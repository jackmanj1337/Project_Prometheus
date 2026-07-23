extends SceneTree

const RulesS = preload("res://scripts/resources/CampaignRules.gd")
const SaveDataS = preload("res://scripts/save/SaveData.gd")

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Battle Result Actions Test ===")
	var rules := RulesS.make_default()
	_check(
		rules.allows_battle_result_action("victory", "save"), "default policy keeps Save visible"
	)
	rules.battle_result_actions["defeat"]["retry"] = false
	_check(
		not rules.allows_battle_result_action("defeat", "retry"),
		"campaign policy can hide defeat Retry"
	)
	_check(
		rules.allows_battle_result_action("victory", "future_action"),
		"unknown future action defaults visible"
	)

	var normalized := SaveDataS.from_dict(
		{"campaign": {"rules": {"battle_result_actions": rules.battle_result_actions}}}
	)
	_check(
		not bool(normalized.campaign["rules"]["battle_result_actions"]["defeat"]["retry"]),
		"action policy survives save normalization",
	)

	var gs := root.get_node_or_null("GameState")
	var old_actions: Dictionary = gs.campaign_rules.battle_result_actions.duplicate(true)
	var old_charges: int = gs.rewind_charges_left
	gs.campaign_rules.battle_result_actions = rules.battle_result_actions.duplicate(true)
	gs.rewind_charges_left = 0
	var defeat: Control = load("res://scenes/ui/GameOverScreen.tscn").instantiate()
	root.add_child(defeat)
	defeat._refresh_defeat_actions()
	_check(not defeat.get_node("Panel/VBox/RetryButton").visible, "defeat policy hides Retry")
	_check(
		not defeat.get_node("Panel/VBox/RewindButton").visible,
		"zero available charges hide defeat Rewind"
	)
	defeat.queue_free()
	gs.campaign_rules.battle_result_actions = old_actions
	gs.rewind_charges_left = old_charges

	var rewind: Control = load("res://scenes/ui/RewindSelector.tscn").instantiate()
	root.add_child(rewind)
	var first_options: Array[Dictionary] = [{"label": "First", "target_index": 0, "cost": 1}]
	var replacement_options: Array[Dictionary] = [
		{"label": "Replacement", "target_index": 1, "cost": 1}
	]
	rewind.open(first_options)
	await process_frame
	rewind._close()
	rewind.open(replacement_options)
	await process_frame
	var choices: VBoxContainer = rewind.get_node("Panel/VBox/Scroll/Choices")
	var focused := root.gui_get_focus_owner()
	_check(
		choices.get_child_count() == 1 and focused != null and choices.is_ancestor_of(focused),
		"Rewind reopen focuses a live replacement button",
	)
	rewind.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK  " + label)
		passed += 1
	else:
		print("FAIL " + label)
		failed += 1
