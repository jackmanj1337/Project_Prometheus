---
Type: playtest
Status: Exported - pending live Windows smoke
Last verified: 2026-07-14
---

# v0.4.0 Windows Playtest Build

- Artifact: `builds/Project_Prometheus_v0.4.0_debug.exe`
- Source branch: `agent/codex/2026-07-14/v0.4.0-windows-build`
- Source commit (full and short):
  `d12eb337cf1bed4dd7e89eaa4c6445a80ad5d8a2` (`d12eb33`)
- Source tree at export: clean at export invocation; Godot generated known ignored
  and disposable import-cache sidecars during export, which were removed afterward.
- Baked version: `0.4.0`
- Baked commit: `d12eb33`
- Baked UTC timestamp: `2026-07-14T07:01:49Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.4.0`
- Platform: Windows Desktop x86-64 debug, embedded PCK
- Size in bytes: `101840832`
- SHA-256: `651bc28deca99724bef1a7a438350defc47fb6cdebd479050d4ad8140cc326a2`
- PE inspection result: `PE32+ executable (GUI) x86-64 (stripped to external
  PDB), for MS Windows, 12 sections`
- Automated test result: PASS - all 75 suites green.
- Documentation check result: PASS - all 31 checks green.
- RNG guard result: PASS - no unmarked engine-RNG use in non-test GDScript.
- Headless import/boot result: PASS - import completed and `test_boot` passed;
  no script or resource load error. Godot regenerated missing `.uid` sidecars as
  non-fatal cache warnings.
- Export result and non-fatal warnings: PASS - Godot returned zero and produced
  the expected executable. The only warnings were the same missing `.uid`
  sidecar regeneration messages; no export error was present.

The executable is ignored by Git. Live Windows behavior is not proven by this
headless result; complete and return
[`playtest_checklist_v0.4.0.md`](playtest_checklist_v0.4.0.md) with the original
matching `godot.log`.
