---
Role: dated
Type: playtest
Status: Candidate - awaiting native return
Last verified: 2026-09-06
---

# v0.7.18 Diagnostics-First Tester Candidate

This is the replacement candidate for the rejected v0.7.17 return. It includes
the six merged corrections, the regenerated migration/backup fixture chain, and
the diagnostics-first tester workflow.

- Source branch: `agent/playtest-release-v0.7.18`
- Source commit, product version, Godot version, and artifact hashes: recorded
  in the bundle `BUILD_INFO.json` and checked against the executable BUILD STAMP.
- Native return checklist: `PLAYTEST_CHECKLIST.md` from the tester bundle.

## Required candidate contents

The bundle must contain Windows release and debug executables, this build record,
the native checklist, the corrected Proving Grounds archive, the migration pack
fixtures, the regenerated campaign backup, and the pack/browser gate receipts.
The diagnostics ZIP is produced by the tester and returned separately.

## Release gates

The exact-HEAD full suite must be green before export. The source branch must be
this v0.7.18 release branch, and each executable BUILD STAMP must match the source
commit and version. Every shipped archive must pass its pack/import/launch gates,
and the assembled ZIP must verify its staged file hashes.

Linux/container evidence is supplemental. Promotion to stable/staging and release
tagging remain gated on the native Windows return; balance, difficulty, damage
curves, and pacing are out of scope for this round.
