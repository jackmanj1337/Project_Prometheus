class_name ItemMenu extends Control
# Item selection menu. Dynamically builds one button per usable inventory item.
# Emits item_chosen(entry) when the player picks one, or cancelled when dismissed.

const MenuScale = preload("res://scripts/ui/MenuScale.gd")

signal item_chosen(entry: InventoryEntry)
signal cancelled()

@onready var _vbox: VBoxContainer = $VBox

var _buttons: Array[Button] = []
var _focused_idx: int = 0


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	_apply_menu_scale_from_settings()
	hide()


func apply_menu_scale(factor: float) -> void:
	MenuScale.apply_to(self, factor, false)


func _apply_menu_scale_from_settings() -> void:
	apply_menu_scale(MenuScale.factor_from_settings(self))


func show_for(unit: Node) -> void:
	# Remove previous buttons (keep static children if any)
	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()

	if unit == null or unit.data == null:
		return
	var ih := get_node_or_null("/root/ItemHandler")

	for entry in unit.data.inventory:
		if not entry.is_item():
			continue
		if not entry.has_uses():
			continue
		if ih != null and not ih.can_apply_item(unit, entry):
			continue
		var btn := Button.new()
		var dm := get_node_or_null("/root/DataManager")
		var item: ItemData = dm.get_item(entry.item_id) if (dm and entry.item_id != "") else null
		var name_text: String = item.display_name if item else "Item"
		# -1 is the infinite-use sentinel — show ∞ rather than a literal "-1".
		var uses_text: String = "∞" if entry.uses_remaining == -1 else str(entry.uses_remaining)
		btn.text = "%s  (%s)" % [name_text, uses_text]
		btn.focus_mode = Control.FOCUS_ALL
		_vbox.add_child(btn)
		var captured: InventoryEntry = entry
		btn.pressed.connect(func(): _on_item_pressed(captured))
		_buttons.append(btn)

	if _buttons.is_empty():
		return

	_focused_idx = 0
	_buttons[0].grab_focus()
	_apply_menu_scale_from_settings()
	show()


func _on_item_pressed(entry: InventoryEntry) -> void:
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
