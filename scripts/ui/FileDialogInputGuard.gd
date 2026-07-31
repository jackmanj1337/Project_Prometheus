extends FileDialog
# FileDialog owns a separate Window/Viewport, so global input arbitration cannot
# see its filename editor. Printable mirrored gameplay keys are inserted here
# before ui_accept/ui_cancel can consume them.

var _text_entry_session: TextEntrySession
var _text_entry_overlay: TextEntryOverlay

# Names the stage that actually consumed the last physical Escape. Escape is
# hooked at four stages because it is not yet established which one wins on
# native Windows; this records the winner so the Windows validation pass can
# keep the authoritative stage and delete the rest instead of guessing.
var escape_consumed_by := ""


func _ready() -> void:
	_text_entry_session = TextEntrySession.new()
	_text_entry_session.name = "TextEntrySession"
	add_child(_text_entry_session)
	_text_entry_session.physical_escape_consumed.connect(_on_filename_edit_ended)
	# The focused editor sees GUI input before FileDialog applies its built-in
	# ui_cancel shortcut. This is the authoritative first-Escape boundary on
	# embedded Windows; the Window hooks below remain diagnostics/fallbacks.
	get_line_edit().gui_input.connect(_on_filename_gui_input)
	get_line_edit().focus_entered.connect(_offer_on_screen_keyboard)
	get_line_edit().focus_exited.connect(_on_filename_focus_exited)
	# Window emits this before its embedded controls evaluate shortcuts. FileDialog's
	# built-in cancel handling can otherwise close the window before `_input` runs.
	window_input.connect(_on_window_input)


func _on_window_input(event: InputEvent) -> void:
	if event is InputEventKey:
		_text_entry_session.observe("window_input", get_viewport())
		if _handle_physical_escape(event as InputEventKey, get_line_edit(), "window_input"):
			get_viewport().set_input_as_handled()


func _on_filename_gui_input(event: InputEvent) -> void:
	_text_entry_session.observe("filename_gui_input", get_viewport())
	if not event is InputEventKey:
		return
	# gui_input is a Control-level stage, so the Control-level accept is the
	# right way to stop propagation here.
	if _handle_physical_escape(event as InputEventKey, get_line_edit(), "filename_gui_input"):
		get_line_edit().accept_event()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	_text_entry_session.observe("input", get_viewport())
	var key := event as InputEventKey
	var filename := get_line_edit()
	if _handle_physical_escape(key, filename, "input"):
		get_viewport().set_input_as_handled()
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
# filename-to-file-list focus handoff on Windows.
func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventKey:
		_text_entry_session.observe("shortcut_input", get_viewport())
		if _handle_physical_escape(event as InputEventKey, get_line_edit(), "shortcut_input"):
			get_viewport().set_input_as_handled()


# Every stage funnels here. TextEntrySession.handle_physical_escape() returns
# false once the editor has lost focus, so whichever stage runs first consumes
# the key and the remaining stages become no-ops for that event. That
# de-duplication is what makes hooking four stages safe — it is a property of
# the focus check, not a coincidence, so do not drop the focus check when
# pruning stages after the Windows pass.
func _handle_physical_escape(key: InputEventKey, filename: LineEdit, stage: String) -> bool:
	if not _text_entry_session.handle_physical_escape(key, filename):
		return false
	escape_consumed_by = stage
	return true


func _on_filename_edit_ended() -> void:
	if _text_entry_overlay != null:
		_text_entry_overlay.close()
	call_deferred("_focus_file_list")


# The grid overlay is offered on focus_entered, so it must also be withdrawn
# when focus leaves by any route — clicking the file list or tabbing away, not
# just Escape. Opening the overlay grabs focus and therefore fires this signal
# itself, so the check is deferred until the new focus owner has settled and
# keeps the overlay open while focus is still inside it.
func _on_filename_focus_exited() -> void:
	call_deferred("_close_overlay_unless_focused")


func _close_overlay_unless_focused() -> void:
	if _text_entry_overlay == null or not _text_entry_overlay.visible:
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	if (
		focus_owner != null
		and (focus_owner == _text_entry_overlay or _text_entry_overlay.is_ancestor_of(focus_owner))
	):
		return
	_text_entry_overlay.close()


func _offer_on_screen_keyboard() -> void:
	if _resolved_text_entry_mode() != &"grid":
		return
	if _text_entry_overlay == null:
		_text_entry_overlay = TextEntryOverlay.new()
		add_child(_text_entry_overlay)
	var request := TextEntryRequest.new()
	request.purpose = TextEntryRequest.Purpose.FILE_PATH
	request.max_characters = 255
	request.max_utf8_bytes = 255
	request.allowed_characters = _printable_ascii()
	var layout := TextEntryLayout.load_json(
		"res://scripts/ui/text_entry/layouts/us_ascii_grid.json"
	)
	_text_entry_overlay.open(get_line_edit(), request, layout)


func _resolved_text_entry_mode() -> StringName:
	var requested := &"auto"
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null:
		requested = StringName(str(settings.get("text_entry_mode")))
	var device := &"mouse_keyboard"
	var input_modes := get_node_or_null("/root/InputModeManager")
	if input_modes != null:
		device = StringName(str(input_modes.get("active_input_mode")))
	var registry := TextEntryRegistry.new()
	registry.register(&"hardware", func() -> Node: return HardwareTextEntryPresenter.new())
	registry.register(&"grid", func() -> Node: return GridTextEntryPresenter.new())
	return registry.resolve(requested, device)


func _printable_ascii() -> String:
	var result := ""
	for code in range(32, 127):
		result += char(code)
	return result


# Godot 4's FileDialog builds its file list from an ItemList; Tree is the Godot 3
# widget and does not exist anywhere in the dialog, so the previous Tree lookup
# matched nothing and Escape dropped focus into the void on every platform.
#
# The dialog also holds two OTHER visible ItemLists — favorites and recent — both
# nested under a VSplitContainer, while the file list is a sibling of that split.
# Selecting by "visible ItemList with no VSplitContainer ancestor" is structural
# rather than public API, so test_text_entry asserts the candidate is unique: a
# Godot upgrade that reshapes the dialog fails the suite instead of silently
# focusing Favorites.
func _find_file_list() -> ItemList:
	for node in find_children("*", "ItemList", true, false):
		var list := node as ItemList
		if list == null or not list.is_visible_in_tree():
			continue
		if _has_split_ancestor(list):
			continue
		return list
	return null


func _has_split_ancestor(node: Node) -> bool:
	var ancestor := node.get_parent()
	while ancestor != null and ancestor != self:
		if ancestor is VSplitContainer:
			return true
		ancestor = ancestor.get_parent()
	return false


func _focus_file_list() -> void:
	var list := _find_file_list()
	if list != null:
		list.grab_focus()
