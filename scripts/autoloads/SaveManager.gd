extends Node
# SaveManager owns disk I/O for save documents. SaveData stays pure and
# JSON-shaped; this service is the only place that knows user:// paths.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")

const DEFAULT_SAVE_DIR := "user://saves"
const SUSPEND_FILENAME := "suspend.json"
const INDEX_FILENAME := "saves_index.json"
const LAST_PLAYED_SUSPEND := "suspend"

var save_dir: String = DEFAULT_SAVE_DIR


func configure_save_dir_for_tests(path: String) -> void:
	save_dir = _strip_trailing_slashes(path)


func get_suspend_path() -> String:
	return _join_path(save_dir, SUSPEND_FILENAME)


func get_index_path() -> String:
	return _join_path(save_dir, INDEX_FILENAME)


func has_suspend() -> bool:
	return FileAccess.file_exists(get_suspend_path())


func has_continue_save() -> bool:
	var last_played := get_last_played()
	if String(last_played.get("kind", "")) == LAST_PLAYED_SUSPEND:
		return has_suspend()
	return has_suspend()


func save_suspend(source: Variant) -> bool:
	var save := _save_data_from_variant(source)
	if save == null:
		push_error("SaveManager: cannot save suspend from unsupported source")
		return false
	var errors: Array[String] = save.validate(_data_manager())
	if not errors.is_empty():
		_push_validation_errors("SaveManager: suspend save rejected", errors)
		return false
	if not _ensure_save_dir():
		return false
	var file := FileAccess.open(get_suspend_path(), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open suspend save for write: %s" \
			% error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(save.to_dict(), "\t", true))
	file.close()
	return _write_last_played(LAST_PLAYED_SUSPEND, get_suspend_path())


func load_suspend() -> RefCounted:
	if not has_suspend():
		return null
	var file := FileAccess.open(get_suspend_path(), FileAccess.READ)
	if file == null:
		push_error("SaveManager: failed to open suspend save for read: %s" \
			% error_string(FileAccess.get_open_error()))
		return null
	var text := file.get_as_text()
	file.close()
	var parsed := _parse_json_dict(text, get_suspend_path())
	if parsed.is_empty():
		return null
	var save: RefCounted = SaveDataScript.from_dict(parsed)
	var errors: Array[String] = save.validate(_data_manager())
	if not errors.is_empty():
		_push_validation_errors("SaveManager: suspend save failed validation", errors)
		return null
	return save


func delete_suspend() -> bool:
	var suspend_path := get_suspend_path()
	var removed := true
	if FileAccess.file_exists(suspend_path):
		var dir := DirAccess.open(save_dir)
		if dir == null:
			push_error("SaveManager: failed to open save dir for suspend delete")
			removed = false
		else:
			var err := dir.remove(SUSPEND_FILENAME)
			if err != OK:
				push_error("SaveManager: failed to delete suspend save: %s" % error_string(err))
				removed = false
	if removed:
		return _clear_last_played_suspend()
	return false


func get_last_played() -> Dictionary:
	var index := load_index()
	var last_played: Variant = index.get("last_played", {})
	return last_played if last_played is Dictionary else {}


func load_index() -> Dictionary:
	var path := get_index_path()
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: failed to open saves index: %s" \
			% error_string(FileAccess.get_open_error()))
		return {}
	var text := file.get_as_text()
	file.close()
	return _parse_json_dict(text, path)


func _save_data_from_variant(source: Variant) -> RefCounted:
	if source is Dictionary:
		return SaveDataScript.from_dict(source)
	if source is Object and source.has_method("to_dict"):
		return SaveDataScript.from_dict(source.call("to_dict"))
	return null


func _ensure_save_dir() -> bool:
	var err := DirAccess.make_dir_recursive_absolute(save_dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("SaveManager: failed to create save dir '%s': %s" \
			% [save_dir, error_string(err)])
		return false
	return true


func _write_last_played(kind: String, path: String) -> bool:
	var index := load_index()
	index["last_played"] = {
		"kind": kind,
		"path": path,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
	}
	return _write_index(index)


func _clear_last_played_suspend() -> bool:
	if not FileAccess.file_exists(get_index_path()):
		return true
	var index := load_index()
	var last_played: Variant = index.get("last_played", {})
	if last_played is Dictionary and String(last_played.get("kind", "")) == LAST_PLAYED_SUSPEND:
		index.erase("last_played")
		return _write_index(index)
	return true


func _write_index(index: Dictionary) -> bool:
	if not _ensure_save_dir():
		return false
	var file := FileAccess.open(get_index_path(), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open saves index for write: %s" \
			% error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(index, "\t", true))
	file.close()
	return true


func _parse_json_dict(text: String, path: String) -> Dictionary:
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("SaveManager: failed to parse JSON '%s' at line %d: %s" \
			% [path, json.get_error_line(), json.get_error_message()])
		return {}
	var data: Variant = json.data
	if not (data is Dictionary):
		push_error("SaveManager: expected JSON object in '%s'" % path)
		return {}
	return data


func _data_manager() -> Object:
	if is_inside_tree():
		return get_node_or_null("/root/DataManager")
	return null


func _push_validation_errors(prefix: String, errors: Array[String]) -> void:
	for err in errors:
		push_error("%s: %s" % [prefix, err])


func _join_path(base: String, file_name: String) -> String:
	return "%s/%s" % [_strip_trailing_slashes(base), file_name]


func _strip_trailing_slashes(path: String) -> String:
	var out := path
	while out.ends_with("/") and out.length() > 0:
		out = out.substr(0, out.length() - 1)
	return out
