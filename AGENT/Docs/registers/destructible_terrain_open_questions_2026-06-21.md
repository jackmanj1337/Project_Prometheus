---
Role: dated
Type: register
Status: RESOLVED 2026-06-21g
Last verified: 2026-06-23
Register: DTR-1..8
Resolved-in: 2026-06-21g
---

# Destructible Terrain — Breakable Walls / Fellable Trees / Crystals (§5) — Draft Plan + Open Questions Register

**Started:** 2026-06-21g
**Status:** [DTR-1..8] **RESOLVED 2026-06-21g** — build-ready (fast-follow on DCH). Key shape:
a breakable is a **real `Unit` in disguise, quarantined from the roster** ([DTR-3]), taking the
**full unit damage pipeline** with no dodge/counter ([DTR-2]); **anything breaks anything**
([DTR-4], durability via HP+Def); on break it reveals terrain + fires a **general `on_break` event
list** (bridge/spawn/loot/flag — [DTR-5]). **Fast-follow on Doors & Chests (DCH)** — rides the
same unified `map_objects` model + runtime passability overlay + `map_objects_state` snapshot.
**Source:** user question 2026-06-21g (breakable walls / fellable trees / breakable magic
crystals); foreshadowed by the `MapData` save-TODO ("shifting terrain / destructible tiles") and
the 2026-05-13c code review (destructible locations force suspend saves).
**Code:** `scripts/GameMap.gd` (`_CHAR_TO_SOURCE`, `"W"` wall = source 6), `scripts/core/GridManager.gd`
(`get_attackable_enemies_from_tile` → units only; passability), `scripts/core/CombatResolver.gd`
(attacker-vs-defender units), `scripts/resources/WeaponData.gd` (`combat_family`, `mt`,
`effect_tags`), `scripts/resources/MapData.gd` (no object model; save-TODO).
**Depends on:** **DCH build** (defines `map_objects` + the passability overlay this rides). Walk
& build this AFTER DCH.
**Converges with Map Events / Triggers ([MET], `map_events_triggers_open_questions_2026-06-21.md`,
RESOLVED 2026-06-21h):** DTR's `on_break` event list is the **`object_broken` trigger's action
list** on the shared MET runner; the `spawn` (reinforcement) seam DTR-5 flagged is owned by
[MET-8]; the `flag` action rides MET's flag store. DTR may build first with a local action list,
then migrate to the MET runner when it lands.
**Pattern:** mirrors §1 ICD / §2 CST / DCH. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

- **No destructible-terrain feature exists, and no plan did before this register.** Roadmap has
  no row; backlog has no entry. Only *groundwork awareness*: the `MapData` save-TODO names
  "shifting terrain / destructible tiles" and the 2026-05-13c review ties them to suspend saves.
- **Walls are static authored terrain.** `GameMap._CHAR_TO_SOURCE` maps `"W"` → tile source 6;
  a wall is just an impassable tile in the immutable `grid`. There is no HP, no per-tile object.
- **Combat targets UNITS only.** `GridManager.get_attackable_enemies_from_tile` returns hostile
  *units*; `CombatResolver` resolves attacker-vs-defender *units*. Striking a tile-object is a
  new target kind with no counter-attack and no EXP-from-kill semantics by default.
- **Weapon data is ready for gating + damage.** `WeaponData` has `combat_family` (axe/sword/…),
  `mt` (might), and `effect_tags` — enough to express "axes fell trees" and "HP reduced by `mt`".
- **DCH already settled the substrate.** [DCH-2] (2026-06-21g) chose the **unified
  `MapData.map_objects` model** + a **runtime passability overlay** + **`map_objects_state`
  snapshot**. A breakable wall is structurally a door whose "open" verb is "attack to 0 HP"; it
  reuses ~80% of DCH slice 1 with zero new save schema.

## 2. Draft plan (relationship to DCH)

A destructible object is a `map_objects` entry (resolved shape):
`{ type:"breakable", subtype:"wall"|"tree"|"crystal", tile:Vector2i,
object_unit:"<object UnitData id>", reveals_terrain:String,
on_break:Array[Dictionary], broken:bool }` — HP/Def/Res live on the spawned object Unit.

- **Combat representation ([DTR-3]):** at map-load the entry **spawns a real `Unit`** with an
  "object" `UnitData` (weaponless, immobile, neutral faction, forced-hit, no counter), tagged
  `is_destructible_object` so the roster systems skip it (turn order, rout liveness, EXP, pair-up,
  save). Attacking it runs the **full unit damage pipeline** ([DTR-2]); **any weapon works**
  ([DTR-4]); the AttackPreview forecast works unchanged.
- **Movement:** while unbroken, the passability overlay (DCH slice 1) treats the tile as blocked;
  on break (object Unit reaches 0 HP and is freed) it flips to `reveals_terrain`.
- **On break ([DTR-5]):** flip terrain, then run the `on_break` event list — `reveal_tiles`
  (bridge), `spawn` (reinforcements), `loot`, `flag` (story-flip seam). v1 = terrain + reveal_tiles.
- **Persistence ([DTR-8]):** `broken` + current HP latch into `map_objects_state` (DCH's array,
  reserved in §2). **No new save field.**

The deltas vs. doors are the *real-unit combat representation + roster quarantine*, the *on_break
event system*, and *emergent HP/Def durability* — all captured in §3.

## 3. Open questions register

### [DTR-1] Scope + type model — which objects in v1, one generic type vs distinct?  **[OPEN]**
- **A — One generic `type:"breakable"` with a `subtype` + per-instance config** (hp, break_with,
  reveals_terrain, on_break). Walls/trees/crystals are data, not code; ship all three at once.
- **B — Walls only in v1**, trees/crystals as fast-follows.
- **C — Three distinct object types** (`wall`/`tree`/`crystal`) each with bespoke code.
- **Rec: A** — one generic breakable backed by per-instance data is the smallest *code* surface
  and makes walls/trees/crystals pure authoring. Subtype drives only flavor (sprite, sfx) +
  default gating. Avoids three parallel systems (the same logic that drove [DCH-2]'s unify).
- **Resolution:** **A (RESOLVED 2026-06-21g)** — one generic breakable, walls/trees/crystals as
  data. **Owner refinement:** it should be **damaged by anything that would damage a unit
  standing on that tile** — i.e. the full unit damage pipeline applies (see [DTR-2]/[DTR-3]).

### [DTR-2] Break mechanic — HP/durability vs one-hit vs flat threshold  **[OPEN]**
- **A — HP pool, reduced by attack `mt`** (object has `hp`; each qualifying strike subtracts the
  weapon's might; breaks at ≤0). FE-classic for siege/walls; readable; rewards strong weapons.
- **B — One-hit break** (any qualifying attack destroys it). Simplest; no HP tracking/UI.
- **C — Hit-count threshold** (N qualifying hits regardless of mt).
- **Rec: A** — an `hp` field is the most expressive (a thick wall vs a sapling = data), reuses the
  damage number combat already computes, and the broken-at-0 check is trivial. `hp:1` degenerates
  to one-hit, so A subsumes B. Crit/effective interactions deferred unless asked.
- **Resolution:** **OWNER OVERRIDE of the flat-mt rec (RESOLVED 2026-06-21g)** — treat attacking
  a breakable **exactly like attacking a unit that can't retaliate or dodge**: run the **full unit
  damage pipeline** (might, weapon triangle, effectiveness, crit, skills, terrain Def/Res) against
  the object's HP, but force the hit (no dodge) and allow no counter-attack. HP pool, breaks at
  ≤0. **Emergent durability:** because real Def/Res apply, a high-Def "wall" naturally shrugs off
  weak weapons (0 damage = can't break it) — durability is tuned via HP + Def, not a hard rule.

### [DTR-3] Attack-a-tile-object combat path — reuse CombatResolver vs separate strike path  **[OPEN]**
Combat is unit-vs-unit today; an object has no Spd/Def/avoid/counter.
- **A — Lightweight separate "strike object" path** — a small resolver branch: damage = attacker
  effective `mt` (minus an optional object `defense`), no hit roll / no counter / no EXP, apply to
  `hp`. Keeps `CombatResolver` unit math clean.
- **B — Model the object as a pseudo-defender** fed through `CombatResolver` (hp, def=0,
  avoid=0, can't counter). Reuses the pipeline but forces "is this a unit?" guards throughout.
- **Rec: A** — a one-hit-applies-`mt` strike path is far simpler than teaching the whole combat
  pipeline about non-unit defenders; objects don't dodge, double, crit-for-EXP, or counter. Wire
  targeting via a sibling to `get_attackable_enemies_from_tile` (e.g. `get_breakables_in_range`).
- **Resolution:** **REAL UNIT, QUARANTINED FROM ROSTER (RESOLVED 2026-06-21g — supersedes both
  draft options A/B).** A breakable is a `map_objects` entry that at map-load **spawns a real
  `Unit`** with an "object" `UnitData` (weaponless ⇒ can't counter, immobile, neutral "object"
  faction, forced-hit so it never dodges). Combat + the AttackPreview forecast then work with
  ~zero combat-code change (the pipeline is already Unit-method duck-typed). **Quarantine:** a
  single `is_destructible_object` flag excludes it from the roster consumers that iterate units —
  • turn order / activation (never takes a turn) • rout/defeat liveness (not a living unit)
  • EXP-on-kill (breaking grants no EXP) • pair-up / support / rescue (never offered)
  • **save** (persists via `map_objects_state`, NOT the unit roster — consistent with DCH).
  On break, the object Unit is freed and the tile flips per [DTR-5]. *Build note: enumerate every
  "for each unit" iteration during the build and add the guard; this is the main risk surface.*

### [DTR-4] Weapon/skill gating — can anything break anything?  **[OPEN]**
- **A — Per-object `break_with` allow-list** (by `combat_family`/`effect_tag`); empty = any
  weapon. e.g. tree→`["axe"]`, crystal→`["tome"]` or a `magic` tag, wall→any.
- **B — Anything breaks anything** (no gating); durability alone differentiates.
- **C — A global rule table** (subtype → allowed families) instead of per-instance.
- **Rec: A** — per-instance `break_with` (defaulting from subtype, overridable) gives authors the
  "only axes fell trees" / "only magic shatters crystals" fantasy without a global rules system,
  and degenerates to B when the list is empty. Keys off existing `combat_family`/`effect_tags`.
- **Resolution:** **B — anything breaks anything (OWNER OVERRIDE of the allow-list rec, RESOLVED
  2026-06-21g).** No `break_with` field; any weapon that deals damage chips HP. Differentiation is
  purely durability (HP + Def, per [DTR-2]) — so "only axes fell trees" is achieved, if ever
  wanted, by tuning Def/Res rather than a hard gate. Simpler data; no gating system to build.

### [DTR-5] On-break result — revealed terrain + drops/triggers  **[OPEN]**
- **A — `reveals_terrain` only** (wall→plain, tree→plain/forest-stump); no drops/events in v1.
- **B — `reveals_terrain` + optional `on_break` payload** (loot item/gold like a chest, or a map
  event/trigger id — e.g. a shattered crystal opens a path or fires a flag).
- **Rec: B (data-optional)** — ship the `reveals_terrain` flip as the required behavior, but
  reserve an optional `on_break` dict now (loot reuses DCH's loot-to-opener path; trigger reuses
  the story-flip seam [CST-11]). Authoring a breakable with no payload = pure A. Cheap-now: the
  field exists, the wiring lands when first used.
- **Resolution:** **B+ — reveal terrain PLUS a general event payload (RESOLVED 2026-06-21g, owner
  expanded scope).** Required: the tile flips to `reveals_terrain`. **Owner vision for `on_break`:
  a list of map EVENTS, not just loot** — e.g. *create a bridge across a chasm* (flip a span of
  tiles passable), *spawn reinforcements*, drop loot, fire a story/rule flag, or other scripted
  actions. Model `on_break: Array[Dictionary]` of typed events `{event:"reveal_tiles"|"spawn"|
  "loot"|"flag"|…, …}`. **Forward sub-features this surfaces (NOT v1-blocking; the breakable just
  fires them):**
  - `reveal_tiles` (bridge) = the **same passability-overlay machinery** as breaking, run in
    reverse over a tile span — cheap, lands with this cluster.
  - `spawn` (reinforcements) = needs a **reinforcement-spawn seam** (today `enemy_placements` is
    initial-only; mid-map spawning is new) — flag as its own small forward design.
  - `flag` = reuse the **[CST-11] story-flip / `campaign_rule_flipped` seam**.
  - `loot` = reuse DCH's loot-to-opener path.
  v1 ships `reveal_terrain` + `reveal_tiles`; `spawn`/`flag`/`loot` are typed events wired as their
  seams land. The event list is the extensible contract so authored maps never need re-touching.

### [DTR-6] Line-of-sight — do trees/crystals block sight, not just movement?  **[OPEN]**
- **A — Movement-block only in v1** (trees/crystals block passage; sight handled later).
- **B — Add a `blocks_los:bool`** so a breakable can occlude vision — but this only matters once
  **fog-of-war/LoS (FOW)** exists, and true-LoS-vs-radius is FOW's own open question ([FOW-1]).
- **Rec: A v1, reserve the flag** — LoS occlusion is meaningless until FOW ships and is genuinely
  FOW's design call. Add `blocks_los` to the schema as a reserved/no-op field now (cheap-now) so
  authored maps don't need re-touching when FOW lands; FOW consumes it.
- **Resolution:** **No LoS concept at all (OWNER OVERRIDE of the reserve-flag rec, RESOLVED
  2026-06-21g).** Do not add a `blocks_los` field, not even reserved. Destructibles block movement
  only in v1; sight-occlusion is entirely FOW's design call and will be revisited there when FOW
  is built (accept that authored maps may need a re-touch then — owner accepted that cost).

### [DTR-7] AI interaction — do enemies break terrain?  **[OPEN]**
- **A — No AI v1** — destructibles are player-acted; enemies path around them (a wall blocks both
  sides). Smallest; no `EnemyAI` change.
- **B — Enemies break to reach you** (a "siege/breaker" behavior) — a whole AI behavior that
  overlaps the AI-profiles register.
- **Rec: A v1** — same call as [DCH-4]: ship the player-facing verb first; an enemy-breaker
  behavior lands later as an AIP profile (cross-ref `ai_profiles_open_questions_2026-06-21.md`),
  not in this cluster. Pathfinding already routes around blocked tiles, so A needs no AI work.
- **Resolution:** **A v1 (RESOLVED 2026-06-21g)** — no AI breaking; enemies path around
  destructibles (pathfinding already routes around blocked tiles). An enemy-breaker/siege behavior
  lands later as an AIP profile (cross-ref `ai_profiles_open_questions_2026-06-21.md`).

### [DTR-8] Persistence — rides DCH's `map_objects_state` (confirm)  **[OPEN]**
- **A — `broken:true` latches into `map_objects_state`** (the array DCH reserves in §2). No new
  save field; broken is a one-way latched event like a looted chest / opened door.
- **B — Re-derive** (can't — destruction is one-way).
- **Rec: A** — identical to [DCH-6]; this register adds **zero** new §2 schema. Partial HP on a
  not-yet-broken object also snapshots into the same per-object state if [DTR-2]→A.
- **Resolution:** **A (RESOLVED 2026-06-21g, resolved to rec inline)** — `broken:true` and current
  HP latch into DCH's `map_objects_state` array (reserved in the §2 schema). **Zero new save
  field.** On load, unbroken objects re-spawn their object-Unit ([DTR-3]); broken ones do not, and
  their `reveals_terrain`/`reveal_tiles` results are reapplied. Consistent with doors/chests.

## 4. Slice sketch (RESOLVED 2026-06-21g — after DCH)
1. **Object-Unit + quarantine.** Add `type:"breakable"` to `map_objects` (subtype, object_unit id,
   reveals_terrain, on_break, broken) + `DataManager` validation; author an "object" `UnitData`
   (weaponless, immobile, neutral faction, forced-hit). At map-load, spawn the object Unit and tag
   it `is_destructible_object`. **Enumerate every "for each unit" iteration** (turn order, rout
   liveness, EXP, pair-up/support/rescue, save) and add the skip guard — *the main risk surface.*
2. **Targeting + break.** `get_breakables_in_range` sibling to `get_attackable_enemies_from_tile`;
   the existing `attack` verb resolves through the **full unit pipeline** (no counter, forced hit)
   against the object Unit's HP. Any weapon works ([DTR-4]). AttackPreview reused.
3. **On break.** Object Unit at 0 HP → free it, flip the passability overlay to `reveals_terrain`,
   run the `on_break` event list — v1 wires `reveal_terrain` + `reveal_tiles` (bridge); `spawn`/
   `flag`/`loot` are typed events stubbed until their seams land ([DTR-5]).
4. **Persistence.** Snapshot `broken` + current HP into `map_objects_state` ([DTR-8]); on load,
   re-spawn unbroken object Units and reapply broken results; extend `test_snapshot_coverage`.
5. **Fast-follows / forward sub-features.** Reinforcement-spawn seam (mid-map `spawn`); `flag` via
   the [CST-11] story-flip seam; enemy-breaker AIP profile ([DTR-7]→B). LoS is explicitly NOT
   handled ([DTR-6]) — deferred wholesale to FOW.

## 5. Test notes
- Headless: a unit in range of a breakable sees the `attack` verb; resolving runs the full damage
  formula against the object Unit's HP (any weapon — [DTR-4]); reaching ≤0 frees the object Unit,
  flips the tile to `reveals_terrain`, and runs `on_break`. A weapon doing 0 damage (Def ≥ atk)
  leaves it standing (emergent durability — [DTR-2]).
- The object Unit **never counter-attacks, never dodges (forced hit), grants no EXP**, and is
  excluded from turn order / rout liveness / pair-up (the `is_destructible_object` quarantine).
- Snapshot round-trip restores broken state + current HP; an unbroken object re-spawns its Unit on
  load, a broken one does not and its terrain/`reveal_tiles` results are reapplied.
- `on_break` `reveal_tiles` flips the named span passable (bridge); `spawn`/`flag`/`loot` events
  are no-ops until their seams land.
