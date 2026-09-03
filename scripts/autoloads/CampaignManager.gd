extends Node
# B1-CST Slices 2-3 — the campaign RUNTIME position, the prep -> map ->
# victory/defeat -> results -> next node flow, and the campaign save envelope.
#
# Authority: GDD_01 §CampaignData Contract, GDD_05 §Campaign Flow
# Slice 1 (CampaignData/CampaignNode + DataManager loading) built the authored
# progression GRAPH. This autoload is the thing that WALKS it: which campaign is
# active, which node the party is parked on, and which nodes are cleared.
#
# Scope guards:
# - Owns the POSITION, not the disk. capture_campaign_state/restore_campaign_state
#   are the serializer seam; SaveManager owns every user:// path, and the three
#   fields they move are the F1 manifest row campaign.campaign_id / node_id /
#   cleared_nodes[]. A persisted field with no manifest row is a bug.
# - Owns the FLOW, not the prep SCREENS. Roster selection, trade, and deployment
#   UI belong to B4-PREP-DEPLOYMENT; the campaign selector belongs to
#   B6-CAMPAIGN-SHARING.
# - Additive only. With no campaign active every handler here no-ops, so the bare
#   single-map launch from NewGameScreen behaves exactly as it did before.

const AutosaveTriggerRegistryScript = preload("res://scripts/save/AutosaveTriggerRegistry.gd")
const CampaignStatusStoreScript = preload("res://scripts/resources/CampaignStatusStore.gd")
const CadenceEngineScript = preload("res://scripts/campaign/CadenceEngine.gd")

# [EPUX] names chapter_reached as a per-milestone counter. Modelling it as a
# prefixed counter id keeps the trigger families a two-entry open registry: an
# author writes counter_id "chapter_reached.<node_id>", mode "after", threshold 1
# and needs no third family and no engine edit.
const CHAPTER_REACHED_PREFIX := "chapter_reached."

const _GAME_MAP_SCENE := "res://scenes/core/GameMap.tscn"
const _PREP_SCENE := "res://scenes/ui/PrepScreen.tscn"
const _OVERWORLD_SCENE := "res://scenes/ui/OverworldScreen.tscn"
const _BOOT_SCENE := "res://scenes/core/Boot.tscn"
const _DEFAULT_ROSTER_PATH := "res://data/roster/default/"

# --- Runtime position --------------------------------------------------------

# Empty campaign id == no campaign active == every signal handler below no-ops.
var active_campaign_id: String = ""

# The node the party is parked on: the one that launches next. On victory this
# moves to the cleared node's successor; on defeat it does not move.
var current_node_id: String = ""

# Nodes beaten this run, in clear order.
var cleared_node_ids: Array[String] = []

# Campaign-scoped mutable author state. Flags are an open string vocabulary and
# vars are an open key/value registry; neither belongs in a closed engine enum.
var campaign_flags: Array[String] = []
var campaign_vars: Dictionary = {}
var cadence_state: Dictionary = {
	"counters": {}, "latched": {}, "last_fired": {}, "ticks": {}, "active": {}
}

# The node actually launched into the live map. Distinct from current_node_id on
# purpose — see the retry note on _pending_result below.
var _active_node_id: String = ""

# The result of the last resolved map, held for the results surface and NOT yet
# applied to the position.
#
# Why the advance is deferred rather than applied on map_victory: GameOverScreen
# offers Retry, which reloads the SAME map. Advancing on the victory signal would
# leave the position on node N+1 while the player replays node N, and a second
# win would then clear N+1 and skip to N+2. So a win only RECORDS a result here;
# the position moves when the results surface commits it (commit_pending_result),
# and Retry drops it (clear_pending_result). Rewards are unaffected — TurnManager
# already applies those through ResourceLedger, and the map snapshot restore is
# what unwinds them on retry.
var _pending_result: Dictionary = {}
var _prepared_launch: Dictionary = {}
var _revisiting_node_id: String = ""
var _autosave_triggers := AutosaveTriggerRegistryScript.new()
var _cadence := CadenceEngineScript.new()
# Derived from cadence_state, not saved: the selection is recomputed at every
# evaluation point rather than persisted, so a save can never disagree with the
# triggers the campaign actually authors today.
var _active_cadence_triggers: Array = []
var _cadence_evaluated: bool = false
# Which node's launch has already counted a deployment. A retry and a
# mid-battle suspend resume both re-enter the same launched node, and neither is
# a new deployment -- counting them would let a player farm any cadence keyed on
# deployments_total by replaying one map.
var _deployment_counted_for: String = ""


func _ready() -> void:
	for trigger_id in ["battle_start", "battle_end", "menu_area_exit", "shop_exit"]:
		_autosave_triggers.register(trigger_id, _handle_autosave_trigger)
	var bus := get_node_or_null("/root/EventBus")
	if bus == null:
		return
	# TurnManager emits map_victory/map_defeat and then map_resolved with the full
	# standings. Outcome comes from the first pair; map_resolved enriches the
	# payload the results surface reads.
	bus.map_victory.connect(_on_map_victory)
	bus.map_defeat.connect(_on_map_defeat)
	bus.map_resolved.connect(_on_map_resolved)
	bus.unit_died.connect(_on_unit_died)


# --- Campaign lifecycle -------------------------------------------------------


# Seeds a run at the campaign's start node. Unknown id fails loud and leaves no
# campaign active, rather than parking the player on a campaign that cannot run.
func start_campaign(campaign_id: String) -> bool:
	var campaign := _get_campaign(campaign_id)
	if campaign == null:
		push_error("CampaignManager: cannot start unknown campaign '%s'" % campaign_id)
		return false
	if not campaign.has_node(campaign.start_node_id):
		push_error(
			(
				"CampaignManager: campaign '%s' start node '%s' is not in the graph"
				% [campaign_id, campaign.start_node_id]
			)
		)
		return false
	active_campaign_id = campaign_id
	current_node_id = campaign.start_node_id
	cleared_node_ids.clear()
	campaign_flags.clear()
	campaign_vars.clear()
	cadence_state = _cadence.normalize_state({})
	_reset_cadence_selection()
	campaign_vars["_runtime_map_casualties"] = []
	var typed_vars := get_node_or_null("/root/CampaignVars")
	if typed_vars != null:
		typed_vars.call("clear_all")
	_active_node_id = ""
	_revisiting_node_id = ""
	_pending_result.clear()
	_prepared_launch.clear()
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("apply_campaign_rule_overrides"):
		gs.call(
			"apply_campaign_rule_overrides", campaign.rule_overrides, campaign.mandated_rule_ids
		)
	_log_playtest_context("campaign_started")
	return true


