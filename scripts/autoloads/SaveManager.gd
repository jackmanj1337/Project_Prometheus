extends Node
# SaveManager owns disk I/O for save documents. SaveData stays pure and
# JSON-shaped; this service is the only place that knows user:// paths.
#
# Every document lives in one named slot namespace. Its intrinsic kind comes from
# map_runtime.map_path: populated means mid-map; empty means between-map.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const SavePolicy = preload("res://scripts/save/SavePolicy.gd")
const SaveIntegrity = preload("res://scripts/save/SaveIntegrity.gd")
const ImportBudgetConfig = preload("res://scripts/resources/ImportBudgets.gd")
const SaveMigrationServiceScript = preload("res://scripts/save/SaveMigrationService.gd")
const CampaignPackRegistryScript = preload("res://scripts/resources/CampaignPackRegistry.gd")
const SaveRecoveryScript = preload("res://scripts/save/SaveRecovery.gd")
const BackupEnvelopeScript = preload("res://scripts/save/BackupEnvelope.gd")
const PreflightScript = preload("res://scripts/resources/CampaignArchivePreflight.gd")

const DEFAULT_SAVE_DIR := "user://saves"
const INDEX_FILENAME := "saves_index.json"
const LAST_PLAYED_SLOT := "slot"

const MID_MAP_SLOT := "resume_battle"

# What a content diagnostic tells the reader to do. SEVERITY_SUPPRESSED is not a
# level: it is the report a repeat of an unchanged state produces.
const SEVERITY_ERROR := "error"
const SEVERITY_WARNING := "warning"
const SEVERITY_SUPPRESSED := "suppressed"

var save_dir: String = DEFAULT_SAVE_DIR
# label -> the last content-state string reported for it, so an unchanged state is
# reported once rather than once per load attempt.
var _reported_content_states: Dictionary = {}

# Failure seam used only by the disk-transaction regression suite.
var _test_fail_before_index_replace := false
# The last rejected write's stable code and player-facing recovery wording. Kept
# at the service boundary so import and ordinary save callers report the same cause.
var _last_write_failure: Dictionary = {}


func configure_save_dir_for_tests(path: String) -> void:
	save_dir = _strip_trailing_slashes(path)


func get_index_path() -> String:
	return _join_path(save_dir, INDEX_FILENAME)


# --- Continue routing ---------------------------------------------------------


# What Continue would resume: the most recently written document. Empty when
# there is nothing to continue. The caller routes on "kind" — a suspend resumes
# into the live map, a slot resumes into the campaign at its parked node.
func get_continue_target() -> Dictionary:
	var last_played := get_last_played()
	var kind: String = String(last_played.get("kind", ""))
	if kind == LAST_PLAYED_SLOT:
		var slot_id: String = String(last_played.get("slot_id", ""))
		if has_slot(slot_id) and _is_slot_resumable(slot_id):
			return {"kind": LAST_PLAYED_SLOT, "slot_id": slot_id}
	# The pointer is missing or names a document that is gone (deleted by hand, or
	# a failed write). Fall back to whatever is actually on disk rather than
	# refusing to continue a save the player can plainly see.
	for row in list_slots():
		if _row_is_resumable(row):
			return {"kind": LAST_PLAYED_SLOT, "slot_id": String(row.get("slot_id", ""))}
	return {}


func has_continue_save() -> bool:
	return not get_continue_target().is_empty()


# --- Unified slots ------------------------------------------------------------

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


func save_slot(
	slot_id: String, source: Variant, origin: String = "manual", rule_id: String = ""
) -> bool:
	var save := _save_data_from_variant(source)
	if save == null:
		_record_save_operation("save_slot", {"slot": slot_id, "reason_code": "invalid_source"})
		return false
	save.origin = origin
	save.rule_id = rule_id
	var errors := _validate_in_saved_catalogue(save)
	if not errors.is_empty():
		_push_validation_errors("SaveManager: slot '%s' rejected" % slot_id, errors)
		_record_save_operation(
			"save_slot",
			{
				"slot": slot_id,
				"reason_code": "validation_failed",
				"unresolved_ids": SaveRecoveryScript.unresolved_ids(errors)
			},
			save
		)
		return false
	var written := _commit_validated_slot(slot_id, save, origin, rule_id)
	var reason_code := String(_last_write_failure.get("reason_code", "commit_failed"))
	_record_save_operation(
		"save_slot", {"slot": slot_id, "reason_code": "" if written else reason_code}, save
	)
	return written


# Only service-owned validation paths enter here. Keep slot policy and the atomic
# file/index write together; validation never depends on the caller's active pack.
func _commit_validated_slot(
	slot_id: String, save: RefCounted, origin: String = "manual", rule_id: String = ""
) -> bool:
	_last_write_failure.clear()
	var path := get_slot_path(slot_id)
	if path == "":
		push_error("SaveManager: invalid slot id '%s'" % slot_id)
		_set_write_failure("invalid_slot_id", "The selected save slot is invalid.")
		return false
	save.origin = origin
	save.rule_id = rule_id
	if origin == "auto" and has_slot(slot_id):
		var existing := _row_for_slot(slot_id)
		# Structural invariant: no automatic write path may name a manual slot or
		# another autosave rule's pool.
		if (
			String(existing.get("origin", "manual")) != "auto"
			or String(existing.get("rule_id", "")) != rule_id
		):
			push_error("SaveManager: autosave '%s' cannot overwrite slot '%s'" % [rule_id, slot_id])
			_set_write_failure(
				"autosave_slot_conflict",
				"The automatic save could not replace the selected slot. Choose another slot."
			)
			return false
	var payload: Dictionary = SaveIntegrity.stamp(save.to_dict())
	if (
		origin == "manual"
		and not _manual_write_allowed(
			slot_id,
			String(payload.get("header", {}).get("save_kind", "between_map")),
			{
				"package_id": String(payload.get("header", {}).get("package_id", "")),
				"package_version": String(payload.get("header", {}).get("package_version", "")),
				"campaign_id": String(payload.get("header", {}).get("campaign_id", "")),
			}
		)
	):
		return false
	var index := load_index()
	var slots: Dictionary = _slots_from_index(index)
	slots[slot_id] = _slot_index_row(path, payload, index)
	index["slots"] = slots
	index["last_played"] = {
		"kind": LAST_PLAYED_SLOT,
		"path": path,
		"slot_id": slot_id,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
	}
	var committed := _commit_slot_transaction(path, payload, index)
	if not committed:
		_set_write_failure("commit_failed", "The save could not be written to disk.")
	return committed


