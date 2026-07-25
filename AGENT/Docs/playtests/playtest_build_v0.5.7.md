---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-07-25
---

# v0.5.7 Windows Playtest Build

Focused Windows debug build for the v0.5.6 return: repeated branching Results state,
ordinary package-save validation, two-stage FileDialog Escape, 200% Results layout and
OptionButton borders, persistent controller hot-plug telemetry, expired resize tracing,
and a visibly distinct Ridge Pass fixture.

- Artifact: `builds/Project_Prometheus_v0.5.7_debug.exe`
- Bundle: `Project_Prometheus_v0.5.7_playtest_bundle.zip`
- Source branch: `agent/playtest-release-v0.5.7-fixes`
- Source commit (built): `34e2e60ca31be6dad4fd354b3a8d4b1d83f3b8ae`
- Source tree: `91cac222106b9b81011bcd5d975b1cfbee15e847`
- Baked version: `0.5.7`
- Baked commit: `34e2e60`
- Baked UTC timestamp: `2026-07-25T02:10:44Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.5.7`
- Automated tests: PASS - all 104 suites green before export.
- Executable: `102187528` bytes, SHA-256
  `beb68029218b6444f0b0059d5e71e56b4d9f5eb6f53c695f04d308b9b58377c5`
- `two-map-skirmish-1.0.zip`: `4501` bytes, SHA-256
  `02ce10167db178cd3813b0766299f24b8fa19af30d4dafb683b025b3fa09455f`
- `branching-skirmish-1.0.zip`: `5167` bytes, SHA-256
  `c83924ce80e39b06ac3b347f6d11700fe4d40a063bdd340804519171ff8263e2`
- Export result: PASS - `godot --headless --export-debug
  "Project Prometheus v0.5.7"` returned zero and produced a PE32+ Windows x86-64
  executable with embedded PCK. The baked version, commit, and timestamp were verified
  directly in the executable.
- Bundle contents: executable, checklist, this build record, `BUILD_INFO.json`, both
  campaign fixtures, and `SHA256SUMS.txt`.

Live Windows behavior remains pending. Complete and return
[`playtest_checklist_v0.5.7.md`](playtest_checklist_v0.5.7.md) with the requested logs,
screenshots, and reproduction artifacts.
