# D3 Design — Extracting `MapCursorInput` and `MapCursorSelection`

Completes the `MapCursor` slicing begun in D2 (`d2_mapcursortargeting_design.md`). Lifts
two more clusters out of `MapCursor` into separately unit-testable objects, with **no
behavior change**. This is the last `code_review_2026-05-16d.md` §4 carry-over.

Safety net already in place: `test_map_cursor.gd` (16 FSM tests, added Session I) plus
`test_unit_selection.gd` (10 tests against the real scene). Both must stay green through
every step below.

---

## 1. Object type — `RefCounted` for both slices

`MapCursorInput extends RefCounted` and `MapCursorSelection extends RefCounted` — matching
`MapCursorTargeting`. Not `Node`s, not inner classes.

**The input-receiver constraint.** Godot only calls `_unhandled_input` / `_input` /
`_process` on a `Node` that is in the tree. So `MapCursorInput` **cannot be the input
receiver** — `MapCursor` keeps those thin callbacks and *forwards* raw events to the
slice. `MapCursorInput` is therefore a **decoder + key-repeat timer**, not an input owner.

**Why not a child `Node` for input (rejected).** A child node with its own
`_unhandled_input` would make event-propagation order between two receivers fragile, mix
slice types (some RefCounted, some Node), need `_state` pushed into it anyway, and churn
the `.tscn`. The decoder approach keeps one receiver and unchanged ordering, so behavior
is provably preserved, and a RefCounted is testable without a `SceneTree`.

**Scope limit on `MapCursorInput`.** Keyboard decoding + key-repeat only. Mouse motion
needs `get_viewport()` (a `Node` call for the canvas transform), so `_handle_mouse_motion`
/ `_handle_mouse_button` stay on `MapCursor`. The danger-zone hold (`_input`) is small and
grid-coupled — it stays too.

---

## 2. Ownership boundary

| Concern | Owner after extraction |
|---|---|
| `State` enum, `_state` (cursor FSM), `_on_confirm` / `_on_cancel` dispatch | `MapCursor` |
| `current_tile`, `_set_tile`, `move_cursor`, camera scrolling | `MapCursor` |
| `_unhandled_input` / `_input` / `_process` callbacks (thin shells) | `MapCursor` |
| mouse motion/button handling, danger-zone hold | `MapCursor` |
| action/item/map-menu wiring, `_show_action_menu`, `_finish_action`, `_cycle_to_next_unit` | `MapCursor` |
| EventBus emissions (`unit_selected` / `unit_deselected` / `cursor_moved`) | `MapCursor` |
| `_targeting` (D2 slice), `_enter_targeting`, targeting mouse/cycle helpers | `MapCursor` / `MapCursorTargeting` |
| key-event → intent decoding; `_held_dir` / `_held_timer` / `_held_initial`; auto-repeat tick | **`MapCursorInput`** |
| `_selected_unit`, `_movement_tiles`; select / move-path / deselect / undo-reselect | **`MapCursorSelection`** |

**The FSM stays on `MapCursor`.** Neither slice reads or writes `MapCursor._state`.
Neither slice touches EventBus (a RefCounted cannot `get_node`) — `MapCursor` relays.
This mirrors D2.

---

## 3. `MapCursorSelection` — public API

```gdscript
class_name MapCursorSelection extends RefCounted

# Injected when MapCursor.setup() runs and _grid/_turn are known.
func setup(grid: GridManager, turn: TurnManager) -> void

# Port of _try_select_unit_at_cursor minus the _state write and EventBus emit.
# Validates team/can_act, sets the selected unit, computes the movement range, paints
# the movement + attack overlays. Returns true when a unit was selected.
func select_at(tile: Vector2i) -> bool

# Port of _try_move_selected_to_cursor's validation half. If `tile` is a legal
# destination: records the move-start for undo, computes the path, clears overlays,
# returns the path. Returns [] when the move is illegal (caller stays UNIT_SELECTED).
# A non-empty result (even size 1) means "proceed".
func plan_path_to(tile: Vector2i) -> Array[Vector2i]

# Port of _undo_move_and_reselect's substance: _turn.undo_move(), recompute the
# movement range, repaint overlays. Caller sets _state = UNIT_SELECTED.
func undo_and_reselect() -> void

# Clears overlays, nulls the selected unit, clears the movement tiles. Used by both
# the cancel path (_deselect) and the completion path (_finish_action).
func clear() -> void

var selected_unit: Unit               # public: MapCursor reads it; tests read + inject it
var movement_tiles: Array[Vector2i]   # public: test_unit_selection.gd reads it
```

