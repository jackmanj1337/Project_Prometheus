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
│   │   ├── units/                   # [PLACEHOLDER] 32x32 unit sprites per class
│   │   ├── terrain/                 # [PLACEHOLDER] 32x32 tile sprites
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
│   ├── skills/
│   │   ├── renewal.tres
│   │   ├── vantage.tres
│   │   ├── nihil.tres
│   │   ├── resolve.tres
│   │   ├── miracle.tres
│   │   └── wrath.tres
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
│           ├── map_001.tscn
│           ├── map_001_data.tres
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
│   │   ├── GameMap.tscn
│   │   └── Boot.tscn
│   ├── units/
│   │   └── Unit.tscn
│   └── ui/
│       ├── MainMenu.tscn
│       ├── HUD.tscn
│       ├── UnitInfoPanel.tscn
│       ├── TerrainInfoPanel.tscn
│       ├── ActionMenu.tscn
│       ├── AttackPreview.tscn
│       ├── TargetSelectList.tscn
│       ├── LevelUpScreen.tscn
│       ├── MapMenu.tscn
│       ├── PhaseBanner.tscn
│       ├── SettingsScreen.tscn
│       ├── GameOverScreen.tscn
│       └── VictoryScreen.tscn
│
└── scripts/
    ├── autoloads/
    │   ├── GameState.gd
    │   ├── DataManager.gd
    │   ├── EventBus.gd
    │   └── SettingsManager.gd
    ├── resources/
    │   ├── ClassData.gd
    │   ├── WeaponData.gd
    │   ├── ItemData.gd
    │   ├── SkillData.gd
    │   ├── UnitData.gd
    │   └── MapData.gd
    ├── core/
    │   ├── TurnManager.gd
    │   ├── GridManager.gd
    │   ├── CombatResolver.gd
    │   └── MapCursor.gd
    ├── units/
    │   ├── Unit.gd
    │   └── UnitStatBlock.gd
    ├── skills/
    │   └── SkillHandler.gd
    ├── ai/
    │   └── EnemyAI.gd
    └── ui/
        ├── HUD.gd
        ├── UnitInfoPanel.gd
        ├── TerrainInfoPanel.gd
        ├── ActionMenu.gd
        ├── AttackPreview.gd
        ├── TargetSelectList.gd
        ├── LevelUpScreen.gd
        ├── MapMenu.gd
        ├── PhaseBanner.gd
        └── SettingsScreen.gd
```

---

## Scene Node Trees

### `GameMap.tscn`
Root scene for every battle. Instanced fresh per map.

```
GameMap (Node2D)
├── TileMapLayer_Terrain        # Godot 4 TileMapLayer; base terrain tiles
├── TileMapLayer_Overlay        # Movement (blue) and attack (red) highlight tiles
├── UnitsContainer (Node2D)     # All Unit scenes instanced here at runtime
├── MapCursor (Node2D)          # script: MapCursor.gd
│   └── AnimatedSprite2D        # [PLACEHOLDER] cursor blink animation
├── Camera2D                    # Follows cursor; clamps to map bounds
├── TurnManager (Node)          # script: TurnManager.gd
├── GridManager (Node)          # script: GridManager.gd
├── CombatResolver (Node)       # script: CombatResolver.gd
├── EnemyAI (Node)              # script: EnemyAI.gd
└── HUD (CanvasLayer)           # layer = 1; always rendered on top
```

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
├── Sprite2D                        # [PLACEHOLDER] 32x32 class sprite
├── HPBar (TextureProgressBar)      # Small bar above sprite; max_value = data.max_hp
├── StatusIcon (Sprite2D)           # [PLACEHOLDER] condition icon; hidden when normal
└── SelectionHighlight (Polygon2D)  # Outline glow; hidden by default; shown when selected
```

### `HUD.tscn`

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
│   └── VBoxContainer
│       ├── AttackButton (Button)
│       ├── StaffButton (Button)
│       ├── ItemButton (Button)
│       ├── TradeButton (Button)
│       └── WaitButton (Button)
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
├── TargetSelectList (VBoxContainer)        # Near cursor; one button per valid target
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
├── GameOverScreen (ColorRect)              # Full screen overlay (black, semi-transparent)
│   ├── GameOverLabel (Label)               # "GAME OVER"
│   └── RetryButton (Button)
└── VictoryScreen (ColorRect)              # Full screen overlay
    ├── VictoryLabel (Label)                # "VICTORY"
    └── ContinueButton (Button)             # [PLACEHOLDER] advance to next map
