# Integration Feature-Branch Consolidation Plan

**Status:** Implemented on `agent/integration` through `f1d6f87a` (2026-07-29);
final clean-cache acceptance and branch archival are recorded by the closeout review.

**Task:** `MERGE-ORDER-FROM-INTEGRATION-2026-07-29`  
**Prepared:** 2026-07-29  
**Target:** `agent/integration` only  
**Starting tip:** `a04712f65ef648b9435b06fdf3c0191c6b9633a5`

## Outcome and current baseline

The accepted v0.5.8 release is already present. Accepted release tip `c59c6c7d`
and its `main` promotion `db4d2a8b` are both ancestors of `agent/integration`.
Do not repeat the release reconcile and do not merge `main` again unless a new
promotion lands after this plan is measured.

This plan brings the useful work from nine outstanding
`agent/from-integration/*` branches onto the current feature base without
reintroducing stale generated files, obsolete control-plane prose, known
fail-open validators, or same-day session-note collisions.

## Non-negotiable intake rules

1. Work on a fresh `agent/from-integration/<wave-slug>` branch for each wave.
2. Before taking a commit, compare its content with current integration. A
   different hash is not proof that work is missing.
3. Select exact commits or files. Do not merge the 84-commit
   `campaign-data-research` branch wholesale.
4. Never accept a branch copy of generated `AGENT/Docs/INDEX.md`,
   `AGENT/Docs/REGISTERS.md`, or the hand-maintained Session Notes index. Rebuild
   or union them after the substantive files are settled.
5. New session notes use the workspace scaffold and the UTC form
   `YYYY-MM-DD-HH-MM-SSZ-<slug>.md`. Imported historical date-only notes receive
   a descriptive collision-safe name; published paths already on integration
   stay unchanged.
6. Run the gates listed for a wave before merging it into `agent/integration`.
   A green test on a stale source tip is supporting evidence, not acceptance of
   the rebased result.
7. After a wave lands, remeasure every remaining branch. Counts in this plan are
   evidence from `a04712f6`, not permanent truth.

## Phase 0 — harden the integration gates

Complete these before runtime-code intake (documentation-only Wave 1 may proceed
in parallel):

1. Make the `run_tests.sh` import warm-up fail loudly. Remove `|| true`, preserve
   the import log on failure, assert generation of
   `.godot/global_script_class_cache.cfg`, and verify a checkout with no
   `.godot/` passes. The current silent import step can reuse stale state and
   recreate the misleading failures found during the branch review.
2. Stop importing playtest evidence as Godot content. Verify `.gdignore` on the
   evidence roots (or move evidence outside `res://`), remove generated evidence
   `.import` sidecars, and prove an import leaves the tree clean.
3. Enforce the UTC session-note filename for newly created notes in the
   documentation/session checker. The generator is fixed, but manual date-only
   filenames must also be rejected so collisions cannot bypass it.

Phase 0 gates: focused tooling tests, `check_docs.py`, a clean-cache
`bash run_tests.sh`, and `git status --porcelain` empty after the run.

## Wave 1 — low-risk governance and planning intake

Use fresh intake branches and take the substantive commit before its session
note. Resolve GDD/control-plane text semantically against current integration;
never choose an old branch version wholesale.

| Order | Source | Unique commits at measurement | Intake rule |
|---|---|---:|---|
| 1 | `web-distribution-freeze` | 2 | Take the web-distribution decision and descriptive note; reconcile `GDD_00` against the current header/status. |
| 2 | `text-entry-governance` | 2 | Take the TEXT-06/Deck OSK governance rule, its checker change, GDD updates, and note. Run a controlled failing documentation fixture for the new rule. |
| 3 | `fe-schema-trial-handoff` | 2 | Take only content still absent. The FE readiness work already extracted several plans; regenerate indexes and reconcile the control plane instead of overwriting it. |
| 4 | `predicate-combat-operations-plan` | 2 | Take the implementation plan and renamed note. Keep implementation explicitly dependent on `B3-REQ` and the movement/vulnerability registry. |
| 5 | `dialogue-recruit-capture-research` | 13 | Intake the accepted plan/register changes as one reviewed set. Rename both date-only notes descriptively and regenerate Docs indexes. Do not import stale portfolio/control-plane status verbatim. |

Wave 1 gates after every source: `gen_docs_index.py`, `check_docs.py`,
`check_session_commit_claims.py`, link/index audit, and a clean diff review. Run
the full suite once on the combined Wave 1 tip before merging it.

## Wave 2 — curated campaign-data research recovery

`campaign-data-research` is 84 unique commits but is largely superseded. Create a
fresh branch from current integration and recover content by file, not by branch
merge or bulk cherry-pick.

