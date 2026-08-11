extends FileDialog
# Save exports are named in TextEntryService's game-owned surface. The native
# FileDialog is deliberately limited to directory selection: its nested Window
# cannot participate reliably in the game's modal/input ownership on Windows.

const TextEntryServiceScript = preload("res://scripts/autoloads/TextEntryService.gd")

var _text_entry_service: Node
var _filename_target := LineEdit.new()
var _restore_focus: Control
var _picker_filename_active := false


func _ready() -> void:
	_text_entry_service = get_node_or_null("/root/TextEntryService")
	if _text_entry_service == null:
		_text_entry_service = TextEntryServiceScript.new()
		_text_entry_service.name = "TextEntryService"
		add_child(_text_entry_service)
	_text_entry_service.session_ended.connect(_on_text_entry_session_ended)
	_filename_target.name = "FilenameValue"
	_filename_target.hide()
	_game_viewport().add_child(_filename_target)
	get_line_edit().focus_entered.connect(_begin_picker_filename_edit)
	get_line_edit().focus_exited.connect(_on_picker_filename_focus_exited)
	file_selected.connect(_on_picker_selected)
	dir_selected.connect(_on_picker_selected)
	canceled.connect(_on_picker_canceled)


# Open-file dialogs still expose Godot's filename filter field. Preserve
# printable mirrored gameplay keys there; save dialogs never enter this path.
func _input(event: InputEvent) -> void:
	if file_mode == FileDialog.FILE_MODE_SAVE_FILE or not event is InputEventKey:
		return
	var key := event as InputEventKey
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
	var editor := get_line_edit()
	if editor == null or not editor.has_focus():
		return
	if editor.has_selection():
		var from := editor.get_selection_from_column()
		editor.delete_text(from, editor.get_selection_to_column())
		editor.caret_column = from
	editor.insert_text_at_caret(char(key.unicode))
	set_input_as_handled()


func _begin_picker_filename_edit() -> void:
	if file_mode == FileDialog.FILE_MODE_SAVE_FILE or _picker_filename_active:
		return
	var request := TextEntryRequest.for_purpose(TextEntryRequest.Purpose.FILE_PATH)
	request.target = get_line_edit()
	request.host_viewport = get_viewport()
	request.dismissal_policy = TextEntryRequest.DismissalPolicy.KEEP_EDITED
	_picker_filename_active = _text_entry_service.begin(request, _resolved_text_entry_mode())


func _on_picker_filename_focus_exited() -> void:
	call_deferred("_close_picker_entry_unless_focused")


func _close_picker_entry_unless_focused() -> void:
	if not _picker_filename_active:
		return
	var owner := get_viewport().gui_get_focus_owner()
	if owner == get_line_edit() or _text_entry_service.owns_focus(owner):
		return
	_picker_filename_active = false
	if _text_entry_service.session.active:
		_text_entry_service.cancel()


func _on_text_entry_session_ended(submitted: bool, value: String) -> void:
	var request: TextEntryRequest = _text_entry_service.session.request
	if request == null or request.target != _filename_target:
		if request != null and request.target == get_line_edit():
			_picker_filename_active = false
		return
	if not submitted:
		call_deferred("_restore_caller_focus")
		return
	current_file = value
	call_deferred("_open_directory_picker")


func begin_save(suggested_name: String) -> void:
	current_file = suggested_name.get_file()
	_remember_caller_focus()
	_open_filename_entry()


func _open_filename_entry() -> void:
	if not is_inside_tree() or file_mode != FileDialog.FILE_MODE_SAVE_FILE:
		return
	_filename_target.text = current_file.get_file()
	var request := TextEntryRequest.for_purpose(TextEntryRequest.Purpose.FILE_PATH)
	request.title = "Name Export"
	request.prompt = "Filename"
	request.placeholder = "Filename"
	request.confirm_label = "Choose Folder"
	request.target = _filename_target
	request.host_viewport = _game_viewport()
	request.normalizer = _normalize_filename
	request.validator = _filename_error
	request.dismissal_policy = TextEntryRequest.DismissalPolicy.RESTORE_INITIAL
	_text_entry_service.begin(request, _resolved_text_entry_mode())


func _open_directory_picker() -> void:
	var editor := get_line_edit()
	editor.editable = false
	popup_centered_ratio(0.75)
	call_deferred("_focus_file_list")


func _remember_caller_focus() -> void:
	if _text_entry_service.session.active:
		return
	_restore_focus = _game_viewport().gui_get_focus_owner()


func _restore_caller_focus() -> void:
	if is_instance_valid(_restore_focus) and _restore_focus.is_visible_in_tree():
		_restore_focus.grab_focus()
	_restore_focus = null


func _game_viewport() -> Viewport:
	var parent := get_parent()
	return parent.get_viewport() if parent != null else get_tree().root


func _normalize_filename(value: String) -> String:
	return value.strip_edges().replace("\\", "/").get_file()


func _filename_error(value: String) -> StringName:
	if value.ends_with(".") or value.ends_with(" "):
		return &"filename_trailing_character"
	for character in '<>:"/\\|?*':
		if value.contains(character):
			return &"filename_character_invalid"
	var stem := value.get_basename().to_upper()
	if stem in ["CON", "PRN", "AUX", "NUL"]:
		return &"filename_reserved"
	if stem.length() == 4 and stem.left(3) in ["COM", "LPT"] and stem[3].is_valid_int():
		return &"filename_reserved"
	return &""


func _on_picker_canceled() -> void:
	_restore_picker_filename_editor()
	call_deferred("_restore_caller_focus")


func _on_picker_selected(_path: String) -> void:
	_restore_picker_filename_editor()
	_restore_focus = null


func _restore_picker_filename_editor() -> void:
	var editor := get_line_edit()
	editor.editable = true


func _exit_tree() -> void:
	if _text_entry_service != null and _text_entry_service.session.active:
		if _text_entry_service.session.request.target == _filename_target:
			_text_entry_service.cancel()
	if is_instance_valid(_filename_target):
		_filename_target.queue_free()


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
