# Process & History Review — 2026-06-14 (Pillar 5)

> **Status:** Historical — first Process & History pillar audit (no predecessor report).
> **Procedure:** `AGENT/Review Procedures/05_Process_History_Pillar.md`
> **Snapshot:** branch `awakening-compatability-refactor`, commit `e924bb4`.
> **Baseline (from orchestrator):** `check_docs.py` = PASS, `run_tests.sh` = PASS.
> **Working tree:** NOT clean — 3 untracked files at snapshot time
> (`AGENT/Docs/950MERC Promotion.png.import`, `scripts/resources/CampaignRules.gd.uid`,
> `scripts/tests/test_unit_inventory_refs.gd.uid`). These are generated sidecars/import
> files, not in-progress work; see Git-hygiene §B-4 (`[CROSS]` Pillar 3/4).

## Executive summary

The development process is **mature, disciplined, and unusually well-documented for a
solo project**. Session-note discipline is near-perfect (91 notes, INDEX bidirectionally
complete), commit messages are exemplary (imperative, specific, cross-referencing
playtest IDs and prior commit SHAs), and the decision register is honest — including
correctly labelling not-yet-shipped design as "Target design" rather than pretending it
is live. The PL#8 (paired GDD+roadmap) and PL#9 (rule→check) loops are visibly followed
in recent commits.

The weaknesses are **structural git hygiene and branch strategy**, not daily discipline:
(1) **zero release tags** despite five version bumps (v0.1.0→v0.1.5.0) — you cannot
`git checkout v0.1.4`; (2) a **long-lived branch 242 commits ahead of `main`** whose name
("awakening-compatability-refactor") no longer matches its contents — the last ~3.5 weeks
of work is playtest fixes, doc consolidation, and review tooling, while the actual AWR
refactor milestones (AWR-2 class migration, AWR-8 terrain) remain unstarted; and (3) a
small but real **recurring-defect signal** concentrated in the Pair Up and combat-preview
subsystems.

**Process-health score: 8 / 10** — solid with minor issues. The day-to-day workflow is
a model; the deductions are for git/branch strategy and two recurring defect classes that
a guard or design pass would close.

## Sample statement

Per the pillar method (do not boil the ocean), the examined sample was:

- **Last 10 sessions in full:** `2026-06-14b`, `2026-06-14`, `2026-06-13n`, `2026-06-13m`
  (read complete); `2026-06-13l`…`2026-06-13b`, `2026-06-13` skimmed via INDEX + commits.
- **Stratified across project life (~one per 2 weeks):** `2026-05-10` (project genesis),
  `2026-05-18` (design-only multiplayer decisions), `2026-05-24` (Pair Up Separate),
  `2026-06-09` (playtest fix-plan kickoff).
- **Flagged by prior reviews/playtests:** the combat-preview render chain
  (`2026-06-10`/`-11`) and the Pair Up integrity work (playtest fix plan 2026-06-09).
- **Breadth via git:** `git log` (543 commits total), `git shortlog -sn`, `git log --stat`,
  `git rev-list --count main..HEAD`, churn-by-file counts.
- **Decision system:** full `decision_index.md` read; supersession + traceability spot-checks.
- **Prior reviews:** all 23 `code_review_*.md` score lines extracted for the trend.
- **Not read in full:** the ~80 other session notes, individual decision-record bodies
  beyond the index, every playtest finding line-by-line.

## A. Workflow adherence (against `AGENTS.md`)

### PL#8 — paired GDD + roadmap updates — **PASS (strong)**
Recent behavior-changing commits carry the paired doc update in the same commit. The
`2026-06-14` session note documents `Last verified` bumps on GDD_02/03/04/05/06/07/08/10
and GDD_10 status flips alongside each fix (e.g. Defect 3 `b53a385` shipped with GDD_05/GDD_10
updates; Obs 8.6 `f51e8db` was docs-only by design). No behavior-changing commit in the
sampled window was found landing code with no paired doc update.

### PL#9 — rule → check landed same change — **PASS (strong)**
The clearest positive in the audit: when the 2026-06-13m review ratified "no new unmarked
engine RNG," the **same fix commit `4b3241d`** added `scripts/ci/check_rng_usage.sh`, tagged
the four known sites `# rng-allow: pre-M9a (RNG-1)`, and wired the guard into the pre-commit
hook *and* both CI workflows. DOC-013 (split-status phrasing) similarly shipped with
`check_docs.py` checks 7–8 in `cf153d8`. This is the rule-with-a-check discipline working as
designed.

