---
Type: code-review
Status: Fixes implemented - pending focused rerun
Last verified: 2026-07-16
---

# v0.4.0 Playtest Triage Code Review

## 1. Executive summary

**Code quality: 8/10.** The tested `d12eb33` build has sound reward, suspend, and
modal foundations, and its logs contain no runtime correctness failure. The one
confirmed runtime defect is that the results overlay tries to consume input after
the map cursor has already received it and never locks the cursor's independently
polled movement. Party gold is awarded through the correct ledger path, but no UI
surface exposes the value, so the release checklist asks the tester to observe a
state that the build does not display.

Review scope: the returned checklist and logs plus `GameOverScreen`, `MapCursor`,
`TurnManager`, `ResourceLedger`, `MapMenu`, suspend restore, and Unit Details UI at
the v0.4.0 build lineage. This is a document-only review; no runtime code changed.

## Implementation follow-up — 2026-07-16

All owner-decided repairs are implemented headlessly: shared owner-counted gameplay
modal locking, committed reward receipts with results/Map Menu gold surfaces,
independent Page Up/Page Down/right-stick More Info scrolling, and metadata-driven
release availability for unimplemented skills. Focused modal/cursor, reward, menu,
Unit Details, and skill-gate regressions pass. The smoke gate remains open pending the
exact Windows artifact and manual rerun evidence required by the handoff.

## 2. Issues found

### V040-UI-02 — results overlay does not own the cursor lock

**[SEVERITY: High]**

- **File & Line:** `scripts/ui/GameOverScreen.gd:137-155`;
  `scripts/core/MapCursor.gd:320-344`; `scenes/ui/GameOverScreen.tscn:12-18`
- **Problem:** Keyboard and gamepad can move the map cursor behind the visible
  victory overlay. `_unhandled_input()` only marks an event handled when the
  overlay receives it. That is ordering-dependent and does not affect
  `MapCursor._process()`, which polls held directional actions every frame. The
  overlay backdrop also uses `MOUSE_FILTER_IGNORE`, so pointer events are not
  captured by the full-screen background.
- **Root Cause:** `GameOverScreen` implements local event consumption but has no
  state-machine contract with `MapCursor`. Other blocking screens explicitly set
  cursor suppression or lock state; the terminal results screen was left outside
  that ownership path.
- **Recommended Fix:** Add explicit result-modal signals or use the existing
  map-resolution signal to lock the cursor before the overlay becomes visible.
  Unlocking is unnecessary on Retry/Quit because both replace the scene, but a
  symmetric signal keeps the modal contract reusable. Also change the backdrop
  to `MOUSE_FILTER_STOP`.

  ```gdscript
  # EventBus.gd
  signal results_presented()

  # GameOverScreen.gd
  func _show_overlay() -> void:
      var bus := get_node_or_null("/root/EventBus")
      if bus != null:
          bus.results_presented.emit()
      show()
      _retry_btn.grab_focus()

  # MapCursor.gd (_ready)
  bus.results_presented.connect(func() -> void: lock())
  ```

  Add a regression test that opens the results overlay, asserts the cursor is
  locked, feeds keyboard and joypad direction including a held/polled action, and
  proves `current_tile` is unchanged. An overlay-only `_unhandled_input` test is
  insufficient because it misses the `_process()` path that caused the report.
- **Tradeoffs:** A new signal adds a small cross-component contract. Directly
  locating the cursor via group would be less code but would couple the overlay
  to a specific scene implementation.

### V040-UI-01 — victory gold is correct internally but unobservable

**[SEVERITY: High — release verification blocker; Medium product impact]**

- **File & Line:** `scripts/core/TurnManager.gd:1210-1220`;
  `scripts/autoloads/ResourceLedger.gd:117-128`;
  `scripts/autoloads/GameState.gd:143`; `scripts/ui/GameOverScreen.gd:115-139`
- **Problem:** The checklist requires before/award/after party-gold totals, but
  the build has no player-facing party-gold readout. The results overlay renders
  standings only. Therefore the tester's “cannot locate” note is reproducible by
  inspection, but it is not evidence that the award itself failed.
- **Root Cause:** The resource-ledger backend shipped ahead of its presentation
  surface, while the smoke checklist assumed the backend value was visible.
- **Recommended Fix:** For v0.4.0, show a read-only reward summary on the results
  overlay, preferably both the delta and resulting balance: `Gold +75` and
  `Party Gold 100`. Pass an immutable reward-result payload from `TurnManager`
  rather than having the UI infer the award by rereading map data. This makes the
  exact committed transaction observable and scales to reward items later.

  ```gdscript
  # Conceptual payload emitted after a successful ledger commit.
  {
      "gold_awarded": map_data.reward_gold,
      "party_gold_after": game_state.party_gold,
      "items_awarded": map_data.reward_items.duplicate(),
  }
  ```

  Add tests for successful award display, zero-gold maps, ledger failure (do not
  claim an award), and repeated condition evaluation (no second award). Rewrite
  the rerun steps to name the exact results-screen labels.
