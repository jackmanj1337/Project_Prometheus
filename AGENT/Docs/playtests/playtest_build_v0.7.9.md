---
Role: dated
Type: playtest
Status: Ready - replacement native-host round
Last verified: 2026-08-22
---

# v0.7.9 Tester Candidate

This replacement candidate fixes the v0.7.8 pack-activation failure. Campaign-variable
definitions now survive export with typed defaults, the supplied Proving Grounds pack
declares its campaign-day variable, and the exported-registry gate resolves and verifies
the current Windows preset instead of silently testing a stale preset.

- Source branch: `agent/playtest-release-v0.7.9-fixes`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.
- Baked product version / preset: `0.7.9` / `Project Prometheus v0.7.9`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: `bash run_tests.sh` green (148 suites); exported registry gate green.

Use `playtest_checklist_v0.7.9.md`. It concentrates on pack activation and the v0.7.8
items that were blocked or incomplete; accepted v0.7.8 observations are not repeated.
