# GDD_01 — Architecture & Project Structure (Detailed)

---

## Core Philosophy: Data-Driven Design

All game content — classes, weapons, items, skills, maps — is defined in **data files**,
not in code. Game logic reads and executes these definitions at runtime. This means:

- Adding a new class = write a new `.tres` resource file, no code changes needed
- Adding a new skill = write a skill resource, register its effect in SkillHandler
- Adding a new map = write a map data file and a Godot TileMap scene

The only time code changes are needed is when introducing a **new type of mechanic**.

---

## Godot Project Folder Structure

```
res://
├── project.godot
│
├── assets/
│   ├── sprites/
│   │   ├── units/                   # [PLACEHOLDER] 64x64 unit sprites per class
│   │   ├── terrain/                 # [PLACEHOLDER] 64x64 tile sprites
│   │   ├── ui/                      # [PLACEHOLDER] UI panels, icons, cursors
│   │   ├── weapons/                 # [PLACEHOLDER] 16x16 weapon icons
│   │   └── cursor/                  # [PLACEHOLDER] map cursor sprite (animated)
│   ├── audio/
│   │   ├── music/                   # [PLACEHOLDER]
│   │   └── sfx/                     # [PLACEHOLDER]
│   └── fonts/                       # [PLACEHOLDER] pixel font recommended
│
├── data/
│   ├── classes/
│   │   ├── soldier.tres
│   │   ├── mercenary.tres
│   │   ├── archer.tres
│   │   ├── mage.tres
│   │   ├── cleric.tres
│   │   └── knight.tres
│   ├── weapons/
│   │   ├── iron_sword.tres
│   │   ├── steel_sword.tres
│   │   ├── iron_lance.tres
│   │   ├── javelin.tres
│   │   ├── iron_bow.tres
│   │   ├── fire.tres
│   │   ├── elfire.tres
│   │   ├── thunder.tres
│   │   ├── wind.tres
│   │   └── heal_staff.tres
│   ├── items/
│   │   ├── vulnerary.tres
│   │   └── elixir.tres
│   ├── skills/                       # 13 SkillData .tres files
│   │   ├── renewal.tres
│   │   ├── vantage.tres
│   │   ├── nihil.tres
│   │   ├── resolve.tres
│   │   ├── miracle.tres
│   │   ├── wrath.tres
│   │   ├── swordfaire.tres
│   │   ├── lancefaire.tres
│   │   ├── bowfaire.tres
│   │   ├── swordbreaker.tres
│   │   ├── lancebreaker.tres
│   │   ├── bowbreaker.tres
│   │   └── s_rank_mastery.tres       # earned at S rank; not assignable in .tres
│   ├── roster/
│   │   └── default/                 # Six starter UnitData .tres files
│   │       ├── unit_01_soldier.tres
│   │       ├── unit_02_mercenary.tres
│   │       ├── unit_03_archer.tres
│   │       ├── unit_04_mage.tres
│   │       ├── unit_05_cleric.tres
│   │       └── unit_06_knight.tres
│   └── maps/
│       └── map_001_rout/
│           ├── map_001_data.tres    # MapData; terrain lives in MapData.grid
│           └── enemies/             # Enemy UnitData .tres files for this map
│               ├── e1_soldier.tres
│               ├── e2_archer.tres
│               ├── e3_mercenary.tres
│               ├── e4_knight.tres
│               ├── e5_archer.tres
│               ├── e6_soldier.tres
│               ├── e7_knight_sub.tres
│               └── e8_knight_boss.tres
│
├── scenes/
│   ├── core/
│   │   ├── Boot.tscn
│   │   └── GameMap.tscn
│   ├── units/
│   │   └── Unit.tscn
│   └── ui/
│       ├── ActionMenu.tscn
│       ├── AttackPreview.tscn
│       ├── GameOverScreen.tscn      # also shown for victory
│       ├── HUD.tscn
│       ├── ItemMenu.tscn
│       ├── LevelUpScreen.tscn
│       ├── MainMenu.tscn
│       ├── MapMenu.tscn
│       ├── NewGameScreen.tscn
│       ├── PhaseBanner.tscn
│       └── SettingsScreen.tscn
│       # CombatHUD has no scene — CombatHUD.gd is attached to a bare
│       # CanvasLayer inside GameMap.tscn and builds its labels in code.
│
└── scripts/
    ├── autoloads/
    │   ├── ConditionManager.gd       # status-condition stub (M8)
    │   ├── DataManager.gd
    │   ├── EventBus.gd
    │   ├── GameState.gd
    │   └── SettingsManager.gd
    ├── core/
    │   ├── Boot.gd
    │   ├── CombatResolver.gd         # also an autoload (/root/CombatResolver)
    │   ├── EnemyAI.gd                # also an autoload (/root/EnemyAI)
    │   ├── GameMap.gd
    │   ├── GridManager.gd            # scene node, child of GameMap
    │   ├── MapCursor.gd              # scene node, child of GameMap
    │   ├── MapCursorInput.gd         # RefCounted slice — key decode + auto-repeat
    │   ├── MapCursorSelection.gd     # RefCounted slice — selection + path planning
    │   ├── MapCursorTargeting.gd     # RefCounted slice — attack/staff targeting
    │   └── TurnManager.gd            # scene node, child of GameMap
    ├── items/
    │   └── ItemHandler.gd            # autoload — item-effect dispatcher
    ├── resources/
    │   ├── ClassData.gd
    │   ├── InventoryEntry.gd
    │   ├── ItemData.gd
    │   ├── MapData.gd
    │   ├── SkillData.gd
    │   ├── UnitData.gd
    │   └── WeaponData.gd
    ├── shared/
    │   └── GameConstants.gd          # autoload — project-wide constants
    ├── skills/
    │   └── SkillHandler.gd           # autoload — skill-effect dispatcher
    ├── tests/                        # 18 test_*.gd suites; run via run_tests.sh
    ├── tools/                        # placeholder-asset + tileset generators
    ├── ui/
    │   ├── ActionMenu.gd
    │   ├── AttackPreview.gd
    │   ├── CombatHUD.gd
    │   ├── GameOverScreen.gd
    │   ├── HUD.gd
    │   ├── ItemMenu.gd
    │   ├── LevelUpScreen.gd
    │   ├── MainMenu.gd
    │   ├── MapMenu.gd
    │   ├── NewGameScreen.gd
    │   ├── PhaseBanner.gd
    │   └── SettingsScreen.gd
    └── units/
        └── Unit.gd
```

