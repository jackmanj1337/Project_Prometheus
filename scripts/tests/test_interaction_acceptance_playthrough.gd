extends SceneTree
# SLICE 7 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: THE PLAYTHROUGH HALF.
#
# `test_interaction_acceptance_pack.gd` is the MEASUREMENT half: it asks the pack what
# it declares and drives the resolver with stub combatants. This is the other half the
# row's completion bar names -- the pack PLAYED: activated through the real path, its
# campaign started, its chapters cleared through CampaignManager/Prep/GameMap, and the
# authored relationship fired inside a fight the runtime actually COMMITTED, on real
# Unit nodes spawned onto the authored board.
#
# WHY THAT DISTINCTION IS NOT PEDANTRY. A stub answers every question the resolver asks,
# so a measurement cannot tell a reachable relationship from an unreachable one. Both
# findings below are invisible to the measurement suite and were found by this file on
# its first run.
#
# THE TWO ROUTES, AND WHY NEITHER IS ENOUGH ALONE. The acceptance content needs two
# things in scope at once: the interaction PROFILES, which `CampaignManager.start_campaign`
# applies from the campaign document, and the hallowed BEARER, who exists only in
# `roster_map_006_hallowed`. No single route supplies both -- see the two `route gap`
# checks. So the content proof forces them together, and says so rather than hiding it
# behind a helper. `[ITR-1..7]`

const AdopterPack = preload("res://scripts/tests/support/adopter_pack.gd")

const PACK_RELATIVE_PATH := "Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds"
const PACK_ID := "prometheus-proving-grounds-internal-fe"
const PACK_VERSION := "0.1.0"
const CAMPAIGN_ID := "proving_grounds"
const GAME_MAP_SCENE := "res://scenes/core/GameMap.tscn"
const PREP_SCENE := "res://scenes/ui/PrepScreen.tscn"
const ACCEPTANCE_MAP := "map_006_hallowed"

# Same guard as the measurement suite: a checkout on a branch without the authored
# content must fail with the reason, not as a wall of bare assertion failures.
const REQUIRED_ENTRY_IDS := [
	"revenant",
	"hallowed_scythe",
	"conditions__hallowed_sear",
	"campaign_vars__hallow_charge",
	"map_006_hallowed",
	"roster_map_006_hallowed",
]

# The campaign's six chapters and the deterministic probe that satisfies each. These are
# playability probes, not balance evidence -- the same split `test_v0717_campaign_playability.gd`
# draws, and for the same reason: a headless rout says the seam works, never that the
# fight was fair.
const CHAPTERS := [
	{"node_id": "node_01_rout", "map_id": "map_001", "objective": "rout"},
	{"node_id": "node_02_seize", "map_id": "map_002_seize", "objective": "seize"},
	{"node_id": "node_03_boss", "map_id": "map_003_defeat_boss", "objective": "defeat_boss"},
	{"node_id": "node_04_escape", "map_id": "map_004_escape", "objective": "escape"},
	{"node_id": "node_05_defend", "map_id": "map_005_defend", "objective": "survive"},
	{"node_id": "node_06_hallowed", "map_id": ACCEPTANCE_MAP, "objective": "rout"},
]

var _passed := 0
var _failed := 0
# A GDScript runtime error aborts the awaiting call and hands control back, so `_finish`
# still runs and still prints "0 failed". The first run of this file did exactly that --
# a wrong autoload method name killed the last check and the suite reported green. This
# flag is the difference between "every check passed" and "the run reached the end".
var _reached_the_end := false
var _dm: Node
var _gs: Node
var _cm: Node
var _cr: Node
var _conditions: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Interaction Acceptance Playthrough ===")
	await process_frame

	var located := AdopterPack.locate(PACK_RELATIVE_PATH)
	if located["state"] == AdopterPack.ABSENT:
		print("SKIP %s" % located["detail"])
		quit(0)
		return
	if located["state"] == AdopterPack.MISSING:
		print("FAIL %s" % located["detail"])
		quit(1)
		return
	var declared := AdopterPack.require_entries(located["path"], REQUIRED_ENTRY_IDS)
	if not declared["ok"]:
		print("FAIL %s" % declared["detail"])
		quit(1)
		return

	_dm = root.get_node_or_null("DataManager")
	_gs = root.get_node_or_null("GameState")
	_cm = root.get_node_or_null("CampaignManager")
	_cr = root.get_node_or_null("CombatResolver")
	_conditions = root.get_node_or_null("ConditionManager")
	if _dm == null or _gs == null or _cm == null or _cr == null or _conditions == null:
		_fail("DataManager, GameState, CampaignManager, CombatResolver and ConditionManager exist")
		_finish()
		return

	var activated: bool = _dm.call(
		"select_tier2_campaign_source", located["path"], PACK_ID, PACK_VERSION
	)
	_check(activated, "the acceptance pack activates through the real path")
	if not activated:
		print("   activation errors: %s" % str(_dm.get("_activation_errors")))
		_finish()
		return

	await _route_gap_checks()
	await _play_the_campaign()
	await _content_proof()
	_finish()


