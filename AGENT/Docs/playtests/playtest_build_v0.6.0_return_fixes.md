---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-08-02
---

# v0.6.0 Return-Fix Windows Candidate

This development export isolates the v0.6.0 return repairs that still require native
Windows evidence. It is not an accepted release and does not close the unresolved
responsive-window, HUD-attachment, save-provenance, or browser gates.

- Artifact: `builds/windows/Project_Prometheus/Project_Prometheus.exe`
- Artifact manifest: `builds/windows/Project_Prometheus/artifact-manifest.json`
- Source branch: `agent/v060-return-fixes-playtest`
- Source commit: `a450d93042ce326ba6770cbaebe0545b12725114`
- Source tree: `28861e5611e15f6247e9c297d8b742fa42acc315`
- Baked product version / preset: `0.6.0` / `Project Prometheus v0.6.0`
- Export mode: development
- Godot: `4.6.3.stable.official.7d41c59c4`
- Generated UTC: `2026-08-02T08:20:13.373830+00:00`
- Executable: `106127744` bytes
- SHA-256: `08bb4278372fbce700e4aa026b9cb6cf9fc115d06e462d6ebf9c4610dec5e75a`
- Automated gate: 118 suites green; `test_text_entry` 33/33,
  `test_transition_telemetry` 9/9, and `test_v060_registry_baseline` 3/3.

Development export mode does not produce independent baked-stamp extraction evidence;
the artifact manifest pins the exact source commit and tree. The live startup log must
still be returned so its BUILD STAMP can be compared with this record.

Use
[`playtest_checklist_v0.6.0_return_fixes.md`](playtest_checklist_v0.6.0_return_fixes.md).
Return the completed checklist and the entire Godot log bundle together.
