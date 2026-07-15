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

const _GAME_MAP_SCENE := "res://scenes/core/GameMap.tscn"
const _PREP_SCENE := "res://scenes/ui/PrepScreen.tscn"
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
var _autosave_triggers := AutosaveTriggerRegistryScript.new()


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


# --- Campaign lifecycle -------------------------------------------------------

# Seeds a run at the campaign's start node. Unknown id fails loud and leaves no
# campaign active, rather than parking the player on a campaign that cannot run.
func start_campaign(campaign_id: String) -> bool:
	var campaign := _get_campaign(campaign_id)
	if campaign == null:
		push_error("CampaignManager: cannot start unknown campaign '%s'" % campaign_id)
		return false
	if not campaign.has_node(campaign.start_node_id):
		push_error("CampaignManager: campaign '%s' start node '%s' is not in the graph" % [
			campaign_id, campaign.start_node_id])
		return false
	active_campaign_id = campaign_id
	current_node_id = campaign.start_node_id
	cleared_node_ids.clear()
	campaign_flags.clear()
	campaign_vars.clear()
	_active_node_id = ""
	_pending_result.clear()
	_prepared_launch.clear()
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("apply_campaign_rule_overrides"):
		gs.call("apply_campaign_rule_overrides", campaign.rule_overrides,
			campaign.mandated_rule_ids)
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
	_active_node_id = ""
	_pending_result.clear()
	_prepared_launch.clear()


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
	return store.export_completion(active_status_target(), state, {
		"completed": true,
		"ending_id": String(campaign_vars.get("ending_id", "")),
		"route_id": String(campaign_vars.get("route_id", "")),
		"rank_id": String(campaign_vars.get("rank_id", "")),
	}, {
		"maps_completed": cleared_node_ids.size(),
		"turns_taken": int(campaign_vars.get("turns_taken", 0)),
	})


func is_campaign_active() -> bool:
	return active_campaign_id != ""


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


# --- Launch (the "prep -> map" seam) -----------------------------------------

# Resolves the current node's map binding, prepares the party, then parks on prep.
# Prep only authors a deployment plan; it must never reapply the roster policy.
func launch_current_node() -> bool:
	var node := get_current_node()
	if node == null:
		push_error("CampaignManager: no current node to launch (campaign '%s')" % active_campaign_id)
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
		push_error("CampaignManager: node '%s' has no valid roster for policy '%s'" % [
			node.node_id, roster_policy])
		return false
	if gs.has_method("begin_campaign_map_rules"):
		gs.call("begin_campaign_map_rules", node.rule_overrides)

	_active_node_id = node.node_id
	_pending_result.clear()
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
	if _prepared_launch.is_empty() \
			or String(_prepared_launch.get("node_id", "")) != current_node_id:
		push_error("CampaignManager: no prepared launch for current node '%s'" % current_node_id)
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return false
	gs.call("configure_next_map", String(_prepared_launch["map_data_path"]),
		String(_prepared_launch["roster_policy"]), String(_prepared_launch["roster_source"]))
	if gs.has_method("begin_campaign_map_rules"):
		gs.call("begin_campaign_map_rules", _prepared_launch.get("rule_overrides", {}))
	_active_node_id = current_node_id
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


# Resolves a node's map binding into the launch parameters GameState needs.
# Empty on an unresolvable binding. Split out from launch_current_node so the
# resolution is testable without changing scene.
func resolve_launch_params(node: CampaignNode) -> Dictionary:
	var dm := get_node_or_null("/root/DataManager")
	if dm == null or not bool(dm.call("has_map_registry_entry", node.map_id)):
		push_error("CampaignManager: node '%s' binds to unknown map id '%s'" % [
			node.node_id, node.map_id])
		return {}
	var entry: Dictionary = dm.call("get_map_registry_entry", node.map_id)

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
		"map_data_path": String(entry.get("map_data_path", "")),
		"roster_policy": roster_policy,
		"roster_source": roster_source,
		"rule_overrides": node.rule_overrides.duplicate(true),
	}


# Prepares the party for the launch policy. Mirrors NewGameScreen's policy switch;
# a policy with no valid prepared roster fails rather than silently falling back
# to the default roster (which would wipe a campaign party).
func _apply_roster_policy(gs: Node, roster_policy: String, roster_source: String) -> bool:
	match roster_policy:
		"default_roster":
			return bool(gs.call("load_default_roster"))
		"fixed_test_roster":
			if roster_source == "":
				return false
			return bool(gs.call("load_roster_from_directory", roster_source, "fixed_test_roster"))
		"campaign_pack_roster":
			var dm := get_node_or_null("/root/DataManager")
			if dm == null or not dm.has_method("get_campaign_pack_roster"):
				return false
			var roster: Array = dm.call("get_campaign_pack_roster", roster_source)
			return bool(gs.call("load_roster_resources", roster,
				"campaign_pack_roster", roster_source))
		"keep_current_roster":
			return bool(gs.call("is_roster_ready_for_launch"))
		_:
			push_error("CampaignManager: unknown roster policy '%s'" % roster_policy)
			return false


