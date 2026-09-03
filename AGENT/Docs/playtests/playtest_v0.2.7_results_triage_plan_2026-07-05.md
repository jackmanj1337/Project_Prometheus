---
Role: dated
Type: playtest
Status: Returned results - diagnosed 2026-07-05; owner walkthrough Q1-Q7 done same day (decisions in `AGENT/Code Reviews/playtest_v0.2.7_triage_review_2026-07-05.md`; Q5 -> full write-back); V027 fix pass LANDED 2026-07-05 (Q1-Q6 with regression tests; Q3 repro found the unflushed cursor-scroll camera write); next = cut the v0.2.8 rerun of section 1.3/1.4/1.6
Last verified: 2026-07-05
---

# v0.2.7 Playtest Results Triage And Fix Plan - 2026-07-05

## Scope

Triage for the returned v0.2.7 playtest — the focused display-gate rerun of
§1.1/§1.3/§1.4/§1.5/§1.6 after the v0.2.6 return. Every tester comment was
researched against the live source on `docs-reorg-2026-06-23` (the release line,
`dd23656`). Unlike the v0.2.6 triage, **no fixes were implemented in this pass** —
each finding below carries a diagnosis and a recommended repair, and the choices
are collected as owner questions in the companion review doc.

Evidence:

- Returned checklist: `playtest_checklist_v0.2.7_returned_2026-07-05.md`
- Screenshots + logs in `AGENT/Docs/archive/evidence/`:
  - `action_menu_max_zoom_drift_over_unit_2026-07-05.png` (§1.3)
  - `settings_menu_1p75x_panel_size_2026-07-05.png` / `settings_menu_2x_panel_size_2026-07-05.png` (§1.1 note)
  - `settings_menu_windowed_4k_switch_2x_stretched_offscreen_2026-07-05.png` (§1.6)
  - `windowed_manual_resize_readout_stale_2026-07-05.png` (§1.6)
  - `godot_log_v0.2.7_returned_2026-07-05.log` (two launches, stamps intact) plus
    three per-session logs `godot_v0.2.7_session_2026-07-05T*.log` and one stray
    v0.2.6 session log `godot_v0.2.6_stray_session_2026-07-04T20.26.21.log`
- Build manifest: `playtest_build_v0.2.7.md` (source commit `26af9f4`,
  SHA-256 `5c02a0c8…`)
- Tester environment: Windows 11, 4K-capable monitor, NVIDIA RTX 5070 Ti,
  OpenGL Compatibility renderer; exe run from `E:/Utilities/ObsidianPortable/`.
- **The log came back again** (second return in a row) — the `%APPDATA%` flow from
  V026-08 is working; BUILD STAMP pasted into §3.2 as asked.

## Findings First

1. **The display gate does NOT close on this return.** §1.1 (Menu Scale) and §1.5
   (promotion picker, tester routes the rest to the UI pass) are **checked PASS**,
   and §3.1 regression is clean — but **§1.3, §1.4 and §1.6 are unchecked** with
   specific new defects. `VAL-V023-DISPLAY` stays Pending validation; the rerun
   shrinks again, to §1.3/§1.4/§1.6 (a v0.2.8 rerun build after fixes).
2. **Both v0.2.6 loose ends on §1.1 close.** The tester reports "everything seems
   fine" at §1.1 — the truncated-sentence ask (`V026-01d`) is subsumed by the pass
   and the "flickers near the border" report (`V026-01e`) was not reproduced by the
   tester either. Both can be marked resolved.
3. **§1.3 is a plain geometry bug, not another stale-transform case.** Diagnosed
   from source; see V027-02.
4. **§1.6 exposed one unimplemented documented behaviour** (the applied-size
   readout does not track OS drag-resizes — nothing in the codebase connects to
   `size_changed` at all) **and one once-per-boot layout race** on the
   1440p→4K switch at 2.0× Menu Scale. See V027-04.
