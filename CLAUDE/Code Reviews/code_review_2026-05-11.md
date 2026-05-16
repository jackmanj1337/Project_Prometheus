# Code Review — 2026-05-11
Covers all code and data through `62d0087` (centralize TILE_SIZE), checked against GDD specs.
Severity: **BUG** = wrong behaviour, **DESIGN** = won't crash but will cause pain later,
**GDD** = code diverges from spec (either missing feature or data mismatch).

---

## BUG-01 — Wrong screen-to-world transform in MapCursor mouse handling
**File:** `scripts/core/MapCursor.gd:103`

```gdscript
var world := _camera.get_global_transform().affine_inverse() * event.position
```

**Why it's wrong:**
`Camera2D.get_global_transform()` returns the camera node's position in world space.
Its inverse maps *world → camera-local*, not *screen → world*.
`event.position` is in viewport (screen) pixels.
Multiplying screen pixels by that inverse gives a garbage world position.
The correct Godot 4 API is `get_viewport().canvas_transform.affine_inverse() * event.position`.

**Consequence:** Mouse-driven tile selection gives the wrong tile whenever the camera has
scrolled away from (0,0). The bug is invisible on first load because the camera starts
near the origin, but breaks as soon as the player scrolls the map.

**Fix:** Replace with `get_viewport().canvas_transform.affine_inverse() * event.position`.

---

## BUG-02 — `get_unit_at()` called twice on the same tile in the same condition
**File:** `scripts/core/MapCursor.gd:187`

```gdscript
if _grid.get_unit_at(current_tile) != null and _grid.get_unit_at(current_tile) != _selected_unit:
```

**Why it's wrong:**
`get_unit_at()` is a linear scan of `GameState.all_units`.
Calling it twice performs the scan twice for no benefit.
More seriously, if a unit somehow changes between calls (signal or deferred callback),
the two calls could return different objects, producing a wrong result.

**Fix:** Store in a local variable:
```gdscript
var occupant := _grid.get_unit_at(current_tile)
if occupant != null and occupant != _selected_unit:
```

---

## BUG-03 — Tests hardcode tile size `64` instead of using `GameConstants.TILE_SIZE`
**Files:** `scripts/tests/test_unit_stats.gd:151`, `scripts/tests/test_grid_manager.gd:32,38`

```gdscript
# test_unit_stats.gd
unit.position == Vector2(5*64, 7*64)

# test_grid_manager.gd
if grid.world_to_tile(Vector2(64, 128)) == Vector2i(1, 2):
if grid.tile_to_world(Vector2i(3, 4)) == Vector2(192, 256):
```

**Why it's wrong:**
We just moved `TILE_SIZE` to `GameConstants` specifically so it can be changed in one place.
These tests undermine that: if someone edits `GameConstants.TILE_SIZE`, the game still works
but these tests suddenly fail, giving a false signal.

**Fix:** Import `GameConstants` via `preload` (same pattern as the tool scripts) and replace
the literal `64` / derived values with `GameConstants.TILE_SIZE`-based expressions.

---

## BUG-04 — `Unit._original_tile` is a class field that should be a local variable
**File:** `scripts/units/Unit.gd:15, 326, 331, 341`

```gdscript
var _original_tile: Vector2i = Vector2i.ZERO  # class field

func move_along_path(path: Array[Vector2i]) -> void:
    _original_tile = tile_position          # written here
    ...
    _emit_moved(_original_tile, path[-1])   # read only in this same function
```

**Why it's wrong:**
`_original_tile` is set at the top of `move_along_path` and only consumed inside that
same function via `_emit_moved`. It does not persist between calls in any useful way.
Meanwhile `TurnManager._original_tiles` is the *actual* undo record. The class field
implies Unit owns the undo logic, which it doesn't — it owns nothing after the function
returns. The field is confusing dead state.

**Fix:** Promote `_original_tile` to a local variable inside `move_along_path` and delete
the class field.

---

## BUG-05 — Dead code branch in `Unit.initialize()`
**File:** `scripts/units/Unit.gd:29`

```gdscript
func initialize(unit_data: UnitData, start_tile: Vector2i, unit_team: String) -> void:
    data = unit_data
    tile_position = start_tile
    team = unit_team
    if is_inside_tree():          # this branch NEVER fires in normal use
        _apply_initial_state()
```

**Why it's wrong:**
`GameMap._spawn_unit()` always calls `initialize()` before `add_child()`.
The unit is therefore never inside the tree when `initialize()` runs.
`is_inside_tree()` is always `false` here; `_apply_initial_state()` is never called from
this branch.
`_ready()` then calls it correctly once the node enters the tree.
The guard looks like a safety net but silently does nothing. If someone changes the call
order (calls `add_child` first, then `initialize`), `_ready()` will fire without data set,
crash, and the `initialize` guard will then also fire — applying state twice.

