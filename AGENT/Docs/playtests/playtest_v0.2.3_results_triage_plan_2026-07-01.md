---
Type: playtest
Status: Planned - routed to control plane
Last verified: 2026-07-01
---

# v0.2.3 Playtest Results Triage And Fix Plan - 2026-07-01

Status: Planned - routed to control plane
Last verified: 2026-07-01

## Scope

Planning-only triage for the returned v0.2.3 playtest. Owner review decisions are recorded
below; approved immediate and deferred rows are routed into the Project Control Plane.

Evidence:

- Returned checklist:
  `AGENT/Docs/playtests/playtest_checklist_v0.2.3_returned_2026-07-01.md`
- Source folder supplied by tester:
  `AGENT/v0.2.3 playtest results/playtest_checklist_v0.2.3.md`
- Screenshot evidence copied to:
  `AGENT/Docs/archive/evidence/zoom2x_attack_preview_more_info_cutoff_2026-07-01.png`
- Build manifest:
  `AGENT/Docs/playtests/playtest_build_v0.2.3.md` (source commit `76060ca`,
  SHA-256 `b92301f62a29523dc3b5adb3eb64e40e3afe9d8bfd5a70733d49791adadae107`)

## Findings First

1. **Display validation did not pass.** Part I has failed/unclear checks for Settings
   live Menu Scale, character-sheet scaling/centering/scrolling, contextual-menu anchoring,
   level-up modal input blocking, AttackPreview More Info fit, and oversized windowed
   resolution behavior. Keep `VAL-V023-DISPLAY` in Pending validation.
2. **Character sheet is the largest common failure.** It is tested as a content/selector
   screen, but `test_menu_scale.gd` does not include it in the centered-scale cases, and
   `UnitDetailsScreen.tscn` has no `ScrollContainer` despite the handbook saying it scrolls.
3. **Weapon names conflict with the source commit.** The returned build reports weapon names
   missing, but `76060ca` contains `AtkWeapon`/`DefWeapon` nodes and `_weapon_name()` wiring,
   and `test_attack_preview_selector.gd` asserts that row. Owner confirmed the tester ran
   the expected SHA-256, so investigate this as real v0.2.3 build behavior rather than a
   stale executable.
4. **Level-up dismissal has a concrete likely cause.** `LevelUpScreen._unhandled_input()`
   dismisses on any pressed `InputEventMouseButton`; Godot mouse-wheel events are mouse
   buttons, so wheel zoom can dismiss the popup even while map input is suppressed.
5. **Terrain action expansion should not grow the closed `TileActions` switch.** Tester asks
   for all non-hidden tile actions plus requirements. That vocabulary will grow with map
   objects and `[SAC]`; plan it as a descriptor/registry surface, not more hardcoded action
   IDs in `TileActions.is_available()`.

## Triage Summary

| ID | Result | Proposed pipeline home | Summary |
|---|---|---|---|
| `V023-01` | Confirmed UI issue | `VAL-V023-DISPLAY` | Settings Menu Scale live preview moves the slider row; add 0.5x scale option. |
| `V023-02` | Confirmed UI issue | `VAL-V023-DISPLAY`, later `UI-INSPECTION` | Character sheet does not scale/center/scroll consistently; consider page design separately. |
| `V023-03` | Confirmed UI issue | `VAL-V023-DISPLAY` | Action/item/weapon menus need stronger tile anchoring and must re-anchor after map zoom. |
| `V023-04` | Confirmed UI issue + source/build conflict | `VAL-V023-DISPLAY` | AttackPreview More Info clips; neutral triangle/effective rows are invisible; weapon row is missing despite matching build hash. |
| `V023-05` | Confirmed bug | `VAL-V023-DISPLAY` | Level-up popup can be dismissed by zoom/wheel input; unrepro stretched panel needs monitor coverage. |
| `V023-06` | Confirmed display issue | `VAL-V023-DISPLAY` | Windowed 1440p/4K can hide the OS title bar; document borderless vs exclusive fullscreen. |
| `V023-07` | Deferred polish follow-up | `VAL-V021-04` | HUD editor frame should include the expanded terrain More Info footprint. |
| `V023-08` | Split content/UI polish | now `VAL-V023-DISPLAY`; later `UI-INSPECTION` | Fix archer copy now; defer full unit-trait coverage and active trait aggregation. |
| `V023-09` | Split design follow-up | now `VAL-V023-DISPLAY`; later `B4-MAP-OBJECTS`/`SAC` | Fix terrain click cycling now; defer full action/requirement descriptors. |
| `V023-10` | Deferred input polish | `B6-INPUT` | Map Menu should close on right-click/backdrop or block outside input consistently. |
| `V023-11` | Validation gap | `VAL-PLAYTEST-RERUN` | Regression pass and `godot.log` were not returned; request on rerun before promoting log/regression issues. |

