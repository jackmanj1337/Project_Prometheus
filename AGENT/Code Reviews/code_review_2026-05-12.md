---
Role: dated
---

# Code Review — 2026-05-12
Reviewer: Claude (full codebase pass)
Scope: All scripts under `scripts/` and `resources/`

Issues are sorted **Critical → High → Medium → Low**.

---

## Implementation Decisions (agreed 2026-05-12)

| Issue | Decision |
|-------|----------|
| C1 | `unregister_unit(self)` called in `Unit.handle_death()` before `queue_free()`; add `is_instance_valid(u)` guards in `get_living_player_units()` and `get_living_enemy_units()` |
| C2 | Remove `get_tree().reload_current_scene()` from `GameState.restore_map_snapshot()`; caller (`GameOverScreen._on_retry()`) owns the scene change |
| C5 | Call `.duplicate(true)` in `GameState.load_default_roster()` when appending each resource |
| H3 | Add `"current_sim_hp": d_hp` to the miracle context dict in `CombatResolver.resolve_combat()`; read it in `SkillHandler._apply_miracle()` instead of `unit.data.hp` |
| H5 | Move weapon triangle table to `GameConstants`; both `DataManager` and `CombatResolver` read from there |
| H6 | Add `camera_start_tile: Vector2i = Vector2i(-1, -1)` to `MapData`; `GameMap._ready()` uses it when set, falls back to centroid of `player_start_tiles` when not |
| M1 | Delete `_combat_lock` from `TurnManager`; set `_state = "locked"` at the top of `MapCursor._do_resolve_attack()` and restore after |
| M4 | Replace hardcoded `1280.0` in `PhaseBanner` with `get_viewport().get_visible_rect().size.x + _panel.size.x` computed inside `_animate()` |
| M6 | Add turn limit check inside `TurnManager.check_victory_conditions()`; ensure it is called at end of each player and enemy phase, after each death (already wired), and on seize/escape actions |
| NEW | Add `unit_id: String = ""` to `UnitData`; rename `MapData.required_survivor_names` to `required_survivor_ids` and match on `unit_id` instead of `unit_name` in `check_victory_conditions()` |

---
Each entry lists: the bug, why it matters, what happens if left, and the fix.

---

## CRITICAL — Will crash or produce completely wrong behavior

---

### C1. Dead units are never unregistered from GameState
**File:** `scripts/units/Unit.gd:347-357` | `scripts/autoloads/GameState.gd:58-71`

`Unit.handle_death()` calls `queue_free()` but never calls `GameState.unregister_unit(self)`. The dead unit's reference stays in `all_units`, `player_units`, and `enemy_units`.

**Why it's a problem:** Any code that iterates those arrays and accesses `u.data` (e.g. `get_living_player_units()` on line 62 of GameState.gd) will crash with `"Invalid access to property or key 'data' on a freed object"` the frame after death, because `queue_free()` destroys the node at end of frame.

**If left:** The game crashes the first time any unit dies and then something queries the living unit lists — practically on every combat kill. `TurnManager.check_victory_conditions()` fires on every death via signal, so this happens immediately.

**Fix:** Add `GameState.unregister_unit(self)` to `Unit.handle_death()` before `queue_free()`. Also add `is_instance_valid(u)` guards to `get_living_player_units()` and `get_living_enemy_units()` as a secondary defense.

---

### C2. Retry flow calls `reload_current_scene()` twice
**File:** `scripts/ui/GameOverScreen.gd:42-46` | `scripts/autoloads/GameState.gd:124-129`

`GameState.restore_map_snapshot()` already calls `get_tree().reload_current_scene()` on its last line (line 129). `GameOverScreen._on_retry()` then calls `get_tree().reload_current_scene()` again after returning.

**Why it's a problem:** Two deferred scene reloads are queued in the same frame. Godot 4 may silently discard one, but the reload order is undefined. Depending on engine internals, this can cause a double-free of scene nodes or leave the game in a half-reloaded state.

