> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# v0.2.0 Playtest Triage and Fix Plan — 2026-06-19

Status: Planned
Last verified: 2026-06-19

## Scope

This is a plan-only triage pass for the returned v0.2.0 playtest package. Source
code changes wait for user approval.

Evidence:

- Returned checklist (archived 2026-06-19):
  `AGENT/Docs/playtest_checklist_v0.2.0_returned_2026-06-19.md`
- Tester log + screenshots: removed from the working tree after triage; recoverable
  from git history (last present under `AGENT/v0.2.0 playtest results/` before commit
  `3b0a308`).

Log result: no `DataManager`, `ERROR`, or `SCRIPT ERROR` lines were reported.
The log only shows expected pre-M9 skill stub warnings (`armsthrift`, `dash`,
`disarm`) plus a generic `ObjectDB instances leaked at exit` warning. Treat the
warning as monitor-only unless a verbose log later identifies leaked nodes.

## Triage Summary

Fix before the next playtest build:

1. `V020-01` — high-zoom camera jitter and over-max zoom reframe.
2. `V020-02` — Settings Map Zoom slider saves but does not apply live.
3. `V020-03` — combat forecast can overlap the defender under zoom.
4. `V020-04` — repeated F9 hotseat toggling refreshes already-spent units.
5. `V020-05` — objective HUD displays Seize tile in zero-based coordinates.
6. `V020-06` — HUD layout reset misplaces the terrain More Info panel when expanded.
7. `V020-16` — split menu UI scale from HUD layout scale after the bug fixes.

Character sheet / More Info / validation work before the next playtest build:

8. `V020-07` — rename or explain `Int` on the character sheet.
9. `V020-08` — replace Pair Up bonus duration marker `(-)` with clearer scope text.
10. `V020-09` — show support partner name on the on-map unit HUD.
11. `V020-15` — add CON and LoS stats to the character sheet.
12. `V020-11` — add class summary / class features to the character sheet.
13. `V020-10` — add weapon stats to More Info and add the full directional selector.
14. `V020-14` — add a Map 950 stat-debuff validation tonic/test item.

Small polish / handbook work before the next playtest build:

15. `V020-12` — improve HUD layout editor affordances.
16. `V020-13` — explain Borderless vs Fullscreen in the next tester handbook only.

No immediate implementation recommended:

- Part I C.1/C.2 were unchecked, but comments say the New Game behavior is usable
  and likely to change during campaign work. Regression item 1.2 passed and the
  behavior matches GDD_07 plus `test_new_game_screen.gd`; leave this for the
  campaign-layer redesign.
- E.6 was not run because no smaller monitor was available; keep pending validation.
- 7.2 was unchecked with no comment; request a rerun note before treating it as a
  defect.
- 8.4 was unchecked with no comment. A.4 confirmed the tonic breakdown immediately;
  the four-turn expiration still needs a live rerun.

## Recommended Order

1. **Camera/zoom bug fixes:** `V020-01`, `V020-02`, `V020-03`.
2. **State/objective/HUD bug fixes:** `V020-04`, `V020-05`, `V020-06`.
3. **Approved post-bug-fix display split:** `V020-16`.
4. **Character-sheet clarity and stat expansion:** `V020-07`, `V020-08`,
   `V020-09`, `V020-15`, `V020-11`.
5. **More Info before next playtest:** `V020-10`.
6. **Validation fixture:** `V020-14`.
7. **Polish and handbook:** `V020-12`, `V020-13`.

This order fixes play-blocking regressions first, then lands the approved UI-scale
split while the display code is still in focus, then expands the character sheet and
More Info surfaces testers will use in the next pass.

## Workstream A — Camera Zoom and Forecast Placement

### V020-01 — High-Zoom Camera Jitter

Tester report: at zoom levels `3x` and `4x`, moving left/right/down makes the
camera jump, and trying to zoom past `4x` also jumps.

Likely files:

- `scripts/core/CameraController.gd`
- `scripts/core/MapCursor.gd`
- `scripts/tests/test_camera_controller.gd`

Likely cause:

- `CameraController.keep_cursor_in_view()` uses the full configured edge buffer
  even when the visible tile span is very small at `3x`/`4x`. With a 5-tile view
  and a 2-tile buffer, there is almost no stable middle zone, so normal cursor
  movement can shove the top-left target back and forth.
