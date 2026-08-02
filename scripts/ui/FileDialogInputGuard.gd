extends FileDialog
# FileDialog owns a separate Window/Viewport, so global input arbitration cannot
# see its filename editor. Printable mirrored gameplay keys are inserted here
# before ui_accept/ui_cancel can consume them.

const TextEntryServiceScript = preload("res://scripts/autoloads/TextEntryService.gd")

var _text_entry_service: Node
var _filename_edit_active := false

# Names the stage that actually consumed the last physical Escape. Escape is
# hooked at four stages because it is not yet established which one wins on
# native Windows; this records the winner so the Windows validation pass can
# keep the authoritative stage and delete the rest instead of guessing.
var escape_consumed_by := ""


func _ready() -> void:
	_text_entry_service = get_node_or_null("/root/TextEntryService")
	if _text_entry_service == null:
		_text_entry_service = TextEntryServiceScript.new()
		_text_entry_service.name = "TextEntryService"
		add_child(_text_entry_service)
	_text_entry_service.session_ended.connect(_on_text_entry_session_ended)
	# The focused editor sees GUI input before FileDialog applies its built-in
	# ui_cancel shortcut. This is the authoritative first-Escape boundary on
	# embedded Windows; the Window hooks below remain diagnostics/fallbacks.
	get_line_edit().gui_input.connect(_on_filename_gui_input)
	get_line_edit().focus_entered.connect(_begin_filename_edit)
	get_line_edit().focus_exited.connect(_on_filename_focus_exited)
	# Window emits this before its embedded controls evaluate shortcuts. FileDialog's
	# built-in cancel handling can otherwise close the window before `_input` runs.
	window_input.connect(_on_window_input)
	visibility_changed.connect(_on_visibility_changed)
	file_selected.connect(func(_path: String) -> void: _end_filename_edit(false))
	dir_selected.connect(func(_path: String) -> void: _end_filename_edit(false))
	canceled.connect(func() -> void: _end_filename_edit(false))


func _on_window_input(event: InputEvent) -> void:
	if event is InputEventKey:
		_observe("window_input")
		if _handle_physical_escape(event as InputEventKey, get_line_edit(), "window_input"):
			get_viewport().set_input_as_handled()


func _on_filename_gui_input(event: InputEvent) -> void:
	_observe("filename_gui_input")
	if not event is InputEventKey:
		return
	# gui_input is a Control-level stage, so the Control-level accept is the
	# right way to stop propagation here.
	if _handle_physical_escape(event as InputEventKey, get_line_edit(), "filename_gui_input"):
		get_line_edit().accept_event()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	_observe("input")
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
		_observe("shortcut_input")
		if _handle_physical_escape(event as InputEventKey, get_line_edit(), "shortcut_input"):
			get_viewport().set_input_as_handled()


# Every stage funnels through one explicit edit-state transition. The first stage
# ends the state synchronously, so the remaining hooks see it inactive and become
# no-ops for that same event.
func _handle_physical_escape(key: InputEventKey, filename: LineEdit, stage: String) -> bool:
	if (
		not _filename_edit_active
		or not key.pressed
		or key.echo
		or (key.keycode != KEY_ESCAPE and key.physical_keycode != KEY_ESCAPE)
		or filename == null
	):
		return false
	escape_consumed_by = stage
	var telemetry := get_node_or_null("/root/TransitionTelemetry")
	if telemetry != null:
		(
			telemetry
			. record(
				"",
				&"file_dialog_escape_owned",
				{
					"stage": stage,
					"filename_edit_active": _filename_edit_active,
					"focus_owner_id": filename.get_instance_id(),
				},
			)
		)
	_end_filename_edit(true)
	return true


func _observe(stage: String) -> void:
	if _text_entry_service != null:
		_text_entry_service.session.observe(stage, get_viewport())


# Filename editing is scoped to the field plus its service-owned grid. Defer the
# check so focus can move from the field into the keyboard without ending it.
func _on_filename_focus_exited() -> void:
	call_deferred("_close_overlay_unless_focused")


func _close_overlay_unless_focused() -> void:
	if not _filename_edit_active:
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner == get_line_edit():
		return
	if _text_entry_service.owns_focus(focus_owner):
		return
	_end_filename_edit(false)


func _begin_filename_edit() -> void:
	if _filename_edit_active or _text_entry_service == null:
		return
	var request := TextEntryRequest.for_purpose(TextEntryRequest.Purpose.FILE_PATH)
	request.target = get_line_edit()
	request.host_viewport = get_viewport()
	request.dismissal_policy = TextEntryRequest.DismissalPolicy.KEEP_EDITED
	_filename_edit_active = _text_entry_service.begin(request, _resolved_text_entry_mode())


func _end_filename_edit(focus_file_list: bool) -> void:
	if not _filename_edit_active:
		return
	_filename_edit_active = false
	if _text_entry_service.session.active:
		_text_entry_service.cancel()
	get_line_edit().release_focus()
	if focus_file_list:
		call_deferred("_focus_file_list")


func _on_text_entry_session_ended(_submitted: bool, _value: String) -> void:
	if _text_entry_service.session.request != null:
		if _text_entry_service.session.request.target == get_line_edit():
			_filename_edit_active = false


func _on_visibility_changed() -> void:
	if not visible:
		_end_filename_edit(false)


func _exit_tree() -> void:
	_end_filename_edit(false)


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
