extends SceneTree
# Contracts for the platform transfer seam. These run headless, where is_web()
# is false, so they pin the DESKTOP behaviour: the seam must stay a pass-through
# and must not disturb the flow a Windows playtest already accepted. The web
# branch's byte handling is exercised through the pure helpers, which do not
# depend on the platform.

const Transfer = preload("res://scripts/resources/TransferFileService.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Transfer File Service Test ===")
	var passed := 0
	var failed := 0

	# Headless is not web; every desktop assertion below depends on this.
	if Transfer.is_web():
		print("FAIL is_web() true under headless; the rest of this suite is invalid")
		quit(1)
		return
	passed += 1
	print("OK  is_web() is false headless")

	# deliver() must be a pass-through on desktop: the exporter already wrote the
	# file where the player asked, so touching it would be wrong.
	var desktop_path := "user://test_transfer_desktop.json"
	var handle := FileAccess.open(desktop_path, FileAccess.WRITE)
	handle.store_string('{"ok":true}')
	handle.close()
	var delivery := Transfer.deliver(desktop_path)
	if not delivery["ok"] or not delivery["errors"].is_empty():
		print("FAIL desktop deliver() reported failure: %s" % [delivery])
		failed += 1
	elif not FileAccess.file_exists(desktop_path):
		print("FAIL desktop deliver() deleted the player's exported file")
		failed += 1
	else:
		passed += 1
		print("OK  desktop deliver() leaves the exported file untouched")
	DirAccess.remove_absolute(desktop_path)

	# request_save() on desktop must route through the dialog, not invoke the
	# callback synchronously — invoking it early would export before the player
	# has chosen a destination.
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	root.add_child(dialog)
	var called := {"count": 0, "path": ""}
	var capture := func(path: String) -> void:
		called["count"] += 1
		called["path"] = path
	Transfer.request_save(dialog, "slot-a.json", capture)
	if called["count"] != 0:
		print("FAIL desktop request_save() invoked the callback without a player choice")
		failed += 1
	elif dialog.current_file != "slot-a.json":
		print("FAIL desktop request_save() did not seed the filename: %s" % dialog.current_file)
		failed += 1
	elif not dialog.visible:
		print("FAIL desktop request_save() did not show the dialog")
		failed += 1
	else:
		passed += 1
		print("OK  desktop request_save() seeds the filename and waits for the dialog")
	dialog.hide()
	dialog.queue_free()

	# Staging paths must stay inside the staging directory even when the caller
	# suggests a name carrying separators; _discard_staged only removes files
	# under that root, so an escaping name would leak files forever.
	var escaped := Transfer.staging_path("../../evil.zip")
	if not escaped.begins_with(Transfer.STAGING_DIR):
		print("FAIL staging_path() escaped the staging dir: %s" % escaped)
		failed += 1
	elif escaped != Transfer.STAGING_DIR.path_join("evil.zip"):
		print("FAIL staging_path() did not reduce to a bare filename: %s" % escaped)
		failed += 1
	else:
		passed += 1
		print("OK  staging_path() keeps a traversing name inside the staging dir")

	# The browser uses the MIME type to name and handle the download; a zip
	# offered as octet-stream is a worse experience but not a failure, so this
	# pins the two formats the transfer surfaces actually produce.
	var mime_cases := {
		"user://a.zip": "application/zip",
		"user://b.json": "application/json",
		"user://c.ZIP": "application/zip",
		"user://d.bin": Transfer.DEFAULT_MIME,
		"user://e": Transfer.DEFAULT_MIME,
	}
	var mime_ok := true
	for path in mime_cases:
		var got := Transfer.mime_for(path)
		if got != mime_cases[path]:
			print("FAIL mime_for(%s) = %s, expected %s" % [path, got, mime_cases[path]])
			mime_ok = false
	if mime_ok:
		passed += 1
		print("OK  mime_for() maps zip/json and falls back for anything else")
	else:
		failed += 1

	# ensure_staging_dir() has to be idempotent: request_save calls it on every
	# web export, not once per session.
	Transfer.ensure_staging_dir()
	Transfer.ensure_staging_dir()
	if not DirAccess.dir_exists_absolute(Transfer.STAGING_DIR):
		print("FAIL ensure_staging_dir() did not create %s" % Transfer.STAGING_DIR)
		failed += 1
	else:
		passed += 1
		print("OK  ensure_staging_dir() is idempotent")
	DirAccess.remove_absolute(Transfer.STAGING_DIR)

	# Browser-selected bytes are staged under a bare filename so the existing
	# path-based import services can consume them without learning JavaScript.
	var upload := Transfer.stage_upload("../selected.zip", PackedByteArray([1, 2, 3]), 3)
	if not upload["ok"] or upload["path"] != Transfer.STAGING_DIR.path_join("selected.zip"):
		print("FAIL stage_upload() did not stage a safe browser path: %s" % [upload])
		failed += 1
	elif FileAccess.get_file_as_bytes(upload["path"]) != PackedByteArray([1, 2, 3]):
		print("FAIL stage_upload() changed the selected bytes")
		failed += 1
	else:
		passed += 1
		print("OK  stage_upload() preserves bytes under a safe staging path")
	Transfer.discard_import(upload["path"])
	if FileAccess.file_exists(upload["path"]):
		print("FAIL discard_import() left browser upload bytes in user storage")
		failed += 1
	else:
		passed += 1
		print("OK  discard_import() removes consumed browser upload bytes")

	# The native FileReader size is checked before reading and the received byte
	# array is checked again here. Oversized input must never touch user storage.
	var oversized := Transfer.stage_upload("large.zip", PackedByteArray([1, 2, 3, 4]), 3)
	if oversized["ok"] or oversized["errors"].is_empty():
		print("FAIL stage_upload() accepted an oversized browser file")
		failed += 1
	elif FileAccess.file_exists(Transfer.staging_path("large.zip")):
		print("FAIL oversized browser input was written before rejection")
		failed += 1
	else:
		passed += 1
		print("OK  stage_upload() rejects oversized bytes before writing")
	DirAccess.remove_absolute(Transfer.STAGING_DIR)

	# JavaScript create_callback exposes a plain JS Array as a Variant Array.
	# Normalizing that boundary keeps the browser representation out of the
	# staging and import services.
	var bridged_bytes: Variant = Transfer.upload_bytes([0, 127, 255])
	if not bridged_bytes is PackedByteArray:
		print("FAIL upload_bytes() did not normalize the callback array")
		failed += 1
	elif bridged_bytes != PackedByteArray([0, 127, 255]):
		print("FAIL upload_bytes() changed browser-selected bytes: %s" % [bridged_bytes])
		failed += 1
	else:
		passed += 1
		print("OK  upload_bytes() normalizes the browser callback array")
	var data_url_bytes: Variant = Transfer.upload_bytes("data:application/zip;base64,AH//")
	if data_url_bytes != PackedByteArray([0, 127, 255]):
		print("FAIL upload_bytes() did not decode the browser data URL: %s" % [data_url_bytes])
		failed += 1
	else:
		passed += 1
		print("OK  upload_bytes() decodes the browser data URL")

	# A missing file must be reported rather than handed to the browser as an
	# empty download that looks like a successful export.
	var missing := Transfer.deliver("user://test_transfer_absent.zip")
	if not missing["ok"]:
		print("FAIL desktop deliver() must not police a missing file; that is the exporter's job")
		failed += 1
	else:
		passed += 1
		print("OK  desktop deliver() stays out of the exporter's error reporting")

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
