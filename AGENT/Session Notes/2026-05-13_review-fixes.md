# Harsh Code Review — 2026-05-13

**Scope:** Full codebase review of all .gd scripts.  
**Severity legend:** 🔴 Critical (crash/data loss) · 🟠 Serious (wrong behavior) · 🟡 Moderate (fragile/latent) · 🔵 Minor/Style

---

## SECTION 1 — CRITICAL BUGS (crash or data loss risk)

---

### 🔴 BUG-01 — Double-kill leaves second unit alive forever
**File:** `CombatResolver.gd:459–474` (`apply_combat_result`)

```gdscript
for exchange in result["exchanges"]:
    ...
    if exchange["hit"]:
        def_unit.take_damage(exchange["damage"])
        def_unit.data.damage_taken_this_map += exchange["damage"]
        if def_unit.data.hp <= 0 and def_unit.has_method("handle_death"):
            def_unit.handle_death()
            break  # ← exits the entire loop
```

**Problem:** The loop `break`s the moment ANY defender's HP hits 0. In a mutual-kill scenario (attacker and defender both reach 0 HP), only the first unit to die (per exchange order) gets `handle_death()`. The second unit is left with 0 HP, alive on the battlefield, taking no further actions but also never removed from `GameState.all_units`. It will block tiles, corrupt future range calculations, and block iteration in `get_living_player_units()` / `get_living_enemy_units()` (which filter by `data.hp > 0`, so they'd be excluded — but `all_units` still holds the zombie node). Turn-manager victory checks (`gs.get_living_enemy_units().is_empty()`) would still work, but the zombie node is never freed, which is a memory leak and a logical inconsistency.

**Fix:** After calling `handle_death()` on the first casualty, continue the loop to check remaining exchanges. Replace the `break` with a continue-or-check pattern. Alternatively, after the loop, check both `result["attacker_died"]` and `result["defender_died"]` and call `handle_death()` on both if neither was freed yet.

**Pros of fix:** Correct death handling in all scenarios.  
**Cons:** Slightly more complex loop; must guard `is_instance_valid()` before accessing nodes on later exchanges.

---

### 🔴 BUG-02 — Follow-up attack ignores `strikes_per_attack` (Brave weapons)
**File:** `CombatResolver.gd:417–430` (`resolve_combat`)

```gdscript
if follow_up != null:
    ...
    var ex := _resolve_single_attack(follow_up, fu_target, context, is_fu_counter, tgt_sim_hp)
    ex["is_follow_up"] = true
```

**Problem:** The follow-up attack fires exactly **one** exchange, regardless of the follow-up unit's `strikes_per_attack`. A Brave weapon (`strikes_per_attack = 2`) normally fires two times before the defender counters. But in the follow-up phase, that same Brave weapon only fires once. A fast unit with a Brave weapon should deliver four strikes total (2 initial + 2 follow-up), but gets three (2 + 1). This is inconsistent with GDD_02 intent and with how initial strikes are handled.

**Fix:** Mirror the initial `for _i in atk_strikes:` loop for the follow-up:

```gdscript
var fu_strikes: int = (context["atk_mod"]["strikes"] + (aw.strikes_per_attack if aw else 1)) \
    if follow_up == attacker else def_strikes
for _i in fu_strikes:
    if tgt_sim_hp <= 0: break
    var ex := _resolve_single_attack(...)
    ...
```

**Pros:** Correct multi-hit behavior.  
**Cons:** Increases exchange list size; `preview_combat()` already computes `attacker_attacks` as `2 * atk_strikes` which would be correct, but `resolve_combat` would not match that count — fixing this also fixes a preview/resolve discrepancy.

---

### 🔴 BUG-03 — Miracle with HP=1 still kills the unit
**File:** `SkillHandler.gd:112–114` (`_apply_miracle`)

```gdscript
if (randi() % 100) < luk:
    context["damage"] = maxi(1, dmg / 2)
```

**Problem:** If the unit has 1 HP and takes 1 damage, Miracle triggers (`dmg >= sim_hp`), rolls successfully, and sets `damage = maxi(1, 1/2) = maxi(1, 0) = 1`. The unit still dies. Miracle failed to save them despite activating. The intended behavior in every Fire Emblem game is that Miracle reduces the killing blow to leave the unit at 1 HP, not halve the damage.

**Decision:** Miracle guarantees survival — it must always leave the unit at exactly 1 HP.

**Fix:**
```gdscript
context["damage"] = sim_hp - 1
```
This unconditionally sets damage to leave 1 HP remaining. The `maxi(1, dmg/2)` formula is replaced entirely — halving is irrelevant once survival is the guarantee.

**Pros:** Faithful to the skill's intent; prevents activating Miracle and dying anyway.  
**Cons:** None meaningful.

---

### 🔴 BUG-04 — `DirAccess.open("res://...")` fails silently in exported builds
**File:** `GameState.gd:93–111` (`load_default_roster`)

```gdscript
var dir := DirAccess.open(roster_path)
if dir == null:
    push_error("GameState: cannot open roster directory: " + roster_path)
    return
```

**Problem:** `DirAccess` on `res://` paths **cannot enumerate files in exported (PCK) builds on most platforms** (Windows, Android, iOS, macOS app bundles). The PCK is an opaque container; directory listing requires parsing it separately. This means `player_roster` stays empty and the game silently falls back to `load_default_roster()` every map start, loading nothing. The same issue affects `DataManager._load_directory()`.

