# Code Review — 2026-06-09

## 1. Executive Summary

**Overall code quality rating:** 7.5/10

The codebase has continued to firm up since the 2026-05-27 review. All four
issues called out then have been addressed: Pair Up re-placement now routes
through `snap_to_tile()`, roster bootstrap is explicit via
`is_roster_ready_for_launch()`, hotseat-aware unlock lives behind
`TurnManager.is_locally_controlled_faction()`, and `DataManager` now flags
duplicate resource ids loud. The remaining concerns are a live Pair Up
correctness bug that breaks auto-end-turn, a multi-faction camera-restore
regression that arrives with the hotseat work, and a few maintainability
nits in the new data-loading and roster-validation paths.

## 2. Issues Found

**[SEVERITY: High]**
- **File & Line:** `scripts/core/TurnManager.gd:232` (`_refresh_faction_units`),
  `scripts/autoloads/GameState.gd:218` (`get_living_units_of`),
  `scripts/core/MapCursor.gd:884` (`_cycle_to_next_unit`)
- **Problem:** A Pair Up support that persists across rounds is treated as an
  "actable" blue unit every blue phase. At pair time `MapCursor._on_pair_up_
  resolved` marks the support `DONE` and moves its `tile_position` to the
  `OFF_MAP_TILE` sentinel, but `_refresh_faction_units("blue")` then resets
  every living blue unit — including the paired support — back to `READY` at
  the start of the next blue phase. The off-map support now contributes to
  `are_all_units_done("blue")`, so auto-end-turn never triggers and the End
  Turn menu always pops the "Some units have not acted" confirmation. Tab /
  next_unit cycles through the support too, snapping the cursor to
  `(-1, -1)` for one press.
- **Root Cause:** Paired support visibility is implemented as a node-side
  state (`visible=false`, sentinel tile), but `GameState` and `TurnManager`
  treat liveness purely as `data.hp > 0`. There is no single predicate for
  "on-map and selectable" that the per-phase reset and the end-turn / cycle
  helpers both consult.
- **Recommended Fix:** Filter paired supports out of the per-faction acting
  set. The simplest hook is `get_living_units_of`, since every caller that
  cares about "who can still act" already routes through it:

```gdscript
# GameState.gd
func get_living_units_of(faction_id: String) -> Array[Node]:
    var result: Array[Node] = []
    var bucket: Array[Node] = _units_by_faction.get(faction_id, [] as Array[Node])
    var reg := get_node_or_null("/root/PairUpRegistry")
    for u in bucket:
        if not is_instance_valid(u) or u.data == null or u.data.hp <= 0:
            continue
        if reg != null and u.data.unit_id != "" \
                and reg.call("is_support", u.data.unit_id):
            continue  # paired support is off-map; not selectable this turn
        result.append(u)
    return result
```

  If a caller does need every living unit regardless of pair role (e.g. an
  alive-count for objectives), split it out as a separate
  `get_all_living_units_of()` and keep the actable variant filtered.
- **Tradeoffs:** Routing through `PairUpRegistry` adds a soft dependency to
  `GameState`, but every existing user of `get_living_units_of` already
  expects "units the player can still interact with". This makes that
  expectation explicit instead of leaking through the OFF_MAP sentinel.

**[SEVERITY: Medium]**
- **File & Line:** `scripts/core/MapCursor.gd:146` (`_on_phase_changed`),
  `scripts/core/CameraController.gd:149` (`save_view`)
- **Problem:** `save_view()` fires on every `Phase.ENEMY` transition, so a
  multi-faction enemy phase (blue → green → red → blue) overwrites the
  saved blue-camera position twice — once with the camera state the green
  hotseat player left, then again when red's phase begins. When blue resumes,
  `restore_view()` puts the camera wherever the hotseat hand-off ended, not
  where blue's player was looking when they ended their turn. PT4 #2's "give
  blue their original view back" guarantee no longer holds once a third
  faction lands.
- **Root Cause:** The save is unconditional on `Phase.ENEMY` rather than
  scoped to "leaving the locally-controlled blue phase". With only two
  factions, every save was a blue→enemy save; with three the assumption
  breaks.
- **Recommended Fix:** Save only when transitioning *from* a player-driven
  blue phase, and never re-save while a hotseat faction is mid-phase.

```gdscript
# MapCursor.gd
func _on_phase_changed(new_phase: int, _faction_id: String = "") -> void:
    if _faction_id != "":
        set_controlling_faction(_faction_id)
    if new_phase == GameState.Phase.ENEMY:
        if _camera_ctrl != null and _controlling_faction == "blue":
            _camera_ctrl.save_view()
        lock()
    else:
        ...
```

  The check reads cleanly because `_controlling_faction` is still "blue" on
  the first ENEMY transition (it is reassigned *after* the save in the new
  body — invert the order if you prefer reading "save before reassign"). An
  alternative is to make `save_view()` itself idempotent until a matching
  `restore_view()` runs.