- `step_zoom()` clamps at min/max but still reruns `set_zoom_index()` even when
  the zoom index did not change, so pressing zoom-in at `4x` can reframe the
  camera despite no actual zoom change.

Plan:

1. Add a pure helper that reduces the effective edge buffer when the visible tile
   span is too small.
2. Make `step_zoom()` no-op on already-clamped indices, returning the same index
   without reframing.
3. Add tests for `4x` movement stability and zoom-past-max no-op behavior.

Recommendation: keep the eight existing zoom levels. Do not lower the max zoom
unless the stability fix still feels bad in live play.

### V020-02 — Settings Map Zoom Slider Does Not Apply Live

Tester report: the Settings slider moves and its label updates, but the active map
does not change zoom until later.

Likely files:

- `scripts/ui/SettingsScreen.gd`
- `scripts/core/GameMap.gd`
- `scripts/core/CameraController.gd`
- `scripts/tests/test_settings_screen.gd`
- `scripts/tests/test_camera_controller.gd`

Confirmed code shape:

- `SettingsScreen._on_map_zoom_changed()` only updates `SettingsManager.map_zoom_index`
  and saves. It does not call the live map's `CameraController`.

Plan:

1. Add a small live-zoom application path from Settings to the active map/camera
   controller.
2. Reuse the same focus tile as keyboard zoom, preferably the map cursor's tile.
3. Keep saving through `SettingsManager` so persistence stays unchanged.
4. Add a focused test seam for live slider application if practical; otherwise
   strengthen the settings scene smoke test and camera-controller unit tests.

Recommendation: expose this through a method on the map/cursor owner rather than
letting Settings write directly to `Camera2D`.

### V020-03 — Combat Forecast Overlaps Defender Under Zoom

Tester report: the combat preview overlaps the defender at most zoom levels and
positions.

Likely files:

- `scripts/ui/AttackPreview.gd`
- `scripts/core/CameraController.gd`
- `scripts/tests/test_attack_preview_position.gd`
- `scripts/tests/test_attack_preview_selector.gd`

Likely cause:

- Side placement clamps to the viewport and HUD panels, but it does not treat the
  defender's on-screen tile rect as an avoid rect.
- At map edges or narrow viewports, the camera-pan fallback may not create enough
  side space, so the final clamp can push the panel over the defender.

Plan:

1. Add a defender screen-space rect to the placement rules.
2. If neither side placement can avoid the defender, fall back to above/below
   placement before accepting overlap.
3. Test at `0.5x`, `1x`, `2x`, and `4x`, including a defender near map edges.
4. Keep the existing HUD-avoidance behavior from v0.1.4.

Recommendation: prioritize "never cover the defender" over always placing the
forecast on the right/left side.

## Workstream B — State and Objective Bugs

### V020-04 — F9 Repeated Toggle Reactivates Spent Units

Tester report: repeated F9 switching during an enemy phase reactivates units that
had already spent their action.

Likely files:

- `scripts/core/TurnManager.gd`
- `scripts/core/HotseatController.gd`
- `scripts/tests/test_turn_manager.gd`

Confirmed code shape:

- `TurnManager.start_enemy_phase()` reruns the same faction after F9 handoffs.
  Each rerun currently executes `_refresh_faction_units(active_faction())` and
  `_begin_phase(...)` again, so spent units can be reset to READY.

Plan:

1. Track whether the active faction's phase-start refresh has already run during
   this `start_enemy_phase()` pass.
2. On same-faction reruns caused by F9 handoff, skip `_refresh_faction_units()` and
   `_begin_phase()` while still allowing UI cleanup and controller swap.
3. Add a regression test where a red unit is DONE, F9 toggles hotseat/AI more than
   once, and the unit remains DONE.

Recommendation: fix the rerun semantics rather than special-casing F9 units. The
same principle will matter if other debug or online handoffs replay a controller.

### V020-05 — Seize Objective Text Uses Zero-Based Tile

Tester report: Map 002's objective window lists the Seize tile as `(15, 2)`;
player-facing terrain coordinates and the handbook say `(16, 3)`.

Likely files:

- `scripts/resources/ObjectiveCondition.gd`
- `scripts/ui/HUD.gd`
- `scripts/tests/test_data_layer.gd`
- possibly `scripts/tests/test_hud.gd`

Confirmed code shape:

- `data/maps/map_002_seize/map_002_seize_data.tres` correctly authors
  `tile = Vector2i(15, 2)` internally.
- `ObjectiveCondition.get_display_text()` renders `str(tile)` directly.

Plan:

1. Add a player-facing coordinate formatter for objective display.
2. Render Seize as one-based while keeping all evaluator/data validation logic
   zero-based.
3. Add/adjust tests so `Vector2i(3, 4)` displays as `(4, 5)`.

Recommendation: put the formatter near `ObjectiveCondition.get_display_text()` for
now. If more objective text grows later, extract a shared coordinate helper.

### V020-06 — HUD Reset With Terrain More Info Expanded

Tester report: if terrain More Info is open when HUD layout reset runs, the top of
the More Info page goes to where the compact panel top would be.

Likely files:

- `scripts/ui/HUD.gd`
- `scripts/ui/HudLayoutEditor.gd`
- `scripts/tests/test_hud_layout.gd`

Likely cause:

- The editor treats `TerrainCorner` as the movable/scalable layout panel. The
  expanded `TerrainMoreInfoPanel` is a child of that corner and remains visible
  during reset, so its local position/size can be wrong after `apply_layout({})`.

Plan:

1. Reproduce in a headless HUD layout test by expanding terrain More Info, applying
   an offset/scale, then calling `reset_layout()`.
2. Make reset/apply-layout reflow the terrain expanded panel relative to the compact
   terrain info panel.
3. Consider collapsing terrain More Info when entering the HUD editor if reflowing
   creates confusing live editing.

Recommendation: reflow rather than auto-close. Closing More Info during reset would
hide the bug but surprise the player.

## Workstream C — Approved Post-Bug-Fix Display Split

### V020-16 — Split Menu Scale From HUD Layout Scale

Tester report: UI scale changes the location of HUD and menus. User decision
2026-06-19: split this after the bug fixes, and make sure menus stay centered at
each scale.

Likely files:

- `scripts/autoloads/SettingsManager.gd`
- `scripts/ui/SettingsScreen.gd`
- `scripts/ui/HUD.gd`
- `scenes/ui/*.tscn`
- `scripts/tests/test_settings_manager.gd`
- `scripts/tests/test_settings_screen.gd`
- `scripts/tests/test_hud_layout.gd`

Plan:

1. Replace or split the current global UI-scale setting so menu/modal UI can scale
   without also changing HUD panel placement semantics.
2. Keep HUD size/position under the HUD Layout editor (`hud_layout`) instead of the
   menu-scale control.
3. Verify Main Menu, New Game, Settings, Map Menu, combat forecast, item/action
   menus, character sheet, and level-up/promotion/reclass modals stay centered or
   intentionally anchored at every supported menu scale.
4. Add tests around settings persistence and scene/modal centering where practical.
5. Update GDD_07 and GDD_10 in the same implementation commit.

Recommendation: name the player-facing control `Menu Scale`. Do not add a second
HUD-scale slider unless playtesting shows the HUD Layout editor is too much work
for simple HUD-size changes.

## Workstream D — Character Sheet and More Info Clarity

### V020-07 — `Int` Label Is Unclear

Tester question: "what is the `Int` in the compact stat view?"

Likely file: `scripts/ui/UnitDetailsScreen.gd`

Plan: rename the compact row to `Internal Lv` or `Internal Level`. The value is
useful for reclass/EXP scaling, but the abbreviation is not self-explanatory.

Recommendation: use `Internal Lv` to keep the line short and add a More Info entry
for it later if hidden progression becomes a teaching surface.

### V020-08 — Pair Up Duration Marker Is Unclear

Tester report: Pair Up bonus listed as `Pair Up +3 (-)` should be clearer, e.g.
`Pair Up +3`, `Pair Up +3 (Until Separation)`, or source/duration detail.

Likely files:

- `scripts/shared/StatBreakdown.gd`
- `scripts/shared/StatContributions.gd`
- `scripts/ui/UnitDetailsScreen.gd`
- `scripts/tests/test_unit_details_screen.gd`

Confirmed code shape:

- `StatContributions._row()` marks Pair Up as `duration_type = "combat"` and
  `remaining = -1`.
- `StatBreakdown.format_duration()` returns `—` for any negative remaining value
  before it can render `"this combat"`.

Plan:

