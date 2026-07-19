---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-07-19
---

# v0.5.2 Windows Playtest Build

- Artifact: `builds/Project_Prometheus_v0.5.2_debug.exe`
- Companion fixture: `builds/two-map-skirmish-1.0.zip`
- Source branch: `agent/playtest-release-v0.5-fixes`
- Source commit: `06e03861e3ce993fbf14899c3df05ab9d999b7fa`
- Baked version: `0.5.2`
- Baked commit: `06e0386`
- Baked UTC timestamp: `2026-07-19T02:08:57Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.5.2`
- Platform: Windows Desktop x86-64 debug, embedded PCK
- Executable size: `102168544` bytes
- Executable SHA-256: `76527c91872d666dde2cc73aedf6a96e4d438c696574067840f3571ae6e5d1d4`
- Fixture size: `4271` bytes
- Fixture SHA-256: `5b5ae637ff782b0b134355bbc409971e590cd1c09e3119a5303a96b3e330123e`
- PE inspection: `PE32+ executable (GUI) x86-64`, 12 sections
- Automated tests: PASS - all 103 suites green at exact source commit
- Documentation checks: PASS - all 40 checks green at exact source commit
- Release metadata: PASS - all 5 checks green
- GDScript format/lint and RNG guard: PASS
- Embedded stamp inspection: PASS - version, commit, and UTC timestamp found in executable
- Export result: PASS - Godot returned zero and produced the embedded-PCK executable

The exporter reported nonfatal cache/settings write errors because the container's
`/home/vscode/.cache/godot` is not writable. Packing completed, Godot returned zero,
the executable identity was measured, and its embedded stamp was inspected.

Live Windows behavior is not proven by headless export. Complete and return
[`playtest_checklist_v0.5.2.md`](playtest_checklist_v0.5.2.md) with its matching
original log and requested screenshots.
