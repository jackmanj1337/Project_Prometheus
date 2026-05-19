extends PanelContainer
# Weapon-swap menu (#8). Lists every weapon the unit can currently equip; picking
# one makes it the equipped weapon. Opened from the ActionMenu's "Equip" option —
# swapping is free and does NOT consume the unit's action.
#
# No `class_name`: this is instantiated from its scene and referenced as a plain
# Node by MapCursor, so headless --script test runs need no global class-cache
# entry. Mirrors the ItemMenu list pattern.

signal weapon_chosen(entry: InventoryEntry)
signal cancelled()

@onready var _vbox: VBoxContainer = $VBox

var _buttons: Array[Button] = []
var _focused_idx: int = 0


func _ready() -> void:
	hide()


# Builds one button per equippable weapon. The equipped weapon is first in the
# list (get_equipped_weapon picks the first usable entry) and is marked so the
# player can see what they are swapping away from.
func show_for(unit: Node) -> void:
	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()

	if unit == null or unit.data == null or not unit.has_method("get_equippable_weapons"):
		return

	var weapons: Array = unit.get_equippable_weapons()
	var dm := get_node_or_null("/root/DataManager")
	for i in weapons.size():
		var entry: InventoryEntry = weapons[i]
		var weapon: WeaponData = dm.get_weapon(entry.weapon_id) if (dm and entry.weapon_id != "") else null
		var name_text: String = weapon.display_name if weapon else "Weapon"
		# -1 is the infinite-use sentinel — show ∞ rather than a literal "-1".
		var uses_text: String = "∞" if entry.uses_remaining == -1 else str(entry.uses_remaining)
		var marker: String = "● " if i == 0 else "   "  # weapons[0] is equipped
		var btn := Button.new()
		btn.text = "%s%s  (%s)" % [marker, name_text, uses_text]
		btn.focus_mode = Control.FOCUS_ALL
		_vbox.add_child(btn)
		var captured: InventoryEntry = entry
		btn.pressed.connect(func(): _on_weapon_pressed(captured))
		_buttons.append(btn)

	if _buttons.is_empty():
		return

	_focused_idx = 0
	_buttons[0].grab_focus()
	show()


func _on_weapon_pressed(entry: InventoryEntry) -> void:
	hide()
	weapon_chosen.emit(entry)


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
