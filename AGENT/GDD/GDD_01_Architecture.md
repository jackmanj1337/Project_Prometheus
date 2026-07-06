# GDD_01 — Architecture & Project Structure

**Status:** Active contract — architecture reference. Most sections are descriptive
**Reference** (folder layout, scene trees, function signatures, resource schemas) tracking
the implemented code; status-bearing **contracts** (Determinism/Snapshot, the
CampaignRules contract) carry their own `Status` + `Last verified` markers.
**Last verified:** 2026-07-06
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This chapter owns project structure, runtime ownership, autoload order, the
resource/serialization schemas (`UnitData`, `ClassData`, `WeaponData`, `ItemData`,
`SkillData`, `InventoryEntry`, `MapData`, `FactionData`, `ObjectiveCondition`,
`PairUpBonusTable`), the **determinism/snapshot/online contract**, and the
**`CampaignRules` contract**. Gameplay rules that use these structures are owned by the
feature chapters (GDD_02–08); this file owns the data shapes and the binding contracts
they depend on.

---

## Core Philosophy: Data-Driven Design

All game content — classes, weapons, items, skills, maps — is defined in **data files**,
not in code. Game logic reads and executes these definitions at runtime. Author-facing
vocabularies follow the `[EXT]` rule: open registries and data compositions, not closed
engine switches, unless a section explicitly marks an engine-only exception. This means:

- Adding a new class = write a new `.tres` resource file, no code changes needed
- Adding a new skill that composes existing primitives = write a skill resource and
  configure its effect/requirement data
- Adding a new map = write a map data file and a Godot TileMap scene

The only time code changes are needed is when introducing a **new engine primitive**.
Those primitives ship through the engine release cadence; content authors get a
growable named library of data compositions and developer-provided presets.

### Authoring Extension Boundary

Status: **Target design**
Last verified: 2026-06-29

Public campaign packages are data + assets first. The in-app authoring surface must not
run arbitrary executable code from shared campaigns. A future sandboxed scripting layer
is allowed only as a bounded expansion; full unrestricted power-user access is forking
the public source.

The author-facing vocabulary families that must be registry-backed are tracked in the
Project Control Plane and vocabulary manifest: objective predicates/actions, AI
profiles/presets, map-object components, PHB panels, action/effect primitives, stat
names, resource types, difficulty/rule profiles, requirement predicates/terms, and
future activities.

For the step-by-step "how do I add or validate one safely?" workflows, prefer
the dedicated guides in `AGENT/Docs/` over repeating local checklists in every
GDD chapter.

### Onboarding Read Order

For a new developer, the shortest accurate path through the docs is:

1. This file (`GDD_01`) for project structure and runtime ownership
2. `GDD_02` for battle-loop rules
3. `GDD_03` for unit/class progression state
4. `GDD_06` for map/objective authoring
5. `GDD_07` for UI surfaces and player flow

`GDD_09_Checklist.md` was the MVP build checklist — deleted in Stage 5.2 (retrieve
via Git). `GDD_10_Roadmap.md` is the sole roadmap. Neither should be treated as the
primary source for shipped behavior; use GDD_01–GDD_08 for that.

Cross-cutting workflow guides:

- `AGENT/Docs/guides/map_authoring_guide.md`
- `AGENT/Docs/guides/testing_guide.md`
- `AGENT/Docs/guides/campaign_rules.md`

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
│   ├── classes/                   # 24 ClassData .tres files (base + promoted + hidden enemy-only fighter)
│   │   ├── archer.tres
│   │   ├── bishop.tres
│   │   ├── bow_knight.tres
│   │   ├── cavalier.tres
│   │   ├── cleric.tres
│   │   ├── ...
│   │   └── war_monk.tres
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
│   ├── items/                     # 8 ItemData .tres files
│   │   ├── vulnerary.tres
│   │   ├── elixir.tres
│   │   ├── master_seal.tres
│   │   ├── orion_bolt.tres
│   │   ├── guiding_ring.tres
│   │   ├── second_seal.tres
│   │   ├── strength_tonic.tres
│   │   └── debuff_tonic.tres        # Map 950 validation-only stat-debuff item
│   ├── skills/                    # 54 SkillData .tres files
│   │   ├── renewal.tres
│   │   ├── vantage.tres
│   │   ├── ...
│   │   └── s_rank_mastery.tres
│   ├── roster/
│   │   ├── default/               # Six starter UnitData .tres files
│   │   │   ├── unit_01_cavalier.tres
│   │   │   ├── unit_02_mercenary.tres
│   │   │   ├── unit_03_archer.tres
│   │   │   ├── unit_04_mage.tres
│   │   │   ├── unit_05_cleric.tres
│   │   │   └── unit_06_knight.tres
│   │   └── test/
│   │       ├── map_900_hotseat_validation/
│   │       └── map_950_promotion_validation/
│   ├── pair_up/
│   │   └── pair_up_bonus_table.tres
│   └── maps/
│       ├── map_001_rout/
│       │   ├── map_001_data.tres
│       │   ├── map_001_c3_factions_data.tres
│       │   └── enemies/
│       ├── map_900_hotseat_validation/
│       │   └── map_900_hotseat_validation_data.tres
│       └── map_950_promotion_validation/
│           ├── map_950_promotion_validation_data.tres
│           └── enemies/
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
│       ├── PromotionScreen.tscn
│       ├── ReclassScreen.tscn
│       ├── SettingsScreen.tscn
│       ├── UnitDetailsScreen.tscn
│       └── WeaponMenu.tscn
│       # CombatHUD still has no scene — CombatHUD.gd is attached to a bare
│       # CanvasLayer inside GameMap.tscn and builds its labels in code.
│
└── scripts/
    ├── autoloads/
    │   ├── ConditionManager.gd       # status-condition stub (M8)
    │   ├── DataManager.gd
    │   ├── EventBus.gd
    │   ├── GameState.gd
    │   ├── PairUpBonusResolver.gd
    │   ├── PairUpRegistry.gd
    │   ├── RngService.gd              # deterministic dice (RNG-1..4, CRR)
    │   └── SettingsManager.gd
    ├── core/
    │   ├── Boot.gd
    │   ├── CameraController.gd
    │   ├── CombatResolver.gd         # also an autoload (/root/CombatResolver)
    │   ├── EnemyAI.gd                # also an autoload (/root/EnemyAI)
    │   ├── GameMap.gd
    │   ├── GridManager.gd            # scene node, child of GameMap
    │   ├── HotseatController.gd
    │   ├── MapCursor.gd              # scene node, child of GameMap
    │   ├── MapCursorInput.gd         # RefCounted slice — key decode + auto-repeat
    │   ├── MapCursorSelection.gd     # RefCounted slice — selection + path planning
    │   ├── MapCursorTargeting.gd     # RefCounted slice — attack/staff targeting
    │   └── TurnManager.gd            # scene node, child of GameMap
    ├── items/
    │   └── ItemHandler.gd            # autoload — item-effect dispatcher
    ├── resources/
    │   ├── ClassData.gd
    │   ├── FactionData.gd
    │   ├── InventoryEntry.gd
    │   ├── ItemData.gd
    │   ├── MapData.gd
    │   ├── ObjectiveCondition.gd
    │   ├── PairUpBonusTable.gd
    │   ├── SkillData.gd
    │   ├── UnitData.gd
    │   └── WeaponData.gd
    ├── shared/
    │   ├── GameConstants.gd          # autoload — project-wide constants
    │   ├── InputDisplay.gd
    │   ├── MoreInfoContent.gd
    │   ├── StatBreakdown.gd
    │   └── TileActions.gd
    ├── skills/
    │   └── SkillHandler.gd           # autoload — skill-effect dispatcher
    ├── tests/                        # headless test suites; run via run_tests.sh
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
    │   ├── ModalScreen.gd
    │   ├── NewGameScreen.gd
    │   ├── PhaseBanner.gd
    │   ├── PromotionScreen.gd
    │   ├── ReclassScreen.gd
    │   ├── SettingsScreen.gd
    │   ├── UnitDetailsScreen.gd
    │   └── WeaponMenu.gd
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
├── MapCursor (Node2D)           # script: MapCursor.gd
│   └── Sprite2D                 # cursor sprite
├── Camera2D                     # follows cursor; clamps to map bounds
├── GridManager (Node)           # script: GridManager.gd
├── TurnManager (Node)           # script: TurnManager.gd
├── HUDLayer (CanvasLayer)
│   ├── ActionMenu
│   ├── ItemMenu
│   ├── MapMenu
│   ├── AttackPreview
│   └── WeaponMenu
├── LevelUpLayer (CanvasLayer)
│   └── LevelUpScreen
├── PromotionLayer (CanvasLayer)
│   └── PromotionScreen
├── ReclassLayer (CanvasLayer)
│   └── ReclassScreen
├── CombatHUDLayer (CanvasLayer) # script: CombatHUD.gd; builds labels in code
├── HUDMainLayer (CanvasLayer)
│   └── HUD                      # HUD.tscn instance; script: HUD.gd
├── BannerLayer (CanvasLayer)
│   └── PhaseBanner
├── GameOverLayer (CanvasLayer)
│   └── GameOverScreen
├── SettingsLayer (CanvasLayer)
│   └── SettingsScreen
└── UnitDetailsLayer (CanvasLayer)
    └── UnitDetailsScreen
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

`Boot` also acts as the stable re-entry point when quitting from an in-progress map:
UI flows return to `Boot.tscn`, then `Boot` routes back to `MainMenu.tscn`.

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

The HUD is now spread across separately-instanced scenes and layers inside
`GameMap.tscn`. `HUD.tscn` owns the persistent map-side panels; menus/modals such
as `ActionMenu`, `AttackPreview`, `PromotionScreen`, `ReclassScreen`, and
`UnitDetailsScreen` are sibling layer instances in the main map scene. The tree
below reflects the current `HUD.tscn` internals; the `.tscn` files remain
authoritative for exact node names and paths.

```
HUD (Control)
├── PhaseLabel (Label)
├── TurnLabel (Label)
├── DebugLabel (Label)                      # debug-build only; hidden in release
├── UnitInfoPanel (PanelContainer)
│   └── VBox
│       ├── UnitName (Label)
│       ├── UnitClass (Label)
│       ├── UnitHP (Label)
│       ├── UnitWeapon (Label)
│       └── MasteryLabel (Label, created dynamically when needed)
├── TerrainInfoPanel (PanelContainer)
│   └── VBox
│       ├── TerrainName (Label)
│       ├── TerrainDef (Label)
│       ├── TerrainDodge (Label)
│       ├── TerrainDescription (RichTextLabel)   # More Info expanded mode
│       ├── TerrainMoveCosts (RichTextLabel)     # More Info expanded mode
│       ├── TerrainActions (RichTextLabel)       # More Info expanded mode
│       └── TerrainHint (Label)
└── ObjectivePanel (PanelContainer)
    └── VBox
        ├── ObjectiveHeader (Label)
        └── ObjectiveList (Label)
```

Related sibling UI scenes/layers in `GameMap.tscn`:
- `ActionMenu.tscn` — post-move action list, including Pair Up / Swap / Separate,
  Seize, Escape, Equip, Item, Staff, Wait as applicable
- `ItemMenu.tscn` and `WeaponMenu.tscn` — submenus launched from the action flow
- `AttackPreview.tscn` — combat forecast with More Info side panel
- `UnitDetailsScreen.tscn` — inspect-unit character sheet with More Info side panel
- `LevelUpScreen.tscn`, `PromotionScreen.tscn`, `ReclassScreen.tscn` — blocking
  progression modals
- `MapMenu.tscn`, `SettingsScreen.tscn`, `PhaseBanner.tscn`, `GameOverScreen.tscn`

The `.tscn` files are authoritative for exact composition and should be checked
before updating this document again.

---

## Autoload Singletons

### `GameState.gd`

Autoload. Holds per-campaign rules, live map state, faction/alliance helpers,
launch-state for the next map, the cross-map roster/economy, and the Retry
snapshot. No `class_name` — Godot 4 forbids `class_name` on an autoload script.