# Writes into a rule-owned rotation pool. Candidate selection contains ONLY
# origin:auto rows with the same rule_id; manual and other-rule rows never enter it.
func save_automatic(rule_id: String, keep: int, source: Variant) -> bool:
	if rule_id.is_empty() or keep <= 0:
		return false
	var candidates: Array[Dictionary] = []
	for row in list_slots():
		if (
			String(row.get("origin", "manual")) == "auto"
			and String(row.get("rule_id", "")) == rule_id
		):
			candidates.append(row)
	var target_id := ""
	if candidates.size() >= keep:
		var target: Dictionary = candidates[candidates.size() - 1]  # oldest; list is newest-first
		assert(String(target.get("origin", "")) != "manual")
		target_id = String(target.get("slot_id", ""))
	else:
		var suffix := 1
		while target_id.is_empty():
			var candidate := "auto_%s_%02d" % [rule_id, suffix]
			if not has_slot(candidate):
				target_id = candidate
			suffix += 1
	var written := save_slot(target_id, source, "auto", rule_id)
	if written:
		_trim_automatic_pool(rule_id, keep)
	return written


func _trim_automatic_pool(rule_id: String, keep: int) -> void:
	var owned: Array[Dictionary] = []
	for row in list_slots():
		if (
			String(row.get("origin", "manual")) == "auto"
			and String(row.get("rule_id", "")) == rule_id
		):
			owned.append(row)
	# list_slots is newest-first; anything after keep is an owned stale rotation.
	for i in range(keep, owned.size()):
		assert(String(owned[i].get("origin", "")) != "manual")
		delete_slot(String(owned[i].get("slot_id", "")))


func should_consume_on_load(slot_id: String, slot_classes: Variant) -> bool:
	var row := _row_for_slot(slot_id)
	var header: Dictionary = row.get("header", {}) if row.get("header") is Dictionary else {}
	return (
		not row.is_empty()
		and SavePolicy.is_consumed_on_load(
			slot_classes, String(header.get("save_kind", "between_map"))
		)
	)


func load_slot(slot_id: String) -> RefCounted:
	if not has_slot(slot_id):
		_record_save_operation("load", {"slot": slot_id, "reason_code": "slot_missing"})
		return null
	var save := _read_save_document(get_slot_path(slot_id), "slot '%s'" % slot_id)
	_record_save_operation(
		"load",
		{"slot": slot_id, "reason_code": "" if save != null else "content_unavailable"},
		save
	)
	return save


# Portable saves are one pretty-printed JSON document. Integrity mismatch is
# advisory; structural/schema validation remains the hard load boundary.
func export_slot(slot_id: String, destination_path: String) -> Dictionary:
	var result := {"ok": false, "errors": [], "warnings": []}
	var save := load_slot(slot_id)
	if save == null:
		result["errors"].append("The selected save could not be loaded.")
		return result
	var payload := SaveIntegrity.stamp(save.to_dict())
	if DirAccess.make_dir_recursive_absolute(destination_path.get_base_dir()) != OK:
		result["errors"].append("The export directory could not be created.")
		return result
	if not _write_json_absolute(destination_path, payload):
		result["errors"].append("The portable save could not be written.")
		return result
	result["ok"] = true
	return result


func inspect_portable_save(
	source_path: String, warning_bytes: int = -1, maximum_bytes: int = -1
) -> Dictionary:
	var result := {
		"ok": false,
		"errors": [],
		"warnings": [],
		"save": null,
		"artifact_kind": "unknown",
		"content_state": SaveRecoveryScript.STATE_READY,
		"diagnostic": {},
		"document": {},
	}
	if warning_bytes < 0:
		warning_bytes = ImportBudgetConfig.portable_save_warning_bytes()
	if maximum_bytes < 0:
		maximum_bytes = ImportBudgetConfig.portable_save_maximum_bytes()
	if warning_bytes < 0 or maximum_bytes < 1 or warning_bytes > maximum_bytes:
		result["errors"].append("Portable-save import budgets are invalid.")
		_record_save_operation(
			"inspect_portable_save", {"source_path": source_path, "reason_code": "invalid_budget"}
		)
		return result
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		result["errors"].append("The selected file could not be opened.")
		_record_save_operation(
			"inspect_portable_save",
			{"source_path": source_path, "reason_code": "source_unreadable"}
		)
		return result
	var source_size := file.get_length()
	if source_size > maximum_bytes:
		result["errors"].append("The selected save exceeds the portable-save size limit.")
		_record_save_operation(
			"inspect_portable_save", {"source_path": source_path, "reason_code": "size_limit"}
		)
		return result
	if source_size > warning_bytes:
		result["warnings"].append(
			(
				"This save is unusually large (%s); verify its source before importing."
				% String.humanize_size(source_size)
			)
		)
	var bytes := file.get_buffer(source_size)
	if BackupEnvelopeScript.looks_like_zip(bytes):
		# A ZIP here is one of two different things, and telling the player the wrong
		# one sends them to a screen that will also refuse the file. Read the entry
		# names and say which it is.
		var entry_errors: Array[String] = []
		var entries := PreflightScript.read_central_directory(bytes, entry_errors)
		var names: Array = []
		for entry in entries:
			names.append(String(entry.get("path", "")))
		var kind := BackupEnvelopeScript.classify_archive_entries(names)
		if entry_errors.is_empty() and kind == BackupEnvelopeScript.ARTIFACT_CAMPAIGN_BACKUP:
			result["artifact_kind"] = BackupEnvelopeScript.ARTIFACT_CAMPAIGN_BACKUP
			result["errors"].append(
				"This ZIP is a full backup, not a single save. Restore it from Manage Campaigns."
			)
			_record_save_operation(
				"inspect_portable_save",
				{"source_path": source_path, "reason_code": "backup_archive"}
			)
			return result
		result["artifact_kind"] = "campaign_pack"
		result["errors"].append(
			"This ZIP is a campaign package. Import it from New Game > Manage Campaigns."
		)
		_record_save_operation(
			"inspect_portable_save", {"source_path": source_path, "reason_code": "campaign_archive"}
		)
		return result
	result["artifact_kind"] = "save_json"
	var parsed := _parse_json_dict(bytes.get_string_from_utf8(), source_path)
	if parsed.is_empty():
		result["errors"].append("The selected file is not a campaign save JSON object.")
		result["diagnostic"] = SaveRecoveryScript.describe(SaveRecoveryScript.REASON_INVALID)
		_record_save_operation(
			"inspect_portable_save", {"source_path": source_path, "reason_code": "invalid_source"}
		)
		return result
	result["warnings"].append_array(SaveIntegrity.verify(parsed))
	# The document as received. A disabled import is stored from this, not from a
	# re-serialized SaveData: normalization fills defaults against the catalogue
	# that is loaded now, which is precisely the catalogue a disabled save does
	# not have. Guessing here would silently edit the player's only copy.
	result["document"] = parsed
	var save: RefCounted = SaveDataScript.from_dict(parsed)
	var prepared := _prepare_for_saved_content(save)
	var errors: Array[String] = prepared["errors"]
	# A save the installed library cannot run is still a save. Only a document
	# that is not a readable save is refused here; everything else is reported as
	# a recoverable disabled import, with the source document untouched.
	if String(prepared["reason"]) == SaveRecoveryScript.REASON_INVALID:
		result["errors"].append_array(errors)
		result["diagnostic"] = _diagnostic_for(prepared, save)
		_record_save_operation(
			"inspect_portable_save",
			{
				"source_path": source_path,
				"reason_code": String(prepared["reason"]),
				"unresolved_ids": SaveRecoveryScript.unresolved_ids(errors)
			},
			save
		)
		return result
	if not errors.is_empty():
		result["content_state"] = SaveRecoveryScript.STATE_DISABLED
		result["diagnostic"] = _diagnostic_for(prepared, save)
		result["save"] = save
		result["ok"] = true
		_record_save_operation(
			"inspect_portable_save",
			{
				"source_path": source_path,
				"outcome": "disabled",
				"reason_code": String(prepared["reason"]),
				"unresolved_ids": SaveRecoveryScript.unresolved_ids(errors)
			},
			save
		)
		return result
	# Import stores the document as received; resolution ran only to decide the
	# content state, so a successor save is migrated on load, not on import.
	result["save"] = save
	result["ok"] = true
	_record_save_operation(
		"inspect_portable_save", {"source_path": source_path, "outcome": "ready"}, save
	)
	return result


