---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-07-28
---

# v0.5.8 Windows Playtest Build

Focused replacement for rejected v0.5.7. The importer now accepts valid explicit
ZIP directory entries at and below the single package root while continuing to
reject root-level files.

- Artifact: `builds/v0.5.8-playtest/Project_Prometheus_v0.5.8.exe`
- Bundle: `Project_Prometheus_v0.5.8_playtest_bundle.zip`
- Source branch: `agent/playtest-release-v0.5.8-fixes`
- Source commit (built): `458e6be2a2b22a4fcb37ca069bc055fdb61bf450`
- Source tree: `83e5ef0da57a6af52db29301c98960d891f997f7`
- Baked version: `0.5.8`
- Baked commit: `458e6be2`
- Baked UTC timestamp: `2026-07-28T00:47:04Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.5.8`
- Automated tests: PASS - all 104 suites green at the exact exported source tree.
- Executable: `106060040` bytes, SHA-256
  `2cf2af15a2477d892baf13042422426ef7413730855becfa20ebc9cc53e8f20d`
- `two-map-skirmish-1.0.zip`: `4501` bytes, SHA-256
  `02ce10167db178cd3813b0766299f24b8fa19af30d4dafb683b025b3fa09455f`
- `branching-skirmish-1.0.zip`: `5167` bytes, SHA-256
  `c83924ce80e39b06ac3b347f6d11700fe4d40a063bdd340804519171ff8263e2`
- Export result: PASS - the canonical release export produced a PE32+ Windows
  x86-64 executable with embedded PCK. The baked version, commit, and timestamp
  were verified directly in the executable.
- Bundle contents: executable, checklist, this build record, `BUILD_INFO.json`,
  both campaign fixtures, and `SHA256SUMS.txt`.
- Bundle: `37067961` bytes, SHA-256
  `6ff1ff26dfc6f85e05a86dbae0e297a87d883939c83d61e15851a1bf430ba0a7`.

Live Windows validation remains pending. Complete and return
[`playtest_checklist_v0.5.8.md`](playtest_checklist_v0.5.8.md) with logs,
screenshots, and reproduction artifacts.
