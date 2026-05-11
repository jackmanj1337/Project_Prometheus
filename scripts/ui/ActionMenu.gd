class_name ActionMenu extends Control
# Action menu shown after a unit moves (or acts in place).
# Buttons: Attack / Staff / Item / Wait. Each can be disabled when invalid.
# Emits action_chosen(action_name) when player confirms, hidden_by_cancel when dismissed.

signal action_chosen(action: String)
signal hidden_by_cancel()

@onready var _btn_attack: Button = $Panel/VBox/BtnAttack
@onready var _btn_staff:  Button = $Panel/VBox/BtnStaff
@onready var _btn_item:   Button = $Panel/VBox/BtnItem
@onready var _btn_wait:   Button = $Panel/VBox/BtnWait

var _focused_idx: int = 0
var _buttons: Array[Button] = []


func _ready() -> void:
	_buttons = [_btn_attack, _btn_staff, _btn_item, _btn_wait]
	_btn_attack.pressed.connect(func(): action_chosen.emit("attack"))
	_btn_staff.pressed.connect(func():  action_chosen.emit("staff"))
	_btn_item.pressed.connect(func():   action_chosen.emit("item"))
	_btn_wait.pressed.connect(func():   action_chosen.emit("wait"))
	hide()


# Show the menu and configure which buttons are active.
func show_for(unit: Node, grid: Node) -> void:
	var has_weapon := unit.get_equipped_weapon() != null
	var has_enemies := false
	var has_heal_targets := false
	var has_items := false

	if grid:
		# Enemies reachable from unit's current tile
		var attackable: Array = grid.get_attackable_enemies_from_tile(unit, unit.tile_position)
		has_enemies = has_weapon and attackable.size() > 0

		# Staff check: equipped weapon is a staff with the heal tag
		var staff_weapon = unit.get_equipped_weapon()
		if staff_weapon and staff_weapon.weapon_type == "staff":
			var allies: Array = grid.get_healable_allies(unit)
			has_heal_targets = allies.size() > 0

	# Items: any inventory entry of type "item" with uses remaining
	if unit.data:
		for entry in unit.data.inventory:
			if entry.get("type", "") == "item" and entry.get("uses_remaining", 0) > 0:
				has_items = true
				break

	_btn_attack.disabled = not has_enemies
	_btn_staff.disabled  = not has_heal_targets
	_btn_item.disabled   = not has_items

	# Focus first enabled button
	_focused_idx = 0
	for i in _buttons.size():
		if not _buttons[i].disabled:
			_focused_idx = i
			break
	_buttons[_focused_idx].grab_focus()
	show()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		hide()
		hidden_by_cancel.emit()
		return
	if event.is_action_pressed("cursor_up"):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cursor_down"):
		_move_focus(1)
		get_viewport().set_input_as_handled()


func _move_focus(delta: int) -> void:
	var start := _focused_idx
	var i := _focused_idx
	while true:
		i = (i + delta + _buttons.size()) % _buttons.size()
		if not _buttons[i].disabled:
			_focused_idx = i
			_buttons[_focused_idx].grab_focus()
			break
		if i == start:
			break  # all disabled; shouldn't happen if Wait is always enabled
