---
Role: dated
Type: playtest
Status: Exported - pending live Windows/controller validation
Last verified: 2026-07-13
---

# Playtester Build Manifest - v0.3.3

## Artifact

- Path: `builds/Project_Prometheus_v0.3.3_debug.exe`
- Source commit: `99fed3b`
- Baked build stamp: version `0.3.3`, commit `99fed3b`, built at
  `2026-07-13T23:14:40Z`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Platform: Windows Desktop, x86-64 debug export, embedded PCK
- Size: `101835216` bytes
- SHA-256: `fd7b40b8b77ccb7db2cc218324b83cc4432545a87077dea160b3a94293d795ba`

The executable is intentionally ignored by Git. Deliver it with the self-contained
[`playtest_checklist_v0.3.3.md`](playtest_checklist_v0.3.3.md).

## Scope

This focused rerun validates only the changes requested after v0.3.2:

- deliberate near-full LT/RT activation and slower equal repeat timing;
- three-row, viewport-clamped focus lookahead in Settings and Unit Details;
- accepted `dual_outline` as the fixed default, retained under Action Menu and
  Map Menu with their resolved movement/transient-overlay policies;
- removal of the temporary F8 overlay comparison control.

## Verification

- Release metadata test: PASS, 5/5.
- Full source suite on stamped commit: PASS, all 75 suites green.
- Documentation checks: PASS, all 31 checks green.
- RNG usage guard: PASS.
- Export: PASS; the artifact is a PE32+ x86-64 Windows GUI executable.
- Manual validation: pending; follow the v0.3.3 checklist on Windows with a real
  controller.

