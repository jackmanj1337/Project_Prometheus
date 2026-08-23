---
Role: dated
---

# Playtester Build Manifest - v0.3.0

> **Status:** exported 2026-07-08. Windows debug `.exe` built with Godot
> `4.6.stable`; release metadata (`export_presets.cfg`, Main Menu
> `VersionLabel`, `environment_setup.md`) is at `v0.3.0`.

## Artifact

- Path: `builds/Project_Prometheus_v0.3.0_debug.exe`
- Source commit: `7b23412`
- Baked build stamp (`build_info.json`): version `0.3.0`, commit `7b23412`,
  built_at `2026-07-08T07:02:14Z`
- Exported: `2026-07-08`
- Godot: `4.6.stable.official.89cea1439`
- Size: `101406640` bytes
- SHA-256: `d003060b300e28ab8e7a0e94234505ef17f62562b51ac49b937de66f1222c5da`

The artifact is intentionally ignored by Git. v0.3.0 ships as **two files**: the
executable and the self-contained handbook
`AGENT/Docs/playtests/playtest_checklist_v0.3.0.md`. No `._sc_` marker; the log
lands in the OS user-data dir (`%APPDATA%`) and the startup BUILD STAMP's `log=`
line reports the exact path.

## Why v0.3.0

v0.3.0 is the first feature playtest build after the v0.2.x display reruns. It
combines the completed v0.3.0 input work with the remaining display close-out so
testers can validate the full player-facing surface in one pass:

- `VAL-V030-GAMEPAD`: real controller mapping, left-stick repeat/deadzone feel,
  held-trigger zoom feel, menu focus comfort, device labels, and visual overlap.
- Input Mode and prompt swapping: Settings `Input Mode`, Auto/device switching,
  focus updates, and live keyboard/controller prompt refresh.
- Key rebinding: InputMap-derived rows, capture/stage/apply flow, conflict
  blocking, clear/revert/reset, and persistence.
- Suspend & Continue: mid-map save/resume across map state, RNG state, Pair Up,
  and watch-set markers.
- Map readability: threat/watch overlays, range peek, path arrows, and terrain
  dimming.
- Combat hit feel: default true-hit roll behavior.
- `VAL-V023-DISPLAY` section 1.6: custom windowed size readout, Windows maximize
  policy, and reactive Settings re-centering.

## What changed since v0.2.9

- **Release metadata moved to v0.3.0:** export preset, Windows product version,
  Main Menu label, environment setup commands, and release-metadata test now
  agree on `v0.3.0`.
- **Tester handbook completed for the broad v0.3.0 pass:** the checklist now
  includes explicit feature-sweep coverage plus a high-attention regression
  matrix, so testers have both "what to test" and "how best to test it" in one
  document.
- **Carried blocker fixes are in the stamped source commit:** fresh maps seed
  `RngService` before Retry snapshots, Settings changes refresh input mode
  promptly, and keybind rows derive from the live `InputMap` instead of a closed
  hand-maintained list.

## Known limitations carried into this build

- **This build is the validation vehicle.** Headless tests cover routing,
  persistence, and structural behavior, but cannot prove real controller feel,
  physical button labeling, Windows maximize behavior, or desktop rendering.
  Those checks stay open until the handbook passes on real hardware.
- **Non-Xbox controller labels are heuristic.** Godot/SDL normalizes button
  positions; the game prints Nintendo/PlayStation-style labels based on the
  detected device name. A wrong printed label with correct input behavior is a
  cosmetic note, not an input routing failure.
- **Aspect-ratio / black-bars policy is deferred.** The v0.3.0 display check is
  limited to the section 1.6 windowed sizing/maximize fixes. Broader Steam Deck,
  mobile, or non-16:9 viewport policy remains routed to `UI-VIEWPORT-ASPECT`.
- **Debug build:** debug test aids remain available where intentionally exposed
  for playtesting. A non-debug/public release still needs the later release-gate
  cleanup.

## Verification

- Release-metadata test: PASS - export preset name/path/product version, Main
  Menu label, current checklist, and setup guide all agree at `v0.3.0`.
- Full source suite: PASS - 66 suites green.
- check_docs: PASS - 26 documentation checks green.
- RNG usage guard: PASS - no unmarked engine-RNG use in non-test GDScript.
- Export: PASS - Windows debug `.exe` built headless; `res://build_info.json`
  packed (version `0.3.0`, commit `7b23412`); SHA-256 + size recorded above.
- Manual validation still required: all live hardware/display checks are in
  `playtest_checklist_v0.3.0.md`, especially Parts I, VII, and VIII §12.2.
