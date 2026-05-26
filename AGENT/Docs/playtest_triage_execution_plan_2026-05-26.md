# Playtest Triage Execution Plan — 2026-05-26

## Goal

Turn the merged playtest triage list into an execution order that fixes the
highest-risk gameplay bugs first, closes the documentation gaps that block
reliable manual validation, and adds the requested `Exit to Main Menu` button
to the in-map menu without destabilizing unrelated systems.

## Recommended Order

1. `Map 900` hotseat phase handoff / refresh bug
2. `Map 900` hotseat combat preview bug
3. `Map 950` reclass menu overflow
4. Debug `Force Level-up` on staff use
5. Map selector labels + manual-task roster expectations
6. Map-menu `Exit to Main Menu` button

This order is deliberate:
- The hotseat control bug is the most severe live-play failure and can also
  poison follow-up testing by leaving the wrong faction active.
- The hotseat preview bug should be fixed before more hotseat validation so the
  combat UI is trustworthy again.
- The reclass overflow and staff debug gap are local fixes with clear tests.
- The documentation and selector cleanup should happen after the live bugs so
  the playtest script reflects the corrected runtime behavior.
- The main-menu button is useful but not a blocker for core validation.

## Workstream A — Hotseat Turn Flow

### Scope

Fix the report from `Map 900` where Green ends turn 1, Red and Yellow act, Blue
phase is announced, but control stays on Green and Green units fail to refresh
on turn 3.

### Likely Files

- `scripts/core/TurnManager.gd`
- `scripts/core/HotseatController.gd`
- `scripts/core/MapCursor.gd`
- `scripts/core/MapCursorSelection.gd`
- `scripts/tests/test_turn_manager.gd`
- `scripts/tests/test_game_map_scene.gd`

### Suspected Failure Shape

- `TurnManager.start_enemy_phase()` correctly loops controllers in the abstract,
  but the live cursor/controller handoff likely leaves the cursor bound to the
  prior hotseat faction after Blue resumes.
- The refresh symptom suggests either the active faction index is wrong at the
  phase boundary or Blue's start-of-phase reset path is being skipped after the
  hotseat/AI chain.

### Plan

1. Reproduce in code first with a targeted headless test that simulates
   `blue -> green HOTSEAT -> red AI -> yellow AI -> blue`.
2. Assert three things in the new test:
   - active faction returns to Blue
   - cursor controlling faction returns to Blue
   - Blue refresh logic runs while Green does not stay latched
3. Fix the handoff at the smallest seam possible:
   - prefer correcting the scheduler/cursor contract in `TurnManager` or
     `HotseatController`
   - avoid map-specific patches in `Map 900`
4. Re-run the hotseat manual checklist on `Map 900`.

### Exit Criteria

- Blue regains control after Red and Yellow finish.
- Later Blue turns remain controllable.
- Green units only refresh on Green's own round boundary.

## Workstream B — Hotseat Combat Preview

### Scope

Fix the `Map 900` case where a Green attack target opens partial `More info`
content instead of the normal combat prediction.

### Likely Files

- `scripts/core/MapCursorTargeting.gd`
- `scripts/core/MapCursor.gd`
- `scripts/ui/AttackPreview.gd`
- `scripts/ui/HUD.gd`
- `scripts/shared/MoreInfoContent.gd`
- `scripts/tests/test_attack_preview_selector.gd`
- `scripts/tests/test_map_cursor.gd`

### Suspected Failure Shape

- The targeting layer probably recognizes the hostile target correctly, but a
  hotseat-specific controlling-faction transition is leaving one preview input
  surface stale, so the HUD/More Info path is winning instead of the attack
  preview path.
- Because the new `.uid` files exist for attack-preview and More Info tests,
  there is already a strong hint that those surfaces were recently expanded and
  may need contract coverage rather than broad refactoring.

### Plan

1. Reproduce with a focused test around Green selecting a hostile target.
2. Verify the state transition is:
   `TARGETING/CHOOSING -> PREVIEWING -> resolve/cancel`
   and not `TARGETING -> terrain/unit info refresh`.
3. Fix the dispatch order at the narrowest level:
   - target confirmation gate in `MapCursorTargeting`
   - preview/opening coordination in `MapCursor`
   - HUD suppression only if the preview itself is correct and the HUD is
     overpainting it
4. Add a regression test that a non-Blue controlling faction still receives the
   standard attack preview.

### Exit Criteria

- Green attacking Red or Yellow shows the same forecast structure Blue gets.
- Preview cancel and confirm both return to the correct cursor state.

## Workstream C — Reclass UI Overflow

### Scope

Fix `Map 950` reclass options running off the bottom of the screen with no way
to reach lower choices.

### Likely Files

- `scenes/ui/ReclassScreen.tscn`
- `scripts/ui/ReclassScreen.gd`
- `scripts/tests/test_reclass_screen.gd`
- `scripts/tests/test_map_950_promotion_validation.gd`

