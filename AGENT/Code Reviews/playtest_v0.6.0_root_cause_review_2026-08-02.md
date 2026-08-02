# v0.6.0 Windows Playtest Return — Root-Cause Review

**Date:** 2026-08-02  
**Build under review:** `cbd1f83257bc68fad1ccdec0bbcb8d5faa7df295`  
**Branch reviewed:** `agent/from-v0.6.0-visual-pass/playtest-patches`  
**Verdict:** Reject v0.6.0 as a release candidate; keep the independently passing
expand/free-resize work, but repair package activation, text entry, and responsive UI
before another combined visual pass.

## Executive summary

The return contains four confirmed release blockers: imported campaigns launch with no
units, grid text entry crashes the process, physical Escape still closes FileDialog,
and several UI/HUD surfaces do not respond correctly to resize and extreme scale
combinations. The logs make the first two causes unusually clear. Controller hot-plug
telemetry and package-save fail-closed behavior passed; free aspect resizing, expanded
map area, persistence, motion, Retry, and controller menu navigation also passed.

The playtester’s proposed three-layer model is directionally sound. The recommendation
is to formalize it as separate map, HUD, and temporary-window coordinate spaces, while
keeping the OS/browser surface outside gameplay layout. Do not implement percentage
storage blindly: normalized anchors plus pixel offsets are more stable for edge HUDs,
and temporary windows need bounded responsive frames rather than a fixed percentage in
all cases.

## Evidence and reproduction scope

- Preserved packet: `AGENT/Docs/playtests/evidence/v0.6.0/` (completed checklist,
  seven logs, eleven screenshots).
- Exact Windows BUILD STAMP: `v0.6.0`, commit `cbd1f832`, Godot 4.6.3, NVIDIA GL,
  Windows, 3840×2160 screen.
- `scripts/playwright-drive.sh --self-test`: Chromium 141 launched; WebGL2 available.
- Browser matrix: Settings and New Game passed at 1280×720, 1280×800, and 1920×1080.
  This is limited evidence: the current harness cannot seed non-default menu/content
  scales and uses an uninstrumented export with Tier-2 coordinates.
- `test_two_map_campaign_fixture`: 4/4 passed, proving the source fixture adapts with
  two blue and three red units. The returned logs then fail every placement at runtime.
- `test_menu_scale`: 29 assertions passed for the surfaces it covers. It does not cover
  Campaign Library anchoring, HUD resize/reset, or the physical size of fixed minimums
  under content scaling.
- A direct cold invocation of `test_text_entry.gd` could not resolve new `class_name`
  types until an import/cache refresh; this is a test-launch precondition, not evidence
  for or against the Windows crash. The returned native crash backtrace is authoritative.

## Findings and options

### V060-01 — Critical — Grid text entry crashes the native build

**Evidence.** `raw/logs/godot.log` and two rotated copies end in SIGSEGV. The GDScript
backtrace is `FileDialogInputGuard._offer_on_screen_keyboard()` →
`TextEntryOverlay.open()` → `GridTextEntryPresenter.configure()` → `_rebuild()` at
`row_box.add_child(button)` (`scripts/ui/text_entry/GridTextEntryPresenter.gd:67`). The
checklist reports the application becoming unresponsive and shutting down immediately
after interacting with a FileDialog in grid mode.

**Likely root cause.** `_offer_on_screen_keyboard()` performs a complete control-tree
construction synchronously inside the FileDialog filename `focus_entered` callback
(`FileDialogInputGuard.gd:25,133-142`). Building and focusing the overlay mutates the
same Window/Viewport’s GUI tree while focus dispatch is active. The crash is below
GDScript at `add_child`, so the exact engine invariant is not proven, but the synchronous
re-entrant construction boundary is the narrowest cause supported by the backtrace.

**Option A — defer and prebuild (recommended).** Create the overlay once after the
FileDialog is ready, build its button grid outside input/focus dispatch, and defer only
`open()`/focus transfer. Add an `_opening` guard and cancel the deferred open if the
dialog or filename focus is gone.

- Pros: smallest change; removes GUI-tree mutation from focus dispatch; retains the
  existing presenter contract.
- Cons: still depends on an overlay living inside FileDialog’s Window; needs a Windows
  regression pass because headless tests did not expose the engine crash.

**Option B — host one keyboard in the parent modal/root viewport.** FileDialog sends a
text-entry request to a persistent overlay outside its Window.

- Pros: clean ownership and reusable for every text field; avoids FileDialog internals.
- Cons: larger refactor; cross-Window focus and z-order need explicit handling.

**Recommendation.** Apply Option A as the release fix and track Option B as the desired
shared text-entry architecture if more consumers appear.

### V060-02 — High — Activating a Tier-2 campaign deletes required occupancy policies

