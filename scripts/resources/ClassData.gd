class_name ClassData extends Resource

const GameConstants = preload("res://scripts/shared/GameConstants.gd")

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""

# Tier 1 = base class, Tier 2 = promoted class. Promotion (M6) keys off this.
@export var tier: int = 1
@export var max_level: int = 20

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

# Numeric WEXP baselines and caps keyed by GameConstants.VALID_WEXP_TRACKS.
@export var weapon_wexp_bases: Dictionary = {}
@export var weapon_wexp_caps: Dictionary = {}
# Optional explicit combat-family allowances. If empty, derived from weapon_wexp_caps.
@export var allowed_weapon_families: Array[String] = []
# Loose semantic tags for item restrictions and future content gating.
@export var class_groups: Array[String] = []
# See GDD_03 for valid values: "flying", "mounted", "armoured", "dragon", "beast", "laguz"
@export var special_qualities: Array[String] = []
@export var vulnerability_groups: Array[String] = []
@export var internal_level_rule: String = ""
@export var class_availability: String = "playable"

# Promotion (M6) — applied as additive stat deltas at promotion.
@export var promotes_to: Array[String] = []
@export var promotes_from: Array[String] = []
@export var promotion_stat_bonuses: Dictionary = {}

# Stat keys recognised in growth_rates / stat_caps dictionaries.
const STAT_KEYS: Array[String] = ["hp", "strength", "magic", "defense",
	"resistance", "skill", "speed", "luck"]

# Growth rates, keys = STAT_KEYS, values 0–100+. Two tables per the GDD:
#   - player_growth_rates: added to a player unit's personal growths at level-up.
#   - enemy_growth_rates:  used alone to auto-level generic enemy units.
@export var player_growth_rates: Dictionary = {}
@export var enemy_growth_rates: Dictionary = {}

# Maximum stats for this class, keys = STAT_KEYS. Level-up gains are clamped here.
# MOV/CON/LoS are intentionally uncapped (no keys), matching the GDD cap tables.
@export var stat_caps: Dictionary = {}

# Skills auto-learned while in this class. Keys = level (int), values = skill id.
# e.g. { 1: "skill_plus_2", 10: "prescience" }. One skill per level.
@export var skill_unlocks: Dictionary = {}

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


func get_weapon_wexp_base(track: String) -> int:
	return int(weapon_wexp_bases.get(track, 0))


func get_weapon_wexp_cap(track: String) -> int:
	return int(weapon_wexp_caps.get(track, 0))


func get_allowed_weapon_families() -> Array[String]:
	if not allowed_weapon_families.is_empty():
		return allowed_weapon_families.duplicate()
	var seen := {}
	var derived: Array[String] = []
	for track in weapon_wexp_caps.keys():
		if get_weapon_wexp_cap(String(track)) <= 0:
			continue
		for family in GameConstants.wexp_track_to_combat_families(String(track)):
			if seen.has(family):
				continue
			seen[family] = true
			derived.append(family)
	return derived


func resolved_internal_level_rule() -> String:
	if internal_level_rule in GameConstants.VALID_INTERNAL_LEVEL_RULES:
		return internal_level_rule
	return "promoted" if tier >= 2 else "base"


func is_menu_visible() -> bool:
	return class_availability != "hidden"
