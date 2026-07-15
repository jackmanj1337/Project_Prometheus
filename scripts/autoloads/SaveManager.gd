extends Node
# SaveManager owns disk I/O for save documents. SaveData stays pure and
# JSON-shaped; this service is the only place that knows user:// paths.
#
# Two kinds of document live here, and they are NOT interchangeable:
# - the SUSPEND save (one file): a mid-map save, carrying map_runtime + suspend.
# - campaign SLOTS (autosave + manual): a BETWEEN-map save, parked on a campaign
#   node with no live map. Slice 3 (B1-CST) added these.
# The saves index records which was written last, so Continue can route to the
# right one.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")

const DEFAULT_SAVE_DIR := "user://saves"
const SUSPEND_FILENAME := "suspend.json"
const INDEX_FILENAME := "saves_index.json"
const LAST_PLAYED_SUSPEND := "suspend"
const LAST_PLAYED_SLOT := "slot"

# The campaign autosave is a reserved slot id, written by the campaign flow after
# a node is committed. Manual slots are any other valid id.
const AUTOSAVE_SLOT := "autosave"

var save_dir: String = DEFAULT_SAVE_DIR

# Failure seam used only by the disk-transaction regression suite.
var _test_fail_before_index_replace := false


func configure_save_dir_for_tests(path: String) -> void:
	save_dir = _strip_trailing_slashes(path)


func get_suspend_path() -> String:
	return _join_path(save_dir, SUSPEND_FILENAME)


func get_index_path() -> String:
	return _join_path(save_dir, INDEX_FILENAME)


func has_suspend() -> bool:
	return FileAccess.file_exists(get_suspend_path())


# --- Continue routing ---------------------------------------------------------

# What Continue would resume: the most recently written document. Empty when
# there is nothing to continue. The caller routes on "kind" — a suspend resumes
# into the live map, a slot resumes into the campaign at its parked node.
func get_continue_target() -> Dictionary:
	var last_played := get_last_played()
	var kind: String = String(last_played.get("kind", ""))
	match kind:
		LAST_PLAYED_SUSPEND:
			if has_suspend():
				return {"kind": LAST_PLAYED_SUSPEND, "slot_id": ""}
		LAST_PLAYED_SLOT:
			var slot_id: String = String(last_played.get("slot_id", ""))
			if has_slot(slot_id) and _is_slot_resumable(slot_id):
				return {"kind": LAST_PLAYED_SLOT, "slot_id": slot_id}
	# The pointer is missing or names a document that is gone (deleted by hand, or
	# a failed write). Fall back to whatever is actually on disk rather than
	# refusing to continue a save the player can plainly see.
	if has_suspend():
		return {"kind": LAST_PLAYED_SUSPEND, "slot_id": ""}
	for row in list_slots():
		if _row_is_resumable(row):
			return {"kind": LAST_PLAYED_SLOT, "slot_id": String(row.get("slot_id", ""))}
	return {}


func has_continue_save() -> bool:
	return not get_continue_target().is_empty()


# --- Suspend save (mid-map) ---------------------------------------------------

func save_suspend(source: Variant) -> bool:
	if not _write_save_document(get_suspend_path(), source, "suspend save"):
		return false
	return _write_last_played(LAST_PLAYED_SUSPEND, get_suspend_path(), "")


func load_suspend() -> RefCounted:
	if not has_suspend():
		return null
	return _read_save_document(get_suspend_path(), "suspend save")


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


# --- Campaign slots (between-map) ---------------------------------------------

# Slot ids become filenames, so the charset is allow-listed rather than sanitized:
# a manual slot id will eventually be player-supplied, and no id may resolve to a
# path outside the save dir (".." and "/" are simply not in the alphabet).
const _SLOT_ID_CHARS := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"

static func is_valid_slot_id(slot_id: String) -> bool:
	if slot_id == "" or slot_id.length() > 64:
		return false
	for i in slot_id.length():
		if not _SLOT_ID_CHARS.contains(slot_id[i]):
			return false
	return true


func get_slot_path(slot_id: String) -> String:
	if not is_valid_slot_id(slot_id):
		return ""
	return _join_path(save_dir, "%s.json" % slot_id)


func has_slot(slot_id: String) -> bool:
	var path := get_slot_path(slot_id)
	return path != "" and FileAccess.file_exists(path)