func import_portable_save(
	source_path: String,
	slot_id: String,
	acknowledge_warnings: bool = false,
	warning_bytes: int = -1,
	maximum_bytes: int = -1
) -> Dictionary:
	var result := inspect_portable_save(source_path, warning_bytes, maximum_bytes)
	if not result["ok"]:
		_record_save_operation(
			"import_portable_save",
			{
				"slot": slot_id,
				"reason_code": "inspection_failed",
				"unresolved_ids": SaveRecoveryScript.unresolved_ids(result.get("errors", []))
			}
		)
		return result
	if not result["warnings"].is_empty() and not acknowledge_warnings:
		result["ok"] = false
		result["requires_acknowledgement"] = true
		_record_save_operation(
			"import_portable_save", {"slot": slot_id, "reason_code": "acknowledgement_required"}
		)
		return result
	# A save whose package is absent is stored disabled: the document is written
	# verbatim and the index row records why it cannot run. It never activates
	# content, never migrates and never counts as a load; installing the package
	# and choosing Retry is what promotes it.
	if String(result["content_state"]) == SaveRecoveryScript.STATE_DISABLED:
		if not _store_disabled_slot(
			slot_id, result["save"], result["document"], result["diagnostic"]
		):
			result["ok"] = false
			result["errors"].append(_last_write_failure_message())
			_record_save_operation(
				"import_portable_save",
				{
					"slot": slot_id,
					"reason_code": _last_write_failure_code(),
					"unresolved_ids": SaveRecoveryScript.unresolved_ids(result.get("errors", []))
				},
				result.get("save")
			)
			return result
		result["ok"] = true
		_record_save_operation(
			"import_portable_save",
			{
				"slot": slot_id,
				"outcome": "disabled",
				"reason_code": String(result.get("diagnostic", {}).get("reason", "")),
				"unresolved_ids": SaveRecoveryScript.unresolved_ids(result.get("errors", []))
			},
			result.get("save")
		)
		return result
	if not _commit_validated_slot(slot_id, result["save"], "manual"):
		result["ok"] = false
		result["errors"].append(_last_write_failure_message())
		_record_save_operation(
			"import_portable_save",
			{"slot": slot_id, "reason_code": _last_write_failure_code()},
			result.get("save")
		)
		return result
	result["ok"] = true
	_record_save_operation(
		"import_portable_save", {"slot": slot_id, "outcome": "ready"}, result.get("save")
	)
	return result


# Writes a structurally valid but unrunnable save. This is save_slot's transaction
# without its catalogue gate: the gate asks whether the ACTIVE library can run the
# document, which is exactly the question a disabled save has already answered no
# to. Structure was validated by inspection before this is reached.
func _store_disabled_slot(
	slot_id: String, save: RefCounted, document: Dictionary, diagnostic: Dictionary
) -> bool:
	_last_write_failure.clear()
	var path := get_slot_path(slot_id)
	if path == "":
		push_error("SaveManager: invalid slot id '%s'" % slot_id)
		_set_write_failure("invalid_slot_id", "The selected save slot is invalid.")
		return false
	if save == null:
		_set_write_failure("invalid_save", "The imported save is invalid.")
		return false
	save.origin = "manual"
	save.rule_id = ""
	var structural: Array[String] = _inspect_structure(save)
	if not structural.is_empty():
		_push_validation_errors("SaveManager: slot '%s' rejected" % slot_id, structural)
		_set_write_failure("validation_failed", "The imported save is structurally invalid.")
		return false
	# The index row is derived from the normalized document (it is a cache), while
	# the stored payload stays exactly what was imported.
	var normalized: Dictionary = save.to_dict()
	var payload: Dictionary = document if not document.is_empty() else normalized
	if not _manual_write_allowed(
		slot_id,
		String(normalized.get("header", {}).get("save_kind", "between_map")),
		{
			"package_id": String(normalized.get("header", {}).get("package_id", "")),
			"package_version": String(normalized.get("header", {}).get("package_version", "")),
			"campaign_id": String(normalized.get("header", {}).get("campaign_id", "")),
		}
	):
		return false
	var index := load_index()
	var slots: Dictionary = _slots_from_index(index)
	var row := _slot_index_row(path, normalized, index)
	row["content_state"] = SaveRecoveryScript.STATE_DISABLED
	row["recovery"] = diagnostic.duplicate(true)
	slots[slot_id] = row
	index["slots"] = slots
	# A disabled save is not resumable, so it must not become the Continue target.
	return _commit_slot_transaction(path, payload, index)


