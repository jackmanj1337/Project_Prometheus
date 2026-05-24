# More Info Mode Plan — 2026-05-24

## Purpose
Turn the current ad-hoc stat breakdown work into a deliberate **More Info
Mode** that helps playtesting and debugging without forcing the player to leave
 the current screen or guess where a modifier came from.

## Current State
- `UnitDetailsScreen` already shows:
  - effective stat values
  - per-stat base/modifier/total breakdown text
- The map HUD now shows the hovered unit's level but does **not** expose stat
  sources inline.
- There is no cross-UI "inspection mode" yet. The current breakdown is only
  reachable through the unit-details page.

## Goal
Add a reusable inspection mode where a stat value can answer:
1. What is the unit's **base** value?
2. What modifiers are active **right now**?
3. What is the **signed delta** from each modifier?
4. What is the final **effective** value being used?

## Recommended MVP
Deliver this in two layers:

### Layer 1 — Unit Details First
Use the existing `UnitDetailsScreen` as the stable debugging surface.

Deliverables:
- Keep the current text breakdown
- Color current values:
  - green when effective > base
  - red when effective < base
- Normalize modifier text so every entry shows:
  - source id/name
  - signed delta
  - duration type when useful (`turn`, `map_turn`, `combat`, `permanent`)

Why first:
- no new input model needed
- low-risk for playtesting
- already implemented enough to serve as the source-of-truth debug page

### Layer 2 — True "More Info Mode"
Add an explicit inspect mode that can be toggled while viewing UI stats.

Recommended UX:
- toggle on/off from unit-details with a button or key prompt
- when active, selecting or focusing a stat opens a small explanation panel
- the panel should show:
  - stat label
  - base value
  - modifier list
  - total
  - optional note for terrain / Pair Up / temporary combat modifiers

## Suggested First Surfaces
Implement in this order:
1. `UnitDetailsScreen`
2. map HUD unit-info panel
3. combat preview stats

Reasoning:
- these are the surfaces most often used while debugging live play
- they already expose stats, so the extra info adds value immediately
- this keeps formatting/data logic reusable before expanding UI reach

## Data Contract
Create one shared helper instead of recomputing breakdowns in each UI script.

Recommended helper shape:

```gdscript
{
  "stat": "strength",
  "label": "Str",
  "base": 9,
  "effective": 11,
  "total_delta": 2,
  "mods": [
    {"source": "tonic", "delta": 2, "duration_type": "turn"}
  ]
}
```

Suggested location:
- `scripts/shared/StatBreakdown.gd`
or
- helper methods on `Unit.gd` if you want the breakdown to stay tightly bound
  to runtime unit state

Recommendation:
- prefer a small shared helper over more UI-local formatting logic
- keep `Unit.get_effective_stat()` as the authoritative math
- have the helper explain the math, not replace it

## Scope Rules
For the first full mode:
- include only modifiers from `active_modifiers`
- do not invent synthetic entries unless they already affect effective stat math
- terrain bonuses should be shown only on surfaces where they actually matter
- Pair Up bonuses should be included when they are present as live modifiers

Do **not** try to fold in:
- future combat-preview-only transient math that is not represented in unit
  runtime state
- speculative or unavailable future systems

## Test Plan
Add tests in this order:
1. unit-details rendering test for boosted and reduced colors
2. shared breakdown helper unit test
3. map HUD rendering test once the HUD surface is added
4. combat-preview test once that surface is added

Important assertions:
- boosted stat renders green
- reduced stat renders red
- unchanged stat renders default color
- breakdown lists every active modifier for the stat
- unrelated modifiers do not appear under the wrong stat

## Open Questions
- Should the mode use raw source ids (`pair_up`, `tonic`) or player-facing
  display names (`Pair Up`, `Tonic`)?
- Should duplicate-source multi-stat effects be grouped visually?
- Should duration info be shown in the MVP text or deferred until the panel UI?
- Should the map HUD use hover, confirm, or a dedicated key to drill into a
  stat?

## Recommended Next Implementation Step
Extract the current unit-details breakdown formatting into a shared helper
before extending the same concept to the HUD or combat preview.
