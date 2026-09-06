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
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const StatusRecord = preload("res://scripts/resources/CampaignStatusRecord.gd")
# For short_fingerprint() only. Refusal wording is SaveRecovery's job everywhere the
# player can read it, and a restore refusal is no different: a 64-hex digest in a
# dialog is not information, it is wallpaper.
const Recovery = preload("res://scripts/save/SaveRecovery.gd")

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


# The installed release's content identity, read through the SAME registry the
# library and the save resolver read. Computing it here instead would be a second
# definition of "what is installed", free to drift from the one that decides whether
# a save loads.
func _installed_identity(package_id: String, package_version: String) -> Dictionary:
	var registry := Registry.new(_storage_root)
	registry.refresh()
	return registry.find(package_id, package_version)


# --- Restore lifecycle records (V0717-08) -------------------------------------
#
# Across all 1,383 records the v0.7.17 return carried, there was no backup category
# and no restore action — so V0717-01 had to be argued from the ABSENCE of a
# `pack | install` record between two unrelated lines. That is sound only when the
# surrounding records happen to bracket the gap, and it can never say WHICH component
# was skipped or why.
#
# These use the existing `pack` and `save` categories rather than a new `backup` one.
# The category vocabulary lives in DiagnosticsLog and is being reworked by
# V0717-DIAGNOSTICS-CHANNEL-BUDGET-2026-09-06 in the same round; a restore package
# record IS a pack-lifecycle record, and putting it beside `pack | install` is what
# lets a reader follow one package through install, skip and activate on one grep.
func _diagnostics() -> Object:
	var tree := Engine.get_main_loop() as SceneTree
	var diagnostics := tree.root.get_node_or_null("DiagnosticsLog") if tree != null else null
	if diagnostics == null or not diagnostics.has_method("record"):
		return null
	return diagnostics


func _record_restore_package(
	outcome: String,
	component: Dictionary,
	preflight,
	installed_identity: Dictionary,
	reason_code: String
) -> void:
	var diagnostics := _diagnostics()
	if diagnostics == null:
		return
	var package_id := String(component.get("package_id", ""))
	var package_version := String(component.get("package_version", ""))
	# Both fingerprints, always — the pair is the whole point. A record carrying only
	# one of them cannot distinguish "already installed" from "a different build of
	# the same version is installed", which is the distinction V0717-01 turned on.
	var fields := {
		"outcome": outcome,
		"package": {"package_id": package_id, "package_version": package_version},
		"backup_content_fingerprint":
		"" if preflight == null else String(preflight.content_fingerprint),
		"installed_content_fingerprint": String(installed_identity.get("content_fingerprint", "")),
	}
	if not reason_code.is_empty():
		fields["reason_code"] = reason_code
	diagnostics.record(
		&"pack", &"restore_package", fields, "restore_package:%s:%s" % [package_id, package_version]
	)


func _record_restore_candidates(chosen: Dictionary, archive_path: String) -> void:
	var diagnostics := _diagnostics()
	if diagnostics == null:
		return
	var package_labels: Array[String] = []
	for component in chosen["packages"]:
		package_labels.append(
			"%s %s" % [component.get("package_id", ""), component.get("package_version", "")]
		)
	var slot_ids: Array[String] = []
	for row in chosen["saves"]:
		slot_ids.append(String(row.get("slot_id", "")))
	var record_ids: Array[String] = []
	for row in chosen["records"]:
		record_ids.append(String(row.get("record_id", "")))
	(
		diagnostics
		. record(
			&"pack",
			&"restore_candidates",
			{
				"outcome": "chosen",
				"source_path": archive_path,
				"packages": package_labels,
				"slots": slot_ids,
				"status_records": record_ids,
			},
			"restore_candidates:%s" % archive_path
		)
	)


func _record_restore_save(slot_id: String, outcome: String, inspection: Dictionary) -> void:
	var diagnostics := _diagnostics()
	if diagnostics == null:
		return
	var fields := {"outcome": outcome, "slot": slot_id}
	var content_state := String(inspection.get("content_state", ""))
	if not content_state.is_empty():
		fields["content_state"] = content_state
	var reason := String(inspection.get("reason", ""))
	if not reason.is_empty():
		fields["reason_code"] = reason
	var identity: Variant = inspection.get("saved_identity", {})
	if identity is Dictionary and not (identity as Dictionary).is_empty():
		fields["source"] = identity
	diagnostics.record(&"save", &"restore_save", fields, "restore_save:%s" % slot_id)


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


