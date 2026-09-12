---
Role: dated
Type: register
Status: RESOLVED 2026-06-21j
Last verified: 2026-06-23
Register: FOW-1..7
Resolved-in: 2026-06-21j
---

# Fog of War / Line-of-Sight (§5) — Draft Plan + Open Questions Register

**Started:** 2026-06-21d
**Status:** RESOLVED 2026-06-21j — all of `[FOW-1..7]` resolved (FOW-7 added this session).
Build-ready (gated behind §2's save slice for `discovered_units`). Substantial new system.
**Source:** `planning_backlog_2026-06-20.md` §5; session note 2026-06-21c Tier 1 #3.
**Ties to:** §2 suspend (`discovered_units` is the only new save field), §4 map-readability
(reveal overlay shares the overlay infra), `EnemyAI` (AI cheats v1 → [FOW-3]), **MET**
(`reveal_tiles` reveals closed rooms; new `light` action + future `set_fog` weather action),
**DCH** (braziers are `map_objects` with a `lit` state — [FOW-7]).
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

- **`UnitData.line_of_sight: int = 4`** already exists (line 33) — authored per unit,
  default 4. **Nothing reads it today.** This is the vision-radius input fog will consume.
- **`MapData` carries a save-system TODO** (top of file): runtime terrain mutation /
  visibility is explicitly called out as not-yet-snapshotted. Fog visibility is per-faction
  runtime state that the §2 save must capture.
- **Terrain model is string-grid based.** `GridManager.get_terrain_at(tile)` returns a
  terrain code; `TERRAIN_DEF_BONUS`/`TERRAIN_DODGE_BONUS` exist. Fog needs a *vision-cost*
  or *blocks-sight* terrain property — **not present** (forests/walls don't yet impede sight).
- **Overlay infra** (`_overlay` TileMapLayer, `_paint_overlay`) can render a fog/unseen
  mask, but there is no "hidden tile" source today.
- **Enemy spawning is full-knowledge.** `GameMap._spawn_units` respawns all enemies; the
  HUD and `EnemyAI` see every unit. Fog requires a per-faction "known units" filter at the
  render + AI layers.
- **`EnemyAI`** targets via `_living_hostiles_for_faction` (sees all). Under fog, the AI
  must either respect the same vision rules or be exempt — see [FOW-3].

## 2. Draft plan (classic FE convention)

Fire Emblem fog (FE3 "Fog of War", GBA, Conquest) convention:
- The map is dark except tiles within **any deployed allied unit's vision radius**.
- **Vision radius** = the unit's stat (here `line_of_sight`), often **+1 on a fort/some
  terrain**, reduced at night in some titles.
- **Enemies are invisible until seen**; stepping a tile adjacent can reveal an ambush.
- Thieves/scouts have **higher vision**; torches/lanterns are consumable vision items.
- **AI under fog**: classic FE enemies on fog maps typically *do* have full knowledge
  (they "cheat") OR are scripted — true symmetric fog for AI is rare. This is the headline
  design decision ([FOW-3]).

Core model: a per-faction `visible_tiles: Dictionary` recomputed at the start of that
faction's phase (and after each of its units moves) as the union of each living unit's
LoS disc. Render = dim/hide tiles not in the active viewer's set; hide enemy unit nodes
on unseen tiles.

## 3. Open questions register

### [FOW-1] Visibility model: radius vs true line-of-sight  **[RESOLVED → A + occlusion seam]**
- **A — Simple radius (Manhattan/Chebyshev disc)**, terrain does NOT block sight. Matches
  GBA-FE fog (vision is a pure range; forests don't occlude). Cheapest; reuses
  `_tiles_in_range`-style math.
- **B — True LoS with terrain occlusion** (walls/forest block sight beyond them;
  raycast/shadowcast per tile). Tactically richer, much heavier, needs a "blocks_sight"
  terrain property added to the terrain model.
- **Rec: A** — GBA-FE (the project's evident touchstone) uses radius fog, not occlusion;
  it's far cheaper for the web/mobile target and `line_of_sight` is already a flat radius.
  Reserve B as a later per-map opt-in if a design wants it.
- **Resolution: A (2026-06-21j).** Simple flat-radius vision for v1. **Implementation
  constraint:** compute visibility through a single `compute_visible_tiles()` seam so true
  line-of-sight (B — "can't see around corners") can replace the disc with a shadowcast
  **as a later expansion** without touching any caller. Owner explicitly wants v1 to ship
  flat-radius unit vision **plus** two authored reveal tools (see new scope §2a): closed
  rooms that reveal on map events, and lightable braziers ([FOW-7]). True LoS occlusion =
  deferred expansion.

### [FOW-2] Fog is per-map opt-in, or a global rule?  **[RESOLVED → encounter-layer property]**
- **A — Per-`MapData` flag (`fog_enabled: bool`)** — fog is a property of a map, authored
  per scenario. Classic FE: specific chapters are fog chapters.
- **B — `CampaignRules` toggle** — fog on/off for the whole run.
- **C — Both:** map declares fog; a campaign rule may force-disable (accessibility).
- **Rec: A** (with C's force-off later) — fog is a per-chapter design choice in FE, not a
  run-wide mode. A `MapData.fog_enabled` field (default false) means existing maps load
  unchanged. Composes with §2's per-map data fields.
- **Resolution: A, framed as ENCOUNTER/SCENARIO data (2026-06-21j).** Owner's framing
  reshaped this: fog is **scenario/encounter data — it lives with the encounter roster and
  difficulty modifiers, explicitly NOT as a terrain-grid property and NOT as a run-wide
  `CampaignRules` mode.** Rationale: terrain geometry should be **reusable across chapters**
  (defend a castle ch.3, attack the same castle ch.7; the same field is clear in summer but
  a sight-blocking blizzard in winter), so fog must ride the encounter layer, not the map's
  baked terrain.
  - **v1 reality:** there is no terrain/encounter split today — `MapData` already bundles
    the terrain `grid`/`tilemap_scene_path` AND the roster `enemy_placements` + objectives.
    So `fog_enabled` ships on `MapData` **next to `enemy_placements`**, which already
    satisfies "same area as the roster." Default `false` ⇒ existing maps load unchanged.
  - **Forward reservation (NOT built now):** a future **`MapData` decomposition** into a
    reusable terrain base + a per-encounter overlay carrying roster + difficulty + fog +
    weather. Authoring fog as encounter data now means it moves with the roster
    automatically when that split lands. *(New forward item — see §6.)*
  - **Timed/weather fog ("blizzard rolls in turn 5") = MET convergence:** a future MET
    `set_fog`/`set_weather` action fired by a `turn_reached` trigger. Fast-follow, not v1.
  - The accessibility force-off + the [FOW-3] `ai_respects_fog` rule still belong in the §2
    `CampaignRules` consolidation (run-wide overrides over the per-encounter default).

### [FOW-3] AI knowledge under fog — the headline decision  **[RESOLVED → A v1, B as future rule]**
- **A — AI cheats (full knowledge).** Enemies path/target as today, ignoring fog; only the
  *player's* view is fogged. Matches most classic FE fog maps; zero `EnemyAI` change.
- **B — AI respects fog symmetrically.** `EnemyAI` only sees player units inside red's
  vision set; un-spotted players are safe. Fairer, far more complex (AI needs a
  "last-known-position" memory + search behavior), and can feel passive/exploitable.
- **C — Per-profile:** most enemies cheat (A); a future "scout/patrol" profile respects
  fog (ties to §5 AI-profiles item).
- **Rec: A** — symmetric fog AI is a large, risky behavior system that classic FE itself
  mostly avoids; cheating AI is the genre norm and keeps `_living_hostiles_for_faction`
  untouched. Note C as a future scout-profile hook (cross-ref the AI-profiles register).
- **Resolution: A for v1/MVP; symmetric fog (B) reserved as a future campaign-rule
  expansion (2026-06-21j).** Owner: "ship A for the MVP and later have an expansion/campaign
  rule for symmetric fog for the AI." So B is **not** discarded — it becomes a run-wide
  `CampaignRules.ai_respects_fog` toggle in the §2 consolidation (distinct from C's
  per-profile scout, which remains a separate AIP hook; the two can coexist).
  - **Build-time constraint to keep B cheap later:** keep ALL AI hostile-acquisition
    funneled through the single `EnemyAI._living_hostiles_for_faction` seam (it already is —
    `EnemyAI.gd:319`). A future `ai_respects_fog` rule then wraps that one function with a
    per-faction vision filter instead of threading fog through `EnemyAI`. v1 ships zero
    `EnemyAI` change; a headless test asserts the AI still targets units the player can't
    see (proves A).
  - **Cross-ref:** AIP `[AIP-2]` (fog-scout profile = C) now has its upstream decision —
    most enemies cheat, scout profile + the campaign rule are the two future fog-aware paths.
  - **Cross-ref:** `[PER-9]` perception forecast-fidelity is the **same family** — a two-channel
    CampaignRules constant (player-view A / AI-view B) that generalizes `ai_respects_fog` to the
    combat forecast; both wrap the `_living_hostiles_for_faction` seam and share the §2 consolidation.

### [FOW-4] Vision recompute cadence + reveal-on-move  **[RESOLVED → A-full / per-step interrupt]**
- **A — Recompute the active faction's visible set at phase start + after every committed
  move** (so walking forward reveals tiles mid-move, enabling ambush reveals).
- **B — Phase-start only** (cheaper; no mid-move reveal — the player must end the turn to
  see what a move uncovered).
- **Rec: A** — mid-move reveal is the *point* of FE fog (the ambush moment); recompute is
  one LoS-disc union per move, cheap at A's radius model. Reveal an enemy → pause/announce
  (reuse the `ai_unit_acting` camera-pan pattern for "enemy spotted").
- **Resolution: A-full — per-step mid-tween reveal WITH ambush interrupt (2026-06-21j).**
  Owner chose the richest form over the cheaper destination-only variant. v1 recomputes the
  mover's visible set **per tile stepped along the path** (not just at the destination); when
  a step brings a previously-hidden enemy into view, the in-progress move **halts at that
  tile** (the classic FE ambush stop) and fires the "enemy spotted" feedback (reuse the
  `ai_unit_acting` camera-pan/announce pattern). **Implementation note:** this is the one
  piece of real v1 complexity — the move-execution path must check visibility per step and
  be able to interrupt the move tween, so build it against the existing per-step movement
  loop and add a headless test that asserts a move halts on the step that reveals an enemy.

### [FOW-5] Save/suspend interaction (forward dep on §2)  **[OPEN]**
Per-faction visibility + "which enemies has the player discovered" is runtime state.
- **A — Serialize the discovered-enemy set + recompute live visibility on load.** Save only
  *which units the player has ever spotted* (small); the visible-tile mask is recomputed
  from unit positions at load. Minimal save growth.
- **B — Serialize the full visible-tile mask per faction.** Larger, exact, but redundant
  (derivable from positions).
- **Rec: A** — visibility is a pure function of unit positions + LoS, so only the
  *discovered* memory (the bit that ISN'T derivable) needs saving. Reserve a
  `discovered_units` field in the §2 schema (this register's only §2 ask).
- **Resolution: A (2026-06-21j).** `discovered_units` (the set of enemy unit ids the player
  has ever spotted) is the **only new save field** this whole feature adds; the visible-tile
  mask is recomputed from unit positions + LoS on load. **The two new authored reveal tools
  add ZERO save fields** because both derive from already-reserved §2 state:
  - **Event-revealed rooms** ([FOW-1] §2a) re-reveal on load from **`map_events_fired`** —
    a room revealed by event `E` is re-revealed because the snapshot records `E` fired
    (MET `[MET-5]`).
  - **Brazier lit state** ([FOW-7]) persists in **`map_objects_state`** (DCH/MET reserved),
    since a brazier is a `map_object`.

### [FOW-6] Vision modifiers: terrain + items  **[RESOLVED → A v1]**
- **A — `line_of_sight` only, no modifiers** (flat per-unit radius). Ship the minimum.
- **B — Terrain bonus** (e.g. +1 LoS on forts/peaks, like FE) via a `TERRAIN_VISION_BONUS`
  dict mirroring the existing bonus dicts.
- **C — B + consumable torch/lantern items** (an `ItemData` effect granting temp vision).
- **Rec: A for v1, design B/C as fast-follows** — ship flat radius fog working end-to-end
  first; terrain vision + torches are additive and slot cleanly onto the existing
  `TERRAIN_*_BONUS` + `ItemHandler` patterns once the core works.
- **Resolution: A for v1 (2026-06-21j).** Flat per-unit `line_of_sight` (the resolved
  `unit.data.line_of_sight`; `ClassData.base_line_of_sight` already feeds it via reclass
  deltas — `Unit.gd:1059`). **Designed fast-follows:** B (terrain LoS bonus via
  `TERRAIN_VISION_BONUS`), C (torch/lantern *items* carried by units via `ItemHandler`), and
  a third **concealment axis** (GBA-FE "unit in a forest is hidden unless adjacent" — a
  per-terrain hide flag, separate from occlusion). **Note:** braziers ([FOW-7]) are NOT this
  question — they are map-placed vision *sources* (`map_objects`), not unit-carried modifiers.

### [FOW-7] Lightable braziers — vision-source map objects  **[RESOLVED → A: unit action + MET action]** *(added 2026-06-21j)*
New question raised by the owner's [FOW-1] answer: v1 should ship **braziers that can be lit
to reveal a larger area.** A brazier is a **map-placed vision source**, distinct from a unit's
LoS and from the unit-carried torch *item* deferred in [FOW-6].
- **Model:** a brazier is a **`map_object`** (DCH's unified `map_objects` model) with a
  runtime **`lit: bool`** state and a **`vision_radius`** property. While `lit`, its tile
  contributes a vision disc to the player's visible set (union alongside unit LoS discs and
  event-revealed regions). Lit state persists in `map_objects_state` (no new save field).
- **How it gets lit — Resolution: BOTH (2026-06-21j).**
  - **Unit action:** an adjacent unit can spend its action to light a brazier — reuse DCH's
    adjacent-interact pattern (the same seam doors/chests use), not a bespoke flow.
  - **Map-event action:** a new MET action **`light`** lets triggers/events light (or
    pre-light) braziers — folds into MET's action vocabulary next to `reveal_tiles`/`flag`/
    `spawn` (MET `[MET-3]`). *(Cross-ref MET register: add `light` to the v1+ action list.)*
- **Open sub-detail for build time (not blocking):** one-way (light only) vs toggle
  (light/extinguish). Rec: **one-way for v1** (lighting reveals; extinguish is a fast-follow
  if a design needs it) — keeps the `lit` latch monotonic like MET's `once`.

## 2a. New v1 scope added this session (authored reveal tools) *(2026-06-21j)*
The owner's [FOW-1] answer expanded v1 beyond pure unit-LoS fog with **two authored reveal
tools**, both of which ride registers already resolved — so they add little new machinery and
**zero new save fields**:
1. **Closed rooms that reveal on map events** — a sealed region stays fogged until a trigger
   fires, then is permanently revealed. This **is** MET's existing `reveal_tiles` action
   (`[MET-3]`) writing into fog's persistent revealed set. Re-reveals on load from
   `map_events_fired` ([FOW-5]).
2. **Lightable braziers** — see [FOW-7]; `map_objects` vision sources lit by unit action or
   MET `light` action.

**Resulting v1 visible-set formula:**
`visible = ⋃(living player-unit LoS discs) ∪ ⋃(lit-brazier discs) ∪ (event-revealed regions)`,
recomputed per the [FOW-4] cadence (phase-start + per-step during movement).

## 4. Slice sketch (revised 2026-06-21j)
1. `MapData.fog_enabled` (encounter-layer field, [FOW-2]) + `compute_visible_tiles()` seam
   ([FOW-1]) computing the per-faction visible set as the radius union of `line_of_sight`.
2. Render: fog mask overlay + hide enemy nodes on unseen tiles (player view only).
3. Reveal-on-move — **per-step recompute with ambush interrupt** ([FOW-4] → A-full) +
   "enemy spotted" feedback (reuse `ai_unit_acting` camera-pan).
4. AI cheats — no `EnemyAI` change; verify acquisition stays funnelled through
   `_living_hostiles_for_faction` so the future `ai_respects_fog` rule wraps one seam
   ([FOW-3] → A).
5. Save: `discovered_units` reserved in §2 schema ([FOW-5]); rooms/braziers derive from
   `map_events_fired` / `map_objects_state` (no new fields).
6. **Authored reveal tools (in v1 per owner):** event-revealed rooms via MET `reveal_tiles`;
   lightable braziers ([FOW-7]) as `map_objects` + new MET `light` action.
7. (Fast-follow) terrain vision bonus + torch items + concealment ([FOW-6]); timed/weather
   fog via a future MET `set_fog` action ([FOW-2]); true-LoS occlusion ([FOW-1] B).

## 5. Test notes
- Headless: assert the visible-tile union for a fixed unit layout + `line_of_sight`; assert
  an enemy on an unseen tile is filtered from the player's render list but NOT from
  `EnemyAI` target lists (proves [FOW-3] → A).
- Reveal: per-step move, assert the move **halts** on the step that brings a previously-hidden
  enemy into view and that the enemy enters `discovered_units` ([FOW-4]).
- Authored reveals: a `reveal_tiles` map event adds its tiles to the revealed set and they
  survive a save/load round-trip via `map_events_fired`; a lit brazier ([FOW-7]) contributes
  its `vision_radius` disc and its `lit` state survives round-trip via `map_objects_state`.

## 6. Forward reservations surfaced (not built now)
- **`MapData` terrain/encounter decomposition** ([FOW-2]) — split the reusable terrain base
  from a per-encounter overlay carrying roster + difficulty + fog + weather. New forward
  architectural item; fog authored as encounter data now so it migrates automatically.
- **Timed/weather fog** ([FOW-2]) — a future MET `set_fog`/`set_weather` action on a
  `turn_reached` trigger (the "blizzard rolls in" case).
- **`CampaignRules.ai_respects_fog`** ([FOW-3]) + accessibility fog force-off — run-wide
  overrides, land in the §2 CampaignRules consolidation.
- **`MET light` action** ([FOW-7]) + brazier extinguish-toggle — MET vocabulary growth.
