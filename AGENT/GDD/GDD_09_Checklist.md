# GDD_09 — Master Implementation Checklist

---

## How to Use This Document

Work through milestones in order. Each milestone produces a **testable build**.
Do not start a new milestone until all tasks in the current one are passing their
test criteria. Tasks marked `[PLACEHOLDER]` require art or audio assets and can be
skipped with a colored rectangle or silent placeholder until assets are ready.

Check boxes use GitHub markdown: `- [ ]` incomplete, `- [x]` complete.

---

## Status Snapshot (last updated 2026-05-21)

| Milestone | Status | Notes |
|---|---|---|
| M0 — Project Setup | ✅ Complete | project.godot, 10 autoloads, folder structure, .gitignore |
| M1 — Data Layer | ✅ Complete | 7 Resource classes, 46 .tres files; A1 fields folded in |
| M2 — Grid and Map Rendering | ✅ Complete | TileSets, GridManager, MapCursor, GameMap; A4 hooks done |
| M3 — Units and Turn Structure | ✅ Complete | Unit.gd, Unit.tscn, GameMap, TurnManager, MapCursor; A2 done |
| M4 — Combat System | ✅ Complete | CombatResolver two-phase pipeline, SkillHandler, EXP, Brave weapons; A3 done |
| M5 — HUD and UI | ✅ Complete | HUD, PhaseBanner, MapMenu, ActionMenu, ItemMenu, AttackPreview, CombatHUD, LevelUp, GameOver, MainMenu, NewGameScreen, SettingsScreen |
| M6 — Enemy AI | ✅ Basic complete | basic / passive / healer profiles; kill-score heuristic deferred to Phase 2 |
| M7 — Full MVP Playthrough | ⏳ In progress | playtest 1 done — 13 findings fixed (+ a ripple audit, 6 more); re-playtest pending |

**Tests:** 586 passing across 26 suites (`scripts/tests/test_*.gd`). Run `bash run_tests.sh`.

