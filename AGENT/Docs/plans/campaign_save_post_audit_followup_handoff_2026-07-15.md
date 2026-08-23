---
Role: dated
Type: plan
Status: Target design
Last verified: 2026-07-15
---

# Campaign/Save Post-Audit Follow-Up Handoff — 2026-07-15

## Purpose

Continue from the full audit and fix pass at `776c241` without reopening settled
campaign/save behavior. The release-relevant import, resume, and export defects are
already fixed. This handoff covers every remaining audit action, records the owner
decision on decision-index vocabulary, and keeps import-size budgets easy to tune
as measurements replace estimates.

Read first:

- `AGENT/Code Reviews/full_review_rollup_2026-07-15.md`
- `AGENT/Code Reviews/code_review_2026-07-15.md`
- `AGENT/Docs/documentation_review_2026-07-15.md`
- `AGENT/Code Reviews/tests_ci_build_review_2026-07-15.md`
- `AGENT/Code Reviews/process_history_review_2026-07-15.md`
- `AGENT/Session Notes/2026-07-15ac.md`

## Settled owner decisions

### Decision index uses two independent states

Replace the overloaded `Status` column with:

1. **Decision state:** `Open`, `Ratified`, `Superseded`, `Historical`.
2. **Delivery status:** `Not scheduled`, `Target design`, `Planned`,
   `In implementation`, `Implemented`, `Pending validation`, `Deferred`,
   `Not applicable`.

Do not retain `Answered`: an answer that has not reached its authoritative owner
is not durable and remains `Open`. Do not invent composite values such as
`Applied (Split)`. A split feature should use one decision state and a delivery
status that reflects the tracked slice, with detail in the row notes or separate
rows.

### Import budgets remain adjustable

- Keep the current **64 MiB portable-save hard ceiling** as a development-safe
  desktop default until measured evidence supports changing it.
- Add an **unusually-large warning threshold**, provisionally 16 MiB, without
  rejecting the file solely for crossing the warning threshold.
- Campaign-package limits stay separate from portable-save limits because media
  dominates package size.
- Limits must have one obvious configuration owner and must not be copied as raw
  numbers across UI, parser, tests, and docs.
- Future Web limits may be stricter than desktop limits; do not force one global
  ceiling if platform evidence differs.

## Work order

Each phase is a separate logical commit. Re-run the full suite after behavior or
checker phases. Apply DoD#1 and DoD#2 in the same commit whenever they trigger.

### Phase 1 — Normalize decision lifecycle and enforce it

1. Update documentation governance to define the two columns and exact values.
2. Migrate every `decision_index.md` row. Preserve meaning; do not silently call
   partially delivered work Implemented.
3. Update consumers/templates that assume a single Status column.
4. Add a `check_docs.py` check for the two headers and allowed vocabularies.
5. Negative-test the checker with an invalid state and invalid delivery value.

Exit gate: every decision row parses, no composite status remains, and the docs
checker fails on vocabulary drift.

### Phase 2 — Centralize and measure import budgets

1. Introduce one small configuration owner for import budgets, preferably a
   typed resource/service constants file rather than values embedded in UI code.
   It should expose at least:
   - portable-save warning bytes;
   - portable-save maximum bytes;
   - campaign archive compressed, uncompressed, per-entry, and entry-count caps.
2. Route `SaveManager`, `CampaignArchivePreflight`, campaign-library feedback,
   and tests through that owner. Preserve caller overrides where test/build tools
   need tighter fixtures.
3. Add a measurement helper/test that records representative JSON byte sizes for:
   - between-map save;
   - normal mid-map save;
   - large roster/convoy;
   - retained rewind ledger under the largest shipped policy.
4. Report parsing time and, where reliably measurable, peak memory. Do not make
   timing a flaky blocking assertion; record evidence and enforce only stable size
   invariants.
5. Warn above the adjustable warning threshold and hard-reject above the maximum
   before buffering. Ensure the warning does not bypass integrity/schema checks.
6. Document how an author/developer changes budgets and when a platform override
   is justified.

Exit gate: no duplicated literal budget, oversize rejection still occurs before
buffering, warning behavior is covered, and the recorded worst case has explicit
headroom. Reconsider 64/16 MiB only from these measurements.

### Phase 3 — Finish campaign documentation governance gaps

1. Restructure the GDD_01 campaign contracts to comply with DOC-002
   (Summary / Specs / Known gaps / Anchors) without duplicating runtime owners.
2. Extend `check_docs.py` to require section-local `Status` + `Last verified`
   pairs in every live split GDD companion.
3. Add a mechanically reliable DOC-002/DOC-002a shape check, keeping the explicit
   catalogue exception for GDD_06/07/08.
