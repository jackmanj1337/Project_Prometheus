---
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-04
---

# Skirmish, Encounter Model & Unit Generation Implementation Plan

**Started:** 2026-07-04.

**Track IDs:** `B4-ENCOUNTER-MODEL` (the data-model split + spawn seam) and `B7-SKIRMISH`
(the generation surface: `ForceSpec`, scaling, the skirmish panel, editor bake).

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 4 + Band 7 rows. Drafted from the RESOLVED registers
[`campaign_node_composition_open_questions_2026-07-03.md`](../registers/campaign_node_composition_open_questions_2026-07-03.md)
(`[CNC-4]` the map/encounter split) and
[`parametric_unit_generation_open_questions_2026-07-03.md`](../registers/parametric_unit_generation_open_questions_2026-07-03.md)
(`[PUG-3..8]`). The generator **core** (`generate_unit(spec, seed)` / `UnitSpec`) is NOT
re-planned here — it is Slice 2 of
[`band7_arena_implementation_plan_2026-07-03.md`](band7_arena_implementation_plan_2026-07-03.md)
(`B7-ARENA`); this plan **reuses** that one generator (one generator, many consumers,
`[PUG-10]`).

## Purpose

Turn the resolved encounter/generation design into a build track. Two coupled outcomes:

1. **The encounter data model (`B4-ENCOUNTER-MODEL`).** Split the monolithic `MapData`
   into a reusable **`BattleMapDef`** (terrain) and a **`BattleEncounterDef`** (the fight
   payload staged on it), per `[CNC-4]`. Generalize the spawn seam so a placement can be an
   in-memory `UnitData`, not only a resource path (`[PUG-3]`). Add **`enemy_start_tiles`**
   spawn zones to `BattleMapDef` (`[PUG-6]`) so a generated force can be placed on any map.

2. **The skirmish generation surface (`B7-SKIRMISH`).** A first-class **`ForceSpec`**
   (`[PUG-4]`) that rolls a roster through the shared `generate_unit`, an **open registry of
   scaling terms** over `[DIF]`/`[TCV]` (`[PUG-7]`), a `BattleEncounterDef` with
   authored-OR-generated **force** and **map** modes (`[PUG-5]`), a skirmish `[PHB]` prep
   panel firing an encounter via the shared launch primitive (`[PUG-6]`, `[CNC-8]`/`[CNC-9]`),
   and the editor **generate-and-bake** flow that freezes a rolled unit to a pack `UnitData`
   (`[PUG-8]`).

The keystone reconciliation the registers settled: there is **one** encounter concept.
A skirmish is a `BattleEncounterDef` whose force and map happen to be generated/pooled
rather than authored. A later overworld is an additive trigger surface over the same
encounter — not a rewrite.

This is a build plan only. It does not authorize starting before the gates land.

## Scope

1. **Spawn seam generalization (`[PUG-3]`).** `_spawn_units` accepts a placement that is
   either a `unit_data_path` (today) **or** an already-built in-memory `UnitData`. One seam
   serves skirmish forces, editor-baked units, and mid-map reinforcements (`[DTR-5]`).
2. **`BattleMapDef` + `BattleEncounterDef` split (`[CNC-4]`).** Split `MapData` along the
   terrain/payload seam; add `enemy_start_tiles` to `BattleMapDef`; the campaign node's
   `encounter_id` points at a `BattleEncounterDef` which points at a `battle_map_id`. The
   legacy `map_id` adapter (`[CNC-2]`) keeps un-split authored maps loading.
3. **`ForceSpec` + scaling (`[PUG-4]`/`[PUG-7]`).** A resource
   `{entries: [{UnitSpec, count}], level_scaling, count_scaling}` that rolls each entry via
   the shared `generate_unit(spec, seed)` and places the result through the Slice 1 seam.
   Scaling is an author-selectable rule read from a registry of terms (player-avg,
   player-max, chapter index, fixed band, `[TCV]` var), default = player-average +
   difficulty offset.
