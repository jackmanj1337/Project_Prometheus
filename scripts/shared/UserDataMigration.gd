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
	var report := {"ran": false, "copied": [], "skipped": [], "errors": []}
	if FileAccess.file_exists(MARKER_PATH):
		return report
	var legacy := legacy_dir()
	if legacy.is_empty() or not DirAccess.dir_exists_absolute(legacy):
		# Fresh install, or a build that never carried the old name. Mark it done
		# so the directory probe does not repeat on every launch forever.
		_write_marker()
		return report

	report["ran"] = true
	for entry in MIGRATED_ENTRIES:
		var source: String = legacy.path_join(entry)
		var destination: String = "user://".path_join(entry)
		var is_dir := DirAccess.dir_exists_absolute(source)
		if not is_dir and not FileAccess.file_exists(source):
			continue
		# Never clobber data the new location already holds: a player who has
		# already launched the renamed build and saved should keep that save.
		if DirAccess.dir_exists_absolute(destination) or FileAccess.file_exists(destination):
			report["skipped"].append(entry)
			continue
		var error := _copy_tree(source, destination) if is_dir else _copy_file(source, destination)
		if error == OK:
			report["copied"].append(entry)
		else:
			report["errors"].append("%s (error %d)" % [entry, error])

	_write_marker()
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


static func _copy_file(source: String, destination: String) -> Error:
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


static func _copy_tree(source: String, destination: String) -> Error:
	var made := DirAccess.make_dir_recursive_absolute(destination)
	if made != OK:
		return made
	var dir := DirAccess.open(source)
	if dir == null:
		return DirAccess.get_open_error()
	for file_name in dir.get_files():
		var error := _copy_file(source.path_join(file_name), destination.path_join(file_name))
		if error != OK:
			return error
	for sub_name in dir.get_directories():
		var error := _copy_tree(source.path_join(sub_name), destination.path_join(sub_name))
		if error != OK:
			return error
	return OK


static func _write_marker() -> void:
	var handle := FileAccess.open(MARKER_PATH, FileAccess.WRITE)
	if handle == null:
		return
	handle.store_string(LEGACY_DIR_NAME)
	handle.close()
