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
# THE TWO ROUTES. The acceptance content needs two things in scope at once: the
# interaction PROFILES, which `CampaignManager.start_campaign` applies from the campaign
# document, and the hallowed BEARER who carries the light-node weapon.
#
# WHEN THIS FILE WAS FIRST WRITTEN NEITHER ROUTE SUPPLIED BOTH, and it asserted that gap
# rather than describing it, so that closing the gap would fail the file instead of
# quietly leaving it stale. The gap is now closed for Route B by AUTHORING ALONE, under the
# owner ruling that closed `ROUTE-GAP-ACCEPTANCE-CONTENT-2026-09-20`: a campaign never
# swaps the army mid-run, so a chapter shapes its cast out of the party it was given. The
# bearer and the A/B control are therefore seeded into the campaign's FIRST node roster,
# where an authored roster policy IS honoured, and pinned onto chapter 6 by that node's
# `required_units` -- the node deployment constraints that were already built. So the
# content proof below runs on chapter 6's OWN board, reached by playing the campaign, with
# nothing forced into scope.
#
# ROUTE A IS STILL HALF-OPEN and this file still holds it open. Launching the map from its
# registry row fields the bearer but starts no campaign, so no ruleset is in scope at all
# and the authored relationship cannot fire. That half is ruled separately and owned by
# `STANDALONE-MAP-RULESET-2026-09-20`; the check below fails the day it lands, which is the
# point. `[ITR-1..7]`

const AdopterPack = preload("res://scripts/tests/support/adopter_pack.gd")
const PackExporter = preload("res://scripts/resources/CampaignPackExporter.gd")
const PackPreflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const PackInstaller = preload("res://scripts/resources/CampaignPackInstaller.gd")
const PackRegistry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const PackBudgets = preload("res://scripts/resources/ImportBudgets.gd")

const PACK_RELATIVE_PATH := "Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds"
const PACK_ID := "prometheus-proving-grounds-internal-fe"
const PACK_VERSION := "0.1.0"
const CAMPAIGN_ID := "proving_grounds"
const GAME_MAP_SCENE := "res://scenes/core/GameMap.tscn"
const PREP_SCENE := "res://scenes/ui/PrepScreen.tscn"
const ACCEPTANCE_MAP := "map_006_hallowed"
# Pins the gameplay dice for the two measured fights. Any fixed value works; this one is
# the date the proof moved onto chapter 6's board.
const MEASUREMENT_SEED := 20260920

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
# The proof now lives INSIDE chapter 6, so "the run reached the end" no longer implies it
# ran: a chapter that fails to launch returns early and the loop carries on to the summary.
var _content_proof_ran := false
var _dm: Node
var _gs: Node
var _cm: Node
var _cr: Node
var _conditions: Node
var _temporary_pack_build_path := ""
var _temporary_pack_archive_path := ""
var _duration_save_dir := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Interaction Acceptance Playthrough ===")
	await process_frame

	var located := AdopterPack.locate(PACK_RELATIVE_PATH)
	if located["state"] == AdopterPack.ABSENT:
		print("SKIP: %s" % located["detail"])
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
	if not _ensure_installed_pack(located["path"]):
		_fail("the acceptance pack is installed for the real suspend / Continue path")
		_finish()
		return

	await _route_checks()
	await _play_the_campaign()
	_reached_the_end = true
	_finish()


