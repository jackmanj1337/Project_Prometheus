# GDD_01 — Architecture & Project Structure

**Status:** Active architecture contract; runtime and data detail are split into the
companion GDD_01 contracts linked below.
**Last verified:** 2026-07-13
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This entry chapter owns project composition, scene/autoload responsibility, extension
boundaries, and contributor-facing architectural constraints. Binding runtime behavior
lives in `GDD_01_Runtime_Contracts.md`; resource and serialization shapes live in
`GDD_01_Data_Contracts.md`. Feature chapters `GDD_02`–`GDD_08` own gameplay rules.

---

## Companion Contracts

- [Runtime contracts](GDD_01_Runtime_Contracts.md) — CampaignRules, determinism,
  snapshots, online boundaries, and service/API invariants.
- [Data contracts](GDD_01_Data_Contracts.md) — resource schemas, persistence fields,
  validation, and authoring invariants.

Display configuration and input behavior are owned by `GDD_07` and the display/settings
guide (`B6-INPUT` for remaining input work). Tactical camera behavior is owned by
`GDD_06 §Tactical Camera`. These contracts are linked instead of duplicated here.

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

### Action/Effect Execution Boundary

Status: **Implemented - contract groundwork**
Last verified: 2026-07-13

State-changing authored actions use a structured `ActionRequest`, `ActionContext`,
and `ActionResult`. `ActionEffectRunner` resolves the request's primitive entry
through `RegistryManager`, validates required subjects and the declared parameter
schema, and only then invokes the engine-owned handler. Unknown primitives,
unavailable handlers, missing subjects, and malformed parameters return structured
failures before mutation. Dry-run requests follow the same validation path and do
not invoke a handler. Parameters omitted from schemas that mark them optional reach
the handler through neutral defaults rather than failing after validation.

The first proof primitive, `apply_active_modifier`, is shared by the existing item
domain and a map-event fixture. It reports `UnitData.active_modifiers` as its touched
save field; all registry entries marked as mutations must declare at least one save
field. Requirement-gated availability remains owned by `B3-REQ`, and broader item,
map-event, dialogue, economy, and objective migrations remain later consumers.

### Resource Transaction Boundary

Status: **Implemented - contract groundwork**
Last verified: 2026-07-13

`ResourceLedger` is the shared affordability and mutation path for registered
wallets. Fixed `CostSpec` records can be quoted without mutation, reserved as
transient non-mutating records, committed atomically across multiple wallets, and
refunded from the recorded committed deltas. Every result is a structured
`ResourceTransaction` containing wallet ids, deltas, shortfalls, and a failure
reason. Unknown resources, unresolved subjects, unsupported scopes, formula terms,
and insufficient balances fail before any wallet changes. A failed refund reports
only its shortfall; its public wallet/delta fields never claim unapplied reversals.

The first registry-backed adapters expose the existing `GameState.party_gold` and
legacy `UnitData.gold` fields. Victory gold now credits the party adapter while item
rewards retain their existing append behavior. Dynamic formula terms, persistent
holds, custom resource pools, and shop/training consumers remain with their owning
later tracks.

### Death Lifecycle Boundary

Status: **Implemented - contract groundwork**
Last verified: 2026-07-13

All production combat deaths enter `DeathLifecycle.handle_death(DeathContext)`.
The context snapshots identity, inventory, tile, source, responsible actor, and a
simultaneous-death group before disposition begins. `DeathDisposition` is the one
future custody/inventory hook; its initial implementation is deliberately a no-op.
`DeathLifecycle` is the sole implementation: combat reports a missing autoload as
an error and stops death processing instead of entering a compatibility fallback.
The lifecycle reads `GameState.campaign_rules`, releases Pair Up support,
unregisters the unit, emits `unit_died` once, and queues the scene node for removal.
`Unit.handle_death()` remains only as a compatibility wrapper. Non-combat causes,
object teardown, key-item custody, and battalion disposition remain later consumers.

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
    │   ├── InputModeManager.gd
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
    │   ├── SelectionCursor.gd
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

## Autoload Composition

The exact registration order is owned by `project.godot [autoload]`; the
“Autoload load order” note below records the dependency invariant and current order.
Responsibilities are divided as follows:

| Layer | Autoloads | Responsibility |
|---|---|---|
| Shared foundation | `GameConstants`, `EventBus`, `RngService`, `SettingsManager`, `InputModeManager`, `GameState` | Common vocabulary/events, deterministic RNG, app settings/input mode, and live campaign/map state |
| Extensibility and transactions | `RegistryManager`, `ActionEffectRunner`, `ResourceLedger`, `OccupancyService`, `DeathLifecycle`, `ProjectionService` | Registry resolution and shared mutation, placement, death, and forecast boundaries |
| Content and persistence | `DataManager`, `SaveManager` | Content load/validation and save-slot disk I/O |
| Gameplay services | `ConditionManager`, `SkillHandler`, `ItemHandler`, `CombatResolver`, `EnemyAI`, `PairUpRegistry`, `PairUpBonusResolver` | Feature execution shared across scenes |

`GameState` owns live state and Retry/suspend capture orchestration; the binding
snapshot and deterministic-event rules live in
[GDD_01 — Runtime Contracts](GDD_01_Runtime_Contracts.md). `DataManager` performs
strict replace-load for a selected self-contained content root; its resource shapes
and validation obligations live in
[GDD_01 — Data Contracts](GDD_01_Data_Contracts.md).

New Game launch is selector-driven through `data/maps/map_registry.json`. A launch
commits an explicit map path and roster policy/source before opening `GameMap`;
missing roster preparation fails loud instead of substituting the default roster.
The operational authoring flow is in
[Map And Campaign Content Authoring Guide](../Docs/guides/map_authoring_guide.md).

Input persistence and mode resolution belong to `GDD_07` and `B6-INPUT`.
Condition behavior belongs to `GDD_02` and its planned condition-effects track. Event payloads and
service signatures are code-owned; GDD chapters document only cross-system
invariants.

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

Project registration order (`project.godot [autoload]`) is the full 21:

`GameConstants → EventBus → RngService → SettingsManager → InputModeManager →
GameState → RegistryManager → ActionEffectRunner → ResourceLedger →
OccupancyService → DeathLifecycle → ProjectionService → DataManager →
SaveManager → ConditionManager → SkillHandler → ItemHandler → CombatResolver →
EnemyAI → PairUpRegistry → PairUpBonusResolver`.

Each autoload's `_ready()` runs in that order, so startup code must not assume a
later autoload is initialized. `RngService` intentionally precedes all gameplay
consumers. The Band 2 shared services precede `DataManager`, whose boot validation
uses the registry foundation. `SaveManager` follows data loading and owns disk I/O;
snapshot encoding remains in the runtime/data contracts.

`ConditionManager` is an implemented seam with no-op condition behavior while
the condition-effects implementation remains planned. `SkillHandler`, `ItemHandler`,
`CombatResolver`, and `EnemyAI` are autoloads rather than scene nodes. Runtime
code and headless tests should resolve autoloads through `/root/<name>` when
compile-time singleton identifiers are unavailable.

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
