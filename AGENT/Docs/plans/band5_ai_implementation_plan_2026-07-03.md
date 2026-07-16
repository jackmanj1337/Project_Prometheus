---
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-16
---

# Band 5 AI Composition And Minimum Scorer Implementation Plan

**Started:** 2026-07-03.

**Track IDs:** `B5-AI-COMPOSITION`, `B5-AI-MIN-SCORER`.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 5 rows. Drafted from
[`band5_implementation_plan_handoff_2026-07-02.md`](band5_implementation_plan_handoff_2026-07-02.md)
(AI chain — runs parallel to the content chain) against the settled **Q7**
walkthrough decision of 2026-07-01.

## Purpose

Build the AI half of Band 5: a data-driven AI composition/profile substrate
(`AIProfileDef` registry, activation order, `set_ai`, seek-tile, group wake) and
a single-ply deterministic scorer good enough for v1 maps. Scorer terms and AI
profiles are registries from day one, so Band 7's valuation brain adds terms and
multi-ply `search_depth` as new registered scorers on the same engine — no
rewrite.

The original composition foundation is now partly present as the shipped
`AISpec`/`AIProfileRegistry` seam, and `B2-PROJECTION` provides a pure combat
forecast. That makes a bounded **Slice 3A** available now: score only the weapon
attacks the present AI already plans and executes, while retaining the shipped
planner as an explicit compatibility preset.

The full scorer remains **Slice 3B**. V1 enemies eventually use styles, staves,
AoE, gambits, capture, and other non-combat actions (C5 resolved 2026-07-03), so
parity across the full action palette still requires the Plan 2 generalized
effect forecast. Slice 3B therefore gates on `B5-SOURCE-STYLE` and the remaining
`B5-AI-COMPOSITION` work. Slice 3A does not pretend those dependencies have
landed and cannot close the track by itself.

This is a build plan only. Slice 3A may start against its explicitly listed
implemented seams; every other slice remains behind its recorded gates.

## Scope

1. **`B5-AI-COMPOSITION`**: `AIProfileDef` as registry data (not an enum,
   `[AIP]`), author-selectable activation order, `set_ai` (mid-map profile
   change), seek-tile behavior, group wake, and the `ai_awake` F1 row.
2. **`B5-AI-MIN-SCORER` Slice 3A**: enumerate the legal weapon-attack tuples the
   present planner can already execute and score expected damage, lethal result,
   counter-damage, exposure, and target value with stable tie-breaks. Preserve
   every shipped profile's old decisions through a compatibility preset.
3. **`B5-AI-MIN-SCORER` Slice 3B**: widen the same registry-backed loop to the
   complete `(action, target, source+style)` palette and author profile weights.
   This is the track-closing slice.

## Non-Goals

- Do not build multi-ply search / `search_depth`, perception (`[PER]`), or the
  economy/role valuation terms (`[VAL]`). Those are **Band 7**, added as new
  registered scorer terms + richer data on this same engine.
- Do not ship a fixed term sum. Scorer terms are a registry from day one (Q7
  watchout).
- Do not build a second forecast for the AI. It reuses the same Plan 2
  projection the player sees — AI and UI never diverge (Q7 watchout).
- Do not model AI profiles as an `enum` + `match`. They are `AIProfileDef` data.
- Do not add saved AI fields (`ai_awake`) without an F1 manifest row.

## Source Docs

