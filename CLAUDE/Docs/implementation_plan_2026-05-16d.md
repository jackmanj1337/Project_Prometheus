# Implementation Plan — Code Review 2026-05-16 (d) Fixes

Source: `CLAUDE/Code Reviews/code_review_2026-05-16d.md`
Scope: all 8 findings + the 3 test-coverage gaps from that review.
Status: **not started** — prepared for next session, execute top-to-bottom.

Baseline: 11 suites / 249 tests green (`bash run_tests.sh`). Every step below must
leave the suite green before its commit.

GDD cross-check done this session:
- GDD_02:76 — "All calculated values are **rounded down**." → confirms fort healing's
  `ceili` is a spec violation (Step 5 is a bug fix, not a judgment call).
- GDD_05 — Vantage "reorders attacks accordingly"; full pre-empt is the intended
  behavior (Step 1).

---

## Step 1 — [HIGH] Vantage dead-attacker bug

**File:** `scripts/core/CombatResolver.gd:536-537` (`resolve_combat`, attacker loop).

**Change:** add the actor-alive guard, mirroring the defender counter loop.
```gdscript
# Attacker's strikes
for _i in atk_strikes:
    if def_sim_hp <= 0 or atk_sim_hp <= 0:
        break
    var ex := _resolve_strike(attacker, defender, context, false, def_sim_hp, weapon_uses, broken)
    ...
```
`atk_sim_hp` is already declared at `:509` and decremented by the Vantage branch — no
new bookkeeping.

**Test (add to `scripts/tests/test_combat.gd`):** Vantage regression.
- Build a defender with `skills:["vantage"]`, a 100%-hit overkill weapon, range 1, fast
  enough to one-shot. Attacker with normal weapon, low HP.
- `resolve_combat(attacker, defender)` → assert `attacker_died == true`,
  `defender_died == false`, and **no exchange has `attacker == <attacker>`** (the dead
  attacker never swings). Confirm `exchanges.size()` equals the defender's strike count.
- Note: `_apply_vantage` requires DataManager + SkillHandler under `/root` — already set
  up in `test_combat._init()`. `vantage.tres` trigger is `on_combat_start`.

**Commit:** `Fix Vantage: dead attacker no longer swings after a counter-kill`

---

## Step 2 — [MEDIUM] preview_combat snapshot scope

**Files:** `scripts/skills/SkillHandler.gd` (`apply_trigger`),
`scripts/core/CombatResolver.gd` (`preview_combat`, `_collect_combat_modifiers`).