# --- the two routes -------------------------------------------------------------------
# Asserted rather than written in a comment, because a comment does not fail when someone
# changes the roster policy and forgets this file.
func _route_checks() -> void:
	# ROUTE A -- the map's own registry row. Its authored roster loads, so the bearer is
	# on the field, but nothing has started a campaign, so no profile is in scope and the
	# relationship cannot fire at all. This half of the gap is STILL OPEN.
	var entry: Dictionary = _dm.call("get_map_registry_entry", ACCEPTANCE_MAP)
	_check(not entry.is_empty(), "%s is registered as a standalone map" % ACCEPTANCE_MAP)
	_load_pack_roster(entry)
	_check(
		_party_has_weapon("hallowed_scythe"),
		"route A (standalone map): the authored roster fields the hallowed_scythe bearer"
	)
	# STILL AN OPEN GAP, held open on purpose. A standalone launch carries no ruleset at
	# all, so this passes today and MUST fail the day STANDALONE-MAP-RULESET-2026-09-20
	# lands -- at which point route A becomes the better home for this measurement bench
	# and this file is the thing to revisit.
	_check(
		_profile_ids().is_empty(),
		(
			(
				"route gap A (open, STANDALONE-MAP-RULESET-2026-09-20): no campaign started, "
				+ "so interaction_profiles is empty: %s"
			)
			% str(_profile_ids())
		)
	)

	# ROUTE B -- the campaign, and it is now WHOLE. The profiles arrive from the campaign
	# document; the bearer arrives because the acceptance authoring seeds him into the
	# first node's roster, which is the one node whose authored policy is honoured.
	_check(bool(_cm.call("start_campaign", CAMPAIGN_ID)), "route B (campaign): it starts")
	var ids := _profile_ids()
	_check(
		ids.has("hallowed_rites") and ids.has("undead_frailty"),
		"route B: the campaign puts the acceptance profiles in scope: %s" % str(ids)
	)

	# keep_current_roster on every node after the first is CORRECT and stays -- an FE party
	# persists between chapters, and a per-node roster policy would let an author silently
	# reset levels and gold mid-run. What changed is that the party it keeps already
	# contains the bearer, so the rule costs the acceptance content nothing.
	var cleared: Array = _cm.get("cleared_node_ids")
	cleared.append("node_01_rout")
	var node: Variant = _cm.call("get_current_node")
	var params: Dictionary = _cm.call("resolve_launch_params", node)
	cleared.clear()
	_check(
		String(params.get("roster_policy", "")) == "keep_current_roster",
		(
			"route B: a node after the first keeps the party it earned (roster_policy=%s)"
			% String(params.get("roster_policy", ""))
		)
	)
	var seeded: Dictionary = _dm.call("get_map_registry_entry", "map_001")
	_load_pack_roster(seeded)
	_check(
		_party_has_weapon("hallowed_scythe"),
		(
			"route B: ...and the party it keeps starts with the bearer, because the "
			+ "campaign's FIRST node roster seeds him"
		)
	)
	_check(
		_party_has_unit("m006_plain_axeman"),
		"route B: ...and the A/B control rides along in the same roster"
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

	var plan := _deployment_plan(_cm.call("get_current_node"))
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
	# when they get here. Observed on the board rather than inferred from the launch
	# params: the party carried five chapters really does field the acceptance weapon, and
	# the node's required_units really did put both halves of the A/B on the map.
	if map_id == ACCEPTANCE_MAP:
		_check(
			_party_has_weapon("hallowed_scythe"),
			(
				"route B, on the board: chapter 6 fields the hallowed_scythe -- the "
				+ "acceptance weapon is reachable by PLAYING the campaign"
			)
		)
		await _content_proof(battle)
		# The suspend regression reloads GameMap in place. Refresh the local handles so the
		# ordinary chapter objective below continues on the restored scene.
		battle = current_scene
		turn_manager = battle.get_node_or_null("TurnManager") if battle != null else null
		if battle == null or turn_manager == null:
			_fail("the restored Chapter 6 map retains its TurnManager")
			return

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
# Run on CHAPTER 6'S OWN BOARD, mid-campaign, with nothing forced: the party was carried
# from chapter 1, the profiles came from the campaign document, and the two measured units
# are on the map because the node requires them. The fight is a real one -- real Unit nodes
# spawned by GameMap onto the authored board, resolved AND COMMITTED, because resolve_combat
# only PREPARES the transaction and a proof that stopped at its return value would see no
# condition and read as a broken seam.
func _content_proof(battle: Node) -> void:
	print("\n--- content proof: the authored relationship, in a committed fight ---")
	_check(
		_party_has_weapon("hallowed_scythe") and not _profile_ids().is_empty(),
		"both halves are in scope by PLAY, not by force (bearer + profiles)"
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
	#
	# ASSERTED, NOT ASSUMED. The two halves are now ORDINARY PARTY MEMBERS -- that is the
	# cost of reaching the content by play, and the ruling names it -- so they
	# level, take damage and can drift apart over five chapters. If they ever do, the
	# damage difference below stops being attributable to the weapon, and this check is
	# what says so instead of the numbers quietly lying.
	_check(
		_stats_match(bearer, axeman),
		"the A/B halves are still stat-identical where it measures: %s" % _stat_diff(bearer, axeman)
	)
	var bearer_strike := _committed_strike(bearer, undead)
	var control_strike := _committed_strike(axeman, undead_control)

	# THE DICE ARE NOT THE MEASUREMENT, so they are stated rather than hoped for. A strike
	# that missed carries no damage and gives the durable seam nothing to fire on, and a
	# crit inflates one half of a comparison whose whole content is the difference. Both
	# were observed on this board before the bench pinned the seed and read the opening
	# strike: one run measured a follow-up that landed for the control and missed for the
	# bearer, and reported the authored relationship BACKWARDS.
	_check(
		bool(bearer_strike["hit"]) and bool(control_strike["hit"]),
		"both opening strikes landed, so the fight is measurable at all"
	)
	_check(
		not bool(bearer_strike["crit"]) and not bool(control_strike["crit"]),
		"...and neither crit, so the damage difference is the relationship, not the dice"
	)
	var bearer_damage := int(bearer_strike["damage"])
	var control_damage := int(control_strike["damage"])
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
	await _duration_release_retest(battle, bearer, undead)
	_content_proof_ran = true


# Reproduce the release-build duration path on the campaign board. The ordinary chapter
# roster cannot demonstrate this cleanly: its other hostiles kill the two subjects before
# the player gets to inspect the next phase. Keep only the Bearer and measured Revenant in
# the live GameState, and give the Revenant the authored healer disposition at runtime so
# the real red AI phase commits a Wait without moving or attacking. This is a test-only
# runtime arrangement; campaign and pack data stay untouched.
func _duration_release_retest(battle: Node, bearer: Node, revenant: Node) -> void:
	print("\n--- release duration proof: ordinary BLUE / RED phases and suspend ---")
	var turn_manager: Node = battle.get_node_or_null("TurnManager")
	var cursor: Node = battle.get_node_or_null("MapCursor")
	var unit_details: Control = battle.get_node_or_null("UnitDetailsLayer/UnitDetailsScreen")
	_check(
		turn_manager != null and cursor != null and unit_details != null,
		"the Chapter 6 battle exposes its turn manager, cursor, and Unit Details screen"
	)
	if turn_manager == null or cursor == null or unit_details == null:
		return
	_check(
		(
			not bool(_gs.get("debug_hotseat_override"))
			and not bool(turn_manager.call("is_debug_hotseat_override_active"))
		),
		"the duration proof runs with the debug hotseat override off"
	)

	for unit in (_gs.get("all_units") as Array).duplicate():
		if unit == bearer or unit == revenant:
			continue
		_gs.call("unregister_unit", unit)
		unit.queue_free()
	await process_frame
	_check(
		(
			(_gs.get("all_units") as Array).size() == 2
			and _find_unit("m006_hallowed_bearer") == bearer
			and _find_unit("m006_revenant_1") == revenant
		),
		"runtime isolation leaves exactly the Bearer and measured Revenant registered"
	)
	if (_gs.get("all_units") as Array).size() != 2:
		return

	# The runtime profile keeps the enemy's normal AI controller active while ensuring its
	# phase is a committed Wait. No hotseat toggle or pack JSON edit participates.
	revenant.data.ai_profile = "healer"
	var hp_before: int = int(revenant.data.hp)
	var tile_before: Vector2i = revenant.tile_position
	_open_resistance_details(unit_details, revenant)
	_check(
		unit_details.visible and _details_show_condition_duration(unit_details, "hallowed sear", 2),
		"Unit Details visibly shows Hallowed Sear with 2 phases after the committed hit"
	)

	var bus := root.get_node_or_null("EventBus")
	var phase_events: Array[Dictionary] = []
	var on_phase := func(phase: int, faction_id: String) -> void:
		phase_events.append({"phase": phase, "faction": faction_id})
	if bus != null and bus.has_signal("phase_changed"):
		bus.phase_changed.connect(on_phase)
	var returned_to_blue := await _end_blue_phase_and_wait(turn_manager)
	if bus != null and bus.has_signal("phase_changed") and bus.phase_changed.is_connected(on_phase):
		bus.phase_changed.disconnect(on_phase)
	var saw_red_phase := false
	var saw_blue_phase := false
	for event in phase_events:
		if int(event["phase"]) == int(_gs.Phase.ENEMY) and String(event["faction"]) == "red":
			saw_red_phase = true
		if int(event["phase"]) == int(_gs.Phase.PLAYER) and String(event["faction"]) == "blue":
			saw_blue_phase = true
	_check(
		returned_to_blue and saw_red_phase and saw_blue_phase,
		"normal phase processing crossed RED and returned to BLUE with debug hotseat off"
	)
	_check(
		int(revenant.data.hp) == hp_before and revenant.tile_position == tile_before,
		"the live red AI commits its healer Wait without changing the Revenant's HP or tile"
	)
	_check(
		int(turn_manager.call("get_unit_state", revenant)) == 2,
		"the Revenant completed a real red AI activation"
	)
	_check(
		_condition_turns(revenant, "hallowed_sear") == 1,
		"Hallowed Sear ticks from 2 phases to 1 across the normal phase boundary"
	)
	_open_resistance_details(unit_details, revenant)
	_check(
		unit_details.visible and _details_show_condition_duration(unit_details, "hallowed sear", 1),
		"Unit Details updates visibly to Hallowed Sear with 1 phase"
	)
	# UnitDetailsScreen defers its menu-scale pass. Let it finish while the screen remains in
	# the active tree before the Continue path replaces GameMap.
	await process_frame

	# Use the same on-disk SaveManager slot and GameState/Map continuation path as the game.
	# A private save directory keeps this regression isolated from a developer's real saves.
	var save_manager := root.get_node_or_null("SaveManager")
	_check(save_manager != null, "SaveManager is available for the suspend round trip")
	if save_manager == null:
		return
	var old_save_dir := String(save_manager.get("save_dir"))
	var test_save_dir := "user://ch6_duration_retest_%d" % Time.get_ticks_usec()
	_duration_save_dir = test_save_dir
	save_manager.call("configure_save_dir_for_tests", test_save_dir)
	var save: Variant = _gs.call("capture_save", "Chapter 6 duration retest", turn_manager, cursor)
	_check(save != null, "the live Chapter 6 board captures as a suspend save")
	if save == null:
		save_manager.call("configure_save_dir_for_tests", old_save_dir)
		return
	var serialized_units: Array = save.to_dict().get("map_runtime", {}).get("units", [])
	_check(
		(
			serialized_units.size() == 2
			and _saved_unit_ids(serialized_units).has("m006_hallowed_bearer")
			and _saved_unit_ids(serialized_units).has("m006_revenant_1")
		),
		"the suspend document carries exactly the isolated Bearer and Revenant"
	)
	var saved_hp := int(revenant.data.hp)
	var saved_tile: Vector2i = revenant.tile_position
	var wrote := bool(save_manager.call("save_slot", "resume_battle", save, "manual", ""))
	_check(wrote, "the mid-map suspend slot is written")
	var loaded: Variant = save_manager.call("load_slot", "resume_battle") if wrote else null
	_check(loaded != null, "the suspend slot reloads through SaveManager")
	var staged := loaded != null and bool(_gs.call("configure_suspend_resume", loaded))
	_check(staged, "Continue stages the loaded suspend through GameState")
	save_manager.call("configure_save_dir_for_tests", old_save_dir)
	if not staged:
		return
	var changed := change_scene_to_file(GAME_MAP_SCENE)
	_check(changed == OK, "Continue opens the restored Chapter 6 map")
	if changed != OK:
		return
	await _settle()
	battle = current_scene
	turn_manager = battle.get_node_or_null("TurnManager") if battle != null else null
	unit_details = (
		battle.get_node_or_null("UnitDetailsLayer/UnitDetailsScreen") if battle != null else null
	)
	revenant = _find_unit("m006_revenant_1")
	bearer = _find_unit("m006_hallowed_bearer")
	_check(
		battle != null and turn_manager != null and bearer != null and revenant != null,
		"Continue restores both isolated Chapter 6 units onto the live board"
	)
	if turn_manager == null or revenant == null or bearer == null:
		return
	_check(
		(
			_condition_turns(revenant, "hallowed_sear") == 1
			and int(revenant.data.hp) == saved_hp
			and revenant.tile_position == saved_tile
		),
		"Continue preserves Hallowed Sear at 1 phase and the Revenant's HP and tile"
	)
	_open_resistance_details(unit_details, revenant)
	_check(
		unit_details.visible and _details_show_condition_duration(unit_details, "hallowed sear", 1),
		"Unit Details still visibly shows 1 phase after Continue"
	)
	await _end_blue_phase_and_wait(turn_manager)
	_check(
		not bool(_conditions.call("has_condition", revenant, "hallowed_sear")),
		"Hallowed Sear expires after the next normal BLUE / RED phase cycle"
	)
	_open_resistance_details(unit_details, revenant)
	_check(
		unit_details.visible and not _details_contains(unit_details, "hallowed sear"),
		"Unit Details removes the expired Hallowed Sear entry"
	)


func _details_show_condition_duration(screen: Control, condition_name: String, phases: int) -> bool:
	var text := _details_text(screen).to_lower()
	return text.contains(condition_name) and text.contains("%d phase" % phases)


func _open_resistance_details(screen: Control, unit: Node) -> void:
	screen.call("open", unit)
	# This is the real Unit Details More Info link path: the condition duration lives in the
	# Resistance breakdown, not in the sheet's default summary after open().
	screen.call("_on_entry_clicked", "stat:resistance")


func _details_contains(screen: Control, value: String) -> bool:
	return _details_text(screen).to_lower().contains(value)


func _details_text(node: Node) -> String:
	var parts: Array[String] = []
	if node is Label or node is RichTextLabel:
		parts.append(String(node.get("text")))
	for child in node.get_children():
		parts.append(_details_text(child))
	return " ".join(parts)


func _saved_unit_ids(units: Array) -> Array[String]:
	var ids: Array[String] = []
	for row in units:
		if row is Dictionary:
			ids.append(String(row.get("unit_id", "")))
	return ids


func _end_blue_phase_and_wait(turn_manager: Node) -> bool:
	var initial_turn := int(_gs.get("turn_number"))
	turn_manager.call("end_player_phase")
	for _frame in range(600):
		await process_frame
		if (
			String(turn_manager.call("active_faction")) == "blue"
			and int(_gs.get("turn_number")) > initial_turn
		):
			return true
	return false


# Save validation resolves campaign identity through the player's installed-pack
# catalogue. The old acceptance setup activated directly from the repository tree, which
# is enough to play but cannot produce a restorable campaign save. Install the exact same
# bytes through the ordinary exporter, preflight, and installer path for this round trip.
func _ensure_installed_pack(pack_root: String) -> bool:
	var fingerprint := String(_dm.get("_active_content_fingerprint"))
	var existing_path := PackRegistry.resolve_installed_path(
		PackRegistry.DEFAULT_STORAGE_ROOT, PACK_ID, PACK_VERSION, fingerprint
	)
	if not existing_path.is_empty():
		return bool(_dm.call("select_tier2_campaign_source", existing_path, PACK_ID, PACK_VERSION))

	var limits = PackPreflight.Limits.new(
		PackBudgets.CAMPAIGN_ARCHIVE_MAX_ENTRIES,
		PackBudgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_COMPRESSED_BYTES,
		PackBudgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES,
		PackBudgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES,
		PackBudgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES
	)
	var output_dir := "user://ch6_duration_pack_%d" % Time.get_ticks_usec()
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir)) != OK:
		return false
	_temporary_pack_archive_path = output_dir.path_join("%s-%s.zip" % [PACK_ID, PACK_VERSION])
	var exported := PackExporter.new().export_zip(pack_root, _temporary_pack_archive_path, limits)
	if not exported.exported:
		return false
	var preflight = PackPreflight.inspect_zip(_temporary_pack_archive_path, limits)
	if not preflight.valid:
		return false
	var installed = PackInstaller.new(PackRegistry.DEFAULT_STORAGE_ROOT).install_zip(
		_temporary_pack_archive_path, preflight
	)
	if not installed.installed or not installed.errors.is_empty():
		return false
	_temporary_pack_build_path = String(installed.installed_path)
	return bool(
		_dm.call("select_tier2_campaign_source", _temporary_pack_build_path, PACK_ID, PACK_VERSION)
	)


