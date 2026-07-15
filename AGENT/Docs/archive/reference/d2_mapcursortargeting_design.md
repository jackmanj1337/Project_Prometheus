> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# D2 Design — Extracting `MapCursorTargeting`

Design pass for Phase D2 of `implementation_plan_2026-05-16.md`. Goal: lift the attack/staff
targeting flow out of `MapCursor` into a separately unit-testable object, with **no behavior
change**. This unblocks D2 for implementation.

---

## 1. Object type — `RefCounted` with dependency injection

`MapCursorTargeting extends RefCounted`. Not a `Node`, not an inner class.

**Rationale.** The whole point of the D-1 split is testability. The targeting logic needs almost
no scene-tree access — its only tree-dependent call today is
`get_node_or_null("/root/CombatResolver")`. Everything else operates on references it can be
*handed*: the `GridManager`, the `Unit`, the `AttackPreview` node, and a cursor tile (a plain
`Vector2i`). By injecting `CombatResolver` at setup, the object has zero tree dependencies and a
test can construct it directly without a `SceneTree`.

**Node alternative (rejected).** A child `Node` would allow `get_node` / easy `await`, but it
forces a scene edit and still needs grid/unit/cursor injected anyway (they aren't its children).
Future combat animations would make resolution async — a `RefCounted` handles that fine by
`await`ing a signal (e.g. `await combat_resolver.combat_finished`), so async is not a reason to
choose `Node`.

---

## 2. Ownership boundary

| Concern | Owner after extraction |
|---|---|
| `State` enum, `_state` (cursor FSM) | `MapCursor` |
| `current_tile`, `position`, cursor movement, camera | `MapCursor` |
| `_selected_unit`, `_movement_tiles`, selection flow | `MapCursor` |
| action/item/map menu wiring, `_show_action_menu`, `_finish_action` | `MapCursor` |
| `@export attack_preview` (editor-assigned node ref) | `MapCursor` (declared), injected into targeting |
| `_attack_tiles`, `_heal_tiles`, `_preview_target` | **`MapCursorTargeting`** |
| attack/staff target selection, preview, combat resolution, staff heal | **`MapCursorTargeting`** |

**Key decision: the cursor FSM stays on `MapCursor`.** The targeting object does **not** own or
write `MapCursor._state`. The current states `TARGETING`, `PREVIEWING`, `STAFF_TARGETING` collapse
into a single `MapCursor.State.TARGETING`; the attack-vs-staff and choosing-vs-previewing
distinctions become *internal* sub-state of `MapCursorTargeting`. `MapCursor` delegates while in
`TARGETING` and reacts to two signals.

Resulting `MapCursor.State` enum: `FREE, UNIT_SELECTED, UNIT_MOVED, TARGETING, LOCKED` (down from 7).

---

## 3. `MapCursorTargeting` public API

```gdscript
class_name MapCursorTargeting extends RefCounted

enum Mode { ATTACK, STAFF }

signal completed   # action resolved — MapCursor should _finish_action()
signal cancelled   # player backed out of target choice — MapCursor returns to ActionMenu

# Injected once, when MapCursor.setup() runs and _grid is known.
# attack_preview may be null (headless tests) — confirm then resolves immediately.
# combat_resolver may be null — resolution is skipped (matches today's `if cr:` guard).
func setup(grid: GridManager, attack_preview: Node, combat_resolver: Node) -> void

# Starts a targeting session. Returns the valid target tiles (caller snaps the cursor
# to tiles[0]). Returns an empty array when there are no targets — caller reopens the
# ActionMenu instead of entering TARGETING.
func begin(mode: Mode, unit: Unit) -> Array[Vector2i]

# Called by MapCursor._on_confirm while in State.TARGETING. cursor_tile is the cursor's
# current tile. In CHOOSING: shows the attack preview (ATTACK) or applies the heal (STAFF).
# In PREVIEWING: resolves the attack. Emits `completed` when the action finishes.
func handle_confirm(cursor_tile: Vector2i) -> void

# Called by MapCursor._on_cancel while in State.TARGETING.
# PREVIEWING -> back to CHOOSING (preview dismissed). CHOOSING -> emits `cancelled`.
func handle_cancel() -> void

# For the D1 input layer: the tiles the cursor may cycle among this session.
func target_tiles() -> Array[Vector2i]

# True only in the CHOOSING sub-state. The input layer checks this before moving the
# cursor — during PREVIEWING the cursor and target are frozen.
func can_change_target() -> bool

func is_active() -> bool
```

### Internal sub-state

```
enum _Sub { IDLE, CHOOSING, PREVIEWING }
var _sub: _Sub = _Sub.IDLE
var _mode: Mode
var _unit: Unit
var _tiles: Array[Vector2i] = []     # _attack_tiles / _heal_tiles unified
var _preview_target: Node = null
```

`begin()` → `_Sub.CHOOSING`. `handle_confirm` in ATTACK/CHOOSING → `_Sub.PREVIEWING` (or straight
to resolve when `attack_preview` is null). `handle_confirm` in PREVIEWING or STAFF/CHOOSING →
resolve/heal → `_Sub.IDLE` + emit `completed`. `handle_cancel` PREVIEWING → `_Sub.CHOOSING`;
CHOOSING → `_Sub.IDLE` + emit `cancelled`.

---

## 4. `MapCursor` side after extraction

```gdscript
var _targeting: MapCursorTargeting = MapCursorTargeting.new()

# in _ready()
_targeting.completed.connect(_on_targeting_completed)
_targeting.cancelled.connect(_on_targeting_cancelled)

# in setup() — _grid now known, CombatResolver autoload available
_targeting.setup(_grid, attack_preview, get_node_or_null("/root/CombatResolver"))

func _on_action_chosen(action: String) -> void:
    match action:
        "attack": _enter_targeting(MapCursorTargeting.Mode.ATTACK)
        "staff":  _enter_targeting(MapCursorTargeting.Mode.STAFF)
        "item":   _use_item()
        "wait":   _commit_wait()

func _enter_targeting(mode) -> void:
    var tiles := _targeting.begin(mode, _selected_unit)
    if tiles.is_empty():
        _show_action_menu()          # no targets — same as today
        return
    _state = State.TARGETING
    current_tile = tiles[0]
    position = _grid.tile_to_world(current_tile)

# _on_confirm / _on_cancel — single TARGETING branch each:
#   State.TARGETING: _targeting.handle_confirm(current_tile)   (confirm)
#   State.TARGETING: _targeting.handle_cancel()                (cancel)

func _on_targeting_completed() -> void:
    _finish_action()                 # clears overlays, marks unit DONE, _state = FREE

func _on_targeting_cancelled() -> void:
    _state = State.UNIT_MOVED
    _show_action_menu()
```

Overlay ownership: `MapCursorTargeting` paints and clears its own attack/heal overlays (on
`begin`, on resolve, on cancel). `_finish_action()` still calls `_grid.clear_overlays()` — that is
idempotent, so no conflict.

`LOCKED` during resolution: combat resolves synchronously (no `await` today), so the momentary
`LOCKED` the old `_do_resolve_attack` set never actually blocked a frame. It is dropped;
`_on_targeting_completed` → `_finish_action()` sets `FREE` directly. (Revisit if combat animations
add an `await` later.)

---

## 5. D1 ↔ D2 interaction

D1 lands first and gates input in-place using `_attack_tiles` / `_heal_tiles`. D2 then re-points
the D1 input layer at the targeting object — still no behavior change:

- cursor-cycle source: `_attack_tiles`/`_heal_tiles` → `_targeting.target_tiles()`
- "may the cursor move?" guard: `_state == TARGETING` → `_state == TARGETING and _targeting.can_change_target()`
  (this also correctly freezes the cursor during PREVIEWING, which D1 alone could not express
  cleanly since PREVIEWING was a separate cursor state).

So D2 is a refactor plus this small input re-wire. Update the plan's "pure refactor" wording to
"refactor + input-layer re-point, no behavior change."

---

## 6. Test plan (new — `scripts/tests/test_targeting.gd`)

Now feasible because `MapCursorTargeting` needs no `SceneTree`:

- Construct `MapCursorTargeting.new()`; `setup(grid, null, combat_resolver)` where `grid` is a real
  `GridManager` with `_terrain_fallback`, `combat_resolver` is a real `CombatResolver` instance
  (its `apply_combat_result` already guards `is_inside_tree()`), `attack_preview` is `null`.
- `begin(ATTACK, unit)` with an enemy in range → `target_tiles()` non-empty; with none → empty.
- `handle_confirm(tile)` with `attack_preview == null` → resolves immediately, emits `completed`.
- `handle_cancel()` in CHOOSING → emits `cancelled`; `can_change_target()` true in CHOOSING.
- `begin(STAFF, healer)` with an injured ally in range → heal applied on confirm, `completed`.
- Regression net for the `MapCursor` side: existing `test_unit_selection.gd` (10 tests against the
  real scene) must stay green.

---

## 7. Risk & sequencing

- Highest-risk item in the plan; do it last, after A/B/C/E and D1.
- Two commits: the extraction itself, then `test_targeting.gd`. Keep them separate so the refactor
  can be verified green against `test_unit_selection.gd` before new tests are added.
- This design covers slice 1 (targeting only). `MapCursorInput` and `MapCursorSelection` remain
  future D-1 slices, not in scope here.
