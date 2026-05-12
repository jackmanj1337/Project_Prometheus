class_name GridManager extends Node
# Authority on map geometry: terrain queries, tile/world conversions, movement
# range, pathfinding, and attack range. Reads terrain from an assigned TileMapLayer
# so that terrain is data-driven (painted in the editor, not hardcoded).

var map_width: int = 0
var map_height: int = 0

# Assigned by GameMap when the map loads
var _tilemap: TileMapLayer = null

# Overlay layer for movement/attack/heal/danger highlights (4 colored tiles)
var _overlay: TileMapLayer = null

# Optional fallback when no TileMapLayer is assigned (tests, headless).
# Maps Vector2i tile -> String terrain type.
var _terrain_fallback: Dictionary = {}


# Move costs per terrain type (GDD_02)
const _DEFAULT_MOVE_COSTS: Dictionary = {
	"plain":    1,
	"forest":   2,
	"mountain": 3,
	"fort":     1,
	"sea":      2,
	"desert":   2,
	"wall":     999,
}

# Terrain DEF/Dodge bonuses applied to defenders only (GDD_02)
const TERRAIN_DEF_BONUS: Dictionary = {
	"plain": 0, "forest": 1, "mountain": 2, "fort": 2,
	"sea": 0, "desert": 0, "wall": 0,
}
const TERRAIN_DODGE_BONUS: Dictionary = {
	"plain": 0, "forest": 15, "mountain": 20, "fort": 30,
	"sea": 10, "desert": 5, "wall": 0,
}


# Called by GameMap during _ready() to wire the layers.
func setup(terrain_layer: TileMapLayer, overlay_layer: TileMapLayer,
		width: int, height: int) -> void:
	_tilemap = terrain_layer
	_overlay = overlay_layer
	map_width = width
	map_height = height


# Out-of-bounds tiles count as walls so callers don't need explicit bounds checks.
func get_terrain_at(tile: Vector2i) -> String:
	if _tilemap != null:
		var tile_data := _tilemap.get_cell_tile_data(tile)
		if tile_data == null:
			return "wall"
		var terrain: Variant = tile_data.get_custom_data("terrain_type")
		if terrain == null or terrain == "":
			return "wall"
		return terrain
	# Fallback for headless tests
	if _terrain_fallback.has(tile):
		return _terrain_fallback[tile]
	return "wall"


# Test helper: assigns terrain to a tile when no TileMapLayer is in use
func set_terrain_fallback(tile: Vector2i, terrain: String) -> void:
	_terrain_fallback[tile] = terrain


func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x) / GameConstants.TILE_SIZE, int(world_pos.y) / GameConstants.TILE_SIZE)


# Returns the top-left corner of the tile in world space.
func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * GameConstants.TILE_SIZE, tile.y * GameConstants.TILE_SIZE)


# Move cost factors in unit special qualities per GDD_02 desert rule.
# Checks SkillHandler for movement overrides (Acrobat, Pass, Nimble) first.
func get_move_cost(tile: Vector2i, unit: Node) -> int:
	var terrain := get_terrain_at(tile)

	# Skill override check (stubs return -1 until M9 skills are implemented)
	if unit != null and is_inside_tree():
		var sh := get_node_or_null("/root/SkillHandler")
		if sh:
			var override: int = sh.get_move_cost_override(unit, terrain)
			if override != -1:
				return override

	var base: int = _DEFAULT_MOVE_COSTS.get(terrain, 1)

	# Desert exception: armoured/mounted cost 3; magic-using line cost 1
	if terrain == "desert" and unit != null:
		if unit.has_method("has_quality"):
			if unit.has_quality("armoured") or unit.has_quality("mounted"):
				return 3
			# Magic users / thief line uniformly use 1; for MVP just check class id
			var class_id: String = unit.data.class_id if unit.data else ""
			if class_id in ["mage", "cleric"]:
				return 1
	return base


# Wall tiles are impassable to all units unless the Phasing skill is active.
# Enemy-occupied tiles block movement unless the Pass skill is active.
func is_passable(tile: Vector2i, unit: Node) -> bool:
	var terrain := get_terrain_at(tile)
	if terrain == "wall":
		# Phasing skill (Sage promotion) can pass through walls — stub returns false
		if unit != null and is_inside_tree():
			var sh := get_node_or_null("/root/SkillHandler")
			if sh and sh.can_phase_through(unit, terrain):
				return true
		return false
	var occupant := get_unit_at(tile)
	if occupant != null and occupant != unit:
		# Enemy units block; same-team allies can be passed through during movement
		if unit != null and unit.has_method("get") and "team" in unit and "team" in occupant:
			if unit.team != occupant.team:
				# Pass skill (Trickster) allows moving through enemies — stub returns false
				if is_inside_tree():
					var sh := get_node_or_null("/root/SkillHandler")
					if sh and sh.can_pass_through_enemies(unit):
						return true
				return false
	return true