## Recommended Order

1. **Close the v0.2.3 display gate.** Fix `V023-01` through `V023-06` as one focused
   v0.2.4-style repair round, with `VAL-V023-DISPLAY` as the owning validation row.
2. **Treat the weapon-row conflict as real build behavior.** The owner confirmed the
   tester's hash matches the manifest, so `V023-04` should inspect row visibility, layout
   height, and source path assumptions inside the actual exported build.
3. **Bundle only the tiny no-design fixes with the display pass.** Also fix `V023-08a`
   archer copy and `V023-09a` terrain More Info click cycling if they stay small during
   implementation.
4. **Move the rest to their home bands.** `V023-07`, `V023-08b`, `V023-09b`, `V023-10`,
   and the page-based half of `V023-02` should not block the display closeout.

## Implementation Split (2026-07-01)

Next session should start with this immediate set:

| ID | Owner row | Scope |
|---|---|---|
| `V023-01` | `VAL-V023-DISPLAY` | Keep Settings live preview, add `0.5x`, and fix Menu Scale slider drift. |
| `V023-02a` | `VAL-V023-DISPLAY` | Fix character-sheet centering, scaling, and scrolling. |
| `V023-03` | `VAL-V023-DISPLAY` | Re-anchor contextual menus after map zoom and keep them tied to the tile. |
| `V023-04` | `VAL-V023-DISPLAY` | Fit AttackPreview More Info, show gray-square `Neutral`, and restore weapon rows in the exported build. |
| `V023-05` | `VAL-V023-DISPLAY` | Stop wheel/zoom input from dismissing Level-Up; re-check stretched popup on large monitors. |
| `V023-06` | `VAL-V023-DISPLAY` | Clamp oversized windowed resolutions; keep exact native size for Borderless/Fullscreen. |
| `V023-08a` | `VAL-V023-DISPLAY` | Fix `data/classes/archer.tres` copy so bow range comes from the equipped weapon. |
| `V023-09a` | `VAL-V023-DISPLAY` | Make clicks anywhere inside the expanded terrain More Info page cycle pages reliably. |

Deferred homes:

| ID | New home | Deferred note |
|---|---|---|
| `V023-02b` | `UI-INSPECTION`, with `B6-INPUT` overlap | Revisit character-sheet pages and page controls only after the full controller scheme shows how many buttons are available. |
| `V023-07` | `VAL-V021-04` | Fold the expanded terrain More Info footprint into the existing terrain corner-snap/editor-scale validation row. |
| `V023-08b` | `UI-INSPECTION` | Full unit-trait display, active movement-rule source, and equipment/skill trait aggregation belong with the broader inspection-surface pass. |
| `V023-09b` | `B4-MAP-OBJECTS` / `[SAC]` | Full "all visible tile actions plus requirements" needs a data-shaped descriptor/registry path, not a growing `TileActions` `match`. |
| `V023-10` | `B6-INPUT` | Right-click/backdrop close and touch-modal semantics should land with the shared input resolver/controller pass unless a quick input-polish pass pulls it forward. |
| `V023-11` | `VAL-PLAYTEST-RERUN` | Request logs and a regression pass on the rerun before promoting new log/regression work. |