# --- the two route gaps -------------------------------------------------------------
# Both are asserted rather than written in a comment, because a comment does not fail
# when someone fixes the roster policy and forgets this file.
func _route_gap_checks() -> void:
	# ROUTE A -- the map's own registry row. Its authored roster loads, so the bearer is
	# on the field, but nothing has started a campaign, so no profile is in scope and the
	# relationship cannot fire at all.
	var entry: Dictionary = _dm.call("get_map_registry_entry", ACCEPTANCE_MAP)
	_check(not entry.is_empty(), "%s is registered as a standalone map" % ACCEPTANCE_MAP)
	_load_pack_roster(entry)
	_check(
		_party_has_weapon("hallowed_scythe"),
		"route A (standalone map): the authored roster fields the hallowed_scythe bearer"
	)
	_check(
		_profile_ids().is_empty(),
		(
			"route gap A: ...but no campaign started, so interaction_profiles is empty: %s"
			% str(_profile_ids())
		)
	)

	# ROUTE B -- the campaign. Profiles arrive, but CampaignManager forces
	# keep_current_roster on every node after the first, so chapter 6 fields whatever the
	# party earned -- and roster_default has no light-family weapon in it.
	_check(bool(_cm.call("start_campaign", CAMPAIGN_ID)), "route B (campaign): it starts")
	var ids := _profile_ids()
	_check(
		ids.has("hallowed_rites") and ids.has("undead_frailty"),
		"route B: the campaign puts the acceptance profiles in scope: %s" % str(ids)
	)
	var cleared: Array = _cm.get("cleared_node_ids")
	cleared.append("node_01_rout")
	var node: Variant = _cm.call("get_current_node")
	var params: Dictionary = _cm.call("resolve_launch_params", node)
	cleared.clear()
	_check(
		String(params.get("roster_policy", "")) == "keep_current_roster",
		(
			(
				"route gap B: ...but any node after the first forces roster_policy=%s, "
				+ "so roster_map_006_hallowed never loads in campaign play"
			)
			% String(params.get("roster_policy", ""))
		)
	)


# --- the campaign, played ------------------------------------------------------------
func _play_the_campaign() -> void:
	_check(bool(_cm.call("start_campaign", CAMPAIGN_ID)), "the campaign restarts for the run")
	for chapter in CHAPTERS:
		await _play_chapter(chapter)
	var cleared: Array = _cm.get("cleared_node_ids")
	_check(
		cleared.size() == CHAPTERS.size(),
		"the pack plays end to end (%d/%d chapters cleared)" % [cleared.size(), CHAPTERS.size()]
	)


