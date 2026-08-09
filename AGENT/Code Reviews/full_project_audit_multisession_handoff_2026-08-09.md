# Full project audit multi-session handoff — 2026-08-09

Status: In progress — Session 6 complete; begin Session 7 next session.

Last verified: 2026-08-09

Tracker: `FULL-AUDIT-2026-08-2026-08-09`

Branch: `agent/from-integration/full-audit-2026-08`

Procedure: [Master Review Procedure](../Review%20Procedures/00_Master_Review_Procedure.md)

Control plane: [Project Control Plane](../Docs/plans/project_control_plane_2026-06-29.md)

## Owner decision and purpose

The owner approved this audit plan on 2026-08-09. The last full rollup is
`AGENT/Code Reviews/full_review_rollup_2026-07-15.md`; its repository commit is
`c003edfaa5d70d1f2109874b52227c0eb154fc6c`, and `agent/integration` was measured
as 702 commits beyond it during planning. The audit is overdue.

Run the full five-pillar review over several back-to-back, deliberately bounded
sessions. Keep the context for each session small by reading this handoff, the master
procedure, that session's pillar procedure, the shared baseline, and the immediately
preceding checkpoint only. Do not reconstruct the audit from chat history.

The audit is a document-only evidence pass. It must not fix code, data, documentation,
workflows, or release artifacts. Fixes begin only after the owner reviews the rollup.

## Snapshot and release contract

- The audit branch was created from synchronized `agent/integration` at
  `41c0e5fc1116a9a01aed3afc48dbc92f021d018d`. Session 1 must verify and record the
  exact audited source SHA before doing any review. Once recorded, every pillar audits
  that same SHA even if `agent/integration` advances.
- Audit-report commits on this branch do not change the audited source snapshot.
- The frozen v0.7.1 candidate is
  `agent/playtest-release-v0.7.1` at
  `0db30fd17adb83fb7e912c57b7630933c31588d6`. Do not modify, merge into, rebuild,
  or otherwise disturb it during the audit.
- Every actionable finding must eventually be classified as one of:
  `affects frozen v0.7.1 candidate`, `integration only`, `already tracked`,
  `duplicate of returned playtest finding`, or `deferred/systemic`.
- The future consolidated v0.7.1 fixes list receives only findings proven to affect
  the frozen candidate and accepted by the owner. Do not silently turn every audit
  finding into a v0.7.1 blocker.
- Existing tracker rows are linked rather than duplicated. Cross-pillar duplicates
  become one rollup entry with one owner.

## Report naming and durable checkpoints

Session 1 chooses one `AUDIT_DATE` and records it in the baseline. All reports in this
run use it. If a same-day path already exists, use the lowercase `-b`, `-c`, ... suffix
required by the master procedure; never overwrite a report.

Expected final outputs:

| Output | Path pattern |
|---|---|
| Shared baseline | `AGENT/Code Reviews/full_review_baseline_AUDIT_DATE.md` |
| Tests, CI & build | `AGENT/Code Reviews/tests_ci_build_review_AUDIT_DATE.md` |
| Code | `AGENT/Code Reviews/code_review_AUDIT_DATE.md` |
| Scenes, data & assets | `AGENT/Code Reviews/data_assets_review_AUDIT_DATE.md` |
| Documentation | `AGENT/Docs/documentation_review_AUDIT_DATE.md` |
| Process & history | `AGENT/Code Reviews/process_history_review_AUDIT_DATE.md` |
| Final rollup | `AGENT/Code Reviews/full_review_rollup_AUDIT_DATE.md` |

If a pillar spans sessions, commit a clearly labelled checkpoint in its eventual report
path or a sibling `*_checkpoint_AUDIT_DATE.md`. Record exactly what remains. No open
work may live only in a session note or conversation.

## Session cycle

Run in the sequential fallback order required by the master procedure:
Tests/Build -> Code -> Scenes/Data -> Documentation -> Process/History. A later session
may cite earlier reports but must not redo their checklist.

