extends RefCounted
# StatRegistry — the single engine-side vocabulary of unit stats: the stat-id
# list(s) and their short display labels, read by every site that used to
# hardcode its own copy. This is the non-schema slice of the author-extensible
# stat model [STM] (extensible_stat_model_open_questions_2026-06-25.md), mirroring
# the AIProfileRegistry seam: a vocabulary the engine reads from ONE place instead
# of ~5 hardcoded lists that had to be edited in lockstep.
#
# It replaces:
#   - ClassData.STAT_KEYS          (growth_rates / stat_caps keys)
#   - Unit._GROWTH_STATS           (level-up growth-roll set + order)
#   - DataManager._VALID_STATS     (skills' activation_chance_stat validation)
#   - LevelUpScreen._STAT_NAMES    (level-up screen labels)
#   - StatBreakdown.STAT_LABELS    (character-sheet labels)
# The last two disagreed on Luck ("Luk" vs "Lck"); reconciled here to "Lck".
#
# SCOPE (non-schema slice only): this unifies the READ / VALIDATION vocabulary.
# The base-stat @export -> Dictionary STORAGE migration and the author-declared
# CampaignRules stat registry ([STM-3]) are schema-affecting and stay gated on
# the F1 lock — do NOT front-run them here. Adding an author stat is not yet one
# entry; this slice just removes the "edit 5 lists in lockstep" trap.
#
# A preloaded const/static script (like AIProfileRegistry / GameConstants), NOT an
# autoload: ClassData (a Resource) and Unit read it in `const` initializers, which
# an autoload can't satisfy, and it carries no instance state.

# Stats that participate in level-up growth rolls, growth_rates and stat_caps.
# ORDER IS SIGNIFICANT: growth_random draws one RNG per stat in this order, so
# reordering changes the deterministic level-up sequence (test_unit_stats §5).
# This is the former ClassData.STAT_KEYS / Unit._GROWTH_STATS / DataManager
# _VALID_STATS set — identical membership, canonical order.
const GROWTH_STAT_IDS: Array[String] = ["hp", "strength", "magic", "defense",
	"resistance", "skill", "speed", "luck"]

# Stats shown on the character sheet that never roll on level-up (no growth /
# cap keys), in display order after the growth stats.
const DISPLAY_ONLY_STAT_IDS: Array[String] = ["movement", "constitution", "line_of_sight"]

# Canonical short label per stat id — single source of truth for every UI that
# abbreviates a stat. Reconciled Luck to "Lck" (was "Luk" on the level-up screen).
const STAT_LABELS: Dictionary = {
	"hp": "HP", "strength": "Str", "magic": "Mag", "defense": "Def",
	"resistance": "Res", "skill": "Skl", "speed": "Spd", "luck": "Lck",
	"movement": "Mov", "constitution": "Con", "line_of_sight": "LoS",
}


# All display stat ids in sheet order (growth stats then display-only stats).
static func display_stat_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.append_array(GROWTH_STAT_IDS)
	ids.append_array(DISPLAY_ONLY_STAT_IDS)
	return ids


# Whether a stat id is a growth stat (level-up / growth_rates / stat_caps member).
# Used by DataManager boot validation for skills' activation_chance_stat, matching
# the old _VALID_STATS membership test exactly (only growth stats are valid there).
static func is_growth_stat(id: String) -> bool:
	return id in GROWTH_STAT_IDS


# Whether a stat id is known to the engine at all — a growth stat OR a display-only
# stat. This is the "registered" set for [STM-5] reference validation: an authored
# resource that NAMES a stat outside this set is a typo / unregistered reference and
# must fail loud at load time, not read as a silent runtime 0. (Non-schema slice:
# the author-declared CampaignRules registry that will WIDEN this set is F1-gated.)
static func is_registered_stat(id: String) -> bool:
	return id in GROWTH_STAT_IDS or id in DISPLAY_ONLY_STAT_IDS


# Short label for a stat id; falls back to the capitalised id so a new or unknown
# stat renders readably instead of crashing the UI (preserves the old fallbacks).
static func label_for(id: String) -> String:
	return STAT_LABELS.get(id, id.capitalize())
