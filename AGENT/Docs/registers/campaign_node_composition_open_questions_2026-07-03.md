---
Type: register
Status: OPEN
Last verified: 2026-07-03
Register: CNC-1..10
---

# Campaign Node Composition - Maps, Encounters, Chapters, and Hub Panels - Open Questions

**Started:** 2026-07-03.
**Status:** OPEN - one owner constraint is resolved: a `CampaignNode` keeps stable
identity while its type and outbound references are author-editable. The remaining
questions decide how nodes point to hub panels, story/chapter metadata, battle maps, and
encounter layers.
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
- **Hub Panel** - a `[PHB]` option-panel id exposed by a node.
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

### [CNC-2] Node reference slots  **[OPEN]**
What fields can a node point to?
- **A - Single overloaded `map_id` plus optional `prep_panels`.** Simple but keeps
  overloading "map" to mean terrain, encounter, and chapter.
- **B - Explicit slots:** `chapter_id`, `prep_panels`, `encounter_id`, optional
  `battle_map_id` override.
- **C - Generic `payload_refs` dictionary keyed by registry ids.** Most extensible; harder
  to validate and explain.
- **Rec: B.** Explicit slots are readable and builder-friendly while still allowing each
  referenced vocabulary to be an open registry.

### [CNC-3] Node type vocabulary  **[OPEN]**
Do we keep `node_type` to `battle|hub`, or add `story` / `activity` node types now?
- **A - Keep `battle|hub` for v1.** Story-only beats are hub nodes with no deploy and an
  opening dialogue/event payload.
- **B - Add `story` now.** Cleaner author intent, but another node flow.
- **C - Add open-registry node types.** Future-proof, but too much before the first loop.
- **Rec: A for build, reserve C for later.** `battle|hub` is already ratified; a node-type
  registry can come after the first loop proves the base flows.

### [CNC-4] Battle map vs encounter layer split  **[OPEN]**
When should `MapData` split into reusable terrain and encounter payload?
- **A - Split now:** `BattleMapDef` plus `BattleEncounterDef`.
- **B - Keep `MapData` monolithic for first loop, but design schema as adapter-friendly.**
- **C - Never split.**
- **Rec: B.** First loop can use live `MapData`; skirmish/generation should target the
  encounter-layer shape so the later split is additive.

### [CNC-5] Chapter semantics  **[OPEN]**
Is a chapter an engine node, a label, or a grouping?
- **A - Chapter = one campaign node.** Simple but blocks multi-node chapters.
- **B - Chapter = story-facing metadata/grouping over one or more nodes.**
- **C - Chapter = battle encounter only.**
- **Rec: B.** Keep `CampaignNode` as the engine primitive. `Chapter` should supply labels,
  numbering, splash art, story grouping, and save-slot display.

### [CNC-6] Valid node compositions  **[OPEN]**
Which field combinations are legal?
- Examples to settle:
  - `hub` + `prep_panels` only.
  - `hub` + chapter metadata + dialogue/event payload.
  - `battle` + encounter only, where encounter points to battle map.
  - `battle` + direct legacy `map_id` as an adapter.
  - `battle` + `prep_panels` before launch.
- **Rec:** define a validation matrix in `DataManager` / campaign loader, not scattered
  per screen.

### [CNC-7] Save/resync behavior when a node changes type or refs  **[OPEN]**
If an author edits a node after a player has a save, what happens?
- **A - Pre-1.0 hard incompatibility:** package edits invalidate old saves unless version
  matches.
- **B - Best-effort resync by `node_id`, warning on missing/new refs.**
- **C - Full migration hooks per package.**
- **Rec: A for early builder iterations; B/C belong to the later content-resync contract.
  Do not pretend this is free.

### [CNC-8] Launch and completion semantics  **[OPEN]**
What event advances a node?
- `hub`: Continue / node-advance action.
- `battle`: battle result (`victory`, `defeat`, possibly draw/PvP result).
- story/dialogue payload: completion, choice branch, or MET action.
- **Rec:** make node completion an action/effect primitive output, not a hardcoded
  `match` per node type.

### [CNC-9] Skirmish and generated encounters  **[OPEN - feeds PUG]**
How does a skirmish attach to the graph?
- **A - A PHB panel launches an encounter table independent of graph nodes.**
- **B - A node points to an encounter table; the panel chooses from that node's table.**
- **C - Both via the same launch primitive; different trigger surfaces.**
- **Rec: C.** This matches `[PUG-5]`: trigger surface changes, launch payload stays shared.

### [CNC-10] Authoring surface and JSON shape  **[OPEN]**
How much of this is hand-authored JSON vs GUI-builder-only?
- **Rec:** JSON is the source of truth and the GUI editor writes it. The schema must be
  readable enough for hand repair; the GUI can provide guardrails and previews.

## 4. Immediate implications

- `CampaignData` should treat `node_id` as durable and every reference field as mutable.
- Do not use `MapData` as the design name for a full chapter or encounter. In prose,
  distinguish **Battle Map** from **Battle Encounter**.
- `[PUG-4..7]` should remain OPEN until `[CNC-2..9]` are resolved.
- The first loop can still build with legacy `map_id -> MapData`; the schema should leave a
  clear adapter path to `encounter_id -> battle_map_id`.