# Restore writes a save the player ALREADY HAD back into its slot. It reuses the
# import inspection (structure remains the hard boundary) and the same atomic
# slot/index transaction, and differs from an ordinary import in two deliberate ways:
#
#   - The recorded origin and rule_id are preserved, so a restored autosave lands
#     back in the pool it belonged to instead of quietly becoming a manual save.
#   - The manual-slot budget is not applied. That budget bounds how many saves a
#     player CREATES during play; applying it here would refuse to restore saves
#     that already existed, which makes a backup unusable on the very machine it
#     was taken from.
#
# The caller supplies the dictionary from inspect_portable_save, so a save whose
# package is absent restores DISABLED rather than being refused, exactly as it would
# on import. An occupied slot is refused: replacing one is the caller's decision and
# its transaction, not a side effect of restoring.
func restore_slot(
	slot_id: String, inspection: Dictionary, origin: String = "manual", rule_id: String = ""
) -> Dictionary:
	var outcome := {"ok": false, "errors": [] as Array[String], "content_state": ""}
	var path := get_slot_path(slot_id)
	if path == "":
		outcome["errors"].append("The restored save has an unusable slot name.")
		return outcome
	if has_slot(slot_id):
		outcome["errors"].append("A save already occupies that slot.")
		return outcome
	var save: RefCounted = inspection.get("save", null)
	if save == null:
		outcome["errors"].append("The restored save could not be read.")
		return outcome
	save.origin = origin
	save.rule_id = rule_id
	var structural: Array[String] = _inspect_structure(save)
	if not structural.is_empty():
		outcome["errors"].append_array(structural)
		return outcome
	# As on import, the index row is derived from the normalized document while the
	# stored payload stays exactly the bytes the backup carried.
	var normalized: Dictionary = save.to_dict()
	var document: Dictionary = inspection.get("document", {})
	var payload: Dictionary = document if not document.is_empty() else normalized
	var index := load_index()
	var slots: Dictionary = _slots_from_index(index)
	var row := _slot_index_row(path, normalized, index)
	var state := String(inspection.get("content_state", SaveRecoveryScript.STATE_READY))
	row["content_state"] = state
	if state == SaveRecoveryScript.STATE_DISABLED:
		row["recovery"] = Dictionary(inspection.get("diagnostic", {})).duplicate(true)
	slots[slot_id] = row
	index["slots"] = slots
	if not _commit_slot_transaction(path, payload, index):
		outcome["errors"].append("The restored save could not be written.")
		return outcome
	outcome["ok"] = true
	outcome["content_state"] = state
	return outcome


# The Retry action. Re-reads the stored document and re-runs resolution against
# the library as it is now; on success the index row is promoted to ready, and on
# failure only the recorded diagnostic is refreshed. The save document itself is
# never rewritten by either outcome.
func revalidate_slot(slot_id: String) -> Dictionary:
	var outcome := {
		"ok": false,
		"content_state": SaveRecoveryScript.STATE_DISABLED,
		"diagnostic": {},
		"errors": [] as Array[String],
	}
	if not has_slot(slot_id):
		outcome["errors"].append("The selected save no longer exists.")
		outcome["diagnostic"] = SaveRecoveryScript.describe(SaveRecoveryScript.REASON_INVALID)
		_record_save_operation("revalidate_slot", {"slot": slot_id, "reason_code": "slot_missing"})
		return outcome
	var file := FileAccess.open(get_slot_path(slot_id), FileAccess.READ)
	if file == null:
		outcome["errors"].append("The selected save could not be opened.")
		outcome["diagnostic"] = SaveRecoveryScript.describe(SaveRecoveryScript.REASON_INVALID)
		_record_save_operation(
			"revalidate_slot", {"slot": slot_id, "reason_code": "source_unreadable"}
		)
		return outcome
	var text := file.get_as_text()
	file.close()
	var parsed := _parse_json_dict(text, get_slot_path(slot_id))
	if parsed.is_empty():
		outcome["errors"].append("The selected save could not be read.")
		outcome["diagnostic"] = SaveRecoveryScript.describe(SaveRecoveryScript.REASON_INVALID)
		_record_save_operation(
			"revalidate_slot", {"slot": slot_id, "reason_code": "invalid_source"}
		)
		return outcome
	var save: RefCounted = SaveDataScript.from_dict(parsed)
	var prepared := _prepare_for_saved_content(save)
	var errors: Array[String] = prepared["errors"]
	if not errors.is_empty():
		outcome["errors"].append_array(errors)
		outcome["diagnostic"] = _diagnostic_for(prepared, save)
		_write_slot_content_state(slot_id, SaveRecoveryScript.STATE_DISABLED, outcome["diagnostic"])
		_record_save_operation(
			"revalidate_slot",
			{
				"slot": slot_id,
				"reason_code": String(prepared["reason"]),
				"unresolved_ids": SaveRecoveryScript.unresolved_ids(errors)
			},
			save
		)
		return outcome
	outcome["ok"] = true
	outcome["content_state"] = SaveRecoveryScript.STATE_READY
	_write_slot_content_state(slot_id, SaveRecoveryScript.STATE_READY, {})
	_record_save_operation("revalidate_slot", {"slot": slot_id, "outcome": "ready"}, save)
	return outcome


# Index-only write: the slot document is not staged, so a failure here leaves the
# save and its row exactly as they were and the next Retry re-derives the state.
func _write_slot_content_state(slot_id: String, state: String, diagnostic: Dictionary) -> bool:
	var index := load_index()
	var slots: Dictionary = _slots_from_index(index)
	if not slots.has(slot_id) or not slots[slot_id] is Dictionary:
		return false
	var row: Dictionary = slots[slot_id]
	row["content_state"] = state
	if state == SaveRecoveryScript.STATE_DISABLED:
		row["recovery"] = diagnostic.duplicate(true)
	else:
		row.erase("recovery")
	slots[slot_id] = row
	index["slots"] = slots
	return _write_index(index)


# Migrates one stored save into a new slot. The source slot is never rewritten
# or deleted, and save_slot retains the existing atomic file/index transaction.
func migrate_save_into_slot(
	source_slot_id: String,
	destination_slot_id: String,
	destination_package_id: String,
	declaration: Dictionary,
	destination_exists: Callable = Callable()
) -> Dictionary:
	var source: SaveData = load_slot(source_slot_id) as SaveData
	return migrate_save_document_into_slot(
		source, destination_slot_id, destination_package_id, declaration, destination_exists
	)


