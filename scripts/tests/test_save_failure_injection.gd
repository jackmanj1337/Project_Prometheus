extends SceneTree

# SaveManager's index replacement is the commit marker. A fault after the slot
# swap must restore the exact old slot/index bytes and leave no staging debris.
const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const SaveManagerScript = preload("res://scripts/autoloads/SaveManager.gd")

const TEST_DIR := "user://test_save_failure_injection"


func _init() -> void:
	print("=== Save Failure Injection Test ===")
	_clean_dir()
	var manager: Node = SaveManagerScript.new()
	manager.configure_save_dir_for_tests(TEST_DIR)

	var initial_ok: bool = manager.save_slot("atomic", _save("Before"))
	var slot_path: String = manager.get_slot_path("atomic")
	var old_slot := FileAccess.get_file_as_bytes(slot_path)
	var old_index := FileAccess.get_file_as_bytes(manager.get_index_path())

	manager._test_fail_before_index_replace = true
	var replacement_ok: bool = manager.save_slot("atomic", _save("After"))
	manager._test_fail_before_index_replace = false

	var leftovers: Array[String] = []
	for file_name in DirAccess.open(TEST_DIR).get_files():
		if file_name.ends_with(".tmp") or file_name.ends_with(".bak"):
			leftovers.append(file_name)
	var rollback_ok := (
		initial_ok
		and not replacement_ok
		and FileAccess.get_file_as_bytes(slot_path) == old_slot
		and FileAccess.get_file_as_bytes(manager.get_index_path()) == old_index
		and leftovers.is_empty()
	)
	if rollback_ok:
		print("OK  injected index failure preserves exact committed bytes and cleans staging")
	else:
		print("FAIL transaction rollback: leftovers=%s" % [leftovers])

	manager.free()
	_clean_dir()
	print(
		"=== Results: %d passed, %d failed ===" % [1 if rollback_ok else 0, 0 if rollback_ok else 1]
	)
	quit(0 if rollback_ok else 1)


func _save(label: String) -> RefCounted:
	var save: RefCounted = SaveDataScript.new()
	save.save_label = label
	save.campaign["campaign_id"] = "proving_grounds"
	save.campaign["node_id"] = "node_01_rout"
	return SaveDataScript.from_dict(save.to_dict())


func _clean_dir() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var directory := DirAccess.open(TEST_DIR)
	if directory == null:
		return
	for file_name in directory.get_files():
		directory.remove(file_name)
