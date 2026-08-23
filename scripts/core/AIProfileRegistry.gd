extends RefCounted
# Open registry that maps an author-facing AI profile id to a resolved AISpec
# (activation / disposition / engagement axes). This is the seam that replaces
# two closed switches per the AI composition-engine design ([GDD-08-ENEMY-AI],
# invariant 1 "no behavior hardcoded in a match"):
#   - DataManager's closed `_VALID_AI_PROFILES` const (boot validation), and
#   - EnemyAI's `match enemy.data.ai_profile` runtime dispatch.
# Adding a profile becomes one PROFILES entry (+ its disposition handler in
# EnemyAI), never an edit to an engine `match`.
#
# A preloaded const/static script (like GameConstants), NOT an autoload: both
# DataManager (boot) and EnemyAI (runtime) read it without autoload-ordering
# constraints in headless mode.
#
# SCOPE (non-schema, incremental): the dispositions with behaviors that ship
# today are registered — pursue_unit, hold_tile, heal. Alongside the three legacy
# profiles (basic/passive/healer) we ship `hunter` — the design-§9 `weakest`
# target_policy pulled forward as a NON-SCHEMA slice: it reuses the existing
# pursue_unit disposition and needs no `ai_awake` save field, so it is unblocked.
# The rest of the MVP presets + dispositions (grunt/guard/sleeper/tethered/coward/
# runner/raider, and territorial/tethered/flee/seek_tile) still land in build-slice
# step 3 — gated on the `ai_awake` save slice (see GDD_10 "Gated build items").
# Discipline: only open the vocabulary that ships a behavior — no `weakest` id
# without _select_target honouring it, no preset without its disposition.

const AISpecScript = preload("res://scripts/core/AISpec.gd")

# Engine-known disposition ids (movement/attack behavior families). EnemyAI keys
# its handler table by these.
const DISP_PURSUE_UNIT := "pursue_unit"
const DISP_HOLD_TILE := "hold_tile"
const DISP_HEAL := "heal"

# Target-selection (engagement) policies EnemyAI._select_target implements. Both
# ship a real behavior; validated so a typo'd profile can't request an unknown one.
const ENG_NEAREST := "nearest"
const ENG_WEAKEST := "weakest"
const VALID_ENGAGEMENTS := [ENG_NEAREST, ENG_WEAKEST]

# Author-facing profile id -> resolved axes. The three legacy names stay first
# class so existing content and saves keep resolving unchanged; `hunter` adds the
# weakest-target focus-fire behavior on the existing pursue_unit disposition.
const PROFILES := {
	"basic": {"activation": "always", "disposition": DISP_PURSUE_UNIT, "engagement": ENG_NEAREST},
	"passive": {"activation": "always", "disposition": DISP_HOLD_TILE, "engagement": ENG_NEAREST},
	"healer": {"activation": "always", "disposition": DISP_HEAL, "engagement": ENG_NEAREST},
	"hunter": {"activation": "always", "disposition": DISP_PURSUE_UNIT, "engagement": ENG_WEAKEST},
}

# Fallback profile used when an id is not registered. Matches EnemyAI's old
# `_: pass` (unknown profile fell through to the basic pursue-and-attack logic);
# boot validation still rejects unknown ids so this only guards runtime edge cases.
const _FALLBACK_PROFILE := "basic"


# Resolve a profile id into an AISpec. `group` and `difficulty` are reserved
# no-op layers so the signature is stable for steps 3+ (base preset -> placement
# -> group -> difficulty; difficulty is numbers-only per [AIP-11] and never
# mutates these axes). Returns an AISpec RefCounted.
static func resolve_ai_spec(
	profile_id: String, _group: Variant = null, _difficulty: Variant = null
) -> RefCounted:
	var axes: Dictionary = PROFILES.get(profile_id, PROFILES[_FALLBACK_PROFILE])
	var spec: RefCounted = AISpecScript.new()
	spec.activation = axes["activation"]
	spec.disposition = axes["disposition"]
	spec.engagement = axes["engagement"]
	return spec


# Boot-validation query — replaces membership tests against the old closed const.
static func is_valid_profile(profile_id: String) -> bool:
	return PROFILES.has(profile_id)


# The registered profile ids (for diagnostics/tests).
static func valid_profile_ids() -> Array:
	return PROFILES.keys()
