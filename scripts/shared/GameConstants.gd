extends Node
# Central project constants. Registered as an autoload so any game script can access
# directly. Tool scripts preload this file instead (autoloads aren't live during _init()).
# [NOTE — M-7] This class has no instance state; only const fields. extends Node is
# required because Godot 4 autoloads must be Node-derived (they're added to /root/).
# Converting to a preloaded script would remove this overhead but requires updating
# every caller — deferred to a dedicated cleanup milestone.

# Tile pixel size. Edit here to resize all tiles project-wide.
const TILE_SIZE: int = 64

# Sentinel value for "no result yet" comparisons — avoids magic literals.
const INT_MAX: int = 0x7FFFFFFF

# WeaponData.effect_tags string constants. CombatResolver must use these — never the
# raw strings — so a typo here is a compile error, not a silent missed effect.
const TAG_EFFECTIVE_FLYING   := "effective_flying"
const TAG_EFFECTIVE_ARMOURED := "effective_armoured"
const TAG_EFFECTIVE_MOUNTED  := "effective_mounted"
const TAG_EFFECTIVE_DRAGON   := "effective_dragon"
const TAG_EFFECTIVE_BEAST    := "effective_beast"
const TAG_HEAL_PLUS_MAG      := "heal_10_plus_mag"

# Canonical set of all valid weapon effect_tags. DataManager._validate_cross_references
# checks every weapon's effect_tags against this; an unknown tag is a typo (or a tag
# that has not yet been added here) and fails loud at startup (B6). Extend this when
# adding new effect tags — e.g. M8 will add "poison_on_hit" for Venin weapons.
const VALID_EFFECT_TAGS: Array[String] = [
	TAG_EFFECTIVE_FLYING, TAG_EFFECTIVE_ARMOURED, TAG_EFFECTIVE_MOUNTED,
	TAG_EFFECTIVE_DRAGON, TAG_EFFECTIVE_BEAST, TAG_HEAL_PLUS_MAG,
]

# Canonical weapon combat families. These drive equip legality, breaker/faire style
# skills, and combat-family-specific behavior. Progression is tracked separately via
# VALID_WEXP_TRACKS.
const VALID_COMBAT_FAMILIES: Array[String] = [
	"sword", "lance", "axe", "bow",
	"fire", "thunder", "wind", "light", "dark", "staff",
	"beaststone", "dragonstone",
]

# Canonical WEXP tracks. UnitData.weapon_wexp stores numeric progress against these
# keys only; displayed ranks are derived from thresholds below.
const VALID_WEXP_TRACKS: Array[String] = [
	"sword", "lance", "axe", "bow",
	"elemental_magic", "light", "dark", "staff",
	"beaststone", "dragonstone",
]

const VALID_VULNERABILITY_GROUPS: Array[String] = [
	"mounted", "flying", "armoured", "dragon", "beast", "monster",
]

const VALID_INTERNAL_LEVEL_RULES: Array[String] = ["base", "promoted", "special"]
const VALID_CLASS_AVAILABILITY: Array[String] = ["playable", "hidden"]

# Movement-type subset of ClassData.special_qualities (V021-11), in DESCENDING
# precedence. A class may carry more than one (Great Knight = armoured+mounted), so
# movement_type_of() resolves to the single highest-precedence tag for terrain cost
# and display. The array also holds non-movement tags (dragon/beast/laguz — M12/M13
# effectiveness types) which the resolver ignores. Every class must declare at least
# one of these (enforced by check_docs.py); `infantry` is the explicit default so a
# class's movement cost is marked rather than inferred from absence.
const VALID_MOVEMENT_TYPES: Array[String] = [
	"flying", "mounted", "armoured", "light_footed", "infantry",
]


# Resolves a class/unit's single movement type from its special_qualities tags by
# VALID_MOVEMENT_TYPES precedence (flying > mounted > armoured > light_footed >
# infantry), ignoring non-movement tags. Defaults to "infantry" when none is present.
# Flying wins cost resolution (fliers ignore ground terrain); among ground types the
# mount/armour penalty dominates the light bonus. Effectiveness is independent —
# vulnerability_groups still reads every tag, so an armoured+mounted unit is hit by
# all matching effective weapons regardless of its resolved movement type.
static func movement_type_of(special_qualities: Array) -> String:
	for mt in VALID_MOVEMENT_TYPES:
		if mt in special_qualities:
			return mt
	return "infantry"

# Stat-modifier DISPLAY duration vocabulary (V021-09). This is the fixed set of
# human-facing scope labels the character sheet renders via
# StatBreakdown.format_duration; M8 conditions / M9 procs author against it so they
# never reintroduce an ad-hoc string. NOTE: this is the *label*, not the tick point
# — when a real modifier decrements is a separate concern carried by the lifecycle
# duration_type on data.active_modifiers ("turn" = per-faction-phase, "map_turn" =
# per round, "combat" = cleared at end of combat, "permanent" = never). The
# 2026-06-20 M8 amendment maps "x turns" to the per-faction-phase ("turn") tick.
#   this_combat     — one engagement (attack + its follow-ups/counters)
#   until_separated — persists across combats until a Pair Up splits
#   until_unequipped— persists while the granting weapon/item is held
#   until_end_of_map— persists for the whole chapter
#   x_turns         — counts down N turns, then expires
#   permanent       — innate/class bonus; never expires (renders blank)
const VALID_DURATION_TYPES: Array[String] = [
	"this_combat", "until_separated", "until_unequipped",
	"until_end_of_map", "x_turns", "permanent",
]

