extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_main_menu.gd
# Covers MainMenu Continue resume wiring and load-failure UX.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const SaveManagerScript = preload("res://scripts/autoloads/SaveManager.gd")

const TEST_SAVE_DIR := "user://test_main_menu_continue"


func _init() -> void:
	print("=== MainMenu Test ===")
	var passed := 0
	var failed := 0
	_clean_test_dir()

	var save_manager: Node = SaveManagerScript.new()
	save_manager.name = "SaveManager"
	save_manager.configure_save_dir_for_tests(TEST_SAVE_DIR)
	root.add_child(save_manager)

	var gs_script := GDScript.new()
	gs_script.source_code = "extends Node\nvar configured := false\nvar configured_map_path := \"\"\nvar resumed_campaign_id := \"\"\nfunc configure_suspend_resume(source: Variant) -> bool:\n\tconfigured = true\n\tvar payload: Dictionary = source.to_dict() if source != null and source.has_method(\"to_dict\") else {}\n\tconfigured_map_path = String(payload.get(\"map_runtime\", {}).get(\"map_path\", \"\"))\n\treturn configured_map_path != \"\"\nfunc configure_campaign_resume(source: Variant) -> bool:\n\tvar payload: Dictionary = source.to_dict() if source != null and source.has_method(\"to_dict\") else {}\n\tresumed_campaign_id = String(payload.get(\"campaign\", {}).get(\"campaign_id\", \"\"))\n\treturn resumed_campaign_id != \"\"\n"
	gs_script.reload()
	var gs: Node = gs_script.new()
	gs.name = "GameState"
	root.add_child(gs)

	# CampaignManager owns the launch, so the slot route is only asked to reach it.
	var cm_script := GDScript.new()
	cm_script.source_code = "extends Node\nvar launched := false\nvar complete := false\nfunc is_campaign_complete() -> bool:\n\treturn complete\nfunc launch_current_node() -> bool:\n\tlaunched = true\n\treturn true\n"
	cm_script.reload()
	var cm: Node = cm_script.new()
	cm.name = "CampaignManager"
	root.add_child(cm)

	var packed := load("res://scenes/ui/MainMenu.tscn")
	if packed == null:
		print("FAIL could not load MainMenu.tscn")
		quit(1)
		return
	var menu: Control = packed.instantiate()
	root.add_child(menu)
	await process_frame

	var continue_btn: Button = menu.get_node("Panel/VBox/ContinueButton")
	if continue_btn.disabled:
		print("OK  Continue is disabled when no suspend save exists")
		passed += 1
	else:
		print("FAIL Continue enabled without a suspend save")
		failed += 1

	save_manager.save_suspend(_make_suspend_save())
	menu._refresh_continue_state()
	if not continue_btn.disabled:
		print("OK  Continue enables when a suspend save exists")
		passed += 1
	else:
		print("FAIL Continue stayed disabled after writing suspend save")
		failed += 1

	var loaded_ok: bool = menu._load_suspend_save(save_manager)
	if loaded_ok and bool(gs.get("configured")) \
			and String(gs.get("configured_map_path")) == "res://data/maps/map_001_rout/map_001_data.tres":
		print("OK  Continue stages suspend payload through GameState")
		passed += 1
	else:
		print("FAIL Continue stage: ok=%s configured=%s path=%s" % [
			loaded_ok, gs.get("configured"), gs.get("configured_map_path")])
		failed += 1

	gs.set("configured", false)
	_write_text(save_manager.get_suspend_path(), "{ not json")
	var failed_load_ok: bool = not menu._load_suspend_save(save_manager)
	if failed_load_ok and not bool(gs.get("configured")) and _consume_error_dialog(menu):
		print("OK  Continue load failure shows an error dialog and does not stage GameState")
		passed += 1
	else:
		print("FAIL Continue load failure: failed_ok=%s configured=%s" % [
			failed_load_ok, gs.get("configured")])
		failed += 1

	# --- Slice 3: Continue routes a campaign slot to the launch seam ------------
	save_manager.delete_suspend()
	save_manager.save_slot("autosave", _make_campaign_save())
	var target: Dictionary = save_manager.get_continue_target()
	if String(target.get("kind", "")) == "slot":
		print("OK  Continue targets the campaign slot when it is the only save")
		passed += 1
	else:
		print("FAIL Continue target with only a slot on disk: %s" % [target])
		failed += 1

	var slot_ok: bool = menu._load_campaign_slot(save_manager, "autosave")
	if slot_ok and String(gs.get("resumed_campaign_id")) == "proving_grounds" \
			and bool(cm.get("launched")):
		print("OK  Continue resumes a campaign slot and launches the parked node")
		passed += 1
	else:
		print("FAIL campaign slot resume: ok=%s campaign=%s launched=%s" % [
			slot_ok, gs.get("resumed_campaign_id"), cm.get("launched")])
		failed += 1

	# A finished campaign has no node to launch: say so, do not fail into a launch.
	cm.set("launched", false)
	cm.set("complete", true)
	var complete_ok: bool = not menu._load_campaign_slot(save_manager, "autosave")
	if complete_ok and not bool(cm.get("launched")) and _consume_error_dialog(menu):
		print("OK  Continue on a completed campaign reports it instead of launching")
		passed += 1
	else:
		print("FAIL completed campaign: refused=%s launched=%s" % [
			complete_ok, cm.get("launched")])
		failed += 1

	menu.queue_free()
	gs.queue_free()
	cm.queue_free()
	save_manager.queue_free()
	_clean_test_dir()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


# The failure UX is an AcceptDialog parented to the menu; consume it so the next
# case starts from a clean menu.
func _consume_error_dialog(menu: Control) -> bool:
	var saw_dialog := false
	for child in menu.get_children():
		if child is AcceptDialog and child.visible:
			saw_dialog = true
			child.queue_free()
	return saw_dialog


func _make_suspend_save() -> RefCounted:
	var save: RefCounted = SaveDataScript.new()
	save.map_runtime["map_id"] = "map_001"
	save.map_runtime["map_path"] = "res://data/maps/map_001_rout/map_001_data.tres"
	save.suspend["kind"] = "map"
	return SaveDataScript.from_dict(save.to_dict())


# A between-map campaign save: a position and a party, and no live map.
func _make_campaign_save() -> RefCounted:
	var save: RefCounted = SaveDataScript.new()
	save.save_label = "Autosave"
	save.campaign["campaign_id"] = "proving_grounds"
	save.campaign["node_id"] = "node_02_seize"
	save.campaign["cleared_nodes"] = ["node_01_rout"]
	save.roster["units"] = [{"unit_id": "lyn", "unit_name": "Lyn"}]
	return SaveDataScript.from_dict(save.to_dict())


func _clean_test_dir() -> void:
	var err := DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("test_main_menu: failed to create test dir: %s" % error_string(err))
		return
	var dir := DirAccess.open(TEST_SAVE_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		dir.remove(file_name)


func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("test_main_menu: failed to write test file: %s" \
			% error_string(FileAccess.get_open_error()))
		return
	file.store_string(text)
	file.close()
