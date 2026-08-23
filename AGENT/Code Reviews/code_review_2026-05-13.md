---
Role: dated
---

# Code Review — 2026-05-13
Reviewer: Claude (full codebase pass on `main` @ commit `b3f416b`)
Scope: All scripts under `scripts/`, all `.tres` resources, and the GDD.
Cross-checked against prior reviews `code_review_2026-05-11.md` and
`code_review_2026-05-12.md`. Findings here are **new** — they were either
introduced after the last review, missed previously, or arose from features
added since.

Severity tiers:
- **CRITICAL** — crashes, data corruption, or a feature is completely broken.
- **HIGH** — feature works but produces wrong gameplay results.
- **MEDIUM** — silent failures, edge-case wrong behaviour, design hazards.
- **LOW** — style / dead comments / minor validations.
- **GDD** — code diverges from the design document (drift, not a runtime fault).

---

## Summary Table

| ID | Severity | File / Subsystem | One-line description |
|----|----------|------------------|----------------------|
| C-1 | CRITICAL | `data/weapons/*.tres` | 4 weapons still use the old `range_min/range_max` int fields — they silently default to 1-1 (Javelin/Thunder/Wind/Elfire/Steel Sword no longer ranged) |
| C-2 | CRITICAL | `MapCursor._apply_item_effect` | Reads non-existent keys `entry["effect"]` / `entry["power"]` on inventory dicts — items are consumed but do nothing |
| H-1 | HIGH | `ItemMenu.show_for`   | Button label reads `entry["name"]`, which doesn't exist — every item button says `"Item (N)"` |
| H-2 | HIGH | `CombatResolver.compute_damage` | Defender DEF/RES read directly from `data`, bypassing `get_effective_stat()` — defender stat modifiers ignored |
| H-3 | HIGH | `CombatResolver._get_effectiveness_multiplier` | Giantkiller bonus keyed on `context["attacker"]`, so a counter-attacker with Giantkiller never gets the 4× multiplier |
| H-4 | HIGH | `WeaponData._stat_value` | Formula stat lookup reads `unit.data.X` raw — active stat modifiers do not affect dynamic weapon range |
| H-5 | HIGH | `EnemyAI._act` (staff branch) | Healer enemies always close on the nearest player first, then only heal if a target happens to be in range — they should pathfind toward injured allies |
| M-1 | MEDIUM | `MapCursor._on_map_menu_closed` | After choosing End Turn (no confirm needed) the cursor is unlocked while the enemy phase is running |
| M-2 | MEDIUM | `MapCursor._set_tile`   | `position = _grid.tile_to_world(...)` is called outside the `_grid != null` guard (M3 from 05-12 review never fixed) |
| M-3 | MEDIUM | `MapCursor._handle_mouse_motion` | Same issue: `_grid.world_to_tile(world)` called without null guard |
| M-4 | MEDIUM | `LevelUpScreen` | Ignores `SettingsManager.level_up_screen` ("auto"/"skip" do nothing) |
| M-5 | MEDIUM | `TurnManager._on_unit_died` | Does not clean `_original_tiles` for the dying unit — slow leak of stale Node refs per kill |
| M-6 | MEDIUM | `EnemyAI._act` | No use of `UnitData.ai_profile` — passive/healer/territorial profiles silently behave as basic |
| M-7 | MEDIUM | `SettingsScreen` | Has no entry point — neither MainMenu nor MapMenu opens it; setting changes mid-game never reach `GameState.permadeath_enabled` until next launch |
| M-8 | MEDIUM | `apply_combat_result` | `combat_resolved` is emitted **after** `handle_death()` queue-frees the loser — listeners that touch the freed node within the same frame need `is_instance_valid` (CombatHUD does; future listeners may forget) |
| L-1 | LOW | `data/maps/map_001_data.tres` | Stale field `required_survivor_names = []` (renamed to `required_survivor_ids` in code) |
| L-2 | LOW | `data/roster/default/*.tres` | All 6 roster files have empty `unit_id` (deferred manual task) |
| L-3 | LOW | `WeaponData.is_natural_weapon` | Docstring claims `Unit.get_equipped_weapon()` auto-returns it when shifted — `Unit.gd` does no such thing |
| L-4 | LOW | `MapData` placement dict | Each entry stores `"is_boss"` and `"required_survivor"` keys that no code reads |
| L-5 | LOW | `UnitData.line_of_sight` / `ClassData.base_line_of_sight` | Declared but never queried — placeholder for fog of war |
| GDD-1 | GDD | `ActionMenu` | GDD lists **Trade** as the 4th action — no implementation or button |
| GDD-2 | GDD | `MapCursor._begin_attack_targeting` / `_begin_staff_targeting` | GDD specifies a **Target Select List** UI (sortable, in-panel) — implementation uses cursor snap only |
| GDD-3 | GDD | `MapCursor._execute_staff_heal` | GDD specifies a staff *preview* ("Heal: +17 HP") — implementation heals immediately on confirm |
| GDD-4 | GDD | `Unit.level_up` | Three of four leveling methods (point_buy / coin_flip / dice) still produce a warning, not an implementation |
| GDD-5 | GDD | `e7_knight_sub.tres` | Placement dict still has `is_boss: false` though GDD calls it a "sub-boss" |

