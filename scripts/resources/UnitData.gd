class_name UnitData extends Resource

@export var unit_id: String = ""   # unique identifier; used by survivor checks and save/load
@export var unit_name: String = ""
# Grid position — captured by GameState's manual snapshot (not by ResourceSaver; not @export).
# Unit.tile_position is a pass-through property to this field.
var tile_position: Vector2i = Vector2i.ZERO
@export var class_id: String = ""
@export var level: int = 1
@export var exp: int = 0
@export var is_promoted: bool = false
# Pre + post promotion levels combined
@export var effective_level: int = 1

# Stats
@export var max_hp: int = 0
@export var hp: int = 0
@export var strength: int = 0
@export var magic: int = 0
@export var defense: int = 0
@export var resistance: int = 0
@export var skill: int = 0
@export var speed: int = 0
@export var luck: int = 0
@export var movement: int = 0
@export var constitution: int = 0
@export var line_of_sight: int = 4

# This unit's personal growth rates, keys = ClassData.STAT_KEYS, values 0–100+.
# Added on top of the class's player_growth_rates at level-up (player units only).
# Empty {} is valid — the unit then levels purely on its class growths.
@export var growth_rates: Dictionary = {}

# Format: { "sword": { "rank": "D", "wexp": 0 } }
@export var proficiencies: Dictionary = {}

# Array of skill ID strings referencing SkillData resources. Equippable; a
# GameState.max_skills cap is planned but NOT yet enforced (see GameState).
@export var skills: Array[String] = []
# Permanently earned mastery skills (S-rank, etc.) — not equippable or removable, never count
# against the skill slot limit. Populated at runtime by Unit.add_wexp(); never set in .tres files.
# Captured by GameState's manual snapshot (not by ResourceSaver; not @export).
var mastery_skills: Array[String] = []

@export var inventory: Array[InventoryEntry] = []

# Array of Dicts: [{ "type": "poison", "turns_remaining": 3 }]
@export var conditions: Array[Dictionary] = []

@export var gold: int = 1000

# Permadeath flag; unit removed from future deployment when true
@export var is_incapacitated: bool = false
# "basic"|"passive" for MVP; future: "territorial"|"guard_tile"|"healer"|"boss"
@export var ai_profile: String = "basic"
# True for the 6 auto-generated MVP starter units
@export var is_default_roster: bool = false

# ── Phase 2 runtime state ─────────────────────────────────────────────────────
# All default to safe empty/zero values. Beorc units never write to the Laguz fields.
# These are serialized for mid-battle suspend saves (no scene tree traversal needed).

# Active temporary stat modifiers. Each entry:
#   { "stat": String, "delta": int, "source": String, "duration": int,
#     "duration_type": "turn"|"map_turn"|"combat"|"permanent" }
# "duration" = -1 means never auto-removed. "permanent" type is never decremented.
var active_modifiers: Array[Dictionary] = []

# Per-map use counters for limited skills. Keys = effect_id, values = times used.
# Reset to {} by Unit.reset_map_state() at map load.
var skill_use_counters: Dictionary = {}

# Cumulative damage taken this map (used by the Vengeance skill — M9).
var damage_taken_this_map: int = 0

# Carry-over accumulators for growth_fixed leveling. Keys = stat name, values = remainder (0–99).
# Persisted with unit data so Retry restores the exact carry state.
@export var growth_accumulators: Dictionary = {}

# Laguz shift gauge — safe for all Beorc units (ignored until M12).
@export var shift_gauge: int = 0
@export var is_shifted: bool = false
@export var shift_profile_id: String = ""
