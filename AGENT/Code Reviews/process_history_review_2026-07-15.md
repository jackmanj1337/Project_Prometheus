# Process & History Review — 2026-07-15

> **Pillar:** 5 — Process & History
> **Procedure:** `AGENT/Review Procedures/05_Process_History_Pillar.md`
> **Snapshot:** `agent/codex/2026-07-15/prep-save-followup` at
> `08b3b5c2aa5dfb1e773a87d07890b9c7629ef1b3`
> **Previous review:** `AGENT/Code Reviews/process_history_review_2026-07-05.md`
> **Baseline supplied by orchestrator:** `check_docs.py` 35/35 PASS;
> `run_tests.sh` 98 suites PASS; Godot 4.6.3; gdtoolkit unavailable.

**Score:** 8/10

## Executive Summary

Process health improved from 7/10 to 8/10. The 28-commit campaign/save run is
highly traceable: messages are specific, commits carry tests and owner docs, every
one of 365 session notes is indexed, and the closing requirement audit found and
repaired contract drift before handoff. DoD#2 is particularly strong: each new
mechanical vocabulary or boundary sampled landed with a `check_docs.py` guard.

The remaining weaknesses are traceability lag at the seams. `RNG-2` still says
suspend/rewind snapshots are pending after both shipped; four behavior commits have
no session note in their own commit and are not identified by SHA in the adjacent
notes; and one campaign-rule authority commit changed behavior without touching the
roadmap in the same commit. The audit cadence is healthier in practice—this audit
was requested at 28 commits—but the prior recommendation to automate the reminder
has not landed.

## Sample Statement

Read the latest eleven campaign/save sessions in full: `2026-07-15r` through
`2026-07-15ab`. Also sampled `2026-07-15e`, `h`, `m`, and `2026-07-14f` for the
beginning and middle of the run; `2026-07-05d/e`, `2026-06-21b`, and
`2026-06-14c/d` for approximately biweekly/cadence history; both prior Process &
History reports; the current decision index; the four archived May playtest
findings; and the current pillar reports. Examined all 28 commit subjects and
file-level stats from `c88ce98..08b3b5c2`, with detailed same-commit pairing for
all 24 behavior-changing commits. The review is pinned to `08b3b5c2`; same-day
uncommitted audit reports are context, not evidence about the pinned history.

## Workflow-Adherence Findings

### DoD#1 — mostly strong; one same-commit roadmap miss

Twenty-three of 24 sampled behavior commits changed a numbered GDD owner, and 22
also changed `GDD_10_Roadmap.md`. The exception that matters is `f5faa1b` (`Add
campaign rule mandates and defaults`): it changed campaign rule authority, New
Game locking, save persistence, GDD_01 and GDD_07, but did not touch the roadmap
in that commit. That is a **Medium** same-commit DoD#1 miss even though surrounding
commits kept the overall campaign-save row accurate. `e727062` is a build/evidence
commit, not a behavior change, so no GDD pair was required.

The previous spawn-seam miss is fixed in the present GDD corpus. More importantly,
the latest completion-audit commit `08b3b5c2` repaired stale GDD, feature-index and
control-plane ownership text in the same commit as the final behavior corrections.

### DoD#2 — pass

Sampled mechanical rules landed with enforcement in the same changes:

- `d665565` added the raw-media/package boundary and a `check_docs.py` guard.
- `dcbb624` added durable-mid-map warning vocabulary and documentation check 33.
- `adb7632` added the `end_of_map|permanent` rule-flip vocabulary and guard.
- `861428b` added the status-record envelope/open-facts rule and guard.

No sampled prose-only mechanical ratification was found.

### Session discipline — index is perfect; commit-to-note linkage is ambiguous

The repository has 365 note files, 365 index links, zero orphan notes, and zero
dead links. Latest notes contain useful results, verification and next steps.

However, behavior commits `202309e`, `d665565`, `e1b7e6a`, and `9255496` do not add
a session note themselves. Adjacent notes describe some surrounding work, but do
not map these commits by SHA; for example `2026-07-15w` describes portable save
transfer and mandates while `9255496` separately performs the substantial New Game
unification. This is a **Low** reconstruction problem, not evidence that no notes
exist. A reviewer cannot reliably distinguish “second commit in this session” from
“session with no note.”

