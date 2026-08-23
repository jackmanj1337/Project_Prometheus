---
Role: dated
---

# Full Project Audit — Rollup (2026-06-14)

> Top-level rollup for the first complete-project audit run under
> `AGENT/Review Procedures/`. Conducted by parallel pillar sub-agents.

## 1. Snapshot

| | |
|---|---|
| **Branch / commit** | `awakening-compatability-refactor` @ `e924bb4` |
| **Working tree** | 3 untracked files only (2 `.uid`, 1 `.import`); no modified tracked files |
| **`check_docs.py`** | PASS (all 8 DOC-011 checks) |
| **`run_tests.sh`** | PASS — 39 suites, 870 assertions, 0 failed, ~1m05s |
| **`check_rng_usage.sh`** | PASS |
| **`tools/` analyzer suite** | **FAIL — 3/12** (stdlib `unittest`; pytest not installed) |
| **Engine** | Godot 4.6.stable |

Pillar reports:
- `AGENT/Code Reviews/code_review_2026-06-14b.md` (Code)
- `AGENT/Docs/documentation_review_2026-06-14.md` (Documentation)
- `AGENT/Code Reviews/data_assets_review_2026-06-14.md` (Scenes, Data & Assets)
- `AGENT/Code Reviews/tests_ci_build_review_2026-06-14.md` (Tests, CI & Build)
- `AGENT/Code Reviews/process_history_review_2026-06-14.md` (Process & History)

Companion: `AGENT/Code Reviews/procedure_meta_review_2026-06-14.md` (review of the
review procedure itself).

## 2. Scorecard

| Pillar | Score | Δ vs previous |
|--------|:----:|---------------|
| 1 — Code | **9/10** | prior diff-review fixes verified; no regressions |
| 2 — Documentation | **8/10** | held (vs `documentation_review_2026-06-13.md`); its 3 findings fixed |
| 3 — Scenes, Data & Assets | **8/10** | first run (n/a) |
| 4 — Tests, CI & Build | **6/10** | first run (n/a) |
| 5 — Process & History | **8/10** | first run (n/a) |
| **Overall health** | **6/10** | weakest-pillar headline; mean 7.8 |

Per master §6 the headline is the **lowest** pillar (Tests/CI/Build, 6) — the
project is only as healthy as its weakest audited area. The mean (7.8) is the
trend figure for the next audit.

## 3. Executive summary