- **Tradeoffs:** Expanding `map_resolved` changes a widely used signal contract.
  A separate `victory_rewards_committed(payload)` signal is safer for v0.4.0,
  though it introduces another event to coordinate with deferred result display.

### Non-blue-turn suspend is an intentional safety gate, not a defect

**[SEVERITY: Low — deferred feature request]**

- **File & Line:** `scripts/core/MapCursor.gd:1625-1636` and `1745-1769`
- **Problem:** Suspend is unavailable during non-blue turns. This is deliberate:
  restoring such a save can return to a locked cursor without re-entering the
  awaited faction scheduler. Simply enabling the button risks a soft lock.
- **Root Cause:** Suspend serialization can preserve the phase, but restoration
  does not yet persist and resume the scheduler/AI continuation boundary.
- **Recommended Fix:** Keep the v0.4.0 gate. Implement this later by defining a
  resumable turn-boundary token (active faction, scheduler state, pending action
  status, and whether AI execution must restart), restoring it before cursor
  lock derivation, and testing blue, hotseat-local, and AI phases independently.
  If the product only needs “suspend whenever the menu is accessible,” normalize
  the save to the next stable faction boundary instead of serializing mid-AI.
- **Tradeoffs:** Exact mid-phase continuation is faithful but substantially more
  complex and needs deterministic AI coverage. Boundary normalization is simpler
  but may advance state beyond the moment the player requested suspension.

### Character-sheet More Info overflow is mouse-only

**[SEVERITY: Medium — keyboard/gamepad accessibility defect]**

- **File & Line:** `scenes/ui/UnitDetailsScreen.tscn:105-135`;
  `scripts/ui/UnitDetailsScreen.gd:428-440`
- **Problem:** The tester could scroll an overflowing description with the mouse
  wheel but could not reach it through any keyboard or gamepad binding. The
  description control is scrollable, but non-pointer users cannot operate it.
- **Root Cause:** `UnitDetailsScreen._input()` consumes arrows/d-pad for entry
  selection, the description never receives keyboard/gamepad focus, and no
  independent action forwards keyboard or gamepad input to its scroll value.
- **Recommended Fix:** Keep entry selection on arrows/d-pad and add independent
  description scrolling: Page Up/Page Down on keyboard, right-stick vertical on
  gamepad, and the existing mouse wheel. Show a hint/scroll indicator only when
  content overflows. Add a focused scene test proving the description remains
  bounded, overflow exists, and each non-pointer path changes its scroll value;
  live-check 0.5x/1x/2x scales.
- **Tradeoffs:** Godot layout tests can prove geometry and scroll range, but
  right-stick cadence and visual comfort still require a Windows/controller
  playtest. A future explicit focus mode may improve long-form reading, but is
  deferred to `UI-INSPECTION` rather than added to this fix.

### Returned evidence cannot close the release gate

**[SEVERITY: Medium] [CROSS]**

- **File & Line:**
  `AGENT/Docs/playtests/playtest_checklist_v0.4.0_returned_2026-07-15.md:14-33,146-159`
- **Problem:** Artifact size/hash, tester/display metadata, final PASS/FAIL,
  reproduction details, and required screenshots were omitted. The logs prove
  the build stamp and clean runtime, but they cannot substitute for the missing
  artifact-integrity and victory observations.
- **Root Cause:** The handbook uses unchecked prose fields without a return-time
  completeness guard, and the gold procedure depended on a nonexistent UI value.
- **Recommended Fix:** Keep the smoke gate open. For the focused rerun, reduce
  the checklist to identity plus the two victory findings, name every observable
  label/action, and reject the return as incomplete unless all required fields
  and a final result are filled. A small checklist linter can flag blank metadata,
  unchecked required boxes, and an unset final result before packaging.
- **Tradeoffs:** A linter adds process tooling, but it prevents another build/test
  cycle from ending with unusable evidence.

### Deferred `armsthrift` warning is expected log noise

**[SEVERITY: Low]**

- **File & Line:** `scripts/skills/SkillHandler.gd` (`_apply_unimplemented`);
  `AGENT/Docs/archive/evidence/godot_v0.4.0_d12eb33_session_2026-07-15T15.38.54.log:28-29`
- **Problem:** One session logs the known deferred skill stub warning. It is not
  repeated and no failure follows it, so it is not a v0.4.0 blocker. It can still
  alarm testers and obscure novel warnings.