func preview_save_migration(
	source_slot_id: String,
	destination_package_id: String,
	declaration: Dictionary,
	destination_exists: Callable = Callable()
) -> Dictionary:
	var source: SaveData = load_slot(source_slot_id) as SaveData
	return SaveMigrationServiceScript.preview(
		source, destination_package_id, declaration, destination_exists
	)


func migrate_save_document_into_slot(
	source: SaveData,
	destination_slot_id: String,
	destination_package_id: String,
	declaration: Dictionary,
	destination_exists: Callable = Callable()
) -> Dictionary:
	var result := SaveMigrationServiceScript.preview(
		source, destination_package_id, declaration, destination_exists
	)
	if not result["ok"]:
		_record_save_operation(
			"migrate_save_into_slot",
			{
				"slot": destination_slot_id,
				"reason_code": SaveRecoveryScript.migration_kind(result.get("errors", [])),
				"unresolved_ids": SaveRecoveryScript.unresolved_ids(result.get("errors", []))
			},
			source
		)
		return result
	if has_slot(destination_slot_id):
		result["ok"] = false
		result["errors"].append("migration_destination_slot_exists")
		_record_save_operation(
			"migrate_save_into_slot",
			{"slot": destination_slot_id, "reason_code": "destination_exists"},
			source
		)
		return result
	if not save_slot(destination_slot_id, result["save"], "manual"):
		result["ok"] = false
		result["errors"].append("migration_commit_failed")
		_record_save_operation(
			"migrate_save_into_slot",
			{"slot": destination_slot_id, "reason_code": "commit_failed"},
			result.get("save", source)
		)
		return result
	_record_save_operation(
		"migrate_save_into_slot",
		{"slot": destination_slot_id, "outcome": "ready"},
		result.get("save", source)
	)
	return result


func delete_slot(slot_id: String) -> bool:
	# A slot id can be reused by a later import, and that import's state is new.
	_reported_content_states.erase("slot '%s'" % slot_id)
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
	# write_seq is the ordering key; the timestamp is
	# only the tiebreak for rows written before the counter existed.
	rows.sort_custom(
		func(a, b):
			var seq_a: int = int(a.get("write_seq", 0))
			var seq_b: int = int(b.get("write_seq", 0))
			if seq_a != seq_b:
				return seq_a > seq_b
			return int(a.get("saved_at_unix", 0)) > int(b.get("saved_at_unix", 0))
	)
	return rows


func get_last_played() -> Dictionary:
	var index := load_index()
	var last_played: Variant = index.get("last_played", {})
	return last_played if last_played is Dictionary else {}


func record_campaign_started(identity: Dictionary) -> bool:
	return _record_campaign_preference("last_started", identity)


func record_campaign_imported(identity: Dictionary) -> bool:
	return _record_campaign_preference("last_imported", identity)


func campaign_preference_candidates() -> Array[Dictionary]:
	var preference: Variant = load_index().get("campaign_preference", {})
	if not (preference is Dictionary):
		return []
	var out: Array[Dictionary] = []
	for key in ["last_started", "last_imported"]:
		var identity: Variant = preference.get(key, {})
		if identity is Dictionary and not String(identity.get("campaign_id", "")).is_empty():
			out.append(identity.duplicate(true))
	return out


func _record_campaign_preference(kind: String, identity: Dictionary) -> bool:
	if (
		kind not in ["last_started", "last_imported"]
		or String(identity.get("campaign_id", "")).is_empty()
	):
		return false
	var index := load_index()
	var preference: Dictionary = (
		index.get("campaign_preference", {}).duplicate(true)
		if index.get("campaign_preference", {}) is Dictionary
		else {}
	)
	preference[kind] = {
		"campaign_id": String(identity.get("campaign_id", "")),
		"package_id": String(identity.get("package_id", "")),
		"package_version": String(identity.get("package_version", "")),
		"recorded_at_unix": int(Time.get_unix_time_from_system()),
	}
	index["campaign_preference"] = preference
	return _write_index(index)


func _row_for_slot(slot_id: String) -> Dictionary:
	var slots := _slots_from_index(load_index())
	var row: Variant = slots.get(slot_id, {})
	return row.duplicate(true) if row is Dictionary else {}


func _manual_write_allowed(slot_id: String, save_kind: String, scope: Variant) -> bool:
	var existing := _row_for_slot(slot_id)
	if not existing.is_empty():
		if String(existing.get("origin", "manual")) != "manual":
			push_error("SaveManager: manual save cannot replace an automatic pool slot")
			_set_write_failure(
				"manual_slot_conflict",
				"The selected slot is reserved for automatic saves. Choose a different slot in the replacement picker."
			)
			return false
		return true
	var budget := manual_slot_budget(save_kind, scope)
	if int(budget.get("class_index", -1)) < 0:
		push_error("SaveManager: save policy accepts no '%s' manual slots" % save_kind)
		_set_write_failure(
			"manual_slot_class_unavailable",
			"This campaign does not allow manual %s saves in the selected slot class." % save_kind
		)
		return false
	if bool(budget.get("full", false)):
		push_error(
			"SaveManager: manual '%s' slot class is full for campaign '%s'" % [save_kind, scope]
		)
		_set_write_failure(
			"manual_slot_class_full",
			(
				"The manual %s save-slot class is full for this campaign. Delete an existing save from that class or choose a different slot in the replacement picker."
				% save_kind
			)
		)
		return false
	return true


func _set_write_failure(reason_code: String, message: String) -> void:
	_last_write_failure = {"reason_code": reason_code, "message": message}


func _last_write_failure_code() -> String:
	return String(_last_write_failure.get("reason_code", "commit_failed"))


func _last_write_failure_message() -> String:
	return String(
		_last_write_failure.get(
			"message", "The imported save could not be stored in the selected slot."
		)
	)


# Reports the manual-slot budget for a save kind within one package/campaign
# version scope. A migration preserves the old release's save without consuming
# the destination release's slots. Different installed packs may intentionally
# reuse campaign ids, so package identity is part of the bucket (V070-07). `scope` defaults to the active
# package and campaign; a legacy string scope remains accepted as an empty-package
# campaign bucket for old callers. Public so the UI can explain
# a cap-full refusal instead of a bare "Save failed." Returns
# {cap, used, full, class_index, scope}; class_index < 0 means the policy accepts
# no manual slot of this kind.
func manual_slot_budget(save_kind: String, scope: Variant = null) -> Dictionary:
	var resolved_scope: Dictionary = _normalize_campaign_scope(
		scope if scope != null else _active_campaign_scope()
	)
	var classes := _active_slot_classes()
	var target_index := _class_index_for_kind(classes, save_kind)
	if target_index < 0:
		return {"cap": 0, "used": 0, "full": true, "class_index": -1, "scope": resolved_scope}
	var used := 0
	for row in list_slots():
		if String(row.get("origin", "manual")) != "manual":
			continue
		var header: Dictionary = row.get("header", {}) if row.get("header") is Dictionary else {}
		if _normalize_campaign_scope(header) != resolved_scope:
			continue
		if (
			_class_index_for_kind(classes, String(header.get("save_kind", "between_map")))
			== target_index
		):
			used += 1
	var cap := int(classes[target_index].get("count", 0))
	return {
		"cap": cap,
		"used": used,
		"full": used >= cap,
		"class_index": target_index,
		"scope": resolved_scope,
	}


