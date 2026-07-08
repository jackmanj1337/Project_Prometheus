# v0.3.0 Full-Scan Tracker

Resume anchor for the resumable full code scan of the v0.3.0 production delta.
**On each invocation, read this file first**, find the first `TODO`/`IN-PROGRESS`
pass, and do exactly that one pass (read → write findings file → flip row to
`DONE` → commit → stop with a pointer to the next pass).

- Base: `ab81a21` (v0.2.8 exe source) · Head: `b7bcfd2` (pre-build v0.3.0 snapshot)
- Cadence: **one pass per invocation** (decided 2026-07-08).
- Type: document-only code-pillar review. No production edits; fixes land later.
- Procedure: `AGENT/Review Procedures/01_Code_Pillar.md`
- Scope detail + file→pass map: `00_scope.md`

| Pass | Subsystem | Files | Findings file | Status | Findings | Commit |
|---|---|---:|---|---|---:|---|
| 0 | Setup & scope lock | — | `00_scope.md` | DONE | — | (this commit) |
| 1 | Save/persistence codec | 3 | `01_save_persistence.md` | DONE | 7 (all Low) | (this commit) |
| 2 | Determinism: state+RNG+combat | 7 | `02_determinism.md` | TODO | — | — |
| 3 | Input model & settings persist | 3 | `03_input_model.md` | TODO | — | — |
| 4 | Input display & rebind UI | 2 | `04_input_display.md` | TODO | — | — |
| 5 | Map/turn core | 5 | `05_map_turn_core.md` | TODO | — | — |
| 6 | UI screens, selection & misc data | 18 | `06_ui_misc.md` | TODO | — | — |
| 7 | General/integration & rollup | (all) | `code_review_v0.3.0_full_scan_2026-07-XX.md` | TODO | — | — |

Total production files covered by passes 1–6: **38** (3+7+3+2+5+18).

## Log

- 2026-07-08 — Pass 0: folder + tracker + scope created; boundary commits
  confirmed (`ab81a21`→`b7bcfd2`), working tree clean at `cef8e83`.
- 2026-07-08 — Pass 1 (save/persistence): read all 3 files at head + their test
  suites. 7 findings, all Low. Highlights: `has_continue_save()` dead if/else +
  needless index read on the MainMenu path (L1); dead `_vector_array_from_variant`
  (L2); non-atomic single-slot `save_suspend` write (L6). No correctness bugs; the
  carried High (`start_map`) is Pass 2/5. Next: Pass 2 (determinism: state+RNG+combat).