---

## Locked Decisions (2026-05-13 session)

| ID | Decision |
|----|----------|
| C-1 | Add a `tools/validate_resources.gd` script, invoked from `run_tests.sh`. Walks every `.tres` and compares declared keys against the script's exported properties. |
| C-2 | Build a new `ItemHandler` autoload mirroring `SkillHandler`. Move item-effect logic out of `MapCursor`. |
| H-5 | Healer enemies use a "greedy + retreat bias" heal AI: pick the move tile that puts the lowest-HP ally in heal range; tie-break by terrain DEF/Dodge bonus. |
| L-4 | Keep top-level `required_survivor_ids`. Drop the per-placement `required_survivor` bool from the doc-comment and from any enemy placement dicts. |
| GDD-1 | Trade button slots between Item and Wait. Final order: **Attack / Staff / Item / Trade / Wait** (matches the current GDD). |
| GDD-4 | Replace the four-method leveling system with two: `growth_fixed` (deterministic accumulator) and `growth_random` (existing roll, with `rate > 100` handling). Default `growth_random`. Remove Point Buy, Coin Flip, and Dice from code and GDD. |

---

## CRITICAL

### C-1. Four weapon `.tres` files use the deprecated `range_min` / `range_max` int fields
**Files:** `data/weapons/javelin.tres`, `steel_sword.tres`, `thunder.tres`, `wind.tres`

**Diff vs current `WeaponData.gd`:** The schema was migrated from `range_min:int` / `range_max:int` to `range_min_formula:String` / `range_max_formula:String` (commit `d4e77d0`). The migration updated six of ten weapon resources; the four listed above still write the old int fields. Godot 4 silently ignores unknown resource fields, so the int values are dropped at load and the new formula strings fall back to their default `"1"` / `"1"`.

**Effect in the game:**
- **Javelin** — should be melee/ranged (1–2). Now 1-only. Cavaliers / soldier with javelin become melee-only. Affects player roster (`unit_06_knight` carries no javelin, but any future deploy with one will misbehave) and enemy `e7_knight_sub`/`e8_knight_boss` would be similarly affected if they ever wielded one.
- **Thunder / Wind** — both are 1–2 anima tomes in GDD_04. Now 1-only. Mage and any future tome user can't fire at range.
- **Steel Sword** — design range is 1–1, so the live effect is the same. Still a data hazard: anyone editing the file thinks they're authoring a working 1-1 weapon when the field is silently dead.

**Why the test suite missed it:** `test_data_layer.gd` only verifies that resources load and that `id` matches the filename. Neither it nor `test_combat.gd` asserts that the loaded `range_max_formula` resolves to the intended value (`test_combat.gd` builds weapons via a factory rather than loading the `.tres`).

**Recommended fix:** Replace the integer assignments with formula strings:
```
range_min_formula = "1"
range_max_formula = "2"
```
Add a regression test that loads each weapon `.tres` and asserts `weapon.get_range_max(null)` matches the expected value.

**Decision needed: should the loader warn when an unknown field is encountered?** Godot does not surface this by default.
| Option | Pros | Cons |
|--------|------|------|
| Tighten `DataManager._load_directory` to read the raw `ConfigFile`-style text and `push_warning` on unknown keys | Catches future stale-field bugs at startup | Re-parses every `.tres` — adds I/O at boot; brittle if Godot's tres format changes |
| Add an "expected fields" allowlist to each Resource class and let an editor tool / test validate it | Cleanly enforced via tests, no runtime cost | Up-front work; needs maintenance when adding new fields |
| Do nothing; rely on reviewers to spot mismatches | Zero cost | This bug shipped — clearly insufficient |

