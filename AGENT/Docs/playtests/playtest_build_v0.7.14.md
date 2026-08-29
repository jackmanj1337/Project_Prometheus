---
Role: dated
Type: playtest
Status: Ready - bundled free-roam schema replacement candidate
Last verified: 2026-08-29
---

# v0.7.14 Bundled Free-Roam Replacement Candidate

This candidate replaces rejected v0.7.13. That Windows return approved Compact Settings
containment, text readability, slider rendering, and keyboard input, then stopped when the
bundled free-roam archive was rejected because the campaign schema had lost its runtime
`traversal_mode` field. v0.7.14 restores that narrow schema contract and also carries the
already-integrated empty-profile save-import reachability repair.

- Source branch: `agent/playtest-release-v0.7.14`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.
- Baked product version / preset: `0.7.14` / `Project Prometheus v0.7.14`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Focused automated gate: campaign schema admits `linear` and `free_roam` and rejects typos.
- Full gate: 153/153 suites on the integrated schema repair.
- Browser gate: the exact 86,978-byte bundled free-roam ZIP imports with zero diagnostics,
  appears in New Game, and launches Chapter 1 Prep as `prometheus-proving-grounds` 0.1.0.

Use `playtest_checklist_v0.7.14.md`. Native Windows evidence remains authoritative for
process-level persistence, physical-controller focus/input, and the remaining campaign-map,
migration, recovery, backup, and restore UI checks that v0.7.13 could not reach.
