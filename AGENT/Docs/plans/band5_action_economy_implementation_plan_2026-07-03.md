---
Role: dated
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-03
---

# Band 5 Action Economy Implementation Plan

**Started:** 2026-07-03.

**Track IDs:** `B5-ACTION-GRANT`, `B5-SECONDARY-MOVEMENT`.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 5 rows. Drafted from
[`band5_implementation_plan_handoff_2026-07-02.md`](band5_implementation_plan_handoff_2026-07-02.md)
(Content-chain steps 6-7) against the settled **Q3** walkthrough decision of
2026-07-01.

## Purpose

Add the two skill-driven action-flow features that sit on top of the Plan 1/2
pipelines: a bounded action-grant (Dancer/Reinvigorate — single-target full-turn
ally refresh) and secondary movement (move-after-acting). Both are authored
extensions expressed on the shared effect pipeline, not bespoke systems.

This is a build plan only. It does not authorize starting before the Band 1-3
gates, `B2-OCCUPANCY`, and Plans 1-2 land.

## Scope

1. **`B5-ACTION-GRANT` v1 slice** (Q3): single-target full-turn ally refresh,
   with range, target filter (same-faction / non-hostile), a **named** grant mode
   (default `refresh_full_turn`), a one-refresh-per-unit cap implemented as a
   **general per-unit per-turn action-budget guard**, suspend-safe counters, and
   effect-forecast display.
2. **`B5-SECONDARY-MOVEMENT`**: skill-driven move-after-acting with
   remaining/flat modes and an allowed-action list, expressed safely in the
   action flow, reading `B2-OCCUPANCY`.

## Non-Goals

- Do not build AoE / remote / self-refresh action grants. They are later authored
  extensions on the same pipeline (AoE = a Plan 2 shape); v1 is single-target.
- Do not implement the anti-loop cap as a dance-specific flag — it is the general
  action-budget guard (Q3 watchout).
- Do not build a bespoke refresh effect outside the Plan 2 effect pipeline.
- Do not add saved counters/action-state without F1 manifest rows.
- Do not replace grant modes or allowed-action lists with a closed `enum` +
  `match`.

## Source Docs

