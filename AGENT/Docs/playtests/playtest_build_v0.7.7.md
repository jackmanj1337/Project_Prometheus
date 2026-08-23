---
Role: dated
Type: playtest
Status: Exported - pending focused Windows validation
Last verified: 2026-08-12
---

# v0.7.7 Tester Candidate

This candidate is the v0.7.6 campaign-library, native-transfer, and direct-save-
migration candidate plus one narrow repair from its returned Windows evidence.
Cold-start save validation now restores the exact prior content session instead of
trying to select an empty saved-package identity; Continue therefore succeeds on its
first attempt from an exported build's inactive startup state.

- Source branch: `agent/playtest-release-v0.7.7`
- Source commit: recorded per artifact in `artifact-manifest.json` and the bundle's
  `BUILD_INFO.json`, read back from the baked BUILD STAMP.
- Baked product version / preset: `0.7.7` / `Project Prometheus v0.7.7`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: `bash run_tests.sh` green on the exact exported HEAD (139 suites),
  recorded in `audit/check-receipts/Project_Prometheus-full.json`.

The bundle includes release and debug Windows executables, a Web export, both
install-checked migration-fixture versions, and the no-playable negative archive.
Artifact sizes, SHA-256 digests, source commit/tree, build type, and BUILD STAMP are
generated from the manifests rather than transcribed here.

Use `playtest_checklist_v0.7.7.md`. Only the focused first-attempt Continue recheck is
required; the accepted portions of the v0.7.6 return remain evidence for this release
line.
