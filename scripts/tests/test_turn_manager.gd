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
	var u1 := _mk_unit("blue", 20, "u1")
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
	var u2 := _mk_unit("blue", 20, "u2")
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
	var d1 := _mk_unit("blue", 20, "d1")
	var d2 := _mk_unit("blue", 20, "d2")
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
	gs.register_unit(_mk_unit("blue", 20, "p1"))
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
	gs.register_unit(_mk_unit("red", 20, "e1"))   # a living enemy → rout victory cannot fire
	gs.register_unit(_mk_unit("blue", 0, "p2"))   # dead player
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
	gs.register_unit(_mk_unit("blue", 20, "p3"))
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
	gs.register_unit(_mk_unit("red", 20, "e2"))      # living enemy → no rout victory
	gs.register_unit(_mk_unit("blue", 20, "grunt"))  # alive, but not the required survivor
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
	var rp := _mk_unit("blue", 20, "rp")
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
	var a1 := _mk_unit("blue", 20, "a1")
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
	var b1 := _mk_unit("blue", 20, "b1")
	var b2 := _mk_unit("blue", 20, "b2")
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
	var done_unit := _mk_unit("blue", 20, "done1")
	var dying_unit := _mk_unit("blue", 20, "dying1")
	gs.register_unit(done_unit)
	gs.register_unit(dying_unit)
	gs.register_unit(_mk_unit("red", 20, "foe1"))   # living enemy → no rout victory
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

	# ---- auto-end honours the SettingsManager toggle (#2) ----
	var sm := root.get_node_or_null("SettingsManager")
	if sm != null:
		gs.reset_map_state()
		gs.set_phase(gs.Phase.PLAYER)
		var solo := _mk_unit("blue", 20, "solo1")
		gs.register_unit(solo)
		var tm_toggle := TurnManager.new()
		root.add_child(tm_toggle)
		# Mark the only player unit DONE directly so set_unit_state's own deferred
		# auto-end doesn't run — this block tests _auto_end_player_phase's gate.
		tm_toggle._unit_states[solo] = TurnManager.UnitState.DONE
		var toggle_seen := [0]
		tm_toggle.turn_changed.connect(func(n): toggle_seen[0] = n)
		sm.auto_end_turn = false
		tm_toggle._auto_end_player_phase()
		var held: bool = toggle_seen[0] == 0
		sm.auto_end_turn = true
		tm_toggle._auto_end_player_phase()
		var ended: bool = toggle_seen[0] != 0
		sm.auto_end_turn = true  # restore the default
		if held and ended:
			print("OK  auto-end respects the SettingsManager toggle (#2)"); passed += 1
		else:
			print("FAIL auto-end toggle: held=%s ended=%s" % [held, ended]); failed += 1
	else:
		print("SKIP auto-end toggle (SettingsManager autoload absent)")

	# ── M14 stage 3: activation scheduler ─────────────────────────────────────

	# ---- start_map: default turn_order is the four-army cycle when MapData is bare ----
	gs.reset_map_state()
	var md_default := MapData.new()
	var tm_default := TurnManager.new()
	root.add_child(tm_default)
	tm_default.start_map(md_default)
	var default_order_ok: bool = (
		tm_default._turn_order == (["blue", "green", "red", "yellow"] as Array[String])
		and tm_default._activation_mode == "WHOLE_PHASE"
		and tm_default.active_faction() == "blue"
	)
	if default_order_ok:
		print("OK  start_map: default turn_order blue→green→red→yellow, WHOLE_PHASE, blue first"); passed += 1
	else:
		print("FAIL default turn_order: order=%s mode=%s active=%s" % [
			tm_default._turn_order, tm_default._activation_mode, tm_default.active_faction()])
		failed += 1

	# ---- start_map: MapData.turn_order overrides the default ----
	gs.reset_map_state()
	var md_custom := MapData.new()
	md_custom.turn_order = ["red", "blue"] as Array[String]   # red moves first
	md_custom.activation_mode = "ALTERNATING"
	var tm_custom := TurnManager.new()
	root.add_child(tm_custom)
	tm_custom.start_map(md_custom)
	var custom_ok: bool = (
		tm_custom._turn_order == (["red", "blue"] as Array[String])
		and tm_custom._activation_mode == "ALTERNATING"
		and tm_custom.active_faction() == "red"
	)
	if custom_ok:
		print("OK  start_map: MapData.turn_order + activation_mode override the defaults"); passed += 1
	else:
		print("FAIL custom turn_order: order=%s mode=%s active=%s" % [
			tm_custom._turn_order, tm_custom._activation_mode, tm_custom.active_faction()])
		failed += 1

	# ---- _advance_faction: skips factions with zero living units ----
	# Cycle blue→green→red. Only blue + red have units; green is empty and must be skipped.
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "b_skip"))
	gs.register_unit(_mk_unit("red", 20, "r_skip"))
	var tm_skip := TurnManager.new()
	root.add_child(tm_skip)
	var md_skip := MapData.new()
	md_skip.turn_order = ["blue", "green", "red"] as Array[String]
	tm_skip.start_map(md_skip)
	# We're on blue (idx 0). One advance should land on red, skipping the empty green.
	var skip_wrapped: bool = tm_skip._advance_faction()
	var skip_active: String = tm_skip.active_faction()
	if not skip_wrapped and skip_active == "red":
		print("OK  _advance_faction: skips zero-unit factions in the cycle"); passed += 1
	else:
		print("FAIL skip-zero: wrapped=%s active=%s (want false / red)" % [skip_wrapped, skip_active])
		failed += 1

	# ---- _advance_faction: wraps past the end and reports it ----
	# Now on red (idx 2). One more advance must wrap → blue (idx 0), wrapped=true.
	var wrap_result: bool = tm_skip._advance_faction()
	var wrap_active: String = tm_skip.active_faction()
	if wrap_result and wrap_active == "blue":
		print("OK  _advance_faction: wraps past end of turn_order and reports it"); passed += 1
	else:
		print("FAIL wrap: wrapped=%s active=%s (want true / blue)" % [wrap_result, wrap_active])
		failed += 1

	# ---- ALTERNATING: end_alternating_activation advances per-unit; round-wrap refreshes + bumps turn ----
	# Build a fresh ALT-mode scheduler with blue + red units, both DONE so we can
	# observe the refresh-on-wrap.
	gs.reset_map_state()
	var alt_blue := _mk_unit("blue", 20, "alt_b")
	var alt_red  := _mk_unit("red", 20, "alt_r")
	gs.register_unit(alt_blue)
	gs.register_unit(alt_red)
	var tm_alt := TurnManager.new()
	root.add_child(tm_alt)
	var md_alt := MapData.new()
	md_alt.turn_order = ["blue", "red"] as Array[String]
	md_alt.activation_mode = "ALTERNATING"
	tm_alt.start_map(md_alt)
	# After start_map: on blue, all units READY.
	tm_alt._unit_states[alt_blue] = TurnManager.UnitState.DONE
	tm_alt._unit_states[alt_red]  = TurnManager.UnitState.DONE
	var alt_turn_seen := [0]
	tm_alt.turn_changed.connect(func(n): alt_turn_seen[0] = n)
	# First end-activation: blue → red, no wrap, no refresh.
	tm_alt.end_alternating_activation()
	var alt_mid_ok: bool = (
		tm_alt.active_faction() == "red"
		and alt_turn_seen[0] == 0
		and tm_alt._unit_states[alt_blue] == TurnManager.UnitState.DONE
	)
	# Second end-activation: red → blue, wraps. Round bumped, units refreshed.
	tm_alt.end_alternating_activation()
	var alt_wrap_ok: bool = (
		tm_alt.active_faction() == "blue"
		and alt_turn_seen[0] == 2                                              # turn_number bumped 1 → 2
		and tm_alt._unit_states[alt_blue] == TurnManager.UnitState.READY       # refreshed
		and tm_alt._unit_states[alt_red] == TurnManager.UnitState.READY
	)
	if alt_mid_ok and alt_wrap_ok:
		print("OK  ALTERNATING: per-unit advance, round-wrap refreshes and bumps turn_number"); passed += 1
	else:
		print("FAIL ALTERNATING: mid_ok=%s wrap_ok=%s active=%s turn_seen=%d" % [
			alt_mid_ok, alt_wrap_ok, tm_alt.active_faction(), alt_turn_seen[0]])
		failed += 1

	# ---- WHOLE_PHASE: end_alternating_activation is a no-op (wrong mode) ----
	var tm_whole := TurnManager.new()
	root.add_child(tm_whole)
	tm_whole._turn_order = ["blue", "red"] as Array[String]
	tm_whole._activation_mode = "WHOLE_PHASE"
	tm_whole._active_faction_idx = 0
	tm_whole.end_alternating_activation()
	if tm_whole.active_faction() == "blue":
		print("OK  end_alternating_activation is a no-op in WHOLE_PHASE mode"); passed += 1
	else:
		print("FAIL ALT no-op: active=%s after call (want blue)" % tm_whole.active_faction())
		failed += 1

	# ---- start_map: factions read FactionData[] when turn_order isn't authored ----
	# Stage 3 lets MapData carry FactionData entries instead of a string list; the
	# scheduler then reads the order from those entries' ids.
	gs.reset_map_state()
	var fd_blue := FactionData.new(); fd_blue.id = "blue"
	var fd_red  := FactionData.new(); fd_red.id  = "red"
	var md_fd := MapData.new()
	md_fd.factions = [fd_blue, fd_red] as Array[FactionData]   # no turn_order
	var tm_fd := TurnManager.new()
	root.add_child(tm_fd)
	tm_fd.start_map(md_fd)
	if tm_fd._turn_order == (["blue", "red"] as Array[String]):
		print("OK  start_map: turn_order derived from MapData.factions when turn_order empty"); passed += 1
	else:
		print("FAIL fd-derived order: %s" % str(tm_fd._turn_order))
		failed += 1

	# ── M16 stage 2: per-group evaluator ────────────────────────────────────────
	# All blocks below use NEW victory_conditions / defeat_conditions dicts (NOT
	# the legacy fields) — the legacy fields keep their pre-M16 tests above. The
	# new evaluator must score the same plus the new rules (last-standing, draw,
	# elimination-round tracking).

	# ---- per-group victory: authored rout on allies group fires map_victory ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_v1"))
	gs.register_unit(_mk_unit("red", 0, "e_v1"))   # red unit dead
	var md_pg_v := MapData.new()
	var c_rout_red := ObjectiveCondition.new()
	c_rout_red.type = "rout"; c_rout_red.faction_id = "red"
	md_pg_v.victory_conditions = {"allies": [c_rout_red]}
	var tm_pg_v := TurnManager.new()
	root.add_child(tm_pg_v)
	tm_pg_v._map_data = md_pg_v
	victories[0] = 0
	tm_pg_v.check_victory_conditions()
	if victories[0] == 1:
		print("OK  per-group victory: authored rout(red) → map_victory"); passed += 1
	else:
		print("FAIL per-group victory: victories=%d" % victories[0]); failed += 1

	# ---- per-group defeat: authored protect fires map_defeat ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "grunt2"))   # protected id absent → defeat
	gs.register_unit(_mk_unit("red", 20, "e_d1"))      # red alive so no last-standing
	var md_pg_d := MapData.new()
	var c_prot := ObjectiveCondition.new()
	c_prot.type = "protect"; c_prot.unit_ids = ["hero_pg"] as Array[String]
	md_pg_d.defeat_conditions = {"allies": [c_prot]}
	var tm_pg_d := TurnManager.new()
	root.add_child(tm_pg_d)
	tm_pg_d._map_data = md_pg_d
	defeats[0] = 0
	tm_pg_d.check_victory_conditions()
	if defeats[0] == 1:
		print("OK  per-group defeat: authored protect (missing unit) → map_defeat"); passed += 1
	else:
		print("FAIL per-group defeat: defeats=%d" % defeats[0]); failed += 1

	# ---- ≤1 group remaining → last group standing wins (no authored victory) ----
	# Authored: foes have a protect condition on a missing unit → foes eliminated.
	# allies have NO conditions → implicit "group routed" defeat. allies has a live
	# blue → not routed → allies survives → last standing → allies wins → map_victory.
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_ls"))
	gs.register_unit(_mk_unit("red", 20, "e_ls"))      # red alive
	var md_ls := MapData.new()
	var c_prot_foes := ObjectiveCondition.new()
	c_prot_foes.type = "protect"; c_prot_foes.unit_ids = ["red_boss_ls"] as Array[String]
	md_ls.defeat_conditions = {"foes": [c_prot_foes]}
	var tm_ls := TurnManager.new()
	root.add_child(tm_ls)
	tm_ls._map_data = md_ls
	victories[0] = 0
	tm_ls.check_victory_conditions()
	if victories[0] == 1:
		print("OK  ≤1 group remaining: last-standing wins (map_victory)"); passed += 1
	else:
		print("FAIL last-standing: victories=%d defeats=%d" % [victories[0], defeats[0]]); failed += 1

	# ---- simultaneous elimination → draw → map_defeat (blue eliminated too) ----
	# Both factions have zero living units; both groups get the implicit routed
	# defeat. 0 in_play → draw → map_defeat.
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 0, "p_draw"))
	gs.register_unit(_mk_unit("red", 0, "e_draw"))
	var md_draw := MapData.new()                       # no conditions
	var tm_draw := TurnManager.new()
	root.add_child(tm_draw)
	tm_draw._map_data = md_draw
	victories[0] = 0; defeats[0] = 0
	tm_draw.check_victory_conditions()
	if defeats[0] == 1 and victories[0] == 0:
		print("OK  simultaneous wipe → draw → map_defeat (blue eliminated)"); passed += 1
	else:
		print("FAIL draw: V=%d D=%d" % [victories[0], defeats[0]]); failed += 1

	# ---- get_group_eliminated_round records the round a group fell ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_er"))
	gs.register_unit(_mk_unit("red", 0, "e_er"))       # red wiped on turn 1
	gs.turn_number = 1
	var md_er := MapData.new()                         # implicit defaults
	var tm_er := TurnManager.new()
	root.add_child(tm_er)
	tm_er._map_data = md_er
	tm_er.check_victory_conditions()                   # foes eliminated, allies wins
	if tm_er.get_group_eliminated_round("foes") == 1 \
			and tm_er.get_group_eliminated_round("allies") == -1:
		print("OK  get_group_eliminated_round: foes=1, allies=-1"); passed += 1
	else:
		print("FAIL elim-round: foes=%d allies=%d" % [
			tm_er.get_group_eliminated_round("foes"),
			tm_er.get_group_eliminated_round("allies"),
		]); failed += 1

	# ── M16 stage 3: defeat_boss / seize / escape / survive ─────────────────────

	# ---- defeat_boss victory: every named unit_id dead → map_victory ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_db"))
	gs.register_unit(_mk_unit("red", 0, "boss_db"))       # boss dead
	var md_db := MapData.new()
	var c_db := ObjectiveCondition.new()
	c_db.type = "defeat_boss"; c_db.unit_ids = ["boss_db"] as Array[String]
	md_db.victory_conditions = {"allies": [c_db]}
	var tm_db := TurnManager.new()
	root.add_child(tm_db)
	tm_db._map_data = md_db
	victories[0] = 0
	tm_db.check_victory_conditions()
	if victories[0] == 1:
		print("OK  defeat_boss: every named unit dead → map_victory"); passed += 1
	else:
		print("FAIL defeat_boss: victories=%d" % victories[0]); failed += 1

	# ---- survive victory: turn_number > turns → map_victory ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_sv"))
	gs.register_unit(_mk_unit("red", 20, "e_sv"))         # red alive — only the timer wins it
	gs.turn_number = 4
	var md_sv := MapData.new()
	var c_sv := ObjectiveCondition.new()
	c_sv.type = "survive"; c_sv.turns = 3
	md_sv.victory_conditions = {"allies": [c_sv]}
	var tm_sv := TurnManager.new()
	root.add_child(tm_sv)
	tm_sv._map_data = md_sv
	victories[0] = 0
	tm_sv.check_victory_conditions()
	if victories[0] == 1:
		print("OK  survive: turn_number > turns → map_victory"); passed += 1
	else:
		print("FAIL survive: victories=%d" % victories[0]); failed += 1

	# ---- record_seize: seize on a named tile by an allowed unit → map_victory ----
	gs.reset_map_state()
	var seizer := _mk_unit("blue", 20, "seizer")
	seizer.set("tile_position", Vector2i(2, 2))
	gs.register_unit(seizer)
	gs.register_unit(_mk_unit("red", 20, "e_seize"))      # red alive — seize is the win
	var md_se := MapData.new()
	var c_se := ObjectiveCondition.new()
	c_se.type = "seize"
	c_se.tiles = [Vector2i(2, 2)] as Array[Vector2i]
	c_se.allowed_unit_ids = ["seizer"] as Array[String]
	md_se.victory_conditions = {"allies": [c_se]}
	var tm_se := TurnManager.new()
	root.add_child(tm_se)
	tm_se._map_data = md_se
	victories[0] = 0
	tm_se.record_seize(seizer)
	if victories[0] == 1:
		print("OK  record_seize: allowed unit on tile → map_victory"); passed += 1
	else:
		print("FAIL record_seize: victories=%d" % victories[0]); failed += 1

	# ---- can_seize: allow-list gate hides Seize for the wrong unit_id ----
	gs.reset_map_state()
	var seizer_ok := _mk_unit("blue", 20, "lord")
	var seizer_no := _mk_unit("blue", 20, "knight")
	seizer_ok.set("tile_position", Vector2i(3, 3))
	seizer_no.set("tile_position", Vector2i(3, 3))
	gs.register_unit(seizer_ok)
	gs.register_unit(seizer_no)
	var md_cs := MapData.new()
	var c_cs := ObjectiveCondition.new()
	c_cs.type = "seize"
	c_cs.tiles = [Vector2i(3, 3)] as Array[Vector2i]
	c_cs.allowed_unit_ids = ["lord"] as Array[String]
	md_cs.victory_conditions = {"allies": [c_cs]}
	var tm_cs := TurnManager.new()
	root.add_child(tm_cs)
	tm_cs._map_data = md_cs
	if tm_cs.can_seize(seizer_ok, Vector2i(3, 3)) \
			and not tm_cs.can_seize(seizer_no, Vector2i(3, 3)) \
			and not tm_cs.can_seize(seizer_ok, Vector2i(0, 0)):
		print("OK  can_seize: allow-list + tile gate"); passed += 1
	else:
		print("FAIL can_seize gate (lord=%s knight=%s offtile=%s)" % [
			tm_cs.can_seize(seizer_ok, Vector2i(3, 3)),
			tm_cs.can_seize(seizer_no, Vector2i(3, 3)),
			tm_cs.can_seize(seizer_ok, Vector2i(0, 0)),
		]); failed += 1

	# ---- record_escape: every named unit escaped → map_victory ----
	gs.reset_map_state()
	var runner := _mk_unit("blue", 20, "runner")
	gs.register_unit(runner)
	gs.register_unit(_mk_unit("red", 20, "e_esc"))        # red alive — escape is the win
	var md_esc := MapData.new()
	var c_esc := ObjectiveCondition.new()
	c_esc.type = "escape"
	c_esc.tiles = [Vector2i(5, 5)] as Array[Vector2i]
	c_esc.unit_ids = ["runner"] as Array[String]
	md_esc.victory_conditions = {"allies": [c_esc]}
	var tm_esc := TurnManager.new()
	root.add_child(tm_esc)
	tm_esc._map_data = md_esc
	victories[0] = 0
	tm_esc.record_escape(runner)
	if victories[0] == 1 and tm_esc._has_unit_escaped("runner"):
		print("OK  record_escape: named unit escaped → map_victory"); passed += 1
	else:
		print("FAIL record_escape: victories=%d escaped=%s" % [victories[0], tm_esc._escape_records]); failed += 1

	# ---- escape exclusion in protect: an escaped id doesn't trigger protect-fail ----
	gs.reset_map_state()
	var prot_unit := _mk_unit("blue", 20, "vip")
	gs.register_unit(prot_unit)
	gs.register_unit(_mk_unit("red", 20, "e_prot"))       # red alive
	var md_xp := MapData.new()
	var c_xp_prot := ObjectiveCondition.new()
	c_xp_prot.type = "protect"; c_xp_prot.unit_ids = ["vip"] as Array[String]
	md_xp.defeat_conditions = {"allies": [c_xp_prot]}
	var tm_xp := TurnManager.new()
	root.add_child(tm_xp)
	tm_xp._map_data = md_xp
	defeats[0] = 0
	tm_xp.record_escape(prot_unit)                        # vip leaves the map alive
	if defeats[0] == 0:
		print("OK  escape exclusion: escaped vip doesn't fail protect"); passed += 1
	else:
		print("FAIL escape exclusion: defeats=%d (should be 0)" % defeats[0]); failed += 1

	# ---- _on_unit_moved auto-escapes a named unit entering the zone ----
	gs.reset_map_state()
	var auto_run := _mk_unit("blue", 20, "auto_runner")
	gs.register_unit(auto_run)
	gs.register_unit(_mk_unit("red", 20, "e_auto"))       # red alive
	var md_auto := MapData.new()
	var c_auto := ObjectiveCondition.new()
	c_auto.type = "escape"
	c_auto.tiles = [Vector2i(7, 7)] as Array[Vector2i]
	c_auto.unit_ids = ["auto_runner"] as Array[String]
	md_auto.victory_conditions = {"allies": [c_auto]}
	var tm_auto_esc := TurnManager.new()
	root.add_child(tm_auto_esc)
	tm_auto_esc._map_data = md_auto
	victories[0] = 0
	# Simulate the EventBus.unit_moved signal payload directly — the real
	# emission happens inside Unit.move_along_path which isn't reachable from
	# the headless stub. Same shape: (unit, from_tile, to_tile).
	tm_auto_esc._on_unit_moved(auto_run, Vector2i(6, 7), Vector2i(7, 7))
	if victories[0] == 1 and tm_auto_esc._has_unit_escaped("auto_runner"):
		print("OK  _on_unit_moved: auto-escape on zone entry → map_victory"); passed += 1
	else:
		print("FAIL auto-escape: victories=%d escaped=%s" % [victories[0], tm_auto_esc._escape_records]); failed += 1

	# ── M16 stage 4: map_resolved standings emission ────────────────────────────

	# Capture the most recent map_resolved payload so each assertion below can
	# inspect it. Connected once; tests reset the slot to track which fires when.
	var resolved: Array = [{}]
	bus.map_resolved.connect(func(w, s):
		resolved[0] = {"winner": w, "standings": s}
	)

	# ---- map_resolved: blue victory → standings rank 1 = allies (you) ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_st"))
	gs.register_unit(_mk_unit("red", 0, "e_st"))           # red wiped → blue wins
	gs.turn_number = 2
	var md_st := MapData.new()
	md_st.objective_type = "rout"
	var tm_st := TurnManager.new()
	root.add_child(tm_st)
	tm_st._map_data = md_st
	resolved[0] = {}
	tm_st.check_victory_conditions()
	var st_ok: bool = (resolved[0].get("winner", "") == "allies"
			and resolved[0].get("standings", []).size() == 2)
	if st_ok:
		var top = resolved[0]["standings"][0]
		var bottom = resolved[0]["standings"][1]
		st_ok = st_ok and top["rank"] == 1 and top["group"] == "allies" \
				and top["is_blue_group"] == true \
				and bottom["rank"] == 2 and bottom["group"] == "foes" \
				and bottom["eliminated_round"] == 2
	if st_ok:
		print("OK  map_resolved: blue victory standings (allies #1, foes #2 elim turn 2)")
		passed += 1
	else:
		print("FAIL map_resolved blue-victory standings: %s" % str(resolved[0]))
		failed += 1

	# ---- map_resolved: draw → winner="" and DRAW header ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 0, "p_draw2"))
	gs.register_unit(_mk_unit("red", 0, "e_draw2"))
	var tm_dr := TurnManager.new()
	root.add_child(tm_dr)
	tm_dr._map_data = MapData.new()
	resolved[0] = {}
	tm_dr.check_victory_conditions()
	if resolved[0].get("winner", "_") == "" and resolved[0].get("standings", []).size() == 2:
		print("OK  map_resolved: draw → winner=\"\", both groups in standings"); passed += 1
	else:
		print("FAIL draw standings: %s" % str(resolved[0])); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
