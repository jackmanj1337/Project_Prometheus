---
Role: dated
Type: playtest
Status: Exported - pending live Windows full feature smoke
Last verified: 2026-07-16
---

# v0.4.1 Windows Playtest Build

- Artifact: `builds/Project_Prometheus_v0.4.1_debug.exe`
- Source branch: `agent/codex/2026-07-14/v0.4.0-windows-build`
- Source commit (full and short):
  `66e197340609ace35896d2c08339bad19ac26e96` (`66e1973`)
- Source tree at export: clean at export invocation; Godot generated known
  disposable import-cache sidecars during export, which were removed afterward.
- Baked version: `0.4.1`
- Baked commit: `66e1973`
- Baked UTC timestamp: `2026-07-16T03:58:59Z`
- Godot version: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.4.1`
- Platform: Windows Desktop x86-64 debug, embedded PCK
- Size in bytes: `101846912`
- SHA-256: `59895ffb837b0da921c21b656efbeebcfc755f2a43c8614443651fc10efd7532`
- PE inspection result: `PE32+ executable (GUI) x86-64 (stripped to external
  PDB), for MS Windows, 12 sections`
- Automated test result: PASS - all 76 suites green.
- Documentation check result: PASS - all 31 checks green.
- RNG guard result: PASS - no unmarked engine-RNG use in non-test GDScript.
- Headless import/boot result: PASS - import completed and `test_boot` passed;
  no script or resource load error.
- Export result: PASS - Godot returned zero and produced the expected executable
  using a writable temporary XDG cache.

The executable is ignored by Git. Live Windows behavior is not proven by this
headless result; complete and return the full v0.4 feature checklist,
[`playtest_checklist_v0.4.1.md`](playtest_checklist_v0.4.1.md), with the original
matching `godot.log`.
