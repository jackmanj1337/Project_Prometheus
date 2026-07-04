---
Type: register
Status: OPEN
Last verified: 2026-07-03
Register: PUG-1..10
---

# Parametric Unit Generation — Shared Generator, Skirmish Encounters, Editor Bake — Draft Plan + Open Questions Register

**Started:** 2026-07-03 (session 2026-07-03f).
**Status:** OPEN — the shared generator core is partially resolved. `[PUG-1]`,
`[PUG-2]`, `[PUG-3]`, `[PUG-9]`, and `[PUG-10]` are settled by the owner
(2026-07-03g). `[PUG-4..7]` (skirmish/encounter formatting) are **now UNBLOCKED**: the
campaign-node composition pass they waited on resolved 2026-07-04 (`[CNC-1..10]` all
RESOLVED). The skirmish data shape locks against `BattleEncounterDef` (`[CNC-4]`) fired by
the shared launch primitive (`[CNC-8]/[CNC-9]`); these remain OPEN only pending their own
resolution walk, no longer gated by CNC.
Earlier scope decision still stands: skirmish = prep-panel now, built against an
overworld-ready shape so a later free-roam overworld is additive, not a rewrite
(2026-07-03f).
**Source:** owner ask 2026-07-03f — "how the random unit generator is placed into an
arena, used for random skirmish encounters (world map), and placed in the GUI editor to
generate base units an author can modify and place into maps."
**Ties to:** the **shared parametric unit generator** already planned as arena plan
Slice 2 (`[BEA-5]`) + `[THL-8]` `generated` recruits (the two existing consumers); the
node/`prep_panels` model + skirmish-as-prep-option (`player_facing_scope_map_2026-06-23.md`
§3a, "auto/random-leveled rosters … without an overworld"); `[DIF]`/`[TCV]` difficulty
variables (level/count scaling); `[RCR-3]` `recruit()` (bought/captured units);
`[DTR-5]` mid-map `spawn` + `B7-PROPERTY-RECRUITMENT` + `[PVP-3]` (further generator
consumers); the campaign builder / `[EXT]` author-extensibility model.
**Pattern:** mirrors the FOW/DTR/BEA registers. Legend: **[OPEN]** / **[ASKED]** /
**[RESOLVED]**.

---

## 1. State today (code-grounded)

- **No unit generation exists.** Enemies are fully authored: `MapData.enemy_placements`
  (`scripts/resources/MapData.gd:14`) is an `Array[Dictionary]` of `{unit_data_path,
  tile, faction, ai_profile}`; `GameMap._spawn_units()` (`scripts/core/GameMap.gd:168`)
  `load()`s each **resource path**, `.duplicate(true)`, sets `ai_profile`, and spawns.
  Deterministic; no randomness at spawn.
- **The spawn path is path-only.** `_spawn_units` accepts a `unit_data_path` string, not
  an in-memory `UnitData`. Any generated (in-memory) unit cannot be spawned through this
  seam today — this is the one load-bearing code change (see `[PUG-3]`).
- **The generator is planned, not built.** `generate_unit(spec)` is arena plan Slice 2
  (`band7_arena_implementation_plan_2026-07-03.md`); `[BEA-5]`/`[THL-8]` name it as one
  shared primitive with two consumers. No `UnitGenerator`/`UnitSpec` in code yet (grep
  clean).
- **Randomness substrate.** `RngService` is planned (`B1-PKGA`, the root gate); level-up
  growth rolls already use engine RNG (the `randi` determinism caveat, atlas Phase C).