1. Render `duration_type == "combat"` before the negative-duration fallback.
2. For Pair Up specifically, consider source label text such as
   `Pair Up (M950_Cavalier)` if support-unit lookup is cheap.
3. Update tests that assert the stat breakdown text.

Recommendation: first fix the generic combat-duration formatter to show
`this combat`. Add support-unit names only if the UI remains readable.

### V020-09 — On-Map HUD Should Name Support Partner

Tester request: add a `Support Name` section to the on-map character HUD.

Likely files:

- `scripts/ui/HUD.gd`
- `scripts/tests/test_hud.gd`

Plan:

1. When `_show_unit()` displays a paired lead, show the support unit name near the
   existing `Paired +N` bonus line.
2. For a support inspected through the `I` sheet, keep `View Lead` as the primary
   navigation path; the support is hidden off-map and should not appear as a HUD
   hover target.

Recommendation: add a single concise line, e.g. `Support: M950_Cavalier`, not a
larger panel section.

### V020-15 — Add CON and LoS to the Character Sheet

Tester found that the A.3 handbook expected CON/LoS, but the live character sheet
does not show them. User decision 2026-06-19: add the stats to the character sheet.

Likely files:

- `scripts/ui/UnitDetailsScreen.gd`
- `scripts/shared/StatBreakdown.gd`
- `scripts/shared/MoreInfoContent.gd`
- `scripts/resources/ClassData.gd`
- `scripts/tests/test_unit_details_screen.gd`
- `AGENT/GDD/GDD_07_UI_UX.md`

Plan:

1. Add Constitution and Line of Sight rows to the character sheet stat block.
2. Give both rows selectable More Info descriptions.
3. Keep cap display as `—` because CON and LoS are intentionally uncapped by the
   class-cap table.
4. Verify the added rows do not crowd the compact sheet at small menu scales.
5. Update GDD_07 and the next playtest handbook wording.

Recommendation: place CON/LoS after Movement or in a final utility-stat row so the
core combat stats keep their existing scan order.

### V020-10 — Weapon Stats and Directional More Info Navigation

Tester requests:

- Weapons should show their stats on the More Info page.
- More Info should have a selector navigable by directional pads.

Relevant existing backlog:

- `GDD_10_Roadmap.md` Phase 3 Backlog already has `"More info" inspection mode`.
- `GDD_10_Roadmap.md` also has richer combat prediction and key/gamepad work.

Plan:

1. Extend Unit Details inventory entries so a selected weapon shows Mt/Hit/Crit/Wt,
   range, rank, uses, effectiveness tags, and weapon family.
2. Reuse `WeaponData` rather than duplicating display text by hand.
3. Add the full selector before the next playtest: arrow keys / d-pad move a visible
   highlight between selectable More Info entries, with confirm opening that entry.
4. Keep `F` cycling as a shortcut on top of directional selection.
5. Add tests for weapon info rendering and keyboard/directional selection.

Recommendation: implement the selector on the character sheet first, then reuse the
same focus model for combat forecast and terrain More Info if time allows before the
next build. If scope gets tight, weapon stats + character-sheet selector are the
minimum acceptance bar.

### V020-11 — Class Summary on Character Sheet

Tester request: character sheet should include class, class archetype summary, and
skills or special features.

Likely files:

- `scripts/ui/UnitDetailsScreen.gd`
- `scripts/resources/ClassData.gd`
- `data/classes/*.tres`
- `scripts/tests/test_unit_details_screen.gd`

Plan:

1. Replace the title's raw `class_id` with `ClassData.display_name`.
2. Add a compact class section using `ClassData.description`, `special_qualities`,
   allowed weapon families, and class skill unlocks.
3. Keep full class-catalog prose out of the sheet; one or two lines should be enough
   for in-map inspection.

Recommendation: do this after `V020-07` and `V020-08`, because they touch the same
screen and tests.

### V020-12 — HUD Layout Editor Affordances

Tester requests:

- Rename toolbar buttons to say `Scale Panel`.
- Make each panel outline bright red and selected outline yellow.
- Give each panel dummy sample text so font size is visible.

Likely files:

- `scripts/ui/HudLayoutEditor.gd`
- `scripts/tests/test_hud_layout_editor.gd`

Plan:

1. Rename buttons to `Scale Panel -` / `Scale Panel +` or a similarly compact label.
2. Use distinct styleboxes for unselected/selected handles rather than `self_modulate`.
3. For panels that are hidden or empty while editing, draw sample labels inside the
   editor frame only; do not mutate the live HUD content.

