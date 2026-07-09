# GDD_08 — Enemy AI

**Status:** Active contract — split status per section (the basic/passive/healer profiles
are **Implemented**; the tactical scoring model, extra profiles, and enemy
generation/autolevel are **Planned / Target design / Not reviewed**, tracked in
`GDD_Adoption_Matrix.md`).
**Last verified:** 2026-07-09
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This chapter owns enemy AI behaviour, AI determinism/parity obligations, and AI
performance constraints. Combat math is owned by `GDD_02`; the EnemyAI autoload + faction
dispatch are owned by `GDD_01`/`GDD_02 §Turn Structure`. Enemy EXP gating is owned by
`GDD_02 §EXP` + `GDD_01 §CampaignRules Contract` (OPEN-4).

---

## Overview

Status: **Implemented** (basic close-and-attack AI); richer scoring is backlog
Last verified: 2026-06-13

Enemy AI lives in `scripts/core/EnemyAI.gd`, registered as the `EnemyAI` autoload.
`TurnManager.start_enemy_phase()` now dispatches AI **per acting faction**. For each
non-blue faction authored as `controller = "AI"`, it awaits
`EnemyAI.run_phase(grid, turn, faction_id)`, then advances to the next faction in the
map's authored `turn_order`.

Implemented behavior is selected by `UnitData.ai_profile`. The former closed
`match enemy.data.ai_profile` was replaced (build-slice steps 1-2 of
`ai_first_build_design_2026-06-22.md`) by the **AISpec composition seam**:
`AIProfileRegistry.resolve_ai_spec()` maps a profile id to an `AISpec`
(`activation`/`disposition`/`engagement`), and `EnemyAI._act()` dispatches through a
`disposition id -> handler` table. Boot validation (`DataManager`) now queries
`AIProfileRegistry.is_valid_profile()` instead of a closed `_VALID_AI_PROFILES`
const. Adding a profile is one registry entry + one disposition handler — no engine
`match` edit (`B5-AI-COMPOSITION`, invariant 1: "no behavior hardcoded in a match").

The remaining MVP axes — territorial/tethered/flee/seek_tile dispositions, the
`weakest` target policy, grouping, event/`set_ai` activation, and difficulty
overlays — are build-slice steps 3-6 and stay **Planned**; step 3 is gated on the
`ai_awake` save-slice (see `GDD_10` "Gated build items"). The handlers still plan and
execute inline; a pure `plan_action` (the action-preview dry-run + `[VAL]`
prerequisite) rides step 3.

> **MVP scope vs. design.** The implemented AI is deliberately simple: it moves toward
> the nearest hostile target and attacks the nearest target in range — there is no
> kill-score heuristic and no counter-damage avoidance yet. The richer
> scoring/positioning model and the extra profiles at the end of this document are
> Phase 2 work. This document describes the **implemented** behaviour first, then the
> design backlog.

---

## Architecture

```gdscript
# scripts/core/EnemyAI.gd  (autoload)
extends Node

# Awaited by TurnManager.start_enemy_phase() for one acting faction at a time.
func run_phase(grid: GridManager, turn: TurnManager, faction_id: String) -> void:
    var gs := get_node_or_null("/root/GameState")
    if gs == null or grid == null or faction_id == "":
        return
    for enemy in gs.get_living_units_of(faction_id):
        if is_instance_valid(enemy):
            await _act(enemy, grid, turn)

# AISpec composition seam (replaced the closed `match enemy.data.ai_profile`).
func _act(enemy: Node, grid: GridManager, turn: TurnManager) -> void:
    var spec := AIProfileRegistry.resolve_ai_spec(enemy.data.ai_profile)
    var handler: Callable = _disposition_handlers().get(spec.disposition, Callable())
    if not handler.is_valid():
        handler = _disposition_pursue_unit  # unreachable; mirrors the old `_: pass`
    await handler.call(enemy, grid, turn, faction_id)

# The single seam a new behavior registers on — no engine `match` edit.
func _disposition_handlers() -> Dictionary:
    return {
        AIProfileRegistry.DISP_PURSUE_UNIT: _disposition_pursue_unit,  # was "basic"
        AIProfileRegistry.DISP_HOLD_TILE:   _disposition_hold_tile,    # was "passive"
        AIProfileRegistry.DISP_HEAL:        _disposition_heal,         # was "healer"
    }
```