# The active package release and campaign used by UI budget queries.
func _active_campaign_scope() -> Dictionary:
	var scope := {"package_id": "", "package_version": "", "campaign_id": ""}
	if is_inside_tree():
		var cm := get_node_or_null("/root/CampaignManager")
		if cm != null and "active_campaign_id" in cm:
			scope["campaign_id"] = String(cm.get("active_campaign_id"))
		var dm := get_node_or_null("/root/DataManager")
		if dm != null and dm.has_method("active_package_identity"):
			var identity: Variant = dm.call("active_package_identity")
			if identity is Dictionary:
				scope["package_id"] = String(identity.get("package_id", ""))
				scope["package_version"] = String(identity.get("package_version", ""))
	return scope


func _normalize_campaign_scope(scope: Variant) -> Dictionary:
	if scope is Dictionary:
		return {
			"package_id": String(scope.get("package_id", "")),
			"package_version": String(scope.get("package_version", "")),
			"campaign_id": String(scope.get("campaign_id", "")),
		}
	return {"package_id": "", "package_version": "", "campaign_id": String(scope)}


func _active_slot_classes() -> Array[Dictionary]:
	if is_inside_tree():
		var gs := get_node_or_null("/root/GameState")
		if gs != null and gs.has_method("get_save_slot_classes"):
			return SavePolicy.normalize_slot_classes(gs.call("get_save_slot_classes"))
	return SavePolicy.classic_gba()


func _class_index_for_kind(classes: Array[Dictionary], save_kind: String) -> int:
	for i in classes.size():
		if (
			int(classes[i].get("count", 0)) > 0
			and String(classes[i].get("accepts", "")) in [save_kind, SavePolicy.ANY]
		):
			return i
	return -1


func _is_slot_resumable(slot_id: String) -> bool:
	for row in list_slots():
		if String(row.get("slot_id", "")) == slot_id:
			return _row_is_resumable(row)
	return false


# A completed campaign is a record, and a disabled save cannot activate its
# content — neither may be offered as Continue. Rows written before the content
# state existed are ready by omission.
static func _row_is_resumable(row: Dictionary) -> bool:
	var header: Variant = row.get("header", {})
	return (
		header is Dictionary
		and String(header.get("campaign_state", "in_progress")) != "completed"
		and (
			String(row.get("content_state", SaveRecoveryScript.STATE_READY))
			!= SaveRecoveryScript.STATE_DISABLED
		)
	)


func load_index() -> Dictionary:
	var path := get_index_path()
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error(
			(
				"SaveManager: failed to open saves index: %s"
				% error_string(FileAccess.get_open_error())
			)
		)
		return {}
	var text := file.get_as_text()
	file.close()
	return _parse_json_dict(text, path)


# Reads one validated document. Null on anything that is not a loadable
# document — unparseable JSON, or a payload that fails validation.
func _read_save_document(path: String, label: String) -> RefCounted:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error(
			(
				"SaveManager: failed to open %s for read: %s"
				% [label, error_string(FileAccess.get_open_error())]
			)
		)
		return null
	var text := file.get_as_text()
	file.close()
	var parsed := _parse_json_dict(text, path)
	if parsed.is_empty():
		return null
	var save: RefCounted = SaveDataScript.from_dict(parsed)
	var prepared := _prepare_for_saved_content(save)
	var errors: Array[String] = prepared["errors"]
	if not errors.is_empty():
		report_content_diagnostic(label, prepared)
		return null
	# A slot that loads has no state left to re-report if it later stops loading.
	_reported_content_states.erase(label)
	return prepared["save"]


# Severity is a decision about what the reader should do, so it is a function that
# can be asserted rather than a branch buried in a logging call (V0715-05).
#
# A save the installed library cannot run is an EXPECTED state: it has a recovery
# row, a worded diagnostic and three offered actions. Reporting it through
# push_error told the reader the engine had faulted. The v0.7.15 return logged
# eight red lines for one intentionally retained, correctly disabled save, against
# a checklist that asks for no migration errors -- an acceptance criterion the
# build could not satisfy while being right.
#
# push_error is kept for the one case that IS a contract violation: a document
# that is not a readable save at all. Nothing in the recovery UI can act on that.
static func diagnostic_severity(reason: String) -> String:
	if reason.is_empty() or reason == SaveRecoveryScript.REASON_INVALID:
		return SEVERITY_ERROR
	return SEVERITY_WARNING


# Returns the severity actually used, so a caller or a test can see that a repeat
# of an unchanged state was suppressed rather than re-emitted.
func report_content_diagnostic(label: String, prepared: Dictionary) -> String:
	var reason := String(prepared.get("reason", ""))
	var errors: Array[String] = prepared["errors"]
	var severity := diagnostic_severity(reason)
	if severity == SEVERITY_ERROR:
		_reported_content_states.erase(label)
		_push_validation_errors("SaveManager: %s failed validation" % label, errors)
		return severity
	# One record per slot per state TRANSITION. The return logged the same four
	# diagnostics twice because every attempt re-emitted the whole list while the
	# slot's state had not changed between them.
	var state := "%s|%s" % [reason, "\n".join(errors)]
	if String(_reported_content_states.get(label, "")) == state:
		return SEVERITY_SUPPRESSED
	_reported_content_states[label] = state
	push_warning(
		(
			"SaveManager: %s is not loadable with the installed content (%s): %s"
			% [label, reason, "; ".join(errors)]
		)
	)
	return severity


# Inventory ids belong to the catalogue recorded by the save, not whichever
# catalogue happens to be active on the menu. Temporarily select that trusted,
# installed source for reference validation, then restore the exact prior content
# session; the later GameState configure step performs permanent activation.
func _validate_for_saved_content(save: RefCounted) -> Array[String]:
	return _prepare_for_saved_content(save)["errors"]


