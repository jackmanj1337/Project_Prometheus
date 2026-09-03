---
Role: dated
---

# Code Review — 2026-05-15

Reviewer: Claude (harsh mode)  
Codebase: ~3,300 lines, 45 GDScript files, Godot 4.3 turn-based strategy RPG

---

## Summary Verdict

The architecture is sound and the intent is clear. But there are real bugs lurking behind `assert()` calls that evaporate in release builds, a 615-line god class, a critical skill-use-counter bypass, and enough duplicated logic that the same bug can exist in two places simultaneously. This is a first-milestone codebase that needs hardening before Phase 2 complexity is added on top of it.

---

## CRITICAL BUGS (will crash or silently misbehave in production)

---

### C-1 — `assert()` used as runtime guard in DataManager (DataManager.gd:70–87)

```gdscript
func get_weapon(id: String) -> WeaponData:
    assert(_weapons.has(id), "DataManager: unknown weapon id '%s'" % id)
    return _weapons[id]
```

**Problem:** In Godot 4 release builds, `assert()` is stripped entirely. If an unknown `id` is passed, `_weapons[id]` throws a "key not found" error and crashes with no message. The `assert` provides zero protection in shipped code — it is only documentation dressed up as safety.

**Impact:** Any `.tres` file with a typo in a weapon/skill/item/class id causes a release-mode crash with a cryptic engine error, not your clear message.

**Fix:**
```gdscript
func get_weapon(id: String) -> WeaponData:
    if not _weapons.has(id):
        push_error("DataManager: unknown weapon id '%s'" % id)
        return null
    return _weapons[id]
```
All four getters need this treatment. All callers must then null-check the result.

---

### C-2 — `_build_combat_context` dereferences `attacker` before null-check (CombatResolver.gd:24)

```gdscript
func _build_combat_context(attacker: Node, defender: Node) -> Dictionary:
    var aw: WeaponData = attacker.get_equipped_weapon() if attacker else null  # guarded
    var can_ctr := can_counterattack(defender, attacker.tile_position)         # NOT guarded
```

**Problem:** Line 24 accesses `attacker.tile_position` unconditionally immediately after a null-guard on line 23. If `attacker` is null, line 24 crashes.

**Fix:** `var can_ctr := can_counterattack(defender, attacker.tile_position) if attacker else false`

---

### C-3 — `apply_trigger` never checks `max_uses_per_map` for non-combat triggers (SkillHandler.gd:24–43)

```gdscript
func apply_trigger(unit: Node, trigger: String, context: Dictionary) -> Dictionary:
    for skill_id in unit.data.skills:
        var skill: SkillData = dm.get_skill(skill_id)
        ...
        context = _execute_skill(skill, unit, context)  # no use-count check
    return context
```

**Problem:** `_skill_available()` and `_consume_skill()` exist in CombatResolver (CombatResolver.gd:329–337) but are **never called from `apply_trigger`**. A skill with `max_uses_per_map = 3` and trigger `start_of_turn` fires unlimited times every turn. The use-counter system only works for skills that go through `CombatResolver._resolve_single_attack`.

**Fix:** `apply_trigger` must call `_skill_available()` before dispatching and `_consume_skill()` after. Either expose these as methods on SkillHandler or duplicate the logic. This is a design flaw — the per-combat use-counter helpers live in the wrong class.

---

### C-4 — `_restore_unit_data` uses dot notation on Dictionary, will crash on missing keys (GameState.gd:170–195)

```gdscript
func _restore_unit_data(data: UnitData, snap: Dictionary) -> void:
    data.tile_position = snap.tile_position   # crashes if key missing
    data.hp = snap.hp
    ...
    data.shift_gauge = snap.shift_gauge       # Phase 2 field — was it snapshotted?
```

**Problem:** GDScript Dictionary dot notation crashes with "Invalid get index 'shift_gauge' on base 'Dictionary'" if that key isn't present. Any snapshot taken before a code change that added a new snapshotted field will crash on restore. This will definitely be triggered the first time you add a field mid-playtest.

**Fix:** Use `.get(key, default)` for every field, or version the snapshot format.

---

### C-5 — `ConfirmationDialog` added as child of a Node2D (MapCursor.gd:562)

```gdscript
add_child(dlg)
dlg.popup_centered()
```

**Problem:** `MapCursor` extends `Node2D`. Adding a `ConfirmationDialog` (a `Window`) as its child means the dialog is parented to a 2D game node, not the scene root or a CanvasLayer. `popup_centered()` may not behave correctly — the dialog could render under game tiles, fail to capture input properly, or not center on screen as expected depending on Godot's window management.

