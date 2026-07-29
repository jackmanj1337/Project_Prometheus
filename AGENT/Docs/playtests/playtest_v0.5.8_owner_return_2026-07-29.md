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

4. **§2 package save validation.** Bidirectional catalogue validation passed in
   the returned v0.5.6 checklist; the missing-package failure path was **never
   run** there, the tester noting *"don't know how to test this"* because the
   instruction never says where the installed package folder is.
5. **§5 non-telemetry regressions.** Retry-after-Save preserving the advanced
   save, and one-item-per-press controller movement across Results, Defeat,
   Rewind, Prep, FileDialogs, and dropdowns.

**B4 result actions — resolved, not carried.** Retry-after-Save is the
acceptance evidence for `B4-RESULT-ACTIONS-2026-07-22`, and contrary to that
task's long-standing trigger text it did not go unreported everywhere: the
returned v0.5.6 checklist exercised it and passed all five sub-checks.
`19e2c0e4` afterwards restructured `MapResultsScreen` (actions moved into an
`Actions` container, Save gained branch-choice disabling) without changing the
retry/save semantics.

**The owner accepted that evidence on 2026-07-29 and B4 is closed.** It stays in
the v0.6.0 checklist as a regression check on the restructured screen only. With
B4 resolved, `PP-INTEGRATION-RELEASE-RECONCILE` has no outstanding live
evidence.

## Downstream effect

Acceptance releases the gate that `LIFECYCLE-STABLE-RELEASE` and
`PP-INTEGRATION-RELEASE-RECONCILE` were both holding on. With B4 also closed on
2026-07-29, neither has any outstanding live-evidence condition. Neither is
executed by this record; both are tracked in the workspace tracker
(`coordination/tasks.json`).

Divergence re-measured 2026-07-29 for the reconcile, against current tips:
`origin/agent/integration` `4ca5cc0d` vs `origin/agent/playtest-release-v0.5.8-fixes`
`c036dfbc`, merge base `258ed12a` — 76 integration-only and 105 release-only
commits, 11 merge conflicts, all in docs, session notes, `AGENTS.md`, and
`scripts/hooks/`. No runtime gameplay file conflicts.