# --- helpers ---------------------------------------------------------------------------
# One fight, measured on its OPENING STRIKE rather than on the defender's HP delta.
# The HP delta folds in follow-ups and the defender's counter, and whether a follow-up
# happens is a dice outcome -- so two fights that differ only in the weapon could still
# report different totals for a reason that has nothing to do with the weapon.
#
# The dice are pinned as well. The seam is deterministic (seed = mix(map_seed,
# history_hash, event record)), so restarting the map seed before each fight measures
# both halves of the A/B from an IDENTICAL dice state and makes the run repeatable.
# `start_map`'s seed_override is the engine's own test/replay hook, not a back door.
func _committed_strike(attacker: Node, defender: Node) -> Dictionary:
	var rng_service := root.get_node_or_null("RngService")
	if rng_service != null:
		rng_service.call("start_map", MEASUREMENT_SEED)
	defender.tile_position = attacker.tile_position + Vector2i(1, 0)
	var result: Dictionary = _cr.call("resolve_combat", attacker, defender)
	_cr.call("apply_combat_result", result, attacker, defender)
	for exchange in result.get("exchanges", []):
		var row: Dictionary = exchange
		if bool(row.get("is_counter", false)):
			continue
		return {
			"damage": int(row.get("damage", 0)),
			"hit": bool(row.get("hit", false)),
			"crit": bool(row.get("crit", false)),
		}
	return {"damage": -1, "hit": false, "crit": false}


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