func _play_chapter(chapter: Dictionary) -> void:
	var node_id := String(chapter["node_id"])
	var map_id := String(chapter["map_id"])
	print("\n--- %s (%s) ---" % [node_id, map_id])
	if String(_cm.get("current_node_id")) != node_id:
		_fail("%s is the current campaign node" % node_id)
		return

	if not bool(_cm.call("launch_current_node")):
		_fail("%s launches" % map_id)
		return
	await _settle()
	_check(
		current_scene != null and current_scene.scene_file_path == PREP_SCENE,
		"%s reaches Prep" % map_id
	)

	var plan := _deployment_plan()
	_check(not plan.is_empty(), "%s has a legal deployment plan" % map_id)
	_gs.call("set_next_map_deployment", plan)
	if not bool(_cm.call("begin_prepared_battle")):
		_fail("%s begins from Prep" % map_id)
		return
	await _settle()

	var battle: Node = current_scene
	_check(
		battle != null and battle.scene_file_path == GAME_MAP_SCENE, "%s reaches GameMap" % map_id
	)
	if battle == null:
		return
	var turn_manager: Node = battle.get_node_or_null("TurnManager")
	if turn_manager == null:
		_fail("%s has a TurnManager" % map_id)
		return

	# CHAPTER 6 IS THE ONE THIS SUITE EXISTS FOR, so record what a player actually holds
	# when they get here. This is route gap B observed on the board rather than inferred
	# from the launch params.
	if map_id == ACCEPTANCE_MAP:
		_check(
			not _party_has_weapon("hallowed_scythe"),
			(
				"route gap B, on the board: chapter 6 fields NO hallowed_scythe -- "
				+ "the acceptance weapon is unreachable by playing the campaign"
			)
		)

	if not _resolve_objective(turn_manager, String(chapter["objective"])):
		_fail("%s objective probe is accepted by the runtime" % map_id)
		return
	await process_frame

	var pending: Dictionary = _cm.call("get_pending_result")
	_check(bool(pending.get("victory", false)), "%s resolves as victory" % map_id)
	if not bool(pending.get("victory", false)):
		return
	var next_id := String(pending.get("next_node_id", ""))
	if not bool(_cm.call("commit_pending_result")):
		_fail("%s commits campaign progression" % map_id)
		return
	_check(
		String(_cm.get("current_node_id")) == next_id,
		"%s advances to %s" % [map_id, next_id if next_id != "" else "terminal"]
	)


# --- the content proof ----------------------------------------------------------------
# Both halves forced into scope at once, because no player route does it. The fight is a
# real one: real Unit nodes spawned by GameMap onto the authored board, resolved AND
# COMMITTED -- resolve_combat only PREPARES the transaction, so a proof that stopped at
# its return value would see no condition and read as a broken seam.
func _content_proof() -> void:
	print("\n--- content proof: the authored relationship, in a committed fight ---")
	_cm.call("start_campaign", CAMPAIGN_ID)
	var entry: Dictionary = _dm.call("get_map_registry_entry", ACCEPTANCE_MAP)
	_load_pack_roster(entry)
	_check(
		_party_has_weapon("hallowed_scythe") and not _profile_ids().is_empty(),
		"the proof forces both halves into scope (bearer + profiles)"
	)

	var plan := _deployment_plan()
	_gs.call("set_next_map_deployment", plan)
	change_scene_to_file(GAME_MAP_SCENE)
	await _settle()
	var battle: Node = current_scene
	_check(
		battle != null and battle.scene_file_path == GAME_MAP_SCENE,
		"the authored board loads as a real battle"
	)
	if battle == null:
		return

	var bearer := _find_unit("m006_hallowed_bearer")
	var axeman := _find_unit("m006_plain_axeman")
	var undead := _find_unit("m006_revenant_1")
	var undead_control := _find_unit("m006_revenant_2")
	if bearer == null or axeman == null or undead == null or undead_control == null:
		_fail("the authored board spawns the bearer, the control axeman and two revenants")
		return
	_pass("the authored board spawns the bearer, the control axeman and two revenants")

	# THE PACK'S OWN A/B. `m006_plain_axeman` carries an iron axe and no light-family
	# weapon, so `sear_the_undead` cannot fire for him and `undead_weakness` is not
	# suppressed. He is why the pack has a second player unit at all, and he is the
	# honest control: re-attacking the SAME pair reuses a per-direction ledger and
	# silently measures the first fight twice.
	var bearer_damage := _committed_damage(bearer, undead)
	var control_damage := _committed_damage(axeman, undead_control)
	_check(
		bearer_damage > control_damage,
		(
			"the light-node weapon hits an undead harder than the plain axe does: %d vs %d"
			% [bearer_damage, control_damage]
		)
	)
	_check(
		bool(_conditions.call("has_condition", undead, "hallowed_sear")),
		"...and the NON-TERM effect commits: hallowed_sear is on the target after apply"
	)
	_check(
		not bool(_conditions.call("has_condition", undead_control, "hallowed_sear")),
		"...while the control fight applies no condition at all"
	)

	# FORMULA-SCALED, not a constant dressed as one: the condition's duration IS
	# `hallow_charge`, so reading the var back is what separates the two.
	var vars_node := root.get_node_or_null("CampaignVars")
	var charge := int(vars_node.call("get_var", "hallow_charge")) if vars_node != null else -1
	var duration := _condition_turns(undead, "hallowed_sear")
	_check(
		charge > 0 and duration == charge,
		(
			"...for a duration read off campaign_var hallow_charge: %d turns, charge %d"
			% [duration, charge]
		)
	)
	_reached_the_end = true


