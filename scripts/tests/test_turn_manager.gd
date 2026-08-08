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
	_unit_stub.source_code = 'extends Node\nvar team: String = "player"\nvar data = null\nvar tile_position: Vector2i = Vector2i.ZERO\nfunc snap_to_tile(t): tile_position = t\n'
	_unit_stub.reload()

	# Real GameState + EventBus autoload scripts at /root so TurnManager resolves them.
	var gs: Node = load("res://scripts/autoloads/GameState.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	var bus: Node = load("res://scripts/autoloads/EventBus.gd").new()
	bus.name = "EventBus"
	root.add_child(bus)
	var pair_reg: Node = load("res://scripts/autoloads/PairUpRegistry.gd").new()
	pair_reg.name = "PairUpRegistry"
	root.add_child(pair_reg)
	var registry: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	registry.name = "RegistryManager"
	root.add_child(registry)
	var ledger: Node = load("res://scripts/autoloads/ResourceLedger.gd").new()
	ledger.name = "ResourceLedger"
	root.add_child(ledger)
	await process_frame

	# Victory/defeat emission counters (Arrays — captured by reference by the lambdas).
	var victories := [0]
	var defeats := [0]
	bus.map_victory.connect(func(): victories[0] += 1)
	bus.map_defeat.connect(func(): defeats[0] += 1)

	# ---- victory reward credits the existing party wallet through the ledger ----
	var reward_tm := TurnManager.new()
	root.add_child(reward_tm)
	var reward_map := MapData.new()
	reward_map.reward_gold = 75
	reward_map.reward_items = ["vulnerary"] as Array[String]
	reward_tm._map_data = reward_map
	gs.party_gold = 25
	gs.party_items.clear()
	var reward_receipt: Dictionary = reward_tm._apply_victory_rewards(gs)
	if (
		gs.party_gold == 100
		and gs.party_items == ["vulnerary"]
		and reward_receipt == {"gold_earned": 75, "total_gold": 100, "items_awarded": ["vulnerary"]}
	):
		print("OK  victory reward preserves gold credit and item append behavior")
		passed += 1
	else:
		print("FAIL victory reward: gold=%d items=%s" % [gs.party_gold, gs.party_items])
		failed += 1
	reward_map.reward_gold = 0
	reward_map.reward_items.clear()
	var zero_receipt: Dictionary = reward_tm._apply_victory_rewards(gs)
	if zero_receipt.gold_earned == 0 and zero_receipt.total_gold == 100:
		print("OK  zero-gold victory produces an honest committed receipt")
		passed += 1
	else:
		print("FAIL zero reward receipt: %s" % zero_receipt)
		failed += 1

	# ---- get_unit_state defaults to READY for an unregistered unit ----
	var tm := TurnManager.new()
	root.add_child(tm)
	var u1 := _mk_unit("blue", 20, "u1")
	if tm.get_unit_state(u1) == TurnManager.UnitState.READY:
		print("OK  get_unit_state defaults to READY")
		passed += 1
	else:
		print("FAIL get_unit_state default")
		failed += 1

	# ---- set_unit_state / get_unit_state round-trip ----
	tm.set_unit_state(u1, TurnManager.UnitState.MOVED)
	var moved_ok: bool = tm.get_unit_state(u1) == TurnManager.UnitState.MOVED
	tm.set_unit_state(u1, TurnManager.UnitState.DONE)
	if moved_ok and tm.get_unit_state(u1) == TurnManager.UnitState.DONE:
		print("OK  set_unit_state / get_unit_state round-trip")
		passed += 1
	else:
		print("FAIL set/get_unit_state")
		failed += 1

	# ---- can_unit_act: READY and MOVED yes, DONE no ----
	tm.set_unit_state(u1, TurnManager.UnitState.READY)
	var act_ready: bool = tm.can_unit_act(u1)
	tm.set_unit_state(u1, TurnManager.UnitState.MOVED)
	var act_moved: bool = tm.can_unit_act(u1)
	tm.set_unit_state(u1, TurnManager.UnitState.DONE)
	var act_done: bool = tm.can_unit_act(u1)
	if act_ready and act_moved and not act_done:
		print("OK  can_unit_act: READY/MOVED true, DONE false")
		passed += 1
	else:
		print("FAIL can_unit_act: ready=%s moved=%s done=%s" % [act_ready, act_moved, act_done])
		failed += 1

	# ---- manual End Turn commits one ordered Wait/history boundary per unit ----
	var batch_script := GDScript.new()
	batch_script.source_code = (
		'extends "res://scripts/core/TurnManager.gd"\n'
		+ "var pushed: Array[Dictionary] = []\n"
		+ "var phase_requests := 0\n"
		+ 'func _push_history(reason: String, metadata: Dictionary = {}) -> void: pushed.append({"reason": reason, "metadata": metadata.duplicate(true)})\n'
		+ "func request_end_phase() -> void: phase_requests += 1\n"
	)
	batch_script.reload()
	var batch_tm: Node = batch_script.new()
	root.add_child(batch_tm)
	batch_tm._turn_order = ["blue"] as Array[String]
	var batch_a := _mk_unit("blue", 20, "batch_a")
	var batch_b := _mk_unit("blue", 20, "batch_b")
	batch_tm.commit_remaining_waits("blue", [batch_b, batch_a] as Array[Node])
	if (
		batch_tm.get_unit_state(batch_a) == TurnManager.UnitState.DONE
		and batch_tm.get_unit_state(batch_b) == TurnManager.UnitState.DONE
		and batch_tm.pushed.size() == 2
		and batch_tm.pushed[0].metadata.unit_id == "batch_b"
		and batch_tm.pushed[1].metadata.unit_id == "batch_a"
		and batch_tm.phase_requests == 1
	):
		print("OK  manual End Turn commits ordered Wait boundaries before one phase request")
		passed += 1
	else:
		print(
			(
				"FAIL manual End Turn batch: pushes=%s requests=%s"
				% [batch_tm.pushed, batch_tm.phase_requests]
			)
		)
		failed += 1

	# ---- record_move_start + undo_move: restores tile and resets to READY ----
	var u2 := _mk_unit("blue", 20, "u2")
	u2.set("tile_position", Vector2i(3, 4))
	tm.record_move_start(u2)
	u2.set("tile_position", Vector2i(7, 8))  # simulate a move
	tm.set_unit_state(u2, TurnManager.UnitState.MOVED)
	tm.undo_move(u2)
	if u2.tile_position == Vector2i(3, 4) and tm.get_unit_state(u2) == TurnManager.UnitState.READY:
		print("OK  record_move_start + undo_move restores tile and state")
		passed += 1
	else:
		print("FAIL undo_move: tile=%s state=%d" % [str(u2.tile_position), tm.get_unit_state(u2)])
		failed += 1

	# ---- _on_unit_died erases the unit from _unit_states ----
	tm.set_unit_state(u1, TurnManager.UnitState.DONE)
	tm._on_unit_died(u1)
	if not tm._unit_states.has(u1):
		print("OK  _on_unit_died erases the unit from _unit_states")
		passed += 1
	else:
		print("FAIL _on_unit_died")
		failed += 1

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
		print("OK  are_all_player_units_done: true when all are DONE")
		passed += 1
	else:
		print("FAIL are_all_player_units_done (all done)")
		failed += 1

	# ---- are_all_player_units_done: false when one is still able to act ----
	tm2.set_unit_state(d2, TurnManager.UnitState.READY)
	if not tm2.are_all_player_units_done():
		print("OK  are_all_player_units_done: false when one can still act")
		passed += 1
	else:
		print("FAIL are_all_player_units_done (one ready)")
		failed += 1

	# ---- are_all_units_done: works for any faction bucket ----
	var d3 := _mk_unit("red", 20, "d3")
	gs.register_unit(d3)
	tm2.set_unit_state(d3, TurnManager.UnitState.DONE)
	var all_red_done: bool = tm2.are_all_units_done("red")
	tm2.set_unit_state(d3, TurnManager.UnitState.READY)
	var red_ready_blocks: bool = not tm2.are_all_units_done("red")
	if all_red_done and red_ready_blocks:
		print("OK  are_all_units_done: checks arbitrary faction buckets")
		passed += 1
	else:
		print(
			(
				"FAIL are_all_units_done: all_red_done=%s red_ready_blocks=%s"
				% [all_red_done, red_ready_blocks]
			)
		)
		failed += 1

	# ---- paired support doesn't block are_all_units_done across a round boundary ----
	# Code review 2026-06-09: a paired support left over from the previous round
	# was being reset to READY by _refresh_faction_units and counted as actable.
	# After the filter lands in GameState.get_living_units_of the lead is the
	# only blue unit reported, and a DONE lead alone reports the phase as ended.
	gs.reset_map_state()
	pair_reg.call("clear")
	var pp_lead := _mk_unit("blue", 20, "pp_lead")
	var pp_support := _mk_unit("blue", 20, "pp_support")
	pp_support.set("tile_position", pair_reg.OFF_MAP_TILE)
	gs.register_unit(pp_lead)
	gs.register_unit(pp_support)
	pair_reg.pair("pp_lead", "pp_support")
	var tm_pp := TurnManager.new()
	root.add_child(tm_pp)
	tm_pp._refresh_faction_units("blue")
	tm_pp.set_unit_state(pp_lead, TurnManager.UnitState.DONE)
	if tm_pp.are_all_units_done("blue"):
		print("OK  paired support does not block are_all_units_done across rounds")
		passed += 1
	else:
		print("FAIL paired support blocks are_all_units_done")
		failed += 1

	# ---- check_victory_conditions: rout authored on allies → map_victory ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p1"))
	var md_rout := MapData.new()
	var c_rout_all := ObjectiveCondition.new()
	c_rout_all.type = "rout"  # faction_id "" = all hostiles
	md_rout.victory_conditions = {"allies": [c_rout_all]}
	var c_rout_allies := ObjectiveCondition.new()
	c_rout_allies.type = "rout"
	c_rout_allies.faction_id = "allies"
	md_rout.defeat_conditions = {"allies": [c_rout_allies]}
	var tm_v := TurnManager.new()
	root.add_child(tm_v)
	tm_v._map_data = md_rout
	victories[0] = 0
	tm_v.check_victory_conditions()
	if victories[0] == 1:
		print("OK  check_victory_conditions: rout(all hostiles) + no enemies → map_victory")
		passed += 1
	else:
		print("FAIL victory rout: victories=%d" % victories[0])
		failed += 1

	# ---- check_victory_conditions: _map_over latches → no double emit ----
	tm_v.check_victory_conditions()
	if victories[0] == 1:
		print("OK  check_victory_conditions: _map_over prevents a second emit")
		passed += 1
	else:
		print("FAIL victory double-emit: victories=%d" % victories[0])
		failed += 1

	# ---- check_victory_conditions: authored allied Rout defeat → map_defeat ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("red", 20, "e1"))
	gs.register_unit(_mk_unit("blue", 0, "p2"))
	var tm_d := TurnManager.new()
	root.add_child(tm_d)
	tm_d._map_data = md_rout
	defeats[0] = 0
	tm_d.check_victory_conditions()
	if defeats[0] == 1:
		print("OK  check_victory_conditions: authored allied Rout → map_defeat")
		passed += 1
	else:
		print("FAIL defeat all-dead: defeats=%d" % defeats[0])
		failed += 1

	# ---- rout counts paired supports as living (playtest v0.1.4 #4) ----
	# _eval_rout used get_living_units_of, which excludes off-map supports, so an
	# allied Rout could resolve while a hidden support was still alive. With a dead
	# lead and a LIVING off-map support, allied Rout must NOT fire; once the support
	# also dies, it must fire.
	gs.reset_map_state()
	pair_reg.call("clear")
	var rd_lead := _mk_unit("blue", 0, "rd_lead")  # lead already dead
	var rd_support := _mk_unit("blue", 20, "rd_support")  # support alive, off-map
	rd_support.set("tile_position", pair_reg.OFF_MAP_TILE)
	gs.register_unit(rd_lead)
	gs.register_unit(rd_support)
	pair_reg.pair("rd_lead", "rd_support")  # rd_support is the support
	gs.register_unit(_mk_unit("red", 20, "rd_e1"))  # keep a hostile alive (no victory)
	var tm_rs := TurnManager.new()
	root.add_child(tm_rs)
	tm_rs._map_data = md_rout
	defeats[0] = 0
	tm_rs.check_victory_conditions()
	var support_alive_no_defeat: bool = defeats[0] == 0
	# Now the support dies too → allies are truly routed → defeat fires.
	rd_support.data.hp = 0
	tm_rs._map_over = false
	defeats[0] = 0
	tm_rs.check_victory_conditions()
	var support_dead_defeat: bool = defeats[0] == 1
	if support_alive_no_defeat and support_dead_defeat:
		print(
			"OK  rout counts paired supports: alive support blocks defeat, dead support allows it"
		)
		passed += 1
	else:
		print(
			(
				"FAIL rout support liveness: no_defeat_while_alive=%s defeat_when_dead=%s"
				% [support_alive_no_defeat, support_dead_defeat]
			)
		)
		failed += 1

	# ---- check_victory_conditions: turn_limit defeat on allies → map_defeat ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p3"))
	gs.turn_number = 4
	var md_limit := MapData.new()
	var c_limit := ObjectiveCondition.new()
	c_limit.type = "turn_limit"
	c_limit.turns = 3
	md_limit.defeat_conditions = {"allies": [c_limit]}
	var tm_t := TurnManager.new()
	root.add_child(tm_t)
	tm_t._map_data = md_limit
	defeats[0] = 0
	tm_t.check_victory_conditions()
	if defeats[0] == 1:
		print("OK  check_victory_conditions: turn_limit defeat → map_defeat")
		passed += 1
	else:
		print("FAIL defeat turn-limit: defeats=%d" % defeats[0])
		failed += 1

	# ---- check_victory_conditions: protect (missing named survivor) → map_defeat ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("red", 20, "e2"))
	gs.register_unit(_mk_unit("blue", 20, "grunt"))
	var md_surv := MapData.new()
	var c_prot_hero := ObjectiveCondition.new()
	c_prot_hero.type = "protect"
	c_prot_hero.unit_ids = ["hero"] as Array[String]
	md_surv.defeat_conditions = {"allies": [c_prot_hero]}
	var tm_s := TurnManager.new()
	root.add_child(tm_s)
	tm_s._map_data = md_surv
	defeats[0] = 0
	tm_s.check_victory_conditions()
	if defeats[0] == 1:
		print("OK  check_victory_conditions: protect (missing) → map_defeat")
		passed += 1
	else:
		print("FAIL defeat survivor: defeats=%d" % defeats[0])
		failed += 1

	# ---- check_victory_conditions: null _map_data is a no-op ----
	var tm_n := TurnManager.new()
	root.add_child(tm_n)
	victories[0] = 0
	defeats[0] = 0
	tm_n.check_victory_conditions()
	if victories[0] == 0 and defeats[0] == 0:
		print("OK  check_victory_conditions: null _map_data is a no-op")
		passed += 1
	else:
		print("FAIL victory null-mapdata")
		failed += 1

	# ---- WHOLE_PHASE: round increments only after every faction phase ----
	gs.reset_map_state()  # turn_number → 1
	var round_blue := _mk_unit("blue", 20, "round_blue")
	var round_red := _mk_unit("red", 20, "round_red")
	gs.register_unit(round_blue)
	gs.register_unit(round_red)
	var tm_e := TurnManager.new()
	root.add_child(tm_e)
	var md_round := MapData.new()
	md_round.turn_order = ["blue", "red"] as Array[String]
	tm_e._map_data = md_round
	tm_e._turn_order = md_round.turn_order.duplicate()
	var round_ai_script := GDScript.new()
	round_ai_script.source_code = "extends Node\nvar game_state: Node\nvar observed_turns: Array[int] = []\nfunc run_phase(_grid, _turn, _faction_id: String) -> void:\n\tobserved_turns.append(game_state.turn_number)\n"
	round_ai_script.reload()
	var round_ai: Node = round_ai_script.new()
	round_ai.set("game_state", gs)
	tm_e.set_ai_controller(round_ai)
	var turn_seen := [0]
	tm_e.turn_changed.connect(func(n): turn_seen[0] = n)
	await tm_e.start_enemy_phase()
	if round_ai.get("observed_turns") == [1] and gs.turn_number == 2 and turn_seen[0] == 2:
		print("OK  WHOLE_PHASE: enemy acts on turn 1; cycle wrap advances to turn 2")
		passed += 1
	else:
		print(
			(
				"FAIL WHOLE_PHASE round timing: observed=%s turn=%d signal=%d"
				% [str(round_ai.get("observed_turns")), gs.turn_number, turn_seen[0]]
			)
		)
		failed += 1

	# ---- start_player_phase: resets a DONE player unit back to READY ----
	var tm_p := TurnManager.new()
	root.add_child(tm_p)
	var rp := _mk_unit("blue", 20, "rp")
	tm_p.set_unit_state(rp, TurnManager.UnitState.DONE)
	tm_p.start_player_phase()
	if tm_p.get_unit_state(rp) == TurnManager.UnitState.READY:
		print("OK  start_player_phase: a DONE player unit is reset to READY")
		passed += 1
	else:
		print("FAIL start_player_phase reset: state=%d" % tm_p.get_unit_state(rp))
		failed += 1

	# Flush any deferred _auto_end_player_phase calls queued by earlier blocks.
	await process_frame

	# ---- set_unit_state DONE on the last player unit auto-ends the phase (#5) ----
	gs.reset_map_state()
	gs.set_phase(gs.Phase.PLAYER)
	var a1 := _mk_unit("blue", 20, "a1")
	gs.register_unit(a1)
	var tm_auto := TurnManager.new()
	root.add_child(tm_auto)
	tm_auto._map_data = MapData.new()
	tm_auto._turn_order = ["blue"] as Array[String]
	var auto_seen := [0]
	tm_auto.turn_changed.connect(func(n): auto_seen[0] = n)
	tm_auto.set_unit_state(a1, TurnManager.UnitState.DONE)
	await process_frame  # let the deferred _auto_end_player_phase run
	if auto_seen[0] != 0:
		print("OK  last player unit DONE auto-ends the phase (#5)")
		passed += 1
	else:
		print("FAIL auto-end did not fire")
		failed += 1

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
	tm_partial.set_unit_state(b1, TurnManager.UnitState.DONE)  # b2 still READY
	await process_frame
	if partial_seen[0] == 0:
		print("OK  auto-end holds while a unit can still act")
		passed += 1
	else:
		print("FAIL auto-end fired early: turn_changed=%d" % partial_seen[0])
		failed += 1

	# ---- request_end_phase: blue falls through to end_player_phase ----
	gs.reset_map_state()
	gs.set_phase(gs.Phase.PLAYER)
	var tm_req_blue := TurnManager.new()
	root.add_child(tm_req_blue)
	tm_req_blue._map_data = MapData.new()
	tm_req_blue._turn_order = ["blue"] as Array[String]
	var req_blue_seen := [0]
	tm_req_blue.turn_changed.connect(func(n): req_blue_seen[0] = n)
	tm_req_blue.request_end_phase()
	if req_blue_seen[0] != 0:
		print("OK  request_end_phase: blue commits through end_player_phase")
		passed += 1
	else:
		print("FAIL request_end_phase blue: turn_changed=%d" % req_blue_seen[0])
		failed += 1

	# ---- request_end_phase: hotseat commits by signal instead of blue logic ----
	var tm_req_hot := TurnManager.new()
	root.add_child(tm_req_hot)
	var md_req_hot := MapData.new()
	var hotseat_faction := FactionData.new()
	hotseat_faction.id = "green"
	hotseat_faction.controller = "HOTSEAT"
	md_req_hot.factions = [hotseat_faction]
	tm_req_hot._map_data = md_req_hot
	tm_req_hot._turn_order = ["green"] as Array[String]
	var hotseat_commit_seen := [0]
	tm_req_hot.phase_committed.connect(func(): hotseat_commit_seen[0] += 1)
	tm_req_hot.request_end_phase()
	if hotseat_commit_seen[0] == 1:
		print("OK  request_end_phase: hotseat commits by emitting phase_committed")
		passed += 1
	else:
		print("FAIL request_end_phase hotseat: commits=%d" % hotseat_commit_seen[0])
		failed += 1

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
		print("OK  _auto_end_player_phase is a no-op once the map is over")
		passed += 1
	else:
		print("FAIL auto-end ran after map over: turn_changed=%d" % over_seen[0])
		failed += 1

	# ---- a death that leaves every player unit DONE auto-ends the phase (#5) ----
	# Mutual kill: the last unit to act dies on its own action, so set_unit_state
	# never marks it DONE — _on_unit_died must still trigger the auto-end.
	gs.reset_map_state()
	gs.set_phase(gs.Phase.PLAYER)
	var done_unit := _mk_unit("blue", 20, "done1")
	var dying_unit := _mk_unit("blue", 20, "dying1")
	gs.register_unit(done_unit)
	gs.register_unit(dying_unit)
	gs.register_unit(_mk_unit("red", 20, "foe1"))  # living enemy → no rout victory
	var tm_death := TurnManager.new()
	root.add_child(tm_death)
	var md_death := MapData.new()
	var c_death_rout := ObjectiveCondition.new()
	c_death_rout.type = "rout"
	md_death.victory_conditions = {"allies": [c_death_rout]}
	tm_death._map_data = md_death
	tm_death._turn_order = ["blue", "red"] as Array[String]
	tm_death.set_unit_state(done_unit, TurnManager.UnitState.DONE)
	var death_seen := [0]
	tm_death.turn_changed.connect(func(n): death_seen[0] = n)
	dying_unit.data.hp = 0  # the mutual-kill death
	tm_death._on_unit_died(dying_unit)
	await process_frame
	if death_seen[0] != 0:
		print("OK  a mutual-kill death auto-ends the phase when others are DONE")
		passed += 1
	else:
		print("FAIL no auto-end after last-unit death")
		failed += 1

	# ---- auto-end honours the SettingsManager toggle (#2) ----
	var sm := root.get_node_or_null("SettingsManager")
	if sm != null:
		gs.reset_map_state()
		gs.set_phase(gs.Phase.PLAYER)
		var solo := _mk_unit("blue", 20, "solo1")
		gs.register_unit(solo)
		var tm_toggle := TurnManager.new()
		root.add_child(tm_toggle)
		tm_toggle._map_data = MapData.new()
		tm_toggle._turn_order = ["blue"] as Array[String]
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
			print("OK  auto-end respects the SettingsManager toggle (#2)")
			passed += 1
		else:
			print("FAIL auto-end toggle: held=%s ended=%s" % [held, ended])
			failed += 1
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
		print("OK  start_map: default turn_order blue→green→red→yellow, WHOLE_PHASE, blue first")
		passed += 1
	else:
		print(
			(
				"FAIL default turn_order: order=%s mode=%s active=%s"
				% [tm_default._turn_order, tm_default._activation_mode, tm_default.active_faction()]
			)
		)
		failed += 1

	# ---- start_map: MapData.turn_order overrides the default ----
	gs.reset_map_state()
	var md_custom := MapData.new()
	md_custom.turn_order = ["red", "blue"] as Array[String]  # red moves first
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
		print("OK  start_map: MapData.turn_order + activation_mode override the defaults")
		passed += 1
	else:
		print(
			(
				"FAIL custom turn_order: order=%s mode=%s active=%s"
				% [tm_custom._turn_order, tm_custom._activation_mode, tm_custom.active_faction()]
			)
		)
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
		print("OK  _advance_faction: skips zero-unit factions in the cycle")
		passed += 1
	else:
		print(
			"FAIL skip-zero: wrapped=%s active=%s (want false / red)" % [skip_wrapped, skip_active]
		)
		failed += 1

	# ---- _advance_faction: wraps past the end and reports it ----
	# Now on red (idx 2). One more advance must wrap → blue (idx 0), wrapped=true.
	var wrap_result: bool = tm_skip._advance_faction()
	var wrap_active: String = tm_skip.active_faction()
	if wrap_result and wrap_active == "blue":
		print("OK  _advance_faction: wraps past end of turn_order and reports it")
		passed += 1
	else:
		print("FAIL wrap: wrapped=%s active=%s (want true / blue)" % [wrap_result, wrap_active])
		failed += 1

	# ---- M15 Part A: start_enemy_phase routes HOTSEAT then AI controllers ----
	gs.reset_map_state()
	var c3_b := _mk_unit("blue", 20, "c3_b")
	var c3_g := _mk_unit("green", 20, "c3_g")
	var c3_r := _mk_unit("red", 20, "c3_r")
	gs.register_unit(c3_b)
	gs.register_unit(c3_g)
	gs.register_unit(c3_r)
	var tm_c3 := TurnManager.new()
	root.add_child(tm_c3)
	var md_c3 := MapData.new()
	var c3_green := FactionData.new()
	c3_green.id = "green"
	c3_green.controller = "HOTSEAT"
	var c3_red := FactionData.new()
	c3_red.id = "red"
	c3_red.controller = "AI"
	md_c3.factions = [c3_green, c3_red]
	md_c3.turn_order = ["blue", "green", "red"] as Array[String]
	tm_c3.start_map(md_c3)
	var ai_stub_script := GDScript.new()
	ai_stub_script.source_code = "extends Node\nvar calls: Array[String] = []\nfunc run_phase(_grid, _turn, faction_id: String) -> void:\n\tcalls.append(faction_id)\n"
	ai_stub_script.reload()
	var ai_stub: Node = ai_stub_script.new()
	var hotseat_stub_script := GDScript.new()
	hotseat_stub_script.source_code = "extends Node\nvar calls: Array[String] = []\nfunc run_phase(_grid, turn, faction_id: String) -> void:\n\tcalls.append(faction_id)\n\tturn.phase_committed.emit()\n"
	hotseat_stub_script.reload()
	var hotseat_stub: Node = hotseat_stub_script.new()
	tm_c3.set_ai_controller(ai_stub)
	tm_c3.set_hotseat_controller(hotseat_stub)
	tm_c3._unit_states[c3_g] = TurnManager.UnitState.DONE
	await tm_c3.start_enemy_phase()
	var c3_calls: Array = ai_stub.get("calls")
	var c3_hotseat_calls: Array = hotseat_stub.get("calls")
	if (
		c3_hotseat_calls == ["green"]
		and c3_calls == ["red"]
		and tm_c3.active_faction() == "blue"
		and gs.is_player_turn()
		and tm_c3.get_unit_state(c3_g) == TurnManager.UnitState.READY
	):
		print("OK  start_enemy_phase: HOTSEAT then AI controllers run before blue resumes")
		passed += 1
	else:
		print(
			(
				"FAIL controller loop: hotseat=%s ai=%s active=%s phase=%s green_state=%s"
				% [
					str(c3_hotseat_calls),
					str(c3_calls),
					tm_c3.active_faction(),
					gs.current_phase,
					tm_c3.get_unit_state(c3_g)
				]
			)
		)
		failed += 1

	# ---- V070-04: is_locally_played_faction is OWNERSHIP, not phase ----
	# Reuses tm_c3 above, which already has a HOTSEAT green and an AI red.
	# Notifications (the level-up screen) need "who plays this faction", not "is it
	# their turn". Reusing is_locally_controlled_faction would have suppressed the
	# level-up screen for a blue unit that counterattacks during the enemy phase — a
	# regression on today's behaviour. This pins the difference between the two
	# predicates so they cannot be quietly collapsed into one later.
	var played_ok: bool = (
		tm_c3.is_locally_played_faction("blue")
		and tm_c3.is_locally_played_faction("green")  # HOTSEAT
		and not tm_c3.is_locally_played_faction("red")  # AI
		and not tm_c3.is_locally_played_faction("")
	)
	var lp_phase_before: int = gs.current_phase
	gs.set_phase(gs.Phase.ENEMY)
	# Blue is still PLAYED by the local human while it is not their phase; the
	# phase-sensitive predicate correctly says otherwise. That gap is the point.
	var survives_enemy_phase: bool = (
		tm_c3.is_locally_played_faction("blue") and not tm_c3.is_locally_controlled_faction("blue")
	)
	gs.set_phase(lp_phase_before)
	if played_ok and survives_enemy_phase:
		print("OK  is_locally_played_faction tracks ownership, not whose phase it is")
		passed += 1
	else:
		print(
			(
				"FAIL is_locally_played_faction: ownership=%s survives_enemy_phase=%s"
				% [played_ok, survives_enemy_phase]
			)
		)
		failed += 1

	# ---- AI suspend seals one history entry and captures once at the boundary ----
	gs.reset_map_state()
	var suspend_red := _mk_unit("red", 20, "suspend_red")
	gs.register_unit(suspend_red)
	var tm_suspend_ai := TurnManager.new()
	root.add_child(tm_suspend_ai)
	var md_suspend_ai := MapData.new()
	var suspend_ai_faction := FactionData.new()
	suspend_ai_faction.id = "red"
	suspend_ai_faction.controller = "AI"
	md_suspend_ai.factions = [suspend_ai_faction]
	tm_suspend_ai._map_data = md_suspend_ai
	tm_suspend_ai._turn_order = ["blue", "red"] as Array[String]
	tm_suspend_ai._active_faction_idx = 1
	var suspend_cursor_script := GDScript.new()
	suspend_cursor_script.source_code = (
		"extends Node\nvar saves := 0\n"
		+ "func capture_suspend_ui_state() -> Dictionary: return {}\n"
		+ "func perform_pending_ai_suspend() -> bool:\n"
		+ "\tsaves += 1\n\treturn true\n"
	)
	suspend_cursor_script.reload()
	var suspend_cursor: Node = suspend_cursor_script.new()
	root.add_child(suspend_cursor)
	tm_suspend_ai.set_history_cursor(suspend_cursor)
	var history_before: int = int(gs.history_size())
	tm_suspend_ai.set_unit_state(suspend_red, TurnManager.UnitState.DONE)
	var request_accepted := tm_suspend_ai.request_suspend_after_ai_activation()
	var stopped_at_boundary := tm_suspend_ai.complete_ai_activation_boundary()
	var captured_state := tm_suspend_ai.capture_suspend_turn_state()
	await process_frame  # queued history callback must now be a no-op
	var history_after: int = int(gs.history_size())
	if (
		request_accepted
		and stopped_at_boundary
		and suspend_cursor.get("saves") == 1
		and history_after == history_before + 1
		and String(captured_state.get("controller_boundary", "")) == "between_ai_activations"
	):
		print("OK  AI suspend seals one ledger entry and captures once at the boundary")
		passed += 1
	else:
		print("FAIL AI suspend boundary: state=%s" % [captured_state])
		failed += 1

	# ---- failed write clears the request and leaves the AI phase runnable ----
	var failed_cursor_script := GDScript.new()
	failed_cursor_script.source_code = ("extends Node\nfunc perform_pending_ai_suspend() -> bool: return false\n")
	failed_cursor_script.reload()
	var failed_cursor: Node = failed_cursor_script.new()
	root.add_child(failed_cursor)
	tm_suspend_ai._ai_suspend_exit_pending = false
	tm_suspend_ai.set_history_cursor(failed_cursor)
	var retry_requested := tm_suspend_ai.request_suspend_after_ai_activation()
	var incorrectly_stopped := tm_suspend_ai.complete_ai_activation_boundary()
	if (
		retry_requested
		and not incorrectly_stopped
		and not tm_suspend_ai.has_pending_ai_suspend()
		and String(tm_suspend_ai.capture_suspend_turn_state()["controller_boundary"]) == ""
	):
		print("OK  failed AI suspend write clears the intent and leaves play runnable")
		passed += 1
	else:
		print("FAIL failed-write AI suspend recovery")
		failed += 1

	# ---- a committed outcome cancels a request instead of writing a stale battle ----
	tm_suspend_ai._map_over = false
	var outcome_request := tm_suspend_ai.request_suspend_after_ai_activation()
	tm_suspend_ai._map_over = true
	var outcome_capture := tm_suspend_ai.complete_ai_activation_boundary()
	if outcome_request and not outcome_capture and not tm_suspend_ai.has_pending_ai_suspend():
		print("OK  map outcome cancels a pending AI suspend")
		passed += 1
	else:
		print("FAIL map outcome left an AI suspend pending")
		failed += 1

	# ---- resumed AI faction does not replay its phase-start refresh ----
	gs.reset_map_state()
	var resume_blue := _mk_unit("blue", 20, "resume_blue")
	var resume_red := _mk_unit("red", 20, "resume_red")
	gs.register_unit(resume_blue)
	gs.register_unit(resume_red)
	var tm_resume_ai := TurnManager.new()
	root.add_child(tm_resume_ai)
	tm_resume_ai._map_data = md_suspend_ai
	tm_resume_ai._turn_order = ["blue", "red"] as Array[String]
	tm_resume_ai._active_faction_idx = 1
	tm_resume_ai._unit_states[resume_red] = TurnManager.UnitState.DONE
	var resume_ai_stub: Node = ai_stub_script.new()
	tm_resume_ai.set_ai_controller(resume_ai_stub)
	await tm_resume_ai._run_enemy_phases(true)
	if (
		resume_ai_stub.get("calls") == ["red"]
		and tm_resume_ai.active_faction() == "blue"
		and tm_resume_ai.get_unit_state(resume_red) == TurnManager.UnitState.DONE
	):
		print("OK  AI resume skips repeated phase-start effects and returns to blue")
		passed += 1
	else:
		print("FAIL AI resume path")
		failed += 1

	# ---- HotseatController.run_phase: points the cursor at the acting faction and waits ----
	var hotseat_controller: Node = load("res://scripts/core/HotseatController.gd").new()
	root.add_child(hotseat_controller)
	var hotseat_cursor_script := GDScript.new()
	hotseat_cursor_script.source_code = 'extends Node\nvar controlling_faction := ""\nvar unlock_calls := 0\nfunc set_controlling_faction(faction_id: String) -> void:\n\tcontrolling_faction = faction_id\nfunc unlock() -> void:\n\tunlock_calls += 1\n'
	hotseat_cursor_script.reload()
	var hotseat_cursor: Node = hotseat_cursor_script.new()
	root.add_child(hotseat_cursor)
	hotseat_controller.set_cursor(hotseat_cursor)
	var tm_hotseat := TurnManager.new()
	root.add_child(tm_hotseat)
	var md_hotseat := MapData.new()
	var hotseat_green := FactionData.new()
	hotseat_green.id = "green"
	hotseat_green.controller = "HOTSEAT"
	md_hotseat.factions = [hotseat_green]
	tm_hotseat._map_data = md_hotseat
	tm_hotseat.call_deferred("emit_signal", "phase_committed")
	await hotseat_controller.run_phase(null, tm_hotseat, "green")
	var configured: bool = (
		hotseat_cursor.get("controlling_faction") == "green"
		and hotseat_cursor.get("unlock_calls") == 1
	)
	if configured:
		print("OK  HotseatController.run_phase configures the cursor then waits for commit")
		passed += 1
	else:
		print(
			(
				"FAIL HotseatController.run_phase: faction=%s unlocks=%s"
				% [hotseat_cursor.get("controlling_faction"), hotseat_cursor.get("unlock_calls")]
			)
		)
		failed += 1

	# ---- Debug F9: all non-blue factions route through hotseat while enabled ----
	gs.reset_map_state()
	gs.set("debug_hotseat_override", true)
	var dbg_blue := _mk_unit("blue", 20, "dbg_blue")
	var dbg_red := _mk_unit("red", 20, "dbg_red")
	gs.register_unit(dbg_blue)
	gs.register_unit(dbg_red)
	var tm_dbg := TurnManager.new()
	root.add_child(tm_dbg)
	var md_dbg := MapData.new()
	var dbg_red_faction := FactionData.new()
	dbg_red_faction.id = "red"
	dbg_red_faction.controller = "AI"
	md_dbg.factions = [dbg_red_faction]
	md_dbg.turn_order = ["blue", "red"] as Array[String]
	tm_dbg.start_map(md_dbg)
	var dbg_ai_script := GDScript.new()
	dbg_ai_script.source_code = "extends Node\nvar calls: Array[String] = []\nfunc run_phase(_grid, _turn, faction_id: String) -> void:\n\tcalls.append(faction_id)\n"
	dbg_ai_script.reload()
	var dbg_ai: Node = dbg_ai_script.new()
	var dbg_hot_script := GDScript.new()
	dbg_hot_script.source_code = "extends Node\nvar calls: Array[String] = []\nfunc run_phase(_grid, turn, faction_id: String) -> void:\n\tcalls.append(faction_id)\n\tturn.phase_committed.emit()\n"
	dbg_hot_script.reload()
	var dbg_hot: Node = dbg_hot_script.new()
	tm_dbg.set_ai_controller(dbg_ai)
	tm_dbg.set_hotseat_controller(dbg_hot)
	await tm_dbg.start_enemy_phase()
	var debug_routes_hotseat: bool = (
		dbg_hot.get("calls") == ["red"]
		and dbg_ai.get("calls").is_empty()
		and tm_dbg.active_faction() == "blue"
		and gs.is_player_turn()
	)
	if debug_routes_hotseat:
		print("OK  F9 debug override routes an AI faction through hotseat")
		passed += 1
	else:
		print(
			(
				"FAIL F9 hotseat route: hotseat=%s ai=%s active=%s phase=%s"
				% [
					str(dbg_hot.get("calls")),
					str(dbg_ai.get("calls")),
					tm_dbg.active_faction(),
					gs.current_phase
				]
			)
		)
		failed += 1
	gs.set("debug_hotseat_override", false)

	# ---- Debug F9 off mid-phase: cleanup runs, then the same AI faction resumes ----
	gs.reset_map_state()
	gs.set("debug_hotseat_override", true)
	var off_blue := _mk_unit("blue", 20, "off_blue")
	var off_red := _mk_unit("red", 20, "off_red")
	gs.register_unit(off_blue)
	gs.register_unit(off_red)
	var tm_off := TurnManager.new()
	root.add_child(tm_off)
	tm_off.start_map(md_dbg)
	var off_ai_script := GDScript.new()
	off_ai_script.source_code = "extends Node\nvar calls: Array[String] = []\nfunc run_phase(_grid, _turn, faction_id: String) -> void:\n\tcalls.append(faction_id)\n"
	off_ai_script.reload()
	var off_ai: Node = off_ai_script.new()
	var off_hot_script := GDScript.new()
	off_hot_script.source_code = "extends Node\nvar calls: Array[String] = []\nvar cancel_calls := 0\nvar game_state: Node = null\nfunc cancel_transient_control_for_handoff() -> void:\n\tcancel_calls += 1\nfunc run_phase(_grid, _turn, faction_id: String) -> void:\n\tcalls.append(faction_id)\n\tgame_state.debug_hotseat_override = false\n"
	off_hot_script.reload()
	var off_hot: Node = off_hot_script.new()
	off_hot.set("game_state", gs)
	tm_off.set_ai_controller(off_ai)
	tm_off.set_hotseat_controller(off_hot)
	await tm_off.start_enemy_phase()
	var debug_off_resumes_ai: bool = (
		off_hot.get("calls") == ["red"]
		and int(off_hot.get("cancel_calls")) == 1
		and off_ai.get("calls") == ["red"]
		and tm_off.active_faction() == "blue"
		and gs.is_player_turn()
	)
	if debug_off_resumes_ai:
		print("OK  F9 off during override cleans up and resumes the same faction via AI")
		passed += 1
	else:
		print(
			(
				"FAIL F9 off resume: hotseat=%s cancel=%s ai=%s active=%s phase=%s debug=%s"
				% [
					str(off_hot.get("calls")),
					off_hot.get("cancel_calls"),
					str(off_ai.get("calls")),
					tm_off.active_faction(),
					gs.current_phase,
					gs.get("debug_hotseat_override")
				]
			)
		)
		failed += 1
	gs.set("debug_hotseat_override", false)

	# ---- Debug F9 toggled repeatedly in one phase doesn't exhaust the cycle guard ----
	# Each F9 re-run replays the SAME faction; the guard (turn_order.size()+1 = 3
	# here) must be refunded on those re-runs or rapid toggling trips the spurious
	# "never returned to blue" abort. The controllers ping-pong the override off/on
	# to force more re-runs than the raw guard budget, then settle on AI.
	gs.reset_map_state()
	gs.set("debug_hotseat_override", false)
	var tog_blue := _mk_unit("blue", 20, "tog_blue")
	var tog_red := _mk_unit("red", 20, "tog_red")
	gs.register_unit(tog_blue)
	gs.register_unit(tog_red)
	var tm_tog := TurnManager.new()
	root.add_child(tm_tog)
	tm_tog.start_map(md_dbg)
	var tog_hot_script := GDScript.new()
	tog_hot_script.source_code = "extends Node\nvar calls: Array[String] = []\nvar toggles := 0\nvar game_state: Node = null\nvar target: Node = null\nfunc cancel_transient_control_for_handoff() -> void:\n\tpass\nfunc run_phase(_grid, turn, faction_id: String) -> void:\n\tcalls.append(faction_id)\n\ttoggles += 1\n\tif target != null:\n\t\tturn.set_unit_state(target, 2)\n\tgame_state.debug_hotseat_override = false\n\tturn.phase_committed.emit()\n"
	tog_hot_script.reload()
	var tog_hot: Node = tog_hot_script.new()
	tog_hot.set("game_state", gs)
	tog_hot.set("target", tog_red)
	var tog_ai_script := GDScript.new()
	tog_ai_script.source_code = "extends Node\nvar calls: Array[String] = []\nvar hotseat: Node = null\nvar game_state: Node = null\nfunc run_phase(_grid, _turn, faction_id: String) -> void:\n\tcalls.append(faction_id)\n\tif hotseat.toggles < 3:\n\t\tgame_state.debug_hotseat_override = true\n"
	tog_ai_script.reload()
	var tog_ai: Node = tog_ai_script.new()
	tog_ai.set("game_state", gs)
	tog_ai.set("hotseat", tog_hot)
	tm_tog.set_ai_controller(tog_ai)
	tm_tog.set_hotseat_controller(tog_hot)
	await tm_tog.start_enemy_phase()
	var guard_survives_toggling: bool = (
		int(tog_hot.get("toggles")) == 3
		and tm_tog.active_faction() == "blue"
		and gs.is_player_turn()
		and tm_tog.get_unit_state(tog_red) == TurnManager.UnitState.DONE
	)
	if guard_survives_toggling:
		print("OK  F9 repeated toggling does not refresh spent same-faction units")
		passed += 1
	else:
		print(
			(
				"FAIL F9 rerun state: toggles=%s active=%s phase=%s red_state=%s"
				% [
					tog_hot.get("toggles"),
					tm_tog.active_faction(),
					gs.current_phase,
					tm_tog.get_unit_state(tog_red)
				]
			)
		)
		failed += 1
	gs.set("debug_hotseat_override", false)

	# ---- ALTERNATING: end_alternating_activation advances per-unit; round-wrap refreshes + bumps turn ----
	# Build a fresh ALT-mode scheduler with blue + red units, both DONE so we can
	# observe the refresh-on-wrap.
	gs.reset_map_state()
	var alt_blue := _mk_unit("blue", 20, "alt_b")
	var alt_red := _mk_unit("red", 20, "alt_r")
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
	tm_alt._unit_states[alt_red] = TurnManager.UnitState.DONE
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
		and alt_turn_seen[0] == 2  # turn_number bumped 1 → 2
		and tm_alt._unit_states[alt_blue] == TurnManager.UnitState.READY  # refreshed
		and tm_alt._unit_states[alt_red] == TurnManager.UnitState.READY
	)
	if alt_mid_ok and alt_wrap_ok:
		print("OK  ALTERNATING: per-unit advance, round-wrap refreshes and bumps turn_number")
		passed += 1
	else:
		print(
			(
				"FAIL ALTERNATING: mid_ok=%s wrap_ok=%s active=%s turn_seen=%d"
				% [alt_mid_ok, alt_wrap_ok, tm_alt.active_faction(), alt_turn_seen[0]]
			)
		)
		failed += 1

	# ---- ALTERNATING: start_player_phase handoff does not refresh blue units ----
	# In alternating mode refreshes happen only on round-wrap in
	# end_alternating_activation(), not every blue handoff.
	tm_alt._unit_states[alt_blue] = TurnManager.UnitState.DONE
	tm_alt._unit_states[alt_red] = TurnManager.UnitState.READY
	tm_alt.start_player_phase()
	if tm_alt._unit_states[alt_blue] == TurnManager.UnitState.DONE:
		print("OK  ALTERNATING: start_player_phase handoff does not refresh blue")
		passed += 1
	else:
		print("FAIL ALT handoff refresh: blue state=%d (want DONE)" % tm_alt._unit_states[alt_blue])
		failed += 1

	# ---- WHOLE_PHASE: end_alternating_activation is a no-op (wrong mode) ----
	var tm_whole := TurnManager.new()
	root.add_child(tm_whole)
	tm_whole._turn_order = ["blue", "red"] as Array[String]
	tm_whole._activation_mode = "WHOLE_PHASE"
	tm_whole._active_faction_idx = 0
	tm_whole.end_alternating_activation()
	if tm_whole.active_faction() == "blue":
		print("OK  end_alternating_activation is a no-op in WHOLE_PHASE mode")
		passed += 1
	else:
		print("FAIL ALT no-op: active=%s after call (want blue)" % tm_whole.active_faction())
		failed += 1

	# ---- start_map: factions read FactionData[] when turn_order isn't authored ----
	# Stage 3 lets MapData carry FactionData entries instead of a string list; the
	# scheduler then reads the order from those entries' ids.
	gs.reset_map_state()
	var fd_blue := FactionData.new()
	fd_blue.id = "blue"
	var fd_red := FactionData.new()
	fd_red.id = "red"
	var md_fd := MapData.new()
	md_fd.factions = [fd_blue, fd_red] as Array[FactionData]  # no turn_order
	var tm_fd := TurnManager.new()
	root.add_child(tm_fd)
	tm_fd.start_map(md_fd)
	if tm_fd._turn_order == (["blue", "red"] as Array[String]):
		print("OK  start_map: turn_order derived from MapData.factions when turn_order empty")
		passed += 1
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
	gs.register_unit(_mk_unit("red", 0, "e_v1"))  # red unit dead
	var md_pg_v := MapData.new()
	var c_rout_red := ObjectiveCondition.new()
	c_rout_red.type = "rout"
	c_rout_red.faction_id = "red"
	md_pg_v.victory_conditions = {"allies": [c_rout_red]}
	var tm_pg_v := TurnManager.new()
	root.add_child(tm_pg_v)
	tm_pg_v._map_data = md_pg_v
	victories[0] = 0
	tm_pg_v.check_victory_conditions()
	if victories[0] == 1:
		print("OK  per-group victory: authored rout(red) → map_victory")
		passed += 1
	else:
		print("FAIL per-group victory: victories=%d" % victories[0])
		failed += 1

	# ---- per-group defeat: authored protect fires map_defeat ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "grunt2"))  # protected id absent → defeat
	gs.register_unit(_mk_unit("red", 20, "e_d1"))  # red alive so no last-standing
	var md_pg_d := MapData.new()
	var c_prot := ObjectiveCondition.new()
	c_prot.type = "protect"
	c_prot.unit_ids = ["hero_pg"] as Array[String]
	md_pg_d.defeat_conditions = {"allies": [c_prot]}
	var tm_pg_d := TurnManager.new()
	root.add_child(tm_pg_d)
	tm_pg_d._map_data = md_pg_d
	defeats[0] = 0
	tm_pg_d.check_victory_conditions()
	if defeats[0] == 1:
		print("OK  per-group defeat: authored protect (missing unit) → map_defeat")
		passed += 1
	else:
		print("FAIL per-group defeat: defeats=%d" % defeats[0])
		failed += 1

	# ---- ≤1 group remaining → last group standing wins (no authored victory) ----
	# Authored: foes have a protect condition on a missing unit → foes eliminated.
	# Allies remain in play, so the last-standing fallback awards them the win.
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_ls"))
	gs.register_unit(_mk_unit("red", 20, "e_ls"))  # red alive
	var md_ls := MapData.new()
	var c_prot_foes := ObjectiveCondition.new()
	c_prot_foes.type = "protect"
	c_prot_foes.unit_ids = ["red_boss_ls"] as Array[String]
	md_ls.defeat_conditions = {"foes": [c_prot_foes]}
	var tm_ls := TurnManager.new()
	root.add_child(tm_ls)
	tm_ls._map_data = md_ls
	victories[0] = 0
	tm_ls.check_victory_conditions()
	if victories[0] == 1:
		print("OK  ≤1 group remaining: last-standing wins (map_victory)")
		passed += 1
	else:
		print("FAIL last-standing: victories=%d defeats=%d" % [victories[0], defeats[0]])
		failed += 1

	# ---- no authored Rout means a wiped board does not end the map ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 0, "p_draw"))
	gs.register_unit(_mk_unit("red", 0, "e_draw"))
	var md_draw := MapData.new()  # no conditions
	var tm_draw := TurnManager.new()
	root.add_child(tm_draw)
	tm_draw._map_data = md_draw
	victories[0] = 0
	defeats[0] = 0
	tm_draw.check_victory_conditions()
	if defeats[0] == 0 and victories[0] == 0 and not tm_draw._map_over:
		print("OK  no authored Rout: zero deployed units does not end the map")
		passed += 1
	else:
		print(
			(
				"FAIL explicit-Rout requirement: V=%d D=%d map_over=%s"
				% [victories[0], defeats[0], tm_draw._map_over]
			)
		)
		failed += 1

	# ---- simultaneous authored elimination → draw → map_defeat ----
	var c_draw_allies := ObjectiveCondition.new()
	c_draw_allies.type = "rout"
	c_draw_allies.faction_id = "allies"
	var c_draw_foes := ObjectiveCondition.new()
	c_draw_foes.type = "rout"
	c_draw_foes.faction_id = "foes"
	md_draw.defeat_conditions = {
		"allies": [c_draw_allies],
		"foes": [c_draw_foes],
	}
	tm_draw = TurnManager.new()
	root.add_child(tm_draw)
	tm_draw._map_data = md_draw
	tm_draw.check_victory_conditions()
	if defeats[0] == 1 and victories[0] == 0:
		print("OK  simultaneous authored elimination → draw → map_defeat")
		passed += 1
	else:
		print("FAIL authored draw: V=%d D=%d" % [victories[0], defeats[0]])
		failed += 1

	# ---- get_group_eliminated_round records the round a group fell ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_er"))
	gs.register_unit(_mk_unit("red", 0, "e_er"))  # red wiped on turn 1
	gs.turn_number = 1
	var md_er := MapData.new()
	var c_er_foes := ObjectiveCondition.new()
	c_er_foes.type = "rout"
	c_er_foes.faction_id = "foes"
	md_er.defeat_conditions = {"foes": [c_er_foes]}
	var tm_er := TurnManager.new()
	root.add_child(tm_er)
	tm_er._map_data = md_er
	tm_er.check_victory_conditions()  # foes eliminated, allies wins
	if (
		tm_er.get_group_eliminated_round("foes") == 1
		and tm_er.get_group_eliminated_round("allies") == -1
	):
		print("OK  get_group_eliminated_round: foes=1, allies=-1")
		passed += 1
	else:
		print(
			(
				"FAIL elim-round: foes=%d allies=%d"
				% [
					tm_er.get_group_eliminated_round("foes"),
					tm_er.get_group_eliminated_round("allies"),
				]
			)
		)
		failed += 1

	# ── M16 stage 3: defeat_boss / seize / escape / survive ─────────────────────

	# ---- defeat_boss victory: every named unit_id dead → map_victory ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_db"))
	gs.register_unit(_mk_unit("red", 0, "boss_db"))  # boss dead
	var md_db := MapData.new()
	var c_db := ObjectiveCondition.new()
	c_db.type = "defeat_boss"
	c_db.unit_ids = ["boss_db"] as Array[String]
	md_db.victory_conditions = {"allies": [c_db]}
	var tm_db := TurnManager.new()
	root.add_child(tm_db)
	tm_db._map_data = md_db
	victories[0] = 0
	tm_db.check_victory_conditions()
	if victories[0] == 1:
		print("OK  defeat_boss: every named unit dead → map_victory")
		passed += 1
	else:
		print("FAIL defeat_boss: victories=%d" % victories[0])
		failed += 1

	# ---- survive victory: turn_number > turns → map_victory ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_sv"))
	gs.register_unit(_mk_unit("red", 20, "e_sv"))  # red alive — only the timer wins it
	gs.turn_number = 4
	var md_sv := MapData.new()
	var c_sv := ObjectiveCondition.new()
	c_sv.type = "survive"
	c_sv.turns = 3
	md_sv.victory_conditions = {"allies": [c_sv]}
	var tm_sv := TurnManager.new()
	root.add_child(tm_sv)
	tm_sv._map_data = md_sv
	victories[0] = 0
	tm_sv.check_victory_conditions()
	if victories[0] == 1:
		print("OK  survive: turn_number > turns → map_victory")
		passed += 1
	else:
		print("FAIL survive: victories=%d" % victories[0])
		failed += 1

	# ---- shipped Map 005 is pure survive: turn 6 no, turn 7 yes, no turn-9 loss ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "unit_01_cavalier"))
	gs.register_unit(_mk_unit("red", 20, "map5_enemy"))
	var map5: MapData = load("res://data/maps/map_005_defend/map_005_defend_data.tres")
	var tm_map5 := TurnManager.new()
	root.add_child(tm_map5)
	tm_map5._map_data = map5
	victories[0] = 0
	defeats[0] = 0
	gs.turn_number = 6
	tm_map5.check_victory_conditions()
	var before_boundary: bool = victories[0] == 0 and defeats[0] == 0
	gs.turn_number = 7
	tm_map5.check_victory_conditions()
	var at_boundary: bool = victories[0] == 1 and defeats[0] == 0
	var tm_map5_late := TurnManager.new()
	root.add_child(tm_map5_late)
	tm_map5_late._map_data = map5
	defeats[0] = 0
	gs.turn_number = 9
	tm_map5_late.check_victory_conditions()
	if before_boundary and at_boundary and defeats[0] == 0:
		print("OK  map_005 pure survive resolves only after turn 6 and never turn-limit defeats")
		passed += 1
	else:
		print(
			(
				"FAIL map_005 survive: before=%s boundary=%s turn9_defeats=%d"
				% [before_boundary, at_boundary, defeats[0]]
			)
		)
		failed += 1

	# ---- record_seize: seize on a named tile by an allowed unit → map_victory ----
	gs.reset_map_state()
	var seizer := _mk_unit("blue", 20, "seizer")
	seizer.set("tile_position", Vector2i(2, 2))
	gs.register_unit(seizer)
	gs.register_unit(_mk_unit("red", 20, "e_seize"))  # red alive — seize is the win
	var md_se := MapData.new()
	var c_se := ObjectiveCondition.new()
	c_se.type = "seize"
	c_se.tile = Vector2i(2, 2)
	seizer.data.can_seize = true
	md_se.victory_conditions = {"allies": [c_se]}
	var tm_se := TurnManager.new()
	root.add_child(tm_se)
	tm_se._map_data = md_se
	victories[0] = 0
	tm_se.record_seize(seizer)
	if victories[0] == 1:
		print("OK  record_seize: allowed unit on tile → map_victory")
		passed += 1
	else:
		print("FAIL record_seize: victories=%d" % victories[0])
		failed += 1

	# ---- seize map does NOT auto-win from last-group-standing before Seize happens ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_seize_only"))
	var md_seize_only := MapData.new()
	var c_seize_only := ObjectiveCondition.new()
	c_seize_only.type = "seize"
	c_seize_only.tile = Vector2i(9, 9)
	md_seize_only.victory_conditions = {"allies": [c_seize_only]}
	var tm_seize_only := TurnManager.new()
	root.add_child(tm_seize_only)
	tm_seize_only._map_data = md_seize_only
	victories[0] = 0
	defeats[0] = 0
	tm_seize_only.check_victory_conditions()
	if victories[0] == 0 and defeats[0] == 0 and not tm_seize_only._map_over:
		print("OK  seize objective suppresses last-group-standing auto-win")
		passed += 1
	else:
		print(
			(
				"FAIL seize fallback suppression: victories=%d defeats=%d map_over=%s"
				% [victories[0], defeats[0], tm_seize_only._map_over]
			)
		)
		failed += 1

	# ---- can_seize: UnitData.can_seize + tile gate ----
	gs.reset_map_state()
	var seizer_ok := _mk_unit("blue", 20, "lord")
	var seizer_no := _mk_unit("blue", 20, "knight")
	seizer_ok.set("tile_position", Vector2i(3, 3))
	seizer_no.set("tile_position", Vector2i(3, 3))
	seizer_ok.data.can_seize = true
	seizer_no.data.can_seize = false
	gs.register_unit(seizer_ok)
	gs.register_unit(seizer_no)
	var md_cs := MapData.new()
	var c_cs := ObjectiveCondition.new()
	c_cs.type = "seize"
	c_cs.tile = Vector2i(3, 3)
	md_cs.victory_conditions = {"allies": [c_cs]}
	var tm_cs := TurnManager.new()
	root.add_child(tm_cs)
	tm_cs._map_data = md_cs
	if (
		tm_cs.can_seize(seizer_ok, Vector2i(3, 3))
		and not tm_cs.can_seize(seizer_no, Vector2i(3, 3))
		and not tm_cs.can_seize(seizer_ok, Vector2i(0, 0))
	):
		print("OK  can_seize: can_seize tag + tile gate")
		passed += 1
	else:
		print(
			(
				"FAIL can_seize gate (lord=%s knight=%s offtile=%s)"
				% [
					tm_cs.can_seize(seizer_ok, Vector2i(3, 3)),
					tm_cs.can_seize(seizer_no, Vector2i(3, 3)),
					tm_cs.can_seize(seizer_ok, Vector2i(0, 0)),
				]
			)
		)
		failed += 1

	# ---- can_seize: false tag blocks another unit on the same tile ----
	gs.reset_map_state()
	var seize_tag_yes := _mk_unit("blue", 20, "tag_yes")
	var seize_tag_no := _mk_unit("blue", 20, "tag_no")
	seize_tag_yes.set("tile_position", Vector2i(6, 6))
	seize_tag_no.set("tile_position", Vector2i(6, 6))
	seize_tag_yes.data.can_seize = true
	seize_tag_no.data.can_seize = false
	gs.register_unit(seize_tag_yes)
	gs.register_unit(seize_tag_no)
	var md_cst := MapData.new()
	var c_cst := ObjectiveCondition.new()
	c_cst.type = "seize"
	c_cst.tile = Vector2i(6, 6)
	md_cst.victory_conditions = {"allies": [c_cst]}
	var tm_cst := TurnManager.new()
	root.add_child(tm_cst)
	tm_cst._map_data = md_cst
	if (
		tm_cst.can_seize(seize_tag_yes, Vector2i(6, 6))
		and not tm_cst.can_seize(seize_tag_no, Vector2i(6, 6))
	):
		print("OK  can_seize: UnitData.can_seize is the sole unit eligibility gate")
		passed += 1
	else:
		print(
			(
				"FAIL can_seize tag gate (yes=%s no=%s)"
				% [
					tm_cst.can_seize(seize_tag_yes, Vector2i(6, 6)),
					tm_cst.can_seize(seize_tag_no, Vector2i(6, 6)),
				]
			)
		)
		failed += 1

	# ---- _eval_rout: unknown faction_id fails closed (no vacuous victory) ----
	# A typo'd rout authoring (e.g. "reds" instead of "red") must not silently
	# fire map_victory; it should treat the condition as unmet and log a warning
	# (push_warning, not asserted here — the editor surfaces it).
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_typo"))
	gs.register_unit(_mk_unit("red", 20, "e_typo"))  # red alive — only typo'd rout could fire
	var md_typo := MapData.new()
	var c_typo := ObjectiveCondition.new()
	c_typo.type = "rout"
	c_typo.faction_id = "reds"  # typo: real id is "red"
	md_typo.victory_conditions = {"allies": [c_typo]}
	var tm_typo := TurnManager.new()
	root.add_child(tm_typo)
	tm_typo._map_data = md_typo
	victories[0] = 0
	tm_typo.check_victory_conditions()
	if victories[0] == 0:
		print("OK  _eval_rout: unknown faction_id treated as unmet")
		passed += 1
	else:
		print("FAIL rout-typo: victories=%d" % victories[0])
		failed += 1

	# ---- _eval_seize: can_seize unit outside the group does NOT win ----
	gs.reset_map_state()
	var infiltrator := _mk_unit("red", 20, "seizer_xg")
	infiltrator.set("tile_position", Vector2i(4, 4))
	infiltrator.data.can_seize = true
	gs.register_unit(infiltrator)
	gs.register_unit(_mk_unit("blue", 20, "p_xg"))
	var md_xg := MapData.new()
	var c_xg := ObjectiveCondition.new()
	c_xg.type = "seize"
	c_xg.tile = Vector2i(4, 4)
	md_xg.victory_conditions = {"allies": [c_xg]}
	var tm_xg := TurnManager.new()
	root.add_child(tm_xg)
	tm_xg._map_data = md_xg
	victories[0] = 0
	tm_xg.record_seize(infiltrator)
	# can_seize must also refuse to show Seize for the cross-group unit.
	var xg_can_seize: bool = tm_xg.can_seize(infiltrator, Vector2i(4, 4))
	if victories[0] == 0 and not xg_can_seize:
		print("OK  _eval_seize / can_seize: tagged unit outside the group is blocked")
		passed += 1
	else:
		print("FAIL seize-xg: victories=%d can_seize=%s" % [victories[0], xg_can_seize])
		failed += 1

	# ---- record_escape: every named unit escaped → map_victory ----
	gs.reset_map_state()
	var runner := _mk_unit("blue", 20, "runner")
	gs.register_unit(runner)
	gs.register_unit(_mk_unit("red", 20, "e_esc"))  # red alive — escape is the win
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
		print("OK  record_escape: named unit escaped → map_victory")
		passed += 1
	else:
		print(
			"FAIL record_escape: victories=%d escaped=%s" % [victories[0], tm_esc._escape_records]
		)
		failed += 1

	# ---- escape map does NOT auto-win from hostile rout before every unit escapes ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "runner_a"))
	gs.register_unit(_mk_unit("blue", 20, "runner_b"))
	var md_escape_only := MapData.new()
	var c_escape_only := ObjectiveCondition.new()
	c_escape_only.type = "escape"
	c_escape_only.tiles = [Vector2i(8, 8)] as Array[Vector2i]
	c_escape_only.unit_ids = ["runner_a", "runner_b"] as Array[String]
	md_escape_only.victory_conditions = {"allies": [c_escape_only]}
	var tm_escape_only := TurnManager.new()
	root.add_child(tm_escape_only)
	tm_escape_only._map_data = md_escape_only
	victories[0] = 0
	defeats[0] = 0
	tm_escape_only.check_victory_conditions()
	if victories[0] == 0 and defeats[0] == 0 and not tm_escape_only._map_over:
		print("OK  escape objective suppresses last-group-standing auto-win")
		passed += 1
	else:
		print(
			(
				"FAIL escape fallback suppression: victories=%d defeats=%d map_over=%s"
				% [victories[0], defeats[0], tm_escape_only._map_over]
			)
		)
		failed += 1

	# ---- record_escape: paired lead escaping removes and counts both units ----
	gs.reset_map_state()
	pair_reg.call("clear")
	var paired_lead := _mk_unit("blue", 20, "pair_lead")
	var paired_support := _mk_unit("blue", 20, "pair_support")
	var paired_lead_data: UnitData = paired_lead.data
	var paired_support_data: UnitData = paired_support.data
	paired_lead.set("tile_position", Vector2i(1, 1))
	paired_support.set("tile_position", pair_reg.OFF_MAP_TILE)
	gs.register_unit(paired_lead)
	gs.register_unit(paired_support)
	gs.register_unit(_mk_unit("red", 20, "e_pair_esc"))
	pair_reg.pair("pair_lead", "pair_support")
	var md_pair_esc := MapData.new()
	var c_pair_esc := ObjectiveCondition.new()
	c_pair_esc.type = "escape"
	c_pair_esc.tiles = [Vector2i(1, 1)] as Array[Vector2i]
	c_pair_esc.unit_ids = ["pair_lead", "pair_support"] as Array[String]
	md_pair_esc.victory_conditions = {"allies": [c_pair_esc]}
	var tm_pair_esc := TurnManager.new()
	root.add_child(tm_pair_esc)
	tm_pair_esc._map_data = md_pair_esc
	victories[0] = 0
	tm_pair_esc.record_escape(paired_lead)
	await process_frame
	var pair_escape_ok: bool = (
		victories[0] == 1
		and tm_pair_esc._has_unit_escaped("pair_lead")
		and tm_pair_esc._has_unit_escaped("pair_support")
		and not pair_reg.is_paired("pair_lead")
		and gs.find_unit_by_id("pair_lead") == null
		and gs.find_unit_by_id("pair_support") == null
		and paired_lead_data.tile_position == Vector2i(1, 1)
		and paired_support_data.tile_position == Vector2i(1, 1)
	)
	if pair_escape_ok:
		print("OK  record_escape: paired lead escape removes and counts both units")
		passed += 1
	else:
		print(
			(
				"FAIL paired escape: victories=%d lead_escaped=%s support_escaped=%s lead_live=%s support_live=%s paired=%s"
				% [
					victories[0],
					tm_pair_esc._has_unit_escaped("pair_lead"),
					tm_pair_esc._has_unit_escaped("pair_support"),
					gs.find_unit_by_id("pair_lead") != null,
					gs.find_unit_by_id("pair_support") != null,
					pair_reg.is_paired("pair_lead"),
				]
			)
		)
		failed += 1

	# ---- escape exclusion in protect: an escaped id doesn't trigger protect-fail ----
	gs.reset_map_state()
	var prot_unit := _mk_unit("blue", 20, "vip")
	gs.register_unit(prot_unit)
	gs.register_unit(_mk_unit("red", 20, "e_prot"))  # red alive
	var md_xp := MapData.new()
	var c_xp_prot := ObjectiveCondition.new()
	c_xp_prot.type = "protect"
	c_xp_prot.unit_ids = ["vip"] as Array[String]
	md_xp.defeat_conditions = {"allies": [c_xp_prot]}
	var tm_xp := TurnManager.new()
	root.add_child(tm_xp)
	tm_xp._map_data = md_xp
	defeats[0] = 0
	tm_xp.record_escape(prot_unit)  # vip leaves the map alive
	if defeats[0] == 0:
		print("OK  escape exclusion: escaped vip doesn't fail protect")
		passed += 1
	else:
		print("FAIL escape exclusion: defeats=%d (should be 0)" % defeats[0])
		failed += 1

	# ---- can_escape gate: ActionMenu sees Escape only on a zone tile for a named unit ----
	# Replaces the old _on_unit_moved auto-escape test (H-1 / 2026-05-20 review:
	# escape is now a deliberate ActionMenu entry, not a movement-driven hook).
	gs.reset_map_state()
	var runner_can := _mk_unit("blue", 20, "auto_runner")
	var runner_not_named := _mk_unit("blue", 20, "other_blue")
	runner_can.set("tile_position", Vector2i(7, 7))
	runner_not_named.set("tile_position", Vector2i(7, 7))
	gs.register_unit(runner_can)
	gs.register_unit(runner_not_named)
	gs.register_unit(_mk_unit("red", 20, "e_auto"))
	var md_can_esc := MapData.new()
	var c_can_esc := ObjectiveCondition.new()
	c_can_esc.type = "escape"
	c_can_esc.tiles = [Vector2i(7, 7)] as Array[Vector2i]
	c_can_esc.unit_ids = ["auto_runner"] as Array[String]
	md_can_esc.victory_conditions = {"allies": [c_can_esc]}
	var tm_can_esc := TurnManager.new()
	root.add_child(tm_can_esc)
	tm_can_esc._map_data = md_can_esc
	# Named unit on the zone tile → can_escape true; other unit on the same tile → false;
	# named unit off the zone → false.
	if (
		tm_can_esc.can_escape(runner_can, Vector2i(7, 7))
		and not tm_can_esc.can_escape(runner_not_named, Vector2i(7, 7))
		and not tm_can_esc.can_escape(runner_can, Vector2i(0, 0))
	):
		print("OK  can_escape: zone + named-unit gate")
		passed += 1
	else:
		print(
			(
				"FAIL can_escape gate (named=%s other=%s offzone=%s)"
				% [
					tm_can_esc.can_escape(runner_can, Vector2i(7, 7)),
					tm_can_esc.can_escape(runner_not_named, Vector2i(7, 7)),
					tm_can_esc.can_escape(runner_can, Vector2i(0, 0)),
				]
			)
		)
		failed += 1

	# ---- TurnManager no longer hooks unit_moved (H-1 / 2026-05-20 review) ----
	# Pinned because the connect used to live alongside unit_died; a future
	# refactor could accidentally re-add it. If escape ever needs movement
	# awareness again, that's a fresh design decision, not a quiet revival.
	var tm_no_hook := TurnManager.new()
	root.add_child(tm_no_hook)
	if not tm_no_hook.has_method("_on_unit_moved"):
		print("OK  TurnManager has no _on_unit_moved handler (auto-escape removed)")
		passed += 1
	else:
		print("FAIL _on_unit_moved still defined on TurnManager")
		failed += 1

	# ── M16 stage 4: map_resolved standings emission ────────────────────────────

	# Capture the most recent map_resolved payload so each assertion below can
	# inspect it. Connected once; tests reset the slot to track which fires when.
	var resolved: Array = [{}]
	bus.map_resolved.connect(func(w, s): resolved[0] = {"winner": w, "standings": s})

	# ---- map_resolved: blue victory → standings rank 1 = allies (you) ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_st"))
	gs.register_unit(_mk_unit("red", 0, "e_st"))  # red wiped → blue wins
	gs.turn_number = 2
	var md_st := MapData.new()
	var c_st_rout := ObjectiveCondition.new()
	c_st_rout.type = "rout"
	md_st.victory_conditions = {"allies": [c_st_rout]}
	var c_st_foes_routed := ObjectiveCondition.new()
	c_st_foes_routed.type = "rout"
	c_st_foes_routed.faction_id = "foes"
	md_st.defeat_conditions = {"foes": [c_st_foes_routed]}
	var tm_st := TurnManager.new()
	root.add_child(tm_st)
	tm_st._map_data = md_st
	resolved[0] = {}
	tm_st.check_victory_conditions()
	var st_ok: bool = (
		resolved[0].get("winner", "") == "allies" and resolved[0].get("standings", []).size() == 2
	)
	if st_ok:
		var top = resolved[0]["standings"][0]
		var bottom = resolved[0]["standings"][1]
		st_ok = (
			st_ok
			and top["rank"] == 1
			and top["group"] == "allies"
			and top["is_blue_group"] == true
			and bottom["rank"] == 2
			and bottom["group"] == "foes"
			and bottom["eliminated_round"] == 2
		)
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
	var md_draw_standings := MapData.new()
	var c_st_draw_allies := ObjectiveCondition.new()
	c_st_draw_allies.type = "rout"
	c_st_draw_allies.faction_id = "allies"
	var c_st_draw_foes := ObjectiveCondition.new()
	c_st_draw_foes.type = "rout"
	c_st_draw_foes.faction_id = "foes"
	md_draw_standings.defeat_conditions = {
		"allies": [c_st_draw_allies],
		"foes": [c_st_draw_foes],
	}
	tm_dr._map_data = md_draw_standings
	resolved[0] = {}
	tm_dr.check_victory_conditions()
	if resolved[0].get("winner", "_") == "" and resolved[0].get("standings", []).size() == 2:
		print('OK  map_resolved: draw → winner="", both groups in standings')
		passed += 1
	else:
		print("FAIL draw standings: %s" % str(resolved[0]))
		failed += 1

	# ── M16 stage 5: Decision 7 phase-boundary sweep on start_enemy_phase ──────
	# A turn_limit defeat that fires when the enemy phase begins. Without the
	# stage-5 sweep, the defeat would have to wait until the next blue phase
	# (or any death/move); with it, start_enemy_phase resolves the map.
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20, "p_pbs"))
	gs.register_unit(_mk_unit("red", 20, "e_pbs"))
	gs.turn_number = 3
	var md_pbs := MapData.new()
	var c_pbs_tl := ObjectiveCondition.new()
	c_pbs_tl.type = "turn_limit"
	c_pbs_tl.turns = 2
	md_pbs.defeat_conditions = {"allies": [c_pbs_tl]}
	var tm_pbs := TurnManager.new()
	root.add_child(tm_pbs)
	tm_pbs._map_data = md_pbs
	# Seed the scheduler so start_enemy_phase has a turn_order to advance through.
	tm_pbs._turn_order = ["blue", "red"] as Array[String]
	tm_pbs._active_faction_idx = 0
	defeats[0] = 0
	tm_pbs.start_enemy_phase()
	await process_frame
	if defeats[0] == 1 and tm_pbs._map_over:
		print("OK  start_enemy_phase: phase-boundary sweep fires map_defeat (D7)")
		passed += 1
	else:
		print("FAIL D7 phase sweep: defeats=%d _map_over=%s" % [defeats[0], tm_pbs._map_over])
		failed += 1

	# ---- start_enemy_phase: a turn_order without blue fails loud instead of looping forever ----
	var tm_guard := TurnManager.new()
	root.add_child(tm_guard)
	var md_guard := MapData.new()
	var fd_guard := FactionData.new()
	fd_guard.id = "red"
	md_guard.factions = [fd_guard]
	md_guard.turn_order = ["red"] as Array[String]
	tm_guard.start_map(md_guard)
	tm_guard.start_enemy_phase()
	await process_frame
	if tm_guard.active_faction() == "red":
		print("OK  start_enemy_phase: no-blue turn_order terminates instead of hanging")
		passed += 1
	else:
		print("FAIL no-blue guard: active_faction=%s" % tm_guard.active_faction())
		failed += 1

	# ---- fort heal floors at 1 (OPEN-7 regression, audit CR-2) ----
	# Pre-fix, _apply_fort_healing used bare floori(): a 5-max-HP unit healed
	# floor(0.10×5)=0. OPEN-7 guarantees max(1, floor(...)), so it must recover ≥1.
	var heal_unit_stub := GDScript.new()
	heal_unit_stub.source_code = 'extends Node\nvar team := "blue"\nvar data = null\nvar tile_position: Vector2i = Vector2i.ZERO\nfunc heal(amount: int) -> void:\n\tdata.hp = mini(data.max_hp, data.hp + amount)\n'
	heal_unit_stub.reload()

	var fort_grid := GridManager.new()
	root.add_child(fort_grid)
	fort_grid.set_terrain_fallback(Vector2i.ZERO, "fort")
	var tm_fort := TurnManager.new()
	root.add_child(tm_fort)
	tm_fort._grid = fort_grid

	# Small unit: floor(0.10×5)=0 → must still heal 1.
	var small_d := UnitData.new()
	small_d.max_hp = 5
	small_d.hp = 1
	var small_u: Node = heal_unit_stub.new()
	small_u.set("data", small_d)
	# Large unit: floor(0.10×20)=2 → heals the full rounded amount, not just 1.
	var big_d := UnitData.new()
	big_d.max_hp = 20
	big_d.hp = 1
	var big_u: Node = heal_unit_stub.new()
	big_u.set("data", big_d)
	root.add_child(small_u)
	root.add_child(big_u)
	tm_fort._apply_fort_healing([small_u, big_u] as Array[Node])
	if small_d.hp == 2 and big_d.hp == 3:
		print("OK  fort heal floors at 1 (5-HP unit +1, 20-HP unit +2)")
		passed += 1
	else:
		print("FAIL fort heal floor: small=%d (want 2) big=%d (want 3)" % [small_d.hp, big_d.hp])
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