### Session discipline — **PASS (near-perfect)**
- Every session-note file has a matching INDEX row (bidirectional check: **0 orphans, 0 dead
  links** across 91 notes vs. 96-line INDEX).
- INDEX summaries are clean one-liners (the truncated auto-seed was repaired in `2026-06-13n`).
- Note quality is high: each has What-was-done / Commits / Tests-gates / Next-session.

### Commit-per-logical-step — **PASS (strong)**
The `2026-06-14` round is the model: one commit per defect, each with its regression test
(`c69347b` iron_axe, `4924dde` Swap, `8c2ff81` rout, `2080b29` New Game, `e7afb51` promotion,
`b53a385` pair-up). No mega-commits in the sampled window. The one genesis commit `33d3226`
("Implement Milestone 0 + Milestone 1") batched the whole data layer, but that is acceptable
for an initial scaffold.

**Minor note (Low):** the `2026-06-14b` session note says the procedure work landed in "(this
commit)", but it actually split across two commits (`1dd4b87` create + `e924bb4` coverage-gap
expansion); `e924bb4` is not reflected in that note. Cosmetic — the note predates the second
commit.

## B. Git-history hygiene

1. **Message quality — Excellent.** Sampled 40 recent messages: imperative mood, specific,
   and cross-referencing (playtest IDs `#2`/`#8.5`, prior SHAs, decision IDs). No
   "wip"/"misc"/"fixes" noise.

2. **Granularity — Good.** 543 commits, 78 (~14%) are "fix"-prefixed — a reasonable rate for
   a playtest-driven game; not churn-pathological. Median diff is focused.

3. **Author identity (Low):** 541 commits as `jackmanj1337`, 2 as `Jacob Jackman` — same
   person, inconsistent `user.name`. Harmless but worth normalizing.

4. **Release tagging — MISSING (High, git-hygiene).** `git tag` returns **nothing** despite
   version bumps to v0.1.0, v0.1.3, v0.1.3a, v0.1.4, and v0.1.5.0 (`5ccb508`). There is no
   way to `git checkout v0.1.4` to reproduce a build a tester reported against. Each
   `playtest_build_*.md` manifest records a binary SHA-256 but not a git tag, so the
   source→binary link is by prose, not by ref.

5. **Branch strategy — concerning (Medium→High).** HEAD is **242 commits ahead of `main`**,
   branched `979b91a` (2026-05-21, ~3.5 weeks ago), and `main` has received no merge. The
   branch name `awakening-compatability-refactor` no longer describes its contents: the last
   ~25 commits are 23/25 playtest-fix / version-bump / doc / review-procedure work. The
   actual AWR refactor (AWR-2 class corpus migration, AWR-8 terrain migration) is still a
   roadmap milestone, unstarted. This is scope drift on a long-lived branch — a single
   merge/rebase event will be large and risky.

6. **Plan adherence — Good.** Sampled session plans match their commits (e.g. `2026-06-14`'s
   "fix every implementable defect" → 6 defect commits + 3 observation commits, all listed).
   No abandoned-plan / phantom-commit mismatches found in the sample.

## C. Decision traceability

The decision register (`decision_index.md`) is **honest and bidirectionally linked**. Spot-checks:

| Decision ID | In code? | In docs? | Status / traceability verdict |
|-------------|----------|----------|-------------------------------|
| RULE-001 (two-RN hit) | **No** (code is single-roll `randi()%100`, `CombatResolver.gd:450`) | Yes (GDD_02/GDD_01) | **Correctly** labelled "Applied (Target design)" + "code is Package A" — not a false "shipped" claim. Tracked via `# rng-allow: pre-M9a (RNG-1)` tags + RNG guard. Not a violation. |
| RNG-1 (chained dice) | No (M9a) | Yes | "Applied (Target design)", roll-order amended by RULE-001. Honest. |
| DOC-001 ↔ D-C | n/a (governance) | Yes | Supersession **bidirectional**: DOC-001 "Supersedes D-C", D-C "Superseded by DOC-001". ✔ |
| DOC-013 (split-status) | Yes (`check_docs.py` 7–8) | Yes (GOV + GDD_02–05/08) | Applied; rule+check shipped together. ✔ |
| RULE-012 (Pair Up scope) | Yes (Pair Up pass 1 shipped) | Yes (GDD_05) | Applied. ✔ |
| RULE-011 (terrain ID map) | No | Open decision | "Deferred", roadmap owner AWR-8. Honest. |