# Legacy authored keys that must be migrated in-repo instead of supported at load time.
const LEGACY_WEXP_TRACKS: Array[String] = ["fire", "thunder", "wind"]

# Shared threshold table for deriving weapon ranks from numeric WEXP totals.
const WEXP_RANK_THRESHOLDS: Dictionary = {
	"E": 0,
	"D": 100,
	"C": 200,
	"B": 300,
	"A": 400,
	"S": 500,
}

# Staff heal formula constants (GDD_02)
const STAFF_HEAL_BASE: int = 10  # base HP restored; full formula = STAFF_HEAL_BASE + healer MAG
const STAFF_HEAL_EXP: int = 10   # flat EXP awarded to the healer per staff use

# MapCursor key-repeat timings (GDD_01)
const CURSOR_KEY_REPEAT_DELAY: float = 0.25  # initial hold delay before auto-repeat
const CURSOR_KEY_REPEAT_RATE: float = 0.10   # per-step delay during auto-repeat
const CURSOR_CAMERA_EDGE_BUFFER: int = 2     # tiles from viewport edge that trigger camera pan

# Combat thresholds
const FOLLOW_UP_SPEED_THRESHOLD: int = 5    # SPD advantage needed to attack twice (GDD_02)

# Percent-of-max-HP healing (GDD_02). Shared by fort/throne terrain healing and the
# Renewal skill so the two "heal 10% of max HP" mechanics stay in sync. Per GDD_02:76
# ("all calculated values are rounded down"), callers must floor the result.
const PERCENT_HP_HEAL_FRACTION: float = 0.10

# Visual
const DONE_APPEARANCE_DARKEN: float = 0.4   # darkening applied to sprites of acted units

# Weapon triangle — single source of truth for DataManager and CombatResolver.
# "advantage" = +10 Hit +2 Dmg; "disadvantage" = -10 Hit -2 Dmg.
# ID collision prevention: weapon IDs and skill effect_ids share the same string namespace
# in DataManager lookups. Use distinct names when a skill and weapon share a common name.
# Convention: if a skill effect_id would collide with a weapon id, suffix the weapon id
# with "_tome" or "_weapon" (e.g. "luna_tome" for the dark tome, "luna" for the skill).
const WEAPON_TRIANGLE: Dictionary = {
	"sword":   {"axe": "advantage",    "lance": "disadvantage"},
	"axe":     {"lance": "advantage",  "sword": "disadvantage"},
	"lance":   {"sword": "advantage",  "axe":   "disadvantage"},
	"dark":    {"fire": "advantage",   "thunder": "advantage", "wind": "advantage",  "light": "disadvantage"},
	"light":   {"dark": "advantage",   "fire": "disadvantage", "thunder": "disadvantage", "wind": "disadvantage"},
	# Anima (fire/thunder/wind) are neutral to each other — intentional design decision.
	# Only dark/light polarize the anima triangle; anima vs anima is always 0 Hit / 0 Dmg.
	"fire":    {"light": "advantage",  "dark": "disadvantage"},
	"thunder": {"light": "advantage",  "dark": "disadvantage"},
	"wind":    {"light": "advantage",  "dark": "disadvantage"},
}


static func combat_family_to_wexp_track(combat_family: String) -> String:
	match combat_family:
		"fire", "thunder", "wind":
			return "elemental_magic"
		_:
			return combat_family


static func wexp_track_to_combat_families(track: String) -> Array[String]:
	match track:
		"elemental_magic":
			return ["fire", "thunder", "wind"]
		_:
			var families: Array[String] = []
			if track in VALID_COMBAT_FAMILIES:
				families.append(track)
			return families


static func weapon_rank_for_wexp(wexp_total: int) -> String:
	var total := maxi(0, wexp_total)
	if total >= int(WEXP_RANK_THRESHOLDS["S"]):
		return "S"
	if total >= int(WEXP_RANK_THRESHOLDS["A"]):
		return "A"
	if total >= int(WEXP_RANK_THRESHOLDS["B"]):
		return "B"
	if total >= int(WEXP_RANK_THRESHOLDS["C"]):
		return "C"
	if total >= int(WEXP_RANK_THRESHOLDS["D"]):
		return "D"
	return "E"


static func minimum_wexp_for_rank(rank: String) -> int:
	return int(WEXP_RANK_THRESHOLDS.get(rank, 0))


static func maximum_wexp_total() -> int:
	return int(WEXP_RANK_THRESHOLDS["S"])


static func next_weapon_rank(rank: String) -> String:
	match rank:
		"E":
			return "D"
		"D":
			return "C"
		"C":
			return "B"
		"B":
			return "A"
		"A":
			return "S"
		_:
			return ""