```

---

## Autoload Singletons

### `GameState.gd`

```gdscript
extends Node

enum Phase { PLAYER, ENEMY }

# Settings
var permadeath_enabled: bool = false
var leveling_method: String = "growth_rates"
var max_skills: int = 4
var max_inventory: int = 8

# Map state
var current_phase: Phase = Phase.PLAYER
var turn_number: int = 1
var all_units: Array[Node] = []
var player_units: Array[Node] = []
var enemy_units: Array[Node] = []
var selected_unit: Node = null
var map_data: MapData = null

# Campaign state (persists between maps)
var player_roster: Array[UnitData] = []

# Map-start snapshot — deep copy taken when map loads; used by Retry
var _map_start_snapshot: Array[Dictionary] = []

func register_unit(unit: Node) -> void
func unregister_unit(unit: Node) -> void
func set_phase(new_phase: Phase) -> void
func get_living_player_units() -> Array[Node]
func get_living_enemy_units() -> Array[Node]
func is_player_turn() -> bool
func reset_map_state() -> void
func load_default_roster() -> void
    # Loads all six .tres files from data/roster/default/ into player_roster.
    # Called by MainMenu on "New Game" for MVP.

func take_map_snapshot() -> void
    # Called by TurnManager.start_map() immediately after units are spawned.
    # Deep-copies each player UnitData (hp, inventory, exp, etc.) into
    # _map_start_snapshot as plain Dictionaries so no resource references
    # are shared between the live unit and the snapshot.

func restore_map_snapshot() -> void
    # Called by Retry. Iterates player_roster and overwrites each UnitData's
    # fields from the corresponding snapshot entry. Then reloads the map scene.
```

### `SettingsManager.gd`

Persists all player preferences to `user://settings.cfg` using Godot's `ConfigFile`.
Loaded once at startup (in `_ready()`); written any time a setting changes.
Must be registered as an **Autoload** after `EventBus` and before `GameState`.

```gdscript
extends Node

const SETTINGS_PATH := "user://settings.cfg"

# --- Audio ---
var master_volume: int = 80
var music_volume: int  = 70
var sfx_volume: int    = 90

# --- Gameplay ---
var combat_animations: String = "all"
    # "all" | "player_only" | "enemy_only" | "none"
var movement_speed: String = "normal"
    # "normal" | "fast" | "instant"
var phase_banner: String = "show"
    # "show" | "skip"
var level_up_screen: String = "show"
    # "show" | "auto" | "skip"
var permadeath: String = "off"
    # "off" | "on"
var leveling_method: String = "growth_rates"
    # "growth_rates" | "point_buy" | "coin_flip" | "dice"

# --- Controls (keybindings) ---
# Stored as a Dictionary: { action_name: Array[InputEvent] }
# Loaded from config and applied to InputMap at startup.
var keybindings: Dictionary = {}

# --- Lifecycle ---
func _ready() -> void:
    load_settings()
    _apply_audio()
    _apply_keybindings()

func load_settings() -> void
    # Reads user://settings.cfg via ConfigFile.
    # Falls back to defaults for any missing key.
    # IMPORTANT: do NOT read or write GameState from here — SettingsManager
    # autoloads BEFORE GameState (per the registration order), so the GameState
    # node may not exist yet. GameState._ready() pulls the relevant values
    # (permadeath_enabled, leveling_method) from SettingsManager instead.

func save() -> void
    # Writes all current values to user://settings.cfg.
    # Called immediately whenever any setting changes.

func reset_section_to_defaults(section: String) -> void
    # section: "audio" | "controls" | "gameplay"
    # Resets vars in that section to their default values.
    # Calls save() and _apply_audio() / _apply_keybindings() as needed.

# --- Internal helpers ---
func _apply_audio() -> void
    # Converts 0–100 int values to decibel gains and sets each AudioServer bus.
    # Formula: AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume / 100.0))
    # Bus indices: Master = 0, Music = 1, SFX = 2
    # Guard each set with `AudioServer.bus_count > N` — Music and SFX buses must be
    # added via the editor's Audio panel; only Master exists in a fresh headless build.

func _apply_keybindings() -> void
    # Iterates keybindings dict and calls InputMap.action_erase_events() +
    # InputMap.action_add_event() for each action.

func set_volume(bus_name: String, value: int) -> void
    # Updates the relevant var, calls _apply_audio(), calls save().

func rebind_action(action_name: String, event: InputEvent) -> void
    # Updates keybindings[action_name], calls _apply_keybindings(), calls save().

func get_movement_speed_seconds() -> float
    # Returns the per-tile tween duration based on movement_speed setting:
    # "normal" -> 0.12  |  "fast" -> 0.06  |  "instant" -> 0.0

### `DataManager.gd`

```gdscript
extends Node