**Fix:** Remove the `if is_inside_tree()` block from `initialize()`. The contract is clear:
call `initialize()` before `add_child()`. Document it with a comment if needed, but don't
add dead guards that imply the opposite contract is also safe.

---

## BUG-06 — `"unit_moved"` state is set and immediately overwritten; undo-after-move cannot work
**File:** `scripts/core/MapCursor.gd:194-200`

```gdscript
_state = "locked"
await _selected_unit.move_along_path(path)
_state = "unit_moved"           # set here…
if _turn != null:
    _turn.set_unit_state(_selected_unit, TurnManager.UnitState.DONE)
_finish_action()                # …immediately cleared to "free" here
```

**Why it's wrong:**
`_finish_action()` sets `_state = "free"`. So `"unit_moved"` is set and overwritten in
the same call frame. `_on_cancel()` has no handler for `"unit_moved"`, and the comment
on line 141 says cancel-from-moved "not yet wired — needs M4".
The undo data (`TurnManager._original_tiles`) is recorded correctly, but the state machine
transition from `unit_moved → cancel → undo` is structurally impossible as written because
the cursor never stays in `"unit_moved"`.

**Consequence:** M4's ActionMenu (Attack/Staff/Item/Wait) will need to be inserted *between*
the `await` and `_finish_action()`. Until then, players cannot undo a move.

**Fix:** Do not call `_finish_action()` immediately after movement. Let the cursor rest in
`"unit_moved"` and add the cancel handler. `_finish_action()` should only be called once
the player commits an action (Wait, Attack, etc.) from the ActionMenu.

---

## DESIGN-01 — Audio bus volume assigned by index, not by name
**File:** `scripts/autoloads/SettingsManager.gd:104-107`

```gdscript
if bus_count > 0: AudioServer.set_bus_volume_db(0, ...)  # assumed Master
if bus_count > 1: AudioServer.set_bus_volume_db(1, ...)  # assumed Music
if bus_count > 2: AudioServer.set_bus_volume_db(2, ...)  # assumed SFX
```

**Why it's a problem:**
The Godot editor lets you drag-reorder audio buses at any time. Index 1 being "Music" is
an assumption that breaks silently the moment someone adds a bus before Music or reorders.
There is no error — the wrong bus just gets the wrong volume.

