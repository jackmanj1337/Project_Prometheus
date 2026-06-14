# Pillar 5 — Process & History Review

> **Status:** Active — new pillar (no predecessor)
> **Last verified:** 2026-06-14
> **Part of:** `AGENT/Review Procedures/00_Master_Review_Procedure.md`

The meta-pillar. The other four judge *artifacts at a point in time*; this judges
**how the project is actually being worked on**, by mining the historical record —
session notes, git history, the decision register, and prior playtests/reviews.
Its second job is forward-looking: recommend tooling and workflow changes that
would improve results or developer experience.

## 1. Mandate & non-goals

**In scope:** `AGENT/Session Notes/**` + `INDEX.md`, git history, the decision
system (`AGENT/Docs/decision_index.md` + decision records), playtest findings,
prior reviews in `AGENT/Code Reviews/`, and adherence to `AGENTS.md` rules.

**Out of scope:** judging the *current* code/docs/data — that is Pillars 1–4. This
pillar judges the *process that produced them* and the *trends* across time.

## 2. Method — sample, don't boil the ocean

There are ~140 session notes and hundreds of commits. Do **not** read them all.
Take a **representative sample**: the last ~10 sessions in full, plus a stratified
sample across the project's life (one per ~2 weeks), plus every session that a
prior review or playtest flagged. State your sample explicitly. Use `git log`,
`git shortlog`, and `git blame` for breadth; read notes for depth.

## 3. Procedure (exhaustive)

**A. Workflow adherence (against `AGENTS.md`)**
- **PL#8** — when a sampled change altered behavior, did the *same commit* update
  the affected GDD section AND flip the `GDD_10_Roadmap.md` status? Find
  behavior-changing commits with no paired doc update.
- **PL#9** — when a mechanical rule was ratified, did the same change add its check
  to `check_docs.py`? Find rules that landed as prose only.
- **Session discipline** — did each working session produce a session note AND an
  `INDEX.md` row? Find sessions with commits but no note, or notes missing from
  the index.
- **Commit-per-logical-step** — were commits made after each logical step, or
  batched into mega-commits?

**B. Git history hygiene**
- Commit-message quality: imperative, specific, references to the work (not
  "wip"/"fixes"). Sample and rate.
- Granularity: median diff size; ratio of mega-commits to focused commits.
- Plan adherence: do commits in a session match that session note's stated plan?
  Flag scope drift (lots of unplanned commits) and abandoned plans (planned work
  with no commit).
- Branch/version discipline: version bumps land cleanly; no work committed to a
  branch that contradicts its name.

**C. Decision traceability**
- Every `decision_index.md` entry → is it reflected in code AND docs? Find
  decisions **recorded but never implemented** (High) and **implemented but never
  recorded** (Medium — invisible decisions).
- Supersession links are bidirectional (X → superseded by Y, and Y → supersedes X).
- Status vocabulary in the index is internally consistent.

**D. Process effectiveness (the trends)**
- **Recurring defect classes:** across `playtest*_findings_*` and prior code
  reviews, what bug *categories* keep recurring? (e.g. headless autoload issues,
  combat-preview rendering, RNG.) A class that recurs 3+ times is a process gap,
  not bad luck — recommend a guard/test/check for it.
- **Review-score trend:** plot the 1–10 scores from prior reviews over time —
  improving, flat, or regressing?
- **Repeatedly-violated rules:** which `AGENTS.md`/governance rules show up as
  violations in multiple reviews? Those need either better enforcement or a
  rewrite.
- **Rework rate:** how often is the same area touched by a "fix" shortly after a
  "feature" commit? High churn signals weak upfront design or testing.

**E. Tooling & workflow recommendations (deliverable)**
- Concrete, justified suggestions: a new `check_docs.py` rule, an MCP/tool that
  would catch a recurring class, a template that would reduce a repeated mistake,
  a CI gate, or a workflow simplification. Each recommendation cites the
  historical evidence that motivates it (the recurring pattern it addresses) and
  estimates effort.

## 4. Output report

**Path:** `AGENT/Code Reviews/process_history_review_YYYY-MM-DD.md`. Sections:
Executive summary + 1–10 process-health score; **Sample statement** (which
sessions/commits examined); Workflow-adherence findings (PL#8/PL#9/session/commit,
each with cited commits); Git-hygiene assessment; Decision-traceability table
(decision ID → in code? → in docs? → status); Process-effectiveness analysis
(recurring defect classes, score trend, repeatedly-violated rules); **Tooling &
workflow recommendations** (evidence-backed, effort-tagged); ≥3 Positive
observations; Prioritized action plan; **Delta vs previous review**. Tag
cross-pillar items `[CROSS]`.

## 5. Sub-agent dispatch brief

> You are the **Process & History** pillar of the full project audit. Follow
> `AGENT/Review Procedures/05_Process_History_Pillar.md` exactly. Mine the
> historical record (session notes + INDEX, `git log`/`shortlog`/`blame`, decision
> index/records, playtest findings, prior reviews) up to commit `<SHA>`. Take a
> stated representative sample — do not read everything. Document only. Compute
> deltas against `<prev process_history_review path>`. Produce the report at
> `AGENT/Code Reviews/process_history_review_<DATE>.md` and return its path, your
> 1–10 score, your top 3 findings, and your top tooling/workflow recommendation.