**Evidence.** Every imported-campaign unit fails with `unknown_policy` in
`godot2026-08-01T17.39.54.log` and `godot final.log`; built-in maps still spawn units.
The two-map fixture test proves the adapter produced the expected units. At runtime,
`DataManager.select_tier2_campaign_source()` commits the package session and then calls
`RegistryManager.deactivate()` (`scripts/autoloads/DataManager.gd:200-224`).
`deactivate()` creates an empty catalogue containing primitive-handler names but no
entries (`scripts/autoloads/RegistryManager.gd:77-81`). `GameMap` defaults spawn policy
to `nearest_free` (`scripts/core/GameMap.gd:443-455`), while `OccupancyService.place()`
rejects it unless the live catalogue contains that entry
(`scripts/autoloads/OccupancyService.gd:20-29`).

**Option A — retain engine registries during Tier-2 activation (recommended now).** Load
and commit the engine-owned registry baseline independently of campaign data, and do not
call `deactivate()` when selecting a package.

- Pros: matches the present package format, which contains no registry files; repairs
  all units with a narrow lifecycle change.
- Cons: must define whether future packs may extend/override registries.

**Option B — compose engine baseline plus package registry contributions.** Build a
transactional layered catalogue with collision/provenance rules.

- Pros: aligns with the open-registry architecture and future author extensibility.
- Cons: materially larger; needs identity, override, validation, and unload semantics.

**Option C — bundle required registries into every package.** Reject packages missing
them.

- Pros: package sessions are self-contained.
- Cons: duplicates engine primitives into every pack, makes ordinary content fragile,
  and contradicts the shipped fixture contract.

**Recommendation.** Ship A, design B as the durable registry-composition seam, reject C.
Add a regression test that activates a Tier-2 pack and calls `OccupancyService.place()`
with `nearest_free`; the existing adapter test stops one call too early.

### V060-03 — High — FileDialog physical Escape still bypasses the guard

**Evidence.** The tester reports first Escape closes the whole dialog, and no returned
log contains `escape_consumed_by`. `FileDialogInputGuard` hooks four script input stages,
but handling is conditional on `get_line_edit().has_focus()`
(`FileDialogInputGuard.gd:32-103`; `TextEntrySession.gd:61-76`). The keyboard-only path
shows a second symptom: arrow navigation accepts X/Z into the field but provides no
visible caret and inserts at the beginning; ordinary keys work only after click/Tab.

**Option A — establish one explicit filename-edit state (recommended).** On entry, call
`grab_focus()`, place/show the caret, and suspend FileDialog’s cancel shortcut while that
state is active. First physical Escape exits the state and restores the shortcut; the
next closes the dialog. Log at the owning boundary.

- Pros: deterministic two-state behavior; solves the invisible-caret ambiguity.
- Cons: temporarily changing shortcut ownership must be scoped per dialog and restored
  on every close path.

**Option B — keep adding propagation hooks.** Try earlier/later Window stages.

- Pros: smaller-looking diff.
- Cons: the four-hook attempt already failed on the target platform; more hooks increase
  duplicate-event risk without clarifying ownership.

**Recommendation.** Use A and remove redundant hooks once the Windows log identifies the
single owner. Add a dispatched-event test for the state transition, but retain a native
Windows check because FileDialog owns a distinct Window/Viewport.

### V060-04 — High — Temporary windows use mixed coordinate and sizing models

**Evidence.** Campaign Library’s panel is still an absolute 500×340 rectangle at
offsets `(390,190)-(890,530)` (`scenes/ui/CampaignLibraryScreen.tscn:21-26`), unlike
New Game’s center-anchored panel (`NewGameScreen.tscn:31-41`). The returned screenshot
shows Manage Campaigns displaced relative to its parent. Settings has a fixed logical
minimum of 760×620 (`SettingsScreen.tscn:22-35`). At Viewport Scale 4.0, that frame is
3040×2480 physical pixels before borders, taller than the 2160p screen; dividing font
scale by content scale cannot reconcile a fixed frame. The screenshot confirms clipping
and overflow. New Game’s background/panel is temporarily displaced at 2×/2× until a
manual resize triggers another layout pass.

**Option A — bounded responsive frames (recommended).** Put every centered modal inside
a full-rect CenterContainer. Give the frame preferred/min sizes plus viewport-relative
maximums; place overflowable content in ScrollContainer. Recompute after scale changes
and on `size_changed`, not only on initial show.

- Pros: one model across screens; respects text scale while guaranteeing reachability.
- Cons: requires a scene-by-scene migration and visual baselines.

**Option B — percentage width/height only.** Temporary panels always occupy a fixed
viewport percentage.

- Pros: simple mental model.
- Cons: poor for tiny confirmation dialogs and ultrawide screens; can waste space or
  produce unreadably long lines.

**Recommendation.** A, with percentage bounds as caps rather than the sole size rule.
Extend the Playwright bridge so the matrix can seed menu/content scale and assert panel
rect containment. Current green tests do not exercise the failed combinations.

### V060-05 — High — HUD layout stores one-time absolute bases and never reflows on resize

