extends SceneTree
# B4-PREP-DEPLOYMENT integration: prep builds a legal explicit plan, lets the
# player bench/reorder units, and writes safe context-derived manual saves.

const SaveManagerScript = preload("res://scripts/autoloads/SaveManager.gd")
const TEST_SAVE_DIR := "user://test_prep_screen"

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Prep Screen Test ===")
	_clean_test_dir()
	var registry: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	registry.name = "RegistryManager"
	root.add_child(registry)
	var dm: Node = load("res://scripts/autoloads/DataManager.gd").new()
	dm.name = "DataManager"
	root.add_child(dm)
	var cm: Node = load("res://scripts/autoloads/CampaignManager.gd").new()
	cm.name = "CampaignManager"
	root.add_child(cm)
	var gs: Node = load("res://scripts/autoloads/GameState.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	var sm := SaveManagerScript.new()
	sm.name = "SaveManager"
	sm.configure_save_dir_for_tests(TEST_SAVE_DIR)
	root.add_child(sm)
	await process_frame

	cm.start_campaign("proving_grounds")
	var params: Dictionary = cm.resolve_launch_params(cm.get_current_node())
	gs.configure_next_map(params["map_data_path"], params["roster_policy"], params["roster_source"])
	gs.load_default_roster()
	cm._active_node_id = cm.current_node_id

	var screen: Node = load("res://scenes/ui/PrepScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var plan: Dictionary = screen.build_plan()
	_check(
		not plan.is_empty() and screen.validation_errors().is_empty(),
		"prep seeds a legal explicit deployment"
	)
	_check(
		not screen.get_node("Margin/VBox/Actions/ReturnButton").visible,
		"ordinary linear prep does not offer a misleading campaign-map return"
	)
	_check(
		(
			screen.get_node("Margin/VBox/RulesSummary").text.begins_with("Rules (read only):")
			and screen.get_node("Margin/VBox/RulesSummary").text.contains("Pair Up Enabled")
			and screen.get_node("Margin/VBox/RulesSummary").text.contains("Rewind Charges Per Map")
		),
		"prep presents the entire effective campaign ruleset as a read-only summary"
	)

	var first_id := String(screen._selected_ids[0])
	var first_tile: Vector2i = plan[first_id]
	screen._move_unit(first_id, 1)
	var moved_plan: Dictionary = screen.build_plan()
	_check(
		moved_plan[first_id] != first_tile and screen.validation_errors().is_empty(),
		"moving a unit changes its start tile without invalidating the plan"
	)

	screen._on_unit_toggled(false, first_id)
	_check(
		not screen.build_plan().has(first_id) and screen.validation_errors().is_empty(),
		"an optional unit can be benched"
	)

	var generated_id: String = screen._next_manual_slot_id(123456)
	_check(
		SaveManagerScript.is_valid_slot_id(generated_id) and generated_id.contains("-prep-123456"),
		"manual save ids are filename-safe and derived from chapter/activity/time"
	)

	screen._on_save()
	_check(
		(
			screen._save_status.text == "Saved."
			and sm.list_slots().size() == 1
			and String(sm.list_slots()[0].get("label", "")).ends_with("— Prep")
		),
		"a context-labelled manual prep save appears in the slot index"
	)

	var first_slot_id := String(sm.list_slots()[0].get("slot_id", ""))
	screen._on_save()
	_check(
		sm.list_slots().size() == 1 and screen._overwrite_confirm.visible,
		"same-label save asks before replacing the existing slot"
	)
	screen._overwrite_confirm.hide()  # cancel: no confirmed signal, so no write
	_check(
		(
			sm.list_slots().size() == 1
			and String(sm.list_slots()[0].get("slot_id", "")) == first_slot_id
		),
		"cancelling overwrite leaves the existing save untouched"
	)
	screen._on_save()
	screen._on_overwrite_confirmed()
	_check(
		(
			screen._save_status.text == "Saved."
			and sm.list_slots().size() == 1
			and String(sm.list_slots()[0].get("slot_id", "")) == first_slot_id
		),
		"confirming overwrite reuses the same slot id in place (V053-04: atomic, cap-safe)"
	)

	_check_replace_survives_full_class(cm, gs, sm, screen)
	await _check_cleared_revisit_return(cm, screen)

	_clean_test_dir()
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check_cleared_revisit_return(cm: Node, old_screen: Node) -> void:
	old_screen.queue_free()
	await process_frame
	var campaign: CampaignData = cm.get_active_campaign()
	campaign.traversal_mode = "free_roam"
	cm.current_node_id = "node_02_seize"
	cm._revisiting_node_id = ""
	cm.set_next_prep_navigation_origin("campaign_map")
	var fresh_screen: Node = load("res://scenes/ui/PrepScreen.tscn").instantiate()
	root.add_child(fresh_screen)
	await process_frame
	_check(
		(fresh_screen.get_node("Margin/VBox/Actions/ReturnButton") as Button).visible,
		"a fresh free-roam node entered from the campaign map exposes Return"
	)
	fresh_screen.queue_free()
	await process_frame
	var cleared: Array[String] = ["node_01_rout"]
	cm.cleared_node_ids = cleared
	cm._active_node_id = "node_01_rout"
	cm._revisiting_node_id = "node_01_rout"
	cm.set_next_prep_navigation_origin("campaign_map")
	var revisit_screen: Node = load("res://scenes/ui/PrepScreen.tscn").instantiate()
	root.add_child(revisit_screen)
	await process_frame
	var return_button: Button = revisit_screen.get_node("Margin/VBox/Actions/ReturnButton")
	_check(
		return_button.visible and return_button.text == "Return to Campaign Map",
		"a cleared-node revisit exposes the player-facing return action"
	)
	return_button.pressed.emit()
	_check(
		(
			cm.current_node_id == "node_02_seize"
			and cm.cleared_node_ids == ["node_01_rout"]
			and not cm.is_revisiting_current_hub()
		),
		"the Prep return action preserves progression while leaving the revisited hub"
	)


# V053-04: the manual between_map budget is a per-campaign cap of 3. Replace must
# survive a full class (it overwrites in place), a brand-new save at the cap must
# be refused with a readable diagnostic, and the count must be scoped per-campaign.
func _check_replace_survives_full_class(cm: Node, gs: Node, sm: Node, screen: Node) -> void:
	for row in sm.list_slots():
		sm.delete_slot(String(row.get("slot_id", "")))
	# Fill the class to the classic-GBA cap of 3 for the active campaign
	# (proving_grounds), with labels that do NOT match the prep node label.
	cm.write_campaign_slot("fill-a", "Fill A")
	cm.write_campaign_slot("fill-b", "Fill B")
	cm.write_campaign_slot("fill-c", "Fill C")
	var budget: Dictionary = sm.manual_slot_budget("between_map")
	_check(
		int(budget.get("cap", 0)) == 3 and bool(budget.get("full", false)),
		"between_map class reports full at the per-campaign cap of 3"
	)
	# A brand-new prep save at the cap opens the in-context replacement picker.
	screen._on_save()
	var picker := screen._overwrite_confirm.get_node("ManualSaveReplacementOptions") as OptionButton
	_check(
		(
			sm.list_slots().size() == 3
			and screen._overwrite_confirm.visible
			and picker.item_count == 3
		),
		"a full prep pool offers all eligible manual slots in context"
	)
	var before_cancel: Array = sm.list_slots()
	screen._overwrite_confirm.hide()
	_check(sm.list_slots() == before_cancel, "canceling replacement changes no save")
	screen._on_save()
	screen._on_overwrite_confirmed()
	_check(sm.list_slots().size() == 3, "confirming replacement atomically reuses one slot")
	# Replace of an existing same-label slot still succeeds at the cap (in place).
	sm.delete_slot("fill-c")
	cm.write_campaign_slot("node-label-slot", screen._manual_save_label())
	screen._on_save()  # same-label match -> overwrite prompt
	screen._on_overwrite_confirmed()
	_check(
		screen._save_status.text == "Saved." and sm.list_slots().size() == 3,
		"Replace at the cap overwrites in place and never trips the full-class refusal"
	)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1


func _clean_test_dir() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	var dir := DirAccess.open(TEST_SAVE_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		dir.remove(file_name)
