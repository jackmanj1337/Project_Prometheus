---
Role: dated
Type: playtest
Status: Exported - pending live Windows campaign test
Last verified: 2026-07-15
---

# v0.4.0 Proving Grounds Campaign Test Build

- Artifact: `builds/Project_Prometheus_v0.4.0_campaign_test_debug.exe`
- Source branch: `agent/codex/2026-07-15/prep-save-followup`
- Source commit: `202309e193cb44360901e1caaf694f0d68e40324` (`202309e`)
- Source tree at export: clean; export generated the now-tracked
  `scripts/tests/test_prep_screen.gd.uid` sidecar afterward.
- Baked version / commit / UTC timestamp: `0.4.0` / `202309e` /
  `2026-07-15T06:43:12Z`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.4.0`
- Platform: Windows Desktop x86-64 debug, embedded PCK
- Size: `101896472` bytes
- SHA-256: `4a10ba8a833746a95f24f361242da61566f2cd2ace3ed8edb4f6e26993e68920`
- PE result: `PE32+ executable (GUI) x86-64 (stripped to external PDB), for
  MS Windows, 12 sections`
- Automated gates: all 82 suites, all 31 documentation checks, and the RNG
  guard pass.
- Export: Godot returned zero and produced the expected executable. The known
  unwritable `/home/vscode/.cache/godot` editor-cache warnings were non-fatal;
  no resource, script, packing, or PE-output failure occurred.

This is a focused campaign test artifact, not a new release version. Live
Windows behavior remains unproven until the matching checklist and `godot.log`
return.
