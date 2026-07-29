# Master Review Procedure — Full Project Audit

> **Status:** Active — orchestrator for the complete project review
> **Last verified:** 2026-07-05

This is the top-level conductor for a **complete, skips-nothing review** of the
entire project: code, scenes/data/assets, tests/CI/build, documentation, and the
development process itself (audited against historical data). It does not contain
the per-area checklists — those live in the five **pillar** documents indexed
below. This document defines *how the whole thing is run, scored, and rolled up*.

A full run is deliberately **extensive and long**. It is not the per-commit
`/code-review`; it is the periodic deep audit. Expect it to surface dozens of
findings across all pillars and to take a multi-hour (multi-agent) pass.

---

## 1. When to run

Run a full audit when any of these is true:

- A milestone / version bump is imminent (e.g. before tagging `v0.2.0`).
- It has been ≳ 4 weeks or ≳ 30 commits since the last full audit.
- A large refactor branch (like `awakening-compatability-refactor`) is about to merge.
- After a painful playtest round, to find the systemic cause, not just the symptoms.

Soft reminder, not a gate: during session closeout, compare the newest
`AGENT/Code Reviews/full_review_rollup_*.md` snapshot date/commit with the
current branch. If the project is approaching the 4-week / 30-commit threshold,
add "full audit due soon" to the next-session note.

For everyday work use the lighter `/code-review` skill on the diff instead.

---

## 2. The five pillars

Each pillar is **self-contained, document-only, and independently dispatchable**
to its own sub-agent. Each produces one dated report and a 1–10 score.

| # | Pillar | Procedure doc | Default report output |
|---|--------|---------------|-----------------------|
| 1 | **Code** — GDScript logic, architecture, perf, security | `AGENT/Review Procedures/01_Code_Pillar.md` | `AGENT/Code Reviews/code_review_YYYY-MM-DD.md` |
| 2 | **Documentation** — GDD, governance, guides, doc↔code drift | `AGENT/Review Procedures/02_Documentation_Pillar.md` | `AGENT/Docs/documentation_review_YYYY-MM-DD.md` |
| 3 | **Scenes, Data & Assets** — .tscn wiring, .tres integrity, import pipeline | `AGENT/Review Procedures/03_Scenes_Data_Assets_Pillar.md` | `AGENT/Code Reviews/data_assets_review_YYYY-MM-DD.md` |
| 4 | **Tests, CI & Build** — coverage, run_tests, ci/hooks, export/docker | `AGENT/Review Procedures/04_Tests_CI_Build_Pillar.md` | `AGENT/Code Reviews/tests_ci_build_review_YYYY-MM-DD.md` |
| 5 | **Process & History** — workflow adherence, git, decisions, tooling | `AGENT/Review Procedures/05_Process_History_Pillar.md` | `AGENT/Code Reviews/process_history_review_YYYY-MM-DD.md` |

Coverage map (so nothing falls between pillars):

- `scripts/**.gd` non-test code → **Pillar 1**
- `scripts/tests/**`, `run_tests.sh`, `scripts/ci/**`, `scripts/hooks/**`,
  `test_fixtures/**`,
  `check_docs.py`, `.github/workflows/**`, `project.godot`, `export_presets.cfg`,
  `Dockerfile`, `docker-compose.yml`, **all `tools/` Python (godot-analyzer MCP +
  one-off scripts) and its pytest suite** → **Pillar 4**
- `scenes/**.tscn`, **all `*.tres` wherever they live** (`data/**`, `assets/**`,
  repo-root), `assets/**`, `Draft UI assets/`, `*.import`, `*.uid` sidecars,
  stray/empty top-level dirs, autoload *wiring* → **Pillar 3**
- `AGENT/GDD/**`, `AGENT/Docs/**` guides + governance, `README.md` → **Pillar 2**
- `AGENT/Session Notes/**`, git history, decision index/records, playtest
  findings, prior reviews, `AGENTS.md` rule adherence → **Pillar 5**

Nothing in the tree is unowned: every top-level dir (`AGENT/`, `assets/`,
`builds/` [gitignored artifacts], `ui_previews/` [gitignored artifacts —
`scripts/tools/ui_inspection_preview.gd` output], `Draft UI assets/`, `data/`,
`scenes/`, `scripts/`, `test_fixtures/`, `tools/`) and the root config files map to exactly one
pillar above.
The §3 tree-completeness preflight enforces this each run, and `check_docs.py`
check 11 fails if a new top-level dir appears that this map does not mention.

If a finding spans two pillars, the discovering pillar files it and tags it
`[CROSS]`; the rollup (§7) reconciles cross-pillar findings.

---

## 3. Shared prerequisites (the baseline)

Do this **once, before dispatching pillars**, and record the results in the
rollup header so every pillar reviews the same snapshot:

1. **Pin the snapshot.** Record the branch and commit SHA under review
   (`git rev-parse HEAD`) and confirm a clean working tree
   (`git status --porcelain`). A dirty tree means the audit is of an
   uncommitted state — note it explicitly.
