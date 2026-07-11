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
	gs_script.source_code = "extends Node\nvar configured := false\nvar configured_map_path := \"\"\nfunc configure_suspend_resume(source: Variant) -> bool:\n\tconfigured = true\n\tvar payload: Dictionary = source.to_dict() if source != null and source.has_method(\"to_dict\") else {}\n\tconfigured_map_path = String(payload.get(\"map_runtime\", {}).get(\"map_path\", \"\"))\n\treturn configured_map_path != \"\"\n"
	gs_script.reload()
	var gs: Node = gs_script.new()
	gs.name = "GameState"
	root.add_child(gs)

	var packed := load("res://scenes/ui/MainMenu.tscn")
	if packed == null:
		print("FAIL could not load MainMenu.tscn")
		quit(1)
		return
	var menu: Control = packed.instantiate()
	root.add_child(menu)
	await process_frame

	# V027-05a: MainMenu is exempt from the shared Menu Scale setting — it
	# always fills the space between the title and version label instead
	# (a "pinned-large home screen"), and must never overlap either.
	var panel: Control = menu.get_node("Panel")
	var title: Control = menu.get_node("TitleLabel")
	var version: Control = menu.get_node("VersionLabel")
	var size_before_slider_call: Vector2 = panel.size
	menu.call("apply_menu_scale", 2.0)  # simulates a Menu Scale slider push
	await process_frame
	if panel.size.is_equal_approx(size_before_slider_call):
		print("OK  Panel ignores the Menu Scale slider factor (V027-05a exemption)")
		passed += 1
	else:
		print("FAIL Panel changed size on apply_menu_scale(2.0): before=%s after=%s" % [
			size_before_slider_call, panel.size])
		failed += 1
	if not panel.get_rect().intersects(title.get_rect()) \
			and not panel.get_rect().intersects(version.get_rect()):
		print("OK  Panel does not overlap TitleLabel or VersionLabel (V030-REG-01)")
		passed += 1
	else:
		print("FAIL Panel overlaps a sibling label: panel=%s title=%s version=%s" % [
			panel.get_rect(), title.get_rect(), version.get_rect()])
		failed += 1
	if panel.size.y > 210.0:  # old fixed authored height was 210px (300..510)
		print("OK  Panel grew beyond its old fixed authored size to fill available space")
		passed += 1
	else:
		print("FAIL Panel did not grow beyond its old fixed size: size=%s" % [panel.size])
		failed += 1

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

	var loaded_ok: bool = menu._load_continue_save()
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
	var failed_load_ok: bool = not menu._load_continue_save()
	var saw_error_dialog := false
	for child in menu.get_children():
		if child is AcceptDialog and child.visible:
			saw_error_dialog = true
			child.queue_free()
	if failed_load_ok and not bool(gs.get("configured")) and saw_error_dialog:
		print("OK  Continue load failure shows an error dialog and does not stage GameState")
		passed += 1
	else:
		print("FAIL Continue load failure: failed_ok=%s configured=%s dialog=%s" % [
			failed_load_ok, gs.get("configured"), saw_error_dialog])
		failed += 1

	menu.queue_free()
	gs.queue_free()
	save_manager.queue_free()
	_clean_test_dir()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _make_suspend_save() -> RefCounted:
	var save: RefCounted = SaveDataScript.new()
	save.map_runtime["map_id"] = "map_001"
	save.map_runtime["map_path"] = "res://data/maps/map_001_rout/map_001_data.tres"
	save.suspend["kind"] = "map"
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