```gdscript
extends Node

enum Phase { PLAYER, ENEMY }

# --- Alliance / faction model ---
const _DEFAULT_ALLIANCE_GROUPS: Dictionary = {
    "blue": "allies",
    "green": "allies",
    "red": "foes",
    "yellow": "rogues",
}
var _alliance_groups: Dictionary = _DEFAULT_ALLIANCE_GROUPS.duplicate()

# --- Per-campaign gameplay rules (set by New Game / future save flow) ---
var permadeath_enabled: bool = false
var leveling_method: String = "growth_random"
var auto_promote_at_max_level: bool = false
var pair_up_enabled: bool = true
var max_skills: int = 5
var max_inventory: int = 8

# --- Debug-only testing aids ---
var debug_force_levelup: bool = false
var debug_growth_boost: bool = false

# --- Current map state ---
var current_phase: Phase = Phase.PLAYER
var turn_number: int = 1
var all_units: Array[Node] = []
var _units_by_faction: Dictionary = {}   # faction_id -> Array[Node]
var map_data: MapData = null

# --- Persists between maps ---
var player_roster: Array[UnitData] = []
var party_gold: int = 0
var party_items: Array[String] = []
var next_map_data_path: String = ""
var next_map_roster_policy: String = "default_roster"
var next_map_roster_source: String = ""

# --- Map-start snapshot — used by Retry ---
var _map_start_snapshot: Array[Dictionary] = []
var _snapshot_party_gold: int = 0
var _snapshot_party_items: Array[String] = []
var _snapshot_pair_up_registry: Dictionary = {}

func are_hostile(a_id: String, b_id: String) -> bool
func get_alliance_group(faction_id: String) -> String
func register_unit(unit: Node) -> void
func unregister_unit(unit: Node) -> void
func set_phase(new_phase: Phase, faction_id: String = "") -> void
func find_unit_by_id(unit_id: String) -> Node
func get_living_units_of(faction_id: String) -> Array[Node]
func get_registered_faction_ids() -> Array[String]
func get_living_player_units() -> Array[Node]
func get_living_enemy_units() -> Array[Node]
func is_player_turn() -> bool
func reset_map_state() -> void
func configure_next_map(map_path: String, roster_policy := "default_roster",
        roster_source := "") -> void
func load_default_roster() -> bool
func load_roster_from_directory(roster_path: String,
        roster_policy := "fixed_test_roster") -> bool
func is_roster_ready_for_launch() -> bool

func take_map_snapshot() -> void
    # Deep-copies each roster UnitData, party economy, and the PairUpRegistry state
    # so Retry rewinds HP, inventory, class changes, pairings, and rewards together.
func restore_map_snapshot() -> void
    # Restores the snapshotted roster/economy/pairings, then resets map state.
    # The caller reloads the current scene after this returns.
```

### New Game / Map Launch Flow

Runtime launch is now selector-driven rather than hardcoded to `Map 001`.

- `NewGameScreen.gd` loads choices from `data/maps/map_registry.json`
- the selected entry is committed into:
  - `GameState.next_map_data_path`
  - `GameState.next_map_roster_policy`
  - `GameState.next_map_roster_source`
- `NewGameScreen.gd` loads the requested roster before scene change
- `GameMap.gd` reads that launch state when the battle scene opens
- `GameMap.gd` now fails loud if the roster was not explicitly prepared for the
  selected launch policy; it no longer silently falls back to the default roster

This means new maps generally need two pieces of authoring to be launchable:

1. the map resource / scene under `data/maps/...`
2. an entry in `data/maps/map_registry.json`

For maps that do not use `default_roster`, the registry entry must also provide
the correct explicit roster source. A bad or missing roster now blocks launch
instead of substituting another roster behind the scenes.

Practical follow-up guides:

- map authoring and registry rules: `AGENT/Docs/guides/map_authoring_guide.md`
- campaign-rule ownership: `AGENT/Docs/guides/campaign_rules.md`
- validation expectations: `AGENT/Docs/guides/testing_guide.md`

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
var mouse_cursor: String = "enabled"        # "enabled" | "disabled"
                                            # When "disabled", mouse motion does not
                                            # move the on-map cursor in any state.
                                            # Mouse clicks (confirm/cancel) still fire.
var auto_end_turn: bool = true              # end phase when every acting unit is DONE
var camera_edge_buffer: int = 2             # clamped 0-5 tiles

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
    for err in collect_validation_errors(_classes, _weapons, _items, _skills):
        push_error(err)

static func collect_validation_errors(classes, weapons, items, skills) -> Array[String]
func _load_directory(path: String, target: Dictionary) -> void
func get_class_data(id: String) -> ClassData   # named *_data, not get_class, to avoid
                                               # Godot's Object.get_class() override warning
func get_all_classes() -> Dictionary
func validate_unit_data(unit: UnitData) -> Array[String]
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
signal unit_leveled_up(unit: Node, stat_increases: Dictionary, learned_skills: Array)
signal promotion_available(unit: Node)
signal unit_promoted(unit: Node, old_class_id: String, new_class_id: String)
signal promotion_started()
signal promotion_finished()
signal unit_reclassed(unit: Node, old_class_id: String, new_class_id: String)
signal reclass_started()
signal reclass_finished()
signal level_up_started()
signal level_up_finished()
signal phase_changed(new_phase: int, faction_id: String)
signal cursor_moved(tile: Vector2i)
signal ai_unit_acting(unit: Node)
signal map_victory()
signal map_defeat()
signal map_resolved(winner_group: String, standings: Array)
signal debug_flags_changed()
```

> `TurnManager` still exposes its own `turn_changed(turn_number: int)` signal
> outside the bus. Condition/Laguz signals (`condition_applied`,
> `shift_gauge_changed`, …) are still deferred to M8/M12.

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
    # Called by TurnManager at the start of the holder's faction phase (the same
    # tick point as "turn"-duration modifiers + fort heal; round-start in ALTERNATING
    # mode). Applies per-turn effects (e.g. Poison damage) and decrements durations.
    # Behavioural enforcement (Sleep/Stun skip, Berserk, Silence) is applied at the
    # unit's activation, NOT here — see GDD_02 §Status Conditions tick timing.
func has_condition(unit: Node, condition_type: String) -> bool
func clear_all_conditions(unit: Node) -> void
    # Called by Restore staff and Panacea item.
```

---

## CampaignRules Contract

Status: **Split** — the live per-save rule fields are **Implemented** (on `GameState`);
consolidation into a `CampaignRules` object is **Target design** (stub created Stage 4.3);
`exp_gaining_factions` field is **Stub** (`scripts/resources/CampaignRules.gd`)
Last verified: 2026-06-13

