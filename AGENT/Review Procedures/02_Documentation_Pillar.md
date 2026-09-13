---
Role: topic
---

# Pillar 2 — Documentation Review

> **Status:** Active — corrected 2026-09-13
> **Last verified:** 2026-09-13
> **Part of:** `AGENT/Review Procedures/00_Master_Review_Procedure.md`
> **Correction:** Luna workers assess live authority and return evidence; the lead writes the report.

Assess whether the assigned live GDD, governance, decision, guide, or index
documents are truthful, navigable, internally consistent, and authoritative.
The master supplies scope, SHA, baseline, prior-report candidates, time/tool
allowance, and coverage target. Historical or superseded documents are context
only unless a live document still cites one as authority. Check actual paths at
the pinned SHA; do not rely on old procedure examples.

Do not rerun structural checks already performed by the lead. Review truth
against the relevant code, data, shipped evidence, and ratified decisions;
status labels and `Last verified`; single-source ownership; links and anchors;
and governance vocabulary. Apply approved statuses (Implemented, Known issue,
Target design, Historical, Superseded) with Last verified. Major GDD features
follow DOC-002; GDD_06/07/08 catalog chapters may use the blessed DOC-002a
chapter Summary plus uniform entry tables. A missing automated check is evidence for a
recommendation, not an automatic reason to add a guard. Every drift finding
cites both the document and its contradicting source, or is marked an
assumption.

Use the container repository's coordination/tasks.json and AGENT/WAITING_WORK.md
as the workflow source, plus the project's `AGENT/Ledger/CLAIMS.tsv`. Frozen
`AGENT/Session Notes/**` may be sampled only for historical periods; never
create or update a session note or its index.

## Evidence returned to the lead

Return the document sample, paths verified, commands used, findings with local
ID, proposed severity, location/evidence/status impact, contradictory source,
confidence (confirmed or suspected), cross-pillar owner and existing task ID
(or no match found), positive observations, and
recommendations with estimated effort. The lead owns score, severity,
cross-pillar reconciliation, and report/tracker updates.

## Dispatch brief

> You are a `gpt-5.6-luna` read-only Documentation worker. Review only `<scope>`
> at `<SHA>`. The lead supplies `<baseline>`, `<prior-report candidates>`,
> `<time/tool allowance>`, and `<coverage target>`. Do not edit or write docs,
> rerun shared baseline checks, create session notes, or create tasks.
> Use the master return schema exactly; budgets never imply complete coverage.
> Verify live paths and authoritative sources; return sample, commands/status,
> evidence-backed findings, assumptions, positives, and friction.
