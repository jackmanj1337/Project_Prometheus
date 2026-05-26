# GDD_06 — Maps & Objectives

---

## Map System Overview

Each map is a Godot **TileMapLayer** scene paired with a **MapData** resource.
The TileMap defines the visual layout and terrain. The MapData resource defines
objectives, faction setup, enemy placements, player start tiles, and rewards.

Maps are self-contained — adding a new map never requires code changes.

---

## Tile Setup in Godot

### TileSet Configuration
Create a single shared `TileSet` resource used by all maps.

- **Tile size:** 64 × 64 pixels (authoritative — `GameConstants.TILE_SIZE = 64`, defined in `scripts/shared/GameConstants.gd`)
- **Tile source:** [PLACEHOLDER] spritesheet with all terrain tiles
- Each tile in the TileSet must have a **Custom Data Layer** named `terrain_type` (type: String)
- Valid `terrain_type` values: `"plain"`, `"forest"`, `"mountain"`, `"fort"`, `"sea"`, `"desert"`, `"wall"`

> The shared `terrain_tileset.tres` and `overlay_tileset.tres` are generated
> programmatically by `scripts/tools/generate_tilesets.gd` for the MVP placeholder
> art. Re-run that tool after sprite changes; the script also creates the
> `terrain_type` custom data layer and assigns each tile's value.

### TileMapLayer Setup Per Map
Each map scene contains two TileMapLayers as children of `GameMap`:

1. `TileMapLayer_Terrain` — the actual map tiles; uses the shared TileSet
2. `TileMapLayer_Overlay` — a second layer for movement/attack highlights;
   uses a separate simple TileSet with colored transparent tiles:
   - Tile 0: Blue (movement range)
   - Tile 1: Red (attack range)
   - Tile 2: Green (heal range)
   - Tile 3: Dark red (enemy danger zone)

### Reading Terrain in Code
```gdscript
# In GridManager.gd
func get_terrain_at(tile: Vector2i) -> String:
    var tile_data = _tilemap.get_cell_tile_data(tile)
    if tile_data == null:
        return "wall"   # Out-of-bounds treated as wall
    return tile_data.get_custom_data("terrain_type")
```

---

## Camera

The `Camera2D` node is a child of `GameMap`. It follows the `MapCursor` position.

```gdscript
# Camera clamp settings — set after map loads based on map dimensions
camera.limit_left   = 0
camera.limit_top    = 0
camera.limit_right  = map_width  * GameConstants.TILE_SIZE
camera.limit_bottom = map_height * GameConstants.TILE_SIZE
```

Camera scrolling behavior:
- When the cursor moves within 2 tiles of the viewport edge, the camera pans to keep
  the cursor at least 3 tiles from any edge
- Camera movement is instantaneous (no smoothing) for MVP — matches GBA FE feel
- Set `Camera2D.position_smoothing_enabled = false`

---

## Objective System

Objectives are now authored as typed `ObjectiveCondition` resources grouped by
alliance group:

- `MapData.victory_conditions: Dictionary`
- `MapData.defeat_conditions: Dictionary`

Each key is an alliance-group id such as `"allies"` or `"foes"`, and each value
is an `Array[ObjectiveCondition]`.

`TurnManager.check_victory_conditions()` evaluates these dictionaries after
combat deaths, phase transitions, Seize confirmations, and Escape resolutions.
It emits the legacy blue-perspective `map_victory()` / `map_defeat()` signals
plus the richer `map_resolved(winner_group, standings)` summary for the newer
results flow.

### Authored Condition Types

#### `rout`
The named faction or alliance group has no living units left. With an empty
`faction_id`, the condition means "every faction hostile to the conditioning
group has been eliminated."

#### `defeat_boss`
Every `unit_id` named in the condition is dead.

#### `protect`
Fails when any named `unit_id` dies. Escaped units do not count as dead.

#### `turn_limit`
Condition becomes true when `turn_number > turns`.

#### `survive`
Condition becomes true once `turn_number > turns`, optionally requiring at least
one unit from the conditioning group to stand on one of the authored tiles.

#### `seize`
Condition becomes true when an allowed unit from the conditioning group uses the
Seize action on the authored tile. **Eligibility comes from a per-unit
`can_seize` tag** on `UnitData` — not from class data and not from a per-map
`allowed_unit_ids` allowlist (locked 2026-05-25; see
`AGENT/Docs/campaign_rules_firming_notes_2026-05-25.md`). Authors set the tag on
the relevant lord-class units; new characters opt in by being tagged.

#### `escape`
Condition becomes true when every named `unit_id` has used the Escape action on
one of the authored escape-zone tiles. Escaped units count as **alive** for
`protect` / `survive` evaluation, are removed from the active board, and may
**not act further** on the current map (locked 2026-05-25).

