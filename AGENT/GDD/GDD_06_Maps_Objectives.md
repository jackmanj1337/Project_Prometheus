# GDD_06 — Maps & Objectives

**Status:** Active contract — split status per section (the objective system, map schema,
and project terrain values are **Implemented**; corpus terrain values/movement categories
are **Target design** (RULE-010/SET-008) and the terrain ID mapping is an **Open
decision** (RULE-011/AWR-8), tracked in `GDD_Adoption_Matrix.md`).
**Last verified:** 2026-07-21
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This chapter owns the **terrain/movement schema** (terrain types, movement categories,
authored values) and the **objective + authored-map contracts**. The *combat effects* of
terrain (defender DEF/Dodge, fort heal) are applied by `GDD_02 §Terrain`; resource schemas
(`BattleMapDef`, `BattleEncounterDef`, legacy `MapData`, `FactionData`,
`ObjectiveCondition`) are defined in `GDD_01`. For the practical
authoring workflow, registry entry shape, roster-policy rules, and export-manifest
reminders, use `AGENT/Docs/guides/map_authoring_guide.md`.

## Map System Overview

Status: **Implemented**
Last verified: 2026-07-16

Battles use the shared `GameMap.tscn`. A **BattleMapDef** supplies reusable
terrain/layout and a **BattleEncounterDef** supplies the fight payload. Campaign
nodes resolve `encounter_id -> battle_map_id`; direct and legacy `map_id`
launches pass through the explicit `MapData` adapter.

Maps are self-contained — adding a new map never requires code changes. A campaign
package should carry its map data, rosters, rules/presets, object data, and raw assets
without depending on executable code.

---

## Terrain & Movement

Status: **Split** — project terrain values/movement costs **Implemented**; corpus values + movement categories **Target design** (SET-008/RULE-010); terrain ID mapping **Open decision** (RULE-011/AWR-8)
Last verified: 2026-06-13

### Summary
This section owns the terrain **schema** (terrain types + their movement/defense data) and
the movement-cost model. The *combat application* of the DEF/Dodge/heal values is owned by
`GDD_02 §Terrain`, which links here rather than repeating the value table.

### Specs

**Implemented (project terrain values).** Each `terrain_type` carries move cost + defender
bonuses; bonuses apply to the defender only, during combat (GDD_02).

| Terrain (`terrain_type`) | Move cost | DEF | Dodge | Notes |
|---|---|---|---|---|
| `plain` | 1 | 0 | 0 | |
| `forest` | 2 | +1 | +15 | |
| `mountain` | 3 | +2 | +20 | |
| `fort` | 1 | +2 | +30 | Heals `max(1, floor(0.10 × max_hp))`/turn (OPEN-7) |
| `sea` | 2 | 0 | +10 | |
| `desert` | 2 (3 armoured/mounted) | 0 | +5 | Magic/Thief line cost 1 |
| `wall` | 999 (impassable) | — | — | Out-of-bounds resolves to `wall` |

- Move cost is consulted by `GridManager.get_move_cost()` (skill movement overrides first).
- Valid `terrain_type` strings: `plain`, `forest`, `mountain`, `fort`, `sea`, `desert`,
  `wall` (the TileSet `terrain_type` custom-data layer + the `MapData.grid` legend
  `. F M T S D W`).

**Target design (corpus terrain & movement, SET-008/RULE-010).** Corpus terrain values and
**movement categories** are an adopted target; **show both tables until** code/data/maps
migrate (RULE-010). Flying is implemented via terrain movement-cost categories (Planned),
never a terrain-ignoring special case. Provenance: `GDD_Adoption_Matrix.md` →
`awakening_lookup_tables.md` (Terrain Categories / Movement Types).

Terrain ids, movement categories, defense/dodge values, and healing profiles are
developer presets over authorable terrain/rule data. New terrain with existing behavior
should be data-only; new movement primitives go through the registry/primitive path.

### Known gaps
- **Terrain ID mapping (RULE-011, Open decision → AWR-8):** sea / wall-building variants /
  throne-vs-Fort behavior are resolved by a **mapping pass**, not name equality. Throne art
  presently reuses Fort runtime behavior. Do not assume name-equality mappings.

### Anchors
- Code: `scripts/core/GridManager.gd` (`get_terrain_at`, `get_move_cost`,
  `TERRAIN_DEF_BONUS`, `TERRAIN_DODGE_BONUS`)
