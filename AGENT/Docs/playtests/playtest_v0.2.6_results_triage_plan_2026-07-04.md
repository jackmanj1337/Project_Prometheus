---
Type: playtest
Status: Returned results - obvious fixes IMPLEMENTED 2026-07-04; owner walkthrough of Q1-Q7 COMPLETE 2026-07-05 (decisions in `AGENT/Code Reviews/playtest_v0.2.6_triage_review_2026-07-04.md`); next = cut the v0.2.7 rerun build
Last verified: 2026-07-05
---

# v0.2.6 Playtest Results Triage And Fix Plan - 2026-07-04

## Scope

Triage for the returned v0.2.6 playtest (the fix-build re-test of the v0.2.5
repairs, `V025-01..10`). Every tester comment was researched against the live
source; unlike the v0.2.5 triage (plan-only), the mechanical, low-risk fixes were
implemented **in this same session** — each workstream below says what already
landed and what is an owner decision. Owner decisions are collected in
`AGENT/Code Reviews/playtest_v0.2.6_triage_review_2026-07-04.md`.

Evidence:

- Returned checklist:
  `playtest_checklist_v0.2.6_returned_2026-07-04.md`
- Screenshot + log evidence in `AGENT/Docs/archive/evidence/` (list in the returned
  checklist's header note). The three combat-preview shots capture the
  before/after of the stale-transform bug (V026-03/04a) directly.
- Build manifest: `playtest_build_v0.2.6.md`
  (source commit `75b3379`, SHA-256 `90a673e1…`)
- Tester environment: Windows 11, 4K native monitor, windowed 3840x2160 request
  (applied 3563x2004 per the §1.6 readout).
- **`godot.log` was returned for the first time** (build stamp intact, three
  launches) — but from the `%APPDATA%` fallback path, not from beside the exe
  (see V026-08).

## Findings First

1. **The display gate is close.** §1.2 character sheet, §1.5 level-up/promotion,
   §1.6 windowed readout, §1.7 terrain click paging, all of Part II, and the Part
   III regression pass now PASS live. Remaining: §1.1 Menu Scale (new
   first-apply centering defect + small asks), §1.3/§1.4 anchoring at high zoom
   (one shared root cause, diagnosed and fixed this session). `VAL-V023-DISPLAY`
   stays Pending validation; the rerun shrinks to §1.1/§1.3/§1.4.
2. **§1.3 and §1.4 are ONE bug: reads of a stale viewport canvas transform.**
   `Camera2D` defers its scroll update to end-of-frame, so
   `MapCursor._reposition_context_menu_anchor()` — which runs synchronously after
   `step_zoom` writes `camera.zoom`/`position` — computed screen positions
   against the PREVIOUS frame's view. The error scales with how far the reframe
   moves the camera, which is why low zooms looked fine and max zoom was visibly
   wrong; a **no-op** zoom step (camera untouched) re-ran the placement against a
   settled transform and "normalized" it — exactly the tester's screenshots.
   FIXED: `CameraController._flush_scroll()` (`force_update_scroll()`) after
   every synchronously-read camera write (`set_zoom_index`, `pan_by_pixels`,
   `nudge_by_tiles`); regression test fails pre-fix, passes post-fix
   (`test_camera_controller.gd`).
3. **§1.1 first-apply off-center is a recenter-vs-deferred-layout race.** With
   horizontal scrolling disabled (v0.2.6's own fix), the scaled rows' minimum
   width propagates through the ScrollContainer; at 2.0x it exceeds the authored
   760px frame. `MenuScale._recenter()` centered the panel at its stale size and
   the deferred layout then grew it rightward — off-center until a later re-apply
   "settled" it (the tester's wiggling). FIXED: `_recenter` now sizes a
   scroll-frame panel from its authored base + current content minimum (capped to
   the viewport) before centering, so the first apply is final.
4. **The `._sc_` portable-log mechanism does not work in exported builds — the
   returned build stamp proves it.** The tester kept `._sc_` beside the exe, yet
   `user_data_dir` resolved to `%APPDATA%`. Godot's self-contained mode is an
   editor/tools feature; exported projects ignore the marker (the docs say
   exported projects should use `OS.get_executable_path()` instead). The v0.2.6
   claim shipped untested on an export. The build stamp's `log=` line did its
   job — the tester found and returned the log from the fallback path — so the
   *outcome* worked, the *mechanism* didn't. Options in review Q3.
5. **Keyboard reachability is the emerging theme** (§1.2 Back button, §1.5
   promotion options). The promotion case was a missing `follow_focus` (focus
   moved but scrolled out of view — fixed). The character-sheet case is
   structural: `UnitDetailsScreen._input` deliberately consumes all four cursor
   directions for the More-Info highlight, so focus nav can never reach Back —
   an owner call on the interaction model (review Q2), overlapping `B6-INPUT`
   selector extraction.

## Triage Summary

Result codes: PASS = tester checked the box; PARTIAL = works with new
defects/asks; FAIL = repaired behavior still broken.

| ID | Checklist | Result | Summary |
|---|---|---|---|
| `V026-01` | §1.1 (V025-01 re-test) | PARTIAL | Apply-on-release + h-scroll fixes hold; NEW: first-apply at 2.0x leaves the panel off-center until wiggled (FIXED); scrollbar hugs rows (FIXED); hotseat debug row missing from controls list (FIXED); slight label flicker near slider border (unreproduced); tester comment truncated mid-sentence. |
| `V026-02` | §1.2 (V025-02 re-test) | PASS + asks | Wrap/Back/More-Info layout confirmed. Asks: merge class label + level counter, fixed page spacing, stable stat grid, auto-scroll to selection (→ UI pass); Back button unreachable by directional keys (review Q2). |
| `V026-03` | §1.3 (V025-03 re-test) | PARTIAL | Good below 1.5x zoom; mispositioned at high zoom (FIXED — finding #2). |
| `V026-04` | §1.4 (V025-04d re-test) | PARTIAL | Re-anchors on zoom, but wrong at max zoom until a no-op zoom step (FIXED — finding #2); Hit/Crit dashes for alignment (FIXED). |
| `V026-05` | §1.5 (V025-05 re-test) | PASS + asks | First-show shape, click dismissal, 2.0x fit all confirmed. Only top class option reachable by keys (FIXED: `follow_focus`); asks: see a whole class per frame (Q4), re-trigger action for dismissed auto-promotions (Q5), victory screen below pending level-ups (Q6). |
| `V026-06` | §1.6 (V025-06 re-test) | PASS | `→ applied 3563x2004` readout confirmed. Ask: resolution/window-mode explainer digest in the next handbook (Q7). |
| `V026-07` | §1.7 (V025-08 re-test) | PASS | Click paging works, including the Movement page. |
| `V026-08` | §3.2 log return | PARTIAL | Log RETURNED (first time in four builds) — but via the `%APPDATA%` fallback; the `._sc_` marker does nothing in exported builds (finding #4, review Q3). |
| — | §2.1/§2.2, §3.1 | PASS | Skill cap shows five skills, weapon choice exists, stat caps hold under grinding, no regressions noticed. |

## Workstream A - Menu Scale (`V026-01`)

Fixed this session:

1. **First-apply off-center (finding #3)** — `MenuScale._recenter()` sizes
   scroll-frame panels from authored base + content minimum before centering
   (`scripts/ui/MenuScale.gd`). This also removes the "width and centering jumps
   around as you wiggle" symptom (each apply is now deterministic). Test: fresh
   instance stays centered at 2.0x and 0.5x on the FIRST apply
   (`test_settings_screen.gd`). The old global slider-x stability check was
   re-scoped panel-relative — the panel now legitimately grows and recenters.
2. **Scrollbar padding** — new `Margin` MarginContainer
   (`margin_right = 14`, scales with the factor) between the rows and the
   vertical scrollbar (`scenes/ui/SettingsScreen.tscn`).
3. **Hotseat debug row** — `debug_toggle_hotseat_override` added to
   `SettingsScreen._DEBUG_KEYBIND_LABELS` (it was toggleable via F9 and shown in
   the HUD debug banner, but never listed in the controls panel).

Open:

- **Label flicker "near the border"** — not reproduced from source reading; the
  drag path only previews the label, and step changes apply once. Needs a repro
  question back to the tester (review Q1) — likely hovering across a step
  boundary mid-drag.
- **Truncated comment** — §1.1's comment ends mid-sentence ("…and this time").
  Ask the tester what the rest was (review Q1).

## Workstream B - Zoom anchoring: context menu + combat forecast (`V026-03`, `V026-04a`)

One root cause (finding #2). Fixed this session in
`scripts/core/CameraController.gd`; `MapCursor._place_menu_near` /
`AttackPreview._reposition_for` are unchanged — they now simply read a flushed
transform. Regression test verified to fail without the fix.

Note for the rerun handbook: the tester should re-walk §1.3 at 2x-4x zoom and
§1.4 at the right wall + max zoom, since these two are exactly the evidenced
failure shapes.

## Workstream C - Combat forecast dash rows (`V026-04b`)

Fixed this session: the no-counter branch renders `Hit  —` / `Crit —` as plain
(non-link) rows instead of collapsing to empty zero-height labels, so the
triangle/effectiveness icons line up across columns
(`scripts/ui/AttackPreview.gd`; test updated). Kept out of the More-Info cycle
on purpose — there is no rate to describe.

## Workstream D - Promotion picker keyboard access (`V026-05c`)

Diagnosis: the class buttons were always `FOCUS_ALL` and focus genuinely moved on
arrow keys — but `OptionsScroll` had no `follow_focus`, so at 2.0x (where roughly
one class fits the frame) the newly focused button sat outside the visible frame.
"Only the top class option is available" was focus moving invisibly.

Fixed this session: `follow_focus = true` on the options ScrollContainer of BOTH
`PromotionScreen.tscn` and `ReclassScreen.tscn` (same rebuild-then-show shape).
Event-injected test drives a real `KEY_DOWN` through `push_input` per the
input-routing test-fidelity rule (`test_promotion_screen.gd`).

## Workstream E - Design asks routed to owner decisions

Collected in the review doc; none implemented this session:

- **Q2** — character-sheet Back button via directional keys (`V026-02e`).
- **Q3** — portable log strategy after the `._sc_` failure (`V026-08`).
- **Q4** — promotion picker sizing: see one whole class per frame (`V026-05a`).
- **Q5** — non-turn-ending "Promote" action for max-level units when
  auto-promote is on, so a dismissed picker is recoverable without more EXP
  (`V026-05b-ask`).
- **Q6** — victory screen must stack UNDER pending level-up/promotion modals so
  they resolve before the battle ends (`V026-05d-ask`).
- **Q7** — resolution/window-mode explainer digest for the next handbook
  (`V026-06-ask`); the source guide `display_and_settings_guide.md` already
  exists.
- **UI-pass items** (`V026-02a..d`): class-label/level merge, fixed page
  spacing, stable stat grid, auto-scroll to selection → `UI-INSPECTION` row
  unless pulled forward.

## Log contents note (`V026-08`)

Beyond the stamp: the log's only warnings are the known M9 skill stubs
(`dash`, `armsthrift`, `bastion`, `iron_wall`, `rally_skill` — owned by
`B5-SKILLS-EFFECTS`, no action here) and one `ObjectDB instances leaked at exit`
on one of three launches (low priority; watch for recurrence in the next
return before promoting it).

## Recommended Order

1. ~~Implement the mechanical fixes~~ — DONE this session (commits in the session
   note 2026-07-04h): V026-01a/b/c, V026-03/04a flush, V026-04b dashes,
   V026-05c follow_focus. Full suite green.
2. ~~Owner walkthrough of the review doc~~ — DONE 2026-07-05. Decisions
   (full table in the review doc): **Q1 A** flicker/truncation → v0.2.7 handbook
   asks; **Q2 C** Back-button keyboard access DEFERRED to `B6-INPUT` /
   `UI-INSPECTION` (not special-cased now); **Q3 A** drop `._sc_`, document
   `%APPDATA%` as primary; **Q4 A** cheap picker cap bump now, redesign stays with
   `UI-INSPECTION`; **Q5 A** recoverable-promotion action lands with the
   `B2-ACTION-EFFECT`/`[SAC]` registry, not a hardcoded row; **Q6 A** victory
   waits for the progression queue to drain (own control-plane slice, does NOT
   block the display gate); **Q7 A** lift the display digest into handbook §1.6.
3. **Cut the rerun build** (v0.2.7) after the walkthrough: Part I shrinks to
   §1.1 (first-apply centering + padding + hotseat row), §1.3/§1.4 at high
   zoom, plus whatever Q-fixes land. §3.2 keeps the `%APPDATA%` path as the
   PRIMARY documented location (per the Q3 decision).
4. `VAL-V023-DISPLAY` flips only when the rerun's Part I passes live.

## Merge Notes

- The GDD_10 `VAL-V023-DISPLAY` queue row and the control-plane row were updated
  to point the rerun at the v0.2.6 return + this triage (same commit as this
  doc, DoD#1).
- The `._sc_` claim in `prepare_build.sh` / the build-manifest template must be
  corrected whichever way Q3 goes — an exported build never honors the marker.
- Victory-screen stacking (Q6), if accepted, is turn/end-of-map sequencing — it
  belongs near the notification/modal ordering seam, not as a z-index patch.