The currently absent design documents are:

- campaign backup content-addressed format;
- campaign-library questions, research, and decisions;
- iOS native-target feasibility;
- prep/economy comparative research;
- text-entry strategy, naming/sanitization, and layout research;
- UI/UX architecture research and interaction vocabulary.

The currently absent handoffs are campaign-data ownership research/planning,
campaign-library UX research, UI/UX research, and zero-content owner/autonomous
execution handoffs. Reconfirm each against current tracker state before intake.

For modified existing files (`awakening_compatability_refactor_plan`, campaign
save follow-up, doc-role manifest, campaign-data findings, and project control
plane), produce a semantic three-way comparison. Keep current integration's
newer status and add only still-valid unique decisions. Do not replace these
files with the source-branch copies.

Required evidence before archiving the source branch:

- a manifest of every recovered file and its source commit;
- a second list classifying every omitted source file as already present,
  superseded, historical-only, or stale;
- generated indexes and all documentation/session-claim checks green;
- exact tree comparison showing no unclassified unique substantive content.

Archive only after that evidence lands. Do not delete the source ref.

## Wave 3 — security and schema code

### 3A. BBCode hardening

Reapply commits `d3c5cec3` and `af84265a` onto current integration after Wave 2,
because code comments cite the text-entry sanitization document recovered there.
Run `test_bbcode_escape`, `test_campaign_archive_preflight`, and the full suite.

The HUD terrain panel remains a tracked latent sink. Either close
`HUD-BBCODE-ESCAPE-LATENT-GAP-2026-07-29` in this slice or preserve an explicit
dependency preventing `MoreInfoContent` from becoming pack-authored first.

### 3B. Entity-schema validator

Do not merge the current prototype unchanged. First close
`ENTITY-SCHEMA-VALIDATOR-DEFAULT-BRANCH-2026-07-29`:

- missing, empty, or unknown field types fail closed;
- negative tests prove misspellings cannot validate arbitrary data;
- nested-object support is either implemented or explicitly rejected;
- error paths identify the entity and field.

Only then reapply the prototype on a fresh branch and run its focused tests plus
the full suite.

### 3C. Class-schema trial

Treat fixtures as validation evidence, not production runtime code. Before
intake, change the checker so `invalid_contract/expected_errors.json` is executed
against a validator and expected errors are matched, not merely checked for
unique strings. Decide which presentation-name warnings are advisory and which
are contract failures; never print a failing contract category as `OK`.

Intake the eleven source commits only after those negative gates pass. Rename
the date-only `2026-07-29.md` note and reconcile the zero-content plan/control
plane semantically.

Wave 3 gates per slice: focused negative and positive tests, GDScript style,
`check_docs.py`, session-claim audit, clean-cache full suite, and a clean working
tree after import/tests.

## Wave 4 — implementation sequencing after consolidation

The old v0.5.8-return/reconcile gate is retired: both conditions are satisfied.
Implementation order is now dependency- and readiness-driven:

1. Finish `B3-REQ` shared requirement/predicate evaluation.
2. Land the production entity/class schema contracts and zero-content loading
   foundation; prototypes alone do not satisfy this gate.
3. Implement predicate-driven combat operations only after `B3-REQ` and the
   movement/vulnerability registry contracts exist.
4. Schedule text-entry implementation after its accepted strategy/governance
   documents land; include the FileDialog Escape arbitration defect in that
   feature rather than losing it as release-line history.
5. Choose `B3-PHB` versus `B3-CAMPAIGN-RULES` on current readiness. Their old
   merge-conflict ordering constraint disappeared when v0.5.8 was reconciled.
6. Cut v0.6.0 only when a tester is available to return the required log bundle,
   and include all items in `playtest_v0.6.0_carryforward_2026-07-29.md`.

## Final consolidation acceptance

The primary integration line is up to date only when all of the following hold:

- accepted v0.5.8 release and promotion remain ancestors of integration;
- all nine source branches are classified as absorbed, curated-and-archived, or
  intentionally deferred with a live tracker row;
- no known fail-open schema validator is reachable as production behavior;
- test import failures cannot be hidden and a no-cache checkout is green;
- evidence imports do not dirty the repository;
- no newly imported date-only session note exists, indexes are consistent, and
  every substantive commit is claimed exactly once;
- `gen_docs_index.py`, `check_docs.py`, GDScript style, focused slice tests, and
  `bash run_tests.sh` all pass on the exact final HEAD;
- a final branch/content inventory is committed, then the consolidation branch
  is merged into `agent/integration` and pushed through `agent-work`.

Product implementation then continues from that settled `agent/integration`;
it does not move to `agent/staging-area` until it has passed through the normal
playtest and stable-release line.
