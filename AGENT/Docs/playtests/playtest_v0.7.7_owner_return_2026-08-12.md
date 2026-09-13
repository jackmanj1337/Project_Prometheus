---
Role: dated
---

# v0.7.7 Owner Playtest Return — ACCEPTED as the stable v0.7 release

Date: 2026-08-12  
Candidate: `agent/playtest-release-v0.7.7`  
Commit: `cfc7749fb85ff7cec5b57901d2601c522e10b5cd`  
Verdict: **ACCEPTED — v0.7.7 is the stable v0.7 release.**

## Evidence reviewed

The focused Windows return is preserved under `evidence/v0.7.7/raw/`. Every
returned log identifies version `0.7.7` and commit `cfc7749f`. Release and debug
runs both contain first-attempt `campaign_restored` followed by `node_launch` or
`node_resumed` for `v076_migration_fixture` version `2.0.0`.

The logs contain neither known rejection signature:

- `DataManager: save has no campaign package identity`
- `SaveData: prior campaign content could not be restored after validation`

No Godot error, script error, duplicate-signal, stuck-modal, input-leakage,
focus-loss, or package-activation error appears. Modal acquisition and release
events are balanced in the recorded smoke path.

## Acceptance scope

This focused return closes the cold-start Continue defect found in v0.7.6. The
rest of the v0.7.6 Windows/browser evidence carries forward because v0.7.7 made
only the narrow session-restoration repair, its regression coverage, and release
identity/checklist changes.

The accepted executable remains the artifact built from exact commit
`cfc7749fb85ff7cec5b57901d2601c522e10b5cd`. Promotion or evidence commits after
that point do not change the release-tag target.

## Lifecycle disposition

Acceptance authorizes promotion through:

`agent/playtest-release-v0.7.7` → `agent/stable-release` →
`agent/staging-area` → human-reviewed PR to `main`.

The release content must also be reconciled into `agent/integration` before the
v0.8 integration window proceeds.
