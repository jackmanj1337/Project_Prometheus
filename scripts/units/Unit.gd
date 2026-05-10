class_name Unit extends Node2D
# A single unit on the battlefield. Wraps a UnitData resource and provides
# combat math, movement, and visual state.
#
# Responsibilities are split:
#   - This file: identity, position, HP/state changes, movement animation
#   - UnitStatBlock.gd (helper): stat math that factors in terrain, S-rank, conditions

# Set by initialize()
var data: UnitData
var tile_position: Vector2i = Vector2i.ZERO
var team: String = "player"  # "player" | "enemy"

# Stored when a unit starts moving so `undo_move` can restore the position
var _original_tile: Vector2i = Vector2i.ZERO

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hp_bar: ProgressBar = $HPBar


# Called by GameMap right after scene instancing. Must be invoked before _ready
# can finish using the data, so the spawner uses call_deferred carefully or sets
# the values before adding to the tree.
func initialize(unit_data: UnitData, start_tile: Vector2i, unit_team: String) -> void:
	data = unit_data
	tile_position = start_tile
	team = unit_team
	# Visual position is set after _ready when nodes are available
	if is_inside_tree():
		_apply_initial_state()


func _ready() -> void:
	if data != null:
		_apply_initial_state()


# Sets sprite tint, HP bar, and world position. Idempotent.
func _apply_initial_state() -> void:
	if _sprite == null or _hp_bar == null:
		return
	# Player units render in blue tint, enemies in red tint (placeholder visuals).
	# When real sprites land we use class_id for sprite selection instead.
	if team == "enemy":
		_sprite.modulate = Color(0.95, 0.35, 0.35, 1.0)
	else:
		_sprite.modulate = Color(0.30, 0.55, 0.95, 1.0)
	_hp_bar.max_value = data.max_hp
	_hp_bar.value = data.hp
	# Snap world position to tile (TILE_SIZE px per tile)
	position = Vector2(tile_position.x * GridManager.TILE_SIZE,
		tile_position.y * GridManager.TILE_SIZE)


# True if the unit's class has the given quality (per ClassData.special_qualities)
# OR the unit has been granted it via skill/item. For MVP only class qualities apply.
func has_quality(quality: String) -> bool:
	if data == null:
		return false
	var class_data := _get_class_data()
	if class_data == null:
		return false
	return quality in class_data.special_qualities


func _get_class_data() -> ClassData:
	if data == null:
		return null
	# Use runtime lookup so this works in --script test mode without DataManager
	if is_inside_tree():
		var dm := get_node_or_null("/root/DataManager")
		if dm:
			return dm.get_class_data(data.class_id)
	# Fallback: load directly. Slower per-call but tests don't need DataManager.
	var path := "res://data/classes/%s.tres" % data.class_id
	if ResourceLoader.exists(path):
		return load(path)
	return null


# Returns the first weapon entry in inventory the unit can actually use:
# - type == "weapon"
# - uses_remaining > 0
# - rank check (unit's proficiency rank >= weapon rank)
func get_equipped_weapon() -> WeaponData:
	var entry := get_equipped_weapon_entry()
	if entry.is_empty():
		return null
	return _load_weapon(entry["weapon_id"])


# Same as get_equipped_weapon but returns the inventory dict (so callers can
# decrement uses_remaining or read forge mods).
func get_equipped_weapon_entry() -> Dictionary:
	if data == null:
		return {}
	for entry in data.inventory:
		if entry.get("type", "") != "weapon":
			continue
		if entry.get("uses_remaining", 0) <= 0:
			continue
		var weapon := _load_weapon(entry["weapon_id"])
		if weapon == null:
			continue
		if not _can_equip_rank(weapon):
			continue
		return entry
	return {}


func _load_weapon(id: String) -> WeaponData:
	if is_inside_tree():
		var dm := get_node_or_null("/root/DataManager")
		if dm:
			return dm.get_weapon(id)
	var path := "res://data/weapons/%s.tres" % id
	if ResourceLoader.exists(path):
		return load(path)
	return null


# Rank order: E < D < C < B < A < S (small lookup map)
const _RANK_ORDER := {"E": 0, "D": 1, "C": 2, "B": 3, "A": 4, "S": 5}


func _can_equip_rank(weapon: WeaponData) -> bool:
	if not data.proficiencies.has(weapon.weapon_type):
		return false
	var unit_rank: String = data.proficiencies[weapon.weapon_type].get("rank", "E")
	return _RANK_ORDER.get(unit_rank, 0) >= _RANK_ORDER.get(weapon.rank, 0)


# Reads terrain bonuses from GridManager; only applies when this unit is the
# defender in combat (per GDD_02).
func get_terrain_def_bonus() -> int:
	var grid := _get_grid_manager()
	if grid == null:
		return 0
	var terrain := grid.get_terrain_at(tile_position)
	return GridManager.TERRAIN_DEF_BONUS.get(terrain, 0)


func get_terrain_dodge_bonus() -> int:
	var grid := _get_grid_manager()
	if grid == null:
		return 0
	var terrain := grid.get_terrain_at(tile_position)
	return GridManager.TERRAIN_DODGE_BONUS.get(terrain, 0)


func _get_grid_manager() -> GridManager:
	# Walk up the tree to find a sibling GridManager under GameMap
	if not is_inside_tree():
		return null
	var n := get_parent()
	while n:
		var g := n.get_node_or_null("GridManager")
		if g and g is GridManager:
			return g
		n = n.get_parent()
	return null