var _classes: Dictionary = {}
var _weapons: Dictionary = {}
var _items: Dictionary = {}
var _skills: Dictionary = {}

# Weapon triangle lookup — nested dict: [attacker_type][defender_type] -> "advantage"|"disadvantage"|"neutral"
var _weapon_triangle: Dictionary = {
    "sword":   { "axe": "advantage",    "lance": "disadvantage" },
    "axe":     { "lance": "advantage",  "sword": "disadvantage" },
    "lance":   { "sword": "advantage",  "axe":   "disadvantage" },
    "dark":    { "fire":  "advantage",  "thunder": "advantage",  "wind": "advantage",  "light": "disadvantage" },
    "light":   { "dark":  "advantage",  "fire": "disadvantage",  "thunder": "disadvantage", "wind": "disadvantage" },
    "fire":    { "light": "advantage",  "dark": "disadvantage" },
    "thunder": { "light": "advantage",  "dark": "disadvantage" },
    "wind":    { "light": "advantage",  "dark": "disadvantage" },
}

func _ready() -> void:
    _load_directory("res://data/classes/", _classes)
    _load_directory("res://data/weapons/", _weapons)
    _load_directory("res://data/items/", _items)
    _load_directory("res://data/skills/", _skills)

func _load_directory(path: String, target: Dictionary) -> void
func get_class_data(id: String) -> ClassData   # named *_data, not get_class, to avoid
                                                # Godot's built-in Object.get_class() override warning
func get_weapon(id: String) -> WeaponData
func get_item(id: String) -> ItemData
func get_skill(id: String) -> SkillData
func get_weapon_triangle_result(attacker_type: String, defender_type: String) -> String
```

### `EventBus.gd`

```gdscript
extends Node

signal unit_selected(unit: Node)
signal unit_deselected()
signal unit_moved(unit: Node, from_tile: Vector2i, to_tile: Vector2i)
signal unit_action_taken(unit: Node)
signal combat_started(attacker: Node, defender: Node)
signal combat_resolved(attacker: Node, defender: Node, result: Dictionary)
signal unit_damaged(unit: Node, amount: int)
signal unit_died(unit: Node)
signal unit_healed(unit: Node, amount: int)
signal unit_leveled_up(unit: Node, stat_increases: Dictionary)
signal phase_changed(new_phase: GameState.Phase)
signal cursor_moved(tile: Vector2i)
signal map_victory()
signal map_defeat()
```

---

## Key Script Function Signatures

### `GridManager.gd`

```gdscript
extends Node

const TILE_SIZE: int = 64   # matches GDD_06 tile size and 64x64 placeholder sprites
var map_width: int = 0
var map_height: int = 0
var _tilemap: TileMapLayer

# Terrain
func get_terrain_at(tile: Vector2i) -> String
    # Returns "plain"|"forest"|"mountain"|"fort"|"sea"|"desert"|"wall"
func is_passable(tile: Vector2i, unit: Node) -> bool
func get_unit_at(tile: Vector2i) -> Node   # null if empty
func world_to_tile(world_pos: Vector2) -> Vector2i
func tile_to_world(tile: Vector2i) -> Vector2   # Returns top-left corner of tile

# Movement
func get_movement_range(unit: Node) -> Array[Vector2i]
    # BFS/Dijkstra from unit's tile; respects move costs and blocking
func get_movement_path(unit: Node, target_tile: Vector2i) -> Array[Vector2i]
    # Ordered path for animation; empty array if unreachable.
    # Named *_path, not get_path_to, because Godot's Node.get_path_to(node, bool) -> NodePath
    # is a built-in that would override-warning here.
func get_move_cost(tile: Vector2i, unit: Node) -> int
    # 1 for plain/fort; 2 for forest/sea/desert (standard);
    # 3 for mountain; 3 for armoured/mounted on desert; 999 for wall

