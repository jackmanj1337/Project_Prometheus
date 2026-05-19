extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_turn_manager.gd
# Tests TurnManager: the per-unit state machine, record/undo move, the end-turn gate,
# the phase transitions, and check_victory_conditions (every win/loss branch). Uses
# the real GameState + EventBus autoload scripts and a lightweight unit stub.

var _unit_stub: GDScript


# Builds a stub unit with a fresh UnitData (hp/max_hp/unit_id for the victory checks).
func _mk_unit(team_name: String, hp: int, uid: String) -> Node:
	var d := UnitData.new()
	d.hp = hp
	d.max_hp = 20
	d.unit_id = uid
	var u: Node = _unit_stub.new()
	u.set("team", team_name)
	u.set("data", d)
	root.add_child(u)
	return u


func _init() -> void:
	print("=== TurnManager Test ===")
	var passed := 0
	var failed := 0

	_unit_stub = GDScript.new()
	_unit_stub.source_code = "extends Node\nvar team: String = \"player\"\nvar data = null\nvar tile_position: Vector2i = Vector2i.ZERO\nfunc snap_to_tile(t): tile_position = t\n"
	_unit_stub.reload()

	# Real GameState + EventBus autoload scripts at /root so TurnManager resolves them.
	var gs: Node = load("res://scripts/autoloads/GameState.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	var bus: Node = load("res://scripts/autoloads/EventBus.gd").new()
	bus.name = "EventBus"
	root.add_child(bus)
	await process_frame

	# Victory/defeat emission counters (Arrays — captured by reference by the lambdas).
	var victories := [0]
	var defeats := [0]
	bus.map_victory.connect(func(): victories[0] += 1)
	bus.map_defeat.connect(func(): defeats[0] += 1)

	# ---- get_unit_state defaults to READY for an unregistered unit ----
	var tm := TurnManager.new()
	root.add_child(tm)
	var u1 := _mk_unit("player", 20, "u1")
	if tm.get_unit_state(u1) == TurnManager.UnitState.READY:
		print("OK  get_unit_state defaults to READY"); passed += 1
	else:
		print("FAIL get_unit_state default"); failed += 1

	# ---- set_unit_state / get_unit_state round-trip ----
	tm.set_unit_state(u1, TurnManager.UnitState.MOVED)
	var moved_ok: bool = tm.get_unit_state(u1) == TurnManager.UnitState.MOVED
	tm.set_unit_state(u1, TurnManager.UnitState.DONE)
	if moved_ok and tm.get_unit_state(u1) == TurnManager.UnitState.DONE:
		print("OK  set_unit_state / get_unit_state round-trip"); passed += 1
	else:
		print("FAIL set/get_unit_state"); failed += 1

	# ---- can_unit_act: READY and MOVED yes, DONE no ----
	tm.set_unit_state(u1, TurnManager.UnitState.READY)
	var act_ready: bool = tm.can_unit_act(u1)
	tm.set_unit_state(u1, TurnManager.UnitState.MOVED)
	var act_moved: bool = tm.can_unit_act(u1)
	tm.set_unit_state(u1, TurnManager.UnitState.DONE)
	var act_done: bool = tm.can_unit_act(u1)
	if act_ready and act_moved and not act_done:
		print("OK  can_unit_act: READY/MOVED true, DONE false"); passed += 1
	else:
		print("FAIL can_unit_act: ready=%s moved=%s done=%s" % [act_ready, act_moved, act_done])
		failed += 1

	# ---- record_move_start + undo_move: restores tile and resets to READY ----
	var u2 := _mk_unit("player", 20, "u2")
	u2.set("tile_position", Vector2i(3, 4))
	tm.record_move_start(u2)
	u2.set("tile_position", Vector2i(7, 8))   # simulate a move
	tm.set_unit_state(u2, TurnManager.UnitState.MOVED)
	tm.undo_move(u2)
	if u2.tile_position == Vector2i(3, 4) \
			and tm.get_unit_state(u2) == TurnManager.UnitState.READY:
		print("OK  record_move_start + undo_move restores tile and state"); passed += 1
	else:
		print("FAIL undo_move: tile=%s state=%d" % [str(u2.tile_position), tm.get_unit_state(u2)])
		failed += 1

	# ---- _on_unit_died erases the unit from _unit_states ----
	tm.set_unit_state(u1, TurnManager.UnitState.DONE)
	tm._on_unit_died(u1)
	if not tm._unit_states.has(u1):
		print("OK  _on_unit_died erases the unit from _unit_states"); passed += 1
	else:
		print("FAIL _on_unit_died"); failed += 1

	# ---- are_all_player_units_done: true when every living player is DONE ----
	gs.reset_map_state()
	var d1 := _mk_unit("player", 20, "d1")
	var d2 := _mk_unit("player", 20, "d2")
	gs.register_unit(d1)
	gs.register_unit(d2)
	var tm2 := TurnManager.new()
	root.add_child(tm2)
	tm2.set_unit_state(d1, TurnManager.UnitState.DONE)
	tm2.set_unit_state(d2, TurnManager.UnitState.DONE)
	if tm2.are_all_player_units_done():
		print("OK  are_all_player_units_done: true when all are DONE"); passed += 1
	else:
		print("FAIL are_all_player_units_done (all done)"); failed += 1

	# ---- are_all_player_units_done: false when one is still able to act ----
	tm2.set_unit_state(d2, TurnManager.UnitState.READY)
	if not tm2.are_all_player_units_done():
		print("OK  are_all_player_units_done: false when one can still act"); passed += 1
	else:
		print("FAIL are_all_player_units_done (one ready)"); failed += 1

	# ---- check_victory_conditions: rout objective + no enemies → map_victory ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("player", 20, "p1"))
	var md_rout := MapData.new()
	md_rout.objective_type = "rout"
	var tm_v := TurnManager.new()
	root.add_child(tm_v)
	tm_v._map_data = md_rout
	victories[0] = 0
	tm_v.check_victory_conditions()
	if victories[0] == 1:
		print("OK  check_victory_conditions: rout + no enemies → map_victory"); passed += 1
	else:
		print("FAIL victory rout: victories=%d" % victories[0]); failed += 1

	# ---- check_victory_conditions: _map_over latches → no double emit ----
	tm_v.check_victory_conditions()
	if victories[0] == 1:
		print("OK  check_victory_conditions: _map_over prevents a second emit"); passed += 1
	else:
		print("FAIL victory double-emit: victories=%d" % victories[0]); failed += 1

	# ---- check_victory_conditions: all players dead → map_defeat ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("enemy", 20, "e1"))   # a living enemy → rout victory cannot fire
	gs.register_unit(_mk_unit("player", 0, "p2"))   # dead player
	var tm_d := TurnManager.new()
	root.add_child(tm_d)
	tm_d._map_data = md_rout
	defeats[0] = 0
	tm_d.check_victory_conditions()
	if defeats[0] == 1:
		print("OK  check_victory_conditions: all players dead → map_defeat"); passed += 1
	else:
		print("FAIL defeat all-dead: defeats=%d" % defeats[0]); failed += 1

	# ---- check_victory_conditions: turn limit exceeded → map_defeat ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("player", 20, "p3"))
	gs.turn_number = 4
	var md_limit := MapData.new()
	md_limit.objective_type = "rout"
	md_limit.turn_limit = 3
	var tm_t := TurnManager.new()
	root.add_child(tm_t)
	tm_t._map_data = md_limit
	defeats[0] = 0
	tm_t.check_victory_conditions()
	if defeats[0] == 1:
		print("OK  check_victory_conditions: turn limit exceeded → map_defeat"); passed += 1
	else:
		print("FAIL defeat turn-limit: defeats=%d" % defeats[0]); failed += 1

	# ---- check_victory_conditions: a required survivor killed → map_defeat ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("enemy", 20, "e2"))      # living enemy → no rout victory
	gs.register_unit(_mk_unit("player", 20, "grunt"))  # alive, but not the required survivor
	var md_surv := MapData.new()
	md_surv.objective_type = "rout"
	md_surv.required_survivor_ids = ["hero"] as Array[String]
	var tm_s := TurnManager.new()
	root.add_child(tm_s)
	tm_s._map_data = md_surv
	defeats[0] = 0
	tm_s.check_victory_conditions()
	if defeats[0] == 1:
		print("OK  check_victory_conditions: required survivor dead → map_defeat"); passed += 1
	else:
		print("FAIL defeat survivor: defeats=%d" % defeats[0]); failed += 1

	# ---- check_victory_conditions: null _map_data is a no-op ----
	var tm_n := TurnManager.new()
	root.add_child(tm_n)
	victories[0] = 0
	defeats[0] = 0
	tm_n.check_victory_conditions()
	if victories[0] == 0 and defeats[0] == 0:
		print("OK  check_victory_conditions: null _map_data is a no-op"); passed += 1
	else:
		print("FAIL victory null-mapdata"); failed += 1

	# ---- end_player_phase: increments turn_number and emits turn_changed ----
	gs.reset_map_state()           # turn_number → 1
	var tm_e := TurnManager.new()
	root.add_child(tm_e)
	var turn_seen := [0]
	tm_e.turn_changed.connect(func(n): turn_seen[0] = n)
	tm_e.end_player_phase()
	if gs.turn_number == 2 and turn_seen[0] == 2:
		print("OK  end_player_phase: turn_number → 2, turn_changed emitted"); passed += 1
	else:
		print("FAIL end_player_phase: turn=%d signal=%d" % [gs.turn_number, turn_seen[0]])
		failed += 1

	# ---- start_player_phase: resets a DONE player unit back to READY ----
	var tm_p := TurnManager.new()
	root.add_child(tm_p)
	var rp := _mk_unit("player", 20, "rp")
	tm_p.set_unit_state(rp, TurnManager.UnitState.DONE)
	tm_p.start_player_phase()
	if tm_p.get_unit_state(rp) == TurnManager.UnitState.READY:
		print("OK  start_player_phase: a DONE player unit is reset to READY"); passed += 1
	else:
		print("FAIL start_player_phase reset: state=%d" % tm_p.get_unit_state(rp)); failed += 1

	# Flush any deferred _auto_end_player_phase calls queued by earlier blocks.
	await process_frame

	# ---- set_unit_state DONE on the last player unit auto-ends the phase (#5) ----
	gs.reset_map_state()
	gs.set_phase(gs.Phase.PLAYER)
	var a1 := _mk_unit("player", 20, "a1")
	gs.register_unit(a1)
	var tm_auto := TurnManager.new()
	root.add_child(tm_auto)
	var auto_seen := [0]
	tm_auto.turn_changed.connect(func(n): auto_seen[0] = n)
	tm_auto.set_unit_state(a1, TurnManager.UnitState.DONE)
	await process_frame   # let the deferred _auto_end_player_phase run
	if auto_seen[0] != 0:
		print("OK  last player unit DONE auto-ends the phase (#5)"); passed += 1
	else:
		print("FAIL auto-end did not fire"); failed += 1

	# ---- auto-end does NOT fire while a player unit can still act ----
	gs.reset_map_state()
	gs.set_phase(gs.Phase.PLAYER)
	var b1 := _mk_unit("player", 20, "b1")
	var b2 := _mk_unit("player", 20, "b2")
	gs.register_unit(b1)
	gs.register_unit(b2)
	var tm_partial := TurnManager.new()
	root.add_child(tm_partial)
	var partial_seen := [0]
	tm_partial.turn_changed.connect(func(n): partial_seen[0] = n)
	tm_partial.set_unit_state(b1, TurnManager.UnitState.DONE)   # b2 still READY
	await process_frame
	if partial_seen[0] == 0:
		print("OK  auto-end holds while a unit can still act"); passed += 1
	else:
		print("FAIL auto-end fired early: turn_changed=%d" % partial_seen[0]); failed += 1

	# ---- _auto_end_player_phase bails when the map is already over ----
	# Audit regression: a last action that also wins/loses the map must not then
	# kick off an enemy phase.
	var tm_over := TurnManager.new()
	root.add_child(tm_over)
	tm_over._map_over = true
	var over_seen := [0]
	tm_over.turn_changed.connect(func(n): over_seen[0] = n)
	tm_over._auto_end_player_phase()
	if over_seen[0] == 0:
		print("OK  _auto_end_player_phase is a no-op once the map is over"); passed += 1
	else:
		print("FAIL auto-end ran after map over: turn_changed=%d" % over_seen[0]); failed += 1

	# ---- a death that leaves every player unit DONE auto-ends the phase (#5) ----
	# Mutual kill: the last unit to act dies on its own action, so set_unit_state
	# never marks it DONE — _on_unit_died must still trigger the auto-end.
	gs.reset_map_state()
	gs.set_phase(gs.Phase.PLAYER)
	var done_unit := _mk_unit("player", 20, "done1")
	var dying_unit := _mk_unit("player", 20, "dying1")
	gs.register_unit(done_unit)
	gs.register_unit(dying_unit)
	gs.register_unit(_mk_unit("enemy", 20, "foe1"))   # living enemy → no rout victory
	var tm_death := TurnManager.new()
	root.add_child(tm_death)
	var md_death := MapData.new()
	md_death.objective_type = "rout"
	tm_death._map_data = md_death
	tm_death.set_unit_state(done_unit, TurnManager.UnitState.DONE)
	var death_seen := [0]
	tm_death.turn_changed.connect(func(n): death_seen[0] = n)
	dying_unit.data.hp = 0                            # the mutual-kill death
	tm_death._on_unit_died(dying_unit)
	await process_frame
	if death_seen[0] != 0:
		print("OK  a mutual-kill death auto-ends the phase when others are DONE")
		passed += 1
	else:
		print("FAIL no auto-end after last-unit death"); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
