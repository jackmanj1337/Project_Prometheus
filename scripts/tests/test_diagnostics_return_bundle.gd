extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_diagnostics_return_bundle.gd
#
# This drives the production DiagnosticsLog autoload and inspects a real ZIP. The
# important security assertion is negative: an installed pack's manifest is copied,
# but its catalogue or payload never crosses the return boundary.

var passed := 0
var failed := 0

const PACK_ROOT := "user://campaign_packs/installed/return_fixture/1.0"
const SAVE_ROOT := "user://saves"


func _init() -> void:
	print("=== Diagnostics Return Bundle Test ===")
	await process_frame
	var diagnostics: Node = root.get_node_or_null("DiagnosticsLog")
	if diagnostics == null:
		print("FAIL DiagnosticsLog autoload is unavailable")
		print("\n=== Results: 0 passed, 1 failed ===")
		quit(1)
		return

	_write_fixture_files()
	diagnostics.print_records = false
	diagnostics.reset()
	diagnostics.record_error(&"session", &"return_fixture_error", {"source": "test"})
	var result: Dictionary = diagnostics.export_return_bundle("test")
	_check(bool(result.get("ok", false)), "a diagnostics bundle is written", str(result))
	if not bool(result.get("ok", false)):
		_cleanup()
		print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
		quit(1)
		return

	var archive := _read_archive(String(result.get("path", "")))
	_check(
		archive.has("MANIFEST.json"), "the archive carries its own manifest", str(archive.keys())
	)
	_check(archive.has("BUILD_INFO.json"), "the archive carries BUILD_INFO", str(archive.keys()))
	_check(
		archive.has("settings/settings_snapshot.json"),
		"the archive carries the settings snapshot",
		str(archive.keys())
	)
	_check(
		archive.has("diagnostics/records.json"),
		"the archive carries structured diagnostics",
		str(archive.keys())
	)
	_check(
		_archive_has_prefix(archive, "diagnostics_logs/"),
		"the archive carries the diagnostics log file",
		str(archive.keys())
	)
	# V0717-09. This used to assert the OPPOSITE — that exactly one diagnostics log
	# was carried — which is the defect written down as a requirement. A diagnostics
	# log is per process (diagnostics-<stamp>-<pid>.log, opened WRITE), and the
	# v0.7.17 session had six boots and returned one log, so the records for the
	# launch that raised V0717-03 never came back while every godot*.log did.
	var diagnostics_logs := _archive_paths_with_prefix(archive, "diagnostics_logs/")
	var bundle_script := load("res://scripts/shared/DiagnosticsReturnBundle.gd")
	_check(
		(
			diagnostics_logs.size() >= 3
			and diagnostics_logs.size() <= int(bundle_script.MAX_LOGS_PER_FAMILY)
		),
		"every diagnostics log in user://logs is carried, up to the bound",
		str(diagnostics_logs)
	)
	# Both foreign logs, not just the newer one: an earlier boot and a concurrent
	# instance are the two shapes the v0.7.17 return lost.
	_check(
		(
			diagnostics_logs.has("diagnostics_logs/diagnostics-20260906T000000-4242.log")
			and diagnostics_logs.has("diagnostics_logs/diagnostics-20260905T235900-4141.log")
		),
		"logs written by other processes are carried",
		str(diagnostics_logs)
	)
	_check(
		_archive_has_prefix(archive, "diagnostics_logs/diagnostics-"),
		"the exporting process's own log is still among them",
		str(diagnostics_logs)
	)
	_check(
		archive.has("godot_logs/godot-return-test.log"),
		"the archive carries the Godot log files",
		str(archive.keys())
	)
	_check(
		archive.has("saves/saves_index.json") and archive.has("saves/slot_return.json"),
		"the archive carries save documents"
	)
	_check(
		archive.has("packs/return_fixture/1.0/manifest.json"),
		"the archive carries installed pack manifests",
		str(archive.keys())
	)
	_check(
		(
			not archive.has("packs/return_fixture/1.0/data/catalogue.json")
			and not archive.has("packs/return_fixture/1.0/data/private_payload.txt")
		),
		"the archive excludes installed pack payloads",
		str(archive.keys())
	)

	var manifest: Variant = JSON.parse_string(String(archive["MANIFEST.json"]))
	var manifest_entries: Array = manifest.get("entries", []) if manifest is Dictionary else []
	_check(
		(
			manifest is Dictionary
			and manifest.get("format_version", 0) == 2
			and manifest.get("manifest", {}).get("sha256", "") == "self"
			and manifest_entries.size() == archive.size() - 1
		),
		"the manifest describes every non-manifest archive entry",
		str(manifest)
	)
	_check(
		_manifest_hashes_match(manifest_entries, archive), "manifest sizes and SHA-256 values match"
	)

	var records: Variant = JSON.parse_string(String(archive["diagnostics/records.json"]))
	_check(
		(
			records is Dictionary
			and (records.get("records", []) as Array).any(
				func(entry): return bool(entry.get("error", false))
			)
			and int(manifest.get("channel_error_count", 0)) == 1
		),
		"the manifest and structured records retain the error that triggered the return",
		str(records)
	)
	# V0717-06: two counts, never one. The v0.7.17 manifest reported a single
	# diagnostic_error_count of 0 against four engine ERROR: lines, so the automatic
	# bundle never armed — and with concurrent instances an in-process push_error
	# hook would have returned zero too. The godot.log scan is the load-bearing half.
	# `>=` on the total, `==` on the fixture: a worker's user:// carries whatever
	# godot logs earlier runs left, and the assertion that matters is attribution.
	_check(
		(
			int(manifest.get("engine_error_count", -1)) >= 2
			and (
				int(
					(manifest.get("engine_error_sources", {}) as Dictionary).get(
						"godot-engine-errors.log", -1
					)
				)
				== 2
			)
			and int(manifest.get("channel_error_count", -1)) == 1
		),
		"engine errors are counted separately from channel errors, and attributed by file",
		str(manifest.get("engine_error_sources", {}))
	)
	var settings_snapshot: Variant = JSON.parse_string(
		String(archive["settings/settings_snapshot.json"])
	)
	_check(
		settings_snapshot is Dictionary and settings_snapshot.has("audio"),
		"the settings snapshot is JSON-shaped"
	)

	var settings_scene: Node = load("res://scenes/ui/SettingsScreen.tscn").instantiate()
	root.add_child(settings_scene)
	await process_frame
	var diagnostics_button: Button = (
		settings_scene.get_node_or_null("Panel/ScrollContainer/Margin/VBox/BtnExportDiagnostics")
		as Button
	)
	_check(diagnostics_button != null, "Settings exposes the diagnostics export action")
	if diagnostics_button != null:
		diagnostics_button.pressed.emit()
	_check(
		String(diagnostics.last_bundle_result.get("reason", "")) == "settings",
		"the Settings action writes a settings-reason bundle",
		str(diagnostics.last_bundle_result)
	)
	settings_scene.queue_free()

	var hotkey := InputEventKey.new()
	hotkey.keycode = KEY_F12
	hotkey.ctrl_pressed = true
	hotkey.shift_pressed = true
	hotkey.pressed = true
	diagnostics._unhandled_input(hotkey)
	_check(
		bool(diagnostics.last_bundle_result.get("ok", false)),
		"Ctrl+Shift+F12 invokes the same export path",
		str(diagnostics.last_bundle_result)
	)

	# The fixture deliberately records an error to verify the manifest. Suppress
	# the production exit-time retry after cleanup so this suite leaves no archive.
	diagnostics._automatic_bundle_attempted = true
	_cleanup()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s%s" % [label, ("\n     %s" % detail) if not detail.is_empty() else ""])
		failed += 1


