---
Role: dated
Type: playtest
Status: Focused rerun handbook - pending live Windows/controller validation
Last verified: 2026-07-14
---

# Playtester Handbook and Checklist - v0.3.5

This narrow rerun validates the two UI repairs from the v0.3.4 return. The
v0.3.4 trigger-threshold and per-faction threat-view checks passed and do not
need to be repeated. Use Windows and return this completed file, `godot.log`,
and the requested original-resolution screenshots.

## Before testing

- Executable: `Project_Prometheus_v0.3.5_debug.exe`
- Expected size and SHA-256: see `playtest_build_v0.3.5.md`
- Input used (keyboard/controller model): ____________________
- Windows version: ____________________
- Monitor resolution: ____________________

```powershell
Get-FileHash .\Project_Prometheus_v0.3.5_debug.exe -Algorithm SHA256
```

- [ ] Filename, byte size, and SHA-256 match the build manifest.
- [ ] Main Menu shows `v0.3.5`.
- [ ] BUILD STAMP shows version `0.3.5` and the manifest commit.

## 1. Action Menu long-to-short resizing

Perform this at Menu Scale `1.0x`, then repeat at `2.0x`:

1. Open an Action Menu containing `Separate` or `Pair Up` plus several actions.
2. Close it and immediately open a menu containing only short actions such as
   `Equip` and `Wait`.
3. Repeat near both horizontal viewport edges.

- [ ] Every label remains inside its ornate button frame.
- [ ] The panel grows for `Separate` / `Pair Up`.
- [ ] The following short menu shrinks immediately with no stale side space.
- [ ] Both long and short widths flip/clamp correctly at either viewport edge.

Attach paired long/short screenshots at 1.0x and paired screenshots at 2.0x
(four screenshots total).

Notes: ____________________

## 2. Bidirectional focus scrolling

At Menu Scale `0.5x`, `1.0x`, and `2.0x`, traverse Settings from Back through
the complete list and back again. Hold a direction for several repeat steps as
well as tapping. Then traverse Unit Details to both ends in both directions.

- [ ] Continuous travel in one direction never jumps the scrollbar backward or
      to the opposite end.
- [ ] Slider and taller OptionButton rows retain comparable upcoming context.
- [ ] Where space permits, roughly three upcoming visual rows remain visible.
- [ ] Top and bottom clamp without blank overflow or clipped controls.
- [ ] No horizontal scrollbar appears; every row and Back remains reachable.

Attach Settings screenshots near both ends at 2.0x and Unit Details screenshots
near both ends at 2.0x (four screenshots total).

Notes: ____________________

## Return package

- [ ] Completed checklist with input/Windows metadata.
- [ ] `godot.log`, including its BUILD STAMP.
- [ ] Eight requested original-resolution screenshots.
- [ ] Exact reproduction steps for every failed box.

Final result: [ ] PASS  [ ] FAIL

Final notes: ____________________
