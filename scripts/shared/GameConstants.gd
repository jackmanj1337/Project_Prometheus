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

# Staff heal formula constants (GDD_02)
const STAFF_HEAL_BASE: int = 10  # base HP restored; full formula = STAFF_HEAL_BASE + healer MAG
const STAFF_HEAL_EXP: int = 10   # flat EXP awarded to the healer per staff use

# MapCursor key-repeat timings (GDD_01)
const CURSOR_KEY_REPEAT_DELAY: float = 0.25  # initial hold delay before auto-repeat
const CURSOR_KEY_REPEAT_RATE: float = 0.10   # per-step delay during auto-repeat
const CURSOR_CAMERA_EDGE_BUFFER: int = 2     # tiles from viewport edge that trigger camera pan

# Combat thresholds
const FOLLOW_UP_SPEED_THRESHOLD: int = 4    # SPD advantage needed to attack twice (GDD_02)

# Terrain healing (GDD_02)
const FORT_HEAL_FRACTION: float = 0.10      # fraction of max HP healed per turn on fort/throne

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
