---
Role: dated
---

# v0.7.0 Windows-round playtest return evidence

> **Historical evidence:** raw return from the 2026-08-06/07 Windows playtest of build
> `v0.7.0`, BUILD STAMP commit `6cf2c89a`. Preserved 2026-08-07.

## Contents

- `returned_checklist.md` — tester-completed `PLAYTEST_CHECKLIST.md`, wording preserved.
- `returned_decision_sheet.md` — tester-completed `v0.7.0_windows_round_decision_sheet.md`;
  decisions 1–3 and 5 answered, decision 4 returned as unanswerable (see below).
- `raw/logs/` — both returned Godot logs, original filenames preserved.
- `raw/screenshots/` — all seven returned screenshots, original filenames preserved.

The original packet arrived at the workspace path `Incoming/v0.7.0 return/`, which is
gitignored. Files were copied into this permanent evidence directory unmodified; SHA-256
values are recorded in `SHA256SUMS.txt`.

The decision-sheet and display-gated-task documents shipped *to* the tester still live on
the docs line as `v0.7.0_windows_round_decision_sheet.md` and
`v0.7.0_windows_round_display_gated_tasks.md`; only the completed copies are preserved here.
The round's onboarding document was deleted 2026-08-24 by `MINE-PLAYTEST-CORPUS-2026-08-23`
(retrieve via git if the tester-facing wording is ever needed again).

## Build identity, verified

Both logs carry `version=0.7.0  commit=6cf2c89a`, matching the bundle record. Windows
10.0.26200, NVIDIA RTX 5070 Ti, 3840×2160 screen, window 3744×2004 for the long session.
`godot.log` is the release executable; `godot2026-08-06T20.46.44.log` is the debug
executable and is the session the checklist was filled from. Nothing here is
misattributed the way the v0.6.1 round was.

## What the logs do and do not contain

- `file_dialog_escape_owned`: **zero records in either log.** The §4 headline value
  `escape_consumed_by` is therefore absent from the return — not because the tester
  skipped it (they reported the failure in prose) but because the guard never took
  ownership and emits nothing when it does not fire. See `V070-06` in the review.
- `exp_awarded`: 99 records. Correlation `tr-000003` awards 14 to one unit and 6 to
  another in the same exchange — direct evidence of the enemy-EXP defect (`V070-04`).
- `level_up_enqueued` 62 / `level_up_shown` 31: not a 2:1 defect. `level_up_shown` fires
  once per *batch* (`LevelUpScreen` only emits `level_up_started` when the queue was
  empty), so the two counters are not comparable.
- ~3,200 `DataManager: unknown skill id` errors, eleven distinct ids. Expected-absent
  content, but the volume is itself a finding (`V070-11`).
- 18 `enemy placement tile (99, 99) is outside the grid` errors with the
  `NewGameScreen._on_start` backtrace — the deliberately-invalid pack being refused
  correctly by the validator and then failing silently at the UI (`V070-05`).

Triage and root-cause analysis:
[`playtest_v0.7.0_root_cause_review_2026-08-07.md`](../../../../Code%20Reviews/playtest_v0.7.0_root_cause_review_2026-08-07.md).
Return record and disposition:
[`playtest_v0.7.0_windows_return_2026-08-07.md`](../../playtest_v0.7.0_windows_return_2026-08-07.md).
