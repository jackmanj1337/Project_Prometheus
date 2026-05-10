class_name GameMap extends Node2D
# The root scene for any battle. Wires the GridManager, paints the terrain
# layer from a static string grid (data-driven, no editor painting required),
# and spawns units once the rest of the systems land in M3+.

# Source IDs match generate_tilesets.gd ordering
const _CHAR_TO_SOURCE := {
	".": 0,  # plain
	"F": 1,  # forest
	"M": 2,  # mountain
	"T": 3,  # fort
	"S": 4,  # sea
	"D": 5,  # desert
	"W": 6,  # wall
}

const MAP_WIDTH: int = 42
const MAP_HEIGHT: int = 26

# 42×26 grid for map_001 transcribed from GDD_06. Each row is exactly 42 chars.
# _validate_map() asserts the dimensions on _ready so transcription errors fail loud.
const MAP_001: Array[String] = [
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",  # 0  top wall
	"W...............SSS..MM..................W",  # 1
	"W..FF...........SSS.MMM....FF............W",  # 2
	"W..FF...........SSS.MMM....FF............W",  # 3
	"W..........FF...SSS..MM...............WWWW",  # 4  NE corner cliff begins
	"W..........FF...SSS...................WWWW",  # 5
	"W......T.........SS.........FF...........W",  # 6  player-side fort
	"W................SS.........FF.....FF....W",  # 7
	"W................SS................FF....W",  # 8
	"W............FF..SS....FF.............T..W",  # 9  E forest + fort
	"W............FF...S....FF................W",  # 10
	"W.................S......................W",  # 11
	"W.................S...................T..W",  # 12  fort 38,12
	"W.................SS.....................W",  # 13
	"W..................S.....................W",  # 14
	"W.....FF...........S.....................W",  # 15
	"W.....FF...........SDDDDDDDDDDDDDDDDD....W",  # 16  desert begins
	"W..................SDDDDDDDDDDDDDDDDD....W",  # 17
	"W..................SDDDDDDDDDDDDDDDDD....W",  # 18
	"W..................SDDDDDDDDDDDDDDDDD....W",  # 19
	"W...................DDDDDDDDDDDDDDDDD....W",  # 20
	"W........MM.........DDDDDDDDDDDDDDDDD....W",  # 21
	"W........MM.........DDDDDDDDDDDDDDDDD....W",  # 22
	"W........................................W",  # 23
	"W........................................W",  # 24
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",  # 25  bottom wall
]

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

var map_data: MapData = null


func _ready() -> void:
	_validate_map()
	_paint_terrain()
	_grid.setup(_terrain_layer, _overlay_layer, MAP_WIDTH, MAP_HEIGHT)
	_cursor.setup(_grid, _camera)
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = MAP_WIDTH * GridManager.TILE_SIZE
	_camera.limit_bottom = MAP_HEIGHT * GridManager.TILE_SIZE
	_camera.position_smoothing_enabled = false
	# Center on the player start area (Unit_01 at tile 1,9)
	_camera.position = _grid.tile_to_world(Vector2i(1, 9))

	_load_map_data()
	_spawn_units()
	# Snapshot for the Retry button — done after units land so HP/inventory reflect map start
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.map_data = map_data
		gs.take_map_snapshot()


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


# Asserts each row is exactly MAP_WIDTH chars and every char is a known terrain.
# Run on _ready and from tests so transcription bugs surface immediately.
func _validate_map() -> void:
	assert(MAP_001.size() == MAP_HEIGHT, "MAP_001 has %d rows, expected %d" % [MAP_001.size(), MAP_HEIGHT])
	for y in MAP_001.size():
		var row: String = MAP_001[y]
		assert(row.length() == MAP_WIDTH, "Row %d length %d, expected %d" % [y, row.length(), MAP_WIDTH])
		for x in row.length():
			var ch: String = row[x]
			assert(_CHAR_TO_SOURCE.has(ch), "Row %d col %d: unknown char '%s'" % [y, x, ch])


func _paint_terrain() -> void:
	for y in MAP_HEIGHT:
		var row: String = MAP_001[y]
		for x in MAP_WIDTH:
			var ch: String = row[x]
			var source_id: int = _CHAR_TO_SOURCE.get(ch, 6)
			_terrain_layer.set_cell(Vector2i(x, y), source_id, Vector2i.ZERO)
