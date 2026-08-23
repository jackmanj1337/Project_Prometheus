---
Role: dated
Type: playtest
Status: Complete - carry-forward items 1, 2, 4, 5 closed on v0.6.0 evidence
Last verified: 2026-08-02
---

# v0.6.0 carry-forward items: log inspection

`PP-V060-CHECKLIST-CARRYFORWARD-2026-07-29` tracked five items said to have "slipped"
across v0.5.6, v0.5.7 and v0.5.8. Four of them were in fact answered by the v0.6.0
return; two of those were answered by evidence nobody had opened.

Source evidence: `AGENT/Docs/playtests/evidence/v0.6.0/` on
`agent/from-from-v0.6.0-visual-pass-playtest-patches/v060-return-triage` (commit
`8020baa2`) — the returned checklist plus seven Godot logs.

**The tester returned the log bundle and left the log-derived rows unchecked.** The
items were not blocked on missing data; they were blocked on nobody performing the
inspection. That is a different failure, and it is the one worth fixing: the returned
checklist asks a human to grep logs, which is exactly the step that gets skipped.

## Item 1 — controller hot-plug telemetry: PASS

`godot2026-08-01T17.39.54.log` records a full five-transition sequence on one pad:

```
connected=true  → connected=false → connected=true → connected=false → connected=true
device_id=0  name=XInput Controller  guid=0300fa675e040000130b000007057801
```

- Every transition is recorded, in order.
- Disconnect records retain both name and GUID, so no transition is anonymous.
- The tester independently confirmed prompts switched keyboard↔controller each time.

Observation, not a defect claim: `godot final.log` carries two `connected=true` records
with no intervening `connected=false` — one before the BUILD STAMP block (boot-time pad
enumeration) and one after. A pad already connected at launch appears to emit both an
enumeration record and a connect record. Harmless for telemetry reading, but if
`InputModeManager` is meant to emit one record per real transition, that is worth a look.

## Item 2 — logging / telemetry presence: PASS

Across all seven returned logs:

| Requirement | Result |
|---|---|
| No `[V030 TRACE]` lines | ABSENT in all 7 — pass |
| `=== BUILD STAMP ===` present | 7/7 |
| `=== RUNTIME ENVIRONMENT ===` present | 7/7 |
| `PLAYTEST CONTEXT` present | 3/7 (only sessions that started a campaign — expected) |
| `PLAYTEST CONTROLLER` present | 2/7 (only sessions with a pad — expected) |

The shipped v0.6.0 stamp reads `version=0.6.0 commit=cbd1f832 built_at=2026-08-01T03:10:37Z`,
which is the same stale bake that later got packed into the first v0.6.1 build.

Not closed: whether a v0.3.0 resize-trace file exists in the user-data dir. That is a
filesystem check, not a log check, and the return does not answer it. Carried into
v0.6.1 as the only open half of this item.

## Item 3 — FileDialog cancel/Escape ownership: FAIL

The return marks it `FAILED` outright. This is what the v0.6.1 explicit filename-edit
state and the four-stage Escape instrumentation address, so it must be re-verified on
v0.6.1 — it is the one carry-forward item still genuinely open on the product side.

The latent joypad double-bind row (`confirm=joy(1,0)` / `cancel=joy(2,1)`,
`BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND-2026-07-24`) was left unchecked and is still
unanswered.

## Item 4 — package save validation, missing-package half: PASS

**This ran, and it passed.** The half described for three releases as "never runnable"
was executed in the v0.6.0 return with all three rows checked: ordinary load activates
the saved catalogue; moving the installed package folder aside makes the load fail
without partially restoring; moving it back restores normal loading.

Tester note: the message read *"Could not load the campaign save. Progress was not
resumed"* — correct behaviour, with a request for a more helpful error. That request is
already the subject of the deferred recovery-wording work in
`pack_associated_save_implementation_plan_2026-07-23.md`.

## Item 5 — Retry-after-Save + controller navigation: PASS

All three rows checked, including the successor-dropdown navigation case that failed in
the v0.5.6 return. B4-RESULT-ACTIONS does not reopen.

## What v0.6.1 still needs

Only item 3 (Escape ownership, plus the unanswered double-bind question) and the
resize-trace filesystem check. Items 1, 2, 4 and 5 are closed on v0.6.0 evidence and
should not be re-run as if they had never happened.