### Summary
`CampaignRules` is the per-save bundle of gameplay rules chosen at New Game and carried by
the save/runtime state — distinct from global app **settings** (`SettingsManager`, on
disk) and from per-map **launch state**. Today these rules live as loose fields on
`GameState`; the contract consolidates them and adds the fields the determinism, EXP, and
campaign systems depend on.

### Specs

**Implemented (live per-save fields on `GameState`).**

| Field | Type | Meaning |
|---|---|---|
| `permadeath_enabled` | bool | Defeated allied units lost for the run (GDD_02 §Permadeath) |
| `leveling_method` | String | `growth_random` / `growth_fixed` (GDD_02 §Leveling) |
| `auto_promote_at_max_level` | bool | Auto-promote at class cap (GDD_02 §Promotion timing) |
| `pair_up_enabled` | bool | Enables Pair Up actions (GDD_05 §Pair Up) |
| `max_skills` | int (5) | Equipped-skill cap (GDD_05) |
| `max_inventory` | int (8) | Inventory slot cap, not yet enforced (GDD_04) |

> Launch-routing fields (`next_map_data_path`, `next_map_roster_policy`,
> `next_map_roster_source`) travel with New Game but are **launch state, not rules**.
> Evergreen rule reference: `AGENT/Docs/guides/campaign_rules.md`.

**Target design (consolidated `CampaignRules` + new fields).**
- Consolidate the rule fields above into a single `CampaignRules` object referenced by
  `GameState` and serialized into the snapshot (`campaign_rules` key — see Determinism
  contract). Code stub created in **Stage 4.3**.
- Treat shipped rule numbers and relationships as selected rule-profile values, not
  engine constants. Developer-provided presets support the project/corpus targets;
  campaigns may select or override exposed profiles through validated data.
- **`exp_gaining_factions` (OPEN-4):** which factions earn EXP; the shipped preset is
  Blue + Green, Red none. Drives `CombatResolver` EXP gating (GDD_02 §EXP).
- **Rewind-charge pool (RNG-3):** bounded reroll/probe budget; shipped presets include
  ironman-style zero charges and limited-charge values. Owned by the determinism
  contract below.
- **Follow-up threshold override:** the Battle-Speed follow-up threshold is read from
  CampaignRules/profile data (GDD_02 §Combat Resolution).
- **Broken-weapon degraded mode (OPEN-5):** likely a `CampaignRules` toggle (GDD_04).

### Known gaps
- `CampaignRules` class stub created (`scripts/resources/CampaignRules.gd`), but not
  yet wired into `GameState`. Fields remain loose on `GameState`; consolidation and
  snapshot integration are a Phase 3 task (requires campaign save/load design).

### Anchors
- Code: `scripts/autoloads/GameState.gd` (current rule fields); `scripts/resources/CampaignRules.gd` (stub)
- Guide: `AGENT/Docs/guides/campaign_rules.md`
- Decisions: OPEN-4, OPEN-5, RNG-3, D-D
- Roadmap: GDD_10 §Release Gates / CampaignRules Stub; EXP gating owner: GDD_02

---

## Determinism, Snapshot & Online Contract

Status: **Split** — RNG-1 dice sourcing + combat migration **Implemented** (2026-07-06,
B1-PKGA Slices 1a+1b); snapshot persistence (RNG-2), suspend, rewind **Target design**
Last verified: 2026-07-06

### Summary
All gameplay randomness flows through a hash-chained, context-seeded `RngService` so
that rewind, suspend save, and Retry reproduce identical outcomes, and online play can
be host-authoritative. This section is the **binding contract**; the implementation
plan (code, integration sweep, tests, build order) is
`AGENT/Docs/design/rng_determinism_design_2026-06-11.md`.

### Specs (binding rules)

- **RNG-1 — Hash-chained context-seeded dice.** Every gameplay die derives from
  `seed = mix(map_seed, history_hash, event_record)`. `history_hash` advances on every
  **committed, non-undoable** unit action; equip, undone moves, menu/cursor/preview
  **never** advance it. Each dice-bearing event draws from its own freshly seeded RNG
  in the canonical roll order; level-ups are chained per `(unit_id, new_level)`.
- **RNG-2 — RNG state lives in the snapshot.** `{map_seed, history_hash}` serializes
  into every map snapshot (Retry, rewind checkpoints, suspend save); replaying the
  identical committed-action sequence reproduces outcomes byte-for-byte.
- **RNG-3 — Accepted exploits, priced by rewind charges.** Probing and Wait-to-reroll
  are knowingly permitted, bounded by a `CampaignRules` rewind-charge pool (default 3–5;
  0 = ironman). No further anti-manipulation machinery.
- **RNG-4 — Online is host-authoritative (M15B, post-1.0).** The host simulates and
  broadcasts result payloads through the `resolve_combat()` / `apply_combat_result()` +
  snapshot seams; determinism guarantees are **engine-local**. The custom mixer is still
  mandatory (protects suspend saves across Godot upgrades).
- **Canonical roll order (binding).** Per `attack` event: per strike, the **selected
  hit resolver's fixed `rn_count`** of 0–99 hit RNs (CRR-1..8) — default `two_roll` =
  RULE-001 (two RNs, hit when `floor((r1+r2)/2) < To-Hit`); `single_roll` is the
  second built-in (`rns[0] < To-Hit`, one RN); selection lives in
  `CampaignRules.hit_formula` — then a **crit RN only on a hit**, then
  skill-activation rolls at their trigger slots; then `levelup` events (one growth
  roll per stat in `ClassData.STAT_KEYS` order). Reordering — including changing a
  resolver's draw count — is a **save/replay-breaking** change.
- **Frame-atomicity (already true).** Combat resolves within one frame
  (`resolve_combat()` builds + rolls; `apply_combat_result()` commits); snapshots exist
  only **between** committed actions, so there is no mid-exchange state to serialize.
- **Snapshot contract.** Generalize `GameState.take_map_snapshot()` into one
  `Dictionary` (`schema_version`, `map_id`, `campaign_rules`, `rng`, `turn`, `party`,
  `pair_up`, `units[]` including non-`@export` runtime fields). Retry = restore
  checkpoint 0; suspend save = this dict to `user://suspend.sav`; rewind = a ring of
  these. **Suspend file persists until the map resolves (OPEN-13)**, then deleted (no
  delete-on-load — RNG-2 already blocks reload-scumming).
