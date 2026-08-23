---
Role: dated
---

# Code Review — 2026-05-27

## 1. Executive Summary

**Overall code quality rating:** 7/10

The codebase is in better shape than earlier passes: tests are broad, runtime
systems are increasingly data-driven, and the recent documentation cleanup
matches the shipped behavior well. The biggest remaining concerns are a few
live-play correctness bugs around Pair Up and hotseat control, plus some
bootstrap fallbacks in core runtime code that will break campaign/save
semantics later.

## 2. Issues Found

**[SEVERITY: High]**
- **File & Line:** `scripts/autoloads/PairUpRegistry.gd:135`, `scripts/core/MapCursor.gd:678`
- **Problem:** Pair Up state changes update `tile_position` but do not move the
  unit node's world `position`. On lead death, the dropped support becomes
  visible again without being snapped onto the lead's tile. On `Separate`, the
  support may reappear on its old tile while logically occupying the new one.
  This creates render/grid desync and can make combat/movement look broken even
  though the underlying logic thinks the unit moved correctly.
- **Root Cause:** `Unit.tile_position` is only a pass-through to `UnitData`; it
  does not update `Node2D.position`. Normal movement uses `snap_to_tile()`, but
  the Pair Up flows bypass that helper.
- **Recommended Fix:**

```gdscript
# PairUpRegistry.gd
support.snap_to_tile(drop_tile)
support.visible = true

# MapCursor.gd
support.snap_to_tile(target_tile)
support.visible = true
```

  If you want to keep the logic centralized, add a tiny helper on `Unit`, for
  example `restore_to_tile(tile: Vector2i)`, and reuse it from every Pair Up
  exit path.
- **Tradeoffs:** This adds a direct dependency on the unit movement helper, but
  that is already the codepath that keeps logical and visual state in sync.

**[SEVERITY: High]**
- **File & Line:** `scripts/core/GameMap.gd:169`, `scripts/autoloads/GameState.gd:288`
- **Problem:** An empty `player_roster` is treated as "MainMenu did not set up a
  roster yet", so `GameMap` silently loads the default roster. That hides bad
  `fixed_test_roster` authoring today, and it will break future campaign logic:
  a legitimately empty roster state, heavy permadeath run, or failed roster
  load will resurrect the default party instead of failing loud.
- **Root Cause:** Direct-boot convenience logic lives inside the real map spawn
  path, and `load_roster_from_directory()` clears the roster before validation.
  The runtime then cannot distinguish "intentional empty" from "load failed".
- **Recommended Fix:**

```gdscript
# GameState.gd
var roster_initialized: bool = false
var roster_load_failed: bool = false

func load_roster_from_directory(roster_path: String) -> bool:
    player_roster.clear()
    roster_load_failed = false
    var resource_paths: Array[String] = ResourceManifest.load_paths(roster_path)
    if resource_paths.is_empty():
        roster_load_failed = true
        return false
    ...
    roster_initialized = true
    return not player_roster.is_empty()

# GameMap.gd
if not gs.roster_initialized and OS.is_debug_build():
    gs.load_default_roster()
elif gs.player_roster.is_empty():
    push_error("GameMap: no initialized roster for selected map")
    return
```

  The main point is to separate "debug bootstrap" from "real roster contract".
- **Tradeoffs:** This makes bad content fail earlier, which may feel stricter
  during development, but it prevents much harder-to-diagnose save/content bugs.

**[SEVERITY: Medium]**
- **File & Line:** `scripts/core/MapCursor.gd:940`
- **Problem:** Closing the map menu during a hotseat-controlled green/yellow
  phase leaves the cursor locked. The same problem exists when canceling the
  "Quit to Menu" confirmation during that phase. The code assumes any
  non-`PLAYER` phase is AI-only, but hotseat local control currently runs under
  `Phase.ENEMY`.
- **Root Cause:** `GameState.is_player_turn()` is being used as a proxy for
  "human-controlled phase". That stopped being true once hotseat support was
  added for non-blue factions.
