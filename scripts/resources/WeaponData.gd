class_name WeaponData extends Resource

const GameConstants = preload("res://scripts/shared/GameConstants.gd")
const StatRegistry = preload("res://scripts/core/StatRegistry.gd")

@export var id: String = ""
@export var display_name: String = ""
# Pack-relative Tier-1 asset id/path. AssetResolver owns raw loading; gameplay
# data never stores a Texture2D that would depend on the res:// import pipeline.
@export var icon: String = ""
# Canonical combat family used for equip legality and family-specific skill checks.
@export var combat_family: String = ""
# Canonical progression track trained by this weapon.
@export var wexp_track: String = ""
# "E"|"D"|"C"|"B"|"A"|"S"
@export var required_rank: String = "E"
# For staves: 0; heal amount computed separately as 10 + MAG
@export var mt: int = 0
# For staves: 0; healing always lands, no hit roll
@export var hit: int = 0
@export var crit: int = 0

# Range as formula strings so dynamic ranges (e.g. Physic "MAG/2") work uniformly.
# Supported: integer literals ("1", "2"), stat/divisor ("MAG/2").
# Static weapons store integer strings ("1", "2") — the effective value is identical.
# Always use get_range_min(unit) / get_range_max(unit) instead of reading these directly.
@export var range_min_formula: String = "1"
@export var range_max_formula: String = "1"
# Registered definitions are the authoring contract. Empty ids retain the old
# string fields strictly as a compatibility/import boundary until base-pack extraction.
@export var range_min_formula_id: String = ""
@export var range_min_parameters: Dictionary = {}
@export var range_max_formula_id: String = ""
@export var range_max_parameters: Dictionary = {}

@export var wt: int = 0
@export var uses: int = 1
@export var cost: int = 0
# wEXP gained per successful hit
@export var wexp: int = 1
# See GDD_04 effect tags reference
@export var effect_tags: Array[String] = []
# If true: uses MAG for damage, targets RES instead of DEF
@export var uses_mag: bool = false
# Optional triangle-family override for hybrid or special weapons.
@export var triangle_family: String = ""

# Set to 2 for all Brave weapons — attacker fires this many times before defender counters.
@export var strikes_per_attack: int = 1

# True for Laguz natural weapons (Fang/Claw/Beak/Talon). No cost, no uses consumed.
# [DEFERRED — Laguz] Unit.get_equipped_weapon() should auto-return this when is_shifted = true,
# but that check is not yet implemented.
@export var is_natural_weapon: bool = false


# A healing staff (mt 0, restores HP via the heal tag). Healing staves cannot be
# used to attack or counterattack — they are gated to the Staff action only.
# Offensive/debuff staves (M8) omit the heal tag and ARE treated as attack weapons,
# so this check keys off the heal tag, not weapon_type alone.
func is_healing_staff() -> bool:
	return combat_family == "staff" and GameConstants.TAG_HEAL_PLUS_MAG in effect_tags


func get_range_min(unit: Node = null) -> int:
	return _registered_range(range_min_formula_id, range_min_parameters, range_min_formula, unit)


func get_range_max(unit: Node = null) -> int:
	return _registered_range(range_max_formula_id, range_max_parameters, range_max_formula, unit)


func get_triangle_family() -> String:
	return triangle_family if triangle_family != "" else combat_family


static func _registered_range(
	id: String, parameters: Dictionary, legacy_formula: String, unit: Node
) -> int:
	var definition := {"id": id, "parameters": parameters}
	if id.is_empty():
		definition = _adapt_legacy_range(legacy_formula)
	if definition.is_empty():
		push_error("WeaponData: unrecognised range formula '%s'" % legacy_formula)
		return 1
	var result := RangeFormulaRegistry.evaluate(
		definition["id"], definition["parameters"], _stat_snapshot(unit)
	)
	if not result.ok:
		push_error("WeaponData: %s" % result.error)
		return 1
	return int(result.value)


# Reads the old literal / STAT-divisor grammar only at the compatibility boundary.
static func _adapt_legacy_range(formula: String) -> Dictionary:
	var f := formula.strip_edges()
	if f.is_valid_int():
		return {"id": "literal", "parameters": {"value": f.to_int()}}
	var parts := f.split("/")
	if parts.size() == 2 and parts[1].strip_edges().is_valid_int():
		var divisor := parts[1].strip_edges().to_int()
		if divisor <= 0:
			return {}
		var stat := _legacy_stat_id(parts[0].strip_edges().to_upper())
		if stat.is_empty():
			return {}
		return {"id": "stat_divisor", "parameters": {"stat": stat, "divisor": divisor}}
	return {}


static func _stat_snapshot(unit: Node) -> Dictionary:
	var result: Dictionary = {}
	for stat_name in StatRegistry.display_stat_ids():
		result[stat_name] = _stat_value(stat_name, unit)
	return result


static func _legacy_stat_id(stat_name: String) -> String:
	return (
		{
			"MAG": "magic",
			"STR": "strength",
			"SKL": "skill",
			"LUK": "luck",
			"SPD": "speed",
			"DEF": "defense",
			"RES": "resistance",
			"HP": "hp",
		}
		. get(stat_name, "")
	)


static func _stat_value(stat_name: String, unit: Node) -> int:
	if unit == null:
		return 0
	# Prefer get_effective_stat so active modifiers (e.g. MAG buffs) affect dynamic range.
	if unit.has_method("get_effective_stat"):
		return int(unit.get_effective_stat(stat_name))
	if not "data" in unit or unit.data == null:
		return 0
	return int(unit.data.get(stat_name)) if unit.data.get(stat_name) != null else 0
