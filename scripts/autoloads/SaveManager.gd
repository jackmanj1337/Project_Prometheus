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

const DEFAULT_SAVE_DIR := "user://saves"
const INDEX_FILENAME := "saves_index.json"
const LAST_PLAYED_SLOT := "slot"

const MID_MAP_SLOT := "resume_battle"
var save_dir: String = DEFAULT_SAVE_DIR

# Failure seam used only by the disk-transaction regression suite.
var _test_fail_before_index_replace := false


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
	var path := get_slot_path(slot_id)
	if path == "":
		push_error("SaveManager: invalid slot id '%s'" % slot_id)
		return false
	var save := _save_data_from_variant(source)
	if save == null:
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
			return false
	var errors: Array[String] = save.validate(_data_manager())
	if not errors.is_empty():
		_push_validation_errors("SaveManager: slot '%s' rejected" % slot_id, errors)
		return false
	var payload: Dictionary = SaveIntegrity.stamp(save.to_dict())
	if (
		origin == "manual"
		and not _manual_write_allowed(
			slot_id,
			String(payload.get("header", {}).get("save_kind", "between_map")),
			String(payload.get("header", {}).get("campaign_id", ""))
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
	return _commit_slot_transaction(path, payload, index)


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
		return null
	return _read_save_document(get_slot_path(slot_id), "slot '%s'" % slot_id)


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
		"ok": false, "errors": [], "warnings": [], "save": null, "artifact_kind": "unknown"
	}
	if warning_bytes < 0:
		warning_bytes = ImportBudgetConfig.portable_save_warning_bytes()
	if maximum_bytes < 0:
		maximum_bytes = ImportBudgetConfig.portable_save_maximum_bytes()
	if warning_bytes < 0 or maximum_bytes < 1 or warning_bytes > maximum_bytes:
		result["errors"].append("Portable-save import budgets are invalid.")
		return result
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		result["errors"].append("The selected file could not be opened.")
		return result
	var source_size := file.get_length()
	if source_size > maximum_bytes:
		result["errors"].append("The selected save exceeds the portable-save size limit.")
		return result
	if source_size > warning_bytes:
		result["warnings"].append(
			(
				"This save is unusually large (%s); verify its source before importing."
				% String.humanize_size(source_size)
			)
		)
	var bytes := file.get_buffer(source_size)
	if bytes.size() >= 4 and bytes.decode_u32(0) == 0x04034b50:
		result["artifact_kind"] = "campaign_pack"
		result["errors"].append(
			"This ZIP is a campaign package. Import it from New Game > Manage Campaigns."
		)
		return result
	result["artifact_kind"] = "save_json"
	var parsed := _parse_json_dict(bytes.get_string_from_utf8(), source_path)
	if parsed.is_empty():
		result["errors"].append("The selected file is not a campaign save JSON object.")
		return result
	result["warnings"].append_array(SaveIntegrity.verify(parsed))
	var save: RefCounted = SaveDataScript.from_dict(parsed)
	var errors: Array[String] = _validate_for_saved_content(save)
	if not errors.is_empty():
		result["errors"].append_array(errors)
		return result
	result["save"] = save
	result["ok"] = true
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
		return result
	if not result["warnings"].is_empty() and not acknowledge_warnings:
		result["ok"] = false
		result["requires_acknowledgement"] = true
		return result
	if not save_slot(slot_id, result["save"], "manual"):
		result["ok"] = false
		result["errors"].append("The imported save could not be stored in the selected slot.")
		return result
	result["ok"] = true
	return result


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
		return result
	if has_slot(destination_slot_id):
		result["ok"] = false
		result["errors"].append("migration_destination_slot_exists")
		return result
	if not save_slot(destination_slot_id, result["save"], "manual"):
		result["ok"] = false
		result["errors"].append("migration_commit_failed")
		return result
	return result


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


func _manual_write_allowed(slot_id: String, save_kind: String, scope: String) -> bool:
	var existing := _row_for_slot(slot_id)
	if not existing.is_empty():
		if String(existing.get("origin", "manual")) != "manual":
			push_error("SaveManager: manual save cannot replace an automatic pool slot")
			return false
		return true
	var budget := manual_slot_budget(save_kind, scope)
	if int(budget.get("class_index", -1)) < 0:
		push_error("SaveManager: save policy accepts no '%s' manual slots" % save_kind)
		return false
	if bool(budget.get("full", false)):
		push_error(
			"SaveManager: manual '%s' slot class is full for campaign '%s'" % [save_kind, scope]
		)
		return false
	return true


# Reports the manual-slot budget for a save kind within one campaign scope. The
# budget is scoped per-campaign so a save in one campaign never blocks saving in
# another (V053-04); single-map runs (campaign_id == "") form their own bucket.
# `scope` defaults to the active campaign id so the UI can query "can I save here
# now?"; the write path passes the campaign_id of the save being written so the
# count is self-consistent regardless of tree state. Public so the UI can explain
# a cap-full refusal instead of a bare "Save failed." Returns
# {cap, used, full, class_index, scope}; class_index < 0 means the policy accepts
# no manual slot of this kind.
func manual_slot_budget(save_kind: String, scope: Variant = null) -> Dictionary:
	var resolved_scope: String = String(scope) if scope != null else _active_campaign_scope()
	var classes := _active_slot_classes()
	var target_index := _class_index_for_kind(classes, save_kind)
	if target_index < 0:
		return {"cap": 0, "used": 0, "full": true, "class_index": -1, "scope": resolved_scope}
	var used := 0
	for row in list_slots():
		if String(row.get("origin", "manual")) != "manual":
			continue
		var header: Dictionary = row.get("header", {}) if row.get("header") is Dictionary else {}
		if String(header.get("campaign_id", "")) != resolved_scope:
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


# The active campaign id, used as the default manual-budget scope for UI queries.
# "" is the single-map / no-campaign bucket.
func _active_campaign_scope() -> String:
	if is_inside_tree():
		var cm := get_node_or_null("/root/CampaignManager")
		if cm != null and "active_campaign_id" in cm:
			return String(cm.get("active_campaign_id"))
	return ""


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


static func _row_is_resumable(row: Dictionary) -> bool:
	var header: Variant = row.get("header", {})
	return (
		header is Dictionary and String(header.get("campaign_state", "in_progress")) != "completed"
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
	var errors: Array[String] = _validate_for_saved_content(save)
	if not errors.is_empty():
		_push_validation_errors("SaveManager: %s failed validation" % label, errors)
		return null
	return save


# Inventory ids belong to the catalogue recorded by the save, not whichever
# catalogue happens to be active on the menu. Temporarily select that trusted,
# installed source for reference validation, then restore the prior source; the
# later GameState configure step performs the permanent transactional activation.
func _validate_for_saved_content(save: RefCounted) -> Array[String]:
	var structural: Array[String] = save.validate(null)
	if not structural.is_empty():
		return structural
	var dm := _data_manager()
	if dm == null or not dm.has_method("select_saved_campaign_source"):
		return save.validate(dm)
	var campaign: Dictionary = save.to_dict().get("campaign", {})
	var package_id := String(campaign.get("package_id", ""))
	var package_version := String(campaign.get("package_version", ""))
	var previous: Dictionary = dm.call("active_package_identity")
	if not bool(dm.call("select_saved_campaign_source", package_id, package_version)):
		return ["SaveData: saved campaign content could not be activated"]
	var errors: Array[String] = save.validate(dm)
	var restored := bool(
		dm.call(
			"select_saved_campaign_source",
			String(previous.get("package_id", "")),
			String(previous.get("package_version", ""))
		)
	)
	if not restored:
		errors.append("SaveData: prior campaign content could not be restored after validation")
	return errors


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
