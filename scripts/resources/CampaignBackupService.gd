class_name CampaignBackupService extends RefCounted
# adopter-todo: IMPL-PACK-SAVE-EXPORTS
# Pack-save Slice 3, stage 3B: writing a full backup.
#
# A backup is assembled from surfaces that already exist and already validate their
# own output. Packs come from the ordinary clean-pack exporter, so the admitted set
# is derived from validated catalogue data and user state cannot leak into an
# installable pack. Saves and status records are copied VERBATIM: a save's bytes are
# what the save resolver later has to agree with, and re-serializing them here would
# quietly re-normalize a document against whatever catalogue happens to be loaded.
#
# BackupEnvelope owns the shape; this file owns bytes, budgets and the temporary
# files. Restore (stage 3D) is a separate entry point and shares nothing but the
# envelope.

const Envelope = preload("res://scripts/save/BackupEnvelope.gd")
const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Exporter = preload("res://scripts/resources/CampaignPackExporter.gd")
const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const StatusStore = preload("res://scripts/resources/CampaignStatusStore.gd")
const Budgets = preload("res://scripts/resources/ImportBudgets.gd")

const STAGING_DIR := "user://.backup_staging"


class ExportResult:
	extends RefCounted
	var exported := false
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var archive_path := ""
	var manifest: Dictionary = {}
	var user_state: Dictionary = {}
	var total_bytes := 0


var _storage_root: String
var _status_root: String
var _save_manager: Object


# The three roots are injected rather than read from constants so a test can run a
# whole backup against its own directories without touching the player's library.
func _init(
	storage_root: String = Registry.DEFAULT_STORAGE_ROOT,
	save_manager: Object = null,
	status_root: String = StatusStore.DEFAULT_ROOT
) -> void:
	_storage_root = storage_root.trim_suffix("/")
	_status_root = status_root.trim_suffix("/")
	_save_manager = save_manager


# --- What a backup could contain ----------------------------------------------


# The selection surface. Ids only: the UI needs to offer components before any bytes
# are read, and reading a whole library to draw a checklist would be wasteful.
func available_components() -> Dictionary:
	var packages: Array[Dictionary] = []
	for summary in Registry.new(_storage_root).refresh():
		(
			packages
			. append(
				{
					"package_id": String(summary["package_id"]),
					"package_version": String(summary["package_version"]),
					"path": String(summary["path"]),
				}
			)
		)
	# Saves carry origin and rule_id because a restored autosave must land back in
	# the pool it belonged to, and the slot index is the only place that pairing
	# exists once the document is out of the save directory.
	var saves: Array[Dictionary] = []
	if _save_manager != null and _save_manager.has_method("list_slots"):
		for row in _save_manager.call("list_slots"):
			(
				saves
				. append(
					{
						"slot_id": String(row.get("slot_id", "")),
						"origin": String(row.get("origin", "manual")),
						"rule_id": String(row.get("rule_id", "")),
					}
				)
			)
		saves.sort_custom(func(a, b): return String(a["slot_id"]) < String(b["slot_id"]))
	var record_ids: Array[String] = []
	for name in _status_record_names():
		record_ids.append(name.trim_suffix(".json"))
	record_ids.sort()
	return {"packages": packages, "saves": saves, "record_ids": record_ids}


func _status_record_names() -> Array[String]:
	var names: Array[String] = []
	var directory := DirAccess.open(_status_root)
	if directory == null:
		return names
	for name in directory.get_files():
		if name.ends_with(".json"):
			names.append(name)
	names.sort()
	return names


# --- Export -------------------------------------------------------------------