> **Amendments folded in.** The MVP amendments A1–A4 (Phase-2 data fields +
> `ConditionManager`; modifier hooks; the combat context pipeline; grid skill-hook
> stubs) are all **complete** and have been merged into GDD_01–GDD_08 — they are no
> longer tracked as separate "amendments". Phase 2 milestones M8–M16 now live in
> `GDD_10_Roadmap.md`.
>
> The per-task checkboxes in the milestone sections below are a **historical build
> record**. M0–M6 are complete per the table above and the resynced GDD_01–GDD_08
> are authoritative for current behaviour, even where individual boxes are still
> shown unchecked.
>
> **Content Expansion supplements** (`GDD/Content Expansion/`) were reviewed against
> the implementation: dynamic range formulas, Faire/Breaker hooks, and Brave-weapon
> multi-strike are implemented; aura skills (Charm/Anathema/Daunt) and Laguz content
> remain deferred (see `Unit.has_quality()`'s DEFERRED comment).

---

## Milestone 0 — Project Setup

**Goal:** Empty Godot project with correct structure, settings, and version control.
**Test:** Project opens without errors. All folders exist. Input actions are registered.

### Environment
- [ ] Install Godot 4 (latest stable release)
- [ ] Create new Godot project named `[PROJECT_NAME]`
- [ ] Initialize a Git repository in the project folder
- [ ] Create a `.gitignore` for Godot projects (ignore `.godot/`, `*.uid` if desired)
- [ ] Create initial commit: "Initial project setup"
- [ ] Create a public GitHub repository and push

### Folder Structure
- [ ] Create `assets/sprites/units/` — add one 64×64 colored rectangle as placeholder unit sprite
- [ ] Create `assets/sprites/terrain/` — add placeholder tile sprites (8 solid colors, one per terrain type)
- [ ] Create `assets/sprites/ui/` — add placeholder panel texture (simple 9-patch or solid rect)
- [ ] Create `assets/sprites/cursor/` — add placeholder cursor sprite (white square outline, 64×64)
- [ ] Create `assets/fonts/` — [PLACEHOLDER] add a pixel font or leave empty (Godot default font is acceptable for MVP)
- [ ] Create `assets/audio/music/` and `assets/audio/sfx/` — leave empty for MVP
- [ ] Create `data/classes/`
- [ ] Create `data/weapons/`
- [ ] Create `data/items/`
- [ ] Create `data/skills/`
- [ ] Create `data/maps/map_001_rout/`
- [ ] Create `scenes/core/`
- [ ] Create `scenes/units/`
- [ ] Create `scenes/ui/`
- [ ] Create `scripts/autoloads/`
- [ ] Create `scripts/resources/`
- [ ] Create `scripts/core/` (also holds `EnemyAI.gd` — there is no `scripts/ai/`)
- [ ] Create `scripts/units/`
- [ ] Create `scripts/skills/`
- [ ] Create `scripts/items/`
- [ ] Create `scripts/shared/`
- [ ] Create `scripts/ui/`
- [ ] Create `scripts/tests/` and `scripts/tools/`

### Project Settings
- [ ] Set `Display/Window/Size/Viewport Width` to `1280`
- [ ] Set `Display/Window/Size/Viewport Height` to `720`
- [ ] Set `Display/Window/Stretch/Mode` to `canvas_items`
- [ ] Set `Display/Window/Stretch/Aspect` to `keep`
- [ ] Enable `Rendering/2D/Snap/Snap 2D Vertices To Pixel`
- [ ] Set project name and icon [PLACEHOLDER]

### Audio Bus Setup (Project → Audio)
- [ ] Open the **Audio** panel (bottom of Godot editor)
- [ ] Rename the default `Master` bus — leave it named `Master` (index 0)
- [ ] Add a new bus named `Music` (index 1) — set its send to `Master`
- [ ] Add a new bus named `SFX` (index 2) — set its send to `Master`
- [ ] Verify: three buses exist in order: Master, Music, SFX
- [ ] Leave all bus volumes at 0 dB for now — `SettingsManager` will set them at runtime

### Input Map (Project Settings → Input Map)
- [ ] Add action `cursor_up` — W key, Up Arrow
- [ ] Add action `cursor_down` — S key, Down Arrow
- [ ] Add action `cursor_left` — A key, Left Arrow
- [ ] Add action `cursor_right` — D key, Right Arrow
- [ ] Add action `confirm` — Z key, Enter, Space, Left Mouse Button
- [ ] Add action `cancel` — X key, Escape, Right Mouse Button
- [ ] Add action `next_unit` — Tab
- [ ] Add action `prev_unit` — Shift + Tab
- [ ] Add action `show_danger_zone` — Q key, Middle Mouse Button
- [ ] Add action `open_menu` — M key
- [ ] Add action `open_settings` — O key

---

## Milestone 1 — Data Layer

**Goal:** All resource class definitions exist and can be created as `.tres` files
in the Godot editor. `DataManager` loads them at startup.
**Test:** Run the project; check Output panel for load errors. Verify each `.tres`
file is accessible via `DataManager.get_class()` etc. in a temporary test script.

### Resource Class Definitions
- [ ] Create `scripts/resources/ClassData.gd` — define all `@export` fields per GDD_01
- [ ] Create `scripts/resources/WeaponData.gd` — define all `@export` fields per GDD_01
- [ ] Create `scripts/resources/ItemData.gd` — define all `@export` fields per GDD_04
- [ ] Create `scripts/resources/SkillData.gd` — define all `@export` fields per GDD_05
- [ ] Create `scripts/resources/UnitData.gd` — define all `@export` fields per GDD_01, including `ai_profile` and `is_default_roster` from the UnitData Field Addendum section
- [ ] Create `scripts/resources/MapData.gd` — define all `@export` fields per GDD_06
- [ ] Verify: each resource can be created via Godot editor "New Resource" dialog
- [ ] Verify: all fields appear in the Inspector when a `.tres` is selected

### Autoloads
- [ ] Create `scripts/autoloads/EventBus.gd` — define all signals listed in GDD_01
- [ ] Create `scripts/autoloads/GameState.gd` — define all vars and method stubs, including `take_map_snapshot()` and `restore_map_snapshot()`
- [ ] Create `scripts/autoloads/DataManager.gd` — implement `_load_directory()`, all `get_*()` methods, and weapon triangle lookup table
- [ ] Create `scripts/autoloads/SettingsManager.gd` — implement all vars, `load_settings()`, `save()`, `_apply_audio()`, `_apply_keybindings()`, `set_volume()`, `rebind_action()`, `reset_section_to_defaults()`, and `get_movement_speed_seconds()` per GDD_01
- [ ] Register the autoloads in Project Settings in this order: GameConstants, EventBus, SettingsManager, GameState, DataManager, ConditionManager, SkillHandler, ItemHandler, CombatResolver, EnemyAI
- [ ] Verify: `SettingsManager._ready()` runs without error; `user://settings.cfg` is created on first run
- [ ] Verify: no circular dependency warnings on project load

### MVP Data Files — Classes (6 files)
For each class below, create a `.tres` resource in `data/classes/` using `ClassData`:
- [ ] `soldier.tres` — stats, proficiencies, growth rates per GDD_03
- [ ] `mercenary.tres`
- [ ] `archer.tres`
- [ ] `mage.tres`
- [ ] `cleric.tres`
- [ ] `knight.tres`
- [ ] Verify: `DataManager.get_class_data("soldier")` returns correct resource at runtime

### MVP Data Files — Weapons (10 files)
Create `.tres` resources in `data/weapons/` using `WeaponData`:
- [ ] `iron_sword.tres`
- [ ] `steel_sword.tres`
- [ ] `iron_lance.tres`
- [ ] `javelin.tres` — range_min_formula = "1", range_max_formula = "2"
- [ ] `iron_bow.tres` — range_min_formula = "2", range_max_formula = "2"; effect_tags = ["effective_flying"] *(Note: range fields changed to formula strings — see WeaponData.gd)*
- [ ] `fire.tres` — uses_mag = true; effect_tags = ["effective_beast"]
- [ ] `elfire.tres` — uses_mag = true; effect_tags = ["effective_beast"]
- [ ] `thunder.tres` — uses_mag = true; effect_tags = ["effective_dragon"]
- [ ] `wind.tres` — uses_mag = true; effect_tags = ["effective_flying"]
- [ ] `heal_staff.tres` — weapon_type = "staff"; effect_tags = ["heal_10_plus_mag"]

### MVP Data Files — Items (2 files)
- [ ] `vulnerary.tres` — effect_id = "heal_flat"; effect_params = {"amount": 20}
- [ ] `elixir.tres` — effect_id = "heal_full"

### MVP Data Files — Skills (13 files)
- [x] `renewal.tres` — trigger = "start_of_turn"; effect_id = "renewal"
- [x] `vantage.tres` — trigger = "on_combat_start"; effect_id = "vantage"
- [x] `nihil.tres` — trigger = "on_combat_start"; effect_id = "nihil"
- [x] `resolve.tres` — trigger = "on_combat_start"; effect_id = "resolve"
- [x] `miracle.tres` — trigger = "on_damaged"; effect_id = "miracle"
- [x] `wrath.tres` — trigger = "on_combat_start"; effect_id = "wrath"
- [x] `swordfaire.tres` — trigger = "on_combat_start"; effect_id = "faire"; effect_params = {"weapon_type": "sword", "bonus": 5}
- [x] `lancefaire.tres` — trigger = "on_combat_start"; effect_id = "faire"; effect_params = {"weapon_type": "lance", "bonus": 5}
- [x] `bowfaire.tres` — trigger = "on_combat_start"; effect_id = "faire"; effect_params = {"weapon_type": "bow", "bonus": 5}
- [x] `swordbreaker.tres` — trigger = "on_combat_start"; effect_id = "breaker"; effect_params = {"weapon_type": "sword", "hit": 50}
- [x] `lancebreaker.tres` — trigger = "on_combat_start"; effect_id = "breaker"; effect_params = {"weapon_type": "lance", "hit": 50}
- [x] `bowbreaker.tres` — trigger = "on_combat_start"; effect_id = "breaker"; effect_params = {"weapon_type": "bow", "hit": 50}
- [x] `s_rank_mastery.tres` — trigger = "on_combat_start"; effect_id = "s_rank_mastery" (earned at S rank; granted at runtime by `Unit.add_wexp()`, never assigned in a roster .tres)

### Amendment A1 — Data Layer Extensions
These fields extend the MVP resource classes for Phase 2 compatibility. Safe defaults
mean all existing `.tres` files load without changes. **Complete before closing M1.**

#### UnitData.gd
- [x] Add `active_modifiers: Array[Dictionary] = []` — serializable per-map modifier list
- [x] Add `skill_use_counters: Dictionary = {}` — per-map skill use tracking
- [x] Add `damage_taken_this_map: int = 0` — for Vengeance skill (M9)
- [x] Add `shift_gauge`, `is_shifted`, `shift_profile_id` — Laguz stubs (M12)
- [x] Update `GameState.take_map_snapshot()` / `_restore_unit_data()` to include new fields

#### ClassData.gd
- [x] Add Laguz gauge fields (`is_laguz`, `max_shift_gauge`, `shift_gain_*`, etc.) — safe defaults for Beorc

#### WeaponData.gd
- [x] Add `strikes_per_attack: int = 1` — set to 2 for all Brave weapons
- [x] Add `is_natural_weapon: bool = false` — for Laguz natural weapons (M12)

#### SkillData.gd
- [x] Add `max_uses_per_map: int = -1`
- [x] Add `max_uses_per_combat: int = -1`
- [x] Update trigger docstring with 5 new Phase 2 trigger strings

#### ConditionManager (stub autoload)
- [x] Create `scripts/autoloads/ConditionManager.gd` with stub methods (all no-ops)
- [x] Register `ConditionManager` as autoload in Godot Project Settings (after `DataManager`)
- [x] Verify: `ConditionManager` node is present at `/root/ConditionManager` at runtime

---

### Default Roster Files (6 UnitData files)
Create `data/roster/default/` and add one `UnitData` `.tres` per unit per GDD_03.
- [x] `unit_01_soldier.tres` — name="Unit_01", class_id="soldier", inventory=[iron_lance, vulnerary], lance proficiency D
- [x] `unit_02_mercenary.tres` — name="Unit_02", class_id="mercenary", inventory=[iron_sword, vulnerary], sword proficiency D; skills=["vantage", "swordfaire"]
- [x] `unit_03_archer.tres` — name="Unit_03", class_id="archer", inventory=[iron_bow, vulnerary], bow proficiency D; skills=["bowfaire"]
- [x] `unit_04_mage.tres` — name="Unit_04", class_id="mage", inventory=[fire, vulnerary], fire proficiency E, thunder proficiency E; skills=["wrath"]
- [x] `unit_05_cleric.tres` — name="Unit_05", class_id="cleric", inventory=[heal_staff, vulnerary], staff proficiency D, light proficiency E; skills=["renewal", "miracle"]
- [x] `unit_06_knight.tres` — name="Unit_06", class_id="knight", inventory=[iron_lance, vulnerary], lance proficiency D; skills=["resolve"]
- [x] For all six: set level=1, exp=0, hp=base class hp, all stats=base class stats, is_default_roster=true, ai_profile="basic"
- [x] Implement `GameState.load_default_roster()` — loads all six `.tres` files into `player_roster`
- [x] Verify: calling `GameState.load_default_roster()` populates `player_roster` with 6 entries

---

## Milestone 2 — Grid and Map Rendering

**Goal:** A map loads and displays. The cursor can move around it. Terrain info
updates as the cursor moves.
**Test:** Launch the game, see map tiles, move cursor with arrow keys and mouse.
Terrain info panel updates. Camera scrolls when cursor nears edge.

### TileSet and TileMap
- [ ] Create a shared `TileSet` resource (save to `assets/terrain_tileset.tres`)
- [ ] Add placeholder tile sprites for each terrain type (colored 64×64 squares)
- [ ] Add a `Custom Data Layer` named `terrain_type` (type: String) to the TileSet
- [ ] Assign correct `terrain_type` value to each tile in the TileSet editor
- [ ] Create a second simple TileSet for overlays (4 tiles: blue, red, green, dark-red)
  and save as `assets/overlay_tileset.tres`

### MVP Map Scene (`map_001.tscn`)
- [ ] Create `GameMap.tscn` scene with the node tree defined in GDD_01
- [ ] Add `TileMapLayer_Terrain` — assign `terrain_tileset.tres`
- [ ] Add `TileMapLayer_Overlay` — assign `overlay_tileset.tres`
- [ ] Paint the map layout for Map 001 per the grid in GDD_06
- [ ] Verify all wall tiles are painted correctly along the border
- [ ] Add `Camera2D` node; set `position_smoothing_enabled = false`
- [ ] Add `MapCursor` node with placeholder `AnimatedSprite2D`

### GridManager
- [ ] Create `scripts/core/GridManager.gd`
- [ ] Implement `get_terrain_at(tile)` — reads TileMapLayer custom data
- [ ] Implement `is_passable(tile, unit)` — checks terrain type and unit occupancy
- [ ] Implement `get_unit_at(tile)` — scans GameState.all_units
- [ ] Implement `world_to_tile()` and `tile_to_world()`
- [ ] Implement `get_move_cost(tile, unit)` — terrain cost table per GDD_02
- [ ] Implement `get_movement_range(unit)` — BFS/Dijkstra using move costs
- [ ] Implement `get_path_to(unit, target_tile)` — returns ordered tile list
- [ ] Implement `get_attack_range_from_tiles(unit, from_tiles)`
- [ ] Implement `get_all_attack_tiles(unit, from_tiles)`
- [ ] Implement `get_attackable_enemies_from_tile(unit, tile)`
- [ ] Implement `can_attack_from_tile(attacker, tile, target)`
- [ ] Implement `get_healable_allies(unit)`
- [ ] Implement `show_movement_overlay(tiles)` — paint blue tiles on overlay layer
- [ ] Implement `show_attack_overlay(tiles)` — paint red tiles
- [ ] Implement `show_heal_overlay(tiles)` — paint green tiles
- [ ] Implement `show_enemy_danger_zone()` — all enemy attack ranges in dark red
- [ ] Implement `clear_overlays()` — clear all overlay layer tiles
- [ ] Verify: movement range correctly respects terrain costs
- [ ] Verify: forest costs 2, mountain costs 3, wall is impassable
- [ ] Verify: movement range does not pass through enemy units
- [ ] Verify: attack range tiles appear correctly after movement range

### MapCursor
- [ ] Create `scripts/core/MapCursor.gd`
- [ ] Implement tile-based movement with keyboard (arrow keys / WASD)
- [ ] Implement mouse hover — cursor snaps to hovered tile instantly
- [ ] Implement left-click confirm, right-click cancel
- [ ] Implement key-repeat (0.25s delay, 0.10s repeat rate)
- [ ] Implement `lock()` and `unlock()`
- [ ] Implement camera edge-scrolling (pan when cursor within 2 tiles of viewport edge)
- [ ] Emit `EventBus.cursor_moved(tile)` on every tile change
- [ ] Verify: cursor cannot move outside map bounds
- [ ] Verify: camera never shows black space outside map

### Map Data Resource
- [ ] Create `scripts/resources/MapData.gd` (if not already done in M1)
- [ ] Create `data/maps/map_001_rout/map_001_data.tres`
- [ ] Fill in: id, objective_type = "rout", player_start_tiles, enemy_placements
- [ ] Create enemy UnitData `.tres` files for all 8 enemies in `data/maps/map_001_rout/enemies/`
- [ ] Fill each enemy UnitData with correct stats per GDD_06 enemy table

---

## Milestone 3 — Units and Turn Structure

**Goal:** Player and enemy units appear on the map. The turn order works. Units can
be selected and deselected. Player units can be moved.
**Test:** Units appear at correct tiles. Selecting a unit shows movement range.
Moving a unit works. Pressing cancel undoes the move. End turn cycles to enemy
phase (enemies stand still for now). New player phase restores unit colors.

### Unit Scene and Script
- [ ] Create `scenes/units/Unit.tscn` with node tree from GDD_01
- [ ] Add placeholder `Sprite2D` (64×64 colored square — different color per team)
- [ ] Add `HPBar` using `TextureProgressBar` or `ProgressBar` (positioned above sprite)
- [ ] Create `scripts/units/Unit.gd`
- [ ] Implement `initialize(unit_data, start_tile, team)`
- [ ] Implement `get_equipped_weapon()` and `get_equipped_weapon_entry()`
- [ ] Implement `has_quality(quality)`
- [ ] Implement `battle_speed()`, `accuracy()`, `dodge()`, `damage()`, `crit_rate()`, `crit_avoid()`
- [ ] Implement `take_damage(amount)` — clamp to 0, update HP bar, emit `unit_damaged`
- [ ] Implement `heal(amount)` — clamp to max_hp, update HP bar, emit `unit_healed`
- [ ] Implement `handle_death()` — set incapacitated if permadeath on, emit `unit_died`, queue_free
- [ ] Implement `move_along_path(path)` — Tween position tile by tile; emit `unit_moved` on completion
- [ ] Implement `snap_to_tile(tile)` — instant position change (for AI and undo)
- [ ] Implement `set_done_appearance()` — darken/desaturate sprite (use `modulate`)
- [ ] Implement `reset_appearance()` — restore `modulate` to white

### Stat computation
- [x] Stat math is **inline in `Unit.gd`** — terrain bonuses are read from
  `GridManager`, and the S-rank bonus is applied via the `s_rank_mastery` skill.
  The separate `UnitStatBlock.gd` helper was designed but never created; the logic
  is small enough to keep in `Unit.gd`.

### GameMap and Unit Spawning
- [ ] In `GameMap.tscn`, add script `GameMap.gd`
- [ ] In `_ready()`: load `MapData`, spawn player units at `player_start_tiles` using roster
- [ ] In `_ready()`: spawn enemy units at their placement tiles from `MapData.enemy_placements`
- [ ] Register all spawned units with `GameState`
- [ ] After all units spawned, call `GameState.take_map_snapshot()` to record map-start state
- [ ] Implement `GameState.take_map_snapshot()` — deep-copies all player `UnitData` fields into `_map_start_snapshot` as plain Dictionaries (no resource references)
- [ ] Implement `GameState.restore_map_snapshot()` — overwrites each player `UnitData` from snapshot, then reloads the current map scene via `get_tree().reload_current_scene()`
- [ ] Wire `GameOverScreen`'s Retry button to call `GameState.restore_map_snapshot()`
- [ ] Verify: 6 player units and 8 enemy units appear at correct tiles
- [ ] Verify: after a retry, all player units return to their map-start HP, inventory, and EXP

### TurnManager
- [ ] Create `scripts/core/TurnManager.gd`
- [ ] Implement `_unit_states` dictionary (Node → UnitState enum)
- [ ] Implement `start_map(map_data)` — spawns phase, connects signals
- [ ] Implement `start_player_phase()` — reset all unit states to READY, reset unit appearances
- [ ] Implement `end_player_phase()` — show confirmation if units still READY/MOVED, then start enemy phase
- [ ] Implement `start_enemy_phase()` — show banner, run AI (stub for now), then start player phase
- [ ] Implement `set_unit_state()`, `get_unit_state()`, `can_unit_act()`, `are_all_player_units_done()`
- [ ] Implement `undo_move(unit)` — return unit to `_original_tile`, set state to READY
- [ ] Implement `check_victory_conditions()` — rout check only for MVP
- [ ] Connect to `EventBus.unit_died` to trigger victory check
- [ ] Verify: turn counter increments each player phase
- [ ] Verify: unit state transitions work correctly (READY → MOVED → DONE)
- [ ] Verify: undo move works (cancel after moving returns unit)

### Amendment A2 — Unit Script (modifier-aware stats)
These extend `Unit.gd` so all combat stat reads go through the modifier system.
**Complete before M4 begins.**

- [x] Add `get_effective_stat(stat_name)` — base stat + active_modifiers sum, clamped ≥ 0
- [x] Add `has_skill(skill_id)` — convenience check on data.skills array
- [x] Add `get_skill_uses_remaining()` and `consume_skill_use()` — per-map skill limits
- [x] Add `add_modifier()`, `remove_modifier()`, `tick_modifiers()`, `clear_combat_modifiers()`, `reset_map_state()`
- [x] Refactor `battle_speed()` to use `get_effective_stat()`
- [x] Refactor `accuracy()` to use `get_effective_stat()`
- [x] Refactor `dodge()` to use `get_effective_stat()`
- [x] Refactor `damage()` to use `get_effective_stat()`
- [x] Refactor `crit_rate()` to use `get_effective_stat()`
- [x] Refactor `crit_avoid()` to use `get_effective_stat()`
- [x] Hook `tick_modifiers("turn")` into `TurnManager.start_player_phase()` for each player unit and each enemy turn start
- [x] Hook `tick_modifiers("map_turn")` into `TurnManager.start_player_phase()` once per full round
- [x] Hook `clear_combat_modifiers()` into `CombatResolver` after each combat resolves
- [x] Hook `reset_map_state()` into `GameMap._ready()` for all units before snapshot
- [ ] Verify: existing unit stat tests still pass (all 130 green ✅)
- [ ] Verify: adding a +5 STR modifier makes `get_effective_stat("strength")` return base + 5
- [ ] Verify: a "turn" duration modifier expires after the correct number of turns

### Amendment A4 — Grid System (movement skill hooks)
These add skill override entry points to `GridManager` so movement skills can be added
in M9 without touching pathfinding core logic. **Complete before M4 begins.**

- [x] Add `SkillHandler.get_move_cost_override()` stub (returns -1)
- [x] Add `SkillHandler.can_pass_through_enemies()` stub (returns false)
- [x] Add `SkillHandler.can_phase_through()` stub (returns false)
- [x] Modify `GridManager.get_move_cost()` to call `get_move_cost_override()` first
- [x] Modify `GridManager.is_passable()` to check `can_pass_through_enemies()` and `can_phase_through()`
- [x] Add `GridManager.can_end_on_tile()` — separates "can move through" from "can stop here"
- [x] Update `get_movement_range()` to call `can_end_on_tile()` when marking reachable tiles
- [x] Update move confirmation in `MapCursor.gd` to call `can_end_on_tile()` before committing move
- [ ] Verify: stubs return safe defaults and existing pathfinding tests still pass (✅)
- [ ] Verify: path through an ally tile is still walkable but not stoppable

---

### MapCursor Unit Selection Logic
- [ ] Implement `_on_confirm()` — select unit if cursor on player unit tile
- [ ] Show movement/attack overlays on selection
- [ ] Implement confirm on move tile — move unit, show Action Menu
- [ ] Implement cancel to deselect unit or undo move
- [ ] Implement `next_unit` — cycle cursor to next READY player unit

---

## Milestone 4 — Combat System

**Goal:** Full combat resolution works. Attack preview shows correct numbers.
Weapons lose durability. EXP and wEXP are awarded. Units die and are removed.
**Test:** Manually verify combat math against handbook formulas. Attack a unit at
weapon triangle advantage and disadvantage. Kill an enemy. Level up a unit.
Equip an archer and verify they cannot attack adjacent targets.

### Amendment A3 — Combat Resolver (context pipeline)
Restructures `CombatResolver` around a modifier pipeline so all future skill effects
plug in cleanly. **Complete.** The combat context pipeline is now documented in
GDD_01 (CombatResolver) and the `CombatResolver.gd` file header.

- [x] Add `_build_combat_context(attacker, defender)` — constructs initial context dict with zero mods
- [x] Add `_collect_combat_modifiers(context)` — applies UnitData modifiers + calls SkillHandler aura triggers
- [x] Add `_get_effectiveness_multiplier(weapon, target, context)` — returns 1.0/3.0/4.0 with Nullify check
- [x] Refactor `resolve_combat()` to use context dict, multi-strike loop, and vantage flag
- [x] Refactor `preview_combat()` to use same context pipeline (no RNG, no side effects)
- [x] Add `_resolve_single_attack()` extracting per-hit logic from the exchange loop
- [x] Add `_skill_available()` and `_consume_skill()` helpers
- [x] Ensure `_resolve_single_attack()` increments `target.data.damage_taken_this_map`
- [x] Ensure `clear_combat_modifiers()` called on both units after `resolve_combat()` returns
- [x] Verify: Brave Sword (strikes_per_attack = 2) fires two attacker strikes before counter
- [ ] Verify: effectiveness multiplier (e.g. iron bow vs flying unit) triples Mt correctly
- [ ] Verify: `preview_combat()` returns identical base numbers to `resolve_combat()` (pre-RNG)

### CombatResolver
- [ ] Create `scripts/core/CombatResolver.gd`
- [ ] Implement `compute_battle_speed(unit, weapon)`
- [ ] Implement `compute_accuracy(attacker, defender, weapon)` — includes weapon triangle and terrain
- [ ] Implement `compute_damage(attacker, defender, weapon)` — includes weapon triangle; clamp min 0
- [ ] Implement `compute_crit_rate(attacker, defender, weapon)` — clamp 0–100
- [ ] Implement `can_counterattack(defender, attacker_tile)` — range check
- [ ] Implement `get_follow_up_attacker(a, b)` — speed difference ≥ 4
- [ ] Implement `calculate_exp(attacker, defender, killed)`
- [ ] Implement `_apply_weapon_triangle()` — ±10 accuracy, ±2 damage
- [ ] Implement `_roll_hit(pct)` and `_roll_crit(pct)` — `randi() % 100 < pct`
- [ ] Implement `preview_combat(attacker, defender)` — no RNG, no side effects
- [ ] Implement `resolve_combat(attacker, defender)` — full RNG resolution; returns result dict
- [ ] Implement `apply_combat_result(result, attacker, defender)` — applies HP changes, animations
- [ ] Verify: unarmed unit cannot attack (graceful null check on equipped weapon)
- [ ] Verify: a unit with a bow equipped cannot attack a range-1 target (range_min = 2 check applies to weapon, not class)
- [ ] Verify: weapon triangle advantage gives +10 accuracy and +2 damage
- [ ] Verify: critical hit deals 3× damage
- [ ] Verify: follow-up triggers when speed difference ≥ 4
- [ ] Verify: defender with out-of-range weapon cannot counterattack
- [ ] Verify: damage cannot go below 0

### SkillHandler (MVP skills + faire/breaker/aura stubs)
- [x] Create `scripts/skills/SkillHandler.gd`
- [x] Implement `apply_trigger(unit, trigger, context)` dispatcher
- [x] Implement `_execute_skill()` match block for MVP effect_ids
- [x] Implement `renewal` effect
- [x] Implement `vantage` effect — flag vantage unit in context
- [x] Implement `nihil` effect — set `defender_skills_blocked = true` in context
- [x] Implement `resolve` effect — conditional stat boost at ≤50% HP
- [x] Implement `miracle` effect — LUK% chance to halve fatal damage
- [x] Implement `wrath` effect — +50 crit at ≤50% HP
- [x] Implement `faire` effect — +5 damage when using matching weapon type
- [x] Implement `breaker` effect — +50 hit against matching weapon type
- [x] Implement `charm`/`anathema`/`daunt` aura effects (trigger = "on_combat_apply_modifiers")
- [x] Implement movement skill stubs: `get_move_cost_override()`, `can_pass_through_enemies()`, `can_phase_through()`
- [x] Hook `apply_trigger()` calls into `CombatResolver` at correct points
- [x] Hook `start_of_turn` trigger into `TurnManager.start_player_phase()`

### Weapon Durability and Inventory
- [ ] Implement `Unit.use_weapon_durability()` — decrement uses; remove weapon if 0
- [ ] Apply correct durability rules: melee/thrown only on hit; bows/tomes/staves always
- [ ] Verify: weapon disappears from inventory when uses reach 0
- [ ] Verify: unit with no usable weapon shows `--` in Attack Preview

### EXP and Leveling
- [ ] Implement `Unit.add_exp(amount)` — add to data.exp; trigger level_up if ≥100; carry overflow
- [ ] Implement `Unit.level_up()` — roll stat increases using growth rates; emit signal
- [ ] Implement `Unit.add_wexp(weapon_type, amount)` — update proficiency; handle rank-up
- [ ] Ensure `add_exp()` is called after each combat resolution
- [ ] Ensure `add_wexp()` is called after each successful hit
- [ ] Verify: EXP correctly matches the level-difference table in GDD_02
- [ ] Verify: wEXP rank-up grants S-rank bonus when applicable

### Staff Healing
- [ ] Add "Staff" option to `ActionMenu`
- [ ] Implement staff target selection (green overlay; ally list)
- [ ] Implement healing: `target.heal(10 + unit.data.magic)`
- [ ] Decrement staff uses after each use (bows/tomes/staves always lose durability)
- [ ] Award EXP after staff use per GDD_02 table

### Item Use
- [ ] Add "Item" option to `ActionMenu`
- [ ] Implement item selection menu
- [ ] Implement `heal_flat` effect (Vulnerary: +20 HP)
- [ ] Implement `heal_full` effect (Elixir: full HP)
- [ ] Decrement item uses; remove from inventory at 0

---

## Milestone 5 — HUD and UI

**Goal:** All UI panels function correctly. Combat preview shows before attacks.
Level-up screen shows stat gains. Phase banner appears on phase change.
**Test:** Play through a full map manually and verify every UI element shows the
correct information at the correct time.

### HUD Panels
- [ ] Create `scenes/ui/HUD.tscn` with full node tree from GDD_01
- [ ] Create `scripts/ui/HUD.gd` — connects to EventBus signals
- [ ] Create `scenes/ui/UnitInfoPanel.tscn` and `scripts/ui/UnitInfoPanel.gd`
  - [ ] Updates on `EventBus.cursor_moved` — show unit data if unit at tile
  - [ ] Hides when no unit at cursor tile
  - [ ] Shows: Name, Class, HP/MaxHP, equipped weapon name
- [ ] Create `scenes/ui/TerrainInfoPanel.tscn` and `scripts/ui/TerrainInfoPanel.gd`
  - [ ] Always visible; updates on `EventBus.cursor_moved`
  - [ ] Shows: terrain name, DEF bonus, Dodge bonus
- [ ] Add Turn Counter label — increments each player phase
- [ ] Verify: UnitInfoPanel shows enemy info when cursor hovers over enemy unit

### Phase Banner
- [ ] Create `scenes/ui/PhaseBanner.tscn` with `ColorRect` and `Label`
- [ ] Create `scripts/ui/PhaseBanner.gd`
- [ ] Implement slide-in / hold / slide-out Tween animation (0.3 / 0.8 / 0.3 seconds)
- [ ] Blue background for Player Phase; red for Enemy Phase
- [ ] Cursor locked during banner; unlocked after slide-out completes
- [ ] Verify: banner appears at correct times and does not block gameplay input after completing

### Action Menu
- [ ] Create `scenes/ui/ActionMenu.tscn` with VBoxContainer and 5 buttons
- [ ] Create `scripts/ui/ActionMenu.gd`
- [ ] Show/hide on unit move confirmation
- [ ] Grey out "Attack" if no enemies in range
- [ ] Grey out "Staff" if no staff equipped or no healable allies in range
- [ ] Grey out "Item" if inventory is empty
- [ ] Grey out "Trade" if no adjacent ally
- [ ] Reposition menu to avoid screen edges
- [ ] Keyboard navigation (up/down between buttons)
- [ ] Cancel closes menu and triggers undo

### Attack Preview
- [ ] Create `scenes/ui/AttackPreview.tscn` with two stat columns
- [ ] Create `scripts/ui/AttackPreview.gd`
- [ ] Populate from `CombatResolver.preview_combat()` — no RNG
- [ ] Show `--` for defender stats when cannot counterattack
- [ ] Show attack count (×1 or ×2) for both sides
- [ ] Updates in real time as player changes target selection
- [ ] Confirm triggers `CombatResolver.resolve_combat()`

### Target Select List
- [ ] Create `scenes/ui/TargetSelectList.tscn`
- [ ] Create `scripts/ui/TargetSelectList.gd`
- [ ] Shows all valid attack targets or heal targets as a scrollable button list
- [ ] Selecting a target moves cursor to that unit's tile on the map
- [ ] Works for both attack mode (red overlay) and staff mode (green overlay)

### Level Up Screen
- [ ] Create `scenes/ui/LevelUpScreen.tscn` with stat grid
- [ ] Create `scripts/ui/LevelUpScreen.gd`
- [ ] Triggered by `EventBus.unit_leveled_up`
- [ ] Display old and new values for all 8 stats
- [ ] Highlight increased stats in yellow with ▲ marker
- [ ] Block all input until player presses `confirm`
- [ ] If multiple level-ups queued, show one screen per level in sequence

### Map Menu
- [ ] Create `scenes/ui/MapMenu.tscn` and `scripts/ui/MapMenu.gd`
- [ ] Opens on `open_menu` action when cursor is on empty tile
- [ ] "End Turn" button — prompts if unacted units remain; calls `TurnManager.end_player_phase()`
- [ ] "Settings" button — opens `SettingsScreen`; map remains paused until Settings is closed
- [ ] "Quit to Menu" button — confirm prompt; returns to Main Menu
- [ ] Cancel closes the menu

### Settings Screen
- [ ] Create `scenes/ui/SettingsScreen.tscn` and `scripts/ui/SettingsScreen.gd`
- [ ] Implement tab bar with three tabs: Audio, Controls, Gameplay
- [ ] Implement "Reset to Defaults" button — resets active tab only, with confirmation prompt
- [ ] Implement "Close" button — saves all settings via `SettingsManager.save()` and returns to previous screen
- [ ] Verify: pressing `cancel` also closes and saves (same as Close button)
- [ ] **Audio tab:**
  - [ ] Add `HSlider` for Master Volume (0–100); label shows numeric value
  - [ ] Add `HSlider` for Music Volume (0–100)
  - [ ] Add `HSlider` for SFX Volume (0–100)
  - [ ] Connect each slider's `value_changed` signal to `SettingsManager.set_volume()`
  - [ ] Verify: dragging a slider changes audio volume immediately in real time
  - [ ] Verify: values are loaded from `SettingsManager` when the screen opens
- [ ] **Controls tab:**
  - [ ] Display all 10 remappable actions in a scrollable list with current binding shown
  - [ ] Add `[ Rebind ]` button per row
  - [ ] Implement rebind flow: show "Press any key…", capture `InputEventKey` or `InputEventMouseButton`
  - [ ] Implement conflict detection: if key is already bound, show "Replace?" prompt
  - [ ] Implement cancel-rebind on `Escape` during capture
  - [ ] Call `SettingsManager.rebind_action()` on successful rebind
  - [ ] Verify: new binding takes effect immediately (InputMap updated live)
  - [ ] Verify: binding survives closing and reopening the game
- [ ] **Gameplay tab:**
  - [ ] Add `OptionButton` for Combat Animations — options: All Units, Player Only, Enemy Only, None
  - [ ] Add `OptionButton` for Movement Speed — options: Normal, Fast, Instant
  - [ ] Add `OptionButton` for Phase Banner — options: Show, Skip
  - [ ] Add `OptionButton` for Level Up Screen — options: Show, Auto-dismiss, Skip
  - [ ] Add `OptionButton` for Permadeath — options: Off, On
  - [ ] Add `OptionButton` for Leveling Method — options: Growth Rates, Point Buy, Coin Flip, Dice Roll
  - [ ] Connect each `OptionButton.item_selected` to write to `SettingsManager` and call `save()`
  - [ ] Show warning label when Permadeath or Leveling Method is changed: "Takes effect on next map"
  - [ ] Verify: all dropdowns show the currently saved value when the screen opens
- [ ] **Main Menu integration:**
  - [ ] "Settings" button on Main Menu opens `SettingsScreen`
  - [ ] Verify: settings changed from the Main Menu are reflected if the map is then started

### Game Over and Victory Screens
- [ ] Create `GameOverScreen` — full-screen dark overlay; Retry and Quit buttons
- [ ] "Retry" calls `GameState.restore_map_snapshot()` — reloads map with map-start unit state
- [ ] Create `VictoryScreen` — shows reward gold; Continue button [PLACEHOLDER]
- [ ] Both triggered by EventBus signals

### Main Menu
- [ ] Create `scenes/ui/MainMenu.tscn`
- [ ] "New Game" — calls `GameState.load_default_roster()` then starts map 001
- [ ] "Settings" — opens `SettingsScreen`
- [ ] "Quit" — closes the application
- [ ] "Continue" — greyed out for MVP (save system Phase 2)

---

## Milestone 6 — Enemy AI

**Goal:** Enemies move and attack during the enemy phase using the basic AI profile.
**Test:** Run the MVP map and watch the full enemy phase. Verify all items on the
AI testing checklist in GDD_08.

- [ ] Create `scripts/ai/EnemyAI.gd`
- [ ] Implement `run_enemy_phase()` — iterates enemies sequentially with 0.3s pause between
- [ ] Implement `take_turn(unit)` — dispatches to profile functions
- [ ] Implement `_run_passive(unit)` — does nothing
- [ ] Implement `_score_target(attacker, target)` — per GDD_08 scoring formula
- [ ] Implement `_find_best_attack_tile(attacker, target)` — prefer terrain DEF
- [ ] Implement `_move_toward_closest_player(unit)` — BFS toward nearest player tile
- [ ] Implement `_run_basic(unit)` — full algorithm per GDD_08
- [ ] Lock cursor at start of enemy phase; unlock after all enemies acted
- [ ] Verify: enemy movement is animated (same speed as player unit movement)
- [ ] Verify: enemy attacks are resolved using the same `CombatResolver` pipeline
- [ ] Verify: two enemies never occupy the same tile
- [ ] Verify: enemies on Fort/Throne tile heal at start of their turn
- [ ] Verify: enemy phase ends and player phase begins correctly every round

---

## Milestone 7 — Full MVP Playthrough

**Goal:** Map 001 is completable from start to finish. All systems work together.
**Test:** Complete the entire map at least twice without crashing or incorrect behavior.

### Integration Tests
- [ ] Start new game → map loads with correct units and enemies at correct tiles
- [ ] Move and attack with each of the 6 player classes
- [ ] Confirm weapon triangle advantage/disadvantage changes numbers visibly
- [ ] Use a Heal staff successfully
- [ ] Use a Vulnerary item successfully
- [ ] A player unit levels up — verify level-up screen shows correct gains
- [ ] A weapon breaks — verify it is removed from inventory
- [ ] Kill all 8 enemies — verify Victory screen appears
- [ ] Retry from Game Over screen — map reloads correctly
- [ ] Permadeath OFF: kill a player unit → they are absent this map, available next time
- [ ] Permadeath ON: kill a player unit → they are flagged incapacitated
- [ ] Enemy phase: all enemies move and attack correctly
- [ ] Enemy on throne tile heals at start of their turn
- [ ] Undo move works (cancel after moving before acting)
- [ ] `Q` key shows enemy danger zone
- [ ] Tab cycles through unacted player units
- [ ] Map Menu opens and closes correctly
- [ ] End turn with unacted units triggers confirmation prompt

### Edge Cases to Verify
- [ ] Unit with 0 weapons cannot attack (no "Attack" option in menu)
- [ ] Any unit with a bow equipped cannot attack an adjacent (range 1) tile — verify with Archer and verify the same restriction applies if a non-Archer unit equips a bow via trade
- [ ] Any unit with a bow equipped cannot receive a counterattack from an adjacent enemy who only has melee weapons
- [ ] Cleric with no allied targets in range: "Staff" is greyed out
- [ ] Two players both target the same enemy — second attacker finds it dead; no crash
- [ ] Unit healed above max HP is clamped correctly
- [ ] EXP overflow (e.g. gain 45 EXP at 80 EXP): level up occurs, 25 EXP carries over
- [ ] Multiple level-ups in sequence (if overflow causes two level-ups): both screens shown

### Settings Integration Tests
- [ ] Open Settings from Main Menu — all values match defaults on first launch
- [ ] Change Master Volume slider — audio output changes in real time
- [ ] Close and reopen Settings — values are still what was set (persisted to file)
- [ ] Rebind `confirm` to a new key — new key works in gameplay; old key no longer works
- [ ] Rebind to an already-used key — conflict prompt appears; choosing "No" cancels the rebind
- [ ] Reset Controls to defaults — all bindings return to original values
- [ ] Set Movement Speed to Instant — units snap to destination with no tween
- [ ] Set Movement Speed to Fast — units move noticeably faster than Normal
- [ ] Set Phase Banner to Skip — no banner appears on phase change; HUD phase label still updates
- [ ] Set Level Up Screen to Auto-dismiss — screen appears briefly and closes without input
- [ ] Set Level Up Screen to Skip — no level-up screen appears; unit still levels up correctly
- [ ] Set Combat Animations to None — HP bars update instantly; no flash animations play
- [ ] Open Settings from Map Menu mid-map — map is paused; closing returns to map correctly
- [ ] Delete `user://settings.cfg` and relaunch — game starts with all defaults; no crash

---

## Phase 2 Backlog (Not in MVP)

Track these here so they are not forgotten. Implement after MVP is stable.

### Content
- [ ] All remaining handbook classes (47 more classes)
- [ ] Full weapon roster from handbook tables
- [ ] Full item roster
- [ ] All generic, promotion, and occult skills

### Systems
- [ ] Class promotion system and UI
- [ ] Status conditions (Poison, Sleep, Silence, Berserk, Stun)
- [ ] Rescue and carry system
- [ ] Trade between units on the map
- [ ] Fog of war
- [ ] Pre-battle deployment screen
- [ ] Shop system (between maps)
- [ ] Forging system
- [ ] **Between-map save / load system** — serialize `GameState.player_roster` (all UnitData),
      current map index, and gold. Save to `user://savegame.cfg` at the end of each map
      and on quit. Load and restore on "Continue" from Main Menu. Implement alongside
      the campaign/chapter select screen so there is something meaningful to return to.
- [ ] Campaign map / chapter select screen
- [ ] Stationary weapons (Ballista, Onager)
- [ ] Laguz units and shift gauge system
- [ ] Door and chest interactions
- [ ] Ally NPC phase
- [ ] Additional AI profiles (territorial, guard_tile, healer, boss)

### Maps
- [ ] Map 002 — Seize objective
- [ ] Map 003 — Defeat the Boss
- [ ] Map 004 — Escape
- [ ] Map 005 — Survive / Defend
- [ ] Additional maps as campaign expands

### Polish
- [ ] [PLACEHOLDER] All unit sprites and portraits
- [ ] [PLACEHOLDER] Terrain tile sprites
- [ ] [PLACEHOLDER] UI panel art / 9-patch textures
- [ ] [PLACEHOLDER] Combat hit/miss/crit animations
- [ ] [PLACEHOLDER] Unit death animations
- [ ] [PLACEHOLDER] Background music per phase
- [ ] [PLACEHOLDER] Sound effects (cursor move, attack, level up, etc.)
- [ ] [PLACEHOLDER] Story / dialogue system
- [ ] **Mid-battle suspend save** — serialize the full battle state to
      `user://suspend.cfg` so the player can quit mid-map and resume exactly
      where they left off. Requires saving: all unit tile positions, current HP,
      active status conditions, which units have acted this turn, turn number,
      current phase, enemy AI state (which enemies have acted), and the active
      map ID. On "Continue" from the Main Menu, detect the presence of a suspend
      save and offer to resume it. Delete the suspend save on map completion,
      map defeat, or if the player deliberately quits to menu without saving.
      Implement after between-map saving is stable, as it builds on the same
      infrastructure.
- [ ] Steam / itch.io / GitHub release packaging