`ai_profile` is stored on `UnitData` (`@export var ai_profile: String = "basic"`) and
set per unit via `MapData.enemy_placements`. Hostility is resolved through
`GameState.are_hostile()` rather than assuming every non-blue unit is an enemy to
every other non-blue unit.

Target AISpec data lives with unit/map/faction/campaign authoring and is validated
against the registry at load. `basic`, `passive`, and `healer` become developer-provided
presets implemented by composing the shared planner primitives.

---

## Implemented Profiles

Status: **Implemented** (`basic`, `passive`, `healer`)
Last verified: 2026-06-13

### `"basic"` — the default

1. Find the nearest **hostile** unit by **real pathfinding cost** — a whole-map Dijkstra
   flood from the enemy's tile (`GridManager.dijkstra_costs`), falling back to
   Manhattan distance only if every target is walled off. The hostile list excludes
   any unit parked at `PairUpRegistry.OFF_MAP_TILE` (a paired support, or any
   role-desynced off-map unit) so the AI never targets or paths toward the off-grid
   sentinel — which clamps to the top-left and made enemies beeline to (1,1).
2. Choose a destination from the enemy's movement range (`_choose_move_tile`):
   prefer a tile it can attack a hostile unit from, picking the one closest to the
   nearest target; if no attack tile is reachable, pick the reachable tile that
   minimises Manhattan distance to the nearest target.
3. Move there (`TurnManager.record_move_start` + `Unit.move_along_path`), then mark
   the unit `MOVED`.
4. If any hostile unit is attackable from the new tile, attack the nearest one via
   `CombatResolver.resolve_combat()` + `apply_combat_result()`. If the enemy instead
   carries a healing staff (and has no attack target), fall back to a staff heal.
5. Mark the unit `DONE`.

The basic profile does **not** score targets, avoid counter-damage, or stop short of
a hostile unit's threat range — it closes on and attacks the nearest reachable target.

### `"passive"`

Holds position — it never moves. If a hostile unit is already within its weapon range it
attacks the nearest one; then it marks `DONE`. Used for stationary guards and
(Phase 2) dormant reinforcements.

### `"healer"`

Moves toward injured same-alliance allies and heals. `_choose_heal_move_tile` picks the tile that
brings the most-injured ally into staff range (tie-broken by terrain DEF + Dodge for
safer positioning), moves there, then heals via `Unit.perform_staff_heal()`. A healer
never attacks.

---

## Combat Forecast — `preview_combat()`

`CombatResolver.preview_combat(attacker, defender)` is the pure, side-effect-free
forecast (no RNG, no HP/EXP/durability changes — it snapshots and restores unit
state). The basic profile does **not** currently consult it for target scoring, but
it is available for the Phase 2 scoring model and is what the attack-preview UI uses.
See GDD_01 → CombatResolver for its return shape.

---

## Execution Timing

Combat resolves in a single frame. `Unit.move_along_path` animates at the
configured movement speed (0.12 s/tile by default, 0 when instant).
`EnemyAI._focus_camera()` also pauses before each acting unit: 0.25 seconds at
normal speed and 0.12 seconds at fast speed. Instant movement skips that delay.

---

## Future AI Profiles (Phase 2+)

Status: **Planned** (separate tactical-AI task); enemy generation/autolevel **Not reviewed**
Last verified: 2026-06-13

Designed but not implemented. These are profile presets or compositions over the AI
registry, not future `_act()` switch arms. Add validation and behavior tests with each
profile/primitive.

| Preset/profile | Behaviour |
|---|---|
| `"territorial"` | Attacks any hostile unit that enters its patrol radius; otherwise stays put |
| `"guard_tile"` | Never leaves a designated tile; attacks hostile units that come in range |
| `"aggressive"` | Like basic but ignores the counter-damage penalty in scoring |
| `"boss"` | Like basic but with terrain-optimal positioning; uses items |

### Phase 2 Scoring Model (design backlog)

When the basic profile is upgraded in the separate tactical-AI task, target selection
uses the `[VAL]` scorer: an authorable F16/REQ term tree over engine forecast
term-sources such as expected damage, would-kill, counter-damage, exposure, and target
value. Nearest/weakest/aggressive behaviors become shipped scoring presets. Until then
the AI uses the nearest-target rule above.

---

