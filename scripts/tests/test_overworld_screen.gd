extends SceneTree
# Overworld contract: authored traversal mode, availability projection, responsive
# scene construction, and revisit results that never advance campaign position.

const CampaignManagerScript = preload("res://scripts/autoloads/CampaignManager.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	var bus: Node = load("res://scripts/autoloads/EventBus.gd").new()
	bus.name = "EventBus"
	root.add_child(bus)
	var registry: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	registry.name = "RegistryManager"
	root.add_child(registry)
	var dm: Node = load("res://scripts/autoloads/DataManager.gd").new()
	dm.name = "DataManager"
	root.add_child(dm)
	var cm := CampaignManagerScript.new()
	cm.name = "CampaignManager"
	root.add_child(cm)
	await process_frame

	cm.start_campaign("proving_grounds")
	var campaign: CampaignData = cm.get_active_campaign()
	campaign.traversal_mode = "free_roam"
	cm.cleared_node_ids = ["node_01_rout"]
	cm.current_node_id = "node_02_seize"
	var rows: Array = cm.get_overworld_nodes()
	_check(cm.uses_overworld(), "free-roam campaign enables the overworld")
	_check(
		(
			bool(rows[0].get("cleared"))
			and bool(rows[0].get("available"))
			and bool(rows[1].get("current"))
			and not bool(rows[2].get("available"))
		),
		"only cleared and current graph nodes are available"
	)

	var screen: Node = load("res://scenes/ui/OverworldScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	_check(
		screen.get_node("Margin/VBox/Canvas/Nodes").get_child_count() == rows.size(),
		"overworld scene projects every authored node without copying graph policy"
	)

	cm._active_node_id = "node_01_rout"
	cm._revisiting_node_id = "node_01_rout"
	cm._record_result(true)
	var before_position := cm.current_node_id
	_check(
		(
			bool(cm.get_pending_result().get("revisit", false))
			and cm.get_pending_successor_options().is_empty()
		),
		"repeat visit result is marked and exposes no successor advance"
	)
	_check(
		(
			cm.commit_pending_result()
			and cm.current_node_id == before_position
			and cm.cleared_node_ids == ["node_01_rout"]
		),
		"committing a revisit preserves campaign position and clear history"
	)

	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed else 0)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1
