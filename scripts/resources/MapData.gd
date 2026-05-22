class_name MapData extends Resource
# TODO save-system: MapData.grid reflects the original authored terrain and is loaded once at
# map start. If shifting terrain / destructible tiles are added, runtime mutations to the
# TileMapLayer will diverge from grid. The save system must snapshot live terrain state
# (or diffs) separately — see §0b N1 in code_review_2026-05-13c.

@export var id: String = ""
@export var display_name: String = ""
@export var tilemap_scene_path: String = ""
@export var player_start_tiles: Array[Vector2i] = []
# Each entry: { "unit_data_path":String, "tile":Vector2i, "ai_profile":String,
#               "is_boss":bool, "faction":String? }
# faction is optional; defaults to "red" for pre-C3 maps.
@export var enemy_placements: Array[Dictionary] = []
@export var reward_gold: int = 0
# Item IDs given at map completion
@export var reward_items: Array[String] = []

# Terrain string grid: one String per row, each char a terrain code (see GameMap._CHAR_TO_SOURCE).
# Height = grid.size(), width = grid[0].length(). Leave empty for scene-painted maps (Phase 2).
@export var grid: Array[String] = []

# Where to center the camera on map load. Vector2i(-1,-1) = not set; falls back
# to the centroid of player_start_tiles.
@export var camera_start_tile: Vector2i = Vector2i(-1, -1)

# ── M14 stage 3: N-faction data ──────────────────────────────────────────────
# The factions that exist on this map. Leave empty for the blue+red default —
# TurnManager / GameState build a default list at start_map time so existing
# maps load with zero edits. Stage-4+ content maps will populate this directly.
@export var factions: Array[FactionData] = []

# The order factions activate in. Leave empty to use the order of `factions`
# (or the [blue, red] default). The cycle skips any faction with zero living
# units (Decision 2 / 2026-05-17). Strings here must match a faction id either
# in `factions` or in the default fallback.
@export var turn_order: Array[String] = []

# Activation policy — "WHOLE_PHASE" exhausts one faction's units before
# advancing (today's FE-style I-Go-You-Go); "ALTERNATING" advances after each
# single unit committed and refreshes everyone at round end (Decision 9).
# Default WHOLE_PHASE keeps the existing M14/M15/M16 specs + content valid.
@export var activation_mode: String = "WHOLE_PHASE"

# ── M16: per-group condition sets ────────────────────────────────────────────
# Victory and defeat conditions are evaluated PER ALLIANCE GROUP (Decision 8 /
# 2026-05-17): each key is a group name from FactionData.alliance_group
# ("allies", "foes", "rogues", … plus any custom group introduced by a map),
# each value is an Array[ObjectiveCondition].
#
# Evaluation semantics (TurnManager.check_victory_conditions):
#   victory = AND of every condition in victory_conditions[group]
#   defeat  = OR  of any condition in defeat_conditions[group]
# A group with no entries in either dictionary gets an implicit "group routed"
# defeat condition so every group always has a way to be out (M16 spec).
@export var victory_conditions: Dictionary = {}
@export var defeat_conditions: Dictionary = {}


func get_faction(faction_id: String) -> FactionData:
	for faction in factions:
		if faction != null and faction.id == faction_id:
			return faction
	return null