4. **`BattleEncounterDef` generated modes + skirmish `[PHB]` panel (`[PUG-5]`/`[PUG-6]`).**
   Give `BattleEncounterDef` a `force_spec` mode (vs authored `enemy_placements`) and a
   `map_pool` mode (vs fixed `battle_map_id`); build a `skirmish` prep panel whose launch
   resolves a map from the pool, generates the force, spawns via the Slice 1 seam, runs the
   battle, and pays the reward — all through the shared `[CNC-8]`/`[CNC-9]` launch primitive.
5. **Editor generate-and-bake (`[PUG-8]`).** The campaign builder's unit editor calls the
   same `generate_unit`, shows an editable result, and on save **freezes** the roll to a
   concrete pack `UnitData`. One primitive, two persistence policies (runtime re-rolls /
   discards; editor freezes).

## Non-Goals

- **No second generator.** `generate_unit`/`UnitSpec` is the `B7-ARENA` Slice 2 primitive;
  this plan consumes it, it does not fork one (`[PUG-10]`).
- **No free-roam overworld.** A walkable world surface + encounter tables is a later
  additive trigger over the same `BattleEncounterDef` (§6 forward reservation of `[PUG]`).
- **No bespoke skirmish combat / no new economy.** The battle reuses the campaign-loop map
  launch and combat; rewards ride the existing gold/EXP paths.
- **No AI-driven generation/recruitment.** The AI buying/producing generated units is the
  `B7-AI-RECRUITMENT` track.
- **No best-effort save resync** when an author edits an encounter after a save exists —
  `[CNC-7]` fixed pre-1.0 hard incompatibility; migration hooks are a Band 8 content-resync
  concern.

## Source Docs

- [`campaign_node_composition_open_questions_2026-07-03.md`](../registers/campaign_node_composition_open_questions_2026-07-03.md)
  — `[CNC-4]` (the split; `BattleMapDef`/`BattleEncounterDef` field lists incl.
  `enemy_start_tiles`), `[CNC-8]`/`[CNC-9]` (the shared launch primitive), `[CNC-2]` (the
  legacy `map_id` adapter), `[CNC-7]` (save incompatibility).
- [`parametric_unit_generation_open_questions_2026-07-03.md`](../registers/parametric_unit_generation_open_questions_2026-07-03.md)
  — `[PUG-3]` (spawn seam), `[PUG-4]` (`ForceSpec`), `[PUG-5]` (unify into
  `BattleEncounterDef`), `[PUG-6]` (skirmish panel + `enemy_start_tiles`), `[PUG-7]`
  (scaling registry), `[PUG-8]` (editor bake); §4 slice sketch.
- [`band7_arena_implementation_plan_2026-07-03.md`](band7_arena_implementation_plan_2026-07-03.md)
  — Slice 2 owns the shared `generate_unit`/`UnitSpec` this plan reuses.
- `[PHB]` container register · `[DIF]`/`[TCV]` (scaling inputs) · `[SAC]` on-map
  dual-surface · `[DTR-5]` reinforcement `spawn` (a downstream reuser of the Slice 1 seam).

## Decisions Not To Reopen

- `[CNC-4]`: `MapData` splits into `BattleMapDef` + `BattleEncounterDef`; node references
  `encounter_id -> battle_map_id`; legacy `map_id` is the migration adapter.
- `[PUG-3]`: one spawn seam accepts path OR in-memory `UnitData` (not a parallel path).
- `[PUG-4]`: `ForceSpec` is a first-class resource; the arena ladder is a degenerate case.
- `[PUG-5]`: no separate `EncounterDef` wrapper — the generated encounter IS a
  `BattleEncounterDef` with `force_spec`/`map_pool` modes.
- `[PUG-6]`: skirmish is a `[PHB]` panel; `enemy_start_tiles` on `BattleMapDef` place a
  generated force on any pooled map.
