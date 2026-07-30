extends SceneTree

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
	var grid := GridTextEntryPresenter.new()
	root.add_child(grid)
	_check(grid.configure(layout, request), "grid presenter consumes registry layout")
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

	# This suite has its own process/viewport, so dispatch the real event route instead
	# of calling FileDialog's handler directly. This is the v0.5.8 regression boundary.
	var dialog: FileDialog = load("res://scripts/ui/FileDialogInputGuard.gd").new()
	root.add_child(dialog)
	dialog.popup_centered(Vector2i(640, 420))
	await process_frame
	var filename := dialog.get_line_edit()
	filename.grab_focus()
	await process_frame
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	# FileDialog is its own Viewport. Push through that viewport's real dispatch
	# route; Input.parse_input_event targets the root viewport in headless mode.
	dialog.push_input(escape)
	await process_frame
	await process_frame
	_check(
		dialog.visible and not filename.has_focus(), "dispatched first Escape exits filename edit"
	)

	dialog.queue_free()
	grid.queue_free()
	hardware.queue_free()
	session.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
