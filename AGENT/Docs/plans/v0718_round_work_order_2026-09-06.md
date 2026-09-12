---
Role: dated
Type: plan
Status: Active — v0.7.18 playtest recut
Last verified: 2026-09-06
---

# v0.7.18 round work order

Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
Feature index: [Documentation Index](../INDEX.md)

The v0.7.17 Windows return rejected build `54c2e3e8` after a restore failure and
nine diagnostics-backed findings. The six corrective rows are now merged into
`agent/integration`; this order governs the recut and the final native pass.

## Source and dependency gate

- Product source: `agent/integration`, after the five V0717 fix merges, full suite
  green at the merged tip.
- Fixture/tooling source: container `agent/staging-area`, including the checked-in
  backup-fixture generator and corrected `campaign_backup_v2.zip`.
- Do not cut or tag until the corrected backup is included in the tester bundle,
  its pack fingerprints agree, and all six V0717 rows are at least in review.

## Recut sequence

1. Create `agent/playtest-release-v0.7.18` from the merged integration tip and
   record the exact source commit in the playtest build record.
2. Regenerate the migration pack archives and backup fixture from tracked source;
   never hand-edit the shipped ZIP. The backup must carry the v2 pack and matching
   save fingerprints.
3. Export release and debug Windows artifacts and the web artifact. Each export
   must have an exact source tree, BUILD STAMP, artifact manifest, size and SHA-256.
4. Run the pack/browser gates against the exact web source and retain their receipts.
5. Assemble the tester bundle with the corrected backup fixture, checklist,
   diagnostics evidence requirements, pack receipts, and supplemental browser
   evidence. Verify the final ZIP listing and SHA-256.
6. Run the final native Windows pass: 4K/windowed/fullscreen display checks,
   phase-banner smoke, compact Settings/keybind labels, actionable refusal text,
   restore against the corrected fixture, registry/concurrency path, and a
   playability smoke through the Proving Grounds campaign.

## Promotion gate

The Linux/container checks are preparation evidence, not native acceptance. A
Windows return must confirm the build stamp, display/GPU/window records, the
corrected Section 4 restore flow, and no new player-visible regression. Only an
accepted return may promote `agent/playtest-release-v0.7.18` to
`agent/stable-release`; only then may the accepted release enter
`agent/staging-area` for the human PR to `main`.

Balance tuning is out of scope. The tester's job is real-display, input,
performance, crash, restore, and playability evidence; the bundle's diagnostics
are the source for machine measurements.