# Attack
func get_attack_range_from_tiles(unit: Node, from_tiles: Array[Vector2i]) -> Array[Vector2i]
    # All tiles attackable from any tile in from_tiles, excluding from_tiles themselves
func get_all_attack_tiles(unit: Node, from_tiles: Array[Vector2i]) -> Array[Vector2i]
    # All attackable tiles including those within movement range
func get_attackable_enemies_from_tile(unit: Node, tile: Vector2i) -> Array[Node]
    # Enemies in weapon range from a specific tile
func can_attack_from_tile(attacker: Node, at_tile: Vector2i, target: Node) -> bool

# Staff
func get_healable_allies(unit: Node) -> Array[Node]
    # Allies within staff range who are below max HP

# Overlays
func show_movement_overlay(tiles: Array[Vector2i]) -> void   # Blue tint
func show_attack_overlay(tiles: Array[Vector2i]) -> void     # Red tint
func show_heal_overlay(tiles: Array[Vector2i]) -> void       # Green tint
func show_enemy_danger_zone() -> void                        # All enemy attack ranges; red tint
func clear_overlays() -> void
```

### `CombatResolver.gd`

```gdscript
extends Node

# Main resolution (has side effects — call only when player confirms)
func resolve_combat(attacker: Node, defender: Node) -> Dictionary
# Returns {
#   exchanges: [{ actor, target, hit: bool, crit: bool, damage: int }],
#   attacker_final_hp: int,
#   defender_final_hp: int,
#   attacker_exp: int,
#   attacker_wexp: int
# }

# Preview only — no RNG, no stat changes
func preview_combat(attacker: Node, defender: Node) -> Dictionary
# Returns {
#   attacker_hit_pct, attacker_dmg, attacker_crit_pct, attacker_attacks,
#   defender_hit_pct, defender_dmg, defender_crit_pct, defender_attacks
# }

# Helpers (used internally and by EnemyAI for scoring)
func compute_battle_speed(unit: Node, weapon: WeaponData) -> int
func compute_accuracy(attacker: Node, defender: Node, weapon: WeaponData) -> int
func compute_damage(attacker: Node, defender: Node, weapon: WeaponData) -> int
func compute_crit_rate(attacker: Node, defender: Node, weapon: WeaponData) -> int
func can_counterattack(defender: Node, attacker_tile: Vector2i) -> bool
func get_follow_up_attacker(a: Node, b: Node) -> Node   # null if no follow-up
func calculate_exp(attacker: Node, defender: Node, killed: bool) -> int

# Internal
func _apply_weapon_triangle(base_accuracy: int, base_damage: int,
        atk_weapon: WeaponData, def_weapon: WeaponData) -> Dictionary
func _apply_terrain(accuracy: int, dodge_bonus: int) -> int
func _roll_hit(pct: int) -> bool       # randi() % 100 < pct
func _roll_crit(pct: int) -> bool
```

### `TurnManager.gd`

```gdscript
extends Node

enum UnitState { READY, MOVED, DONE }

var _unit_states: Dictionary = {}   # Node -> UnitState
var _combat_lock: bool = false      # True while combat animation plays

func start_map(map_data: MapData) -> void
func start_player_phase() -> void
func end_player_phase() -> void
func start_enemy_phase() -> void
func set_unit_state(unit: Node, state: UnitState) -> void
func get_unit_state(unit: Node) -> UnitState
func can_unit_act(unit: Node) -> bool   # READY or MOVED
func are_all_player_units_done() -> bool
func undo_move(unit: Node) -> void      # Returns MOVED unit to READY; restores position
func check_victory_conditions() -> void
```

### `Unit.gd`

```gdscript
extends Node2D

var data: UnitData
var tile_position: Vector2i
var team: String   # "player" | "enemy"
var _original_tile: Vector2i   # Stored when unit starts moving (for undo)

func initialize(unit_data: UnitData, start_tile: Vector2i, unit_team: String) -> void
func get_equipped_weapon() -> WeaponData       # null if inventory empty or all broken
func get_equipped_weapon_entry() -> Dictionary
func has_quality(quality: String) -> bool
func get_terrain_def_bonus() -> int
func get_terrain_dodge_bonus() -> int

# Combat stats (all account for equipped weapon unless overridden)
func battle_speed(weapon: WeaponData = null) -> int
func accuracy(weapon: WeaponData = null) -> int
func dodge() -> int
func damage(weapon: WeaponData = null) -> int
func crit_rate(weapon: WeaponData = null) -> int
func crit_avoid() -> int

