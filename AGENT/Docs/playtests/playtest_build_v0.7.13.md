---
Role: dated
Type: playtest
Status: Ready - Settings clipping replacement candidate
Last verified: 2026-08-28
---

# v0.7.13 Settings Clipping Replacement Candidate

This candidate replaces v0.7.12 after browser geometry and image review found clipped
slider values, keybinding descriptions, and footer controls in Settings. It retains the
v0.7.12 campaign-map, save, migration, recovery, backup, and restore scope.

- Source branch: `agent/playtest-release-v0.7.13-fixes`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.
- Baked product version / preset: `0.7.13` / `Project Prometheus v0.7.13`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Focused automated gate: Settings compact containment 68/68.
- Full gate: 154/154 suites.
- Browser gate: zero truncated bridge controls at 360x640 and 1280x720.

Use `playtest_checklist_v0.7.13.md`. Native Windows evidence remains authoritative for
process-level persistence, physical-controller focus/input, Windows GPU rendering,
Compact Settings presentation, and migration/recovery/backup/restore UI.