### Commit-per-logical-step — pass

The 28 commits have a median textual diff of 343 changed lines, mean 352, and no
commit at or above 1,000 lines. The largest is `dcbb624` at 796 lines across 28
files, but it is one coherent save-policy/autosave slice with docs and tests.
Implementation, test-build, planning, and session-record steps are separated.

## Git-Hygiene Assessment

- **Messages:** 28/28 are specific, imperative descriptions; there are no WIP,
  “misc,” or context-free “fixes” subjects.
- **Granularity:** larger than the prior review because persistence slices include
  schemas, UI, tests and owner docs, but still logically bounded. Nine commits are
  over 500 changed lines; none exceeds 796.
- **Plan adherence:** `r` through `ab` follows the stated chain—rewind, unified
  slots, save policy, package UI, audit-discovered gaps, results, mutable state,
  status records, defeat actions, final audit. No abandoned stated step was found.
- **Branch discipline:** the branch name accurately describes the work and is an
  allowed `agent/**` branch. At the pin it is 28 commits ahead of its remote, so
  source loss/recovery risk remains until the requested push.
- **Attribution:** sampled commits use the human author and AI metadata trailers,
  matching workspace policy.

## Decision Traceability

| Decision | In code? | In docs? | Status / finding |
|---|---|---|---|
| DOC-001 ↔ D-C | Governance | Yes | Bidirectional supersession remains correct. |
| DOC-011 | Yes | Yes | `check_docs.py` and CI ownership remain visible; sampled rules extend it. |
| RNG-1 | Yes | Yes | Index correctly records implemented dice sourcing with remaining event-commit scope. |
| RNG-2 | Yes | Partly stale | **Medium:** index says suspend/rewind snapshots are pending, but `b2535f0`, `faf206a`, and the F1 schema show RNG timeline persistence/restoration. |
| OPEN-13 | Yes, migrated | Yes | Semantics survive in the named-slot lifecycle, though the title still says “Suspend-file.” |
| SET-011–014 | As applicable | Yes | Scope decisions remain linked to GDD/roadmap owners. |

No sampled decision is falsely claimed implemented while absent from both code and
docs. No material implemented-but-unrecorded product decision was found; the new
campaign contracts are primarily traced through `[CST-*]`, control-plane IDs and
GDD owners rather than this older central decision namespace.

## Process-Effectiveness Analysis

### Recurring defect classes

The older Pair Up and combat-preview classes are not recurring in this 28-commit
window. The emerging class is **persistence contract/transaction drift**: the
post-build review found four save/advance defects (`2026-07-15d`), the rolling
requirement audit found portable integrity, branch/result, mutable-state,
status-record and defeat-menu gaps (`v` through `aa`), and the final audit found
protected-field, rule-display and hotseat-suspend gaps (`ab`). This is productive
audit-driven closure, but three or more discoveries after a feature was initially
called implemented show that requirements evidence is being assembled late.
`[CROSS]` The current Code pillar likewise found external-file and transaction
failure-path risks despite 98 green suites.

### Review-score trend

Process scores are **8/10 (2026-06-14) → 7/10 (2026-07-05) → 8/10 today**: a
recovery, not yet a sustained upward trend. Current artifact pillars span 6/10
Code, 8/10 Tests/CI/Build, and 10/10 Data/Assets, reinforcing that strong process
and green suites do not remove the need for boundary/failure-path review.

### Repeatedly violated rules

DoD#1 remains the repeated weak point: the prior review found the spawn-seam GDD
miss, and this sample finds the roadmap half missing from `f5faa1b`. Session notes
are consistently indexed, but note-to-commit mapping remains an honor-system seam.
DoD#2 shows no repeated violation.

### Rework rate