**Fix:** Add to the scene root: `get_tree().root.add_child(dlg)`.

---

## SERIOUS ISSUES (incorrect behaviour, broken invariants)

---

### S-1 — Phase enum values compared as raw integers everywhere (MapCursor.gd:76, HUD.gd:42)

```gdscript
# MapCursor.gd:76
if new_phase == 1:   # "ENEMY"
    lock()

# HUD.gd:42
_phase_label.text = "PLAYER PHASE" if new_phase == 0 else "ENEMY PHASE"
```

**Problem:** `EventBus.phase_changed` emits `int` from `GameState.Phase` enum. All listeners then magic-number-compare `0` and `1`. If a new phase is ever added (e.g., a "cinematic" phase), every listener silently breaks. The signal type is `int` instead of `GameState.Phase` — GDScript enums are typed integers but signals don't enforce this.

**Fix:** Either type the signal as `Phase` and cast at call sites, or define `PLAYER_PHASE = 0` / `ENEMY_PHASE = 1` in GameConstants. At minimum, use `GameState.Phase.ENEMY` in comparisons and fix the signal type.

---

### S-2 — `_apply_resolve` calculates bonus from base stat, not effective stat (SkillHandler.gd:96–99)

```gdscript
unit.add_modifier("strength", floori(unit.data.strength * 0.5), "resolve", -1, "combat")
unit.add_modifier("magic",    floori(unit.data.magic    * 0.5), "resolve", -1, "combat")
```

**Problem:** Resolve's +50% is calculated from `unit.data.strength` (base stat). If the unit already has a +5 STR modifier active, the Resolve bonus ignores it. The bonus should be `floori(unit.get_effective_stat("strength") * 0.5)`. This is inconsistent with how every other stat calculation in the codebase uses `get_effective_stat`.

---

### S-3 — Desert rule uses hardcoded class_id strings, breaks with promotions (GridManager.gd:101–104)

```gdscript
var class_id: String = unit.data.class_id if unit.data else ""
if class_id in ["mage", "cleric"]:
    return 1
```

**Problem:** Promoted mages (Sage, Bishop, Valkyrie, etc.) will have different class IDs and will pay the standard desert cost instead of 1. The comment even says "for MVP just check class id" — but "MVP" code has a way of becoming permanent. This also violates the data-driven principle: a magic-user quality should be set on the ClassData, not checked by string in GridManager.

**Fix:** Add `"magic_user"` to `ClassData.special_qualities` for magic classes. Use `unit.has_quality("magic_user")`.

---

### S-4 — `_execute_staff_heal` is duplicated between MapCursor and EnemyAI (MapCursor.gd:423–441, EnemyAI.gd:163–186)

Both implement: `heal_amount = 10 + unit.data.magic`, consume durability, add wexp, add 10 EXP. EnemyAI even has the comment "Mirrors the player's _execute_staff_heal() formula." Two implementations of the same formula means any future change (e.g., GDD update changes it to `8 + MAG * 1.5`) must be applied in two places — and one will be missed.

**Fix:** Move staff heal into a shared method, either on `Unit` itself or a helper autoload. The magic constant `10` (base heal) should live in GameConstants.

---

### S-5 — `inventory.duplicate()` drops typed array information in snapshot (GameState.gd:157)

```gdscript
"inventory": data.inventory.duplicate(true),
```

`data.inventory` is `Array[InventoryEntry]`. `.duplicate(true)` returns an untyped `Array`. On restore:
```gdscript
data.inventory = snap.inventory.duplicate(true)
```
This assigns an untyped `Array` to a typed `Array[InventoryEntry]` field. Godot 4 will coerce it, but the elements inside are deep-copied Resources — if any InventoryEntry's class isn't registered yet at restore time (unlikely but possible during scene load), this silently corrupts inventory.

**Fix:** Use proper typed reconstruction, or at minimum cast: `data.inventory.assign(snap.inventory)`.

---

### S-6 — `resolve_combat` returns placeholder zeros for EXP fields (CombatResolver.gd:491–494)

```gdscript
return {
    "exchanges":     exchanges,
    "attacker_died": attacker_died,
    "defender_died": defender_died,
    "attacker_exp":  0,   # <-- placeholder
    "defender_exp":  0,   # <-- placeholder
    "context":       context,
}
```

