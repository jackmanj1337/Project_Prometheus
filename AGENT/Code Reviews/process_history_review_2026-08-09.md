---
Role: dated
---

# Process & History Review — 2026-08-09

> **Pillar:** 5 — Process & History
> **Snapshot:** `agent/integration` at `41c0e5fc1116a9a01aed3afc48dbc92f021d018d`
> **Previous review:** `AGENT/Code Reviews/process_history_review_2026-07-15.md`

**Score:** 7/10

## Executive summary

Release and playtest evidence is strong, commit subjects are specific, and the new
claim ledger removes July's ambiguity between session narrative and commit ownership.
Process health nevertheless falls from 8/10 to 7/10 because three governance seams
still require manual rescue: recent runtime slices do not consistently pair behavior,
GDD and roadmap in one commit; four live session notes are absent from the index; and a
manual audit removed 82 of 143 path claims because no gate enforces claim reality. None
of these findings changes or blocks frozen v0.7.1.

## Sample statement

Read the latest ten sessions in full (2026-08-06 21:14 through 2026-08-08 19:16),
plus stratified July 30 Light/Dark and FE-numeric sessions, the August 2 v0.6.0
return/root-cause pass, the August 4 claim-ledger migration, and the August 7 path-claim
audit. Examined the decision index, all three prior process reports, current pillar
reports, first-parent history, and subject/stat data for all 600 non-merge commits in
`08b3b5c2..41c0e5fc`. Detailed DoD pairing sampled ten implementation,
infrastructure, evidence and planning commits. Measurements stop at the pinned source.

## Workflow adherence

### DoD#1 — Medium — same-commit pairing remains inconsistent

The latest sprite chain separates behavior from owner documentation. `3d718f08`
changes only `SpriteSheetFramesBuilder.gd` plus tests; `222b79e4` changes the same
runtime/test pair; and `cb32da10` changes `Unit.gd`, a new resolver and tests. None
changes a numbered GDD or `GDD_10_Roadmap.md`. The later handoff accurately records the
completed seam, but that is not the same-commit contract. `6b5cce49` updates
`GDD_01_Data_Contracts.md` for unresolved-id behavior but omits the roadmap. This
repeats July's roadmap miss: the rule is understood but unreliable when implementation
and closeout are split. `[CROSS]`

### DoD#2 — pass

No sampled mechanical rule landed as unenforced prose. Combat-feedback decisions use
the existing typed register/index checks, while the session-claim ownership and
cross-line infrastructure rules landed with guards. This report ratifies no new rule;
follow-up recommendations remain proposals for owner review.

### Session discipline — Medium

`CLAIMS.tsv` cleanly fixes the prior commit-to-note ambiguity, and the August 7 audit
records the claim checker passing on every branch with unmerged commits
(`2026-08-07-16-57-03Z-claim-audit-and-v070-11-handoff.md:58-64`). Four live notes at
the pin have no `INDEX.md` link: `2026-07-11d.md`, `2026-07-11e.md`,
`2026-07-30-12-00-00Z-light-dark-tomes.md`, and
`2026-07-30-12-30-00Z-fe-numeric-audit.md`. The first pair arrived through an archive
merge; the second pair are normal typed notes. This proves note/index integrity is not
mechanically complete.

### Commit granularity — pass with evidence exceptions

The 600 non-merge commits have median textual churn 49.5 lines and mean 435.6. Sixteen
exceed a 1,000-line threshold, but the two extremes are evidence preservation
(`05bfdc54`, 63,777 lines; `8020baa2`, 63,255), not batched implementation. No WIP,
“misc”, or context-free “fixes” subject appears in the latest 40 commits.

## Git hygiene

- Messages are specific and outcome-oriented; merge subjects identify their slice.
- Latest implementation generally uses feature branches and descriptive no-FF merges.
- Two owner-walk sessions commit directly to `agent/integration`; their notes explicitly
  record this (`2026-08-08-01-40-24Z...:3-9` and
  `2026-08-08-03-41-56Z...:3-10`). This is a Low consistency risk against the stated
  feature-branch workflow, even though the destination is an allowed `agent/**` ref.
- Sampled commits retain human authorship and AI trailers.

## Decision traceability

| Decision | Code | Docs | Status |
|---|---|---|---|
| DOC-001 / D-C | Governance boundary | Yes | Bidirectional supersession is explicit. |
| DOC-011 | Yes | Yes | Documentation checks remain visible locally and in CI. |
| RNG-2 | Yes | Yes | **Fixed since July:** the index now names Retry, suspend, rewind and unified mid-map persistence and says Implemented. |
| OPEN-4 | Yes | Yes | EXP authority is indexed as Implemented and linked to campaign rules. |
| OPEN-11 | Partly superseded | Stale risk | Still says “revisit once UI-scale setting exists” after scale controls exist; reconcile with the Documentation pillar. `[CROSS]` |
| SET-014 | Not yet | Yes | Correctly remains Planned under `REL-WEB-DEMO`. |