Recommendation: add a `tools/validate_resources.gd` script invoked from `run_tests.sh` that walks every `.tres` and compares declared keys against the script's exported properties. Cheapest, easiest to maintain, fits the existing test-driven workflow.

**Decision locked:** resource validator script in `tools/`, invoked from `run_tests.sh`.

---

### C-2. Item effects never fire — `_apply_item_effect` reads keys that aren't on the inventory dict
**File:** `scripts/core/MapCursor.gd:469-479`

```gdscript
func _apply_item_effect(entry: Dictionary) -> void:
    ...
    var power: int = entry.get("power", 20)
    match entry.get("effect", ""):
        "heal_flat":
            _selected_unit.heal(power)
        "heal_full":
            _selected_unit.heal(_selected_unit.data.max_hp)
    entry["uses_remaining"] -= 1
```

`UnitData.inventory` entries have this shape (per the doc-comment at `UnitData.gd:34`):
```gdscript
{ "type": "item", "item_id": String, "uses_remaining": int }
```

`entry.get("effect", "")` therefore always resolves to `""`, the `match` falls through, **no healing happens**, and `uses_remaining` is decremented anyway. The player burns a Vulnerary / Elixir charge for nothing.

**Why it's a problem:** Items are entirely broken. Worst, the use count drops, so the player can tell something happened but the HP didn't move — extremely confusing.

**Recommended fix:** look the item up in `DataManager` and read its real effect:
```gdscript
func _apply_item_effect(entry: Dictionary) -> void:
    if _selected_unit == null or _selected_unit.data == null:
        return
    var item_id: String = entry.get("item_id", "")
    var item: ItemData = DataManager.get_item(item_id) if item_id != "" else null
    if item == null:
        return
    var power: int = int(item.effect_params.get("amount", 0))
    match item.effect_id:
        "heal_flat": _selected_unit.heal(power)
        "heal_full": _selected_unit.heal(_selected_unit.data.max_hp)
        _: push_warning("Unknown item effect_id '%s'" % item.effect_id)
    entry["uses_remaining"] -= 1
    if entry["uses_remaining"] <= 0:
        _selected_unit.data.inventory.erase(entry)
```

**Decision needed: where should item effects live?**
| Option | Pros | Cons |
|--------|------|------|
| Inline the match in `MapCursor` (above) | Smallest diff; matches existing pattern for staves | Couples UI code to item logic; every new item type touches MapCursor |
| Build an `ItemHandler` autoload mirroring `SkillHandler` | Items become data-driven and reusable from AI/scripts | Adds an autoload; small upfront refactor |
| Move item logic into `Unit.use_item(entry)` | Co-located with the unit's HP/HUD code | Unit gains a UI-ish responsibility |

Recommendation: **build `ItemHandler`** — keeps Unit/MapCursor lean and gives a single place to wire animations, sounds, and future items (Pure Water, Antitoxin, Energy Drop). The autoload list is short already; one more is cheap.

**Decision locked:** new `ItemHandler` autoload, registered after `SkillHandler` in `project.godot`. `MapCursor._apply_item_effect` becomes a one-line dispatch into it.

---

## HIGH

### H-1. Item buttons show "Item (N)" instead of the item's name
**File:** `scripts/ui/ItemMenu.gd:34`

```gdscript
btn.text = "%s  (%d)" % [entry.get("name", "Item"), uses]
```

Inventory entries do not contain a `"name"` key (see C-2 for the actual shape). The fallback `"Item"` is therefore used for every entry. Players can't tell their items apart.

**Recommended fix:** look up the display name via `DataManager.get_item(entry["item_id"]).display_name`:
```gdscript
var item_id: String = entry.get("item_id", "")
var item := DataManager.get_item(item_id) if item_id != "" else null
var name_text := item.display_name if item else "Item"
btn.text = "%s  (%d)" % [name_text, uses]
```

---

### H-2. `compute_damage` ignores defender stat modifiers
**File:** `scripts/core/CombatResolver.gd:193`

```gdscript
var def_stat: int = defender.data.resistance if w.uses_mag else defender.data.defense
```

This reads the raw resource field. Everywhere else in the file the attacker reads via `attacker.get_effective_stat(...)` so that `data.active_modifiers` are honoured. A defender benefits from `+def` (e.g. a fort terrain tile is already covered via `defender.get_terrain_def_bonus()`, but skill-applied or item-applied DEF buffs are not) — those modifiers vanish from the damage formula.

