---
Role: dated
Type: register
Status: RESOLVED
Last verified: 2026-07-04
Register: CNC-1..10
---

# Campaign Node Composition - Maps, Encounters, Chapters, and Hub Panels - Open Questions

**Started:** 2026-07-03. **Resolved:** 2026-07-04.
**Status:** RESOLVED - all of `[CNC-1..10]` are settled. `[CNC-1]` stable node identity /
mutable contents; `[CNC-2]` explicit reference slots + panel-instance refs; `[CNC-3]`
node-type vocabulary = `battle|hub` for v1, `node_type` read as data not a closed enum;
`[CNC-4]` **canonical split** into `BattleMapDef` + `BattleEncounterDef` (option A);
`[CNC-5]` chapter = story-facing metadata over one-or-more nodes; `[CNC-6]` composition
validation matrix owned by the campaign loader; `[CNC-7]` pre-1.0 hard save incompatibility
on package edit; `[CNC-8]` node completion as an action/effect primitive dispatched on
`node_type` as data; `[CNC-9]` skirmish = shared launch primitive, different trigger
surfaces; `[CNC-10]` JSON is the hand-repairable source of truth, GUI builder writes it.
`[PUG-4..7]` is now unblocked.
**Source:** owner follow-up after `[PUG]` partial resolution: the campaign plan must let
the same campaign node change type and change the collection of hub panels, chapter
metadata, or encounter layer it points to.
**Ties to:** `CampaignData` graph (`[CST-3/5/6]`), `[PHB-1..7]` node types and
`prep_panels`, `[MET]` map events, `[PUG-4..7]` skirmish/encounter formatting, the
campaign package JSON format, and the future campaign builder.
**Pattern:** mirrors the PHB/PUG registers. Legend: **[OPEN]** / **[ASKED]** /
**[RESOLVED]**.

---

## 1. Vocabulary contract

- **Campaign Package** - the full self-contained author bundle.
- **Campaign Graph** - the progression structure inside a package.
- **Campaign Node** - one graph stop with stable `node_id`; this is the save/progression
  identity.
- **Node Type** - the node's launch behavior. Firmed today as `battle|hub` by `[PHB-4]`;
  possible future story/activity types are open.
- **Chapter** - story-facing grouping/label metadata, not the engine progression
  primitive.
- **Hub Panel Type** - a `[PHB]` option-panel type, such as `shop`, `arena`, `convoy`,
  or `skirmish`.
- **Hub Panel Instance** - a specific configured instance of a hub panel type, such as
  a shop with a particular stock list or an arena with a particular opponent roster.
- **Battle Map** - reusable tactical terrain/layout.
- **Battle Encounter** - the specific fight payload staged on a battle map: force,
  placements, objectives, rewards, events, visibility, and encounter rules.
- **Encounter Layer** - the data overlay that turns a battle map into a battle
  encounter. Today this is folded into `MapData`; the split is a target shape.

## 2. Grounding

- Code today has `MapData` as a single tactical battle resource: grid, starts,
  `enemy_placements`, factions, objectives, and rewards.
- `map_registry.json` is a flat launcher registry, not a campaign graph.
- Campaign/save design already says `CampaignData` JSON owns graph nodes with `node_id`,
  `map_id`, `next`, deployment constraints, and campaign rules.
- `[PHB-4]` already resolved that `node_type` exists and is author-switchable:
  `battle` nodes launch a map; `hub` nodes expose prep/panels and advance by Continue.
- `[PUG-4..7]` is waiting on this pass before locking skirmish/encounter format.

## 3. Open questions register

### [CNC-1] Stable node identity vs mutable node contents  **[RESOLVED]**
Can the same campaign node change type and references, or does changing type create a new
node?
- **Resolution (2026-07-03): stable identity, mutable contents.** `node_id` is the durable
  save/progression identity. Authors may change `node_type` and the node's reference set
  (`prep_panels`, chapter/story metadata, encounter pointer, map pointer) without changing
  `node_id`.
- **Implication:** saves bind to `node_id`; content-pack resync/migration must decide what
  happens if the node's type or refs changed after a save was created.

### [CNC-2] Node reference slots  **[RESOLVED]**
What fields can a node point to?
- **A - Single overloaded `map_id` plus optional `prep_panels`.** Simple but keeps
  overloading "map" to mean terrain, encounter, and chapter.
- **B - Explicit slots:** `chapter_id`, `prep_panels`, `encounter_id`, optional
  `battle_map_id` override.
- **C - Generic `payload_refs` dictionary keyed by registry ids.** Most extensible; harder
  to validate and explain.
- **Resolution (2026-07-03): B, with panel instance refs.** Use explicit slots:
  `chapter_id`, `prep_panels`, `encounter_id`, and a temporary legacy `map_id` adapter
  while `MapData` is still monolithic. `prep_panels` is not a plain list of panel-type
  strings; each entry is a **panel reference** that can identify a specific configured
  panel instance.

Example:

```json
{
  "node_id": "ch01_market",
  "node_type": "hub",
  "chapter_id": "ch01",
  "prep_panels": [
    {"panel_type": "convoy"},
    {"panel_type": "shop", "panel_instance_id": "ch01_armory"},
    {"panel_type": "arena", "panel_instance_id": "rookie_ladder"}
  ],
  "next": ["ch01_battle"]
}
```

- **Implication:** panel types are registered once, while panel instances carry per-use
  config owned by that panel's data model: shop stock/prices, arena roster/risks,
  training-hall benefits, skirmish encounter table, and so on.
- **Validation rule:** if a panel type requires an instance, `panel_instance_id` must
  resolve to a config of that type. Types with no per-instance config, such as a generic
  convoy panel, may omit it.

### [CNC-3] Node type vocabulary  **[RESOLVED]**
Do we keep `node_type` to `battle|hub`, or add `story` / `activity` node types now?
- **A - Keep `battle|hub` for v1.** Story-only beats are hub nodes with no deploy and an
  opening dialogue/event payload.
- **B - Add `story` now.** Cleaner author intent, but another node flow.
- **C - Add open-registry node types.** Future-proof, but too much before the first loop.
- **Resolution (2026-07-04): A, but `node_type` is read as DATA, not a closed enum.** Ship
  only the two ratified types (`battle|hub`) for the first loop — a story-only beat is a
  `hub` node with no deploy and an opening dialogue/event payload. Crucially, the engine
  must **not** hardcode a `match node_type` two-way switch: node launch and completion
  dispatch on `node_type` as a data key (aligns with the AGENTS.md open-registry principle
  and `[CNC-8]`), so adding a third type later (`story`, `activity`, …) is additive
  content, not an engine edit. C (the full authored node-type registry) is deferred until
  after the first loop proves the base `battle`/`hub` flows.
- **Implication:** the campaign loader/dispatch keeps a small internal registry seeded with
  `battle` and `hub`; `[CNC-8]` (launch/completion as an action/effect primitive output)
  is the mechanism that keeps this open rather than a per-type `match`.

### [CNC-4] Battle map vs encounter layer split  **[RESOLVED]**
When should `MapData` split into reusable terrain and encounter payload?
- **A - Split now:** `BattleMapDef` plus `BattleEncounterDef`.
- **B - Keep `MapData` monolithic for first loop, but design schema as adapter-friendly.**
- **C - Never split.**
- **Resolution (2026-07-04): A - the canonical campaign data model is two resources.** The
  monolithic `MapData` is split along the terrain/payload seam. A campaign node references an
  `encounter_id`; the encounter references a `battle_map_id`.
  - **`BattleMapDef`** (reusable terrain): `id`, `display_name`, `tilemap_scene_path`,
    `grid`, `camera_start_tile`, `player_start_tiles` (deployment slots are terrain-fixed),
    and **`enemy_start_tiles`** (enemy spawn zones symmetric with `player_start_tiles`,
    added by `[PUG-6]` so a generated force can be placed on any map in a pool).
  - **`BattleEncounterDef`** (fight payload staged on a map): `id`, `battle_map_id`,
    `enemy_placements`, `factions`, `turn_order`, `activation_mode`, `victory_conditions`,
    `defeat_conditions`, `reward_gold`, `reward_items`, optional `deploy_slots` override
    (a subset of the map's `player_start_tiles`). **Authored-OR-generated modes (added by
    `[PUG-5]`):** the force is authored `enemy_placements` XOR a generated `force_spec`
    (a `ForceSpec`); the map is a fixed `battle_map_id` XOR a `map_pool` (pick/rotate). A
    skirmish encounter is the fully-generated case.
- **Implication:** the tactical runtime (`GameMap._spawn_units`, `TurnManager`) consumes a
  monolithic `MapData` today, so the campaign band must either compose the two defs into a
  runtime bundle at load or refactor the runtime to read both. Sequencing lands in the
  campaign band; the register locks the split as the target shape now (not deferred). The
  legacy `map_id` slot from `[CNC-2]` is the migration bridge for un-split authored maps.
  Skirmish/generation (`[PUG]`) targets the `BattleEncounterDef` shape directly.
- **Build plan (2026-07-04):** the split is control-plane row `B4-ENCOUNTER-MODEL`, planned
  in
  [`skirmish_encounter_generation_implementation_plan_2026-07-04.md`](../plans/skirmish_encounter_generation_implementation_plan_2026-07-04.md)
  (Slices 1-2).

### [CNC-5] Chapter semantics  **[RESOLVED]**
Is a chapter an engine node, a label, or a grouping?
- **A - Chapter = one campaign node.** Simple but blocks multi-node chapters.
- **B - Chapter = story-facing metadata/grouping over one or more nodes.**
- **C - Chapter = battle encounter only.**
- **Resolution (2026-07-04): B.** `CampaignNode` stays the sole engine progression
  primitive. `Chapter` is story-facing metadata supplying labels, numbering, splash art,
  story grouping, and save-slot display over one or more nodes. A node carries an optional
  `chapter_id` (see the `[CNC-6]` matrix); it must resolve to a `Chapter` metadata record.

