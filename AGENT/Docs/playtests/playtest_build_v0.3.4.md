---
Type: playtest
Status: Exported - pending live Windows/controller validation
Last verified: 2026-07-14
---

# Playtester Build Manifest - v0.3.4

## Artifact

- Path: `builds/Project_Prometheus_v0.3.4_debug.exe`
- Source commit: `7d2b379`
- Baked build stamp: version `0.3.4`, commit `7d2b379`, built at
  `2026-07-14T00:22:24Z`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Platform: Windows Desktop, x86-64 debug export, embedded PCK
- Size: `101838080` bytes
- SHA-256: `195c13cf6702d1336850c90a228fdeb4b9ca1e565e9ddf9021fe726d65290364`

The executable is intentionally ignored by Git. Deliver it with
[`playtest_checklist_v0.3.4.md`](playtest_checklist_v0.3.4.md).

## Scope

This focused rerun validates four v0.3.3-return repairs:

- threshold-owned LT/RT zoom without raw-axis double consumption;
- independent per-controlling-faction threat views and suspend persistence;
- content-driven Action Menu width at every supported Menu Scale;
- mixed-height visual-row focus lookahead.

## Verification

- Release metadata: PASS, 5/5.
- Full source suite: PASS, all 75 suites green.
- Documentation checks: PASS, all 31 checks green.
- RNG usage guard: PASS.
- Export: PASS; PE32+ x86-64 Windows GUI executable.
- Export emitted non-fatal cache/settings warnings because the container cannot
  write `/home/vscode/.cache/godot`; packing and artifact validation succeeded.
- Manual validation: pending; follow the v0.3.4 checklist on Windows.
