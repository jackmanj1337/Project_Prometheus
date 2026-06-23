---
Type: register
Status: RESOLVED 2026-06-21h
Last verified: 2026-06-23
Register: MET-1..9
Resolved-in: 2026-06-21h
---

# Map Events / Triggers Framework — Draft Plan + Open Questions Register

**Started:** 2026-06-21h
**Status:** [MET-1..9] **RESOLVED 2026-06-21h** — build-ready (all recommendations accepted).
**NEW general system.** A data-authored *trigger → action* framework: *"on `<trigger>` (e.g. unit
X dies), run `<typed action list>`."* Authored as `MapData.map_events: Array[Dictionary]`; a
`MapEventManager` matches `EventBus` signals → flag-guarded → deferred action run → fire-once latch
(`map_events_fired` in §2). v1 triggers: `unit_died`/`turn_reached`/`object_broken`; v1 actions:
`reveal_tiles`/`flag`/`spawn`. **DTR's `on_break` folds in as the `object_broken` action list.**
Unifies the action half DTR-5 started with a general trigger layer; `unit_died` is the seed trigger
the owner asked for.
**Source:** user question 2026-06-21h ("general hooks to trigger events on any specific unit's
death"). Converges with DTR-5's `on_break` event list + [CST-11] story-flip seam + DTR's
reinforcement-spawn forward sub-feature.
**Code:** `scripts/autoloads/EventBus.gd` (`unit_died`/`turn_changed`/`phase_changed`/
`combat_resolved` = the trigger substrate), `scripts/core/TurnManager.gd` (round counter, deferred
end-of-action pattern, `_on_unit_died`), `scripts/resources/ObjectiveCondition.gd` (existing
per-unit `unit_ids` watcher — for win/lose only), `scripts/resources/MapData.gd` (authoring home;
no event field today), `scripts/GameMap.gd` (init-only unit spawn), `scripts/autoloads/GameState.gd`
(`turn_number`; no flag store).
**Pattern:** mirrors §1 ICD / §2 CST / DCH / DTR. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

- **The engine substrate exists; the authoring layer does not.** `EventBus` already broadcasts
  `unit_died(unit)`, `turn_changed(turn_number)`, `phase_changed`, `combat_resolved`,
  `map_victory/defeat`, `unit_moved`. Today every reaction is **hardcoded in GDScript** (e.g.
  `TurnManager._on_unit_died` runs victory checks). There is no data-authored "on event → do X."
- **`ObjectiveCondition` is the closest precedent** — a data-authored Resource that watches
  `unit_ids` (`defeat_boss`/`protect`) and `tiles`/`turns`, but it feeds **only victory/defeat
  evaluation**, not arbitrary actions. Good model to mirror; should stay separate (see [MET-7]).
- **No flag store.** `GameState` has only debug-aid flags. A `flag` action (set) and flag-gated
  triggers (read) need a real campaign/map flag store — overlaps the [CST-11] story-flip seam.
- **No mid-map spawn seam.** `GameMap` instantiates units once at map start (TurnManager:
  "called by GameMap after units have spawned"). A `spawn` action needs a public spawn entry
  extracted from that init path. (This is exactly DTR-5's flagged reinforcement-spawn sub-feature.)
- **Deferred-timing precedent exists.** `TurnManager` already defers end-of-action work (victory
  checks, orphaned-support) to safe points — the same pattern actions should use ([MET-8]).

## 2. Draft plan

Author on `MapData.map_events` — each event = a **trigger** + an ordered **action list**:
```
MapEvent {
  id: String
  trigger: { type:"unit_died"|"turn_reached"|"object_broken"|"tile_seized"|…, …params }
  condition: { flag:String, … }      # optional guard (see [MET-4])
  actions: Array[Dictionary]         # the shared vocabulary, see [MET-3]
  once: bool = true                  # fire-once latch (see [MET-5])
}
```
A `MapEventManager` (autoload or map-scoped node) connects the `EventBus` substrate signals once,
matches fired signals against authored events, checks the guard, runs the action list at a safe
deferred point, and latches `once` events into the save. **DTR's `on_break` becomes the
`object_broken` trigger's action list — same action vocabulary, no parallel system** ([MET-9]).

## 3. Open questions register

### [MET-1] Authoring model — typed Resource vs Dictionary array  **[OPEN]**
- **A — A `MapEvent` Resource class** (mirrors `ObjectiveCondition`'s single-typed-resource
  inspector pattern), with `trigger`/`condition`/`actions`/`once` fields.
- **B — Plain `Array[Dictionary]` on MapData** (JSON-native, matches `enemy_placements`/
  `map_objects`).
- **Rec: B** — events are deeply nested (trigger + variable action list) and must round-trip
  through the §2 JSON save anyway; a Dictionary array matches `map_objects`/`enemy_placements`
  and the DTR `on_break` list already chosen, keeping ONE authoring style for the map-data layer.
  `DataManager` validates shape (as it does for the other dict arrays). Resource UX is nicer in
  the inspector but fights the JSON-save round-trip and splits the style.
- **Resolution:** **B (RESOLVED 2026-06-21h)** — `MapData.map_events: Array[Dictionary]`,
  `DataManager`-validated, matching `map_objects`/`enemy_placements`/DTR's `on_break`. One
  authoring style; clean §2 JSON round-trip.

### [MET-2] Trigger vocabulary v1 — which triggers ship first  **[OPEN]**
The substrate signals available: `unit_died`, `turn_changed`, `phase_changed`, `combat_resolved`,
`unit_moved`, `map_victory/defeat`, plus DTR's `object_broken`, seize/escape from objectives.
- **A — Seed set: `unit_died` + `turn_reached`** (the owner's ask + the most common scripting
  need), then add triggers as concrete maps need them.
- **B — Broad set up front** (unit_died, turn_reached, object_broken, tile_seized,
  unit_reached_tile, flag_set, phase_started).
- **Rec: A + `object_broken`** — ship `unit_died` (the request) + `turn_reached` (reinforcement
  waves) + `object_broken` (DTR convergence, [MET-9]). Each new trigger is a tiny adapter over an
  existing `EventBus` signal, added on demand; over-building the vocabulary before maps need it is
  speculative.
- **Resolution:** **A+ (RESOLVED 2026-06-21h)** — ship `unit_died` + `turn_reached` +
  `object_broken`; further triggers added on demand as thin adapters over existing `EventBus`
  signals.

### [MET-3] Action vocabulary v1 — which actions ship first  **[OPEN]**
- **A — Seeds with existing seams: `reveal_tiles` + `flag`** (both nearly free) + **`spawn`**
  (needs the [MET-8] seam) since reinforcements are the headline use.
- **B — Full set** (spawn, reveal_tiles, flag, loot, dialogue, change_objective, …).
- **Rec: A** — `reveal_tiles` reuses the DCH/DTR passability overlay; `flag` rides [MET-6]; `spawn`
  is the headline (reinforcements on death/turn). `loot` reuses DCH's path, `dialogue`/
  `change_objective` wait for their own systems. **This IS the vocabulary DTR's `on_break` shares.**
- **Resolution:** **A (RESOLVED 2026-06-21h)** — `reveal_tiles` + `flag` + `spawn` in v1
  (the shared `on_break` vocabulary); `loot`/`dialogue`/`change_objective` land with their seams.
- **FOW convergence (2026-06-21j):** the Fog-of-War register adds two consumers of this
  vocabulary. (1) **`reveal_tiles` is FOW's "closed room reveals on a map event" tool** — it
  writes into fog's persistent revealed set; no new action needed. (2) FOW `[FOW-7]` adds a new
  **`light`** action (light a brazier `map_object`, a fog vision source), and FOW `[FOW-2]`
  reserves a future **`set_fog`/`set_weather`** action (timed/"blizzard rolls in" weather on a
  `turn_reached` trigger). Add `light` to the action vocabulary when FOW builds; `set_fog` is a
  later fast-follow. See `fog_of_war_los_open_questions_2026-06-21.md` §2a + [FOW-7].
- **AIP gap-analysis cross-ref (2026-06-21k):** the AI-profiles register (§8 gap analysis) found
  three FE patterns that need MET growth, none scheduled yet: (1) **event/turn-driven aggression**
  — a candidate **`set_aggro`/`wake`** action (or have `territorial`/`tethered` honor a map-flag)
  so a `turn_reached`→event can wake/charge a group regardless of player proximity (the proximity-
  aggro ↔ event-aggro bridge); (2) a **`unit_hp_below` trigger** for "boss enrages at half HP" /
  summoner phases (current triggers are `unit_died`/`turn_reached`/`object_broken`); (3) confirm
  the **`spawn` action can flag "acts immediately"** for FE ambush spawns ([MET-8] spawn mechanism).
  See `ai_profiles_open_questions_2026-06-21.md` §8.
- **`set_ai` action — CONFIRMED REQUIREMENT (owner 2026-06-22c).** Promotes (1) above from a
  candidate to a required action: a **`set_ai`** action changes a unit's or group's AI **preset or
  individual axes** on an event trigger (e.g. "on turn 5 the `guard` squad becomes `grunt`"; "when
  the boss dies the survivors become `coward`"). `set_aggro`/`wake` is the narrow case (Activation
  axis only). Mechanically: it overrides the target's resolved `AISpec`; the AI planner reads the
  new spec on the next activation. **OPEN schema:** unit vs `group_id` target; whole-preset vs
  per-axis payload. **Now FIRST-BUILD, not deferred** — [AIP-8] (2026-06-22c) pulled event-driven
  aggression into the first AI build, so `set_ai` ships with the initial AI + MET work (alongside
  the existing `turn_reached`/`unit_died`/`flag` triggers that drive it). See
  `ai_profiles_open_questions_2026-06-21.md` §2b + [AIP-7]/[AIP-8]/[AIP-15].

### [MET-4] Trigger guards — optional flag/condition predicate  **[OPEN]**
Branching narrative needs "fire only if flag X set / turn ≥ N / objective Y still open."
- **A — Optional `condition` predicate** on each event (flag-set test + simple comparisons),
  evaluated when the trigger fires; false = skip without consuming `once`.
- **B — No guards v1** — events fire unconditionally on their trigger.
- **Rec: A (flag predicate only, v1)** — a single optional flag test is cheap and unlocks
  branching (route A vs route B reinforcements) for almost no cost; richer predicates added later.
  Depends on the [MET-6] flag store.
- **Resolution:** **A (RESOLVED 2026-06-21h)** — optional `condition` flag predicate per event;
  false = skip without consuming the `once` latch. Richer predicates added later.

### [MET-5] Fire-once + fired-state persistence (§2)  **[OPEN]**
A reinforcement wave must not re-trigger after a mid-map save/load.
- **A — `once:bool` (default true) + snapshot the fired-event id set** into the §2 save (a small
  `map_events_fired` array, sibling to `map_objects_state`).
- **B — No persistence** — events re-fire on reload (broken for suspend saves).
- **Rec: A** — fire-once is the common case and fired-state is a latched event like a looted
  chest; reserve `map_events_fired` in the §2 schema. `once:false` events (repeatable) skip the
  latch. This register's only §2 ask.
- **Resolution:** **A (RESOLVED 2026-06-21h)** — `once:bool` (default true) + snapshot the fired
  id set as `map_events_fired` in the §2 save (sibling to `map_objects_state`). `once:false`
  repeats, skips the latch.

### [MET-6] Flag store — scope + home  **[OPEN]**
The `flag` action and `condition` guards need a flag store.
- **A — Two scopes: map-flags (cleared per map) + campaign-flags (persist across maps)** on
  `GameState`/`CampaignData`, set/read by name.
- **B — One global flag dict.**
- **Rec: A** — most flags are map-local (this map's gate is open); some must persist (chapter X
  completed) for an overworld/branching campaign. Two scopes is the minimal honest model and
  aligns with [CST-11]'s story-flip seam + the §2 campaign save. Map-flags snapshot with the map;
  campaign-flags with the campaign save.
- **Resolution:** **A (RESOLVED 2026-06-21h)** — two scopes: map-flags (cleared per map, snapshot
  with the map) + campaign-flags (persist across maps, in the campaign save). Aligns with [CST-11]
  + §2.

### [MET-7] Relationship to `ObjectiveCondition` — unify or keep separate  **[OPEN]**
- **A — Keep separate.** `ObjectiveCondition` stays the win/lose evaluator; events are a separate
  authored list that can fire a `change_objective` action when that system lands.
- **B — Merge** objectives into the event framework (win/lose = events with a `win`/`lose` action).
- **Rec: A** — objectives have bespoke AND/OR per-group evaluation semantics (M16) that don't map
  cleanly onto fire-once triggers; merging risks regressing a working system. Let events *influence*
  objectives via a future `change_objective` action instead of absorbing them.
- **Resolution:** **A (RESOLVED 2026-06-21h, resolved to rec inline)** — keep `ObjectiveCondition`
  as the win/lose evaluator; events influence objectives via a future `change_objective` action.
  Its M16 AND/OR per-group semantics don't map onto fire-once triggers — don't merge.

### [MET-8] `spawn` mechanism + action timing  **[OPEN]**
- **Mechanism:** extract a public `GameMap.spawn_unit(placement)` from the init spawn path; the
  `spawn` action calls it (this resolves DTR-5's reinforcement-spawn forward sub-feature).
- **Timing:** when `unit_died` fires mid-combat, actions must NOT run inside the combat exchange.
  - **A — Defer to the next safe point** (after `combat_resolved` / end of the current action),
    reusing TurnManager's existing deferred-work pattern.
  - **B — Run immediately** in the signal handler (risks re-entrancy mid-combat/mid-anim).
- **Rec: A for both** — extract the spawn seam; run all actions at a deferred safe point. Newly
  spawned units join the current/next phase per a `spawn` param (immediate vs next-round).
- **Resolution:** **A for both (RESOLVED 2026-06-21h)** — extract a public
  `GameMap.spawn_unit(placement)` from the init path (resolves DTR-5's reinforcement-spawn
  sub-feature); run all actions at the next safe deferred point (after `combat_resolved`), reusing
  TurnManager's deferred-work pattern. Spawn param controls immediate-vs-next-round join.

### [MET-9] DTR convergence — fold `on_break` into this framework  **[OPEN]**
- **A — DTR's `on_break` becomes the `object_broken` trigger's action list** using this shared
  action vocabulary; the destructible register references this one for actions.
- **B — Keep DTR's `on_break` separate** (two action systems).
- **Rec: A** — this is the whole point: one action vocabulary, one runner. Update the DTR register
  to point here for `on_break` action semantics once this lands (DTR can still build first with a
  local action list, then migrate — note the seam).
- **Resolution:** **A (RESOLVED 2026-06-21h, resolved to rec inline)** — DTR's `on_break` becomes
  the `object_broken` trigger's action list on this shared runner. If DTR builds first, it uses a
  local action list and migrates to this runner when it lands — DTR register gets a pointer here.

## 4. Slice sketch (provisional)
1. `MapData.map_events` (Dictionary array) + `DataManager` validation + a `MapEventManager` that
   connects `EventBus` substrate signals and matches authored events; `unit_died` + `turn_reached`
   triggers; `flag` + `reveal_tiles` actions; flag store ([MET-6]). Test map: "boss dies → set flag
   + reveal tiles."
2. Flag-guard predicate ([MET-4]); fire-once latch + `map_events_fired` snapshot ([MET-5]).
3. `spawn` action + extracted `GameMap.spawn_unit` seam ([MET-8]); deferred-timing safe point.
4. `object_broken` trigger; migrate DTR's `on_break` onto the shared runner ([MET-9]).
5. (Later) `loot`/`dialogue`/`change_objective` actions + more triggers as maps need them.

## 5. Test notes
- Headless: authored "unit_died(id=boss) → [flag(gate_open), reveal_tiles(span)]" fires once when
  that unit dies; tiles flip passable; flag set; re-running the trigger does nothing (once-latch).
- Flag-guard: an event with `condition.flag=route_a` does not fire when the flag is unset.
- Persistence: fire an event, save mid-map, load → the event does NOT re-fire; spawned units and
  revealed tiles persist.
- `turn_reached(3)` fires a `spawn` wave on round 3; spawned units appear and act per the param.
