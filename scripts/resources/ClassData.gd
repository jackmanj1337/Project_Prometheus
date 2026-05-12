class_name ClassData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""

# Base stats copied to UnitData at unit creation
@export var base_hp: int = 0
@export var base_strength: int = 0
@export var base_magic: int = 0
@export var base_defense: int = 0
@export var base_resistance: int = 0
@export var base_skill: int = 0
@export var base_speed: int = 0
@export var base_luck: int = 0
@export var base_movement: int = 0
@export var base_constitution: int = 0
@export var base_line_of_sight: int = 4

# First entry = primary weapon type (starts at D rank); rest start at E rank
@export var proficiencies: Array[String] = []
@export var starting_skills: Array[String] = []
# See GDD_03 for valid values: "flying", "mounted", "armoured", "dragon", "beast", "laguz"
@export var special_qualities: Array[String] = []

# Promotion (Phase 2)
@export var promotes_to: Array[String] = []
@export var promotion_stat_increases: Dictionary = {}
@export var promotion_skill: String = ""
@export var occult_skill: String = ""

# Keys: "hp","strength","magic","defense","resistance","skill","speed","luck" — values 0–100
@export var growth_rates: Dictionary = {}

# [PLACEHOLDER] links to sprite sheet row
@export var sprite_id: String = ""

# ── Laguz gauge parameters (all default to 0/false/"" for Beorc — safe to ignore) ──
@export var is_laguz: bool = false
@export var max_shift_gauge: int = 0
@export var shift_gauge_start: int = 0
@export var shift_gain_per_turn_humanoid: int = 0
@export var shift_gain_per_turn_animal: int = 0
@export var shift_gain_per_combat_humanoid: int = 0
@export var shift_gain_per_combat_animal: int = 0
# +50% stats in animal form for standard Laguz; reduced to +25% with Feral Instincts
@export var animal_stat_bonus_pct: float = 0.5
# "fang"|"claw"|"beak"|"talon" etc. Empty string for all Beorc classes.
@export var natural_weapon_type: String = ""
# CON increases ~75% in animal form
@export var animal_con_bonus_pct: float = 0.75