# An EMPTY selection means "everything installed and stored". A selection that names
# any field is taken literally: fields it does not name contribute nothing. The
# alternative — treating an unnamed field as "all" — makes "back up just this save"
# silently write the whole library, which is the opposite of what was asked.
#
# A selection that names something absent is an error, never a silent omission: a
# backup that quietly drops the save the player chose is worse than one that refuses
# to be written.
func export_backup(destination_path: String, selection: Dictionary = {}) -> ExportResult:
	var result := ExportResult.new()
	result.archive_path = destination_path
	var available := available_components()
	var chosen := _resolve_selection(available, selection, result.errors)
	if not result.errors.is_empty():
		return result
	if (
		chosen["packages"].is_empty()
		and chosen["saves"].is_empty()
		and chosen["record_ids"].is_empty()
	):
		result.errors.append("There is nothing to back up yet.")
		return result

	var staging := _unique_staging_path()
	if DirAccess.make_dir_recursive_absolute(staging) != OK:
		result.errors.append("The backup workspace could not be created.")
		return result
	# One exit path removes the workspace: every failure below returns through it.
	var payloads := _collect_payloads(chosen, staging, result)
	if not result.errors.is_empty():
		_remove_tree(staging)
		return result
	_enforce_budgets(payloads, result)
	if not result.errors.is_empty():
		_remove_tree(staging)
		return result
	if not _write_archive(payloads, staging, destination_path, result):
		_remove_tree(staging)
		return result
	_remove_tree(staging)
	result.exported = true
	return result


func _resolve_selection(
	available: Dictionary, selection: Dictionary, errors: Array[String]
) -> Dictionary:
	var packages: Array[Dictionary] = []
	var explicit := not selection.is_empty()
	var installed := {}
	for entry in available["packages"]:
		installed["%s|%s" % [entry["package_id"], entry["package_version"]]] = entry
	if selection.has("packages"):
		for wanted in selection["packages"]:
			var key := (
				"%s|%s"
				% [
					String(wanted.get("package_id", "")),
					String(wanted.get("package_version", "")),
				]
			)
			if not installed.has(key):
				errors.append("A selected campaign package is not installed.")
				continue
			packages.append(installed[key])
	elif not explicit:
		packages = available["packages"].duplicate(true)
	var saves := _resolve_saves(available["saves"], selection, explicit, errors)
	var record_ids := _resolve_ids(
		available["record_ids"], selection, explicit, "record_ids", "status record", errors
	)
	packages.sort_custom(
		func(a, b):
			return (
				"%s|%s" % [a["package_id"], a["package_version"]]
				< "%s|%s" % [b["package_id"], b["package_version"]]
			)
	)
	saves.sort_custom(func(a, b): return String(a["slot_id"]) < String(b["slot_id"]))
	record_ids.sort()
	return {"packages": packages, "saves": saves, "record_ids": record_ids}


func _resolve_saves(
	available: Array, selection: Dictionary, explicit: bool, errors: Array[String]
) -> Array[Dictionary]:
	var stored := {}
	for row in available:
		stored[String(row["slot_id"])] = row
	if not selection.has("slot_ids"):
		var all: Array[Dictionary] = []
		if not explicit:
			for row in available:
				all.append(row)
		return all
	var resolved: Array[Dictionary] = []
	for wanted in selection["slot_ids"]:
		var slot_id := String(wanted)
		if not stored.has(slot_id):
			errors.append("A selected save is no longer stored.")
			continue
		resolved.append(stored[slot_id])
	return resolved


func _resolve_ids(
	available: Array,
	selection: Dictionary,
	explicit: bool,
	field: String,
	label: String,
	errors: Array[String]
) -> Array[String]:
	var resolved: Array[String] = []
	if not selection.has(field):
		if not explicit:
			for id in available:
				resolved.append(String(id))
		return resolved
	for wanted in selection[field]:
		var id := String(wanted)
		if not id in available:
			errors.append("A selected %s is no longer stored." % label)
			continue
		resolved.append(id)
	return resolved


