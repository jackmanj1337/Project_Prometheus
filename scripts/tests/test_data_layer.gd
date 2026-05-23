extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_data_layer.gd
# Tests that all .tres resource files load correctly without using autoload singletons.

func _init() -> void:
	print("=== Data Layer Test ===")
	var passed := 0
	var failed := 0

	# --- Classes / weapons / items / skills ---
	for loaded in _load_resources_from_dir("res://data/classes/"):
		if loaded and loaded is ClassData and loaded.id != "":
			print("OK  class: " + loaded.id)
			passed += 1
		else:
			print("FAIL class resource: " + str(loaded))
			failed += 1

	for loaded in _load_resources_from_dir("res://data/weapons/"):
		if loaded and loaded is WeaponData and loaded.id != "":
			print("OK  weapon: " + loaded.id)
			passed += 1
		else:
			print("FAIL weapon resource: " + str(loaded))
			failed += 1

	for loaded in _load_resources_from_dir("res://data/items/"):
		if loaded and loaded is ItemData and loaded.id != "":
			print("OK  item: " + loaded.id)
			passed += 1
		else:
			print("FAIL item resource: " + str(loaded))
			failed += 1

	for loaded in _load_resources_from_dir("res://data/skills/"):
		if loaded and loaded is SkillData and loaded.id != "":
			print("OK  skill: " + loaded.id)
			passed += 1
		else:
			print("FAIL skill resource: " + str(loaded))
			failed += 1

	# --- Default roster ---
	var roster_files := [
		"res://data/roster/default/unit_01_cavalier.tres",
		"res://data/roster/default/unit_02_mercenary.tres",
		"res://data/roster/default/unit_03_archer.tres",
		"res://data/roster/default/unit_04_mage.tres",
		"res://data/roster/default/unit_05_cleric.tres",
		"res://data/roster/default/unit_06_knight.tres",
	]
	for path in roster_files:
		var u = load(path)
		if u and u is UnitData and u.unit_name != "":
			print("OK  roster: " + u.unit_name + " (" + u.class_id + ")")
			passed += 1
		else:
			print("FAIL roster: " + path)
			failed += 1

	# --- Map data ---
	var md = load("res://data/maps/map_001_rout/map_001_data.tres")
	if md and md is MapData and md.id == "map_001":
		print("OK  map_data: map_001 (%d enemies)" % md.enemy_placements.size())
		passed += 1
	else:
		print("FAIL map_data: map_001_data.tres")
		failed += 1

	# --- M16: map_001 authored conditions ---
	# Stage 5 migrated map_001 to victory_conditions = {"allies": [rout()]}.
	# defeat_conditions stays empty — the implicit "group routed" default
	# (TurnManager) supplies the all-allies-dead defeat.
	if md and md.victory_conditions is Dictionary \
			and md.victory_conditions.has("allies") \
			and (md.victory_conditions["allies"] as Array).size() == 1 \
			and (md.victory_conditions["allies"][0] as ObjectiveCondition).type == "rout":
		print("OK  map_001: victory_conditions = {allies: [rout]}"); passed += 1
	else:
		print("FAIL map_001 victory_conditions: %s" % str(md.victory_conditions if md else null)); failed += 1
	if md and md.defeat_conditions is Dictionary and md.defeat_conditions.is_empty():
		print("OK  map_001: defeat_conditions empty (implicit group-routed default)"); passed += 1
	else:
		print("FAIL map_001 defeat_conditions: %s" % str(md.defeat_conditions if md else null)); failed += 1

	# --- M16 stage 1: ObjectiveCondition resource constructs with defaults ---
	# L-1 (post-review): seize uses a separate singular `tile` field; the
	# sentinel Vector2i(-1, -1) means "not authored".
	var oc := ObjectiveCondition.new()
	if oc is ObjectiveCondition and oc.type == "rout" and oc.faction_id == "" \
			and oc.unit_ids.is_empty() and oc.tiles.is_empty() \
			and oc.allowed_unit_ids.is_empty() and oc.turns == 0 \
			and oc.tile == Vector2i(-1, -1):
		print("OK  ObjectiveCondition: defaults (type=rout, all params empty/0, tile sentinel)"); passed += 1
	else:
		print("FAIL ObjectiveCondition defaults — got type=%s, faction_id=%s, tile=%s" % [oc.type, oc.faction_id, str(oc.tile)]); failed += 1

	# --- M16 stage 4: get_display_text() one-liners per type ---
	var dt_rout_all := ObjectiveCondition.new()
	dt_rout_all.type = "rout"
	var dt_rout_named := ObjectiveCondition.new()
	dt_rout_named.type = "rout"; dt_rout_named.faction_id = "red"
	var dt_boss := ObjectiveCondition.new()
	dt_boss.type = "defeat_boss"; dt_boss.unit_ids = ["e8"] as Array[String]
	var dt_esc := ObjectiveCondition.new()
	dt_esc.type = "escape"; dt_esc.unit_ids = ["lord"] as Array[String]
	var dt_surv := ObjectiveCondition.new()
	dt_surv.type = "survive"; dt_surv.turns = 5
	# Seize display text (L-1): uses the singular `tile` field; sentinel → "Seize".
	var dt_seize_bare := ObjectiveCondition.new()
	dt_seize_bare.type = "seize"
	var dt_seize_tile := ObjectiveCondition.new()
	dt_seize_tile.type = "seize"; dt_seize_tile.tile = Vector2i(3, 4)
	if dt_rout_all.get_display_text() == "Rout all hostiles" \
			and dt_rout_named.get_display_text() == "Rout red" \
			and dt_boss.get_display_text() == "Defeat e8" \
			and dt_esc.get_display_text() == "Escape: lord" \
			and dt_surv.get_display_text() == "Survive 5 turn(s)" \
			and dt_seize_bare.get_display_text() == "Seize" \
			and dt_seize_tile.get_display_text() == "Seize (3, 4)":
		print("OK  ObjectiveCondition.get_display_text: per-type one-liners"); passed += 1
	else:
		print("FAIL display_text: rout_all=%s rout_red=%s boss=%s esc=%s surv=%s seize_bare=%s seize_tile=%s" % [
			dt_rout_all.get_display_text(), dt_rout_named.get_display_text(),
			dt_boss.get_display_text(), dt_esc.get_display_text(),
			dt_surv.get_display_text(), dt_seize_bare.get_display_text(),
			dt_seize_tile.get_display_text()]); failed += 1

	# --- Roster unit_id non-empty ---
	for path in roster_files:
		var u = load(path)
		if u and u is UnitData and u.unit_id != "":
			print("OK  unit_id: " + u.unit_id)
			passed += 1
		else:
			print("FAIL unit_id empty in: " + path)
			failed += 1

	# --- Roster reclass metadata validates against the loaded class catalogue ---
	var DataManagerS = load("res://scripts/autoloads/DataManager.gd")
	var class_catalogue := {}
	for loaded_class in _load_resources_from_dir("res://data/classes/"):
		if loaded_class and loaded_class is ClassData and loaded_class.id != "":
			class_catalogue[loaded_class.id] = loaded_class
	var roster_units: Array = []
	for path in roster_files:
		roster_units.append(load(path))
	var roster_errors: Array[String] = DataManagerS.collect_unit_validation_errors(
		roster_units, class_catalogue)
	if roster_errors.is_empty():
		print("OK  roster reclass metadata validates cleanly")
		passed += 1
	else:
		print("FAIL roster reclass validation: %s" % [roster_errors])
		failed += 1

	# --- Snapshot coverage: every mutable UnitData property must appear in the
	# snapshot dict or in the explicit allowlist of intentionally-excluded fields.
	# Fail if a new @export var is added to UnitData without updating the snapshot.
	var snapshot_keys := [
		"tile_position", "class_id", "hp", "max_hp", "strength", "magic", "defense",
		"resistance", "skill", "speed", "luck", "exp", "level", "effective_level",
		"is_promoted", "class_line_id",
		"weapon_wexp", "inventory", "conditions", "skills", "earned_skills",
		"mastery_skills",
		"is_incapacitated", "active_modifiers", "skill_use_counters",
		"damage_taken_this_map", "growth_accumulators", "shift_gauge", "is_shifted",
	]
	# Properties intentionally excluded: static identity or between-map state only.
	var snapshot_allowlist := [
		"unit_id", "unit_name", "movement",
		"constitution", "line_of_sight", "gold", "ai_profile", "is_default_roster",
		"shift_profile_id", "growth_rates", "reclass_options",
	]
	var sample_unit: UnitData = UnitData.new()
	var snapshot_fail := false
	for prop_dict in sample_unit.get_property_list():
		var pname: String = prop_dict["name"]
		var usage: int = prop_dict["usage"]
		# Only check script-level properties (skips built-in Resource fields).
		if not (usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if pname in snapshot_keys or pname in snapshot_allowlist:
			continue
		print("FAIL snapshot_coverage: UnitData.%s not in snapshot or allowlist" % pname)
		snapshot_fail = true
	if snapshot_fail:
		failed += 1
	else:
		print("OK  snapshot_coverage: all UnitData properties accounted for")
		passed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _load_resources_from_dir(path: String) -> Array:
	var loaded: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		return loaded
	var files: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()
	for fname2 in files:
		loaded.append(load(path + fname2))
	return loaded
