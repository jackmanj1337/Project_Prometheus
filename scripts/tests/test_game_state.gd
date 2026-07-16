extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_game_state.gd
# Tests GameState: the unit registry, the living-unit filters, phase tracking,
# reset_map_state, the default-roster load, and the map-snapshot round-trip.
# test_snapshot_coverage already verifies _snapshot_unit_data's FIELD coverage —
# this suite covers the behavioural round-trip and the rest of the API.

var _unit_stub: GDScript


func _mk_unit(team_name: String, hp: int, unit_id: String = "") -> Node:
	var d := UnitData.new()
	d.hp = hp
	d.max_hp = 20
	d.unit_id = unit_id
	var u: Node = _unit_stub.new()
	u.set("team", team_name)
	u.set("data", d)
	root.add_child(u)
	return u


func _has_property(obj: Object, property_name: String) -> bool:
	for info in obj.get_property_list():
		if String(info.get("name", "")) == property_name:
			return true
	return false


func _init() -> void:
	print("=== GameState Test ===")
	var passed := 0
	var failed := 0

	_unit_stub = GDScript.new()
	_unit_stub.source_code = 'extends Node\nvar team: String = "blue"\nvar data = null\n'
	_unit_stub.reload()

	var dm: Node = load("res://scripts/autoloads/DataManager.gd").new()
	dm.name = "DataManager"
	root.add_child(dm)

	var gs: Node = load("res://scripts/autoloads/GameState.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	# PairUpRegistry is consulted by get_living_units_of so paired supports
	# are excluded; load it as an autoload-equivalent for tests that pair units.
	var pair_reg: Node = load("res://scripts/autoloads/PairUpRegistry.gd").new()
	pair_reg.name = "PairUpRegistry"
	root.add_child(pair_reg)
	await process_frame

	var rules: CampaignRules = gs.get("campaign_rules") as CampaignRules
	if (
		rules != null
		and not rules.permadeath_enabled
		and rules.leveling_method == "growth_random"
		and not rules.auto_promote_at_max_level
		and rules.pair_up_enabled
		and rules.max_skills == 5
		and rules.max_inventory == 8
		and rules.exp_gaining_factions == (["blue", "green"] as Array[String])
		and rules.hit_formula == "two_roll"
		and rules.rewind_charges_per_map == 4
	):
		print("OK  CampaignRules defaults match the campaign/save contract")
		passed += 1
	else:
		print("FAIL CampaignRules defaults: %s" % [rules])
		failed += 1

	var loose_fields_gone := true
	for field in [
		"permadeath_enabled",
		"leveling_method",
		"auto_promote_at_max_level",
		"pair_up_enabled",
		"max_skills",
		"max_inventory",
		"exp_gaining_factions",
	]:
		loose_fields_gone = loose_fields_gone and not _has_property(gs, field)
	if loose_fields_gone:
		print("OK  loose GameState rule fields are removed")
		passed += 1
	else:
		print("FAIL loose GameState rule field still exists")
		failed += 1

	# ---- register_unit adds the unit to all_units ----
	var p1 := _mk_unit("blue", 20)
	gs.register_unit(p1)
	if p1 in gs.all_units:
		print("OK  register_unit adds the unit to all_units")
		passed += 1
	else:
		print("FAIL register_unit")
		failed += 1

	# ---- register_unit ignores a double registration (a push_error is expected) ----
	var before: int = gs.all_units.size()
	gs.register_unit(p1)
	if gs.all_units.size() == before:
		print("OK  register_unit: a double registration is ignored")
		passed += 1
	else:
		print("FAIL register_unit double")
		failed += 1

	# ---- the living-unit getters separate units by team ----
	gs.reset_map_state()
	var pa := _mk_unit("blue", 20)
	var ea := _mk_unit("red", 20)
	gs.register_unit(pa)
	gs.register_unit(ea)
	var lp: Array = gs.get_living_player_units()
	var le: Array = gs.get_living_enemy_units()
	if lp.size() == 1 and lp[0] == pa and le.size() == 1 and le[0] == ea:
		print("OK  get_living_player/enemy_units separate units by team")
		passed += 1
	else:
		print("FAIL living getters: players=%d enemies=%d" % [lp.size(), le.size()])
		failed += 1

	# ---- get_living_player_units excludes a dead (hp 0) unit ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20))
	gs.register_unit(_mk_unit("blue", 0))  # dead
	if gs.get_living_player_units().size() == 1:
		print("OK  get_living_player_units excludes a dead unit")
		passed += 1
	else:
		print("FAIL living excludes dead: got %d" % gs.get_living_player_units().size())
		failed += 1

	# ---- get_living_units_of excludes a paired support ----
	# A paired support has its tile moved off-grid and its lead has already
	# consumed the joint action. Counting it as living inflated
	# are_all_units_done so auto-end-turn never fired (code review 2026-06-09).
	gs.reset_map_state()
	pair_reg.call("clear")
	var lead := _mk_unit("blue", 20, "pp_lead")
	var support := _mk_unit("blue", 20, "pp_support")
	gs.register_unit(lead)
	gs.register_unit(support)
	var paired_ok: bool = pair_reg.pair("pp_lead", "pp_support")
	var live_after_pair: Array = gs.get_living_units_of("blue")
	if paired_ok and live_after_pair.size() == 1 and live_after_pair[0] == lead:
		print("OK  get_living_units_of excludes a paired support")
		passed += 1
	else:
		print(
			(
				"FAIL paired support filter: paired=%s live_count=%d"
				% [paired_ok, live_after_pair.size()]
			)
		)
		failed += 1

	# ---- after Separate the support is counted again ----
	pair_reg.call("separate", "pp_lead")
	var live_after_sep: Array = gs.get_living_units_of("blue")
	if live_after_sep.size() == 2:
		print("OK  get_living_units_of counts the support again after Separate")
		passed += 1
	else:
		print("FAIL paired support filter after Separate: %d" % live_after_sep.size())
		failed += 1

	# ---- unregister_unit removes the unit from every list ----
	gs.reset_map_state()
	var ru := _mk_unit("blue", 20)
	gs.register_unit(ru)
	gs.unregister_unit(ru)
	if not (ru in gs.all_units) and gs.get_living_player_units().is_empty():
		print("OK  unregister_unit removes the unit from all lists")
		passed += 1
	else:
		print("FAIL unregister_unit")
		failed += 1

	# ---- get_registered_faction_ids: returns every faction id with a unit ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20))
	gs.register_unit(_mk_unit("red", 20))
	gs.register_unit(_mk_unit("green", 20))
	var fids: Array[String] = gs.get_registered_faction_ids()
	fids.sort()
	if fids == (["blue", "green", "red"] as Array[String]):
		print("OK  get_registered_faction_ids returns every registered faction")
		passed += 1
	else:
		print("FAIL get_registered_faction_ids: %s" % str(fids))
		failed += 1

	# ---- set_phase / is_player_turn track the current phase ----
	gs.set_phase(gs.Phase.ENEMY)
	var on_enemy: bool = not gs.is_player_turn()
	gs.set_phase(gs.Phase.PLAYER)
	if on_enemy and gs.is_player_turn():
		print("OK  set_phase / is_player_turn track the current phase")
		passed += 1
	else:
		print("FAIL set_phase / is_player_turn")
		failed += 1

	# ---- reset_map_state clears units and resets turn_number / phase ----
	gs.register_unit(_mk_unit("blue", 20))
	gs.turn_number = 9
	gs.set_phase(gs.Phase.ENEMY)
	gs.reset_map_state()
	if gs.all_units.is_empty() and gs.turn_number == 1 and gs.is_player_turn():
		print("OK  reset_map_state clears units, turn_number → 1, phase → PLAYER")
		passed += 1
	else:
		print("FAIL reset_map_state")
		failed += 1

	# ---- load_default_roster populates player_roster and explicit roster state ----
	var default_ok: bool = gs.load_default_roster()
	if (
		default_ok
		and gs.player_roster.size() > 0
		and gs.roster_initialized
		and not gs.roster_load_failed
		and gs.active_roster_policy == "default_roster"
		and gs.active_roster_source == "res://data/roster/default/"
	):
		print("OK  load_default_roster loads the roster (%d units)" % gs.player_roster.size())
		passed += 1
	else:
		print("FAIL load_default_roster: roster is empty")
		failed += 1

	# ---- export-safe roster manifest lists the default roster in slot order ----
	var ResourceManifest = load("res://scripts/shared/ResourceManifest.gd")
	var roster_manifest: Array[String] = ResourceManifest.load_paths("res://data/roster/default/")
	if roster_manifest.size() == 6 and roster_manifest[0].ends_with("unit_01_cavalier.tres"):
		print("OK  default roster manifest preserves deployment order")
		passed += 1
	else:
		print("FAIL default roster manifest: %s" % [roster_manifest])
		failed += 1

	# ---- default roster Cavalier movement matches authored class intent ----
	var cav_ok: bool = false
	for unit_data in gs.player_roster:
		if unit_data.class_id == "cavalier":
			cav_ok = unit_data.movement == 7
			break
	if cav_ok:
		print("OK  default-roster Cavalier movement is 7")
		passed += 1
	else:
		print("FAIL default-roster Cavalier movement should be 7")
		failed += 1

	# ---- load_roster_from_directory loads a fixed test roster ----
	var fixed_ok: bool = gs.load_roster_from_directory(
		"res://data/roster/test/map_900_hotseat_validation/", "fixed_test_roster"
	)
	if (
		fixed_ok
		and gs.player_roster.size() == 2
		and gs.roster_initialized
		and not gs.roster_load_failed
		and gs.active_roster_policy == "fixed_test_roster"
		and gs.active_roster_source == "res://data/roster/test/map_900_hotseat_validation/"
	):
		print("OK  load_roster_from_directory loads the fixed test roster (2 units)")
		passed += 1
	else:
		print(
			"FAIL load_roster_from_directory: roster size = %d (want 2)" % gs.player_roster.size()
		)
		failed += 1

	# ---- bad roster path fails loud and does not leave stale roster state behind ----
	var missing_ok: bool = not gs.load_roster_from_directory(
		"res://data/roster/test/does_not_exist/", "fixed_test_roster"
	)
	if (
		missing_ok
		and gs.player_roster.is_empty()
		and not gs.roster_initialized
		and gs.roster_load_failed
		and gs.active_roster_policy == ""
	):
		print("OK  missing roster path fails without silently leaving an old roster active")
		passed += 1
	else:
		print(
			(
				"FAIL missing roster path state: size=%d initialized=%s failed=%s policy=%s"
				% [
					gs.player_roster.size(),
					gs.roster_initialized,
					gs.roster_load_failed,
					gs.active_roster_policy
				]
			)
		)
		failed += 1

	# ---- configure_next_map stores the next map path + roster policy ----
	gs.configure_next_map(
		"res://data/maps/map_001_rout/map_001_c3_factions_data.tres",
		"default_roster",
		"res://data/roster/default/"
	)
	if (
		gs.next_map_data_path == "res://data/maps/map_001_rout/map_001_c3_factions_data.tres"
		and gs.next_map_roster_policy == "default_roster"
		and gs.next_map_roster_source == "res://data/roster/default/"
	):
		print("OK  configure_next_map stores selector launch state")
		passed += 1
	else:
		print(
			(
				"FAIL configure_next_map: path=%s policy=%s source=%s"
				% [gs.next_map_data_path, gs.next_map_roster_policy, gs.next_map_roster_source]
			)
		)
		failed += 1

	# ---- is_roster_ready_for_launch requires explicit roster prep that matches the launch policy ----
	gs.load_default_roster()
	gs.configure_next_map("res://data/maps/map_001_rout/map_001_data.tres", "default_roster", "")
	var launch_default_ok: bool = gs.is_roster_ready_for_launch()
	gs.configure_next_map(
		"res://data/maps/map_900_hotseat_validation/map_900_hotseat_validation_data.tres",
		"fixed_test_roster",
		"res://data/roster/test/map_900_hotseat_validation/"
	)
	var launch_fixed_mismatch_ok: bool = not gs.is_roster_ready_for_launch()
	gs.load_roster_from_directory(
		"res://data/roster/test/map_900_hotseat_validation/", "fixed_test_roster"
	)
	var launch_fixed_ok: bool = gs.is_roster_ready_for_launch()
	if launch_default_ok and launch_fixed_mismatch_ok and launch_fixed_ok:
		print("OK  is_roster_ready_for_launch enforces explicit roster prep per policy")
		passed += 1
	else:
		print(
			(
				"FAIL is_roster_ready_for_launch: default=%s mismatch=%s fixed=%s"
				% [launch_default_ok, launch_fixed_mismatch_ok, launch_fixed_ok]
			)
		)
		failed += 1

	# ---- M14 stage 2: are_hostile uses the alliance-group model ----
	# Default groups: {blue,green} (allies), {red} (foes), {yellow} (rogues).
	var hostility_ok: bool = (
		not gs.are_hostile("blue", "blue")  # same id → never hostile
		and not gs.are_hostile("blue", "green")  # same alliance group "allies"
		and not gs.are_hostile("green", "blue")  # symmetric
		and gs.are_hostile("blue", "red")  # different groups
		and gs.are_hostile("green", "red")  # green ally is hostile to red
		and gs.are_hostile("yellow", "blue")  # yellow fights everyone
		and gs.are_hostile("yellow", "red")
		and gs.are_hostile("yellow", "green")
		and gs.are_hostile("blue", "")  # unknown ("") is its own group
		and gs.are_hostile("blue", "purple")
	)  # unmapped → hostile to all mapped
	if hostility_ok:
		print("OK  are_hostile: alliance-group model matches the GDD")
		passed += 1
	else:
		print("FAIL are_hostile: alliance-group check failed")
		failed += 1

	# ---- M14 stage 3: per-faction buckets via get_living_units_of() ----
	gs.reset_map_state()
	gs.register_unit(_mk_unit("blue", 20))
	gs.register_unit(_mk_unit("blue", 0))  # dead — excluded by living filter
	gs.register_unit(_mk_unit("red", 20))
	gs.register_unit(_mk_unit("green", 20))  # 4-faction-ready
	gs.register_unit(_mk_unit("yellow", 0))  # dead yellow
	var bucket_ok: bool = (
		gs.get_living_units_of("blue").size() == 1
		and gs.get_living_units_of("red").size() == 1
		and gs.get_living_units_of("green").size() == 1
		and gs.get_living_units_of("yellow").is_empty()  # only the dead one was registered
		and gs.get_living_units_of("purple").is_empty()
	)  # never registered
	if bucket_ok:
		print(
			"OK  get_living_units_of: per-faction buckets, excludes dead, returns [] for unknowns"
		)
		passed += 1
	else:
		print(
			(
				"FAIL get_living_units_of: blue=%d red=%d green=%d yellow=%d purple=%d"
				% [
					gs.get_living_units_of("blue").size(),
					gs.get_living_units_of("red").size(),
					gs.get_living_units_of("green").size(),
					gs.get_living_units_of("yellow").size(),
					gs.get_living_units_of("purple").size(),
				]
			)
		)
		failed += 1

	# ---- legacy aliases still work: blue → player wrapper, hostile-to-blue → enemy wrapper ----
	var alias_ok: bool = (
		gs.get_living_player_units().size() == 1 and gs.get_living_enemy_units().size() == 1
	)  # blue  # red is hostile to blue; green is ally; yellow has no live unit
	if alias_ok:
		print(
			"OK  get_living_player_units == get_living_units_of('blue'); enemy alias hostility-aware"
		)
		passed += 1
	else:
		print(
			(
				"FAIL legacy aliases: player=%d enemy=%d"
				% [
					gs.get_living_player_units().size(),
					gs.get_living_enemy_units().size(),
				]
			)
		)
		failed += 1

	# ---- get_alliance_group returns the group name; unknown id falls back to itself ----
	var group_ok: bool = (
		gs.get_alliance_group("blue") == "allies"
		and gs.get_alliance_group("green") == "allies"
		and gs.get_alliance_group("red") == "foes"
		and gs.get_alliance_group("yellow") == "rogues"
		and gs.get_alliance_group("purple") == "purple"
	)  # unmapped → own group
	if group_ok:
		print("OK  get_alliance_group: known ids resolve, unknown id is its own group")
		passed += 1
	else:
		print("FAIL get_alliance_group: lookup result mismatch")
		failed += 1

	# ---- take_map_snapshot / restore_history(0): a hp change rolls back (B1-LEDGER
	# Phase 2 — Retry now reads the ledger's round-0 entry, not the old party snapshot) ----
	var ud := UnitData.new()
	ud.hp = 20
	ud.max_hp = 20
	var roster: Array[UnitData] = [ud]
	gs.player_roster = roster
	gs.take_map_snapshot()
	ud.hp = 3  # simulate battle damage
	gs.restore_history(0)
	if ud.hp == 20:
		print("OK  ledger round-trip: restore_history(0) rolls hp back to 20")
		passed += 1
	else:
		print("FAIL ledger round-trip: hp=%d (want 20)" % ud.hp)
		failed += 1

	# ---- roster-count mismatch fails loud before mutating roster state. Seed the
	# round-0 entry with a 1-unit roster, then grow player_roster so the entry no
	# longer matches — restore_history must reject without touching the unit. ----
	var bad_count_unit := UnitData.new()
	bad_count_unit.hp = 17
	bad_count_unit.max_hp = 20
	gs.player_roster = [bad_count_unit] as Array[UnitData]
	gs.take_map_snapshot()
	gs.player_roster = [bad_count_unit, UnitData.new()] as Array[UnitData]
	var count_restore_ok: bool = not gs.restore_history(0)
	if count_restore_ok and bad_count_unit.hp == 17:
		print("OK  restore_history rejects roster count mismatch without mutating roster")
		passed += 1
	else:
		print("FAIL ledger count guard: ok=%s hp=%d" % [count_restore_ok, bad_count_unit.hp])
		failed += 1

	# ---- malformed entry payload fails loud before applying any fields. Push a
	# hand-built entry with an out-of-range hp and an unknown item id straight onto
	# the ledger, so the entry validator rejects it before any partial restore. ----
	var bad_payload_unit := UnitData.new()
	bad_payload_unit.hp = 12
	bad_payload_unit.max_hp = 20
	bad_payload_unit.weapon_wexp = {"sword": 1}
	gs.player_roster = [bad_payload_unit] as Array[UnitData]
	gs._map_ledger.clear()
	(
		gs
		. _map_ledger
		. push(
			{
				"map_runtime": {},
				"party":
				{
					"gold": 0,
					"items": ["missing_item"],
					"roster":
					[
						{
							"hp": 25,
							"max_hp": 20,
							"tile_position": Vector2.ZERO,
							"inventory": {},
							"conditions": [],
							"skills": [],
							"earned_skills": [],
							"mastery_skills": [],
							"active_modifiers": [],
							"weapon_wexp": [],
							"skill_use_counters": [],
							"growth_accumulators": [],
						}
					],
				},
			},
			"round_start"
		)
	)
	var payload_restore_ok: bool = not gs.restore_history(0)
	if payload_restore_ok and bad_payload_unit.hp == 12:
		print("OK  restore_history rejects malformed payloads before partial restore")
		passed += 1
	else:
		print("FAIL ledger payload guard: ok=%s hp=%d" % [payload_restore_ok, bad_payload_unit.hp])
		failed += 1

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
			print("OK  debug hotkeys toggle force_levelup / growth_boost on and back off")
			passed += 1
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
			print("OK  debug keybindings: force-levelup on F10, growth-boost on F11")
			passed += 1
		else:
			print(
				(
					"FAIL debug keybindings: force=%s growth=%s"
					% [str(force_events), str(growth_events)]
				)
			)
			failed += 1
	else:
		print("SKIP debug hotkey test (not a debug build)")

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
