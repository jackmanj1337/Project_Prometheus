---
Role: dated
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-03
---

# Band 6 Destructible Terrain Implementation Plan

**Started:** 2026-07-03.

**Track IDs:** `B6-DTR`.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 6 rows. Drafted from the RESOLVED register `[DTR-1..8]`
([`destructible_terrain_open_questions_2026-06-21.md`](../registers/destructible_terrain_open_questions_2026-06-21.md)),
confirmed **in v1** by the owner (2026-07-03d).

## Purpose

Build breakable walls / fellable trees / shatterable crystals as **one generic
breakable** backed by per-instance data (`[DTR-1]` A). The core shape: a breakable
is a **real `Unit` in disguise, quarantined from the roster** (`[DTR-3]`), taking
the **full unit damage pipeline** with a forced hit and no counter (`[DTR-2]`);
**anything breaks anything**, differentiated purely by HP + Def durability
(`[DTR-4]` B); on break it flips terrain and fires a **general `on_break` event
list** (`[DTR-5]` B+). It is a **fast-follow on Doors & Chests (DCH)** — rides the
same unified `map_objects` model, runtime passability overlay, and
`map_objects_state` snapshot, so it adds **zero new save schema**.

The `on_break` list is the extensible author contract ([EXT]) — new break results
(bridge/spawn/loot/flag) are typed events, not engine edits.

This is a build plan only. It does not authorize starting before the gates land.

## Scope

1. **Object-Unit + roster quarantine (`[DTR-1]` A, `[DTR-3]`).** A
   `type:"breakable"` `map_objects` entry that spawns a real `Unit` (weaponless,
   immobile, neutral faction, forced-hit) tagged `is_destructible_object`, skipped
   by every roster consumer.
