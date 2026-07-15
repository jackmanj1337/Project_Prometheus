---
Type: playtest
Status: Focused rerun checklist - pending rerun build/export and live Windows validation
Last verified: 2026-07-09
---

# v0.3.0 Focused Rerun Checklist - 2026-07-09

Use this only for the post-2026-07-09 rerun build that includes the
`V030-DSP-TRACE` and `V030-NG-FOCUS` diagnostic log lines. The broad v0.3.0
handbook remains `playtest_checklist_v0.3.0.md`; this checklist narrows the
rerun to the fixes and live-only holdouts from the returned v0.3.0 pass.

## Required Return Artifacts

- The whole `godot.log` from each launch used in this checklist.
- Screenshots for any visual or focus failure.
- Controller model(s), Windows version, monitor native resolution, Menu Scale,
  and exact repro steps.

The log is per launch. Copy it before relaunching if a step says to quit and
reopen the game.

## Diagnostic Log Markers

This rerun build intentionally prints temporary diagnostic lines:

- `V030-NG-FOCUS` while the New Game modal is visible. These lines record focus
  owner, directional input events, and input-prompt mode switches.
- `V030-DSP-TRACE` around viewport resize handling, DisplayServer window mode,
  saved resolution, requested window size, and write-back decisions.

Do not trim these lines from the returned log. They are the evidence for the two
holdouts that could not be reproduced headlessly.

## 1. Controller Fix Rerun

Use a real controller for this section.

1. Open Settings with Start -> Settings.
2. Move down past the visible Settings rows using the d-pad and left stick.
3. Confirm the list scrolls to keep the focused row visible.
4. Open the Action Menu and Unit Details. Hold a direction on the d-pad and left
   stick long enough to feel repeat cadence.
5. Use LT/RT on the map: short tap, light pull, full hold.
6. Connect a second pad if available. Use each pad and confirm prompts follow
   the pad actually used.

Expected:

- Settings and Unit Details scroll with focused rows.
- Custom menus repeat steadily and do not step too fast or stall.
- Light trigger contact below a real press does not zoom; deliberate pulls do.
- Prompt labels follow the last active pad brand.

- [ ] Controller fixes pass.

Notes:

## 2. New Game Focus Holdout

This is the live-only `V030-GP-01` holdout. The headless focus chain already
passes, so the log is more important than guessing.

1. Set Settings -> Input Prompts to **Auto**.
2. Return to Main Menu and open New Game.
3. Using only the controller d-pad, press down one step at a time:
   Map -> Permadeath -> Auto Promote -> Leveling -> Pair Up -> Start -> Back.
4. Repeat with the left stick, using deliberate taps and full releases.
5. Switch once from keyboard/mouse to controller while New Game is open, then
   repeat the same down-chain.

Expected:

- The focus highlight remains visible on every row.
- One down press moves one row.
- No press disappears into a hidden focus owner or resets focus to Start.

If the highlight disappears, stop immediately, note the exact row transition,
take a screenshot if useful, and return the `godot.log` containing
`V030-NG-FOCUS` lines.

- [ ] New Game focus passes or the log captures the failure.

Notes:

## 3. Suspend And Continue Rerun

Run the v0.3.0 handbook Part IV section 9, with extra attention to the
2026-07-09 fixes.

Expected:

- Done units resume with DONE visuals and cannot look falsely ready.
- Pair Up supports stay hidden/off-map after Continue.
- Suspend & Quit is available only on the blue player phase.
- Turn counter restores immediately.
- Relaunching after suspend still offers Continue and resumes correctly.

- [ ] Suspend/Continue fixes pass.

Notes:

## 4. Display One-Axis Drag And Persistence

Run this on Windows in Windowed mode with Settings open.

1. Pick a known windowed preset such as 1920x1080.
2. Drag a corner or two edges to a clearly custom two-axis size. Confirm the
   readout updates to `client WxH` and the dropdown shows `Custom (WxH)`.
3. Reset to the preset. Drag only the right or left edge so width changes much
   more than height and the rendered picture mainly grows black bars.
4. Reset again if needed. Drag only the top or bottom edge so height changes
   much more than width.
5. Maximize the Windowed window and confirm the readout says `Maximized (WxH)`.
6. Restore/un-maximize and confirm the saved windowed readout returns.
7. Quit the game, relaunch, reopen Settings, and confirm the custom dragged
   size persisted.

Expected:

- Every genuine OS edge drag that changes client size writes a `client WxH`
  value and a matching `Custom (WxH)` dropdown entry.
- Maximize shows `Maximized (WxH)` but does not persist that size.
- Relaunch returns to the saved custom windowed size.

If a one-axis drag does not update the readout, return the log with
`V030-DSP-TRACE` lines from that launch.

- [ ] Display one-axis drag, maximize, and relaunch persistence pass or the log
  captures the failure.

Notes:

## 5. MRD-7 Shared-Cell Overlay Comparison

Run this on a map with at least one watched enemy and one player unit whose
movement or target range overlaps that watched threat.

1. Use R3/Q/MMB over an enemy to add a watched threat and show its "D" marker.
2. Select a player unit whose movement range overlaps that threat.
3. Press **F8** to cycle `single_layer` -> `border_through` -> `stacked`.
   The log prints `MRD shared-cell overlay mode: ...` after each cycle.
4. Repeat once while entering attack/staff/pair-up targeting.

Expected:

- The watched-threat paint and "D" marker remain visible through selection and
  targeting.
- `border_through` reads as threat colour with a strong movement/target border.
- `stacked` reads as a blended threat + movement/target tile.
- Pick the clearer presentation for the shipped mode.

- [ ] MRD-7 shared-cell presentation picked, or screenshots/log notes explain
  why neither prototype is acceptable.

Notes:

## 6. Recorded Requests

Do not mark these as new v0.3.0 defects unless the behavior is worse than the
original return:

- Cursor-traced manual pathing is recorded as `[MRD-8]` and deferred with
  perception/fog design.
- Main Menu 2.0x overlap is already routed to `UI-INSPECTION`.
- Real controller sensitivity sliders are `B6-INPUT` backlog after the default
  LT/RT threshold fix.

## Gate Summary

- [ ] `VAL-V030-GAMEPAD` can close: controller fixes and New Game focus pass on
  real hardware, or the only remaining issue is fully captured in logs.
- [ ] `VAL-V023-DISPLAY` can close: display item 4 passes on real Windows
  hardware, including one-axis drag, maximize readout, and relaunch persistence.
- [ ] Suspend/Continue can move from pending live validation after item 3 passes.

Notes:
