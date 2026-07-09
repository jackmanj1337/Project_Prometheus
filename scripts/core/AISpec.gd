extends RefCounted
# Resolved AI composition for one unit — the three axes the planner reads
# (ai_first_build_design_2026-06-22.md §2). Produced by
# AIProfileRegistry.resolve_ai_spec() and consumed by EnemyAI's disposition
# dispatch, which replaces the old `match enemy.data.ai_profile`.
#
# A plain RefCounted (no class_name) so headless `--script` runs need no global
# class-cache entry (see the class-cache headless gotcha).
#
# Axis params (home_tile, aggro_radius, leash_radius, goal_tile, target_policy,
# group_id) join in build-slice step 3 alongside the territorial/tethered/flee/
# seek_tile dispositions that actually read them — kept off the struct until a
# behavior consumes them so we do not carry speculative dead fields.
var activation: String = "always"
var disposition: String = "pursue_unit"
# Target-selection policy (design §9 `target_policy`): "nearest" picks the closest
# hostile (path cost); "weakest" focus-fires the lowest-HP hostile. The targeting
# dispositions (pursue_unit, hold_tile) honour this; heal/flee ignore it. Both
# shipped values thread a real behavior — see EnemyAI._select_target.
var engagement: String = "nearest"