# Drops the run. Called when the player quits to menu; also the reset seam tests
# use between cases.
func end_campaign() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("end_campaign_map_rules"):
		gs.call("end_campaign_map_rules")
	active_campaign_id = ""
	current_node_id = ""
	cleared_node_ids.clear()
	campaign_flags.clear()
	campaign_vars.clear()
	cadence_state = _cadence.normalize_state({})
	_reset_cadence_selection()
	var typed_vars := get_node_or_null("/root/CampaignVars")
	if typed_vars != null:
		typed_vars.call("clear_all")
	_active_node_id = ""
	_revisiting_node_id = ""
	_pending_result.clear()
	_prepared_launch.clear()


# The one path back to the main menu. Three screens used to open Boot.tscn by hand
# with slightly different pre-work, and none of them deactivated the content package.
#
# Deactivation is the part that was missing: [CSA-28](f) ruled quit-to-shell
# deactivates and nothing implemented it, so the menu was reached with the last-played
# pack still loaded. Nothing depended on that until [CEUI-S13] made the campaign editor
# main-menu-only -- the editor activates its own working copy, and doing so over a live
# player pack is the provenance failure [CEUI-S9] call 1 exists to prevent.
#
# Deliberately does NOT call end_campaign(). Two of the three callers already do, and
# the third (quit from the in-map menu) never has; folding it in here would change what
# those callers do beyond the deactivation this fixes. Campaign progress and content
# activation are separate concerns and this function owns only the second.
func quit_to_shell() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("reset_map_state"):
		gs.call("reset_map_state")
	var dm := get_node_or_null("/root/DataManager")
	if dm != null and dm.has_method("reset_to_boot_content_baseline"):
		dm.call("reset_to_boot_content_baseline")
	get_tree().change_scene_to_file(_BOOT_SCENE)


func has_campaign_flag(flag_id: String) -> bool:
	return flag_id in campaign_flags


func set_campaign_flag(flag_id: String, enabled: bool = true) -> bool:
	if flag_id.is_empty():
		return false
	if enabled and not flag_id in campaign_flags:
		campaign_flags.append(flag_id)
	elif not enabled:
		campaign_flags.erase(flag_id)
	return true


func get_campaign_var(var_id: String, default_value: Variant = null) -> Variant:
	return campaign_vars.get(var_id, default_value)


func set_campaign_var(var_id: String, value: Variant) -> bool:
	if var_id.is_empty():
		return false
	campaign_vars[var_id] = value
	return true


func set_carry_forward_fact(fact_id: String, value: Variant) -> bool:
	if not set_campaign_var(fact_id, value):
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var state: MutableCampaignState = gs.get("mutable_campaign_state") as MutableCampaignState
	if state == null:
		return false
	state.carry_forward_facts[fact_id] = value
	return true


func import_carry_forward_facts(facts: Variant) -> bool:
	if not (facts is Dictionary):
		return false
	for fact_id in facts:
		if not (fact_id is String) or String(fact_id) == "":
			return false
	for fact_id in facts:
		campaign_vars[fact_id] = facts[fact_id]
	return true


func stage_status_import_benefits(record: Dictionary) -> bool:
	var campaign := get_active_campaign()
	if campaign == null:
		return false
	for benefit in campaign.status_import_benefits:
		if CampaignStatusStoreScript.source_matches(record, benefit.get("source", {})):
			campaign_vars["_pending_status_import_benefit"] = benefit.duplicate(true)
			campaign_vars["_pending_status_import_record"] = record.duplicate(true)
			return true
	return true


func active_status_target() -> Dictionary:
	var campaign := get_active_campaign()
	if campaign == null:
		return {}
	return {
		"author_id": campaign.author_id,
		"campaign_id": campaign.campaign_id,
		"campaign_version": campaign.campaign_version,
		"compatible_status_sources": campaign.compatible_status_sources.duplicate(true),
	}


# Terminal results call this before ending the runtime campaign. The record is
# deliberately separate from the full save and contains only portable facts.
func export_completion_status_record() -> Dictionary:
	if not is_campaign_complete():
		return {}
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return {}
	var state: MutableCampaignState = gs.get("mutable_campaign_state") as MutableCampaignState
	if state == null:
		return {}
	var store := CampaignStatusStoreScript.new()
	return (
		store
		. export_completion(
			active_status_target(),
			state,
			{
				"completed": true,
				"ending_id": String(campaign_vars.get("ending_id", "")),
				"route_id": String(campaign_vars.get("route_id", "")),
				"rank_id": String(campaign_vars.get("rank_id", "")),
			},
			{
				"maps_completed": cleared_node_ids.size(),
				"turns_taken": int(campaign_vars.get("turns_taken", 0)),
				"party_gold": int(gs.get("party_gold")),
			}
		)
	)


func is_campaign_active() -> bool:
	return active_campaign_id != ""


func uses_overworld() -> bool:
	var campaign := get_active_campaign()
	return campaign != null and campaign.traversal_mode == "free_roam"


# Stable presentation model for the overworld. Authored node order controls
# layout and focus order; the screen does not infer a second progression graph.
# Every row carries its own unmet reason, because [EPUX-04] puts the disabled
# treatment and the reason WITH the availability authority rather than leaving
# each surface to phrase its own — that is the per-adapter drift the ruling exists
# to prevent, and the overworld is the fifth surface to inherit it.
func get_overworld_nodes() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var campaign := get_active_campaign()
	if campaign == null:
		return rows
	for node in campaign.nodes:
		var cleared := node.node_id in cleared_node_ids
		var available := cleared or node.node_id == current_node_id
		(
			rows
			. append(
				{
					"node_id": node.node_id,
					"label": node.label if node.label != "" else node.node_id,
					"cleared": cleared,
					"current": node.node_id == current_node_id,
					"available": available,
					"unavailable_reason": "" if available else _overworld_unmet_reason(node),
					"repeatable_battle": node.repeatable_battle,
					"next": node.next_node_ids.duplicate(),
				}
			)
		)
	return rows