- `[PUG-7]`: scaling is an open registry of terms read as data, not a hardcoded match.
- `[PUG-8]`: the editor freezes the same `generate_unit` roll; no editor-only generator.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates:

- **`B1-PKGA`** (`RngService`) — every generated roll needs a seeded, reproducible RNG.
  Hard gate for Slices 3-5.
- **`B1-CST`** — the campaign spine owns the node model and the `encounter_id` slot that
  `BattleEncounterDef` plugs into. Hard gate for Slice 2's node wiring.
- **`B7-ARENA` Slice 2** — the shared `generate_unit`/`UnitSpec`. Whichever of arena /
  skirmish / recruit-purchase lands first builds it; the others reuse it. Hard gate for
  Slices 3-5.
- **`B3-PHB`** — the prep-panel container the skirmish panel plugs into. Hard gate for
  Slice 4.
- **`B3-TCV`** / **`B4-DIFFICULTY-DEATHMODE`** — the `[TCV]`/`[DIF]` variables scaling
  reads. Soft gate: scaling defaults to player-average until they exist.
- **Live today:** `GameMap._spawn_units` (`scripts/core/GameMap.gd:168`) and
  `MapData` (`scripts/resources/MapData.gd`) exist — Slice 1 (spawn seam) is buildable
  against the live tree now; Slice 2 (the split) is a refactor of live resources.

## Existing Code Touchpoints

Verified 2026-07-04 against the live tree:

- **`scripts/resources/MapData.gd`** — the monolithic resource Slice 2 splits. Terrain
  fields (`tilemap_scene_path`, `grid`, `camera_start_tile`, `player_start_tiles`) →
  `BattleMapDef`; payload fields (`enemy_placements`, `factions`, `turn_order`,
  `activation_mode`, `victory_conditions`, `defeat_conditions`, `reward_gold`,
  `reward_items`) → `BattleEncounterDef`.
- **`scripts/core/GameMap.gd:168` `_spawn_units()`** — reads `map_data.enemy_placements`,
  `load()`s each `unit_data_path`, and calls `_spawn_unit(u_data, tile, faction)`.
  `_spawn_unit` already takes a `UnitData`, so only the placement-resolution loop
  (l.197-203) needs the path-vs-instance branch (`[PUG-3]`). After Slice 2 it reads the
  encounter's force (authored placements or a `force_spec`) and the map's
  `enemy_start_tiles`.
- **`GameState` roster/launch prep** (`is_roster_ready_for_launch`, `player_roster`) — the
  player-spawn side is unchanged; skirmish reuses the same launch-roster path.
- **No `BattleMapDef` / `BattleEncounterDef` / `ForceSpec` / `UnitGenerator` / `prep_panels`
  in code yet** (grep clean) — drafted against the planned `B7-ARENA` generator and `[PHB]`
  APIs, same caveat as the Band 5/6/7 plans.
- Tests to create: `test_spawn_seam.gd` (path vs in-memory placement), `test_battle_encounter_def.gd`
  (split load + legacy adapter + `enemy_start_tiles`), `test_force_spec.gd` (roster/counts/
  scaling), `test_skirmish_panel.gd` (launch → generate → spawn → reward → determinism),
  `test_editor_bake.gd` (freeze roll to a pack `UnitData`).

## Slice 1 - Spawn Seam Generalization  (`B4-ENCOUNTER-MODEL`)

**Goal:** `_spawn_units` places an in-memory `UnitData`, not only a resource path.
Buildable against the live tree now.

Files to touch:

- `scripts/core/GameMap.gd` (the enemy-placement resolution loop)
- `scripts/resources/MapData.gd` (allow a placement entry to carry a `unit_data` instance)
- `scripts/tests/test_spawn_seam.gd` (new)

Implementation steps:

1. Extend a placement entry to carry EITHER `unit_data_path: String` OR an already-built
   `unit_data: UnitData`. In `_spawn_units`, branch: if an instance is present, use it
   (`.duplicate(true)`); else `load()` the path as today.
2. Keep `_spawn_unit(u_data, tile, team)` unchanged — it already takes a `UnitData`.

Tests:

- An authored path placement and an in-memory `UnitData` placement both spawn through the
  same `_spawn_units`, producing equivalent registered units.

F1 obligations: none — placements are authoring/runtime data; generated units persist
through the normal roster/`UnitData` save only when recruited/captured.

DoD#1 obligations: none until a consumer ships (the seam is invisible alone).

## Slice 2 - BattleMapDef + BattleEncounterDef Split  (`B4-ENCOUNTER-MODEL`)

**Goal:** the two-resource encounter model. **Gated on `B1-CST`** for the node wiring.

Files to touch:

- `scripts/resources/BattleMapDef.gd` (new), `scripts/resources/BattleEncounterDef.gd` (new)
- the map-load path (`GameMap` / `DataManager`) to resolve `encounter_id -> battle_map_id`
- `scripts/tests/test_battle_encounter_def.gd` (new)

Implementation steps:

1. `BattleMapDef` = `{id, display_name, tilemap_scene_path, grid, camera_start_tile,
   player_start_tiles, enemy_start_tiles}`. `enemy_start_tiles` is the enemy spawn-zone
   list symmetric with `player_start_tiles` (`[PUG-6]`).
2. `BattleEncounterDef` = `{id, battle_map_id, enemy_placements, factions, turn_order,
   activation_mode, victory_conditions, defeat_conditions, reward_gold, reward_items,
   deploy_slots?}`. (The `force_spec`/`map_pool` generated modes are added in Slice 4.)
3. The campaign node's `encounter_id` resolves to a `BattleEncounterDef`; the runtime
   composes the two defs into the bundle `GameMap` consumes (or `GameMap` reads both). The
   legacy `map_id` slot still resolves a monolithic `MapData` for un-split authored maps.

Tests:

- An encounter + map pair loads and runs equivalently to today's monolithic `MapData`.
- A legacy `map_id` node still loads (adapter path).
- `enemy_start_tiles` are read as the enemy spawn zones.

F1 obligations: encounter/map ids are authoring data; a save binds to the node's
`encounter_id` (`[CNC-1]`). No new runtime save field.

DoD#1 obligations: update `GDD_06` (map/encounter model) + `GDD_01` (data resources);
flip `GDD_10` when the split lands.

## Slice 3 - ForceSpec + Scaling  (`B7-SKIRMISH`)

**Goal:** a rolled roster with author-selectable scaling. **Gated on `B1-PKGA` +
`B7-ARENA` Slice 2.**

Files to touch:

- `scripts/resources/ForceSpec.gd` (new)
- a scaling-term registry (data-driven, `[EXT]`-shaped)
- `scripts/tests/test_force_spec.gd` (new)

Implementation steps:

1. `ForceSpec = {entries: [{unit_spec: UnitSpec, count: int}], level_scaling, count_scaling}`.
   Roll each entry `count` times through the shared `generate_unit(spec, seed)`; return
   in-memory `UnitData`s placed via the Slice 1 seam.
2. `level_scaling`/`count_scaling` name a **registry term** resolved as data (player-avg,
   player-max, chapter/progress index, fixed band, `[TCV]` var). Default = player-average
   level + difficulty offset. No hardcoded `match` — a new base adds as a registry entry.

Tests:

- A `ForceSpec` produces the right roster and counts; a fixed seed reproduces it.
- A scaling term shifts levels with its `[DIF]`/`[TCV]` input; the fixed-band term is a
  constant; an unknown term fails validation (registry-closed at load, open to content).

F1 obligations: none — a `ForceSpec` is authoring data; rolled units are ephemeral until
recruited/captured.

