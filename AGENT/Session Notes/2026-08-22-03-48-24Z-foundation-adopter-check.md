# Session Note - 2026-08-22 — foundation-adopter guard

## Branch context

- Branch: `agent/from-integration/foundation-adopter-check`
- Base branch: `agent/integration`
- Base SHA: `d3dbb1a5`
- Coordination Work ID: `FOUNDATION-ADOPTER-CHECK-2026-08-22`

## What was done

Built the mechanical half of the clause that landed as prose on 2026-08-22 — *a
foundation closes on an adopter, not on its own tests* — as
`scripts/ci/check_foundation_adopters.py`.

**The row's stated design was wrong, and correcting it is most of the work here.**
It specified one query — "a `class_name` whose only references are its own file and
`scripts/tests/`" — and asserted that would have caught all three named instances.
Measured against the tree, it catches one:

| Named instance | What it actually is |
|---|---|
| `PrepActivityRegistry` | Live, but **not** a direct-reference orphan. `PrepActivityDef.gd` references it, and nothing reaches `PrepActivityDef`. A two-file orphan cluster passes a direct-reference check. |
| `RequirementFormulaRegistry` | **Does not exist.** Deleted by `REQ-LEGACY-REGISTRY-RECONCILE`; the only surviving mention is the comment recording the deletion. |
| `RequirementSystem` | Has **no `class_name`** — an autoload — and **has** a non-test caller: `CampaignManager.gd:453` resolves it at `/root/RequirementSystem`. Not an instance. |

So the check has two rules, because the engine has two foundation shapes:

1. **`class_name` types, by reachability**, walked out from real entry points — the
   `[autoload]` block in `project.godot` and every scene-attached script. This is what
   catches the orphan cluster a grep calls adopted.
2. **Autoloads, by direct reference.** An autoload is its own reachability root, so
   rule 1 can never flag one; and an `extends Node` service with no `class_name` is
   invisible to rule 1 either way.

**Comments do not count as adoption**, and that is not a theoretical refinement. The
first draft went green on `ControllerWebBridge` because a marker comment added in the
same pass named it, from a file that happens to be an autoload and therefore a
reachability seed. A guard its own explanatory prose can silence reads as evidence
while asserting nothing. `strip_comments` is that fix, with a quote-aware scan so a
`#` inside a string literal does not eat the code after it.

**Triaged, not baselined.** Ten instances, every one given a marker on its merits:

- `adopter-todo` (8), each naming the row that owes the consumer —
  `CampaignVarDef` → `B6-MUTABLE-CAMPAIGN-STATE-2026-07-23`;
  `ClassAdvancement` → `IMPL-ZERO-CONTENT-BASE-PACK` (that row already records the gap
  in its own words: advancement_edge documents are not emitted);
  `ControllerWebBridge` and `ControllerService` → `MOBILE-WEB-CONTROLLER-2026-08-04`;
  `PrepActivityDef` and `PrepActivityRegistry` → `PREP-V1-S01`;
  `ZeroContentFixtureValidator` → `ZERO-CONTENT-PREDICATE-FIXTURE-PLAN-2026-07-29`;
  `ConditionManager` → `B5-SKILLS-CONDITIONS-2026-07-23`.
- `adopter-allow` (2), where no in-repo caller can exist — `WebTestBridge` is read over
  `JavaScriptBridge` by the out-of-repo Playwright harness, and `SaveBudgetMeasurement`
  is a measurement fixture whose consumer is the suite that publishes its evidence.

## Gates

- `python3 scripts/ci/check_foundation_adopters.py` — PASS, 8 deferred, 2 waived.
- `python3 scripts/ci/test_check_foundation_adopters.py` — 12 tests OK. Every case is
  asserted in both directions, including the comment-mention incident above.
- `bash scripts/ci/run_required_non_godot_tests.sh` — PASS (5 Python files, 1 browser).
- `bash scripts/ci/check_gdscript_style.sh` — PASS, 335 files.
- `bash run_tests.sh` — **all 148 suites green.**

Wired into `scripts/hooks/pre-commit` and gated through the required-test runner,
which discovers `scripts/ci/test_*.py`, so the guard cannot be dropped from the gate by
forgetting a workflow line. The `.github/workflows` step is **deliberately not added** —
that path needs owner approval per `AGENTS.md`.

## Next

Add the CI workflow step (owner approval). The eight deferred markers are each
recoverable through the row they name; none blocks anything.