**Decision:** Use a `ResourcePreloader` node.

**Fix:** Create a `DataPreloader.tscn` autoloaded scene containing a `ResourcePreloader` node. All `.tres` files for roster, weapons, classes, items, and skills are added to it in the editor by drag-and-drop. `GameState.load_default_roster()` and `DataManager._load_directory()` are replaced with lookups against the preloader by resource name. Adding a new resource = drag it into the preloader in the editor; no code change required.

**Pros:** Works in all exported builds; editor-validated; no hardcoded path strings in code.  
**Cons:** Must open the editor to add new data files (can't drop a `.tres` in a folder and have it auto-appear); preloader node must be kept in sync with the data directory.

---

## SECTION 2 — SERIOUS BUGS (wrong behavior, no crash)

---

### 🟠 BUG-05 — Victory conditions fire twice on every kill
**File:** `TurnManager.gd:111`, `TurnManager.gd:194`

```gdscript
# In start_enemy_phase():
await ai.run_enemy_phase(_grid, self)
check_victory_conditions()  # ← once at end of enemy phase

# In _on_unit_died():
func _on_unit_died(_unit: Node) -> void:
    check_victory_conditions()  # ← once per kill via signal
```

**Problem:** When any unit dies, `_on_unit_died` fires (via `EventBus.unit_died`) and calls `check_victory_conditions()`. At the end of the enemy phase, `check_victory_conditions()` is called again. If the last enemy died during the enemy phase, `map_victory.emit()` fires twice. The `GameOverScreen` or win-condition handler receives the signal twice, potentially triggering a double scene transition or double UI popup.

**Fix:** Remove the call to `check_victory_conditions()` from `start_enemy_phase()`. The `_on_unit_died` handler already covers mid-battle checks. Add a post-phase check only for turn-limit defeat (which can't be detected via `unit_died`).

**Pros:** Single, authoritative victory emit.  
**Cons:** Must ensure `start_player_phase()` also checks turn limit on its own.

---

### 🟠 BUG-06 — `_apply_resolve()` is fundamentally wrong: Resolve is a stat modifier, not an accuracy patch
**File:** `SkillHandler.gd:82–91`

```gdscript
func _apply_resolve(_skill: SkillData, unit: Node, context: Dictionary) -> Dictionary:
    ...
    mod["damage"]   += floori(base_stat * 0.5)
    mod["accuracy"] += floori(unit.data.skill * 0.5) * 2
    return context
```

**Problem:** The current implementation patches `atk_mod["accuracy"]` and `atk_mod["damage"]` directly, which means Resolve only affects combat math for one fight. But the **correct behavior** (per design decision) is: when HP ≤ 50%, Resolve grants +50% to STR, MAG, SKL, and SPD as temporary stat modifiers — which then flow through all the normal stat functions (`accuracy()`, `damage()`, `battle_speed()`, etc.) correctly and affect all derived stats. The current approach misses SPD entirely (no follow-up threshold adjustment), misses interaction with other skills that read raw stats, and the accuracy formula `floori(skill * 0.5) * 2` is wrong (gives `skill - 1` for odd SKL values).

**Decision:** Resolve should call `unit.add_modifier()` for each stat at the start of combat (not patch the mod dict), so the buff is reflected in all stat reads for the duration.

**Fix:** Replace the entire `_apply_resolve` body:
```gdscript
func _apply_resolve(_skill: SkillData, unit: Node, _context: Dictionary) -> Dictionary:
    if unit.data.hp * 2 > unit.data.max_hp:
        return _context
    # Apply +50% to STR, MAG, SKL, SPD as one-combat modifiers
    unit.add_modifier("strength",  floori(unit.data.strength * 0.5), "resolve", -1, "combat")
    unit.add_modifier("magic",     floori(unit.data.magic    * 0.5), "resolve", -1, "combat")
    unit.add_modifier("skill",     floori(unit.data.skill    * 0.5), "resolve", -1, "combat")
    unit.add_modifier("speed",     floori(unit.data.speed    * 0.5), "resolve", -1, "combat")
    return _context
```
Because `duration_type = "combat"`, `clear_combat_modifiers()` (already called by CombatResolver after each fight) will clean these up automatically.

**Pros:** Correct for all derived stats; SPD buff enables follow-up threshold adjustment; consistent with the modifier system already in place.  
**Cons:** `add_modifier()` replaces any existing "resolve" modifier (by source), so re-triggering Resolve mid-fight is handled correctly already.

---

### 🟠 BUG-07 — `preview_combat()` fires side-effectful skill triggers
**File:** `CombatResolver.gd:330` (`preview_combat`)

```gdscript
func preview_combat(attacker: Node, defender: Node) -> Dictionary:
    var context := _build_combat_context(attacker, defender)
    _collect_combat_modifiers(context)  # ← fires on_combat_start skills
```

**Problem:** `_collect_combat_modifiers()` calls `sh.apply_trigger(attacker, "on_combat_start", context)`. Any `on_combat_start` skill that modifies unit state (e.g., a future skill that heals or buffs stats as a side effect) would corrupt live unit data during a preview call. Currently safe because existing `on_combat_start` skills only write to `atk_mod`/`def_mod`. But this is a ticking time bomb: the preview pipeline is not safe-by-design, only safe-by-luck.

**Decision:** Use the snapshot/restore approach for future-proofing.

**Fix:** Before `_collect_combat_modifiers()` in `preview_combat()`, snapshot both units' `active_modifiers`, `skill_use_counters`, `hp`, and any other mutable state. After collection, restore the snapshots. This makes preview unconditionally safe for any skill implementation without requiring authors to remember to check a flag.

```gdscript
func preview_combat(attacker: Node, defender: Node) -> Dictionary:
    var atk_snap := _snapshot_unit_state(attacker)
    var def_snap := _snapshot_unit_state(defender)
    var context := _build_combat_context(attacker, defender)
    _collect_combat_modifiers(context)
    _restore_unit_state(attacker, atk_snap)
    _restore_unit_state(defender, def_snap)
    ...
```

**Pros:** Any future skill is automatically preview-safe; no author discipline required; no flag threading.  
**Cons:** More code; snapshot/restore must cover every field a skill could mutate — must be kept in sync as new mutable fields are added to UnitData.

---

### 🟠 BUG-08 — Enemy AI uses Manhattan distance for "nearest" ignoring walls
**File:** `EnemyAI.gd:89–97` (`_find_nearest`)

```gdscript
var d: int = absi(u.tile_position.x - from_unit.tile_position.x) \
    + absi(u.tile_position.y - from_unit.tile_position.y)
```

**Problem:** An enemy separated from a player by a wall will consider that player "nearest" even though no path exists. The enemy then tries to move toward them, picks a move tile closest to that player (still by Manhattan distance), and may end up permanently stuck against the wall, never attacking. On any map with walls separating units, enemy AI behavior degrades or stalls.

**Fix:** Use actual movement cost (already computed by Dijkstra in `get_movement_range()`) to find the nearest **reachable** target.

**Pros:** Correct AI targeting on maps with terrain.  
**Cons:** More expensive; requires running Dijkstra from enemy's position toward each player's position, or pre-computing reachability.

---

### 🟠 BUG-09 — `AttackPreview.show_preview()` calls `preview_combat()` which fires skill triggers while UI is just rendering
**File:** `AttackPreview.gd:22–44`

This is the same issue as BUG-07, but from a UI-level caller. Every time the player hovers over a target and the preview updates, skills fire. If `preview_combat` is ever called on `cursor_moved`, this becomes an every-frame state corruption issue.

Currently `show_preview()` is only called once per target (on confirm → "previewing" state), not on hover. But there's no guard preventing a future developer from calling it on hover.

---

### 🟠 BUG-10 — `apply_combat_result()` may award EXP for 0-hit exchanges
**File:** `CombatResolver.gd:443–445`

```gdscript
var atk_dealt: bool = exchanges.any(func(e): return e["attacker"] == attacker and e["hit"])
...
"attacker_exp": calculate_exp(attacker, defender, defender_died) if atk_dealt or defender_died else 0,
```

**Problem:** `atk_dealt or defender_died` means if the defender dies (e.g., from Vantage counter making them counterattack and die) but the attacker never landed a hit, the attacker still gets EXP if `defender_died`. A unit that attacked, missed all hits, but the defender died from their own vantage attack would receive kill EXP.

**Fix:** `defender_died and atk_dealt` — only award kill EXP if the attacker both hit and the defender died.

**Pros:** EXP only for actual contributions.  
**Cons:** Edge case where Vantage kills attacker and nobody gets EXP for the kill.

---

## SECTION 3 — MODERATE / LATENT ISSUES

---

### 🟡 BUG-11 — `_validate_map()` uses `assert()`, stripped in release builds
**File:** `GameMap.gd:139–147`

```gdscript
assert(grid.size() == height, ...)
assert(row.length() == width, ...)
assert(_CHAR_TO_SOURCE.has(ch), ...)
```

**Problem:** GDScript `assert()` is compiled out in exported builds. A malformed map `.tres` would silently paint garbage terrain, zero-width rows, or unknown terrain chars — all producing invisible corruption (wrong tile source IDs → wrong move costs → wrong combat bonuses).

**Fix:** Replace with `push_error()` + early `return` guards, which execute in all builds.

**Pros:** Map validation is always active.  
**Cons:** Slightly more verbose.

---

### 🟡 BUG-12 — `MapCursor` state machine uses Strings instead of an enum; "previewing" is undocumented
**File:** `MapCursor.gd:24–25`, `_on_confirm()` line 227, `_show_attack_preview()` line 363

The state comment at line 203 lists 6 states but omits `"previewing"`. A typo (`"prewieving"`) would silently break the state machine with no error — the `match` block would simply fall through.

**Fix:** Convert to `enum State { FREE, UNIT_SELECTED, UNIT_MOVED, TARGETING, PREVIEWING, STAFF_TARGETING, LOCKED }` and update all match statements. Update the comment.

**Pros:** Type-checked states; autocomplete; typos become compile errors.  
**Cons:** Slightly more boilerplate.

---

### 🟡 BUG-13 — `GameState` has three overlapping unit arrays that can desync
**File:** `GameState.gd:14–16`

```gdscript
var all_units: Array[Node] = []
var player_units: Array[Node] = []
var enemy_units: Array[Node] = []
```

**Problem:** Every unit must be registered via `register_unit()` which writes to all three. Any direct modification of one array (e.g., `gs.all_units.erase(u)` without going through `unregister_unit()`) silently desyncs the three arrays. Several callers iterate `gs.all_units` (CombatResolver, auras), while others use `gs.get_living_player_units()` (which reads `player_units`). If they diverge, aura skills see different unit counts than victory checks.

**Fix:** Make `player_units` and `enemy_units` private (leading underscore) and expose only getters. Remove `player_units` and `enemy_units` as public vars entirely; `get_living_player_units()` / `get_living_enemy_units()` can filter `all_units` internally. Yes, slightly slower, but correct.

**Pros:** Single source of truth.  
**Cons:** Minor performance cost (filtering on every call).

---

### 🟡 BUG-14 — `TurnManager._unit_states` holds freed Node keys
**File:** `TurnManager.gd:9`

```gdscript
var _unit_states: Dictionary = {}
```

When a unit dies and calls `queue_free()`, its Node key remains in `_unit_states`. Godot 4's Dictionary doesn't auto-evict freed Node keys. While the TurnManager is reloaded on scene reload (so this resets), within a single map, dead units leave orphaned entries. `can_unit_act()` will silently return `READY` for a dead unit (since `_unit_states.get(unit, READY)` returns the stored state for the freed but not-yet-evicted node). This could cause off-by-one errors in `are_all_player_units_done()`.

**Fix:** In `_on_unit_died()` (or on `handle_death()`), call `_unit_states.erase(unit)`.

**Pros:** Clean dictionary; correct all-done checks.  
**Cons:** None.

---

### 🟡 BUG-15 — Wait button not explicitly re-enabled in `ActionMenu.show_for()`
**File:** `ActionMenu.gd:52–54`

```gdscript
_btn_attack.disabled = not has_enemies
_btn_staff.disabled  = not has_heal_targets
_btn_item.disabled   = not has_items
# _btn_wait is never touched
```

**Problem:** The Wait button is assumed to always be enabled. But if any code path ever calls `_btn_wait.disabled = true` (future menus, editor default), it will never be re-enabled. The `_move_focus()` comment even admits this: `"# all disabled; shouldn't happen if Wait is always enabled"`. That's a fragile guarantee.

**Fix:** Add `_btn_wait.disabled = false` at the bottom of `show_for()`.

---

### 🟡 BUG-16 — `_do_resolve_attack()` doesn't await animations; input unblocks before combat visuals complete
**File:** `MapCursor.gd:383–394`

```gdscript
_state = "locked"
var cr := get_node_or_null("/root/CombatResolver")
if cr:
    var result := cr.resolve_combat(_selected_unit, target)
    cr.apply_combat_result(result, _selected_unit, target)
_finish_action()  # immediately sets _state = "free"
```

**Problem:** `apply_combat_result` emits signals (`combat_resolved`) which trigger `CombatHUD._on_combat_resolved()` which spawns floating damage labels using Tweens. These tweens run for 0.8 seconds asynchronously. Meanwhile, `_finish_action()` has already set `_state = "free"`, allowing the player to select another unit, move it, and attack again while the floating numbers from the previous combat are still animating. This is not a crash, but it's a poor UX and can cause overlapping visual state.

**Decision:** `combat_animations = "none"` means zero animations — no tweens, no floating labels, instant resolution. When animations are enabled, `_do_resolve_attack` must stay locked until all combat visuals finish.

**Fix:** Make `_do_resolve_attack` async. `apply_combat_result` should emit a signal when all per-exchange animations have completed (or immediately when `combat_animations = "none"`). `_do_resolve_attack` awaits that signal before calling `_finish_action()`. The `SettingsManager.combat_animations` value must be threaded into `CombatHUD` so it knows whether to spawn tweens or skip them entirely.

---

### 🟡 BUG-17 — `context["flags"]["nihil"]` is dead code
**File:** `CombatResolver.gd:39`, `SkillHandler.gd:73–77`

The context is initialized with `"flags": { "nihil": false, ... }`. Nihil is implemented by setting `"defender_skills_blocked"` / `"attacker_skills_blocked"` directly on `context`. The `flags["nihil"]` entry is never read by any code. It's dead and misleading — suggesting Nihil uses a flag dict key when it doesn't.

**Fix:** Remove `"nihil": false` from the flags dict, or move the `defender_skills_blocked` logic into `flags["nihil"]` consistently.

---

### 🟡 BUG-18 — `Unit.tile_position` not updated during move animation
**File:** `Unit.gd:418–419`

```gdscript
await tween.finished
tile_position = path[-1]  # ← updated only AFTER animation
```

**Problem:** During a 0.8s movement animation, `tile_position` still reflects the origin tile. Any query to `get_unit_at(tile)` during animation returns the unit at its old position. `GridManager.get_movement_range()` called on another unit during this window would see the old position, potentially allowing a second unit to plan movement through the animating unit. Currently safe because `MapCursor._state = "locked"` during animation. Fragile if enemy AI could run concurrently.

---

### 🟡 BUG-19 — `GameState.selected_unit` is a dead field
**File:** `GameState.gd:17`

```gdscript
var selected_unit: Node = null
```

This field is declared, never set (MapCursor tracks selection internally), and never read. It's stale API that could confuse future developers who try to use it and get `null`.

**Fix:** Remove the field. Selection state belongs to MapCursor.

---

### 🟡 BUG-20 — `_get_grid_manager()` in Unit.gd walks the scene tree on every call
**File:** `Unit.gd:142–152`

```gdscript
func _get_grid_manager() -> GridManager:
    var n := get_parent()
    while n:
        var g := n.get_node_or_null("GridManager")
        if g and g is GridManager:
            return g
        n = n.get_parent()
    return null
```

This is called by `get_terrain_def_bonus()` and `get_terrain_dodge_bonus()`, which are called on every damage calculation. Each call walks the entire tree upward. For a map with 10+ units fighting, this is a repeated O(depth) lookup per combat.

**Fix:** Cache the GridManager reference in `_ready()` or `initialize()`. If the unit is never moved between maps (it is freed), a cached reference is always valid.

---

## SECTION 4 — ARCHITECTURE / DESIGN PROBLEMS

---

### 🔵 ARCH-01 — Every system does `get_node_or_null("/root/...")` everywhere
**Files:** Nearly every .gd file

```gdscript
var sh := get_node_or_null("/root/SkillHandler")
var gs := get_node_or_null("/root/GameState")
var bus := get_node_or_null("/root/EventBus")
```

**Problem:** This pattern appears 50+ times across the codebase. It's a string-based lookup that bypasses type checking. It creates invisible coupling despite claims of "decoupling" — every system knows the string names of every other autoload. If any autoload is renamed, the error is a silent null at runtime, not a compile error. It also makes unit testing nearly impossible without a full fake autoload hierarchy.

**Argument:** Yes, autoloads ARE the GDScript equivalent of singletons, and this is idiomatic Godot. But caching the reference at `_ready()` time (e.g., `@onready var _sh: SkillHandler = get_node("/root/SkillHandler")`) gives you the same semantics with a typed reference and a single lookup.

**Fix:** Cache autoload references at `_ready()` with typed `@onready` vars. This also surfaces missing autoloads at map load rather than silently returning null mid-combat.

---

### 🔵 ARCH-02 — Magic triangle has asymmetric coverage: anima weapons have no internal triangle
**File:** `GameConstants.gd:30–35`

```gdscript
"fire":    {"light": "advantage",  "dark": "disadvantage"},
"thunder": {"light": "advantage",  "dark": "disadvantage"},
"wind":    {"light": "advantage",  "dark": "disadvantage"},
```

**Problem:** Fire, Thunder, and Wind all have identical triangle relationships to Light and Dark but NO relationships to each other. In classic FE magic triangle (Anima > Dark > Light > Anima), or GBA triangle (Anima beats Dark beats Light beats Anima), the three anima types should beat or lose to each other. Currently they're all equal against each other. A thunder mage fighting a fire mage gets no triangle modifier.

This is a design gap, not a code bug. But it means the magic triangle is half-implemented and will silently produce wrong results when fire vs. thunder combat happens.

**Decision:** Anima-vs-anima is neutral by design. Fire, Thunder, and Wind do not have triangle relationships with each other. The current code is correct — add a comment to `GameConstants.gd` explicitly stating this is intentional so future developers do not "fix" it.

---

### 🔵 ARCH-03 — Context dict passes live Node references through skill system
**File:** `CombatResolver.gd`, `SkillHandler.gd`

The `context` dict holds `"attacker"` and `"defender"` as live scene Node references. If either unit is freed mid-combat (double-kill scenario from BUG-01), any code accessing `context["attacker"]` after that point accesses a freed node, which in Godot 4 will raise "Invalid get index 'data' on base 'null instance'" errors.

**Fix:** Defensive `is_instance_valid()` checks before every `context["attacker"].data` access in SkillHandler. Or, restructure context to hold data snapshots rather than Node references.

---

### 🔵 ARCH-04 — `ConditionManager` is registered as autoload but does absolutely nothing
**File:** `ConditionManager.gd`

Five stub methods, all `pass`. This takes up an autoload slot, adds to startup time, and creates the impression that conditions are integrated when they aren't. Until M8, this is dead weight.

**Argument for keeping it:** Signal interfaces are defined; future implementation just fills in the stubs.  
**Argument against:** Any time a developer writes `ConditionManager.has_condition(u, "poison")` expecting real behavior, they get `false` silently — bugs that look like features.

**Fix:** Leave it registered but add a loud `push_warning("ConditionManager: stub — not implemented until M8")` to every method call during development builds.

---

### 🔵 ARCH-05 — `UnitData.inventory` inventory entries use untyped Dicts; no schema enforcement
**File:** `UnitData.gd:35`

```gdscript
@export var inventory: Array[Dictionary] = []
# Weapon entry: { "type":"weapon", "weapon_id":String, "uses_remaining":int, "forged_mods":Dictionary }
# Item entry:   { "type":"item",   "item_id":String,   "uses_remaining":int }
```

**Problem:** Every caller does `entry.get("type", "")`, `entry.get("uses_remaining", 0)`. If a `.tres` file has a typo in the key name (e.g., `"use_remaining"` instead of `"uses_remaining"`), items silently have infinite uses (default 0 returns false → item not usable) or zero uses. No validation anywhere.

**Decision:** Full `InventoryEntry` resource class — migrate now.

**Fix:** Create `scripts/resources/InventoryEntry.gd` as a `Resource` subclass with typed `@export` fields covering both weapon and item cases:
```gdscript
class_name InventoryEntry extends Resource
@export var type: String = ""           # "weapon" | "item" | "equip"
@export var weapon_id: String = ""
@export var item_id: String = ""
@export var uses_remaining: int = 0
@export var forged_mods: Dictionary = {}  # Phase 2 forge system
```
Change `UnitData.inventory` from `Array[Dictionary]` to `Array[InventoryEntry]`. Migrate all existing `.tres` roster and enemy data files. Update every call site that uses `.get("type", "")` etc. to direct property access.

**Pros:** Type safety; editor validates fields at load; typos become load errors not silent wrong behavior; autocomplete in editor and IDE.  
**Cons:** All existing `.tres` files must be re-saved after migration (editor will handle this on open if the script is changed first); every call site needs updating (mechanical find-and-replace).

---

### 🔵 ARCH-06 — `forged_mods` in inventory entries is never read
**File:** `UnitData.gd:34`

```gdscript
# Weapon entry: { ..., "forged_mods":Dictionary }
```

The `forged_mods` key is documented in UnitData, stored in inventory dicts, but never read anywhere in the codebase — not in `compute_damage()`, not in `get_equipped_weapon()`, not in WeaponData. It's dead functionality that looks live. Any `.tres` with forge mods will silently have them ignored.

**Fix:** Either implement forge mods or remove the field from the schema docs.

---

### 🔵 ARCH-07 — `GameState.load_default_roster()` prints to stdout in production
**File:** `GameState.gd:111`

```gdscript
print("GameState: loaded %d roster units" % player_roster.size())
```

`print()` is expensive on some platforms and clutters logs in production. Use `push_warning()` only for unexpected sizes, or wrap in `if OS.is_debug_build():`.

---

### 🔵 ARCH-08 — `EnemyAI._choose_move_tile()` uses O(N×M) loop with magic constant
**File:** `EnemyAI.gd:63`, `EnemyAI.gd:78`

```gdscript
var best_attack_dist: int = 999999
var best_dist: int = 999999
```

The `999999` sentinel is a code smell — it's "infinity" with a specific value that could be exceeded if map dimensions ever reach ~1000×1000 tiles. Use `INF` (cast to int when needed) or `INT_MAX` from a constant.

Also, the O(N×M) loop (move_tiles × all_players) for finding the best attack tile, combined with calling `can_attack_from_tile()` for each pair, means enemy AI scales as O(tiles × units). On a 20×20 map with 10 enemies and 6 players, that's 400 × 6 = 2400 calls per enemy, × 10 enemies = 24,000 calls per phase. For MVP this is fine, but it will become a problem when enemy counts grow.

---

### 🔵 ARCH-09 — `GridManager.get_movement_range()` is O(N²) naive Dijkstra
**File:** `GridManager.gd:183–212`

The frontier is a plain Array with linear scan for minimum:
```gdscript
var best_idx := 0
for i in frontier.size():
    if costs[frontier[i]] < costs[frontier[best_idx]]:
        best_idx = i
frontier.remove_at(best_idx)  # also O(N) shift
```

This is O(N²) where N = reachable tiles. For a unit with movement=5 on a plain map, N ≈ 60 tiles. 60² = 3600 operations. For an enemy phase with 10 enemies each computing movement range + path: 36,000 operations. Fine now, painful at scale.

**Fix:** Use a proper priority queue (min-heap). GDScript doesn't have one built in, but a simple binary heap or sorted insertion into a PackedInt32Array works.

---

### 🔵 ARCH-10 — Skill `effect_params` dictionary is unconstrained and unvalidated
**File:** `SkillData.gd:16`

```gdscript
@export var effect_params: Dictionary = {}
```

Every skill reads from this dict with `.get()` defaults:
```gdscript
skill.effect_params.get("weapon_type", "")  # faire: empty string → applies to all weapon types
skill.effect_params.get("radius", 3)        # charm/anathema/daunt
skill.effect_params.get("bonus", 5)         # faire
```

If a `.tres` is missing `"weapon_type"`, `faire` silently buffs ALL weapon types. If it has `"weapone_type"` (typo), same result. No warning is emitted. DataManager doesn't validate param presence.

**Fix:** Add a `validate()` method to SkillData called by DataManager after loading, which checks that `effect_params` contains all required keys for the given `effect_id`. Emit `push_error()` for missing required params.

---

## SECTION 5 — PENDING FROM EARLIER REVIEWS

Items carried forward from `code_review_2026-05-12.md` and the 2026-05-12b session plans that have no entry above.

---

### 🟠 PEND-01 — `MapData.reward_gold` / `reward_items` never applied on victory
**File:** `scripts/resources/MapData.gd`, `scripts/core/TurnManager.gd`

`MapData` exports `reward_gold: int` and `reward_items: Array`. `TurnManager.check_victory_conditions()` emits `map_victory` but never reads these fields. Gold and item rewards authored in `.tres` files are silently discarded.

**Fix:** Read `_map_data.reward_gold` and `_map_data.reward_items` in `check_victory_conditions()` (or a helper) and write them to `GameState` on `map_victory`.

---

### 🟠 PEND-02 — EnemyAI has no healing branch — healer enemies stand idle
**File:** `scripts/core/EnemyAI.gd`

`_act()` only checks `get_attackable_enemies_from_tile()`. Enemies with only a staff weapon get an empty target list, move toward the nearest player, then do nothing.

**Fix:** After the attack check fails, check if the unit has a staff weapon, call `get_healable_allies()`, and execute a staff heal on the most-injured ally. Mirror `MapCursor._execute_staff_heal()`.

---

### 🟡 PEND-03 — `DataManager._load_directory()` silently skips subdirectories
**File:** `scripts/autoloads/DataManager.gd`

`DirAccess.get_next()` returns both files and directories; there is no `current_is_dir()` check. Subdirectories are silently skipped with no warning — future data reorganisation will fail to load with no error.

**Fix:** Add `if dir.current_is_dir(): continue` or a `push_warning()` when a subdirectory is encountered.

---

### 🟠 PEND-04 — Breaker skill missing dodge side
**File:** `scripts/skills/SkillHandler.gd`

`_apply_breaker()` adds a hit bonus when the opponent wields a matching weapon type. The GDD also specifies +50 dodge vs that weapon type when defending — this half is not implemented because `compute_hit_pct()` has no parameter for a separate defender-dodge bonus.

**Fix:** Add a defender-dodge context entry to `compute_hit_pct()` and wire the breaker dodge bonus through it.

---

### 🟡 PEND-05 — HUD does not show unit info when cursor hovers over an enemy
**File:** `scripts/core/MapCursor.gd`, `scripts/ui/HUD.gd`

Moving the cursor over an enemy unit does not populate the unit info panel. Players cannot see enemy HP, class, or weapon without initiating an attack.

**Fix:** In `_set_tile()` or the cursor-move handler, check if any unit occupies the new tile and emit the HUD update signal for both player and enemy units.

---

### 🟡 PEND-06 — No End Turn confirmation when units have not acted
**File:** `scripts/core/TurnManager.gd`, `scripts/ui/`

Pressing End Turn with READY or MOVED units remaining ends the phase immediately. Players can accidentally skip unacted units.

**Fix:** In the end-turn handler, call `are_all_player_units_done()`. If `false`, show a confirmation dialog before calling `start_enemy_phase()`.

---

### 🟡 PEND-07 — No Settings Screen
**File:** `scripts/ui/` (missing)

The GDD specifies a Settings Screen accessible from Map Menu and Main Menu. No stub or scene exists.

**Fix:** Create a minimal `SettingsScreen.tscn` with volume sliders and combat animation toggle. Wire it from MapMenu and MainMenu.

---

### 🔵 PEND-08 — Boot.gd stale comment
**File:** `scripts/core/Boot.gd:7`

Comment says "MainMenu not yet implemented; change this path once Milestone 5 scene exists." Milestone 5 is complete.

**Fix:** Remove the comment.

---

### 🔵 PEND-09 — ItemMenu lambda comment misleads about Dictionary copy semantics
**File:** `scripts/ui/ItemMenu.gd:37`

Comment says "Capture entry by value so the lambda closes over a copy." GDScript 4 Dictionary assignment is by reference — `captured` IS `entry`. The comment is actively wrong and could cause a future reader to rely on isolation that doesn't exist.

**Fix:** Remove or replace with `# reference to the inventory dict entry`.

---

### 🔵 PEND-10 — Dead zoom stubs in MapCursor
**File:** `scripts/core/MapCursor.gd`

`_handle_zoom()` and `_apply_zoom()` are defined but have no callers. Dead code.

**Fix:** Remove both functions and add a GDD TODO for Phase 2 zoom.

---

### 🔵 PEND-11 — `SettingsManager.save()` ignores write errors
**File:** `scripts/autoloads/SettingsManager.gd`

`cfg.save(SETTINGS_PATH)` return value (`Error`) is discarded. Full disk or sandbox write failures are invisible.

**Fix:**
```gdscript
var err := cfg.save(SETTINGS_PATH)
if err != OK:
    push_error("SettingsManager: failed to save: %s" % error_string(err))
```

---

## SECTION 6 — TEST COVERAGE GAPS

---

### 🟡 TEST-01 — No test for double-kill scenario (BUG-01)
No test verifies what happens when both attacker and defender reach 0 HP. The test suite has basic resolve tests but no mutual-kill coverage.

### 🟡 TEST-02 — No test for Brave weapon follow-up (BUG-02)
No test for `strikes_per_attack > 1` in follow-up exchange.

### 🟡 TEST-03 — No test for Miracle at 1 HP (BUG-03)
`test_combat.gd` doesn't test the Miracle edge case.

### 🟡 TEST-04 — No test for `apply_combat_result` (integration)
Tests verify `resolve_combat()` output dicts but not `apply_combat_result()` side effects (HP deduction, EXP award, weapon durability decrement, death signal).

### 🟡 TEST-05 — No tests for `TurnManager` phase transitions
`start_enemy_phase()`, `start_player_phase()`, victory conditions — all untested.

### 🟡 TEST-06 — No tests for `GameState` snapshot/restore
The retry mechanic is fully untested.

### 🟡 TEST-07 — `preview_combat` test only checks key presence
`test_combat.gd:305–311` only checks `has("attacker_hit")` etc. It doesn't verify the values match `compute_hit_pct()` / `compute_damage()` directly, so preview/resolve discrepancies (like BUG-02) would not be caught.

---

## SUMMARY TABLE

| # | File | Severity | Status | Notes |
|---|------|----------|--------|-------|
| BUG-01 | CombatResolver.gd:459 | 🔴 Critical | ✅ Fixed | Double-kill zombie unit |
| BUG-02 | CombatResolver.gd:417 | 🔴 Critical | ✅ Fixed | Follow-up ignores Brave strikes |
| BUG-03 | SkillHandler.gd:112 | 🔴 Critical | ✅ Fixed | Miracle → guarantee survival (`sim_hp - 1`) |
| BUG-04 | GameState.gd:93 | 🔴 Critical | ⬜ Deferred | DirAccess broken in exports — **use ResourcePreloader node** |
| BUG-05 | TurnManager.gd:111 | 🟠 Serious | ✅ Fixed | Double victory emit |
| BUG-06 | SkillHandler.gd:90 | 🟠 Serious | ✅ Fixed | Resolve → add_modifier() for STR/MAG/SKL/SPD |
| BUG-07 | CombatResolver.gd:330 | 🟠 Serious | ✅ Fixed | Preview snapshot/restore unit state |
| BUG-08 | EnemyAI.gd:89 | 🟠 Serious | ✅ Fixed | AI Dijkstra flood for wall-aware targeting |
| BUG-09 | AttackPreview.gd:22 | 🟠 Serious | ✅ Fixed | Fixed via BUG-07 (preview_combat snapshots) |
| BUG-10 | CombatResolver.gd:443 | 🟠 Serious | ✅ Fixed | EXP only when attacker lands a hit |
| BUG-11 | GameMap.gd:139 | 🟡 Moderate | ✅ Fixed | assert() → push_error() |
| BUG-12 | MapCursor.gd:24 | 🟡 Moderate | ✅ Fixed | String state → State enum |
| BUG-13 | GameState.gd:14 | 🟡 Moderate | ✅ Fixed | player_units/enemy_units privatized |
| BUG-14 | TurnManager.gd:9 | 🟡 Moderate | ✅ Fixed | Erase dead unit from _unit_states on death |
| BUG-15 | ActionMenu.gd:52 | 🟡 Moderate | ✅ Fixed | _btn_wait.disabled = false always |
| BUG-16 | MapCursor.gd:389 | 🟡 Moderate | ⬜ Deferred | Combat anim: "none"=instant; await signal when on |
| BUG-17 | CombatResolver.gd:39 | 🟡 Moderate | ✅ Fixed | Removed dead flags["nihil"] |
| BUG-18 | Unit.gd:419 | 🟡 Moderate | ✅ Fixed | tile_position updated before tween |
| BUG-19 | GameState.gd:17 | 🟡 Moderate | ✅ Fixed | Removed dead selected_unit field |
| BUG-20 | Unit.gd:142 | 🟡 Moderate | ✅ Fixed | GridManager cached on first lookup |
| ARCH-01 | Everywhere | 🔵 Minor | ⬜ Open | get_node_or_null string lookups |
| ARCH-02 | GameConstants.gd:30 | 🔵 Minor | ✅ Fixed | Added comment: anima-vs-anima neutral by design |
| ARCH-03 | CombatResolver.gd | 🔵 Minor | ⬜ Open | Context holds freed Node refs |
| ARCH-04 | ConditionManager.gd | 🔵 Minor | ⬜ Open | Stub autoload, silent failures |
| ARCH-05 | UnitData.gd:35 | 🔵 Minor | ⬜ Deferred | Full InventoryEntry resource class |
| ARCH-06 | UnitData.gd:34 | 🔵 Minor | ✅ Fixed | forged_mods documented as reserved for ARCH-05 |
| ARCH-07 | GameState.gd:111 | 🔵 Minor | ✅ Fixed | Removed print() from production path |
| ARCH-08 | EnemyAI.gd:63 | 🔵 Minor | ✅ Fixed | 999999 → 0x7FFFFFFF |
| ARCH-09 | GridManager.gd:183 | 🔵 Minor | ⬜ Open | O(N²) Dijkstra (acceptable for MVP map sizes) |
| ARCH-10 | SkillData.gd:16 | 🔵 Minor | ⬜ Open | effect_params unvalidated |
| PEND-01 | TurnManager.gd | 🟠 Serious | ✅ Fixed | reward_gold/reward_items applied before map_victory |
| PEND-02 | EnemyAI.gd | 🟠 Serious | ✅ Fixed | _try_staff_heal() branch added |
| PEND-03 | DataManager.gd | 🟡 Moderate | ✅ Fixed | current_is_dir() guard added |
| PEND-04 | SkillHandler.gd | 🟠 Serious | ✅ Fixed | Breaker dodge side wired via def_mod["dodge"] |
| PEND-05 | MapCursor.gd / HUD.gd | 🟡 Moderate | ✅ Fixed | HUD shows unit info for any unit under cursor |
| PEND-06 | TurnManager.gd | 🟡 Moderate | ✅ Fixed | ConfirmationDialog shown when units unacted |
| PEND-07 | scripts/ui/ | 🟡 Moderate | ✅ Fixed | SettingsScreen.gd complete; scene needs editor (GDD_Manual_Tasks) |
| PEND-08 | Boot.gd:7 | 🔵 Minor | ✅ Fixed | Stale comment removed |
| PEND-09 | ItemMenu.gd:37 | 🔵 Minor | ✅ Fixed | Comment corrected |
| PEND-10 | MapCursor.gd | 🔵 Minor | ✅ Fixed | Dead zoom stubs removed |
| PEND-11 | SettingsManager.gd | 🔵 Minor | ✅ Fixed | cfg.save() error checked |

**Commits made this session:**
- `92342bd` — BUG-01, BUG-02, BUG-03, BUG-05 + test_combat mutual-kill and Brave tests
- `6289b21` — BUG-07 (preview snapshot/restore) + BUG-06 (Resolve add_modifier + compute_damage)
- `b98963c` — BUG-08 (AI wall-navigation), BUG-10 (EXP guard), ARCH-08 (sentinel)
- `4655b36` — BUG-11..15, BUG-17, BUG-19, BUG-20, ARCH-02 (moderate batch)
- `fde7145` — BUG-18, ARCH-06, ARCH-07 (tile_position + cleanup)

**Remaining deferred (requires design/editor work):**
- BUG-04: ResourcePreloader node (needs Godot editor to create scene)
- BUG-16: Combat animation wiring (async signal, settings integration)
- ARCH-05: InventoryEntry resource class + migration of all .tres files
