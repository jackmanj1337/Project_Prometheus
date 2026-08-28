---
Role: dated
Type: playtest
Status: Ready - remediation validation candidate
Last verified: 2026-08-25
---

# v0.7.11 Tester Candidate

This candidate validates the rejected v0.7.10 round's remediation: return from a
cleared non-repeatable hub, campaign-map Save and Settings access, persisted Menu
Density, supported-width Main Menu text, and visible slider tracks/endcaps.

- Source branch: `agent/from-integration/slider-track-endcaps`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.
- Baked product version / preset: `0.7.11` / `Project Prometheus v0.7.11`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: `bash run_tests.sh` green (148 suites); focused overworld,
  SettingsManager, SettingsScreen, and responsive Main Menu suites green.
- Browser preflight: full Main Menu labels fit at 282, 360, 599, and 600 pixels;
  Menu Density is visible; slider trough/fill/endcaps render at 3840×2160.

Use `playtest_checklist_v0.7.11.md`. Native Windows evidence remains the approval
authority for save/restore, focus return, and slider-state legibility.