`selected_unit` and `movement_tiles` are plain **public** vars: the slice's methods write
them, `MapCursor` reads `selected_unit`, and the two test suites both read them and inject
`selected_unit` directly (§6). Injected internals: `_grid`, `_turn`.

---

## 4. `MapCursorInput` — public API

Member name on `MapCursor` must **not** be `_input` (collides with the `_input` callback)
— use `_input_handler`.

```gdscript
class_name MapCursorInput extends RefCounted

enum Intent { NONE, MOVE, CONFIRM, CANCEL, NEXT_UNIT, OPEN_MENU }

# State-agnostic key decode. Arrows always decode as MOVE + a direction; MapCursor
# decides per _state whether that is a cursor move, a target cycle, or ignored.
func decode_key(event: InputEventKey) -> Dictionary    # {"intent": Intent, "dir": Vector2i}

# Key-repeat (held-direction auto-repeat).
func arm_repeat(dir: Vector2i) -> void                 # call on a fresh direction press
func note_key_released(event: InputEventKey) -> void   # clears _held_dir if it matches
func clear_repeat() -> void                            # used by MapCursor.lock()
func tick(delta: float) -> Vector2i                    # per-frame; ZERO or a step direction
```

Internal state: `_held_dir`, `_held_timer`, `_held_initial`.

The `KEY_REPEAT_DELAY` / `KEY_REPEAT_RATE` consts move from `MapCursor` into
`MapCursorInput` (it owns repeat timing); `CAMERA_EDGE_BUFFER` stays on `MapCursor`.
`decode_key` assumes the caller (`MapCursor._unhandled_input`) has already filtered to
`pressed`, non-`echo` key events — it does not re-check. The slice member on `MapCursor`
is `_input_handler` (the name `_input` would collide with the `_input` callback).

**Port `tick()` verbatim.** The current `_process` repeat has a latent quirk: the first
auto-repeat step waits `DELAY` *twice* (`_held_initial` is cleared after the timer is set,
so the first repeat re-arms with `DELAY` instead of `RATE`). The comment promises
"0.25s pause, then 0.10s per step". Preserve the quirk in `tick()` so the extraction is
behavior-neutral; the one-line fix (clear `_held_initial` before reading it) is a
**separate** change, out of scope here. The `test_map_cursor_input.gd` timing test should
assert the *current* behavior and carry a comment naming the quirk.

---

## 5. `MapCursor` side after extraction

```gdscript
var _selection: MapCursorSelection = MapCursorSelection.new()
var _input_handler: MapCursorInput = MapCursorInput.new()

# in setup()
_selection.setup(_grid, _turn)
# _input_handler needs no injection — it is pure decode + timer state.

func _handle_key_press(event: InputEventKey) -> void:
    var decoded := _input_handler.decode_key(event)
    match decoded["intent"]:
        MapCursorInput.Intent.MOVE:
            match _state:
                State.FREE, State.UNIT_SELECTED:
                    move_cursor(decoded["dir"])
                    _input_handler.arm_repeat(decoded["dir"])
                State.TARGETING:
                    _cycle_target(decoded["dir"])
        MapCursorInput.Intent.CONFIRM:   _on_confirm()
        MapCursorInput.Intent.CANCEL:    _on_cancel()
        MapCursorInput.Intent.NEXT_UNIT: _cycle_to_next_unit()
        MapCursorInput.Intent.OPEN_MENU:
            if _state == State.FREE: _open_map_menu()

func _process(delta: float) -> void:
    if _state != State.FREE and _state != State.UNIT_SELECTED:
        _input_handler.clear_repeat()
        return
    var d := _input_handler.tick(delta)
    if d != Vector2i.ZERO:
        move_cursor(d)

func _try_select_unit_at_cursor() -> void:        # still the FREE-confirm handler
    if _selection.select_at(current_tile):
        _state = State.UNIT_SELECTED
        var bus := get_node_or_null("/root/EventBus")
        if bus: bus.unit_selected.emit(_selection.selected_unit)

func _try_move_selected_to_cursor() -> void:
    var path := _selection.plan_path_to(current_tile)
    if path.is_empty(): return
    _state = State.LOCKED
    await _selection.selected_unit.move_along_path(path)
    _state = State.UNIT_MOVED
    _show_action_menu()

func _deselect() -> void:
    _selection.clear()
    _state = State.FREE
    var bus := get_node_or_null("/root/EventBus")
    if bus: bus.unit_deselected.emit()

func _undo_move_and_reselect() -> void:
    if _state == State.LOCKED: return
    _selection.undo_and_reselect()
    _state = State.UNIT_SELECTED

func _finish_action() -> void:
    var u := _selection.selected_unit
    if _turn != null and is_instance_valid(u) and u.data != null and u.data.hp > 0:
        _turn.set_unit_state(u, TurnManager.UnitState.DONE)
    _selection.clear()
    _state = State.FREE
```