# Why a node cannot be entered right now. Free roam opens CLEARED nodes for
# revisit and the current node for advance; everything else is still ahead on the
# authored graph. Text keys rather than the plain sentences this shipped with: the
# hardcoded English was a documented stopgap for an empty shared table, and now that
# the table exists, leaving it would mean two conventions for one kind of string.
func _overworld_unmet_reason(node: CampaignNode) -> String:
	if is_campaign_complete():
		return _overworld_text("overworld.node.campaign_complete")
	for other in get_active_campaign().nodes:
		if node.node_id in other.next_node_ids:
			var label := other.label if other.label != "" else other.node_id
			return _overworld_text("overworld.node.clear_first", {"node": label})
	return _overworld_text("overworld.node.not_reached")


# Resolves the TextDB autoload lazily, the same way RequirementSystem.render_reason
# does, so the overworld and the predicate vocabulary read from one table. The bare-key
# return is a last resort reached only outside the tree; it is silent, so treat it as a
# wiring bug rather than a missing translation.
func _overworld_text(key: String, params: Dictionary = {}) -> String:
	var text_db := get_node_or_null("/root/TextDB")
	if text_db != null and text_db.has_method("tr_key"):
		return text_db.call("tr_key", key, params)
	return key


func route_to_overworld() -> bool:
	if not uses_overworld() or is_campaign_complete():
		return false
	evaluate_cadence()
	get_tree().change_scene_to_file(_OVERWORLD_SCENE)
	return true


# Reuses the ordinary prep path while leaving current_node_id untouched for a
# cleared-node revisit. The revisit itself evaluates cadence but ticks nothing.
func enter_overworld_node(node_id: String) -> bool:
	if not uses_overworld() or node_id == "":
		return false
	var campaign := get_active_campaign()
	var node: CampaignNode = campaign.get_node_by_id(node_id) if campaign != null else null
	var revisiting := node_id in cleared_node_ids
	if node == null or (not revisiting and node_id != current_node_id):
		return false
	evaluate_cadence()
	var params := resolve_launch_params(node)
	var gs := get_node_or_null("/root/GameState")
	if params.is_empty() or gs == null:
		return false
	# A campaign party already exists at every overworld entry, including the
	# first screen reached after a battle result.
	params["roster_policy"] = "keep_current_roster"
	params["roster_source"] = ""
	gs.call("configure_next_map", params["map_data_path"], "keep_current_roster", "")
	if not _apply_roster_policy(gs, "keep_current_roster", ""):
		return false
	if gs.has_method("begin_campaign_map_rules"):
		gs.call("begin_campaign_map_rules", node.rule_overrides)
	_revisiting_node_id = node_id if revisiting else ""
	_active_node_id = node_id
	_deployment_counted_for = ""
	campaign_vars["_runtime_map_casualties"] = []
	get_tree().change_scene_to_file(_PREP_SCENE)
	return true


func is_revisiting_current_hub() -> bool:
	return _revisiting_node_id != ""


# Leaves a cleared-node hub without treating the visit as a battle result.  The
# campaign position and clear history remain authoritative; only transient
# launch state from the revisit is discarded before returning to the overworld.
func return_from_revisited_hub() -> bool:
	if not uses_overworld() or _revisiting_node_id == "":
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("end_campaign_map_rules"):
		gs.call("end_campaign_map_rules")
	_revisiting_node_id = ""
	_active_node_id = ""
	_deployment_counted_for = ""
	campaign_vars["_runtime_map_casualties"] = []
	get_tree().change_scene_to_file(_OVERWORLD_SCENE)
	return true


func get_hub_node() -> CampaignNode:
	var campaign := get_active_campaign()
	if campaign == null:
		return null
	return campaign.get_node_by_id(
		_revisiting_node_id if _revisiting_node_id != "" else current_node_id
	)


# True once the position has walked off the end of the graph (a terminal node was
# cleared and committed). A campaign with no active id is NOT complete — it is
# simply absent.
func is_campaign_complete() -> bool:
	return is_campaign_active() and current_node_id == ""


func get_active_campaign() -> CampaignData:
	if not is_campaign_active():
		return null
	return _get_campaign(active_campaign_id)


# The node that launches next. Null when no campaign is active or the campaign is
# complete — callers must treat null as "nothing to launch", never as node 1.
func get_current_node() -> CampaignNode:
	var campaign := get_active_campaign()
	if campaign == null or current_node_id == "":
		return null
	return campaign.get_node_by_id(current_node_id)


func is_node_cleared(node_id: String) -> bool:
	return node_id in cleared_node_ids


# Revisit entry evaluates cadence but advances no campaign counter.
func evaluate_cadence() -> Array[String]:
	var campaign := get_active_campaign()
	if campaign == null:
		return []
	var result := (
		_cadence
		. evaluate(
			campaign.cadence_triggers,
			cadence_state,
			{
				"requirement_system": get_node_or_null("/root/RequirementSystem"),
				"requirement_context":
				{
					"campaign_flags": _flags_as_dictionary(),
					"campaign_vars": get_node_or_null("/root/CampaignVars"),
				}
			}
		)
	)
	cadence_state = result.state
	_active_cadence_triggers = result.active
	_cadence_evaluated = true
	return result.fired


func increment_cadence_counter(counter_id: String, amount: int = 1) -> Array[String]:
	_cadence.increment_counter(cadence_state, counter_id, amount)
	return evaluate_cadence()


# What cadence currently SELECTS for one node: subscriber id -> authored payload.
# The three node-bound subscriber families ([EPUX] activity set, battle target,
# activity variant) read this; only battle_target is interpreted here, because it
# is the only one whose consumer exists in the engine today. Everything else is
# handed back untouched for its own family to interpret when that family lands.
func resolve_node_cadence(node: CampaignNode) -> Dictionary:
	if node == null:
		return {}
	if not _cadence_evaluated:
		evaluate_cadence()
	return _cadence.resolve_subscriptions(node.cadence_subscriptions, _active_cadence_triggers)


