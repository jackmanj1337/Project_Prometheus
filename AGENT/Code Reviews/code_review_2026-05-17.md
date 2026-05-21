# Code Review — 2026-05-17

Reviewer: Claude
Scope: the D-3 `MapCursor` slicing landed this session — `MapCursorSelection` and
`MapCursorInput` extraction, the key-repeat quirk fix, and the `.gitignore` change.
Files read in full: `MapCursor.gd` (575 lines), `MapCursorSelection.gd` (85),
`MapCursorInput.gd` (84), `MapCursorTargeting.gd` (153, for the slice pattern),
`test_map_cursor_selection.gd` (141), `test_map_cursor_input.gd` (115),
`test_map_cursor.gd` / `test_unit_selection.gd` (the edited regression nets).
Cross-checked against `GridManager` (`get_movement_path`, `can_end_on_tile`) and the
project `InputMap`. Suite re-run this pass: **14 suites / 300 tests green**.

This is a focused review of the refactor, per request — not a full-codebase pass.

---

## 1. Executive Summary

**Overall quality of the D-3 work: 8.5 / 10.**

The extraction is genuinely behavior-neutral and was verified as such at every commit
against the pre-existing nets before new tests were added — the right discipline. The
two new slices are cleanly encapsulated (a repo-wide grep finds **zero** external
references to the moved internals), consistently commented, and follow the established
`MapCursorTargeting` RefCounted+`setup()` pattern. No correctness regression was
introduced; the one genuinely risky spot — `plan_path_to`'s empty-array return
overloading both "illegal move" and "trivial path" — was checked against
`GridManager` and is sound. The findings below are one **pre-existing** input-map bug
that the refactor faithfully preserved (and that its new tests usefully surfaced), plus
small maintainability/test-comment nits.

---

## 2. Issues Found

### [SEVERITY: Medium]
- **File & Line:** `scripts/core/MapCursorInput.gd:28-40` (`decode_key`);
  `scripts/core/MapCursor.gd:142-144` (`Intent.OPEN_MENU` branch); project `InputMap`
  (`open_menu` / `cancel`).
- **Problem:** `open_menu` and `cancel` are **both bound to ESCAPE** in the project
  InputMap (`cancel` = X + ESCAPE; `open_menu` = ESCAPE only). `decode_key` tests
  `cancel` before `open_menu`, so an ESCAPE press always decodes as `CANCEL` — the
  `OPEN_MENU` intent is unreachable from the keyboard, and `_open_map_menu()` is dead.
  Mouse handling (`_handle_mouse_button`) only does confirm/cancel, so I found **no
  reachable path to open the map menu** in `MapCursor`. The map menu is where
  `end_turn_requested` originates, so this likely means the player cannot manually open
  the map menu / end-turn dialog at all.
- **Root Cause:** Pre-existing — the old `_handle_key_press` had the same `cancel`
  elif *before* the `open_menu` elif. The D-3 refactor preserved it faithfully (correct
  for a behavior-neutral extraction), and the new `test_map_cursor_input.gd` ESCAPE test
  documents it. **This is not a refactor regression** — it is a latent input-map bug the
  refactor's tests made visible.
- **Recommended Fix:** Decide the intended key. If the map menu should have its own
  key, rebind `open_menu` in the InputMap to a free key (the `[input]` block shows
  `open_settings` on `O`, so the menu cluster is otherwise sparse) — no code change
  needed. If ESCAPE is *meant* to open the menu from `FREE`, then `decode_key` must test
  `open_menu` before `cancel` *and* be state-aware, which breaks its state-agnostic
  contract — the InputMap rebind is the cleaner fix.
- **Tradeoffs:** None for the rebind. Flag: confirm there is no other map-menu entry
  point (e.g. an on-screen button in a HUD scene) before treating this as player-facing
  breakage — this review covered `MapCursor` only.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/MapCursorSelection.gd:54` (`plan_path_to`, the
  `_grid == null` guard).
- **Problem:** `plan_path_to` guards `if _grid == null or not _grid.can_end_on_tile(...)`.
  The `_grid == null` half is unreachable: if `_grid` is null, `select_at` returned
  false, so `selected_unit` is null and `movement_tiles` is empty — the earlier
  `selected_unit == null` / `tile in movement_tiles` checks already returned `[]`. The
  guard is harmless defensive code, but a reader may puzzle over when it fires.
- **Root Cause:** Defensive symmetry with `select_at`'s real `_grid == null` guard.
- **Recommended Fix:** Either drop the `_grid == null` half (rely on the earlier
  returns) or keep it with a one-word comment that it is belt-and-suspenders. Minor.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/MapCursorInput.gd:28-40` (`decode_key` return),
  `scripts/core/MapCursor.gd:123-126` (`decoded["intent"]` / `decoded["dir"]`).