**Problem:** Any future listener on `combat_resolved` that reads `result["attacker_exp"]` before checking for `apply_combat_result` will get `0`. This is a latent trap — the dict lies. The comment says "filled in by apply_combat_result" but callers have no way to know this without reading both functions.

**Fix:** Either compute EXP in `resolve_combat` (it has all the info needed) or document the field as `"attacker_exp_pending"` and rename it after apply. Don't ship a data structure with known-wrong fields.

---

### S-7 — `LevelUpScreen` accesses `unit.data` without validity check (LevelUpScreen.gd:45–46)

```gdscript
var unit_name: String = unit.data.unit_name if (unit and unit.data) else "???"
```

**Problem:** In rare cases (e.g., a unit levels up from a counter-kill and immediately dies in the same combat exchange), the unit could be `queue_free()`'d before `_show_next()` runs. `unit and unit.data` does not check `is_instance_valid(unit)` — in Godot 4, accessing a freed object through a variable that hasn't been nulled crashes with "Attempt to call method on a previously freed instance."

**Fix:** `if unit and is_instance_valid(unit) and unit.data else "???"`

---

## DESIGN PROBLEMS (not bugs today, but will cause bugs in Phase 2)

---

### D-1 — `MapCursor` is a 615-line god class with 7 states and 30+ methods

This file handles: keyboard input, mouse input, camera scrolling, unit selection, movement, action dispatch, attack targeting, attack preview, staff targeting, item use, end-turn confirmation, danger zone display, and map menu. It is impossible to unit-test any single behaviour without mocking the entire cursor + grid + turn manager + action menu + attack preview + item menu chain.

The existing `test_unit_selection.gd` barely scratches the surface. As Phase 2 adds more actions (skills, transformation, etc.), this file will become unmaintainable.

**Fix:** Extract state behaviour into separate handler objects or at minimum split into `MapCursorInput.gd`, `MapCursorSelection.gd`, `MapCursorTargeting.gd`. A proper FSM class with enter/exit/handle would allow testing each state in isolation.

---

### D-2 — S-rank bonuses are hardcoded in `Unit.gd` instead of data-driven (Unit.gd:258–314)

```gdscript
func accuracy(weapon: WeaponData = null) -> int:
    ...
    if _has_s_rank(w):
        acc += 10   # magic number
```

`+10 Hit`, `+5 Crit`, `+1 Damage` for S-rank appear in three separate methods with hardcoded values. These should be a "s_rank_mastery" passive skill defined in SkillData. A designer cannot tune S-rank bonuses without editing code. The numbers `10`, `5`, `1` should at minimum be GameConstants.

---

### D-3 — `UnitData` exports runtime fields, polluting the editor inspector (UnitData.gd:57–73)

```gdscript
@export var active_modifiers: Array[Dictionary] = []
@export var skill_use_counters: Dictionary = {}
@export var damage_taken_this_map: int = 0
```

These are pure runtime state. They should never be set in the editor — they're reset by `reset_map_state()` at map load. Exporting them means anyone editing a `.tres` file sees them, could accidentally set them, and the resource files will grow bloated with serialized runtime state if Godot ever writes them out.

**Fix:** Remove `@export` from all three. Store runtime state separately (e.g., in a parallel RuntimeUnitState dict keyed by unit_id).

---

### D-4 — `InventoryEntry` uses a union type with no enforcement

`InventoryEntry` combines weapon fields, item fields, and equip fields in one class with an `entry_type: String` discriminant. Nothing prevents:
```gdscript
var e := InventoryEntry.new()
e.entry_type = "weapon"
e.weapon_id = "iron_sword"
e.item_id = "vulnerary"   # nonsense — silently accepted
```
The discriminant pattern is fragile. `uses_remaining` defaults to `0`, making a raw `InventoryEntry.new()` immediately broken (0 uses = un-usable).

**Fix:** Either use `GDScript inner classes` as derived types, or at minimum add a `validate()` method similar to SkillData, and change the default `uses_remaining` to `-1` (infinite) with 0 being "broken/empty."

---

### D-5 — Skill effect dispatch uses raw string matching with no compile-time safety (SkillHandler.gd:47–62)

```gdscript
match skill.effect_id:
    "renewal":    return _apply_renewal(...)
    "vantage":    return _apply_vantage(...)
    ...
    _:
        push_warning("SkillHandler: unknown effect_id '%s'" % skill.effect_id)
```

