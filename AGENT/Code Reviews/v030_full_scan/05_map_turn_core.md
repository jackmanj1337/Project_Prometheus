# Pass 5 — Map/turn core

Part of the v0.3.0 full-scan (`_TRACKER.md`). Document-only; fixes land later.

- Reviewed at head `b7bcfd2` (working tree == `b7bcfd2` for all 5 files; confirmed
  `git diff b7bcfd2 HEAD` empty for them).
- Files (5): `scripts/core/MapCursor.gd` (1946), `scripts/core/MapCursorTargeting.gd`
  (351), `scripts/core/GridManager.gd` (683), `scripts/core/GameMap.gd` (351),
  `scripts/core/TurnManager.gd` (1297).
- Diffs read: `MapCursor` `+733/−…`, `TurnManager` `+208`, `GridManager` `+115`,
  `MapCursorTargeting` `+25`, `GameMap` `+144`.
- Cross-read: `RngService.gd` (seed lifecycle), `MapCursorInput.gd` (arm/poll seam),
  `scripts/tests/` suites (`test_map_cursor`, `test_map_cursor_input`,
  `test_grid_manager`, `test_turn_manager`, `test_suspend_map_runtime`,
  `test_rng_*`).

**Findings: 1 High (carried, re-CONFIRMED — fix site is here) + 4 Low (1 nit).**
No new correctness bugs.

---

## H1 — [CARRIED, re-CONFIRMED] Fresh maps never call `RngService.start_map()`

- **Severity:** High
- **File & line:** `scripts/core/GameMap.gd:107-127` (fix site); root confirmed at
  `:127` (`_turn_manager.start_map(...)`) and `RngService.gd:21` (`start_map` only
  test/replay-invoked in production).
- **Problem:** `GameMap._ready()`, on the fresh (not-resuming) path, runs
  `gs.call("take_map_snapshot")` (`:115`) and then `_turn_manager.start_map(map_data,
  _grid)` (`:127`) — but nothing on this path calls `RngService.start_map()`.
  `TurnManager.start_map` (verified `:76-110`) does **not** call it either. So
  `RngService.map_seed` stays `0` and `history_hash` is **never reset between maps**.
- **Why it matters:**
  1. Zero cross-session entropy — every fresh map runs on `map_seed == 0`, so the
     whole dice timeline (`begin_event` mixes `map_seed`) is identical run-to-run.
  2. `history_hash` bleeds across maps within a session — map N's committed-action
     chain carries into map N+1, so the same action produces different dice
     depending on what was played earlier that session (a replay/repro hazard).
  3. The Retry snapshot at `:115` captures whatever stale `map_seed`/`history_hash`
     were left over, so Retry inherits the wrong dice identity.
  - Snapshot/resume are unaffected: `_apply_suspend_resume` (`GameMap.gd:260-263`)
    restores RNG via `rng_svc.from_save_dict(...)`, which is correct.
- **Root cause:** the seed lifecycle was never wired into production map boot — only
  tests/replay call `start_map(seed_override)`.
- **Recommended fix:** on the fresh (`not is_resuming`) branch, seed **before** the
  snapshot — call `RngService.start_map()` in `GameMap._ready()` just before
  `gs.call("take_map_snapshot")` (`:114-115`), via `get_node_or_null("/root/RngService")`
  with a null guard (headless). Do NOT put it on the resume branch (that path restores
  from the save dict). A focused test: two fresh boots produce different `map_seed`,
  and a second map in the same session starts at `history_hash == 0`.
- **Tradeoffs:** none — this is the missing half of the RNG-2 lifecycle.

---

## L1 — Dead `TurnManager._array_from_variant`