# Separate from is_passable: can the unit END their move on this tile?
# A unit with Pass can move through enemy tiles but cannot stop on one.
func can_end_on_tile(tile: Vector2i, unit: Node) -> bool:
	var occupant := get_unit_at(tile)
	if occupant == null or occupant == unit:
		return true
	# Cannot stack on allies OR end on enemies (even with Pass)
	return false


# Resolves to GameState.all_units when this node is in the scene tree.
# Returns [] in --script test mode where the autoload isn't registered.
# Decoupling like this lets us test GridManager without spinning up GameState.
func _get_units() -> Array:
	if is_inside_tree():
		var gs := get_node_or_null("/root/GameState")
		if gs:
			return gs.all_units
	return []


# Linear scan of all units for the given tile. Returns null if empty.
func get_unit_at(tile: Vector2i) -> Node:
	for u in _get_units():
		if u.tile_position == tile:
			return u
	return null


# 4-direction adjacency (no diagonals per GDD_02)
const _DIRS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
]


# Dijkstra over move costs from unit's tile, capped at unit.data.movement.
# Tiles with enemy units occupying are NOT included even if reachable
# (you can't end your move on an enemy). Allies don't block traversal.
func get_movement_range(unit: Node) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if unit == null:
		return result
	var max_cost: int = unit.data.movement
	var start: Vector2i = unit.tile_position

	# Best known cost-to-reach for each tile
	var costs: Dictionary = {start: 0}
	# Open set: priority by lowest accumulated cost
	var frontier: Array[Vector2i] = [start]

	while not frontier.is_empty():
		# Pop the lowest-cost tile (small N, simple linear scan is fine for MVP)
		var best_idx := 0
		for i in frontier.size():
			if costs[frontier[i]] < costs[frontier[best_idx]]:
				best_idx = i
		var current: Vector2i = frontier[best_idx]
		frontier.remove_at(best_idx)
		var current_cost: int = costs[current]

		for d in _DIRS:
			var next: Vector2i = current + d
			if get_terrain_at(next) == "wall":
				continue
			# Enemy units block traversal
			var occupant := get_unit_at(next)
			if occupant != null and occupant != unit and "team" in occupant and occupant.team != unit.team:
				continue
			var step_cost := get_move_cost(next, unit)
			var total: int = current_cost + step_cost
			if total > max_cost:
				continue
			if not costs.has(next) or total < costs[next]:
				costs[next] = total
				frontier.append(next)

	# Build the result list: any reachable tile not currently occupied by another unit
	for tile in costs.keys():
		var occ := get_unit_at(tile)
		if occ == null or occ == unit:
			result.append(tile)
	return result


