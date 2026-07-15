extends SceneTree
# B4-PREP-DEPLOYMENT integration: prep builds a legal explicit plan, lets the
# player bench/reorder units, and rejects unsafe manual slot ids.

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

	screen._slot_id.text = "../escape"
	screen._save_label.text = "Unsafe"
	screen._on_save()
	_check(
		screen._save_status.text.begins_with("Save failed") and sm.list_slots().is_empty(),
		"an unsafe player-supplied slot id writes nothing"
	)

	screen._slot_id.text = "before_chapter_1"
	screen._save_label.text = "Before Chapter 1"
	screen._on_save()
	_check(
		screen._save_status.text == "Saved." and sm.list_slots().size() == 1,
		"a valid manual prep save appears in the slot index"
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