# Monotonic count of how many times a trigger has fired, durable in the save.
# This is the fourth subscriber family's seam: [CVS-S6] puts the restock cadence
# reference on the stock ENTITY, not on the node, so a stock entry stores the
# tick it last restocked at and compares. Keeping the comparison on the consumer
# means no drain protocol here, many entities may share one trigger, and a tick
# survives a reload instead of being lost with an unread event queue.
func get_cadence_tick(trigger_id: String) -> int:
	return int(cadence_state.get("ticks", {}).get(trigger_id, 0))


func _reset_cadence_selection() -> void:
	_active_cadence_triggers = []
	_cadence_evaluated = false


# True exactly once per launched visit to a node. Retry and a suspend resume both
# re-enter the same launched node without passing a launch entry point, so they
# see the claim already taken and count no second deployment.
func _claim_deployment_count() -> bool:
	if _deployment_counted_for == _active_node_id:
		return false
	_deployment_counted_for = _active_node_id
	return true


func _flags_as_dictionary() -> Dictionary:
	var out := {}
	for flag_id in campaign_flags:
		out[flag_id] = true
	return out


# --- Launch (the "prep -> map" seam) -----------------------------------------


# Resolves the current node's map binding, prepares the party, then parks on prep.
# Prep only authors a deployment plan; it must never reapply the roster policy.
func launch_current_node() -> bool:
	var node := get_current_node()
	if node == null:
		push_error(
			"CampaignManager: no current node to launch (campaign '%s')" % active_campaign_id
		)
		return false

	var params := resolve_launch_params(node)
	if params.is_empty():
		return false

	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		push_error("CampaignManager: GameState is unavailable")
		return false

	var roster_policy: String = String(params["roster_policy"])
	var roster_source: String = String(params["roster_source"])
	gs.call("configure_next_map", String(params["map_data_path"]), roster_policy, roster_source)
	if not _apply_roster_policy(gs, roster_policy, roster_source):
		push_error(
			(
				"CampaignManager: node '%s' has no valid roster for policy '%s'"
				% [node.node_id, roster_policy]
			)
		)
		return false
	if gs.has_method("begin_campaign_map_rules"):
		gs.call("begin_campaign_map_rules", node.rule_overrides)

	_active_node_id = node.node_id
	_pending_result.clear()
	_deployment_counted_for = ""
	campaign_vars["_runtime_map_casualties"] = []
	_log_playtest_context("node_launch")
	get_tree().change_scene_to_file(_PREP_SCENE)
	return true


# Validates and prepares the successor named by the pending victory without
# consuming that result. A failure leaves position/result untouched so Next can
# be retried after authored data or runtime roster state is repaired.
func prepare_pending_advance() -> bool:
	if not has_pending_victory():
		return false
	var next_id: String = String(_pending_result.get("next_node_id", ""))
	if next_id == "":
		_prepared_launch.clear()  # terminal completion has no successor to launch
		return true
	var campaign := get_active_campaign()
	var node: CampaignNode = campaign.get_node_by_id(next_id) if campaign != null else null
	if node == null:
		push_error("CampaignManager: pending victory names unknown successor '%s'" % next_id)
		return false
	var params := resolve_launch_params(node)
	if params.is_empty() or String(params.get("map_data_path", "")) == "":
		return false
	# Every successor is a continuation even before the pending clear is committed.
	params["roster_policy"] = "keep_current_roster"
	params["roster_source"] = ""
	var gs := get_node_or_null("/root/GameState")
	if gs == null or not _apply_roster_policy(gs, "keep_current_roster", ""):
		push_error("CampaignManager: successor '%s' has no prepared campaign roster" % next_id)
		return false
	params["node_id"] = next_id
	_prepared_launch = params.duplicate(true)
	return true


# Launches only a successor already validated by prepare_pending_advance().
func launch_prepared_node() -> bool:
	if (
		_prepared_launch.is_empty()
		or String(_prepared_launch.get("node_id", "")) != current_node_id
	):
		push_error("CampaignManager: no prepared launch for current node '%s'" % current_node_id)
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return false
	gs.call(
		"configure_next_map",
		String(_prepared_launch["map_data_path"]),
		String(_prepared_launch["roster_policy"]),
		String(_prepared_launch["roster_source"])
	)
	if gs.has_method("begin_campaign_map_rules"):
		gs.call("begin_campaign_map_rules", _prepared_launch.get("rule_overrides", {}))
	_active_node_id = current_node_id
	campaign_vars["_runtime_map_casualties"] = []
	_deployment_counted_for = ""
	_prepared_launch.clear()
	get_tree().change_scene_to_file(_PREP_SCENE)
	return true


# Prep's one-way handoff after it has staged a legal deployment plan.
func begin_prepared_battle() -> bool:
	if not is_campaign_active() or _active_node_id == "":
		push_error("CampaignManager: no prepared campaign battle to begin")
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs == null or (gs.get("next_map_deployment") as Dictionary).is_empty():
		push_error("CampaignManager: prep has not staged a deployment plan")
		return false
	# Committing a staged plan to the map IS the deployment event, including the
	# battle launched from a revisited hub -- the revisit itself advances nothing,
	# but the battle it leads to is a real deployment.
	if _claim_deployment_count():
		increment_cadence_counter("deployments_total")
	dispatch_autosave_trigger("battle_start")
	get_tree().change_scene_to_file(_GAME_MAP_SCENE)
	return true


# Retry has already restored ledger entry 0. Keep that restored party and launch
# staging intact; only replace the map scene with prep so the plan can be edited.
func route_retry_to_prep() -> bool:
	if not is_campaign_active() or _active_node_id == "":
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var suspend_payload: Variant = gs.get("next_map_suspend_payload")
	if suspend_payload is Dictionary and not suspend_payload.is_empty():
		return false
	get_tree().change_scene_to_file(_PREP_SCENE)
	return true


