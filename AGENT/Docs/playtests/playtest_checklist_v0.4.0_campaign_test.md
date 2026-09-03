---
Role: dated
Type: playtest
Status: Superseded by the fresh campaign/save follow-up checklist
Last verified: 2026-07-15
---

# v0.4.0 Proving Grounds Campaign Test Checklist

> **Superseded:** this checklist belongs to the earlier `202309e` artifact. The
> authoritative Phase 6 return surface is now
> [`playtest_checklist_v0.4.0_campaign_followup.md`](playtest_checklist_v0.4.0_campaign_followup.md),
> paired with the traceable `dd4f971` artifact and expanded to cover every item
> required by the post-audit handoff. Preserve this file as historical evidence;
> do not return it for the current goal.

Return this completed file, the original matching `godot.log`, and screenshots
for visual failures.

## Identity

- Executable: `Project_Prometheus_v0.4.0_campaign_test_debug.exe`
- Size: `101896472` bytes
- SHA-256: `4a10ba8a833746a95f24f361242da61566f2cd2ace3ed8edb4f6e26993e68920`
- Windows/device and resolution: ____________________
- Tester/date: ____________________
- Controller model, or `NOT RUN`: ____________________

- [ ] File identity matches; Main Menu shows `v0.4.0`; BUILD STAMP names
      commit `202309e`.

## 1. Campaign entry and first prep

Open New Game, select `The Proving Grounds`, choose recognizable rule settings,
and Start.

- [ ] The developer map picker disables only while the campaign is selected.
- [ ] Start enters Prep for Chapter 1, not the map directly.
- [ ] Prep text fits, focus is always visible, and keyboard/gamepad navigation
      reaches every unit and button without a trap.
- [ ] A roster longer than the visible panel scrolls with focus; required units
      cannot be benched.
- [ ] Deploy/Bench and Up/Down visibly change the plan; Begin Battle remains
      blocked for an illegal plan and launches the authored order when legal.
- [ ] The selected permadeath, leveling, auto-promote, and Pair Up rules apply.

Notes: ____________________

## 2. Retry redeployment

In Chapter 1, change positions/state, reach the result screen, and choose Retry.

- [ ] Retry returns to Prep with the campaign parked on Chapter 1.
- [ ] The map-start party/economy state is restored; rewards are not duplicated.
- [ ] A different legal deployment can be authored and appears correctly after
      Begin Battle.

Notes: ____________________

## 3. Manual save and both restore routes

On Prep, create a distinctive legal deployment and use Manual Save. Quit to the
Main Menu without starting that battle.

- [ ] Manual Save reports success and creates a visible Load Game row.
- [ ] Continue restores the campaign to the same chapter's Prep; party, rules,
      gold, inventory, and campaign position match.
- [ ] Repeat from a later Prep using Load Game explicitly; it restores the
      selected slot rather than another/newer slot.
- [ ] The loaded Prep requires a valid deployment plan before battle.

Notes: ____________________

## 4. Five-node progression

Complete the campaign in order and tick each results-to-prep transition.

- [ ] Chapter 1 — First Blood (rout) -> Chapter 2 Prep.
- [ ] Chapter 2 — Take the Throne (seize) -> Chapter 3 Prep.
- [ ] Chapter 3 — The Commander (defeat boss) -> Chapter 4 Prep.
- [ ] Chapter 4 — Withdraw (escape) -> Chapter 5 Prep.
- [ ] Chapter 5 — Hold the Line (defend) -> terminal campaign completion.
- [ ] Roster state and party economy carry forward once per transition; maps do
      not reset to the default roster and victory rewards do not duplicate.
- [ ] Each Prep remains readable and focus-scrollable at the tested resolution.

Notes: ____________________

## 5. Terminal record and log

- [ ] Completion does not try to launch a sixth map or show a broken Prep.
- [ ] Relaunching the game does not offer the completed record as Continue.
- [ ] Load Game retains the completion record and identifies it as completed.
- [ ] `godot.log` matches the BUILD STAMP and contains no crash, assertion,
      campaign/map lookup failure, save transaction failure, or missing resource.

Final result: [ ] PASS  [ ] FAIL

Failure notes (exact chapter, input, steps, actual, expected): ____________________
