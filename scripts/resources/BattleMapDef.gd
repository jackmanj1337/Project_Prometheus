class_name BattleMapDef extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var tilemap_scene_path: String = ""
@export var grid: Array[String] = []
@export var camera_start_tile: Vector2i = Vector2i(-1, -1)
@export var player_start_tiles: Array[Vector2i] = []
@export var enemy_start_tiles: Array[Vector2i] = []