- Decisions: SET-008, RULE-010, RULE-011, OPEN-7
- Owner of terrain combat effects: GDD_02 §Terrain
- Reference: `awakening_lookup_tables.md`; `GDD_Adoption_Matrix.md`

---

## Tile Setup in Godot

Status: **Implemented** (placeholder art)
Last verified: 2026-06-13

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

### Runtime TileMapLayer Setup
The shared `GameMap` scene contains three TileMapLayers:

1. `TileMapLayer_Terrain` — the actual map tiles; uses the shared TileSet
2. `TileMapLayer_Overlay` — a second layer for movement/attack highlights;
   uses a separate simple TileSet with colored transparent tiles:
   - Tile 0: Blue (movement range)
   - Tile 1: Red (attack range)
   - Tile 2: Green (heal range)
   - Tile 3: Dark red (enemy danger zone)
   - Tile 4: Darker red (watched-threat danger zone)
   - Tiles 5-10: shared-cell border-through prototype sources
   - Tiles 11-40: generated threat-perimeter edge-mask sources for the
     `stacked_perimeter` MRD-7 candidate
3. `TileMapLayer_OverlayTop` — optional second overlay lane for MRD-7 stacked
   range/target fill above retained threat paint

`GridManager.get_terrain_at()` reads the TileSet custom-data value; missing/out-of-bounds
cells resolve to `wall`. Exact implementation belongs to production code.

---

## Tactical Camera

Status: **Implemented**
Last verified: 2026-07-13

`CameraController` is the sole production writer of tactical-camera position. It keeps
the cursor within the configured edge buffer, accounts for zoom when measuring the
visible world, clamps each axis to map bounds, and centers maps smaller than the view.
Player-phase cursor movement is immediate; AI tracking temporarily enables smoothing.
Each faction's last view is restored when its phase returns. Zoom and edge-buffer
settings presentation are owned by `GDD_07`.

### Anchors
- Code: `scripts/core/CameraController.gd`, `scripts/core/MapCursor.gd`
- Settings owner: `GDD_07 §Settings`

---

## Rewind Boundaries

Status: **Implemented**
Last verified: 2026-07-15

The tactical map records a suspend-complete checkpoint after every committed
activation and after each refreshed round start. Multiple unit-state writes made
by one atomic action coalesce into one activation checkpoint. Rewind is exposed
only while an earlier checkpoint and a campaign-authored charge remain. Full-history
cost mode retains every activation boundary; per-activation mode uses its authored
fine-history cap. Rewind restores the boundary through the normal active-map resume
path, stages the already-truncated ledger in the durable payload, spends one charge,
and only then truncates live history. Round-0 remains reserved for Retry. Because the
checkpoint includes the RNG timeline, repeating an identical decision repeats its
outcome while a different committed decision advances a different history chain.

### Anchors
- Runtime: `scripts/core/TurnManager.gd`, `scripts/autoloads/GameState.gd`
- Ledger: `scripts/save/MapLedger.gd`
- Rule owner: `GDD_01 §CampaignRules Contract`

Campaign nodes may author an open `rule_overrides` dictionary. It becomes the
middle layer only while that node's map is active, below triggered mid-map flips
and above effective campaign defaults. A mandate cannot be shadowed. The layer
is included in suspend/ledger state and clears on map commit or campaign cancel.

---

## Objective System

Status: **Implemented**
Last verified: 2026-07-15

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

The following compatibility ids are implemented registry presets. Their data entries
bind validation, evaluation, and display primitives through
`ObjectiveConditionRegistry`; `DataManager`, `TurnManager`, and the HUD no longer own
closed id switches. A new objective id that reuses registered primitives is authored
as registry data; only a new primitive predicate requires engine work. The broader
`[TCV-4]`/`B3-REQ`/`B3-MET` requirement/action composition, `end_map` actions, and
event-driven re-checks remain their own tracks.

#### `rout`
The named faction or alliance group has no living units left. With an empty
`faction_id`, the condition means "every faction hostile to the conditioning
group has been eliminated." Liveness here counts **every** undefeated unit,
including a paired support hidden off-map — a pair's support is not "dead" just
because it is off the grid, so a Rout does not resolve while one survives.
(`TurnManager._eval_rout` uses `GameState.get_all_living_units_of`, not the
support-excluding `get_living_units_of` used for selection/turn-end.)

