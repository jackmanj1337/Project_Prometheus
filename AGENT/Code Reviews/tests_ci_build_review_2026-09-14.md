---
Role: dated
---

# Tests, CI and Build Review — 2026-09-14

**Score:** 4/10

Luna W1/W4 plus lead verification reviewed engine run_tests, suite classification,
required non-Godot discovery, headless CI callers, pre-commit/pre-push, pack freshness,
and container exact-tree runner/receipt verification, manifest, tool runner and CI
filters. Snapshot/baseline details: [rollup](full_review_rollup_2026-09-14.md).

## Critical — A required schema validator cannot fail the full gate

At engine `ad2e6be729013f46a3978269c8ea0f6248f81aad`, `run_tests.sh:94-100`
explicitly calls the schema-pressure validator a required contract gate, but invokes
`python3 "$SCHEMA_TRIAL_CHECK"` without checking its exit status. The runner has no
`set -e`. Its final status instead follows the Godot suites. The required non-Godot
runner at `:39-43` correctly propagates failures, which does not cover this separate call.

Lead reproduction copied the actual runner and classifier to a temporary harness,
supplied a validator that exits 1 and a successful Godot stub. Output was deliberate
schema failure, `PASS: all suites green`, exit 0. Evidence:
`/tmp/full-audit-schema-gate-probe.log`; harness `/tmp/audit-schema-gate-7cli6nk7`.
This proves a broken required gate under the Master's Critical impact bar; it does
**not** say the real pinned fixtures fail. Owner: `AUDIT-SCHEMA-GATE-2026-09-14`.
Repair the existing status propagation and exercise its rejection path.

## Medium — Sibling-pack inputs are outside exact-tree receipt identity

Container `49dd69be21bac60b2318fabedc3950d41cb7a952`, `scripts/check-receipt.py:71-73`
passes live sibling directories into the isolated engine checkout, while `:117-126`
records only primary HEAD/tree/command/status. `scripts/workflow_core.py:77-102`
validates those fields but no sibling tree/state. A receipt remains acceptable after
its authored input changes. Separately, `repo.parent` is wrong for an arbitrarily
located linked worktree supported by `scripts/run-full-tests.sh:17-20`;
`adopter_pack.gd` can report ABSENT and skip real but undiscovered siblings.

These are confirmed identity/path limitations from both producer and consumers;
no release failure was reproduced. Current primary-checkout baseline did execute
all five authored-pack proofs. Owner: `AUDIT-SIBLING-RECEIPT-2026-09-14`.
Correct the existing receipt/root contract rather than adding a second gate.

## Medium — Root Playwright changes do not trigger the CI backstop

Container `.github/workflows/tool-tests.yml:18-40` filters only
`tools/playwright/lib/**`, whereas `scripts/test-tools.sh:34-35` executes root and
lib tests, and `hooks/pre-push:136-147` matches `tools/playwright/*`. Thus a root-only
driver/test change invokes the local hook but does not schedule push/PR CI. The
workflow says these lists mirror one another. Pinned and report-time code agree.
Reopened owner: `NODE-TEST-DISCOVERY-2026-09-12`. A workflow edit needs the existing
explicit authorization required by AGENTS.md; this audit changes no workflow.

## Positive evidence, deltas and limitations

The new lead engine run discovers 200 Godot suites and reports all green, no SKIP
lines, including five authored-pack proofs. Required non-Godot discovery also passed.
Docs checks 1–50 passed. Classifier rejects missing Results/SKIP summaries and uses
exit status; per-suite user-data isolation and failure reruns exist. Hooks are active.
Engine CI reaches the same required runner through run_headless_tests.sh.

August's broad missing-test discovery is substantially repaired, but the schema
validator is another instance of ignored command status and the CI filter lags the
new Node scope. Exact-tree receipts correctly verify the primary tree and command.
Engine single-repository CI intentionally omits sibling freshness; that is disclosed
coverage, not a new mismatch. Container configured pytest excludes shell/Node tool
checks, which the scoped hook/CI separately run.

No new exports, Docker rebuilds, native tests, binary acceptance or signing inspection.
Not every test assertion/workflow branch/export gate was semantically reviewed.
Inherited pack/container pass counts lack retained raw log paths in their receipts;
see rollup. The score is constrained by the demonstrated required-gate failure even
though the real baseline passes.
