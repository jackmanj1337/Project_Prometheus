# v0.5.8 Owner Playtest Return — ACCEPTED as the stable v0.5 release

**Date:** 2026-07-29
**Build:** v0.5.8 (`agent/playtest-release-v0.5.8-fixes`, tip `bd6b5adb` at return)
**Checklist:** `AGENT/Docs/playtests/playtest_checklist_v0.5.8.md`
**Return form:** verbal owner return (quick playtest). No log bundle, screenshots,
or completed checklist file were returned with it.
**Verdict:** **ACCEPTED — v0.5.8 is the acceptable stable v0.5 release.**

Acceptance is the owner's explicit declaration. It is recorded here as given,
including the items that were not exercised, so the gaps travel forward instead
of being read later as passes.

## Result by checklist section

| § | Item | Result |
|---|---|---|
| Bundle | Campaign ZIP imports (`two-map-skirmish-1.0`, `branching-skirmish-1.0`) | **PASS** — imports good; the v0.5.7 directory-entry blocker is resolved |
| 1 | Branching Results state and map identity | **PASS (acceptable)** — the repeated branch-choice problem is acceptably resolved |
| 2 | Package save validation | **NOT REPORTED** |
| 3 | FileDialog input ownership | **FAIL** — the first physical Escape still closes the entire dialog window |
| 4 | Controller hot-plug telemetry | **NOT COLLECTED** |
| 5 | Logging and focused regression (telemetry) | **NOT COLLECTED** |

The §3 failure is accepted, not waived: it is deferred into the text-input
feature set rather than fixed on the release line. See
`playtest_v0.6.0_carryforward_2026-07-29.md`.

## What this acceptance covers

v0.5.8's reason to exist was the campaign-ZIP directory-entry importer
regression that rejected v0.5.7. That fix is confirmed working on Windows
against the official packs, and the branching-Results defect that drove the
v0.5.6 and v0.5.7 cycles is resolved. Those are the two blocking items, and both
pass.

## What this acceptance does not cover

All five items below are carried into v0.6.0 by owner instruction. Items 1–3
were named at acceptance; items 4–5 were added on the same day once the
unreported sections were identified. Full requirements:
`playtest_v0.6.0_carryforward_2026-07-29.md`.

1. **FileDialog first-Escape close (§3).** Reproduced again on Windows. Deferred
   to the text-input feature set; a fix must be written into that
   implementation plan, not patched on the release line.
2. **Controller hot-plug telemetry (§4).** Never exercised in this cycle. The
   connect → disconnect → reconnect transition records remain unverified on
   Windows across v0.5.6, v0.5.7, and v0.5.8.
3. **Logging / telemetry evidence (§5 items 1–2).** No `[V030 TRACE]` / resize
   trace file, and BUILD STAMP, runtime environment, `PLAYTEST CONTEXT`, and
   controller telemetry presence. Log-inspection only — not collected.

Two further items went unreported — neither passed nor failed. Added to the
v0.6.0 carry-forward by owner instruction on 2026-07-29, so silence is never
read later as a pass:

4. **§2 package save validation.** Bidirectional catalogue validation and the
   missing-package failure path. Last exercised in v0.5.6, where it failed.
5. **§5 non-telemetry regressions.** Retry-after-Save preserving the advanced
   save, and one-item-per-press controller movement across Results, Defeat,
   Rewind, Prep, FileDialogs, and dropdowns.

The Retry-after-Save item is also the outstanding acceptance evidence for
`B4-RESULT-ACTIONS-2026-07-22`, which has been waiting on a live return since
v0.5.5. That task stays open.

## Downstream effect

Acceptance releases the gate that `LIFECYCLE-STABLE-RELEASE` and
`PP-INTEGRATION-RELEASE-RECONCILE` were both holding on. Neither is executed by
this record; both are tracked in the workspace tracker
(`coordination/tasks.json`).