- **File & line:** `scripts/core/TurnManager.gd:231-232`.
- **Problem:** `_array_from_variant(value)` has **no in-file caller** (grep-confirmed:
  the only `_array_from_variant` hits in `TurnManager.gd` are its own definition; every
  other project caller is `SaveData.gd`'s separate `static` copy). It was likely added
  alongside `_string_array_from_variant`/`_dict_records_from_variant` (which ARE used
  by `start_map_from_suspend`) but never consumed.
- **Why it matters:** dead code (procedure §4B) — a reader assumes it's live.
- **Fix:** delete it (SaveData keeps its own).

## L2 — Unused overlay `blend` metadata + `overlay_layer_blends()` accessor

- **File & line:** `scripts/core/GridManager.gd:562-576`.
- **Problem:** `register_overlay_layer` stores a `blend` flag and
  `overlay_layer_blends(layer_id)` reads it back, but **nothing consumes it**
  (grep-confirmed: only the store at `:563` and the accessor at `:574-576`).
  `repaint_overlays` (`:583-…`) achieves the "exclusive opaque top layer" effect for
  hover-peek/path-arrows purely via ascending `precedence` + opaque tile art
  (last-`set_cell`-wins), never via the `blend` flag. The flag + accessor are a
  speculative abstraction ahead of a consumer.
- **Why it matters:** the doc comment (`:520-528`) promises `blend=false → exclusive
  opaque top layer`, but that semantic isn't enforced anywhere; a future author could
  register `blend=false` and be surprised it changes nothing.
- **Fix (pick one):** either (a) drop the `blend` field + accessor until a consumer
  exists (simplest, matches "no dead code"), or (b) have `repaint_overlays` honor it —
  when painting a `blend=false` layer, first clear the cells it will occupy from lower
  layers so it's genuinely exclusive, not merely opaque-on-top. The precedence
  registry itself is a good open-registry pattern (see Positives); only the unused
  half is the smell.

## L3 (nit) — `_pending_item_id` not cleared on promotion/reclass cancel

- **File & line:** `scripts/core/MapCursor.gd:1439-1440`
  (`_on_promotion_item_cancelled`) vs the confirm path clearing it at `:1434-1435`.
- **Problem:** the cancel callback reopens the ActionMenu but leaves `_pending_item_id`
  set to the cancelled item's id. **Benign today** — `_pending_item_id` is only read in
  `_on_promotion_item_confirmed`, and every path that reaches confirm first re-sets it
  in `_apply_item_effect` (`:1401`/`:1407`), so the stale value is always overwritten
  before it's read.
- **Fix:** clear `_pending_item_id = ""` in `_on_promotion_item_cancelled` for symmetry
  with the confirm path (defensive against a future confirm path that forgets to set it).

## L4 — Keyboard-held zoom now auto-repeats via `_poll_held_zoom`

- **File & line:** `scripts/core/MapCursor.gd:1499-1519` (`_poll_held_zoom`) + the
  `_process` call site `:319-321`; press edge at `:283-291`.
- **Problem:** `_poll_held_zoom` polls `Input.get_action_strength("zoom_in"/"zoom_out")`
  every frame and steps the discrete zoom on a timer. The intent (per the header
  comment and gamepad slice 2) was **held-trigger** zoom, but the poll reads action
  strength device-agnostically, so **holding a keyboard zoom key now repeats** too
  (previously discrete: one step per non-echo press). No double-step on the press frame
  (traced: `_arm_zoom_repeat` sets `_zoom_held_direction` before the poll, so the poll's
  `direction == _zoom_held_direction` branch ticks the DELAY timer instead of stepping).
- **Why it matters:** a behavior change from prior discrete keyboard zoom. Likely
  intended/acceptable (parity with the trigger, clamps at min/max), but it is
  undocumented and not asserted by a test — flagging so the owner can confirm it's the
  wanted UX rather than an accident of the shared poll.
- **Fix (only if unwanted):** gate the keyboard portion — e.g. only poll-repeat when the
  active source is a joypad axis — or accept and add a one-line note + a test asserting
  held keyboard zoom repeats. No change needed if intended.

---

## Positive observations

- **Determinism (E) clean:** no raw `randi()/randf()/randomize()` in any of the 5 files
  (grep-confirmed) — all gameplay dice route through `RngService`. The new RNG commit
  seam is disciplined: non-dice actions (`wait`/`seize`/`escape`/`item`/`staff`/
  `pair_up`/`swap`/`separate`) call `TurnManager.commit_action_event` /
  `RngService.commit_event`, and the header explicitly warns dice-bearing kinds
  (attack/levelup) must NOT route through it (double-advance guard).
- **Pass-3 arm-on-decode concern resolves CLEAN.** Traced the keyboard/d-pad edge vs
  analog poll seam: `_handle_discrete_press` (`MapCursor.gd:344-355`) calls
  `move_cursor(dir)` then `_input_handler.arm_repeat(dir)` **synchronously**, setting
  `_held_dir` before `_process` runs `poll_direction` that same frame.
  `poll_direction` (`MapCursorInput.gd:116-124`) sees `dir == _held_dir` → `tick()`,
  which waits `KEY_REPEAT_DELAY` — so the edge move and the poll never both fire on the
  press frame. TARGETING never reaches the poll (`_process` early-returns for non
  FREE/UNIT_SELECTED after `clear_repeat`). No double-move.
- **Stale pre-move-tile desync defused (Pass 2 positive re-confirmed in the RNG record
  path).** `_original_tiles.erase(unit)` now runs on `set_unit_state(...DONE)`
  (`TurnManager.gd:604-607`), `_refresh_faction_units` (`:383-385`), and
  `end_alternating_activation` (`:591`), so `get_action_start_tile` (`:589-591`) — the
  `from_tile` of every RNG event record — can't inherit a previous action's move start.
- **Quit paths deduped:** both `_on_quit_to_menu_requested` and the new
  `_on_suspend_and_quit_requested` funnel through `_return_to_main_menu`
  (`MapCursor.gd`), so the reset-state + scene-change is written once.
- **Overlay precedence registry is a proper open registry** (`GridManager.gd:530-559`) —
  adding an overlay (healing zones, objective markers) is a `register_overlay_layer`
  call + a spec entry, not a `repaint` edit. Matches the `AGENTS.md` open-registry
  principle and the `[MRD-1]`/`[EXT]` intent; `test_grid_manager` already registers a
  `fixture_healing_zone` to prove additivity.

## Next

- **Pass 6 — UI screens, selection & misc data (18 files).** Carries the Pass-6-scoped
  carried Medium (author-facing closed dispatch lists / registry debt → `DataManager`).
  No blockers carried into Pass 6 beyond that; H1 above is the last determinism fix
  site and is now fully localized to `GameMap._ready()`.