- **Tradeoffs:** Restored view now always belongs to blue, which is the
  user-visible expectation. Hotseat factions don't currently get their own
  per-faction save; that is fine as a follow-up — record it in the hotseat
  notes if you want camera continuity across rounds for non-blue players.

**[SEVERITY: Medium]**
- **File & Line:** `scripts/autoloads/DataManager.gd:512` (`_load_directory`),
  `scripts/autoloads/DataManager.gd:501` (`register_loaded_resource`)
- **Problem:** The duplicate-id detection introduced after the prior review
  uses an error *string* as its transport, and `_load_directory` then
  decides severity with a substring search:
  `if "duplicate resource id" in err: push_error(err) else: push_warning(err)`.
  A future rewording of the error message — including legitimate cases
  like adding the source path to the duplicate message — silently demotes
  the duplicate to a warning, which lets duplicate ids ship again.
- **Root Cause:** The split between "found a problem" and "how loud should
  we be" is encoded in the message text rather than in the return type.
- **Recommended Fix:** Return a small result struct or an enum severity
  alongside the message, and let the caller switch on that.

```gdscript
# DataManager.gd
enum LoadResult { OK, MISSING_ID, DUPLICATE_ID, LOAD_FAILED }

static func register_loaded_resource(
        target: Dictionary, res: Resource, res_path: String
) -> Dictionary:
    if res == null:
        return {"result": LoadResult.LOAD_FAILED,
            "message": "DataManager: resource at %s failed to load" % res_path}
    var rid: Variant = res.get("id")
    if rid == null or rid == "":
        return {"result": LoadResult.MISSING_ID,
            "message": "DataManager: resource at %s has no 'id' field" % res_path}
    var id: String = String(rid)
    if target.has(id):
        return {"result": LoadResult.DUPLICATE_ID,
            "message": "DataManager: duplicate resource id '%s' at %s" % [id, res_path]}
    target[id] = res
    return {"result": LoadResult.OK, "message": ""}

func _load_directory(path: String, target: Dictionary) -> void:
    ...
    for res_path in resource_paths:
        var res := load(res_path)
        var r: Dictionary = register_loaded_resource(target, res, res_path)
        match r["result"]:
            LoadResult.OK: continue
            LoadResult.DUPLICATE_ID, LoadResult.LOAD_FAILED:
                push_error(r["message"])
            _:
                push_warning(r["message"])
```

  Tests that pin "duplicate id is push_error, missing id is push_warning"
  already exist; switching them to assert on the enum gives the same
  coverage without the string sniff.
- **Tradeoffs:** Small API shape change; the static helper now returns a
  Dictionary instead of a String. The test in `test_data_manager.gd` for
  this path moves with the rename in one place.

**[SEVERITY: Medium]**
- **File & Line:** `scripts/autoloads/GameState.gd:311`
  (`load_roster_from_directory`)
- **Problem:** Every `.tres` in the roster directory is loaded, validated,
  and *unconditionally* deep-copied via `loaded.duplicate(true)` before any
  type check. If a non-`UnitData` resource lands in the roster directory
  (a stray `ClassData`, a partial save), `var res: UnitData = ...` triggers a
  typed-assignment error rather than a clear "skip this file" warning. The
  current error message ("roster file '...' has empty unit_id") would still
  fire eventually, but the user sees a typed-assignment runtime error first.
- **Root Cause:** The type check is implicit in the typed local variable,
  so the friendly-error path runs only when the resource happens to *be* a
  UnitData with an empty unit_id.
- **Recommended Fix:** Type-check explicitly before the assignment, and
  push_error + continue on a mismatch:

```gdscript
# GameState.gd
var loaded := load(res_path)
if loaded == null:
    push_error("GameState: failed to load roster file '%s' — skipping" % res_path)
    had_errors = true
    continue
if not (loaded is UnitData):
    push_error("GameState: roster file '%s' is not UnitData — skipping" % res_path)
    had_errors = true
    continue
var res: UnitData = loaded.duplicate(true)
```

- **Tradeoffs:** None — strictly defensive. Matches the explicit
  `is MapData` and `is PackedScene` patterns the map-registry validator
  already uses.

**[SEVERITY: Low]**
- **File & Line:** `scripts/units/Unit.gd:844`
  (`_grant_current_level_class_skills`)
- **Problem:** This method reaches into `DataManager._classes` directly
  twice (`dm._classes.has(...)`, `dm._classes[...]`) instead of going
  through the public `get_class_data()` accessor. It works because GDScript
  doesn't enforce privacy, but it bypasses the `push_error` that
  `get_class_data` already emits on an unknown id, and a future rename or
  re-keying of the dict would silently break this path.
- **Root Cause:** Speed-up shortcut from when the dict was the only
  surface; never updated when `get_class_data` was added.
- **Recommended Fix:**

```gdscript
# Unit.gd
var class_data: ClassData = dm.get_class_data(data.class_id)
if class_data == null:
    return
```

  `_ensure_class_line_id` (line 871) has the same shape and the same fix.