No sampled Ratified/Implemented decision is absent from both code and docs. The
decision index's controlled two-axis vocabulary is internally consistent.

## Process effectiveness

### Recurring defect classes

The dominant class is **boundary validation stopping one call too early**. The v0.6.0
adapter fixture passed while runtime activation deleted occupancy policy because the
test stopped before `OccupancyService.place()` (`playtest_v0.6.0_root_cause_review_2026-08-02.md`,
V060-02). The current Code pillar finds the same shape in campaign resume and failed
user-data migration. The v0.7.0 unresolved-id incident then produced roughly 3,200
errors because pack skill references were not covered at activation
(`2026-08-07-16-57-03Z...:69-75`). Integration tests need to cross the final consumer
and rollback boundary, not merely validate an adapter or serializer. `[CROSS]`

A second recurring class is **responsive/native behavior escaping headless coverage**:
v0.6.0 returned FileDialog focus/Escape and resize/scale failures, while the
Documentation pillar still finds the native Escape contract overstated. Windows visual
gates remain necessary; browser/headless success is not native acceptance.

### Trends and repeated rules

Process scores are **8/10 (June 14) → 7/10 (July 5) → 8/10 (July 15) → 7/10 now**:
flat-to-volatile. DoD#1 is the only repeated rule violation. Session-note indexing
regressed from July's perfect measured set, although commit ownership is stronger.

The clearest coordination rework is the August 7 claim audit: 143 claims contained only
22 active entries; it released 40 reservations, removed six phantoms, and reduced the
set to 61, making independently workable band plans rise from 1 to 8
(`2026-08-07-16-57-03Z...:16-31`). Its first pass was redone because the local tracker
was 26 commits behind (`:34-38`), and the note confirms no hook or CI check enforces
`claimed_paths` (`:40-47`).

## Tooling and workflow recommendations

| Priority | Recommendation | Evidence | Effort |
|---|---|---|---:|
| 1 | Add read-only claim-liveness checks to task validation/status: unstarted rows cannot reserve paths; nonexistent paths fail; branch/path reachability is reported. | Manual audit reduced claims 143→61 and workable plans rose 1→8. | Medium, 4–6 h |
| 2 | Make session closeout verify every live root note has exactly one index row, including notes introduced by merges. | Four live notes are unindexed; July reported zero. | Low, 1–2 h |
| 3 | Add a non-blocking DoD#1 changed-path report for runtime changes lacking both numbered GDD and roadmap, with an explicit no-behavior-change justification. | Repeated July/current misses. | Medium, 3–5 h |
| 4 | Add an implementation-plan checklist: activate → final consumer → failure/rollback, with a negative case. | Occupancy, resume/migration and skill-reference evidence. | Low template; Medium per feature |
| 5 | Add a non-blocking audit-cadence notice to closeout/status. | This audit was 702 commits beyond the prior rollup. | Low, 1–2 h |

## Positive observations

1. The v0.7.1 bundle records exact candidate/source identity, release/debug hashes,
   bundle integrity, and native-only gates it could not claim
   (`2026-08-08-07-24-00Z...:13-44`).
2. Returned v0.6.0 evidence was preserved before root-cause edits.
3. The claim ledger directly repairs July's reconstruction ambiguity.
4. Feature merges make first-parent history and provenance readable.
5. Waiting-work notes state preemption clearly; frozen v0.7.1 stayed immutable.

## Prioritized action plan

1. Mechanize path-claim liveness and stale-tracker detection.
2. Repair the four missing index rows and enforce note/index bijection.
3. Add a justified, non-blocking DoD#1 changed-path report.
4. Adopt final-consumer and rollback coverage in multi-layer plans.
5. Add the overdue-audit notice to closeout/status output.

## Frozen v0.7.1 applicability

No finding changes the frozen candidate's runtime or release contents. Recommendations
apply to integration/workspace infrastructure after rollup and owner approval; they
must not modify `agent/playtest-release-v0.7.1`.

## Delta vs previous review

- **Fixed:** RNG-2 wording; exact commit ownership; gdtoolkit installation and format pass.
- **Improved:** release evidence, playtest preservation, feature merges and preemption.
- **Still open:** audit cadence; DoD#1 remains an honor-system seam.
- **New/regressed:** four unindexed notes; stale/phantom claims; two direct integration sessions.

## Procedure friction

- The “~140 session notes” estimate is far below the 519 live root notes measured; remove it.
- “Every decision-index entry” needs a minimum stratified sample definition.
- Commit-size reporting needs an evidence/binary exclusion rule.
- Read-only history commands do not need a worktree; reserve isolation for cache/receipt writers.
