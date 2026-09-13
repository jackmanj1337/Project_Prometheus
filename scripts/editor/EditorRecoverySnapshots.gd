class_name EditorRecoverySnapshots extends RefCounted
# `[CEUI-S6]`/`[CEUI-S40]`'s durable recovery path. This is deliberately separate from
# `EditorDocument`'s session-scoped Undo history and from explicit saves: a recovery entry
# protects an interrupted edit, while the last-good save remains the author's durable
# baseline. The state is opaque to this class so every editor document can use one service.

const FORMAT_VERSION := 1
const DEFAULT_STORAGE_PATH := "user://campaign_editor/recovery_snapshots.json"
const DEFAULT_MAX_RECOVERY_SNAPSHOTS := 5
const DEFAULT_PERIOD_SECONDS := 30.0
const KIND_PERIODIC := "periodic"
const KIND_PRE_RISK := "pre_risk"

var _storage_path: String
var _max_recovery_snapshots: int
var _period_seconds: float
var _recovery: Array[Dictionary] = []
var _last_good_saves: Dictionary = {}
var _last_error := ""


func _init(
	storage_path: String = DEFAULT_STORAGE_PATH,
	max_recovery_snapshots: int = DEFAULT_MAX_RECOVERY_SNAPSHOTS,
	period_seconds: float = DEFAULT_PERIOD_SECONDS
) -> void:
	_storage_path = storage_path
	_max_recovery_snapshots = max(1, max_recovery_snapshots)
	_period_seconds = max(0.0, period_seconds)
	load_from_disk()


func storage_path() -> String:
	return _storage_path


## Draft ids are already pack-manifest ids, so they are safe path components. Keeping the
## derivation here means every editor entry point uses the same recovery store for a draft.
static func storage_path_for_working_copy(draft_id: String) -> String:
	return "user://campaign_editor/recovery/%s.json" % draft_id


func max_recovery_snapshots() -> int:
	return _max_recovery_snapshots


func period_seconds() -> float:
	return _period_seconds


func last_error() -> String:
	return _last_error


## Loads the editor's recovery store. A missing file is the normal first-run state; a
## malformed file is reported and ignored rather than turning recovery into a boot gate.
func load_from_disk() -> Dictionary:
	_recovery.clear()
	_last_good_saves.clear()
	_last_error = ""
	if not FileAccess.file_exists(_storage_path):
		return {"loaded": true, "recovery_count": 0}
	var handle := FileAccess.open(_storage_path, FileAccess.READ)
	if handle == null:
		_last_error = "Cannot read editor recovery snapshots."
		return {"loaded": false, "reason": _last_error}
	var parsed: Variant = JSON.parse_string(handle.get_as_text())
	handle.close()
	if (
		not parsed is Dictionary
		or int((parsed as Dictionary).get("format_version", 0)) != FORMAT_VERSION
	):
		_last_error = "The editor recovery snapshot file is not a supported format."
		return {"loaded": false, "reason": _last_error}
	var payload: Dictionary = parsed
	var recovery_value: Variant = payload.get("recovery", [])
	if recovery_value is Array:
		for value in recovery_value as Array:
			if value is Dictionary and _valid_entry(value as Dictionary):
				_recovery.append((value as Dictionary).duplicate(true))
	var saves_value: Variant = payload.get("last_good_saves", {})
	if saves_value is Dictionary:
		for document_id in saves_value:
			var save: Variant = (saves_value as Dictionary)[document_id]
			if save is Dictionary and _valid_save(save as Dictionary):
				_last_good_saves[String(document_id)] = (save as Dictionary).duplicate(true)
	_prune()
	return {"loaded": true, "recovery_count": _recovery.size()}


## A periodic capture is due only after the configured quiet period for that document.
## The caller supplies time so headless tests and browser hosts do not need to sleep.
func capture_periodic(document_id: String, state: Dictionary, now: float = -1.0) -> Dictionary:
	var timestamp := _now(now)
	if not _periodic_due(document_id, timestamp):
		return {"captured": false, "reason": "period_not_elapsed"}
	return _capture(document_id, state, KIND_PERIODIC, "periodic", timestamp)


