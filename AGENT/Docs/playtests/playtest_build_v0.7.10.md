---
Role: dated
Type: playtest
Status: Ready - focused native-host round
Last verified: 2026-08-24
---

# v0.7.10 Tester Candidate

This candidate admits the runtime-supported `free_roam` traversal mode through the
pack-facing campaign schema and supplies a separately authored free-roam Proving Grounds
validation pack. It is intended to close the overworld evidence gap left by v0.7.9.

- Source branch: `agent/playtest-release-v0.7.9-fixes`
- Source commit: recorded in `BUILD_INFO.json` and read back from the baked BUILD STAMP.
- Baked product version / preset: `0.7.10` / `Project Prometheus v0.7.10`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: `bash run_tests.sh` green (148 suites); authored pack activates and
  validates 8/8 playable maps.

Use `playtest_checklist_v0.7.10.md`. The public Proving Grounds pack remains linear; the
bundle's free-roam variant exists only for this focused validation round.
