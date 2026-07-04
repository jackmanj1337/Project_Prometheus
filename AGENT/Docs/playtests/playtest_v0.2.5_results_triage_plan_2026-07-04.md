---
Type: playtest
Status: Planned - owner walkthrough DONE 2026-07-04 (decisions in `AGENT/Code Reviews/playtest_v0.2.5_triage_review_2026-07-04.md`); v0.2.6 fix pass next
Last verified: 2026-07-04
---

# v0.2.5 Playtest Results Triage And Fix Plan - 2026-07-04

Status: Planned - owner walkthrough DONE 2026-07-04; ready for the v0.2.6 fix pass
Last verified: 2026-07-04

## Scope

Planning-only triage for the returned v0.2.5 playtest (the focused display/input re-test
of the v0.2.3 repairs). Every tester comment was researched against the live source; the
diagnosis and fix plan per item are below. Owner decisions are collected in the companion
review doc `AGENT/Code Reviews/playtest_v0.2.5_triage_review_2026-07-04.md` and should be
walked before the fixes are implemented.

Evidence:

- Returned checklist:
  `AGENT/Docs/playtests/playtest_checklist_v0.2.5_returned_2026-07-04.md`
- Screenshot evidence copied to `AGENT/Docs/archive/evidence/`:
  - `levelup_first_show_narrow_panel_1080p_2026-07-03.png` (V025-05a)
  - `promotion_picker_baseline_1x_2026-07-03.png` (V025-05c baseline)
  - `promotion_picker_2x_top_bottom_cutoff_2026-07-03.png` (V025-05c)
  - `promotion_picker_0p5x_2026-07-03.png` (V025-05c small-scale contrast)
  - `windowed_4k_clamp_desktop_gap_2026-07-03.png` (V025-06)
  - `unit_details_horizontal_scrollbar_back_button_2026-07-01.png` (V025-02)
- Build manifest: `AGENT/Docs/playtests/playtest_build_v0.2.5.md`
  (source commit `8734136`, SHA-256 `d1d758c2…`)
- Tester environment: Windows 11, window at 1920x1080 on a 3840x2160-native monitor
  (relevant to V025-06 — OS display scaling is in play).

## Findings First

1. **The display gate still does not close, but it moved a long way.** §1.4 AttackPreview
   (the v0.2.3 headline), §1.7 archer copy, and all of Part II (§2.1-2.4) now PASS.
   Remaining failures: level-up/promotion modals (§1.5), terrain click paging (§1.8), and
   partial issues on Menu Scale (§1.1), character sheet (§1.2), and menu anchoring (§1.3).
   `VAL-V023-DISPLAY` stays Pending validation.