## Captures immediately before a file-affecting or otherwise risky operation. The operation
## name is retained so crash recovery can explain why the entry exists.
func capture_before_risk(
	document_id: String, state: Dictionary, operation: String, now: float = -1.0
) -> Dictionary:
	if operation.strip_edges().is_empty():
		return {"captured": false, "reason": "operation_required"}
	return _capture(document_id, state, KIND_PRE_RISK, operation, _now(now))


## Explicit Save is not a recovery snapshot. Retaining this separately gives crash start a
## known-good baseline even after older recovery entries have been pruned or discarded.
func remember_last_good_save(
	document_id: String, state: Dictionary, now: float = -1.0
) -> Dictionary:
	if document_id.strip_edges().is_empty():
		return {"saved": false, "reason": "document_id_required"}
	var had_previous := _last_good_saves.has(document_id)
	var previous: Dictionary = last_good_save(document_id)
	_last_good_saves[document_id] = {
		"document_id": document_id,
		"saved_at": _now(now),
		"state": state.duplicate(true),
	}
	if not _persist():
		if had_previous:
			_last_good_saves[document_id] = previous
		else:
			_last_good_saves.erase(document_id)
		return {"saved": false, "reason": _last_error}
	return {"saved": true, "save": _last_good_saves[document_id].duplicate(true)}