Recommendation: use sample text in editor overlay frames, not in the HUD nodes, so
the editor cannot leak fake text into gameplay.

### V020-13 — Borderless vs Fullscreen Explanation

Tester question: "what is the difference between borderless and fullscreen?"

Likely files:

- next playtest handbook

Plan:

1. Add tester-facing wording in the next playtest handbook:
   Borderless = desktop-sized window without borders; Fullscreen = exclusive
   fullscreen mode.
2. Do not add permanent Settings UI helper text for this pass.

Recommendation: handbook-only for now.

### V020-14 — Debuff Tonic / Live Red-Stat Fixture

Tester request: author a stat-debuffing tonic for the next playtest so red effective
values can be checked live.

Likely files:

- `data/items/*.tres`
- Map 950 fixed roster/inventory data
- `scripts/tests/test_skill_item_handler.gd`
- next playtest handbook

Plan:

1. Author it as a Map 950 validation-only test item, not a general balance item.
2. Give it clear test wording so players understand it exists to validate red
   negative-stat display.
3. Place it in the fixed Map 950 roster/inventory path used by the playtest.
4. Add tests for item data validity and the red effective-stat display if the current
   test coverage does not already hit that path.

Recommendation: keep the item out of the regular roster/shop pipeline until real
debuff consumables are designed.

## Decisions Resolved 2026-06-19

### UI Scale Semantics

Tester report: UI scale changes HUD/menu locations; suggestion was to split menu
scaling from HUD scaling and let HUD layout own HUD scaling.

Tradeoff:

- Keeping `Window.content_scale_factor` preserves one global accessibility knob and
  matches the implemented GDD_07 contract, but it can visibly move anchored HUD/menu
  elements as the whole GUI coordinate space changes.
- Splitting menu scale from HUD scale gives players steadier in-map HUD placement,
  but it adds settings complexity and requires a GDD_07 behavior change.

Decision:

- `Menu Scale` affects modal/menu UI.
- HUD size/position are controlled by HUD Layout editor.
- Optional later setting: `HUD follows menu scale` if accessibility testing needs it.
- Menus must stay centered at each supported scale.

Completion order: after the immediate bug fixes (`V020-01` through `V020-06`) and
before the character-sheet / More Info expansion.

### CON / LoS on Character Sheet

The v0.2.0 handbook expected CON/LoS to be visible when testing uncapped stat caps,
but the live sheet only shows Movement from the non-core stat set.

Decision: add CON and LoS to the character sheet before the next playtest.

### Full More Info Selector

Decision: add the full directional selector to the before-next-playtest work list,
not merely the long-term More Info backlog.

### Debuff Validation Item

Decision: make the stat-debuff tonic a Map 950 test item, not a normal content item.

### Borderless vs Fullscreen Explanation

Decision: document the difference in the next tester handbook only.

## Verification Plan

Run after approved implementation:

1. `python3 AGENT/Docs/check_docs.py`
2. Focused tests:
   - `scripts/tests/test_camera_controller.gd`
   - `scripts/tests/test_attack_preview_position.gd`
   - `scripts/tests/test_turn_manager.gd`
   - `scripts/tests/test_data_layer.gd`
   - `scripts/tests/test_hud_layout.gd`
   - `scripts/tests/test_hud_layout_editor.gd`
   - `scripts/tests/test_settings_manager.gd`
   - `scripts/tests/test_settings_screen.gd`
   - `scripts/tests/test_unit_details_screen.gd`
   - `scripts/tests/test_more_info_content.gd`
   - `scripts/tests/test_skill_item_handler.gd`
   - `scripts/tests/test_hud.gd`
3. Full suite: `TEST_JOBS=8 ./run_tests.sh`
4. Manual Windows retest of v0.2.0 failed/unclear items:
   D.1, D.3, D.6, Menu Scale at every supported level, G.5, H.3, 3.2, E.6,
   7.2, 8.4, CON/LoS character-sheet rows, weapon More Info selector, and the
   Map 950 debuff validation item.

DoD reminders:

- Any behavior change needs matching GDD_01-08 and GDD_10 updates in the same
  implementation commit.
- Any new mechanical doc rule needs an automated `check_docs.py` check in the same
  commit.