### Evaluation Rules

- Victory for a group is the logical `AND` of that group's authored victory conditions.
- Defeat for a group is the logical `OR` of that group's authored defeat conditions.
- A group with no authored defeat list gets an implicit "group routed" defeat so
  every group has a way to leave play.
- If one group remains in play, it wins by last-group-standing even without an
  explicit victory condition.
- If no groups remain in play, the map resolves as a draw.

---

## MapData Resource

```gdscript
# scripts/resources/MapData.gd — see GDD_01 → MapData.gd for the authoritative list
class_name MapData extends Resource

@export var id: String
@export var display_name: String
@export var tilemap_scene_path: String
@export var player_start_tiles: Array[Vector2i]
@export var enemy_placements: Array[Dictionary]
# enemy_placement dict: { "unit_data_path": String, "tile": Vector2i,
#                         "ai_profile": String, "is_boss": bool, "faction": String? }
@export var reward_gold: int = 0
@export var reward_items: Array[String]             # item IDs granted at map completion
@export var grid: Array[String]                     # terrain string grid (data-driven maps)
@export var camera_start_tile: Vector2i             # (-1,-1) = centroid of player starts
@export var factions: Array[FactionData]
@export var turn_order: Array[String]
@export var activation_mode: String = "WHOLE_PHASE"
@export var victory_conditions: Dictionary          # alliance_group -> Array[ObjectiveCondition]
@export var defeat_conditions: Dictionary
```

---

## MVP Map: Map 001 — "First Battle" (Rout)

### Summary
- **Size:** 42 × 26 tiles
- **Objective:** Rout (defeat all 8 enemies)
- **Player units:** 6 (auto-deployed from default roster)
- **Visible area at 64px:** ~20×11 tiles — map is much larger than the viewport,
  forcing camera scrolling in all directions
- **Turn limit:** None
- **Reward:** 500 gold
- **Terrain types present:** Plain, Forest, Mountain, Fort, Sea, Desert, Wall

### Tile Legend
```
W = Wall       (impassable)
. = Plain      (no modifiers)
F = Forest     (+1 DEF, +15 Dodge, move cost 2)
M = Mountain   (+2 DEF, +20 Dodge, move cost 3)
T = Fort       (+2 DEF, +30 Dodge, no move penalty, heals 10% HP/turn)
S = Sea        (+10 Dodge, move cost 2)
D = Desert     (+5 Dodge, move cost 2; cost 3 for armoured/mounted)
```

### Map Grid (42 cols × 26 rows)

```
     0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41
  0 [W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W]
  1 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][S][S][S][.][.][M][M][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][W]
  2 [W][.][.][F][F][.][.][.][.][.][.][.][.][.][.][.][S][S][S][.][M][M][M][.][.][.][.][F][F][.][.][.][.][.][.][.][.][.][.][.][.][W]
  3 [W][.][.][F][F][.][.][.][.][.][.][.][.][.][.][.][S][S][S][.][M][M][M][.][.][.][.][F][F][.][.][.][.][.][.][.][.][.][.][.][.][W]
  4 [W][.][.][.][.][.][.][.][.][.][.][F][F][.][.][.][S][S][S][.][.][M][M][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][W][W][W][W]
  5 [W][.][.][.][.][.][.][.][.][.][.][F][F][.][.][.][S][S][S][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][W][W][W][W]
  6 [W][.][.][.][.][.][.][T][.][.][.][.][.][.][.][.][.][S][S][.][.][.][.][.][.][.][.][.][F][F][.][.][.][.][.][.][.][.][.][.][.][W]
  7 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][S][S][.][.][.][.][.][.][.][.][.][F][F][.][.][.][.][.][F][F][.][.][.][.][W]
  8 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][S][S][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][F][F][.][.][.][.][W]
  9 [W][.][.][.][.][.][.][.][.][.][.][.][.][F][F][.][.][S][S][.][.][.][.][F][F][.][.][.][.][.][.][.][.][.][.][.][.][.][T][.][.][W]
 10 [W][.][.][.][.][.][.][.][.][.][.][.][.][F][F][.][.][.][S][.][.][.][.][F][F][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][W]
 11 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][S][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][W]
 12 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][S][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][T][.][W]
 13 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][S][S][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][W]
 14 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][S][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][W]
 15 [W][.][.][.][.][.][F][F][.][.][.][.][.][.][.][.][.][.][.][S][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][W]
 16 [W][.][.][.][.][.][F][F][.][.][.][.][.][.][.][.][.][.][.][S][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][.][.][.][.][W]
 17 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][S][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][.][.][.][.][W]
 18 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][S][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][.][.][.][.][W]
 19 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][S][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][.][.][.][.][W]
 20 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][.][.][.][.][W]
 21 [W][.][.][.][.][.][.][.][.][M][M][.][.][.][.][.][.][.][.][.][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][.][.][.][.][W]
 22 [W][.][.][.][.][.][.][.][.][M][M][.][.][.][.][.][.][.][.][.][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][D][.][.][.][.][W]
 23 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][W]
 24 [W][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][.][W]
 25 [W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W][W]
```