# The three budgets are parameters with a configured default, matching
# inspect_portable_save. A test cannot build a half-gigabyte archive, so the only way
# to prove the ceilings actually refuse anything is to hand it small ones.
func inspect_backup(
	archive_path: String,
	max_entries: int = -1,
	max_entry_bytes: int = -1,
	max_total_bytes: int = -1
) -> InspectResult:
	if max_entries < 0:
		max_entries = Budgets.BACKUP_ARCHIVE_MAX_ENTRIES
	if max_entry_bytes < 0:
		max_entry_bytes = Budgets.BACKUP_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES
	if max_total_bytes < 0:
		max_total_bytes = Budgets.BACKUP_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES
	var result := InspectResult.new()
	if max_entries < 1 or max_entry_bytes < 1 or max_total_bytes < max_entry_bytes:
		result.errors.append("Backup size limits are invalid.")
		return result
	var file := FileAccess.open(archive_path, FileAccess.READ)
	if file == null:
		result.errors.append("The selected backup could not be opened.")
		return result
	# The outer budget is enforced BEFORE the bytes are buffered. Per-entry limits
	# cannot protect memory that the whole file has already been read into.
	var size := file.get_length()
	if size > max_total_bytes:
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
	_validate_entries(entries, max_entries, max_entry_bytes, max_total_bytes, result)
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


func _validate_entries(
	entries: Array[Dictionary],
	max_entries: int,
	max_entry_bytes: int,
	max_total_bytes: int,
	result: InspectResult
) -> void:
	if entries.size() > max_entries:
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
		if uncompressed < 0 or compressed < 0 or uncompressed > max_entry_bytes:
			result.errors.append("The selected backup contains a component that is too large.")
			return
		total += uncompressed
	if total > max_total_bytes:
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


# --- Restore (stage 3D) -------------------------------------------------------
#
# Two phases, and the boundary between them is the whole point. Phase one validates
# every selected component through the validator that owns it — packs through the
# archive preflight, saves through the save inspection, status records through their
# own parser — and writes nothing. Phase two commits, and if any commit fails the
# snapshot taken beforehand puts the library, the save index and the status store
# back exactly as they were.
#
# The source archive is never modified, in either phase or in rollback.


class RestoreResult:
	extends RefCounted
	var restored := false
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var installed_packages: Array[Dictionary] = []
	var skipped_packages: Array[Dictionary] = []
	var restored_slots: Array[String] = []
	var restored_records: Array[String] = []
	# Set when the only thing standing in the way is saves that exist here now. The
	# caller offers Replace on this flag rather than pattern-matching an error string.
	var requires_replacement := false
	var occupied_slots: Array[String] = []


# Test seam only: named stages fail on demand so rollback can be proven rather than
# assumed. The installer carries the same seam for the same reason.
var fault_injector: Callable = Callable()


func restore_backup(
	archive_path: String, selection: Dictionary = {}, replace_existing: bool = false
) -> RestoreResult:
	var result := RestoreResult.new()
	var inspected := inspect_backup(archive_path)
	if not inspected.valid:
		result.errors.append_array(inspected.errors)
		return result
	var chosen := _resolve_restore_selection(inspected, selection, result.errors)
	if not result.errors.is_empty():
		return result
	if (
		chosen["packages"].is_empty()
		and chosen["saves"].is_empty()
		and chosen["records"].is_empty()
	):
		result.errors.append("No component of this backup was selected to restore.")
		return result

	var staging := _unique_staging_path()
	if DirAccess.make_dir_recursive_absolute(staging) != OK:
		result.errors.append("The restore workspace could not be created.")
		return result
	_record_restore_candidates(chosen, archive_path)
	var prepared := _validate_restore_candidates(
		inspected, chosen, staging, replace_existing, result
	)
	if not result.errors.is_empty():
		_remove_tree(staging)
		return result
	_commit_restore(prepared, replace_existing, result)
	_remove_tree(staging)
	result.restored = result.errors.is_empty()
	return result


