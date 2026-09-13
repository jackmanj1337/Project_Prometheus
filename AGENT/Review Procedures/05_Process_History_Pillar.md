---
Role: topic
---

# Pillar 5 — Process & History Review

> **Status:** Active — corrected 2026-09-13
> **Last verified:** 2026-09-13
> **Part of:** `AGENT/Review Procedures/00_Master_Review_Procedure.md`
> **Correction:** session notes are frozen history; current outcomes belong in the ledger, tracker, and waiting-work handoff.

The tracker and waiting handoff below belong to the container repository at the
workspace root: coordination/tasks.json and AGENT/WAITING_WORK.md. They are not
paths inside Project_Prometheus; pin their container SHA separately.

Review the assigned historical period and process surface at the pinned SHA.
The master supplies scope, baseline, prior-report candidates, time/tool
allowance, and coverage target. Workers are read-only and return evidence;
the lead writes the report, assigns severity/score, reconciles duplicates, and
decides whether a recommendation belongs in the tracker.

Use `git log`, `shortlog`, `blame`, `AGENT/Ledger/CLAIMS.tsv`,
`coordination/tasks.json`, `AGENT/WAITING_WORK.md`, decision records, playtest
evidence, and prior reviews. Treat `AGENT/Session Notes/**` and its index as
frozen historical evidence only; do not require a new note or report note
absence as a current violation. Define the sample by commit/date ranges and
tracker rows, not by an assumed “session” unit. State the exact sample.

Assess branch and commit discipline, claim/task traceability, decision
implementation versus delivery (planned is not implemented), bidirectional
supersession, recurring defect classes, review-score trends, repeatedly violated rules, and
rework. Compare current requirements with the policy in force at the sampled
date; do not apply today’s rule retroactively. A recommendation must cite the
observed pattern, estimate effort, and name a mechanism to retire when it adds
process machinery (one-in-one-out). Do not recommend a guard by default.

## Evidence returned to the lead

Return the exact sample, commands and statuses, evidence-backed adherence and
trend findings, decision/task links, local ID, proposed severity, confidence
(confirmed or suspected), cross-pillar owner and existing task ID (or no match
found), positives, recommendations, and friction. The lead owns report output, score, severity, and coordination
updates through the canonical tracker and ledger.

## Dispatch brief

> You are a `gpt-5.6-luna` read-only Process/History worker. Review only
> `<scope>` through `<SHA>`. The lead supplies `<baseline>`, `<prior-report
> candidates>`, `<time/tool allowance>`, and `<coverage target>`. Sample
> commits/date ranges and tracker evidence explicitly. Do not create session
> notes, edit documents, write reports, or create tasks. Use the master return
> schema exactly; budgets never imply complete coverage. Return commands/status,
> sample, evidence-backed findings, assumptions, positives, recommendations
> with effort and one-in-one-out implications, and friction.
