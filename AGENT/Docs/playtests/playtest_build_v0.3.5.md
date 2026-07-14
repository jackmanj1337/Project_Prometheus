---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-07-14
---

# Playtester Build Manifest - v0.3.5

## Artifact

- Path: `builds/Project_Prometheus_v0.3.5_debug.exe`
- Source commit: `47e29e4`
- Baked build stamp: version `0.3.5`, commit `47e29e4`, built at
  `2026-07-14T05:29:58Z`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Platform: Windows Desktop, x86-64 debug export, embedded PCK
- Size: `101839008` bytes
- SHA-256: `8e2adbb373c4348ac0b0287ae4f82d48d04cf4a781563097a3b40f661296e8ec`

The executable is intentionally ignored by Git. Deliver it with
[`playtest_checklist_v0.3.5.md`](playtest_checklist_v0.3.5.md).

## Scope

This narrow rerun validates two v0.3.4-return repairs:

- Action Menu rendered width shrinks immediately after a longer action list;
- Settings and Unit Details use one direction-aware focus-scroll owner without
  opposite-end jumps.

The LT/RT threshold and per-faction threat-view paths passed v0.3.4 and are not
part of this rerun.

## Verification

- Release metadata: PASS, 5/5.
- Full source suite: PASS, all 75 suites green.
- Documentation checks: PASS, all 31 checks green.
- RNG usage guard: PASS.
- Export: PASS; PE32+ x86-64 Windows GUI executable.
- Export emitted non-fatal cache/settings warnings because the container cannot
  write `/home/vscode/.cache/godot`; packing and artifact validation succeeded.
- Manual validation: pending; follow the v0.3.5 checklist on Windows.
