---
Role: topic
---

# Pillar 4 — Tests, CI & Build Review

> **Status:** Active — corrected 2026-09-13
> **Last verified:** 2026-09-13
> **Part of:** `AGENT/Review Procedures/00_Master_Review_Procedure.md`
> **Correction:** the lead runs the shared baseline once; Luna workers return bounded evidence.

Review the assigned tests, CI, hooks, checkers, tooling, and build configuration
at the pinned SHA. The master supplies scope, baseline results, prior-report
candidates, time/tool allowance, and coverage target. Workers are read-only:
they do not edit files, export builds, alter Docker state, write reports, or
create tasks. Do not repeat the master’s `check_docs.py` or `run_tests.sh`
baseline. Run only explicitly assigned, narrow probes and record command,
runtime, exit code, pass/fail/skip counts, and errors.

Assess meaningful coverage and disabled-test reasons. Map tests to systems and
critical paths (turn flow, combat resolution, save/load, promotion/reclass,
pair-up), editor authoring and authored-pack adoption. Check whether wiring tests
exercise real autoloads after tree readiness, whether errors abort before assertions,
and whether skipped suites are being presented as tested behavior. Inspect import
cache and typed-array assumptions in the actual harness.
Check order/flakiness and RNG control; CI enforcement versus advisory steps; hook behavior versus actual CI
behavior; and checker rules against current policy. The analyzer suite must be
runnable with stock `python3` when its tests permit it; pytest is optional when
the fallback is available, so missing pytest alone is not a finding. Report
tool or environment absence as a limitation unless the project requires it.

Inspect exports, packaging, and Docker configuration only when the dispatch
includes them. The lead owns any authorized build execution; workers inspect
its recorded evidence. Distinguish a local hook from a server CI
gate and verify whether either actually blocks. Record runtime errors and
skips separately from genuine test failures.

## Evidence returned to the lead

Return exact scope, probes and statuses, coverage gaps tied to named behavior,
local ID, proposed severity, evidence/reproduction, confidence (confirmed or
suspected), cross-pillar owner and existing task ID (or no match found),
CI/hook observations, limitations, positives, and friction. The lead owns
severity, score, report writing, and any tracker recommendations.

## Dispatch brief

> You are a `gpt-5.6-luna` read-only Tests/CI/Build worker. Review only `<scope>`
> at `<SHA>`. The lead supplies `<baseline>`, `<prior-report candidates>`,
> `<time/tool allowance>`, and `<coverage target>`. Do not repeat shared
> baselines, edit files, export, run Docker, write reports, or create tasks.
> A lead-authorized narrow diagnostic probe may run only if explicitly listed in
> this assignment; it grants no permission to edit files, write reports or tasks,
> export builds, or run Docker. Use the master return schema exactly; budgets never imply
> complete coverage. Return commands,
> runtime, exit codes, counts, errors/skips, evidence-backed findings,
> assumptions, positives, and friction.
