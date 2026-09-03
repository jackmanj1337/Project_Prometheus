---
Role: dated
Type: plan
Status: Planned - next-session implementation handoff
Last verified: 2026-07-16
---

# `B4-ENCOUNTER-MODEL` Slice 2 Handoff - 2026-07-16

## Goal-ready objective

Use the following objective for the next implementation goal:

> Complete `B4-ENCOUNTER-MODEL` Slice 2 by splitting monolithic `MapData` into
> reusable `BattleMapDef` terrain/layout data and `BattleEncounterDef` fight-payload
> data, wiring campaign `encounter_id -> battle_map_id` resolution through the
> catalogue and launch path, migrating shipped battle content, and preserving every
> shipped map/campaign launch through an explicit legacy `map_id`/`MapData` adapter;
> prove split-load, validation, spawn, objective, reward, suspend/retry, and legacy
> behavioral equivalence headlessly, then update the owning GDD/control-plane status
> to the exact implemented subset without starting generated skirmishes or Slice 3+.

## Why this can run without an owner walkthrough

- `[CNC-1..10]` and `[PUG-3..8]` are resolved. The decisions relevant to this slice
  are `[CNC-2]`, `[CNC-4]`, `[CNC-6]`, `[CNC-7]`, and `[PUG-6]`.
- `B1-CST`, the only hard gate for Slice 2, is Implemented.
- Slice 1's path-or-in-memory `UnitData` spawn seam is Implemented and covered by
  `test_spawn_seam.gd`.
- The work is data architecture, migration, compatibility, and headless evidence.
  It does not require visual tuning or reinterpret the outstanding Windows builds.

If implementation reveals a choice not settled by the sources below, stop at the
last green commit and record one compact decision packet. Do not silently invent new
content semantics.

## Resume point and preemption

- Work in `repo/Project_Prometheus_prep_save` on
  `agent/codex/2026-07-15/prep-save-followup`, or branch from its clean committed head.
- Preserve unrelated scorer/planning changes already in the worktree; isolate this
  track before committing.
- At session start and before each logical commit, check whether either outstanding
  Windows playtest return has arrived. Returned evidence preempts this work at the
  current green commit.
- Do not rebuild, replace, rename, or reinterpret either protected playtest artifact.

## Read first

1. [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md),
   `B4-ENCOUNTER-MODEL` row.
2. [`skirmish_encounter_generation_implementation_plan_2026-07-04.md`](skirmish_encounter_generation_implementation_plan_2026-07-04.md),
   especially Decisions Not To Reopen, dependencies, Slice 1, and Slice 2.
3. [`campaign_node_composition_open_questions_2026-07-03.md`](../registers/campaign_node_composition_open_questions_2026-07-03.md),
   especially `[CNC-2]`, `[CNC-4]`, `[CNC-6]`, and `[CNC-7]`.
4. [`parametric_unit_generation_open_questions_2026-07-03.md`](../registers/parametric_unit_generation_open_questions_2026-07-03.md),
   especially `[PUG-3]` and `[PUG-6]`.
5. `GDD_01` data-resource contracts, `GDD_06` map/encounter ownership, `GDD_10`,
   and the Feature Index row that owns campaign/map data.

## Current-state anchors

Verified 2026-07-16:

- `scripts/resources/MapData.gd` still owns both halves:
  - map/layout: `id`, `display_name`, `tilemap_scene_path`, `grid`,
    `camera_start_tile`, `player_start_tiles`;
  - encounter payload: `enemy_placements`, factions/turn order/activation mode,
    victory/defeat conditions, and rewards.
- `scripts/core/GameMap.gd` loads one `MapData`, paints its grid, spawns both armies,
  starts TurnManager, and stores it on GameState.
- `scripts/autoloads/DataManager.gd` caches `map_registry.json`, validates registry
  entries as `MapData`, and cross-validates campaign `map_id` references.
