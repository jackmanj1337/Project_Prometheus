extends SceneTree
# The bundled-pack gate reads two things the bridge did not publish before v4:
# which campaigns the New Game selector OFFERS (by identity, not dropdown index)
# and which campaign node was actually launched into the live map. v0.7.13 shipped
# a bundled pack that failed at import; nothing downstream could have proved the
# pack's campaigns reach a map, because neither fact left the engine.

const BridgeScript = preload("res://scripts/autoloads/WebTestBridge.gd")
const NewGameScreenScene = preload("res://scenes/ui/NewGameScreen.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var bridge := BridgeScript.new()
	root.add_child(bridge)
	await process_frame

	if BridgeScript.VERSION != 4:
		print("FAIL bridge version must advance with its published contract")
		quit(1)
		return

	# No NewGameScreen in the tree: the gate must read an explicit empty offer,
	# never a missing key it would have to guess about.
	var absent: Dictionary = bridge._new_game_entries_snapshot()
	if absent.get("offered") != [] or absent.get("selected") != -1:
		print("FAIL bridge invented New Game entries with no selector present: %s" % [absent])
		quit(1)
		return
	print("OK  bridge reports an empty offer when no selector exists")

	var screen := NewGameScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	if not screen.has_method("offered_campaign_entries"):
		print("FAIL NewGameScreen no longer publishes its offered campaigns")
		quit(1)
		return
	var offered: Array = screen.call("offered_campaign_entries")
	for entry: Dictionary in offered:
		for field: String in ["index", "label", "campaign_id", "campaign_version"]:
			if not entry.has(field):
				print("FAIL offered campaign entry omits '%s': %s" % [field, entry])
				quit(1)
				return
	print("OK  every offered campaign entry carries launchable identity (%d)" % offered.size())

	# The launched node is what proves a selector entry reached its map. It is a
	# distinct field from the parked position on purpose: they disagree during a
	# launch, and the gate asserts on the one that means "this map is live".
	var manager: Node = root.get_node_or_null("CampaignManager")
	if manager == null:
		manager = load("res://scripts/autoloads/CampaignManager.gd").new()
		manager.name = "CampaignManager"
		root.add_child(manager)
		await process_frame
	manager.active_campaign_id = "gate_campaign"
	manager.current_node_id = "node_b"
	manager.set("_active_node_id", "node_a")
	var campaign: Dictionary = bridge._active_campaign_snapshot()
	if campaign.get("campaignId") != "gate_campaign":
		print("FAIL bridge omitted the active campaign id: %s" % [campaign])
		quit(1)
		return
	if campaign.get("activeNodeId") != "node_a" or campaign.get("currentNodeId") != "node_b":
		print("FAIL bridge conflated the launched node with the parked position: %s" % [campaign])
		quit(1)
		return
	if campaign.get("mapLive") != false:
		print("FAIL bridge claimed a live map with no GameMap scene: %s" % [campaign])
		quit(1)
		return
	print("OK  bridge distinguishes the launched node from the parked position")

	bridge.queue_free()
	screen.queue_free()
	print("\nResults: 3 passed, 0 failed")
	quit(0)
