---
Role: dated
Type: playtest
Status: Exported - pending live Windows and browser validation
Last verified: 2026-08-11
---

# v0.7.6 Tester Candidate

This candidate implements the approved campaign-library, platform-native transfer,
and direct same-package save-migration repairs. It is not an accepted stable release;
the accompanying bundle exists to collect the required Windows and browser evidence.

- Source branch: `agent/playtest-release-v0.7.6`
- Source commit: recorded per artifact in `artifact-manifest.json` and the bundle's
  `BUILD_INFO.json`, read back from the baked BUILD STAMP.
- Baked product version / preset: `0.7.6` / `Project Prometheus v0.7.6`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: `bash run_tests.sh` green on the exact exported HEAD (139 suites),
  recorded in `audit/check-receipts/Project_Prometheus-full.json`.

The bundle includes release and debug Windows executables, a Web export, two
install-checked versions of the same migration fixture, and a negative archive that
is deterministically refused with `no_playable_campaign`. Sizes, SHA-256 digests,
source commit/tree, build type, and read-back BUILD STAMP are generated from the
artifact manifests and bundle rather than transcribed here.

Use `playtest_checklist_v0.7.6.md`. Return the completed checklist and the full Godot
log directory; the native Windows and browser gates cannot be closed headlessly.
