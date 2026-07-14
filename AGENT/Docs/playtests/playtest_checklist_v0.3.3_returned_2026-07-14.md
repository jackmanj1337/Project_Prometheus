---
Type: playtest
Status: Historical - returned live Windows/controller evidence
Last verified: 2026-07-14
---

# Returned Playtester Handbook and Checklist - v0.3.3 (Focused Rerun)

> **Historical:** preserved tester-authored evidence. Findings and proposed
> solutions are triaged in
> [`playtest_v0.3.3_results_triage_plan_2026-07-14.md`](playtest_v0.3.3_results_triage_plan_2026-07-14.md).

This is a narrow retest of the three fixes requested after v0.3.2. It is not a
general feature sweep. Use a real controller on Windows and return this completed
file, every `godot.log` created during the run, and the requested screenshots.

## Before testing

- Executable: `Project_Prometheus_v0.3.3_debug.exe`
- Expected size and SHA-256: see `playtest_build_v0.3.3.md`
- Controller model: ____________________
- Windows version: ____________________
- Monitor resolution: ____________________

Verify the file in PowerShell:

```powershell
Get-FileHash .\Project_Prometheus_v0.3.3_debug.exe -Algorithm SHA256
```

- [ ] Filename, byte size, and SHA-256 match the build manifest.
- [ ] Main Menu shows `v0.3.3`.
- [ ] The startup BUILD STAMP shows version `0.3.3` and the manifest commit.

## 1. LT/RT zoom feel

Start a map and use the same controller that reported v0.3.2.

1. Pull LT and RT shallowly, below roughly 85% travel.
2. Pull each trigger fully once and release promptly.
3. Hold LT fully for at least three repeat steps, then do the same with RT.
4. Repeat while an Action Menu is open to confirm its anchor remains stable.

- [ ] Shallow pulls do not zoom.
- [ ] A deliberate near-full/full pull produces exactly one immediate step.
- [ ] Holding either trigger pauses, then repeats at the same slow cadence.
- [x] LT and RT feel equally controllable despite the unequal visual zoom ratios.
- [x] Action Menu remains anchored correctly after zooming.

Notes: trigger sensitivity does not feel like 85 percent and repeat is still fast enough that a single full pull does two steps. A gentle pull has the same quick zoom, but a full pull has the more gentle distinct steps but you stil get a bit of a rush in the middle as the trigger is deppressed. The GUI menu testing also sneaked into the release and the action menu text labels on the buttons don't quite stay withing the graphical boundaries. 

## 2. Menu focus lookahead

Test Settings and Unit Details at Menu Scale `0.5x`, `1.0x`, and `2.0x`.

1. In Settings, move focus down and up through the full list near both ends.
2. In Unit Details, traverse every More Info row, View Support/View Lead if
   available, and Back near both ends of the sheet.
3. At each scale, check how much upcoming content remains visible.

- [ ] Where space permits, roughly three upcoming row heights remain visible.
- [x] Near list ends, scrolling clamps cleanly without blank overflow.
- [x] At 2.0x, the margin shrinks when necessary instead of clipping controls.
- [x] No horizontal scrollbar appears.
- [x] Every row, paired-unit entry, and Back remains reachable.

Attach one screenshot from Settings and one from Unit Details at `2.0x`.

Notes: Looks good at 0.5 and 1x but still a little cramped at the top on 2x. double check if the sliders have a different height impact on the padding because it seems to be smaller.

## 3. Threat overlays under menus

Use a map with full danger plus at least one watched enemy so both bright and
dark `dual_outline` boundaries are visible.

1. Select and move a player unit to open Action Menu.
2. Close it without committing, then open Map Menu from an empty tile.
3. Close Map Menu, end the phase, and return to the player phase.
4. If practical, suspend and continue once.

- [x] `dual_outline` is active by default; F8 no longer changes its mode.
- [x] Action Menu retains threat/watch plus the selected unit's movement range.
- [x] Action Menu clears path arrows and hover-peek paint.
- [x] Map Menu retains threat/watch but not a movement range.
- [x] Map Menu clears path arrows and hover-peek paint.
- [x] Closing either menu restores normal interactive overlays without residue.
- [x] Enemy phase and suspend/continue do not retain stale threat positions.

Attach one Action Menu screenshot and one Map Menu screenshot with threat visible.

Notes: There is a small bug where during an red phase you can mark a blue unit and then on a blue turn that blue unit is still included in the watchlist view but can't be removed by the blue player. Each team should have a separate watchlist that only shows on their turn and the markers of who you are watching should only show up for you on your turn.

## Return package

- [x] Completed checklist.
- [ ] Every `godot.log`, including its BUILD STAMP.
- [ ] Four requested screenshots at their original resolution.
- [ ] Controller model and Windows version recorded above.

Final result:

- [ ] PASS — all three fixes are accepted.
- [ ] FAIL — list failed section(s) and exact reproduction steps below.

Final notes: ____________________
