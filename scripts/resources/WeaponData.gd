class_name WeaponData extends Resource

@export var id: String = ""
@export var display_name: String = ""
# "sword"|"lance"|"axe"|"bow"|"knife"|"fire"|"thunder"|"wind"|"light"|"dark"|"staff"
@export var weapon_type: String = ""
# "E"|"D"|"C"|"B"|"A"|"S"
@export var rank: String = "E"
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

@export var wt: int = 0
@export var uses: int = 1
@export var cost: int = 0
# wEXP gained per successful hit
@export var wexp: int = 1
# See GDD_04 effect tags reference
@export var effect_tags: Array[String] = []
# If true: uses MAG for damage, targets RES instead of DEF
@export var uses_mag: bool = false
# For hybrid weapons only (e.g. Bolt Axe); leave empty for standard weapons
@export var magic_triangle_type: String = ""

# Set to 2 for all Brave weapons — attacker fires this many times before defender counters.
@export var strikes_per_attack: int = 1

# True for Laguz natural weapons (Fang/Claw/Beak/Talon). No cost, no uses consumed.
# [DEFERRED — Laguz] Unit.get_equipped_weapon() should auto-return this when is_shifted = true,
# but that check is not yet implemented.
@export var is_natural_weapon: bool = false


func get_range_min(unit: Node = null) -> int:
	return _eval_formula(range_min_formula, unit)


func get_range_max(unit: Node = null) -> int:
	return _eval_formula(range_max_formula, unit)


# Parses a formula string against the given unit's stats.
# Supported: integer literals ("1"), stat/divisor ("MAG/2"). Returns 1 on error.
static func _eval_formula(formula: String, unit: Node) -> int:
	var f := formula.strip_edges()
	if f.is_valid_int():
		return f.to_int()
	var parts := f.split("/")
	if parts.size() == 2 and parts[1].strip_edges().is_valid_int():
		var divisor := parts[1].strip_edges().to_int()
		if divisor <= 0:
			return 1
		return _stat_value(parts[0].strip_edges().to_upper(), unit) / divisor
	push_error("WeaponData: unrecognised range formula '%s'" % formula)
	return 1


static func _stat_value(stat_name: String, unit: Node) -> int:
	if unit == null:
		return 0
	# Prefer get_effective_stat so active modifiers (e.g. MAG buffs) affect dynamic range.
	if unit.has_method("get_effective_stat"):
		match stat_name:
			"MAG": return unit.get_effective_stat("magic")
			"STR": return unit.get_effective_stat("strength")
			"SKL": return unit.get_effective_stat("skill")
			"LUK": return unit.get_effective_stat("luck")
			"SPD": return unit.get_effective_stat("speed")
			"DEF": return unit.get_effective_stat("defense")
			"RES": return unit.get_effective_stat("resistance")
			"HP":  return unit.get_effective_stat("hp")
	if not "data" in unit or unit.data == null:
		return 0
	match stat_name:
		"MAG": return unit.data.magic
		"STR": return unit.data.strength
		"SKL": return unit.data.skill
		"LUK": return unit.data.luck
		"SPD": return unit.data.speed
		"DEF": return unit.data.defense
		"RES": return unit.data.resistance
		"HP":  return unit.data.hp
	return 0
