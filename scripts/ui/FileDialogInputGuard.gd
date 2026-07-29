extends FileDialog
# FileDialog owns a separate Window/Viewport, so global input arbitration cannot
# see its filename editor. Printable mirrored gameplay keys are inserted here
# before ui_accept/ui_cancel can consume them.


func _ready() -> void:
	# Window emits this before its embedded controls evaluate shortcuts. FileDialog's
	# built-in cancel handling can otherwise close the window before `_input` runs.
	window_input.connect(_on_window_input)


func _on_window_input(event: InputEvent) -> void:
	if event is InputEventKey:
		_handle_physical_escape(event as InputEventKey, get_line_edit())


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	var filename := get_line_edit()
	if _handle_physical_escape(key, filename):
		return
	if (
		not key.pressed
		or key.unicode < 32
		or key.ctrl_pressed
		or key.alt_pressed
		or key.meta_pressed
	):
		return
	if not (
		InputMap.event_is_action(key, "confirm")
		or InputMap.event_is_action(key, "cancel")
		or InputMap.event_is_action(key, "ui_accept")
		or InputMap.event_is_action(key, "ui_cancel")
	):
		return
	if filename == null or not filename.has_focus():
		return
	if filename.has_selection():
		var from := filename.get_selection_from_column()
		filename.delete_text(from, filename.get_selection_to_column())
		filename.caret_column = from
	filename.insert_text_at_caret(char(key.unicode))
	set_input_as_handled()


# FileDialog also evaluates cancel shortcuts in the shortcut-input stage. Catch
# physical Escape here as well as _input so the built-in close cannot outrun the
# filename-to-tree focus handoff on Windows.
func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventKey:
		_handle_physical_escape(event as InputEventKey, get_line_edit())


func _handle_physical_escape(key: InputEventKey, filename: LineEdit) -> bool:
	if (
		not key.pressed
		or key.echo
		or (key.keycode != KEY_ESCAPE and key.physical_keycode != KEY_ESCAPE)
		or filename == null
	):
		return false
	var focused := get_viewport().gui_get_focus_owner()
	if focused != filename and (focused == null or not filename.is_ancestor_of(focused)):
		return false
	filename.release_focus()
	call_deferred("_focus_file_list")
	get_viewport().set_input_as_handled()
	return true


func _focus_file_list() -> void:
	for node in find_children("*", "Tree", true, false):
		if node is Tree and node.is_visible_in_tree():
			(node as Tree).grab_focus()
			return
