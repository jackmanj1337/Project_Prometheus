---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-07-17
---

# v0.5.1 Windows Playtest Build

- Artifact: `builds/Project_Prometheus_v0.5.1_debug.exe`
- Companion fixture: `builds/two-map-skirmish-1.0.zip`
- Source branch: `agent/playtest-release-v0.5-fixes`
- Source commit: `d96d035`
- Baked version: `0.5.1`
- Baked commit: `d96d035`
- Baked UTC timestamp: `2026-07-17T04:32:08Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.5.1`
- Platform: Windows Desktop x86-64 debug, embedded PCK
- Executable size: `102162400` bytes
- Executable SHA-256: `44a11c6a86cae807547a54f72fb16a3bff4610270a3bd3e880c7e2abc778c6fc`
- Fixture size: `3652` bytes
- Fixture SHA-256: `09737619bc15403d923d9b72ca1039cb157325f5cbca57867498b57a39abbfff`
- PE inspection: `PE32+ executable (GUI) x86-64`, 12 sections
- Automated tests: PASS - all 103 suites green
- Documentation checks: PASS - all 40 checks green
- Release metadata: PASS - all 5 checks green
- GDScript format/lint, RNG guard, analyzer, and scene integrity: PASS
- Export result: PASS - Godot returned zero and produced the expected embedded-PCK executable

Live Windows behavior is not proven by headless export. Complete and return
[`playtest_checklist_v0.5.1.md`](playtest_checklist_v0.5.1.md) with its matching
original log and requested screenshots.
