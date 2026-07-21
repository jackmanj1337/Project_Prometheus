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
			sm.list_slots().size() == 1
			and String(sm.list_slots()[0].get("slot_id", "")) != first_slot_id
		),
		"confirming overwrite replaces exactly one same-label slot with a fresh id"
	)

	_clean_test_dir()
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


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