- `scripts/resources/CampaignData.gd` parses every node with a required `map_id`.
- `scripts/autoloads/CampaignManager.gd` resolves `node.map_id` through DataManager and
  stages `map_data_path` through `GameState.configure_next_map`.
- `scripts/autoloads/GameState.gd` types live battle data as `MapData` and stages a
  `next_map_data_path`.
- Seven shipped `MapData` resources and `data/maps/map_registry.json` require either
  migration or explicit legacy coverage.
- `scripts/tests/test_spawn_seam.gd` proves the implemented Slice 1 seam.

Re-inventory these anchors at goal start. Current code is authoritative if line numbers
or names have moved.

## Decisions not to reopen

1. `BattleMapDef` and `BattleEncounterDef` are separate first-class resources.
2. A campaign battle node uses `encounter_id`; that encounter uses `battle_map_id`.
3. `node_id` remains the durable campaign/save identity.
4. Legacy `map_id` and monolithic `MapData` remain an explicit compatibility adapter,
   not an alternate new design.
5. The campaign loader owns composition/reference validation and fails loudly.
6. `enemy_start_tiles` belongs to `BattleMapDef` as reusable enemy spawn zones.
7. JSON remains the hand-repairable campaign source of truth.
8. Package edits are hard-incompatible before 1.0; do not build best-effort resync.
9. The Slice 1 spawn seam remains the only placement-to-`UnitData` resolver.
10. Slice 2 does not add generated forces, map pools, scaling, skirmish panels, or an
    editor generator.

## Exact Slice 2 data contract

### `BattleMapDef`

Own reusable battlefield layout:

- `id: String`
- `display_name: String`
- `tilemap_scene_path: String`
- `grid: Array[String]`
- `camera_start_tile: Vector2i`
- `player_start_tiles: Array[Vector2i]`
- `enemy_start_tiles: Array[Vector2i]`

Do not move objectives, factions, placements, rewards, or encounter rules here.

### `BattleEncounterDef`

Own the authored fight staged on a map:

- `id: String`
- `battle_map_id: String`
- `enemy_placements: Array[Dictionary]`
- `factions: Array[FactionData]`
- `turn_order: Array[String]`
- `activation_mode: String`
- `victory_conditions: Dictionary`
- `defeat_conditions: Dictionary`
- `reward_gold: int`
- `reward_items: Array[String]`

Deployment constraints already owned by `CampaignNode` stay there unless an existing
resolved contract explicitly requires an encounter-level field. Do not guess at the
old plan's provisional `deploy_slots?` marker.

### Runtime composition

Introduce one explicit resolved battle bundle/API used by `GameMap` and downstream
systems. It may be a small typed resource/value or two typed references, but it must:

- expose map/layout and encounter/payload without copying authoritative fields into a
  second mutable schema;
- let `GameMap`, TurnManager, GameState, retry, suspend, and UI read their owning half;
- identify whether resolution used split data or the legacy adapter;
- keep compatibility adaptation at the load boundary, not scattered across gameplay.

Prefer a single DataManager/CampaignManager resolution seam over `if legacy` branches
throughout `GameMap`.

## Compatibility contract

For every shipped map and campaign node, the legacy and split paths must agree on:

- painted grid, map dimensions, camera start, and player start tiles;
- spawned enemy source, tile, faction, AI-profile override, boss flag, and order;
- faction definitions, turn order, and activation mode;
- victory and defeat condition payloads;
- reward gold and item IDs;
- campaign node progression and launch roster policy;
- retry source and suspend/resume battle identity;
- deterministic iteration/tie order where authored arrays currently define order.

Do not claim compatibility from resource-load success alone. Compare normalized
semantic projections or execute both paths through the relevant runtime seams.

## Implementation sequence

### Commit 1 - Types, catalogue, and validation

