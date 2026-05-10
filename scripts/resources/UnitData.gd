class_name UnitData extends Resource

@export var unit_name: String = ""
@export var class_id: String = ""
@export var level: int = 1
@export var exp: int = 0
@export var is_promoted: bool = false
# Pre + post promotion levels combined
@export var effective_level: int = 1

# Stats
@export var max_hp: int = 0
@export var hp: int = 0
@export var str: int = 0
@export var mag: int = 0
@export var def: int = 0
@export var res: int = 0
@export var skl: int = 0
@export var spd: int = 0
@export var luk: int = 0
@export var mov: int = 0
@export var con: int = 0
@export var los: int = 4

# Format: { "sword": { "rank": "D", "wexp": 0 } }
@export var proficiencies: Dictionary = {}

# Array of skill ID strings referencing SkillData resources
@export var skills: Array[String] = []

# Array of Dicts; every entry has a "type" field ("weapon" or "item").
# Weapon entry: { "type":"weapon", "weapon_id":String, "uses_remaining":int, "forged_mods":Dictionary }
# Item entry:   { "type":"item",   "item_id":String,   "uses_remaining":int }
@export var inventory: Array[Dictionary] = []

# Array of Dicts: [{ "type": "poison", "turns_remaining": 3 }]
@export var conditions: Array[Dictionary] = []

@export var gold: int = 1000

# Permadeath flag; unit removed from future deployment when true
@export var is_incapacitated: bool = false
# "basic"|"passive" for MVP; future: "territorial"|"guard_tile"|"healer"|"boss"
@export var ai_profile: String = "basic"
# True for the 6 auto-generated MVP starter units
@export var is_default_roster: bool = false
