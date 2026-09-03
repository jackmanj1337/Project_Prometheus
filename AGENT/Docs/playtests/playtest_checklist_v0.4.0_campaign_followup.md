---
Role: dated
Type: playtest
Status: Pending - live Windows campaign/save follow-up
Last verified: 2026-07-15
---

# v0.4.0 Campaign/Save Follow-up Checklist

Return this completed file with the original matching `godot.log`. Attach a
screenshot for every visual failure and for each specifically requested evidence
row. Do not rename or edit the original log.

## Identity and environment

- Executable: `Project_Prometheus_v0.4.0_campaign_followup_debug.exe`
- Size: `102090960` bytes
- SHA-256: `522c5687572355506d019ee58452ef21f9cfd0f4fa00723d2cd881a42634a615`
- Windows version/device/GPU: ____________________
- Resolution/window mode/menu scale: ____________________
- Tester/date: ____________________
- Controller model, or `NOT RUN`: ____________________

- [ ] File identity matches; Main Menu shows `v0.4.0`; BUILD STAMP names
      commit `dd4f971` and the returned log comes from this run.

## 1. Campaign entry, Prep focus, and long roster

Select `The Proving Grounds`, choose recognizable rule settings, and Start.

- [ ] Campaign selection disables only the developer map picker and opens Chapter 1 Prep.
- [ ] Keyboard and controller reach every roster row and action without a focus trap.
- [ ] A roster longer than the viewport scrolls with focus; text does not overlap or clip.
- [ ] Required-unit bench rejection and illegal-plan Begin Battle blocking are clear.
- [ ] Deploy/Bench and Up/Down produce the authored legal deployment order.
- [ ] Screenshot attached: long-roster Prep with focused off-first-page row.

Notes: ____________________

## 2. Branch results and five-map transitions

- [ ] Chapter 1 rout reaches Chapter 2 Prep.
- [ ] Chapter 2 seize reaches Chapter 3 Prep.
- [ ] Chapter 3 defeat-boss reaches Chapter 4 Prep.
- [ ] Chapter 4 escape reaches Chapter 5 Prep.
- [ ] Chapter 5 survive/protect result ends the campaign without a sixth-map launch.
- [ ] Every presented branch choice selects the named successor and cannot double-advance.
- [ ] Roster, rules, gold, convoy, and rewards carry exactly once per transition.
- [ ] Screenshot attached: one branch-choice result and its resulting Prep chapter.

Notes: ____________________

## 3. Defeat actions, Retry, and Rewind

Create a distinguishable map state and defeat the player-controlled force.

- [ ] Retry restores map-start party/economy/RNG state and returns through legal Prep.
- [ ] Load Recent restores the newest eligible save.
- [ ] Choose Save opens the picker and restores the selected—not merely newest—slot.
- [ ] Rewind appears only when available, spends the correct charge, and restores the
      expected activation/round state without duplicated economy or rewards.
- [ ] Main Menu exits cleanly; returning does not commit a pending defeat result.

Notes: ____________________

## 4. Manual save, autosave, Continue, and Load Game

- [ ] Manual Save on Prep reports success and creates a labeled Load Game row.
- [ ] Continue restores the same chapter, rules, roster, gold, convoy, and position.
- [ ] A later explicit Load Game selection restores that exact slot.
- [ ] Transition autosaves rotate independently and never overwrite a manual slot.
- [ ] Mid-map suspend is offered only at a safe committed-action boundary and resumes
      the correct locally controlled faction, including a non-blue hotseat faction.
- [ ] Completed terminal records remain in Load Game but are excluded from Continue.

Notes: ____________________

## 5. Portable save warning and hard cap

- [ ] Export a portable save, then import it normally; identity and state round-trip.
- [ ] A warning-sized valid fixture requires explicit acknowledgement before mutation.
- [ ] Cancel at the warning leaves slots, index, Continue pointer, and campaign state unchanged.
- [ ] A fixture above the configured maximum is rejected before buffering and cannot be acknowledged through.
- [ ] Tampered/integrity-invalid input remains rejected even after a size acknowledgement.
- [ ] Screenshot attached: warning dialogue and hard-cap rejection feedback.

Notes and fixture sizes: ____________________

## 6. Campaign package import/export dialogs

- [ ] Manage Campaigns import accepts a valid package and refreshes discovery without
      silently starting or replacing the current campaign.
- [ ] Invalid/hostile package feedback is structured and leaves installed/runtime/save state unchanged.
- [ ] Export produces a deterministic package and reports its destination/result.
- [ ] Re-import/duplicate-version handling is explicit; no partial staging directory remains.
- [ ] Screenshot attached: successful package result and one rejected-package result.

Notes: ____________________

## 7. Evidence return and final result

- [ ] Original `godot.log` attached and BUILD STAMP matches the artifact.
- [ ] Log has no crash, assertion, lookup, transaction, missing-resource, or unhandled registry-id failure.
- [ ] Platform, display, input device, fixture sizes, and all requested screenshots are supplied.

Final result: [ ] PASS  [ ] FAIL

Failure record (section, exact steps, expected, actual, reproducibility): ____________________