func _write_fixture_files() -> void:
	_write_text(PACK_ROOT.path_join("manifest.json"), '{"id":"return_fixture","version":"1.0"}')
	_write_text(PACK_ROOT.path_join("data/catalogue.json"), '{"private":"payload"}')
	_write_text(
		PACK_ROOT.path_join("data/private_payload.txt"), "must not leave the installed pack"
	)
	_write_text(SAVE_ROOT.path_join("saves_index.json"), '{"slots":{"slot_return":{}}}')
	_write_text(SAVE_ROOT.path_join("slot_return.json"), '{"header":{"campaign_id":"fixture"}}')
	_write_text("user://logs/godot-return-test.log", "BUILD STAMP fixture\n")
	# Two logs this process did not write: one from an earlier boot, one from a
	# concurrent instance. Both must come back (V0717-09).
	_write_text(
		"user://logs/diagnostics-20260906T000000-4242.log", "1 | session | build_stamp | pid=4242\n"
	)
	_write_text(
		"user://logs/diagnostics-20260905T235900-4141.log", "1 | session | build_stamp | pid=4141\n"
	)
	# Engine errors never pass through the channel, so they are counted from
	# godot*.log at bundle time (V0717-06).
	_write_text(
		"user://logs/godot-engine-errors.log",
		(
			"ERROR: TurnManager: terrain healing failed for unit (unknown_primitive)\n"
			+ "   at: _apply_fort_healing (scripts/core/TurnManager.gd:1)\n"
			+ "ERROR: a second engine error\n"
		)
	)


func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


func _read_archive(path: String) -> Dictionary:
	var reader := ZIPReader.new()
	if reader.open(path) != OK:
		return {}
	var archive := {}
	for entry in reader.get_files():
		archive[entry] = reader.read_file(entry).get_string_from_utf8()
	reader.close()
	return archive


func _archive_has_prefix(archive: Dictionary, prefix: String) -> bool:
	for path in archive:
		if String(path).begins_with(prefix):
			return true
	return false


func _archive_paths_with_prefix(archive: Dictionary, prefix: String) -> Array[String]:
	var paths: Array[String] = []
	for path in archive:
		if String(path).begins_with(prefix):
			paths.append(String(path))
	return paths


func _manifest_hashes_match(entries: Array, archive: Dictionary) -> bool:
	for entry: Dictionary in entries:
		var path := String(entry.get("path", ""))
		if not archive.has(path):
			return false
		var bytes := String(archive[path]).to_utf8_buffer()
		var hashing := HashingContext.new()
		hashing.start(HashingContext.HASH_SHA256)
		hashing.update(bytes)
		if (
			int(entry.get("size", -1)) != bytes.size()
			or String(entry.get("sha256", "")) != hashing.finish().hex_encode()
		):
			return false
	return true


func _cleanup() -> void:
	_remove_tree(ProjectSettings.globalize_path(PACK_ROOT))
	_remove_tree(ProjectSettings.globalize_path(SAVE_ROOT))
	for stale in [
		"user://logs/godot-return-test.log",
		"user://logs/godot-engine-errors.log",
		"user://logs/diagnostics-20260906T000000-4242.log",
		"user://logs/diagnostics-20260905T235900-4141.log",
	]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(stale))
	_remove_tree(ProjectSettings.globalize_path("user://diagnostics"))


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := path.path_join(name)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		name = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)
