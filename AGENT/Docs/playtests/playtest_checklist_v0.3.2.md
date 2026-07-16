Status: Planned - focused live rerun
Last verified: 2026-07-12

# Playtester Handbook and Checklist - v0.3.2

## Purpose

This is a narrow confirmation build for the remaining v0.3.1 findings. Test the
five areas below on Windows with a real controller. Do not use this run as a
general feature sweep.

The build intentionally retains the `V030-NG-FOCUS` and `V030-DSP-TRACE` log
lines and the debug F8 threat-overlay selector. Attach `godot.log` after the run.

## Build verification

- Executable: `Project_Prometheus_v0.3.2_debug.exe`
- Expected size and SHA-256: see `playtest_build_v0.3.2.md`
- Source stamp: see the same manifest and the startup log

PowerShell verification:

```powershell
Get-FileHash .\Project_Prometheus_v0.3.2_debug.exe -Algorithm SHA256
```

Record:

- [ ] Filename is exactly `Project_Prometheus_v0.3.2_debug.exe`.
- [ ] SHA-256 matches the build manifest.
- [ ] Main Menu shows `v0.3.2`.
- [ ] Startup log build stamp matches the manifest source commit.

## A. Dropdown focus standdown

Use both keyboard and controller.

1. Open New Game and highlight a dropdown.
2. Open it, move up and down inside the popup, then choose an item.
3. Repeat in Settings with Input Prompts, Window Mode, and Resolution.
4. Close a popup while still holding Up or Down.

- [ ] Popup selection moves normally.
- [ ] The parent screen's focus does not move behind the open popup.
- [ ] Closing while a direction is held does not cause a surprise parent-row step.
- [ ] Confirm and Cancel affect only the active popup.

Notes:

## B. Character sheet navigation and scrolling

Use a paired unit so View Support or View Lead is visible. Test keyboard and
controller separately.

1. Open Unit Details and traverse every More Info row with directions.
2. Continue through View Support/View Lead and Back.
3. Confirm View Support/View Lead, then navigate back to the original unit.
4. Repeat at Menu Scale 0.5x, 1.0x, and 2.0x.

- [ ] Selection reaches every visible information section.
- [ ] Selection reaches View Support/View Lead without mouse or shoulder shortcut.
- [ ] Confirm opens the paired unit from that selectable entry.
- [ ] The sheet scrolls to keep the selected section visible.
- [ ] Back remains reachable and closes the sheet.
- [ ] No horizontal scrollbar or clipped controls appear at the tested scales.

Notes:

## C. Menu cadence and map zoom feel

1. Hold a direction in Action Menu, Settings, and Unit Details.
2. Compare taps with a held direction; check wraparound near list ends.
3. On the map, tap LT/RT once, then hold each trigger at shallow and full pull.

- [ ] A tap advances exactly once.
- [ ] Held menu movement begins after a noticeable pause and remains controllable.
- [ ] No menu skips multiple rows unexpectedly.
- [ ] Trigger zoom steps once on press, then repeats at a constant slow cadence.
- [ ] Shallow and full trigger pulls use the same repeat cadence after threshold.
- [ ] Context menus remain anchored correctly after zooming.

Notes:

## D. One-axis window resize and persistence

Start Window Mode = Windowed. Run this section with the Settings screen open so
the Resolution readout is visible.

1. Drag only the bottom edge for at least five seconds, pause, then release.
2. Drag only the right edge for at least five seconds, pause, then release.
3. Alternate short width-only and height-only drags.
4. Wait two seconds after the last drag, exit normally, and relaunch.
5. Maximize and restore once; do not treat the maximized client size as a chosen
   custom resolution.

- [ ] Readout follows the final width-only size.
- [ ] Readout follows the final height-only size.
- [ ] Readout converges within one second if a live event is missed.
- [ ] The final custom size survives relaunch.
- [ ] Maximize shows `Maximized (W x H)` and does not overwrite the saved size.
- [ ] Restore returns to the chosen windowed size.

Record the final readout before exit and after relaunch:

- Before exit:
- After relaunch:

Notes:

## E. MRD-7 dual-outline review

Use a map with overlapping full danger and watched-enemy threat. Toggle full and
selected danger so both regions are visible, then press F8 until the log prints
`dual_outline`.

- [ ] Bright red outlines the complete danger-area union.
- [ ] Dark red outlines the watched-threat union.
- [ ] Dark red draws over bright red where their edges overlap.
- [ ] Both outlines remain readable over unit sprites.
- [ ] Movement/path overlays remain readable with the threat display active.
- [ ] No stale outline remains after danger mode is turned off or the map changes.

MRD-7 decision:

- [ ] Accept `dual_outline` as the default.
- [ ] Reject it; describe the exact visibility/color/width problem below.

Notes:

## Return package and gate result

Return:

- This completed checklist.
- `godot.log` from the run, including the startup stamp and resize traces.
- A screenshot of the accepted/rejected `dual_outline` state.
- A screenshot of the final custom-size readout after relaunch.

Final result:

- [ ] `VAL-V030-GAMEPAD` passes.
- [ ] `VAL-V030-GAMEPAD` remains open; failed item(s):
- [ ] `VAL-V023-DISPLAY` passes.
- [ ] `VAL-V023-DISPLAY` remains open; failed item(s):