## AI Determinism & Parity

Status: **Target design** (parity obligations; binding once `RngService` lands — RNG-4)
Last verified: 2026-06-13

### Summary
AI decisions must be reproducible so replay, rewind, suspend, and host-authoritative
online play stay consistent.

### Specs
- **Deterministic decisions.** AI move/target selection must be a pure function of the
  snapshotted game state plus the deterministic event stream. Any AI dice (none today) must
  draw from `RngService` in canonical order, never `randi()` (GDD_01 §Determinism).
- **Tie-break stability.** Target/destination tie-breaks use stable ordering (pathfinding
  cost, then a deterministic key) so the same state always yields the same action — no
  dependence on iteration/hash order.
- **Online parity (RNG-4, post-1.0, M15B).** In online play the **host simulates AI** and
  broadcasts results through the `resolve_combat()`/`apply_combat_result()` + snapshot
  seams; clients never run a divergent AI. Determinism guarantees are engine-local.
- **EXP parity (OPEN-4).** Enemy/AI EXP follows `CampaignRules.exp_gaining_factions`;
  the shipped preset is Blue + Green, Red none — owned by GDD_02 §EXP / GDD_01
  §CampaignRules Contract.

### Anchors
- Code: `scripts/core/EnemyAI.gd`; target `scripts/autoloads/RngService.gd`
- Decisions: RNG-4, OPEN-4
- Owner of the determinism contract: GDD_01 §Determinism, Snapshot & Online Contract

---

## Performance Constraints

Status: **Implemented** (project budget) + **Target design** (scaling guardrails)
Last verified: 2026-06-13

### Summary
The AI must resolve a faction phase within an acceptable frame/time budget on the largest
authored maps.

### Specs
- **Per-unit pathfinding:** the basic profile runs a whole-map Dijkstra flood
  (`GridManager.dijkstra_costs`) from each acting unit to find the nearest hostile by real
  cost, with a Manhattan fallback only when every target is walled off. Cost scales with
  map size × acting units; authored maps are tested through 42×26.
- **Frame atomicity:** combat resolves within one frame; movement animates at the
  configured speed; `_focus_camera()` pauses 0.25 s (0.12 s fast, 0 instant) before each
  acting unit for readability.
- **Target design (scaling):** if larger maps or denser factions stress the budget, cache
  per-phase flood results / cap re-floods rather than per-unit recompute. Any optimization
  must preserve AI Determinism above (identical decisions).

### Anchors
- Code: `scripts/core/EnemyAI.gd` (`run_phase`, `_choose_move_tile`, `_focus_camera`),
  `scripts/core/GridManager.gd` (`dijkstra_costs`)
- Owner of grid/pathfinding: GDD_01 §GridManager

---

## Enemy Generation & Autolevel

Status: **Open decision** (corpus stat-block adoption) — project enemies use static stat blocks
Last verified: 2026-06-13

### Specs
- **Implemented:** map enemies are authored `UnitData` `.tres` with static stat blocks at
  their level (no level-up rolls); see GDD_06 Map 001 (`stat = base + floor(growth% ×
  (N−1))`).
- **Not reviewed:** corpus enemy generation / autolevel adoption is unreviewed; resolve at
  the enemy-generation task. Class/stat ownership stays in GDD_03.

### Anchors
- Decisions: — (enemy generation row, `GDD_Adoption_Matrix.md`)
- Owner of class/stat data: GDD_03; authored placements: GDD_06

---

## Testing the AI

Status: **Implemented** (profile coverage); scoring tests **Planned**
Last verified: 2026-06-13

`scripts/tests/test_enemy_ai.gd` covers the AI profiles. Behaviour checklist:

- [x] A melee unit moves adjacent to the nearest hostile unit and attacks
- [x] A ranged unit attacks a hostile unit from range
- [x] An enemy with no target in range moves toward the nearest hostile unit
- [x] A `passive` enemy holds position and only attacks an already-in-range hostile unit
- [x] A `healer` enemy moves to reach an injured ally and heals it
- [x] A defender with a ranged weapon cannot counter a melee attacker out of range
- [x] AI phases hand back to the next authored faction and eventually back to blue
- [ ] Kill-priority target scoring — Phase 2 (not yet implemented)
- [ ] Enemy stops short of a hostile threat range — Phase 2 (not yet implemented)