`_show_action_menu`, `_use_item`, `_enter_targeting` read `_selection.selected_unit`
instead of the old `_selected_unit` field.

**The FSM-entry methods are not delegating shims.** `_on_confirm`, `_on_cancel`,
`_finish_action`, `_undo_move_and_reselect`, `_try_select_unit_at_cursor`,
`_try_move_selected_to_cursor` keep real responsibility — the `_state` transitions, the
`LOCKED` guard, the `await`, the liveness guard, the EventBus relay. Only the *substance*
(grid queries, overlay painting, unit/tile bookkeeping) moves into the slices. That is
why `test_map_cursor.gd` needs no behavioral edits (see §6).

---

## 6. Test plan

`test_map_cursor.gd` (16 FSM tests) and `test_unit_selection.gd` (10, real scene) are the
regression net. The FSM *logic* is unchanged (entry methods stay on `MapCursor`, §5), but
both suites poke fields that **move into the slices**, so they need mechanical field-
reference edits (no logic changes):

**`test_map_cursor.gd`** — `_selected_unit` → `_selection.selected_unit` (reads in T6–T10;
writes in T11–T14, e.g. `c._selection.selected_unit = unit`); `_held_dir` →
`_input_handler._held_dir` (T2, set + assert). ~10 of the 16 cases touch one of these.

**`test_unit_selection.gd`** — `cursor._selected_unit` → `cursor._selection.selected_unit`
(lines ~32/36/49/53); `cursor._movement_tiles` → `cursor._selection.movement_tiles`
(lines ~40/41/44).

Make these edits in the **same commit as each extraction** (Selection-field edits with
the Selection extraction; the `_held_dir` edit with the Input extraction), so the suite is
green at every commit. After the edits both suites still serve as the FSM/integration net.

New slice suites (per the chosen "update tests + add slice tests" approach):

- **`test_map_cursor_selection.gd`** — construct `MapCursorSelection.new()`,
  `setup(real GridManager with _terrain_fallback, real TurnManager)`, register units in a
  stub `/root/GameState` (reuse the `test_map_cursor.gd` pattern). Cover: `select_at`
  (player unit → true + `selected_unit` set + `movement_tiles` non-empty; enemy / empty /
  already-acted → false); `plan_path_to` (in-range tile → non-empty path; out-of-range →
  `[]`); `undo_and_reselect`; `clear` (nulls `selected_unit`).
- **`test_map_cursor_input.gd`** — construct `MapCursorInput.new()`. Cover: `decode_key`
  classification for confirm / cancel / each direction / next_unit / open_menu;
  `arm_repeat` + `tick` timing (`tick` returns ZERO before `DELAY` elapses, the direction
  after — and the verbatim double-`DELAY` quirk from §4); `note_key_released` and
  `clear_repeat` reset `_held_dir`.
  - Verify during impl: `decode_key` uses `event.is_action_pressed(...)`, so the test must
    build `InputEventKey`s with keycodes matching the project `InputMap`. The `InputMap`
    loads from project settings in `--script` mode, so this is expected to work — confirm
    early.

Register both new files in `run_tests.sh`.

---

## 7. Risk & sequencing

Order — **`MapCursorSelection` first** (larger, more tangled, best protected by the
existing nets), then `MapCursorInput`. Four commits:

1. Extract `MapCursorSelection` **+ patch the class cache (§9) + edit both test suites'
   `_selection.*` field references (§6)**; verify `test_map_cursor.gd` +
   `test_unit_selection.gd` green.
2. Add `test_map_cursor_selection.gd` (+ register in `run_tests.sh`).
3. Extract `MapCursorInput` **+ patch the class cache + edit `test_map_cursor.gd` T2's
   `_held_dir` reference**; verify both nets green.
4. Add `test_map_cursor_input.gd` (+ register in `run_tests.sh`).

Keeping extraction and new-tests in separate commits means each refactor is verified
behavior-neutral against the *existing* nets before new tests are written.

Risks:
- **Class-cache trap (do this first — see §9).** `MapCursorInput` / `MapCursorSelection`
  are new `class_name` scripts. `.godot/global_script_class_cache.cfg` is gitignored and
  is not regenerated by a plain file write, so until it is hand-patched, `MapCursor.gd`
  fails to compile under headless `--script` and the whole suite (and the pre-commit hook)
  fails. Patch the cache immediately after creating each slice file, before editing
  `MapCursor.gd`.