**Fix:** Use `AudioServer.get_bus_index("Master")` etc. and skip the call if the result is
`-1` (bus doesn't exist yet). This is both correct and self-documenting.

---

## DESIGN-02 — `Unit._get_class_data()` and `Unit._load_weapon()` bypass DataManager
**File:** `scripts/units/Unit.gd:66-78, 111-119`

```gdscript
# Fallback: load directly. Slower per-call but tests don't need DataManager.
var path := "res://data/classes/%s.tres" % data.class_id
if ResourceLoader.exists(path):
    return load(path)
```

**Why it's a problem:**
`DataManager` loads all resources once at startup and holds them in memory.
The fallback bypasses that cache and `load()`s a fresh instance every call.
In test mode this means stat changes made to a DataManager-cached resource are invisible
to Unit's fallback — the two instances can diverge. As more systems share data, this
creates subtle "works in game, fails in tests" bugs.
It also silently generates a new resource instance each call — if anything mutates the
returned ClassData, the mutation is lost.

**Fix:** Remove the direct-load fallback. In test scripts that need class data, pass the
resource in directly (inject via `unit.data.class_id` pointing to an already-loaded tres).
For headless tests that really can't use DataManager, create a minimal test-only setup
function rather than a hidden fallback inside production code.

---

## DESIGN-03 — `GameMap.MAP_001` string grid is hardcoded in the class
**File:** `scripts/core/GameMap.gd:22-49`

```gdscript
const MAP_001: Array[String] = [
    "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
    ...
]
```

**Why it's a problem:**
Every additional map either needs another const block inside `GameMap.gd` (class grows
unboundedly) or a subclass per map (combinatorial scene proliferation).
`MapData` already has `tilemap_scene_path` and an `id`. Maps should be self-contained
data, not code. The string grid should live alongside the MapData resource — either as
a field on MapData (`var grid: Array[String]`) or as a companion `.txt`/`.json` file
loaded at runtime.

**Fix:** Add a `grid: Array[String]` exported field to `MapData.gd`. Move the MAP_001
const into the `map_001_data.tres` (or a companion file). `GameMap._paint_terrain()`
reads `map_data.grid` instead of the hardcoded const. This is the only change needed
to support multiple maps without code changes.

---

## DESIGN-04 — No maximum level cap in `Unit.add_exp()` / `level_up()`
**File:** `scripts/units/Unit.gd:384-416`

```gdscript
func add_exp(amount: int) -> void:
    data.exp += amount
    while data.exp >= 100:
        data.exp -= 100
        level_up()  # no cap check
```

**Why it's a problem:**
In GBA Fire Emblem, unpromoted units cap at level 20. There is no cap here.
A soldier can reach level 21, 22, etc. with no check and no promotion trigger.
Promotion (Phase 2) will have no natural entry point without it.
At extreme levels, stats could overflow int range (unlikely in practice but real).

**Fix:** Add a `MAX_LEVEL` constant (probably on `ClassData` or `GameConstants`) and
stop `level_up()` when `data.level >= MAX_LEVEL`. The overflow EXP should be discarded
or held. When Phase 2 promotion lands, the check becomes "if at max_level and not
promoted, trigger promotion prompt" instead.

---

## DESIGN-05 — `GameState.register_unit()` has no duplicate guard
**File:** `scripts/autoloads/GameState.gd:35-41`

```gdscript
func register_unit(unit: Node) -> void:
    all_units.append(unit)
    if unit.team == "player":
        player_units.append(unit)
    else:
        enemy_units.append(unit)
```

**Why it's a problem:**
No check for whether the unit is already registered. If called twice (e.g., during a
retry, or from a future system that also calls it), the unit appears twice in every list.
`GridManager.get_unit_at()` would return it twice. `TurnManager.are_all_player_units_done()`
would check it twice. Victory checks could trigger or suppress incorrectly.

**Fix:** Add a guard: `if unit in all_units: return` (or `push_error` to make the
double-register visible during development). `Array.has()` is O(n) but the unit count
is tiny.

---

## DESIGN-06 — `UnitData.str` field name shadows the GDScript built-in `str()`
**File:** `scripts/resources/UnitData.gd:14`

```gdscript
@export var str: int = 0
```

**Why it's a problem:**
`str` is a GDScript built-in function (`str(x)` converts to String). Defining a property
named `str` on a class shadows the built-in within that class's methods.
This works by accident — `data.str` (property access) resolves before the global `str()`
function — but any future code that writes `str(some_value)` inside `UnitData.gd` methods
will get a type error or wrong result. It also makes code harder to read:
`data.str - weapon.def` looks like a string operation.

**Fix:** Rename the field. GBA FE community convention is `strength` or `pow` (power)
for the stat and `str` for the short display label only. Using `strength: int` or
`pow: int` is unambiguous. Requires a rename across all .tres files and code references,
but better done now before more code is written against it.

---

---

## GDD-01 — Fort/Throne per-turn healing not implemented
**GDD Source:** `GDD_02_Core_Mechanics.md` — Terrain table: "Fort / Throne: Unit heals 10% max HP per turn"

**Code:** `scripts/core/TurnManager.gd:start_player_phase()` — no healing logic present.

**Why it matters:**
Fort tiles give +2 DEF and +30 Dodge (implemented in GridManager), but the healing is
the main tactical reason to garrison a fort. E7 and E8 (sub-boss, boss) are both on Forts
and the GDD explicitly notes they "heal each turn". Without this, those enemies are
significantly easier than designed — the boss encounter loses its intended pressure.

**Fix:** In `TurnManager.start_player_phase()`, iterate all units, check if their tile's
terrain is `"fort"`, and call `unit.heal(ceil(unit.data.max_hp * 0.10))` if HP < max_hp.

---

## GDD-02 — `Unit.level_up()` ignores `leveling_method` setting; always uses growth rates
**GDD Source:** `GDD_02_Core_Mechanics.md` — "Leveling Methods (GM/Session Settings): Point Buy, Coin Flip, Dice Roll, Growth Rates"

**Code:** `scripts/units/Unit.gd:398-416` — only growth-rate logic; never checks
`GameState.leveling_method` or `SettingsManager.leveling_method`.

**Why it matters:**
Both `SettingsManager` and `GameState` expose a `leveling_method` field and the GDD makes
it a first-class campaign setting. Currently changing it does nothing — the setting is
silently ignored. Players who choose "Coin Flip" or "Point Buy" will still get growth-rate
results, which is undefined and confusing behavior.

**Fix:** Either implement all four methods now, or add a `push_warning` if a non-growth-rate
method is selected so it's obviously unimplemented. Leaving it silently wrong is the worst
option.

---

## GDD-03 — `MapData.tilemap_scene_path` points to a file that doesn't exist and is never read
**GDD Source:** `GDD_06_Maps_Objectives.md` — "Maps are self-contained — adding a new map never requires code changes"

**Data:** `data/maps/map_001_rout/map_001_data.tres` has `tilemap_scene_path = "res://data/maps/map_001_rout/map_001.tscn"` — that file does not exist.

**Code:** No file in `scripts/` reads `MapData.tilemap_scene_path`. GameMap.gd hardcodes the map grid instead (see DESIGN-03).

**Why it matters:**
The field implies maps are loaded from scene files (one scene per map). The GDD promises
maps are data-only. Currently neither is true: maps are hardcoded in `GameMap.gd`. The
ghost path is misleading and will cause confusion when someone tries to add a second map.

**Fix:** Align implementation with either the GDD's data-driven model (store grid in
MapData, kill the field) or document explicitly that the field is deferred to Phase 2.