A typo in any `.tres` file's `effect_id` field silently hits the `push_warning` branch. New skills require code changes to `_execute_skill`. Phase 2 will add 15+ more skills — this match statement becomes a liability.

**Fix:** Build a Dictionary of callables at startup: `{ "renewal": _apply_renewal, "vantage": _apply_vantage, ... }`. New skills can register themselves. Or give SkillData a `Callable` field directly.

---

### D-6 — Dijkstra is implemented twice with the same complexity flaw

`GridManager.get_movement_range` (GridManager.gd:183–207) and `GridManager.get_movement_path` (GridManager.gd:218–260) both implement Dijkstra with the same O(n²) frontier-pop pattern. Then `EnemyAI._flood_costs` (EnemyAI.gd:232–256) implements a *third* Dijkstra. The `_DIRS` constant is also duplicated: `GridManager.gd:163` and `EnemyAI.gd:235`.

Three copies of the same algorithm means three places to fix a bug. GridManager's comment acknowledges the O(n²) in `get_movement_range` but `get_movement_path` has no such comment and has the same flaw.

**Fix:** Extract a shared `_dijkstra(start, max_cost, unit, grid)` utility. Make `_DIRS` a public constant on `GridManager` and reference it from `EnemyAI`.

---

### D-7 — Context dict has 35+ keys with no schema or documentation

`_build_combat_context` returns a dict with keys: `attacker`, `defender`, `attacker_weapon`, `defender_weapon`, `is_player_initiated`, `turn_number`, `atk_mod` (with 6 sub-keys), `def_mod` (with 6 sub-keys), `flags` (with 8 sub-keys). Skills then ADD keys: `defender_skills_blocked`, `attacker_skills_blocked`, `current_sim_hp`, `unit`, `damage`, etc.

There is no single place listing all valid context keys. A skill that reads a key another skill sets is implicitly coupled with no documentation of the dependency. A typo in a context key causes silent wrong behavior.

**Fix:** At minimum, document all context keys in a comment block at the top of CombatResolver. Long-term: typed inner classes for CombatContext, AttackModifiers, CombatFlags.

---

## QUALITY ISSUES (real problems, lower blast radius)

---

### Q-1 — `Unit._get_grid_manager` walks the scene tree on every combat calculation (Unit.gd:148–160)

Called from `get_terrain_def_bonus()` and `get_terrain_dodge_bonus()`, which are called during every combat calculation. The walk traverses the parent chain calling `get_node_or_null("GridManager")` at each level, every time. The cache helps only after first success, but `is_instance_valid()` re-checks every call.

**Fix:** Cache once in `_ready()` via `get_tree().get_first_node_in_group("grid_manager")` or inject the reference in `Unit.initialize()`.

---

### Q-2 — `Unit.get_equipped_weapon_entry` causes redundant DataManager lookups (Unit.gd:94–117)

`get_equipped_weapon()` calls `get_equipped_weapon_entry()` which calls `_load_weapon()`. `_load_weapon` calls `get_node_or_null("/root/DataManager")` AND `dm.get_weapon(id)`. Then `get_equipped_weapon()` calls `_load_weapon()` AGAIN on the found entry. Two `get_node_or_null` calls and two dict lookups per equipped-weapon query. This happens multiple times per combat round.

**Fix:** `get_equipped_weapon_entry()` should return the entry AND the loaded WeaponData together, or `get_equipped_weapon()` should call `get_equipped_weapon_entry()` and load once from the returned entry's ID.

---

### Q-3 — `WeaponData._eval_formula` silently returns `1` on formula errors (WeaponData.gd:62–64)

```gdscript
push_warning("WeaponData: unrecognised range formula '%s'" % formula)
return 1
```

A typo like `"MAG/2 "` (trailing space) silently gives every weapon range 1. A bow with a broken formula appears as a melee weapon with no in-editor indication beyond a console warning. This should be `push_error`.

---

### Q-4 — `SettingsManager` stores booleans as strings (SettingsManager.gd:21–22, GameState.gd:37)

```gdscript
var permadeath: String = "off"
...
permadeath_enabled = (SettingsManager.permadeath == "on")
```

Using String `"on"`/`"off"` for a boolean is unnecessary complexity. `cfg.get_value()` handles `bool` natively. A typo anywhere — `"On"`, `"ON"`, `"true"` — silently evaluates to `false`. All boolean settings should use `bool`.

---

### Q-5 — `GameMap._validate_map` logs errors but doesn't abort map load (GameMap.gd:141–153)

