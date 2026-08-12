---
Type: register
Status: RESOLVED 2026-07-21
Last verified: 2026-07-21
---

# v0.5.2 playtest evidence

> **ARCHIVED** — raw playtest return evidence, preserved unedited. Live analysis
> lives in the linked triage plan under `AGENT/Docs/playtests/`.

Byte-for-byte return artifacts for the v0.5.2 Windows playtest (build commit
`06e0386`, branch `agent/playtest-release-v0.5-fixes`). Preserved unedited.

The completed checklist as returned is preserved (unedited) at
`AGENT/Docs/playtests/playtest_checklist_v0.5.2_returned_2026-07-21.md`.

- `godot*.log` — all eight session logs. Only engine error across them is the
  SaveManager slot-id rejection (`godot2026-07-20T16.10.37.log`); the rest is
  `V030-NG-FOCUS` / `V030-DSP-TRACE` menu/display telemetry.
- `*.png` — screenshots: main menu, settings 1x/2x, the rewind-selector cursor
  drift, the "next battle unavailable" escape error, the defend fail, the
  post-rewind data error, and the Fallen/Retreated casualty labels.

Root-cause analysis and fix plan:
[`../../playtests/playtest_v0.5.2_results_triage_plan_2026-07-21.md`](../../playtests/playtest_v0.5.2_results_triage_plan_2026-07-21.md).
