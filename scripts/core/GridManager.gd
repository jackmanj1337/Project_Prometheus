class_name GridManager extends Node
# Authority on map geometry: terrain queries, tile/world conversions, movement
# range, pathfinding, and attack range. Reads terrain from an assigned TileMapLayer
# so that terrain is data-driven (painted in the editor, not hardcoded).

# GDD discrepancy note: GDD_01 specifies TILE_SIZE = 32, GDD_06 specifies 64x64
# tiles. Using 64 to match GDD_06's tileset spec and the placeholder sprite sizes.
const TILE_SIZE: int = 64

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
	return Vector2i(int(world_pos.x) / TILE_SIZE, int(world_pos.y) / TILE_SIZE)


# Returns the top-left corner of the tile in world space.
func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * TILE_SIZE, tile.y * TILE_SIZE)


# Move cost factors in unit special qualities per GDD_02 desert rule.
func get_move_cost(tile: Vector2i, unit: Node) -> int:
	var terrain := get_terrain_at(tile)
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


# Wall tiles are impassable to all (MVP — flying does not bypass walls per GDD_02).
# Tiles occupied by enemy units block movement (allies can be passed through).
func is_passable(tile: Vector2i, unit: Node) -> bool:
	var terrain := get_terrain_at(tile)
	if terrain == "wall":
		return false
	var occupant := get_unit_at(tile)
	if occupant != null and occupant != unit:
		# Enemy units block; same-team allies can be passed through during movement
		if unit != null and unit.has_method("get") and "team" in unit and "team" in occupant:
			if unit.team != occupant.team:
				return false
	return true


# Linear scan of GameState.all_units for the given tile. Returns null if empty.
func get_unit_at(tile: Vector2i) -> Node:
	for u in GameState.all_units:
		if u.tile_position == tile:
			return u
	return null
