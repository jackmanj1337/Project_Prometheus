extends FileDialog
# FileDialog owns a separate Window/Viewport, so global input arbitration cannot
# see its filename editor. Printable mirrored gameplay keys are inserted here
# before ui_accept/ui_cancel can consume them.

var _text_entry_session: TextEntrySession


func _ready() -> void:
	_text_entry_session = TextEntrySession.new()
	_text_entry_session.name = "TextEntrySession"
	add_child(_text_entry_session)
	_text_entry_session.physical_escape_consumed.connect(_on_filename_edit_ended)
	# The focused editor sees GUI input before FileDialog applies its built-in
	# ui_cancel shortcut. This is the authoritative first-Escape boundary on
	# embedded Windows; the Window hooks below remain diagnostics/fallbacks.
	get_line_edit().gui_input.connect(_on_filename_gui_input)
	# Window emits this before its embedded controls evaluate shortcuts. FileDialog's
	# built-in cancel handling can otherwise close the window before `_input` runs.
	window_input.connect(_on_window_input)


func _on_window_input(event: InputEvent) -> void:
	if event is InputEventKey:
		_text_entry_session.observe("window_input", get_viewport())
		_handle_physical_escape(event as InputEventKey, get_line_edit())


func _on_filename_gui_input(event: InputEvent) -> void:
	_text_entry_session.observe("filename_gui_input", get_viewport())
	if _text_entry_session.handle_physical_escape(event, get_line_edit()):
		get_line_edit().accept_event()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	_text_entry_session.observe("input", get_viewport())
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
		_text_entry_session.observe("shortcut_input", get_viewport())
		_handle_physical_escape(event as InputEventKey, get_line_edit())


func _handle_physical_escape(key: InputEventKey, filename: LineEdit) -> bool:
	if not _text_entry_session.handle_physical_escape(key, filename):
		return false
	get_viewport().set_input_as_handled()
	return true


func _on_filename_edit_ended() -> void:
	call_deferred("_focus_file_list")


func _focus_file_list() -> void:
	for node in find_children("*", "Tree", true, false):
		if node is Tree and node.is_visible_in_tree():
			(node as Tree).grab_focus()
			return
