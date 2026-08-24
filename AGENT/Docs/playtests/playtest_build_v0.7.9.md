---
Role: dated
Type: playtest
Status: Ready - focused disposition bundle
Last verified: 2026-08-24
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

Use `playtest_checklist_v0.7.9.md`. It concentrates on the remaining narrow-layout
disposition; accepted activation, controller, battle, and save observations are not repeated.

**Focused recut 2026-08-24:** the executable and source commit remain byte-for-byte the
accepted v0.7.9 candidate. Only bundle documents and generated bundle metadata changed.
The checklist now asks for the unresolved narrow-layout disposition and records why an
authored free-roam check cannot be run against this build: its exported campaign schema
rejects `traversal_mode` even though the runtime model understands it. No invalid test pack
is shipped as a workaround.