- [`band5_implementation_plan_handoff_2026-07-02.md`](band5_implementation_plan_handoff_2026-07-02.md)
- [`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
  → "Walkthrough Decisions (2026-07-01)" Q3.
- [`band5_v1_content_manifest_2026-07-03.md`](../design/band5_v1_content_manifest_2026-07-03.md)
  (§6 Dance / action grant, §7 Canto / secondary movement).
- [`action_grant_open_questions_2026-06-25.md`](../registers/action_grant_open_questions_2026-06-25.md)
- [`secondary_movement_open_questions_2026-06-24.md`](../registers/secondary_movement_open_questions_2026-06-24.md)
- [`band5_conditions_skills_implementation_plan_2026-07-03.md`](band5_conditions_skills_implementation_plan_2026-07-03.md)
  (skills effect pipeline)
- [`band5_source_style_implementation_plan_2026-07-03.md`](band5_source_style_implementation_plan_2026-07-03.md)
  (effect pipeline + forecast the grant/move ride)
- [`band1_determinism_save_implementation_plan_2026-06-30.md`](band1_determinism_save_implementation_plan_2026-06-30.md)
  (`B1-SUSPEND` for counter persistence)

## Decisions Not To Reopen

- V1 action-grant = single-target full-turn ally refresh. AoE/remote/self-refresh
  are later authored extensions on the same pipeline.
- The anti-loop cap is a **general per-unit per-turn action-budget guard**, not a
  dance flag. Any action-flow feature that must not re-trigger a unit reuses it.
- Grant mode is **named** (default `refresh_full_turn`); modes are registry data.
- The refresh runs through the Plan 2 shared effect pipeline (a grant effect +
  ally target filter), and its forecast reuses the Plan 2 forecast.
- Secondary movement has remaining/flat modes and an allowed-action list, all
  data; it reads `B2-OCCUPANCY` for legal destinations.
- Counters/action-state are F1-saved before code; persistence trails
  `B1-SUSPEND`.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates:

- Plans 1-2 (skills effect pipeline, effect forecast, target filters).
- `B2-OCCUPANCY` for secondary-movement legal destinations and refresh-target
  positioning.
- `B1-SUSPEND` before the action counters and mid-flow action-state persist
  (this trails; the feature is buildable and testable in-session before then).
- `B3-REQ` for the target filter and allowed-action predicates.

## Existing Code Touchpoints

Verified 2026-07-03:

- `scripts/core/TurnManager.gd` owns per-unit turn state (has-acted / has-moved)
  — the action-budget guard lives against this state.
- `scripts/skills/SkillHandler.gd` is where the grant/secondary-move effects
  register (Plan 1 converts its dispatch to registry-backed lookup).
- `scripts/units/Unit.gd` tracks per-unit action/movement flags the guard and the
  move-remainder read.
- `scripts/resources/SkillData.gd` triggers (`player_activated`, `on_move`, …)
  drive when the grant/move fire.
- Tests to extend: `test_turn_manager.gd`, `test_skill_item_handler.gd`, new
  `test_action_grant.gd` / `test_secondary_movement.gd`.

## Slice 0 - Preflight After Gates

**Goal:** confirm the shared effect pipeline, occupancy, and forecast exist.

Implementation checklist:

- Run `rg -n "has_acted|has_moved|action_budget|TurnManager|SkillHandler" scripts`.
- Confirm Plans 1-2, `B2-OCCUPANCY`, and `B3-REQ` have landed.
- Reserve F1 rows: per-unit per-turn action-budget counters, action-grant last
  target, and mid-flow action-state for secondary movement.

Tests: none required in preflight.

## Slice 1 - Action-Budget Guard

**Goal:** the general per-unit per-turn action-budget guard the grant (and any
future re-trigger feature) consume.

Files to touch:

- `scripts/core/TurnManager.gd`
- `scripts/units/Unit.gd`
- `scripts/tests/test_turn_manager.gd`

Implementation steps:

1. Add a per-unit per-turn budget keyed by a named budget id (data), decremented
   when a guarded action fires; the refresh cap is "1 refresh received per unit
   per turn" expressed as a budget, not a boolean.
2. Reset budgets at the correct turn boundary; make the guard queryable
   (`can_receive(unit, budget_id)`).
3. Keep the budget suspend-safe (counters persist; trails `B1-SUSPEND`).

Tests:

- A unit can receive a refresh once per turn; a second is refused.
- Budgets reset on the turn boundary.
- Budget counters round-trip through snapshot/save.

F1 obligations: action-budget counter rows before code.

## Slice 2 - Action-Grant Effect (Refresh)

**Goal:** the v1 single-target full-turn ally refresh as an effect on the shared
pipeline.

Files to touch:

- `scripts/skills/SkillHandler.gd` (register the grant effect)
- `scripts/core/TurnManager.gd` (clear has-acted/has-moved on refresh)
- fixture: a Dancer-style skill/style with range + target filter + named mode
- `scripts/tests/test_action_grant.gd`

Implementation steps:

1. Register a grant effect (kind on the Plan 2 effect registry) with params:
   `range`, `target_filter` (same-faction / non-hostile), `grant_mode`
   (default `refresh_full_turn`), and the action-budget id.
2. On resolve: check the Slice 1 budget, refresh the target (clear
   has-acted/has-moved), decrement the budget, record last target.
3. Forecast the grant through the Plan 2 effect forecast (shows "Refreshes: full
   turn").
4. Leave AoE/remote/self as unimplemented authored extensions — the shape and
   filter registries already leave room.

Tests:

- Refresh clears the ally's has-acted/has-moved and lets them act again.
- The per-unit cap blocks a second refresh that turn.
- Self / hostile targets are rejected by the target filter.
- The refresh consumes the dancer's own action.

F1 obligations: action-grant last-target + budget rows before code.

DoD#1 obligations: update `GDD_02`, `GDD_05`, `GDD_07`, `GDD_Feature_Index`,
`GDD_10` with the action-grant landing.

DoD#2 obligations: guard that a new grant mode registers as data (no closed mode
switch), and that the cap is the general budget guard, not a dance flag.

## Slice 3 - Secondary Movement

**Goal:** skill-driven move-after-acting with remaining/flat modes and an
allowed-action list.

Files to touch:

- `scripts/skills/SkillHandler.gd` (register the secondary-move effect)
- `scripts/core/GridManager.gd` (post-action movement range from occupancy)
- `scripts/units/Unit.gd` (movement remainder)
- `scripts/tests/test_secondary_movement.gd`

Implementation steps:

1. Register a secondary-move effect with params: `mode` (`remaining` = leftover
   movement, `flat` = fixed N), and `allowed_actions` (the actions after which
   the move may fire — data list).
2. After an allowed action resolves, offer the move; compute legal destinations
   through `B2-OCCUPANCY`; `remaining` mode uses movement not yet spent, `flat`
   grants N.
3. Ensure the flow is safe mid-action: if suspended between act and move, the
   pending move-state persists and restores (trails `B1-SUSPEND`).

Tests:

- `remaining` mode offers exactly the unspent movement after acting.
- `flat` mode offers N tiles regardless of movement spent.
- The move only fires after an allowed action, not others.
- Occupied/illegal destinations are excluded.

F1 obligations: mid-flow action-state rows before code.

DoD#1 obligations: update `GDD_02`, `GDD_05`, `GDD_10` with secondary movement.

DoD#2 obligations: guard that `allowed_actions` is a data list, not a closed
match.

## Implementation Commit Order

1. Slice 0 preflight.
2. Slice 1 action-budget guard.
3. Slice 2 action-grant refresh effect.
4. Slice 3 secondary movement.

Do not start before Plans 1-2 and `B2-OCCUPANCY` exist. Counter/action-state
persistence trails `B1-SUSPEND`; the features are buildable and testable
in-session before suspend lands.

## Verification Checklist

Same as the Band 2/3/4 plans. Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
git diff --check
```