# Stage 2F splits one question into two. "Is this document a save?" is answered
# without touching the catalogue and is a hard boundary: a malformed document is
# never stored. "Can the installed library run it?" is answered separately and is
# recoverable — a sound save whose package is absent is kept verbatim in the
# disabled state rather than refused, because refusing it destroys the only copy
# of the player's progress over something installing a package would fix.
func _inspect_structure(save: RefCounted) -> Array[String]:
	return save.validate(null)


# Resolve identity before touching live content. Exact saves must match the
# installed bytes; successors run a complete declared chain on a deep copy.
# The source slot is never rewritten, and the prior content session is restored
# after catalogue validation on every success or failure path.
#
# Returns {save, errors, reason, saved_identity, installed_identities}: `reason`
# is empty when the save is ready, and otherwise names the SaveRecovery reason
# that words the failure for the player.
func _prepare_for_saved_content(save: RefCounted) -> Dictionary:
	var result := {
		"save": save,
		"errors": [] as Array[String],
		"reason": "",
		"saved_identity": {},
		"installed_identities": [] as Array[Dictionary],
	}
	var structural: Array[String] = _inspect_structure(save)
	if not structural.is_empty():
		result["errors"] = structural
		result["reason"] = SaveRecoveryScript.REASON_INVALID
		return result
	var dm := _data_manager()
	if (
		dm == null
		or not dm.has_method("select_saved_campaign_source")
		or not dm.has_method("capture_content_session")
		or not dm.has_method("restore_content_session")
	):
		result["errors"] = save.validate(dm)
		if not result["errors"].is_empty():
			result["reason"] = SaveRecoveryScript.REASON_MISSING_CONTENT
		return result
	# Format-1 and editor-authored fixtures predate package identity. They keep
	# the shipped-content path until the existing in-memory schema migration has
	# supplied a source envelope; package resolution applies only to identified
	# format-2 saves.
	if String(save.source.get("package_id", "")).is_empty():
		var previous_legacy: RefCounted = dm.call("capture_content_session")
		if not bool(dm.call("select_saved_campaign_source", "", "")):
			dm.call("restore_content_session", previous_legacy)
			result["errors"].append("SaveData: saved campaign content could not be activated")
			result["reason"] = SaveRecoveryScript.REASON_MISSING
			return result
		result["errors"] = save.validate(dm)
		dm.call("restore_content_session", previous_legacy)
		if not result["errors"].is_empty():
			result["reason"] = SaveRecoveryScript.REASON_MISSING_CONTENT
		return result
	var registry := CampaignPackRegistryScript.new(CampaignPackRegistryScript.DEFAULT_STORAGE_ROOT)
	var summaries: Array[Dictionary] = registry.refresh()
	var resolution := SaveMigrationServiceScript.resolve_source(save.source, summaries)
	result["saved_identity"] = resolution.saved_identity.duplicate(true)
	result["installed_identities"] = resolution.installed_identities.duplicate(true)
	if not resolution.can_continue():
		result["errors"].append("save_source_%s" % resolution.status)
		result["reason"] = SaveRecoveryScript.reason_for_status(resolution.status)
		return result
	var candidate: RefCounted = save
	# A pre-fingerprint save resolved to an exact version adopts that release's
	# content identity in memory, so the run continues as a complete format-2
	# document. The stored slot is not rewritten here; the next ordinary save
	# records the adopted identity.
	if resolution.status == SaveMigrationServiceScript.STATUS_EXACT:
		for field in ["content_schema_version", "content_fingerprint"]:
			if resolution.candidate_identity.has(field):
				save.source[field] = resolution.candidate_identity[field]
				save.campaign[field] = resolution.candidate_identity[field]
	if resolution.status == SaveMigrationServiceScript.STATUS_SUCCESSOR:
		var summary: Dictionary = {}
		for installed in summaries:
			if (
				(
					String(installed.get("package_id", ""))
					== String(resolution.candidate_identity.get("package_id", ""))
				)
				and (
					String(installed.get("package_version", ""))
					== String(resolution.candidate_identity.get("package_version", ""))
				)
			):
				summary = installed
				break
		if summary.is_empty():
			result["errors"].append("save_source_candidate_missing")
			result["reason"] = SaveRecoveryScript.REASON_INCOMPATIBLE
			return result
		var chain := SaveMigrationServiceScript.plan_chain(
			save.source, summary, summary.get("save_migrations", [])
		)
		if not chain["ok"]:
			result["errors"].append_array(chain["errors"])
			result["reason"] = SaveRecoveryScript.REASON_INCOMPATIBLE
			return result
		var ids: Dictionary = summary.get("content_ids", {})
		var exists := func(family: String, id: String) -> bool:
			return ids.has(family) and ids[family].has(id)
		for index in chain["chain"].size():
			var declaration: Dictionary = chain["chain"][index]
			# Intermediate ids may be intentionally transient. Only the complete
			# candidate is required to resolve against the installed destination.
			var destination_check := exists if index == chain["chain"].size() - 1 else Callable()
			var preview := SaveMigrationServiceScript.preview(
				candidate, String(summary["package_id"]), declaration, destination_check
			)
			if not preview["ok"]:
				result["errors"].append_array(preview["errors"])
				result["reason"] = SaveRecoveryScript.REASON_INCOMPATIBLE
				return result
			candidate = preview["save"]
		result["save"] = candidate
	result["errors"] = _validate_in_saved_catalogue(candidate)
	if not result["errors"].is_empty():
		result["reason"] = SaveRecoveryScript.REASON_MISSING_CONTENT
	return result


# Validate the document's exact identity, never a successor or an ambient pack.
# Legacy editor/test documents have no identity and retain their active catalogue.
func _validate_in_saved_catalogue(save: RefCounted) -> Array[String]:
	var dm := _data_manager()
	var source: Dictionary = save.source
	if (
		dm == null
		or not dm.has_method("capture_content_session")
		or String(source.get("package_id", "")).is_empty()
	):
		return save.validate(dm)
	var previous: RefCounted = dm.call("capture_content_session")
	var activated := bool(
		dm.call(
			"select_saved_campaign_source",
			String(source.get("package_id", "")),
			String(source.get("package_version", "")),
			(
				int(source.get("content_schema_version", -1))
				if not String(source.get("content_fingerprint", "")).is_empty()
				else -1
			),
			String(source.get("content_fingerprint", ""))
		)
	)
	var errors: Array[String] = []
	if activated:
		errors = save.validate(dm)
	else:
		errors.append("SaveData: saved campaign content could not be activated")
	dm.call("restore_content_session", previous)
	return errors