### Session 1 — shared baseline and audit map

Read the master procedure completely. Pin and record the audited source SHA, clean-tree
state, available tool versions, prior-report globs and resolved prior reports. Run
`python3 AGENT/Docs/check_docs.py` and `bash run_tests.sh`, preserving their real exit
codes. Map every top-level directory and root configuration file to exactly one pillar.

Exit only when the baseline report is committed and contains everything required by
master procedure section 3. If either baseline gate is red, record it as the first
Critical finding and preserve the unstable-baseline warning for all pillars.

### Session 2 — Pillar 4: tests, CI, build and tooling

Follow `AGENT/Review Procedures/04_Tests_CI_Build_Pillar.md` completely. Review tests,
fixtures, test runners, hooks, CI definitions, export/build configuration, project
configuration, and all analyzer/one-off tools assigned to Pillar 4. This is read-only;
reviewing `.github/workflows/**` does not authorize editing them.

Exit with the final pillar report, anchored `**Score:** N/10`, top findings,
delta from its prior report, v0.7.1 applicability notes, and procedure-friction notes.

### Session 3 — Pillar 1A: architecture and high-risk runtime systems

Begin `AGENT/Review Procedures/01_Code_Pillar.md`. Cover autoloads, content activation,
registries and open-extension seams, campaign-pack isolation, save/load, battle state,
maps/objectives, and other high-risk architectural paths. Check against the one-active,
self-contained campaign-pack rule; cross-pack duplicate ids are legal and are not a
finding.

Exit with a committed checkpoint listing reviewed paths, provisional evidence-backed
findings, spot checks completed, and the exact unchecked Pillar 1 scope.

### Session 4 — Pillar 1B: remaining code and reconciliation

Finish every unchecked Pillar 1 item, including UI, units, skills, AI, combat and the
remaining runtime scripts. Reconcile provisional findings against existing tracker rows,
the v0.7.0 root-cause review, and the frozen v0.7.1 candidate.

Exit with the final code report, anchored score, history delta, top findings,
v0.7.1 applicability notes, and procedure-friction notes. Remove or clearly supersede
the temporary checkpoint so there is one authoritative Pillar 1 report.

### Session 5 — Pillar 3: scenes, data and assets

Follow `AGENT/Review Procedures/03_Scenes_Data_Assets_Pillar.md` completely. Cover scene
wiring, all `.tres` resources, imports, UID sidecars, assets, autoload wiring, stray
directories, and data/runtime compatibility. Follow cross-repository evidence when it
demonstrates a Project Prometheus interface defect, but do not silently expand this run
into independent full audits of both campaign-pack repositories.

Exit with the final pillar report, anchored score, history delta, top findings,
v0.7.1 applicability notes, and procedure-friction notes.

### Session 6 — Pillar 2: documentation

Follow `AGENT/Review Procedures/02_Documentation_Pillar.md` completely. Check GDD/code
agreement, roadmap statuses, governance, decisions, registers, plans, guides, generated
indexes, cross-links, stale instructions, and contradictory live sources. Apply the
documentation definition of done and cite both sides of every drift claim.

Exit with the final pillar report, anchored score, history delta, top findings,
v0.7.1 applicability notes, and procedure-friction notes.

### Session 7 — Pillar 5: process and history

Follow `AGENT/Review Procedures/05_Process_History_Pillar.md` completely. Audit branch
lifecycle, tracker and claim integrity, release evidence, playtest handling, commit and
session-note hygiene, decision follow-through, tooling use, and recurring failure
patterns. Compare against the July 15 audit and later historical evidence rather than
judging only the current tree.

Exit with the final pillar report, anchored score, history delta, top findings,
v0.7.1 applicability notes, and procedure-friction notes.

### Session 8 — rollup, tracker intake and owner review

