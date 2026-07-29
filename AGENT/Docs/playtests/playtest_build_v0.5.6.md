---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-07-24
---

# v0.5.6 Windows Playtest Build

Windows debug build for the v0.5.5 returned-playtest repairs: package-catalogue
save validation ordering, long-list focus scrolling, Retry-after-Save branching,
two-stage FileDialog Escape, removal of the expired New Game trace, and a genuine
branching campaign fixture.

- Artifact: `builds/Project_Prometheus_v0.5.6_debug.exe`
- Bundle: `Project_Prometheus_v0.5.6_playtest_bundle.zip`
- Source branch: `agent/playtest-release-v0.5.5-fixes`
- Source commit (built): `e7ee9f5704e3a303680f52deac495e7a150c4a02`
- Source tree: `7978fbe415b2f5fd0d0bed9e6efda9820b0b29a1`
- Baked version: `0.5.6`
- Baked commit: `e7ee9f5`
- Baked UTC timestamp: `2026-07-24T17:54:53Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.5.6`
- Automated tests: PASS - all 104 suites green before export.
- Executable size: `102185816` bytes
- Executable SHA-256: `56b1d55fe971666584319e801d7048f41e22a0945f5f84e986d669200903085e`
- `two-map-skirmish-1.0.zip`: `4271` bytes, SHA-256
  `5b5ae637ff782b0b134355bbc409971e590cd1c09e3119a5303a96b3e330123e`
- `branching-skirmish-1.0.zip`: `4340` bytes, SHA-256
  `aa0074ed679477206a9a13d50839af82e47aeb15a0cde971a260688c94810360`
- Export result: PASS - `godot --headless --export-debug
  "Project Prometheus v0.5.6"` returned zero and produced the embedded-PCK
  Windows x86-64 debug executable.
- Bundle contents: executable, focused checklist, this build record, baked
  `BUILD_INFO.json`, both importable campaign fixtures, and `SHA256SUMS.txt`.

Live Windows behavior remains pending. Complete and return
[`playtest_checklist_v0.5.6.md`](playtest_checklist_v0.5.6.md) with the requested
logs, screenshots, and reproduction artifacts.
