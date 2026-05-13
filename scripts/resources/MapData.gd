class_name MapData extends Resource
# TODO save-system: MapData.grid reflects the original authored terrain and is loaded once at
# map start. If shifting terrain / destructible tiles are added, runtime mutations to the
# TileMapLayer will diverge from grid. The save system must snapshot live terrain state
# (or diffs) separately — see §0b N1 in code_review_2026-05-13c.

@export var id: String = ""
@export var display_name: String = ""
@export var tilemap_scene_path: String = ""
# "rout"|"seize"|"boss"|"survive"|"defend"|"escape"
@export var objective_type: String = ""
@export var objective_params: Dictionary = {}
# 0 = no turn limit; defeat if exceeded
@export var turn_limit: int = 0
@export var player_start_tiles: Array[Vector2i] = []
# Each entry: { "unit_data_path":String, "tile":Vector2i, "ai_profile":String, "is_boss":bool }
# required_survivor belongs on the top-level required_survivor_ids array, not per-placement.
@export var enemy_placements: Array[Dictionary] = []
# Player unit names that trigger defeat if killed
@export var required_survivor_ids: Array[String] = []
@export var reward_gold: int = 0
# Item IDs given at map completion
@export var reward_items: Array[String] = []

# Terrain string grid: one String per row, each char a terrain code (see GameMap._CHAR_TO_SOURCE).
# Height = grid.size(), width = grid[0].length(). Leave empty for scene-painted maps (Phase 2).
@export var grid: Array[String] = []

# Where to center the camera on map load. Vector2i(-1,-1) = not set; falls back
# to the centroid of player_start_tiles.
@export var camera_start_tile: Vector2i = Vector2i(-1, -1)