**Approach:** add a `dry_run` flag to `apply_trigger` (preferred over snapshotting all
units — makes the preview's read-only contract hold by construction).

1. `apply_trigger(unit, trigger, context, preview=false, skills_blocked=false,
   dry_run:bool=false)` — when `dry_run` is true, **skip both use-counter writes**
   (`unit.data.skill_use_counters[...]` at `:120-122` and `_combat_skill_uses[...]` at
   `:123-125`). The skill effect still runs so the forecast is accurate; only the
   counter persistence is suppressed.
2. `_collect_combat_modifiers(context, preview)` — thread a `dry_run` param through and
   pass it to every `apply_trigger` call inside. `preview_combat` passes
   `dry_run = true`; `resolve_combat` passes `false`.
3. Once `dry_run` covers `skill_use_counters`, `_snapshot_unit_state` /
   `_restore_unit_state` no longer need to carry `skill_use_counters` for previews —
   but **leave them in** (cheap, and they still guard `active_modifiers`/`hp`). Just
   drop the reliance, don't churn the snapshot.

**Test (add to `test_skill_item_handler.gd` or `test_combat.gd`):** give a unit a
use-limited skill (`max_uses_per_map = 1`), call `preview_combat` twice, assert
`unit.data.skill_use_counters` is unchanged; then `resolve_combat` once and assert it
incremented.

**Commit:** `Add dry_run to apply_trigger so combat previews never burn skill uses`

---

## Step 3 — [LOW batch] polish (one commit)

All small, independent, low-risk. Apply together.

3a. **HP bar max on level-up** — `scripts/units/Unit.gd:545-547` (`_increment_stat`,
`"hp"` branch):
```gdscript
"hp":
    data.max_hp += 1
    data.hp += 1
    if _hp_bar:
        _hp_bar.max_value = data.max_hp
        _hp_bar.value = data.hp
```

3b. **active_modifiers default type** — `scripts/autoloads/GameState.gd:230`
(`_restore_unit_data`): change `snap.get("active_modifiers", {})` →
`snap.get("active_modifiers", [])` (field is `Array[Dictionary]`, not Dictionary).

3c. **CombatResolver header comment** — `scripts/core/CombatResolver.gd:1-3`: reword
so the "no unit fields written until apply_combat_result()" claim is scoped to
HP/durability/EXP, and note that `on_combat_start`/`on_combat_end`/`on_damaged` skill
triggers DO mutate unit state (preview_combat snapshots around this).

3d. **_finish_action liveness guard** — `scripts/core/MapCursor.gd:503-504`: guard the
state write so a player unit that died mid-action isn't re-inserted into
`TurnManager._unit_states`:
```gdscript
if _turn != null and is_instance_valid(_selected_unit) \
        and _selected_unit.data != null and _selected_unit.data.hp > 0:
    _turn.set_unit_state(_selected_unit, TurnManager.UnitState.DONE)
```

3e. **Fort healing rounding** — `scripts/core/TurnManager.gd:47` (`_apply_fort_healing`):
GDD_02:76 mandates round-down. Change `ceili(...)` → `floori(...)` to match the global
rule and Renewal. Also replace Renewal's magic literal `0.10`
(`SkillHandler.gd:164`, `_apply_renewal`) with a named constant — add
`FORT_HEAL_FRACTION`-style `RENEWAL_HEAL_FRACTION` to `GameConstants`, or reuse one
shared `PERCENT_HEAL` constant if fort and Renewal are meant to share the 10% figure.

**Tests:** existing `test_unit_stats` (level-up) and `test_snapshot_coverage` should
still pass; add a focused assertion that fort healing on a 25-HP unit heals 2 (floor),
not 3 — check whichever suite covers `_apply_fort_healing` (likely none today; add to
`test_unit_stats` or a turn-manager test if one exists).

**Commit:** `Low-severity polish: HP bar refresh, restore default, fort rounding, liveness guard`

---

## Step 4 — [MEDIUM] consolidate the three pathfinding floods

**Files:** `scripts/core/GridManager.gd` (`get_movement_range`, `get_movement_path`),
`scripts/core/EnemyAI.gd` (`_flood_costs`).

**Change:** extract one primitive on `GridManager`:
```gdscript
# Dijkstra cost map from `start`. max_cost caps expansion (use INT_MAX for "whole map").
# ignore_occupants=true skips the enemy-blocks-traversal rule. blocker_unit is the unit
# whose team defines "enemy" for occupant checks. Returns {tile: cost}; if track_paths
# is true also populates the passed `came_from` dict.
func dijkstra_costs(start, max_cost, ignore_occupants, blocker_unit, came_from:={}) -> Dictionary
```
- `get_movement_range` → `dijkstra_costs(start, movement, false, unit)` then filter by
  `can_end_on_tile`.
- `get_movement_path` → `dijkstra_costs(start, movement, false, unit, came_from)` then
  reconstruct.
- `EnemyAI._flood_costs` → `grid.dijkstra_costs(start, INT_MAX, true, null)`; delete the
  EnemyAI copy.
- Pick **one** priority-queue strategy: keep the insertion-sorted heap from
  `_flood_costs` (better than the O(n²) linear-scan frontier), use it in the primitive.

**Risk:** behavior-visible refactor. Do it strictly behind the green suite —
`test_grid_manager`, `test_map_grid`, `test_enemy_ai` must stay green. Verify the
cap=INT_MAX + ignore_occupants path matches the old `_flood_costs` output (the heap vs
linear-scan change must not alter results, only speed).

**Commit:** `Consolidate movement/path/flood pathfinding into GridManager.dijkstra_costs`

---

## Step 5 — [TEST DEBT] deepen EnemyAI coverage

**File:** `scripts/tests/test_enemy_ai.gd` (currently 5 tests).

Add tests for:
- `_act` profile dispatch — a `passive` enemy holds position and only attacks an
  in-range player; a `basic` enemy moves+attacks; a `healer` enemy routes to
  `_act_healer`.
- `_try_staff_heal` — enemy with a healing staff heals the most-injured in-range ally;
  enemy with a non-staff weapon does nothing.
- `_choose_heal_move_tile` — picks the tile that puts the most-injured ally in range,
  tie-breaking on terrain bonus.
- `_flood_costs` (or its replacement `dijkstra_costs`) — real-grid cost map: costs grow
  with terrain, walls are unreachable.
- `_find_nearest` with a non-null `grid` — exercises the Dijkstra branch, not just the
  Manhattan fallback.

Use the existing `stub_script` pattern in the file; extend it with `data`/`ai_profile`
where a profile test needs it (or use real `Unit`/`UnitData` if the stub gets unwieldy).

**Commit:** `Expand EnemyAI test coverage: profiles, staff heal, heal positioning, flood`

---

## Step 6 — final verification

- `bash run_tests.sh` → all 11 suites green; test count should be ~249 + new tests.
- Update `CLAUDE/GDD/GDD_updates.md` if any fix changes documented behavior (the fort
  rounding correction is the only candidate — note it was already GDD-correct, code was
  not).
- Write session notes (`CLAUDE/Session Notes/2026-05-16i.md` or next letter) covering
  what landed and the commit list.

---

## Execution order rationale

1 first (the only shipped bug). 2 and 3 are independent and low-risk. 4 is the riskiest
(behavior-visible refactor) so it goes after the cheap wins and is isolated in its own
commit for easy revert. 5 last — coverage hardening, no production code change. Each
step is its own commit so any single change can be reverted in isolation.
