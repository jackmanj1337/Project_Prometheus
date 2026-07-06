extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_save_manager.gd
# B1-CST / B1-SUSPEND: disk I/O seam for active-map suspend saves.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const SaveManagerScript = preload("res://scripts/autoloads/SaveManager.gd")

const TEST_SAVE_DIR := "user://test_save_manager"


func _init() -> void:
	print("=== SaveManager Test ===")
	var passed := 0
	var failed := 0
	_clean_test_dir()

	var manager: Node = SaveManagerScript.new()
	manager.configure_save_dir_for_tests(TEST_SAVE_DIR)

	var suspend_save: RefCounted = _make_suspend_save()
	var write_ok: bool = manager.save_suspend(suspend_save)
	var file_exists: bool = FileAccess.file_exists(manager.get_suspend_path())
	var index: Dictionary = manager.load_index()
	var last_played: Dictionary = manager.get_last_played()
	if write_ok and file_exists \
			and String(last_played.get("kind", "")) == "suspend" \
			and String(last_played.get("path", "")) == manager.get_suspend_path() \
			and index.has("last_played"):
		print("OK  save_suspend_writes_file_and_continue_pointer")
		passed += 1
	else:
		print("FAIL suspend write/index: write=%s file=%s index=%s last=%s" % [
			write_ok, file_exists, index, last_played])
		failed += 1

	var loaded: RefCounted = manager.load_suspend()
	if loaded != null \
			and loaded.map_runtime["map_id"] == "map_001" \
			and loaded.map_runtime["map_path"] == "res://data/maps/map_001_rout/map_001_data.tres" \
			and loaded.map_runtime["rng"] == {"map_seed": "123", "history_hash": "456"} \
			and loaded.suspend["kind"] == "map":
		print("OK  load_suspend_roundtrips_saved_SaveData")
		passed += 1
	else:
		print("FAIL suspend load: %s" % [loaded.to_dict() if loaded != null else null])
		failed += 1

	if manager.has_continue_save():
		print("OK  has_continue_save_tracks_suspend_slot")
		passed += 1
	else:
		print("FAIL continue availability false after save")
		failed += 1

	if manager.delete_suspend() \
			and not FileAccess.file_exists(manager.get_suspend_path()) \
			and manager.get_last_played().is_empty():
		print("OK  delete_suspend_removes_file_and_continue_pointer")
		passed += 1
	else:
		print("FAIL suspend delete: file=%s last=%s" % [
			FileAccess.file_exists(manager.get_suspend_path()), manager.get_last_played()])
		failed += 1

	_write_text(manager.get_suspend_path(), "{ not json")
	if manager.load_suspend() == null:
		print("OK  load_suspend_rejects_invalid_json")
		passed += 1
	else:
		print("FAIL invalid JSON loaded")
		failed += 1

	_write_text(manager.get_suspend_path(), JSON.stringify({"format_version": 99}, "\t", true))
	if manager.load_suspend() == null:
		print("OK  load_suspend_rejects_unsupported_version")
		passed += 1
	else:
		print("FAIL unsupported save version loaded")
		failed += 1

	manager.free()
	_clean_test_dir()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _make_suspend_save() -> RefCounted:
	var save: RefCounted = SaveDataScript.new()
	save.save_label = "Suspend test"
	save.campaign["campaign_id"] = "demo"
	save.campaign["node_id"] = "map_001"
	save.party["resources"]["party_gold"] = 50
	save.map_runtime["map_id"] = "map_001"
	save.map_runtime["map_path"] = "res://data/maps/map_001_rout/map_001_data.tres"
	save.map_runtime["rng"] = {"map_seed": 123, "history_hash": 456}
	save.suspend["kind"] = "map"
	return SaveDataScript.from_dict(save.to_dict())


func _clean_test_dir() -> void:
	var err := DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("test_save_manager: failed to create test dir: %s" % error_string(err))
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
		push_error("test_save_manager: failed to write test file: %s" \
			% error_string(FileAccess.get_open_error()))
		return
	file.store_string(text)
	file.close()
