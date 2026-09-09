---
Role: dated
Type: code_review
Status: Draft - owner disposition required
Last verified: 2026-09-09
---

# v0.7.18 expanded Windows return — findings and disposition

## Executive summary

The expanded return is genuine native evidence for the prior 0.7.18 candidate:
0.7.18, source `6972b61b`, on Windows with Intel Graphics. The four diagnostics
archives open cleanly, their manifests agree on the build, and the returned
backup is cryptographically self-consistent. The migration follow-up also
contains successful v1 load, v2 migration, and v2 load records.

The return is **not accepted as native release evidence**. The returned
`PLAYTEST_CHECKLIST.md` is the pre-clarification checklist: it has no Section
3a Renewal table, and the return contains no Renewal measurements, screenshots,
or Continue no-replay evidence. Sections 1, 4, and 6 are also left unticked.
The package therefore cannot clear the native shared-effect architecture gate,
even though the supplied pack does contain the authored `Unit_05` Renewal
fixture.

One product-instrumentation defect was confirmed by the return: `LayoutAudit`
reported hidden descendants as overflowing. This is fixed in the recut candidate
by using tree visibility for the walk and dialog check, with hidden-screen
regression coverage in `test_diagnostics_layout.gd`. The existing
`V0717-LAYOUT-OVERFLOW-PREDICATE-2026-09-06` follow-up remains the source record.

The four native runs also emitted the Godot engine error
`Condition "len == 0" is true. Returning: FAILED` from
`core/crypto/hashing_context.cpp:53`. The recut candidate localizes and fixes
the confirmed application caller: empty diagnostic log bytes now use the
canonical empty SHA-256 value instead of calling `HashingContext.update()` with
zero bytes, with a zero-byte archive regression test. This remains recorded
under `V0717-DIAGNOSTICS-CHANNEL-BUDGET-2026-09-06`.

## Evidence reviewed

- `Incoming/Project_Prometheus_v0.7.18/PLAYTEST_CHECKLIST.md` and the complete
  `Incoming/Project_Prometheus_v0.7.18/v0.7.18 return/` directory.
- Four returned diagnostics archives:
  `Prometheus_diagnostics_0.7.18_20260909T015739.zip`,
  `020448.zip`, `020750.zip`, and `020914.zip`.
- Returned `godot.log`, diagnostics logs, four archive manifests, and all
  archive entry hashes.
- `campaign-backup-free-roam.zip`, its `backup.json`, user-state manifest,
  four saves, and the three embedded campaign packs.
- Candidate branch `agent/playtest-release-v0.7.18` at source
  `637ab88f78ba51cbe06674c2bf616c9c14bee41e`, including the clarified checklist,
  both return fixes, and their regression tests.
- Recut bundle `builds/tester/v0.7.18-final/Project_Prometheus_v0.7.18_tester_bundle.zip`,
  with 83 verified files and SHA-256
  `20e22ec36e9b7f39e56cc34b7a6bb0a6d4d5b8b135487a27cda3ca7bdce6dacc`.

The incoming directory is gitignored evidence and was not copied into the
repository.

## Verification performed

### Package identity and archive integrity

All four diagnostics ZIPs pass `unzip -t`. Each manifest reports format 2,
version 0.7.18, commit `6972b61b`, and channel error count 0. The engine error
counts are separate and truthful: 1, 2, 1, and 1 respectively. The second
archive's additional engine error is the expected manual `mid_map` slot-class
full message.

The native log reports Windows, Intel Graphics, and live window sizes including
1194x720, 1280x720, and fullscreen 1920x1009. Its build stamp is 0.7.18 /
`6972b61b`.

The recut Windows release and debug artifacts, web export, pack gate, and
supplemental browser gate all identify source `637ab88f`; the release bundle's
ZIP test is clean and its manifest records 83 staged files.

### Backup and pack consistency

`campaign-backup-free-roam.zip` contains:

- the Proving Grounds pack, `prometheus-proving-grounds` 0.1.0;
- migration fixture packs `v076_migration_fixture` 1.0.0 and 2.0.0; and
- a user-state manifest with four saves.