# --- Result handling ----------------------------------------------------------

func _on_map_victory() -> void:
	_record_result(true)


func _on_map_defeat() -> void:
	_record_result(false)


# Records the outcome for the node that was actually LAUNCHED (_active_node_id),
# not the position — so a retried map records against the node being replayed.
func _record_result(victory: bool) -> void:
	if not is_campaign_active() or _active_node_id == "":
		return  # bare single-map launch: nothing to track
	var campaign := get_active_campaign()
	var node: CampaignNode = campaign.get_node_by_id(_active_node_id) if campaign != null else null
	if node == null:
		push_error("CampaignManager: resolved node '%s' is not in campaign '%s'" % [
			_active_node_id, active_campaign_id])
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
		"winner_group": "",
		"standings": [],
	}
	_prepared_launch.clear()


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
	var campaign := get_active_campaign()
	var node_id: String = String(_pending_result.get("node_id", ""))
	var node: CampaignNode = campaign.get_node_by_id(node_id) if campaign != null else null
	if node == null:
		return options
	for successor_id in node.next_node_ids:
		var successor: CampaignNode = campaign.get_node_by_id(successor_id)
		if successor == null:
			continue
		options.append({
			"node_id": successor_id,
			"label": successor.label if successor.label != "" else successor_id,
		})
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
		push_error("CampaignManager: '%s' is not a successor of pending node '%s'" % [
			node_id, String(_pending_result.get("node_id", ""))])
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
	if bool(_pending_result.get("requires_successor_choice", false)) \
			and String(_pending_result.get("next_node_id", "")) == "":
		push_error("CampaignManager: pending victory requires a successor choice")
		return false
	var node_id: String = String(_pending_result.get("node_id", ""))
	var next_id: String = String(_pending_result.get("next_node_id", ""))
	if next_id != "" and (_prepared_launch.is_empty() \
			or String(_prepared_launch.get("node_id", "")) != next_id) \
			and not prepare_pending_advance():
		return false
	if not is_node_cleared(node_id):
		cleared_node_ids.append(node_id)
	current_node_id = next_id  # "" == terminal node cleared == campaign complete
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("end_campaign_map_rules"):
		gs.call("end_campaign_map_rules")
	_active_node_id = ""
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
	return {
		"campaign_id": active_campaign_id,
		"node_id": current_node_id,
		"cleared_nodes": cleared_node_ids.duplicate(),
		"flags": campaign_flags.duplicate(),
		"vars": campaign_vars.duplicate(true),
	}


# Restores the position from a save's campaign envelope. Every id is validated
# against the authored graph before ANY state is written: a save that names an
# unknown campaign, an unknown node, or an unknown cleared node fails loud and
# leaves no campaign active, rather than half-restoring a position the graph
# cannot walk. This is the manifest's reference_validation obligation for the row
# ("ids must resolve or load fails").
func restore_campaign_state(source: Variant) -> bool:
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
		push_error("CampaignManager: save names unknown node '%s' in campaign '%s'" % [
			node_id, campaign_id])
		return false

	var cleared: Array[String] = []
	var raw_cleared: Variant = envelope.get("cleared_nodes", [])
	if not (raw_cleared is Array):
		push_error("CampaignManager: save campaign.cleared_nodes is not an Array")
		return false
	for entry in raw_cleared:
		var cleared_id: String = String(entry)
		if not campaign.has_node(cleared_id):
			push_error("CampaignManager: save names unknown cleared node '%s' in campaign '%s'" % [
				cleared_id, campaign_id])
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

	active_campaign_id = campaign_id
	current_node_id = node_id
	cleared_node_ids = cleared
	campaign_flags = flags
	campaign_vars = validated_vars.duplicate(true)
	# Runtime-only: nothing is on a map yet, and no result is in flight.
	_active_node_id = ""
	_pending_result.clear()
	return true


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
	if gs == null or sm == null or not gs.has_method("capture_save") \
			or not sm.has_method("save_automatic"):
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
		var save: Variant = gs.call("capture_save", String(rule.get("label", "Autosave")),
			turn_manager, cursor)
		if save != null and bool(sm.call("save_automatic", String(rule.get("rule_id", "")),
				int(rule.get("keep", 0)), save)):
			wrote_any = true
	return wrote_any


# Writes the parked position + party to a campaign slot. This is the seam the
# manual-save UI calls with its own slot id.
func write_campaign_slot(slot_id: String, save_label: String, origin: String = "manual",
		rule_id: String = "") -> bool:
	if not is_campaign_active():
		return false  # a bare single-map launch has no campaign to save
	var gs := get_node_or_null("/root/GameState")
	var sm := get_node_or_null("/root/SaveManager")
	if gs == null or sm == null or not gs.has_method("capture_save") \
			or not sm.has_method("save_slot"):
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