# Returns {archive_path: bytes} for every entry the archive will hold, including the
# two manifests. Building the whole map before writing anything is what makes the
# export atomic: a component that cannot be read fails the export, not the file.
func _collect_payloads(chosen: Dictionary, staging: String, result: ExportResult) -> Dictionary:
	var payloads := {}
	var components: Array[Dictionary] = []
	for entry in chosen["packages"]:
		var bytes := _export_clean_pack(entry, staging, result)
		if bytes.is_empty():
			return {}
		var component := Envelope.build_pack_component(
			String(entry["package_id"]), String(entry["package_version"]), bytes
		)
		if (
			not Envelope.is_safe_identity(String(component["package_id"]))
			or not (Envelope.is_safe_identity(String(component["package_version"])))
		):
			result.errors.append("An installed package has an identity a backup cannot store.")
			return {}
		payloads[component["path"]] = bytes
		components.append(component)

	var save_rows: Array[Dictionary] = []
	for row in chosen["saves"]:
		var slot_id := String(row["slot_id"])
		var bytes := _read_slot_bytes(slot_id, result)
		if bytes.is_empty():
			return {}
		var save_row := Envelope.build_save_row(
			slot_id, bytes, String(row.get("origin", "manual")), String(row.get("rule_id", ""))
		)
		payloads[save_row["path"]] = bytes
		save_rows.append(save_row)

	var status_rows: Array[Dictionary] = []
	for record_id in chosen["record_ids"]:
		var bytes := _read_file_bytes(_status_root.path_join("%s.json" % record_id))
		if bytes.is_empty():
			result.errors.append("A stored status record could not be read.")
			return {}
		var status_row := Envelope.build_status_row(record_id, bytes)
		payloads[status_row["path"]] = bytes
		status_rows.append(status_row)

	if not save_rows.is_empty() or not status_rows.is_empty():
		var user_state := Envelope.build_user_state_manifest(save_rows, status_rows)
		var user_state_bytes := _json_bytes(user_state)
		payloads[Envelope.USER_STATE_MANIFEST_PATH] = user_state_bytes
		components.append(Envelope.build_user_state_component(user_state_bytes))
		result.user_state = user_state

	var manifest := Envelope.build_manifest(components, Time.get_datetime_string_from_system(true))
	payloads[Envelope.MANIFEST_PATH] = _json_bytes(manifest)
	result.manifest = manifest
	return payloads


# The clean-pack exporter is the ONLY producer of pack bytes here. Reusing it is what
# makes "a backup contains no user state inside a pack" true by construction rather
# than by a second rule this file would have to keep in step.
func _export_clean_pack(
	entry: Dictionary, staging: String, result: ExportResult
) -> PackedByteArray:
	var archive := staging.path_join("%s-%s.zip" % [entry["package_id"], entry["package_version"]])
	var exported = Exporter.new().export_zip(String(entry["path"]), archive, _pack_limits())
	if not exported.exported:
		result.errors.append(
			"Campaign package '%s' could not be prepared for backup." % entry["package_id"]
		)
		result.errors.append_array(exported.errors)
		return PackedByteArray()
	var bytes := _read_file_bytes(archive)
	if bytes.is_empty():
		result.errors.append("A prepared campaign package could not be read back.")
	return bytes


func _read_slot_bytes(slot_id: String, result: ExportResult) -> PackedByteArray:
	if _save_manager == null or not _save_manager.has_method("get_slot_path"):
		result.errors.append("Saves are not available to back up.")
		return PackedByteArray()
	var path := String(_save_manager.call("get_slot_path", slot_id))
	if path.is_empty():
		result.errors.append("A selected save has an unusable identifier.")
		return PackedByteArray()
	var bytes := _read_file_bytes(path)
	if bytes.is_empty():
		result.errors.append("A stored save could not be read.")
	return bytes


func _enforce_budgets(payloads: Dictionary, result: ExportResult) -> void:
	if payloads.size() > Budgets.BACKUP_ARCHIVE_MAX_ENTRIES:
		result.errors.append("This backup would contain too many files.")
		return
	var total := 0
	for path in payloads:
		var size: int = payloads[path].size()
		if size > Budgets.BACKUP_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES:
			result.errors.append("A component of this backup is too large to store.")
			return
		total += size
	if total > Budgets.BACKUP_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES:
		result.errors.append("This backup would be larger than the supported limit.")
		return
	result.total_bytes = total
	if total > Budgets.BACKUP_ARCHIVE_WARNING_BYTES:
		result.warnings.append(
			"This backup is large (%s); writing it may take a moment." % String.humanize_size(total)
		)


# Entries are written in sorted path order so two backups of the same state differ
# only in each entry's modification stamp, which Godot's ZIPPacker writes itself and
# offers no way to set.
func _write_archive(
	payloads: Dictionary, staging: String, destination_path: String, result: ExportResult
) -> bool:
	var temporary := staging.path_join("backup.zip")
	var packer := ZIPPacker.new()
	var open_error := packer.open(temporary, ZIPPacker.APPEND_CREATE)
	if open_error != OK:
		result.errors.append("The backup file could not be created.")
		return false
	var paths := payloads.keys()
	paths.sort()
	var wrote := true
	for path in paths:
		if packer.start_file(String(path)) != OK:
			result.errors.append("The backup file could not be assembled.")
			wrote = false
			break
		packer.write_file(payloads[path])
		packer.close_file()
	packer.close()
	if not wrote:
		return false
	if DirAccess.make_dir_recursive_absolute(destination_path.get_base_dir()) != OK:
		result.errors.append("The backup destination could not be created.")
		return false
	return _promote_with_rollback(temporary, destination_path, result.errors)


