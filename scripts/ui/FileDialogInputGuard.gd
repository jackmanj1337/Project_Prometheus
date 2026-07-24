extends FileDialog
# FileDialog owns a separate Window/Viewport, so global input arbitration cannot
# see its filename editor. Printable mirrored gameplay keys are inserted here
# before ui_accept/ui_cancel can consume them.


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	var filename := get_line_edit()
	if (
		key.pressed
		and not key.echo
		and (key.keycode == KEY_ESCAPE or key.physical_keycode == KEY_ESCAPE)
	):
		if filename != null and filename.has_focus():
			filename.release_focus()
			call_deferred("_focus_file_list")
			set_input_as_handled()
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


func _focus_file_list() -> void:
	for node in find_children("*", "Tree", true, false):
		if node is Tree and node.is_visible_in_tree():
			(node as Tree).grab_focus()
			return