**If left:** Retry is unreliable. It may work by accident or may produce subtle corruption or crashes that are extremely hard to reproduce.

**Fix:** Remove `get_tree().reload_current_scene()` from `GameState.restore_map_snapshot()`. The caller (`GameOverScreen._on_retry()`) already does it. `restore_map_snapshot()` should only restore data; scene management belongs to the caller.

---

### C3. HUD and AttackPreview read properties that don't exist on Unit
**Files:** `scripts/ui/HUD.gd:64-70` | `scripts/ui/AttackPreview.gd:27-28,33-34`

Both scripts access `unit.unit_name`, `unit.unit_class`, `unit.current_hp`, and `unit.max_hp()` directly on the `Unit` node. None of these exist on `Unit`. The correct paths are:
- `unit.data.unit_name`
- `unit.data.class_id`
- `unit.data.hp`
- `unit.data.max_hp`

**Why it's a problem:** GDScript's `"property" in node` returns `false` for all four. Every conditional falls to the else branch, so the HUD always displays `"???"` for name, `""` for class, and `0/0` for HP. The AttackPreview panel always shows `"???"` and `HP 0` for both combatants.

**If left:** The persistent HUD and attack preview are completely non-functional. A player has no way to read unit information.

**Fix:** Update all property accesses to go through `unit.data`. E.g.:
```gdscript
_unit_name.text = unit.data.unit_name if unit.data else "???"
_unit_hp.text   = "HP %d / %d" % [unit.data.hp, unit.data.max_hp]
```

---

### C4. `wpn.weapon_name` accessed in HUD — field is named `display_name`
**File:** `scripts/ui/HUD.gd:70`

```gdscript
_unit_weapon.text = wpn.weapon_name if wpn != null else "--"
```

`WeaponData` exports `display_name`, not `weapon_name`. In Godot 4, accessing a non-existent property on a typed resource via dot notation raises an error.

**Why it's a problem:** The equipped weapon label will either crash, show nothing, or display `"<null>"` depending on Godot's error mode.

**If left:** Weapon name is never shown in the HUD. Crash possible in strict mode.

**Fix:** Change to `wpn.display_name`.

---

### C5. Player roster resources are not duplicated — stat changes corrupt the cache
**File:** `scripts/autoloads/GameState.gd:107-110`

```gdscript
var res: UnitData = load(roster_path + f)
if res:
    player_roster.append(res)
```

Enemy units are correctly loaded with `load(path).duplicate(true)`. Player roster units are not. In Godot 4, `load()` returns a reference to the global resource cache. Modifying `player_roster[i].hp` during gameplay modifies the cached `.tres` in memory.

**Why it's a problem:** On Retry, `restore_map_snapshot()` copies snapshot values back into `player_roster[i]`, but the snapshot itself was taken from the same modified resource. If the game is quit and relaunched (within the same process), the `.tres` cache holds dirty data. Unit stats are never a clean starting state.

**If left:** Level-up stat gains, HP loss, and EXP changes slowly corrupt the canonical `.tres` files in memory. Retry may not correctly restore units. Impossible to do a clean New Game without restarting the process.

**Fix:**
```gdscript
var res: UnitData = load(roster_path + f).duplicate(true)
```

---

## HIGH — Broken features or data integrity failures

---

### H1. `_execute_staff_heal()` bypasses `Unit.heal()` — HP bar never updates
**File:** `scripts/core/MapCursor.gd:421-422`

```gdscript
target.data.hp = mini(target.data.hp + heal_amount, target.data.max_hp)
```

`Unit.heal()` exists and does: clamp HP, update the HP bar `ProgressBar`, and emit `unit_healed` signal.

**Why it's a problem:** The HP bar on the healed unit never visually updates. `unit_healed` is never emitted, so `CombatHUD` never spawns the green `+N` floating number. The heal is invisible to the player.