# Re-marks the current node as the launched node after a mid-battle suspend
# resume. restore_campaign_state() clears _active_node_id ("nothing is on a map
# yet"), which is correct for a between-map restore that then calls
# launch_current_node(). But a suspend resume boots straight into the live
# GameMap without re-launching, so without this the eventual map result is
# ignored (_record_result bails on the empty _active_node_id) and the win/loss
# is lost (V053-01). Guarded so it is a no-op unless a campaign with a real
# current node is active.
func resume_launched_node() -> bool:
	if not is_campaign_active() or current_node_id == "":
		return false
	_active_node_id = current_node_id
	_pending_result.clear()
	_log_playtest_context("node_resumed")
	return true


# Resolves a node's map binding into the launch parameters GameState needs.
# Empty on an unresolvable binding. Split out from launch_current_node so the
# resolution is testable without changing scene.
# The battle this node launches right now. A cadence selection replaces the
# authored pair WHOLESALE rather than merging field by field: a swapped target
# that inherited half the authored binding would launch a map nobody authored.
func _resolve_battle_target(node: CampaignNode) -> Dictionary:
	var authored := {"encounter_id": node.encounter_id, "map_id": node.map_id}
	var selection: Variant = resolve_node_cadence(node).get(
		CampaignNode.BATTLE_TARGET_SUBSCRIBER, null
	)
	if not selection is Dictionary:
		return authored
	var swapped := {
		"encounter_id": String(selection.get("encounter_id", "")),
		"map_id": String(selection.get("map_id", "")),
	}
	if swapped["encounter_id"] == "" and swapped["map_id"] == "":
		return authored
	return swapped


func resolve_launch_params(node: CampaignNode) -> Dictionary:
	var dm := get_node_or_null("/root/DataManager")
	if dm == null:
		return {}
	var entry: Dictionary = {}
	var battle_source := ""
	# The battle_target cadence subscriber swaps which battle this node launches
	# without moving the node: a satisfied trigger replaces the authored binding,
	# and an unsatisfied one leaves the node exactly as authored. The swap happens
	# HERE so every launch route -- linear advance, overworld entry and revisit --
	# gets it from one place rather than each resolving a target of its own.
	var target := _resolve_battle_target(node)
	var encounter_id := String(target.get("encounter_id", ""))
	var map_id := String(target.get("map_id", ""))
	if encounter_id != "":
		if not bool(dm.call("has_battle_encounter", encounter_id)):
			push_error(
				(
					"CampaignManager: node '%s' binds to unknown encounter id '%s'"
					% [node.node_id, encounter_id]
				)
			)
			return {}
		entry = dm.call("get_battle_encounter_entry", encounter_id)
		battle_source = encounter_id
	elif not bool(dm.call("has_map_registry_entry", map_id)):
		push_error(
			"CampaignManager: node '%s' binds to unknown map id '%s'" % [node.node_id, map_id]
		)
		return {}
	else:
		entry = dm.call("get_map_registry_entry", map_id)
		battle_source = String(entry.get("map_data_path", ""))

	# Roster policy: the FIRST node of a run seeds the party from the map
	# registry's authored policy; every later node keeps the party it earned, or
	# levels and gold would reset each map. keep_current_roster is the existing
	# GameState policy for exactly this.
	var roster_policy: String = String(entry.get("roster_policy", "default_roster"))
	var roster_source: String = String(entry.get("roster_source", ""))
	if not cleared_node_ids.is_empty():
		roster_policy = "keep_current_roster"
		roster_source = ""

	return {
		"map_data_path": battle_source,
		"roster_policy": roster_policy,
		"roster_source": roster_source,
		"rule_overrides": node.rule_overrides.duplicate(true),
	}


# Prepares the party for the launch policy. Mirrors NewGameScreen's policy switch;
# a policy with no valid prepared roster fails rather than silently falling back
# to the default roster (which would wipe a campaign party).
func _apply_roster_policy(gs: Node, roster_policy: String, roster_source: String) -> bool:
	var loaded := false
	match roster_policy:
		"default_roster":
			loaded = bool(gs.call("load_default_roster"))
		"fixed_test_roster":
			if roster_source == "":
				return false
			loaded = bool(gs.call("load_roster_from_directory", roster_source, "fixed_test_roster"))
		"campaign_pack_roster":
			var dm := get_node_or_null("/root/DataManager")
			if dm == null or not dm.has_method("get_campaign_pack_roster"):
				return false
			var roster: Array = dm.call("get_campaign_pack_roster", roster_source)
			loaded = bool(
				gs.call("load_roster_resources", roster, "campaign_pack_roster", roster_source)
			)
		"keep_current_roster":
			loaded = bool(gs.call("is_roster_ready_for_launch"))
		_:
			push_error("CampaignManager: unknown roster policy '%s'" % roster_policy)
			return false
	if not (loaded and _apply_pending_status_import_benefit(gs)):
		return false
	_full_heal_roster(gs)
	return true


# V053-03: every roster unit re-enters a fresh campaign map at full HP (decision
# (a), FE-series convention). With permadeath off, casual-mode fallen units keep
# hp = 0 in the shared UnitData (DeathLifecycle only sets is_incapacitated under
# permadeath), so without this they spawn as 0-HP "walking dead" that die to any
# hit; living units also silently carried damage between maps. This runs on the
# campaign launch path (_apply_roster_policy) only — never on suspend resume,
# which must preserve exact mid-map HP, nor on retry, which restores ledger
# round 0 without re-applying the roster policy.
func _full_heal_roster(gs: Node) -> void:
	for unit: UnitData in gs.get("player_roster"):
		if unit == null:
			continue
		unit.hp = unit.max_hp
		unit.damage_taken_this_map = 0