5. **Log notes:** the returned logs contain only the known M9 `SkillHandler` stub
   warnings (`bastion`, `iron_wall`) and one `ObjectDB instances leaked at exit`
   warning on the 18:42 session — noted for a future leak audit, not a playtest
   defect.

## Workstreams

### V027-01 — §1.1 Menu Scale: panel total size differs between 1.75× and 2.0× (PASSED, note only)

Tester: *"everything seems fine, but the menu still changes total size when moving
between 2x and 1.75x. We should also make a note that the home screen menu can be
disconnected from scaling and left large later."*

**Diagnosis (by-design mechanism, not a defect):** `MenuScale._recenter()` sizes a
scroll-frame panel to `clamp(max(authored base, scaled content minimum), viewport)`
(the V026-01a fix). The content minimum scales with the font factor, so the frame
legitimately lands on different sizes at 1.75× vs 2.0×. The screenshots show
exactly that (≈54% vs ≈56% of the window width). A constant-size frame is a
different design, not a repair.

- Routing recommendation: log both the frame-stability question and the
  main-menu-exempt-from-scaling ask (`V027-05a`) to the `UI-INSPECTION` pass —
  the tester checked the item and said "later" themselves. Owner question Q7.

### V027-02 — §1.3 Action menu drifts OVER the unit as zoom rises (FAILED)

Tester: *"does not jump away from the unit but at higher than 1x zoom it gradually
moves more over the unit the more you zoom in. Does not appear to be affected by
menu scale size."*

**Diagnosis (confirmed in source):** `MapCursor._place_menu_near()` offsets the
menu from the tile's **top-left** screen position (`tile_to_world` returns the TL
corner) by `gap_px = minf(tile_px, TILE_SIZE) + 4` — the V025-03 cap that stopped
the menu launching a full magnified tile away. But the cap is measured from the
tile's LEFT edge, so once the zoomed tile is wider than one unzoomed tile
(zoom > 1: 96–256px wide vs the capped 68px offset) the menu sits progressively
further INSIDE the unit's tile. At 4× the tile is 256px and the menu covers most
of it — exactly the screenshot. Menu Scale not affecting it matches: the bug is in
the anchor math, not the menu size.

**Fix (mechanical):** anchor to the tile's **far edge** plus a small constant gap,
the same model `AttackPreview._reposition_for()` already uses
(`defender_screen.x + tile_px + margin`): `right_x = screen_pos.x + tile_px + 4`,
`left_x = screen_pos.x - menu_size.x - 4`. Keeps V025-03's intent (the GAP beyond
the tile edge stays constant instead of scaling) without re-introducing the
far-launch. Regression case in `test_map_cursor.gd` at zoom 4. Owner question Q1
(includes rejected alternates).

### V027-03 — §1.4 Combat forecast: first-open dead space + left-wall misplacement (FAILED)

Tester: *"The first time the combat preview opened, there was extra space in the
tinted window bellow the information. the second time it was not there … The old
bug on the right wall is fixed, but it is still doing the same thing on the left
wall."*

**(a) First-open extra space — diagnosed.** `_size_panel_to_content()` seeds a
fixed `PANEL_DEFAULT_HEIGHT` and lets `PanelContainer`'s minimum-size pass grow the
panel. On the FIRST show the RichTextLabel content minimums read inflated (they
settle after one layout frame — the same first-show trap as V025-05a), so the
panel draws taller than its rows for that open only; the second open reads settled
minimums and fits. Fix: re-run sizing + placement once, one frame after the first
show (`apply_to_deferred` precedent). Owner question Q2.

