extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_spawn_seam.gd
#
# [PUG-3] The spawn seam generalization: an enemy placement resolves to a
# UnitData via exactly one source: an already-built in-memory `unit_data`
# instance OR a `unit_data_path` resource path. Both paths flow through the SAME
# resolution (GameMap._resolve_placement_unit_data), producing an equivalent
# fresh copy so generated skirmish forces / editor-baked units / reinforcements
# can spawn without ever writing a .tres. This tests the seam directly.

const ENEMY_PATH := "res://data/maps/map_001_rout/enemies/e1_soldier.tres"


func _init() -> void:
	print("=== Spawn Seam Test ([PUG-3]) ===")
	var passed := 0
	var failed := 0

	# A bare GameMap script instance is enough — _resolve_placement_unit_data
	# only touches the placement dict + ResourceLoader, not scene nodes.
	var gm: GameMap = GameMap.new()

	# 1. Path branch: an authored placement resolves via load().
	var path_placement := {"unit_data_path": ENEMY_PATH, "tile": Vector2i(3, 3)}
	var from_path: UnitData = gm._resolve_placement_unit_data(path_placement)
	if from_path != null and from_path.unit_id != "":
		print("OK  path placement resolves to a UnitData (id=%s)" % from_path.unit_id)
		passed += 1
	else:
		print("FAIL path placement did not resolve to a valid UnitData")
		failed += 1

	# 2. In-memory branch: an already-built UnitData is used directly, no path.
	var in_mem := UnitData.new()
	in_mem.unit_id = "gen_grunt_01"
	in_mem.unit_name = "Generated Grunt"
	in_mem.class_id = "soldier"
	in_mem.ai_profile = "passive"
	in_mem.max_hp = 20
	in_mem.hp = 20
	var mem_placement := {"unit_data": in_mem, "tile": Vector2i(4, 4)}
	var from_mem: UnitData = gm._resolve_placement_unit_data(mem_placement)
	if (
		from_mem != null
		and from_mem.unit_id == "gen_grunt_01"
		and from_mem.max_hp == 20
		and from_mem.ai_profile == "passive"
	):
		print("OK  in-memory placement resolves to the built UnitData")
		passed += 1
	else:
		print("FAIL in-memory placement did not resolve correctly")
		failed += 1

	# 3. The seam returns a FRESH copy, not the caller's instance — mutating the
	# spawned copy must not bleed back into the source spec (fresh copy per map).
	if from_mem != null and from_mem != in_mem:
		from_mem.hp = 1
		if in_mem.hp == 20:
			print("OK  in-memory placement is duplicated (source unchanged)")
			passed += 1
		else:
			print("FAIL in-memory source mutated by spawned copy")
			failed += 1
	else:
		print("FAIL in-memory placement was not duplicated")
		failed += 1

	# 4. Placement keys are explicit overrides; omission preserves UnitData data.
	if from_mem != null:
		gm._apply_enemy_placement_overrides(from_mem, {})
		if from_mem.ai_profile == "passive":
			print("OK  omitted ai_profile preserves the UnitData profile")
			passed += 1
		else:
			print("FAIL omitted ai_profile overwrote the UnitData profile")
			failed += 1
	else:
		print("FAIL could not test omitted ai_profile because in-memory resolution failed")
		failed += 1

	# 5. Authored placements can still explicitly override ai_profile.
	if from_mem != null:
		gm._apply_enemy_placement_overrides(from_mem, {"ai_profile": "basic"})
		if from_mem.ai_profile == "basic":
			print("OK  explicit ai_profile overrides the UnitData profile")
			passed += 1
		else:
			print("FAIL explicit ai_profile did not override the UnitData profile")
			failed += 1
	else:
		print("FAIL could not test explicit ai_profile because in-memory resolution failed")
		failed += 1

	# 6. Ambiguous sources are rejected instead of choosing one silently.
	var both := {
		"unit_data": in_mem, "unit_data_path": "res://does/not/exist.tres", "tile": Vector2i.ZERO
	}
	var from_both: UnitData = gm._resolve_placement_unit_data(both)
	if from_both == null:
		print("OK  mixed unit_data + unit_data_path placement is rejected")
		passed += 1
	else:
		print("FAIL mixed unit_data + unit_data_path placement was accepted")
		failed += 1

	# 7. Bad data (no instance, missing path) resolves to null so the caller skips.
	var bad := {"tile": Vector2i.ZERO}
	if gm._resolve_placement_unit_data(bad) == null:
		print("OK  empty placement resolves to null (caller skips)")
		passed += 1
	else:
		print("FAIL empty placement did not resolve to null")
		failed += 1

	# 8. Equivalence: a path unit and an in-memory unit built from the same source
	# produce units with the same identity through the one seam.
	var loaded_src := load(ENEMY_PATH) as UnitData
	var equiv_placement := {"unit_data": loaded_src, "tile": Vector2i(5, 5)}
	var via_mem: UnitData = gm._resolve_placement_unit_data(equiv_placement)
	if via_mem != null and from_path != null and via_mem.unit_id == from_path.unit_id:
		print("OK  path and in-memory placements built from the same source match")
		passed += 1
	else:
		print("FAIL path/in-memory equivalence mismatch")
		failed += 1

	gm.free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
