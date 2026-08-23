---
Role: topic
Type: governance
Status: Enforced
Last verified: 2026-07-16
---

# Release Version Numbering

Project Prometheus playtest releases use `vMAJOR.FEATURE.FIX`.

Release-fix work branches use the sibling form
`agent/playtest-release-vMAJOR.FEATURE-fixes` and branch explicitly from
`origin/agent/playtest-release`. A slash form such as
`agent/playtest-release/v0.5-fixes` is invalid while the lifecycle branch
`agent/playtest-release` exists because Git refs cannot be both a branch and a
directory prefix.

- `MAJOR` is the primary release marker. It advances when the planned feature
  set for that primary release has been implemented and accepted. Before that
  milestone, releases remain in major version `0`.
- `FEATURE` advances when intentionally added feature scope enters a release.
- `FIX` advances for bug fixes, tester-comment responses, and corrections to an
  existing feature's implementation. It resets to `0` when `FEATURE` advances.

Examples: a feature-bearing release after v0.4.2 is v0.5.0; a tester-driven fix
to that feature set is v0.5.1. Version identity must agree across the export
preset, executable name, Main Menu label, checklist, build manifest, and BUILD
STAMP. `scripts/tests/test_release_metadata.gd` enforces that alignment.
Before export, `scripts/tools/prepare_build.sh` also requires the matching
playtest build record's `Source branch` to equal the checked-out branch.