2. **Two v0.2.4 "fixes" passed headless tests but failed in the real build for the same
   reason: the tests bypass real input routing.** `test_level_up_screen.gd` calls
   `screen._unhandled_input(click)` directly and the terrain-paging tests call
   `_try_cycle_terrain_panel_at()` directly, so neither exercises the GUI-phase mouse
   delivery that consumes the events in the exported build (V025-05b, V025-08). Process
   fix: input-routing repairs need viewport `push_input` event-injection tests, plus a
   note that headless GUI picking differs from desktop (a headless probe this session
   showed clicks reaching `_unhandled_input` that the tester's desktop build eats).
3. **The stretched/narrow level-up panel is now REPRODUCED** (twice: first level-up per
   map load, repeats after map restart, 1.0x scale, 1920x1080 windowed). It was
   unreproduced in v0.2.3; it now has a screenshot and a deterministic trigger, so it is
   fixable (V025-05a).
4. **The promotion picker was never in the Menu Scale re-apply loop.**
   `PromotionScreen.open_for()` rebuilds its option buttons after `ModalScreen._ready()`
   ran the scale/viewport-clamp pass on an empty Options box, so at 2.0x the grown panel
   is never clamped or recentred and clips top+bottom (V025-05c).
5. **The tester's §1.4 follow-ups land squarely on ratified design directions.** The
   "author-configurable forecast rows" ask is the open-registry/authoring-extensibility
   principle applied to AttackPreview, and Band 5's source/style plan already contains
   the generalized-forecast slice this should ride with (not a bespoke UI patch now).

## Triage Summary

Result codes: PASS = tester checked the box; PARTIAL = works with new defects/asks;
FAIL = repaired behavior still broken.

| ID | Checklist | Result | Summary |
|---|---|---|---|
| `V025-01` | §1.1 (V023-01 re-test) | PARTIAL | Vertical drift fixed; NEW: slider value flickers when dragging across >1x steps; horizontal scrollbar appears at high scales. |
| `V025-02` | §1.2 (V023-02a re-test) | PARTIAL | Centering/scaling/scrolling fixed; NEW: horizontal scrollbar (wrap wanted), Back button full-width, stats More-Info layout redesign requested. |
| `V025-03` | §1.3 (V023-03 re-test) | PARTIAL | Re-anchoring works; residual menu jumping at close-in zoom levels. |
| `V025-04` | §1.4 (V023-04 re-test) | PASS + design asks | Weapon rows/Neutral/More-Info confirmed. Asks: author-extensible forecast rows; effectiveness as green damage (drop 2nd Neutral row); re-anchor preview on zoom. |
| `V025-05` | §1.5 (V023-05 re-test) | FAIL | (a) narrow/stretched panel REPRODUCED on first level-up per map; (b) left-click does not dismiss (keyboard does); (c) promotion picker clips top+bottom at 2.0x; (d) picker UX redesign suggested; (e) content asks (skill-cap hero, extra weapons). |
| `V025-06` | §1.6 (V023-06 re-test) | PARTIAL | Clamp works (title bar reachable) but desktop shows around the window; tester asks for a full resolution/window-mode/display-size explainer. |
| `V025-07` | §1.7 (V023-08a re-test) | PASS | Archer copy confirmed. |
| `V025-08` | §1.8 (V023-09a re-test) | FAIL | Click paging still fails exactly as v0.2.3; single-page redesign suggested again. |
| `V025-09` | §1.9 (migration guard) | NOT RUN | No prior settings.cfg on the test machine; tester asks for a settings.cfg explainer. |
| `V025-10` | Part III + error log | NOT RUN | Regression pass not run; `godot.log` STILL not returned (3rd request). |

## Workstream A - Menu Scale slider flicker + Settings horizontal overflow (`V025-01`)

Tester report: vertical drift fixed; but dragging between scales above 1.0x makes the
slider "flicker back and forth between sizes", and high scales trigger horizontal
scrollbars — wants tighter wrapping/spacing.

Diagnosis (from source):

- `SettingsScreen._on_menu_scale_changed()` applies the new factor live on every step.
  The re-scale changes the Settings rows' label widths, which changes the **slider
  track's x-position and width** mid-drag. The mouse hasn't moved, but the same pixel
  now maps to a different slider value, so the value flips back, which re-scales again —
  a feedback oscillation between two adjacent steps. The v0.2.5 row-y anchor fixed the
  vertical axis only; the horizontal geometry of the *track itself* still breathes.
- The horizontal scrollbar: `SettingsScreen.tscn`'s ScrollContainer does not disable
  horizontal scrolling, and rows are `HBoxContainer`s whose label + control + value
  minimum widths at 1.5-2.0x exceed the panel frame, so the container grows sideways.

Fix plan (owner decisions Q1/Q2 recorded 2026-07-04):

1. **Q1 = Option A:** apply the scale change on `drag_ended` only, showing the target
   value in the row label during the drag; keyboard/step changes stay live.
2. **Q2 = Option A + panel widen:** disable horizontal scroll
   (`horizontal_scroll_mode = SCROLL_MODE_DISABLED`) and make rows adapt (value labels
   autowrap/ellipsize, keybind rows two-line above a factor threshold), AND widen the
   Settings panel itself so the adapt branch has more room before it triggers.
3. Regression tests: slider value stable across a simulated multi-step drag at 1.25x to
   2.0x; Settings VBox min width fits the panel frame at 2.0x.

Likely files: `scenes/ui/SettingsScreen.tscn`, `scripts/ui/SettingsScreen.gd`,
`scripts/tests/test_settings_screen.gd`.

## Workstream B - Character sheet wrap, Back button, stats More-Info layout (`V025-02`)

Tester report: centered and scales well; wants (a) text wrapping instead of the sideways
scrollbar, (b) a narrower Back button, (c) a redesigned stats More-Info: numbers at the
top, prose at the bottom, box the full height of the page.

Diagnosis:

- `UnitDetailsScreen.tscn`'s `MainScroll` ScrollContainer leaves
  `horizontal_scroll_mode` at the default AUTO; long unwrapped lines (inventory entries,
  "Sword D 130 / 200 to C") exceed the 420px column at scale and summon the horizontal
  bar (see evidence screenshot).
- `BtnBack` is a direct VBox child with default horizontal size flags — it fills the
  full column width.
- The More-Info side panel currently mixes stat numbers and prose in one flow;
  the tester wants a fixed vertical split (numbers top / prose bottom) at full page
  height so short descriptions don't shrink the box.

Fix plan:

1. Set `horizontal_scroll_mode = SCROLL_MODE_DISABLED` on `MainScroll`; add
   autowrap/ellipsis on the row labels that can exceed the column.
2. Size `BtnBack` shrink-center with a reasonable minimum width.
3. Restructure the More-Info panel per the tester's layout (owner confirms exact split —
   review Q3): full-height frame, stat table top, prose bottom.