- **Problem:** `decode_key` returns an untyped, string-keyed `Dictionary`. The caller
  reads `decoded["intent"]` and `decoded["dir"]` — a typo in either key is silent (a
  `match` on a missing key would fall through to no branch; `decoded["dir"]` on a miss
  would error at runtime, not parse time). The design doc explicitly chose a Dictionary,
  so this is a known trade, not an oversight.
- **Root Cause:** Dictionary is the lightest possible multi-value return in GDScript;
  the alternatives (a tiny RefCounted result, or returning the `Intent` and exposing
  `dir` as a slice field) are heavier.
- **Recommended Fix:** Acceptable as-is for a two-field result. If `decode_key` ever
  grows a third field, promote it to a small typed result object. No change needed now.
- **Tradeoffs:** A typed result is safer but adds a class; not worth it for two fields.

### [SEVERITY: Low]
- **File & Line:** `scripts/tests/test_map_cursor_selection.gd:90` (comment above the
  out-of-range search loop).
- **Problem:** The comment reads "movement 5 from (2,2) on plain → only (5,5)", but the
  loop actually picks `(4,4)` — the enemy-occupied tile, which `get_movement_range`
  excludes via `can_end_on_tile` regardless of cost. The test is still **correct** (it
  validates "a tile not in `movement_tiles` → `[]`"), but the comment misdescribes which
  tile and why it is excluded. The test's own output line prints the real tile, so the
  discrepancy is visible at runtime.
- **Root Cause:** The comment was written predicting cost-range exclusion; the
  occupied-tile exclusion reaches the loop first.
- **Recommended Fix:** Reword to "Find any tile not in `movement_tiles` — either out of
  cost range, or excluded because it is occupied (the enemy at (4,4))."
- **Tradeoffs:** None — comment only.

### [SEVERITY: Low — test debt]
- **File & Line:** `scripts/core/MapCursor.gd:318-327` (`_try_move_selected_to_cursor`);
  `test_map_cursor.gd` / `test_unit_selection.gd`.
- **Problem:** `_try_move_selected_to_cursor`'s correctness hinges on `plan_path_to`
  never returning `[]` for a legal in-range tile. I verified this holds — including the
  subtle case of confirming on the unit's **own tile** (`get_movement_path` special-cases
  `start == target` to return `[start]`, a size-1 non-empty path, so the cursor still
  proceeds to `UNIT_MOVED` + ActionMenu). But no test exercises that own-tile path:
  `test_unit_selection.gd` only does a 2-tile move, and `test_map_cursor.gd` cannot drive
  the `await`. A future change to `get_movement_path`'s `start == target` branch could
  silently break "stand still and act" with the suite green.
- **Root Cause:** The own-tile move is a real FSM path with no dedicated coverage; the
  D-3 plan acknowledged the `await` path is only covered by `test_unit_selection.gd`.
- **Recommended Fix:** Add a `test_map_cursor_selection.gd` case asserting
  `plan_path_to(unit.tile_position)` returns a non-empty (size-1) path — that pins the
  invariant `_try_move_selected_to_cursor` depends on, without needing the `await`.
- **Tradeoffs:** None — one extra cheap test.

---

## 3. Positive Observations

1. **Verified behavior-neutral, not assumed.** Each extraction commit ran the full
   suite (12→13→14 suites) *before* its new slice tests were written, so each refactor
   is proven neutral against the *existing* nets first. The commit messages state this
   discipline explicitly.
2. **Clean encapsulation.** A repo-wide grep for `_selected_unit` / `_movement_tiles` /
   `_held_dir` / `_direction_from_event` finds zero references outside `MapCursor` and
   its own test — nothing else reached into the cursor's internals, so the slicing had
   no blast radius. `MapCursorSelection` / `MapCursorInput` are referenced only by
   `MapCursor` and their tests.