### [CNC-6] Valid node compositions  **[RESOLVED]**
Which field combinations are legal?
- **Resolution (2026-07-04): a validation matrix owned by the campaign loader /
  `DataManager`, evaluated once at load, not scattered per screen.**

  | `node_type` | battle target | `prep_panels` | `chapter_id` | event payload |
  |---|---|---|---|---|
  | `battle` | **required** — `encounter_id` XOR legacy `map_id` | optional (pre-launch prep) | optional | optional |
  | `hub` | **forbidden** — advances by Continue | optional (>=0) | optional | optional (story beat = hub + event, no deploy) |

- **Rules:**
  - A `battle` node must resolve exactly one battle target: `encounter_id` (preferred) XOR
    the legacy `map_id` adapter. A `hub` node must not carry an encounter/map ref.
  - Each `prep_panels` entry validates per the `[CNC-2]` rule (`panel_type` resolves; a
    `panel_instance_id` is present iff the type requires per-instance config).
  - A story-only beat is a `hub` node with an opening event payload and no deploy (per
    `[CNC-3]`). A skirmish is a `prep_panel` of `panel_type:"skirmish"` bound to an
    encounter-table instance (per `[CNC-9]`).
  - `chapter_id`, when present on any node, must resolve to a `Chapter` record (`[CNC-5]`).

### [CNC-7] Save/resync behavior when a node changes type or refs  **[RESOLVED]**
If an author edits a node after a player has a save, what happens?
- **A - Pre-1.0 hard incompatibility:** package edits invalidate old saves unless version
  matches.
- **B - Best-effort resync by `node_id`, warning on missing/new refs.**
- **C - Full migration hooks per package.**
- **Resolution (2026-07-04): A for the early builder iterations.** A package edit
  invalidates old saves unless the version matches. Best-effort resync (B) and per-package
  migration hooks (C) are a later content-resync contract, not built now. This is a
  deliberate scope cut, not a free property — the save binds to `node_id` (`[CNC-1]`), but
  we do not attempt to reconcile changed refs mid-development.

### [CNC-8] Launch and completion semantics  **[RESOLVED]**
What event advances a node?
- `hub`: Continue / node-advance action.
- `battle`: battle result (`victory`, `defeat`, possibly draw/PvP result).
- story/dialogue payload: completion, choice branch, or MET action.
- **Resolution (2026-07-04): node completion is an action/effect primitive output,
  dispatched on `node_type` as a data key — never a hardcoded `match` per node type.** The
  campaign loader keeps a small internal registry seeded with `battle` and `hub` completion
  handlers; a node's launch/completion is resolved by looking up `node_type` in that
  registry. This is the mechanism that keeps `[CNC-3]` open: a third type (`story`,
  `activity`) registers a handler as additive content, not an engine edit. Aligns with the
  AGENTS.md open-registry principle.

### [CNC-9] Skirmish and generated encounters  **[RESOLVED - feeds PUG]**
How does a skirmish attach to the graph?
- **A - A PHB panel launches an encounter table independent of graph nodes.**
- **B - A node points to an encounter table; the panel chooses from that node's table.**
- **C - Both via the same launch primitive; different trigger surfaces.**
- **Resolution (2026-07-04): C.** The same launch primitive (the `[CNC-8]` action/effect
  output) fires from a graph node OR a PHB `skirmish` panel; only the trigger surface
  differs, the launch payload (a `BattleEncounterDef`, possibly generated) stays shared.
  Matches `[PUG-5]`. This resolves the `[CNC]` dependency that `[PUG-4..7]` waited on —
  skirmish/encounter format can now be locked against the `BattleEncounterDef` shape.

### [CNC-10] Authoring surface and JSON shape  **[RESOLVED]**
How much of this is hand-authored JSON vs GUI-builder-only?
- **Resolution (2026-07-04): JSON is the source of truth and the GUI builder writes it.**
  The schema stays readable enough for hand repair; the GUI provides guardrails and
  previews on top. Neither surface is privileged over the other — the JSON is canonical and
  the builder is a validated editor for it.

## 4. Immediate implications

- `CampaignData` should treat `node_id` as durable and every reference field as mutable.
- Do not use `MapData` as the design name for a full chapter or encounter. The canonical
  model is split: **Battle Map** (`BattleMapDef`) vs **Battle Encounter**
  (`BattleEncounterDef`), per `[CNC-4]`.
- `[PUG-4..7]` is now **UNBLOCKED** — the skirmish/encounter format locks against the
  `BattleEncounterDef` shape and the shared `[CNC-8]/[CNC-9]` launch primitive.
- The legacy `map_id -> MapData` slot remains the migration adapter for un-split authored
  maps while the campaign band composes/refactors the runtime onto the two-def model.
