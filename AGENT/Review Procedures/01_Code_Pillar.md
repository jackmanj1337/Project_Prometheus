# Pillar 1 — Code Review

> **Status:** Active — supersedes `AGENT/Docs/code_review_instructions.txt`
> **Last verified:** 2026-06-14
> **Part of:** `AGENT/Review Procedures/00_Master_Review_Procedure.md`

Judges the **GDScript source logic** — correctness, architecture, performance,
security, and adherence to GDScript style. Read the master doc for the shared
severity rubric (§5) and the document-only constraint.

## 1. Mandate & non-goals

**In scope:** non-test `.gd` files under `scripts/` — `ai/`, `autoloads/`,
`core/`, `items/`, `resources/`, `shared/`, `skills/`, `units/`, `ui/`, `tools/`.

**Out of scope (owned elsewhere):** test code and CI (Pillar 4); `.tscn` wiring,
`.tres`/`data/` integrity, autoload *registration* (Pillar 3); docstring/GDD
accuracy as documentation (Pillar 2 — but missing docs on a public API is a Low
finding here too). Assume `run_tests.sh` is green (master §3); do not re-run the
suite to find failures — that is Pillar 4's job.

## 2. Inputs

All non-test `scripts/**.gd`. Use `mcp__godot-analyzer__get_autoloads` to know the
singleton surface, and `grep`/`Read` for everything else. Pin to the master's SHA.

## 3. Historical data to consult

Prior code reviews in `AGENT/Code Reviews/code_review_*.md` (for recurring issues
and to compute the delta), plus the RNG design at
`AGENT/Docs/rng_determinism_design_2026-06-11.md`.

## 4. Procedure (exhaustive)

Work file-group by file-group. For each, check:

**A. Correctness & logic**
- Edge cases, off-by-one, empty/null inputs, integer division, unit/grid bounds.
- Error handling: are failure paths handled or do they silently no-op?
- Signal connections: connected once, disconnected when needed, no leaks.
- State machines (combat, turn flow): every state reachable and exitable.

**B. GDScript idioms & style**
- Typed variables, params, and return types; `@export` types correct.
- Naming per GDScript style guide (snake_case funcs/vars, PascalCase classes,
  CONSTANT_CASE consts).
- No dead code, commented-out blocks, or unreachable branches.
- Duplication: same logic in 3+ places → flag for a shared helper.

**C. Known GDScript footguns (project-specific checklist)**
- **Setter recursion** — inline setters assigning to their own property recurse
  infinitely; require a backing variable.
- **Headless autoload cross-refs** — autoloads referencing each other by
  identifier fail in headless `--script` runs; require
  `get_node_or_null` + `.get()/.call()`.
- **Exported node refs to later siblings** — `@export` Node refs can resolve null;
  re-resolve via `get_node_or_null` in `_ready()`.
- **Typed-array call sites** — a bare `[]` won't satisfy an `Array[String]` param;
  a typed local is needed.
- **Class cache** — new `class_name` scripts need the global class-cache entry or
  headless runs can't resolve them.

**D. Architecture & coupling**
- Autoload boundaries: are singletons doing too much / reaching across layers?
- Separation of concerns: UI logic leaking into core, core reaching into UI.
- Resource vs. node responsibilities respected.

**E. Determinism & RNG**
- All randomness goes through the project RNG service (no raw `randi()/randf()`
  in gameplay paths); seeds threaded correctly per the RNG design doc.

**F. Performance**
- Per-frame allocations in `_process`/`_physics_process`; work that could be
  cached or event-driven; large loops over units/tiles each frame.

**G. Security (online play surface)**
- Input validation on anything crossing the network boundary
  (see `AGENT/Docs/online_play_design_decisions.md`); no secrets in source.

## 5. Spot-check requirements

State your sample. Verify falsifiable claims (a formula constant, a bounds check,
a signal lifecycle) by reading the code — not vibes. Cite `file:line` for every
finding; for "this is wrong" cite the correct behavior's source too.

## 6. Output report

**Path:** `AGENT/Code Reviews/code_review_YYYY-MM-DD.md`. Sections: Executive
summary + 1–10 score; Issues (severity-tagged, with File&Line / Problem / Root
cause / Recommended fix / Tradeoffs); ≥3 Positive observations; Architectural
observations; Prioritized action plan; **Delta vs previous review**
(new/fixed/regressed). Tag cross-pillar items `[CROSS]`. The delta section may
necessarily *reference* another pillar's files (e.g. a prior finding that was
`.tscn`-rooted) — that is expected; cite it with a `[CROSS]` tag rather than
treating it as out of scope. Note when a "new" item is *newly-scoped* by a fuller
review rather than newly-introduced, so it isn't mistaken for a regression.

## 7. Sub-agent dispatch brief

> You are the **Code** pillar of the full project audit. Follow
> `AGENT/Review Procedures/01_Code_Pillar.md` exactly. Review non-test
> `scripts/**.gd` at commit `<SHA>`. Assume `run_tests.sh` and `check_docs.py`
> are green (baseline: `<results>`); do not re-run them. Document only — do not
> edit code. Compute deltas against `<prev code_review path>`. Produce the report
> at `AGENT/Code Reviews/code_review_<DATE>.md` and return its path, your 1–10
> score, and your top 3 findings.