**If left:** Staff healing appears to do nothing. Players cannot tell if healing worked.

**Fix:** Replace with `target.heal(heal_amount)`. Remove the manual HP calculation.

---

### H2. `_apply_item_effect()` also bypasses `Unit.heal()` — same HP bar issue
**File:** `scripts/core/MapCursor.gd:469-472`

```gdscript
"heal_flat":
    _selected_unit.data.hp = mini(_selected_unit.data.hp + power, _selected_unit.data.max_hp)
"heal_full":
    _selected_unit.data.hp = _selected_unit.data.max_hp
```

Same problem as H1. HP bar not updated, signal not emitted.

**Fix:** Replace with `_selected_unit.heal(power)` for `heal_flat` and `_selected_unit.heal(_selected_unit.data.max_hp)` for `heal_full`.

---

### H3. Miracle skill checks real HP instead of simulated HP — fails in multi-hit combats
**File:** `scripts/skills/SkillHandler.gd:107-108` | `scripts/core/CombatResolver.gd:282-289`

In `resolve_combat()`, Miracle is triggered when `dmg >= d_hp` (simulated remaining HP after earlier hits). Inside `_apply_miracle()`, the check is:
```gdscript
if dmg < unit.data.hp:   # unit.data.hp = REAL, unmodified HP
    return context
```

`resolve_combat()` is a pure simulation — `unit.data.hp` is unchanged during it. In a two-hit combat where the defender took 6 of 10 HP in the first exchange, `d_hp = 4`, and a second hit of 5 would trigger the outer miracle check (`5 >= 4`). But inside `_apply_miracle`, `5 < unit.data.hp (10)` → returns early. Miracle is suppressed.

**Why it's a problem:** Miracle activates in single-hit scenarios but fails silently in any double-hit or follow-up scenario where prior hits reduced simulated HP. Skill is effectively broken in most real combats.

**If left:** Miracle is unreliable. Players can observe that a unit "should have" triggered Miracle but didn't.

**Fix:** Pass the simulated current HP into the miracle context and check against that instead of `unit.data.hp`.

---

### H4. Brave weapon `strikes_per_attack` field is never read — Brave weapons broken
**File:** `scripts/resources/WeaponData.gd:29` | `scripts/core/CombatResolver.gd:246-262`

`WeaponData` declares `strikes_per_attack: int = 1` with a comment: "Set to 2 for all Brave weapons — attacker fires this many times before defender counters." `CombatResolver.resolve_combat()` builds the `seq_atk`/`seq_def` arrays without reading this field.

**Why it's a problem:** Any Brave weapon in the `.tres` data fires exactly once, the same as a normal weapon. The data field is silently ignored.

**If left:** Brave weapons are completely non-functional. The mechanical distinction can't be tested.

**Fix:** In the sequence-building section of `resolve_combat()`, check `attacker.get_equipped_weapon().strikes_per_attack` and insert extra attacker strikes before the defender's counter.

---

### H5. Weapon triangle is duplicated across two files — will silently diverge
**Files:** `scripts/autoloads/DataManager.gd:12-21` | `scripts/core/CombatResolver.gd:20-29`

Both files define the full weapon triangle as a `const Dictionary`. The CombatResolver comment reads: "Must stay in sync with DataManager._weapon_triangle." There is no enforcement.

**Why it's a problem:** When adding new weapon types (e.g., "knife"), a developer must update both files. Missing one means triangle results differ between `DataManager.get_weapon_triangle_result()` and `CombatResolver._get_triangle_result()`, but no error is raised.

**If left:** Stealth bugs where the AI's triangle math differs from the player's preview math. Extremely hard to diagnose.

**Fix:** Remove the duplicate from `CombatResolver`. Have it call `DataManager.get_weapon_triangle_result()` or share the constant via `GameConstants`.

---

### H6. Camera start position is hardcoded to map_001's tile (1,9)
**File:** `scripts/core/GameMap.gd:53`

