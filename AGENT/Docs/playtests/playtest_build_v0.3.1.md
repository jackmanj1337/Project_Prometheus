---
Role: dated
---

# Playtester Build Manifest - v0.3.1

> **Status:** exported 2026-07-10. Windows debug `.exe` built with Godot
> `4.6.stable`; release metadata (`export_presets.cfg`, Main Menu
> `VersionLabel`, `environment_setup.md`) is at `v0.3.1`.

## Artifact

- Path: `builds/Project_Prometheus_v0.3.1_debug.exe`
- Source commit: `c7ce311`
- Baked build stamp (`build_info.json`): version `0.3.1`, commit `c7ce311`,
  built_at `2026-07-10T05:41:42Z`
- Exported: `2026-07-10`
- Godot: `4.6.stable.official.89cea1439`
- Size: `101685192` bytes
- SHA-256: `ac4b079a5fdde815823f0c6c6fe883a1e23f59792fe66d4b761995bdb1205332`

The artifact is intentionally ignored by Git. v0.3.1 ships as **two files**:
the executable and the self-contained handbook
`AGENT/Docs/playtests/playtest_checklist_v0.3.1.md`. No `._sc_` marker; the log
lands in the OS user-data dir (`%APPDATA%`) and the startup BUILD STAMP's `log=`
line reports the exact path.

## Why v0.3.1

v0.3.1 is a **focused rerun** carrying the fixes made after the v0.3.0.d live
return, not a new feature build. The v0.3.0.d pass confirmed Suspend & Continue
on real hardware but failed the gamepad and display gates and rejected the
single-layer overlay look. This build narrows the tester pass to those fixes:

- `VAL-V030-GAMEPAD`: modal directional repeat in Settings/shared modals, the
  new keybind-capture focus guard, New Game modal focus containment, left-stick
  attack/Pair Up target cycling, and the slower/less-sensitive LT/RT trigger feel
  (handbook §1-§3); the New Game holdout still logs `V030-NG-FOCUS`.
- `VAL-V023-DISPLAY`: the maximized `Maximized (WxH)` readout fix and the
  one-axis windowed drag write-back hook, with `V030-DSP-TRACE` diagnostics
  (handbook §4).
- `[MRD-7]`: a debug-only F8 cycle now including the `stacked_perimeter`
  candidate the v0.3.0.d tester sketched, for the shipped-look pick (handbook §5).
- Suspend & Continue: a light regression check only — it already passed live on
  v0.3.0.d (handbook §6).

## What changed since v0.3.0.d

- **Release metadata moved to v0.3.1:** export preset name/path/product version,
  Main Menu label, and environment setup export commands all agree on `v0.3.1`;
  the release-metadata test passes 5/5.
- **Post-v0.3.0.d fixes are in the stamped source** (`c7ce311` and its parents on
  `v0.3.0-features`): modal focus repeat + containment (`0e46452`), the
  keybind-capture focus guard (`7a7a1ce`), display resize/readout hooks
  (`533734a`), and the MRD-7 `stacked_perimeter` overlay plus trigger tune
  (`2d1fc11`).
- **Temporary diagnostics are intentionally present:** `V030-NG-FOCUS` and
  `V030-DSP-TRACE` log lines, and the debug-only F8 overlay cycle, exist only to
  service this rerun and will be removed after the live pick.

## Known limitations carried into this build

- **This build is the validation vehicle.** Headless tests cover routing,
  persistence, and structure but cannot prove real controller feel, physical
  button labeling, Windows maximize behavior, or desktop rendering. Those checks
  stay open until the handbook passes on real hardware.
- **The one-axis drag write-back is a hypothesis fix.** v0.3.0.d showed no resize
  trace for bar-only one-axis edge drags; this build adds a root-Window
  `size_changed` listener on the theory it fires where the viewport signal did
  not. It is the item most likely to still need the log — §4 exists to prove it.
- **Non-Xbox controller labels are heuristic.** SDL normalizes button positions;
  the printed Nintendo/PlayStation-style label is based on the detected device
  name. A wrong label with correct input behavior is a cosmetic note, not an
  input-routing failure.
- **F8 overlay cycling and the diagnostic log lines are temporary.** They are not
  shipped features; do not file them as defects.
- **Debug build:** debug test aids remain available where intentionally exposed
  for playtesting. A non-debug/public release still needs the later release-gate
  cleanup.

## Verification

- Release-metadata test: PASS - export preset name/path/product version, Main
  Menu label, current checklist, and setup guide all agree at `v0.3.1`.
- Full source suite: PASS - all 69 suites green on the stamped commit `c7ce311`
  (pre-commit hook).
- check_docs: PASS - all documentation checks green.
- RNG usage guard: PASS - no unmarked engine-RNG use in non-test GDScript.
- Export: PASS - Windows debug `.exe` built headless; `res://build_info.json`
  packed (version `0.3.1`, commit `c7ce311`); SHA-256 + size recorded above.
- Manual validation still required: all live hardware/display checks are in
  `playtest_checklist_v0.3.1.md`.