2. **Probe the toolchain (MR-4).** Record what is actually available —
   `godot --version`, `python3`, `pytest`, `gdtoolkit` (gdlint/gdformat), `gh` —
   and pass the results to the pillars. Pillars must use the lowest-dependency
   runner available (e.g. the analyzer suite runs under stock `python3`, no pytest)
   and report a *missing* tool as a finding, never assume its absence is the defect.
3. **Establish the green baseline.** Run `python3 AGENT/Docs/check_docs.py`
   and `bash run_tests.sh`. Capture exit codes *before* piping output (a piped
   `| tail` masks a non-zero exit — MR-8). Record pass/fail. **Pillars assume these
   are green and must not re-do their work** — they go after what a script cannot
   judge. If either is red, that is the *first* finding (Critical) and pillars note
   that their baseline was unstable.
4. **Tree-completeness preflight (MR-1).** List every top-level dir
   (`ls -d */`) and the root config files, and confirm each maps to exactly one
   pillar in §2. If anything is unowned, the audit is incomplete — assign it before
   dispatching. (`check_docs.py` check 11 enforces the dir half of this.)
5. **Discover the delta baseline per pillar (MR-2).** For each pillar, find the
   *latest* matching prior report by filename pattern (e.g.
   `AGENT/Code Reviews/code_review_*.md`) and hand the pillar that **pattern**, not a
   first-run/last-report assertion — let the pillar resolve and confirm it, so a
   missed prior report (it happens) is caught, not asserted away.

---

## 4. Execution model — parallel sub-agents

The audit is designed to fan out. The orchestrator (you) does §3, then dispatches
**one sub-agent per pillar, in parallel**, each with:

- its pillar doc as the brief ("Follow `AGENT/Review Procedures/0N_*.md` exactly"),
- the pinned commit SHA, the §3 baseline results, and the toolchain probe,
- the **prior-report glob** for delta computation (not a first-run assertion — MR-2),
- the **output path with the same-day disambiguator** (MR-3): reports are
  `…_YYYY-MM-DD.md`; if that file already exists from an earlier run the same day,
  append a lowercase suffix (`…_YYYY-MM-DD-b.md`, `-c`, …), matching the existing
  `AGENT/Code Reviews/` convention. Never overwrite a same-day report.
- a **document-only** constraint: the pillar produces a report; it does **not**
  edit code or docs. Fixes are a separate follow-up pass after the rollup. Each
  pillar also returns **procedure-friction notes** (kept permanent — they feed the
  next meta-review).

Dispatch guidance:

- Use a read-only/explore-class agent where the pillar is pure analysis.
- Use `isolation: "worktree"` if a pillar needs to *run* things (Pillar 4 runs
  tests; Pillar 5 runs `git log`/`git blame`) so it can't disturb the main tree.
- Each pillar doc ends with a copy-paste **dispatch brief** — use it verbatim.
- Pillars are independent; if you cannot run them concurrently, run them in the
  order 4 → 1 → 3 → 2 → 5 (build/tests first establishes ground truth that the
  later pillars cite).

Each sub-agent returns: its report path, its 1–10 score, and its top 3 findings.

---

## 5. Shared severity rubric (single source of truth)

All pillars use these labels so the rollup can merge findings uniformly. The
*examples* are area-specific; the *bar* is the same.

| Severity | The bar |
|----------|---------|
| **Critical** | Crash, data loss, security hole, broken build/test gate, OR a live doc/decision that makes a reader do actively wrong work. |
| **High** | Correctness bug, serious perf issue, doc↔code drift on a shipped feature, untested critical path, a decision recorded but never implemented. |
| **Medium** | Maintainability / tech debt, governance-vocabulary violation, a real gap a contributor will hit, a rule duplicated where it can drift. |
| **Low** | Style, naming, weak cross-linking, minor cleanup. |

Every finding cites **evidence on both sides** where it is a drift/contradiction
claim: the source line *and* the thing it contradicts (`file:line`, a `data/…`
resource, a decision ID). A claim without a cited counter-source is an opinion —
flag it as an assumption, not a finding.

---

## 6. Scoring

Each pillar scores **1–10** using its own rubric (defined in its doc) on the same
shape: 9–10 exemplary, 7–8 solid with minor issues, 5–6 notable debt, 3–4 serious
problems, 1–2 broken. The rollup reports each pillar score plus an **overall
health score** = the *lowest* pillar score is the headline (a project is only as
healthy as its weakest audited pillar), with the rounded mean shown alongside for
trend tracking. Always compare against the previous audit's scores.

**Anchored score header (MR-6).** Every pillar report and the rollup MUST carry a
machine-readable score line so trend extraction can't mis-parse (a naive grep for
`N/10` hit a `150 / 10` code snippet last run). Use exactly, near the top:
`**Score:** N/10` in each pillar report, and `**Overall health:** N/10` in the
rollup. `check_docs.py` check 12 enforces this on `full_review_rollup_*.md`.

---

## 7. The rollup report

After all pillars return, the orchestrator writes one top-level rollup:

**Path:** `AGENT/Code Reviews/full_review_rollup_YYYY-MM-DD.md`