3. **The class-cache problem was fixed at the root.** Rather than continuing to
   hand-patch the gitignored cache, the `.godot/*` + negation change versions
   `global_script_class_cache.cfg`, so the D-3 cache entries landed as ordinary tracked
   diffs and fresh clones / CI now resolve the new `class_name` scripts. This also
   retired the design doc's §7 clone-breakage risk.
4. **The quirk fix used judgment beyond the plan.** The design called it a "one-line
   fix"; in fact clearing `_held_initial` before the read makes its ternary always pick
   `RATE`, leaving the field dead. The fix correctly removed the field outright instead
   of leaving vestigial code — and the GDD cross-check confirmed the result matches
   GDD_07:46-47 ("0.25s delay, 0.10s rate"), so it is a spec-alignment fix, not a
   behavior invention.
5. **Comments explain the non-obvious *why*.** The `_input_handler` naming rationale
   (collision with the `_input()` callback), the "a RefCounted slice can't `get_node`"
   note on why the EventBus relays stay on `MapCursor`, and the `tick()` cadence comment
   all document decisions a maintainer would otherwise have to reverse-engineer.
6. **The input tests are honest.** `test_map_cursor_input.gd` builds real
   `InputEventKey`s against the real project `InputMap` rather than mocking the decode,
   and its ESCAPE→CANCEL case pins a genuine precedence rule (see the Medium finding)
   instead of asserting a convenient fiction.

---

## 4. Architectural Observations

- **`MapCursor` is now a coherent core.** At 575 lines (down from ~620) it is the
  cursor FSM + menus + camera + thin input/mouse receiver shells, with three RefCounted
  slices (`MapCursorTargeting`, `MapCursorSelection`, `MapCursorInput`) carrying the
  substance. All four `code_review_2026-05-16d` §4 carry-overs are now closed. The FSM
  entry methods (`_try_select_unit_at_cursor`, `_try_move_selected_to_cursor`,
  `_deselect`, `_undo_move_and_reselect`, `_finish_action`) are real FSM shells — they
  own the `_state` writes, the `LOCKED` guard, the `await`, the liveness guard, and the
  EventBus relays — not pass-through delegators. That is the right boundary: the FSM is
  legible in one file, the queries/painting are unit-testable in isolation.
- **Consistent slice pattern.** All three slices are `RefCounted` with a `setup()`
  injection point, so they are exercisable in `--script` mode without a `SceneTree`.
  This is the same pattern the 16d review praised for `MapCursorTargeting`; D-3 extended
  it uniformly.
- **The `MapCursorInput` ↔ `MapCursor` boundary is a string-keyed dict.** Functional,
  but the only untyped seam in the new code (see Low finding). Worth promoting to a
  typed result if that boundary grows.
- **Out-of-scope, by design (D-3 §8):** `_scroll_camera_if_needed`,
  `_handle_targeting_mouse_motion` / `_cycle_target`, mouse handling, and the
  danger-zone hold all remain on `MapCursor` because they are `get_viewport()` /
  grid-coupled. None are urgent; `MapCursor` no longer reads as oversized.

---

## 5. Prioritized Action Plan

1. **Resolve the `open_menu` ESCAPE shadowing** (Medium): confirm whether the map menu
   has any other entry point; if not, rebind `open_menu` to a free key in the project
   InputMap. No code change — an InputMap edit. This is the one finding with
   player-facing impact, and it predates D-3.
2. **Add the own-tile `plan_path_to` test** (Low/test-debt): one cheap case in
   `test_map_cursor_selection.gd` pinning the size-1-path invariant
   `_try_move_selected_to_cursor` relies on.
3. **Fix the `test_map_cursor_selection.gd` out-of-range comment** (Low): describe the
   occupied-tile exclusion accurately.
4. **Tidy `plan_path_to`'s redundant `_grid == null` guard** (Low): drop it or annotate
   it. Cosmetic.

None of items 2-4 are urgent; item 1 should be confirmed before the next playable build.

---

## Assumptions Flagged

- I assume the map menu has no entry point outside `MapCursor` (no HUD button). This
  review covered the cursor and its slices only — if a HUD scene opens the map menu
  directly, the Medium finding is cosmetic rather than player-facing.
- I assume the D-3 design's intent was a strictly behavior-neutral extraction (the
  commit messages and design doc say so); the key-repeat fix is the one deliberate
  behavior change, and it aligns the code to GDD_07:46-47.
- Suite was read and re-run: 14 suites / 300 tests green (`bash run_tests.sh`).
