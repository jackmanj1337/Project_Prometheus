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

	# [EPUX-07] / [RPD-15] on the fifth availability surface. A gated entry must stay
	# in the focus order AND carry a reason; the overworld is a plain VBox, so native
	# traversal supplies the first half and these assertions pin the second.
	var node_buttons: Array[Node] = screen.get_node("Margin/VBox/Canvas/Nodes").get_children()
	var gated: Button = null
	for button in node_buttons:
		if (button as Button).disabled:
			gated = button
			break
	_check(gated != null, "the fixture projects at least one gated entry to reason about")
	_check(
		gated != null and gated.focus_mode != Control.FOCUS_NONE,
		"a gated overworld entry stays focusable so its reason is reachable"
	)
	_check(
		gated != null and gated.tooltip_text != "",
		"a gated overworld entry carries an unmet reason, not a bare disabled state"
	)
	if gated != null:
		gated.grab_focus()
		await process_frame
		# Both halves matter: an empty status matching an empty tooltip would pass a
		# bare equality check while announcing nothing at all.
		var announced := String(screen.get_node("Margin/VBox/Status").text)
		_check(
			gated.has_focus() and announced != "" and announced == gated.tooltip_text,
			"focusing a gated entry announces its reason without a pointer"
		)

	# Entry focus prefers available and falls back to a gated entry only when every
	# entry is gated -- a fully gated surface must never become unreachable.
	cm.cleared_node_ids = []
	cm.current_node_id = ""
	screen._rebuild()
	await process_frame
	var all_gated: Array[Node] = screen.get_node("Margin/VBox/Canvas/Nodes").get_children()
	var any_focused := false
	for button in all_gated:
		if (button as Button).has_focus():
			any_focused = true
			break
	_check(
		not all_gated.is_empty() and any_focused,
		"a fully gated overworld still takes entry focus instead of stranding the player"
	)
	cm.cleared_node_ids = ["node_01_rout"]
	cm.current_node_id = "node_02_seize"

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