- **Root Cause:** Deferred M9 content is loadable before its behavior exists.
- **Recommended Fix:** Retain the warning in development builds, but exclude the
  skill from release-facing selectable content until implemented, or classify
  known deferred warnings explicitly in the handbook/log scanner.
- **Tradeoffs:** Suppressing it entirely makes accidental execution harder to
  notice; content gating is preferable.

## 3. Positive observations

- Victory gold uses the centralized ledger and reports a missing ledger or failed
  transaction instead of silently mutating `party_gold`.
- Result presentation already waits for level-up/promotion queues, avoiding a
  modal ordering race on the killing blow.
- Suspend capture has a defensive recheck at the write boundary, not merely a
  disabled UI button.
- The returned logs consistently identify the exact `d12eb33` artifact and show
  no crash, assertion, registry, resource, or transaction failure.

## 4. Architectural observations

Modal input ownership is inconsistent. Progression screens and map menus affect
cursor state explicitly, while `GameOverScreen` relies on local event consumption.
Every full-screen gameplay modal should share one cursor-suppression contract so
event order and per-frame polling cannot bypass it.

The ledger correctly owns resource mutation, but there is no presentation model
for committed transaction results. A small immutable reward receipt would keep UI
read-only, prevent it from reconstructing gameplay facts, and support gold, items,
and future resource types uniformly.

## 5. Prioritized action plan

1. Fix results-modal cursor ownership and add keyboard, held-input, gamepad, and
   pointer regression coverage.
2. Surface a committed victory-reward receipt on the results overlay and test
   success, failure, zero reward, and duplicate-evaluation behavior.
3. Cut a focused Windows artifact and complete identity, gold, duplicate-award,
   cursor-lock, and clean-log evidence before closing the v0.4.0 gate.
4. Add bounded-overflow coverage and a live scale/input matrix for Unit Details
   More Info.
5. Keep non-blue suspend gated until scheduler continuation has an explicit save
   and restore contract.
6. Add a return-package completeness check for future release-smoke handbooks.

## 6. Delta vs. previous review

- **Newly confirmed:** results overlay cursor leakage (`V040-UI-02`). This is a
  playtest-confirmed gap, not evidence of a newly introduced regression.
- **Newly scoped:** party-gold presentation/testability (`V040-UI-01`). The ledger
  backend is behaving as designed; the missing observation surface was exposed by
  the new v0.4.0 smoke requirement.
- **Not a defect:** non-blue suspend and Character Sheet scrolling remain deferred
  policy/validation work.
- **Unchanged:** the known M9 `armsthrift` stub warning remains non-blocking.

## 7. Owner walkthrough decisions

Decisions recorded 2026-07-16:

- **Q1 — reusable results-modal lock contract.** The victory/results screen must
  explicitly acquire the shared gameplay-modal cursor suppression before it is
  shown. Coverage must include event-driven keyboard/gamepad input, held input
  polled from `_process()`, and pointer capture; overlay-local event consumption
  alone is not sufficient.
- **Q2 — reward delta plus resulting balance, with a general balance surface.**
  The results overlay will use the clearer labels `Gold earned` and `Total gold`.
  `Total gold` will also be available from the Map Menu; later prep, base, and
  shop screens should reuse the same read-only balance presentation rather than
  inventing separate resource reads. Gold does not need permanent tactical-HUD
  space.
- **Q3 — retain the v0.4.0 non-blue suspend gate, then split the follow-up.** Add
  a bounded `B1-SUSPEND-LOCAL` slice for stable non-AI, locally controlled
  faction phases, and track full AI/mid-action continuation separately as
  `B1-SUSPEND-ANYTIME` on the project control plane. Lifting the gate without a
  controller-aware resume entry point is explicitly rejected because it restores
  values but leaves the scheduler/cursor driverless.
- **Q4 — independent More Info scrolling now; focus mode later.** Preserve
  arrows/d-pad for entry selection. Add Page Up/Page Down and right-stick
  vertical scrolling for the description while retaining mouse-wheel behavior;
  show scroll affordances only when content overflows. Track an explicit
  description-focus mode for evaluation in the later `UI-INSPECTION` pass.
- **Q5 — manual evidence-completeness review.** Do not add a checklist linter.
  Review returned metadata, assertions, reproduction details, screenshots, and
  final PASS/FAIL case by case. Keep focused rerun checklists short and explicit,
  but missing evidence remains a human triage decision rather than an automated
  acceptance rule.
- **Q6 — development warning plus release-content gate.** Retain the
  `armsthrift` unimplemented-stub warning in development builds, but prevent the
  skill from appearing in release-facing selectable content until its behavior
  is implemented. Do not suppress the diagnostic or treat the known warning as
  a v0.4.0 runtime blocker.