4. Extend `test_unit_details_screen.gd`: no horizontal scrollbar at 2.0x, Back button
   narrower than the column, More-Info panel height equals the frame height.

Likely files: `scenes/ui/UnitDetailsScreen.tscn`, `scripts/ui/UnitDetailsScreen.gd`,
`scripts/tests/test_unit_details_screen.gd`.

## Workstream C - Contextual menu residual jump at close zoom (`V025-03`)

Tester report: better, but at close-in zoom levels the menu still jumps around a bit.

Diagnosis:

- `MapCursor._place_menu_near()` offsets the menu one tile to the unit's right
  (`tile_px = TILE_SIZE * camera.zoom.x`) and flips to the left side when it would run
  off the right edge. At high zoom `tile_px` is large, so the preferred position
  overflows more often and small zoom/cursor changes flip the side — there is no
  hysteresis, and the flip inverts which screen edge the clamp fights.

Fix plan:

1. Add side stickiness: keep the previously chosen side across re-placements for the
   same anchor unless the menu can no longer fit there at all.
2. Optionally cap the effective `tile_px` offset so the menu hugs the unit at high zoom
   instead of leaping a full magnified tile away.
3. Test: repeated `_place_menu_near` calls across zoom steps produce monotone positions
   (no alternation) for a mid-map anchor.

Likely files: `scripts/core/MapCursor.gd`, `scripts/tests/test_map_cursor.gd`.

## Workstream D - AttackPreview follow-ups (`V025-04`, passed; design asks)

Tester asks:

