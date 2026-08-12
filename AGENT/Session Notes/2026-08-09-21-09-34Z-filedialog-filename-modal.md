# Session Note - FileDialog filename modal

## Branch context

- Branch: `agent/from-integration/filedialog-filename-modal`
- Base branch: `agent/integration`
- Base SHA: `f9096839361d86a898e0c435d57e408204144136`
- Coordination Work ID: `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`

## What was done

- Verified the original text-entry branch was content-subsumed by integration and cut a
  fresh continuation branch from the current remediation base.
- Removed all four ineffective FileDialog physical-Escape interception stages and their
  telemetry after both v0.7.0 and v0.7.1 Windows returns showed they never owned the key.
- Save-mode dialogs now divert to a game-owned filename modal. Confirmation opens the
  FileDialog only for directory selection, with its filename field read-only; imports
  keep their existing picker-owned path entry.
- Avoided the active web-transfer claim by keeping the redesign entirely inside
  `FileDialogInputGuard.gd`; no transfer service or screen call site changed.
- Replaced direct-handler regressions with modal/cancel boundary tests and updated the
  input contract, text-entry design, and roadmap.

## Commits

The behavior commit `00fe05dd` implements the redesign, focused regressions, and paired
documentation updates. Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`.

## Gates

- Focused `test_text_entry.gd`: 29 passed, 0 failed.
- Focused `test_settings_manager.gd`: 40 passed, 0 failed.
- Fast/full command `bash run_tests.sh`: 135 suites green at behavior commit
  `00fe05dd972c`.
- Windows physical Escape, controller entry, and visual layout remain deliberately
  unverified in the container. The row stays `in_progress` until that return.

## Next

Merge this green branch into `agent/integration`, then continue the ordered v0.7.1
remediation programme with `IMPL-ZERO-CONTENT-EXPORT-GATE`. Before removing
`res://data` compatibility content, re-prove the replacement-pack lifecycle remains
green on the updated integration base. Include this filename modal in the next Windows
candidate: verify physical Escape cancels the name modal without opening the picker,
confirm opens the directory picker with a read-only filename, one picker Escape cancels
once, and controller/grid entry plus focus layout are usable.
