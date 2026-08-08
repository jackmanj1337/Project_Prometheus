class_name TextEntrySession
extends Node

signal text_changed(value: String)
signal submitted(value: String)
signal cancelled
signal physical_escape_consumed
signal input_observed(stage: String, focus_owner: String)

var request: TextEntryRequest
var text := ""
var active := false


func begin(next_request: TextEntryRequest) -> void:
	request = next_request
	text = request.validate(request.initial_text)
	active = true
	text_changed.emit(text)


func finish() -> void:
	active = false


func insert(value: String) -> bool:
	if not active or request == null:
		return false
	var validated := request.validate(text + value)
	if validated == text:
		return false
	text = validated
	text_changed.emit(text)
	return true


func backspace() -> bool:
	if not active or text.is_empty():
		return false
	text = text.left(-1)
	text_changed.emit(text)
	return true


func submit() -> bool:
	if not active or request == null or not request.is_submittable(text):
		return false
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