Only one of 28 subjects is explicitly an audit-gap repair, but file churn reveals
the integration pressure: `CampaignManager.gd` changed in 8 commits;
`NewGameScreen.gd`, `GameState.gd`, and `SaveData.gd` in 7 each. The work is planned
sequencing rather than fix churn, yet the same central surfaces absorb many rapid
changes in one day. The end-of-run audit was therefore valuable and should become
a planned gate before a feature row is labelled Implemented.

## Tooling & Workflow Recommendations

| Priority | Recommendation | Evidence | Effort |
|---|---|---|---:|
| 1 | Add `python3 AGENT/Docs/check_audit_cadence.py` (or a non-blocking `check_docs.py` notice) that reports commits and days since the latest full-review rollup; print it at session closeout and before push. | Prior audit ran 514 commits late; this one happened near the 30-commit threshold only after owner request. Prior recommendation remains unimplemented. | Low, 1–2 h |
| 2 | Add a machine-readable requirement/evidence matrix to each multi-slice implementation plan and require all rows green before flipping the roadmap row to Implemented. | The `v`–`ab` audit repeatedly discovered firm-contract gaps after earlier slices/status flips. `[CROSS]` Current Code review found more failure-boundary gaps. | Medium, 3–5 h/template plus initial matrix |
| 3 | Extend the session-note template with `Commits: <SHA subject>` and a closeout check that every non-merge commit since the preceding note is claimed exactly once. | Four behavior commits lack an in-commit note and adjacent prose cannot establish ownership. | Low, 2–3 h |
| 4 | Add a decision-index freshness check for implementation phrases that name “pending” milestones already marked Implemented in the roadmap, with explicit allow-listing for legitimate splits. | RNG-2 still calls suspend/rewind pending after implementation. | Medium, 3–4 h |
| 5 | Install/pin gdtoolkit and add its lint/format gate. | Still unavailable in the 2026-07-05 and current tool probes. `[CROSS]` | Medium |

## Positive Observations

1. All 365 session notes are indexed bidirectionally with no navigation defects.
2. The campaign/save plan was executed in a comprehensible dependency order, and
   each latest note states the next bounded slice.
3. DoD#2 is working as designed: four sampled new mechanical contracts shipped
   with guards, not prose promises.
4. Commit subjects and AI attribution are consistently clean across all 28 commits.
5. The rolling and closing audits corrected their own discovered gaps before push;
   `08b3b5c2` records tests, docs, RNG guard and whitespace verification together.

## Prioritized Action Plan

1. Correct the RNG-2 decision-index row and review OPEN-13's migrated terminology.
2. Add the audit-cadence reminder before another 30-commit interval elapses.
3. Adopt the requirement/evidence matrix as the pre-Implemented gate for the next
   multi-slice feature.
4. Add exact commit ownership to the session-note template/check.
5. Install and pin gdtoolkit, then gate lint/format in CI.

## Delta vs Previous Review

- **Fixed:** the spawn-seam owner-spec drift is no longer present; branch naming is
  accurate; this audit occurred around the documented 30-commit interval rather
  than hundreds of commits late.
- **Improved:** DoD#1 pairing is 23/24 for sampled behavior commits, DoD#2 has
  multiple fresh examples, and the process score returns from 7 to 8.
- **Still open:** audit cadence has no automated reminder; gdtoolkit is absent.
- **New:** RNG-2 decision text lags shipped suspend/rewind behavior; session notes
  have perfect indexing but ambiguous per-commit ownership; campaign requirement
  evidence was consolidated late in the run.

## Procedure Friction

- The procedure's “~140 session notes” estimate is now materially low: there are
  365. Sampling guidance remains correct, but the count should be removed or made
  dynamic.
- “Every decision-index entry → code and docs” is too broad for a sampled pillar
  and for target/deferred decisions. A prescribed stratified decision sample and
  explicit minimum would make repeat audits comparable.
- Commit-size metrics need a defined convention (textual additions+deletions,
  treatment of binaries/renames, mega threshold). This report used numstat textual
  churn and a 1,000-line mega threshold.
- Session boundaries are not encoded in git; without SHAs in notes, the required
  “commits but no note” test cannot be made conclusive.
