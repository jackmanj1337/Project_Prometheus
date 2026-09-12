---
Role: dated
---

# v0.3.0.d Playtest Triage - Code Review Plan - 2026-07-10

Status: PLANNED - review targets selected from returned live evidence; implement before the next focused rerun
Scope: returned `v0.3.0.d` checklist, focus/display logs, MRD-7 screenshots,
and the code paths touched by the 2026-07-09 fix pass.
Companion: `AGENT/Docs/playtests/playtest_v0.3.0.d_results_triage_plan_2026-07-10.md`

## Verdict

The suspend pass is validated and should move out of pending live validation.
The remaining defects are concentrated in two reusable seams: modal/focus input
ownership and display resize observation. Fixing those seams is preferable to
patching one screen at a time.

## Planned Findings

### R1 (HIGH) - New Game focus can escape its modal into Main Menu controls

Evidence: `godot_log_v0.3.0.d_focus_returned_2026-07-10.log` shows focus
leaving New Game controls and landing on `QuitButton`, `SettingsButton`,
`NewGameButton`, and `ContinueButton` while the New Game modal is still visible.

Risk: invisible focus steps are not just cosmetic. Activation can land on a
background command if confirm is pressed after the leak.

Review files: `scripts/ui/ModalScreen.gd`, `scripts/ui/MainMenu.gd`,
`scripts/ui/NewGameScreen.gd`, `scenes/ui/MainMenu.tscn`,
`scenes/ui/NewGameScreen.tscn`.

Possible fix: add modal focus containment in `ModalScreen` / Main Menu modal
host. While a modal is open, background controls should not participate in
focus navigation. Explicit New Game neighbor links are a fallback, but the
reusable trap is the better fix.

Test plan: instantiate `MainMenu.tscn`, open New Game, simulate up/down
keyboard, d-pad, and stick navigation, and assert the focus owner remains a
descendant of the New Game screen.

### R2 (HIGH) - Display resize observation misses bar-only one-axis drags

Evidence: the returned display log has only two `V030-DSP-TRACE` rows at
startup/maximized; no row appears for the reported one-axis drag. That points
away from the pure write-back policy and toward the event source.

Risk: any resize that changes the OS client size but not the kept 16:9 viewport
will never update Settings or persistence.

Review files: `scripts/autoloads/SettingsManager.gd`,
`scripts/ui/SettingsScreen.gd`, `scripts/shared/MenuScale.gd`.

Possible fix: observe actual OS window/client size via Window/DisplayServer
instead of relying only on `Viewport.size_changed`, or poll actual window size
while Settings is visible/windowed. Keep the policy testable by passing observed
sizes into `SettingsManager`.

Test plan: pure policy tests for window-size transitions, plus a Windows live
rerun for one-axis drag.

### R3 (HIGH) - Maximized readout still lacks a live refresh trigger

Evidence: tester reports maximize shows the correct size but labels it as
`Custom`, not `Maximized`. The 2026-07-09 fix covered formatter behavior, but
the live screen still does not refresh when the OS window state changes.

Risk: display validation remains open even though persistence is now correct.

Possible fix: connect SettingsScreen to a live window/viewport change while
visible and defer `_refresh_applied_size()`. Do not emit a resolution write-back
for maximize.

Test plan: signal-driven SettingsScreen test that changes the maximized state
while the screen is already open.

### R4 (MEDIUM) - Engine-focus modals still lack directional repeat

Evidence: Settings scrolls now, but the tester still noticed no repeat behavior
in Settings. `MenuRepeatPolicy` exists but only custom menus consume it.

Risk: controller users must tap through long Settings lists one row at a time.

Review files: `scripts/ui/ModalScreen.gd`,
`scripts/shared/MenuRepeatPolicy.gd`, Settings/Promotion/Reclass modals.

Possible fix: add vertical-only repeat to `ModalScreen`. Consume up/down press
events so engine focus does not double-step. Let left/right remain owned by the
focused control.

Test plan: modal repeat test over a focus chain, plus regression that sliders
and option buttons still receive left/right.

### R5 (MEDIUM) - Held-stick neutral latch is still needed after clearing menu repeat

Evidence: carried from `v0.3.0_fix_pass_review_2026-07-09.md`: `clear()` resets
the policy to zero, so a stick already held when a menu opens can fire as a new
direction on the first poll.

Risk: action menus can open and immediately move off their default item.

Possible fix: after `clear()`, ignore directions until a neutral vector has
been observed once.

Test plan: `test_menu_repeat_policy.gd` case proving a held direction across
`clear()` does not step until released.

### R6 (MEDIUM) - Analog stick is ignored during targeting

Evidence: tester reports joystick cannot change attack or Pair Up targets, but
d-pad can.

Risk: controller parity fails in one of the most common combat flows.

Review files: `scripts/core/MapCursor.gd`, `scripts/core/MapCursorInput.gd`,
`scripts/core/MapCursorTargeting.gd`.

Possible fix: in targeting states, route the polled stick direction to
`_cycle_target(dir)` through the same repeat cadence used by the map cursor.

Test plan: `test_map_cursor.gd` coverage for stick-driven attack target and
Pair Up target cycling.

### R7 (LOW/MEDIUM) - Trigger zoom feel still needs a conservative tune

Evidence: tester says trigger zoom is better but could be less sensitive or
slower.

Risk: not a mapping failure anymore, but still affects controller comfort.

Possible fix: raise the activation threshold and/or slow the repeat floor.
Sensitivity sliders remain backlog unless constants cannot settle the feel.

Test plan: retain graze/no-zoom coverage and add partial-pull repeat coverage.

### R8 (MRD) - Neither existing shared-cell prototype should be shipped as-is

Evidence: single-layer was rejected; stacked and border-through were acceptable;
the tester sketch asks for stacked fill plus one outline around the threat area.

Risk: shipping either prototype misses the actual readability ask.

Review files: `scripts/core/GridManager.gd`, `scripts/core/MapCursor.gd`,
`test_mrd_scene.gd`.

Possible fix: implement `stacked_perimeter`: stacked source fills inside the
area, edge mask drawn around the union perimeter. Remove temporary F8 once the
accepted shipped mode is chosen.

Test plan: pure perimeter edge-mask tests plus MRD scene screenshot coverage.

### R9 (UI backlog) - Main Menu 2.0x overlap remains visible

Evidence: `v030d_main_menu_2x_overlap_2026-07-10.png`.

Risk: not a `v0.3.0.d` gate blocker, but it confirms `V027-05a` is still live.

Possible fix: route through `UI-INSPECTION`: scale-safe Main Menu layout using
responsive containers or a home-screen-specific Menu Scale constraint.

## Recommended Fix Sequence

1. `ModalScreen`: vertical repeat plus wait-for-neutral policy coverage.
2. Main Menu / New Game: reusable modal focus containment and live-parent focus
   regression test.
3. Map targeting: stick-driven target cycling.
4. Display: live maximized readout refresh, then OS-window-size observation for
   one-axis drags.
5. MRD-7: `stacked_perimeter` candidate and removal plan for temporary F8.
6. Trigger feel tune after the core controller correctness fixes.

## Rerun Criteria

Cut the next focused build only after the tests above pass and the handbook
asks for the narrow live matrix: Settings repeat, New Game focus containment,
stick target cycling, trigger feel, one-axis drag, maximized label, relaunch
persistence, and MRD-7 perimeter readability.
