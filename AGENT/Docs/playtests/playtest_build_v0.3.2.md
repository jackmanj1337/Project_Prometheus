---
Role: dated
---

# Playtester Build Manifest - v0.3.2

Status: Built - awaiting focused live rerun
Last verified: 2026-07-12

## Artifact

- Path: `builds/Project_Prometheus_v0.3.2_debug.exe`
- Size: `101780192` bytes
- SHA-256: `7059cb2af3bc7d9de0c2bdfc3d25f76a39fc55be4a8f41962202f859162c7838`
- Source commit baked into startup stamp: `8340318`
- Built at (UTC): `2026-07-12T22:52:52Z`
- Godot: `4.6.3.stable.official.7d41c59c4`

The executable is intentionally ignored by Git. Deliver it with
`playtest_checklist_v0.3.2.md`; the checklist contains the matching PowerShell
hash command and the focused return requirements.

## Scope

This rerun contains only the v0.3.1 return fixes and their supporting tests:

- Slower menu repeat and constant-cadence LT/RT zoom.
- Popup focus standdown and neutral latch on close.
- Character-sheet View Support/View Lead traversal and selection scrolling.
- Resize settle-then-persist plus missed-size-event polling.
- MRD-7 `dual_outline` as the fifth debug F8 candidate.

The parallel v0.4 registry foundation and MenuScale theme fix were explicitly
reverted on the build branch before metadata was cut. Development docs, tests,
and tools remain excluded by the export preset.

## Verification

- Documentation checks: passed, 27/27.
- RNG usage guard: passed.
- Full suite: passed, 69 suites.
- Release metadata test: passed, 5/5.
- Windows debug export: passed after restoring the local Godot 4.6.3 template
  directory alias (`4.6.3.stable` -> installed `4.6.3-stable`).