## Workstream A - Settings Menu Scale (`V023-01`)

Tester report:

- Large-scale crispness mostly works.
- The Menu Scale slider itself moves while the scale is being changed.
- Request: add a 0.5x option for large-resolution users.

Research:

- `SettingsScreen._on_menu_scale_changed()` applies live to the whole
  `menu_scale_targets` group, including Settings itself.
- `MenuScale.apply_to()` scales fonts/metrics and recenters the panel. The Settings panel
  frame stays fixed because it has a `ScrollContainer`, but row metrics and label columns
  still resize, so the slider's screen position can move during the drag.
- `SettingsScreen.tscn` uses repeated `HBoxContainer` rows with 200px label minimums; there
  is no stable settings-grid column model.

Plan:

1. Keep live preview. Do not add an Apply button unless the fixed-row solution fails.
2. Convert Settings rows to a stable label/control/value column layout, or add a helper that
   locks the slider/control column x-position independent of label text scaling.
3. Add `0.5` to `SettingsManager.MENU_SCALE_LEVELS`, keeping default index at 1.0x and
   preserving old saved indices via a migration/clamp.
4. Extend `test_menu_scale.gd` or `test_settings_screen.gd` to assert the Menu Scale slider
   global x-position does not drift across factor changes.

Likely files:

- `scenes/ui/SettingsScreen.tscn`
- `scripts/ui/SettingsScreen.gd`
- `scripts/autoloads/SettingsManager.gd`
- `scripts/tests/test_menu_scale.gd`
- `scripts/tests/test_settings_screen.gd`

## Workstream B - Character Sheet Scale, Centering, Scroll, Pages (`V023-02`)

Tester report:

- Character sheet does not seem affected by Menu Scale like other menus.
- It can appear off-center, with the effect worsened by selecting different units.
- It has no scroll bar when content grows.
- Long sheets at 2.0x are usable but awkward; tester suggests page-based layout.
- Extra note: it "occasionally acted up" but a larger UI pass is coming.

Research:

- `UnitDetailsScreen` extends `ModalScreen`, so it should receive Menu Scale, but
  `test_menu_scale.gd` does not include `UnitDetailsScreen.tscn` in its centered panel cases.
- `UnitDetailsScreen.tscn` has no `ScrollContainer`. Its `RichTextLabel` sections use
  `fit_content = true`, so the panel grows/shrinks rather than scrolling.
- `MenuScale._has_scroll_container()` decides fixed-frame behavior by scanning for a
  `ScrollContainer`; the sheet therefore goes down the grow-to-content/clamp path.
- Unit swaps call `open(_paired_unit)` again but do not add a post-populate frame wait before
  scale/recenter, so dynamic label sizes can settle after placement.

Short-term plan (`V023-02a`, next session):

1. Add `UnitDetailsScreen` to `test_menu_scale.gd` centered-scale coverage.
2. Convert the sheet to a fixed centered frame with scrollable content, likely one
   `ScrollContainer` for the main column and one bounded side-panel area for More Info.
3. Re-apply Menu Scale and recenter after `open()` populates dynamic content and after paired
   unit swaps.
4. Add tests for 0.75x, 1.0x, 2.0x: panel centered, `Control.scale == Vector2.ONE`, scroll
   containers visible when content exceeds frame, and top/bottom reachable.

Longer UI pass (`V023-02b`, deferred to `UI-INSPECTION`):

- Page-based sheet should be a separate `UI-INSPECTION` design. The existing
  `next_unit`/`prev_unit` actions already jump between lead/support sheets; reusing them for
  pages would create an input conflict unless B6 input context resolves it first. Review this
  only after the full controller scheme is available.

Likely files:

- `scenes/ui/UnitDetailsScreen.tscn`
- `scripts/ui/UnitDetailsScreen.gd`
- `scripts/tests/test_menu_scale.gd`
- `scripts/tests/test_unit_details_screen.gd`

## Workstream C - Contextual Menu Anchoring (`V023-03`)

Tester report:

- Action/item menus are near the cursor but not tied tightly enough to it.
- They do not recalculate when map zoom changes.

Research:

- `MapCursor._place_menu_near(menu, tile)` places `ActionMenu`, `ItemMenu`, and
  `WeaponMenu` after `show_for()`.
- The menu does not store its anchor tile, and zoom handlers only reframe the camera:
  `apply_zoom_index()`, `_apply_zoom_step()`, and `_apply_zoom_reset()` do not re-place an
  open menu.

Plan:

1. Add a small anchored-popup helper or local MapCursor state:
   `{menu, tile, anchor_kind}` for the currently open contextual menu.
2. Re-run `_place_menu_near()` after every zoom change and after camera pan while a
   contextual menu is visible.
3. Tighten placement to use the selected unit/cursor tile screen rect, with safe-area and
   viewport clamps.
4. Add tests for initial placement and re-placement after a simulated zoom transform.

Likely files:

- `scripts/core/MapCursor.gd`
- `scripts/tests/test_map_cursor.gd` or a new focused menu-anchor suite

## Workstream D - AttackPreview More Info, Neutral Markers, Weapon Row (`V023-04`)

Tester report:

- Screenshot shows combat-preview More Info text clipped/cut off at 2x zoom.
- Neutral weapon-triangle/effectiveness state should show a gray marker instead of an empty
  row.
- Weapon name is missing.

Research:

- `AttackPreview.gd` has `_atk_weapon`/`_def_weapon` onready vars and sets them in
  `show_preview()`.
- `AttackPreview.tscn` has `AtkWeapon` and `DefWeapon` rows.
- `test_attack_preview_selector.gd` asserts "Iron Sword" and "Unarmed".
- `git show 76060ca` confirms the build source commit contains this wiring, and the owner
  confirmed the tester's SHA-256 matches the v0.2.3 manifest. Treat missing names as an
  exported-build row-size/render issue until verified.
- The InfoBox description is a fixed-height `RichTextLabel` (`custom_minimum_size.y = 88`,
  `fit_content = false`) without a `ScrollContainer`, so longer More Info copy clips.
- `_triangle_link()` and `_effective_link()` register neutral entries but render `""`, so
  More Info cycling can land on invisible rows.

Plan (`V023-04`, next session):

1. Investigate why the matching v0.2.3 artifact hides the weapon rows despite source/test
   coverage at `76060ca`: row height, panel sizing, export scene cache, and text colour/clip
   are the first suspects.
2. Wrap `InfoDescription` in a `ScrollContainer` or make the InfoBox a bounded scroll area
   so More Info text is readable at large Menu Scale / map zoom.
3. Keep forecast columns wide enough after weapon rows and neutral markers are visible.
4. Render neutral triangle/effectiveness rows as visible low-emphasis rows, not blank cycle
   entries. Owner decision: neutral weapon-triangle row should show a gray square plus
   `Neutral`; effectiveness should follow the same visible-neutral pattern unless a better
   copy emerges in implementation.
5. Add tests for visible weapon rows, neutral marker text/height, and More Info description
   non-zero visible area. Keep screenshot/live check for final fit.

Likely files:

- `scenes/ui/AttackPreview.tscn`
- `scripts/ui/AttackPreview.gd`
- `scripts/tests/test_attack_preview_selector.gd`
- `scripts/tests/test_attack_preview_position.gd`

## Workstream E - Level-Up Modal Input Blocking (`V023-05`)

Tester report:

- Level-up screen looked stretched/narrow once, unreproduced.
- Zooming in/out dismissed the level-up screen.
- Popups like this should block all input until dismissed.

Research:

- `LevelUpScreen.gd` says it blocks all input, and `MapCursor` suppresses map input on
  `level_up_started`.
- `_unhandled_input()` dismisses on any pressed `InputEventMouseButton`; wheel up/down are
  mouse buttons in Godot, so scroll-wheel zoom can dismiss the panel.

Plan (`V023-05`, next session):

