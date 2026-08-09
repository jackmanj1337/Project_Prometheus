extends FileDialog
# FileDialog owns a separate Window/Viewport, so global input arbitration cannot
# see its filename editor. Printable mirrored gameplay keys are inserted here
# before ui_accept/ui_cancel can consume them.

const TextEntryServiceScript = preload("res://scripts/autoloads/TextEntryService.gd")

var _text_entry_service: Node
var _filename_edit_active := false
var _filename_prompt: ConfirmationDialog
var _filename_prompt_edit: LineEdit
var _picker_open_authorized := false


func _ready() -> void:
	_text_entry_service = get_node_or_null("/root/TextEntryService")
	if _text_entry_service == null:
		_text_entry_service = TextEntryServiceScript.new()
		_text_entry_service.name = "TextEntryService"
		add_child(_text_entry_service)
	_text_entry_service.session_ended.connect(_on_text_entry_session_ended)
	get_line_edit().focus_entered.connect(_begin_filename_edit)
	get_line_edit().focus_exited.connect(_on_filename_focus_exited)
	visibility_changed.connect(_on_visibility_changed)
	file_selected.connect(_on_picker_selected)
	dir_selected.connect(_on_picker_selected)
	canceled.connect(_on_picker_canceled)
	_build_filename_prompt()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	_observe("input")
	var key := event as InputEventKey
	var filename := get_line_edit()
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
	if _filename_edit_active or _text_entry_service == null or not get_line_edit().editable:
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
	if visible and file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		if _picker_open_authorized:
			_picker_open_authorized = false
			return
		# FileDialog's filename editor has no reliable pre-cancel input boundary on
		# Windows. Name the export in a game-owned modal, then use FileDialog only
		# to choose its directory; Escape can retain its normal one-step cancel.
		hide()
		call_deferred("_open_filename_prompt")
	elif not visible:
		_end_filename_edit(false)


func _build_filename_prompt() -> void:
	_filename_prompt = ConfirmationDialog.new()
	_filename_prompt.name = "FilenamePrompt"
	_filename_prompt.title = "Name Export"
	_filename_prompt.ok_button_text = "Choose Folder"
	_filename_prompt.cancel_button_text = "Cancel"
	_filename_prompt.exclusive = true
	_filename_prompt_edit = LineEdit.new()
	_filename_prompt_edit.name = "Filename"
	_filename_prompt_edit.placeholder_text = "Filename"
	_filename_prompt_edit.select_all_on_focus = true
	_filename_prompt.add_child(_filename_prompt_edit)
	add_child(_filename_prompt)
	_filename_prompt.confirmed.connect(_on_filename_confirmed)
	_filename_prompt.canceled.connect(_on_filename_prompt_canceled)


func _open_filename_prompt() -> void:
	if not is_inside_tree() or file_mode != FileDialog.FILE_MODE_SAVE_FILE:
		return
	_filename_prompt_edit.text = current_file.get_file()
	var request := TextEntryRequest.for_purpose(TextEntryRequest.Purpose.FILE_PATH)
	request.target = _filename_prompt_edit
	request.host_viewport = _filename_prompt.get_viewport()
	request.initial_text = _filename_prompt_edit.text
	request.dismissal_policy = TextEntryRequest.DismissalPolicy.KEEP_EDITED
	_filename_prompt.popup_centered(Vector2i(520, 160))
	_filename_prompt_edit.grab_focus()
	_filename_prompt_edit.select_all()
	_text_entry_service.begin(request, _resolved_text_entry_mode())


func _on_filename_confirmed() -> void:
	var request := TextEntryRequest.for_purpose(TextEntryRequest.Purpose.FILE_PATH)
	var filename := request.validate(_filename_prompt_edit.text).strip_edges().get_file()
	if not request.is_submittable(filename):
		call_deferred("_open_filename_prompt")
		return
	if _text_entry_service.session.active:
		_text_entry_service.submit()
	current_file = filename
	var editor := get_line_edit()
	editor.editable = false
	_picker_open_authorized = true
	popup_centered_ratio(0.75)
	call_deferred("_focus_file_list")


func _on_filename_prompt_canceled() -> void:
	if _text_entry_service.session.active:
		_text_entry_service.cancel()


func _on_picker_canceled() -> void:
	_end_filename_edit(false)
	_restore_picker_filename_editor()


func _on_picker_selected(_path: String) -> void:
	_end_filename_edit(false)
	_restore_picker_filename_editor()


func _restore_picker_filename_editor() -> void:
	var editor := get_line_edit()
	editor.editable = true


func _exit_tree() -> void:
	_end_filename_edit(false)
	_on_filename_prompt_canceled()


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