### Terrain Features

| Feature | Tiles | Notes |
|---|---|---|
| **Sea (river)** | Col 16–18 rows 1–5; col 17–18 rows 6–13; col 18 rows 10–19; col 19 rows 13–19 | Diagonal river shape; crossable at cost 2; creates major east–west barrier |
| **Crossing zone** | Col 18–19 rows 10–12 | Narrowest sea section; natural chokepoint |
| **Forest NW** | (3–4, 2–3) | Player-side cover |
| **Forest central-W** | (11–12, 4–5) | Mid-left cover |
| **Forest central-E** | (13–14, 9–10) | Near the crossing |
| **Forest E upper** | (27–28, 2–3) and (28–29, 6–7) | East side tree cover |
| **Forest E mid** | (23–24, 9–10) | Post-crossing cover |
| **Forest SW** | (6–7, 15–16) | Southern player-side cover |
| **Forest far-E** | (35–36, 7–8) | Near enemy territory |
| **Mountain N** | (21–22, 1–3) and (20–22, 2–3) | North mountain wall; forces sea crossing |
| **Mountain S** | (9–10, 21–22) | Southern mountain cluster |
| **Fort (player-side)** | (7, 6) | Players can use for HP recovery mid-map |
| **Fort (E7)** | (38, 9) | Enemy E7 starts here |
| **Fort / Throne (boss)** | (39, 12) | Enemy E8 (boss) starts here; heals every turn |
| **Desert belt** | Cols 20–36 rows 16–22 | Slows armoured and mounted units; thief/mage unaffected |
| **Walled corner** | Cols 38–41 rows 4–5 | Impassable cliff; blocks northeast shortcut |

### Player Start Tiles
Auto-deployed in slot order (Unit_01 first):

| Unit | Slot | Start Tile |
|---|---|---|
| Unit_01 (Soldier) | 1 | (1, 9) |
| Unit_02 (Mercenary) | 2 | (1, 10) |
| Unit_03 (Archer) | 3 | (1, 11) |
| Unit_04 (Mage) | 4 | (2, 9) |
| Unit_05 (Cleric) | 5 | (2, 10) |
| Unit_06 (Knight) | 6 | (2, 11) |

### Enemy Placements

| # | File | Tile | Class | Level | Weapon | Item | AI | Notes |
|---|---|---|---|---|---|---|---|---|
| E1 | `e1_soldier.tres` | (24, 2) | Soldier | 3 | Iron Lance | — | basic | Guards north mountain pass |
| E2 | `e2_archer.tres` | (28, 7) | Archer | 3 | Iron Bow | — | basic | In eastern forest; ranged threat |
| E3 | `e3_mercenary.tres` | (23, 11) | Mercenary | 3 | Iron Sword | — | basic | Guards sea crossing; fast |
| E4 | `e4_knight.tres` | (27, 15) | Knight | 3 | Iron Lance | — | basic | Slow central defender |
| E5 | `e5_archer.tres` | (35, 8) | Archer | 3 | Iron Bow | — | basic | Far east forest; covers approach |
| E6 | `e6_soldier.tres` | (30, 18) | Soldier | 4 | Iron Lance | — | basic | Desert patrol; slowed if mounted nearby |
| E7 | `e7_knight_sub.tres` | (38, 9) | Knight | 4 | Iron Lance | Vulnerary | basic | Standard enemy on Fort; heals each turn; `is_boss=false` |
| E8 | `e8_knight_boss.tres` | (39, 12) | Knight | 5 | Iron Lance | Vulnerary | basic | Boss on Fort; highest stats; heals each turn |

### Enemy UnitData Stats (Level-based formula)

Use `stat = base_stat + floor((growth_rate / 100) * (level - 1))` for each stat.
Apply using the class's growth rates from `ClassData`. Round down all results.

### Tactical Notes for Map Design
- The sea river is the map's central challenge — players must decide when and where
  to cross. The crossing zone at cols 18–19 rows 10–12 is the safest but funnels units
- E3 (Mercenary) near the crossing punishes slow crossings
- The Fort at (7, 6) rewards players who position their healer or damaged units nearby
- The desert in the south-east slows armoured/mounted units approaching the boss
- The walled northeast corner at cols 38–41 rows 4–5 prevents a shortcut; players
  must come around through the main map