1. Dismiss only on `confirm`, `cancel`, left-click, or maybe right-click if approved.
2. While visible, consume all other input events so nothing below sees zoom/open-menu/cursor
   commands.
3. Add regression tests: wheel event does not dismiss; zoom action does not dismiss; left
   click and confirm still dismiss.
4. Add a live note to watch for the stretched/narrow panel; do not chase it until it has a
   reproduction or a failing layout test.

Likely files:

- `scripts/ui/LevelUpScreen.gd`
- `scripts/tests/test_level_up_screen.gd`

## Workstream F - Windowed Native Resolutions (`V023-06`)

Tester report:

- Windowed mode at monitor resolution or larger hides the title bar and resembles
  fullscreen/borderless.
- Auto-revert works.
- Tester asks to confirm borderless and fullscreen differ in code.

Research:

- `SettingsManager._apply_display()` uses `WINDOW_MODE_WINDOWED`, then
  `DisplayServer.window_set_size(size)`, then centers via `window_centre_position()`.
- `window_centre_position()` clamps top-left to the screen origin for oversized windows, but
  the requested client area can still equal the monitor size; OS title bar/borders can push
  the decorated window beyond the usable screen area.
- Borderless and fullscreen do differ in code:
  `WINDOW_MODE_FULLSCREEN` for borderless/windowed fullscreen and
  `WINDOW_MODE_EXCLUSIVE_FULLSCREEN` for exclusive fullscreen.

Plan:

1. Add a display-size guard for windowed mode: if requested client size cannot fit with a
   reachable title bar, clamp to the largest 16:9 size inside the usable display rect.
2. Keep confirm/revert.
3. Surface the applied size in Settings or at least in code comments/tests so a selected 4K
   option on a 4K monitor is not silently mistaken for exact client-size application.
4. Add a handbook note: Borderless uses Godot fullscreen window mode; Fullscreen uses
   exclusive fullscreen.

Likely files:

- `scripts/autoloads/SettingsManager.gd`
- `scripts/ui/SettingsScreen.gd`
- `scripts/tests/test_settings_manager.gd`
- `AGENT/Docs/playtests/playtest_checklist_v0.2.3.md` for the next rerun/checklist

## Workstream G - HUD Editor Terrain Frame (`V023-07`)

Tester report:

- HUD editor works, but the terrain More Info panel size should be included in the editable
  frame's base size.

Research:

- `HudLayoutEditor._refresh_handles()` draws handles from `panel.get_global_rect()`.
- The editable `terrain_corner` node is a container that can visually include the expanded
  More Info box, but the base edit intent is the compact terrain panel. This mismatch is
  visible when More Info is open.

Deferred plan (`V023-07`, home: `VAL-V021-04`):

1. When terrain More Info is visible, compute the editor handle from the union of compact
   terrain panel and expanded More Info panel.
2. Keep saved layout offsets anchored to the compact panel, per the existing design; only the
   editor frame should expand to show the true footprint.
3. Add a `test_hud_layout_editor.gd` assertion for handle rect union when expanded.

Likely files:

- `scripts/ui/HudLayoutEditor.gd`
- `scripts/ui/HUD.gd`
- `scripts/tests/test_hud_layout_editor.gd`

## Workstream H - Class More Info Content (`V023-08`)

Tester report:

- Add the full list of traits the unit has.
- Specify the active movement rule.
- Update archer description to remove the "cannot attack range 1" wording.

Research:

- `_class_description()` displays `ClassData.special_qualities` non-movement traits and
  resolved movement type from class data only.
- Unit-level traits from skills/items are not shown in that class side panel.
- `data/classes/archer.tres` still says: "Cannot attack adjacent (range 1) targets."

Immediate plan (`V023-08a`, next session):

1. Change archer description to weapon-neutral wording, e.g. "A ranged physical attacker;
   bow range is determined by the equipped weapon."
2. Add or extend `test_unit_details_screen.gd` only if the copy is exercised by existing
   class-description UI tests.

Deferred plan (`V023-08b`, home: `UI-INSPECTION`):

