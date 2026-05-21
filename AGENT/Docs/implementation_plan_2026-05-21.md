# Implementation Plan — M15 Part A: Hotseat Control

**Date:** 2026-05-21
**Status:** Ready to implement — next action item.
**Scope:** Milestone 15 Part A (hotseat) per `GDD_10_Roadmap.md:1205`, bounded
to **WHOLE_PHASE maps only** (see Decision Q6).
**Design source:** `second_player_control_feasibility.md` §5 stage 6, refined by
the six decisions below.

---

## 1. Goal

Let any **non-blue** faction be driven by a local human through the existing
`MapCursor` instead of the AI. Shared screen, phases alternate. Blue is always
player 1. AI factions are unaffected.

---

## 2. Settled decisions (2026-05-21)

| # | Decision |
|---|----------|
| Q1 | **Uniform controller contract.** AI and hotseat both implement `run_phase(grid, turn, faction_id) -> void`. The `start_enemy_phase` loop `await`s it regardless of controller type. |
| Q2 | **TurnManager owns End-Turn.** A single `request_end_phase()` entry reads the active faction, runs a faction-generic units-done check, and either ends blue's phase or emits `phase_committed`. |
| Q3 | **HotseatController configures the cursor.** Its `run_phase()` sets the cursor's controlling faction + unlocks it on entry, awaits End Turn, returns. |
| Q4 | **`MapCursor._on_phase_changed` unchanged.** It still auto-locks on `Phase.ENEMY`; the HotseatController unlocks afterward. Lock→unlock happens synchronously in one loop iteration, so the cursor is never observably locked during a hotseat phase. |
| Q5 | **Controller enum `AI` / `HOTSEAT` only.** `HUMAN` is dropped; blue is identified structurally by `id == "blue"`. |
| Q6 | **WHOLE_PHASE-only for Part A.** ALTERNATING hotseat is split to a later item. |

---

## 3. Done-vs-remaining audit (against current code)

**Already in place** — the feasibility doc §4 over-states the remaining work:

- Faction-relative cursor: `MapCursor` / `MapCursorSelection` / `MapCursorTargeting`
  all carry `_controlling_faction` (M14 stage 1). A cursor can already select and
  target relative to any faction.
- N-faction turn cycle: `active_faction()`, `_advance_faction()`, the
  `start_enemy_phase` per-faction loop (C3).
- `FactionData.controller` field + `TurnManager._is_ai_controlled()`.
- `phase_changed` signal carries `faction_id` (Issue 5, 2026-05-21).
- AI controller injection seam: `_ai_controller` + `set_ai_controller()`.
- `EnemyAI.run_ai_phase(grid, turn, faction_id)` — already the right shape.
- HUD / PhaseBanner show the faction label/colour.

**Remaining** — what Part A actually builds:

- `MapCursor._controlling_faction` is set once at `setup()` (defaults `"blue"`,
  callsite `GameMap.gd:57` passes no faction) and never changes.
- No `HotseatController`; no shared `run_phase()` contract name.
- `start_enemy_phase` skips non-AI factions (`if _is_ai_controlled(...) and ai`).
- End-Turn path is blue-only: `MapCursor._on_end_turn_requested` →
  `are_all_player_units_done()` → `end_player_phase()`.