Sections:

1. **Header / snapshot** — branch, commit SHA, dirty?, baseline results
   (`check_docs.py`, `run_tests.sh`), date, list of pillar reports with links.
2. **Scorecard** — table of the five pillar scores + overall, each with the
   delta vs the previous audit.
3. **Executive summary** — 3–5 sentences: biggest strengths, single most
   important concern, overall trajectory.
4. **Cross-pillar findings** — every `[CROSS]`-tagged finding reconciled into one
   entry with a single owner pillar (de-duplicate; don't double-count).
5. **Unified prioritized action plan** — all pillars' findings merged and
   re-ranked by impact ÷ effort across the whole project, not per-pillar. This is
   the artifact the next work session actually executes from.
6. **Process & tooling recommendations** — surfaced from Pillar 5: workflow or
   tooling changes that would improve results or developer experience.
7. **Regression watch** — anything fixed in a prior audit that has reappeared.

---

## 8. Feedback loop (definition of done)

A full audit is not done when the reports are written — it is done when it has
fed back into the project:

1. Write the rollup (§7) and all five pillar reports.
2. Turn the unified action plan into tracked work (the next session's plan, or
   roadmap/feature-index entries for anything systemic).
3. Per **DoD#2**: if the audit ratifies a new mechanical, checkable rule, land its
   check in `AGENT/Docs/check_docs.py` in the follow-up — a rule with no check
   rots. (See §10 for current enforcement candidates.)
4. Per **DoD#1**: if the audit drives a behavior/doc change, update the affected
   GDD section *and* `GDD_10_Roadmap.md` status in the same commit.
5. Write a session note and add its row to `AGENT/Session Notes/INDEX.md`.
6. Fixes themselves land as a **separate** pass after the audit — the audit
   documents, it does not refactor.

---

## 9. Historical-data catalog (for Pillar 5 and deltas)

Where the project's history lives, so an audit can reconstruct what happened:

- **Session notes** — `AGENT/Session Notes/*.md` + `INDEX.md` (newest first;
  each row summarizes a session's work, commits, and next-session plan).
- **Prior reviews** — `AGENT/Code Reviews/code_review_*.md` and
  `AGENT/Docs/documentation_review_*.md` (score + finding trends over time).
- **Decisions** — `AGENT/Docs/decision_index.md` (one row per decision ID) plus
  the individual `decision_record_*` / `*_decisions_*` files.
- **Playtests** — `AGENT/Docs/playtest*_findings_*.md`, `playtest_*fix_plan_*.md`,
  `playtest_checklist_*.md`, and `AGENT/GDD/Play_tester_comments.md`.
- **Governance** — `AGENT/Docs/documentation_governance_2026-06-13.md` and
  `documentation_lifecycle_2026-06-13.md` (the rubric Pillar 2 grades against).
- **Git** — `git log`, `git blame`, `git shortlog` for granularity, message
  quality, and whether commits matched their session-note plans.

---

## 10. Enforcement candidates (DoD#2 backlog)

Mechanical rules this procedure relies on. **Landed** ones run in `check_docs.py`
and/or CI; **remaining** ones are honor-system until ratified (list any violation as
a Pillar 2 finding).

**Landed (as of 2026-06-14):**
- **`.uid` tracking** — `check_docs.py` check 9: every `.uid` sidecar on disk is
  git-tracked (untracked UIDs break fresh clones).
- **Release version ↔ tag** — check 10: `product_version` must have a `v<version>` tag.
- **Tree-completeness** — check 11: every top-level dir is named in the §2 coverage map.
- **Anchored rollup score** — check 12: `full_review_rollup_*.md` carries an
  `**Overall health:** N/10` line for reliable trend parsing.
- **`tools/` analyzer tested in CI** — `tools/godot-analyzer-mcp/tests/` runs in both
  workflows (stdlib `unittest`; no pytest dependency).
- **Scene-integrity gate** — `scripts/ci/check_scene_integrity.py` runs in CI: every
  scene-attached `@onready` path resolves.

**Remaining:**
- **GDScript lint/format gate** — `gdlint`/`gdformat` (gdtoolkit) in hooks/CI.
  Needs a pip dependency + a one-time whole-repo reformat; do it on a pip-capable
  machine (it can't run where pip is absent).
- **Procedure-folder scan** — add `AGENT/Review Procedures/**` to `check_docs.py`'s
  path-scan set (skip `YYYY-MM-DD`/glob placeholders) so its backtick paths validate.
- **Pillar-report score line** — extend check 12 to each `*_review_*` report, not
  just the rollup (deferred: ~20 historical reports predate the convention).
- **Rollup links to exactly five pillar reports**, and **one severity table**
  (single-source-of-truth: the rubric lives only in §5).

---

## 11. Lifecycle of this folder

These procedure docs are **Active** living documents. When a pillar's checklist
is improved, bump its `Last verified` date. The two predecessor files
(`AGENT/Docs/code_review_instructions.txt`,
`AGENT/Docs/documentation_review_instructions.md`) are **Superseded** by Pillars 1
and 2 respectively and kept only for provenance.
