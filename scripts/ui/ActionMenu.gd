class_name ActionMenu extends Control
# Action menu shown after a unit moves (or acts in place).
# Buttons: Attack / Staff / Item / Wait. Each can be disabled when invalid.
# Emits action_chosen(action_name) when player confirms, hidden_by_cancel when dismissed.

signal action_chosen(action: String)
signal hidden_by_cancel()

@onready var _btn_attack: Button = $VBox/BtnAttack
@onready var _btn_staff:  Button = $VBox/BtnStaff
@onready var _btn_item:   Button = $VBox/BtnItem
@onready var _btn_equip:  Button = $VBox/BtnEquip
@onready var _btn_wait:   Button = $VBox/BtnWait

var _focused_idx: int = 0
var _buttons: Array[Button] = []


func _ready() -> void:
	_buttons = [_btn_attack, _btn_staff, _btn_item, _btn_equip, _btn_wait]
	# Hide on press as well as on cancel — otherwise the menu lingers on screen
	# after a choice (it never appeared before the menu-ref fix, so this was latent).
	_btn_attack.pressed.connect(func(): hide(); action_chosen.emit("attack"))
	_btn_staff.pressed.connect(func():  hide(); action_chosen.emit("staff"))
	_btn_item.pressed.connect(func():   hide(); action_chosen.emit("item"))
	_btn_equip.pressed.connect(func():  hide(); action_chosen.emit("equip"))
	_btn_wait.pressed.connect(func():   hide(); action_chosen.emit("wait"))
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

		# Staff check: equipped weapon is a healing staff. Keys off is_healing_staff()
		# (the heal tag) — not weapon_type — so a future offensive staff won't offer Staff.
		var staff_weapon = unit.get_equipped_weapon()
		if staff_weapon and staff_weapon.is_healing_staff():
			var allies: Array = grid.get_healable_allies(unit)
			has_heal_targets = allies.size() > 0

	# Items: any inventory entry of type "item" with uses remaining
	if unit.data:
		for entry in unit.data.inventory:
			if entry.is_item() and entry.has_uses():
				has_items = true
				break

	# Equip is offered only with 2+ usable weapons — swapping needs an alternative.
	var has_weapon_swap := false
	if unit.has_method("get_equippable_weapons"):
		has_weapon_swap = unit.get_equippable_weapons().size() >= 2

	# Hide unavailable rows entirely (playtest 3 #21) — the VBoxContainer
	# collapses the gap so the menu shrinks to fit the offered choices, instead
	# of showing greyed-out buttons. Wait is always offered.
	_btn_attack.visible = has_enemies
	_btn_staff.visible  = has_heal_targets
	_btn_item.visible   = has_items
	_btn_equip.visible  = has_weapon_swap
	_btn_wait.visible   = true

	# Focus first visible button — keyboard nav also skips hidden ones below.
	_focused_idx = 0
	for i in _buttons.size():
		if _buttons[i].visible:
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
		if _buttons[i].visible:
			_focused_idx = i
			_buttons[_focused_idx].grab_focus()
			break
		if i == start:
			push_error("ActionMenu: all buttons hidden — Wait should always be visible")
			break
