---
Type: playtest
Status: Exported - pending live Windows full feature smoke
Last verified: 2026-07-16
---

# v0.4.2 Windows Playtest Build

- Artifact: `builds/Project_Prometheus_v0.4.2_debug.exe`
- Source branch: `agent/codex/2026-07-14/v0.4.0-windows-build`
- Source commit (full and short):
  `58c6d7d794cc3c7a420390f73a8850dec13bc44f` (`58c6d7d`)
- Source tree at export: clean except the preserved untracked returned v0.4.1
  evidence folder; `AGENT/**` is excluded from the export. Godot-generated
  import sidecar churn was removed afterward.
- Baked version: `0.4.2`
- Baked commit: `58c6d7d`
- Baked UTC timestamp: `2026-07-16T17:18:16Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.4.2`
- Platform: Windows Desktop x86-64 debug, embedded PCK
- Size in bytes: `101847152`
- SHA-256: `22a553d8ab53e2ae95d740cdffd97aa63c102991ce4ae5e10b881232c98c262a`
- PE inspection result: `PE32+ executable (GUI) x86-64 (stripped to external
  PDB), for MS Windows, 12 sections`
- Automated test result: PASS - all 76 suites green.
- Documentation check result: PASS - all 31 checks green.
- RNG guard result: PASS - no unmarked engine-RNG use in non-test GDScript.
- Release metadata result: PASS - all 5 checks green.
- Export result: PASS - Godot returned zero and produced the expected executable
  using a writable temporary XDG cache.

The executable is ignored by Git. Live Windows behavior is not proven by this
headless result; complete and return
[`playtest_checklist_v0.4.2.md`](playtest_checklist_v0.4.2.md) with the original
matching `godot.log` and the requested victory-layout screenshots.