**(b) Left-wall misplacement — NOT yet pinned; needs a repro.** The right-wall
fix (V026-03/04a stale-transform flush) is in and the tester confirms that wall.
Source reading finds no left-side mirror of the old bug: placement prefers the
defender's right side, which is exactly where room exists at the left wall.
Candidates, in likelihood order: (1) at max zoom the panel (~650 canvas px) plus a
256px tile exceeds half the 1280×720 canvas, so the pan-camera branch triggers
across most of the map and its interplay with the wall clamp is untested at the
left edge; (2) `_place_clear_of()` slides vertically per avoid-rect in ONE pass —
clearing a HUD rect can land the panel back on the defender rect with no
re-check; (3) a residual one-frame timing hole the manual "zoom past max" no-op
heals. Fix plan: reproduce headlessly first (durable scene-suite pattern from
`test_mrd_scene.gd`: defender on the left wall, max zoom, assert panel rect vs
defender rect), then repair what the repro shows; belt-and-braces, add a deferred
one-frame re-anchor after zoom repositions — the automated version of the tester's
manual heal. Owner question Q3.

### V027-04 — §1.6 Windowed sizing: 4K-switch stretch + stale applied readout (FAILED)

Tester: *"after switching from windowed 1440p to windowed 4k at 2x menu scale the
menu got all stretched out and went off the right hand side of the screen. The
menu returned to normal after decreasing and re-increasing the menu size and would
not replicate the effect until the game was rebooted. The applied resolution does
not update when manually resized by the os. picture given in folder. When in
borderless and fullscreen mode can we fix resolution displayed to the display size
and gray out or remove the option to prevent confusion."*

**(a) 4K-switch stretch — diagnosed as a missing resize hook.** Nothing in the
codebase re-applies Menu Scale when the window size changes (`size_changed` is
connected nowhere). On the resolution apply the window resizes asynchronously;
any post-resize change to the scaled rows' content minimum (font re-measure under
the new stretch scale) propagates up the ScrollContainer AFTER the last
`_recenter` ran — the panel grows rightward/downward from its anchored top-left
with nobody re-centering it. That is the V026-01a failure shape, re-triggered by a
window-size change instead of a slider change, and it matches the screenshot
(left edge on screen, right edge off) and the recovery (any slider wiggle
re-applies and settles it). Fix: one `size_changed` → deferred
`_apply_menu_scale()` hook in SettingsManager. Owner question Q4.

**(b) Applied readout stale after OS drag-resize — documented behaviour was never
built.** The §1.6 handbook explainer promised "dragging the window edge writes the
new applied size back into the readout and re-centres the window". In source,
`applied_windowed_size()` computes from the SAVED resolution request + usable
rect — it never reads the actual window size — and no `size_changed` handler
exists, so the readout can only change when the dropdown does. The handbook
overpromised (my error in the v0.2.7 doc pass — the explainer generalised the
dropdown-apply recentre into a drag-resize behaviour that does not exist). Fix
options (readout-only live refresh vs full write-back) + handbook correction:
owner question Q5.

**(c) Borderless/fullscreen resolution row — UX ask.** Show the native display
size and disable (gray out) the Resolution row outside Windowed mode. Owner
question Q6.

### V027-05 — Feature asks routed to registers (no build this cycle)

- **(a) Main menu decoupled from Menu Scale** (from §1.1): `MainMenu.gd` is a
  `menu_scale_targets` member like every menu; exempting it (or pinning it large)
  is an authoring choice for the `UI-INSPECTION` pass. With Q7.
- **(b) §1.5 promotion-picker polish**: tester explicitly re-routes to the UI pass
  ("lets leave this for now and just make sure that we come back to this during
  the ui pass") — already recorded there (promotion-picker master/detail redesign,
  `UI-INSPECTION`). No new item.

## Sequencing

1. Owner walkthrough of Q1–Q7 (companion review doc).
2. Land the decided fixes on `docs-reorg-2026-06-23` with regression tests
   (V027-02 geometry; V027-03a deferred re-size; V027-03b repro-then-fix;
   V027-04a resize hook; V027-04b readout; V027-05c gray-out — per decisions).
3. Correct the §1.6 handbook explainer wherever V027-04b lands.
4. Cut **v0.2.8** as the next (smaller) display-gate rerun: §1.3, §1.4, §1.6 only.
5. On a v0.2.8 Part I pass: flip `VAL-V023-DISPLAY` → proceed to `REL-V023-MERGE`
   / `B6-WEB-DEBUG` per the control plane.