### Enemy UnitData for MVP Map

Enemy UnitData resources are created as `.tres` files in
`data/maps/map_001_rout/enemies/`. Use base class stats at the specified level
(no level-up rolls for enemies — use static stat blocks at their level's expected values).

**Formula for enemy stats at level N** (approximate):
```
stat = base_stat + floor((growth_rate / 100) * (N - 1))
```
Apply this to each stat using the class's growth rates.

---

## Doors and Chests (Phase 2)

Not in MVP. Architecture placeholder:

- Doors are map objects (not tiles). Implement as `Node2D` with HP and a `is_open` flag.
- Chests are similarly `Node2D` with a `loot_item_id` String.
- A unit adjacent to a door/chest can interact via the Action Menu.
- Doors can be opened with a Door Key or the `pick` skill (Thief).
- Chests can be opened with a Chest Key or the `pick` skill.

Door HP values from handbook:
| Type | HP |
|---|---|
| Wooden Door | 25 |
| Reinforced Wooden Door | 40 |
| Iron Door | 50 |
| Reinforced Iron Door | 65 |
| Portcullis | 80 |
| Castle Door | 100 |

---

## Fog of War (Phase 2)

Not in MVP. Architecture placeholder:

- Each unit has a `LoS` stat (line of sight radius in tiles)
- A `FogOfWarManager` node tracks which tiles are currently visible to the player
- Tiles outside LoS of all player units are hidden (black overlay)
- Enemies in hidden tiles are not drawn; their positions are unknown
- A `Torch` item temporarily increases a unit's LoS by 4

Store fog state as a `Dictionary` of tile → visibility status on `GameState`.

---

## Phase 3 Maps 002–005 — Authoring Rules (locked 2026-05-25)

The objective-map followup authors four maps against the implemented
`ObjectiveCondition` system to validate it through real content. See
`GDD_10_Roadmap.md` § Milestone 16 → *Locked design decisions* and
`AGENT/Docs/campaign_rules_firming_notes_2026-05-25.md`.

- **Showcase plan — one map per primary objective.** Maps 002–005 cover the
  four objective types one each: **Seize**, **Defeat Boss**, **Escape**,
  **Survive / Defend**. Variety within a type is a later authoring pass.
- **One primary objective per map.** Each of the four maps declares **exactly
  one** primary victory objective for blue. Multi-primary and optional-
  secondary objectives are out of scope until the basics are validated.
- **Seize eligibility comes from the `can_seize` unit tag** (not class, not a
  per-map allowlist).
- **Escape semantics — alive, removed from the board, no further actions
  this map.**
- **Authored defeat standard — ≥1 authored defeat per map, beyond rout.** Every
  Phase 3 objective map must declare at least one **authored** defeat condition
  (e.g. `turn_limit`, `protect`, hold-the-tile failure) in addition to the
  implicit "all units dead" rout fallback. The implicit rout condition is
  satisfied by leaving a group's `defeat_conditions` list empty, but Maps
  002–005 must *also* add at least one explicit entry.

---

## Adding a New Map (Checklist)

Two approaches are supported:

### Data-driven (used for MVP `map_001`)
The map layout lives in `MapData.grid`. No editor painting is required for
terrain. To add a map this way:
- [ ] Create `MapData.tres` with a `grid` string array using the legend `. F M T S D W`
- [ ] Fill `player_start_tiles`, `enemy_placements`, rewards, and camera start
- [ ] Author `factions`, `turn_order`, and `activation_mode` only when the map
      needs to override the default blue/green/red/yellow behavior
- [ ] Author `victory_conditions` / `defeat_conditions` using `ObjectiveCondition`
- [ ] Create enemy `UnitData` `.tres` files
- [ ] `_validate_map()` asserts row count, row length, and chars on `_ready`

### Editor-painted (heavier maps in Phase 2+)
- [ ] Create folder `res://data/maps/map_XXX_name/`
- [ ] Build TileMap scene in Godot editor using shared TileSet
- [ ] Verify every tile has correct `terrain_type` custom data set
- [ ] Create `MapData` resource, fill all fields
- [ ] Create enemy `UnitData` `.tres` files for all enemies on this map
- [ ] Reference enemy `.tres` paths in `MapData.enemy_placements`
- [ ] Set `player_start_tiles` array
- [ ] Set `victory_conditions` / `defeat_conditions`
- [ ] Register map in the map select / campaign sequence `[PLACEHOLDER]`
- [ ] Test: verify all tiles are passable/impassable as intended
- [ ] Test: verify objective triggers correctly
- [ ] Test: verify enemy placements load at correct tiles