- **Nodes carry `prep_panels`** (`node_type: battle|hub`, opt-in panel list); **skirmish
  is an IN-scope prep option** with "auto/random-leveled rosters," explicitly **without a
  free-roam overworld** (scope map §3a / feature #13).
- **No in-app editor exists.** The campaign builder is the v1 showpiece direction
  (self-contained per-campaign packs); authoring today is `.tres` resources referenced by
  `enemy_placements`.

## 2. Draft plan (the shared primitive + three surfaces)

**The atom:** `generate_unit(spec, seed) -> Unit`. A **`UnitSpec`** is authored data
(class · level/level-range · stat-generation mode · equipment), resolved
deterministically from an explicit `seed` (via `RngService` when randomness is used).
The stat-generation modes are explicit ranges, rolled growths, and fixed growths.

The three surfaces are the same primitive differing on two axes — **one unit vs a
force**, and **ephemeral (runtime) vs baked (authoring)**:

1. **Arena** — one `UnitSpec` (or a tiered ladder) → ephemeral 1v1 opponent. Already
   designed (arena plan Slice 2); the panel's opponent source is `authored table OR
   parametric spec`.
2. **Skirmish** — a **`ForceSpec`** (roster of `UnitSpec`s + counts + level/count
   scaling) → a generated enemy force launched on an authored map. Ephemeral unless a
   unit is captured/recruited.
3. **Editor** — one `UnitSpec` → `generate_unit` → a concrete `UnitData` the author
   **edits and saves** (frozen roll), then references in `enemy_placements`. The generator
   is a **design-time seed**, not a runtime event.

**Overworld-ready framing (owner 2026-07-03f):** the reusable atom is an **`EncounterDef`**
= `{ForceSpec, map source, reward}`. The *skirmish panel* is one trigger surface for it
now; a *future overworld tile/region* is another trigger surface for the **same**
`EncounterDef` — so the overworld is additive (a new trigger + an encounter table), not a
rewrite of skirmish.

## 3. Open questions register

### [PUG-1] `UnitSpec` model + stat-generation mode  **[RESOLVED]**
What does a spec contain, and how are stats rolled?
- **A — Explicit per-stat ranges** (`hp: 20-24`, …). Tight authorial control.
- **B — Class base + growths rolled to level** (reuse the level-up growth path up to the
  spec's level). Class-plausible, less authoring.
- **C — Fixed growths** (class base + deterministic expected growths to level; no
  per-level random growth rolls). Stable, class-plausible, and useful for fair/tuned
  generation.
- **Resolution (2026-07-03g): A + B + C.** `UnitSpec` supports all three modes through a
  stat-generation field: explicit stat ranges, class-growth rolled stats, and fixed
  growths. Keys off existing class/growth data where applicable.

### [PUG-2] Determinism & seed ownership  **[RESOLVED]**
- **A — `generate_unit` takes an explicit `seed`;** runtime consumers supply it from
  `RngService` (reproducible across a mid-encounter suspend/save), the editor supplies a
  fresh/random seed on demand.
- **B — Generator owns its own RNG** (harder to reproduce for save).
- **Resolution (2026-07-03g): A.** `generate_unit(spec, seed)` takes an explicit seed.
  Runtime consumers get that seed from `RngService`; editor/authoring surfaces can request
  a fresh seed for re-rolls. Depends on `RngService` (`B1-PKGA`).

### [PUG-3] The spawn seam — path vs in-memory `UnitData`  **[RESOLVED — load-bearing]**
`_spawn_units`/`enemy_placements` accept only a **resource path** today; a generated unit
is an in-memory `UnitData`.
- **A — Generalize a placement to accept EITHER a `unit_data_path` OR an already-built
  `UnitData` instance** (generated or otherwise). One seam unblocks skirmish,
  reinforcements (`[DTR-5]` `spawn`), and any generated-unit spawn.
- **B — A separate generated-unit spawn path** (parallel code).
- **Resolution (2026-07-03g): A.** The single generalization is the smallest change and serves every
  generated-unit consumer; `_spawn_unit(u_data, tile, team)` already takes a `UnitData`,
  so only the placement-resolution front of `_spawn_units` needs to branch path-vs-instance.

### [PUG-4] `ForceSpec` model  **[OPEN — deferred until campaign-map structure pass]**
- **A — A resource `{entries: [{UnitSpec, count}], level_scaling, count_scaling}`** — a
  roster of specs with per-entry counts + scaling rules. Arena's ladder is a degenerate
  `ForceSpec` (1 entry, tiered); skirmish is a full one.
- **B — An inline list on the panel** (no reusable resource).
- **Current lean:** A first-class `ForceSpec` resource is still the likely reusable shape,
  but do not lock the schema until the campaign-map/skirmish structure pass decides how
  generated forces attach to maps and progression nodes (`[CNC-2..9]`). Consumes
  `[DIF]`/`[TCV]` for scaling (`[PUG-7]`).

### [PUG-5] `EncounterDef` — the overworld-ready atom  **[SCOPE DECIDED → shape OPEN / DEFERRED]**
**Owner decision (2026-07-03f): build skirmish now against an overworld-ready shape.**
- The reusable atom = **`EncounterDef` `{ForceSpec, map_source, reward}`**; a **trigger
  surface** fires it. v1 trigger = the **skirmish prep panel**; a later trigger = an
  **overworld tile/region** consuming an encounter table of `EncounterDef`s. Both fire the
  **same** launch path (generate force → spawn via `[PUG-3]` → run battle → reward).
- **Open/deferred (2026-07-03g):** the exact `EncounterDef` schema and skirmish format
  wait on the campaign-node composition pass (`[CNC-1..10]`). Keep the author-facing
  extension point open-registry-shaped (`[EXT]`) so overworld/mission-board/random-event
  triggers can reuse it later without engine edits.

### [PUG-6] Skirmish container + map source  **[OPEN — deferred until campaign-map structure pass]**
- **A — Skirmish is a `[PHB]` prep panel** (like arena/training/recruit), on-map placeable
  via `[SAC]`; its `map_source` = an **authored map pool** (pick/rotate one). Reuses the
  campaign-loop map launch.
- **B — A bespoke skirmish flow** outside `[PHB]`.
- **Current lean:** skirmish remains a `[PHB]` prep option by ratified scope, but the
  concrete map-source format should wait until campaign-map structure is walked. Avoid
  hardcoding a skirmish-only format ahead of that pass.

### [PUG-7] Level/count scaling source (auto/random-leveled)  **[OPEN — deferred until campaign-map structure pass]**
The scope map calls for "auto/random-leveled rosters." Scale to what?
- **A — Player average/max level;** **B — chapter/progress index;** **C — a `[TCV]`
  variable / `[DIF]` multiplier;** **D — a fixed authored band.**
- **Current lean:** an author-selectable scaling rule referencing `[DIF]`/`[TCV]`
  variables, defaulting to player-average + difficulty offset. Keep this as an open
  registry of scaling terms, not a hardcoded `match`. Final defaults wait on the
  campaign-map/skirmish structure pass.

### [PUG-8] Editor generate-and-bake — runtime vs authoring generation  **[OPEN]**
- **A — The editor calls the SAME `generate_unit` primitive, then PERSISTS the result**
  as a concrete `UnitData` in the campaign pack; the roll is **frozen** on save. A
  "re-roll" re-rolls before save; after save it is a normal authored unit.
- **B — A separate editor-only generator.**
- **Rec: A.** One primitive, two persistence policies (runtime discards / re-rolls; editor
  freezes). This also gives authors a fast baseline for the `.tres` files
  `enemy_placements` needs — generate a plausible unit, tweak, place. Distinguish clearly
  in docs: **runtime-generated** (ephemeral, re-rolled) vs **authoring-generated** (frozen,
  editable).

### [PUG-9] Equipment / inventory generation  **[RESOLVED]**
- **A — Fixed loadout on the spec;** **B — a weighted equipment table** (by class/tier);
  **C — both.**
- **Resolution (2026-07-03g): C.** `UnitSpec` supports fixed equipment and weighted
  equipment tables. Fixed lists cover tuned encounters; weighted tables cover variety.
  Tables key off existing weapon/item data + class proficiency. A one-entry table
  degenerates to a fixed loadout.

### [PUG-10] Consumer map / reuse  **[RESOLVED — cross-ref]**
Confirm the one generator + `ForceSpec` serve every generated-unit consumer (not parallel
systems):
- **Arena opponents** (`[BEA-5]`, arena plan Slice 2) · **generated recruits** (`[THL-8]`,
  prep-progression Slice 5) · **skirmish forces** (this register) · **editor base units**
  (`[PUG-8]`) · **mid-map reinforcements** (`[DTR-5]` `spawn`, still `enemy_placements`-only
  today) · **property-recruitment produced units** (`B7-PROPERTY-RECRUITMENT`) · **PvP
  buy-phase** (`[PVP-3]`).
- **Resolution (2026-07-03g):** one `generate_unit(spec, seed)` service backs any system
  that needs a fresh unit. Consumers differ only in trigger, source spec, and persistence
  policy; they do not get parallel generators. `ForceSpec` remains the likely multi-unit
  wrapper, but its exact schema stays open with `[PUG-4]`.

## 4. Slice sketch (draft — not yet a build track; register OPEN)

1. **`UnitSpec` + `generate_unit(spec, seed)`** (`[PUG-1]`/`[PUG-2]`/`[PUG-9]`) — the atom.
   Buildable against live `UnitData`/`Unit` once `RngService` (`B1-PKGA`) lands. (This is
   arena plan Slice 2; this register generalizes its spec model.)
2. **The spawn seam** (`[PUG-3]`) — `_spawn_units`/`enemy_placements` accept an in-memory
   `UnitData`. Small, load-bearing, unblocks every generated-unit consumer.
3. **Campaign-map/skirmish structure pass** — decide how generated forces attach to
   campaign maps/progression nodes before locking skirmish format.
4. **`ForceSpec` + scaling** (`[PUG-4]`/`[PUG-7]`) — the roster/count/level-scaling
   resource consuming `[DIF]`/`[TCV]`; schema follows the campaign-map structure pass.
5. **`EncounterDef` + the skirmish `[PHB]` panel** (`[PUG-5]`/`[PUG-6]`) — the panel
   trigger fires an encounter payload (generate force → spawn → battle → reward) on the
   chosen map source. Built overworld-ready (trigger surface is a registry), but exact
   schema is deferred.
6. **Editor generate-and-bake** (`[PUG-8]`) — the campaign builder's unit editor calls
   `generate_unit`, shows an editable result, freezes it to a pack `UnitData` on save.
7. **(Later, additive) Overworld** — a free-roam surface whose tiles/regions carry
   encounter tables of `EncounterDef`s, reusing slices 1-4 with a new trigger surface only.

## 5. Test notes
- `generate_unit(spec, seed)` is deterministic: same spec + seed → identical unit; ranges
  honored; output is a normal `Unit` usable by `CombatResolver`/`recruit()` (`[PUG-1/2]`).
- The spawn seam spawns an in-memory generated `UnitData` (no resource path) and an
  authored-path unit through the same `_spawn_units` (`[PUG-3]`).
- A `ForceSpec` generates the right roster/counts; scaling shifts levels with the
  `[DIF]`/`[TCV]` input (`[PUG-4/7]`).
- Skirmish: selecting the panel launches a battle with the generated force on a pooled map;
  a suspend mid-skirmish re-rolls identically on resume (seed reproducibility) (`[PUG-5/6]`).
- Editor: Generate produces an editable unit; re-roll changes it; Save freezes a concrete
  pack `UnitData` that then loads like any authored unit (`[PUG-8]`).

## 6. Forward reservations (not built now)
- **Free-roam overworld** (`[PUG-5]`) — a walkable world surface + encounter tables; a new
  trigger surface over the same `EncounterDef`. Owner: additive later.
- **Reinforcement `spawn`** (`[DTR-5]`) — mid-map generated spawns via the same seam.
- **AI-driven generation/recruitment** (`B7-AI-RECRUITMENT`) — the AI buying/producing
  generated units.
- **Named-character freeze provenance** — whether an editor-baked unit remembers it was
  generated (for re-roll) or is opaque authored data after save (`[PUG-8]` sub-detail).
