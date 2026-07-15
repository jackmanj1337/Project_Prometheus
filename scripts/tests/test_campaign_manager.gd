extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_campaign_manager.gd
# Tests the B1-CST Slice 2 campaign runtime flow: node advance on victory, defeat
# handling, the results state handoff, and the retry double-advance guard.
#
# launch_current_node() changes scene, so the tests drive the two halves it is
# built from instead: resolve_launch_params() for the map/roster resolution, and
# the _active_node_id marker it sets (poked directly, as elsewhere in this suite)
# to stand in for "this node is the one on the map right now".

const DataManagerScript = preload("res://scripts/autoloads/DataManager.gd")
const CampaignManagerScript = preload("res://scripts/autoloads/CampaignManager.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== CampaignManager Test ===")

	# Autoload stand-ins, in dependency order: CampaignManager binds EventBus at
	# _ready and resolves campaigns/maps through DataManager.
	var bus: Node = load("res://scripts/autoloads/EventBus.gd").new()
	bus.name = "EventBus"
	root.add_child(bus)
	var registry_manager: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	registry_manager.name = "RegistryManager"
	root.add_child(registry_manager)
	var dm: Node = DataManagerScript.new()
	dm.name = "DataManager"
	root.add_child(dm)
	var cm: Node = CampaignManagerScript.new()
	cm.name = "CampaignManager"
	root.add_child(cm)
	var gs_script := GDScript.new()
	gs_script.source_code = "extends Node\nvar roster_ready := true\nfunc is_roster_ready_for_launch() -> bool: return roster_ready\nfunc configure_next_map(_path: String, _policy: String, _source: String) -> void: pass\n"
	gs_script.reload()
	var gs: Node = gs_script.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame

	_test_map_registry_accessor(dm)
	_test_start_campaign(cm)
	_test_launch_resolution(cm)
	_test_victory_advances_node(cm, bus)
	_test_defeat_parks_on_node(cm, bus)
	_test_retry_does_not_advance(cm, bus)
	_test_campaign_completes_on_terminal_node(cm, bus)
	_test_single_map_launch_unaffected(cm, bus)
	_test_campaign_envelope_roundtrip(cm)
	_test_restore_rejects_unresolvable_ids(cm)
	_test_restore_of_a_bare_map_save(cm)
	_test_pending_result_is_not_position_state(cm, bus)
	_test_branch_requires_explicit_successor(cm, bus)
	_test_advance_validates_before_commit(cm, bus, gs)

	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s%s" % [label, ("" if detail == "" else " — %s" % detail)])
		_failed += 1


# --- DataManager map registry accessor (the Slice 2 lookup gap) ---------------

func _test_map_registry_accessor(dm: Node) -> void:
	var entry: Dictionary = dm.get_map_registry_entry("map_002_seize")
	_check(dm.has_map_registry_entry("map_002_seize")
			and entry.get("map_data_path", "") == "res://data/maps/map_002_seize/map_002_seize_data.tres"
			and entry.get("roster_policy", "") == "default_roster",
		"DataManager resolves a map registry entry by id", str(entry))
	_check(not dm.has_map_registry_entry("map_does_not_exist"),
		"DataManager reports an unknown map id as absent")


# --- Campaign lifecycle -------------------------------------------------------

func _test_start_campaign(cm: Node) -> void:
	_check(cm.start_campaign("proving_grounds")
			and cm.is_campaign_active()
			and cm.active_campaign_id == "proving_grounds"
			and cm.current_node_id == "node_01_rout"
			and cm.cleared_node_ids.is_empty()
			and not cm.is_campaign_complete(),
		"start_campaign seeds the position at the start node")

	cm.end_campaign()
	_check(not cm.start_campaign("no_such_campaign") and not cm.is_campaign_active(),
		"start_campaign fails loud on an unknown campaign id and leaves none active")


# The first node seeds the party from the registry's authored policy; later nodes
# keep the party they earned, or levels and gold would reset every map.
func _test_launch_resolution(cm: Node) -> void:
	cm.start_campaign("proving_grounds")
	var first: Dictionary = cm.resolve_launch_params(cm.get_current_node())
	_check(first.get("map_data_path", "") == "res://data/maps/map_001_rout/map_001_data.tres"
			and first.get("roster_policy", "") == "default_roster",
		"the start node resolves to its registry map and authored roster policy", str(first))

	cm.cleared_node_ids.append("node_01_rout")
	cm.current_node_id = "node_02_seize"
	var later: Dictionary = cm.resolve_launch_params(cm.get_current_node())
	_check(later.get("map_data_path", "") == "res://data/maps/map_002_seize/map_002_seize_data.tres"
			and later.get("roster_policy", "") == "keep_current_roster"
			and later.get("roster_source", "") == "",
		"a later node keeps the campaign party instead of reloading the default roster", str(later))
	cm.end_campaign()


