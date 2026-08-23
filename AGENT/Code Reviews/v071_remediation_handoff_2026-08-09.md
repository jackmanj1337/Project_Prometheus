---
Role: dated
---

# v0.7.1 remediation handoff — 2026-08-09

Status: Active — pack discovery implemented and green; campaign-resume atomicity next.

Last verified: 2026-08-09

Tracker: `V071-RETURN-TRIAGE-2026-08-09`

## Completed section

`V071-PACK-DISCOVERY-2026-08-09` is implemented on
`agent/from-integration/v071-pack-discovery`. `CampaignPackRegistry` now unwraps the
validated `entries` rows from registered map-registry documents while retaining the
legacy bare-array form. The New Game regression builds a registered-envelope fixture
and proves export -> preflight -> install -> discovery -> selection -> playable launch.
The targeted test passes 6/6 and the full 135-suite gate is green.

This section deliberately did not remove `res://data`; the replacement-pack lifecycle
must land before `IMPL-ZERO-CONTENT-EXPORT-GATE` removes compatibility content.

## Next section

Start `V071-CAMPAIGN-RESUME-ATOMICITY-2026-08-09` from current
`agent/integration`. Read the exact late-rejection evidence in
`AGENT/Code Reviews/code_review_2026-08-09.md`. Preserve the complete prior
`ContentSession` on every failure after package activation, and assert package identity,
registries, catalogues, and campaign position all roll back together.

Then continue in this order:

1. `V071-USERDATA-MIGRATION-ATOMICITY-2026-08-09`;
2. `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`, using the approved game-owned
   filename modal rather than another FileDialog interception hook;
3. `IMPL-ZERO-CONTENT-EXPORT-GATE`, only after replacement-pack lifecycle and export
   evidence remain green.

Keep frozen `agent/playtest-release-v0.7.1` at `0db30fd1` immutable. Implement from
integration feature branches and pair behavior changes with their GDD and roadmap
updates under DoD#1.
