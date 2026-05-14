extends Node
# Central project constants. Registered as an autoload so any game script can access
# directly. Tool scripts preload this file instead (autoloads aren't live during _init()).

# Tile pixel size. Edit here to resize all tiles project-wide.
const TILE_SIZE: int = 64

# Sentinel value for "no result yet" comparisons — avoids magic literals.
const INT_MAX: int = 0x7FFFFFFF

# Maximum level for unpromoted units before promotion is required (GDD_02).
const MAX_LEVEL: int = 20

# WeaponData.effect_tags string constants. CombatResolver must use these — never the
# raw strings — so a typo here is a compile error, not a silent missed effect.
const TAG_EFFECTIVE_FLYING   := "effective_flying"
const TAG_EFFECTIVE_ARMOURED := "effective_armoured"
const TAG_EFFECTIVE_MOUNTED  := "effective_mounted"
const TAG_EFFECTIVE_DRAGON   := "effective_dragon"
const TAG_EFFECTIVE_BEAST    := "effective_beast"
const TAG_HEAL_PLUS_MAG      := "heal_10_plus_mag"

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