2. **Targeting + break via the full pipeline (`[DTR-2]`/`[DTR-4]`).** A
   `get_breakables_in_range` sibling to `get_attackable_enemies_from_tile`; the
   existing `attack` verb resolves through `CombatResolver` against the object's HP
   — full formula (might, triangle, effectiveness, crit, skills, terrain Def/Res),
   forced hit, no counter, no EXP. Any weapon works; durability is emergent (Def ≥
   atk ⇒ 0 damage ⇒ can't break it).
3. **On break (`[DTR-5]` B+).** Free the object Unit, flip the passability overlay
   to `reveals_terrain`, then run `on_break: Array[Dictionary]` — v1 wires
   `reveal_terrain` + `reveal_tiles` (bridge); `spawn`/`flag`/`loot` are typed
   events stubbed until their seams land.
4. **Persistence (`[DTR-8]` A).** `broken` + current HP latch into DCH's
   `map_objects_state`. Zero new save field.

## Non-Goals

- **No `break_with` gating** (`[DTR-4]`) — anything breaks anything; no allow-list.
- **No LoS / `blocks_los` field** (`[DTR-6]`) — not even reserved; sight-occlusion
  is entirely FOW's call, revisited there (authored maps accept a re-touch then).
- **No AI breaking** (`[DTR-7]`) — enemies path around destructibles (pathfinding
  already routes around blocked tiles); an enemy-breaker/siege behavior is a later
  AIP profile.
- **No reinforcement-spawn seam in v1** (`[DTR-5]`) — the `spawn` event is a typed
  no-op until the mid-map spawn seam lands (today `enemy_placements` is
  initial-only); `flag` waits on the `[CST-11]` story-flip seam; `loot` reuses DCH's
  loot-to-opener path when wired.
- **Not before DCH** — DTR is a fast-follow on the DCH `map_objects` build.

## Source Docs

- [`destructible_terrain_open_questions_2026-06-21.md`](../registers/destructible_terrain_open_questions_2026-06-21.md)
  (`[DTR-1..8]` RESOLVED — generic A, full-pipeline forced-hit, real-unit quarantine,
  anything-breaks-anything B, `on_break` event list B+, no-LoS, no-AI, `map_objects_state`
  A) + §4 slice sketch + §5 test notes.
- DCH register (doors/chests) — the unified `map_objects` model + runtime passability
  overlay + `map_objects_state` snapshot this rides (`[DCH-2]`/`[DCH-6]`).
- MET register — DTR's `on_break` list is the `object_broken` trigger's action list
  on the shared MET runner (`reveal_tiles`, `spawn` via `[MET-8]`, `flag`).

## Decisions Not To Reopen

- `[DTR-1]` A: one generic `type:"breakable"` with `subtype` (wall/tree/crystal) —
  data, not three parallel systems.
- `[DTR-2]`: full unit damage pipeline against an HP pool, **forced hit, no
  counter, no EXP**; emergent durability via HP + Def.
- `[DTR-3]`: a **real `Unit`** quarantined by `is_destructible_object` (skips turn
  order, rout liveness, EXP-on-kill, pair-up/support/rescue, and the unit-roster
  save — it persists via `map_objects_state`, not the roster).
- `[DTR-4]` B: anything breaks anything; no gating field.
- `[DTR-5]` B+: `reveals_terrain` required, plus a general typed `on_break` event
  list; v1 wires terrain + `reveal_tiles`.
- `[DTR-6]`: no `blocks_los`, not reserved.
- `[DTR-7]` A: no AI breaking in v1.
- `[DTR-8]` A: `broken` + HP latch into `map_objects_state`; zero new save field.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates:

- **`B4-MAP-OBJECTS` (DCH)** — the hard gate. DTR reuses ~80% of DCH slice 1
  (`map_objects`, passability overlay, `map_objects_state`). **Walk & build after
  DCH.**
- **`B2-DEATH-LIFECYCLE`** — the object Unit reaching 0 HP frees it through the
  death/lifecycle path (quarantined: no EXP, no permadeath ledger). Confirm the
  lifecycle owner honors `is_destructible_object`.
- **`B3-MET`** — the `on_break` list migrates to the shared MET runner's
  `object_broken` trigger. DTR may build first with a **local action list**, then
  migrate when MET lands (register note).
- Nothing in DTR is buildable against the live tree today — there is no
  `map_objects` model yet (grep clean); it is drafted against the planned DCH API,
  same caveat as the other Band 6 plans.

## Existing Code Touchpoints

Verified 2026-07-03 against the live tree:

- **`GameMap._CHAR_TO_SOURCE` (l.6, default source 6)** — `"W"` wall is a static
  impassable tile in the immutable `grid` today (no HP, no per-tile object). A
  breakable is the `map_objects` replacement for authored breakable tiles.
- **`GridManager.get_attackable_enemies_from_tile` (l.444)** — targets hostile
  **units** only; slice 2 adds a `get_breakables_in_range` sibling. Consumers to
  extend: `EnemyAI.gd:119,143` (leave — AI doesn't break, `[DTR-7]`) and
  `MapCursorTargeting.gd:72` (add breakables to the player's target enumeration).
- **`scripts/core/CombatResolver.gd`** — the unit-vs-unit pipeline; the object Unit
  is duck-typed as a defender (HP, forced hit, no counter). The AttackPreview
  forecast reuses it unchanged.
- **`scripts/resources/WeaponData.gd`** (`combat_family`, `mt`, `effect_tags`) —
  already expresses damage; no `break_with` gating added (`[DTR-4]` B).
- **`scripts/resources/MapData.gd`** (l.19 terrain-string grid; save-TODO names
  "shifting terrain / destructible tiles") — the save-TODO this feature closes.
- **No `map_objects` / `is_destructible_object` in code yet** (grep clean) —
  drafted against the planned DCH API.
- Tests to create/extend: new `test_destructible_terrain.gd` (target/break/
  quarantine/emergent durability), `test_snapshot_coverage` (broken + HP round-trip),
  `test_combat_resolver` (forced-hit no-counter object defender).

## Slice 1 - Object-Unit + Quarantine

**Goal:** a breakable spawns a real Unit skipped by every roster consumer — the
main risk surface.

Files to touch:

- the `map_objects` model + `DataManager` validation (DCH-owned)
- an "object" `UnitData` resource (weaponless, immobile, neutral, forced-hit)
- every "for each unit" roster iteration site (add the skip guard)
- `scripts/tests/test_destructible_terrain.gd` (new)

Implementation steps:

1. Add `type:"breakable"` to `map_objects` — `{subtype, object_unit, reveals_terrain,
   on_break, broken}`; HP/Def/Res live on the spawned object Unit. `DataManager`
   validation.
2. At map-load, spawn the object Unit and tag it `is_destructible_object`.
3. **Enumerate every "for each unit" iteration** (turn order/activation, rout
   liveness, EXP-on-kill, pair-up/support/rescue, unit-roster save) and add the skip
   guard. *This is the main risk surface — build note `[DTR-3]`.*

Tests:

- The object Unit is excluded from turn order, rout liveness, EXP, and pair-up.
- It persists via `map_objects_state`, not the unit roster.

F1 obligations: the breakable persists via `map_objects_state` (DCH's array) — no
new field; confirm the DCH snapshot covers it.

DoD#1 obligations: update `GDD_06` (destructible terrain) when slice 2/3 make it
player-visible.

## Slice 2 - Targeting + Break Through the Full Pipeline

**Goal:** attack a breakable like a unit that can't dodge or counter.

Files to touch:

- `scripts/core/GridManager.gd` (`get_breakables_in_range`)
- `scripts/core/MapCursorTargeting.gd` (l.72 — add breakables to enumeration)
- `scripts/core/CombatResolver.gd` (forced-hit / no-counter object path)
- `scripts/tests/test_destructible_terrain.gd`

Implementation steps:

1. `get_breakables_in_range(unit, tile)` sibling to
   `get_attackable_enemies_from_tile`, returning in-range unbroken breakables.
2. The existing `attack` verb resolves through `CombatResolver` against the object
   Unit's HP: **full formula** (might, triangle, effectiveness, crit, skills, terrain
   Def/Res), **forced hit** (never dodges), **no counter**, **no EXP**. Any weapon
   works (`[DTR-4]` B). AttackPreview reused.
3. Emergent durability: a weapon doing 0 damage (Def ≥ atk) leaves it standing.

Tests:

- A unit in range sees the `attack` verb on a breakable; resolving runs the full
  formula against HP; any weapon chips it.
- The object never counters, never dodges (forced hit), grants no EXP.
- A 0-damage weapon leaves it standing (emergent durability, `[DTR-2]`).

F1 obligations: current HP latches into `map_objects_state` (slice 4).

DoD#1 obligations: update `GDD_06` + flip `GDD_10`.

## Slice 3 - On Break + `on_break` Event List

**Goal:** at 0 HP, free the object, flip terrain, run the event list.

Files to touch:

- the break/lifecycle handler + passability overlay flip
- the `on_break` runner (local list, migrates to MET's `object_broken` trigger)
- `scripts/tests/test_destructible_terrain.gd`

Implementation steps:

1. Object Unit at ≤0 HP → free it, flip the passability overlay to
   `reveals_terrain`.
2. Run `on_break: Array[Dictionary]` of typed events. v1 wires `reveal_terrain` +
   `reveal_tiles` (bridge — the same passability machinery run in reverse over a
   span). `spawn`/`flag`/`loot` are typed **no-ops** until their seams land
   (`[DTR-5]`).
3. Build the runner as a **local action list** now; migrate to the shared MET runner
   (`object_broken` trigger) when MET lands.

Tests:

- Reaching ≤0 HP frees the object, flips the tile to `reveals_terrain`, runs
  `on_break`.
- `reveal_tiles` flips the named span passable (bridge); `spawn`/`flag`/`loot` are
  no-ops until their seams land.

F1 obligations: none new (results reapply from `map_objects_state` on load).

DoD#1 obligations: update `GDD_06` (on-break events) + flip `GDD_10`; add
`object_broken` / `light`-style entries to the MET action list when migrated.

## Slice 4 - Persistence (map_objects_state)

**Goal:** broken state + partial HP survive save/load; zero new field.

Files to touch:

- the DCH `map_objects_state` snapshot/restore
- `scripts/tests/test_snapshot_coverage.gd`

Implementation steps:

1. Snapshot `broken` + current HP into `map_objects_state` (`[DTR-8]` A).
2. On load: unbroken objects re-spawn their object Unit; broken ones do not, and
   their `reveals_terrain` / `reveal_tiles` results are reapplied.

Tests:

- Snapshot round-trip restores broken state + current HP; an unbroken object
  re-spawns its Unit, a broken one does not and its terrain results reapply.

F1 obligations: `broken` + HP ride DCH's reserved `map_objects_state` array — no new
schema (flag confirmation in the DCH plan).

DoD#1 obligations: update `GDD_06` + flip `GDD_10`.

## Slice 5 - Fast-Follows (Not v1, Documented)

Reserved, not built now (`[DTR-5]`/`[DTR-7]`): the mid-map reinforcement-`spawn`
seam, `flag` via the `[CST-11]` story-flip seam, `loot` via DCH's loot-to-opener
path, and the enemy-breaker AIP profile (`[DTR-7]` B). LoS occlusion is explicitly
**not** handled here — deferred wholesale to FOW (`[DTR-6]`). The `on_break` list is
the stable contract, so authored maps never need re-touching as these land.

## Implementation Commit Order

1. Slice 1 object-Unit + quarantine (the risk surface — enumerate roster guards).
2. Slice 2 targeting + break through the full pipeline.
3. Slice 3 on-break + `on_break` event list (local runner, MET migration later).
4. Slice 4 persistence via `map_objects_state`.

All slices trail **`B4-MAP-OBJECTS` (DCH)** — the hard gate. Slice 3's `on_break`
runner migrates to `B3-MET` when it lands.

## Verification Checklist

Same as the Band 2/3/4/5 plans. Run after each implementation slice:

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