func _resolve_restore_selection(
	inspected: InspectResult, selection: Dictionary, errors: Array[String]
) -> Dictionary:
	var explicit := not selection.is_empty()
	var packages: Array[Dictionary] = []
	var stored_packages := {}
	for component in Envelope.pack_components(inspected.manifest):
		stored_packages["%s|%s" % [component["package_id"], component["package_version"]]] = component
	if selection.has("packages"):
		for wanted in selection["packages"]:
			var key := (
				"%s|%s"
				% [String(wanted.get("package_id", "")), String(wanted.get("package_version", ""))]
			)
			if not stored_packages.has(key):
				errors.append("A selected campaign package is not in this backup.")
				continue
			packages.append(stored_packages[key])
	elif not explicit:
		for key in stored_packages:
			packages.append(stored_packages[key])

	var saves: Array[Dictionary] = []
	var stored_saves := {}
	for row in inspected.user_state.get("saves", []):
		stored_saves[String(row["slot_id"])] = row
	if selection.has("slot_ids"):
		for wanted in selection["slot_ids"]:
			if not stored_saves.has(String(wanted)):
				errors.append("A selected save is not in this backup.")
				continue
			saves.append(stored_saves[String(wanted)])
	elif not explicit:
		for key in stored_saves:
			saves.append(stored_saves[key])

	var records: Array[Dictionary] = []
	var stored_records := {}
	for row in inspected.user_state.get("status_records", []):
		stored_records[String(row["record_id"])] = row
	if selection.has("record_ids"):
		for wanted in selection["record_ids"]:
			if not stored_records.has(String(wanted)):
				errors.append("A selected status record is not in this backup.")
				continue
			records.append(stored_records[String(wanted)])
	elif not explicit:
		for key in stored_records:
			records.append(stored_records[key])

	packages.sort_custom(func(a, b): return String(a["path"]) < String(b["path"]))
	saves.sort_custom(func(a, b): return String(a["slot_id"]) < String(b["slot_id"]))
	records.sort_custom(func(a, b): return String(a["record_id"]) < String(b["record_id"]))
	return {"packages": packages, "saves": saves, "records": records}


# Phase one. Every candidate is proven acceptable to the surface that will receive
# it, and the only thing written is inside the staging directory.
func _validate_restore_candidates(
	inspected: InspectResult,
	chosen: Dictionary,
	staging: String,
	replace_existing: bool,
	result: RestoreResult
) -> Dictionary:
	var packages: Array[Dictionary] = []
	for component in chosen["packages"]:
		var package_id := String(component["package_id"])
		var package_version := String(component["package_version"])
		var installed := Registry.installed_path(_storage_root, package_id, package_version)
		var already_installed := DirAccess.dir_exists_absolute(installed)

		# Every component is staged and preflighted, INCLUDING one whose id and version
		# are already installed. Until V0717-01 an installed directory short-circuited
		# here on id and version alone, on the strength of a comment asserting that
		# "same id AND version is the same release by definition of the library's
		# identity rules". Nothing enforced that. The identity the library keys on is
		# coarser than the identity a save is validated against
		# (id|version|content_fingerprint), so a pack edited without a version bump
		# collided silently: the saves restored against whatever content happened to be
		# installed, every one failed revalidation, and the player was told to reinstall
		# a version that was already there. Staging costs one temporary file; not
		# staging cost the v0.7.17 round its Section 4.
		var staged := staging.path_join("%s-%s.zip" % [package_id, package_version])
		if not _write_bytes(staged, inspected.payloads[String(component["path"])]):
			result.errors.append("A campaign package could not be prepared for restore.")
			return {}
		var preflight = Preflight.inspect_zip(staged, _pack_limits())
		if not preflight.valid:
			result.errors.append(
				"Campaign package '%s' in this backup cannot be installed." % package_id
			)
			result.errors.append_array(preflight.errors)
			return {}
		if preflight.package_id != package_id:
			result.errors.append("A campaign package in this backup does not match its label.")
			return {}

		if already_installed:
			var installed_identity := _installed_identity(package_id, package_version)
			var installed_fingerprint := String(installed_identity.get("content_fingerprint", ""))
			if installed_fingerprint.is_empty():
				# The library cannot say what is installed, so nothing here can say the
				# restore is safe. Refusing is the only honest answer: overwriting would
				# discard content this service never read.
				_record_restore_package(
					"refused", component, preflight, installed_identity, "installed_unreadable"
				)
				(
					result
					. errors
					. append(
						(
							(
								"A campaign package named '%s' v%s is already installed, but it could "
								+ "not be read. Repair or remove it from Manage Campaigns, then restore "
								+ "again."
							)
							% [package_id, package_version]
						)
					)
				)
				return {}
			if installed_fingerprint != String(preflight.content_fingerprint):
				# The one place with enough information to say something true. Both
				# fingerprints are in hand, so the refusal names the conflict instead of
				# repeating an instruction the player has already followed. Installing the
				# backup's copy side-by-side is the destination (SAVE-IDENTITY-BLOCK-
				# UNIFICATION-2026-09-05); it needs a library identity that carries the
				# fingerprint, which this round deliberately does not add.
				_record_restore_package(
					"refused", component, preflight, installed_identity, "fingerprint_mismatch"
				)
				(
					result
					. errors
					. append(
						(
							(
								"The installed '%s' v%s is a different build from the one in this "
								+ "backup. Installed content: %s. Backup content: %s. Restoring would "
								+ "leave every save in this backup unopenable, so nothing was changed. "
								+ "Remove the installed copy from Manage Campaigns first, or restore "
								+ "only the saves once the matching build is installed."
							)
							% [
								package_id,
								package_version,
								Recovery.short_fingerprint(installed_fingerprint),
								Recovery.short_fingerprint(String(preflight.content_fingerprint)),
							]
						)
					)
				)
				return {}
			# Same id, same version, same content: genuinely already where restore would
			# put it, and reinstalling it would be pure churn.
			result.skipped_packages.append(
				{"package_id": package_id, "package_version": package_version}
			)
			_record_restore_package("skipped", component, preflight, installed_identity, "")
			continue

		(
			packages
			. append(
				{
					"package_id": package_id,
					"package_version": package_version,
					"archive": staged,
					"preflight": preflight,
					"installed_path": installed,
				}
			)
		)

	var saves: Array[Dictionary] = []
	var occupied: Array[String] = []
	for row in chosen["saves"]:
		var slot_id := String(row["slot_id"])
		if _save_manager == null or not _save_manager.has_method("inspect_portable_save"):
			result.errors.append("Saves cannot be restored here.")
			return {}
		var staged_save := staging.path_join("%s.json" % slot_id)
		if not _write_bytes(staged_save, inspected.payloads[String(row["path"])]):
			result.errors.append("A save could not be prepared for restore.")
			return {}
		var inspection: Dictionary = _save_manager.call("inspect_portable_save", staged_save)
		# Structure is the hard boundary here, exactly as on import. A save whose
		# package is missing is NOT a failure: it restores disabled, and installing
		# the package promotes it.
		if not bool(inspection.get("ok", false)):
			_record_restore_save(slot_id, "refused", inspection)
			result.errors.append("A save in this backup could not be read.")
			result.errors.append_array(inspection.get("errors", []))
			return {}
		_record_restore_save(slot_id, "accepted", inspection)
		if bool(_save_manager.call("has_slot", slot_id)):
			occupied.append(slot_id)
		saves.append({"slot_id": slot_id, "inspection": inspection, "row": row})
	if not occupied.is_empty() and not replace_existing:
		result.requires_replacement = true
		result.occupied_slots = occupied.duplicate()
		result.errors.append(
			(
				"%d save(s) in this backup already exist here. Choose Replace to overwrite them."
				% occupied.size()
			)
		)
		return {}

	var records: Array[Dictionary] = []
	for row in chosen["records"]:
		var record_id := String(row["record_id"])
		var document: Variant = JSON.parse_string(
			inspected.payloads[String(row["path"])].get_string_from_utf8()
		)
		var record_errors: Array[String] = []
		if StatusRecord.from_dict(document, record_errors) == null:
			result.errors.append("A campaign status record in this backup is unusable.")
			result.errors.append_array(record_errors)
			return {}
		(
			records
			. append(
				{
					"record_id": record_id,
					"bytes": inspected.payloads[String(row["path"])],
					"path": _status_root.path_join("%s.json" % record_id),
				}
			)
		)
	return {"packages": packages, "saves": saves, "records": records, "occupied": occupied}


