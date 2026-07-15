# Process & History Review - 2026-07-05

> **Pillar:** 5 - Process & History
> **Procedure:** `AGENT/Review Procedures/05_Process_History_Pillar.md`
> **Snapshot:** branch `v0.3.0-features`, commit `914dd025ea8fbd898e5dbbc7c8ed7a6441cbf4dc`
> **Previous review:** `AGENT/Code Reviews/process_history_review_2026-06-14.md`

**Score:** 7/10

## Executive Summary

The session-note discipline and commit granularity remain strong. Recent work is
well narrated, tested, and usually committed in focused steps. The two process gaps
are the full-audit cadence not triggering until the owner asked, and a DoD#1 miss
where the spawn-seam behavior changed without updating the GDD owner specs.

## Sample Statement

Read latest sessions `2026-07-05c`, `2026-07-05b`, `2026-07-05`,
`2026-07-04h`, `2026-07-04g`; skimmed `INDEX.md` for 2026-07-03 to 2026-06-14
review/design sessions; checked git history from `e924bb4` to `914dd02`; reviewed
prior full audit, current control plane row `B4-ENCOUNTER-MODEL`, and the spawn-seam
commits `5b5d322` / `355d2a8`.

## Workflow-Adherence Findings

### Medium - Full-audit cadence is documented but not operationalized

Location: `AGENT/Review Procedures/00_Master_Review_Procedure.md:20`,
git `rev-list e924bb4..HEAD`

The master procedure says to run a full audit after roughly 30 commits or four weeks.
This audit was requested 514 commits after the previous full audit. That is a useful
signal that the cadence rule is not visible during normal work.

Recommended fix: add a cheap command or `check_docs.py` informational check that prints
commits since the latest `full_review_rollup_*.md`, or add it to session closeout.

### High - Spawn-seam implementation missed the paired GDD owner update

Location: commit `5b5d322`, `AGENT/Docs/plans/project_control_plane_2026-06-29.md:102`,
`AGENT/GDD/GDD_01_Architecture.md:1440`, `AGENT/GDD/GDD_06_Maps_Objectives.md:239`

The session note says `GameMap._spawn_units` now accepts inline `unit_data`, and the
control plane row was updated. The GDD owner specs still describe only
`unit_data_path`. This is exactly the DoD#1 failure mode: behavior changed, but the
GDD section that readers use as the schema reference did not change in the same commit.

Recommended fix: update the GDD now, and for future schema/runtime changes, treat the
control plane as tracking only; it does not replace the GDD owner update.

## Git-Hygiene Assessment

- Commit messages remain specific and useful.
- Recent changes are split by logical step: spawn seam, MRD slices, tile authoring,
  review fixes, and session notes are separate commits.
- Branch hygiene improved with `v0.3.0-features` split from `docs-reorg-2026-06-23`,
  but `HEAD` is one local commit ahead of `origin/v0.3.0-features` at audit time
  (`914dd02` vs `a771ccb`).

## Process-Effectiveness Analysis

Recurring defect classes have shifted from 2026-06-14's UID/analyzer/fort-heal issues
to display-live-verification and schema-contract drift. The good pattern is that
playtest returns are triaged with IDs and regression tests; the weak pattern is that
small buildable slices can update implementation plans/control plane while skipping
the live GDD schema owner.

## Tooling & Workflow Recommendations

| Recommendation | Evidence | Effort |
|---|---|---:|
| Add an audit-cadence reminder | 514 commits since previous full audit; procedure says about 30 | Low |
| Add a DoD#1 closeout checklist line for schema/resource changes | Spawn seam updated control plane but not GDD_01/GDD_06 | Low |
| Finish gdtoolkit installation and gate | Still absent from tool probe; procedure backlog remains open | Medium |

## Positive Observations

- Session notes are current and indexed.
- The owner-review walkthrough pattern is working: questions are separated from
  mechanical fixes and routed to control-plane rows.
- Pre-commit hooks are consistently reported in session notes and remain green.

## Delta Vs Previous Review

Fixed: release tagging, UID tracking, analyzer gating, scene-integrity gating, and
branch naming for the new v0.3.0 work. Regressed/new: audit cadence exceeded its
commit threshold, and DoD#1 missed the inline spawn-seam GDD update.

## Prioritized Action Plan

1. Patch GDD_01/GDD_06 for the spawn seam.
2. Add an audit-cadence reminder.
3. Land the gdformat/gdlint gate on a pip-capable setup.
