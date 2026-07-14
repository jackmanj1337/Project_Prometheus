---
Type: playtest
Status: Historical
Last verified: 2026-07-14
---

# Returned Playtester Handbook and Checklist - v0.3.4

This focused rerun validates the four repairs from the v0.3.3 return. Use a real
controller on Windows and return this completed file, the `godot.log`, and every
requested screenshot.

## Before testing

- Executable: `Project_Prometheus_v0.3.4_debug.exe`
- Expected size and SHA-256: see `playtest_build_v0.3.4.md`
- Controller model: ____________________
- Windows version: ____________________
- Monitor resolution: ____________________

```powershell
Get-FileHash .\Project_Prometheus_v0.3.4_debug.exe -Algorithm SHA256
```

- [ ] Filename, byte size, and SHA-256 match the build manifest.
- [ ] Main Menu shows `v0.3.4`.
- [ ] BUILD STAMP shows version `0.3.4` and the manifest commit.

## 1. LT/RT single-step threshold

For both LT and RT, slowly ramp from released through a shallow pull to full,
release, then repeat. Finally hold each trigger for at least three repeat steps.

- [x] Pulls below roughly 85% do not zoom.
- [x] Crossing the activation point produces exactly one immediate step.
- [x] Continuing from the activation point to full does not add a second step.
- [x] Release/repress produces exactly one new immediate step.
- [x] A hold pauses, then repeats at the same slow cadence for LT and RT.

Notes: ____________________

## 2. Per-faction threat views

During a red-controlled phase, watch a blue unit. Advance to blue, then return
to red. If practical, suspend/continue after both factions have distinct views.

- [x] Blue never sees red's watched marker or selected-threat view.
- [x] Blue can add/remove its own hostile watches normally.
- [x] Returning to red restores red's watch set and danger mode.
- [x] Dead or newly friendly units are pruned from their owner's view.
- [x] Suspend/continue restores each faction's independent view.
- [x] Action Menu and Map Menu still retain only their intended overlay layers.

Attach one screenshot from the red view and one from the blue view.

Notes: all looks good

## 3. Action Menu label fit

At Menu Scale `1.0x` and `2.0x`, open Action Menu with `Pair Up` and `Separate`
visible where possible. Repeat near the left and right viewport edges.

- [ ] Every label stays inside the ornate button frame at 1.0x.
- [ ] Every label stays inside the ornate button frame at 2.0x.
- [x] The wider menu flips/clamps correctly near both viewport edges.
- [ ] Changing visible actions recomputes the width without stale extra space.

Attach one 1.0x and one 2.0x screenshot.

Notes: See pictures, Menu backing grows to accommodate longer list, but does not shrink for shorter lists

## 4. Mixed-height focus lookahead

At Menu Scale `0.5x`, `1.0x`, and `2.0x`, traverse Settings through slider and
OptionButton rows in both directions. Traverse Unit Details to both list ends.

- [ ] Slider rows retain comparable upcoming context to taller option rows.
- [ ] Where space permits, roughly three upcoming visual rows remain visible.
- [ ] Both list ends clamp without blank overflow or clipped controls.
- [x] No horizontal scrollbar appears; every row and Back remains reachable.

Attach Settings and Unit Details screenshots at `2.0x` near both list ends.

using the keyboard or gamepad to move the settings menu focus up or down immediately shot the scroll bar flipping between opposite ends of the menu even when continuously moving in the same direction.
## Return package

- [ ] Completed checklist with controller/Windows metadata.
- [ ] `godot.log`, including its BUILD STAMP.
- [ ] Eight requested original-resolution screenshots.
- [ ] Exact reproduction steps for every failed box.

Final result: [ ] PASS  [ ] FAIL

Final notes: ____________________