# Phase two. Everything below is undoable, and the snapshot is taken before the first
# write so a failure at any point restores the state that existed at entry.
func _commit_restore(prepared: Dictionary, replace_existing: bool, result: RestoreResult) -> void:
	var snapshot := _snapshot_targets(prepared)
	var installed_paths: Array[String] = []
	var installer := Installer.new(_storage_root)
	for entry in prepared["packages"]:
		var installed = installer.install_zip(entry["archive"], entry["preflight"])
		if not installed.installed or _fault("package_installed"):
			result.errors.append(
				"Campaign package '%s' could not be installed." % entry["package_id"]
			)
			result.errors.append_array(installed.errors)
			installed_paths.append(String(entry["installed_path"]))
			_rollback_restore(snapshot, installed_paths)
			return
		installed_paths.append(String(entry["installed_path"]))
		(
			result
			. installed_packages
			. append(
				{
					"package_id": entry["package_id"],
					"package_version": entry["package_version"],
				}
			)
		)

	for entry in prepared["saves"]:
		var slot_id := String(entry["slot_id"])
		if replace_existing and bool(_save_manager.call("has_slot", slot_id)):
			_save_manager.call("delete_slot", slot_id)
		var written: Dictionary = _save_manager.call(
			"restore_slot",
			slot_id,
			entry["inspection"],
			String(entry["row"].get("origin", "manual")),
			String(entry["row"].get("rule_id", ""))
		)
		if not bool(written.get("ok", false)) or _fault("slot_restored"):
			result.errors.append("A save from this backup could not be written.")
			result.errors.append_array(written.get("errors", []))
			_rollback_restore(snapshot, installed_paths)
			return
		result.restored_slots.append(slot_id)

	if not prepared["records"].is_empty():
		if DirAccess.make_dir_recursive_absolute(_status_root) not in [OK, ERR_ALREADY_EXISTS]:
			result.errors.append("The campaign status directory could not be created.")
			_rollback_restore(snapshot, installed_paths)
			return
	for entry in prepared["records"]:
		if not _write_bytes(String(entry["path"]), entry["bytes"]) or _fault("record_restored"):
			result.errors.append("A campaign status record from this backup could not be written.")
			_rollback_restore(snapshot, installed_paths)
			return
		result.restored_records.append(String(entry["record_id"]))


# The save index is snapshotted whole. Individual slot rows are not independent —
# the index is the commit marker for every one of them — so restoring the file is
# what actually returns the save directory to its previous state.
func _snapshot_targets(prepared: Dictionary) -> Array[Dictionary]:
	var files: Array[String] = []
	if _save_manager != null and _save_manager.has_method("get_index_path"):
		files.append(String(_save_manager.call("get_index_path")))
	for entry in prepared["saves"]:
		files.append(String(_save_manager.call("get_slot_path", entry["slot_id"])))
	for entry in prepared["records"]:
		files.append(String(entry["path"]))
	var snapshot: Array[Dictionary] = []
	for path in files:
		(
			snapshot
			. append(
				{
					"path": path,
					"existed": FileAccess.file_exists(path),
					"bytes": _read_file_bytes(path),
				}
			)
		)
	return snapshot


func _rollback_restore(snapshot: Array[Dictionary], installed_paths: Array[String]) -> void:
	for path in installed_paths:
		_remove_tree(path)
		# The library nests <id>/<version>; leaving an empty id directory behind
		# would make the package look installed to a directory-name scan.
		var parent := String(path).get_base_dir()
		var directory := DirAccess.open(parent)
		if (
			directory != null
			and directory.get_files().is_empty()
			and (directory.get_directories().is_empty())
		):
			DirAccess.remove_absolute(parent)
	for entry in snapshot:
		var path := String(entry["path"])
		if bool(entry["existed"]):
			_write_bytes(path, entry["bytes"])
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fault(stage: String) -> bool:
	return fault_injector.is_valid() and bool(fault_injector.call(stage))


static func _write_bytes(path: String, bytes: PackedByteArray) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(bytes)
	file.close()
	return true


# --- Artifact naming at the import boundaries (stage 3E) ----------------------


# Cheap classification for an entry point that is about to hand a file to a
# validator it may not belong to. One central-directory parse is enough to stop a
# full backup being reported as a malformed campaign package, which sends the player
# to a screen that would refuse it too.
static func classify_archive_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return Envelope.ARTIFACT_UNKNOWN
	var size := file.get_length()
	if size > Budgets.BACKUP_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES:
		return Envelope.ARTIFACT_UNKNOWN
	var bytes := file.get_buffer(size)
	if not Envelope.looks_like_zip(bytes):
		return Envelope.classify_document(JSON.parse_string(bytes.get_string_from_utf8()))
	var errors: Array[String] = []
	var entries := Preflight.read_central_directory(bytes, errors)
	if not errors.is_empty():
		return Envelope.ARTIFACT_UNKNOWN
	var names: Array = []
	for entry in entries:
		names.append(String(entry.get("path", "")))
	return Envelope.classify_archive_entries(names)
