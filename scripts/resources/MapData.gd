class_name MapData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var tilemap_scene_path: String = ""
# "rout"|"seize"|"boss"|"survive"|"defend"|"escape"
@export var objective_type: String = ""
@export var objective_params: Dictionary = {}
# 0 = no turn limit; defeat if exceeded
@export var turn_limit: int = 0
@export var player_start_tiles: Array[Vector2i] = []
# Each entry: { "unit_data_path":String, "tile":Vector2i, "ai_profile":String,
#               "is_boss":bool, "required_survivor":bool }
@export var enemy_placements: Array[Dictionary] = []
# Player unit names that trigger defeat if killed
@export var required_survivor_names: Array[String] = []
@export var reward_gold: int = 0
# Item IDs given at map completion
@export var reward_items: Array[String] = []