**Effect in the game:** Any future skill that grants `+def` / `+res` to the defender (e.g. Pavise, Aegis, Tower Shield, a planned Bond skill, an Energy Ring-style item) will fail. Right now no shipped skill writes def/res modifiers, but the next one will.

**Recommended fix:**
```gdscript
var def_stat: int = defender.get_effective_stat("resistance") if w.uses_mag \
                  else defender.get_effective_stat("defense")
```
Add a regression test: defender with `{"stat":"defense","delta":3,...}` takes 3 less damage from a physical hit.

---

### H-3. Giantkiller bonus only applies when the original attacker wields it
**File:** `scripts/core/CombatResolver.gd:145-154`

```gdscript
func _get_effectiveness_multiplier(weapon, target, context) -> float:
    ...
    var attacker: Node = context["attacker"]
    if attacker.has_skill("giantkiller"):
        return 4.0
    return 3.0
```

When called inside `_resolve_single_attack` for a counter-attack (`is_counter=true`), `actor` is the defender, but this function still looks up `context["attacker"]`. A defender with Giantkiller wielding an effective weapon never gets the 4× multiplier.

**Recommended fix:** thread the active actor through:
```gdscript
func _get_effectiveness_multiplier(weapon, target, context, actor: Node) -> float:
    ...
    if actor != null and actor.has_method("has_skill") and actor.has_skill("giantkiller"):
        return 4.0
    return 3.0
```
…and pass `actor` from `_resolve_single_attack` and `preview_combat`.

---

### H-4. Dynamic weapon range ignores stat modifiers
**File:** `scripts/resources/WeaponData.gd:66-78`

```gdscript
static func _stat_value(stat_name: String, unit: Node) -> int:
    ...
    match stat_name:
        "MAG": return unit.data.magic
        ...
```

If a future Physic staff has `range_max_formula = "MAG/2"` and the cleric has a `+5 magic` modifier active, the range is computed off the raw `data.magic` and the buff is ignored. The combat damage formulas already honour modifiers via `get_effective_stat` — range should match.

**Recommended fix:** call `unit.get_effective_stat(snake_case_name)` instead of `unit.data.<name>`:
```gdscript
static func _stat_value(stat_name: String, unit: Node) -> int:
    if unit == null or not unit.has_method("get_effective_stat"):
        return 0
    match stat_name:
        "MAG": return unit.get_effective_stat("magic")
        ...
```

(Test units in `test_combat.gd` already implement `get_effective_stat`, so this is a one-liner update.)

---

### H-5. Healer enemies path toward players, not toward injured allies
**File:** `scripts/core/EnemyAI.gd:31, 92-113`

`_act` does:
1. find nearest player; pick best move tile via `_choose_move_tile` (which only considers attack reach or distance to that player);
2. after moving, if the equipped weapon is a staff, heal whoever is in range.

A cleric enemy whose only weapon is a staff has *zero* attackable enemies from any tile, so step 1 falls through to "move closer to nearest player". The staff heal in step 3 then checks targets from the new (front-line) position — usually after the unit has walked **toward** the player frontline and **away** from injured allies.

**Effect in the game:** Healer enemies behave like reckless melee. Boss compositions with a flanking healer (per GDD_08) won't function.

**Recommended fix:** branch on weapon type before picking the move:
```gdscript
var weapon := enemy.get_equipped_weapon()
if weapon != null and weapon.weapon_type == "staff":
    var best := _choose_heal_move_tile(enemy, move_tiles, grid)
    ... # move there, then heal
    return
# else: existing attack logic
```
`_choose_heal_move_tile` should pick the tile that maximises reachable injured allies (or minimises distance to the most-injured ally) and tie-break by terrain DEF/Dodge bonus.

**Decision needed: how smart should the heal AI be?**
| Option | Pros | Cons |
|--------|------|------|
| Greedy: pick tile that puts the lowest-HP ally in range, ignore self-safety | Trivial implementation | Healer easily kited; player will exploit this |
| Greedy + retreat bias: prefer fort/forest tiles when multiple options heal the same target | Matches GDD_08's profile sketch | More tuning needed; still doesn't position prophylactically |
| Predictive: stand within 2 tiles of allies who would be in danger next player phase | Best-feeling AI | Requires danger-zone lookahead — sizeable engine work |

Recommendation: **Greedy + retreat bias**. Aligns with GDD_08, small code, leaves headroom for predictive later.

**Decision locked:** greedy + retreat bias. Pick the move tile that places the lowest-HP ally in heal range; tie-break by `TERRAIN_DEF_BONUS + TERRAIN_DODGE_BONUS` of the candidate tile.