func save_slot(slot_id: String, source: Variant) -> bool:
	var path := get_slot_path(slot_id)
	if path == "":
		push_error("SaveManager: invalid slot id '%s'" % slot_id)
		return false
	var save := _save_data_from_variant(source)
	if save == null:
		return false
	var errors: Array[String] = save.validate(_data_manager())
	if not errors.is_empty():
		_push_validation_errors("SaveManager: slot '%s' rejected" % slot_id, errors)
		return false
	var payload: Dictionary = save.to_dict()
	var index := load_index()
	var slots: Dictionary = _slots_from_index(index)
	slots[slot_id] = _slot_index_row(path, payload, index)
	index["slots"] = slots
	index["last_played"] = {
		"kind": LAST_PLAYED_SLOT, "path": path, "slot_id": slot_id,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
	}
	return _commit_slot_transaction(path, payload, index)


func load_slot(slot_id: String) -> RefCounted:
	if not has_slot(slot_id):
		return null
	return _read_save_document(get_slot_path(slot_id), "slot '%s'" % slot_id)


func delete_slot(slot_id: String) -> bool:
	var path := get_slot_path(slot_id)
	if path == "":
		push_error("SaveManager: invalid slot id '%s'" % slot_id)
		return false
	if FileAccess.file_exists(path):
		var dir := DirAccess.open(save_dir)
		if dir == null:
			push_error("SaveManager: failed to open save dir for slot delete")
			return false
		var err := dir.remove("%s.json" % slot_id)
		if err != OK:
			push_error("SaveManager: failed to delete slot '%s': %s" % [slot_id, error_string(err)])
			return false
	return _forget_slot(slot_id)


# Slot rows for the load picker, newest first. Rows are read from the index, but
# an index row whose file has gone missing is skipped — the picker must never
# offer a save that cannot be loaded.
func list_slots() -> Array[Dictionary]:
	var slots: Dictionary = _slots_from_index(load_index())
	var rows: Array[Dictionary] = []
	for slot_id in slots:
		if not has_slot(String(slot_id)):
			continue
		var row: Dictionary = slots[slot_id].duplicate(true) if slots[slot_id] is Dictionary else {}
		row["slot_id"] = String(slot_id)
		rows.append(row)
	# write_seq is the ordering key (see _write_slot_index_entry); the timestamp is
	# only the tiebreak for rows written before the counter existed.
	rows.sort_custom(func(a, b):
		var seq_a: int = int(a.get("write_seq", 0))
		var seq_b: int = int(b.get("write_seq", 0))
		if seq_a != seq_b:
			return seq_a > seq_b
		return int(a.get("saved_at_unix", 0)) > int(b.get("saved_at_unix", 0)))
	return rows


func get_last_played() -> Dictionary:
	var index := load_index()
	var last_played: Variant = index.get("last_played", {})
	return last_played if last_played is Dictionary else {}


func _is_slot_resumable(slot_id: String) -> bool:
	for row in list_slots():
		if String(row.get("slot_id", "")) == slot_id:
			return _row_is_resumable(row)
	return false


static func _row_is_resumable(row: Dictionary) -> bool:
	var header: Variant = row.get("header", {})
	return header is Dictionary and String(header.get("campaign_state", "in_progress")) \
		!= "completed"


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


# Every save document takes the same path onto disk: coerce to SaveData, validate,
# then write. A document that fails validation is never written — a rejected save
# must leave the previous one intact rather than truncating it to a bad state.
func _write_save_document(path: String, source: Variant, label: String) -> bool:
	var save := _save_data_from_variant(source)
	if save == null:
		push_error("SaveManager: cannot write %s from unsupported source" % label)
		return false
	var errors: Array[String] = save.validate(_data_manager())
	if not errors.is_empty():
		_push_validation_errors("SaveManager: %s rejected" % label, errors)
		return false
	if not _ensure_save_dir():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open %s for write: %s" \
			% [label, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(save.to_dict(), "\t", true))
	file.close()
	return true


# The mirror of _write_save_document. Null on anything that is not a loadable
# document — unparseable JSON, or a payload that fails validation.
func _read_save_document(path: String, label: String) -> RefCounted:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: failed to open %s for read: %s" \
			% [label, error_string(FileAccess.get_open_error())])
		return null
	var text := file.get_as_text()
	file.close()
	var parsed := _parse_json_dict(text, path)
	if parsed.is_empty():
		return null
	var save: RefCounted = SaveDataScript.from_dict(parsed)
	var errors: Array[String] = save.validate(_data_manager())
	if not errors.is_empty():
		_push_validation_errors("SaveManager: %s failed validation" % label, errors)
		return null
	return save


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


func _write_last_played(kind: String, path: String, slot_id: String) -> bool:
	var index := load_index()
	index["last_played"] = {
		"kind": kind,
		"path": path,
		"slot_id": slot_id,  # "" for the suspend save, which has no slot
		"saved_at_unix": int(Time.get_unix_time_from_system()),
	}
	return _write_index(index)


