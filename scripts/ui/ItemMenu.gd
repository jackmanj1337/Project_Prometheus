class_name ItemMenu extends Control
# Item selection menu. Dynamically builds one button per usable inventory item.
# Emits item_chosen(entry) when the player picks one, or cancelled when dismissed.

signal item_chosen(entry: Dictionary)
signal cancelled()

@onready var _vbox: VBoxContainer = $Panel/VBox

var _buttons: Array[Button] = []
var _focused_idx: int = 0


func _ready() -> void:
	hide()


func show_for(unit: Node) -> void:
	# Remove previous buttons (keep static children if any)
	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()

	if unit == null or unit.data == null:
		return

	for entry in unit.data.inventory:
		if entry.get("type", "") != "item":
			continue
		if entry.get("uses_remaining", 0) <= 0:
			continue
		var btn := Button.new()
		var uses: int = entry.get("uses_remaining", 0)
		var item_id: String = entry.get("item_id", "")
		var dm := get_node_or_null("/root/DataManager")
		var item := dm.get_item(item_id) if (dm and item_id != "") else null
		var name_text: String = item.display_name if item else "Item"
		btn.text = "%s  (%d)" % [name_text, uses]
		btn.focus_mode = Control.FOCUS_ALL
		_vbox.add_child(btn)
		var captured: Dictionary = entry  # reference to the inventory dict entry
		btn.pressed.connect(func(): _on_item_pressed(captured))
		_buttons.append(btn)

	if _buttons.is_empty():
		return

	_focused_idx = 0
	_buttons[0].grab_focus()
	show()


func _on_item_pressed(entry: Dictionary) -> void:
	hide()
	item_chosen.emit(entry)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		hide()
		cancelled.emit()
	elif event.is_action_pressed("cursor_up"):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cursor_down"):
		_move_focus(1)
		get_viewport().set_input_as_handled()


func _move_focus(delta: int) -> void:
	if _buttons.is_empty():
		return
	_focused_idx = (_focused_idx + delta + _buttons.size()) % _buttons.size()
	_buttons[_focused_idx].grab_focus()
