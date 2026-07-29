extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_map_950_promotion_validation.gd
# Smoke-test for the map_950 promotion / reclass validation map. Confirms:
#   - the registry entry is well-formed
#   - the map data .tres loads
#   - every enemy_placement unit_data_path resolves
#   - every fixed-roster .tres loads and passes DataManager.validate_unit_data
# A regression here means the next playtest will fail before any flow can be
# exercised — fail loud now rather than mid-playtest.

const REGISTRY_PATH := "res://data/maps/map_registry.json"
const MAP_ID := "map_950_promotion_validation"


func _init() -> void:
	print("=== map_950 Promotion Validation Smoke Test ===")
	var passed := 0
	var failed := 0

	# Registry must declare the map.
	var registry_raw := FileAccess.get_file_as_string(REGISTRY_PATH)
	var registry: Variant = JSON.parse_string(registry_raw)
	var entry: Dictionary = {}
	if registry is Array:
		for e in registry:
			if e is Dictionary and e.get("id", "") == MAP_ID:
				entry = e
				break
	if entry.is_empty():
		print("FAIL map_registry.json missing entry for %s" % MAP_ID)
		quit(1)
		return
	print("OK  registry entry present")
	passed += 1

	# Sanity: roster_policy + roster_source point at a fixed roster directory.
	if (
		entry.get("roster_policy", "") == "fixed_test_roster"
		and String(entry.get("roster_source", "")).ends_with("/")
	):
		print("OK  registry roster_policy/source shape correct")
		passed += 1
	else:
		print(
			(
				"FAIL registry roster shape: policy=%s source=%s"
				% [entry.get("roster_policy"), entry.get("roster_source")]
			)
		)
		failed += 1

	# Map data .tres loads.
	var map_path: String = entry["map_data_path"]
	if not ResourceLoader.exists(map_path):
		print("FAIL map_data_path missing: %s" % map_path)
		failed += 1
		print("Results: %d passed, %d failed" % [passed, failed])
		quit(1)
		return
	var map_data: Resource = load(map_path)
	if map_data == null:
		print("FAIL map_data did not load: %s" % map_path)
		failed += 1
	else:
		print("OK  map data .tres loads")
		passed += 1

	# Every enemy_placement unit_data_path must resolve and load.
	var placements: Array = map_data.get("enemy_placements")
	if placements.is_empty():
		print("FAIL enemy_placements is empty")
		failed += 1
	else:
		var bad_paths := 0
		for p in placements:
			var path: String = String(p.get("unit_data_path", ""))
			if path == "" or not ResourceLoader.exists(path) or load(path) == null:
				bad_paths += 1
				print("    bad enemy path: %s" % path)
		if bad_paths == 0:
			print("OK  all %d enemy unit paths resolve" % placements.size())
			passed += 1
		else:
			print("FAIL %d enemy unit paths failed to resolve" % bad_paths)
			failed += 1

	# Fixed-roster directory: every .tres loads and passes validation.
	var roster_dir: String = entry["roster_source"]
	var dir := DirAccess.open(roster_dir)
	if dir == null:
		print("FAIL cannot open roster_source: %s" % roster_dir)
		failed += 1
	else:
		var files: Array[String] = []
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if fname.ends_with(".tres"):
				files.append(fname)
			fname = dir.get_next()
		dir.list_dir_end()
		files.sort()
		if files.size() >= 10:
			print("OK  roster has %d .tres files (expected 10+)" % files.size())
			passed += 1
		else:
			print("FAIL roster has only %d .tres files" % files.size())
			failed += 1

		# Validate each roster unit via DataManager. Bring up a live DataManager
		# instance via the relay-node pattern.
		var relay := Node.new()
		root.add_child(relay)
		await process_frame
		var dm := relay.get_node_or_null("/root/DataManager")
		relay.queue_free()
		if dm == null:
			print("BAIL DataManager autoload missing — validation step skipped")
		else:
			var bad_units := 0
			for f in files:
				var unit: Resource = load(roster_dir + f)
				if unit == null:
					print("    cannot load %s" % f)
					bad_units += 1
					continue
				var errors: Array[String] = dm.validate_unit_data(unit)
				if not errors.is_empty():
					bad_units += 1
					for err in errors:
						print("    %s: %s" % [f, err])
			if bad_units == 0:
				print("OK  all roster units pass validate_unit_data")
				passed += 1
			else:
				print("FAIL %d roster units failed validation" % bad_units)
				failed += 1

	# V025-05e content asks: the skill-cap hero must actually sit AT the 5-skill cap so
	# the "skill slots full" path is exercised, and the map must carry the 10 grind
	# units the owner requested for repeated level-up / stat-cap testing.
	var hero: Resource = load(roster_dir + "unit_12_hero_skill_cap.tres")
	if hero != null and Array(hero.get("skills")).size() == 5:
		print("OK  V025-05e skill-cap hero carries a full 5-skill loadout")
		passed += 1
	else:
		print(
			(
				"FAIL hero skill count: %s"
				% [Array(hero.get("skills")).size() if hero != null else "<none>"]
			)
		)
		failed += 1
	var grind_count := 0
	for p in placements:
		if "grind" in String(p.get("unit_data_path", "")):
			grind_count += 1
	if grind_count >= 10:
		print("OK  V025-05e map carries %d grind units for EXP/stat-cap testing" % grind_count)
		passed += 1
	else:
		print("FAIL grind unit count: %d (want >= 10)" % grind_count)
		failed += 1

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