# --- Flow: victory / defeat / results handoff --------------------------------

# Puts the campaign in the state launch_current_node() would leave it in: parked
# on `node_id` with that node live on the map.
func _park_on(cm: Node, node_id: String) -> void:
	cm.start_campaign("proving_grounds")
	cm.current_node_id = node_id
	cm._active_node_id = node_id


func _test_victory_advances_node(cm: Node, bus: Node) -> void:
	_park_on(cm, "node_01_rout")
	bus.map_victory.emit()
	bus.map_resolved.emit("blue", [{"rank": 1, "group": "allies", "is_blue_group": true}])

	var result: Dictionary = cm.get_pending_result()
	_check(cm.has_pending_victory()
			and result.get("node_id", "") == "node_01_rout"
			and result.get("next_node_id", "") == "node_02_seize"
			and not bool(result.get("campaign_complete", true))
			and result.get("winner_group", "") == "blue"
			and (result.get("standings", []) as Array).size() == 1,
		"a win records the results payload (node, successor, winner, standings)", str(result))
	_check(cm.current_node_id == "node_01_rout" and cm.cleared_node_ids.is_empty(),
		"the position does not move until the result is committed")

	_check(cm.commit_pending_result()
			and cm.current_node_id == "node_02_seize"
			and cm.is_node_cleared("node_01_rout")
			and cm.get_pending_result().is_empty()
			and not cm.is_campaign_complete(),
		"committing the win clears the node and advances to its successor")
	cm.end_campaign()


func _test_defeat_parks_on_node(cm: Node, bus: Node) -> void:
	_park_on(cm, "node_02_seize")
	bus.map_defeat.emit()
	bus.map_resolved.emit("red", [{"rank": 1, "group": "foes", "is_blue_group": false}])

	var result: Dictionary = cm.get_pending_result()
	_check(not bool(result.get("victory", true)) and not cm.has_pending_victory(),
		"a loss records a non-victory result")
	_check(not cm.commit_pending_result()
			and cm.current_node_id == "node_02_seize"
			and cm.cleared_node_ids.is_empty(),
		"a loss neither clears nor advances the node — the campaign stays parked")
	cm.end_campaign()


# The retry landmine: Retry replays the SAME map, so the win it discards must not
# leave the campaign a node ahead, and re-winning must not skip a node.
func _test_retry_does_not_advance(cm: Node, bus: Node) -> void:
	_park_on(cm, "node_01_rout")
	bus.map_victory.emit()
	cm.clear_pending_result()  # what GameOverScreen._on_retry does

	_check(not cm.has_pending_victory()
			and not cm.commit_pending_result()
			and cm.current_node_id == "node_01_rout"
			and cm.cleared_node_ids.is_empty(),
		"retry drops the pending win, so the campaign stays on the replayed node")

	# Replay the same map and win again: exactly one advance, no skipped node.
	bus.map_victory.emit()
	_check(cm.commit_pending_result()
			and cm.current_node_id == "node_02_seize"
			and cm.cleared_node_ids.size() == 1
			and cm.cleared_node_ids[0] == "node_01_rout",
		"winning the retried map advances exactly one node", str(cm.cleared_node_ids))
	cm.end_campaign()


func _test_campaign_completes_on_terminal_node(cm: Node, bus: Node) -> void:
	_park_on(cm, "node_05_defend")
	bus.map_victory.emit()

	var result: Dictionary = cm.get_pending_result()
	_check(bool(result.get("campaign_complete", false))
			and result.get("next_node_id", "x") == "",
		"a win on the terminal node reports the campaign as complete", str(result))
	_check(cm.commit_pending_result()
			and cm.current_node_id == ""
			and cm.is_campaign_complete()
			and cm.is_node_cleared("node_05_defend"),
		"committing the terminal win completes the campaign")
	cm.end_campaign()