func _apply_pending_status_import_benefit(gs: Node) -> bool:
	if not campaign_vars.has("_pending_status_import_benefit"):
		return true
	var benefit: Dictionary = campaign_vars["_pending_status_import_benefit"]
	var record: Dictionary = campaign_vars.get("_pending_status_import_record", {})
	var grants: Variant = benefit.get("item_grants", [])
	if not grants is Array:
		return false
	var units := {}
	for unit: UnitData in gs.get("player_roster"):
		units[unit.unit_id] = unit
	var dm := get_node_or_null("/root/DataManager")
	for grant in grants:
		if not grant is Dictionary:
			return false
		var unit_id := String(grant.get("unit_id", ""))
		var item_id := String(grant.get("item_id", ""))
		if (
			not units.has(unit_id)
			or item_id.is_empty()
			or (dm != null and dm.has_method("has_item") and not bool(dm.call("has_item", item_id)))
		):
			return false
	if bool(benefit.get("carry_gold", false)):
		gs.set("party_gold", maxi(0, int(record.get("counters", {}).get("party_gold", 0))))
	for grant in grants:
		var unit: UnitData = units[String(grant["unit_id"])]
		unit.inventory.append(
			InventoryEntry.make_item(String(grant["item_id"]), int(grant.get("uses", 1)))
		)
	campaign_vars.erase("_pending_status_import_benefit")
	campaign_vars.erase("_pending_status_import_record")
	return true


# --- Result handling ----------------------------------------------------------


func _on_map_victory() -> void:
	_record_result(true)


func _on_map_defeat() -> void:
	_record_result(false)


# Records the outcome for the node that was actually LAUNCHED (_active_node_id),
# not the position — so a retried map records against the node being replayed.
func _record_result(victory: bool) -> void:
	if not is_campaign_active():
		push_warning("CampaignManager: map result ignored because no campaign is active")
		return  # bare single-map launch: nothing to track
	if _active_node_id == "":
		push_warning(
			"CampaignManager: map result ignored because the active campaign has no launched node"
		)
		return
	var campaign := get_active_campaign()
	var node: CampaignNode = campaign.get_node_by_id(_active_node_id) if campaign != null else null
	if node == null:
		push_error(
			(
				"CampaignManager: resolved node '%s' is not in campaign '%s'"
				% [_active_node_id, active_campaign_id]
			)
		)
		return
	_pending_result = {
		"campaign_id": active_campaign_id,
		"node_id": _active_node_id,
		"victory": victory,
		# A single successor is unambiguous. Branches remain deliberately unset
		# until the player chooses on MapResultsScreen; authored order controls
		# presentation, never an implicit first-branch decision.
		"next_node_id": _unambiguous_successor_of(node),
		"requires_successor_choice": node.next_node_ids.size() > 1,
		"campaign_complete": victory and node.is_terminal(),
		"revisit": _revisiting_node_id == _active_node_id,
		"winner_group": "",
		"standings": [],
		"casualties": campaign_vars.get("_runtime_map_casualties", []).duplicate(),
	}
	_prepared_launch.clear()


func _on_unit_died(unit: Node) -> void:
	if not is_campaign_active() or unit == null or String(unit.get("team")) != "blue":
		return
	var data: UnitData = unit.get("data") as UnitData
	if data == null:
		return
	var entries: Array = campaign_vars.get("_runtime_map_casualties", [])
	var disposition := "Fallen" if data.is_incapacitated else "Retreated"
	var label := (
		"%s — %s" % [data.unit_name if not data.unit_name.is_empty() else data.unit_id, disposition]
	)
	if not label in entries:
		entries.append(label)
	campaign_vars["_runtime_map_casualties"] = entries


# map_resolved fires right after map_victory/map_defeat and carries the ranked
# standings, so it enriches the result the victory/defeat handler just recorded.
func _on_map_resolved(winner_group: String, standings: Array) -> void:
	if _pending_result.is_empty():
		return
	_pending_result["winner_group"] = winner_group
	_pending_result["standings"] = standings.duplicate()


# The results state handoff: what the results surface renders and routes on.
# Empty when there is nothing to present (no campaign, or an unresolved map).
func get_pending_result() -> Dictionary:
	return _pending_result.duplicate(true)


func has_pending_victory() -> bool:
	return not _pending_result.is_empty() and bool(_pending_result.get("victory", false))


# Ordered options for the pending node's authored outgoing edges. Labels come
# from the destination nodes so result UI never invents a parallel branch name.
func get_pending_successor_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if not has_pending_victory():
		return options
	if bool(_pending_result.get("revisit", false)):
		return options
	var campaign := get_active_campaign()
	var node_id: String = String(_pending_result.get("node_id", ""))
	var node: CampaignNode = campaign.get_node_by_id(node_id) if campaign != null else null
	if node == null:
		return options
	for successor_id in node.next_node_ids:
		var successor: CampaignNode = campaign.get_node_by_id(successor_id)
		if successor == null:
			continue
		(
			options
			. append(
				{
					"node_id": successor_id,
					"label": successor.label if successor.label != "" else successor_id,
				}
			)
		)
	return options


# Records a player-authored branch choice without advancing position. Only an
# outgoing edge of the resolved node is accepted; bad/stale UI input is inert.
func choose_pending_successor(node_id: String) -> bool:
	if not has_pending_victory() or node_id == "":
		return false
	var valid := false
	for option in get_pending_successor_options():
		if String(option.get("node_id", "")) == node_id:
			valid = true
			break
	if not valid:
		push_error(
			(
				"CampaignManager: '%s' is not a successor of pending node '%s'"
				% [node_id, String(_pending_result.get("node_id", ""))]
			)
		)
		return false
	_pending_result["next_node_id"] = node_id
	_prepared_launch.clear()
	return true


