# Recruit + Any-Faction Reassignment — Implementation Plan

**Status:** Planned (approved 2026-06-15; implementation deferred)
**Last verified:** 2026-06-15
**Authority:** GDD_10 §1.0 Definition (D-D campaign prerequisites); GDD_03 §Units; M14 Faction System
**Depends on:** `campaign_rules_save_load_plan_2026-06-15.md` (roster persistence for recruited units)

## Context

The third D-D prerequisite is a **recruit mechanic** (an ally/enemy unit becomes a
player unit). Per the explicit requirement, the foundation is a **generalized
any-faction → any-faction reassignment primitive** — recruit is just the
player-facing specialization that reassigns a unit to `blue` *and* persists it into
the roster. The M14 faction system already models units by faction id, so this is a
runtime mutation on top of existing data.

### Decision taken (2026-06-15)
**Generalized `reassign_faction` primitive + recruiter-talks-to-target** player flow:
build the primitive (scriptable + debug, works between any two faction ids), plus a
player **Recruit/Talk** action gated by per-unit recruit data (a named recruiter must
reach the recruitable target). Classic FE recruit conversations, data-authored.

### Adopted defaults (not asked)
- **Persistence split:** recruiting to `blue` appends the unit's `UnitData` to
  `player_roster` (so it survives via the campaign save). A *generic* reassignment
  (e.g. `blue→red`, `green→yellow`) is **runtime/map state only** — it is captured by
  the deferred mid-battle suspend save, not the between-map campaign save.
- Reassigning a **paired** unit (Pair Up) **separates** the pair first (safest;
  matches the M9 "pair-up is campaign-rule" scoping).
- A recruited unit is marked so it can't be re-recruited.

## Key findings from exploration

- **`Unit.team: String`** is the faction id, set once in `Unit.initialize(...)`
  (`scripts/units/Unit.gd:31`) and visualized by `apply_faction_visual(map_data)`
  (reads `MapData.factions` colors). There is **no runtime team-change path today** —
  that's the gap.
- **`GameState._units_by_faction`** buckets units by id, maintained by
  `register_unit` / `unregister_unit` (`scripts/autoloads/GameState.gd:167`, `:181`) —
  reassignment must move a unit between buckets through these.
- **`FactionData.controller`** ("AI" / player) drives who activates a faction
  (`scripts/resources/FactionData.gd:34`); once a unit's `team` changes, the existing
  TurnManager faction dispatch makes it act under the new faction's controller — no
  scheduler change needed.
- **`UnitData.can_seize: bool`** (`scripts/resources/UnitData.gd:51`) is the existing
  per-unit tag precedent to mirror for recruit data.

## Design

### Part 1 — the primitive (any faction → any faction)
`GameState.reassign_unit_faction(unit: Node, new_faction_id: String) -> bool`:
1. Reject if `new_faction_id` unknown for the map / equal to current team.
2. If the unit is in a Pair Up, separate it first (via `PairUpRegistry`).
3. `unregister_unit(unit)` → set `unit.team = new_faction_id` → `register_unit(unit)`
   (moves it between `_units_by_faction` buckets).
4. `unit.apply_faction_visual(map_data)` to re-tint.
5. Emit a new `EventBus.unit_faction_changed(unit, old, new)` so HUD/objectives react.
The unit now activates under the new faction's `controller` automatically. This is the
scriptable/debug tool — usable from map events and a debug command, satisfying the
"swap units between any factions" requirement directly.

### Part 2 — recruit (player-facing specialization to `blue`)
- **Recruit data on `UnitData`:** `@export var recruitable_by: String = ""` (a
  recruiter `unit_id`; empty = not recruitable) and a runtime `recruited: bool`.
  Mirror the `can_seize` authoring pattern.
- **Action:** a `Recruit` (Talk) entry in `ActionMenu`, shown when the acting player
  unit's `unit_id == target.recruitable_by` and the target is adjacent and hostile/green.
  On confirm: `reassign_unit_faction(target, "blue")`, append the target's `UnitData`
  to `GameState.player_roster` (idempotent — guarded by `recruited`), set
  `recruited = true`, emit a recruit event for UI/log.
- **Persistence:** because the recruited unit is now in `player_roster`, the campaign
  save (save/load plan) carries it forward; benching/deployment then applies next map.

## Tests (headless, glob-discovered)
- **`test_faction_reassignment.gd`** (new): `reassign_unit_faction` moves the unit
  between `_units_by_faction` buckets, updates `team`, and emits the event; reassigning
  to an unknown id is rejected; reassigning a paired unit separates the pair first;
  round-trips A→B→A cleanly.
- **`test_recruit.gd`** (new): a recruiter adjacent to its `recruitable_by` target can
  recruit → target becomes `blue`, is appended to `player_roster` exactly once, and
  `recruited` blocks a second recruit; a non-matching recruiter sees no Recruit action;
  a recruited unit persists through a `SaveManager` round-trip.
- Behavior-neutral guard: existing faction/turn/AI tests stay green (no scheduler
  change); `ActionMenu` tests still pass with the new gated entry.

## Documentation (DoD#1)
- GDD_03 §Units: `recruitable_by` + `recruited` fields; recruit flow.
- GDD_08 / GDD_02: faction reassignment primitive + the Recruit/Talk action.
- GDD_07 §UI: the Recruit action affordance + gating.
- GDD_10: flip the D-D "recruit mechanic" prerequisite to Implemented; note the
  generalized reassignment primitive. Bump `Last verified`.
- DoD#2: candidate check — "`recruitable_by` references a real roster/enemy unit_id"
  in `DataManager.validate_unit_data`; add if ratified.

## Out of scope
- Recruit *conversations* (dialogue/cutscene) — only the mechanical reassignment.
- Persisting transient non-blue reassignments (rides with the deferred mid-battle
  suspend save).
- Auto-recruit on conditions, mass/event recruitment scripting beyond the primitive.

## Verification
- Headless `bash run_tests.sh` green incl. the two new suites.
- Live: a map with a recruiter + a recruitable green/red unit → bring the named
  recruiter adjacent → Recruit action appears → use it → target turns blue, acts on the
  player's phase, and is in the roster after the map; a debug reassignment swaps any
  unit to any faction and it re-tints + acts under the new controller.