# Slice 2 is additive: a bare single-map launch (NewGameScreen) has no campaign,
# so the map result must not be tracked or routed anywhere.
func _test_single_map_launch_unaffected(cm: Node, bus: Node) -> void:
	cm.end_campaign()
	bus.map_victory.emit()
	bus.map_resolved.emit("blue", [])
	_check(cm.get_pending_result().is_empty()
			and not cm.has_pending_victory()
			and not cm.is_campaign_active()
			and not cm.is_campaign_complete(),
		"a map won with no campaign active records nothing")


# --- Slice 3: the campaign save envelope --------------------------------------

# The envelope is exactly the three F1 manifest fields, and a restore must land
# the position back where the capture took it.
func _test_campaign_envelope_roundtrip(cm: Node) -> void:
	cm.start_campaign("proving_grounds")
	cm.cleared_node_ids.append("node_01_rout")
	cm.current_node_id = "node_02_seize"
	cm.set_campaign_flag("recruited_guide")
	cm.set_campaign_flag("recruited_guide")  # set semantics deduplicate
	cm.set_campaign_var("villages_saved", 2)

	var envelope: Dictionary = cm.capture_campaign_state()
	_check(envelope.get("campaign_id", "") == "proving_grounds"
			and envelope.get("node_id", "") == "node_02_seize"
			and envelope.get("cleared_nodes", []) == ["node_01_rout"]
			and envelope.get("flags", []) == ["recruited_guide"]
			and envelope.get("vars", {}).get("villages_saved", 0) == 2
			and envelope.size() == 5,
		"capture_campaign_state writes position plus mutable campaign state", str(envelope))

	cm.end_campaign()
	_check(cm.restore_campaign_state(envelope)
			and cm.active_campaign_id == "proving_grounds"
			and cm.current_node_id == "node_02_seize"
			and cm.cleared_node_ids == ["node_01_rout"]
			and cm.has_campaign_flag("recruited_guide")
			and cm.get_campaign_var("villages_saved") == 2
			and cm.is_campaign_active(),
		"restore_campaign_state restores position, flags, and vars")

	# The captured array must not alias the live one, or a later clear would edit
	# the save that was already taken.
	var captured: Dictionary = cm.capture_campaign_state()
	cm.cleared_node_ids.append("node_02_seize")
	_check(captured.get("cleared_nodes", []) == ["node_01_rout"],
		"the captured envelope does not alias the live cleared list",
		str(captured.get("cleared_nodes", [])))
	cm.campaign_vars["villages_saved"] = 9
	_check(captured.get("vars", {}).get("villages_saved") == 2,
		"the captured vars dictionary does not alias live state")
	cm.end_campaign()


# The manifest's reference_validation obligation for the row: ids must resolve or
# the load fails — and a failed load must leave NO campaign active, never a
# half-restored position the graph cannot walk.
func _test_restore_rejects_unresolvable_ids(cm: Node) -> void:
	cm.end_campaign()
	_check(not cm.restore_campaign_state({"campaign_id": "no_such_campaign", "node_id": "node_01_rout"})
			and not cm.is_campaign_active(),
		"restore rejects a save naming an unknown campaign")

	cm.end_campaign()
	_check(not cm.restore_campaign_state({"campaign_id": "proving_grounds", "node_id": "no_such_node"})
			and not cm.is_campaign_active(),
		"restore rejects a save naming an unknown node")

	cm.end_campaign()
	_check(not cm.restore_campaign_state({
				"campaign_id": "proving_grounds",
				"node_id": "node_02_seize",
				"cleared_nodes": ["node_01_rout", "no_such_node"],
			})
			and not cm.is_campaign_active(),
		"restore rejects a save naming an unknown cleared node")

	cm.end_campaign()
	_check(not cm.restore_campaign_state({
			"campaign_id": "proving_grounds", "node_id": "node_01_rout",
			"flags": ["", "valid"], "vars": {},
		}) and not cm.is_campaign_active(),
		"restore rejects malformed campaign flags before applying state")

	cm.end_campaign()
	_check(not cm.restore_campaign_state({
			"campaign_id": "proving_grounds", "node_id": "node_01_rout",
			"flags": [], "vars": [],
		}) and not cm.is_campaign_active(),
		"restore rejects malformed campaign vars before applying state")

	# "" is the campaign-complete position (walked off the end of the graph), not
	# an unknown node — it must load, and load AS complete.
	cm.end_campaign()
	_check(cm.restore_campaign_state({
				"campaign_id": "proving_grounds",
				"node_id": "",
				"cleared_nodes": ["node_01_rout"],
			})
			and cm.is_campaign_active()
			and cm.is_campaign_complete(),
		"restore accepts the completed-campaign position")
	cm.end_campaign()