```gdscript
push_error("GameMap: row %d length %d, expected %d" % [y, row.length(), width])
return  # returns from _validate_map, not from _ready
```

After pushing a row-length error, `_ready` continues to `_paint_terrain`, which will access out-of-bounds string indices or paint garbage. The validation is theater — it reports the problem but doesn't prevent the broken state.

**Fix:** Have `_validate_map` return a `bool` and abort `_ready` on failure.

---

### Q-6 — `ActionMenu._move_focus` contains an infinite loop if all buttons disabled (ActionMenu.gd:83–93)

```gdscript
while true:
    i = (i + delta + _buttons.size()) % _buttons.size()
    if not _buttons[i].disabled:
        break
    if i == start:
        break  # "shouldn't happen"
```

The "shouldn't happen" case WILL happen the moment a bug elsewhere leaves Wait disabled. The infinite loop protection exists (the `i == start` break), but the loop will still cycle through all buttons once before breaking — and then does nothing, leaving focus on a disabled button with no feedback to the player.

---

### Q-7 — `HUD._find_grid` walks the scene tree on every cursor move (HUD.gd:58–70, 85–89)

`_find_grid()` is called from `_on_cursor_moved()` → `_update_terrain()` when `_grid == null`. Since `_grid` is set in `setup()`, this is only a problem if `setup()` wasn't called. But it's also called from `_on_unit_deselected()` with the same null check — if `setup()` was properly called, these are no-ops, but they run the check every time anyway.

---

### Q-8 — `SettingsManager.set_volume` has no input validation (SettingsManager.gd:123–129)

```gdscript
func set_volume(bus_name: String, value: int) -> void:
    match bus_name:
        "Master": master_volume = value
```

No clamping. `linear_to_db(150 / 100.0)` or `linear_to_db(-10 / 100.0)` will produce invalid audio bus values. **Fix:** `value = clampi(value, 0, 100)`.

---

### Q-9 — `Unit.set_done_appearance` is not idempotent (Unit.gd:459–461)

```gdscript
func set_done_appearance() -> void:
    if _sprite:
        _sprite.modulate = _sprite.modulate.darkened(0.4)
```

`darkened(0.4)` is relative — calling this twice darkens the sprite to 36% of original brightness. If any code path calls `set_done_appearance()` twice on the same unit without a `reset_appearance()` in between, the visual is wrong. No documentation warns callers of this.

---

### Q-10 — `GameState.load_default_roster` silently fails if DirAccess returns null (GameState.gd:97–116)

```gdscript
var dir := DirAccess.open(roster_path)
if dir == null:
    push_error("GameState: cannot open roster directory: " + roster_path)
    return
```

`push_error` and `return` — the error is logged, `player_roster` stays empty, execution continues. `GameMap._spawn_units` then spawns zero player units and silently starts a map with no player units. The player sees an empty map with no error message.

**Fix:** At minimum emit a `map_defeat` or show a fatal error screen. Better: `assert(dir != null, ...)` in debug; dedicated error handling in release.

---

## MINOR ISSUES (style, naming, consistency)

---

### M-1 — `class_name` missing on autoloads

`EventBus.gd`, `GameState.gd`, `DataManager.gd` etc. all lack `class_name`. Without it, you can't write `EventBus.phase_changed.emit(...)` with type checking outside the autoload system. Type-safe signal calls are the main benefit of the typed GDScript 2.0 system.

---

### M-2 — Magic numbers not in GameConstants

The following numbers appear in code without GameConstants references:
- `10` (base staff heal) — MapCursor.gd:430, EnemyAI.gd:181
- `0.10` (fort healing rate) — TurnManager.gd:47  
- `4` (follow-up speed threshold) — CombatResolver.gd:232–235
- `10`, `5`, `1` (S-rank bonuses) — Unit.gd:282, 302, 312
- `0.25` and `0.10` (key repeat timings) — defined in MapCursor.gd but not in GameConstants
- `0.4` (done-appearance darkening) — Unit.gd:461

---

### M-3 — `_DIRS` duplicated in GridManager and EnemyAI (GridManager.gd:163, EnemyAI.gd:235)

Identical constant defined twice. Should be `const DIRS: Array[Vector2i]` (public) on GridManager and referenced as `GridManager.DIRS` in EnemyAI.

---

### M-4 — `test_combat.gd` MockUnit breaks `get_equipped_weapon_entry` return type contract (test_combat.gd:28–30)

