# Pillar 4 — Tests, CI & Build Review

> **Status:** Active — new pillar (no predecessor)
> **Last verified:** 2026-06-14
> **Part of:** `AGENT/Review Procedures/00_Master_Review_Procedure.md`

Judges the project's **safety net and shippability**: test coverage and quality,
the CI/hook gates, the documentation checker, and the build/export/Docker config.
This pillar is the one that *runs things* — it establishes the ground truth the
other pillars assume.

## 1. Mandate & non-goals

**In scope:** `scripts/tests/**`, `run_tests.sh`, `scripts/ci/**`,
`scripts/hooks/**`, `AGENT/Docs/check_docs.py`, `.github/workflows/**`,
`project.godot` (build/input/autoload *settings*), `export_presets.cfg`,
`Dockerfile`, `docker-compose.yml`.

**Out of scope:** the logic being tested (Pillar 1); the *content* of scenes/data
(Pillar 3); the *prose* of the Docker/testing guides (Pillar 2 — but a guide whose
documented command no longer works is a `[CROSS]` you raise).

Run in a **worktree** (master §4) so running tests can't disturb the main tree.

## 2. Procedure (exhaustive)

**A. Test execution & health**
- Run `./run_tests.sh`; record pass/fail/skipped counts and runtime. This is the
  baseline the other pillars cite — report it precisely.
- Any skipped/disabled tests: is there a written reason and a removal condition?
- Flakiness / order-dependence: do tests rely on shared state or RNG without a
  pinned seed?

**B. Coverage mapping**
- Map `scripts/tests/*` to the systems under `scripts/`. Which subsystems (ai,
  core, skills, units, items, combat flow) have **no** meaningful test?
- Critical paths (turn flow, combat resolution, save/load, promotion/reclass,
  pair-up) — each should have a regression test. Flag uncovered critical paths
  High.
- Headless-safety of tests (autoload cross-ref, class cache, typed arrays) — tests
  that pass in-editor but would fail headless are a real gap.

**C. CI & hooks**
- `.github/workflows/**`: do they run `run_tests.sh` *and* `check_docs.py`? Is the
  gate actually blocking (not `continue-on-error`)?
- `scripts/hooks/**` pre-commit: does it match CI (same checks), so local and
  remote agree? Drift between hook and CI is a Medium finding.

**D. `check_docs.py` enforcement audit**
- Which governance/AGENTS.md rules are *stated but unchecked*? Cross-reference the
  master doc's PL#9 backlog and Pillar 2's coverage gaps. Recommend concrete new
  checks. (This is the PL#9 health check.)

**E. Build / export / packaging**
- `export_presets.cfg` valid and matching the platforms you actually ship.
- `project.godot`: autoloads, input map, and rendering settings sane; version
  string consistent with the latest build manifest / handbook.
- Version-string consistency across `project.godot`, README, and the current
  playtest handbook (a mismatch ships the wrong version number).
- `Dockerfile` / `docker-compose.yml` build, and `AGENT/Docs/Docker Instructions.md`
  commands still work.

## 3. Spot-check requirements

State exactly what you ran and its output (counts, runtime, exit codes). For
coverage gaps, name the untested script and the critical behavior it owns.

## 4. Output report

**Path:** `AGENT/Code Reviews/tests_ci_build_review_YYYY-MM-DD.md`. Sections:
Executive summary + 1–10 score; **Baseline results** (test counts/runtime,
check_docs status — this is what the rollup header quotes); Issues (severity-
tagged); Coverage gap table (system → has-test? → criticality); CI/hook findings;
PL#9 enforcement-gap list; Build/export findings; ≥3 Positive observations;
Prioritized action plan; **Delta vs previous review**. Tag cross-pillar items
`[CROSS]`.

## 5. Sub-agent dispatch brief

> You are the **Tests, CI & Build** pillar of the full project audit. Follow
> `AGENT/Review Procedures/04_Tests_CI_Build_Pillar.md` exactly, at commit
> `<SHA>`, in an isolated worktree. You MAY run `./run_tests.sh`,
> `python3 AGENT/Docs/check_docs.py`, and docker/export builds — but do not edit
> code or docs. Report the precise baseline results (the rollup quotes them).
> Compute deltas against `<prev tests_ci_build_review path>`. Produce the report
> at `AGENT/Code Reviews/tests_ci_build_review_<DATE>.md` and return its path,
> your 1–10 score, the baseline results, and your top 3 findings.
