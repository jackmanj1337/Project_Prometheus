---
Type: playtest
Status: Focused rerun handbook - pending live Windows/controller validation
Last verified: 2026-07-14
---

# Playtester Handbook and Checklist - v0.3.6

This rerun validates the remaining Action Menu and Settings repairs from the
v0.3.5 return. Use Windows and return this completed file, `godot.log`, and all
requested original-resolution screenshots.

## Before testing

- Executable: `Project_Prometheus_v0.3.6_debug.exe`
- Expected size and SHA-256: see `playtest_build_v0.3.6.md`
- Input used (keyboard/controller model): ____________________
- Windows version: ____________________
- Monitor resolution: ____________________

```powershell
Get-FileHash .\Project_Prometheus_v0.3.6_debug.exe -Algorithm SHA256
```

- [ ] Filename, byte size, and SHA-256 match the build manifest.
- [ ] Main Menu shows `v0.3.6`.
- [ ] BUILD STAMP shows version `0.3.6` and the manifest commit.

## 1. Action Menu full shrink-wrap

Perform at Menu Scale `1.0x`, then repeat at `2.0x`:

1. Open a menu containing `Separate` or `Pair Up` plus several actions.
2. Close it and immediately open one containing only `Equip` and `Wait`.
3. Reverse the order, then repeat near both horizontal viewport edges.

- [ ] Every label has clear space between it and both ornate arrows.
- [ ] The panel grows in both dimensions for the longer/taller action list.
- [ ] The following short menu immediately loses all stale side and bottom space.
- [ ] Reopening the long menu grows it again without clipping.
- [ ] Every variant flips/clamps correctly at either viewport edge.

Attach paired long/short screenshots at 1.0x and 2.0x (four screenshots).

Notes: ____________________

## 2. Bounded bidirectional focus scrolling

At Menu Scale `0.5x`, `1.0x`, and `2.0x`, traverse the complete Settings list
in both directions using taps and a held direction. Repeat in Unit Details.

- [ ] No focus step jumps directly to an end unless the focused row is at that end.
- [ ] Continuous travel never moves the scrollbar opposite to focus travel.
- [ ] Slider and taller OptionButton rows retain comparable upcoming context.
- [ ] Where space permits, roughly three upcoming visual rows remain visible.
- [ ] Top and bottom clamp without blank overflow or clipped controls.
- [ ] No horizontal scrollbar appears; every row and Back remains reachable.
- [ ] Unit Details remains smooth in both directions.

Attach Settings screenshots near both ends at 2.0x and Unit Details screenshots
near both ends at 2.0x (four screenshots).

Notes: ____________________

## Return package

- [ ] Completed checklist with input/Windows metadata and final result.
- [ ] `godot.log`, including its BUILD STAMP.
- [ ] Eight requested original-resolution screenshots.
- [ ] Exact reproduction steps for every failed box.

Final result: [ ] PASS  [ ] FAIL

Final notes: ____________________
