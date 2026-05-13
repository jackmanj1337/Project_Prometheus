class_name GameMap extends Node2D
# The root scene for any battle. Loads MapData, paints the terrain from its string grid,
# and spawns units. Adding a new map = adding a new MapData resource; no code changes.

# Source IDs match generate_tilesets.gd ordering. Also referenced by test_map_grid.gd.
const _CHAR_TO_SOURCE := {
	".": 0,  # plain
	"F": 1,  # forest
	"M": 2,  # mountain
	"T": 3,  # fort
	"S": 4,  # sea
	"D": 5,  # desert
	"W": 6,  # wall
}

# Path to the active map's MapData resource. Defaults to map_001 for MVP.
# Will be set externally (e.g. by MainMenu) once campaign/chapter select lands.
@export var map_data_path: String = "res://data/maps/map_001_rout/map_001_data.tres"

# Packed scene used to instance unit nodes
@export var unit_scene: PackedScene = preload("res://scenes/units/Unit.tscn")

@onready var _terrain_layer: TileMapLayer = $TileMapLayer_Terrain
@onready var _overlay_layer: TileMapLayer = $TileMapLayer_Overlay
@onready var _units_container: Node2D = $UnitsContainer
@onready var _grid: GridManager = $GridManager
@onready var _cursor: MapCursor = $MapCursor
@onready var _camera: Camera2D = $Camera2D
@onready var _turn_manager: TurnManager = $TurnManager
@onready var _hud: Control = $HUDMainLayer/HUD

var map_data: MapData = null


func _ready() -> void:
	# Load data first — terrain painting and grid setup both depend on map_data.grid.
	_load_map_data()
	if map_data == null or map_data.grid.is_empty():
		push_error("GameMap: no grid in MapData; cannot paint terrain")
		return
	var map_width: int = map_data.grid[0].length()
	var map_height: int = map_data.grid.size()
	_validate_map(map_data.grid, map_width, map_height)
	_paint_terrain(map_data.grid, map_width, map_height)
	_grid.setup(_terrain_layer, _overlay_layer, map_width, map_height)
	_cursor.setup(_grid, _camera, _turn_manager)
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = map_width * GameConstants.TILE_SIZE
	_camera.limit_bottom = map_height * GameConstants.TILE_SIZE
	_camera.position_smoothing_enabled = false
	_camera.position = _get_camera_start()

	_spawn_units()
	# Snapshot for the Retry button — done after units land so HP/inventory reflect map start
	var gs := get_node_or_null("/root/GameState")
	if gs:
		# Clear any carry-over modifier state so the snapshot captures a clean map start.
		for u in gs.all_units:
			if u.has_method("reset_map_state"):
				u.reset_map_state()
		gs.map_data = map_data
		gs.take_map_snapshot()
	# Wire persistent HUD
	if _hud and _hud.has_method("setup"):
		_hud.setup(_grid, _turn_manager)
	# Kick off the first player phase
	_turn_manager.start_map(map_data, _grid)


# Returns the world-space camera start position. Uses map_data.camera_start_tile when
# explicitly set; otherwise computes the centroid of player_start_tiles.
func _get_camera_start() -> Vector2:
	if map_data.camera_start_tile != Vector2i(-1, -1):
		return _grid.tile_to_world(map_data.camera_start_tile)
	if map_data.player_start_tiles.is_empty():
		return Vector2.ZERO
	var sum := Vector2i.ZERO
	for t in map_data.player_start_tiles:
		sum += t
	var centroid := Vector2i(sum.x / map_data.player_start_tiles.size(),
		sum.y / map_data.player_start_tiles.size())
	return _grid.tile_to_world(centroid)


func _load_map_data() -> void:
	if ResourceLoader.exists(map_data_path):
		map_data = load(map_data_path)
	else:
		push_error("GameMap: missing MapData at " + map_data_path)


# Spawns player units from GameState.player_roster onto player_start_tiles,
# then enemy units from MapData.enemy_placements. All units get registered
# with GameState so GridManager can find them via _get_units().
func _spawn_units() -> void:
	if map_data == null:
		return
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		push_error("GameMap: GameState autoload missing")
		return

	# Auto-load default roster if MainMenu hasn't filled it (e.g. direct boot)
	if gs.player_roster.is_empty():
		gs.load_default_roster()

	# Player units: roster slot N → player_start_tiles[N]
	for i in gs.player_roster.size():
		if i >= map_data.player_start_tiles.size():
			break
		var u_data: UnitData = gs.player_roster[i]
		if u_data.is_incapacitated:
			continue  # permadeath: skip dead units in future deployments
		_spawn_unit(u_data, map_data.player_start_tiles[i], "player")

	# Enemy units: load each UnitData .tres referenced by enemy_placements
	for placement in map_data.enemy_placements:
		var path: String = placement.get("unit_data_path", "")
		var tile: Vector2i = placement.get("tile", Vector2i.ZERO)
		if path == "" or not ResourceLoader.exists(path):
			push_warning("GameMap: bad enemy placement: " + str(placement))
			continue
		var u_data: UnitData = load(path).duplicate(true)  # fresh copy per map
		u_data.ai_profile = placement.get("ai_profile", "basic")
		_spawn_unit(u_data, tile, "enemy")


func _spawn_unit(u_data: UnitData, tile: Vector2i, team: String) -> void:
	var unit: Unit = unit_scene.instantiate()
	unit.initialize(u_data, tile, team)
	_units_container.add_child(unit)
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.register_unit(unit)


# Asserts all rows are the expected length and contain only known terrain chars.
func _validate_map(grid: Array[String], width: int, height: int) -> void:
	if grid.size() != height:
		push_error("GameMap: grid has %d rows, expected %d" % [grid.size(), height])
		return
	for y in grid.size():
		var row: String = grid[y]
		if row.length() != width:
			push_error("GameMap: row %d length %d, expected %d" % [y, row.length(), width])
			return
		for x in row.length():
			var ch: String = row[x]
			if not _CHAR_TO_SOURCE.has(ch):
				push_error("GameMap: row %d col %d: unknown terrain char '%s'" % [y, x, ch])


func _paint_terrain(grid: Array[String], width: int, height: int) -> void:
	for y in height:
		var row: String = grid[y]
		for x in width:
			var ch: String = row[x]
			var source_id: int = _CHAR_TO_SOURCE.get(ch, 6)
			_terrain_layer.set_cell(Vector2i(x, y), source_id, Vector2i.ZERO)