# The player-facing record for a prepare failure: SaveRecovery words it from the
# identities alone, so no engine error string or path reaches the screen.
func _diagnostic_for(prepared: Dictionary, save: RefCounted) -> Dictionary:
	var reason := String(prepared.get("reason", ""))
	if reason.is_empty():
		return {}
	var saved_identity: Dictionary = prepared.get("saved_identity", {})
	if saved_identity.is_empty() and save != null:
		saved_identity = save.source
	return SaveRecoveryScript.describe(
		reason,
		saved_identity,
		prepared.get("installed_identities", []),
		SaveRecoveryScript.unresolved_ids(prepared.get("errors", []))
	)


func _record_save_operation(event: String, fields: Dictionary = {}, save: Variant = null) -> void:
	var diagnostics := get_node_or_null("/root/DiagnosticsLog") if is_inside_tree() else null
	if diagnostics == null or not diagnostics.has_method("record"):
		return
	var record_fields := fields.duplicate(true)
	if not record_fields.has("outcome"):
		record_fields["outcome"] = (
			"refused"
			if not String(record_fields.get("reason_code", "")).is_empty()
			else "completed"
		)
	record_fields["active_session"] = _active_diagnostics_session()
	if save != null and save is Object:
		var campaign: Variant = save.get("campaign")
		var source: Variant = save.get("source")
		record_fields["campaign"] = _diagnostic_identity(campaign, source)
		record_fields["source"] = _diagnostic_identity(source)
	if record_fields.has("unresolved_ids") and record_fields["unresolved_ids"] is Array:
		record_fields["unresolved_ids"] = SaveRecoveryScript.unresolved_ids(
			record_fields["unresolved_ids"]
		)
	diagnostics.record(
		&"save",
		StringName(event),
		record_fields,
		"%s:%s" % [event, record_fields.get("slot", record_fields.get("source_path", ""))]
	)


func _active_diagnostics_session() -> Dictionary:
	var result := {
		"package_id": "",
		"package_version": "",
		"content_schema_version": 0,
		"content_fingerprint": "",
		"campaign_id": ""
	}
	var dm := get_node_or_null("/root/DataManager") if is_inside_tree() else null
	if dm != null and dm.has_method("active_package_identity"):
		result.merge(dm.call("active_package_identity"), true)
	var cm := get_node_or_null("/root/CampaignManager") if is_inside_tree() else null
	if cm != null and "active_campaign_id" in cm:
		result["campaign_id"] = String(cm.get("active_campaign_id"))
	return result


func _diagnostic_identity(value: Variant, fallback: Variant = {}) -> Dictionary:
	var identity: Dictionary = value if value is Dictionary else {}
	var backup: Dictionary = fallback if fallback is Dictionary else {}
	return {
		"package_id": String(identity.get("package_id", backup.get("package_id", ""))),
		"package_version":
		String(identity.get("package_version", backup.get("package_version", ""))),
		"content_schema_version":
		int(identity.get("content_schema_version", backup.get("content_schema_version", 0))),
		"content_fingerprint":
		String(identity.get("content_fingerprint", backup.get("content_fingerprint", ""))),
	}


func _save_data_from_variant(source: Variant) -> RefCounted:
	if source is Dictionary:
		return SaveDataScript.from_dict(source)
	if source is Object and source.has_method("to_dict"):
		return SaveDataScript.from_dict(source.call("to_dict"))
	return null


func _ensure_save_dir() -> bool:
	var err := DirAccess.make_dir_recursive_absolute(save_dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error(
			"SaveManager: failed to create save dir '%s': %s" % [save_dir, error_string(err)]
		)
		return false
	return true


# The slot's picker row. The header is mirrored out of the save document so the
# load menu can list slots without opening (and validating) every save file.
#
# write_seq orders the rows, not saved_at_unix: the timestamp has whole-second
# resolution, so two saves written in the same second tie and "newest first"
# becomes arbitrary — including for the Continue fallback, which takes the first
# row. The counter is monotonic per save dir, so writes always order by when they
# actually happened. The timestamp stays for display.
func _slot_index_row(path: String, payload: Dictionary, index: Dictionary) -> Dictionary:
	return {
		"path": path,
		"label": String(payload.get("save_label", "")),
		"header": payload.get("header", {}),
		"origin": String(payload.get("origin", "manual")),
		"rule_id": String(payload.get("rule_id", "")),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"write_seq": _next_write_seq(index),
		"content_state": SaveRecoveryScript.STATE_READY,
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
	if _test_fail_before_index_replace or not _replace_staged(index_tmp, index_path, index_backup):
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


func _write_json_absolute(path: String, value: Dictionary) -> bool:
	var temporary := "%s.tmp-%d-%d" % [path, Time.get_ticks_usec(), OS.get_process_id()]
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(value, "\t", true))
	file.flush()
	file.close()
	return _promote_absolute_file(temporary, path)


func _promote_absolute_file(temporary: String, destination: String) -> bool:
	var backup := "%s.bak" % destination
	DirAccess.remove_absolute(backup)
	if FileAccess.file_exists(destination) and DirAccess.rename_absolute(destination, backup) != OK:
		DirAccess.remove_absolute(temporary)
		return false
	if DirAccess.rename_absolute(temporary, destination) == OK:
		DirAccess.remove_absolute(backup)
		return true
	if FileAccess.file_exists(backup):
		DirAccess.rename_absolute(backup, destination)
	DirAccess.remove_absolute(temporary)
	return false


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
	if (
		last_played is Dictionary
		and String(last_played.get("kind", "")) == LAST_PLAYED_SLOT
		and String(last_played.get("slot_id", "")) == slot_id
	):
		index.erase("last_played")
	return _write_index(index)


static func _slots_from_index(index: Dictionary) -> Dictionary:
	var slots: Variant = index.get("slots", {})
	return slots.duplicate(true) if slots is Dictionary else {}


func _write_index(index: Dictionary) -> bool:
	if not _ensure_save_dir():
		return false
	var file := FileAccess.open(get_index_path(), FileAccess.WRITE)
	if file == null:
		push_error(
			(
				"SaveManager: failed to open saves index for write: %s"
				% error_string(FileAccess.get_open_error())
			)
		)
		return false
	file.store_string(JSON.stringify(index, "\t", true))
	file.close()
	return true


func _parse_json_dict(text: String, path: String) -> Dictionary:
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error(
			(
				"SaveManager: failed to parse JSON '%s' at line %d: %s"
				% [path, json.get_error_line(), json.get_error_message()]
			)
		)
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