# The slot's picker row. The header is mirrored out of the save document so the
# load menu can list slots without opening (and validating) every save file.
#
# write_seq orders the rows, not saved_at_unix: the timestamp has whole-second
# resolution, so two saves written in the same second tie and "newest first"
# becomes arbitrary — including for the Continue fallback, which takes the first
# row. The counter is monotonic per save dir, so writes always order by when they
# actually happened. The timestamp stays for display.
func _write_slot_index_entry(slot_id: String, path: String, source: Variant) -> bool:
	var save := _save_data_from_variant(source)
	if save == null:
		return false
	var payload: Dictionary = save.to_dict()
	var index := load_index()
	var slots: Dictionary = _slots_from_index(index)
	slots[slot_id] = _slot_index_row(path, payload, index)
	index["slots"] = slots
	return _write_index(index)


func _slot_index_row(path: String, payload: Dictionary, index: Dictionary) -> Dictionary:
	return {
		"path": path,
		"label": String(payload.get("save_label", "")),
		"header": payload.get("header", {}),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"write_seq": _next_write_seq(index),
	}


# Slot and index are staged together. The index is the commit marker; if its
# replacement fails after the slot swap, the prior slot is restored before false
# is returned, so readers observe the old pair or the new pair.
func _commit_slot_transaction(slot_path: String, payload: Dictionary, index: Dictionary) -> bool:
	if not _ensure_save_dir():
		return false
	var slot_tmp := "%s.tmp" % slot_path
	var index_path := get_index_path()
	var index_tmp := "%s.tmp" % index_path
	_cleanup_paths([slot_tmp, index_tmp])
	if not _write_json_file(slot_tmp, payload) or not _write_json_file(index_tmp, index):
		_cleanup_paths([slot_tmp, index_tmp])
		return false
	var slot_backup := "%s.bak" % slot_path
	var index_backup := "%s.bak" % index_path
	_cleanup_paths([slot_backup, index_backup])
	if not _replace_staged(slot_tmp, slot_path, slot_backup):
		_cleanup_paths([slot_tmp, index_tmp, slot_backup])
		return false
	if _test_fail_before_index_replace \
			or not _replace_staged(index_tmp, index_path, index_backup):
		_restore_backup(slot_path, slot_backup)
		_cleanup_paths([slot_tmp, index_tmp, slot_backup, index_backup])
		return false
	_cleanup_paths([slot_backup, index_backup])
	return true


func _write_json_file(path: String, value: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(value, "\t", true))
	file.flush()
	file.close()
	return true


func _replace_staged(staged_path: String, destination_path: String, backup_path: String) -> bool:
	var dir := DirAccess.open(save_dir)
	if dir == null:
		return false
	var destination := destination_path.get_file()
	var staged := staged_path.get_file()
	var backup := backup_path.get_file()
	if FileAccess.file_exists(destination_path) and dir.rename(destination, backup) != OK:
		return false
	if dir.rename(staged, destination) == OK:
		return true
	if FileAccess.file_exists(backup_path):
		dir.rename(backup, destination)
	return false


func _restore_backup(destination_path: String, backup_path: String) -> void:
	var dir := DirAccess.open(save_dir)
	if dir == null:
		return
	if FileAccess.file_exists(destination_path):
		dir.remove(destination_path.get_file())
	if FileAccess.file_exists(backup_path):
		dir.rename(backup_path.get_file(), destination_path.get_file())


func _cleanup_paths(paths: Array) -> void:
	var dir := DirAccess.open(save_dir)
	if dir == null:
		return
	for path in paths:
		if FileAccess.file_exists(String(path)):
			dir.remove(String(path).get_file())


func _next_write_seq(index: Dictionary) -> int:
	var seq: int = int(index.get("write_seq", 0)) + 1
	index["write_seq"] = seq
	return seq


func _forget_slot(slot_id: String) -> bool:
	var index := load_index()
	var slots: Dictionary = _slots_from_index(index)
	if slots.has(slot_id):
		slots.erase(slot_id)
		index["slots"] = slots
	# A deleted slot must not stay the Continue target.
	var last_played: Variant = index.get("last_played", {})
	if last_played is Dictionary \
			and String(last_played.get("kind", "")) == LAST_PLAYED_SLOT \
			and String(last_played.get("slot_id", "")) == slot_id:
		index.erase("last_played")
	return _write_index(index)


static func _slots_from_index(index: Dictionary) -> Dictionary:
	var slots: Variant = index.get("slots", {})
	return slots.duplicate(true) if slots is Dictionary else {}


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
