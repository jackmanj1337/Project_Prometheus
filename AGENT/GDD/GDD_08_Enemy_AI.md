# GDD_08 — Enemy AI

---

## Overview

Enemy AI lives in `scripts/core/EnemyAI.gd`, registered as the `EnemyAI` autoload.
`TurnManager.start_enemy_phase()` now dispatches AI **per acting faction**. For each
non-blue faction authored as `controller = "AI"`, it awaits
`EnemyAI.run_phase(grid, turn, faction_id)`, then advances to the next faction in the
map's authored `turn_order`.

Each enemy's behaviour is selected by its `UnitData.ai_profile` string. The dispatcher
(`_act()`) reads that string and calls the matching routine — adding a new profile is
just a new `match` branch plus a new function.

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

# Dispatch on ai_profile; each routine marks the unit DONE when finished.
func _act(enemy: Node, grid: GridManager, turn: TurnManager) -> void:
    match enemy.data.ai_profile:
        "passive": await _act_passive(enemy, grid, turn)
        "healer":  await _act_healer(enemy, grid, turn)
        _:         # "basic" — the default; standard close-and-attack logic
            ...
```

`ai_profile` is stored on `UnitData` (`@export var ai_profile: String = "basic"`) and
set per unit via `MapData.enemy_placements`. Hostility is resolved through
`GameState.are_hostile()` rather than assuming every non-blue unit is an enemy to
every other non-blue unit.

---

## Implemented Profiles

### `"basic"` — the default

1. Find the nearest **hostile** unit by **real pathfinding cost** — a whole-map Dijkstra
   flood from the enemy's tile (`GridManager.dijkstra_costs`), falling back to
   Manhattan distance only if every target is walled off.
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

MVP combat is **instant** — there is no per-tile pause, no per-enemy pause, and no
combat animation. `Unit.move_along_path` animates movement at the player's configured
speed (`SettingsManager.get_movement_speed_seconds()` — 0.12 s/tile by default, 0 when
"instant"); combat itself resolves in a single frame. Pacing pauses and combat
animations are a Phase 2 polish item; when added, their durations should be constants
at the top of `EnemyAI.gd`.

---

## Future AI Profiles (Phase 2+)

Designed but not implemented. Register them in `_act()`'s `match` block when ready.

| Profile | Behaviour |
|---|---|
| `"territorial"` | Attacks any hostile unit that enters its patrol radius; otherwise stays put |
| `"guard_tile"` | Never leaves a designated tile; attacks hostile units that come in range |
| `"aggressive"` | Like basic but ignores the counter-damage penalty in scoring |
| `"boss"` | Like basic but with terrain-optimal positioning; uses items |

### Phase 2 Scoring Model (design backlog)

When the basic profile is upgraded (M14 stage 4), target selection should score each
reachable target with `preview_combat()` — prioritising guaranteed kills, then
low-HP targets, then expected damage, penalised by the counter-damage the enemy would
take. Until then the AI uses the nearest-target rule above.

---

## Testing the AI

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