The game code, content layer, and documentation are in strong, disciplined shape
(8–9 each); the gap is the **safety net and supply-chain around the code**, not the
code itself. The single most important concern is that the project's own analyzer
tooling is **untested by any gate and currently red**, while the GDScript suite it
sits beside is green — so confidence is high where it's measured and blind where it
isn't. The most valuable finding came from **cross-pillar contradiction** (Docs vs
Code) rather than any single lens: a shipped correctness bug a code-only review
missed. Trajectory is positive — the prior review's findings are verified fixed and
the rule→check→CI loop (PL#9) is demonstrably working.

## 4. Cross-pillar findings (reconciled)

Each appears once, with a single owner; corroborating pillars noted.

**CR-1 — Untracked `.uid` sidecars break fresh clones.** `[Owner: P3]` corroborated
by **P3 (High), P4 (H3), P5 (rec)** — the most-corroborated finding of the audit.
`scripts/resources/CampaignRules.gd.uid` and
`scripts/tests/test_unit_inventory_refs.gd.uid` are untracked though their `.gd`
owners are committed and policy is "track all `.gd.uid`" (95/97). Breaks `uid://`
resolution on a clean checkout/CI. Fix: `git add` both; land the `.uid`-tracking
check in `check_docs.py` (master §10).

**CR-2 — Fort-heal floor: doc says ≥1, code rounds to 0.** `[Owner: P1]` found by
**P2 (High), CROSS P1.** `GDD_02:61-63` ratifies `max(1, floor(0.10×max_hp))`;
`TurnManager.gd:197` uses bare `floori(...)`, so 1–9 max-HP units heal **0** on a
fort. The staff-heal path (`SkillHandler.gd:239`) *does* apply `maxi(1,...)` — so
the rule is implemented inconsistently. (Note an internal doc snag too: the code
comment cites `GDD_02:76` while the spec is at `:61-63`.) Verified by the
orchestrator. Fix: apply `maxi(1, ...)` in TurnManager + regression test. **This is
the headline correctness bug and the clearest argument for multi-pillar review** —
the Code pillar (9/10, internal-consistency lens) did not surface it; the Doc↔code
contradiction did.

**CR-3 — Analyzer test suite red + ungated; Pillar 3 depends on it.** `[Owner: P4]`
found by **P4 (H1), CROSS P3.** `tools/godot-analyzer-mcp/tests/` fails 3/12. All
three are **stale-assertion rot** (tool output correct, assertions outdated:
SettingsScreen now scene-attached; iron_sword uses `combat_family`; HUD has 21
`@onready`), so **Pillar 3's results this run remain trustworthy** — but a real
parser regression would silently corrupt Pillar 3 and nothing would catch it. The
suite is stdlib `unittest` (no pytest needed). Fix: refresh the 3 assertions; add a
zero-dependency CI step.

**CR-4 — `CampaignRules.gd` dead stub.** `[Owner: P1]` found by **P3 (Medium),
CROSS P1.** No `.tres` instantiates it, nothing references it; it also owns one of
the untracked UIDs in CR-1. Fix: remove, or wire + document if intended.

## 5. Unified prioritized action plan

Ranked by impact ÷ effort across the whole project (not per-pillar). Fixes are a
**separate pass** — this audit documents only (master §8).

1. **Track the 2 `.uid` files** (CR-1) — trivial, prevents fresh-clone breakage. Add the `.uid` check to `check_docs.py` same commit (PL#9).
2. **Fix fort-heal floor** (CR-2) — `maxi(1,...)` in `TurnManager.gd:197` + regression test; pair the GDD comment-line correction (PL#8). High-impact, tiny.
3. **Un-rot + gate the analyzer suite** (CR-3) — refresh 3 assertions; add a stdlib-`unittest` CI step so the analyzer can't silently break Pillar 3.
4. **Resolve pre-commit ↔ CI drift** (P4 M1) — the hook calls `run_tests.sh`; CI calls `run_headless_tests.sh` (asserts class cache). Align them.
5. **Tag releases retroactively + version↔tag check** (P5 R2) — restore source→binary reproducibility for the 5 shipped versions; add the check (PL#9).
6. **Housekeeping:** delete empty `code/`; remove/justify `CampaignRules.gd` stub (CR-4); track or remove the orphan `950MERC Promotion.png.import`.
7. **Decouple `PairUpRegistry` from the hardcoded `/root/GameMap/TurnManager` path** (P1 Medium) — EventBus/injected ref.
8. **Branch strategy** (P5 #2) — HEAD is 242 commits ahead of `main` and the branch name no longer matches its contents. Merge to `main` or rename + open a fresh AWR branch.
9. **Pair Up invariant test harness** (P5 R1) — addresses the top recurring defect class (≥4 occurrences).
10. **Doc cleanup:** bless a DOC-002 "catalog section" variant for GDD_06/07/08; fix the "Canonical" status outlier in `decision_index.md:123`; bump stale `Last verified` dates.

## 6. Process & tooling recommendations (from Pillar 5 + cross-pillar friction)

- **Tag-per-release + version↔tag check** (R2) — see action #5.
- **Pair Up invariant harness** (R1) — see action #9.
- **Machine-readable decision→implementation link** — extend the existing
  `# rng-allow: ... (RNG-1)` tag style to decision IDs so traceability is auditable
  (currently manual). PL#9 candidate.
- **Anchored score header in every report** — automate score-trend tracking without
  the `150 / 10` false positives Pillar 5 hit. PL#9 candidate.
- **Analyzer/MCP gaps** — `get_resource_fields` truncates arrays; no orphan /
  cross-ref / ID-uniqueness primitive (Pillar 3 hand-rolled these). Tooling backlog.

## 7. Regression watch

No prior-audit regressions (first full run for 3 of 5 pillars; Code and Docs both
show prior findings *fixed*, none reappeared). Establish this section as the
baseline for the next audit.

## 8. Positive observations (cross-pillar)

- Decision register is exemplary: honest `Target design` labels, bidirectional
  supersession links, and PL#9 genuinely closed (RNG guard + DOC-013 checks shipped
  in the same commit as the rule).
- Session-note / INDEX discipline near-perfect (91 notes, 0 orphans, 0 dead links).
- Version strings are machine-enforced (`test_release_metadata.gd`).
- Content layer is clean: 18/18 scenes pass onready validation, 12/12 autoloads
  resolve, no data↔code field drift, import pipeline clean.
- ~13k lines of GDScript with **zero Critical/High** internal-correctness findings.