---

## MEDIUM

### M-1. Cursor unlocks during the enemy phase when End Turn is selected and all units are already done
**File:** `scripts/ui/MapMenu.gd:32-35`, `scripts/core/MapCursor.gd:540-566`

```gdscript
# MapMenu
func _on_end_turn() -> void:
    hide()
    end_turn_requested.emit()
    menu_closed.emit()
```

Both signals fire synchronously. In `MapCursor`:
1. `_on_end_turn_requested` → `_turn.are_all_player_units_done()` is true → `_turn.end_player_phase()` runs synchronously up to the first `await` inside `start_enemy_phase`. By that point `set_phase(ENEMY)` has fired, so `_on_phase_changed(1)` ran and the cursor is `LOCKED`.
2. Control returns to MapMenu, which emits `menu_closed`.
3. `_on_map_menu_closed` checks `_awaiting_end_turn_confirm` (false because we never opened the confirm dialog) and calls `unlock()`.
4. Cursor is now `FREE` while AI is still running its phase.

The bug doesn't bite when the confirm dialog path is taken because `_awaiting_end_turn_confirm` is set to `true` before the dialog opens.

**Recommended fix:** check the phase instead of (or in addition to) the confirm flag:
```gdscript
func _on_map_menu_closed() -> void:
    if _awaiting_end_turn_confirm:
        return
    var gs := get_node_or_null("/root/GameState")
    if gs and not gs.is_player_turn():
        return  # phase listener will handle locking/unlocking
    unlock()
```

A second option: have `MapMenu` not emit `menu_closed` when it emits `end_turn_requested` — End Turn is its own terminal action.

---

### M-2 & M-3. Two `_grid` null dereferences in MapCursor
**Files:** `scripts/core/MapCursor.gd:199`, `scripts/core/MapCursor.gd:174-175`

`_set_tile`:
```gdscript
if _grid != null:
    tile.x = clamp(tile.x, 0, _grid.map_width - 1)
    tile.y = clamp(tile.y, 0, _grid.map_height - 1)
if tile == current_tile:
    return
current_tile = tile
position = _grid.tile_to_world(current_tile)   # ← unguarded
```

`_handle_mouse_motion`:
```gdscript
var world := get_viewport().canvas_transform.affine_inverse() * event.position
var tile := _grid.world_to_tile(world)         # ← unguarded
```

The 05-12 review's M3 flagged the first one; the fix never landed. The mouse-motion path has the same shape. Either crashes if input fires before `setup()` (unlikely in normal flow, but easy to hit in `--script` test runs).

**Recommended fix:** make the operations contingent on `_grid`:
```gdscript
if _grid != null:
    tile.x = clamp(tile.x, 0, _grid.map_width - 1)
    tile.y = clamp(tile.y, 0, _grid.map_height - 1)
    if tile == current_tile:
        return
    current_tile = tile
    position = _grid.tile_to_world(current_tile)
    _scroll_camera_if_needed()
```

---

### M-4. `LevelUpScreen` ignores `SettingsManager.level_up_screen`
**File:** `scripts/ui/LevelUpScreen.gd`

The setting has three states (`"show" | "auto" | "skip"`) and three documented behaviours. The screen always shows and always waits for input. Players who select Auto or Skip see no effect.

**Recommended fix:**
```gdscript
func _on_unit_leveled_up(unit, increases) -> void:
    if not ("team" in unit) or unit.team != "player":
        return
    match SettingsManager.level_up_screen:
        "skip":
            return
        "auto":
            _queue.append({"unit": unit, "increases": increases})
            if not visible:
                _show_next()
                # auto-dismiss after 1.5s
                await get_tree().create_timer(1.5).timeout
                hide(); _show_next()
        _:
            _queue.append({"unit": unit, "increases": increases})
            if not visible:
                _show_next()
```

---

### M-5. Dead units leak in `TurnManager._original_tiles`
**File:** `scripts/core/TurnManager.gd:210-212`

```gdscript
func _on_unit_died(unit: Node) -> void:
    _unit_states.erase(unit)
    check_victory_conditions()
```

`_original_tiles[unit]` is never erased. After several hundred kills the dictionary grows unboundedly with freed Node keys. Godot's Dictionary handles freed-object keys gracefully (they remain reachable via key iteration as `null`), but it's still a leak — and a freed-key iteration could surprise a future feature that walks the map.

**Recommended fix:** `_original_tiles.erase(unit)` alongside `_unit_states.erase(unit)`.

---