func recovery_snapshots(document_id: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in _recovery:
		if document_id.is_empty() or String(entry["document_id"]) == document_id:
			out.append(entry.duplicate(true))
	return out


func last_good_save(document_id: String) -> Dictionary:
	return (_last_good_saves.get(document_id, {}) as Dictionary).duplicate(true)


func has_recovery(document_id: String = "") -> bool:
	return not recovery_snapshots(document_id).is_empty()


func recovery_count(document_id: String = "") -> int:
	return recovery_snapshots(document_id).size()


## Crash-start inspection returns metadata and state copies, but does not consume anything.
func inspect(document_id: String = "") -> Dictionary:
	return {
		"recovery": recovery_snapshots(document_id),
		"last_good_saves": _saves_for(document_id),
	}


## Returns the selected recovery state without deleting it. An empty id means newest for the
## requested document, which is the Restore action's safe default.
func restore(snapshot_id: String = "", document_id: String = "") -> Dictionary:
	var selected: Dictionary = {}
	for index in range(_recovery.size() - 1, -1, -1):
		var entry := _recovery[index]
		if not document_id.is_empty() and String(entry["document_id"]) != document_id:
			continue
		if snapshot_id.is_empty() or String(entry["snapshot_id"]) == snapshot_id:
			selected = entry
			break
	if selected.is_empty():
		return {"restored": false, "reason": "No recovery snapshot is available."}
	return {
		"restored": true,
		"snapshot": selected.duplicate(true),
		"state": (selected["state"] as Dictionary).duplicate(true)
	}


## Discard removes recovery entries only. The last-good explicit save is deliberately kept.
func discard_recovery(snapshot_id: String = "", document_id: String = "") -> Dictionary:
	var previous := _recovery.duplicate(true)
	var removed := 0
	var kept: Array[Dictionary] = []
	for entry in _recovery:
		var matches_document := (
			document_id.is_empty() or String(entry["document_id"]) == document_id
		)
		var matches_id := snapshot_id.is_empty() or String(entry["snapshot_id"]) == snapshot_id
		if matches_document and matches_id:
			removed += 1
		else:
			kept.append(entry)
	_recovery = kept
	if removed == 0:
		return {"discarded": false, "reason": "No matching recovery snapshot exists."}
	if not _persist():
		_recovery = previous
		return {"discarded": false, "reason": _last_error}
	return {"discarded": true, "removed": removed}


func _capture(
	document_id: String, state: Dictionary, kind: String, reason: String, timestamp: float
) -> Dictionary:
	if document_id.strip_edges().is_empty():
		return {"captured": false, "reason": "document_id_required"}
	var entry := {
		"schema_version": FORMAT_VERSION,
		"snapshot_id": _unique_id(document_id, kind, timestamp),
		"document_id": document_id,
		"kind": kind,
		"reason": reason,
		"captured_at": timestamp,
		"state": state.duplicate(true),
	}
	var previous := _recovery.duplicate(true)
	_recovery.append(entry)
	_prune()
	if not _persist():
		_recovery = previous
		return {"captured": false, "reason": _last_error}
	return {"captured": true, "snapshot": entry.duplicate(true)}


func _periodic_due(document_id: String, now: float) -> bool:
	for index in range(_recovery.size() - 1, -1, -1):
		var entry := _recovery[index]
		if String(entry["document_id"]) == document_id and String(entry["kind"]) == KIND_PERIODIC:
			return now - float(entry["captured_at"]) >= _period_seconds
	return true


func _unique_id(document_id: String, kind: String, timestamp: float) -> String:
	var base := "%s:%s:%d" % [document_id, kind, int(timestamp * 1000000.0)]
	var candidate := base
	var suffix := 1
	while _has_id(candidate):
		suffix += 1
		candidate = "%s-%d" % [base, suffix]
	return candidate


func _has_id(snapshot_id: String) -> bool:
	for entry in _recovery:
		if String(entry["snapshot_id"]) == snapshot_id:
			return true
	return false


func _prune() -> void:
	while _recovery.size() > _max_recovery_snapshots:
		_recovery.pop_front()


func _saves_for(document_id: String) -> Dictionary:
	if document_id.is_empty():
		return _last_good_saves.duplicate(true)
	return {document_id: last_good_save(document_id)} if _last_good_saves.has(document_id) else {}


func _valid_entry(entry: Dictionary) -> bool:
	return (
		String(entry.get("snapshot_id", "")) != ""
		and String(entry.get("document_id", "")) != ""
		and entry.get("state", null) is Dictionary
	)


func _valid_save(save: Dictionary) -> bool:
	return String(save.get("document_id", "")) != "" and save.get("state", null) is Dictionary


func _now(value: float) -> float:
	return Time.get_unix_time_from_system() if value < 0.0 else value


func _persist() -> bool:
	_last_error = ""
	var parent := _storage_path.get_base_dir()
	if (
		not parent.is_empty()
		and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(parent)) != OK
	):
		_last_error = "Cannot create the editor recovery snapshot directory."
		return false
	var temporary := "%s.tmp-%d-%d" % [_storage_path, Time.get_ticks_usec(), OS.get_process_id()]
	var handle := FileAccess.open(temporary, FileAccess.WRITE)
	if handle == null:
		_last_error = "Cannot write editor recovery snapshots."
		return false
	(
		handle
		. store_string(
			(
				JSON
				. stringify(
					{
						"format_version": FORMAT_VERSION,
						"recovery": _recovery,
						"last_good_saves": _last_good_saves,
					},
					"\t"
				)
			)
		)
	)
	handle.flush()
	handle.close()
	if _promote(temporary, _storage_path):
		return true
	_last_error = "Cannot replace editor recovery snapshots."
	return false


## A recovery file must never be half-written: crash recovery is least useful when the
## process crash that triggered it also corrupts the only copy. The old file is restored if
## the final rename fails.
func _promote(temporary: String, destination: String) -> bool:
	var temporary_absolute := ProjectSettings.globalize_path(temporary)
	var destination_absolute := ProjectSettings.globalize_path(destination)
	var backup_absolute := "%s.bak" % destination_absolute
	DirAccess.remove_absolute(backup_absolute)
	if FileAccess.file_exists(destination_absolute):
		if DirAccess.rename_absolute(destination_absolute, backup_absolute) != OK:
			DirAccess.remove_absolute(temporary_absolute)
			return false
	if DirAccess.rename_absolute(temporary_absolute, destination_absolute) == OK:
		DirAccess.remove_absolute(backup_absolute)
		return true
	if FileAccess.file_exists(backup_absolute):
		DirAccess.rename_absolute(backup_absolute, destination_absolute)
	DirAccess.remove_absolute(temporary_absolute)
	return false
