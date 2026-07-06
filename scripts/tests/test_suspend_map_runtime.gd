extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_suspend_map_runtime.gd
# B1-SUSPEND Slice 1: active-map suspend payloads round-trip through SaveData
# and GameMap restores live unit/scheduler/UI state instead of authored spawns.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const PairUpRegistryScript = preload("res://scripts/autoloads/PairUpRegistry.gd")


func _ensure_autoload(name: String, path: String) -> Node:
	var node := root.get_node_or_null(name)
	if node != null:
		return node
	node = load(path).new()
	node.name = name
	root.add_child(node)
	return node


func _find_unit(units_container: Node, unit_id: String) -> Node:
	for child in units_container.get_children():
		if child.get("data") != null and child.data.unit_id == unit_id:
			return child
	return null


func _init() -> void:
	print("=== Suspend Map Runtime Test ===")
	var passed := 0
	var failed := 0

	_ensure_autoload("EventBus", "res://scripts/autoloads/EventBus.gd")
	_ensure_autoload("DataManager", "res://scripts/autoloads/DataManager.gd")
	var pair_reg: Node = _ensure_autoload("PairUpRegistry", "res://scripts/autoloads/PairUpRegistry.gd")
	var rng: Node = _ensure_autoload("RngService", "res://scripts/autoloads/RngService.gd")
	var gs: Node = _ensure_autoload("GameState", "res://scripts/autoloads/GameState.gd")
	await process_frame

	var packed: PackedScene = load("res://scenes/core/GameMap.tscn")
	gs.reset_map_state()
	gs.load_default_roster()
	gs.configure_next_map("res://data/maps/map_001_rout/map_001_data.tres", "default_roster", "")
	rng.start_map(20260706)

	var first_map: Node = packed.instantiate()
	root.add_child(first_map)
	await process_frame

	var units: Node = first_map.get_node("UnitsContainer")
	var cursor: MapCursor = first_map.get_node("MapCursor")
	var turn: TurnManager = first_map.get_node("TurnManager")
	var blue_a: Node = _find_unit(units, "unit_01_cavalier")
	var blue_b: Node = _find_unit(units, "unit_02_mercenary")
	var boss: Node = _find_unit(units, "e8_knight_boss")
	if blue_a == null or blue_b == null or boss == null:
		print("FAIL setup: expected units missing")
		quit(1)
		return
	var blue_a_id: String = blue_a.data.unit_id
	var blue_b_id: String = blue_b.data.unit_id
	var boss_id: String = boss.data.unit_id

	# Mid-map mutations that authored enemy placements cannot recreate.
	boss.data.hp = 4
	boss.snap_to_tile(Vector2i(10, 11))
	pair_reg.call("pair", blue_a_id, blue_b_id)
	turn._activation_mode = "ALTERNATING"
	turn._turn_order = ["blue", "red"] as Array[String]
	turn._active_faction_idx = 1
	turn._unit_states[blue_a] = TurnManager.UnitState.DONE
	turn._unit_states[boss] = TurnManager.UnitState.READY
	gs.turn_number = 3
	gs.set_phase(gs.Phase.ENEMY, "red")
	rng.commit_event("wait", [blue_a_id, "1,9", "1,9"] as Array[String])
	var rng_at_suspend: Dictionary = rng.to_save_dict()
	cursor._watch_set.clear()
	cursor._watch_set[boss_id] = true
	cursor._danger_mode = "combined"
	cursor._set_tile(Vector2i(8, 8))

	var captured: RefCounted = gs.capture_suspend_save(turn, cursor)
	var parsed: Variant = JSON.parse_string(JSON.stringify(captured.to_dict()))
	var restored_save: RefCounted = SaveDataScript.from_dict(parsed)
	var payload: Dictionary = restored_save.to_dict()
	var payload_ok: bool = payload["map_runtime"]["units"].size() == gs.all_units.size() \
		and int(payload["map_runtime"]["turn"]["unit_states"].get(blue_a_id, -1)) == TurnManager.UnitState.DONE \
		and String(payload["map_runtime"]["turn"]["active_faction"]) == "red" \
		and int(payload["map_runtime"]["rng"].get("map_seed", 0)) == rng_at_suspend["map_seed"] \
		and boss_id in payload["suspend"]["watch_set"] \
		and String(payload["suspend"]["danger_mode"]) == "combined"
	if payload_ok:
		print("OK  capture payload carries units, scheduler, RNG, and MRD UI state")
		passed += 1
	else:
		print("FAIL payload: %s" % [payload])
		failed += 1

	first_map.queue_free()
	await process_frame
	if not gs.configure_suspend_resume(payload):
		print("FAIL configure_suspend_resume rejected payload")
		quit(1)
		return

	var resumed_map: Node = packed.instantiate()
	root.add_child(resumed_map)
	await process_frame
	var resumed_units: Node = resumed_map.get_node("UnitsContainer")
	var resumed_turn: TurnManager = resumed_map.get_node("TurnManager")
	var resumed_cursor: MapCursor = resumed_map.get_node("MapCursor")
	var resumed_boss: Node = _find_unit(resumed_units, "e8_knight_boss")
	var resumed_blue: Node = _find_unit(resumed_units, "unit_01_cavalier")

	var enemy_restored: bool = resumed_boss != null \
		and resumed_boss.data.hp == 4 \
		and resumed_boss.tile_position == Vector2i(10, 11) \
		and resumed_boss.team == "red"
	if enemy_restored:
		print("OK  resume spawns live enemy state from map_runtime.units")
		passed += 1
	else:
		print("FAIL enemy restore: boss=%s" % [resumed_boss])
		failed += 1

	var turn_restored: bool = resumed_turn._activation_mode == "ALTERNATING" \
		and resumed_turn.active_faction() == "red" \
		and gs.turn_number == 3 \
		and resumed_blue != null \
		and resumed_turn.get_unit_state(resumed_blue) == TurnManager.UnitState.DONE \
		and resumed_boss != null \
		and resumed_turn.get_unit_state(resumed_boss) == TurnManager.UnitState.READY
	if turn_restored:
		print("OK  resume restores ALTERNATING scheduler and mixed unit states")
		passed += 1
	else:
		print("FAIL turn restore: mode=%s faction=%s turn=%d blue_state=%s boss_state=%s" % [
			resumed_turn._activation_mode,
			resumed_turn.active_faction(),
			gs.turn_number,
			str(resumed_turn.get_unit_state(resumed_blue)) if resumed_blue != null else "missing",
			str(resumed_turn.get_unit_state(resumed_boss)) if resumed_boss != null else "missing",
		])
		failed += 1

	var resumed_rng: Dictionary = rng.to_save_dict()
	var rng_restored: bool = int(resumed_rng.get("map_seed", 0)) == int(rng_at_suspend.get("map_seed", 0)) \
		and int(resumed_rng.get("history_hash", 0)) == int(rng_at_suspend.get("history_hash", 0))
	var pair_restored: bool = bool(pair_reg.call("is_paired", blue_a_id))
	var cursor_restored: bool = resumed_cursor.current_tile == Vector2i(8, 8) \
		and resumed_cursor._watch_set.has("e8_knight_boss") \
		and resumed_cursor._danger_mode == "combined"
	var payload_cleared: bool = gs.next_map_suspend_payload.is_empty()
	var side_state_restored: bool = rng_restored and pair_restored and cursor_restored and payload_cleared
	if side_state_restored:
		print("OK  resume restores RNG, Pair Up, cursor tile, watch set, and clears launch payload")
		passed += 1
	else:
		print("FAIL side restore: rng_ok=%s pair_ok=%s cursor_ok=%s payload_ok=%s rng=%s pair=%s cursor=%s watch=%s mode=%s payload=%s" % [
			rng_restored,
			pair_restored,
			cursor_restored,
			payload_cleared,
			rng.to_save_dict(),
			pair_reg.call("serialize"),
			resumed_cursor.current_tile,
			resumed_cursor._watch_set.keys(),
			resumed_cursor._danger_mode,
			gs.next_map_suspend_payload,
		])
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