# HP
func take_damage(amount: int) -> void
func heal(amount: int) -> void
func handle_death() -> void

# Movement
func move_along_path(path: Array[Vector2i]) -> void   # async; uses Tween
func snap_to_tile(tile: Vector2i) -> void             # instant; used by AI and undo

# Inventory
func use_weapon_durability() -> void
func can_equip(weapon_data: WeaponData) -> bool

# Progression
func add_exp(amount: int) -> void
func level_up() -> void
func add_wexp(weapon_type: String, amount: int) -> void

# Visual state
func set_done_appearance() -> void     # Greyscale/darkened sprite when DONE
func reset_appearance() -> void        # Back to normal at phase start
```

### `MapCursor.gd`

```gdscript
extends Node2D

var current_tile: Vector2i = Vector2i(0, 0)
var _grid: GridManager
var _camera: Camera2D
var _state: String = "free"   # "free" | "unit_selected" | "unit_moved" | "targeting" | "locked"

const CURSOR_SPEED: float = 0.10    # Seconds between moves when key held

func _unhandled_input(event: InputEvent) -> void
func move_cursor(direction: Vector2i) -> void
func _on_confirm() -> void
func _on_cancel() -> void
func lock() -> void     # Disable cursor input during animations and enemy phase
func unlock() -> void
func _scroll_camera_if_needed() -> void
    # If cursor is within 2 tiles of viewport edge, scroll camera
```

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
> sprite sizes in the checklist. `GridManager.TILE_SIZE = 64` is authoritative.

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
| `open_menu` | Escape, Enter (on empty tile) | — |
| `show_danger_zone` | Q | Middle Click |
| `end_turn` | — | — (accessed via Map Menu) |
| `zoom_in` | + / = | Scroll Up — [PLACEHOLDER Phase 2] |
| `zoom_out` | - | Scroll Down — [PLACEHOLDER Phase 2] |
| `zoom_reset` | 0 | — [PLACEHOLDER Phase 2] |

---

## UnitData Field Addendum

The following fields are additions to `UnitData.gd` that were introduced after the
initial resource definition. Include them alongside the fields listed in GDD_03.

```gdscript
# In UnitData.gd — add these fields:

@export var ai_profile: String = "basic"
    # Used by EnemyAI to determine decision-making behaviour.
    # Valid values for MVP: "basic" | "passive"
    # Future values: "territorial" | "guard_tile" | "healer" | "boss"
    # Player units should leave this as "basic" (it is never read for player units).

@export var is_default_roster: bool = false
    # True for the 6 auto-generated MVP starter units.
    # Used by GameMap to distinguish generated units from player-created ones.
```

---

## Resource Class Definitions

These are the full `@export` field definitions for every custom Resource class.
Each file lives in `scripts/resources/` and is saved as a `.tres` in its
respective `data/` subfolder.

### `UnitData.gd`

```gdscript
class_name UnitData extends Resource

@export var unit_name: String = ""
@export var class_id: String = ""
@export var level: int = 1
@export var exp: int = 0
@export var is_promoted: bool = false
@export var effective_level: int = 1      # pre + post promotion levels combined

# Stats
@export var max_hp: int = 0
@export var hp: int = 0                   # current HP
@export var str: int = 0
@export var mag: int = 0
@export var def: int = 0
@export var res: int = 0
@export var skl: int = 0
@export var spd: int = 0
@export var luk: int = 0
@export var mov: int = 0
@export var con: int = 0
@export var los: int = 4

# Proficiencies — Dictionary: { "sword": { "rank": "D", "wexp": 0 } }
@export var proficiencies: Dictionary = {}

# Skills — Array of skill ID strings
@export var skills: Array[String] = []

# Inventory — Array of Dictionaries; each entry has a "type" field.
# All code that reads inventory must check entry["type"] before reading
# other fields. See Inventory Entry Format below.
@export var inventory: Array[Dictionary] = []

# Conditions — Array of Dictionaries; see GDD_02 status conditions
@export var conditions: Array[Dictionary] = []

# Economy
@export var gold: int = 1000

# State
@export var is_incapacitated: bool = false  # permadeath flag
@export var ai_profile: String = "basic"
@export var is_default_roster: bool = false
```

### Inventory Entry Format

Every entry in `UnitData.inventory` is a Dictionary with a mandatory `"type"` field.
This is the single source of truth — all code that reads inventory checks `type` first.

```gdscript
# Weapon entry
{
  "type": "weapon",
  "weapon_id": "iron_sword",     # must match a WeaponData resource id
  "uses_remaining": 45,
  "forged_mods": {}              # empty dict = unforged; see GDD_04 forging section
}