---

## GDD-04 — `MapData.is_boss` field exists but is never used in code
**GDD Source:** `GDD_06_Maps_Objectives.md` — E7 described as "Sub-boss on Fort", E8 as "Boss on Fort"

**Data:** `e7_knight_sub.tres` has `is_boss = false`; `e8_knight_boss.tres` has `is_boss = true`.
No code reads `is_boss` from enemy placements. E7 is described as a sub-boss in the GDD
but its data says `false`.

**Why it matters:**
`is_boss` presumably drives different behavior (no flee, boss music, different AI profile,
victory condition). With no code reading it and an inconsistent data value for E7, the
field currently does nothing. When boss behavior IS implemented, E7 will be treated as a
regular enemy unless the data is corrected.

**Fix:** Either implement boss behavior now (at minimum: bosses don't flee, are a required
kill for objective), or add a TODO comment in TurnManager and correct E7's `is_boss` to
`true` in the .tres file.

---

## GDD-05 — `WeaponData.effect_tags` uses undocumented magic strings with no authoritative list
**GDD Source:** `GDD_04_Weapons_Items.md` — various "Effective vs X" weapon tags

**Data examples:**
- `iron_bow.tres`: `effect_tags = ["effective_flying"]`
- `heal_staff.tres`: `effect_tags = ["heal_10_plus_mag"]`

**Code:** No constants, enum, or docstring defines valid tag values anywhere. CombatResolver
(Milestone 4) must match these exact strings to implement their effects.

**Why it matters:**
Magic strings that must match across data and code are a primary source of silent bugs.
A typo in either location ("effective_flyer" vs "effective_flying") silently disables the
effect with no error. There are also no tests for tag parsing.

**Fix:** Add a constants class or inner class (e.g., in `GameConstants.gd`) that defines
the valid tags as `const TAG_EFFECTIVE_FLYING = "effective_flying"` etc. Both .tres files
and CombatResolver reference the constant, not the string literal.

---

## Summary Table

| # | File | Severity | One-liner |
|---|------|----------|-----------|
| BUG-01 | MapCursor.gd:103 | **BUG** | Wrong camera transform — mouse tile detection broken after scroll |
| BUG-02 | MapCursor.gd:187 | **BUG** | `get_unit_at()` called twice; store in local variable |
| BUG-03 | test_*.gd | **BUG** | Tests hardcode `64`; break if `GameConstants.TILE_SIZE` changes |
| BUG-04 | Unit.gd:15,326 | **BUG** | `_original_tile` is class field but should be local; misleading dead state |
| BUG-05 | Unit.gd:29 | **BUG** | `is_inside_tree()` guard in `initialize()` is unreachable dead code |
| BUG-06 | MapCursor.gd:196-200 | **BUG** | `"unit_moved"` state cleared immediately; undo-after-move structurally impossible |
| DESIGN-01 | SettingsManager.gd:105 | DESIGN | Audio bus index instead of name; silent breakage if buses reordered |
| DESIGN-02 | Unit.gd:66-119 | DESIGN | Direct `load()` fallback bypasses DataManager; two data instances can diverge |
| DESIGN-03 | GameMap.gd:22 | DESIGN | Map grid hardcoded in class; every new map needs code changes |
| DESIGN-04 | Unit.gd:384 | DESIGN | No max-level cap; stats grow unbounded, promotion has no trigger |
| DESIGN-05 | GameState.gd:35 | DESIGN | No duplicate guard on `register_unit()`; double-registration corrupts lists |
| DESIGN-06 | UnitData.gd:14 | DESIGN | `str` field shadows GDScript built-in; rename to `strength` or `pow` |
| GDD-01 | TurnManager.gd | GDD | Fort healing (GDD_02: 10% HP/turn) not implemented — boss encounter is too easy |
| GDD-02 | Unit.gd:398 | GDD | `leveling_method` setting silently ignored; always growth-rate regardless |
| GDD-03 | MapData.tres | GDD | `tilemap_scene_path` points to nonexistent file; field never read by any code |
| GDD-04 | e7_knight_sub.tres | GDD | `is_boss=false` contradicts GDD "sub-boss" description; field unused in code |
| GDD-05 | WeaponData.gd | GDD | `effect_tags` magic strings have no constant definitions; typos will silently disable effects |
