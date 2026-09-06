extends RefCounted
# Writes the single artifact a native tester returns after a diagnostics session.
#
# This intentionally copies only bounded, player-owned evidence: logs, build
# identity, the settings snapshot, save documents, and installed pack manifests.
# Pack payloads are never admitted, both to keep the return small and to avoid
# turning a support bundle into an accidental content export.

const BuildInfo = preload("res://scripts/shared/BuildInfo.gd")
const CampaignPackRegistry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const SaveManager = preload("res://scripts/autoloads/SaveManager.gd")

const BUNDLE_DIR := "user://diagnostics"
const LOG_DIR := "user://logs"
const SAVE_DIR := SaveManager.DEFAULT_SAVE_DIR
const MANIFEST_NAME := "MANIFEST.json"


static func write(diagnostics: Node, reason: String = "manual") -> Dictionary:
	var result := {"ok": false, "path": "", "absolute_path": "", "entries": [], "errors": []}
	result["reason"] = reason
	var bundle_dir := ProjectSettings.globalize_path(BUNDLE_DIR)
	if DirAccess.make_dir_recursive_absolute(bundle_dir) != OK:
		result.errors.append("The diagnostics directory could not be created.")
		return result

	var build := BuildInfo.load_info()
	var output_path := _output_path(String(build.get("version", "dev")))
	var temporary_path := (
		"%s.tmp-%d-%d"
		% [
			ProjectSettings.globalize_path(output_path),
			Time.get_ticks_usec(),
			OS.get_process_id(),
		]
	)
	var packer := ZIPPacker.new()
	var open_error := packer.open(temporary_path, ZIPPacker.APPEND_CREATE)
	if open_error != OK:
		result.errors.append(
			"The diagnostics archive could not be created: %s" % error_string(open_error)
		)
		return result

	var entries: Array[Dictionary] = []
	var seen: Dictionary = {}
	var errors: Array[String] = []
	_add_bytes(
		packer,
		"BUILD_INFO.json",
		JSON.stringify(build, "\t").to_utf8_buffer(),
		entries,
		seen,
		errors
	)
	_add_bytes(
		packer,
		"settings/settings_snapshot.json",
		_settings_bytes(diagnostics),
		entries,
		seen,
		errors
	)
	_add_bytes(
		packer, "diagnostics/records.json", _records_bytes(diagnostics), entries, seen, errors
	)

	var current_log := (
		String(diagnostics.file_path())
		if diagnostics != null and diagnostics.has_method("file_path")
		else ""
	)
	var source_files := _source_files(current_log)
	var source_paths: Array[String] = []
	for source_key: Variant in source_files.keys():
		source_paths.append(String(source_key))
	source_paths.sort()
	for entry_path in source_paths:
		var source_path := String(source_files[entry_path])
		_add_file(packer, entry_path, source_path, entries, seen, errors)

	var bundle_manifest := {
		"format_version": 1,
		"created_at_utc": "%sZ" % Time.get_datetime_string_from_system(true),
		"reason": reason,
		"build": build,
		"diagnostic_error_count": diagnostics.error_count() if diagnostics != null else 0,
		"entries": entries,
		"manifest": {"path": MANIFEST_NAME, "sha256": "self"},
	}
	_add_bytes(
		packer,
		MANIFEST_NAME,
		JSON.stringify(bundle_manifest, "\t").to_utf8_buffer(),
		entries,
		seen,
		errors
	)
	packer.close()

	if not errors.is_empty():
		DirAccess.remove_absolute(temporary_path)
		result.errors = errors
		return result
	var rename_error := DirAccess.rename_absolute(
		temporary_path, ProjectSettings.globalize_path(output_path)
	)
	if rename_error != OK:
		DirAccess.remove_absolute(temporary_path)
		result.errors.append(
			"The diagnostics archive could not be finalized: %s" % error_string(rename_error)
		)
		return result

	result.ok = true
	result.path = output_path
	result.absolute_path = ProjectSettings.globalize_path(output_path)
	result.entries = entries
	return result


