class_name ClassData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""

# Base stats copied to UnitData at unit creation
@export var base_hp: int = 0
@export var base_str: int = 0
@export var base_mag: int = 0
@export var base_def: int = 0
@export var base_res: int = 0
@export var base_skl: int = 0
@export var base_spd: int = 0
@export var base_luk: int = 0
@export var base_mov: int = 0
@export var base_con: int = 0
@export var base_los: int = 4

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

# Keys: "hp","str","mag","def","res","skl","spd","luk" — values 0–100
@export var growth_rates: Dictionary = {}

# [PLACEHOLDER] links to sprite sheet row
@export var sprite_id: String = ""