# Applies a pending VICTORY to the position: the node is cleared and the party
# moves to its successor (or the campaign completes on a terminal node). This is
# the only thing that advances the campaign — see _pending_result on why the
# advance is not done on the victory signal itself. A defeat commits nothing: the
# campaign stays parked on the current node.
func commit_pending_result() -> bool:
	if not has_pending_victory():
		return false
	if bool(_pending_result.get("revisit", false)):
		# A revisit advances no counter and prepares no successor, but it DID run a
		# map under the revisited node's rule_overrides, so it has to end them for
		# the same reason the advance path below does. Skipping this left the
		# previous node's overrides and any end_of_map rule flips live on the
		# overworld until the next node entry happened to clear them.
		var revisit_gs := get_node_or_null("/root/GameState")
		if revisit_gs != null and revisit_gs.has_method("end_campaign_map_rules"):
			revisit_gs.call("end_campaign_map_rules")
		_active_node_id = ""
		_revisiting_node_id = ""
		_pending_result.clear()
		write_autosave()
		return true
	if (
		bool(_pending_result.get("requires_successor_choice", false))
		and String(_pending_result.get("next_node_id", "")) == ""
	):
		push_error("CampaignManager: pending victory requires a successor choice")
		return false
	var node_id: String = String(_pending_result.get("node_id", ""))
	var next_id: String = String(_pending_result.get("next_node_id", ""))
	# Clearing a node is the chapter boundary. The counters advance BEFORE the
	# successor is prepared, so a trigger that fires on this clear selects the
	# battle the player is about to launch rather than the one after it; a stale
	# preparation built pre-tick is discarded when the selection actually moved.
	var previous_active := _active_cadence_triggers.duplicate()
	increment_cadence_counter("chapters_elapsed")
	increment_cadence_counter(CHAPTER_REACHED_PREFIX + node_id)
	if _active_cadence_triggers != previous_active:
		_prepared_launch.clear()
	if (
		next_id != ""
		and (_prepared_launch.is_empty() or String(_prepared_launch.get("node_id", "")) != next_id)
		and not prepare_pending_advance()
	):
		return false
	if not is_node_cleared(node_id):
		cleared_node_ids.append(node_id)
	current_node_id = next_id  # "" == terminal node cleared == campaign complete
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("end_campaign_map_rules"):
		gs.call("end_campaign_map_rules")
	_active_node_id = ""
	_revisiting_node_id = ""
	_pending_result.clear()
	# The commit IS the between-map moment — the position just advanced and the
	# party is parked. Autosaving here means every route that advances the campaign
	# autosaves, rather than each results surface having to remember to.
	write_autosave()
	return true


# Drops an unapplied result. Retry calls this: the map is about to be replayed, so
# its outcome must not advance the campaign.
func clear_pending_result() -> void:
	_pending_result.clear()
	_prepared_launch.clear()


# Results Save may commit an advanced timeline while the player keeps playing and
# chooses Retry. Restore the pre-commit campaign position as a new active branch;
# the durable advanced save remains untouched and can still be loaded later.
func restore_retry_branch(source: Dictionary, node_id: String) -> bool:
	if node_id.is_empty() or not restore_campaign_state(source, "campaign_retry_branch"):
		return false
	var campaign := get_active_campaign()
	if campaign == null or not campaign.has_node(node_id) or current_node_id != node_id:
		push_error("CampaignManager: retry branch does not resolve node '%s'" % node_id)
		return false
	_active_node_id = node_id
	_pending_result.clear()
	_prepared_launch.clear()
	return true


# --- Persistence (Slice 3) ----------------------------------------------------


# The campaign envelope: position plus campaign-scoped mutable author state,
# matching the reserved F1 campaign rows.
#
# The pending result is deliberately NOT position state. It is discarded on quit,
# so a save taken while the results surface is up restores parked on the current
# node — the map is simply replayed. Persisting it would mean a save could restore
# holding an uncommitted win, and committing it after a reload would advance a
# campaign whose map was never actually played this session.
func capture_campaign_state() -> Dictionary:
	var persisted_vars := campaign_vars.duplicate(true)
	var typed_vars := get_node_or_null("/root/CampaignVars")
	if typed_vars != null:
		persisted_vars.merge(typed_vars.call("capture_campaign_values"), true)
	return {
		"campaign_id": active_campaign_id,
		"node_id": current_node_id,
		"cleared_nodes": cleared_node_ids.duplicate(),
		"flags": campaign_flags.duplicate(),
		"vars": persisted_vars,
		"cadence": cadence_state.duplicate(true),
	}


# Restores the position from a save's campaign envelope. Every id is validated
# against the authored graph before ANY state is written: a save that names an
# unknown campaign, an unknown node, or an unknown cleared node fails loud and
# leaves no campaign active, rather than half-restoring a position the graph
# cannot walk. This is the manifest's reference_validation obligation for the row
# ("ids must resolve or load fails").
# restore_event names the playtest telemetry event emitted on success. Callers
# that re-stage an already-restored envelope (GameMap._ready re-installing the
# suspend payload) pass "campaign_restaged" so a single Continue does not log
# "campaign_restored" twice and cost triage time (V053-08).
func restore_campaign_state(source: Variant, restore_event: String = "campaign_restored") -> bool:
	if not (source is Dictionary):
		push_error("CampaignManager: campaign envelope is not a Dictionary")
		return false
	var envelope: Dictionary = source

	# An empty campaign id is a valid save: the bare single-map launch persists no
	# campaign. Restore it as "no campaign active" rather than an error.
	var campaign_id: String = String(envelope.get("campaign_id", ""))
	if campaign_id == "":
		end_campaign()
		return true

	var campaign := _get_campaign(campaign_id)
	if campaign == null:
		push_error("CampaignManager: save names unknown campaign '%s'" % campaign_id)
		return false

	# "" is the campaign-complete position (walked off the end of the graph); any
	# other id must resolve to an authored node.
	var node_id: String = String(envelope.get("node_id", ""))
	if node_id != "" and not campaign.has_node(node_id):
		push_error(
			(
				"CampaignManager: save names unknown node '%s' in campaign '%s'"
				% [node_id, campaign_id]
			)
		)
		return false

	var cleared: Array[String] = []
	var raw_cleared: Variant = envelope.get("cleared_nodes", [])
	if not (raw_cleared is Array):
		push_error("CampaignManager: save campaign.cleared_nodes is not an Array")
		return false
	for entry in raw_cleared:
		var cleared_id: String = String(entry)
		if not campaign.has_node(cleared_id):
			push_error(
				(
					"CampaignManager: save names unknown cleared node '%s' in campaign '%s'"
					% [cleared_id, campaign_id]
				)
			)
			return false
		if not cleared_id in cleared:  # a duplicate is tolerable; a wrong id is not
			cleared.append(cleared_id)

	var flags: Array[String] = []
	var raw_flags: Variant = envelope.get("flags", [])
	if not (raw_flags is Array):
		push_error("CampaignManager: save campaign.flags is not an Array")
		return false
	for entry in raw_flags:
		if not (entry is String) or String(entry).is_empty():
			push_error("CampaignManager: save campaign.flags contains an invalid id")
			return false
		if not entry in flags:
			flags.append(entry)

	var vars_value: Variant = envelope.get("vars", {})
	if not (vars_value is Dictionary):
		push_error("CampaignManager: save campaign.vars is not a Dictionary")
		return false
	var validated_vars: Dictionary = {}
	for key in vars_value:
		if not (key is String) or String(key).is_empty():
			push_error("CampaignManager: save campaign.vars contains an invalid id")
			return false
		validated_vars[key] = vars_value[key]
	var restored_cadence := _cadence.normalize_state(envelope.get("cadence", {}))

	var typed_vars := get_node_or_null("/root/CampaignVars")
	if typed_vars != null and not typed_vars.call("restore_campaign_values", validated_vars):
		push_error("CampaignManager: save campaign.vars contains an invalid typed value")
		return false

	active_campaign_id = campaign_id
	current_node_id = node_id
	cleared_node_ids = cleared
	campaign_flags = flags
	campaign_vars = validated_vars.duplicate(true)
	cadence_state = restored_cadence
	# A load is an evaluation point, but not here: autoloads a predicate reads may
	# still be settling. Dropping the derived selection makes the next resolution
	# recompute it from the restored state.
	_reset_cadence_selection()
	# Runtime-only: nothing is on a map yet, and no result is in flight. The
	# revisit and deployment-claim fields belong to the same class and are reset
	# here too — a restore taken during a revisit (restore_retry_branch is the live
	# route) otherwise left get_hub_node() answering with the revisited node while
	# the position said otherwise.
	_active_node_id = ""
	_revisiting_node_id = ""
	_deployment_counted_for = ""
	_pending_result.clear()
	_log_playtest_context(restore_event)
	return true


