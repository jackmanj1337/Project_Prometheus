---
Type: playtest
Status: Exported - pending live Windows campaign follow-up
Last verified: 2026-07-15
---

# v0.4.0 Campaign/Save Follow-up Windows Build

- Artifact: `builds/Project_Prometheus_v0.4.0_campaign_followup_debug.exe`
- Source branch: `agent/codex/2026-07-15/prep-save-followup`
- Source commit: `dd4f971e2f028286f5dac3929bfc7da7d8e8f3fa` (`dd4f971`)
- Baked version / commit / UTC timestamp: `0.4.0` / `dd4f971` /
  `2026-07-15T22:57:07Z`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Preset: `Project Prometheus v0.4.0`
- Platform: Windows Desktop x86-64 debug, embedded PCK
- Size: `102090960` bytes
- SHA-256: `522c5687572355506d019ee58452ef21f9cfd0f4fa00723d2cd881a42634a615`
- PE result: `PE32+ executable (GUI) x86-64 (stripped to external PDB), for
  MS Windows, 12 sections`
- Quiet export smoke: exit `0`, expected artifact present, size and hash above.
- Automated gates at source: 40 documentation checks, pinned format/lint over
  226 tracked GDScript files, and all 100 Godot suites pass.

The Linux environment has the Windows export templates but no Wine or Windows
desktop/controller surface. It proves export/identity only. Live behavior remains
`Pending validation` until the matching returned checklist, original `godot.log`,
platform/controller details, and requested screenshots are archived and triaged.