- Auto-end-on-all-done (`_auto_end_player_phase`, playtest #5) is blue-only.
- The C3 `.tres` carries `controller = "HUMAN"` (to be removed per Q5).

**Out of scope / blocked:**

- The M15 checklist item *"`grant_extra_turn` re-enters the active controller"*
  references an M10 feature — `grant_extra_turn` does not exist in the codebase
  yet. It cannot be satisfied now; tracked against M10. Mark the checklist item
  blocked, do not attempt it here.
- ALTERNATING hotseat (Q6).

---

## 4. Architecture

```
TurnManager.start_enemy_phase()  ── per-faction loop ──┐
   for each non-blue faction:                          │
       controller = _controller_for(faction)           │
       await controller.run_phase(grid, self, faction) │
                                                        │
   AIController.run_phase()      → drives units, returns when done
   HotseatController.run_phase() → configures cursor, unlocks,
                                   await TurnManager.phase_committed,
                                   returns

End Turn (UI) → MapCursor._on_end_turn_requested()
             → TurnManager.request_end_phase()
                  ├─ active faction blue → end_player_phase()
                  └─ active faction hotseat → emit phase_committed
```

- **Contract:** `run_phase(grid: GridManager, turn: TurnManager, faction_id: String) -> void`.
- **`phase_committed`** is a new `TurnManager` signal. It is emitted by
  `request_end_phase()` for a hotseat faction **and** must also be emitted when
  the map ends mid-phase (see Risk R1) so a waiting HotseatController never hangs.

---

## 5. Implementation steps

Each step is one commit; the suite stays green throughout.

**Step 1 — Controller contract (behaviour-neutral).**
Rename `EnemyAI.run_ai_phase` → `run_phase`. Update the `start_enemy_phase`
call site and the C3 test stubs (`test_turn_manager.gd`, `test_enemy_ai.gd`)
that reference `run_ai_phase`. No behaviour change — verify the suite is green.

**Step 2 — TurnManager phase-end seam.**
- Add `signal phase_committed`.
- Add `are_all_units_done(faction_id: String) -> bool` — generalises
  `are_all_player_units_done()` to iterate `gs.get_living_units_of(faction_id)`.
  Keep `are_all_player_units_done()` as a thin `are_all_units_done("blue")` shim
  (or migrate callers).
- Add `request_end_phase()`: reads `active_faction()`; if `"blue"` →
  `end_player_phase()`; else → `emit phase_committed`.
- Generalise the auto-end (`_auto_end_player_phase` and its two call sites) so a
  hotseat faction with all units done also auto-ends.

**Step 3 — HotseatController.**
New node `scripts/core/HotseatController.gd` implementing `run_phase()`:
configures the cursor (Step 4's setter), `unlock()`s it, `await turn.phase_committed`,
returns. Add `_hotseat_controller` + `set_hotseat_controller()` to TurnManager,
mirroring the AI seam. In `start_enemy_phase`, route a `HOTSEAT` faction to the
hotseat controller instead of skipping: `_controller_for(faction)`.

**Step 4 — MapCursor wiring.**
- Add `set_controlling_faction(faction_id: String)` — re-points the cursor and
  its `MapCursorSelection` / `MapCursorTargeting` slices.
- `_on_end_turn_requested()` routes through `TurnManager.request_end_phase()`;
  the "some units have not acted" confirm dialog uses
  `are_all_units_done(active_faction())` so it works for any faction.
- Wire the HotseatController with the `MapCursor` reference in `GameMap`.

**Step 5 — Cleanup.**
- Remove `controller = "HUMAN"` from `map_001_c3_factions_data.tres`.
- Revert the `"HUMAN"` line in `FactionData.gd`'s `controller` doc comment
  (added under Issue 8, superseded by Q5) — document `AI | HOTSEAT | REMOTE`.
- Amend `GDD_10_Roadmap.md` M15 Part A: scope to WHOLE_PHASE; split ALTERNATING
  hotseat into a later backlog item; mark the `grant_extra_turn` checklist item
  blocked on M10.

**Step 6 — Content + verification.**
Author a small WHOLE_PHASE test map with one `HOTSEAT` non-blue faction
alongside an `AI` faction. Manual verify per §6; run the full suite.

---

## 6. Test plan

**Headless unit tests:**
- `TurnManager.are_all_units_done(faction)` — true/false per faction bucket.
- `request_end_phase()` — blue → `end_player_phase`; hotseat → `phase_committed`
  fires (use a signal-watcher / await-with-timeout).
- `start_enemy_phase` loop routes a `HOTSEAT` faction to the injected hotseat
  controller and an `AI` faction to the AI controller (extend the C3 stage-4
  test with a mixed turn order + a hotseat stub).
- `HotseatController.run_phase()` — returns after `phase_committed`; sets the
  injected cursor stub's controlling faction and calls `unlock()`.
- `MapCursor.set_controlling_faction()` — selection/targeting follow the new id.

**Manual verification (the GDD acceptance test):**
Assign green to hotseat on the Step 6 map; confirm a second person drives green
units via the cursor, End Turn passes to the red (AI) phase, AI factions are
unaffected, and blue play is unchanged. Also verify an all-non-blue-AI map still
plays exactly as M14.

---

## 7. Risks / edge cases

- **R1 — map ends mid-hotseat-phase.** If victory/defeat fires (via `_on_unit_died`)
  while a HotseatController awaits `phase_committed`, it would hang. **Mitigation:**
  emit `phase_committed` (or a paired `phase_aborted`) whenever `_map_over` latches,
  and have `run_phase()` return immediately when `_map_over` is already set.
- **R2 — camera save/restore.** `MapCursor._on_phase_changed` saves the view on
  ENEMY entry and restores on PLAYER. During a hotseat phase the human pans
  freely; blue's pre-phase view is restored when blue resumes. Acceptable — note
  it, do not special-case.
- **R3 — the lock→unlock window (Q4).** Confirm `set_phase` → `phase_changed` →
  `lock()` and the subsequent `controller.run_phase()` → `unlock()` all run
  before any frame yields. If an `await` sneaks in between, the cursor flickers
  locked. Covered by the Step 3 test.

---

## 8. Deferred (not Part A)

- ALTERNATING-mode hotseat (Q6) and ALTERNATING phase handoff generally.
- `grant_extra_turn` controller-routing — blocked on M10.
- Per-phase `InputMap` action sets (feasibility doc §5 stage 6 "optional polish").
- M15 Part B (REMOTE) — the `run_phase()` contract is the seam it will reuse.