- **Persistence ban.** Engine `hash()` / `String.hash()` are permanently banned in this
  subsystem; the SplitMix64-style mixer and string-fold are frozen (changing them is
  save-breaking).

### Known gaps
- Non-dice event commits (wait/seize/escape/item/staff) + the raw-RNG lint (T5)
  are Slice 1d; snapshot persistence of RNG state (T2) is Step 2; suspend
  round-trip (T6) and equip neutrality (T4) follow. Landed: T1 replay, T3
  butterfly/isolation, T7 roll-order freeze, growth + activation determinism
  (Slice 1c, 2026-07-06), plus the RngService unit tests.

### Anchors
- Code: `scripts/autoloads/RngService.gd`; `CombatResolver.gd`, `TurnManager.gd`
  (`get_action_start_tile`), `SkillHandler.gd` (activation from the event RNG),
  `Unit.gd` (`level_up` chained `levelup` events)
- Tests: `scripts/tests/test_rng_service.gd`,
  `scripts/tests/test_rng_combat_determinism.gd` (T1/T3/T7); pending: T2/T4/T5/T6
- Decisions: RNG-1…4, RULE-001, CRR-1..8, OPEN-13
- Implementation plan: `AGENT/Docs/design/rng_determinism_design_2026-06-11.md`
- Combat-facing rules: GDD_02 → Combat Resolution & Hit RNG

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
# event_record = [attacker_id, "fromX,fromY", "toX,toY", defender_id];
# from_tile is the pre-move tile via TurnManager.get_action_start_tile(unit).
func resolve_combat(attacker: Node, defender: Node, event_record: Array[String] = []) -> Dictionary
# Returns {
#   "exchanges": [ { attacker, defender, weapon, hit, crit, damage,
#                    loses_durability, is_counter, is_follow_up } ],
#   "attacker_died": bool,   # from the simulated HP
#   "defender_died": bool,
#   "context": Dictionary,
#   "rng_event_kind": String,        # "attack"
#   "rng_event_record": Array,       # the event record rolled against
# }

# Phase 2 — commit the result: durability, HP (take_damage), wEXP, EXP, deaths.
# Adds "attacker_exp"/"defender_exp" to result; emits combat_resolved at the end.
# (combat_started is emitted by resolve_combat() above, before any RNG.)
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
> **Hit/crit roll — Implemented (2026-07-06).** Rolls draw from the `RngService`
> per-event RNG (seeded by `begin_event("attack", record)`; `apply_combat_result()`
> commits the event exactly once, before EXP) through the pure-predicate resolver
> seam (CRR-2): `two_roll` (RULE-001) is the default, `single_roll` selectable via
> `CampaignRules.hit_formula`. See GDD_02 → Combat Resolution and "Determinism,
> Snapshot & Online Contract" above.

### `TurnManager.gd`

`class_name TurnManager`. A scene node, child of `GameMap`. Owns phase progression
and per-unit action state.

```gdscript
class_name TurnManager extends Node

signal turn_changed(turn_number: int)

enum UnitState { READY, MOVED, DONE }

var _unit_states: Dictionary = {}     # Node -> UnitState
var _original_tiles: Dictionary = {}  # Node -> pre-move tile, for undo
var _map_over: bool = false
var _group_eliminated_round: Dictionary = {}
var _seize_records: Array[Dictionary] = []
var _escape_records: Array[Dictionary] = []
var _turn_order: Array[String] = []
var _active_faction_idx: int = 0
var _activation_mode: String = "WHOLE_PHASE"

func start_map(map_data: MapData, grid: GridManager = null) -> void
func start_player_phase() -> void
func end_player_phase() -> void
func start_enemy_phase() -> void
func active_faction() -> String
func set_ai_controller(ai: Node) -> void
func set_hotseat_controller(controller: Node) -> void
func set_unit_state(unit: Node, state: UnitState) -> void
func get_unit_state(unit: Node) -> UnitState
func can_unit_act(unit: Node) -> bool          # READY or MOVED
func are_all_player_units_done() -> bool
func record_move_start(unit: Node) -> void     # stores pre-move tile for undo
func undo_move(unit: Node) -> void             # restores tile, returns unit to READY
func check_victory_conditions() -> void
    # Evaluates authored ObjectiveCondition arrays per alliance group, including
    # rout, defeat_boss, protect, survive, seize, escape, and turn_limit.
func record_seize(unit: Node) -> void
func can_seize(unit: Node, tile: Vector2i) -> bool
func record_escape(unit: Node) -> void
func can_escape(unit: Node, tile: Vector2i) -> bool
func get_group_eliminated_round(group: String) -> int
```

In `WHOLE_PHASE`, `start_enemy_phase()` runs phase-start refresh/tick effects once
per faction phase. Same-faction controller replays, such as the debug F9 AI↔hotseat
handoff, rerun the controller without rerunning `_refresh_faction_units()` or
`_begin_phase()`, so units that already spent their action remain `DONE`.

The **activation boundary** is enforced at the controller (V021-01). `EnemyAI.run_phase`
skips any unit for which `can_unit_act()` is false, so a same-faction replay never
re-moves a unit that already finished. Before acting a unit it snapshots the tile via
`record_move_start()`; if the F9 override flips *mid-activation* (so `_act` bails before
finalizing), the loop rolls that unit back to its activation-start tile and `READY` via
`undo_move()` — a unit must either complete its turn (`DONE`) or be fully restored, never
left moved-but-`READY`. The player/hotseat side gets the same guarantee through
`MapCursor.cancel_transient_control_for_handoff()`, which calls
`MapCursorSelection.undo_and_reselect()` (→ `undo_move()`) to back out an uncommitted move
on handoff. This per-selection rollback is the primitive M15B (online serialize-on-handoff)
and M10 (extra activation) inherit.

### `Unit.gd`

`class_name Unit`. One scene instance per unit on the map; wraps a `UnitData`.