---

## Scene Node Trees

### `GameMap.tscn`
Root scene for every battle. Instanced fresh per map.

```
GameMap (Node2D)                 # script: GameMap.gd
├── TileMapLayer_Terrain         # base terrain tiles, painted at runtime from MapData.grid
├── TileMapLayer_Overlay         # movement/attack/heal/danger highlight tiles
├── UnitsContainer (Node2D)      # all Unit scenes instanced here at runtime
├── GridManager (Node)           # script: GridManager.gd
├── MapCursor (Node2D)           # script: MapCursor.gd
│   └── AnimatedSprite2D         # [PLACEHOLDER] cursor blink animation
├── Camera2D                     # follows cursor; clamps to map bounds
├── TurnManager (Node)           # script: TurnManager.gd
├── HUDMainLayer (CanvasLayer)
│   └── HUD                      # HUD.tscn instance; script: HUD.gd
└── CombatHUDLayer (CanvasLayer) # script: CombatHUD.gd; builds its labels in code
```

> **Note:** `CombatResolver` and `EnemyAI` are **autoload singletons**
> (`/root/CombatResolver`, `/root/EnemyAI`) — they are *not* children of
> `GameMap`. Code reaches them via `get_node_or_null("/root/...")`.

### `Boot.tscn`
The first scene loaded by Godot (set as the main scene in `project.godot`).
For MVP it is a plain `Node` with a single script that immediately transitions
to the Main Menu. In Phase 2+ this is where a splash screen or loading bar
would live.

```gdscript
# scripts/core/Boot.gd
extends Node

func _ready() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
```

### `Unit.tscn`
One instance per unit on the map.

```
Unit (Node2D)                       # script: Unit.gd
├── Sprite2D                        # [PLACEHOLDER] 64x64 class sprite; team-tinted in code
└── HPBar (ProgressBar)             # small bar above sprite; max_value = data.max_hp
```

> `Unit.gd` references only `$Sprite2D` and `$HPBar`. A condition-icon node and a
> selection-highlight node are planned (`[PLACEHOLDER]`) but not yet wired.

### `HUD.tscn`

