---
Type: playtest
Status: Exported - pending live Windows smoke
Last verified: 2026-07-16
---

# v0.4.0 Windows Playtest Build

- Artifact: `builds/Project_Prometheus_v0.4.0_debug.exe`
- Source branch: `agent/codex/2026-07-14/v0.4.0-windows-build`
- Source commit (full and short):
  `b64ce3a42b8e18b2aa859cf7354625c20f0cb047` (`b64ce3a`)
- Source tree at export: clean at export invocation; Godot generated known ignored
  and disposable import-cache sidecars during export, which were removed afterward.
- Baked version: `0.4.0`
- Baked commit: `b64ce3a`
- Baked UTC timestamp: `2026-07-16T03:51:50Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.4.0`
- Platform: Windows Desktop x86-64 debug, embedded PCK
- Size in bytes: `101846912`
- SHA-256: `4edd0aaf0f448965d201966fbeb84decfa06ef7927279f9d11a97b5057a18bf7`
- PE inspection result: `PE32+ executable (GUI) x86-64 (stripped to external
  PDB), for MS Windows, 12 sections`
- Automated test result: PASS - all 76 suites green.
- Documentation check result: PASS - all 31 checks green.
- RNG guard result: PASS - no unmarked engine-RNG use in non-test GDScript.
- Headless import/boot result: PASS - import completed and `test_boot` passed;
  no script or resource load error.
- Export result and non-fatal warnings: PASS - Godot returned zero and produced
  the expected executable. A writable temporary XDG cache was used to avoid the
  known container cache-owner warning; no export error was present.

The executable is ignored by Git. Live Windows behavior is not proven by this
headless result; complete and return
[`playtest_checklist_v0.4.0_fix_rerun.md`](playtest_checklist_v0.4.0_fix_rerun.md) with the original
matching `godot.log`.