**Evidence.** The tester reports phase label, turn counter, unit HUD, debug label, phase
banner, and Reset HUD Layout do not account for maximized/custom sizes; the active-phase
label can remain unreachable. `HUD._capture_base_positions()` captures absolute
`panel.position` once (`scripts/ui/HUD.gd:173-181`), persisted entries are absolute pixel
offsets from those bases (`:184-210,260-275`), and Reset merely reapplies the captured
bases (`:278-280`). There is no viewport-resize handler that reapplies or normalizes the
layout.

**Option A — normalized anchors plus local pixel offsets (recommended).** Store an anchor
point per panel (corners/edges/center or normalized Vector2) and a small logical offset;
derive position from the live safe rect on every resize. Keep scale per panel.

- Pros: preserves edge intent across aspect/size changes; supports player adjustments;
  easier to clamp safely than raw percentages.
- Cons: requires migration of existing `hud_layout` values and a defined anchor chooser.

**Option B — raw position percentages.** Store `position / viewport_size`.

- Pros: simple and close to the tester’s draft.
- Cons: panel size is ignored, so right/bottom edges drift; text growth and safe-area
  changes can still move panels off screen.

**Option C — authored anchors only; no free positioning.** Offer predefined slots.

- Pros: robust and easy to test.
- Cons: substantially reduces HUD customization.

**Recommendation.** A. Version the persisted HUD schema, migrate old absolute offsets
against the saved/reference viewport when available, and fall back to authored anchors.
Connect viewport `size_changed` to a deferred reflow and add resize/reset tests.

### V060-06 — Medium — Missing-package behavior is correct but the user message is weak

**Evidence.** The package removal test passed atomically. Logs show activation and save
validation fail without partial restore. The visible message was only “Could not load
the campaign save. Progress was not resumed,” which does not identify the missing
package or recovery action.

**Options.** Keep the generic message (low implementation cost, poor recovery), or map
the structured activation error to package id/version/path and tell the player to
restore/reinstall it (slightly more UI work, much better recovery).

**Recommendation.** Keep fail-closed behavior and add the package identity plus
“restore or reinstall, then retry.” Do not expose a raw filesystem path unless a Details
panel is opened.

### V060-07 — Medium — Intermittent controller lockout lacks enough telemetry

**Evidence.** The tester saw sticks/triggers stop responding after attack/end-turn
confirmation and a missing level-up screen, but could not reproduce it. Returned logs
do prove controller hot-plug correctness: connect/disconnect/reconnect transitions retain
device 0 name and GUID. No error or state-transition record correlates with the one-off
lockout.

**Options.** Guess at input-mode/focus changes (fast but unsafe), or instrument modal
ownership, active input mode, turn/combat state, and level-up enqueue/show transitions at
the transition boundaries.

**Recommendation.** Do not patch speculatively. Add bounded transition telemetry and a
focused next-pass sequence around confirm attack/end turn/level-up. Preserve the existing
hot-plug logger; that carry-forward check passes.

## Accepted checks and non-findings

- Controller telemetry: pass, including retained name/GUID on disconnect.
- Logging presence: BUILD STAMP, runtime environment, PLAYTEST CONTEXT, and controller
  telemetry are present. No `[V030 TRACE]` lines occur in the returned bundle. The
  checklist did not explicitly report whether the old resize-trace file existed, so that
  filesystem half remains unverified.
- Package save validation: pass and fail-closed; only message quality remains.
- Retry-after-Save and one-item controller navigation: pass.
- Expand/free resize/no black bars/more tiles/persistence/sprite motion: pass.
- Imported-package unit absence is not malformed fixture data; it is V060-02.
- Pixel shimmer should be revisited with final art, as the tester requested.

## Recommended order

1. Fix V060-02 and add the missing activation→occupancy regression test.
2. Fix V060-01 using deferred/prebuilt grid construction; rerun natively.
3. Replace FileDialog Escape hook stacking with explicit edit-state ownership (V060-03).
4. Ratify the four-layer display model as a discussion/design task, then implement
   responsive temporary frames (V060-04) and anchored HUD persistence/reflow (V060-05).
5. Improve the missing-package message (V060-06) and add focused telemetry for V060-07.
6. Cut separate verification builds where practical so text-entry failure does not hide
   viewport acceptance, and run Windows plus scale-seeded browser matrices.

## Proposed display-model discussion packet

Track the owner’s draft rather than treating it as an implementation decision:

1. **Host surface:** OS window/browser canvas; supplies the available safe rectangle.
2. **Map:** world/camera space; map zoom alone controls tile scale and visible tile count.
3. **Map HUD:** screen/safe-area space; each panel has its own scale and an anchor plus
   local offset, with future opacity. Persist intent, not raw absolute coordinates.
4. **Temporary windows:** responsive screen-space frames. Centered frames use preferred
   size with viewport-relative caps; content wraps/scrolls. Contextual frames clamp to
   the safe rect and may wrap/scroll after reaching their cap. Menu Scale controls type
   and control density, not map zoom or HUD panel scale.

Open questions: HUD anchor vocabulary and migration; min/max modal bounds; safe-area
policy; whether Menu Scale may shrink below accessibility minimum to fit; contextual
menu collision priorities; and which scale combinations become supported test points.