- **The `await` move path is not covered by `test_map_cursor.gd`** (it needs a real
  `move_along_path`). It is covered by `test_unit_selection.gd` against the real scene —
  that suite must stay green. The new `plan_path_to` slice test covers the path-planning
  half directly.
- **`plan_path_to` must have no side effects on a `[]` return** — replicate
  `_try_move_selected_to_cursor`'s early-out: on an illegal destination, do **not**
  `record_move_start` and do **not** `clear_overlays`. Record/clear only happen once the
  move is committed.
- **Dropped EventBus emits** would silently break HUD updates. The emits stay on
  `MapCursor` (§5); `test_unit_selection.gd` exercises the real scene. Spot-check
  `unit_selected` / `unit_deselected` manually.
- **`_input` name collision** — the input-slice member is `_input_handler`, never `_input`.
- **Key-repeat quirk** — port `tick()` verbatim; do not "fix while moving" (§4).
- **Slice methods null-guard internally** — `select_at` returns `false` when `_grid` is
  null; `undo_and_reselect` no-ops on a null unit/grid/turn. The `_state == LOCKED` guard
  for undo stays on `MapCursor` (it owns `_state`).

---

## 8. Out of scope

- Extracting `_scroll_camera_if_needed` (small, `get_viewport()`-coupled — leave on `MapCursor`).
- Moving `_handle_targeting_mouse_motion` / `_cycle_target` into `MapCursorTargeting`
  (a `MapCursorTargeting` follow-up, not part of this slicing).
- Mouse handling and the danger-zone hold (viewport/grid-coupled — stay on `MapCursor`).
- Fixing the key-repeat double-`DELAY` quirk (separate one-line change).

---

## 9. Implementation checklist (next session)

Baseline first: `bash run_tests.sh` → 12 suites / 277 green.

**Slice A — `MapCursorSelection`**
1. Create `scripts/core/MapCursorSelection.gd` (`class_name MapCursorSelection extends RefCounted`), API per §3.
2. **Patch the class cache** — append the block below to the `list` array in
   `.godot/global_script_class_cache.cfg` (before the closing `])`). `.godot/` is
   gitignored, so this is a local-only step that will *not* appear in the commit — but it
   is mandatory or step 5 fails.
3. Edit `MapCursor.gd`: delete the `_selected_unit` / `_movement_tiles` fields; add
   `var _selection := MapCursorSelection.new()`; call `_selection.setup(_grid, _turn)` in
   `setup()`; rewrite `_try_select_unit_at_cursor` / `_try_move_selected_to_cursor` /
   `_deselect` / `_undo_move_and_reselect` / `_finish_action` per §5; re-point
   `_show_action_menu` / `_use_item` / `_enter_targeting` to `_selection.selected_unit`.
4. Edit `test_map_cursor.gd` + `test_unit_selection.gd` field references per §6.
5. `bash run_tests.sh` green → commit `Extract MapCursorSelection slice from MapCursor`.
6. Add `test_map_cursor_selection.gd`, register in `run_tests.sh`, green → commit.

**Slice B — `MapCursorInput`**
7. Create `scripts/core/MapCursorInput.gd` (`class_name MapCursorInput extends RefCounted`); patch the cache (block below).
8. Edit `MapCursor.gd`: delete the `_held_*` fields and `KEY_REPEAT_*` consts; add
   `var _input_handler := MapCursorInput.new()`; rewrite `_handle_key_press` / `_process` /
   `lock` and the key-release branch of `_input` per §5.
9. Edit `test_map_cursor.gd` T2 (`_held_dir` → `_input_handler._held_dir`).
10. `bash run_tests.sh` green → commit `Extract MapCursorInput slice from MapCursor`.
11. Add `test_map_cursor_input.gd`, register in `run_tests.sh`, green → commit.

**Class-cache blocks** (append each inside `list=Array[Dictionary]([ ... ])`, comma-separated):
```
, {
"base": &"RefCounted",
"class": &"MapCursorSelection",
"icon": "",
"language": &"GDScript",
"path": "res://scripts/core/MapCursorSelection.gd"
}, {
"base": &"RefCounted",
"class": &"MapCursorInput",
"icon": "",
"language": &"GDScript",
"path": "res://scripts/core/MapCursorInput.gd"
}
```
Add each block in its own step — the `MapCursorSelection` block in step 2, the
`MapCursorInput` block in step 7 — right after creating the corresponding file. Do not
pre-add a block whose `.gd` file does not yet exist; a cache entry pointing at a missing
path can trip headless load warnings on the intervening test runs.

Done when: `bash run_tests.sh` → 14 suites / ~290+ green, and `MapCursor.gd` is down to
the FSM core + menus + camera + thin input/mouse shells.
