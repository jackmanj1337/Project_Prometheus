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
@export var range_min: int = 1
@export var range_max: int = 1
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
