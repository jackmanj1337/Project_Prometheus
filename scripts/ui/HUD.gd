extends Control
# Persistent HUD overlay: phase label, turn counter, unit info panel, terrain info panel.
# Connects to EventBus signals; reads GridManager for terrain data.

@onready var _phase_label: Label = $PhaseLabel
@onready var _turn_label: Label = $TurnLabel
@onready var _unit_panel: PanelContainer = $UnitInfoPanel
@onready var _unit_name: Label = $UnitInfoPanel/VBox/UnitName
@onready var _unit_class: Label = $UnitInfoPanel/VBox/UnitClass
@onready var _unit_hp: Label = $UnitInfoPanel/VBox/UnitHP
@onready var _unit_weapon: Label = $UnitInfoPanel/VBox/UnitWeapon
@onready var _terrain_panel: PanelContainer = $TerrainInfoPanel
@onready var _terrain_name: Label = $TerrainInfoPanel/VBox/TerrainName
@onready var _terrain_def: Label = $TerrainInfoPanel/VBox/TerrainDef
@onready var _terrain_dodge: Label = $TerrainInfoPanel/VBox/TerrainDodge

var _turn: int = 1
var _grid: Node = null  # GridManager reference, set by GameMap


func _ready() -> void:
	_unit_panel.hide()
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.cursor_moved.connect(_on_cursor_moved)
		bus.phase_changed.connect(_on_phase_changed)
		bus.unit_selected.connect(_on_unit_selected)
		bus.unit_deselected.connect(_on_unit_deselected)
	_update_turn_label()
	_on_phase_changed(0)


func setup(grid: Node, turn_node: Node) -> void:
	_grid = grid
	if turn_node:
		turn_node.turn_changed.connect(_on_turn_changed)


func _on_phase_changed(new_phase: int) -> void:
	_phase_label.text = "PLAYER PHASE" if new_phase == 0 else "ENEMY PHASE"


func _on_turn_changed(turn_number: int) -> void:
	_turn = turn_number
	_update_turn_label()


func _on_unit_selected(unit: Node) -> void:
	_show_unit(unit)


func _on_unit_deselected() -> void:
	_unit_panel.hide()


func _on_cursor_moved(tile: Vector2i) -> void:
	_update_terrain(tile)


func _show_unit(unit: Node) -> void:
	if unit == null or unit.data == null:
		_unit_panel.hide()
		return
	_unit_name.text = unit.data.unit_name
	_unit_class.text = unit.data.class_id
	_unit_hp.text = "HP %d / %d" % [unit.data.hp, unit.data.max_hp]
	var wpn := unit.get_equipped_weapon() if unit.has_method("get_equipped_weapon") else null
	_unit_weapon.text = wpn.display_name if wpn != null else "--"
	_unit_panel.show()


func _update_terrain(tile: Vector2i) -> void:
	if _grid == null:
		_grid = _find_grid()
	if _grid == null:
		return
	var terrain: String = _grid.get_terrain_at(tile)
	_terrain_name.text = terrain.capitalize()
	var def_bonus: int = _grid.TERRAIN_DEF_BONUS.get(terrain, 0)
	var dodge_bonus: int = _grid.TERRAIN_DODGE_BONUS.get(terrain, 0)
	_terrain_def.text = "DEF  +%d" % def_bonus
	_terrain_dodge.text = "DODGE +%d" % dodge_bonus


func _find_grid() -> Node:
	# Walk up to GameMap sibling
	var p := get_parent()
	while p:
		var g := p.get_node_or_null("GridManager")
		if g:
			return g
		p = p.get_parent()
	return null


func _update_turn_label() -> void:
	_turn_label.text = "Turn %d" % _turn
