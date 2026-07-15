# Playtester Build Manifest - v0.1.4

## Artifact

- Path: `builds/Project_Prometheus_v0.1.4_debug.exe`
- Source commit: `a8ee66a0ed257b9fe24234e05b4818a0aea93fef`
- Source subject: `Defer boot scene transition`
- Exported: 2026-06-12 17:32 UTC
- Godot: `4.6.stable.official.89cea1439`
- Size: `101,199,464` bytes
- SHA-256:
  `b8aa878399b9315ab78496acaf0b24cc88dabda12d55c9fd09665f7a0dc4ee16`

The artifact is intentionally ignored by Git. Distribute the executable and
`AGENT/Docs/playtest_checklist_v0.1.4.md` together.

## Verification

- Full source suite: PASS, all 38 suites green.
- Export: PASS using the `Project Prometheus v0.1.4` Windows Desktop preset.
- Binary format: PASS, PEI x86-64 Windows GUI executable.
- Embedded metadata strings: PASS, `Project Prometheus`, `0.1.4`, and
  `v0.1.4` present.
- Development-file scan: PASS; no `AGENT`, `scripts/tests`, `scripts/tools`,
  or combat-preview screenshot paths found in the executable.
- Embedded-pack startup: PASS with the Linux Godot 4.6 runtime for five
  frames; the Boot scene opened without engine errors.

Wine is not installed in the development container, so the Windows wrapper
itself was not launched here. The first-launch and visual checks remain in the
playtester checklist.