4. Add stable feature/track identifiers if needed, then detect duplicate Feature
   Index ownership/status rows.
5. Refresh generated indexes and negative-test each new checker rule.

Exit gate: campaign contracts conform, the known omissions cannot recur, and all
documentation checks pass.

### Phase 4 — Migrate closed authored vocabularies

Treat this as a designed compatibility slice, not a search-and-replace.

1. Inventory every objective-condition and item-effect id, validator, evaluator,
   renderer, save implication, and authored resource.
2. Define open registry entries/handlers for:
   - objective validation, evaluation, and display;
   - item-effect validation, preview, and commit.
3. Preserve existing ids and authored data compatibility through adapters or a
   one-time migration with loud validation.
4. Route existing behavior through the registry before deleting closed constants
   and `match` dispatch.
5. Add unknown-id, duplicate-id, validation, preview/evaluation, commit, and
   compatibility coverage.
6. Update the owning GDD sections and roadmap/control-plane rows in the same
   behavior commits.

Exit gate: adding a new objective condition or item effect requires registration,
not edits to central closed switches; current content behaves identically.

### Phase 5 — Process/tooling enforcement

1. Add a non-blocking audit-cadence report: days and commits since the newest full
   rollup. Print it during session closeout and before push.
2. Add exact commit SHAs/subjects to the session-note template and a check that
   each non-merge commit since the previous note is claimed once. Design the
   bootstrap/migration rule before enforcing history.
3. Add a reusable requirement/evidence matrix template and require it before a
   multi-slice roadmap track moves to Implemented.
4. Add a quiet export-smoke wrapper reporting exit code, artifact size, and hash.
5. Pin gdtoolkit, run the one-time formatting change on its own branch/commit, and
   then add `gdformat --check` plus `gdlint` to hooks and both CI workflows.

Changing `.github/workflows/**` requires explicit owner approval at that phase.
Do not mix the mechanical whole-tree format with feature work.

Exit gate: cadence and evidence gaps are visible automatically; commit ownership
is reconstructable; lint/format enforcement is reproducible and version-pinned.

### Phase 6 — Live Windows campaign validation

Run `AGENT/Docs/playtests/playtest_checklist_v0.4.0_campaign_test.md` against a
fresh traceable build. Cover Prep focus/long-roster layout, five-map transitions,
branch results, defeat actions, Retry/Rewind, manual/auto save and load, portable
save warnings, and campaign package import/export dialogs. Archive the checklist,
build hash, original `godot.log`, platform/controller details, and requested
screenshots before changing `Pending validation` delivery rows to `Implemented`.

## Explicitly outside this goal

- Public campaign-builder GUI and content resynchronization remain deferred.
- New shops/convoy/arena/recruitment Prep services remain their own tracks.
- Do not change the 64 MiB maximum merely to make a test smaller; tests should use
  dependency injection or caller overrides.
- Do not merge or push to `main`; use the permitted `agent/**` workflow.

## Completion gate

Execution evidence is tracked row-by-row in
[`campaign_save_post_audit_followup_evidence_matrix_2026-07-15.md`](../playtests/campaign_save_post_audit_followup_evidence_matrix_2026-07-15.md).
That matrix is intentionally still `Pending validation` while its live Windows
rows lack returned evidence.

The follow-up is done only when:

- the accepted two-column decision schema is ratified and enforced;
- import limits have one adjustable owner plus measurements and warning coverage;
- campaign DOC-002/verification gaps are closed and checked;
- objective/item authored vocabularies use open registries with compatibility;
- cadence/session/evidence/lint work is implemented or explicitly split behind a
  recorded external-approval blocker;
- the Windows campaign checklist is returned and triaged;
- all full automated gates are green; and
- a session note lists every commit and any intentionally remaining work.

## Recommended next-session goal prompt

> Continue on the campaign/save follow-up branch using
> `AGENT/Docs/plans/campaign_save_post_audit_followup_handoff_2026-07-15.md` as
> the authoritative sequence. Create a persistent goal to complete every phase
> within scope: implement and enforce the accepted two-column decision-index
> vocabulary; centralize adjustable import budgets, measure representative saves,
> and add the warning/hard-cap behavior; close and automate the remaining campaign
> documentation-governance gaps; migrate objective conditions and item effects to
> compatibility-preserving open registries; implement the audit/session/evidence
> tooling; and prepare/execute the focused Windows validation where the environment
> permits. Keep logical phases in separate commits, obey DoD#1/DoD#2, request
> explicit approval before workflow edits, run all required gates, and do not mark
> the goal complete while an in-scope phase or evidence-backed finding remains.
