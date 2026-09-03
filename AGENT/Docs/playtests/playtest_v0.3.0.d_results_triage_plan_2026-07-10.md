---
Role: dated
Type: playtest
Status: Returned results - diagnosed 2026-07-10; suspend validated; VAL-V030-GAMEPAD and VAL-V023-DISPLAY stay open; MRD-7 routed to stacked-perimeter candidate
Last verified: 2026-07-10
---

# v0.3.0.d Playtest Results Triage And Review Plan - 2026-07-10

## Scope

Triage for the returned `v0.3.0.d` focused rerun. This pass existed to verify
the 2026-07-09 recovery fixes on live Windows/controller hardware and to choose
the next MRD-7 shared-threat presentation candidate.

Evidence:

- Returned checklist: `playtest_checklist_v0.3.0.d_returned_2026-07-10.md`
- Build manifest: `playtest_build_v0.3.0.d.md` (source commit `e19ac9b`,
  SHA-256 `cff6a6bc...7627efd`)
- Logs in `AGENT/Docs/archive/evidence/`:
  - `godot_log_v0.3.0.d_focus_returned_2026-07-10.log`
  - `godot_log_v0.3.0.d_display_mrd_returned_2026-07-10.log`
- Screenshots in `AGENT/Docs/archive/evidence/`:
  - `v030d_main_menu_2x_overlap_2026-07-10.png`
  - `v030d_mrd7_single_layer_bad_2026-07-10.png`
  - `v030d_mrd7_stacked_ok_2026-07-10.png`
  - `v030d_mrd7_border_through_ok_2026-07-10.png`
  - `v030d_mrd7_area_perimeter_sketch_2026-07-10.png`
- Tester environment: Windows 11, Xbox controller, 4K monitor.

## Findings First

1. **Suspend & Continue passed live.** Section 3 is checked. Continue works
   after a suspend, units can move, pair-up supports stay hidden/off-map, turn
   state restores, and relaunch after suspend still offers Continue. Move
   `B1-SUSPEND` off pending live validation. The tester's question about saving
   red turns belongs to future hotseat/online-save scope, not this gate.
2. **`VAL-V030-GAMEPAD` still fails.** Settings now scrolls, but Settings still
   lacks directional repeat. New Game focus still has invisible steps; the
   returned `V030-NG-FOCUS` log shows focus escaping to Main Menu controls
   (`QuitButton`, `SettingsButton`, `NewGameButton`, `ContinueButton`) while the
   New Game modal is open. D-pad can change attack / Pair Up targets, but the
   joystick cannot. Trigger zoom is better but still too sensitive or too fast.
3. **`VAL-V023-DISPLAY` still fails.** One-axis drag still behaves as before.
   Maximize shows the correct size but labels it as `Custom`, not `Maximized`.
   Relaunch persistence passes. The returned `V030-DSP-TRACE` log has only
   startup/maximized entries, which strongly suggests the viewport resize hook
   does not fire for bar-only one-axis drags under `stretch/aspect=keep`.
4. **MRD-7 needs a new shipped candidate.** The tester rejected the single-layer
   treatment, found `stacked` and `border_through` acceptable, and supplied a
   sketch for stacked fill plus a perimeter outline around the whole threatened
   area. Route the next implementation to `stacked_perimeter`, then remove the
   temporary F8 debug cycle after the shipped look is chosen.
5. **Main Menu 2.0x overlap remains routed to `UI-INSPECTION`.**
   `v030d_main_menu_2x_overlap_2026-07-10.png` shows Continue overlapping the
   title. This is the existing `V027-05a` Menu Scale / home-screen layout issue,
   not a `v0.3.0.d` validation blocker.

## Workstreams

### V030D-GP-01 - Modal directional repeat

Settings now scrolls, but the tester still noticed no repeat behavior in the
Settings menu. This confirms the 2026-07-09 review finding: `MenuRepeatPolicy`
was only consumed by custom menus, not engine-focus modals.

Possible fix: implement vertical-only repeat in `ModalScreen` using
`MenuRepeatPolicy("ui_left", "ui_right", "ui_up", "ui_down")`. Consume
`ui_up`/`ui_down` pressed events so engine focus cannot double-step. Leave
left/right with the focused control for sliders and option buttons.

Tests: add a `ModalScreen`/Settings-focused test proving held d-pad or stick
advances focus repeatedly through rows while left/right still reaches the
focused control.

### V030D-GP-02 - New Game modal focus containment

The old isolated New Game scene probe was too narrow. The returned live log
shows focus escaping from New Game controls to Main Menu controls while the
modal remains visible. Examples include focus moving from `BtnStart` to
`QuitButton`, from `OptPairUp` to `SettingsButton`, and from `OptMap` to
`ContinueButton`.