```gdscript
class_name Unit extends Node2D

var data: UnitData
var team: String = "blue"   # faction id, not a binary player/enemy enum
var tile_position: Vector2i   # pass-through property to data.tile_position

func initialize(unit_data: UnitData, start_tile: Vector2i, unit_team: String) -> void
func set_grid_manager(grid: GridManager) -> void   # cached by GameMap; avoids tree walks
func get_equipped_weapon() -> WeaponData           # first usable equipped weapon, or null
func get_equipped_weapon_entry() -> InventoryEntry # the matching InventoryEntry, or null
func get_equippable_weapons() -> Array[InventoryEntry]
func set_equipped_weapon(entry: InventoryEntry) -> void
func has_quality(quality: String) -> bool
func has_vulnerability(group: String) -> bool
func get_terrain_def_bonus() -> int
func get_terrain_dodge_bonus() -> int

# Stat access — all combat stats read through get_effective_stat so modifiers apply
func get_effective_stat(stat_name: String) -> int
    # Base value + active_modifiers matching stat_name, clamped >= 0. stat_name must
    # match a UnitData property exactly: "strength","magic","defense","resistance",
    # "skill","speed","luck","hp" — the FULL names, never "str"/"spd"/etc.
func has_skill(skill_id: String) -> bool
func get_skill_uses_remaining(skill_id: String, max_per_map: int) -> int
func consume_skill_use(skill_id: String) -> void

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
func promote(target_class_id: String) -> bool
func can_reclass() -> bool
func get_second_seal_options() -> Array[Dictionary]
func reclass(target_class_id: String, target_line_id := "") -> bool

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
    # Also injects HUD-layer menus/screens and the helper slices
    # (MapCursorSelection / MapCursorTargeting / MapCursorInput).
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
Rendering/Renderer/Rendering Method:  gl_compatibility  (+ .mobile = gl_compatibility)
Rendering/2D/Snap/Snap 2D Vertices To Pixel: ON
```

**Renderer = Compatibility (V021-18, web-load-bearing).** The project runs on the
**Compatibility** renderer (`renderer/rendering_method="gl_compatibility"`), not
Forward+. This is the renderer the debug Web build requires (Web has no Forward+/Mobile
backend) and the game is 2D-only, so the Forward+ feature set is unused. The switch is
pinned here so it can't silently revert; `check_docs.py` guards both this key and the
explicit `Stretch/Aspect: keep` line (the 16:9 contract both desktop letterboxing and the
web canvas rely on).

Tile size: **64 × 64 pixels** (matches GDD_06 tileset spec)
Visible tiles at native resolution: approximately **20 × 11**
Camera clamps to map bounds so empty space is never shown.

**Player display controls (Implemented — Display & Accessibility items 2–3).** The
Settings screen lets the player choose a window mode (Windowed / Borderless /
Fullscreen) and, in windowed mode, a 16:9 resolution (1280×720 / 1600×900 /
1920×1080 / 2560×1440 / 3840×2160), persisted under `[display]` in `settings.cfg`
and applied via `DisplayServer` in `SettingsManager._apply_display()` (desktop only —
see the E1 gate below). All choices are 16:9. The `Stretch/Aspect: keep`
policy above letterboxes non-16:9 screens so the absolute-offset scene nodes stay
on-screen. Menu/modal scale is player-set without changing the HUD's global window
scale — see `GDD_07_UI_UX.md` §Accessibility. Player map zoom is the §Camera Zoom
section below.

In **Windowed** mode, a selected client size that would hide the OS title bar is clamped
to the largest 16:9 client area inside the usable display rect, with a conservative
decoration margin (`SettingsManager.windowed_client_size_for_screen`, V023-06). Exact
monitor-size output is reserved for Borderless (`WINDOW_MODE_FULLSCREEN`) and Fullscreen
(`WINDOW_MODE_EXCLUSIVE_FULLSCREEN`), which are separate code paths.

**OS drag-resize write-back (V027-04b, Q5 owner decision).** While windowed, an OS
resize (edge drag / maximize) **writes the actual client size back into the saved
resolution** and persists it (`SettingsManager.apply_resize_write_back`, announced via
`resolution_written_back`); the Resolution dropdown shows a non-preset value as a
trailing display-only `Custom (WxH)` item, dropped again when a preset is picked.
Programmatic resizes are excluded by comparing against the size `_apply_display`
requested, and a drag never re-centres the window. Detection rides the viewport
`size_changed` hook (V027-04a) that also re-applies Menu Scale after any resize
(deferred + coalesced). Outside Windowed mode the Resolution dropdown is **disabled**
with the readout pinned to the native display size; the saved request is preserved and
the row re-enables intact on return to Windowed (V027-05c, Q6). Player-facing detail:
`AGENT/Docs/guides/display_and_settings_guide.md`.

**Confirm-or-revert on risky display changes.** Changing window mode or resolution
applies the new mode immediately (so the player can see it) but **defers the save
behind a 15-second confirm dialog** (`DisplayConfirmDialog`): Keep persists it, while
Revert or the countdown reaching zero restores the previous value, re-applies it, and
resets the dropdown. This guards the case where a wrong fullscreen/resolution leaves
the screen unusable. Wired generically via a `"confirm": true` flag on the
`SettingsScreen` enum-setting schema, so it covers both display-mode settings.

**Desktop-only display config (E1, mobile-web prep).** Window mode + resolution are
honoured only where the platform can apply them: `SettingsManager.is_display_config_supported()`
returns `false` on Web (the browser + stretch system own the canvas), so `_apply_display()`
skips the `DisplayServer` resize there and `SettingsScreen` hides the two confirm-gated rows.
Desktop behaviour is unchanged. This is a single seam so the renderer/scaling foundation the
debug Web build inherits never plumbs the platform check independently.

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
@export var internal_level: int = 1        # hidden progression state for promotion/reclass

# Stats — implemented storage fields. Combat code reads these via
# Unit.get_effective_stat(); target B3-STAT-REGISTRY generalizes stat names/display.
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

# Personal growth rates, added to the class growth table for player units.
@export var growth_rates: Dictionary = {}

# Authoritative numeric WEXP totals keyed by track (e.g. "sword", "staff",
# "elemental_magic"). Rank display is derived from these totals.
@export var weapon_wexp: Dictionary = {}

# Equipped skill IDs (future prep UI can swap a subset out of earned_skills)
@export var skills: Array[String] = []
@export var earned_skills: Array[String] = []
@export var reclass_options: Array[String] = []
@export var class_line_id: String = ""
# Permanently earned mastery skills. NOT @export — runtime only.
var mastery_skills: Array[String] = []