# The bare single-map launch persists no campaign, so its save carries an empty
# campaign id. That is a valid document, not a corrupt one.
func _test_restore_of_a_bare_map_save(cm: Node) -> void:
	cm.start_campaign("proving_grounds")
	_check(cm.restore_campaign_state({"campaign_id": "", "node_id": "", "cleared_nodes": []})
			and not cm.is_campaign_active()
			and cm.current_node_id == ""
			and cm.cleared_node_ids.is_empty(),
		"restoring a save with no campaign leaves no campaign active")


# A save taken while the results surface is up must restore parked on the current
# node — the pending win is discarded, so a reload cannot commit a map that was
# never played this session.
func _test_pending_result_is_not_position_state(cm: Node, bus: Node) -> void:
	_park_on(cm, "node_01_rout")
	bus.map_victory.emit()
	_check(cm.has_pending_victory(), "a win is pending before the save is taken")

	var envelope: Dictionary = cm.capture_campaign_state()
	_check(envelope.get("node_id", "") == "node_01_rout"
			and envelope.get("cleared_nodes", []) == []
			and not envelope.has("pending_result"),
		"the envelope holds the parked node, not the uncommitted win", str(envelope))

	cm.end_campaign()
	cm.restore_campaign_state(envelope)
	_check(not cm.has_pending_victory()
			and cm.get_pending_result().is_empty()
			and cm.current_node_id == "node_01_rout"
			and not cm.is_node_cleared("node_01_rout"),
		"the restored campaign holds no pending result and is parked on the node")
	cm.end_campaign()


func _test_advance_validates_before_commit(cm: Node, bus: Node, gs: Node) -> void:
	_park_on(cm, "node_01_rout")
	bus.map_victory.emit()
	cm._pending_result["next_node_id"] = "missing_successor"
	_check(not cm.commit_pending_result()
			and cm.current_node_id == "node_01_rout"
			and cm.has_pending_victory()
			and cm.cleared_node_ids.is_empty(),
		"an invalid successor leaves the pending victory retryable")

	cm._pending_result["next_node_id"] = "node_02_seize"
	gs.set("roster_ready", false)
	_check(not cm.prepare_pending_advance() and cm.has_pending_victory(),
		"an unprepared roster does not consume the pending victory")
	gs.set("roster_ready", true)
	_check(cm.prepare_pending_advance() and cm.commit_pending_result()
			and cm.current_node_id == "node_02_seize"
			and not cm.has_pending_victory(),
		"a valid successor prepares and advances exactly once")
	cm.end_campaign()


func _test_branch_requires_explicit_successor(cm: Node, bus: Node) -> void:
	_park_on(cm, "node_01_rout")
	var node: CampaignNode = cm.get_current_node()
	var authored_successors := node.next_node_ids.duplicate()
	node.next_node_ids = ["node_02_seize", "node_03_boss"]
	bus.map_victory.emit()
	var result: Dictionary = cm.get_pending_result()
	var options: Array = cm.get_pending_successor_options()
	_check(bool(result.get("requires_successor_choice", false))
			and result.get("next_node_id", "sentinel") == ""
			and options.size() == 2
			and options[0].get("node_id", "") == "node_02_seize"
			and options[1].get("node_id", "") == "node_03_boss",
		"a branch exposes authored successors without silently choosing the first",
		str({"result": result, "options": options}))
	_check(not cm.commit_pending_result()
			and cm.current_node_id == "node_01_rout"
			and cm.cleared_node_ids.is_empty(),
		"an unresolved branch cannot commit campaign position")
	_check(not cm.choose_pending_successor("node_05_defend")
			and cm.choose_pending_successor("node_03_boss")
			and cm.get_pending_result().get("next_node_id", "") == "node_03_boss",
		"only an authored outgoing edge can become the explicit branch choice")
	_check(cm.commit_pending_result()
			and cm.current_node_id == "node_03_boss"
			and cm.is_node_cleared("node_01_rout"),
		"the chosen branch, rather than authored index zero, is committed")
	node.next_node_ids = authored_successors
	cm.end_campaign()