# BFS-style traceback using move costs. Returns ordered tile list from unit's
# current tile to target_tile inclusive. Empty if unreachable.
func get_movement_path(unit: Node, target_tile: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if unit == null:
		return path
	var max_cost: int = unit.data.movement
	var start: Vector2i = unit.tile_position
	if start == target_tile:
		path.append(start)
		return path

	var costs: Dictionary = {start: 0}
	var came_from: Dictionary = {}
	var frontier: Array[Vector2i] = [start]
	var found := false

	while not frontier.is_empty():
		var best_idx := 0
		for i in frontier.size():
			if costs[frontier[i]] < costs[frontier[best_idx]]:
				best_idx = i
		var current: Vector2i = frontier[best_idx]
		frontier.remove_at(best_idx)
		if current == target_tile:
			found = true
			break
		var current_cost: int = costs[current]

		for d in _DIRS:
			var next: Vector2i = current + d
			if get_terrain_at(next) == "wall":
				continue
			var occupant := get_unit_at(next)
			if occupant != null and occupant != unit and "team" in occupant and occupant.team != unit.team:
				continue
			var step_cost := get_move_cost(next, unit)
			var total: int = current_cost + step_cost
			if total > max_cost:
				continue
			if not costs.has(next) or total < costs[next]:
				costs[next] = total
				came_from[next] = current
				frontier.append(next)

	if not found:
		return path

	# Reconstruct path from target back to start
	var node: Vector2i = target_tile
	path.append(node)
	while came_from.has(node):
		node = came_from[node]
		path.push_front(node)
	return path


# Reads the unit's currently equipped weapon's range. Returns (1, 1) when the
# unit has no usable weapon — get_attackable_enemies_from_tile then returns []
# but the caller can still query "what tiles would I threaten if armed".
func _get_weapon_range(unit: Node) -> Vector2i:
	if unit == null or not unit.has_method("get_equipped_weapon"):
		return Vector2i(1, 1)
	var weapon = unit.get_equipped_weapon()
	if weapon == null:
		return Vector2i(1, 1)
	return Vector2i(weapon.range_min, weapon.range_max)


# Manhattan-distance ring at distances [range_min, range_max] from a tile.
func _tiles_in_range(center: Vector2i, range_min: int, range_max: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in range(-range_max, range_max + 1):
		for dy in range(-range_max, range_max + 1):
			var dist := absi(dx) + absi(dy)
			if dist >= range_min and dist <= range_max:
				out.append(center + Vector2i(dx, dy))
	return out


# All tiles attackable from any tile in from_tiles, excluding from_tiles themselves.
# Used to draw the red attack overlay around the blue movement overlay.
func get_attack_range_from_tiles(unit: Node, from_tiles: Array[Vector2i]) -> Array[Vector2i]:
	var wrange := _get_weapon_range(unit)
	var seen: Dictionary = {}
	var from_set: Dictionary = {}
	for t in from_tiles:
		from_set[t] = true
	for src in from_tiles:
		for tile in _tiles_in_range(src, wrange.x, wrange.y):
			if not from_set.has(tile) and not seen.has(tile):
				seen[tile] = true
	var out: Array[Vector2i] = []
	for k in seen.keys():
		out.append(k)
	return out


# Union of from_tiles and all attackable tiles. Used by AI scoring.
func get_all_attack_tiles(unit: Node, from_tiles: Array[Vector2i]) -> Array[Vector2i]:
	var wrange := _get_weapon_range(unit)
	var seen: Dictionary = {}
	for src in from_tiles:
		seen[src] = true
		for tile in _tiles_in_range(src, wrange.x, wrange.y):
			seen[tile] = true
	var out: Array[Vector2i] = []
	for k in seen.keys():
		out.append(k)
	return out


# Enemies the unit could hit from `tile`, given its equipped weapon's range.
func get_attackable_enemies_from_tile(unit: Node, tile: Vector2i) -> Array[Node]:
	var out: Array[Node] = []
	if unit == null:
		return out
	var wrange := _get_weapon_range(unit)
	for target in _get_units():
		if "team" in target and target.team == unit.team:
			continue
		if target.data.hp <= 0:
			continue
		var dist: int = absi(target.tile_position.x - tile.x) + absi(target.tile_position.y - tile.y)
		if dist >= wrange.x and dist <= wrange.y:
			out.append(target)
	return out


func can_attack_from_tile(attacker: Node, at_tile: Vector2i, target: Node) -> bool:
	if attacker == null or target == null:
		return false
	var wrange := _get_weapon_range(attacker)
	var dist: int = absi(target.tile_position.x - at_tile.x) + absi(target.tile_position.y - at_tile.y)
	return dist >= wrange.x and dist <= wrange.y


# Allies within staff range whose HP is below max. Used for staff target selection.
# Reads the unit's equipped weapon range — if it's a staff, that's the heal range.
func get_healable_allies(unit: Node) -> Array[Node]:
	var out: Array[Node] = []
	if unit == null:
		return out
	var wrange := _get_weapon_range(unit)
	for ally in _get_units():
		if not ("team" in ally) or ally.team != unit.team:
			continue
		if ally == unit:
			continue
		if ally.data.hp >= ally.data.max_hp:
			continue
		var dist: int = absi(ally.tile_position.x - unit.tile_position.x) + absi(ally.tile_position.y - unit.tile_position.y)
		if dist >= wrange.x and dist <= wrange.y:
			out.append(ally)
	return out


# Overlay tile source IDs (assigned to overlay TileMapLayer in editor):
#   0: Blue (movement), 1: Red (attack), 2: Green (heal), 3: Dark red (danger)
const OVERLAY_BLUE := 0
const OVERLAY_RED := 1
const OVERLAY_GREEN := 2
const OVERLAY_DARK_RED := 3


func _paint_overlay(tiles: Array[Vector2i], source_id: int) -> void:
	if _overlay == null:
		return
	for t in tiles:
		_overlay.set_cell(t, source_id, Vector2i.ZERO)


func show_movement_overlay(tiles: Array[Vector2i]) -> void:
	_paint_overlay(tiles, OVERLAY_BLUE)


func show_attack_overlay(tiles: Array[Vector2i]) -> void:
	_paint_overlay(tiles, OVERLAY_RED)


func show_heal_overlay(tiles: Array[Vector2i]) -> void:
	_paint_overlay(tiles, OVERLAY_GREEN)


# Paints union of every enemy unit's attack range so the player can see threats.
# Triggered by Q key / middle mouse via MapCursor.
func show_enemy_danger_zone() -> void:
	if _overlay == null:
		return
	var seen: Dictionary = {}
	for u in _get_units():
		if not ("team" in u) or u.team != "enemy":
			continue
		if u.data.hp <= 0:
			continue
		var wrange := _get_weapon_range(u)
		for t in _tiles_in_range(u.tile_position, wrange.x, wrange.y):
			seen[t] = true
	for tile in seen.keys():
		_overlay.set_cell(tile, OVERLAY_DARK_RED, Vector2i.ZERO)


# Clears every painted overlay tile. Called between selection states and at phase change.
func clear_overlays() -> void:
	if _overlay == null:
		return
	_overlay.clear()