func _log_playtest_context(event_name: String) -> void:
	var package := {}
	var dm := get_node_or_null("/root/DataManager")
	if dm != null and dm.has_method("active_package_identity"):
		package = dm.call("active_package_identity")
	print(
		(
			"PLAYTEST CONTEXT %s"
			% (
				JSON
				. stringify(
					{
						"event": event_name,
						"campaign_id": active_campaign_id,
						"node_id": current_node_id,
						"active_node_id": _active_node_id,
						"package_id": String(package.get("package_id", "")),
						"package_version": String(package.get("package_version", "")),
						"package_path": String(package.get("path", "")),
					}
				)
			)
		)
	)


# Writes the campaign autosave slot. Returns false if the save could not be
# written; a caller that cares (a manual save) should surface that, while the
# autosave path only logs — a failed autosave must not block the player from
# continuing to the next map.
func write_autosave() -> bool:
	var results := dispatch_autosave_trigger("battle_end")
	return results.any(func(value): return bool(value))


func dispatch_autosave_trigger(trigger_id: String, context: Dictionary = {}) -> Array:
	# Custom author ids use the identical registry path; registration is additive,
	# never a hardcoded trigger enum or match branch.
	if not _autosave_triggers.has_trigger(trigger_id):
		_autosave_triggers.register(trigger_id, _handle_autosave_trigger)
	return _autosave_triggers.dispatch(trigger_id, context)


func _handle_autosave_trigger(trigger_id: String, context: Dictionary) -> bool:
	var gs := get_node_or_null("/root/GameState")
	var sm := get_node_or_null("/root/SaveManager")
	if (
		gs == null
		or sm == null
		or not gs.has_method("capture_save")
		or not sm.has_method("save_automatic")
	):
		return false
	var rules: CampaignRules = gs.get("campaign_rules") as CampaignRules
	if rules == null:
		return false
	var wrote_any := false
	for rule in rules.autosave_rules:
		if String(rule.get("trigger", "")) != trigger_id or int(rule.get("keep", 0)) <= 0:
			continue
		var turn_manager: Node = context.get("turn_manager", null)
		var cursor: Node = context.get("cursor", null)
		var save: Variant = gs.call(
			"capture_save", String(rule.get("label", "Autosave")), turn_manager, cursor
		)
		if (
			save != null
			and bool(
				sm.call(
					"save_automatic",
					String(rule.get("rule_id", "")),
					int(rule.get("keep", 0)),
					save
				)
			)
		):
			wrote_any = true
	return wrote_any


# Writes the parked position + party to a campaign slot. This is the seam the
# manual-save UI calls with its own slot id.
func write_campaign_slot(
	slot_id: String, save_label: String, origin: String = "manual", rule_id: String = ""
) -> bool:
	if not is_campaign_active():
		return false  # a bare single-map launch has no campaign to save
	var gs := get_node_or_null("/root/GameState")
	var sm := get_node_or_null("/root/SaveManager")
	if (
		gs == null
		or sm == null
		or not gs.has_method("capture_save")
		or not sm.has_method("save_slot")
	):
		# No disk seam wired (headless tests drive the position directly). The
		# position is still correct in memory; only persistence is skipped.
		return false
	var save: Variant = gs.call("capture_save", save_label)
	if save == null:
		push_error("CampaignManager: campaign save capture failed for slot '%s'" % slot_id)
		return false
	if not bool(sm.call("save_slot", slot_id, save, origin, rule_id)):
		push_error("CampaignManager: failed to write campaign slot '%s'" % slot_id)
		return false
	return true


# Slot rows are what the load picker shows, so the label names the position the
# save restores to: the node the party is parked ON, not the one just cleared.
func _autosave_label() -> String:
	var campaign := get_active_campaign()
	var campaign_label: String = campaign.label if campaign != null else active_campaign_id
	if is_campaign_complete():
		return "%s - Complete" % campaign_label
	var node := get_current_node()
	var node_label: String = node.label if node != null and node.label != "" else current_node_id
	return "%s - %s" % [campaign_label, node_label]


# Terminal and linear nodes need no player prompt. A branch intentionally has no
# successor until choose_pending_successor() receives the explicit UI choice.
func _unambiguous_successor_of(node: CampaignNode) -> String:
	if node.next_node_ids.size() != 1:
		return ""
	return node.next_node_ids[0]


func _get_campaign(campaign_id: String) -> CampaignData:
	var dm := get_node_or_null("/root/DataManager")
	if dm == null or not bool(dm.call("has_campaign", campaign_id)):
		return null
	return dm.call("get_campaign", campaign_id)