# --- helpers ---------------------------------------------------------------------------
func _committed_damage(attacker: Node, defender: Node) -> int:
	defender.tile_position = attacker.tile_position + Vector2i(1, 0)
	var before := int(defender.get("data").get("hp"))
	var result: Dictionary = _cr.call("resolve_combat", attacker, defender)
	_cr.call("apply_combat_result", result, attacker, defender)
	return before - int(defender.get("data").get("hp"))


func _condition_turns(unit: Node, condition_id: String) -> int:
	for entry in _conditions.call("conditions_of", unit):
		if String((entry as Dictionary).get("type", "")) == condition_id:
			return int((entry as Dictionary).get("turns_remaining", 0))
	return -1


func _find_unit(unit_id: String) -> Node:
	for unit in _gs.get("all_units"):
		var data: Variant = unit.get("data")
		if data != null and String(data.get("unit_id")) == unit_id:
			return unit
	return null


func _load_pack_roster(entry: Dictionary) -> void:
	_gs.call(
		"configure_next_map",
		String(entry["map_data_path"]),
		"campaign_pack_roster",
		String(entry["roster_source"])
	)
	var roster: Array = _dm.call("get_campaign_pack_roster", String(entry["roster_source"]))
	_gs.call(
		"load_roster_resources", roster, "campaign_pack_roster", String(entry["roster_source"])
	)


func _party_has_weapon(weapon_id: String) -> bool:
	for unit_data in _gs.get("player_roster"):
		for slot in unit_data.get("inventory"):
			if slot != null and String(slot.get("weapon_id")) == weapon_id:
				return true
	return false


func _profile_ids() -> Array:
	var rules: Variant = _gs.get("campaign_rules")
	if rules == null:
		return []
	var out: Array = []
	for profile in rules.get("interaction_profiles"):
		out.append(String((profile as Dictionary).get("profile_id", "")))
	return out


func _deployment_plan() -> Dictionary:
	var path := String(_gs.get("next_map_data_path"))
	var resolved: Variant = _dm.call("resolve_battle_source", path)
	if resolved == null:
		return {}
	var map_data: Variant = resolved.get("battle_map")
	if map_data == null:
		return {}
	var tiles: Array = map_data.get("player_start_tiles")
	var roster: Array = _gs.get("player_roster")
	var plan := {}
	for i in range(mini(roster.size(), tiles.size())):
		var unit_data: Variant = roster[i]
		if unit_data != null and String(unit_data.get("unit_id")) != "":
			plan[String(unit_data.get("unit_id"))] = tiles[i]
	return plan


# Deterministic objective probes, lifted from test_v0717_campaign_playability.gd because
# the campaign is the same six objectives over the pack's copy of those maps.
func _resolve_objective(turn_manager: Node, objective: String) -> bool:
	var units: Array = _gs.get("all_units")
	match objective:
		"rout":
			for unit in units:
				if unit != null and String(unit.get("team")) != "blue" and unit.get("data") != null:
					unit.data.hp = 0
			turn_manager.call("check_victory_conditions")
			return true
		"seize":
			var lord := _find_unit("unit_01_cavalier")
			if lord == null:
				return false
			lord.tile_position = Vector2i(15, 2)
			turn_manager.call("record_seize", lord)
			return true
		"defeat_boss":
			var boss := _find_unit("m003_boss")
			if boss == null or boss.get("data") == null:
				return false
			boss.data.hp = 0
			turn_manager.call("check_victory_conditions")
			return true
		"escape":
			var lord := _find_unit("unit_01_cavalier")
			var merc := _find_unit("unit_02_mercenary")
			if lord == null or merc == null:
				return false
			lord.tile_position = Vector2i(16, 2)
			merc.tile_position = Vector2i(16, 3)
			turn_manager.call("record_escape", lord)
			turn_manager.call("record_escape", merc)
			return true
		"survive":
			_gs.set("turn_number", 7)
			turn_manager.call("start_player_phase")
			return true
	return false


func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame


func _pass(message: String) -> void:
	_passed += 1
	print("OK  " + message)


func _fail(message: String) -> void:
	_failed += 1
	print("FAIL " + message)


func _check(condition: bool, message: String) -> void:
	if condition:
		_pass(message)
	else:
		_fail(message)


func _finish() -> void:
	if not _reached_the_end:
		_failed += 1
		print("FAIL the run did not reach the end of the content proof -- see the error above")
	print("\n=== Playthrough Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
