extends Node
# Central project constants. Registered as an autoload so any game script can access
# directly. Tool scripts preload this file instead (autoloads aren't live during _init()).

# Tile pixel size. Edit here to resize all tiles project-wide.
const TILE_SIZE: int = 64

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