1. Add `BattleMapDef.gd` and `BattleEncounterDef.gd` with tracked `.uid` sidecars.
2. Add resource manifests/catalogue loading for maps and encounters following existing
   package/registry conventions; do not use ad-hoc directory scans where manifests are
   required.
3. Add validation for IDs, duplicate IDs, resource types, map references, grid shape,
   start tiles, factions, activation mode, objectives, placements, and rewards by
   delegating/reusing existing validators where possible.
4. Cross-validate every `BattleEncounterDef.battle_map_id`.
5. Add focused malformed/missing/duplicate/cross-reference fixtures.

Green gate: new resources load and validate without changing any launch path.

### Commit 2 - Campaign schema and launch resolver

1. Add optional `CampaignNode.encounter_id` parsing and preserve legacy `map_id`.
2. Validate exactly the permitted reference shape for a battle node. During migration,
   do not require both; reject ambiguous/conflicting dual references unless the resolved
   register explicitly defines an equivalence-only transition case.
3. Add DataManager accessors that resolve encounter ID to encounter + battle map.
4. Update CampaignManager launch preparation to resolve `encounter_id` through the new
   catalogue while retaining its legacy `map_id -> MapData` adapter.
5. Stage a typed resolved battle source through GameState without adding a new durable
   save field. Preserve current campaign `node_id` save identity.

Green gate: campaign parser/resolver tests cover split, legacy, unknown, missing, and
ambiguous references; no shipped content is migrated yet.

### Commit 3 - Runtime composition

1. Update `GameMap` to consume the resolved battle source.
2. Read terrain/layout exclusively from the map half and encounter behavior exclusively
   from the encounter half.
3. Keep `_resolve_placement_unit_data` and enemy placement ordering unchanged.
4. Update TurnManager/GameState/UI consumers to receive the minimum correct view rather
   than retaining a false monolithic type.
5. Make retry and suspend resolve the same campaign-node/encounter/map identity without
   replaying committed state or changing snapshot bytes unnecessarily.
6. Keep direct developer/single-map launch working through the legacy adapter.

Green gate: focused runtime tests pass on both split and legacy sources.

### Commit 4 - Shipped-content migration

1. Create reusable map and encounter resources for the shipped content selected by the
   implementation plan.
2. Update `map_registry.json`, campaign JSON, and resource manifests together.
3. Preserve stable public IDs where possible. If a split introduces new IDs, document
   the mapping and keep legacy IDs resolving through the adapter.
4. Populate `enemy_start_tiles` from authored enemy placement zones only where the
   resolved contract supports it; do not make current fixed placements depend on those
   zones.
5. Run a mechanical semantic-equivalence test for every migrated resource pair.

Green gate: all shipped entries validate and both campaign and direct-map launches use
the intended route.

### Commit 5 - Documentation and status

1. Update GDD_01's data-resource/runtime ownership.
2. Update GDD_06's battle-map/encounter authoring contract and compatibility adapter.
3. Update GDD_10 and the Feature Index in the same behavior-changing delivery.
4. Update `B4-ENCOUNTER-MODEL` with exact evidence:
   - mark **Implemented** only if Slice 1 and all of Slice 2 are complete;
   - otherwise mark **Split** and name the exact remainder;
   - do not imply `B7-SKIRMISH` Slices 3-5 are implemented.
5. Refresh generated docs/resource manifests and add a session note/index row.

## Requirement/evidence matrix