The SHA-256 values in `backup.json` match the extracted pack archives and the
user-state manifest byte-for-byte. All four saves identify the Proving Grounds
campaign and package. The separately returned Proving Grounds export contains
151 entries and its roster includes:

```text
unit_id: unit_05_cleric
unit_name: Unit_05
skills: renewal, miracle
```

This proves the required fixture was supplied; it does not prove that Renewal
was triggered or that Continue avoided replaying it.

### Migration and save evidence

The focused diagnostics run records the following successful path:

1. v1 save inspection/import initially becomes `disabled` with reason `missing`
   while its pack is absent.
2. After installation, `revalidate_slot` becomes `ready` and the imported save
   loads successfully against v2 content.
3. An active v1 session saves and loads `resume_battle` successfully.
4. The v2 session saves `resume_battle_migrated` successfully, and
   `migrate_save_into_slot` records `ready` with the v2 fingerprint.

The expanded evidence therefore supports the migration/save fixes for the
paths actually exercised. It does not satisfy the separate Proving Grounds
Renewal transaction gate.

### Playability extent

The native logs contain context for Proving Grounds nodes
`node_00_drill`, `node_01_rout`, `node_02_seize`, `node_03_boss`, and
`node_04_escape`. They do not contain a `node_05_defend` context or a returned
completed six-node campaign result. This is useful progress evidence, but it
is not the checklist's full 45-minute/playability closeout.

## Returned observations

| ID | Evidence | Disposition |
|---|---|---|
| V0718-RETURN-01 | Returned checklist has no Section 3a; no HP/phase table, Renewal records, screenshots, or Continue no-replay measurements. | Release blocker. Native architecture gate remains open. |
| V0718-RETURN-02 | Sections 1, 4, and 6 remain unticked; tester note says expected artifacts are missing and suggests a further Playwright pass. | Return incomplete. Do not infer a pass from the note or from automated evidence. |
| V0718-RETURN-03 | Backup manifest hashes match all three embedded packs and the user-state manifest; four saves identify Proving Grounds 0.1.0. | Pass for artifact integrity. |
| V0718-RETURN-04 | Focused diagnostics record v1 revalidation/load and v1→v2 migration/save/load outcomes as completed/ready. | Pass for the exercised migration path; retain the native revalidation result in the release record. |
| V0718-RETURN-05 | Native context reaches Proving Grounds nodes 00 through 04; no node 05 or completed six-node result is returned. | Incomplete playability evidence, not a proven gameplay defect. |
| V0718-RETURN-06 | `LayoutAudit` reports `/root/GameMap/BannerLayer/PhaseBanner/Panel/Label` while parked at `x=-viewport_width`, visible only through hidden ancestry. | Confirmed instrumentation false positive; fixed in candidate `637ab88f` with hidden-tree regression coverage. |
| V0718-RETURN-07 | Four native diagnostics runs report the empty-buffer `HashingContext` error; one run also reports a full manual `mid_map` slot class. | Empty-buffer caller localized and fixed in candidate `637ab88f`; the slot-class message remains an expected refusal, not an independently proven release blocker. |

## Decisions and next actions

1. Keep `V0718-ROUND-PREP-2026-09-06` in review. The candidate remains out of
   `agent/stable-release`, `agent/staging-area`, and release tagging.
2. Request a corrected native return using the actual recut checklist from the
   candidate bundle. The minimum return is the completed Section 3a table for
   `Unit_05`, including two eligible phases, suspend/Continue no-replay, and an
   explicit statement about enemy Renewal coverage, plus the required screenshots
   and build metadata.
3. The hidden-ancestor visibility case is now in the LayoutAudit probe and the
   candidate uses `is_visible_in_tree()` for the relevant checks.
4. The empty-buffer hash call is localized to the diagnostics return exporter
   and fixed with a production regression test; the fresh candidate and bundle
   gates pass against the new source.
5. Hand the recut bundle to the native tester using the clarified Section 3a
   checklist. Keep promotion, stable/staging merge, and release tagging blocked
   until the returned Renewal/suspend-Continue evidence is complete.

No product code was changed on this review branch; the two confirmed fixes were
implemented on their feature branches and merged into the recut candidate. The
optional manual-slot-full message was not changed because the return shows an
expected refusal with existing UI handling, not a confirmed bug.