# The stats a level-up or a wound can move. Compared on the SPAWNED units, which is where
# the measurement happens, rather than on the roster entries they were built from.
const MEASURED_STATS := [
	"level",
	"max_hp",
	"hp",
	"strength",
	"magic",
	"skill",
	"speed",
	"luck",
	"defense",
	"resistance",
	"constitution",
]


func _stats_match(left: Node, right: Node) -> bool:
	return _stat_diff(left, right) == "identical"


func _stat_diff(left: Node, right: Node) -> String:
	var left_data: Variant = left.get("data") if left != null else null
	var right_data: Variant = right.get("data") if right != null else null
	if left_data == null or right_data == null:
		return "one of the pair has no unit data"
	var differences: Array[String] = []
	for stat in MEASURED_STATS:
		var a: int = int(left_data.get(stat))
		var b: int = int(right_data.get(stat))
		if a != b:
			differences.append("%s %d vs %d" % [stat, a, b])
	return "identical" if differences.is_empty() else ", ".join(differences)


func _party_has_unit(unit_id: String) -> bool:
	for unit_data in _gs.get("player_roster"):
		if unit_data != null and String(unit_data.get("unit_id")) == unit_id:
			return true
	return false


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


# Mirrors PrepScreen._seed_selection: the node's required units take the first start
# tiles and the rest of the party fills what is left. The party is now BIGGER than the
# board (eight units, six tiles), so roster order alone would bench the two units chapter
# 6 pins and DeploymentPlan.validate would refuse the plan outright.
func _deployment_plan(node: Variant = null) -> Dictionary:
	var path := String(_gs.get("next_map_data_path"))
	var resolved: Variant = _dm.call("resolve_battle_source", path)
	if resolved == null:
		return {}
	var map_data: Variant = resolved.get("battle_map")
	if map_data == null:
		return {}
	var tiles: Array = map_data.get("player_start_tiles")
	var roster: Array = _gs.get("player_roster")
	var party: Array[String] = []
	for unit_data in roster:
		if unit_data != null and String(unit_data.get("unit_id")) != "":
			party.append(String(unit_data.get("unit_id")))
	var ordered: Array[String] = []
	if node != null:
		for required_id in node.get("required_units"):
			var unit_id := String(required_id)
			if unit_id in party and not unit_id in ordered:
				ordered.append(unit_id)
	for unit_id in party:
		if not unit_id in ordered:
			ordered.append(unit_id)
	var plan := {}
	for i in range(mini(ordered.size(), tiles.size())):
		plan[ordered[i]] = tiles[i]
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
		print("FAIL the run did not reach the end of the playthrough -- see the error above")
	if not _content_proof_ran:
		_failed += 1
		print("FAIL the content proof did not run to completion on chapter 6's board")
	print("\n=== Playthrough Results: %d passed, %d failed ===" % [_passed, _failed])
	if _duration_save_dir != "":
		_remove_tree(ProjectSettings.globalize_path(_duration_save_dir))
	if _temporary_pack_build_path != "":
		_remove_tree(ProjectSettings.globalize_path(_temporary_pack_build_path))
	if _temporary_pack_archive_path != "":
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_temporary_pack_archive_path))
		_remove_tree(ProjectSettings.globalize_path(_temporary_pack_archive_path.get_base_dir()))
	quit(0 if _failed == 0 else 1)


func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for directory_name in dir.get_directories():
		_remove_tree(path.path_join(directory_name))
	DirAccess.remove_absolute(path)
