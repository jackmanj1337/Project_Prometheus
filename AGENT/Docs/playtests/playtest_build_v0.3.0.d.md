---
Role: dated
---

# Playtester Build Manifest - v0.3.0.d

> **Status:** exported 2026-07-09. Windows debug `.exe` built with Godot
> `4.6.stable`; release metadata (`export_presets.cfg`, Main Menu
> `VersionLabel`, `environment_setup.md`) is at `v0.3.0.d`.

## Artifact

- Path: `builds/Project_Prometheus_v0.3.0.d_debug.exe`
- Source commit: `e19ac9b`
- Baked build stamp (`build_info.json`): version `0.3.0.d`, commit `e19ac9b`,
  built_at `2026-07-09T15:55:07Z`
- Exported: `2026-07-09`
- Godot: `4.6.stable.official.89cea1439`
- Size: `101496496` bytes
- SHA-256: `cff6a6bcb67c8f7b58471b462d54bc8bfafa115112dea463bce244d5d7627efd`

The artifact is intentionally ignored by Git. v0.3.0.d ships as **two files**:
the executable and the self-contained handbook
`AGENT/Docs/playtests/playtest_checklist_v0.3.0.d.md`. No `._sc_` marker; the log
lands in the OS user-data dir (`%APPDATA%`) and the startup BUILD STAMP's `log=`
line reports the exact path.

## Why v0.3.0.d

v0.3.0.d is a **focused rerun** of v0.3.0, not a new feature build. The broad
v0.3.0 pass returned two live-only holdouts and a batch of recovery fixes that
need real-hardware confirmation. Rather than re-run the entire v0.3.0 handbook,
this build narrows the tester pass to the fixes and holdouts:

- `VAL-V030-GAMEPAD`: menu focus scroll, custom-menu repeat cadence, LT/RT
  trigger threshold, and multi-pad brand labels (handbook §1); plus the live-only
  New Game focus holdout with `V030-NG-FOCUS` diagnostics (handbook §2).
- Suspend & Continue: the 2026-07-09 fixes (DONE visuals, off-map Pair Up
  supports, blue-phase-only Suspend, restored turn counter, relaunch
  persistence) (handbook §3).
- `VAL-V023-DISPLAY` §1.6: one-axis windowed drag readout, maximize readout, and
  relaunch persistence with `V030-DSP-TRACE` diagnostics (handbook §4).
- `[MRD-7]`: a debug-only F8 cycle over `single_layer` / `border_through` /
  `stacked` shared-cell overlays for the tester to pick the shipped presentation
  (handbook §5).

## What changed since v0.3.0

- **Release metadata moved to v0.3.0.d:** export preset name/path/product
  version, Main Menu label, and environment setup export commands all agree on
  `v0.3.0.d`; the release-metadata test passes 5/5.
- **Recovery fixes are in the stamped source:** the suspend restore, gamepad/menu
  repeat, maximized resolution readout, and MRD overlay compose work landed on
  `v0.3.0-features` before this cut.
- **Temporary diagnostics are intentionally present:** `V030-NG-FOCUS` and
  `V030-DSP-TRACE` log lines, and the debug-only F8 overlay cycle, exist only to
  service this rerun and will be removed after the live pick.

## Known limitations carried into this build

- **This build is the validation vehicle.** Headless tests cover routing,
  persistence, and structure but cannot prove real controller feel, physical
  button labeling, Windows maximize behavior, or desktop rendering. Those checks
  stay open until the handbook passes on real hardware.
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
  Menu label, current checklist, and setup guide all agree at `v0.3.0.d`.
- Full source suite: PASS - all suites green on the stamped commit `e19ac9b`
  (pre-commit hook).
- check_docs: PASS - all documentation checks green.
- RNG usage guard: PASS - no unmarked engine-RNG use in non-test GDScript.
- Export: PASS - Windows debug `.exe` built headless; `res://build_info.json`
  packed (version `0.3.0.d`, commit `e19ac9b`); SHA-256 + size recorded above.
- Manual validation still required: all live hardware/display checks are in
  `playtest_checklist_v0.3.0.d.md`.
