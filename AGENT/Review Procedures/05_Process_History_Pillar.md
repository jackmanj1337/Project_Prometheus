# Pillar 5 — Process & History Review

> **Status:** Active — new pillar (no predecessor)
> **Last verified:** 2026-07-17
> **Part of:** `AGENT/Review Procedures/00_Master_Review_Procedure.md`

The meta-pillar. The other four judge *artifacts at a point in time*; this judges
**how the project is actually being worked on**, by mining the historical record —
session notes, git history, the decision register, and prior playtests/reviews.
Its second job is forward-looking: recommend tooling and workflow changes that
would improve results or developer experience.

## 1. Mandate & non-goals

**In scope:** `AGENT/Session Notes/**` + `INDEX.md`, git history, the decision
system (`AGENT/Docs/decisions/decision_index.md` + decision records), playtest
findings, prior reviews in `AGENT/Code Reviews/`, the coordination registry, and
adherence to every applicable policy layer: this repository's `AGENTS.md` and,
when the checkout is inside the shared workspace, the workspace-level
`../AGENTS.md` fallback rules.

**Out of scope:** judging the *current* code/docs/data — that is Pillars 1–4. This
pillar judges the *process that produced them* and the *trends* across time.

## 2. Method — sample, don't boil the ocean

There are hundreds of session notes and commits. Do **not** read every note
manually. Split the work into two modes:

- Run available mechanical checkers over the **whole applicable history/tree**
  (for example `scripts/session_closeout.sh`, the coordination-registry checker,
  and documentation checks). A representative sample cannot waive a mechanical
  rule.
- For qualitative judgments, take a **representative sample**: the last ~10
  sessions in full; a stratified sample across the project's life (at least one
  per ~2 weeks); release, feature, correction, and closeout sessions; plus every
  session that a prior review or playtest flagged.

State both the whole-history/tree checks and the qualitative sample explicitly.
Use `git log`, `git shortlog`, and `git blame` for breadth; read notes for depth.

## 3. Procedure (exhaustive)

**A. Workflow adherence (against `AGENTS.md`)**
- **DoD#1** — when a sampled change altered behavior, did the *same commit* update
  the affected GDD section AND flip the `GDD_10_Roadmap.md` status? Find
  behavior-changing commits with no paired doc update.
- **DoD#2** — when a mechanical rule was ratified, did the same change add its check
  to `check_docs.py`? Find rules that landed as prose only.
- **Documentation-system discipline** — when documents were added, moved,
  retitled, or had indexed headers changed, were `AGENT/Docs/INDEX.md` and
  `REGISTERS.md` regenerated in the same change? Are live documents in the
  type-based folders and historical documents retained under `archive/**` with a
  Historical/Superseded marker in their first 10 lines?
- **Session discipline** — did each working session start from
  `AGENT/Session Notes/TEMPLATE.md`, record branch/base/base SHA/Coordination Work
  ID, outcomes, gates/evidence, and a bounded next action? Did it claim every
  substantive non-merge commit exactly once by full SHA and exact subject, while
  exempting note/index-only closeout commits? Did it add a newest-first
  `INDEX.md` row and pass `bash scripts/session_closeout.sh` before handoff or
  push? Find commits with no note, duplicate/unclaimed commits, malformed notes,
  and notes missing from the index.
- **Commit-per-logical-step** — were commits made after each logical step, or
  batched into mega-commits?
- **Attribution and protected content** — do sampled commits retain the human
  author/committer, omit model `Co-authored-by` trailers, and carry the required
  `AI-Tool`, `AI-Model`, `AI-Run-ID`, and `AI-Workspace` trailers? Check the
  complete changed-file history for prohibited secrets/signing credentials and
  check that approval-controlled workflow, Docker, signing, and release-
  automation changes have recorded user authorization.

**B. Git history hygiene**
- Commit-message quality: imperative, specific, references to the work (not
  "wip"/"fixes"). Sample and rate.
- Granularity: median diff size; ratio of mega-commits to focused commits.
- Plan adherence: do commits in a session match that session note's stated plan?
  Flag scope drift (lots of unplanned commits) and abandoned plans (planned work
  with no commit).
- Branch/version discipline and coordination provenance:
  - agents create, commit, and push only `agent/**`; `main`, `integration`,
    `release/**`, and `coordination` remain human-controlled lifecycle refs;
  - feature work uses the registered integration/release base, and ownership is
    registered before implementation with branch, base, and exact source SHA;
  - the coordination record retains test/playtest evidence and final disposition;
  - task creation rejects local/remote ref-prefix collisions, and a viable
    sibling branch is used when a lifecycle ref already occupies the prefix;
  - superseded branches are recorded for human retirement rather than rewritten
    or deleted by an agent;
  - release preparation/build records name the checked-out source branch and
    commit, version bumps land cleanly, and release tags match the baked BUILD
    STAMP plus recorded export size/SHA-256;
  - agents do not push protected refs, force/move/delete remote tags, or merge
    PRs; humans perform protected-ref advancement and PR creation/merge.

**C. Decision traceability**
- Every `AGENT/Docs/decisions/decision_index.md` entry → is it reflected in code
  AND docs? Find
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
sessions/commits examined, plus whole-history/tree checks run);
Workflow-adherence findings (DoD#1/DoD#2/documentation/session/commit/attribution,
each with cited commits); **Branch, coordination & release-provenance
assessment**; Git-hygiene assessment; Decision-traceability table (decision ID →
in code? → in docs? → status); Process-effectiveness analysis (recurring defect
classes, score trend, repeatedly-violated rules); **Tooling & workflow
recommendations** (evidence-backed, effort-tagged); ≥3 Positive observations;
Prioritized action plan; **Delta vs previous review**. Tag cross-pillar items
`[CROSS]`.

## 5. Sub-agent dispatch brief

> You are the **Process & History** pillar of the full project audit. Follow
> `AGENT/Review Procedures/05_Process_History_Pillar.md` exactly. Mine the
> historical record (session notes + INDEX, `git log`/`shortlog`/`blame`, decision
> index/records, coordination records, playtest findings, prior reviews) up to
> commit `<SHA>`. Run available mechanical checks across the whole applicable
> history/tree, then take a stated representative sample for qualitative review —
> do not read every note manually. Document only. Compute deltas against
> `<prev process_history_review path>`. Produce the report at
> `AGENT/Code Reviews/process_history_review_<DATE>.md` and return its path, your
> 1–10 score, your top 3 findings, and your top tooling/workflow recommendation.
