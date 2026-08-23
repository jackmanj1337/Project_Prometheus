---
Role: dated
Type: plan
Status: Active — re-scope proposal plus the collision report that survives
Last verified: 2026-08-20
Tracker: REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Re-scoping the accepted-portfolio code-state review (2026-08-20)

`REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27` was cleared to `planned` on 2026-08-16
when its long-standing release blocker was swept. This pass was asked to run it. It should
not be run as written, and this document says why, proposes what to run instead, and
delivers the part of its deliverable that is still live.

## 1. The gate is stale, and the project has already passed it

`accepted_portfolio_code_state_review_handoff_2026-07-27.md` is built on a premise that no
longer holds: *"Review the accepted implementation portfolio against the actual current
Project Prometheus codebase **before any product implementation begins**."* Four checks:

| Claim in the handoff | State on 2026-08-20 |
|---|---|
| `Status: WAITING FOR ACCEPTED STABLE v0.5 RELEASE` (frontmatter) | Superseded 2026-08-16. The v0.7.x acceptance gate satisfied it: `v0.7.7` at `cfc7749f` → `agent/stable-release` `8f777ae6` → reconciled into `agent/integration` `82819f5a`. |
| Merge order steps 1–2 (promote v0.5.7, reconcile stable→integration) | Done, by the above. |
| Merge order steps 3–4 (merge five named branches) | All five are archived: `agent/archive/from-integration/{bbcode-injection-hardening,text-entry-governance,web-distribution-freeze,campaign-data-research,dialogue-recruit-capture-research}`. |
| *"Do not implement runtime, UI, schema, data, save, migration, or authoring-tool changes"* | The project has implemented continuously since. `B3-TEXT`, `B3-TCV`, `B3-REQ`/F16, the crossing resolver, the shell focus fix and the cadence/overworld track all landed while this row sat `planned`. |

The sharpest instance is in the handoff's own post-review sequence, which places
**"Requirement + shared record-screen foundations"** *after* the gate. `B3-REQ`/F16 was
built and merged on 2026-08-19/20. Its tracker row's dependencies are
`['B3-TEXT-BUILD-2026-08-19', 'B3-TCV-BUILD-2026-08-19']` — **no edge to this row exists**,
and `B3-REQ-F16-BUILD` is not among this row's 49 transitive dependents.

So the ordering was recorded in prose and not in the graph, and the graph is what anyone
actually reads. That is the same invisibility failure `B3-REQ`'s own row was created to
fix, one level up.

### 1.1 One correction to the row's own numbers

The row says it *"transitively gates 47 open rows"*. Computed from `coordination/tasks.json`
on 2026-08-20 the closure is **49** rows: 45 `planned`, 1 `blocked`, 1 `in_progress`, 2
`completed`. Both `completed` entries are administrative rather than evidence that work
jumped the gate — `PREP-V1-S04` was closed as a duplicate of `DRC-V1-S05`, and
`SUPPRESS-WEB-OS-KEYBOARD-2026-08-06` is unrelated to the portfolio sequence.

## 2. Recommended re-scope

Running the handoff verbatim produces a slice-by-slice evidence matrix measured against a
sequence the project has departed from, and a "first-tranche readiness verdict" for a
tranche that is partly built. Three of its deliverables are still worth having; one is not.

| Handoff deliverable | Recommendation |
|---|---|
| 1. Evidence matrix, every accepted slice → files/symbols → verdict | **Keep, re-baselined.** Measure against current `agent/integration`, and treat "already built" as a first-class verdict rather than an anomaly. |
| 2. Architecture collision report | **Keep — highest value, and §3 below is a down payment.** Nothing about it depended on the release gate. |
| 3. Corrected dependency edges and plan text | **Keep, and widen.** The prose-vs-graph divergence in §1 is exactly this deliverable's subject. |
| 4. First-tranche readiness verdict | **Drop.** The tranche is no longer un-started, so a go/no-go verdict on starting it answers a question nobody is asking. |

Also drop the handoff's blanket *"make no product-code changes"* clause. It was written for
a pre-implementation audit; today it would forbid fixing a one-line defect the review
itself surfaced, which is how findings rot. Keep the useful half — do not start a new
tranche — and let evidenced, in-scope fixes land with their tests.

## 3. Architecture collision report — first three, evidenced

Deliverable 2 asks for *"duplicate machinery, incorrect ownership, closed switches that
should be registries, and services at risk of becoming feature-aware god objects."* Three
collisions were found while dispositioning the `B3-REQ` audit and reviewing the cadence
branch. Each is evidenced against current `agent/integration`, and each now has a row.

### 3.1 Duplicate machinery — two formula evaluators

`scripts/registries/RequirementFormulaRegistry.gd` (static `evaluate(definition, facts,
depth)`, `MAX_DEPTH 8`) ships beside `scripts/req/FormulaEvaluator.gd` (bounded fixed-point,
`HARD_MAX_DEPTH 32`, `HARD_MAX_NODES 512`, explicit `on_zero`, registered value sources).
The `B3-REQ` row's own instruction was *"grow it or replace it, but do not ship two."* The
legacy class has exactly one reference in the project — `test_formula_registries.gd:63` —
and no production caller. Row: `REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20`.

### 3.2 A foundation with no consumers, twice over

`RequirementSystem` has **no production callers**: a search of `scripts/` excluding
`scripts/tests/` returns nothing. The stated justification for building it was that
`RequirementFormulaRegistry` had *"no production callers, only tests"* — the replacement
reproduced the property it was meant to cure. Its first real consumer is the cadence
engine, merged 2026-08-20.

This is the shape deliverable 2 exists to catch: a shared contract is "done" when it has
an API and a green suite, and stays inert until a feature adopts it. The portfolio's
contract-tracing step (handoff §4) should therefore verify each shared contract by
**naming its consumers**, not by confirming the contract exists.

### 3.3 Ownership — the shell ruling is not inheritable by construction

`[EPUX-07]`/`[RPD-15]` (gated entries stay in the focus order and carry a reason) is
implemented in two places: `ModalScreen` and `FocusNavigator`. `OverworldScreen`, added
2026-08-19, is a bare `Control` using neither, and reproduced the exact defect
`SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` had fixed shell-wide the previous day —
gated entries with no reason and no all-gated entry-focus fallback. Fixed in `9cae4dfc`
before that branch merged.

The collision is not the bug; it is that **a sixth availability surface can be written that
inherits nothing and fails nothing**. Two shared implementations with explanatory comments
help a reader already inside those files, and do not reach an author writing a new screen.
Whether the answer is a shared availability-list builder or a check that a `disabled`
`BaseButton` carries a reason is a design question, deliberately not decided here.

## 4. What this pass did not do

No evidence matrix, no dependency-edge sweep beyond the rows named above, no readiness
verdict. Those need the re-scope in §2 agreed first, because their shape depends on it. The
row stays `planned`.