1. **Author-extensible forecast rows** — e.g. a campaign with no weapon triangle that
   bases advantage on class tags (air/water/land). This is the open-registry principle
   (`[EXT]`) applied to the combat preview. Home: the Band 5 source/style plan's
   generalized-forecast slice already rebuilds the forecast from `EffectSpec`/registry
   terms; the row vocabulary should be part of that surface, not a bespoke edit now
   (review Q5 decides the seam's v1 scope).
2. **Effectiveness presentation** — drop the second `■ Neutral` row; instead color the
   per-hit damage green when effectiveness applies, with the full breakdown on the
   More-Info page (review Q6 for the exact convention; colorblind/readability note).
3. **Re-anchor on zoom like the action menu** — `AttackPreview._reposition_for()` runs
   only on `show_preview()`; `MapCursor._reposition_context_menu_anchor()` covers only
   the action/item/weapon menus. Fix: register the visible preview with the same
   zoom-reposition hook (small, low-risk; can ride the next fix pass).

Likely files: `scripts/ui/AttackPreview.gd`, `scripts/core/MapCursor.gd`,
`scripts/tests/test_attack_preview_position.gd`; forecast-row registry belongs to
`band5_source_style_implementation_plan_2026-07-03.md`.

## Workstream E - Level-up / promotion modals (`V025-05`) — highest priority

### E1. Narrow/stretched level-up panel — REPRODUCED (`V025-05a`)

Tester report: first level-up per map load renders the long-skinny panel (screenshot);
subsequent level-ups are normal; restarting the map reproduces it. 1.0x scale,
1920x1080 windowed.

Diagnosis (leading hypothesis):

- `LevelUpScreen._show_next()` sets the label text and immediately runs
  `_apply_menu_scale_from_settings()` → `MenuScale._recenter()`, which does
  `target.size = target.get_combined_minimum_size()` while the panel is still hidden
  and has never been laid out. `LabelStats` has `autowrap_mode = 3`; an autowrap
  label's minimum size is width-dependent, and on the first pass the label's width is
  the pre-layout scene default, which can yield a degenerate (narrow x, tall y)
  combined minimum. The frozen `PRESET_CENTER / KEEP_SIZE` anchors then pin that
  degenerate size. On the second level-up the labels have settled sizes from the
  previous show, so the minimum computes sanely — matching "first show only, per map
  instance".

Fix plan:

1. Defer the size/recenter one frame after `show()` (await a layout frame, or
   `call_deferred`) so autowrap minimums are computed against real layout — or drop
   autowrap on `LabelStats` entirely (stat lines are short; owner call, review Q8).
2. Regression test: instantiate the scene fresh, drive one `_show_next()`, assert the
   panel's aspect/width on the first show matches a second show within tolerance.

### E2. Left-click does not dismiss (`V025-05b`)

Tester report: left-click does not dismiss the level-up screen; keyboard does.

Diagnosis (leading hypothesis, needs one live confirmation):

- The scene root is a full-rect Control with `mouse_filter = 0` (STOP). On desktop the
  GUI phase delivers the click to that root and consumes it, so
  `_unhandled_input()` — where the v0.2.4 left/right-click dismissal lives — never sees
  mouse buttons. Keyboard events skip the GUI mouse phase and still arrive. Wheel is
  special-cased scroll delivery, which is how the *original* v0.2.3 wheel-dismiss bug
  could happen while clicks are eaten now.
- A headless probe (viewport `push_input`, same scene shape) shows all mouse events
  reaching `_unhandled_input` — headless GUI picking does not match desktop, which is
  why `test_level_up_screen.gd` (which calls `_unhandled_input` directly) passes.

Fix plan:

1. Move click handling to `_gui_input()` on the root (STOP guarantees delivery there):
   left/right click advances, everything else consumed. Keep `_unhandled_input` for
   confirm/cancel keys. The root keeps STOP so the map beneath stays blocked.
2. Regression test via real event injection (`push_input`), not direct method calls —
   plus a live check in the next build, since headless picking differs (finding #2).

### E3. Promotion picker clips at 2.0x (`V025-05c`)

Tester report: the auto-promote screen at max Menu Scale cuts off the top and bottom of
the menu badly; at 0.5x it fits (screenshots). Second Seal flow works at both ends but
is cramped; suggests more height/width or less label padding.

Diagnosis (confirmed from source):

- `PromotionScreen` extends `ModalScreen`, which applies MenuScale once in `_ready()` —
  when the `Options` VBox is empty. `open_for()` → `_rebuild_options()` adds the class
  buttons (which inherit the scaled theme and grow) and then calls `show()` **without
  re-applying the scale pass**, so `MenuScale._clamp_to_viewport()` and `_recenter()`
  never see the real content. At 2.0x the panel's content exceeds the screen and the
  center-anchored panel clips both ends. There is also no ScrollContainer fallback.
- Same latent pattern risk in `ReclassScreen` (shares the rebuild-then-show shape).

Fix plan:

1. Re-apply `apply_menu_scale(...)` after `_rebuild_options()` (and after any dynamic
   rebuild in `ReclassScreen`), so clamp + recenter run against real content.
2. Put `Options` in a ScrollContainer so the panel becomes a fixed frame that scrolls
   when the class list is long — this also future-proofs larger promotion pools.
3. Test: open with 3 classes at 2.0x, assert panel fits the viewport and is centered.

### E4. Promotion picker UX redesign (`V025-05d`, design)

Tester suggestion: class names in a scrollable list on the left; a More-Info-style panel
on the right with prose description, stat changes, weapons, skills — eventually cycling
class animations. This is a real design ask, not a bug: route to the UI-inspection pass
(`UI-INSPECTION`) unless the owner pulls it forward (review Q10). E3's minimal fix keeps
v0.2.6 unblocked either way.

### E5. Validation-map content asks (`V025-05e`)

- Checked this session: the skill cap is **5** (`GameState.max_skills` /
  `CampaignRules.max_skills`), and `M950_Hero_SkillCap` has only **4** skills
  (`armsthrift`, `patience`, `dash`, `discipline`) — it does NOT sit at the cap, so cap
  behavior (the "skill slots full" suffix path) is never exercised. Fix: give it a 5th
  skill in `data/roster/test/map_950_promotion_validation/unit_12_hero_skill_cap.tres`.
- Give several Map 950 units a second/third weapon so weapon selection is testable
  (today e.g. `M950_Lvl19_Merc` carries a single Iron Sword).
- **Owner add (Q14):** add **10 extra red (enemy) units** to the promotion validation
  map (Map 950) usable as EXP-grind fodder, so the tester can drive repeated level-ups
  on one unit and confirm stat caps are enforced at the ceiling.

## Workstream F - Windowed clamp explainer (`V025-06`)

Tester report: 4K windowed is visibly different from fullscreen/borderless (title bar
reachable — the repair works) but desktop shows around the window; wants a full
discussion of how resolution, window mode, display size, and OS window resizing
interact.

Diagnosis: **working as designed, under-explained.** `windowed_client_size_for_screen()`
clamps the client area into `screen_get_usable_rect` minus a decoration allowance
(title bar + taskbar), preserving 16:9 — so a 4K request on a 4K desktop yields a window
smaller than the screen on both axes; the leftover desktop is the expected result. The
tester's monitor runs a 1920x1080 desktop on 3840x2160 native, so OS display scaling is
also in play (Godot sizes in physical pixels of the current desktop mode).

Fix plan:

1. Write the explainer as a short guide (`AGENT/Docs/guides/` — display & settings
   model: window modes, clamp rule, DPI/OS-scaling, what settings.cfg stores and how
   versions migrate — folds in the V025-09 ask), and lift a tester-facing digest into
   the next handbook.
2. Optional polish (review Q11): show the *applied* window size next to the Resolution
   row, and/or add a "Fit screen" choice that names the clamped size explicitly.

## Workstream G - Terrain More Info click paging (`V025-08`) — repeat failure

Tester report: repeats the v0.2.3 behavior; clicking in the More-Info page (mouse in
click mode) advances to Movement cost but never dismisses. Suggests (again) a single
page with tile type + coordinate as a label, cycling all info options, with tactics info
as another option.

Diagnosis (confirmed from scene + code):

- The terrain containers (`TerrainCorner`, panels, Scroll, VBox) are all
  `mouse_filter = 2` (IGNORE), but the three `RichTextLabel`s inside
  (`TerrainDescription`, `TerrainMoveCosts`, `TerrainActions`) keep the RichTextLabel
  default `STOP` — so a click landing on the *text* is consumed in the GUI phase and
  never reaches `MapCursor._unhandled_input`, where `_try_cycle_terrain_panel_at()`
  lives. Clicks only cycle when they hit padding gaps; the Movement page's table fills
  the panel, leaving no gap — exactly "fails on the Movement page".
- The v0.2.4 repair extended the *rect hit-test* (`terrain_corner_contains_screen_
  position` now includes the More-Info panel) but the event never arrives; the headless
  test calls `_try_cycle_terrain_panel_at()` directly, so it passes (finding #2 again).

Fix plan:

1. Set `mouse_filter = MOUSE_FILTER_IGNORE` on the three RichTextLabels (they have no
   links/selection; `scroll_active` is already false).
2. Scene-level regression test asserting the mouse_filter of every node under
   `TerrainCorner` is IGNORE, plus a `push_input` click-cycling test.
3. The single-page redesign is a design question (review Q12) — it would also absorb
   the `V023-09b` "all actions + requirements" descriptor surface when `[SAC]` lands.

Likely files: `scenes/ui/HUD.tscn`, `scripts/tests/test_hud.gd`.

## Validation gaps (`V025-09`, `V025-10`)

- §1.9 migration guard: NOT RUN (no prior settings.cfg on the machine). The migration
  matrix is covered by `test_settings_manager.gd`; accept the headless coverage and
  answer the "how does settings.cfg work" ask via the Workstream F explainer.
- `godot.log` was not returned for the third consecutive pass, and Part III regression
  was not run. For the next build: make the log return a top-of-handbook checklist item
  with the exact `%APPDATA%` path, and keep `VAL-PLAYTEST-RERUN` active.

## Recommended Order

1. ~~**Owner walkthrough of the review doc**~~ — DONE 2026-07-04; all Q1-Q14 decisions
   recorded in the review doc's "Walkthrough Decisions" section (all recommendations
   taken; owner adds = Q2 panel-widen, Q14 grind units).
2. **v0.2.6 repair pass (small, focused):** E1-E3 (level-up first-show size, click
   dismissal via `_gui_input`, promotion re-apply+scroll), G (terrain mouse_filter),
   A (slider flicker + h-scroll), B1-B2 (sheet wrap + Back button), D3 (preview
   re-anchor on zoom), C (anchor stickiness), E5 (validation-map content), each with
   event-injection tests where input routing is involved.
3. **Docs:** the display/settings explainer guide (F), with a tester-facing digest in
   the v0.2.6 handbook; request `godot.log` prominently.
4. **Route the design asks to their homes:** forecast-row registry → Band 5
   source/style generalized forecast; promotion-picker redesign + stats More-Info
   layout → `UI-INSPECTION` (unless pulled); terrain single-page redesign → decide in
   review, overlaps `V023-09b` / `[SAC]`.
5. **Cut v0.2.6** as the next display rerun; `VAL-V023-DISPLAY` flips only when §1.1,
   §1.2, §1.3, §1.5, §1.6, §1.8 all pass live.

## Merge Notes

- This triage is plan-only; no behavior changed, so no GDD/roadmap flip in this commit
  (DoD#1 applies to the fix commits).
- The forecast-row ask must NOT become a hardcoded row-type switch in AttackPreview —
  it is an open-registry surface per the architecture principle and belongs with the
  Band 5 generalized forecast.
- When the input-routing fixes land, also record the test-fidelity rule (event
  injection over direct `_unhandled_input` calls) in the testing guide.