1. In Class More Info, split:
   - `Movement rule:` resolved movement type plus precedence source.
   - `Class traits:` class `special_qualities` excluding movement tags.
   - `Unit traits:` class + unit/equipment traits when available.
2. Resolve unit/equipment trait aggregation in the broader inspection pass rather than
   adding a one-off UI path here.
3. Add or extend `test_unit_details_screen.gd`.

Likely files:

- `data/classes/archer.tres`
- `scripts/ui/UnitDetailsScreen.gd`
- `scripts/tests/test_unit_details_screen.gd`

## Workstream I - Terrain More Info Actions And Click Paging (`V023-09`)

Tester report:

- Terrain paging works by key, but click cycling fails on the movement-cost page.
- Actions list should show all non-hidden actions units could take on that square, with
  requirements, not just actions for the selected unit.
- Consider making base info the default page and tile name a header.

Research:

- `MapCursor._try_cycle_terrain_panel_at()` cycles only when
  `HUD.terrain_corner_contains_screen_position(screen_pos)` is true.
- `terrain_corner_contains_screen_position()` checks the `TerrainCorner` global rect; click
  behavior can miss if the expanded page's scroll/control rect is not inside or not passing
  the click through.
- `_format_tile_actions()` calls `TileActions.available_for(_selected_unit, tile, turn)`,
  so it intentionally hides actions when no selected unit qualifies.
- `TileActions.gd` is a closed `_ACTION_ORDER` plus `match`. That is tolerable for today's
  two hardwired actions, but the requested "all actions + requirements" surface grows with
  `[SAC]` map-object/action content and should become descriptor-driven.

Immediate plan (`V023-09a`, next session):

1. Fix click cycling so any click inside compact terrain or expanded More Info page cycles
   Hidden -> Description -> Movement -> Hidden, including the movement page.
2. Keep base compact info always visible; define whether "default page" means first expanded
   page restates compact data or simply starts on Description.

Deferred plan (`V023-09b`, home: `B4-MAP-OBJECTS` / `[SAC]`):

1. Add tile name/header to the expanded panel when the action-descriptor surface is designed.
2. Add a short-term descriptor method for authored objective actions:
   `TileActions.describe_for_tile(tile, turn, unit = null)` returning visible actions with
   requirement text and availability. Keep it data-shaped so B4-MAP-OBJECTS/SAC can replace
   the hardcoded source later.
3. Do not add more content-specific `match` branches for future shops/visits/activate
   beyond the existing placeholders.

Likely files:

- `scripts/ui/HUD.gd`
- `scripts/core/MapCursor.gd`
- `scripts/shared/TileActions.gd`
- `scripts/tests/test_hud.gd`
- `scripts/tests/test_tile_actions.gd`

## Workstream J - Map Menu Input Semantics (`V023-10`)

Tester report:

- Backdrop left-click works.
- Consider right-click anywhere to cancel the menu, or block all input outside the menu for
  touch controls.

Research:

- `MapMenu._on_backdrop_input()` closes only on left-click outside the panel.
- `_unhandled_input()` already closes on `cancel` or `open_menu`.
- The menu's full-rect root handles backdrop clicks; panel children consume their own input.

Deferred plan (`V023-10`, home: `B6-INPUT`):

1. Add right-click/cancel on backdrop as a small input polish fix.
2. For touch, keep inside-panel controls active and outside-panel taps dismiss. Do not block
   every outside input forever; that is frustrating on modal menus and inconsistent with the
   accepted left-click behavior.
3. Add `test_map_menu.gd` coverage for right-click backdrop dismissal when implemented.

Likely files:

- `scripts/ui/MapMenu.gd`
- `scripts/tests/test_map_menu.gd`

## Validation Gap (`V023-11`)

The returned checklist leaves the full regression pass and error-log check unchecked with no
comment. Treat this as `NOT RUN`.

Plan:

1. Ask for `godot.log` or a focused rerun after fixes.
2. Add a short returned-results checklist for the next pass that records the confirmed
   artifact hash, the AttackPreview weapon-row check, and the level-up wheel-input check.