| Requirement | Required evidence |
|---|---|
| Separate typed map and encounter resources | Resource scripts, manifests, type/load tests |
| Encounter resolves one valid battle map | Catalogue cross-reference tests, malformed fixture |
| Campaign supports `encounter_id` | Parser and CampaignManager launch tests |
| Legacy `map_id` remains functional | Explicit adapter test and direct-map launch regression |
| No ambiguous source selection | Missing/both/unknown reference rejection tests |
| Runtime reads fields from the correct owner | Focused GameMap/TurnManager integration fixture |
| Spawn behavior is unchanged | Existing `test_spawn_seam` plus split/legacy placement comparison |
| Terrain/camera/start behavior is unchanged | Normalized map projection and GameMap fixture |
| Factions/objectives/rewards are unchanged | Normalized encounter projection and resolution fixtures |
| Retry and suspend preserve battle identity | Retry + suspend/resume tests for split and legacy paths |
| All shipped content migrates or stays intentionally legacy | Registry-wide enumeration test with per-entry route assertion |
| Deterministic authored ordering remains stable | Byte/array-order comparison fixtures |
| Save schema does not grow accidentally | F1/snapshot coverage; no-new-field assertion or documented manifest update |
| Documentation status is honest | GDD_01/GDD_06/GDD_10/Feature Index/control-plane diff + `check_docs.py` |

## Tests to add or extend

Minimum focused coverage:

- `test_battle_encounter_def.gd`
  - valid split pair;
  - unknown/duplicate IDs;
  - invalid grid/start tile;
  - invalid activation/faction/objective/reward/placement references;
  - `enemy_start_tiles` load and validation.
- Campaign data/manager tests
  - split `encounter_id` node;
  - legacy `map_id` node;
  - missing/both/unknown references;
  - launch parameters and roster policy unchanged.
- GameMap scene tests
  - split map paints/spawns/starts correctly;
  - legacy adapter still does the same;
  - direct-map developer launch remains valid.
- Equivalence tests
  - normalized old `MapData` projection equals new map + encounter projection for every
    migrated shipped map;
  - placements preserve authored order and exact overrides.
- Save/retry tests
  - split battle retry;
  - split suspend/resume;
  - legacy equivalents remain green;
  - no extra phase-start effects or rerolls.

Keep `test_spawn_seam.gd` green; extend it only if the split changes its input boundary.

## Full verification

Run, in repository-standard order:

1. New focused resource/catalogue tests.
2. CampaignData, CampaignManager/campaign flow, DataManager, GameMap scene, spawn seam,
   TurnManager, GameState, snapshot, suspend, and retry suites.
3. RNG/determinism guard.
4. Resource/scene integrity and generated-manifest checks.
5. `python3 AGENT/Docs/check_docs.py`.
6. Full headless suite.
7. `git diff --check` scoped first, then whole tree while distinguishing unrelated
   pre-existing changes.

Record suite/assertion counts and any unrelated known warning separately. A green narrow
fixture is not enough to claim all shipped maps are preserved.

## Non-goals

- No `ForceSpec`, generated roster, level/count scaling, or generator work.
- No `force_spec` or `map_pool` encounter mode.
- No skirmish PHB panel, arena, editor generate-and-bake, or campaign builder.
- No overworld, random encounter table, reinforcement redesign, or map-object work.
- No new visual design, release build, upload, merge, or playtest replacement.
- No best-effort package/save resynchronization.
- No removal of `MapData` until all intentional legacy consumers and direct-launch paths
  have an explicit replacement and migration evidence.

## Stop conditions

Stop and report rather than guessing if:

- a returned Windows playtest package arrives;
- a save needs a new durable field not covered by F1;
- a campaign node must legally carry both `map_id` and `encounter_id` but the resolved
  register does not define precedence/equivalence;
- runtime composition would require duplicating mutable map/encounter state;
- a migrated map cannot prove semantic equivalence;
- an existing public ID must be broken rather than adapted;
- Slice 2 unexpectedly requires `ForceSpec`, PHB, generator, or difficulty work.

## Completion audit

Before marking the goal complete, enumerate every requirement/evidence row above and
cite current-state proof. Confirm all shipped resources are accounted for, not merely
the proving-grounds campaign. Confirm direct map launch, campaign launch, retry, and
suspend on both split and legacy routes. The objective is incomplete if the types exist
but gameplay still depends on duplicated monolithic fields, if migrated content lacks
equivalence evidence, or if the track is marked more complete than the behavior proves.
