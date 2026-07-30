class_name GridTextEntryPresenter
extends Control

signal character_entered(value: String)
signal action_invoked(action: StringName)

var layout: TextEntryLayout
var request: TextEntryRequest
var active_layer := "ABC"
var _rows: Array = []
var _position := Vector2i.ZERO


func configure(next_layout: TextEntryLayout, next_request: TextEntryRequest) -> bool:
	if next_layout == null or not next_layout.is_valid() or next_request == null:
		return false
	layout = next_layout
	request = next_request
	_rebuild()
	return true


func set_layer(layer_name: String) -> bool:
	if layout == null or not layout.layers.has(layer_name):
		return false
	active_layer = layer_name
	_position = Vector2i.ZERO
	_rebuild()
	return true


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_rows.clear()
	var column := VBoxContainer.new()
	add_child(column)
	for row_data: Array in layout.layers[active_layer]:
		var row_box := HBoxContainer.new()
		column.add_child(row_box)
		var row: Array = []
		for key_data: Dictionary in row_data:
			var button := Button.new()
			var emitted := str(key_data.get("emit", ""))
			var action := StringName(str(key_data.get("action", "")))
			button.text = emitted if not emitted.is_empty() else str(action).capitalize()
			button.focus_mode = Control.FOCUS_ALL
			button.disabled = not emitted.is_empty() and not request.accepts(emitted)
			button.tooltip_text = (
				"Character is not allowed for this field" if button.disabled else ""
			)
			button.pressed.connect(_activate.bind(emitted, action, button))
			row_box.add_child(button)
			row.append(button)
		_rows.append(row)
	_move_to_enabled(Vector2i.ZERO, Vector2i.RIGHT)


func _gui_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var direction := Vector2i.ZERO
	if event.is_action("ui_left"):
		direction = Vector2i.LEFT
	elif event.is_action("ui_right"):
		direction = Vector2i.RIGHT
	elif event.is_action("ui_up"):
		direction = Vector2i.UP
	elif event.is_action("ui_down"):
		direction = Vector2i.DOWN
	elif event.is_action("ui_accept") and not _rows.is_empty():
		(_rows[_position.y][_position.x] as Button).emit_signal("pressed")
		accept_event()
		return
	else:
		return
	_move_to_enabled(_position + direction, direction)
	accept_event()


func _move_to_enabled(candidate: Vector2i, direction: Vector2i) -> void:
	if _rows.is_empty():
		return
	var attempts := 0
	while attempts < 256:
		candidate.y = posmod(candidate.y, _rows.size())
		candidate.x = posmod(candidate.x, _rows[candidate.y].size())
		var button := _rows[candidate.y][candidate.x] as Button
		if not button.disabled:
			_position = candidate
			button.grab_focus()
			return
		candidate += direction
		attempts += 1


func _activate(emitted: String, action: StringName, button: Button) -> void:
	if button.disabled:
		return
	if not emitted.is_empty():
		character_entered.emit(emitted)
	else:
		action_invoked.emit(action)
