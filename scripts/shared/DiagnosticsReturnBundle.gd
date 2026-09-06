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

# How much of user://logs a bundle may carry, newest first. Applied to godot*.log
# and diagnostics-*.log alike: both are per-session families that accumulate, and a
# bound on one of them only is what produced the v0.7.17 asymmetry (see
# _source_files).
const MAX_LOGS_PER_FAMILY := 12
const MAX_LOG_BYTES_PER_FAMILY := 24 * 1024 * 1024


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

	# TWO counts, never one. `diagnostic_error_count` was a single number and it read
	# 0 against four engine ERROR: lines, which is what let the v0.7.17 session end
	# without an automatic bundle. A channel error is a record a subscriber
	# classified; an engine error is a line Godot printed, possibly from another
	# process sharing this user://. Collapsing them loses the distinction that
	# decides which of the two is worth chasing.
	var engine_errors := engine_error_counts()
	var engine_error_total := 0
	for counted: int in engine_errors.values():
		engine_error_total += counted
	var bundle_manifest := {
		"format_version": 2,
		"created_at_utc": "%sZ" % Time.get_datetime_string_from_system(true),
		"reason": reason,
		"build": build,
		"channel_error_count": diagnostics.error_count() if diagnostics != null else 0,
		"engine_error_count": engine_error_total,
		"engine_error_sources": engine_errors,
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


# WHY EVERY DIAGNOSTICS LOG, NOT JUST THIS PROCESS'S (V0717-09).
#
# DiagnosticsLog names its file diagnostics-<stamp>-<pid>.log and opens it with
# FileAccess.WRITE, so the file is PER PROCESS. This used to collect every
# godot*.log but only `path == current_diagnostics_path`, and the asymmetry is what
# disguised the loss: the text log was complete, so every launch was visible while
# its structured records were not.
#
# The v0.7.17 session had SIX boots (godot.log records started_at 17:31:04,
# 17:44:58, 18:07:04, 18:20:14, 18:21:15, 18:22:00) and the bundle returned ONE
# diagnostics log. The exporting process booted 17:31:04 and was still alive at
# 18:27:03 (MANIFEST.created_at_utc, last record t=3,353,978 ms), so at least two
# instances ran concurrently against one user:// — and the records for the launch
# that raised V0717-03 were never returned. A return can look complete while the
# failure it was collected to explain is missing from it.
#
# `current_diagnostics_path` is still taken, and still admitted first, so the
# exporting process's own log survives the bound even in a directory full of older
# ones.
static func _source_files(current_diagnostics_path: String = "") -> Dictionary:
	var sources := {}
	var godot_logs: Array[String] = []
	var diagnostics_logs: Array[String] = []
	for path in _files_in_dir(LOG_DIR):
		var filename := path.get_file()
		if filename.get_extension().to_lower() != "log":
			continue
		if filename.begins_with("godot"):
			godot_logs.append(path)
		elif filename.begins_with("diagnostics-"):
			diagnostics_logs.append(path)
	for path in _bounded_newest_first(godot_logs, ""):
		sources["godot_logs/%s" % path.get_file()] = path
	for path in _bounded_newest_first(diagnostics_logs, current_diagnostics_path):
		sources["diagnostics_logs/%s" % path.get_file()] = path

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


# Newest first, capped by count and by total bytes, with `always_first` admitted
# ahead of the sort so the exporting process's own log can never be the one the
# bound drops.
static func _bounded_newest_first(paths: Array[String], always_first: String) -> Array[String]:
	var ordered := paths.duplicate()
	ordered.sort_custom(
		func(a: String, b: String) -> bool:
			return FileAccess.get_modified_time(a) > FileAccess.get_modified_time(b)
	)
	if not always_first.is_empty() and ordered.has(always_first):
		ordered.erase(always_first)
		ordered.insert(0, always_first)
	var kept: Array[String] = []
	var total := 0
	for path in ordered:
		if kept.size() >= MAX_LOGS_PER_FAMILY:
			break
		var size := 0
		var handle := FileAccess.open(path, FileAccess.READ)
		if handle != null:
			size = handle.get_length()
			handle.close()
		if not kept.is_empty() and total + size > MAX_LOG_BYTES_PER_FAMILY:
			break
		kept.append(path)
		total += size
	return kept


# Engine errors per godot*.log, counted at bundle time. They never pass through
# DiagnosticsLog, so nothing in process can report them; and with concurrent
# instances sharing one godot.log, a count is per FILE rather than per process,
# which is why the breakdown is reported rather than only the total.
static func engine_error_counts() -> Dictionary:
	var counts := {}
	for path in _files_in_dir(LOG_DIR):
		var filename := path.get_file()
		if not filename.begins_with("godot") or filename.get_extension().to_lower() != "log":
			continue
		var text := FileAccess.get_file_as_string(path)
		if text.is_empty():
			continue
		var counted := 0
		for line in text.split("\n", false):
			if line.begins_with("ERROR:") or line.contains(" ERROR:"):
				counted += 1
		counts[filename] = counted
	return counts


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
