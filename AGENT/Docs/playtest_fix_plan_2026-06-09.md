# Playtest Fix Plan — 2026-06-09

> **Historical** — all fixes resolved; superseded by the v0.1.4 release and
> subsequent sessions. Retained for provenance. Do not use as a live action list.

## Goal

Resolve every defect and requested usability improvement recorded in the latest
`GDD_Manual_Tasks.md` responses, while keeping campaign implementation out of
this bug-fix series.

Unchecked manual tests with no reported failure remain validation work. The four
May fixes already marked closed must be regression-tested first and reopened
only if they still fail: Map 900 hotseat handoff, hotseat combat preview dispatch,
Map 950 reclass-menu overflow, and staff-use force-level-up.

## Locked Decisions

- Retry restarts the map from its initial launch state.
- Player-facing map coordinates are one-based; upper-left is `(1, 1)`.
- The Seize map is won only through `Seize`; routing Red is not a Blue victory.
- Both named Escape units must escape. Either unit dying is immediate defeat.
- A paired lead escaping also escapes its support and counts both units.
- Reclassing replaces class base-stat contributions while preserving personal
  stats and earned level-up gains, then clamps to the new class caps.
- More Info shows effective growth and fixed-growth progress as `X / 100`.
- Confirm/left-click advances level-up notifications. Ordinary menus allow
  Cancel/right-click and backdrop dismissal; consequential confirmations do not.
- Single-target threat display is temporary per-enemy inspection; `Q` remains
  the global threat toggle.
- Camera overscan is fixed and viewport-aware. Pan speed/smoothing is a user
  preference; overscan does not need its own setting.
- Campaign-owned rule defaults and designer locks are roadmap work, not part of
  this plan.

## Work Order

### 1. Baseline and Regression Recheck

1. Run `bash run_tests.sh`.
2. Recheck the four closed May fixes.
3. Capture a minimal reproduction for each failure that remains.
4. Recheck the Red archer using the diagnostic fields in
   `GDD_Manual_Tasks.md`; do not change AI until guard behavior versus pathing
   failure is known.

### 2. Objective Correctness

Fix objectives before UI polish because wrong map resolution invalidates later
playtests.

Likely ownership:

- `scripts/autoloads/ConditionManager.gd`
- objective resources and Maps 002–005 data
- `scripts/ui/ActionMenu.gd`
- Pair Up / escape registry coordination

Required outcomes:

- Seize appears only for a `can_seize` unit on the authored tile.
- Routing Red on the Seize map does not win the map; Blue rout is defeat.
- Required Escape-unit death resolves defeat immediately.
- Pair-escaping removes and records both lead and support.
- Enemy rout does not become an undeclared Escape-map victory.

Add evaluator tests for exclusive Seize victory, required-unit death, paired
Escape completion, and absence of implicit hostile-rout victory for Blue. Then
run live checks on Maps 002 and 004.

### 3. Progression and Class Changes

Likely ownership:

- `scripts/units/Unit.gd`
- promotion/reclass services and screens
- `scripts/ui/LevelUpScreen.gd`
- `data/roster/test/map_950_promotion_validation/`

Required outcomes:

- Reclass swaps class base-stat contributions, preserves earned/personal stats,
  and clamps to new caps.
- Class-change UI shows old value, signed change, new value/cap, and skills gained.
- A level-20 General has every skill earned at or below its progression level.
- Promotion-item usability refreshes when a unit becomes eligible.
- Level-up notifications queue without dropping middle entries.
- Level-up content handles more than five raised stats and remains dismissible.
- Add a level-19 tier-1 fixture and a fixture that can exceed the equipped-skill
  cap during one validation run.
- Retry after an in-map class change restores initial map state.

### 4. Pair Up Action Integrity

Likely ownership:

- `scripts/autoloads/PairUpRegistry.gd`
- `scripts/core/MapCursor.gd`
- `scripts/ui/ActionMenu.gd`
- combat-context / Pair Up bonus resolver

Required outcomes:

- Creating a pair marks both units done and permits normal phase auto-end.
- Swap exchanges lead/support roles before expending the action.
- Escape handles paired units as defined above.
- Pair Up bonuses affect the same context used by preview and resolution.

Documented comparison: Hero lead with Cavalier support should receive the table's
flat `+1 Str`, `+1 Def`, `+1 Spd`, plus any support-level scaling from
`data/pair_up/pair_up_bonus_table.tres`.

### 5. Combat Preview and More Info

Broken-layout evidence:

- `AGENT/Docs/2026-06-09 broken combat preview.png` (`1335×806`)

Inspect the screenshot directly before choosing layout dimensions and preserve
both the base forecast and the More Info panel as distinct readable regions.

Likely ownership:

- `scenes/ui/AttackPreview.tscn`
- `scripts/ui/AttackPreview.gd`
- `scripts/shared/MoreInfoContent.gd`
- `scripts/shared/StatBreakdown.gd`
- `scripts/ui/UnitDetailsScreen.gd`

Required outcomes:

- Normal forecast rows remain visible while More Info cycles.
- More Info cannot cover or replace the base forecast.
- Counter/no-counter, triangle, effectiveness, crit, and Vantage rows do not overlap.
- Character stat details show active modifiers.
- Stat details add effective growth and fixed-growth progress `X / 100`.
- A validation fixture provides a reliable positive modifier.

Test at `1280×720`, the screenshot size, and a narrower viewport.

### 6. Map HUD, Camera, Threat, and Input

Likely ownership:

- `scripts/ui/HUD.gd` and terrain/map-details UI
- `scripts/core/CameraController.gd`
- `scripts/core/GameMap.gd`
- `scripts/core/MapCursor.gd`
- `scripts/core/GridManager.gd`
- `scripts/ui/MapMenu.gd`

Required outcomes:

- Map details show one-based coordinates.
- Compact details remain at the bottom; expanded details grow upward and scroll.
- Available tile actions remain visible and terrain content does not clip.
- Camera limits include viewport-aware overscan for edge panels.
- Mouse-follow camera catch-up is slower/smoother.
- Mouse-wheel input over New Game UI does not alter map camera state.
- Movement cancel returns the cursor to the selected unit.
- Ordinary map-menu backdrop/Cancel closes the menu and restores control.
- Inspecting one enemy can show only that enemy's threat range; `Q` remains global.
- New Game panel is centered beneath its title.

## Commit Sequence

1. objective correctness
2. progression and class-state fixes
3. level-up queue/layout
4. Pair Up action integrity
5. combat preview and More Info
6. map HUD/camera/input polish
7. validation fixtures and manual-test updates

Run focused suites after each commit and `bash run_tests.sh` after each workstream.

## Deferred Campaign Work

Do not add campaign resources, saves, or campaign-specific New Game UI here.
The eventual campaign layer must provide defaults for every New Game rule, mark
rules adjustable or designer-locked, store player selections in that campaign
save, and support single-map campaigns through the same contract.

This is tracked in `GDD_10_Roadmap.md` and `AGENT/Docs/campaign_rules.md`.