```gdscript
func get_equipped_weapon_entry() -> Dictionary:
    if _weapon == null: return {}
    return {"weapon_id": _weapon.get("id"), "type": "weapon", "uses_remaining": 99}
```

Real `Unit.get_equipped_weapon_entry()` returns `InventoryEntry` (or null). The mock returns a `Dictionary`. If any future test path passes a MockUnit to code that calls `entry.is_weapon()`, it crashes because Dictionary has no `is_weapon()` method. The mock is a type lie.

---

### M-5 — `EnemyAI._find_nearest` Manhattan fallback is unreachable in normal gameplay (EnemyAI.gd:208–209)

```gdscript
return nearest if nearest != null else _find_nearest_manhattan(from_unit, units)
```

If `_flood_costs` returns a valid cost map but all target tiles have cost `INT_MAX` (fully walled off), `nearest` will be null and Manhattan is used. This is a reasonable fallback, but it contradicts Dijkstra's result — Manhattan can pick a different target than the true nearest through open terrain. The fallback should be documented as "pathfinding distance not available, using heuristic."

---

### M-6 — `_apply_stat_bonus`, `_apply_charm`, `_apply_anathema`, `_apply_daunt` are dead stubs (SkillHandler.gd:153–177)

Four skill implementations are `return context  # [STUB]` — no-ops. Their `.tres` entries presumably exist or will exist. Currently harmless, but if a `.tres` file sets `effect_id = "charm"` it silently does nothing. At minimum, log a warning in the stub so stubs don't pass for real behavior.

---

### M-7 — `GameConstants` extends Node unnecessarily

```gdscript
extends Node
```

`GameConstants` has zero instance methods — only `const` fields. An autoload that extends `Node` costs a node in the scene tree, processes `_ready()`, etc. Since all fields are `const`, a plain script file with no extends would suffice, preloaded anywhere it's needed. At minimum, there's no reason to extend Node over RefCounted.

---

### M-8 — `InventoryEntry.uses_remaining` defaults to `0`, making raw-constructed entries immediately broken (InventoryEntry.gd:17)

`@export var uses_remaining: int = 0` — an `InventoryEntry.new()` that skips the factory methods has 0 uses and cannot be used. Any future code that constructs an entry manually without using `make_weapon()`/`make_item()` will get a silent "no uses" bug.

---

### M-9 — `GameState._snapshot_unit_data` uses `duplicate()` without `true` for `skills` array (GameState.gd:158)

```gdscript
"skills": data.skills.duplicate(),       # shallow copy
...
"proficiencies": data.proficiencies.duplicate(true),  # deep copy
```

`skills` is `Array[String]`. Strings are immutable so shallow is fine — but the inconsistency with every other array in the same function is confusing. A future reader will assume shallow is a bug and "fix" it, or assume deep is wrong and break something.

---

### M-10 — No CI/CD — tests are run manually only

There is no evidence of automated test execution on commit. The comment in `test_combat.gd` says "Run with: godot --headless ..." — meaning someone has to remember to run it. A broken commit that passes style checks but fails combat math will not be caught until someone manually runs tests.

**Fix:** Add a `Makefile` or shell script that runs all test files headlessly, and wire it to a pre-commit hook or CI pipeline.

---

## WHAT'S ACTUALLY GOOD

To be balanced: the stateless `CombatResolver` design is excellent and makes preview-without-side-effects trivial. The EventBus decoupling is solid. The data-driven content system works. `InventoryEntry` replacing raw dictionaries is the right call. The snapshot/restore system is well-thought-out. The test coverage of the core math is real and catches regressions. The GDD comment discipline (`[DEFERRED — Laguz]`, `[STUB — M9]`) is valuable.

The architecture can support a shipped game. The issues above are preventing it from being production-ready.

---

## Priority Fix Order

1. **C-3** — `apply_trigger` ignores `max_uses_per_map` (skills cheat)
2. **C-1** — `assert()` as runtime guard (release crash)
3. **C-2** — `attacker.tile_position` null dereference (crash)
4. **C-4** — snapshot restore key access (crash on new fields)
5. **C-5** — ConfirmationDialog parented to Node2D (UI corruption)
6. **S-2** — Resolve uses base stat not effective stat (wrong combat math)
7. **S-3** — Desert rule by class_id string (breaks promotions)
8. **S-4** — Staff heal duplicated (diverge bug waiting to happen)
9. **D-3** — Remove `@export` from runtime UnitData fields (data integrity)
10. **Q-4** — Boolean settings stored as strings (silent failure)