- **Tradeoffs:** `get_class_data` push_errors on a miss, which is the
  correct behavior here — silently skipping was hiding bad data.

## 3. Positive Observations

- The four prior-review issues (Pair Up snap, roster init, hotseat unlock,
  duplicate id detection) are all resolved with code that matches the
  recommended approach rather than half-measures. The roster-launch state
  machine in `GameState` is especially clean — three explicit flags plus
  `is_roster_ready_for_launch()` make the previous "did MainMenu actually
  set this up?" guesswork impossible to mis-author.
- Map-content validation in `DataManager.collect_map_data_validation_errors`
  is now comprehensive: terrain chars, grid rectangularity, faction ids,
  turn-order references, enemy placements, and objective conditions all
  fail at startup with clear messages. This is exactly the "central
  startup validator" the previous review recommended.
- The `TurnManager` activation scheduler is well-factored. The
  WHOLE_PHASE / ALTERNATING split is data-driven, the round-boundary
  handling lives in one place (`end_alternating_activation` /
  `start_player_phase`), and the new `is_locally_controlled_faction`
  predicate is the right shared surface for cursor unlock decisions.
- `release_support_from_fallen_lead` reads cleanly: separate first, then
  re-place via `snap_to_tile`, then a phase-aware DONE for player-phase
  deaths. The order-comment ("log → unregister → drop bookkeeping → free
  → re-evaluate") in `record_escape` is exactly the kind of WHY comment
  that pays off when future authors touch the function.

## 4. Architectural Observations

- The OFF_MAP_TILE sentinel pattern works for grid queries but does not
  signal "off-map" to the rest of the runtime. The paired-support
  auto-end-turn bug above is the first time this leaks. As Pair Up moves
  toward production, treating "is on-map and selectable" as a real query
  (likely via `PairUpRegistry` plus a tiny `Unit.is_on_map()` helper) will
  be cleaner than the current tile-position-equality check, and it gives
  `TurnManager`, the cursor cycle, and any future selectable-unit list one
  surface to share.
- Camera and cursor state are still tied to the legacy two-faction phase
  model in a couple of places (PT4 #2 view save/restore, the binary
  PLAYER/ENEMY enum in `GameState.Phase`). Stage 5 of the M14 rebuild will
  eventually need per-faction camera context for hotseat continuity —
  worth a roadmap line, not a fix right now.
- `DataManager` mixes loading, validation, and runtime accessors in one
  ~620-line autoload. The split-into-static-helpers pattern is already
  there for validation; pulling the loading half (`_load_directory`,
  `register_loaded_resource`) into a small loader RefCounted would let the
  autoload shrink to "validators + dictionary accessors" and remove the
  weird `get_class_data` vs Object.get_class() naming dance.
- Direct `_classes` access from `Unit.gd` (low-severity issue above) is a
  symptom of the same coupling. Once the loader splits out, the dictionary
  becomes private to the loader and `get_class_data` is the only entry
  point — the temptation to peek at the dict disappears.

## 5. Prioritized Action Plan

1. Filter paired supports out of `GameState.get_living_units_of` so
   auto-end-turn, `are_all_units_done`, and Tab-cycling stop counting them.
2. Scope `save_view()` to "leaving the blue phase" in `MapCursor._on_phase
   _changed` so multi-faction hotseat preserves blue's camera view.
3. Convert `DataManager.register_loaded_resource` to return a typed result
   (enum or dict) so duplicate-vs-warning routing stops depending on a
   substring search in the message.
4. Add an explicit `is UnitData` guard in `GameState.load_roster_from_
   directory` so a stray non-UnitData `.tres` fails with a clean skip
   message instead of a typed-assignment crash.
5. Replace the direct `_classes` reads in `Unit._grant_current_level_
   class_skills` and `_ensure_class_line_id` with `get_class_data`.
6. Add targeted tests for:
   - paired support is excluded from `are_all_units_done("blue")` across
     a round boundary;
   - `_cycle_to_next_unit` does not snap the cursor onto a paired support;
   - multi-faction camera save/restore preserves blue's view after a
     hotseat green phase;
   - a non-UnitData `.tres` placed in `res://data/roster/...` is skipped
     with `push_error` rather than crashing.

## Assumptions

- I assumed paired support is *intended* to be hidden from the player's
  selection / end-turn surface during the paired window, and the
  OFF_MAP_TILE sentinel was the chosen way to express that — the bug is
  therefore "the filter never made it past tile-position queries", not "we
  want the support to be selectable while paired".
- I assumed PT4 #2 ("restore blue's camera at the start of their next
  phase") is still the intended behavior under hotseat — i.e. blue's view
  should not get clobbered by intervening green/red phases.
- I assumed the roster directory contract is "every `.tres` here is a
  `UnitData`"; if the directory is also expected to hold other resource
  types, the type-check recommendation should instead skip non-`UnitData`
  silently rather than logging.