3. Keep `VAL-PLAYTEST-RERUN` active until logs and regression scope are returned.

## Owner Review Decisions (2026-07-01)

1. **Character sheet short-term scope:** fix centering/scrolling now; defer page-based
   character-sheet design to `UI-INSPECTION`.
2. **0.5x Menu Scale:** try adding `0.5x` as a normal selectable level; keep `1.0x` as the
   default.
3. **Settings live preview:** keep live preview and fix the Settings slider drift.
4. **Windowed native resolution policy:** clamp oversized windowed resolutions so the OS
   title bar remains reachable.
5. **Neutral combat marker copy:** show a gray square plus `Neutral` for no weapon-triangle
   advantage. Use the same visible-neutral pattern for effectiveness unless implementation
   finds better wording.
6. **Terrain action requirement depth:** show action names plus one-line requirements now;
   defer full requirement breakdowns until `[REQ]`/`[SAC]` descriptors exist.
7. **Map Menu right-click:** right-click outside the Map Menu should close it.
8. **Character sheet page controls later:** defer the `next_unit`/`prev_unit` page-control
   decision until page design happens alongside the full controller scheme.
9. **Weapon names missing:** owner confirmed the playtest build hash was
   `B92301F62A29523DC3B5ADB3EB64E40E3AFE9D8BFD5A70733D49791ADADAE107`, matching the
   v0.2.3 manifest. Treat the missing weapon row as a real v0.2.3 artifact issue.
10. **Implementation split:** do `V023-01..06`, `V023-08a`, and `V023-09a` next session;
    route `V023-02b`, `V023-07`, `V023-08b`, `V023-09b`, `V023-10`, and `V023-11` to their
    deferred home rows listed above.

## Original Owner Questions

1. **Character sheet short-term scope:** fix centering/scrolling now and defer page layout,
   or design pages before the next build? Recommendation: fix centering/scrolling now; page
   layout belongs in `UI-INSPECTION`.
2. **0.5x Menu Scale:** add it as a normal selectable level? Recommendation: yes, keep
   default 1.0x and document that 0.5x is for large displays, not touch comfort.
3. **Settings live preview:** keep live preview with a stable settings grid, or switch to an
   Apply button? Recommendation: keep live preview and stabilize the row layout.
4. **Windowed native resolution policy:** when selected resolution equals/exceeds the monitor,
   should the game clamp to the largest titled 16:9 window? Recommendation: yes; exact-native
   belongs to Borderless/Fullscreen, not Windowed.
5. **Neutral combat marker copy:** gray square only, or explicit text? Recommendation: visible
   low-emphasis text such as `Neutral` and `No effective bonus`; a square alone is easy to
   miss and not screen-reader/localization friendly.
6. **Terrain action requirement depth:** should terrain More Info list only action names plus
   one-line requirements, or full requirement breakdowns? Recommendation: one-line
   requirements now; full predicate breakdown later when `[REQ]`/`[SAC]` descriptors exist.
7. **Map Menu right-click:** should right-click outside close the menu? Recommendation: yes,
   matching `cancel`; keep left-click backdrop close.
8. **Next/previous buttons on character sheet pages:** if pages are approved later, should
   `next_unit`/`prev_unit` be repurposed? Recommendation: no; they already handle paired-unit
   sheet jumps. Use tabs or a page selector after B6 input.
9. **Weapon names missing:** can the tester confirm the SHA-256 they ran? Recommendation:
   require hash confirmation before source changes for `V023-04`. Resolved: hash confirmed
   matching the v0.2.3 manifest.

## Merge Notes

- Do not flip `VAL-V023-DISPLAY` until `V023-01` through `V023-06` pass live validation.
- Do not expand `TileActions` into a growing closed switch. The action-description request
  should align with `B4-MAP-OBJECTS`/`SAC` and the open-registry authoring rule.
- If any fix changes behavior, update the owning GDD section and Project Control Plane row in
  the same implementation commit. This triage doc is plan-only and does not change behavior.
