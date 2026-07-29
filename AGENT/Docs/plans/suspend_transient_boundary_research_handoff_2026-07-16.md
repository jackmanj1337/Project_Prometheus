---
Type: plan
Status: Planned - discussion and headless research handoff
Last verified: 2026-07-16
---

# Suspend Transient-Boundary Research Handoff - 2026-07-16

## Purpose

Use the campaign/save follow-up branch while both Windows playtest returns are
out to determine the safest next suspend increment. This handoff authorizes
discussion, code-path inventory, pure probes, fixtures, and test-only
experiments. It does not authorize a player-facing suspend expansion, a save
schema change, or a new release build.

Work on `agent/codex/2026-07-15/prep-save-followup`. Preserve the identity of
the existing `dd4f971` campaign/save test artifact; do not rebuild or replace it.
If either v0.4.1 or campaign/save live evidence returns, intake and triage that
evidence before starting an implementation slice.

## Baseline already built

Do not rediscover or rebuild these behaviors:

- `B1-SUSPEND` captures a suspend-complete board, party/campaign state, RNG
  history, ledger, scheduler state, Pair Up state, and cursor/threat-view state.
- `MapCursor.can_capture_suspend()` permits idle committed-action boundaries for
  every locally controlled faction and rejects AI control and transient cursor
  states.
- `TurnManager.start_map_from_suspend()` restores the active faction and
  re-enters `HotseatController` for a locally controlled non-blue faction.
- Retry, Rewind, and suspend share the same board serializer and unified named
  slot store.
- These paths are automated, but the expanded campaign/save behavior still
  awaits the live Windows checklist return.

The remaining question is what “suspend at any time” should mean while an action,
modal, animation, AI activation, controller handoff, or results transaction is
in flight.

## Recommended direction to research

Prefer a **deferred suspend intent** over serializing an in-flight coroutine or
partially applied action:

1. A request at an already-safe boundary may capture immediately.
2. A request during a recoverable transient state may latch one intent and
   capture at the next atomic committed boundary.
3. A request after map outcome commitment, during an external transaction, or
   in a state with no proven boundary must be rejected with a precise reason.
4. Resume should always enter an existing stable controller entry point; it
   should not attempt to reconstruct a Godot signal stack, tween, animation, or
   awaited function.

This is only the working recommendation. The next session must compare it with
explicit checkpoint/resume tokens and cancellation-to-last-boundary before an
owner decision is recorded.

## Research sequence

### 1. Build the boundary inventory

Trace every route that can be active between two ledger commits and classify it
as `safe_now`, `defer_to_commit`, or `reject`:

- free local cursor and selected-unit states;
- Action Menu, target selection, Attack Preview, item/staff flow, Pair Up, and
  secondary confirmation dialogs;
- combat resolution, animation/level-up queues, death lifecycle, and reward
  application;
- WHOLE_PHASE and ALTERNATING controller handoffs;
- hotseat and AI `run_phase()` awaits;
- victory/defeat/results and campaign-node commit;
- Rewind, Retry, manual save, autosave, and package/save import transactions.

For each route, record the mutation owner, first committed side effect, ledger
push point, next stable entry point, and whether the existing snapshot fully
represents the state at that boundary.

### 2. Map controller continuation ownership

Document which stable function owns resumption for:

- blue local control;
- non-blue hotseat control;
- WHOLE_PHASE AI;
- ALTERNATING AI;
- a phase transition between controllers;
- map outcome/results sequencing.

Prototype only a pure data shape if the inventory proves one is needed. A
possible research shape is `{boundary_kind, faction_id, controller_kind,
activation_mode, round, activation_id}`. Do not add it to `SaveData` until tests
prove existing scheduler state cannot derive the same facts.

### 3. Add headless characterization probes

Test-only probes may establish the current behavior without changing production
semantics:

- request suspend before, during, and after each representative action commit;
- prove a denied/deferred request cannot write a partial slot;
- prove exactly one capture occurs if several inputs request suspend;
- prove rewards, item use, HP, death, action state, and RNG are neither skipped
  nor duplicated across the candidate boundary;
- cover local blue, local non-blue, WHOLE_PHASE AI, and ALTERNATING AI;
- cover map-over and campaign-result transactions;
- corrupt or omit any proposed continuation fields and require fail-closed
  validation with no live-state mutation.

Keep these as characterization or test fixtures unless an implementation slice
is separately approved.

### 4. Research adjacent low-impact hardening

If suspend analysis blocks on an owner decision, continue with tests and reports
that do not alter player behavior:

- legacy and malformed suspend-envelope compatibility fixtures;
- transactional failure injection for slot writes and Continue-pointer updates;
- byte/determinism comparisons between ledger and suspend board payloads;
- save/import size-budget and integrity-boundary probes;
- orphaned package/version behavior for an existing suspend slot;
- static audit that every mutable runtime field is owned by the shared board
  serializer or explicitly marked transient.

Do not begin a new campaign, combat, UI, or content feature while using this
fallback queue.

## Owner discussion packet

Bring one recommendation for each question, with the boundary inventory and
tests as evidence:

1. Does “any time” mean immediate capture, queued capture at the next atomic
   boundary, or cancellation back to the last ledger boundary?
2. During AI control, should a request finish the current activation, finish the
   current faction phase, or be unavailable?
3. If a deferred request reaches victory/defeat first, should results commit and
   save between maps, or should the request be cancelled?
4. Is one pending intent sufficient, and what cancels it?
5. Must the UI expose “Suspend pending,” or is a blocking confirmation shown
   only once the safe boundary is reached?
6. May a new suspend overwrite `resume_battle` automatically, and what failure
   feedback is required?
7. Are old suspend saves required to load after a continuation contract is
   introduced? The recommendation is yes, with stable-boundary defaults.

## Non-goals

- Do not serialize coroutines, signal connections, tweens, scene nodes, or
  half-applied combat/effect transactions.
- Do not lift `MapCursor.can_capture_suspend()` gates before the boundary model
  and failure tests exist.
- Do not change the `dd4f971` artifact, checklist, or expected live evidence.
- Do not merge the v0.4.1 release branch into this branch during research.
- Do not implement online/remote controller persistence; only identify the seam
  it will eventually require.

## Primary code and evidence anchors

- `scripts/core/MapCursor.gd`: `can_capture_suspend()`, menu request and slot write.
- `scripts/core/TurnManager.gd`: scheduler capture, controller dispatch, and
  `start_map_from_suspend()`.
- `scripts/core/HotseatController.gd` and `scripts/core/EnemyAI.gd`: awaited
  controller entry/exit behavior.
- `scripts/autoloads/GameState.gd`: shared board capture and resume staging.
- `scripts/autoloads/SaveManager.gd`: transactional slot and Continue ownership.
- `scripts/save/MapLedger.gd`: stable history boundaries.
- `scripts/tests/test_suspend_map_runtime.gd`, `test_save_manager.gd`,
  `test_ledger_entry.gd`, `test_rewind.gd`, and `test_turn_manager.gd`.
- [`playtest_checklist_v0.4.0_campaign_followup.md`](../playtests/playtest_checklist_v0.4.0_campaign_followup.md): live gate that remains protected.

## Next-session exit conditions

The research session is done when it leaves:

- a reviewed boundary/continuation matrix;
- headless characterization evidence for the highest-risk boundaries;
- a concise owner decision packet answering the seven questions above;
- a recommendation to implement, narrow, defer, or reject the expansion;
- only after owner approval, a separate implementation plan split into green
  commits with explicit schema, migration, and live-test gates.

Run `python3 AGENT/Docs/check_docs.py`, the RNG guard, relevant focused suites,
and the full suite if any executable test or production file changes.