DoD#1 obligations: note `ForceSpec` + scaling in `GDD_03` (unit sources) / `GDD_07`
(skirmish); flip `GDD_10`.

## Slice 4 - Generated Encounter Modes + Skirmish PHB Panel  (`B7-SKIRMISH`)

**Goal:** the skirmish panel fires a generated encounter. **Gated on `B3-PHB` +
Slices 2-3.**

Files to touch:

- `scripts/resources/BattleEncounterDef.gd` (add `force_spec`, `map_pool`)
- a `skirmish` PHB panel + its launch handler
- `scripts/tests/test_skirmish_panel.gd` (new)

Implementation steps:

1. Add the authored-OR-generated modes to `BattleEncounterDef`: force = authored
   `enemy_placements` XOR `force_spec: ForceSpec`; map = fixed `battle_map_id` XOR
   `map_pool: Array[String]` (`battle_map_id`s to pick/rotate).
2. Register a `skirmish` `[PHB]` prep panel (on-map placeable via `[SAC]`). Its launch runs
   the shared `[CNC-8]`/`[CNC-9]` primitive: resolve a map from `map_pool` (seeded pick) →
   generate the force from `force_spec` (Slice 3) → spawn onto `enemy_start_tiles` via the
   Slice 1 seam → run the battle → pay the reward.
3. A suspend mid-skirmish re-rolls identically on resume (the seed is stored, not the
   rolled units) — consistent with `[PUG-2]` seed reproducibility.

Tests:

- Selecting the panel launches a battle with the generated force on a pooled map.
- A fully-authored `BattleEncounterDef` (no `force_spec`/`map_pool`) still runs — the
  generated modes are additive, not required.
- Same seed → same map pick + same force (determinism through suspend/resume).

F1 obligations: the skirmish encounter seed rides the suspend save so a resumed skirmish
re-rolls identically (`[PUG-2]`); no rolled-unit snapshot is stored.

DoD#1 obligations: update `GDD_07` (skirmish panel) + `GDD_06` (encounter modes); flip
`GDD_10`.

## Slice 5 - Editor Generate-and-Bake  (`B7-SKIRMISH`)

**Goal:** the builder freezes a rolled unit into a pack `UnitData`.

Files to touch:

- the campaign builder unit-editor surface (calls `generate_unit`, shows an editable result)
- `scripts/tests/test_editor_bake.gd` (new)

Implementation steps:

1. The editor calls the same `generate_unit(spec, fresh_seed)`; the result is an editable
   `UnitData`. "Re-roll" requests a new seed and regenerates.
2. On save, **freeze** the current roll to a concrete pack `UnitData` that then loads like
   any authored unit. Distinguish in docs: **runtime-generated** (ephemeral, re-rolled) vs
   **authoring-generated** (frozen concrete resource).

Tests:

- Generate produces an editable unit; re-roll changes it; Save writes a concrete pack
  `UnitData` that loads and spawns like an authored one.

F1 obligations: none — a baked unit is a normal authored `UnitData` in the pack.

DoD#1 obligations: note generate-and-bake in `GDD_03` / the authoring docs; flip `GDD_10`.

## Implementation Commit Order

1. Slice 1 spawn seam (`B4-ENCOUNTER-MODEL`) — buildable now against the live tree.
2. Slice 2 `BattleMapDef`/`BattleEncounterDef` split (`B4-ENCOUNTER-MODEL`) — **trails
   `B1-CST`**.
3. Slice 3 `ForceSpec` + scaling (`B7-SKIRMISH`) — **trails `B1-PKGA` + `B7-ARENA` Slice 2**.
4. Slice 4 generated encounter modes + skirmish panel (`B7-SKIRMISH`) — **trails `B3-PHB`**.
5. Slice 5 editor generate-and-bake (`B7-SKIRMISH`).

## Verification Checklist

Same as the Band 2/3/4/5/7 plans. Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
```
