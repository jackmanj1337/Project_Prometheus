class_name ActionMenu extends Control
# Action menu shown after a unit moves (or acts in place).
# Buttons: Attack / Staff / Item / Wait. Each can be disabled when invalid.
# Emits action_chosen(action_name) when player confirms, hidden_by_cancel when dismissed.
#
# Tile-action visibility (Seize, Escape, …) is routed through the shared
# TileActions helper so the HUD's terrain More Info panel and this menu
# never disagree about what's available on a given tile.

const TileActions = preload("res://scripts/shared/TileActions.gd")

signal action_chosen(action: String)
signal hidden_by_cancel()

@onready var _btn_attack: Button = $VBox/BtnAttack
@onready var _btn_staff:  Button = $VBox/BtnStaff
@onready var _btn_item:   Button = $VBox/BtnItem
@onready var _btn_equip:  Button = $VBox/BtnEquip
@onready var _btn_seize:  Button = $VBox/BtnSeize
@onready var _btn_escape:  Button = $VBox/BtnEscape
@onready var _btn_pair_up: Button = $VBox/BtnPairUp
@onready var _btn_swap:    Button = $VBox/BtnSwap
@onready var _btn_separate: Button = $VBox/BtnSeparate
@onready var _btn_wait:    Button = $VBox/BtnWait

var _focused_idx: int = 0
var _buttons: Array[Button] = []


func _ready() -> void:
	# Seize and Escape are the two map-objective entries; both sit between Equip
	# and Wait so the always-available Wait stays at the bottom. Pair Up and Swap
	# sit between Escape and Wait as the Pair Up section (Separate joins them in
	# step 6c).
	_buttons = [_btn_attack, _btn_staff, _btn_item, _btn_equip, _btn_seize, _btn_escape,
		_btn_pair_up, _btn_swap, _btn_separate, _btn_wait]
	# Hide on press as well as on cancel — otherwise the menu lingers on screen
	# after a choice (it never appeared before the menu-ref fix, so this was latent).
	_btn_attack.pressed.connect(func():  hide(); action_chosen.emit("attack"))
	_btn_staff.pressed.connect(func():   hide(); action_chosen.emit("staff"))
	_btn_item.pressed.connect(func():    hide(); action_chosen.emit("item"))
	_btn_equip.pressed.connect(func():   hide(); action_chosen.emit("equip"))
	_btn_seize.pressed.connect(func():   hide(); action_chosen.emit("seize"))
	_btn_escape.pressed.connect(func():  hide(); action_chosen.emit("escape"))
	_btn_pair_up.pressed.connect(func(): hide(); action_chosen.emit("pair_up"))
	_btn_swap.pressed.connect(func():    hide(); action_chosen.emit("swap_roles"))
	_btn_separate.pressed.connect(func(): hide(); action_chosen.emit("separate"))
	_btn_wait.pressed.connect(func():    hide(); action_chosen.emit("wait"))
	hide()