```gdscript
# Center on the player start area (Unit_01 at tile 1,9)
_camera.position = _grid.tile_to_world(Vector2i(1, 9))
```

**Why it's a problem:** The next planned session adds a second map. The camera will always start at tile (1,9) regardless of where that map's player start tiles are.

**If left:** Every map other than map_001 starts with the camera in the wrong corner. The player may not be able to see their units on load.

**Fix:** Use `map_data.player_start_tiles[0]` if available, or add a `camera_start_tile: Vector2i` field to `MapData`.

---

## MEDIUM — Architectural hazards, silent failures, wrong behavior under edge cases

---

### M1. `_combat_lock` declared but never read or written — dead field
**File:** `scripts/core/TurnManager.gd:14`

```gdscript
var _combat_lock: bool = false
```

This field is never assigned or checked anywhere in the file or in callers.

**Why it's a problem:** If it was intended to block input during combat animations, it does nothing. The false sense that input is locked during combat may mask a missing lock.

**If left:** No immediate crash, but if combat animations are playing and the player can still move the cursor, state corruption is possible.

**Fix:** Either wire it up (set to `true` before `apply_combat_result`, reset after) or delete it.

---

### M2. `get_living_player_units()` and `get_living_enemy_units()` don't guard against freed nodes
**File:** `scripts/autoloads/GameState.gd:58-71`

Even if C1 is fixed by calling `unregister_unit()` on death, these iteration loops should still use `is_instance_valid(u)` as a defensive measure.

**Why it's a problem:** Any ordering issue or edge case where `unregister_unit()` is called late leaves a window where iterating these lists crashes.

**Fix:**
```gdscript
for u in player_units:
    if is_instance_valid(u) and u.data.hp > 0:
        result.append(u)
```

---

### M3. `MapCursor._set_tile()` dereferences `_grid` after a null check that doesn't cover it
**File:** `scripts/core/MapCursor.gd:185-193`

```gdscript
if _grid != null:
    tile.x = clamp(...)   # guarded
if tile == current_tile:
    return
current_tile = tile
position = _grid.tile_to_world(current_tile)  # ← NOT guarded; crashes if _grid == null
```

**Why it's a problem:** If `_grid` is null (e.g., `setup()` was not called before input fires), the clamp is skipped, and the `tile_to_world` call crashes.

**Fix:** Move the `tile_to_world` call inside the `_grid != null` block, or guard it with a null check.

---

### M4. `PhaseBanner` uses hardcoded pixel offsets that assume 1280px screen width
**File:** `scripts/ui/PhaseBanner.gd:11-13`

```gdscript
const OFFSCREEN_RIGHT: float = 1280.0
const OFFSCREEN_LEFT: float = -1280.0
```

**Why it's a problem:** On a 1920px monitor (or 1024px window), the banner won't start or end fully off-screen.

**If left:** The slide animation is cosmetically broken at non-standard resolutions. The panel pops in from a visible position or exits while still partially on-screen.

**Fix:** Use `get_viewport().get_visible_rect().size.x + _panel.size.x` as the offscreen offset, computed in `_animate()`.

---

### M5. `Unit.get_effective_stat()` silently returns 0 for invalid stat names
**File:** `scripts/units/Unit.gd:159`

```gdscript
var base = data.get(stat_name)
var total: int = int(base) if base != null else 0
```

`Object.get()` returns `null` for unknown properties with no warning. A typo in a skill's `effect_params` key (e.g., `"strenght"`) silently gives 0.

**Why it's a problem:** Skill bugs caused by bad stat strings are invisible and very hard to track down.

**Fix:** Add a validation check: `if base == null: push_error("get_effective_stat: unknown stat '%s'" % stat_name)`.

---

### M6. `MapData.turn_limit` is declared but never checked
**File:** `scripts/resources/MapData.gd:10` | `scripts/core/TurnManager.gd:150-174`