# --- Shared helpers -----------------------------------------------------------


static func _pack_limits() -> Preflight.Limits:
	return Preflight.Limits.new(
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRIES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES
	)


static func _json_bytes(value: Dictionary) -> PackedByteArray:
	return (JSON.stringify(value, "  ", false) + "\n").to_utf8_buffer()


static func _read_file_bytes(path: String) -> PackedByteArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	return file.get_buffer(file.get_length())


static func _promote_with_rollback(
	temporary: String, destination: String, errors: Array[String]
) -> bool:
	var backup := destination + ".bak"
	DirAccess.remove_absolute(backup)
	if FileAccess.file_exists(destination) and DirAccess.rename_absolute(destination, backup) != OK:
		errors.append("The previous backup at that location could not be replaced.")
		return false
	if DirAccess.rename_absolute(temporary, destination) == OK:
		DirAccess.remove_absolute(backup)
		return true
	if FileAccess.file_exists(backup):
		DirAccess.rename_absolute(backup, destination)
	errors.append("The backup could not be finalized.")
	return false


func _unique_staging_path() -> String:
	return STAGING_DIR.path_join("%d-%d" % [Time.get_ticks_usec(), OS.get_process_id()])


static func _remove_tree(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(name))
	for name in directory.get_directories():
		_remove_tree(path.path_join(name))
	DirAccess.remove_absolute(path)


# --- Inspect (stage 3C) -------------------------------------------------------
#
# Reading a backup is a pure question: what is in this file, and is it intact? It
# never installs, never writes a slot and never touches the library. Restore (3D)
# calls it first and commits only after it, so a malformed archive is rejected before
# anything on disk has changed.


class InspectResult:
	extends RefCounted
	var valid := false
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var artifact_kind := Envelope.ARTIFACT_UNKNOWN
	var manifest: Dictionary = {}
	var user_state: Dictionary = {}
	var payloads: Dictionary = {}


func inspect_backup(archive_path: String) -> InspectResult:
	var result := InspectResult.new()
	var file := FileAccess.open(archive_path, FileAccess.READ)
	if file == null:
		result.errors.append("The selected backup could not be opened.")
		return result
	# The outer budget is enforced BEFORE the bytes are buffered. Per-entry limits
	# cannot protect memory that the whole file has already been read into.
	var size := file.get_length()
	if size > Budgets.BACKUP_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES:
		result.errors.append("The selected backup exceeds the supported size limit.")
		return result
	var bytes := file.get_buffer(size)
	if not Envelope.looks_like_zip(bytes):
		# Classify before complaining: a player who picked a save or a renamed
		# envelope should be told what they picked, not that it is "not a backup".
		result.artifact_kind = Envelope.classify_document(
			JSON.parse_string(bytes.get_string_from_utf8())
		)
		result.errors.append(_wrong_artifact_text(result.artifact_kind))
		return result

	var entries := Preflight.read_central_directory(bytes, result.errors)
	if not result.errors.is_empty():
		result.errors.append("The selected backup is not a readable archive.")
		return result
	var names: Array = []
	for entry in entries:
		names.append(String(entry.get("path", "")))
	result.artifact_kind = Envelope.classify_archive_entries(names)
	if result.artifact_kind != Envelope.ARTIFACT_CAMPAIGN_BACKUP:
		result.errors.append(_wrong_artifact_text(result.artifact_kind))
		return result
	_validate_entries(entries, result)
	if not result.errors.is_empty():
		return result

	result.payloads = _read_payloads(archive_path, entries, result)
	if not result.errors.is_empty():
		return result
	_validate_envelope(result)
	result.valid = result.errors.is_empty()
	return result


static func _wrong_artifact_text(kind: String) -> String:
	match kind:
		Envelope.ARTIFACT_CAMPAIGN_PACK:
			return "This file is a campaign package, not a backup. Import it from Manage Campaigns."
		Envelope.ARTIFACT_PORTABLE_SAVE:
			return "This file is a single save, not a backup. Import it from Load Game."
		_:
			return "This file is not a campaign backup."