# Typed inventory — Array[InventoryEntry] (replaced the old Array[Dictionary]).
@export var inventory: Array[InventoryEntry] = []

# Conditions — Array of Dictionaries; see GDD_02. Target: condition/effect registry.
@export var conditions: Array[Dictionary] = []

@export var gold: int = 1000             # legacy field; active economy uses GameState.party_gold
@export var is_incapacitated: bool = false  # permadeath flag
@export var ai_profile: String = "basic"    # Implemented profile id; target AISpec/profile registry — see GDD_08
@export var is_default_roster: bool = false # true for the 6 generated starter units

# ── Phase 2 runtime state ────────────────────────────────────────────────────
# Active temporary stat modifiers. Each entry:
#   { "stat": String, "delta": int, "source": String, "duration": int,
#     "duration_type": "turn"|"map_turn"|"combat"|"permanent" }
# duration -1 or "permanent" type = never auto-removed.
var active_modifiers: Array[Dictionary] = []
var skill_use_counters: Dictionary = {}     # skill.id -> uses this map
var damage_taken_this_map: int = 0          # used by Vengeance (M9)
@export var growth_accumulators: Dictionary = {}   # carry-over for growth_fixed leveling

# Laguz fields — safe defaults for all Beorc units; ignored until M12.
@export var shift_gauge: int = 0
@export var is_shifted: bool = false
@export var shift_profile_id: String = ""
```

> The non-`@export` fields (`tile_position`, `mastery_skills`, `active_modifiers`,
> `skill_use_counters`, `damage_taken_this_map`) are runtime state. `GameState`'s map snapshot copies them
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
@export var combat_family: String = ""    # canonical equip / skill family; target profile data validates ids
@export var wexp_track: String = ""       # canonical trained progression track
@export var required_rank: String = "E"
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
@export var effect_tags: Array[String] = []   # built-in ids today; target component/effect registry
@export var uses_mag: bool = false        # true: MAG for damage, targets RES (tomes)
@export var triangle_family: String = ""       # hybrid override for triangle checks
@export var strikes_per_attack: int = 1   # 2 for Brave weapons
@export var is_natural_weapon: bool = false    # Laguz Fang/Claw/Beak/Talon (deferred)

func is_healing_staff() -> bool                # staff type + heal_10_plus_mag tag
func get_range_min(unit: Node = null) -> int   # evaluates range_min_formula
func get_range_max(unit: Node = null) -> int   # evaluates range_max_formula
func get_triangle_family() -> String
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
@export var tier: int = 1
@export var max_level: int = 20
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
@export var weapon_wexp_bases: Dictionary = {}
@export var weapon_wexp_caps: Dictionary = {}
@export var allowed_weapon_families: Array[String] = []
@export var class_groups: Array[String] = []
@export var special_qualities: Array[String] = []
@export var vulnerability_groups: Array[String] = []
@export var internal_level_rule: String = ""
@export var class_availability: String = "playable"
@export var promotes_to: Array[String] = []
@export var promotes_from: Array[String] = []
@export var promotion_stat_bonuses: Dictionary = {}
const STAT_KEYS: Array[String] = ["hp", "strength", "magic", "defense",
    "resistance", "skill", "speed", "luck"]
@export var player_growth_rates: Dictionary = {}
@export var enemy_growth_rates: Dictionary = {}
@export var stat_caps: Dictionary = {}
@export var skill_unlocks: Dictionary = {}
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

func get_weapon_wexp_base(track: String) -> int
func get_weapon_wexp_cap(track: String) -> int
func get_allowed_weapon_families() -> Array[String]
func resolved_internal_level_rule() -> String
func is_menu_visible() -> bool
```

Each usable WEXP track has an authored class cap. Current classes default to
the A-rank threshold (400 WEXP); special classes may explicitly author S-rank
caps later. `Unit.add_wexp()` stops at the active class cap.

### `ItemData.gd`

```gdscript
class_name ItemData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var item_type: String = ""
    # implemented built-in ids; target item/component registry validates this
@export var uses: int = 1                 # -1 = infinite / equippable
@export var cost: int = 0
@export var effect_id: String = ""
    # implemented ItemHandler ids; target action/effect primitive registry validates this
@export var effect_params: Dictionary = {}
```

### `SkillData.gd`

```gdscript
class_name SkillData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var trigger: String = ""
    # implemented built-in trigger ids:
    # "passive" | "start_of_turn" | "on_attack" | "on_defend" | "on_hit"
    # | "on_kill" | "on_damaged" | "on_combat_start" | "on_combat_end"
    # | "on_move" | "on_level_up" | "player_activated"
    # | "on_combat_start_negate"  (pre-pass before on_combat_start — Nihil)
    # Phase 2: "on_combat_apply_modifiers" | "on_ally_attacked"
    # | "on_enemy_leaves_adjacent" | "on_map_start" | "on_shift"
@export var activation_chance_stat: String = ""
    # e.g. "skill" — empty string if the skill always triggers
@export var activation_divisor: int = 2    # 2 = SKL/2 % activation chance
@export var effect_id: String = ""         # implemented dispatch id; target effect registry
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
@export var player_start_tiles: Array[Vector2i] = []
@export var enemy_placements: Array[Dictionary] = []
    # Each entry carries exactly one UnitData source:
    # { "unit_data_path": String OR "unit_data": UnitData,
    #   "tile": Vector2i, "ai_profile": String?, "is_boss": bool, "faction": String? }
    # "ai_profile" is an explicit placement override; omission preserves the
    # UnitData profile.
    # Target: ai_profile resolves through the AI spec/profile registry, not a match branch.
@export var reward_gold: int = 0
@export var reward_items: Array[String] = []
# Terrain string grid — one String per row; chars per GameMap._CHAR_TO_SOURCE
# (. F M T S D W). Height = grid.size(), width = grid[0].length().
@export var grid: Array[String] = []
# Camera start; Vector2i(-1,-1) = unset -> centroid of player_start_tiles.
@export var camera_start_tile: Vector2i = Vector2i(-1, -1)
@export var factions: Array[FactionData] = []
@export var turn_order: Array[String] = []
@export var activation_mode: String = "WHOLE_PHASE"
@export var victory_conditions: Dictionary = {}   # alliance_group -> Array[ObjectiveCondition]
@export var defeat_conditions: Dictionary = {}

func get_faction(faction_id: String) -> FactionData
```

