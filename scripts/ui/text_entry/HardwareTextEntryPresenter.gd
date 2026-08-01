class_name HardwareTextEntryPresenter
extends Node

signal character_entered(value: String)
signal action_invoked(action: StringName)

var request: TextEntryRequest
var enabled := false


func configure(next_request: TextEntryRequest) -> void:
	request = next_request
	enabled = request != null


func handle(event: InputEvent) -> bool:
	if not enabled or not event is InputEventKey:
		return false
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return false
	if key.keycode == KEY_BACKSPACE:
		action_invoked.emit(&"backspace")
		return true
	if key.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		action_invoked.emit(&"submit")
		return true
	if key.keycode == KEY_ESCAPE:
		action_invoked.emit(&"cancel")
		return true
	if key.ctrl_pressed or key.alt_pressed or key.meta_pressed or key.unicode < 32:
		return false
	var value := char(key.unicode)
	if not request.accepts(value):
		return false
	character_entered.emit(value)
	return true