# Item entry
{
  "type": "item",
  "item_id": "vulnerary",        # must match an ItemData resource id
  "uses_remaining": 3
}
```

`Unit.get_equipped_weapon()` filters for `type == "weapon"` entries only and
returns the first one whose `uses_remaining > 0` and which the unit can equip
(proficiency rank check). Items are never auto-equipped.

### `WeaponData.gd`

```gdscript
class_name WeaponData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var weapon_type: String = ""
    # "sword" | "lance" | "axe" | "bow" | "knife"
    # | "fire" | "thunder" | "wind" | "light" | "dark" | "staff"
@export var rank: String = "E"            # "E" | "D" | "C" | "B" | "A" | "S"
@export var mt: int = 0
    # For staves: set to 0. Heal amount is computed separately (10 + MAG).
@export var hit: int = 0
    # For staves: set to 0. Staves do not use a hit roll (healing always lands).
@export var crit: int = 0
    # For staves: set to 0. Staves cannot crit.
@export var range_min: int = 1
@export var range_max: int = 1
@export var wt: int = 0
@export var uses: int = 1
@export var cost: int = 0
@export var wexp: int = 1
@export var effect_tags: Array[String] = []
    # See GDD_04 for full tag list
@export var uses_mag: bool = false
    # If true: uses MAG instead of STR for damage; targets RES instead of DEF
    # Set true for all tomes. Set false for staves (staves have their own heal logic).
@export var magic_triangle_type: String = ""
    # Only for hybrid weapons (e.g. Bolt Axe uses "thunder" triangle).
    # Leave empty for standard weapons and tomes.
```

**Staff note:** Staves are `WeaponData` resources with `weapon_type = "staff"`.
Their `mt`, `hit`, and `crit` fields are all `0` and are never read during combat.
Staff effects are handled by dedicated staff-use logic in `Unit.gd` and the
`ActionMenu`, not by `CombatResolver`. The `range_min` and `range_max` fields
define healing reach (Heal staff: min=1, max=1).

### `ClassData.gd`

```gdscript
class_name ClassData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var base_hp: int = 0
@export var base_str: int = 0
@export var base_mag: int = 0
@export var base_def: int = 0
@export var base_res: int = 0
@export var base_skl: int = 0
@export var base_spd: int = 0
@export var base_luk: int = 0
@export var base_mov: int = 0
@export var base_con: int = 0
@export var base_los: int = 4
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
    # { "hp": 70, "str": 50, "mag": 5, "def": 40,
    #   "res": 20, "skl": 60, "spd": 50, "luk": 35 }
@export var sprite_id: String = ""        # [PLACEHOLDER] links to sprite sheet row
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
@export var effect_id: String = ""
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
@export var activation_chance_stat: String = ""
    # e.g. "skl" — empty string if always triggers
@export var activation_divisor: int = 2   # e.g. 2 for SKL/2%
@export var effect_id: String = ""
@export var effect_params: Dictionary = {}
@export var is_player_activated: bool = false
```

### `MapData.gd`

```gdscript
class_name MapData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var tilemap_scene_path: String = ""
@export var objective_type: String = ""
    # "rout" | "seize" | "boss" | "survive" | "defend" | "escape"
@export var objective_params: Dictionary = {}
@export var turn_limit: int = 0           # 0 = no limit
@export var player_start_tiles: Array[Vector2i] = []
@export var enemy_placements: Array[Dictionary] = []
    # Each entry: {
    #   "unit_data_path": String,  # e.g. "res://data/maps/map_001_rout/enemies/e1_soldier.tres"
    #   "tile": Vector2i,
    #   "ai_profile": String,
    #   "is_boss": bool
    # }
@export var required_survivor_names: Array[String] = []
@export var reward_gold: int = 0
@export var reward_items: Array[String] = []
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

Project registration order is `EventBus → SettingsManager → GameState → DataManager`.
Each autoload's `_ready()` runs in that order. Practical consequence: an autoload
must NOT touch a later autoload from its own `_ready()`. SettingsManager loads
settings from disk but does not push values to GameState; GameState pulls them
in its own `_ready()` instead.

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