#### `defeat_boss`
Every `unit_id` named in the condition is dead.

#### `protect`
Fails when any named `unit_id` dies. Escaped units do not count as dead.

#### `turn_limit`
Condition becomes true when `turn_number > turns`.

#### `survive`
Condition becomes true once `turn_number > turns`, optionally requiring at least
one unit from the conditioning group to stand on one of the authored tiles. The
shipped Map 005 Defend objective is pure survival through turn 6 plus protection of
its lord; it has no hold-tile requirement or separate turn-limit defeat.

#### `seize`
Condition becomes true when an allowed unit from the conditioning group uses the
Seize action on the authored tile. **Eligibility comes from a per-unit
`can_seize` tag** on `UnitData` — not from class data and not from a per-map
`allowed_unit_ids` allowlist (locked 2026-05-25; see
`AGENT/Docs/archive/reference/campaign_rules_firming_notes_2026-05-25.md`). Authors set the tag on
the relevant lord-class units; new characters opt in by being tagged.

#### `escape`
Condition becomes true when every named `unit_id` has used the Escape action on
one of the authored escape-zone tiles. Escaped units count as **alive** for
`protect` / `survive` evaluation, are removed from the active board, and may
**not act further** on the current map (locked 2026-05-25). A paired lead and support
both retain the escape tile in roster/save state rather than persisting the off-map
Pair Up sentinel.

### Evaluation Rules

- Victory for a group is the logical `AND` of that group's authored victory conditions.
- Defeat for a group is the logical `OR` of that group's authored defeat conditions.
- Rout is never implicit. A group is eliminated only by an authored defeat
  condition. Maps that should fail when a group has no living units must author
  a `rout` defeat for that group.
- If one group remains in play, it wins by last-group-standing even without an
  explicit victory condition.
- If no groups remain in play, the map resolves as a draw.

Explicit Rout is required because a zero-unit group may still be active while
waiting for reinforcements, and timed or escape objectives can fail without any
opposing units remaining.

---

## Battle Map And Encounter Resources

`BattleMapDef` binds identity/display, terrain source, camera/player starts, and enemy
spawn zones. `BattleEncounterDef` binds one map, faction scheduling, unit placements,
grouped objective conditions, and completion rewards. A placement must
provide exactly one unit source (`unit_data_path` or `unit_data`) plus its tile; optional
AI/faction/boss fields refine that placement. The exact typed field list is owned by
`GDD_01`. Legacy `MapData` is adapted only at DataManager's resolution boundary.

**Implemented (Tier-2 `map_data` schema, 2026-08-01).** A pack-authored map is a
registered engine-owned schema in `EntitySchemaRegistry` (`map_data` version 1). v1
registers **one** document holding terrain and encounter together, because `MapData`
holds both today; splitting them here would invent a boundary the resource, the adapter,
and the runtime validator do not have. The split belongs with the first encounter
authored independently of its terrain.

The schema owns **document shape** only: admitted fields, types, vocabularies, and exact
JSON paths. Inline enemy placements reuse the roster schema's unit object rather than a
second copy, so an unknown field inside a placement reports
`enemy_placements[i].unit.<field>`. Objective condition types resolve through
`ObjectiveConditionRegistry` — the canonical `[TCV-4]` open registry, so adding a
condition stays a registration. `activation_mode` is the deliberate opposite: a **closed**
engine vocabulary seeded from `GameConstants.VALID_ACTIVATION_MODES`, because a new mode
is a turn-scheduler change rather than authored content. Victory/defeat condition keys
carry no key vocabulary — the group names are author-defined and are cross-checked
against the map's own factions instead. `tilemap_scene_path` is **not** admitted: a pack
carries indexed JSON plus approved Tier-1 media only, so it can never ship the
`PackedScene` that field names.

Map **semantics** — tile bounds, terrain codes, faction and turn-order coherence,
duplicate tiles, objective groups against alliance groups — keep their single existing
owner in `DataManager.collect_map_data_validation_errors`, which now also runs on Tier-2
packs at activation, before the content session is committed. A pack is therefore held to
the same map rules as project data rather than to a second, weaker copy of them.