Follow master procedure sections 5-8. Reconcile every `[CROSS]` finding, deduplicate
existing tracked/playtest work, score all pillars, compute lowest-pillar overall health
and rounded mean, compare trends, identify regressions, and rank the unified action plan
by impact divided by effort.

Create or update canonical tracker rows for every still-open action. Prepare a distinct
v0.7.1 intake section containing only findings proven against the frozen candidate.
Merge that intake into the consolidated v0.7.1 fixes list when that list exists; until
then the audit tracker row and rollup must remain the durable pointer. Present the
rollup and proposed v0.7.1 additions to the owner for approval before implementing any
fix.

Exit when all five pillar reports and the rollup are committed, indexed where required,
tracker state is regenerated and valid, the branch passes the configured full check,
and the reports are pushed. The audit is not closed until its action plan is represented
in the canonical tracker.

## Per-session opening checklist

1. Run `scripts/agent-work --repo Project_Prometheus status --agent`.
2. Read this handoff, the master procedure, the current pillar procedure, the baseline,
   and only the immediately relevant prior report/checkpoint.
3. Confirm the branch is `agent/from-integration/full-audit-2026-08`, the tree is clean,
   and the pinned audited SHA has not changed in the baseline.
4. Check `coordination/tasks.json` for new claims or returned v0.7.1 playtest work.
   A playtest return preempts audit work, but it does not invalidate completed reports.
5. State the session number and its exit condition before beginning.

## Per-session closing checklist

1. Finish the session's report or durable checkpoint; do not leave conclusions only in
   chat context.
2. Cite evidence with paths and line numbers. Mark assumptions as assumptions.
3. Record procedure friction separately from product findings.
4. Update the canonical tracker pointer/status and regenerate/validate its human view.
5. Run the checks proportionate to a document-only change, commit with the required AI
   trailers, and push the `agent/**` branch.
6. Leave a clean tree and update this handoff's progress table.

## Progress table

| Session | State | Durable output | Notes |
|---|---|---|---|
| 0 — approved plan and handoff | Complete | This document | Audit branch and tracker row created. |
| 1 — shared baseline | Complete | `AGENT/Code Reviews/full_review_baseline_2026-08-09.md` | Pinned `41c0e5fc`; docs 43/43 and all 135 suites green; full tree and prior-report map recorded. |
| 2 — tests/CI/build | Complete | `AGENT/Code Reviews/tests_ci_build_review_2026-08-09.md` | Score 8/10; 135 suites and both exports green. Main finding: 51 passing infrastructure/browser assertions are not in a required gate. |
| 3 — code architecture | Complete | `AGENT/Code Reviews/code_review_checkpoint_2026-08-09.md` | High-risk architecture traced; recurring partial campaign-resume transaction is the provisional High finding. |
| 4 — remaining code | Complete | `AGENT/Code Reviews/code_review_2026-08-09.md` | Score 6/10; resume transaction remains High and a newly scoped failed user-data migration can be permanently marked complete. Both exact implementations affect frozen v0.7.1. |
| 5 — scenes/data/assets | Complete | `AGENT/Code Reviews/data_assets_review_2026-08-09.md` | Score 10/10; all 25 scenes, 221 resources, 15 manifests, 125 live asset imports, 313 UID pairs, eight map/encounter pairs, and five campaign nodes validated with no actionable defect. |
| 6 — documentation | Complete | `AGENT/Docs/documentation_review_2026-08-09.md` | Score 6/10; two live GDD claims overstate known-broken resume atomicity and native FileDialog Escape behavior. The active lifecycle rubric also retains pre-typed-layout paths. |
| 7 — process/history | Not started | Pillar 5 report | Read the Pillar 5 procedure, baseline, July process report, and this session's checkpoint; audit lifecycle/tracker/claims/releases/history without redoing product pillars. |
| 8 — rollup and v0.7.1 intake | Not started | Full rollup and tracker rows | Owner approval gates fixes. |