### Plan

1. Make the options area scrollable or otherwise bounded to the viewport.
2. Keep focus navigation intact for keyboard/controller use.
3. Add a test that opens the screen with enough options to require overflow and
   verifies the options live inside a constrained container instead of growing
   unbounded.
4. Manually validate on `Map 950`.

### Exit Criteria

- Lower reclass entries remain reachable.
- The cancel button remains reachable.
- Existing two-option smoke tests still pass.

## Workstream D — Debug `Force Level-up` on Staff Use

### Scope

Make the debug `F10` force-level-up path work for staff EXP, not just combat.

### Likely Files

- `scripts/units/Unit.gd`
- `scripts/core/CombatResolver.gd`
- any EXP-award helper shared by combat and staff actions
- `scripts/tests/test_unit_stats.gd`

### Suspected Failure Shape

- Combat already routes through `CombatResolver.calculate_exp()`, which checks
  `GameState.debug_force_levelup`.
- Staff healing likely awards EXP through a separate path in `Unit.gd`, so the
  debug override is not being reused.

### Plan

1. Extract or centralize the debug-level-up override so all EXP-award paths use
   the same rule.
2. Add a unit test that enables the debug flag, performs a staff heal, and
   asserts a level-up fires.
3. Confirm the normal non-debug EXP path is unchanged.

### Exit Criteria

- `F10` works on staff use.
- Normal healing EXP remains intact when debug is off.

## Workstream E — Documentation / Selector Cleanup

### Scope

Close the two remaining playtest documentation gaps:
- duplicate `Map 001` naming in the selector
- missing expected rosters / required knowledge in manual tasks

### Likely Files

- map metadata for `Map 001` and the faction-demo map
- `AGENT/GDD/GDD_Manual_Tasks.md`
- `AGENT/GDD/GDD_10a_Overview.md` if roadmap wording needs sync

### Plan

1. Rename the duplicate map labels so the selector clearly distinguishes the
   baseline rout map from the faction demo map.
2. Update the manual task setup blocks to name:
   - which roster is expected on each validation map
   - which toggles/settings matter before launch
   - which objective types are intentionally still blocked on `Maps 002–005`
3. Do not claim `Seize` / `Escape` are testable until those authored maps land.

### Exit Criteria

- The selector no longer shows ambiguous `001` entries.
- A tester can launch each current validation map without outside context.

## Workstream F — Map Menu `Exit to Main Menu`

### Scope

Add a safe `Exit to Main Menu` option to the in-map `MapMenu`.

### Likely Files

- `scenes/ui/MapMenu.tscn`
- `scripts/ui/MapMenu.gd`
- `scripts/core/MapCursor.gd`
- `scripts/autoloads/GameState.gd` if cleanup/reset is needed
- `scripts/tests/test_map_cursor.gd`
- a new focused `MapMenu` or scene-navigation test if practical

### Design Recommendation

Use the same destination as `GameOverScreen._on_quit()`:
`res://scenes/core/Boot.tscn`

Why:
- it preserves the existing boot-to-main-menu route
- it avoids adding a second canonical title-scene jump path
- it gives one chokepoint if startup routing changes later

### Plan

1. Add a new button between `Settings` and `Close`.
2. Emit a dedicated signal from `MapMenu` instead of hard-coding scene changes
   in the menu itself.
3. Handle the scene transition from `MapCursor` or another map-level owner so
   menu UI stays dumb and reusable.
4. Decide whether the action needs a confirmation dialog.

Recommendation:
Add confirmation on the first pass. Quitting to menu from a live map is
destructive relative to current progress, and the current map menu already uses
confirmation for early end-turn.

### Exit Criteria

- The map menu exposes `Exit to Main Menu`.
- Confirming it returns to Boot/MainMenu cleanly.
- Canceling it restores cursor control without soft-locking the map.

## Test Plan

Run these after each relevant slice, not only at the end:

- `godot --headless --path /workspace --script res://scripts/tests/test_turn_manager.gd`
- `godot --headless --path /workspace --script res://scripts/tests/test_map_cursor.gd`
- `godot --headless --path /workspace --script res://scripts/tests/test_reclass_screen.gd`
- `godot --headless --path /workspace --script res://scripts/tests/test_unit_stats.gd`
- `godot --headless --path /workspace --script res://scripts/tests/test_game_map_scene.gd`

Then run:

- `bash run_tests.sh`

Manual follow-up after the code slices:

- `Map 900 - Hotseat Validation`
- `Map 950 - Promotion Validation`
- `Map 001` selector/menu smoke pass

## First Implementation Slice Recommendation

Start with Workstream A, then immediately do Workstream B in the same
hotseat-focused branch of work.

Reason:
- both bugs block the same validation map
- both depend on faction-control correctness
- fixing them together gives the fastest route back to a trustworthy hotseat
  playtest