Faction lists authored by a pack now actually reach the map: `MapData.factions` is an
`Array[FactionData]` export, so the adapter's plain property copy silently left it empty
before this family, and an authored faction list became the blue+red default without a
diagnostic. An empty authored list remains legal and still means "use the default".

---

## MVP Map: Map 001 — "First Battle" (Rout)

Status: **Implemented** (authored content reference)
Last verified: 2026-06-13

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
| **Fort with throne art (boss)** | (39, 12) | Uses Fort runtime behavior; enemy E8 starts here and heals every turn |
| **Desert belt** | Cols 20–36 rows 16–22 | Slows armoured and mounted units; thief/mage unaffected |
| **Walled corner** | Cols 38–41 rows 4–5 | Impassable cliff; blocks northeast shortcut |

### Player Start Tiles
Auto-deployed in slot order (Unit_01 first):

| Unit | Slot | Start Tile |
|---|---|---|
| Unit_01 (Cavalier) | 1 | (1, 9) |
| Unit_02 (Mercenary) | 2 | (1, 10) |
| Unit_03 (Archer) | 3 | (1, 11) |
| Unit_04 (Mage) | 4 | (2, 9) |
| Unit_05 (Cleric) | 5 | (2, 10) |
| Unit_06 (Knight) | 6 | (2, 11) |

### Enemy Placements

Map-start placements are checked by the implemented `B2-OCCUPANCY` transaction
service before unit instancing. Authored player/enemy overlaps fail validation;
runtime `require_empty` prevents accidental double occupancy. The shared policy
registry also provides deterministic `nearest_free`, `delay`, and `skip` for
later spawn consumers. Swap, hidden overlap, and object-unit behavior remain
reserved until their owning slices implement them.

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

## Doors and Chests

Status: **Planned** (Phase 2)
Last verified: 2026-06-13

Not in MVP. Architecture placeholder:

- Doors, chests, villages, shops, breakables, and stationary weapons use the unified
  `map_objects` model (`B4-MAP-OBJECTS`, `[DCH]`, `[SAC]`), not bespoke node classes.
- Each object authors its component ids, state fields, interaction options, HP/lock data,
  loot, and ordered action/effect list.
- The Action Menu exposes `activate`; the object/component registry decides which
  interactions are legal for the acting unit.
- Door/chest key and `pick` behavior are requirement/action data over the same registry.

Door HP values from handbook are developer preset data:
| Type | HP |
|---|---|
| Wooden Door | 25 |
| Reinforced Wooden Door | 40 |
| Iron Door | 50 |
| Reinforced Iron Door | 65 |
| Portcullis | 80 |
| Castle Door | 100 |

---

## Fog of War

Status: **Planned** (Phase 2)
Last verified: 2026-06-13

Not in MVP. Architecture placeholder:

- Fog is encounter/scenario data on `MapData`/campaign content, not a global terrain-grid
  property.
- Each unit has an LoS stat or stat-registry equivalent used by the visibility rule.
- A `FogOfWarManager` node tracks currently visible/discovered tiles for the relevant
  viewer.
- Hidden enemies are presentation/AI-acquisition concerns; AI-cheats vs symmetric fog is
  a CampaignRules/profile choice.
- Torch/brazier vision bonuses are authored item/object/effect data, with built-in
  presets for common radius values.

Store fog state as a `Dictionary` of tile → visibility status on `GameState`.

---

## Objective Showcase Maps 002–005

Status: **Implemented**
Last verified: 2026-07-13

Four selector-visible maps exercise the implemented `ObjectiveCondition` system through
authored content. `test_game_map_scene.gd` boots every map with its expected roster and
enemy count; `test_turn_manager.gd` covers the corresponding resolution semantics.

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
- **Authored defeat standard.** Every Phase 3 objective map declares at least
  one authored defeat condition appropriate to that map, such as `turn_limit`
  or `protect`. Rout is added explicitly only where a full wipe should itself
  eliminate the group.

These are validation-map authoring constraints, not engine limits. The target objective
registry supports multi-condition victory/defeat sets and author-defined compositions as
soon as the required predicates/actions exist.

---

## Adding a New Map (Checklist)

The operational checklist lives in `AGENT/Docs/guides/map_authoring_guide.md`. The
current runtime supports data-driven string-grid maps; `tilemap_scene_path` remains
reserved and editor-painted scenes are not instanced.
