class_name UserDataMigration extends RefCounted
# One-time carry-over of player data after the application/config/name change
# from "Fire Emblem RPG" to "Project Prometheus".
#
# config/name determines OS.get_user_data_dir(), so renaming it silently moves
# user:// on every platform. Without this, an existing install would launch with
# no saves, default settings, and no imported campaign packages -- and the old
# data would still be on disk, invisible, looking like data loss.
#
# Runs from SettingsManager._ready() because that is the first autoload to read
# user:// (4th in the autoload list; SaveManager is 15th). It cannot be an
# autoload of its own placed first without risking the autoload/class_name
# collision that has hollowed out suites here before.
#
# Deliberately NOT migrated:
#   logs/  - the engine has already opened a log file in the new location before
#            any autoload runs, and old logs are diagnostic history, not player
#            data.
#   _transfer/ - ephemeral web download staging (TransferFileService).
#
# The legacy directory is left in place rather than deleted. It is the player's
# only rollback if a future build reverts the rename, and reclaiming the disk is
# not worth owning a recursive delete of a directory this code did not create.

const LEGACY_DIR_NAME := "Fire Emblem RPG"
const MARKER_PATH := "user://.legacy_user_data_migrated"

# Every user:// root the game owns, as of the rename. A root missing from the
# legacy directory is skipped, so this list may safely name things that only
# newer builds create.
const MIGRATED_ENTRIES := [
	"saves",
	"campaign_packs",
	"campaign_status",
	"settings.cfg",
]


# Returns a report so callers and tests can see what happened; migration failure
# is never fatal, because launching with default settings beats not launching.
static func run() -> Dictionary:
	return _run_from(legacy_dir(), "user://", MARKER_PATH)


# Separate paths make the failure boundary testable without touching a player's
# actual legacy directory. Production always enters through run().
static func _run_from(
	legacy: String, destination_root: String, marker_path: String, before_file_copy := Callable()
) -> Dictionary:
	var report := {"ran": false, "copied": [], "skipped": [], "errors": []}
	if FileAccess.file_exists(marker_path):
		return report
	if legacy.is_empty() or not DirAccess.dir_exists_absolute(legacy):
		# Fresh install, or a build that never carried the old name. Mark it done
		# so the directory probe does not repeat on every launch forever.
		_write_marker(marker_path)
		return report

	report["ran"] = true
	for entry in MIGRATED_ENTRIES:
		var source: String = legacy.path_join(entry)
		var destination: String = destination_root.path_join(entry)
		var is_dir := DirAccess.dir_exists_absolute(source)
		if not is_dir and not FileAccess.file_exists(source):
			continue
		# Never clobber data the new location already holds: a player who has
		# already launched the renamed build and saved should keep that save.
		if DirAccess.dir_exists_absolute(destination) or FileAccess.file_exists(destination):
			report["skipped"].append(entry)
			continue
		var error := _copy_entry_atomically(source, destination, is_dir, before_file_copy)
		if error == OK:
			report["copied"].append(entry)
		else:
			report["errors"].append("%s (error %d)" % [entry, error])

	# A partial tree is not a completed migration. Without this guard the marker
	# makes the missing files permanent; with it, the next launch retries while
	# preserving entries that were committed successfully before the failure.
	if report["errors"].is_empty():
		_write_marker(marker_path)
	return report


# Absolute path of the pre-rename user data directory: the sibling of the
# current one, under the same app_userdata parent. Returns "" if the current
# directory has no parent to be a sibling of, which should not happen.
static func legacy_dir() -> String:
	var current := OS.get_user_data_dir()
	var parent := current.get_base_dir()
	if parent.is_empty() or parent == current:
		return ""
	return parent.path_join(LEGACY_DIR_NAME)


static func _copy_entry_atomically(
	source: String, destination: String, is_dir: bool, before_file_copy := Callable()
) -> Error:
	var staging := destination + ".migration_tmp"
	_remove_path(staging)
	var error := (
		_copy_tree(source, staging, before_file_copy)
		if is_dir
		else _copy_file(source, staging, before_file_copy)
	)
	if error != OK:
		_remove_path(staging)
		return error
	error = DirAccess.rename_absolute(staging, destination)
	if error != OK:
		_remove_path(staging)
	return error


static func _copy_file(
	source: String, destination: String, before_file_copy := Callable()
) -> Error:
	if before_file_copy.is_valid():
		var injected_error: Error = before_file_copy.call(source, destination)
		if injected_error != OK:
			return injected_error
	var reader := FileAccess.open(source, FileAccess.READ)
	if reader == null:
		return FileAccess.get_open_error()
	var bytes := reader.get_buffer(reader.get_length())
	reader.close()
	var writer := FileAccess.open(destination, FileAccess.WRITE)
	if writer == null:
		return FileAccess.get_open_error()
	writer.store_buffer(bytes)
	writer.close()
	return OK


static func _copy_tree(
	source: String, destination: String, before_file_copy := Callable()
) -> Error:
	var made := DirAccess.make_dir_recursive_absolute(destination)
	if made != OK:
		return made
	var dir := DirAccess.open(source)
	if dir == null:
		return DirAccess.get_open_error()
	for file_name in dir.get_files():
		var error := _copy_file(
			source.path_join(file_name), destination.path_join(file_name), before_file_copy
		)
		if error != OK:
			return error
	for sub_name in dir.get_directories():
		var error := _copy_tree(
			source.path_join(sub_name), destination.path_join(sub_name), before_file_copy
		)
		if error != OK:
			return error
	return OK


static func _remove_path(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir != null:
		for file_name in dir.get_files():
			DirAccess.remove_absolute(path.path_join(file_name))
		for sub_name in dir.get_directories():
			_remove_path(path.path_join(sub_name))
		DirAccess.remove_absolute(path)
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


static func _write_marker(marker_path := MARKER_PATH) -> void:
	var handle := FileAccess.open(marker_path, FileAccess.WRITE)
	if handle == null:
		return
	handle.store_string(LEGACY_DIR_NAME)
	handle.close()