### M-6. `UnitData.ai_profile` is set but never consulted
**File:** `scripts/core/EnemyAI.gd`, `scripts/resources/UnitData.gd:47`

Every enemy resource carries an `ai_profile` ("basic" / "passive" / "healer" / "territorial" per the doc-comment), and `GameMap._spawn_units()` already copies the placement's profile into the data. `EnemyAI._act` never reads it. Passive enemies (per GDD_08) should hold position until attacked; right now they charge.

**Recommended fix:** add a branch at the top of `_act`:
```gdscript
match enemy.data.ai_profile:
    "passive":   _act_passive(enemy, grid, turn); return
    "healer":    _act_healer(enemy, grid, turn); return
    _:           pass  # fall through to basic
```

This pairs naturally with the H-5 fix (the `"healer"` branch becomes the dedicated heal pathing).

---

### M-7. `SettingsScreen` has no entry point
**Files:** `scripts/ui/MainMenu.gd`, `scripts/ui/MapMenu.gd`, `scripts/ui/SettingsScreen.gd`

`SettingsScreen.tscn`/`.gd` exist and look functional, but no scene instantiates them. Both MainMenu and MapMenu say "Settings placeholder for Phase 3" in comments. The screen also writes `SettingsManager.permadeath` immediately but `GameState.permadeath_enabled` only re-reads `SettingsManager.permadeath` in `_ready()` — mid-game changes don't take effect.

**Recommended fixes (both should land together):**
1. Add a "Settings" button to `MainMenu.tscn` and a "Settings" entry to `MapMenu.tscn`; show `SettingsScreen` from each (pause map when opened from MapMenu).
2. Have `SettingsManager` emit a `setting_changed(key, value)` signal; have `GameState` listen and update `permadeath_enabled` / `leveling_method` live.

---

### M-8. `combat_resolved` is emitted after deaths — be deliberate about listener ordering
**File:** `scripts/core/CombatResolver.gd:528-534`

```gdscript
if result["defender_died"]:
    defender.handle_death()       # → queue_free()
if result["attacker_died"]:
    attacker.handle_death()
if bus:
    bus.combat_resolved.emit(attacker, defender, result)
```

Within the frame this is safe (`queue_free` is deferred), but anything that listens to `combat_resolved` and stores references for a later frame must guard with `is_instance_valid`. Only `CombatHUD` listens today and it does guard. Worth documenting the contract on the signal in `EventBus.gd`.

**Recommended fix:** add a doc comment on the signal:
```gdscript
# combat_resolved(attacker, defender, result)
# Emitted AFTER handle_death() has been called on the loser(s). Listeners
# MUST use is_instance_valid() before dereferencing attacker/defender across
# frames; both are valid only until end-of-frame queue_free runs.
signal combat_resolved(attacker: Node, defender: Node, result: Dictionary)
```

---

## LOW

### L-1. `map_001_data.tres` has stale `required_survivor_names = []`
**File:** `data/maps/map_001_rout/map_001_data.tres:24`

`MapData.gd` renamed the field to `required_survivor_ids`. Godot silently drops the unknown key, so functionally it doesn't matter (both default to `[]`), but the file is now misleading. Strip it.

---

### L-2. All six roster `.tres` files have an empty `unit_id`
**Files:** `data/roster/default/unit_0[1-6]_*.tres`

`UnitData.unit_id` was added so `TurnManager.required_survivor_ids` could match by id rather than the human-readable `unit_name`. Roster files have not been updated. No map currently uses `required_survivor_ids`, so this is dormant — but the moment a story map needs a "Don't let Marth die" rule, it will silently never fire.

**Fix:** open each `.tres` in the editor (or hand-edit) and set `unit_id = "unit_01"` etc. The session notes already list this as a pending manual task.

---

### L-3. `WeaponData.is_natural_weapon` doc-comment is wrong
**File:** `scripts/resources/WeaponData.gd:38-39`

> "Unit.get_equipped_weapon() returns this automatically when unit.data.is_shifted = true."

`Unit.get_equipped_weapon()` does no `is_shifted` check (`scripts/units/Unit.gd:80-103`). Either update the comment to "[DEFERRED — Laguz]" or implement the lookup behind `if data.is_shifted` to keep parity with `has_quality`.

---

### L-4. `MapData` placement dict keys `is_boss` and `required_survivor` are never read
**File:** `scripts/resources/MapData.gd:13`

