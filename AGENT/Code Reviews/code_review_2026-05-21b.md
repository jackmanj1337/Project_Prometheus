# Code Review — 2026-05-21b

## 1. Executive Summary

**Overall code quality: 8 / 10**

The gameplay code is in solid shape: the current headless suites pass cleanly,
the promotion/reclass/hotseat work is covered by focused tests, and the newer
systems are integrated with the existing event-driven flow rather than bolted on.
The main problems are in the verification path and living documentation, where
the repo drifted behind the code and could hide regressions or mislead the next
session.

## 2. Issues Found

**[SEVERITY: High]**
- **File & Line:** `run_tests.sh:4`
- **Problem:** The default test runner omitted `test_promotion_screen` and
  `test_reclass_screen`, so the repo's main verification command did not cover
  two recently added UI flows. Pre-commit and manual "run the full suite"
  checks could report green while promotion/reclass regressions were present.
- **Root Cause:** The runner's static suite list was not updated when the new
  test files were added.
- **Recommended Fix:** Keep the suite list in sync whenever a new `test_*.gd`
  file lands, or generate the list dynamically from `scripts/tests/`.
  ```bash
  TESTS=(
    ...
    test_level_up_screen
    test_promotion_screen
    test_reclass_screen
  )
  ```
- **Tradeoffs:** A static list is easy to control and order, but it creates
  ongoing maintenance debt. A generated list reduces drift but changes suite order.

**[SEVERITY: Medium]**
- **File & Line:** `README.md:6`
- **Problem:** The documented primary test command was `./run_tests.sh`, but in
  this repo state the script was not executable (`0644`). A fresh shell run
  fails with `Permission denied`, which makes the baseline verification
  instruction unreliable.
- **Root Cause:** The docs assumed executable-bit availability, while the
  repository state and some container/mounted-volume setups did not provide it.
- **Recommended Fix:** Document `bash run_tests.sh` as the portable default, and
  optionally keep the executable bit set for convenience.
  ```md
  `bash run_tests.sh` runs the GDScript test suites headlessly.
  ```
- **Tradeoffs:** `bash run_tests.sh` is slightly more verbose, but it is more
  portable across shells, containers, and mounted filesystems.

**[SEVERITY: Medium]**
- **File & Line:** `AGENT/GDD/GDD_09_Checklist.md:16`, `AGENT/GDD/GDD_01_Architecture.md:146`, `AGENT/GDD/GDD_01_Architecture.md:1190`
- **Problem:** The living project docs still reported older test-suite counts
  and the old runner command. That makes planning and validation guidance stale,
  especially after the M6/M7 and hotseat follow-up work.
- **Root Cause:** Documentation snapshots were not resynced after the newer test
  suites and verification conventions landed.
- **Recommended Fix:** Update the current-status docs to the real suite/test
  totals and the current test command, and treat dated historical notes as
  historical unless they are explicitly marked as living references.
  ```md
  **Tests:** 586 passing across 26 suites (`scripts/tests/test_*.gd`). Run `bash run_tests.sh`.
  ```
- **Tradeoffs:** Historical documents should usually keep their original dated
  context, so only living references should be updated.

## 3. Positive Observations

- The newer class-change features are covered from multiple angles: unit logic,
  scene-level integration, and dedicated promotion/reclass modal tests.
- `TurnManager` keeps the controller routing, phase commits, and victory
  resolution centralized, which limits special-case drift across player, AI,
  and hotseat flows.
- The codebase consistently prefers data-driven seams (`ClassData`, `UnitData`,
  map registry content, faction controller data) over hardcoded branching.

## 4. Architectural Observations

- The project is strongest where there is a single authority per concern:
  `TurnManager` for phase flow, `DataManager` for content loading, and the
  modal screens for class-change confirmation. That pattern should be preserved.
- Verification drift is now the main architectural risk. The code can be well
  tested locally while the default runner and status docs still under-report
  coverage, which weakens trust in "green means green."
- The current test harness style remains practical and readable, but the static
  runner list should be treated as part of the architecture, not just shell glue.

## 5. Prioritized Action Plan

1. Keep `run_tests.sh` aligned with `scripts/tests/test_*.gd` so the default suite truly covers all shipped tests.
2. Standardize living docs on `bash run_tests.sh` and current suite/test totals.
3. Keep historical notes dated, but resync the README/GDD files that are meant to guide current work.