- [`band5_implementation_plan_handoff_2026-07-02.md`](band5_implementation_plan_handoff_2026-07-02.md)
- [`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
  → "Walkthrough Decisions (2026-07-01)" Q7.
- [`band5_v1_content_manifest_2026-07-03.md`](../design/band5_v1_content_manifest_2026-07-03.md)
  (§8 AI profiles + scorer terms — the floor this plan ships).
- [`ai_profiles_open_questions_2026-06-21.md`](../registers/ai_profiles_open_questions_2026-06-21.md)
  (`[AIP]`)
- [`ai_first_build_design_2026-06-22.md`](../design/ai_first_build_design_2026-06-22.md)
- [`ai_valuation_engagement_open_questions_2026-06-27.md`](../registers/ai_valuation_engagement_open_questions_2026-06-27.md)
  (**Band 7 boundary only** — the terms this plan deliberately defers)
- [`band5_source_style_implementation_plan_2026-07-03.md`](band5_source_style_implementation_plan_2026-07-03.md)
  (the projection the scorer reuses)
- [`band1_determinism_save_implementation_plan_2026-06-30.md`](band1_determinism_save_implementation_plan_2026-06-30.md)
  (`RngService` determinism, `ai_awake` save row)

## Decisions Not To Reopen

- AI profiles are `AIProfileDef` registry data; activation order is
  author-selectable. Adding a profile is data, not an engine edit.
- The scorer is single-ply: enumerate legal `(action, target, weapon/source)`
  tuples, weighted sum, best-with-stable-tie-breaks.
- Scorer terms are a **registry from day one**. Band 7 adds terms; it does not
  crack open a fixed sum.
- The scorer reuses the same projection the player sees.
- Determinism: enumeration order, tie-breaks, and any activation roll are stable
  and route through `RngService`.
- Advanced valuation (`[VAL-1..13]`), perception (`[PER]`), and `search_depth`
  are Band 7.

## Dependency Note

Minimum upstream gates are slice-specific:

- `B2-REGISTRY` for `AIProfileDef` and scorer-term ids.
- `B1-F1` for the `ai_awake` save row.
- `B2-PROJECTION`, `B2-REGISTRY`, the existing `AISpec` composition seam, and
  `RngService` are sufficient for bounded Slice 3A.
- `B3-MET` remains required for `set_ai`, seek-tile targets, and group-wake
  triggers in the remaining composition work.
- The Plan 2
  (`B5-SOURCE-STYLE`) generalized effect forecast — v1 enemies use styles/staves
  (C5), so Slice 3B scores source+style tuples at parity with weapons.

Slice 3A adds no RNG. Stable tuple identifiers resolve full ties. Profiles that
intentionally randomize remain outside this slice and continue to use
`RngService` through their existing path.

## Existing Code Touchpoints

Verified 2026-07-03:

- `scripts/core/TurnManager.gd` already has the AI seam: `_ai_controller`,
  `set_ai_controller(ai)`, `start_enemy_phase()`, `_is_ai_controlled(faction)`,
  and a fallback to `/root/EnemyAI`. This plan builds the controller behind that
  seam — do not add a parallel enemy-turn path.
- `scripts/resources/MapData.gd` unit entries carry `ai_profile: String` per
  spawn; `scripts/resources/UnitData.gd` has `ai_profile = "basic"`. These id
  strings resolve against the new `AIProfileDef` registry.
- Group wake / seek-tile hang off `MapData` authored data (spawn groups, seek
  targets); `B3-MET` owns the map-event triggers that fire `set_ai` / wake.
- Tests to extend: `test_turn_manager.gd`, and new `test_ai_profile.gd` /
  `test_ai_scorer.gd`.

## Slice 0 - Preflight After Gates

**Goal:** confirm the AI seam, projection, and MET triggers exist.

Implementation checklist:

- Run `rg -n "_ai_controller|set_ai_controller|start_enemy_phase|ai_profile|EnemyAI" scripts`.
- Confirm `B2-REGISTRY`, `B1-F1`, `B3-MET`, and `B2-PROJECTION` have landed.
- Reserve the F1 `ai_awake` row.

Tests: none required in preflight.

## Slice 1 - AIProfileDef Registry And Resolution

**Goal:** AI profiles as data; resolve a unit's `ai_profile` id to a profile.

Files to create or touch:

- `scripts/resources/AIProfileDef.gd`
- `scripts/autoloads/RegistryManager.gd` (profile ids)
- `scripts/autoloads/DataManager.gd` (load/validate profiles)
- `scripts/tests/test_ai_profile.gd`

Implementation steps:

1. `AIProfileDef` fields: `id`, `display_name`, `activation_order` (author-chosen
   phase ordering), scorer-term **weights** (a Dictionary keyed by scorer-term
   id — extensible), aggression/behavior params (seek vs hold vs guard),
   seek-tile reference, and wake policy.
2. Register profile ids through `RegistryManager`; resolve `UnitData.ai_profile`
   / `MapData` spawn `ai_profile` against the registry, defaulting `basic`.
3. Validators: unknown profile id, unknown scorer-term weight key, malformed
   activation order.

Tests:

- A `basic` profile validates and resolves from a unit/spawn.
- Unknown profile id / weight key reports a useful error.
- Adding a second profile is pure data (no engine edit).

F1 obligations: none in this slice (profiles are content).

DoD#2 obligations: validator test that a new `AIProfileDef` + a new scorer-term
weight key load as data with no engine switch.

## Slice 2 - Composition: set_ai, Seek-Tile, Group Wake, ai_awake

**Goal:** the mid-map composition behaviors the profile drives.

Files to touch:

- `scripts/core/TurnManager.gd` (the AI controller behind `set_ai_controller`)
- `scripts/resources/UnitData.gd` (`ai_awake` runtime flag)
- MET trigger hooks (`B3-MET`)
- `scripts/tests/test_ai_profile.gd`, `scripts/tests/test_turn_manager.gd`

Implementation steps:

1. `set_ai(unit, profile_id)`: a MET-fired mid-map profile change; validate the
   id resolves.
2. `ai_awake`: units start asleep/guarding until woken; `ai_awake` is F1-saved
   runtime state. Group wake sets `ai_awake` on a spawn group when its trigger
   fires (proximity / turn / event via `B3-MET`).
3. Seek-tile: an awake profile with a seek target moves toward the authored tile
   when no better scored action exists (the scorer's fallback in Slice 3).
4. Activation order: process factions/units per the profile's author-chosen
   ordering deterministically.

Tests:

- A sleeping unit does not act until its group-wake trigger fires.
- `set_ai` swaps a unit's profile mid-map and changes its behavior.
- `ai_awake` round-trips through snapshot/save.
- Seek-tile moves a unit toward its target when no scored action beats holding.

F1 obligations: `ai_awake` row must exist before code.

DoD#1 obligations: update `GDD_06`, `GDD_08`, `GDD_Feature_Index`, `GDD_10` with
the AI composition landing.

## Slice 3A - Bounded Weapon-Attack Scorer (Available Now)

**Goal:** introduce the deterministic, registry-backed scoring seam without
claiming support for actions the present AI cannot yet enumerate or execute.

Before production code, write a requirement/evidence matrix covering:

- legal weapon attacks only; no invented action executor;
- expected damage, lethal result, counter-damage, exposure, and target value;
- stable unit/tile/weapon identifiers as the complete tie-break chain;
- no live-state mutation and no RNG draw during enumeration or scoring;
- an explicit compatibility preset that reproduces shipped profile decisions;
- score-component diagnostics available to tests/headless failures but quiet in
  normal release output.

Exit tests cover lethal/non-lethal, counter/no-counter, exposure, stable ties,
wait/staff fallback delegation, forecast parity, mutation/RNG guards, an open
fixture scorer term, and byte/decision fixtures for the compatibility preset.
Staff fallback is a regression obligation here, not a newly scored staff action.

Landing Slice 3A changes the control-plane track to **Split**, not Implemented.
The GDD/roadmap must describe exactly the weapon-scoring subset that landed.

## Slice 3B - Full Minimum Single-Ply Scorer (Dependency-Gated)

**Goal:** widen Slice 3A to every required v1 action tuple and pick the best by a
registry-backed weighted sum, reusing the player forecast.

Files to create or touch:

- `scripts/ai/ActionScorer.gd`
- `scripts/ai/scorer_terms/` (built-in term set: outcome, survival, objective,
  profile weights)
- `scripts/autoloads/RegistryManager.gd` (scorer-term ids)
- `scripts/tests/test_ai_scorer.gd`

Implementation steps:

1. Enumerate legal `(action, target, source+style)` tuples for the acting unit
   (reachable tiles × usable sources × applicable styles × valid targets), in a
   deterministic order. **Styles and staves are enumerated, not just weapons**
   (C5): an enemy dancer, healer, or combat-artist scores its style/staff options
   the same way it scores a plain attack. With the widened palette (owner "widen
   everything"), enumeration also covers **AoE shapes** (score the summed outcome
   over every footprint tile), **gambits** (charge-limited AoE), and **capture**
   (a non-lethal option scored via the same forecast) — the scorer treats them as
   more tuples through the one Plan 2 forecast, not special cases.
2. For each tuple, run the **Plan 2 projection** (the same forecast the player
   sees) and score with the registered terms:
   - **immediate projected outcome** (damage dealt / kill / heal from the
     forecast),
   - **survival danger** (projected incoming damage at the destination),
   - **objective pressure** (progress toward the map objective),
   - **author profile weights** (the `AIProfileDef` term weights).
3. Register scorer terms through `RegistryManager` so Band 7 adds
   perception/economy/role terms and `search_depth` without editing the scorer
   loop.
4. Pick the highest score with **stable tie-breaks** (deterministic ordering,
   `RngService` only if a profile intentionally randomizes — behind a
   `# rng-allow:` guard). Fall back to seek-tile/hold when no action scores
   positive.
5. **Berserk override (C6):** when the acting unit has a condition with
   `overrides_targeting` (berserk), the scorer's valid-target set is
   **hostile-to-all** (every other unit, own side included) and the author profile
   weights are bypassed — the condition's targeting override wins over the profile,
   consistent with the Slice 3 targeting-override in the conditions plan. It stays
   one enumeration path (berserk widens the target set), not a special scorer.

Tests:

- Given a killable target in range, the scorer chooses the killing tuple.
- An enemy with a healing staff heals a hurt ally when that scores above its
  attack options; an enemy dancer refreshes an ally when that scores highest
  (C5 — styles/staves are scored, not ignored).
- Given lethal counter-danger, a cautious profile's survival term deters the
  attack; an aggressive profile's weights still take it.
- Objective-pressure term moves a seize-profile unit toward the objective.
- The scorer's projection equals the player's `AttackPreview` for the same tuple
  (AI/UI never diverge).
- Enumeration + tie-breaks are deterministic across runs (same seed → same
  choice).
- Adding a fixture scorer term changes scoring with no `ActionScorer` loop edit.
- **Berserk (C6):** a berserked AI unit targets any unit including its own side
  (targeting override honored over the profile weights), and attacks the
  best-scoring reachable target regardless of faction.

F1 obligations: none (scoring is derived; `no_save_guard` on the scorer).

DoD#1 obligations: update `GDD_08`, `GDD_10` with the v1 scorer landing.

DoD#2 obligations: guard that a new scorer term registers as data and is summed
by the generic loop, not a hardcoded 4-term expression.

## Implementation Commit Order

1. Slice 0 preflight.
2. Slice 1 `AIProfileDef` registry + resolution.
3. Slice 2 composition (`set_ai`, seek-tile, group wake, `ai_awake`).
4. Slice 3A bounded weapon-attack scorer (available against the existing seams).
5. Slice 3B full action-palette scorer after its dependencies land.

Slices 1-2 (remaining composition) run parallel to Plans 1-3. Slice 3A is a
compatibility-preserving foundation over today's weapon planner. **Slice 3B gates
on Plan 2 (`B5-SOURCE-STYLE`) and the remaining composition contract**: v1
enemies use styles/staves (C5), so track closure requires source+style tuples
through the Plan 2 forecast.
Band 7's valuation brain (`[VAL]`/`[PER]`/`search_depth`) plugs in as new
registered scorer terms on this engine — do not pre-build them here.

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
