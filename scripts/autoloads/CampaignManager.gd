extends Node
# B1-CST Slice 2 — the campaign RUNTIME position and the prep -> map ->
# victory/defeat -> results -> next node flow.
#
# Authority: GDD_01 §CampaignData Contract, GDD_05 §Campaign Flow
# Slice 1 (CampaignData/CampaignNode + DataManager loading) built the authored
# progression GRAPH. This autoload is the thing that WALKS it: which campaign is
# active, which node the party is parked on, and which nodes are cleared.
#
# Scope guards:
# - Persists NOTHING. The position is runtime-only until Slice 3 registers the
#   campaign envelope (campaign.campaign_id / node_id / cleared_nodes[]) in the
#   F1 save manifest. An unregistered persisted field is a bug.
# - Owns the FLOW, not the prep SCREENS. Roster selection, trade, and deployment
#   UI belong to B4-PREP-DEPLOYMENT; the campaign selector belongs to
#   B6-CAMPAIGN-SHARING.
# - Additive only. With no campaign active every handler here no-ops, so the bare
#   single-map launch from NewGameScreen behaves exactly as it did before.

const _GAME_MAP_SCENE := "res://scenes/core/GameMap.tscn"
const _DEFAULT_ROSTER_PATH := "res://data/roster/default/"

# --- Runtime position --------------------------------------------------------

# Empty campaign id == no campaign active == every signal handler below no-ops.
var active_campaign_id: String = ""

# The node the party is parked on: the one that launches next. On victory this
# moves to the cleared node's successor; on defeat it does not move.
var current_node_id: String = ""

# Nodes beaten this run, in clear order.
var cleared_node_ids: Array[String] = []

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


func _ready() -> void:
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
	_active_node_id = ""
	_pending_result.clear()
	return true


# Drops the run. Called when the player quits to menu; also the reset seam tests
# use between cases.
func end_campaign() -> void:
	active_campaign_id = ""
	current_node_id = ""
	cleared_node_ids.clear()
	_active_node_id = ""
	_pending_result.clear()


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

# Resolves the current node's map binding through the map registry and hands off
# to the existing GameState launch seam. The prep SCREENS are not this slice; this
# is the entry point they will eventually call.
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

	_active_node_id = node.node_id
	_pending_result.clear()
	get_tree().change_scene_to_file(_GAME_MAP_SCENE)
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
		# Successor the commit would move to; "" when clearing this node ends the run.
		"next_node_id": _successor_of(node),
		"campaign_complete": victory and node.is_terminal(),
		"winner_group": "",
		"standings": [],
	}


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


# Applies a pending VICTORY to the position: the node is cleared and the party
# moves to its successor (or the campaign completes on a terminal node). This is
# the only thing that advances the campaign — see _pending_result on why the
# advance is not done on the victory signal itself. A defeat commits nothing: the
# campaign stays parked on the current node.
func commit_pending_result() -> bool:
	if not has_pending_victory():
		return false
	var node_id: String = String(_pending_result.get("node_id", ""))
	var next_id: String = String(_pending_result.get("next_node_id", ""))
	if not is_node_cleared(node_id):
		cleared_node_ids.append(node_id)
	current_node_id = next_id  # "" == terminal node cleared == campaign complete
	_active_node_id = ""
	_pending_result.clear()
	return true


# Drops an unapplied result. Retry calls this: the map is about to be replayed, so
# its outcome must not advance the campaign.
func clear_pending_result() -> void:
	_pending_result.clear()


# Successor for the linear MVP case. A branching node (multiple successors) needs
# a player choice, which lands with the campaign selector/branch UI — take the
# first authored successor until then, since authored order is the ordering
# contract ([CST-3]).
func _successor_of(node: CampaignNode) -> String:
	if node.is_terminal():
		return ""
	return node.next_node_ids[0]


func _get_campaign(campaign_id: String) -> CampaignData:
	var dm := get_node_or_null("/root/DataManager")
	if dm == null or not bool(dm.call("has_campaign", campaign_id)):
		return null
	return dm.call("get_campaign", campaign_id)