The doc-comment promises both fields. `is_boss` should drive UI (boss music, "Boss" tag on the HUD, anti-flee AI). `required_survivor` is redundant with the top-level `required_survivor_ids` array. Pick one and remove the other.

**Decision needed: per-placement or top-level survivor list?**
| Option | Pros | Cons |
|--------|------|------|
| Keep per-placement `required_survivor: bool` on each enemy entry | Co-locates objective data with the unit | "Survivor" applies to *player* units; the placement list is enemies — semantic mismatch |
| Keep top-level `required_survivor_ids: Array[String]` (current) | Cleanly references player roster `unit_id`s; what `check_victory_conditions` already uses | Need to delete the doc-comment claim about per-placement |

Recommendation: **drop `required_survivor` from the placement dict** (it's a leftover); document `required_survivor_ids` as the only source.

**Decision locked:** keep top-level `required_survivor_ids`; remove the per-placement key from the `MapData` doc-comment and from any enemy placement dicts that include it.

---

### L-5. `line_of_sight` is exported on `UnitData` and `ClassData` but never queried
**Files:** `scripts/resources/UnitData.gd:24`, `scripts/resources/ClassData.gd:18`

Reserved for fog-of-war / scouting in Phase 2. No-op today; flag if Phase 2 is moved out further or cut from scope.

---

## GDD — Documentation vs Implementation

### GDD-1. Trade action not implemented
**GDD ref:** `GDD_07_UI_UX.md:198-212` lists Trade alongside Attack / Staff / Item / Wait. `ActionMenu.gd` has no Trade button.

**Why it matters:** Trade is a core FE feature (handing items between adjacent allies). Without it, players can't pre-position healing items.

**Recommended fix:** add a `Trade` button to `ActionMenu` that enables when an adjacent ally exists. Triggers a `TradeScreen` showing both inventories side-by-side; allow item moves. Logic is straightforward — inventory swap with `data.inventory.remove_at` / `data.inventory.append`.

**Decision needed: which side of Wait should Trade sit?**
| Option | Pros | Cons |
|--------|------|------|
| Match GDD ordering: Attack / Staff / Item / **Trade** / Wait | Reads natural; Wait is the terminator | Adds a button between two semantically-grouped actions |
| Use FE-canonical ordering: Attack / Staff / Trade / Item / Wait | Familiar to FE players | Differs from GDD; would need a GDD update too |

Recommendation: stick with the GDD ordering, update only the implementation.

**Decision locked:** GDD ordering — **Attack / Staff / Item / Trade / Wait**. No GDD changes needed for this item.

---

### GDD-2. No Target Select List UI
**GDD ref:** `GDD_07_UI_UX.md:224-244`

Player picks targets by moving the cursor onto an enemy tile (or, for staves, an ally tile). The GDD specifies a sortable panel that shows target name, class, HP, and live-updated combat preview. Functional gap, not a bug.

**Recommended fix:** add a `TargetSelectList.tscn` UI used in both attack and staff modes; replace the current `_attack_tiles` / `_heal_tiles` snap-to-cursor logic with list nav (cursor still snaps when selection moves).

---

### GDD-3. Staff use has no preview
**GDD ref:** `GDD_07_UI_UX.md:278-287`

GDD says staves should show "Heal: +17 HP" preview before confirm. `_execute_staff_heal` applies the heal immediately on confirm. Player has no information before committing.

**Recommended fix:** intermediate `STAFF_PREVIEW` state mirroring `PREVIEWING` for attacks. Reuse `AttackPreview.tscn` (rename to `ActionPreview`) or add a `StaffPreview.tscn`.

---

### GDD-4. Replace the four-method leveling system with two — `growth_fixed` and `growth_random`
**GDD ref:** `GDD_02_Core_Mechanics.md:264-274` (Leveling Methods table)

The original GDD listed Point Buy / Coin Flip / Dice Roll / Growth Rates. Only Growth Rates is implemented; the other three `push_warning` and fall back. Rather than implement methods nobody is going to use, the decision is to **collapse to two well-defined methods, both based on the existing `growth_rates` dictionary on `ClassData`**.

**Decision locked:**

- **`growth_random`** (default, matches current behaviour with a fix for `rate > 100`):
  ```gdscript
  for stat in _GROWTH_STATS:
      var rate: int = int(rates.get(stat, 0))
      var guaranteed: int = rate / 100
      var remainder: int = rate % 100
      var gain: int = guaranteed
      if (randi() % 100) < remainder:
          gain += 1
      if gain > 0:
          for _i in gain:
              _increment_stat(stat)
          changes[stat] = gain
  ```
  Example: rate 150 → +1 guaranteed, 50% chance of +1 more (final gain 1 or 2). Rate 230 → +2 guaranteed, 30% of +3.

- **`growth_fixed`** (deterministic, with carry):
  Add a new `growth_accumulators: Dictionary` field to `UnitData` (default `{}`). On level-up:
  ```gdscript
  for stat in _GROWTH_STATS:
      var rate: int = int(rates.get(stat, 0))
      var acc: int = int(data.growth_accumulators.get(stat, 0)) + rate
      var gain: int = acc / 100
      data.growth_accumulators[stat] = acc % 100  # carry persists
      if gain > 0:
          for _i in gain:
              _increment_stat(stat)
          changes[stat] = gain
  ```
  Example: rate 50 → +1 every 2 levels exactly. Rate 75 → +1 first level (carry 75), +1 second level (carry 50), +1 third level (carry 25), +1 fifth level (carry 0). Rate 150 → +1 guaranteed each level, plus an extra +1 every other level (carry rolls over).

**Cleanup checklist for the implementer:**
1. Remove `point_buy`, `coin_flip`, `dice` from `SettingsManager.leveling_method` docstring and `reset_section_to_defaults`.
2. Update the default in `SettingsManager` (`var leveling_method: String = "growth_random"`).
3. Update `GameState.leveling_method` initialiser accordingly.
4. Add `growth_accumulators: Dictionary = {}` to `UnitData`; include it in `_snapshot_unit_data` / `_restore_unit_data` so Retry restores carry.
5. Rewrite `Unit.level_up()` to branch on `gs.leveling_method` (`growth_fixed` vs `growth_random`); remove the `push_warning` fallback.
6. Update `GDD_02_Core_Mechanics.md` leveling-methods table to list only the two methods with formulas above.
7. When `SettingsScreen` is wired (M-7), expose only "Random" / "Fixed" radio options.
8. Add unit tests for both paths in `test_unit_stats.gd` (carry persists across calls; rate > 100 yields guaranteed gain).

---

### GDD-5. `e7_knight_sub.tres` placement says `is_boss = false`
**File:** `data/maps/map_001_rout/map_001_data.tres:17`
**GDD ref:** `GDD_06_Maps_Objectives.md` describes E7 as "Sub-boss on Fort".

When boss behaviour lands (anti-flee, distinct music, victory-condition tagging) E7 will be treated as a generic enemy. Either rename the placement key, accept the design (sub-boss = generic with extra stats), or set `is_boss = true` and use a different flag for "true boss".

Recommendation: keep `is_boss` for the chapter-final unit (E8) only; if "sub-boss" needs distinct behaviour later, add a `boss_tier: int` field.

---

## Already-fixed since 05-12 (verified during this pass)

These items from `code_review_2026-05-12.md` and `_2026-05-11.md` are now resolved; listed for the audit trail:

- C1 / C2 / C3 / C4 / C5 — fixed.
- H1 / H2 / H3 / H4 / H5 / H6 / H7 — fixed (H7 wired in `TurnManager._apply_victory_rewards`).
- M1 / M4 / M6 / M7 / M9 (basic heal branch) / M10 — fixed.
- L1 (Boot.gd stale comment) — removed.
- L2 (ItemMenu lambda comment) — corrected.
- L3 (zoom dead code) — removed.
- L4 (SettingsManager save error handling) — fixed.
- BUG-01 / BUG-04 / BUG-05 / BUG-06 — fixed.
- DESIGN-01 / DESIGN-03 / DESIGN-04 / DESIGN-05 / DESIGN-06 — fixed.
- A2 / A4 modifier and movement hooks — wired (contrary to the still-open list in `2026-05-12b.md`; verify by running a session that ticks a modifier through `start_player_phase` and confirming the duration counts down).

Session-notes manual task `ConditionManager autoload` — **done** in `project.godot` (autoload list, line 26).
Session-notes manual task `unit_id` on roster — **still pending** (see L-2).

---

## Suggested ordering for next session

1. **C-1** + **C-2** + **H-1** — three small fixes that unblock items and ranged weapons.
2. **H-2** + **H-3** + **H-4** — three combat-formula correctness fixes; pair each with a unit test.
3. **M-1** — cursor lock during enemy phase (one-line fix once the decision is made).
4. **M-2** / **M-3** — null guards (trivial).
5. Add the resource-field validator from C-1's decision (catches future drift).
6. Defer H-5 + M-6 to a single AI session.

---

End of review.