- **Recommended Fix:**

```gdscript
# TurnManager.gd
func is_locally_controlled_faction(faction_id: String) -> bool:
    if faction_id == "blue":
        var gs := get_node_or_null("/root/GameState")
        return gs != null and gs.is_player_turn()
    return _is_hotseat_controlled(faction_id)

# MapCursor.gd
var faction_id: String = _turn.active_faction()
if _turn != null and not _turn.is_locally_controlled_faction(faction_id):
    return
unlock()
```

  Reuse the same predicate for menu-close, quit-dialog-cancel, and any future
  overlay that unlocks the cursor on exit.
- **Tradeoffs:** This slightly broadens TurnManager's public surface, but it
  removes duplicated control-ownership logic from UI code.

**[SEVERITY: Medium]**
- **File & Line:** `scripts/autoloads/DataManager.gd:185`
- **Problem:** Duplicate resource ids silently overwrite earlier entries during
  startup. If two classes, weapons, items, or skills share an `id`, whichever
  file loads later wins. The runtime then behaves correctly against the wrong
  resource, which is one of the hardest content bugs to spot.
- **Root Cause:** `_load_directory()` stores everything straight into a
  dictionary keyed by `id` without checking for collisions.
- **Recommended Fix:**

```gdscript
if rid != null and rid != "":
    if target.has(rid):
        push_error("DataManager: duplicate resource id '%s' at %s" % [rid, res_path])
        continue
    target[rid] = res
else:
    push_warning("DataManager: resource at %s has no 'id' field" % res_path)
```

  I would also include the original path in the error if you keep a small
  `id -> source_path` map during loading.
- **Tradeoffs:** Duplicate ids that currently "work by accident" will start
  failing loud, but that is the safer behavior for a data-driven project.

## 3. Positive Observations

- The headless test coverage is broad and targets real gameplay seams instead of
  only tiny helper functions. That is paying off.
- The faction/alliance model in `GameState` and `TurnManager` is much cleaner
  than the earlier binary player/enemy split and should scale better.
- `ResourceManifest` plus explicit runtime loading rules is a good export-safe
  pattern. Keep that discipline.
- The recent documentation refresh clearly reduced drift between code and docs,
  which is important for a content-heavy project.

## 4. Architectural Observations

- Core runtime still mixes some development bootstrap behavior with real game
  contracts. The default-roster fallback in `GameMap` is the clearest example.
  As save/load and campaign progression grow, those shortcuts should move behind
  explicit dev-only flows.
- Validation is strong for classes/weapons/items/skills, but weaker for
  map-facing authored content. `map_registry.json`, roster policy correctness,
  and many `MapData` contracts are still validated mostly by live launch rather
  than by one central startup validator.
- Control ownership logic is split across `TurnManager`, `MapCursor`, and
  `HotseatController`. The current bug around menu unlocks is a symptom. A
  single "is this faction locally controlled right now?" API would reduce drift.
- A few features still rely on absolute scene-tree paths such as
  `/root/GameMap/TurnManager`. Those work today, but they will become fragile if
  you add wrappers, modal roots, or alternate battle shells later.

## 5. Prioritized Action Plan

1. Fix Pair Up visual/logical desync by routing all re-placement through
   `snap_to_tile()` or a dedicated helper.
2. Remove the silent default-roster fallback from the real map spawn path and
   make roster initialization explicit.
3. Centralize local-control ownership checks in `TurnManager` and use that in
   `MapCursor` unlock/overlay paths.
4. Add duplicate-id detection in `DataManager` so content collisions fail loud.
5. Add targeted tests for:
   - support release after lead death
   - `Separate` repositioning
   - map-menu close/cancel during hotseat green phase
   - invalid `fixed_test_roster` launch behavior

## Assumptions

- I assumed hotseat-controlled non-blue phases are intended to keep full map
  menu usability, including close/cancel unlock behavior.
- I assumed an empty roster should become a valid future campaign/save state and
  must not be auto-replaced with the default roster outside a deliberate dev
  bootstrap path.
