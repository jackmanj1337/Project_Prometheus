class_name TransferFileService extends RefCounted
# Platform seam for player-facing file transfer (save export, campaign pack
# export/import).
#
# Desktop keeps Godot's FileDialog over the real filesystem. Web cannot: there
# FileDialog browses the Emscripten virtual filesystem, so a player can neither
# reach a file on their machine nor retrieve anything an "export" wrote into
# browser storage. This service is the only place that knows the difference, so
# the desktop input workarounds in FileDialogInputGuard.gd stay on the desktop
# branch and the web path never inherits them.
#
# The web branch stages bytes through user:// and hands them to
# JavaScriptBridge.download_buffer. That keeps every consumer's existing
# path-taking API intact — CampaignPackExporter.export_zip and
# SaveManager.export_slot still just write to a path — so no service had to be
# rewritten to speak PackedByteArray.
#
# IMPORT IS NOT HERE YET. Web import needs a JS <input type=file> upload shim,
# and the three screens that would adopt it also adopt the text-entry seam at
# the same time; doing it before DESIGN-TEXT-ENTRY-SERVICE settles would bake in
# three copies of the current per-call construction. Export has no such
# coupling: on web the browser names the downloaded file, so there is no
# filename field at all.

const STAGING_DIR := "user://_transfer"

# Godot's own archive/report formats. Anything else downloads as a generic
# binary rather than guessing, which is what a browser does with an unknown type
# anyway.
const MIME_TYPES := {
	"zip": "application/zip",
	"json": "application/json",
}
const DEFAULT_MIME := "application/octet-stream"


static func is_web() -> bool:
	return OS.has_feature("web")


# Where the caller should write. On desktop this is the player's chosen path and
# arrives asynchronously through the dialog's existing file_selected signal; on
# web there is no chooser, so a staging path is handed back immediately and the
# same callback runs synchronously.
static func request_save(dialog: FileDialog, suggested_name: String, on_selected: Callable) -> void:
	if is_web():
		# The consumer writes straight to this path, so the directory has to
		# exist before the callback runs rather than at deliver() time.
		ensure_staging_dir()
		on_selected.call(staging_path(suggested_name))
		return
	if dialog.has_method("begin_save"):
		dialog.call("begin_save", suggested_name)
		return
	dialog.current_file = suggested_name
	dialog.popup_centered_ratio(0.75)


static func staging_path(suggested_name: String) -> String:
	return STAGING_DIR.path_join(suggested_name.get_file())


# Hand a written file to the player. No-op on desktop, where the file already
# sits where they asked for it. Call this only after the write succeeded.
static func deliver(path: String) -> Dictionary:
	if not is_web():
		return {"ok": true, "errors": []}
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["Export produced no file to download: %s" % path]}
	var bytes := FileAccess.get_file_as_bytes(path)
	# An exported archive or save record is never legitimately empty, so an empty
	# read means the write failed rather than that there was nothing to send.
	if bytes.is_empty():
		_discard_staged(path)
		return {"ok": false, "errors": ["Export file was empty and was not downloaded: %s" % path]}
	JavaScriptBridge.download_buffer(bytes, path.get_file(), mime_for(path))
	_discard_staged(path)
	return {"ok": true, "errors": []}


static func mime_for(path: String) -> String:
	return MIME_TYPES.get(path.get_extension().to_lower(), DEFAULT_MIME)


# Ensure the staging directory exists before a caller writes into it. Separate
# from request_save so a caller that builds its own path can still stage safely.
static func ensure_staging_dir() -> void:
	if not DirAccess.dir_exists_absolute(STAGING_DIR):
		DirAccess.make_dir_recursive_absolute(STAGING_DIR)


# Staged bytes have already been copied into the browser download; leaving them
# in user:// would grow IndexedDB without bound, and on web that storage is the
# same budget the player's saves live in.
static func _discard_staged(path: String) -> void:
	if path.begins_with(STAGING_DIR):
		DirAccess.remove_absolute(path)
