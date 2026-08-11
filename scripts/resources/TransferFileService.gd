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
# Browser imports use one short-lived <input type=file>. The browser reads the
# selected bytes, this service stages them under user://, and existing consumers
# keep their path-taking APIs. Keep the JavaScript callback alive here: Godot
# releases a callback when its JavaScriptObject has no remaining reference.

const STAGING_DIR := "user://_transfer"

# Godot's own archive/report formats. Anything else downloads as a generic
# binary rather than guessing, which is what a browser does with an unknown type
# anyway.
const MIME_TYPES := {
	"zip": "application/zip",
	"json": "application/json",
}
const DEFAULT_MIME := "application/octet-stream"
const _UPLOAD_CALLBACK_NAME := "__prometheusTransferUpload"

static var _upload_callback: JavaScriptObject
static var _upload_selected: Callable
static var _upload_failed: Callable
static var _upload_maximum_bytes := 0


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


# Ask the player for one local file. This must be called directly from a button
# press on web so the browser recognizes the file picker as user initiated.
static func request_open(
	dialog: FileDialog,
	accept: String,
	maximum_bytes: int,
	on_selected: Callable,
	on_failed: Callable
) -> void:
	if not is_web():
		dialog.popup_centered_ratio(0.75)
		return
	if not Engine.has_singleton("JavaScriptBridge"):
		on_failed.call("Browser file access is unavailable.", false)
		return
	var window: Variant = JavaScriptBridge.get_interface("window")
	if window == null:
		on_failed.call("Browser file access is unavailable.", false)
		return
	_upload_selected = on_selected
	_upload_failed = on_failed
	_upload_maximum_bytes = maximum_bytes
	_upload_callback = JavaScriptBridge.create_callback(_on_browser_upload)
	window.set(_UPLOAD_CALLBACK_NAME, _upload_callback)
	JavaScriptBridge.eval(_upload_script(accept, maximum_bytes), true)


static func _upload_script(accept: String, maximum_bytes: int) -> String:
	# JSON.stringify gives JavaScript-safe string quoting without hand-escaping an
	# accept filter that may contain commas or MIME types.
	var accept_json := JSON.stringify(accept)
	return (
		"""
(() => {
  const callback = window.%s;
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = %s;
  input.style.display = 'none';
  const finish = (...args) => { input.remove(); callback(...args); };
  input.addEventListener('cancel', () => finish('cancelled', '', null, ''));
  input.addEventListener('change', () => {
    const file = input.files && input.files[0];
    if (!file) { finish('cancelled', '', null, ''); return; }
    if (file.size > %d) {
      finish('too_large', file.name, null, String(file.size));
      return;
    }
    const reader = new FileReader();
    reader.onerror = () => finish('read_failed', file.name, null, reader.error ? reader.error.message : 'unknown read error');
    reader.onabort = () => finish('cancelled', file.name, null, '');
    reader.onload = () => finish('selected', file.name, new Uint8Array(reader.result), '');
    reader.readAsArrayBuffer(file);
  }, { once: true });
  document.body.appendChild(input);
  input.click();
})();
"""
		% [_UPLOAD_CALLBACK_NAME, accept_json, maximum_bytes]
	)


static func _on_browser_upload(args: Array) -> void:
	var status := String(args[0]) if not args.is_empty() else "read_failed"
	var name := String(args[1]) if args.size() > 1 else ""
	var payload: Variant = args[2] if args.size() > 2 else null
	var detail := String(args[3]) if args.size() > 3 else ""
	if status == "cancelled":
		_upload_failed.call("File selection was cancelled.", true)
	elif status == "too_large":
		_upload_failed.call(
			"Selected file is %s bytes; the limit is %s bytes." % [detail, _upload_maximum_bytes],
			false
		)
	elif status != "selected" or not payload is PackedByteArray:
		_upload_failed.call("The browser could not read '%s': %s" % [name, detail], false)
	else:
		var staged := stage_upload(name, payload, _upload_maximum_bytes)
		if staged["ok"]:
			_upload_selected.call(staged["path"])
		else:
			_upload_failed.call(staged["errors"][0], false)
	_clear_upload_request()


# Pure/testable half of browser upload. It enforces the byte budget again after
# the JavaScript pre-check, because data crossing the bridge is untrusted input.
static func stage_upload(
	filename: String, bytes: PackedByteArray, maximum_bytes: int
) -> Dictionary:
	if bytes.size() > maximum_bytes:
		return {
			"ok": false,
			"path": "",
			"errors":
			["Selected file is %d bytes; the limit is %d bytes." % [bytes.size(), maximum_bytes]],
		}
	ensure_staging_dir()
	var path := staging_path(filename)
	var handle := FileAccess.open(path, FileAccess.WRITE)
	if handle == null:
		return {"ok": false, "path": "", "errors": ["Could not stage '%s' for import." % filename]}
	handle.store_buffer(bytes)
	handle.close()
	return {"ok": true, "path": path, "errors": []}


static func discard_import(path: String) -> void:
	_discard_staged(path)


static func _clear_upload_request() -> void:
	_upload_callback = null
	_upload_selected = Callable()
	_upload_failed = Callable()
	_upload_maximum_bytes = 0


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