func _validate_entries(entries: Array[Dictionary], result: InspectResult) -> void:
	if entries.size() > Budgets.BACKUP_ARCHIVE_MAX_ENTRIES:
		result.errors.append("The selected backup contains too many files.")
		return
	var exact := {}
	var folded := {}
	var total := 0
	for entry in entries:
		var path := String(entry.get("path", ""))
		if not Preflight.is_safe_archive_path(path):
			result.errors.append("The selected backup contains an unsafe file path.")
			return
		var file_type := String(entry.get("file_type", "file"))
		if not file_type in ["file", "directory"]:
			result.errors.append("The selected backup contains a file type that cannot be read.")
			return
		var normalized := path.trim_suffix("/")
		if exact.has(normalized):
			result.errors.append("The selected backup stores the same path twice.")
			return
		exact[normalized] = true
		var case_key := normalized.to_lower()
		if folded.has(case_key):
			result.errors.append("The selected backup stores two paths that differ only in case.")
			return
		folded[case_key] = true
		var uncompressed := int(entry.get("uncompressed_size", 0))
		var compressed := int(entry.get("compressed_size", 0))
		if (
			uncompressed < 0
			or compressed < 0
			or uncompressed > Budgets.BACKUP_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES
		):
			result.errors.append("The selected backup contains a component that is too large.")
			return
		total += uncompressed
	if total > Budgets.BACKUP_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES:
		result.errors.append("The selected backup expands beyond the supported size limit.")


func _read_payloads(
	archive_path: String, entries: Array[Dictionary], result: InspectResult
) -> Dictionary:
	var reader := ZIPReader.new()
	if reader.open(archive_path) != OK:
		result.errors.append("The selected backup could not be read.")
		return {}
	var payloads := {}
	for entry in entries:
		if bool(entry.get("is_directory", false)):
			continue
		var path := String(entry["path"])
		var payload: PackedByteArray = reader.read_file(path)
		# A short read means the declared size and the stored bytes disagree, which
		# is exactly the condition digests exist to catch.
		if payload.size() != int(entry.get("uncompressed_size", 0)):
			result.errors.append("A component of the selected backup could not be read whole.")
			break
		payloads[path] = payload
	reader.close()
	return payloads


func _validate_envelope(result: InspectResult) -> void:
	if not result.payloads.has(Envelope.MANIFEST_PATH):
		result.errors.append("The selected backup has no envelope.")
		return
	var manifest := Envelope.parse_manifest(
		JSON.parse_string(result.payloads[Envelope.MANIFEST_PATH].get_string_from_utf8()),
		result.errors
	)
	if manifest.is_empty():
		return
	result.manifest = manifest
	for component in manifest["components"]:
		if not _verify_component(component, "path", result):
			return
	var state_component := Envelope.user_state_component(manifest)
	if not state_component.is_empty():
		var user_state := Envelope.parse_user_state_manifest(
			JSON.parse_string(
				result.payloads[Envelope.USER_STATE_MANIFEST_PATH].get_string_from_utf8()
			),
			result.errors
		)
		if user_state.is_empty():
			return
		result.user_state = user_state
		for row in user_state["saves"]:
			if not _verify_component(row, "path", result):
				return
		for row in user_state["status_records"]:
			if not _verify_component(row, "path", result):
				return
	# Anything the envelope does not account for is content nobody validated. It is
	# refused rather than ignored: silently skipping it would let a backup carry
	# payload that a later reader might decide to trust.
	var accounted := {}
	for path in Envelope.accounted_paths(result.manifest, result.user_state):
		accounted[path] = true
	for path in result.payloads:
		if not accounted.has(String(path)):
			result.errors.append("The selected backup contains a file nothing accounts for.")
			return


func _verify_component(row: Dictionary, path_field: String, result: InspectResult) -> bool:
	var path := String(row[path_field])
	if not result.payloads.has(path):
		result.errors.append("The selected backup is missing one of its own components.")
		return false
	var payload: PackedByteArray = result.payloads[path]
	if payload.size() != int(row["bytes"]) or Envelope.digest(payload) != String(row["sha256"]):
		result.errors.append("A component of the selected backup does not match its digest.")
		return false
	return true