Possible fix: add reusable modal focus containment in `ModalScreen` or the
Main Menu modal host. While a modal is visible, focus navigation should stay
inside that modal; background/main-menu controls should not be valid focus
targets. A narrow fallback is explicit New Game focus neighbors, but that only
patches this one modal and leaves the bug class open.

Tests: instantiate `MainMenu.tscn`, open `NewGameScreen`, simulate keyboard,
d-pad, and stick navigation, and assert `get_viewport().gui_get_focus_owner()`
is always a descendant of `NewGameScreen`.

### V030D-GP-03 - Joystick ignored during targeting

The tester reports joystick movement cannot change attack or Pair Up targets,
while the d-pad can. The likely source is `MapCursor`: polled stick movement is
only routed in free/unit-selected states, while d-pad events route through
targeting and call `_cycle_target(dir)`.

Possible fix: when the cursor state is `TARGETING`, let the existing polled
stick direction call `_cycle_target(dir)` through the same repeat timing used
for free cursor movement, instead of clearing/ignoring the repeat.

Tests: extend `test_map_cursor.gd` with stick-driven attack and Pair Up target
cycling, including repeat timing and neutral reset.

### V030D-GP-04 - Trigger zoom feel

The threshold fix helped but did not fully settle controller feel. The tester
asks for less sensitivity or slower repeat.

Possible fix: raise `ZOOM_PRESS_THRESHOLD` above `0.25`, slow the fast repeat
floor, or both. Sensitivity sliders remain `B6-INPUT` backlog unless a single
constant tune is insufficient.

Tests: keep the existing low-strength graze coverage and add a repeat-rate
expectation for partial trigger pulls.

### V030D-DSP-01 - Maximized live readout

The returned result proves the readout still refreshes through the wrong event
path: maximize yields the right size but the label reads `Custom`.

Possible fix: connect SettingsScreen to a live window/viewport resize signal
while visible and defer `_refresh_applied_size()`. Keep maximize as transient
window state; do not persist it as a saved resolution.

Tests: retain formatter tests and add a signal-driven refresh test where
maximized state changes while Settings is already open.

### V030D-DSP-02 - One-axis drag detection source

The display log only contains startup/maximized `V030-DSP-TRACE` rows. There is
no trace for the reported one-axis drag. That means `Viewport.size_changed` is
probably the wrong detection source for a bar-only client resize under the
kept 16:9 viewport.

Possible fix: move resize write-back detection to a Window/DisplayServer size
source that observes the actual OS client size, or poll `DisplayServer` window
size while Settings is open/windowed and compare against the last observed
client size. Keep the pure policy in `SettingsManager` testable.

Tests: isolate the write-back policy with synthetic saved/requested/window
sizes, then live-rerun on Windows for the one-axis drag.

### V030D-MRD-01 - Stacked fill plus perimeter outline

The single-layer prototype loses shared-cell clarity. The next candidate should
keep stacked fill clarity and add one outline around the contiguous threatened
area. Future patterned fills can ride the same visual layer later.

Possible fix: ship `stacked_perimeter` as the next debug candidate. Generate
edge masks from the union of threatened tiles, draw perimeter edges through the
overlay layer, and keep source-specific stacked fills inside.

Tests: add pure edge-mask tests for isolated, adjacent, concave, and shared
source tiles; keep `test_mrd_scene.gd` screenshot coverage for nonblank stacked
and perimeter output.

## Gate Routing

| Gate / row | Result | Route |
|---|---|---|
| `B1-SUSPEND` | Passes live on `v0.3.0.d` | Flip to Implemented / live validated. |
| `VAL-V030-GAMEPAD` | Fails live | Keep Pending validation; fix modal repeat, modal focus containment, stick target cycling, and trigger feel before the next rerun. |
| `VAL-V023-DISPLAY` | Fails live | Keep Pending validation; fix maximized refresh trigger and one-axis resize source before the next rerun. |
| `B6-MRD` / MRD-7 | No shipped pick yet | Build `stacked_perimeter`; remove F8 after the shipped candidate is accepted. |
| `UI-INSPECTION` | New evidence only | Carry the 2.0x Main Menu overlap into the existing scale-safe layout task. |

## Next Review / Fix Order

1. Review and fix the gamepad bug class: modal repeat, modal focus containment,
   `MenuRepeatPolicy.clear()` neutral latch, and stick target cycling.
2. Fix display refresh/source issues: live maximize readout first, then
   one-axis write-back detection from an OS-window size source.
3. Implement the MRD-7 `stacked_perimeter` candidate and remove temporary F8
   once the candidate is accepted.
4. Cut `v0.3.0.e` as a focused rerun for gamepad, display, and MRD-7 only.