Objective condition tiles are authored and evaluated in zero-based map coordinates.
HUD display text converts tile coordinates to player-facing one-based coordinates
only at render time.

> **Registry migration note.** The field lists above describe the implemented resource
> schema. Where comments name built-in ids, those ids are the developer preset library
> for today's engine. The target registry rows (`B2-REGISTRY`, `B2-ACTION-EFFECT`,
> `B3-REQ`, `B3-STAT-REGISTRY`, `B3-RESOURCE-POOLS`, `B5-AI-COMPOSITION`) are the
> migration path that prevents new content from requiring one more GDScript `match`.

---

## Camera Zoom

Status: Implemented (Display & Accessibility item 1)

Player-controlled map zoom. The player steps through discrete zoom levels with the
scroll wheel or the `+`/`-`/`0` keys; the chosen level persists across maps and
restarts.

### Design
- Eight discrete levels: **0.25× / 0.5× / 0.75× / 1.0× / 1.5× / 2.0× / 3.0× / 4.0×**
  (`CameraController.ZOOM_LEVELS` is the single source of truth). 1.0× is the default.
  Power-of-two-friendly stops keep pixel snapping crisp at the common zooms; the
  intermediate 0.75/1.5/3 stops can shimmer slightly under `Rendering/2D/Snap`.
- At 1280×720 with 64px tiles, 1× shows ~20×11 tiles; lower zoom shows proportionally
  more, higher zoom fewer (`visible tiles = viewport_px / (TILE_SIZE × zoom)`).
- Zoom re-frames on the cursor's tile, not the screen centre.
- Camera clamping applies at every level (no blank space past the map). When a low
  zoom makes the whole map smaller than the viewport on an axis, that axis is centred.
- At high zoom, the effective edge-scroll buffer is capped by the visible tile span
  so the cursor still has a stable middle zone. Pressing zoom in/out past the
  configured min/max is a no-op and does not reframe the camera.
- The level is stored as `SettingsManager.map_zoom_index` (an index into
  `ZOOM_LEVELS`) and exposed as a stepped slider in the Settings screen.

### Input Actions
| Action | Key | Mouse |
|---|---|---|
| `zoom_in` | = | Scroll Up |
| `zoom_out` | - | Scroll Down |
| `zoom_reset` | 0 | — |

### Implementation
`CameraController.gd` owns the zoom state and the zoom-aware view math: every
tile/pan calculation sizes the visible region through `_visible_world_size()`
(`viewport_px / zoom`) rather than raw pixels, so framing and clamping stay correct
at all levels. The public API is `set_zoom_index` / `step_zoom` / `reset_zoom`
(re-frame on a focus tile) and `set_zoom_index_silent` (level-only, used at map load
before the initial centre). `MapCursor._unhandled_input` maps the input actions onto
`step_zoom` / `reset_zoom` and persists the result; `GameMap` applies the saved level
on map load. When Settings is opened on an active map, `SettingsScreen` finds the
live cursor through the `map_cursor` group and calls `MapCursor.apply_zoom_index()`
so slider changes apply immediately and still persist through `SettingsManager`.

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

Project registration order (`project.godot [autoload]`) is the full thirteen:
`GameConstants → EventBus → RngService → SettingsManager → GameState → DataManager →
ConditionManager → SkillHandler → ItemHandler → CombatResolver → EnemyAI →
PairUpRegistry → PairUpBonusResolver`.
Each autoload's `_ready()` runs in that order. Practical consequence: an autoload
must NOT touch a later autoload from its own `_ready()`. SettingsManager loads
settings from disk but does not push values to GameState; GameState pulls them
in its own `_ready()` instead.

`ConditionManager` is a stub until M8. It must be registered now so other systems
can call into it without `get_node_or_null` guards. `CombatResolver`, `EnemyAI`,
`SkillHandler`, and `ItemHandler` are autoload singletons reached via
`get_node_or_null("/root/...")` — they are not scene nodes.

`RngService` (see "Determinism, Snapshot & Online Contract") sits **after `EventBus`,
before `SettingsManager`** — it has no dependencies and must exist before anything
rolls (Implemented 2026-07-06, B1-PKGA Slice 1a).

### Export-safe content loading

Exported builds cannot reliably enumerate `res://` directories the same way the editor
can. The project's live rule is:

- use `scripts/shared/ResourceManifest.gd`
- author `resource_manifest.json` in content directories that must load in exports
- let `DataManager` and `GameState.load_roster_from_directory()` resolve through the
  manifest first, only falling back to raw directory listing in editor/headless runs

If new exported content appears to load in-editor but vanish in a packaged build, check
for a missing or stale `resource_manifest.json` first.

### `.tres` files in headless mode

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

`GameMap.gd` paints `TileMapLayer_Terrain` at runtime from `MapData.grid`.
This means a data-driven map is added by authoring the terrain string grid in
the map resource, not by editing code-side constants. The string-grid format is
documented in `GDD_06`.

`_validate_map()` asserts row count, row length, and that every char is a
known terrain on `_ready` — transcription bugs fail loud at map load.

### Common onboarding gotchas

- If a new gameplay resource exists on disk but not at runtime, check `DataManager`
  validation errors and the relevant `resource_manifest.json`.
- If a map exists but cannot be chosen from New Game, check `map_registry.json`.
- If a test script needs an autoload, use `get_node_or_null("/root/...")` rather than
  compile-time identifiers.
- If a change affects battle retry behavior, inspect both `GameState.take_map_snapshot()`
  and `restore_map_snapshot()`; Retry rewinds more than HP.

### Test infrastructure

All tests live under `scripts/tests/test_*.gd` and run via
`bash run_tests.sh` (a bash wrapper) or per-suite via
`godot --headless --path . --script res://scripts/tests/<name>.gd`.

Each test extends `SceneTree`, prints `OK`/`FAIL` lines, and exits with code
0/1 for green/red.

Tool scripts (`scripts/tools/`) regenerate placeholder assets and tilesets
deterministically — re-run them after sprite or terrain changes.