- **Recorded-but-unimplemented:** several "Target design" RNG/two-RN/terrain decisions —
  but all are **explicitly status-labelled as target/deferred and tracked to a milestone**
  (M9a, AWR-8). None are silently claimed as live. No High finding here.
- **Implemented-but-unrecorded (invisible decisions):** none material found. The
  `iron_axe.tres` data addition (`c69347b`) is a bug fix to satisfy existing references,
  not a design decision, so its absence from the register is fine.
- **Status vocabulary:** internally consistent with the governance vocabulary.

Decision traceability is the **strongest pillar of the process** — full credit.

## D. Process effectiveness (the trends)

### Recurring defect classes (the systemic signal)
Two categories recur 3+ times — process gaps, not bad luck:

1. **Pair Up subsystem (≥4 occurrences).** `2026-05-24` (Separate flow), `2026-06-09`
   fix plan (Pair Up Action Integrity + escape registry), v0.1.4 Defect 2 (`4924dde` Swap
   no-op), v0.1.4 Defect 3 (`b53a385` bonus-source collision). The collision bug is
   instructive: triage initially called the code path "correct," and only writing the
   asserting test proved it broken (the lesson is captured in the `2026-06-14` note). Churn
   data corroborates: `MapCursor.gd` (18) and `GameState.gd` (19) — the Pair Up surfaces —
   are the two most-touched files since 2026-05-21.

2. **Combat-preview rendering / placement (≥4 occurrences).** `2026-06-09`/`-10`/`-11`
   (broken-preview screenshots, zero-height forecast-row regression, render fix plan) and
   v0.1.4 Obs 2.4 (`4c15aa0` HUD overlap). `AttackPreview.gd` shows 9 touches. This class
   is hard to test headlessly (it is geometry/visual), which is exactly why it keeps
   recurring — see Recommendation R1.

### Review-score trend — flat-to-slightly-improving (healthy)
1–10 scores from the 23 `code_review_*.md`:

```
5-16: 7.0 → 7.5 → 7.5 → 7.5
5-17: 8.5   5-18/19/20: 8.0 (one 6.0 outlier on 5-19b)
5-21: 8.0 ×2   5-24: 8.0   5-27: 7.0
6-09: 7.5   6-10: 7.5   6-13: 8.0   6-14: 8.5
```
(The `5-15` "150/10" is a regex false positive — an audio-clamp code snippet, not a score.)
Trend: stable in the 7.5–8.5 band, ending at the project high (8.5, `2026-06-14`). No
regression. This is the **first** Process & History score, so there is no prior pillar score
to delta against.

### Repeatedly-violated rules — none material
No `AGENTS.md` rule shows up as a repeat violation across reviews. PL#8/PL#9 and session
discipline are consistently honored. The honor-system items in Master §10 (`.uid` tracking,
`tools/` Python in CI, gdlint/gdformat gate) are *unenforced*, not *violated* — and the
3 untracked `.uid`/`.import` files at snapshot are a live example of why `.uid` tracking
should be machine-checked (`[CROSS]` Pillar 4).

### Rework rate — moderate, concentrated
78/543 (~14%) fix commits; churn concentrates in MapCursor/GameState/Unit/AttackPreview —
i.e. the same Pair Up + combat-preview surfaces as the recurring-defect classes. This is
self-consistent: the rework is real but localized to two hard subsystems, not spread
project-wide.

## E. Tooling & workflow recommendations (evidence-backed)

