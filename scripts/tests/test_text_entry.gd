extends SceneTree

const Transfer = preload("res://scripts/resources/TransferFileService.gd")

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s" % label)
		failed += 1


func _run() -> void:
	var request := TextEntryRequest.new()
	request.allowed_characters = "Ab1 "
	request.max_characters = 3
	_check(request.validate("A!b1 ") == "Ab1", "request filters and caps input")
	request.max_characters = 10
	request.max_utf8_bytes = 2
	_check(request.validate("Ab1") == "Ab", "request enforces UTF-8 byte limit")

	var session := TextEntrySession.new()
	root.add_child(session)
	session.begin(request)
	_check(session.insert("A") and not session.insert("!"), "session uses request validator")
	_check(session.backspace() and session.text.is_empty(), "session edits one character")

	var registry := TextEntryRegistry.new()
	registry.register(&"hardware", func() -> Node: return Node.new())
	registry.register(&"grid", func() -> Node: return Control.new())
	_check(registry.resolve(&"auto", &"gamepad") == &"grid", "gamepad auto-routes to grid")
	_check(
		registry.resolve(&"system", &"touch") == &"hardware", "missing system backend falls back"
	)

	var layout := TextEntryLayout.load_json(
		"res://scripts/ui/text_entry/layouts/us_ascii_grid.json"
	)
	_check(layout != null, "US-ASCII grid layout validates")
	var emitted := ""
	if layout != null:
		for layer: Array in layout.layers.values():
			for row: Array in layer:
				for key: Dictionary in row:
					emitted += str(key.get("emit", ""))
	var complete_ascii := true
	for code in range(32, 127):
		if not emitted.contains(char(code)):
			complete_ascii = false
			break
	_check(complete_ascii, "layout exposes printable US-ASCII U+0020..U+007E")
	# A key whose glyph is not self-describing needs an explicit label; without
	# this the space key rendered as a blank button.
	var space_label := ""
	for row: Array in layout.layers["ABC"]:
		for key: Dictionary in row:
			if str(key.get("emit", "")) == " ":
				space_label = str(key.get("label", ""))
	_check(space_label == "Space", "the space key carries a readable label")
	_check(
		layout.first_layer() == "ABC" and TextEntryLayout.load_default_grid() != null,
		"default grid layout loads through the shared path"
	)
	var grid := GridTextEntryPresenter.new()
	root.add_child(grid)
	_check(grid.configure(layout, request), "grid presenter consumes registry layout")
	_check(grid.active_layer == layout.first_layer(), "presenter opens on the layout's first layer")

	# A layout is not required to name a layer "ABC". This used to crash in
	# _rebuild() while configure() still returned true.
	var alt_path := "user://test_alt_layout.json"
	var alt_file := FileAccess.open(alt_path, FileAccess.WRITE)
	alt_file.store_string(
		'{"id":"alt","layers":{"Letters":[[{"emit":"a"},{"emit":"b"}],[{"action":"submit"}]]}}'
	)
	alt_file.close()
	var alt_layout := TextEntryLayout.load_json(alt_path)
	var alt_grid := GridTextEntryPresenter.new()
	root.add_child(alt_grid)
	_check(
		alt_layout != null and alt_grid.configure(alt_layout, request),
		"a layout with no ABC layer configures cleanly"
	)
	_check(alt_grid.active_layer == "Letters", "presenter adopts the alternate layer name")
	alt_grid.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(alt_path))

	# Purpose owns the charset and the caps, so screens do not carry literals.
	var file_request := TextEntryRequest.for_purpose(TextEntryRequest.Purpose.FILE_PATH)
	var name_request := TextEntryRequest.for_purpose(TextEntryRequest.Purpose.NAME)
	_check(
		file_request.max_characters == 255 and name_request.max_characters == 64,
		"per-purpose requests carry their own caps"
	)
	_check(
		file_request.accepts("/") and not file_request.accepts("é"),
		"per-purpose charset is printable US-ASCII"
	)
	var hardware := HardwareTextEntryPresenter.new()
	root.add_child(hardware)
	hardware.configure(request)
	var hardware_values: Array[String] = []
	hardware.character_entered.connect(func(value: String) -> void: hardware_values.append(value))
	var hardware_key := InputEventKey.new()
	hardware_key.pressed = true
	hardware_key.unicode = KEY_A
	_check(
		hardware.handle(hardware_key) and hardware_values == ["A"],
		"hardware presenter emits through the shared character contract"
	)
	var overlay := TextEntryOverlay.new()
	var target := LineEdit.new()
	root.add_child(target)
	root.add_child(overlay)
	_check(overlay.open(target, request, layout) and overlay.visible, "reusable grid overlay opens")
	# Setting LineEdit.text emits nothing, so a caller listening on the target
	# rather than on the overlay must still observe grid input.
	var mirrored: Array[String] = []
	target.text_changed.connect(func(value: String) -> void: mirrored.append(value))
	overlay.call("_sync_target", "Ab")
	_check(
		target.text == "Ab" and mirrored == ["Ab"],
		"overlay mirrors text_changed onto the target LineEdit"
	)
	overlay.call("_sync_target", "Ab")
	_check(mirrored == ["Ab"], "overlay does not re-emit an unchanged value")
	overlay.call("_on_action", &"cancel")
	_check(not overlay.visible, "overlay cancel closes without caller authority")

	# External-file naming belongs to the platform picker. The guard must not
	# create a competing TextEntryService session or intercept Escape.
	var dialog: FileDialog = load("res://scripts/ui/FileDialogInputGuard.gd").new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	root.add_child(dialog)
	Transfer.request_save(dialog, "slot-a.json", func(_path: String) -> void: pass)
	await process_frame
	_check(
		dialog.visible and dialog.current_file == "slot-a.json" and dialog.use_native_dialog,
		"save transfer opens one native picker with the suggested filename"
	)
	_check(
		not dialog.has_method("_open_filename_entry") and not dialog.has_method("_input"),
		"external picker has no game-owned filename or key interception stage"
	)
	dialog.hide()
	dialog.canceled.emit()
	await process_frame
	_check(not dialog.visible, "one platform-picker cancel closes the picker")

	dialog.queue_free()
	grid.queue_free()
	hardware.queue_free()
	overlay.queue_free()
	target.queue_free()
	session.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