`MapData` has `turn_limit: int = 0` (0 = no limit). `TurnManager.check_victory_conditions()` never reads it.

**Why it's a problem:** Maps with a turn limit cannot be designed. The data field is inert.

**If left:** Survive/defend objectives that require a time limit cannot be implemented without code changes.

**Fix:** In `end_player_phase()` or `check_victory_conditions()`, check if `_map_data.turn_limit > 0 and gs.turn_number > _map_data.turn_limit` and emit `map_defeat`.

---

### M7. `MapData.reward_gold` and `reward_items` are declared but never read
**File:** `scripts/resources/MapData.gd:17-19`

These are exported fields that the victory flow ignores entirely. No gold or items are ever granted on map completion.

**Why it's a problem:** Loot and shop economy cannot be playtested. Data authored in `.tres` files is silently thrown away.

**Fix:** Read these fields in `TurnManager._on_unit_died` (or a dedicated on-victory handler) and apply them to `GameState`.

---

### M8. `ActionMenu._move_focus()` has an infinite loop if all buttons are disabled
**File:** `scripts/ui/ActionMenu.gd:82-92`

The `while true` loop breaks when it finds an enabled button or returns to `start`. The comment says "Wait is always enabled" but Wait is never explicitly forced enabled in code. If someone disables all four buttons, this locks the game.

**Fix:** Add a hard counter: `var steps := 0; while steps < _buttons.size(): steps += 1; ...` and break unconditionally after a full cycle.

---

### M9. Enemy AI has no healing branch — healer enemies stand idle
**File:** `scripts/core/EnemyAI.gd:42-52`