| # | Recommendation | Evidence it addresses | Effort |
|---|----------------|-----------------------|--------|
| **R1** | **Pair Up invariant test harness** — a single headless suite that drives Pair Up / Swap / Separate / escape through `MapCursor` + `GameState` + `PairUpRegistry` and asserts unit positions, visibility, role labels, and combat-bonus deltas after each op. | The Pair Up class recurred ≥4× (`4924dde`, `b53a385`, 2026-06-09 fix plan, 2026-05-24); each fix added a point test but the bugs were *interactions*. An invariant harness catches the next one before playtest. | ~3–4 h |
| **R2** | **Tag every release** — `git tag vX.Y.Z` at each version-bump commit, and add a `check_docs.py` rule that fails if `export_presets.cfg` `product_version` has no matching tag. | Zero tags exist for v0.1.0–v0.1.5.0 (§B-4); testers report against binaries that cannot be checked out. | ~1 h (process) + ~1 h (check) |
| **R3** | **Wire the Master §10 PL#9 candidates into `check_docs.py`** — start with `.uid`-tracking (every `.gd`/`.tres` with a `.uid` sidecar is git-tracked) and add `AGENT/Review Procedures/**` to the scan set. | 3 untracked `.uid`/`.import` files are in the snapshot tree right now (header); untracked UIDs break fresh clones — exactly the machine-move risk `2026-06-13n` worked to prevent. `[CROSS]` Pillar 4. | ~2 h |
| **R4** | **Combat-preview golden-geometry test** — render `AttackPreview` headlessly and assert the panel rect stays on-screen and clear of HUD rects (the `_place_clear_of` helper already exists, untested at the panel level). | Combat-preview class recurred ≥4× and is the canonical "can't test headlessly" excuse; the 2026-06-14 work already proved geometry *is* assertable headlessly. | ~2 h |
| **R5** | **Branch-strategy reset** — merge `awakening-compatability-refactor` into `main` now (it is 242 commits of shipped fixes, not refactor WIP) and start AWR-2/AWR-8 on a fresh, correctly-named branch. | §B-5: branch name contradicts its contents; a 242-commit divergence is an accumulating merge risk. | ~1 h (merge) + review |

## Positive observations (≥3)

1. **Decision register is exemplary.** Honest "Target design" labels, bidirectional
   supersession links (DOC-001↔D-C), and a clear ID namespace make the project's design
   reasoning fully reconstructable — rare for a solo project.
2. **PL#9 is real, not aspirational.** The RNG guard (`4b3241d`) and DOC-013 checks
   (`cf153d8`) both shipped *in the same commit as the rule* — the rule-with-a-check
   discipline is working and visibly enforced in pre-commit + CI.
3. **Session-note + INDEX discipline is near-perfect** — 91 notes, zero orphans, zero dead
   links, with a clear next-session handoff in each. The `2026-06-14` note's "write the
   asserting test before declaring a pipeline correct" self-correction is exactly the kind of
   process learning this pillar exists to surface.
4. **Commit-per-defect with a regression test** is the standing pattern (the whole v0.1.4
   round), not an exception.

## Prioritized action plan

1. **(High)** R2 — tag releases retroactively (v0.1.0…v0.1.5.0) and add the version↔tag check. Cheap, closes a real reproducibility hole.
2. **(High/Medium)** R5 — merge the long-lived branch to `main`; start AWR work on a fresh branch.
3. **(Medium)** R1 — Pair Up invariant harness (highest recurring-defect class).
4. **(Medium)** R3 — `.uid`-tracking check + add Review Procedures to the scan set (`[CROSS]` Pillar 4); fixes the live untracked-sidecar state.
5. **(Low/Medium)** R4 — combat-preview golden-geometry test.
6. **(Low)** Normalize git `user.name` (one identity); patch the `2026-06-14b` note's commit list.

## Delta vs previous review

**None — this is the first Process & History pillar audit.** No predecessor
`process_history_review_*.md` exists, so there are no new/fixed/regressed deltas to compute.
Future runs should delta the process-health score (8/10) and the recurring-defect-class list
against this report.

---

## Procedure friction

- **Sample-size mismatch:** the pillar doc and dispatch brief both say "~140 session notes,"
  but the tree holds **91** (`AGENT/Session Notes/*.md`). Not blocking, but the "do not read
  all 140" framing slightly overstates the corpus. Worth re-counting in the doc.
- **Score-extraction false positives:** grepping `N / 10` across prior reviews hit a `150 / 10`
  audio-code snippet in `code_review_2026-05-15.md`. A future automated score-trend check (a
  PL#9 candidate already in Master §10) needs an anchored pattern (e.g. a required
  "**Score: N/10**" header line), or it will mis-parse. This is itself evidence for the
  "every pillar report carries a pillar-score line" enforcement candidate.
- **"git blame for breadth" guidance** (pillar §2) was low-value here vs. `git log --name-only`
  churn counts and `rev-list --count`; the doc could point at those instead for the
  process-trend use case.
- **Decision "in code?" verification is manual and slow** — there is no machine-readable link
  from a decision ID to the code that implements it, so traceability is grep-and-judge. A
  lightweight convention (decision IDs in code comments at the implementing site, à la the
  existing `# rng-allow: ... (RNG-1)` tags) would make this auditable — and is a good PL#9
  candidate in its own right.
- Otherwise the procedure was followable end-to-end and the §4 output structure mapped cleanly
  onto the evidence.