static func _output_path(version: String) -> String:
	var safe_version := version.replace("/", "_").replace("\\", "_").replace(" ", "_")
	var stamp := Time.get_datetime_string_from_system(true).replace("-", "").replace(":", "")
	var base := "Prometheus_diagnostics_%s_%s" % [safe_version, stamp]
	var output := BUNDLE_DIR.path_join("%s.zip" % base)
	if FileAccess.file_exists(output):
		output = BUNDLE_DIR.path_join("%s-%d.zip" % [base, Time.get_ticks_usec()])
	return output


static func _settings_bytes(diagnostics: Node) -> PackedByteArray:
	var settings := (
		diagnostics.get_node_or_null("/root/SettingsManager") if diagnostics != null else null
	)
	var snapshot: Variant = (
		settings.call("snapshot") if settings != null and settings.has_method("snapshot") else {}
	)
	return JSON.stringify(snapshot, "\t").to_utf8_buffer()


static func _records_bytes(diagnostics: Node) -> PackedByteArray:
	var records: Array = (
		diagnostics.snapshot() if diagnostics != null and diagnostics.has_method("snapshot") else []
	)
	var counters: Dictionary = (
		diagnostics.counters() if diagnostics != null and diagnostics.has_method("counters") else {}
	)
	return JSON.stringify({"records": records, "counters": counters}, "\t").to_utf8_buffer()


static func _source_files(current_diagnostics_path: String = "") -> Dictionary:
	var sources := {}
	for path in _files_in_dir(LOG_DIR):
		var filename := path.get_file()
		if filename.begins_with("godot") and filename.get_extension().to_lower() == "log":
			sources["godot_logs/%s" % filename] = path
		elif (
			path == current_diagnostics_path
			and filename.begins_with("diagnostics-")
			and filename.get_extension().to_lower() == "log"
		):
			sources["diagnostics_logs/%s" % filename] = path

	for path in _files_in_dir(SAVE_DIR):
		if path.get_extension().to_lower() == "json":
			sources["saves/%s" % path.get_file()] = path

	var installed_root := CampaignPackRegistry.DEFAULT_STORAGE_ROOT.path_join(
		CampaignPackRegistry.INSTALLED_DIR
	)
	for path in _files_in_dir(installed_root):
		if path.get_file().to_lower() != CampaignPackRegistry.MANIFEST_PATH:
			continue
		var relative := path.trim_prefix(installed_root + "/").replace("\\", "/")
		sources["packs/%s" % relative] = path
	return sources


static func _files_in_dir(path: String) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := path.path_join(name)
		if directory.current_is_dir():
			result.append_array(_files_in_dir(child))
		else:
			result.append(child)
		name = directory.get_next()
	directory.list_dir_end()
	return result


static func _add_file(
	packer: ZIPPacker,
	entry_path: String,
	source_path: String,
	entries: Array[Dictionary],
	seen: Dictionary,
	errors: Array[String]
) -> void:
	if seen.has(entry_path) or not FileAccess.file_exists(source_path):
		return
	_add_bytes(packer, entry_path, FileAccess.get_file_as_bytes(source_path), entries, seen, errors)


static func _add_bytes(
	packer: ZIPPacker,
	entry_path: String,
	bytes: PackedByteArray,
	entries: Array[Dictionary],
	seen: Dictionary,
	errors: Array[String]
) -> void:
	if seen.has(entry_path):
		return
	var start_error := packer.start_file(entry_path)
	if start_error != OK:
		errors.append("Could not add '%s': %s" % [entry_path, error_string(start_error)])
		return
	packer.write_file(bytes)
	packer.close_file()
	seen[entry_path] = true
	(
		entries
		. append(
			{
				"path": entry_path,
				"size": bytes.size(),
				"sha256": _sha256(bytes),
			}
		)
	)


static func _sha256(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	return hashing.finish().hex_encode()
