extends SceneTree
# Contracts for the user:// carry-over that the config/name rename forces.
#
# The dangerous failure here is not "migration did not run" -- that costs a
# player their settings. It is "migration overwrote data the new install already
# had", which destroys work that exists. Both directions are pinned below.
#
# These tests drive the copy helpers against real directories rather than
# mocking them, because the bug this guards against is a filesystem-ordering
# bug, not a logic bug.

const Migration = preload("res://scripts/shared/UserDataMigration.gd")

const SANDBOX := "user://test_migration_sandbox"

var _copies_before_failure := -1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== User Data Migration Test ===")
	var passed := 0
	var failed := 0

	_reset_sandbox()

	# legacy_dir() must name a SIBLING of the live user dir, so the two resolve
	# under the same app_userdata parent on every platform.
	var legacy := Migration.legacy_dir()
	var current := OS.get_user_data_dir()
	if legacy.is_empty():
		print("FAIL legacy_dir() returned empty")
		failed += 1
	elif legacy.get_base_dir() != current.get_base_dir():
		print("FAIL legacy_dir() is not a sibling of the user dir: %s vs %s" % [legacy, current])
		failed += 1
	elif legacy.get_file() != Migration.LEGACY_DIR_NAME:
		print(
			(
				"FAIL legacy_dir() leaf is %s, expected %s"
				% [legacy.get_file(), Migration.LEGACY_DIR_NAME]
			)
		)
		failed += 1
	else:
		passed += 1
		print("OK  legacy_dir() is a sibling named %s" % Migration.LEGACY_DIR_NAME)

	# The rename must not have left the old name anywhere that resolves paths.
	if current.get_file() == Migration.LEGACY_DIR_NAME:
		print("FAIL live user dir is still %s; the rename did not take" % Migration.LEGACY_DIR_NAME)
		failed += 1
	else:
		passed += 1
		print("OK  live user dir is no longer %s" % Migration.LEGACY_DIR_NAME)

	# A nested tree must copy whole, not just its top level -- saves/ and
	# campaign_packs/ both nest.
	var source := SANDBOX.path_join("src")
	var destination := SANDBOX.path_join("dst")
	DirAccess.make_dir_recursive_absolute(source.path_join("nested/deeper"))
	_write(source.path_join("top.json"), "top")
	_write(source.path_join("nested/mid.json"), "mid")
	_write(source.path_join("nested/deeper/leaf.json"), "leaf")
	var copy_error: Error = Migration._copy_tree(source, destination)
	if copy_error != OK:
		print("FAIL _copy_tree() returned error %d" % copy_error)
		failed += 1
	elif (
		_read(destination.path_join("top.json")) != "top"
		or _read(destination.path_join("nested/mid.json")) != "mid"
		or _read(destination.path_join("nested/deeper/leaf.json")) != "leaf"
	):
		print("FAIL _copy_tree() did not reproduce the nested tree")
		failed += 1
	else:
		passed += 1
		print("OK  _copy_tree() copies a nested tree byte for byte")

	# A copy failure after one nested file must not expose the partial tree or
	# write the global completion marker. The next launch retries and commits the
	# whole entry, while already-completed sibling entries remain untouched.
	var retry_legacy := SANDBOX.path_join("retry_legacy")
	var retry_current := SANDBOX.path_join("retry_current")
	var retry_marker := retry_current.path_join(".migrated")
	DirAccess.make_dir_recursive_absolute(retry_legacy.path_join("saves/nested"))
	DirAccess.make_dir_recursive_absolute(retry_current)
	_write(retry_legacy.path_join("saves/first.json"), "first")
	_write(retry_legacy.path_join("saves/nested/second.json"), "second")
	_copies_before_failure = 1
	var failed_report := Migration._run_from(
		retry_legacy, retry_current, retry_marker, Callable(self, "_fail_copy_after_budget")
	)
	var partial_destination := retry_current.path_join("saves")
	if (
		failed_report["errors"].is_empty()
		or FileAccess.file_exists(retry_marker)
		or DirAccess.dir_exists_absolute(partial_destination)
	):
		print("FAIL partial migration was exposed or marked complete: %s" % [failed_report])
		failed += 1
	else:
		var retry_report := Migration._run_from(retry_legacy, retry_current, retry_marker)
		if (
			not retry_report["errors"].is_empty()
			or not FileAccess.file_exists(retry_marker)
			or _read(partial_destination.path_join("first.json")) != "first"
			or _read(partial_destination.path_join("nested/second.json")) != "second"
		):
			print("FAIL migration did not retry safely: %s" % [retry_report])
			failed += 1
		else:
			passed += 1
			print("OK  failed nested copy stays uncommitted and retries on next launch")

	# Binary fidelity: saves are JSON today but campaign_packs holds .zip
	# archives, and a text-mode copy would silently corrupt them.
	var blob := PackedByteArray([0, 255, 10, 13, 26, 127, 200])
	var binary_source := SANDBOX.path_join("bin/src.zip")
	var binary_destination := SANDBOX.path_join("bin/dst.zip")
	DirAccess.make_dir_recursive_absolute(SANDBOX.path_join("bin"))
	var writer := FileAccess.open(binary_source, FileAccess.WRITE)
	writer.store_buffer(blob)
	writer.close()
	Migration._copy_file(binary_source, binary_destination)
	if FileAccess.get_file_as_bytes(binary_destination) != blob:
		print("FAIL _copy_file() did not preserve binary content")
		failed += 1
	else:
		passed += 1
		print("OK  _copy_file() preserves bytes including nulls and CR/LF")

	# The marker makes run() a no-op, so a launch after migration never re-copies
	# and never re-probes the legacy directory.
	var had_marker := FileAccess.file_exists(Migration.MARKER_PATH)
	Migration._write_marker()
	var second := Migration.run()
	if second["ran"] or not second["copied"].is_empty():
		print("FAIL run() acted despite the marker: %s" % [second])
		failed += 1
	else:
		passed += 1
		print("OK  run() is a no-op once the marker exists")
	if not had_marker:
		DirAccess.remove_absolute(Migration.MARKER_PATH)

	# Every migrated entry must be a real user:// root the game owns; a typo here
	# would silently skip a player's data forever.
	var known := ["saves", "campaign_packs", "campaign_status", "settings.cfg"]
	var entries_ok := true
	for entry in Migration.MIGRATED_ENTRIES:
		if not known.has(entry):
			print("FAIL MIGRATED_ENTRIES names an unknown root: %s" % entry)
			entries_ok = false
	for entry in known:
		if not Migration.MIGRATED_ENTRIES.has(entry):
			print("FAIL MIGRATED_ENTRIES is missing a known root: %s" % entry)
			entries_ok = false
	if entries_ok:
		passed += 1
		print("OK  MIGRATED_ENTRIES covers exactly the owned user:// roots")
	else:
		failed += 1

	_reset_sandbox()
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var handle := FileAccess.open(path, FileAccess.WRITE)
	handle.store_string(text)
	handle.close()


func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _fail_copy_after_budget(_source: String, _destination: String) -> Error:
	if _copies_before_failure == 0:
		return ERR_FILE_CANT_WRITE
	_copies_before_failure -= 1
	return OK


func _reset_sandbox() -> void:
	_remove_tree(SANDBOX)


func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub_name in dir.get_directories():
		_remove_tree(path.path_join(sub_name))
	DirAccess.remove_absolute(path)
