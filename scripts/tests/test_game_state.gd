extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_game_state.gd
# Tests GameState: the unit registry, the living-unit filters, phase tracking,
# reset_map_state, the default-roster load, and the map-snapshot round-trip.
# test_snapshot_coverage already verifies _snapshot_unit_data's FIELD coverage —
# this suite covers the behavioural round-trip and the rest of the API.

var _unit_stub: GDScript


func _mk_unit(team_name: String, hp: int) -> Node:
	var d := UnitData.new()
	d.hp = hp
	d.max_hp = 20
	var u: Node = _unit_stub.new()
	u.set("team", team_name)
	u.set("data", d)
	root.add_child(u)
	return u


func _init() -> void:
	print("=== GameState Test ===")
	var passed := 0
	var failed := 0

	_unit_stub = GDScript.new()
	_unit_stub.source_code = "extends Node\nvar team: String = \"blue\"\nvar data = null\n"
	_unit_stub.reload()

	var gs: Node = load("res://scripts/autoloads/GameState.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame

	# ---- register_unit adds the unit to all_units ----
	var p1 := _mk_unit("blue", 20)
	gs.register_unit(p1)
	if p1 in gs.all_units:
		print("OK  register_unit adds the unit to all_units"); passed += 1
	else:
		print("FAIL register_unit"); failed += 1

	# ---- register_unit ignores a double registration (a push_error is expected) ----
	var before: int = gs.all_units.size()
	gs.register_unit(p1)
	if gs.all_units.size() == before:
		print("OK  register_unit: a double registration is ignored"); passed += 1
	else:
		print("FAIL register_unit double"); failed += 1

	# ---- the living-unit getters separate units by team ----
	gs.reset_map_state()
	var pa := _mk_unit("blue", 20)
	var ea := _mk_unit("red", 20)
	gs.register_unit(pa)
	gs.register_unit(ea)
	var lp: Array = gs.get_living_player_units()
	var le: Array = gs.get_living_enemy_units()
	if lp.size() == 1 and lp[0] == pa and le.size() == 1 and le[0] == ea:
		print("OK  get_living_player/enemy_units separate units by team"); passed += 1
	else:
		print("FAIL living getters: players=%d enemies=%d" % [lp.size(), le.size()])
		failed += 1

	# ---- get_living_player_units excludes a dead (hp 0) unit ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20))
	gs.register_unit(_mk_unit("blue", 0))   # dead
	if gs.get_living_player_units().size() == 1:
		print("OK  get_living_player_units excludes a dead unit"); passed += 1
	else:
		print("FAIL living excludes dead: got %d" % gs.get_living_player_units().size())
		failed += 1

	# ---- unregister_unit removes the unit from every list ----
	gs.reset_map_state()
	var ru := _mk_unit("blue", 20)
	gs.register_unit(ru)
	gs.unregister_unit(ru)
	if not (ru in gs.all_units) and gs.get_living_player_units().is_empty():
		print("OK  unregister_unit removes the unit from all lists"); passed += 1
	else:
		print("FAIL unregister_unit"); failed += 1

	# ---- get_registered_faction_ids: returns every faction id with a unit ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20))
	gs.register_unit(_mk_unit("red", 20))
	gs.register_unit(_mk_unit("green", 20))
	var fids: Array[String] = gs.get_registered_faction_ids()
	fids.sort()
	if fids == (["blue", "green", "red"] as Array[String]):
		print("OK  get_registered_faction_ids returns every registered faction"); passed += 1
	else:
		print("FAIL get_registered_faction_ids: %s" % str(fids)); failed += 1

	# ---- set_phase / is_player_turn track the current phase ----
	gs.set_phase(gs.Phase.ENEMY)
	var on_enemy: bool = not gs.is_player_turn()
	gs.set_phase(gs.Phase.PLAYER)
	if on_enemy and gs.is_player_turn():
		print("OK  set_phase / is_player_turn track the current phase"); passed += 1
	else:
		print("FAIL set_phase / is_player_turn"); failed += 1

	# ---- reset_map_state clears units and resets turn_number / phase ----
	gs.register_unit(_mk_unit("blue", 20))
	gs.turn_number = 9
	gs.set_phase(gs.Phase.ENEMY)
	gs.reset_map_state()
	if gs.all_units.is_empty() and gs.turn_number == 1 and gs.is_player_turn():
		print("OK  reset_map_state clears units, turn_number → 1, phase → PLAYER"); passed += 1
	else:
		print("FAIL reset_map_state"); failed += 1

	# ---- load_default_roster populates player_roster ----
	gs.load_default_roster()
	if gs.player_roster.size() > 0:
		print("OK  load_default_roster loads the roster (%d units)" % gs.player_roster.size())
		passed += 1
	else:
		print("FAIL load_default_roster: roster is empty"); failed += 1

	# ---- export-safe roster manifest lists the default roster in slot order ----
	var ResourceManifest = load("res://scripts/shared/ResourceManifest.gd")
	var roster_manifest: Array[String] = ResourceManifest.load_paths("res://data/roster/default/")
	if roster_manifest.size() == 6 and roster_manifest[0].ends_with("unit_01_cavalier.tres"):
		print("OK  default roster manifest preserves deployment order"); passed += 1
	else:
		print("FAIL default roster manifest: %s" % [roster_manifest]); failed += 1

	# ---- default roster Cavalier movement matches authored class intent ----
	var cav_ok: bool = false
	for unit_data in gs.player_roster:
		if unit_data.class_id == "cavalier":
			cav_ok = unit_data.movement == 7
			break
	if cav_ok:
		print("OK  default-roster Cavalier movement is 7"); passed += 1
	else:
		print("FAIL default-roster Cavalier movement should be 7"); failed += 1

	# ---- load_roster_from_directory loads a fixed test roster ----
	gs.load_roster_from_directory("res://data/roster/test/map_900_hotseat_validation/")
	if gs.player_roster.size() == 2:
		print("OK  load_roster_from_directory loads the fixed test roster (2 units)")
		passed += 1
	else:
		print("FAIL load_roster_from_directory: roster size = %d (want 2)" % gs.player_roster.size())
		failed += 1

	# ---- configure_next_map stores the next map path + roster policy ----
	gs.configure_next_map("res://data/maps/map_001_rout/map_001_c3_factions_data.tres",
		"default_roster", "res://data/roster/default/")
	if gs.next_map_data_path == "res://data/maps/map_001_rout/map_001_c3_factions_data.tres" \
			and gs.next_map_roster_policy == "default_roster" \
			and gs.next_map_roster_source == "res://data/roster/default/":
		print("OK  configure_next_map stores selector launch state"); passed += 1
	else:
		print("FAIL configure_next_map: path=%s policy=%s source=%s" % [
			gs.next_map_data_path, gs.next_map_roster_policy, gs.next_map_roster_source]); failed += 1

	# ---- M14 stage 2: are_hostile uses the alliance-group model ----
	# Default groups: {blue,green} (allies), {red} (foes), {yellow} (rogues).
	var hostility_ok: bool = (
		not gs.are_hostile("blue", "blue")          # same id → never hostile
		and not gs.are_hostile("blue", "green")     # same alliance group "allies"
		and not gs.are_hostile("green", "blue")     # symmetric
		and gs.are_hostile("blue", "red")           # different groups
		and gs.are_hostile("green", "red")          # green ally is hostile to red
		and gs.are_hostile("yellow", "blue")        # yellow fights everyone
		and gs.are_hostile("yellow", "red")
		and gs.are_hostile("yellow", "green")
		and gs.are_hostile("blue", "")              # unknown ("") is its own group
		and gs.are_hostile("blue", "purple")        # unmapped → hostile to all mapped
	)
	if hostility_ok:
		print("OK  are_hostile: alliance-group model matches the GDD"); passed += 1
	else:
		print("FAIL are_hostile: alliance-group check failed"); failed += 1

	# ---- M14 stage 3: per-faction buckets via get_living_units_of() ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20))
	gs.register_unit(_mk_unit("blue", 0))    # dead — excluded by living filter
	gs.register_unit(_mk_unit("red", 20))
	gs.register_unit(_mk_unit("green", 20))  # 4-faction-ready
	gs.register_unit(_mk_unit("yellow", 0))  # dead yellow
	var bucket_ok: bool = (
		gs.get_living_units_of("blue").size() == 1
		and gs.get_living_units_of("red").size() == 1
		and gs.get_living_units_of("green").size() == 1
		and gs.get_living_units_of("yellow").is_empty()         # only the dead one was registered
		and gs.get_living_units_of("purple").is_empty()         # never registered
	)
	if bucket_ok:
		print("OK  get_living_units_of: per-faction buckets, excludes dead, returns [] for unknowns"); passed += 1
	else:
		print("FAIL get_living_units_of: blue=%d red=%d green=%d yellow=%d purple=%d" % [
			gs.get_living_units_of("blue").size(),
			gs.get_living_units_of("red").size(),
			gs.get_living_units_of("green").size(),
			gs.get_living_units_of("yellow").size(),
			gs.get_living_units_of("purple").size(),
		])
		failed += 1

	# ---- legacy aliases still work: blue → player wrapper, hostile-to-blue → enemy wrapper ----
	var alias_ok: bool = (
		gs.get_living_player_units().size() == 1            # blue
		and gs.get_living_enemy_units().size() == 1         # red is hostile to blue; green is ally; yellow has no live unit
	)
	if alias_ok:
		print("OK  get_living_player_units == get_living_units_of('blue'); enemy alias hostility-aware"); passed += 1
	else:
		print("FAIL legacy aliases: player=%d enemy=%d" % [
			gs.get_living_player_units().size(),
			gs.get_living_enemy_units().size(),
		])
		failed += 1

	# ---- get_alliance_group returns the group name; unknown id falls back to itself ----
	var group_ok: bool = (
		gs.get_alliance_group("blue") == "allies"
		and gs.get_alliance_group("green") == "allies"
		and gs.get_alliance_group("red") == "foes"
		and gs.get_alliance_group("yellow") == "rogues"
		and gs.get_alliance_group("purple") == "purple"  # unmapped → own group
	)
	if group_ok:
		print("OK  get_alliance_group: known ids resolve, unknown id is its own group"); passed += 1
	else:
		print("FAIL get_alliance_group: lookup result mismatch"); failed += 1

	# ---- take_map_snapshot / restore_map_snapshot: a hp change rolls back ----
	var ud := UnitData.new()
	ud.hp = 20
	ud.max_hp = 20
	var roster: Array[UnitData] = [ud]
	gs.player_roster = roster
	gs.take_map_snapshot()
	ud.hp = 3                       # simulate battle damage
	gs.restore_map_snapshot()
	if ud.hp == 20:
		print("OK  snapshot round-trip: restore_map_snapshot rolls hp back to 20"); passed += 1
	else:
		print("FAIL snapshot round-trip: hp=%d (want 20)" % ud.hp); failed += 1

	# ---- Debug hotkey handler flips the matching flag in debug builds ----
	# Headless tests run via the Godot binary which OS.is_debug_build() reports
	# true for, so we exercise the active path here. The handler ignores events
	# entirely in release; that branch is verified by inspection of the early
	# return in GameState._unhandled_input.
	if OS.is_debug_build():
		gs.debug_force_levelup = false
		gs.debug_growth_boost = false
		# InputEventAction carries an action name + pressed flag; the handler's
		# event.is_action_pressed() lookup matches it via InputMap.
		var ev_fl := InputEventAction.new()
		ev_fl.action = "debug_toggle_force_levelup"
		ev_fl.pressed = true
		gs._unhandled_input(ev_fl)
		var force_ok: bool = gs.debug_force_levelup == true
		gs._unhandled_input(ev_fl)  # second press toggles back off
		force_ok = force_ok and (gs.debug_force_levelup == false)

		var ev_gb := InputEventAction.new()
		ev_gb.action = "debug_toggle_growth_boost"
		ev_gb.pressed = true
		gs._unhandled_input(ev_gb)
		var growth_ok: bool = gs.debug_growth_boost == true
		gs._unhandled_input(ev_gb)
		growth_ok = growth_ok and (gs.debug_growth_boost == false)

		if force_ok and growth_ok:
			print("OK  debug hotkeys toggle force_levelup / growth_boost on and back off"); passed += 1
		else:
			print("FAIL debug hotkeys: force_ok=%s growth_ok=%s" % [force_ok, growth_ok])
			failed += 1
		var force_events: Array = InputMap.action_get_events("debug_toggle_force_levelup")
		var growth_events: Array = InputMap.action_get_events("debug_toggle_growth_boost")
		var binding_ok: bool = (
			not force_events.is_empty()
			and not growth_events.is_empty()
			and force_events[0] is InputEventKey
			and growth_events[0] is InputEventKey
			and force_events[0].keycode == KEY_F10
			and growth_events[0].keycode == KEY_F11
		)
		if binding_ok:
			print("OK  debug keybindings: force-levelup on F10, growth-boost on F11"); passed += 1
		else:
			print("FAIL debug keybindings: force=%s growth=%s" % [
				str(force_events), str(growth_events)])
			failed += 1
	else:
		print("SKIP debug hotkey test (not a debug build)")

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
