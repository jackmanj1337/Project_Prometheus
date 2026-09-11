---
Role: dated
Type: playtest
Status: Candidate - awaiting native return
Last verified: 2026-09-11
---

# v0.7.19 Windows Tester Candidate

This candidate is cut from the current integration line after the Campaign
Library reconciliation at `8a4d1b32`. It carries the current Pack 0 Proving
Grounds source at `0ed6143f`, regenerated pack archives and migration/backup
fixtures, and the browser gates bound to the exact web export.

- Source branch: `agent/playtest-release-v0.7.19`
- Source commit, product version, Godot version, and artifact hashes: recorded
  in the bundle `BUILD_INFO.json`, artifact manifests, and `SHA256SUMS.txt`.
- Native return checklist: `PLAYTEST_CHECKLIST.md` from the tester bundle.

## Required candidate contents

The bundle contains Windows release and debug executables, this build record,
the native checklist, the regenerated Proving Grounds archive, migration v1/v2
archives, the corrected campaign backup and tester fixtures, pack/import/launch
gate receipts, supplemental browser evidence, and source/hash manifests.

## Release gates

The exact-HEAD full suite must be green before export. Each executable and the
web export must identify this source commit and version. Every shipped archive
must pass its pack/import/launch gate, and the assembled ZIP must verify its
staged file hashes and integrity.

Linux/container and browser evidence are supplemental. Native Windows display,
GPU, input, accessibility, restore, and playability acceptance remains pending;
this candidate is not promoted to stable/staging and has no release tag.