`_act()` calls `get_attackable_enemies_from_tile()` and attacks the nearest target. For cleric-type enemies whose only weapon is a staff, this list is empty (staves can't attack). The unit moves toward players but never acts.

**Why it's a problem:** Healer enemies are useless and potentially confusing to the player. More critically, if a boss unit has a staff, it won't function.

**Fix:** After the attack-range check fails, add a staff/heal branch that mirrors the player's `_execute_staff_heal()` path.

---

### M10. `DataManager._load_directory()` silently skips subdirectories
**File:** `scripts/autoloads/DataManager.gd:36-48`

`DirAccess.get_next()` returns both files and directories. There is no call to `current_is_dir()`. The `.tres` suffix check filters out most directories, but subdirectories in a data folder are silently ignored with no warning.

**Why it's a problem:** If a future data reorganization puts `.tres` files in subdirectories, they will silently fail to load. The error only surfaces at runtime when a resource is looked up and missing.

**Fix:** Add a `if dir.current_is_dir(): continue` check, or a `push_warning` when a subdirectory is encountered.

---

## LOW — Style issues, stale code, minor missing validations

---

### L1. `Boot.gd` has a stale comment
**File:** `scripts/core/Boot.gd:7`

```gdscript
# MainMenu not yet implemented; change this path once Milestone 5 scene exists
```

Milestone 5 is complete. The comment is wrong.

---

### L2. `ItemMenu` lambda comment claims a value copy but makes a reference copy
**File:** `scripts/ui/ItemMenu.gd:37-39`

```gdscript
# Capture entry by value so the lambda closes over a copy
var captured: Dictionary = entry
```

In GDScript 4, Dictionary assignment is by reference, not by value. `captured` IS `entry`. The behavior works correctly (modifying `captured` modifies the inventory dictionary), but the comment is actively misleading. Future readers may rely on it being a copy and introduce a bug.

**Fix:** Remove or correct the comment: `var captured: Dictionary = entry  # reference to the inventory dict`.

---

### L3. `_handle_zoom()` and `_apply_zoom()` are dead code in MapCursor
**File:** `scripts/core/MapCursor.gd:582-589`

These Phase-2 stub functions are defined but have no callers. They add noise to the file.

**Fix:** Either wire them to input or remove them and add a TODO comment in the GDD.

---

### L4. `SettingsManager.save()` ignores disk write errors
**File:** `scripts/autoloads/SettingsManager.gd:76`

```gdscript
cfg.save(SETTINGS_PATH)
```

The return value (`Error`) is discarded. If the write fails (full disk, sandbox restriction), the failure is invisible.

**Fix:**
```gdscript
var err := cfg.save(SETTINGS_PATH)
if err != OK:
    push_error("SettingsManager: failed to save settings: %s" % error_string(err))
```

---

### L5. `GridManager.get_movement_range()` and `get_movement_path()` use O(n²) priority queues
**File:** `scripts/core/GridManager.gd:185-191`

The frontier scan is acknowledged in the comment ("small N, simple linear scan is fine for MVP"). Flagging here for M6 planning — on maps larger than ~15×15 or with many units on the frontier this will become a noticeable frame hitch.

**Fix (when needed):** Replace with a binary heap / `Array.sort()` approach or Godot's `AStar2D`.

---

## Summary Table

| ID | Severity | File | One-line description |
|----|----------|------|----------------------|
| C1 | CRITICAL | Unit.gd, GameState.gd | Dead units not unregistered → crash on next living-unit query |
| C2 | CRITICAL | GameOverScreen.gd, GameState.gd | Double `reload_current_scene()` on Retry |
| C3 | CRITICAL | HUD.gd, AttackPreview.gd | Unit properties read via wrong paths → always shows "???" and 0 |
| C4 | CRITICAL | HUD.gd | `wpn.weapon_name` doesn't exist; should be `display_name` |
| C5 | CRITICAL | GameState.gd | Player roster not `.duplicate()`'d — live stats corrupt the resource cache |
| H1 | HIGH | MapCursor.gd | Staff heal writes `data.hp` directly — HP bar never updates |
| H2 | HIGH | MapCursor.gd | Item heal writes `data.hp` directly — HP bar never updates |
| H3 | HIGH | SkillHandler.gd, CombatResolver.gd | Miracle checks real HP not simulated HP — fails in multi-hit combat |
| H4 | HIGH | WeaponData.gd, CombatResolver.gd | `strikes_per_attack` never read — Brave weapons don't work |
| H5 | HIGH | DataManager.gd, CombatResolver.gd | Duplicate weapon triangle tables will silently diverge |
| H6 | HIGH | GameMap.gd | Camera start tile hardcoded to map_001 tile (1,9) |
| M1 | MEDIUM | TurnManager.gd | `_combat_lock` declared but never used |
| M2 | MEDIUM | GameState.gd | Living-unit iterators don't guard `is_instance_valid()` |
| M3 | MEDIUM | MapCursor.gd | Null dereference on `_grid` after incomplete null check |
| M4 | MEDIUM | PhaseBanner.gd | Hardcoded 1280px offscreen constants break at other resolutions |
| M5 | MEDIUM | Unit.gd | `get_effective_stat()` silently returns 0 for typo'd stat names |
| M6 | MEDIUM | TurnManager.gd, MapData.gd | `turn_limit` declared but never enforced |
| M7 | MEDIUM | MapData.gd | `reward_gold` / `reward_items` declared but never applied |
| M8 | MEDIUM | ActionMenu.gd | `_move_focus()` infinite loop if all buttons disabled |
| M9 | MEDIUM | EnemyAI.gd | Healer enemies have no heal branch — stand idle |
| M10 | MEDIUM | DataManager.gd | `_load_directory()` silently skips subdirectories |
| L1 | LOW | Boot.gd | Stale comment says MainMenu not built (it is) |
| L2 | LOW | ItemMenu.gd | Wrong comment — Dictionary assignment is by reference, not value |
| L3 | LOW | MapCursor.gd | Zoom stub functions are dead code |
| L4 | LOW | SettingsManager.gd | `cfg.save()` return value ignored |
| L5 | LOW | GridManager.gd | O(n²) Dijkstra frontier scan — acceptable for MVP, flag for M6 |
