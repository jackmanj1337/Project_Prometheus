---
Role: dated
Type: playtest
Status: Exported - owner-accepted live pass
Last verified: 2026-07-14
---

# Playtester Build Manifest - v0.3.6

## Artifact

- Path: `builds/Project_Prometheus_v0.3.6_debug.exe`
- Source commit: `16ec845`
- Baked build stamp: version `0.3.6`, commit `16ec845`, built at
  `2026-07-14T06:02:12Z`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Platform: Windows Desktop, x86-64 debug export, embedded PCK
- Size: `101840736` bytes
- SHA-256: `0695aaa733dc204e2398effa1cfb8705d7f46482aa3a842fc234bb67fad325c6`

The executable is intentionally ignored by Git. Deliver it with
[`playtest_checklist_v0.3.6.md`](playtest_checklist_v0.3.6.md).

## Scope

This narrow rerun validates the v0.3.5-return repairs:

- Action Menu shrink-wraps both rendered axes and reserves scaled ornament-safe
  label space;
- Settings resolves the actual visual row, coalesces deferred corrections, and
  reveals lookahead only when it lies outside the viewport.

## Verification

- Release metadata: PASS, 5/5.
- Full source suite: PASS, all 75 suites green.
- Documentation checks: PASS, all 31 checks green.
- RNG usage guard: PASS.
- Export: PASS; PE32+ x86-64 Windows GUI executable.
- Export emitted non-fatal cache/editor-settings warnings because the container
  cannot write `/home/vscode/.cache/godot`; packing and artifact validation
  succeeded.
- Manual validation: PASS by returned checklist; all behavior boxes passed.
  Build metadata, log, and requested screenshots were not returned, so the
  result is owner-accepted rather than a complete evidence package. Visual
  polish is deferred to `UI-INSPECTION`.
