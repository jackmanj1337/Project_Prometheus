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
	# The stated contract is not just "leave the field" but "hand focus to the
	# file list"; _focus_file_list is deferred, so assert the landing site too.
	# Godot 4's file list is an ItemList — a Tree lookup matched nothing here.
	var focus_owner := dialog.get_viewport().gui_get_focus_owner()
	_check(
		focus_owner is ItemList,
		"first Escape hands focus to the file list, not just away from the field"
	)
	# The file list is selected structurally, not through public API. Assert the
	# selection stays unambiguous so a Godot upgrade that reshapes FileDialog
	# fails here rather than silently focusing Favorites or Recent.
	var candidates := 0
	for node in dialog.find_children("*", "ItemList", true, false):
		var list := node as ItemList
		if (
			list != null
			and list.is_visible_in_tree()
			and not dialog.call("_has_split_ancestor", list)
		):
			candidates += 1
	_check(candidates == 1, "exactly one ItemList qualifies as the file list")
	# Records which of the four hooked stages actually consumed the key. The
	# Windows pass needs this to prune the others rather than guess.
	_check(
		not dialog.escape_consumed_by.is_empty(),
		"the consuming Escape stage is recorded for the Windows pass"
	)

	# Focus leaving the filename field by any route must withdraw the grid
	# overlay, not only Escape. Resolved mode is hardware in this suite, so no
	# overlay is offered on focus_entered; install one and drive the guard's own
	# withdrawal check. Focus is per-viewport and FileDialog is its own viewport,
	# so the competing focus must be taken INSIDE the dialog to be meaningful.
	var leak_overlay := TextEntryOverlay.new()
	dialog.add_child(leak_overlay)
	dialog.set("_text_entry_overlay", leak_overlay)
	leak_overlay.open(filename, request, layout)
	await process_frame
	_check(leak_overlay.visible, "overlay is open before focus leaves")
	var file_list: ItemList = dialog.call("_find_file_list")
	file_list.grab_focus()
	await process_frame
	dialog.call("_close_overlay_unless_focused")
	_check(not leak_overlay.visible, "overlay closes when focus leaves the filename field")

	# ...but focus moving INTO the overlay must not close it, which is what
	# opening it does (open() grabs focus and so fires focus_exited itself).
	leak_overlay.open(filename, request, layout)
	await process_frame
	dialog.call("_close_overlay_unless_focused")
	_check(leak_overlay.visible, "overlay survives the focus_exited its own open() causes")

	dialog.queue_free()
	grid.queue_free()
	hardware.queue_free()
	overlay.queue_free()
	target.queue_free()
	session.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
