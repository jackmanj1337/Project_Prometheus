extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_suspend_map_runtime.gd
# B1-SUSPEND Slice 1: active-map suspend payloads round-trip through SaveData
# and GameMap restores live unit/scheduler/UI state instead of authored spawns.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const PairUpRegistryScript = preload("res://scripts/autoloads/PairUpRegistry.gd")

# V030-SUS-01 (d): captures turn_changed emitted during restore so the test can
# assert the HUD-refresh signal fires (a plain local can't be mutated from the
# lambda by reference; a member var can — GDScript lambda capture rule).
var _restore_turn_changed_value: int = -1


func _on_restore_turn_changed(turn_number: int) -> void:
	_restore_turn_changed_value = turn_number


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
	var pair_reg: Node = _ensure_autoload(
		"PairUpRegistry", "res://scripts/autoloads/PairUpRegistry.gd"
	)
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
	# Mirror MapCursor's pair flow (MapCursor.gd:1203-1204): the support is moved
	# to the off-map sentinel and hidden, and that sentinel tile is what the
	# payload serializes. Without this the test wouldn't reproduce the (-1,-1)
	# render — pair() alone only writes the registry dict.
	blue_b.snap_to_tile(PairUpRegistryScript.OFF_MAP_TILE)
	blue_b.visible = false
	turn._activation_mode = "ALTERNATING"
	turn._turn_order = ["blue", "red"] as Array[String]
	turn._active_faction_idx = 1
	turn._unit_states[blue_a] = TurnManager.UnitState.DONE
	turn._unit_states[boss] = TurnManager.UnitState.READY
	gs.turn_number = 3
	gs.set_phase(gs.Phase.ENEMY, "red")
	# CST-8: committed-action boundaries are suspendable for any locally
	# controlled faction, including a non-blue hotseat phase, but never for AI.
	var red_faction: FactionData = null
	if turn._map_data != null:
		for f in turn._map_data.factions:
			if f != null and f.id == "red":
				red_faction = f
				f.controller = "HOTSEAT"
		if red_faction == null:
			red_faction = FactionData.new()
			red_faction.id = "red"
			red_faction.controller = "HOTSEAT"
			turn._map_data.factions.append(red_faction)
	# Model the idle boundary exposed by HotseatController.run_phase(). Directly
	# changing GameState to ENEMY above correctly locked the cursor first.
	cursor.unlock()
	var suspend_allowed_hotseat: bool = cursor.can_capture_suspend()
	if red_faction != null:
		red_faction.controller = "BASIC"
	var suspend_refused_ai: bool = not cursor.can_capture_suspend()
	if red_faction != null:
		red_faction.controller = "HOTSEAT"
	turn._active_faction_idx = 0
	gs.set_phase(gs.Phase.PLAYER, "blue")
	var suspend_allowed_blue: bool = cursor.can_capture_suspend()
	if suspend_allowed_hotseat and suspend_refused_ai and suspend_allowed_blue:
		print("OK  suspend capture allows local blue/hotseat phases and rejects AI")
		passed += 1
	else:
		print(
			(
				"FAIL suspend gate: hotseat_allowed=%s ai_refused=%s blue_allowed=%s"
				% [suspend_allowed_hotseat, suspend_refused_ai, suspend_allowed_blue]
			)
		)
		failed += 1
	turn._active_faction_idx = 1
	gs.set_phase(gs.Phase.ENEMY, "red")
	rng.commit_event("wait", [blue_a_id, "1,9", "1,9"] as Array[String])
	var rng_at_suspend: Dictionary = rng.to_save_dict()
	gs.rewind_charges_left = 3
	cursor._watch_set.clear()
	cursor._watch_set[blue_a_id] = true
	cursor._danger_mode = "combined"
	cursor._set_tile(Vector2i(8, 8))

	var captured: RefCounted = gs.capture_suspend_save(turn, cursor)
	var parsed: Variant = JSON.parse_string(JSON.stringify(captured.to_dict()))
	var restored_save: RefCounted = SaveDataScript.from_dict(parsed)
	var payload: Dictionary = restored_save.to_dict()
	var payload_ok: bool = (
		payload["map_runtime"]["units"].size() == gs.all_units.size()
		and payload["ledger"].size() >= 1
		and (
			int(payload["map_runtime"]["turn"]["unit_states"].get(blue_a_id, -1))
			== TurnManager.UnitState.DONE
		)
		and String(payload["map_runtime"]["turn"]["active_faction"]) == "red"
		and int(payload["map_runtime"]["rng"].get("map_seed", 0)) == rng_at_suspend["map_seed"]
		and blue_a_id in payload["suspend"]["threat_views_by_faction"]["red"]["watch_set"]
		and (
			String(payload["suspend"]["threat_views_by_faction"]["red"]["danger_mode"])
			== "combined"
		)
	)
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
	if gs.history_size() != payload["ledger"].size():
		print(
			(
				"FAIL restored rewind ledger size: %s != %s"
				% [gs.history_size(), payload["ledger"].size()]
			)
		)
		quit(1)
		return
	# The fixture map is authored as AI and DataManager returns a fresh resolved
	# copy on the second scene boot. F9 exercises the same local-controller route
	# without changing the production campaign asset just for this runtime test.
	gs.debug_hotseat_override = true

	var resumed_map: Node = packed.instantiate()
	# Connect BEFORE add_child: start_map_from_suspend runs inside GameMap._ready
	# (fired by add_child), so a listener attached afterward would miss the emit.
	var resumed_turn_early: TurnManager = resumed_map.get_node("TurnManager")
	resumed_turn_early.turn_changed.connect(_on_restore_turn_changed)
	root.add_child(resumed_map)
	await process_frame
	var resumed_units: Node = resumed_map.get_node("UnitsContainer")
	var resumed_turn: TurnManager = resumed_map.get_node("TurnManager")
	var resumed_cursor: MapCursor = resumed_map.get_node("MapCursor")
	var resumed_boss: Node = _find_unit(resumed_units, "e8_knight_boss")
	var resumed_blue: Node = _find_unit(resumed_units, "unit_01_cavalier")
	var local_driver_restored: bool = (
		resumed_cursor._state == MapCursor.State.FREE
		and resumed_cursor._controlling_faction == "red"
	)
	if local_driver_restored:
		print("OK  resume re-enters the red hotseat driver and unlocks its cursor")
		passed += 1
	else:
		print(
			(
				"FAIL local driver restore: state=%s faction=%s"
				% [resumed_cursor._state, resumed_cursor._controlling_faction]
			)
		)
		failed += 1

	var enemy_restored: bool = (
		resumed_boss != null
		and resumed_boss.data.hp == 4
		and resumed_boss.tile_position == Vector2i(10, 11)
		and resumed_boss.team == "red"
	)
	if enemy_restored:
		print("OK  resume spawns live enemy state from map_runtime.units")
		passed += 1
	else:
		print("FAIL enemy restore: boss=%s" % [resumed_boss])
		failed += 1

	var turn_restored: bool = (
		resumed_turn._activation_mode == "ALTERNATING"
		and resumed_turn.active_faction() == "red"
		and gs.turn_number == 3
		and resumed_blue != null
		and resumed_turn.get_unit_state(resumed_blue) == TurnManager.UnitState.DONE
		and resumed_boss != null
		and resumed_turn.get_unit_state(resumed_boss) == TurnManager.UnitState.READY
	)
	if turn_restored:
		print("OK  resume restores ALTERNATING scheduler and mixed unit states")
		passed += 1
	else:
		print(
			(
				"FAIL turn restore: mode=%s faction=%s turn=%d blue_state=%s boss_state=%s"
				% [
					resumed_turn._activation_mode,
					resumed_turn.active_faction(),
					gs.turn_number,
					(
						str(resumed_turn.get_unit_state(resumed_blue))
						if resumed_blue != null
						else "missing"
					),
					(
						str(resumed_turn.get_unit_state(resumed_boss))
						if resumed_boss != null
						else "missing"
					),
				]
			)
		)
		failed += 1

	var resumed_rng: Dictionary = rng.to_save_dict()
	var rng_restored: bool = (
		int(resumed_rng.get("map_seed", 0)) == int(rng_at_suspend.get("map_seed", 0))
		and int(resumed_rng.get("history_hash", 0)) == int(rng_at_suspend.get("history_hash", 0))
	)
	var pair_restored: bool = bool(pair_reg.call("is_paired", blue_a_id))
	var cursor_restored: bool = (
		resumed_cursor.current_tile == Vector2i(8, 8)
		and resumed_cursor._watch_set.has(blue_a_id)
		and resumed_cursor._danger_mode == "combined"
	)
	var payload_cleared: bool = gs.next_map_suspend_payload.is_empty()
	var rewind_state_restored: bool = (
		gs.rewind_charges_left == 3 and gs.history_size() == payload["ledger"].size()
	)
	var side_state_restored: bool = (
		rng_restored
		and pair_restored
		and cursor_restored
		and payload_cleared
		and rewind_state_restored
	)
	if side_state_restored:
		print("OK  resume restores RNG, Pair Up, cursor tile, watch set, and clears launch payload")
		passed += 1
	else:
		print(
			(
				"FAIL side restore: rng_ok=%s pair_ok=%s cursor_ok=%s payload_ok=%s rewind_ok=%s rng=%s pair=%s cursor=%s watch=%s mode=%s payload=%s"
				% [
					rng_restored,
					pair_restored,
					cursor_restored,
					payload_cleared,
					rewind_state_restored,
					rng.to_save_dict(),
					pair_reg.call("serialize"),
					resumed_cursor.current_tile,
					resumed_cursor._watch_set.keys(),
					resumed_cursor._danger_mode,
					gs.next_map_suspend_payload,
				]
			)
		)
		failed += 1

	# V030-SUS-01 (a): a restored DONE unit must LOOK done. Restore fills
	# _unit_states directly, so without the fix the sprite keeps its fresh-spawn
	# tint even though can_unit_act correctly refuses it — the "looks ready but
	# won't move" symptom. Compare the sprite modulate against the darkened base.
	var resumed_blue_sprite: Sprite2D = (
		resumed_blue.get_node("Sprite2D") if resumed_blue != null else null
	)
	# set_done_appearance darkens the unit's team-colour base, so derive the
	# expectation from that base rather than white.
	var blue_base: Color = (
		resumed_blue.get("_base_modulate") if resumed_blue != null else Color.WHITE
	)
	var expected_done_modulate: Color = blue_base.darkened(GameConstants.DONE_APPEARANCE_DARKEN)
	var done_appearance_ok: bool = (
		resumed_blue_sprite != null
		and resumed_blue_sprite.modulate.is_equal_approx(expected_done_modulate)
	)
	if done_appearance_ok:
		print("OK  restored DONE unit shows the done (darkened) appearance")
		passed += 1
	else:
		print(
			(
				"FAIL done appearance: sprite_modulate=%s expected=%s"
				% [
					(
						str(resumed_blue_sprite.modulate)
						if resumed_blue_sprite != null
						else "no-sprite"
					),
					expected_done_modulate,
				]
			)
		)
		failed += 1

	# V030-SUS-01 (b): the paired support (blue_b) was hidden at OFF_MAP_TILE when
	# the pair formed. Resume spawns every payload unit visible via _spawn_unit and
	# PairUpRegistry.restore is dict-only, so without the fix the support renders at
	# (-1,-1). It must stay hidden and off-map after resume.
	var resumed_support: Node = _find_unit(resumed_units, "unit_02_mercenary")
	var off_map: Vector2i = PairUpRegistryScript.OFF_MAP_TILE
	var support_hidden_ok: bool = (
		resumed_support != null
		and resumed_support.tile_position == off_map
		and not resumed_support.visible
	)
	if support_hidden_ok:
		print("OK  restored paired support stays hidden at the off-map sentinel")
		passed += 1
	else:
		print(
			(
				"FAIL support restore: support=%s tile=%s visible=%s"
				% [
					resumed_support,
					str(resumed_support.tile_position) if resumed_support != null else "missing",
					str(resumed_support.visible) if resumed_support != null else "missing",
				]
			)
		)
		failed += 1

	# V030-SUS-01 (d): restore assigns gs.turn_number directly and (without the
	# fix) never emits turn_changed, so the HUD label stays stale until the next
	# round boundary. The restore must emit turn_changed with the restored value.
	var turn_changed_ok: bool = _restore_turn_changed_value == 3
	if turn_changed_ok:
		print("OK  restore emits turn_changed so the HUD refreshes immediately")
		passed += 1
	else:
		print("FAIL turn_changed: captured=%d expected=3" % _restore_turn_changed_value)
		failed += 1
	gs.debug_hotseat_override = false

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
