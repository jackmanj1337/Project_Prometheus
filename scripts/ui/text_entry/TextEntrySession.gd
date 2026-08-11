class_name TextEntrySession
extends Node

signal text_changed(value: String)
signal selection_changed(caret: int, anchor: int)
signal validation_changed(code: StringName)
signal submitted(value: String)
signal cancelled
signal physical_escape_consumed
signal input_observed(stage: String, focus_owner: String)

var request: TextEntryRequest
var text := ""
var active := false
var caret := 0
var selection_anchor := 0
var validation_code: StringName = &""


func begin(next_request: TextEntryRequest) -> void:
	request = next_request
	text = request.validate(request.initial_text)
	caret = text.length()
	selection_anchor = caret
	active = true
	text_changed.emit(text)
	selection_changed.emit(caret, selection_anchor)
	_update_validation()


func finish() -> void:
	active = false


func insert(value: String) -> bool:
	if not active or request == null:
		return false
	var bounds := _selection_bounds()
	var candidate := text.left(bounds.x) + value + text.substr(bounds.y)
	var validated := request.validate(candidate)
	if validated == text:
		return false
	text = validated
	caret = mini(bounds.x + value.length(), text.length())
	selection_anchor = caret
	text_changed.emit(text)
	selection_changed.emit(caret, selection_anchor)
	_update_validation()
	return true


func backspace() -> bool:
	if not active or text.is_empty():
		return false
	var bounds := _selection_bounds()
	if bounds.x != bounds.y:
		text = text.left(bounds.x) + text.substr(bounds.y)
		caret = bounds.x
	elif caret > 0:
		text = text.left(caret - 1) + text.substr(caret)
		caret -= 1
	else:
		return false
	selection_anchor = caret
	text_changed.emit(text)
	selection_changed.emit(caret, selection_anchor)
	_update_validation()
	return true


func delete_forward() -> bool:
	if not active:
		return false
	var bounds := _selection_bounds()
	if bounds.x != bounds.y:
		text = text.left(bounds.x) + text.substr(bounds.y)
		caret = bounds.x
	elif caret < text.length():
		text = text.left(caret) + text.substr(caret + 1)
	else:
		return false
	selection_anchor = caret
	text_changed.emit(text)
	selection_changed.emit(caret, selection_anchor)
	_update_validation()
	return true


func set_selection(next_caret: int, next_anchor: int = -1) -> void:
	caret = clampi(next_caret, 0, text.length())
	selection_anchor = caret if next_anchor < 0 else clampi(next_anchor, 0, text.length())
	selection_changed.emit(caret, selection_anchor)


func move_caret(offset: int, extend_selection := false) -> void:
	var anchor := selection_anchor if extend_selection else clampi(caret + offset, 0, text.length())
	caret = clampi(caret + offset, 0, text.length())
	selection_anchor = anchor
	selection_changed.emit(caret, selection_anchor)


func submit() -> bool:
	if not active or request == null or not request.is_submittable(text):
		return false
	text = request.normalize(text)
	active = false
	submitted.emit(text)
	return true


func cancel() -> bool:
	if not active:
		return false
	active = false
	cancelled.emit()
	return true


func handle_physical_escape(event: InputEvent, editor: Control) -> bool:
	if not event is InputEventKey:
		return false
	var key := event as InputEventKey
	if (
		not key.pressed
		or key.echo
		or (key.keycode != KEY_ESCAPE and key.physical_keycode != KEY_ESCAPE)
		or editor == null
		or not editor.has_focus()
	):
		return false
	input_observed.emit("physical_escape", _focus_name(editor.get_viewport()))
	editor.release_focus()
	physical_escape_consumed.emit()
	return true


func observe(stage: String, viewport: Viewport) -> void:
	input_observed.emit(stage, _focus_name(viewport))


func _focus_name(viewport: Viewport) -> String:
	if viewport == null:
		return "<no viewport>"
	var owner := viewport.gui_get_focus_owner()
	return owner.get_path() if owner != null and owner.is_inside_tree() else "<none>"


func _selection_bounds() -> Vector2i:
	return Vector2i(mini(caret, selection_anchor), maxi(caret, selection_anchor))


func _update_validation() -> void:
	validation_code = request.validation_error(text) if request != null else &""
	validation_changed.emit(validation_code)