# Show the menu and configure which buttons are active.
# `turn` is the TurnManager — passed to compute the Seize gate (M16). Optional
# so older callers (incl. test_action_menu's pre-M16 cases) still compile;
# Seize stays hidden when `turn` is null.
func show_for(unit: Node, grid: Node, turn: Node = null) -> void:
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
	var ih := get_node_or_null("/root/ItemHandler")
	if unit.data:
		for entry in unit.data.inventory:
			if entry.is_item() and entry.has_uses() and (ih == null or ih.can_apply_item(unit, entry)):
				has_items = true
				break

	# Equip is offered only with 2+ usable weapons — swapping needs an alternative.
	var has_weapon_swap := false
	if unit.has_method("get_equippable_weapons"):
		has_weapon_swap = unit.get_equippable_weapons().size() >= 2

	# M16 stage 3: Seize is a deliberate, gated entry (Decision 4 / 2026-05-17)
	# — visible only when the active map authors a seize condition that accepts
	# this unit on this tile. Hidden when no TurnManager was passed.
	# Escape (Decision 5 + 2026-05-20 review): deliberate ActionMenu entry,
	# gated by an authored escape condition that names this unit AND a `tiles`
	# zone covering its current tile.
	# Both gates go through TileActions so the HUD's terrain More Info panel
	# shows exactly the same set of available actions.
	var can_seize: bool = TileActions.is_available("seize", unit, unit.tile_position, turn)
	var can_escape: bool = TileActions.is_available("escape", unit, unit.tile_position, turn)

	# Pair Up / Swap visibility. Pair Up is shown when the unit is unpaired
	# AND there is at least one adjacent unpaired ally; Swap when the unit is
	# already paired. The registry holds the unit_id index — fetch via /root
	# so headless tests that omit the autoload still resolve the menu.
	var can_swap := false
	var can_separate := false
	var can_pair_up := false
	if unit != null and unit.data != null and unit.data.unit_id != "":
		var registry := get_node_or_null("/root/PairUpRegistry")
		var gs := get_node_or_null("/root/GameState")
		var pair_up_enabled: bool = true if gs == null else bool(gs.get("pair_up_enabled"))
		if registry != null and registry.has_method("is_paired"):
			if bool(registry.is_paired(unit.data.unit_id)):
				can_swap = true
				can_separate = bool(registry.call("is_lead", unit.data.unit_id)) \
					and _has_adjacent_separate_tile(unit, grid, registry)
			elif pair_up_enabled:
				can_pair_up = _has_adjacent_unpaired_ally(unit, grid, registry)

	# Hide unavailable rows entirely (playtest 3 #21) — the VBoxContainer
	# collapses the gap so the menu shrinks to fit the offered choices, instead
	# of showing greyed-out buttons. Wait is always offered.
	_btn_attack.visible  = has_enemies
	_btn_staff.visible   = has_heal_targets
	_btn_item.visible    = has_items
	_btn_equip.visible   = has_weapon_swap
	_btn_seize.visible   = can_seize
	_btn_escape.visible  = can_escape
	_btn_pair_up.visible = can_pair_up
	_btn_swap.visible    = can_swap
	_btn_separate.visible = can_separate
	_btn_wait.visible    = true

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


# True iff `unit` has at least one adjacent (4-cardinal) ally with a unit_id
# who is also unpaired per the registry. Visibility-only helper — the real
# target-collection happens in MapCursorTargeting.begin(PAIR_UP) and must agree
# with this filter so the button never shows when no targets exist.
func _has_adjacent_unpaired_ally(unit: Node, grid: Node, registry: Node) -> bool:
	if unit == null or grid == null or not grid.has_method("get_unit_at"):
		return false
	if unit.data == null or unit.data.unit_id == "":
		return false
	const _CARDINALS: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)
	]
	for delta in _CARDINALS:
		var neighbor: Node = grid.get_unit_at(unit.tile_position + delta)
		if neighbor == null or neighbor == unit:
			continue
		if not ("team" in neighbor) or neighbor.team != unit.team:
			continue
		if neighbor.data == null or neighbor.data.unit_id == "":
			continue
		if not bool(registry.call("is_paired", neighbor.data.unit_id)):
			return true
	return false


# True iff the paired lead can place its support onto at least one adjacent
# cardinal tile. Separate is only offered on the lead, and only when the
# placement can succeed immediately.
func _has_adjacent_separate_tile(unit: Node, grid: Node, registry: Node) -> bool:
	if unit == null or grid == null or registry == null:
		return false
	if unit.data == null or unit.data.unit_id == "" or not bool(registry.call("is_lead", unit.data.unit_id)):
		return false
	if not grid.has_method("is_passable") or not grid.has_method("can_end_on_tile"):
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs == null or not gs.has_method("find_unit_by_id"):
		return false
	var support_id: String = registry.call("get_partner_id", unit.data.unit_id)
	var support: Node = gs.find_unit_by_id(support_id)
	if support == null or support.data == null or support.data.hp <= 0:
		return false
	const _CARDINALS: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)
	]
	for delta in _CARDINALS:
		var tile: Vector2i = unit.tile_position + delta
		if grid.is_passable(tile, support) and grid.can_end_on_tile(tile, support):
			return true
	return false


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