The HUD is built from separately-instanced scenes (`ActionMenu.tscn`, `ItemMenu.tscn`,
`AttackPreview.tscn`, `PhaseBanner.tscn`, `LevelUpScreen.tscn`, `MapMenu.tscn`,
`SettingsScreen.tscn`, `GameOverScreen.tscn`, `NewGameScreen.tscn`). The tree below is
the intended composition — the `.tscn` files are authoritative for exact node names
and paths (verified to match each script's `@onready` paths).

```
HUD (CanvasLayer)
├── UnitInfoPanel (PanelContainer)          # Anchor: bottom-left; 300x110 px
│   ├── PortraitRect (TextureRect)          # [PLACEHOLDER] 64x64 unit portrait (2× the 32x32 sprite)
│   ├── NameLabel (Label)
│   ├── ClassLabel (Label)
│   ├── HPLabel (Label)                     # e.g. "HP  17 / 21"
│   └── WeaponLabel (Label)                 # Equipped weapon name or "---"
├── TerrainInfoPanel (PanelContainer)       # Anchor: bottom-right; 200x80 px
│   ├── TerrainNameLabel (Label)
│   ├── DefBonusLabel (Label)               # e.g. "DEF +1"
│   └── DodgeBonusLabel (Label)             # e.g. "Dodge +15"
├── TurnCounterLabel (Label)                # Anchor: top-right; e.g. "Turn  3"
├── ActionMenu (PanelContainer)             # Shown after unit moves; hidden by default
│   └── Panel/VBox
│       ├── BtnAttack (Button)
│       ├── BtnStaff (Button)
│       ├── BtnItem (Button)
│       └── BtnWait (Button)                # Trade is designed but NOT yet implemented
│   # ItemMenu.tscn is a separate submenu opened by the Item action.
├── AttackPreview (PanelContainer)          # Centered bottom; shown when targeting
│   ├── AttackerColumn (VBoxContainer)
│   │   ├── AttackerNameLabel (Label)
│   │   ├── AttackerHitLabel (Label)        # "Hit: 82%"
│   │   ├── AttackerDmgLabel (Label)        # "Dmg: 7"
│   │   └── AttackerCritLabel (Label)       # "Crit: 5%"
│   └── DefenderColumn (VBoxContainer)
│       ├── DefenderNameLabel (Label)
│       ├── DefenderHitLabel (Label)        # "--" if cannot counterattack
│       ├── DefenderDmgLabel (Label)
│       └── DefenderCritLabel (Label)
│   # No TargetSelectList: target selection uses red/green overlay tiles plus
│   # cursor cycling among valid target tiles (see MapCursorTargeting.gd).
├── PhaseBanner (ColorRect)                 # Full-width (1280x80); slides from off-screen
│   └── BannerLabel (Label)                 # "PLAYER PHASE" | "ENEMY PHASE"
├── LevelUpScreen (PanelContainer)          # Centered; 400x300; blocks all input
│   ├── UnitNameLabel (Label)
│   ├── LevelLabel (Label)
│   └── StatGrid (GridContainer)            # 8 stats; highlight changed ones in yellow
├── MapMenu (PanelContainer)                # Centered overlay; shown on Escape
│   └── VBoxContainer
│       ├── EndTurnButton (Button)
│       ├── SettingsButton (Button)
│       └── QuitButton (Button)
├── SettingsScreen (PanelContainer)         # Full screen; shown from MapMenu or MainMenu
└── GameOverScreen (ColorRect)              # Full-screen overlay; handles BOTH the
                                            #   defeat ("GAME OVER" + Retry) and the
                                            #   victory states. There is no separate
                                            #   VictoryScreen scene.
```

---

## Autoload Singletons

### `GameState.gd`

Autoload. Holds per-save rules, live map state, and the cross-map roster/economy.
No `class_name` — Godot 4 forbids `class_name` on an autoload script.

```gdscript
extends Node

enum Phase { PLAYER, ENEMY }

# --- Per-save gameplay rules (set by the New Game screen) ---
var permadeath_enabled: bool = false
var leveling_method: String = "growth_random"   # "growth_random" | "growth_fixed"
var max_skills: int = 4        # NOT ENFORCED YET — no equip/inventory UI caps these
var max_inventory: int = 8     # NOT ENFORCED YET

# --- Current map state ---
var current_phase: Phase = Phase.PLAYER
var turn_number: int = 1
var all_units: Array[Node] = []
var _player_units: Array[Node] = []   # private — query via get_living_player_units()
var _enemy_units: Array[Node] = []    # private — query via get_living_enemy_units()
var map_data: MapData = null

# --- Persists between maps ---
var player_roster: Array[UnitData] = []
var party_gold: int = 0
var party_items: Array[String] = []   # item IDs awarded by completed maps

# --- Map-start snapshot — deep copy taken at map load; used by Retry ---
var _map_start_snapshot: Array[Dictionary] = []
var _snapshot_party_gold: int = 0
var _snapshot_party_items: Array[String] = []

func register_unit(unit: Node) -> void
func unregister_unit(unit: Node) -> void
func set_phase(new_phase: Phase) -> void
func get_living_player_units() -> Array[Node]
func get_living_enemy_units() -> Array[Node]
func is_player_turn() -> bool
func reset_map_state() -> void
func load_default_roster() -> void
    # Loads the six .tres files from data/roster/default/ into player_roster.
    # Skips (push_error) any file with an empty unit_id. Called by the New Game
    # screen, and as a fallback by GameMap if the roster is empty (direct boot).

func take_map_snapshot() -> void
    # Called by GameMap after units spawn. Deep-copies each player UnitData and
    # the party economy (gold/items) into the snapshot so Retry rolls back exactly.
    # Each InventoryEntry is duplicated individually — Array.duplicate(true) shares
    # Resource references, so combat use would otherwise mutate the snapshot.

func restore_map_snapshot() -> void
    # Called by the Retry button. Overwrites each roster UnitData and the party
    # economy from the snapshot, then resets map state. Caller reloads the scene.
```

### `SettingsManager.gd`

Persists global player preferences to `user://settings.cfg` via `ConfigFile`.
Loaded once at startup (`_ready()`); written immediately on any change.
Registered as an autoload after `EventBus` and before `GameState`.

> Permadeath and leveling method are **not** here — they are per-save gameplay
> rules and live on `GameState`, set via the New Game screen.

```gdscript
extends Node

const SETTINGS_PATH := "user://settings.cfg"

# --- Audio (0–100 int scale) ---
var master_volume: int = 80
var music_volume: int  = 70
var sfx_volume: int    = 90

# --- Gameplay ---
var combat_animations: String = "all"      # "all"|"player_only"|"enemy_only"|"none"
                                            # NOTE: scaffolded — no combat-animation
                                            # system reads this yet.
var movement_speed: String = "normal"       # "normal" | "fast" | "instant"
var phase_banner: String = "show"           # "show" | "skip"
var level_up_screen: String = "show"        # "show" | "auto" | "skip"
var mouse_targeting: String = "snap"        # "snap" | "disabled"

# --- Controls ---
# { action_name: Array[InputEvent] }; applied to InputMap at startup.
var keybindings: Dictionary = {}

func _ready() -> void:
    load_settings()
    _apply_audio()
    _apply_keybindings()
    _mirror_game_keys_to_ui()

func load_settings() -> void
    # Reads user://settings.cfg via ConfigFile; falls back to defaults per key.
    # Stale permadeath/leveling_method keys from old config files are ignored.

func save() -> void
    # Writes all current values to user://settings.cfg.

func reset_section_to_defaults(section: String) -> void
    # section: "audio" | "controls" | "gameplay"

func _apply_audio() -> void
    # Converts 0–100 ints to decibels and sets each AudioServer bus.
    # Buses are looked up by NAME (get_bus_index("Master"/"Music"/"SFX")), so
    # editor bus order does not matter; missing buses are silently skipped.

func _apply_keybindings() -> void
    # InputMap.action_erase_events() + action_add_event() per bound action.

func _mirror_game_keys_to_ui() -> void
    # Copies the cursor_*/confirm/cancel events onto Godot's built-in ui_* actions
    # so menus (which navigate via ui_*) respond to the same keys as in-game (WASD/Z/X).

func set_volume(bus_name: String, value: int) -> void   # updates var, applies, saves
func rebind_action(action_name: String, event: InputEvent) -> void
func get_movement_speed_seconds() -> float
    # Per-tile tween duration: "normal" -> 0.12 | "fast" -> 0.06 | "instant" -> 0.0
```

### `DataManager.gd`

Autoload. Loads every content `.tres` at startup so bad data fails loud at boot.

```gdscript
extends Node

var _classes: Dictionary = {}
var _weapons: Dictionary = {}
var _items: Dictionary = {}
var _skills: Dictionary = {}
# The weapon triangle lives in GameConstants.WEAPON_TRIANGLE — the single source
# of truth, shared with CombatResolver. DataManager no longer holds its own copy.

func _ready() -> void:
    _load_directory("res://data/classes/", _classes)
    _load_directory("res://data/weapons/", _weapons)
    _load_directory("res://data/items/", _items)
    _load_directory("res://data/skills/", _skills)
    for skill in _skills.values():
        skill.validate()
    _validate_cross_references()   # class starting_skills + skill activation stats

func _load_directory(path: String, target: Dictionary) -> void
func get_class_data(id: String) -> ClassData   # named *_data, not get_class, to avoid
                                               # Godot's Object.get_class() override warning
func get_weapon(id: String) -> WeaponData
func get_item(id: String) -> ItemData
func get_skill(id: String) -> SkillData
func get_weapon_triangle_result(attacker_type: String, defender_type: String) -> String
    # "advantage" | "disadvantage" | "neutral" — reads GameConstants.WEAPON_TRIANGLE.
```

### `EventBus.gd`

Autoload. Central signal bus — systems emit here instead of referencing each other.

```gdscript
extends Node

signal unit_selected(unit: Node)
signal unit_deselected()
signal unit_moved(unit: Node, from_tile: Vector2i, to_tile: Vector2i)
signal unit_action_taken(unit: Node)
signal combat_started(attacker: Node, defender: Node)
# combat_resolved is emitted AFTER handle_death() on any loser — listeners MUST
# is_instance_valid() before dereferencing attacker/defender across frames.
signal combat_resolved(attacker: Node, defender: Node, result: Dictionary)
signal unit_damaged(unit: Node, amount: int)
signal unit_died(unit: Node)
signal unit_healed(unit: Node, amount: int)
signal unit_leveled_up(unit: Node, stat_increases: Dictionary)
signal phase_changed(new_phase: int)   # carries a GameState.Phase value, typed int
signal cursor_moved(tile: Vector2i)
signal map_victory()
signal map_defeat()
```

> `TurnManager` exposes its own `turn_changed(turn_number: int)` signal (not on the
> bus). Condition/Laguz signals (`condition_applied`, `shift_gauge_changed`, …) are
> planned for M8/M12 and are not declared yet.

### `ConditionManager.gd` (stub until M8)

Autoload, registered after `DataManager`. All methods are no-ops until Milestone 8;
it exists now so other systems can call into it without `get_node_or_null` guards.

```gdscript
extends Node

const CONDITION_POISON   := "poison"
const CONDITION_SLEEP    := "sleep"
const CONDITION_SILENCE  := "silence"
const CONDITION_BERSERK  := "berserk"
const CONDITION_STUN     := "stun"

func apply_condition(unit: Node, condition_type: String, duration: int) -> void
func remove_condition(unit: Node, condition_type: String) -> void
func tick_conditions(unit: Node) -> void
    # Called by TurnManager at the start of each unit's activation.
    # Applies per-turn effects (e.g. Poison damage) and decrements durations.
func has_condition(unit: Node, condition_type: String) -> bool
func clear_all_conditions(unit: Node) -> void
    # Called by Restore staff and Panacea item.
```

---

## Key Script Function Signatures

### `GridManager.gd`

`class_name GridManager`. A scene node, child of `GameMap`. Authority on map geometry.

```gdscript
class_name GridManager extends Node

var map_width: int = 0
var map_height: int = 0
# Terrain bonuses applied to defenders only:
const TERRAIN_DEF_BONUS: Dictionary    # plain 0, forest 1, mountain 2, fort 2, sea/desert 0
const TERRAIN_DODGE_BONUS: Dictionary  # plain 0, forest 15, mountain 20, fort 30, sea 10, desert 5

func setup(terrain_layer, overlay_layer, width, height) -> void   # wired by GameMap

# Terrain / queries
func get_terrain_at(tile: Vector2i) -> String
    # "plain"|"forest"|"mountain"|"fort"|"sea"|"desert"|"wall"; out-of-bounds -> "wall"
func is_passable(tile: Vector2i, unit: Node) -> bool
func can_end_on_tile(tile: Vector2i, unit: Node) -> bool   # cannot stop on any occupant
func get_unit_at(tile: Vector2i) -> Node                   # null if empty
func world_to_tile(world_pos: Vector2) -> Vector2i
func tile_to_world(tile: Vector2i) -> Vector2              # top-left corner of tile
func get_move_cost(tile: Vector2i, unit: Node) -> int
    # 1 plain/fort; 2 forest/sea/desert; 3 mountain; 3 armoured/mounted on desert;
    # 999 wall. Consults SkillHandler movement overrides first.

# Movement (Dijkstra)
func dijkstra_costs(start, max_cost, ignore_occupants, blocker_unit, came_from := {}) -> Dictionary
    # Shared cost flood behind the queries below. Returns { tile: cost }.
func get_movement_range(unit: Node) -> Array[Vector2i]
    # Tiles the unit can legally stop on; capped at unit.data.movement.
func get_movement_path(unit: Node, target_tile: Vector2i) -> Array[Vector2i]
    # Ordered path; [] if unreachable. Named *_path, not get_path_to, to avoid the
    # Node.get_path_to() built-in override warning.

# Attack / staff range
func get_attack_range_from_tiles(unit, from_tiles) -> Array[Vector2i]
func get_all_attack_tiles(unit, from_tiles) -> Array[Vector2i]
func get_attackable_enemies_from_tile(unit, tile) -> Array[Node]
func can_attack_from_tile(attacker, at_tile, target) -> bool
func in_weapon_range_from_tile(unit, at_tile, target) -> bool   # range only; allows staves
func get_healable_allies(unit: Node) -> Array[Node]             # allies in staff range, hurt

# Overlays
func show_movement_overlay(tiles) -> void   # blue
func show_attack_overlay(tiles) -> void     # red
func show_heal_overlay(tiles) -> void       # green
func get_enemy_danger_tiles() -> Array[Vector2i]  # threat = each enemy's move range + attack reach
func show_enemy_danger_zone() -> void       # paints get_enemy_danger_tiles() in dark red
func clear_overlays() -> void
```

### `CombatResolver.gd`

Autoload. The combat math engine. Resolution is **two-phase**: `resolve_combat()`
builds the exchange list and rolls RNG; `apply_combat_result()` commits the outcome.
Splitting them lets weapon breakage and skill triggers be modelled during simulation
before any state is mutated. See the `CombatResolver.gd` header for the full
combat-context dictionary schema.

```gdscript
extends Node

# Phase 1 — build the exchange list and roll RNG. No HP/EXP applied yet.
func resolve_combat(attacker: Node, defender: Node) -> Dictionary
# Returns {
#   "exchanges": [ { attacker, defender, weapon, hit, crit, damage,
#                    loses_durability, is_counter, is_follow_up } ],
#   "attacker_died": bool,   # from the simulated HP
#   "defender_died": bool,
#   "context": Dictionary,
# }

# Phase 2 — commit the result: durability, HP (take_damage), wEXP, EXP, deaths.
# Adds "attacker_exp"/"defender_exp" to result; emits combat_started/combat_resolved.
func apply_combat_result(result: Dictionary, attacker: Node, defender: Node) -> void

# Forecast — no RNG, no lasting side effects (snapshots and restores unit state).
func preview_combat(attacker: Node, defender: Node) -> Dictionary
# Returns {
#   attacker_hit, attacker_damage, attacker_crit, attacker_attacks,
#   can_counter, defender_hit, defender_damage, defender_crit, defender_attacks,
#   attacker_weapon, defender_weapon, defender_vantage
# }

# Stat helpers (also used by EnemyAI). Each takes an optional context Dictionary.
func compute_hit_pct(attacker, defender, weapon := null, context := {}) -> int
func compute_damage(attacker, defender, weapon := null, context := {}) -> int
func compute_crit_pct(attacker, defender, weapon := null, context := {}) -> int
func can_counterattack(defender: Node, attacker_tile: Vector2i) -> bool
func get_follow_up_attacker(a: Node, b: Node) -> Node   # null if no follow-up
func calculate_exp(attacker: Node, defender: Node, killed: bool) -> int
```

> Battle speed is not a CombatResolver method — it is `Unit.battle_speed()`.
> The hit/crit roll is inline `(randi() % 100) < pct` (see GDD_02 → Combat Resolution).

### `TurnManager.gd`

`class_name TurnManager`. A scene node, child of `GameMap`. Owns phase progression
and per-unit action state.

```gdscript
class_name TurnManager extends Node

signal turn_changed(turn_number: int)

enum UnitState { READY, MOVED, DONE }

var _unit_states: Dictionary = {}     # Node -> UnitState
var _original_tiles: Dictionary = {}  # Node -> pre-move tile, for undo
var _map_over: bool = false           # latches on first victory/defeat emit

func start_map(map_data: MapData, grid: GridManager = null) -> void
func start_player_phase() -> void
func end_player_phase() -> void       # increments turn_number, fires turn_changed
func start_enemy_phase() -> void      # awaits EnemyAI.run_enemy_phase()
func set_unit_state(unit: Node, state: UnitState) -> void
    # Marking the last player unit DONE auto-ends the player phase (deferred via
    # _auto_end_player_phase, which re-validates and bails if the map is over).
func get_unit_state(unit: Node) -> UnitState
func can_unit_act(unit: Node) -> bool          # READY or MOVED
func are_all_player_units_done() -> bool
func record_move_start(unit: Node) -> void     # stores pre-move tile for undo
func undo_move(unit: Node) -> void             # restores tile, returns unit to READY
func check_victory_conditions() -> void
    # Reads MapData.objective_type. MVP supports "rout". Also handles turn-limit
    # defeat, all-players-dead defeat, and required_survivor_ids defeat.
```

### `Unit.gd`

`class_name Unit`. One scene instance per unit on the map; wraps a `UnitData`.

```gdscript
class_name Unit extends Node2D

var data: UnitData
var team: String = "player"   # "player" | "enemy"
var tile_position: Vector2i   # pass-through property to data.tile_position

func initialize(unit_data: UnitData, start_tile: Vector2i, unit_team: String) -> void
func set_grid_manager(grid: GridManager) -> void   # cached by GameMap; avoids tree walks
func get_equipped_weapon() -> WeaponData           # first usable equipped weapon, or null
func get_equipped_weapon_entry() -> InventoryEntry # the matching InventoryEntry, or null
func has_quality(quality: String) -> bool
func get_terrain_def_bonus() -> int
func get_terrain_dodge_bonus() -> int

# Stat access — all combat stats read through get_effective_stat so modifiers apply
func get_effective_stat(stat_name: String) -> int
    # Base value + active_modifiers matching stat_name, clamped >= 0. stat_name must
    # match a UnitData property exactly: "strength","magic","defense","resistance",
    # "skill","speed","luck","hp" — the FULL names, never "str"/"spd"/etc.
func has_skill(skill_id: String) -> bool
func get_skill_uses_remaining(effect_id: String, max_per_map: int) -> int
func consume_skill_use(effect_id: String) -> void

# Modifier lifecycle
func add_modifier(stat, delta, source, duration, duration_type) -> void
func remove_modifier(source: String) -> void
func tick_modifiers(duration_type: String) -> void   # "turn" / "map_turn"
func clear_combat_modifiers() -> void                # called after each combat
func reset_map_state() -> void                       # before take_map_snapshot()

# Combat stats (optional weapon override; default = currently equipped weapon)
func battle_speed(weapon := null) -> int
func accuracy(weapon := null) -> int
func dodge(weapon := null) -> int
func crit_rate(weapon := null) -> int
func crit_avoid() -> int

# HP / death
func take_damage(amount: int) -> void
func heal(amount: int) -> void
func perform_staff_heal(target: Node, weapon: WeaponData) -> void   # shared by player + AI
func handle_death() -> void

# Movement
func move_along_path(path: Array[Vector2i]) -> void   # async; Tween; await to block
func snap_to_tile(tile: Vector2i) -> void             # instant; used by AI and undo

# Inventory / progression
func use_weapon_durability(weapon_id: String = "") -> bool   # true if the weapon broke
func can_equip(weapon_data: WeaponData) -> bool
func add_exp(amount: int) -> void
func level_up() -> void
func add_wexp(weapon_type: String, amount: int) -> bool      # true if a rank-up occurred

# Visual state
func set_done_appearance() -> void     # darkened sprite when DONE
func reset_appearance() -> void        # back to normal at phase start
```

> There is no `Unit.damage()` method — per-attack damage is computed only by
> `CombatResolver.compute_damage()`.

### `MapCursor.gd`

`class_name MapCursor`. A scene node, child of `GameMap`. The cursor FSM, camera,
and menu wiring. Three concerns are sliced into `RefCounted` helpers, injected via
`setup()` so they are unit-testable without a SceneTree:
`MapCursorSelection` (unit selection + path planning), `MapCursorTargeting`
(attack/staff targeting flow), and `MapCursorInput` (key decode + auto-repeat).

```gdscript
class_name MapCursor extends Node2D

var current_tile: Vector2i = Vector2i(0, 0)

enum State { FREE, UNIT_SELECTED, UNIT_MOVED, TARGETING, LOCKED }
var _state: State = State.FREE

func setup(grid: GridManager, camera: Camera2D, turn: TurnManager = null) -> void
func move_cursor(direction: Vector2i) -> void
func center_on_tile(tile: Vector2i) -> void   # jump the cursor to a tile (GameMap uses
                                              # this to start it on the first player unit)
func _on_confirm() -> void
func _on_cancel() -> void
func lock() -> void      # input suppressed (animation, enemy phase); also clears the danger zone
func unlock() -> void
func _scroll_camera_if_needed() -> void
```

> **Menu wiring.** `MapCursor` exports `Node` refs to the HUD-layer menus
> (`action_menu`, `item_menu`, `map_menu`, `attack_preview`, `settings_screen`).
> Exported `NodePath`s to nodes declared later in `GameMap.tscn` can resolve to
> `null` at scene-build time, so `_resolve_menu_refs()` re-resolves any null ref
> via `get_node_or_null()` in `_ready()` before wiring signals.

> Key-repeat timing lives in `GameConstants` (`CURSOR_KEY_REPEAT_DELAY` 0.25 s /
> `CURSOR_KEY_REPEAT_RATE` 0.10 s) and `MapCursorInput` — there is no `CURSOR_SPEED`.
> The Phase-2 camera-zoom hooks (`ZOOM_LEVELS`, `_handle_zoom`) are not yet added
> (see the Camera Zoom section).

---

## Rendering and Display Settings

Set in **Project → Project Settings**:

```
Display/Window/Size/Viewport Width:   1280
Display/Window/Size/Viewport Height:  720
Display/Window/Stretch/Mode:          canvas_items
Display/Window/Stretch/Aspect:        keep
Rendering/2D/Snap/Snap 2D Vertices To Pixel: ON
```

Tile size: **64 × 64 pixels** (matches GDD_06 tileset spec)
Visible tiles at native resolution: approximately **20 × 11**
Camera clamps to map bounds so empty space is never shown.

> **Note:** earlier drafts of this document specified 32×32 tiles. The project
> standardized on 64×64 to match the GDD_06 tileset spec and the placeholder
> sprite sizes in the checklist. `GameConstants.TILE_SIZE = 64` is authoritative
> (defined in `scripts/shared/GameConstants.gd`).

---

## Input Map

Define these actions in **Project → Project Settings → Input Map**:

| Action Name | Default Keys | Mouse Equivalent |
|---|---|---|
| `cursor_up` | W, Up Arrow | — |
| `cursor_down` | S, Down Arrow | — |
| `cursor_left` | A, Left Arrow | — |
| `cursor_right` | D, Right Arrow | — |
| `confirm` | Z, Enter, Space | Left Click |
| `cancel` | X, Escape | Right Click |
| `next_unit` | Tab | — |
| `prev_unit` | Shift+Tab | — |
| `open_menu` | M | — (the map menu also opens via confirm/cancel on an empty tile) |
| `open_settings` | O | — |
| `show_danger_zone` | Q | Middle Click |
| `end_turn` | — | — (accessed via Map Menu) |
| `zoom_in` | + / = | Scroll Up — [PLACEHOLDER Phase 2] |
| `zoom_out` | - | Scroll Down — [PLACEHOLDER Phase 2] |
| `zoom_reset` | 0 | — [PLACEHOLDER Phase 2] |

---

## Resource Class Definitions

The full `@export` field definitions for every custom Resource class. Each class
lives in `scripts/resources/` and is saved as `.tres` files in its `data/` subfolder.

> **Headless `.tres` note:** in `--script` runs the global class registry is not
> initialized, so `.tres` files are written with `type="Resource"` and the real
> class assigned via the `script = ExtResource(...)` line — see Implementation Notes.

### `UnitData.gd`

```gdscript
class_name UnitData extends Resource

@export var unit_id: String = ""           # unique id — survivor checks & save/load
@export var unit_name: String = ""
var tile_position: Vector2i = Vector2i.ZERO
    # NOT @export — runtime map state. Captured by GameState's manual snapshot,
    # not by ResourceSaver. Unit.tile_position is a pass-through to this field.
@export var class_id: String = ""
@export var level: int = 1
@export var exp: int = 0
@export var is_promoted: bool = false
@export var effective_level: int = 1       # pre + post promotion levels combined

# Stats — FULL property names. Combat code reads these via Unit.get_effective_stat().
@export var max_hp: int = 0
@export var hp: int = 0                    # current HP
@export var strength: int = 0
@export var magic: int = 0
@export var defense: int = 0
@export var resistance: int = 0
@export var skill: int = 0
@export var speed: int = 0
@export var luck: int = 0
@export var movement: int = 0
@export var constitution: int = 0
@export var line_of_sight: int = 4

# Proficiencies — { "sword": { "rank": "D", "wexp": 0 } }
@export var proficiencies: Dictionary = {}

# Equippable skill IDs (max GameState.max_skills — cap not yet enforced)
@export var skills: Array[String] = []
# Earned mastery skills (e.g. s_rank_mastery). NOT @export — populated at runtime
# by Unit.add_wexp(); never authored in .tres; never count against the skill cap.
var mastery_skills: Array[String] = []

# Typed inventory — Array[InventoryEntry] (replaced the old Array[Dictionary]).
@export var inventory: Array[InventoryEntry] = []

# Conditions — Array of Dictionaries; see GDD_02 status conditions
@export var conditions: Array[Dictionary] = []

@export var gold: int = 1000
@export var is_incapacitated: bool = false  # permadeath flag
@export var ai_profile: String = "basic"    # EnemyAI dispatch — see GDD_08
@export var is_default_roster: bool = false # true for the 6 generated starter units

# ── Phase 2 runtime state ────────────────────────────────────────────────────
# Active temporary stat modifiers. Each entry:
#   { "stat": String, "delta": int, "source": String, "duration": int,
#     "duration_type": "turn"|"map_turn"|"combat"|"permanent" }
# duration -1 or "permanent" type = never auto-removed.
@export var active_modifiers: Array[Dictionary] = []
var skill_use_counters: Dictionary = {}     # NOT @export — effect_id -> uses this map
var damage_taken_this_map: int = 0          # NOT @export — used by Vengeance (M9)
@export var growth_accumulators: Dictionary = {}   # carry-over for growth_fixed leveling

# Laguz fields — safe defaults for all Beorc units; ignored until M12.
@export var shift_gauge: int = 0
@export var is_shifted: bool = false
@export var shift_profile_id: String = ""
```

> The non-`@export` fields (`tile_position`, `mastery_skills`, `skill_use_counters`,
> `damage_taken_this_map`) are runtime state. `GameState`'s map snapshot copies them
> by hand for Retry; a future `ResourceSaver`-based save must serialize them via that
> snapshot dict (a `ResourceSaver` write does not persist non-exported vars).

### `InventoryEntry.gd`

A unit's inventory is `Array[InventoryEntry]` — a typed `Resource`, **not** the old
`Array[Dictionary]` format. One `InventoryEntry` per slot; `entry_type` discriminates.

```gdscript
class_name InventoryEntry extends Resource

@export var entry_type: String = ""    # "weapon" | "item" | "equip"

# Weapon fields
@export var weapon_id: String = ""     # must match a WeaponData id
@export var forged_mods: Dictionary = {}   # reserved for forging (M10)

# Item fields
@export var item_id: String = ""       # must match an ItemData id

# Shared — remaining uses. -1 = infinite, 0 = exhausted, >0 = finite.
# Equip-type entries ignore this (gate them with is_equip()).
@export var uses_remaining: int = 0

# Equipment bonus fields (equip type — M10 forging)
@export var accuracy: int = 0
@export var damage: int = 0
@export var crit: int = 0
@export var dodge: int = 0

func is_weapon() -> bool       # entry_type == "weapon"
func is_item() -> bool         # entry_type == "item"
func is_equip() -> bool        # entry_type == "equip"
func has_uses() -> bool        # uses_remaining != 0
func validate() -> bool        # checks type/id consistency
static func make_weapon(weapon_id: String, uses: int) -> InventoryEntry
static func make_item(item_id: String, uses: int) -> InventoryEntry
```

`Unit.get_equipped_weapon()` returns the first `is_weapon()` entry that still
`has_uses()` and whose `WeaponData` the unit can equip (proficiency rank check).
Items are never auto-equipped.

### `WeaponData.gd`

```gdscript
class_name WeaponData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var weapon_type: String = ""
    # "sword" | "lance" | "axe" | "bow" | "knife"
    # | "fire" | "thunder" | "wind" | "light" | "dark" | "staff"
@export var rank: String = "E"            # "E" | "D" | "C" | "B" | "A" | "S"
@export var mt: int = 0                   # staves: 0 (heal = 10 + MAG, computed separately)
@export var hit: int = 0                  # staves: 0 (healing always lands)
@export var crit: int = 0                 # staves: 0 (staves cannot crit)

# Range as formula strings so dynamic ranges (e.g. Physic "MAG/2") work uniformly.
# Static weapons store integer strings ("1", "2"). Always read via get_range_min/max().
@export var range_min_formula: String = "1"
@export var range_max_formula: String = "1"

@export var wt: int = 0
@export var uses: int = 1
@export var cost: int = 0
@export var wexp: int = 1                 # wEXP granted per successful hit
@export var effect_tags: Array[String] = []   # see GDD_04 for the full tag list
@export var uses_mag: bool = false        # true: MAG for damage, targets RES (tomes)
@export var magic_triangle_type: String = ""   # hybrid weapons only (e.g. Bolt Axe)
@export var strikes_per_attack: int = 1   # 2 for Brave weapons
@export var is_natural_weapon: bool = false    # Laguz Fang/Claw/Beak/Talon (deferred)

func is_healing_staff() -> bool                # staff type + heal_10_plus_mag tag
func get_range_min(unit: Node = null) -> int   # evaluates range_min_formula
func get_range_max(unit: Node = null) -> int   # evaluates range_max_formula
```

**Staff note:** healing staves have `weapon_type = "staff"` and the `heal_10_plus_mag`
effect tag. `is_healing_staff()` keys off the **tag** (not the type), so future
offensive/debuff staves remain attack-capable. Healing staves cannot attack or
counterattack — staff use runs through `Unit.perform_staff_heal()`, not `CombatResolver`.

### `ClassData.gd`

```gdscript
class_name ClassData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var base_hp: int = 0
@export var base_strength: int = 0
@export var base_magic: int = 0
@export var base_defense: int = 0
@export var base_resistance: int = 0
@export var base_skill: int = 0
@export var base_speed: int = 0
@export var base_luck: int = 0
@export var base_movement: int = 0
@export var base_constitution: int = 0
@export var base_line_of_sight: int = 4
@export var proficiencies: Array[String] = []
    # Weapon type strings for starting proficiencies.
    # First entry starts at D rank; remaining start at E rank.
@export var starting_skills: Array[String] = []
@export var special_qualities: Array[String] = []
@export var promotes_to: Array[String] = []
@export var promotion_stat_increases: Dictionary = {}
@export var promotion_skill: String = ""
@export var occult_skill: String = ""
@export var growth_rates: Dictionary = {}
    # FULL stat-name keys, values 0–100:
    # { "hp": 75, "strength": 50, "magic": 5, "defense": 45,
    #   "resistance": 25, "skill": 50, "speed": 45, "luck": 40 }
@export var sprite_id: String = ""        # [PLACEHOLDER] links to sprite sheet row

# ── Laguz gauge parameters ───────────────────────────────────────────────────
# All default to 0/false/"" for Beorc classes — safe to ignore until M12.
@export var is_laguz: bool = false
@export var max_shift_gauge: int = 0
@export var shift_gauge_start: int = 0
@export var shift_gain_per_turn_humanoid: int = 0
@export var shift_gain_per_turn_animal: int = 0
@export var shift_gain_per_combat_humanoid: int = 0
@export var shift_gain_per_combat_animal: int = 0
@export var animal_stat_bonus_pct: float = 0.5    # +50%; reduced to +25% with Feral Instincts
@export var natural_weapon_type: String = ""       # "fang"|"claw"|"beak"|"talon"|"" for Beorc
@export var animal_con_bonus_pct: float = 0.75     # CON ~+75% in animal form
```

### `ItemData.gd`

```gdscript
class_name ItemData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var item_type: String = ""
    # "healing" | "stat" | "promotion" | "equip" | "key" | "sellable"
@export var uses: int = 1                 # -1 = infinite / equippable
@export var cost: int = 0
@export var effect_id: String = ""        # dispatched by ItemHandler ("heal_flat", "heal_full")
@export var effect_params: Dictionary = {}
```

### `SkillData.gd`

```gdscript
class_name SkillData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var trigger: String = ""
    # "passive" | "start_of_turn" | "on_attack" | "on_defend" | "on_hit"
    # | "on_kill" | "on_damaged" | "on_combat_start" | "on_combat_end"
    # | "on_move" | "on_level_up" | "player_activated"
    # | "on_combat_start_negate"  (pre-pass before on_combat_start — Nihil)
    # Phase 2: "on_combat_apply_modifiers" | "on_ally_attacked"
    # | "on_enemy_leaves_adjacent" | "on_map_start" | "on_shift"
@export var activation_chance_stat: String = ""
    # e.g. "skill" — empty string if the skill always triggers
@export var activation_divisor: int = 2    # 2 = SKL/2 % activation chance
@export var effect_id: String = ""         # dispatched by SkillHandler
@export var effect_params: Dictionary = {}
@export var is_player_activated: bool = false
@export var max_uses_per_map: int = -1     # -1 = unlimited (vs skill_use_counters)
@export var max_uses_per_combat: int = -1  # -1 = unlimited (reset after each combat)

func validate() -> void   # warns on missing id/effect_id/trigger; called by DataManager
```

### `MapData.gd`

```gdscript
class_name MapData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var tilemap_scene_path: String = ""
@export var objective_type: String = ""   # "rout"|"seize"|"boss"|"survive"|"defend"|"escape"
                                           # (MVP implements "rout")
@export var objective_params: Dictionary = {}
@export var turn_limit: int = 0            # 0 = no limit; defeat if exceeded
@export var player_start_tiles: Array[Vector2i] = []
@export var enemy_placements: Array[Dictionary] = []
    # Each entry: { "unit_data_path": String, "tile": Vector2i,
    #               "ai_profile": String, "is_boss": bool }
@export var required_survivor_ids: Array[String] = []   # unit_ids whose death = defeat
@export var reward_gold: int = 0
@export var reward_items: Array[String] = []
# Terrain string grid — one String per row; chars per GameMap._CHAR_TO_SOURCE
# (. F M T S D W). Height = grid.size(), width = grid[0].length().
@export var grid: Array[String] = []
# Camera start; Vector2i(-1,-1) = unset -> centroid of player_start_tiles.
@export var camera_start_tile: Vector2i = Vector2i(-1, -1)
```

---

## Camera Zoom

Camera zoom is planned as a **Phase 2** feature. The architecture below should
be built into `MapCursor.gd` and `Camera2D` from the start so zoom can be added
without restructuring.

### Design
- The player zooms using the scroll wheel or dedicated keyboard shortcuts
- Three discrete zoom levels: **0.75×** (zoomed out), **1×** (default), **1.5×** (zoomed in)
- At 0.75× zoom: approximately 53×29 tiles visible — useful for tactical overview
- At 1.5× zoom: approximately 27×15 tiles visible — useful for precise unit inspection
- Zoom is centered on the cursor's current tile, not the screen center
- Camera clamping still applies at all zoom levels (no black space shown)
- Pixel snapping (`Rendering/2D/Snap`) remains active at all zoom levels

### Input Actions to Add (Phase 2)
Add to Input Map:
| Action | Key | Mouse |
|---|---|---|
| `zoom_in` | + / = | Scroll Up |
| `zoom_out` | - | Scroll Down |
| `zoom_reset` | 0 | — |

### Architecture Hooks (Add Now)
Add these to `MapCursor.gd` even in MVP so Phase 2 zoom slots in cleanly:

```gdscript
# In MapCursor.gd

const ZOOM_LEVELS: Array[float] = [0.75, 1.0, 1.5]
const DEFAULT_ZOOM_INDEX: int = 1
var _zoom_index: int = DEFAULT_ZOOM_INDEX

func _handle_zoom(direction: int) -> void
    # direction: +1 = zoom in, -1 = zoom out
    # Clamps to ZOOM_LEVELS array bounds
    # Calls _apply_zoom()
    # [PLACEHOLDER — implement in Phase 2]

func _apply_zoom() -> void
    # Sets _camera.zoom = Vector2.ONE * ZOOM_LEVELS[_zoom_index]
    # Re-applies camera clamp limits adjusted for current zoom
    # [PLACEHOLDER — implement in Phase 2]
```

---

## Implementation Notes

Decisions made during initial implementation that affect future work. These do
not change the design but document non-obvious choices a fresh contributor would
otherwise repeat as bugs.

### Method names that collide with Godot built-ins

GDScript prints a warning (treated as error by default) when a class method
shadows a `Node` or `Object` built-in with a different signature. Two such
collisions came up; both were renamed:

- `DataManager.get_class(id)` → **`get_class_data(id)`** (collides with `Object.get_class() -> String`)
- `GridManager.get_path_to(...)` → **`get_movement_path(...)`** (collides with `Node.get_path_to(Node, bool) -> NodePath`)

When adding new methods to nodes, sanity-check against the engine docs.
Common at-risk names include `damage` (Node has none — fine to use as a method
on `Unit.gd`), `get_path`, `get_node`, `get_class`, `get_children`.

### Autoload load order

Project registration order (`project.godot [autoload]`) is the full ten:
`GameConstants → EventBus → SettingsManager → GameState → DataManager →
ConditionManager → SkillHandler → ItemHandler → CombatResolver → EnemyAI`.
Each autoload's `_ready()` runs in that order. Practical consequence: an autoload
must NOT touch a later autoload from its own `_ready()`. SettingsManager loads
settings from disk but does not push values to GameState; GameState pulls them
in its own `_ready()` instead.

`ConditionManager` is a stub until M8. It must be registered now so other systems
can call into it without `get_node_or_null` guards. `CombatResolver`, `EnemyAI`,
`SkillHandler`, and `ItemHandler` are autoload singletons reached via
`get_node_or_null("/root/...")` — they are not scene nodes.

### .tres files in headless mode

When `.tres` files are created via the editor, their header reads
`[gd_resource type="ClassData" ...]` (using the `class_name` of the custom
class). Godot resolves "ClassData" through the global class registry, which is
populated by `class_name`-bearing scripts.

In **headless `--script` runs**, the global class registry is not initialized.
A `.tres` with `type="ClassData"` then fails to load with "Cannot get class
'ClassData'". The fix used in this project: write `.tres` files with
`type="Resource"` and let the `script = ExtResource(...)` line in the resource
body assign the actual class. Custom-typed properties (e.g. `Array[Vector2i]`)
still serialize correctly because the script defines the property types.

The editor will rewrite the type to the proper class name on first save,
which is fine — both forms load correctly.

### Autoloads inside test scripts

A script run via `godot --headless --path <project> --script <script>` does
**not** parse identifiers like `GameState`, `EventBus`, etc. at compile time —
those identifiers are resolved by the editor at parse time, but `--script` mode
skips that step. Scripts that may run in test mode (anything in `scripts/core/`
or `scripts/units/`) must access autoloads via runtime lookup:

```gdscript
if is_inside_tree():
    var bus := get_node_or_null("/root/EventBus")
    if bus:
        bus.cursor_moved.emit(tile)
```

This pattern works in both runtime and test mode. The autoloads do load at
runtime even when test scripts are executed via `--script` — only the
**parse-time identifier resolution** fails. Runtime `get_node_or_null` works.

### Map painting is data-driven

`GameMap.gd` paints `TileMapLayer_Terrain` at runtime from a string grid
(`MAP_001` constant). This means new maps are added by writing a new constant
grid + a new MapData `.tres`, with no editor painting required. The string
grid format is documented in `GDD_06` map section.

`_validate_map()` asserts row count, row length, and that every char is a
known terrain on `_ready` — transcription bugs fail loud at map load.

### Test infrastructure

All tests live under `scripts/tests/test_*.gd` and run via
`./run_tests.sh` (a bash wrapper) or per-suite via
`godot --headless --path . --script res://scripts/tests/<name>.gd`.

Each test extends `SceneTree`, prints `OK`/`FAIL` lines, and exits with code
0/1 for green/red.

Tool scripts (`scripts/tools/`) regenerate placeholder assets and tilesets
deterministically — re-run them after sprite or terrain changes.
