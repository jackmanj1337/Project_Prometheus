---
Role: dated
---

# Code Review — Comprehensive codebase pass (2026-06-17)

**Scope:** a full-codebase health review requested verbally, not tied to a single
diff. Read the foundational autoloads (`EventBus`, `GameState`, `DataManager`) and
the largest core systems (`CombatResolver`, `Unit`, `TurnManager`, `SkillHandler`,
`EnemyAI`), ran the full test suite + `check_docs.py`, and scanned the tree for
debt markers, debug leftovers, and ignore/build hygiene. UI screens and the
`MapCursor*` cluster were skimmed, not read line-by-line.

Reviewer note: I did not write the bulk of this code, so this is an outside read —
I went looking for correctness bugs and drift, and report honestly where I found
none.

## 1. Executive Summary

**Overall quality: 9 / 10.**

This is an unusually disciplined codebase for its scale (~14k production LOC,
~13k test LOC). Boot-time data validation is exhaustive and fails loud in release
(`push_error`, not `assert`); the combat preview is genuinely side-effect-free via
snapshot/restore; the autoload→scene decoupling (e.g. `support_orphaned` on
EventBus rather than reaching into the scene `TurnManager`) is principled; and
inline comments cite the specific review/playtest that motivated each non-obvious
choice. The test suite (47 suites, ~700+ assertions) and the documentation
governance checks (12/12) are both green.

No correctness bugs were found in the systems read. The findings below are all
low-severity hygiene/readability items.

## 2. Findings

### #1 — `builds/` ignored only via local `.git/info/exclude` (Fixed)
The 870 MB `builds/` dir (7 stale ~100 MB debug `.exe`s) was excluded only by a
machine-local exclude, not the committed `.gitignore`. A fresh clone or different
machine had no protection against an accidental ~100 MB commit. **Fix:** added
`/builds/` to `.gitignore`. (Pruning the stale local builds is a separate manual
cleanup — only the latest version is needed.)

### #2 — Stale comment referencing a non-existent file (Fixed)
`Unit.gd`'s header claimed stat math was split into `UnitStatBlock.gd (helper)` —
that file does not exist; all stat math lives in `Unit.gd`. A maintainer would
hunt for a file that was never created. **Fix:** header rewritten to describe the
file's actual responsibilities. `check_docs.py` enforces this kind of accuracy for
`AGENT/` docs but cannot see code comments.

### #3 — `const preload` at the bottom of `GameState.gd` (Fixed)
`const ResourceManifest = preload(...)` sat as the last line of the file. It works
(consts resolve at compile time regardless of position) but is inconsistent with
`DataManager`, which groups preloads at the top. **Fix:** moved to the top.

### #4 — `add_exp` at max level skipped promotion availability (Fixed)
`Unit.add_exp` returns early when the unit is already at the level cap, but did not
call `_maybe_emit_promotion_available()` on that path. A unit authored to spawn
ALREADY at max level never crosses the cap via `level_up()` (the other emit site),
so under `auto_promote_at_max_level` it could never auto-promote. **Fix:** emit on
the early-return path. Verified idempotent — the emitter is gated on
`auto_promote_at_max_level` + `can_promote()` (false once promoted), and
`PromotionScreen` ignores re-emits while it is open. Backed by a new regression
test in `test_unit_stats.gd` (58 → 59 assertions). This brings the code in line
with the already-documented auto-promote behavior, so DoD#1 (GDD/roadmap flip)
does not apply.

### #5 — Largest files are getting heavy (Planned — not in this change)
`MapCursor.gd` (1194) and `Unit.gd` (1188) are the two largest files. `MapCursor`
already delegates to `MapCursorInput/Selection/Targeting`; `Unit.gd` still folds
the ~300-line class-change (promotion/reclass/second-seal) state machine in with
identity, combat stats, and EXP growth. Plan to extract it into a `UnitProgression`
RefCounted helper (mirroring the `MapCursorSelection` pattern) is written up in
`AGENT/Docs/unit_progression_extraction_plan_2026-06-17.md`. Pure refactor, no
behavior change; deferred to a dedicated session.

## 3. Architecture observations (not defects)

- The `get_node_or_null(...).call()/.get()` idiom for autoload-to-autoload access
  (forced by Godot 4's headless `--script` constraint) is applied consistently but
  costs static type-checking and adds verbosity. It is a documented, deliberate
  tradeoff — noted here as the single largest readability tax, not as a fix item.
- `CombatResolver` is the strongest module: modelling weapon breakage inside
  resolution (so discarded exchanges never fire skill triggers) and the Nihil
  negate pre-pass ordering are both subtle and correct.

## 4. Verification

- `run_tests.sh`: all 47 suites green.
- `check_docs.py`: 12/12 green (including the new plan doc).
