# Code Review — 2026-05-16 (d)

Reviewer: Claude
Codebase: ~7,150 lines of GDScript (30 source files + 11 test suites), Godot 4
turn-based tactics RPG (Fire Emblem-like).
Scope: all `scripts/` source — autoloads, core, resources, units, items, skills, ui,
shared. Skill/unit `.tres` data inspected where it affects correctness. Test suites
were read for coverage and **re-run this pass**: 11 suites / 249 tests green.
Tool scripts (`tools/`, `scripts/tools/`) excluded.

Follow-up to `code_review_2026-05-16c.md`. **All nine findings from that review
(1 High, 3 Medium, 5 Low) plus the two Nihil follow-ups are correctly implemented and
verified in this read** — see Positive Observations §1. This pass covers what is still
open or newly visible after Session G's changes, with an emphasis on combat-sequence
correctness and test depth.

---

## 1. Executive Summary

**Overall quality: 7.5 / 10.**

The codebase remains well-structured, unusually well-commented, and well-tested, and
Session G's follow-through on the previous review was complete and accurate. The
headline concern this pass is a genuine, *shipped* combat-ordering bug: when a unit
with **Vantage** defends and kills its attacker on the pre-emptive strike, the
already-dead attacker still gets to swing back in `resolve_combat`, because the
attacker's strike loop only checks whether the *defender* is dead, never itself.
`unit_02_mercenary` ships with Vantage, so this is reachable in normal play. The
remaining issues are latent inconsistencies and duplication: the combat preview's
side-effect snapshot covers only the two combatants while `_collect_combat_modifiers`
can touch others, and three separate hand-rolled pathfinding floods have already begun
to drift. None crash; the suite is green.

---

## 2. Issues Found

### [SEVERITY: High]
- **File & Line:** `scripts/core/CombatResolver.gd:535-544` (`resolve_combat`, the
  attacker strike loop), vs `:523-533` (the Vantage branch).
- **Problem:** `resolve_combat` runs the attacker's strikes in a loop that breaks only
  on the *defender's* simulated HP:
  ```gdscript
  # Attacker's strikes
  for _i in atk_strikes:
      if def_sim_hp <= 0:
          break
      var ex := _resolve_strike(attacker, defender, context, false, def_sim_hp, ...)
  ```
  There is no `atk_sim_hp <= 0` guard. In a normal fight that is harmless — the
  attacker always strikes first while at full HP. **But with Vantage it is not.** The
  Vantage branch immediately above (`:523-533`) lets the defender strike first and
  decrements `atk_sim_hp`; that branch *does* guard itself (`:525 if atk_sim_hp <= 0:
  break`). So when a Vantage defender kills the attacker on the pre-emptive strike,
  `atk_sim_hp` is `<= 0` — and the attacker loop then runs anyway and generates strike
  exchanges for a dead unit. `apply_combat_result` applies them: `def_unit.take_damage`
  lands real damage from the corpse, and a low-HP Vantage defender can be killed by the
  attacker it already killed (`defender_died` flips true → mutual death). The whole
  point of Vantage — "strike first, kill before they hit you" — is defeated.
  This is reachable in shipped content: `data/roster/default/unit_02_mercenary.tres`
  has `skills = ["vantage", "swordfaire"]`, and `vantage.tres` is `trigger =
  "on_combat_start"`, `effect_id = "vantage"`. Any enemy that attacks the mercenary
  while the mercenary can counter triggers this path.
- **Root Cause:** The attacker loop was written assuming the attacker is always alive
  when it runs (true without Vantage). The Vantage branch was added later and reorders
  the defender's strikes ahead of the attacker's, but the attacker loop was never given
  the matching actor-alive guard that the defender's counter loop (`:548-556`) and the
  follow-up block (`:565`) both have.
- **Recommended Fix:** Add the actor-alive guard to the attacker loop, mirroring the
  defender loop:
  ```gdscript
  # Attacker's strikes
  for _i in atk_strikes:
      if def_sim_hp <= 0 or atk_sim_hp <= 0:
          break
      var ex := _resolve_strike(attacker, defender, context, false, def_sim_hp, ...)
      ...
  ```
  `atk_sim_hp` is already in scope (declared `:509`) and is decremented by the Vantage
  branch, so no new bookkeeping is needed. The follow-up block already guards
  `fu_sim_hp > 0`, so a dead attacker correctly skips its follow-up too once this lands.
- **Tradeoffs:** None. This is a one-line correctness fix.
- **Assumption flagged:** I assume Vantage is meant to fully pre-empt — a defender who
  kills the attacker before it acts should take zero retaliation. That is standard FE
  behavior and matches the Vantage branch's own `atk_sim_hp` guard. If the design
  intends the attacker to always get at least one swing, this is instead a
  documentation gap — but nothing in the code suggests that.

### [SEVERITY: Medium]
- **File & Line:** `scripts/core/CombatResolver.gd:440-448` (`preview_combat`),
  `:420-428` (`_snapshot_unit_state`), `:104-108` (`_collect_combat_modifiers` aura
  loop); `scripts/skills/SkillHandler.gd:118-125` (`apply_trigger` use-counter writes).
- **Problem:** `preview_combat` is contractually side-effect-free — it snapshots
  mutable unit state, runs `_collect_combat_modifiers`, reads every displayed figure,
  then restores. But it only snapshots **two units**: `attacker` and `defender`
  (`:441-442`). `_collect_combat_modifiers` also iterates *every other living unit* for
  `on_combat_apply_modifiers` aura skills (`:104-108`), and `apply_trigger`
  **writes `unit.data.skill_use_counters`** on the trigger's owner whenever a fired
  skill has `max_uses_per_map != -1` (`SkillHandler.gd:120-122`). So an aura-bearing
  third unit with a per-map use limit would have its counter incremented every time the
  player *opens a combat preview* — and never restored. Today every aura skill
  (`_apply_charm`/`_apply_anathema`/`_apply_daunt`) is an M9 stub that returns `false`,
  so nothing fires and the leak is dormant — but the moment a real limited-use aura
  skill lands, hovering the attack preview will silently burn its uses.
- **Root Cause:** The snapshot scope was sized to the combat preview's *visible*
  participants, but `_collect_combat_modifiers` reaches wider — it mutates whoever owns
  a fired, use-limited skill, which includes off-combat aura bearers.
- **Recommended Fix:** Snapshot every unit `_collect_combat_modifiers` can touch, not
  just the two combatants. The cheapest correct option: in `preview_combat`, snapshot
  the aura-bearer set the same way the aura loop selects it —
  ```gdscript
  var snaps: Dictionary = {}   # Node -> snapshot
  snaps[attacker] = _snapshot_unit_state(attacker)
  snaps[defender] = _snapshot_unit_state(defender)
  var gs := get_node_or_null("/root/GameState")
  if gs:
      for u in gs.all_units:
          if is_instance_valid(u) and u.data != null and not snaps.has(u):
              snaps[u] = _snapshot_unit_state(u)
  ```
  then restore all of `snaps` at the end. Alternatively — and more robust long-term —
  give `apply_trigger` a `dry_run` parameter that `preview = true` callers pass, which
  suppresses both the per-map and per-combat counter writes entirely. The dry-run
  approach also removes the need to snapshot `skill_use_counters` at all for previews.
- **Tradeoffs:** Snapshotting all units is O(units) dictionary copies per preview —
  trivial at MVP scale but grows with roster size. The `dry_run` flag is a cleaner
  contract but touches `apply_trigger`'s signature (already five params). I'd take the
  `dry_run` flag.

### [SEVERITY: Medium]
- **File & Line:** `scripts/core/GridManager.gd:171-213` (`get_movement_range`),
  `:218-270` (`get_movement_path`); `scripts/core/EnemyAI.gd:228-251` (`_flood_costs`).
- **Problem:** There are **three** independent hand-rolled shortest-path floods over
  the same terrain-cost graph:
  - `get_movement_range` — Dijkstra, linear-scan frontier (O(n²) pop), respects the
    movement cap and unit occupants.
  - `get_movement_path` — a near-identical copy of the same loop, plus a `came_from`
    map and an early-out at the target.
  - `EnemyAI._flood_costs` — Dijkstra again, this time with an insertion-sorted-array
    heap, ignoring the cap and occupants; its own comment says "same algorithm as
    GridManager."
  The two `GridManager` functions are ~50 lines of duplicated traversal that differ
  only in their output (tile set vs. reconstructed path) — a maintenance hazard: a fix
  to one (e.g. a future diagonal-movement or zone-of-control rule) must be mirrored by
  hand into the other. The third uses a *different* priority-queue implementation, so
  the project carries two queue strategies for one algorithm.
- **Root Cause:** Each consumer grew its own flood when it needed one; no shared
  cost-map primitive was ever factored out.
- **Recommended Fix:** Extract one parameterised flood on `GridManager`, e.g.
  `_dijkstra_costs(start, max_cost, ignore_occupants, blocker_unit) -> {tile: cost}`
  plus optional `came_from`. `get_movement_range` becomes "flood with the cap, filter
  by `can_end_on_tile`"; `get_movement_path` becomes "flood with the cap + `came_from`,
  reconstruct"; `EnemyAI._flood_costs` becomes "flood with `INT_MAX` cap, ignore
  occupants." Pick one priority-queue strategy (the insertion-sorted heap is the better
  of the two) and delete the other. Do this behind the existing green tests
  (`test_grid_manager`, `test_map_grid`, `test_enemy_ai`).
- **Tradeoffs:** A non-trivial refactor touching two files; needs careful test
  coverage of the cap/occupant parameter combinations. Worth doing before M9 adds
  movement-override skills (`get_move_cost_override`, `can_pass_through_enemies`), each
  of which would otherwise have to be wired into three places.

### [SEVERITY: Low]
- **File & Line:** `scripts/units/Unit.gd:543-554` (`_increment_stat`), `:46-60`
  (`_apply_initial_state`), `:308-328` (`take_damage` / `heal`).
- **Problem:** `_apply_initial_state` sets `_hp_bar.max_value = data.max_hp` once.
  `_increment_stat` raises `data.max_hp` on an HP level-up (`:546`), but nothing
  updates `_hp_bar.max_value` afterward. `take_damage`/`heal` only assign
  `_hp_bar.value`, never `max_value`. So a unit that levels up mid-map and gains HP has
  an HP bar whose `max_value` is stale (too low) until the next player phase — when
  `start_player_phase` → `reset_appearance()` → `_apply_initial_state()` happens to
  rebuild it. For player units the glitch self-corrects within a turn; for enemy units
  (which never get `reset_appearance`) it persists, though enemies rarely level.
- **Root Cause:** The HP bar's `max_value` is initialised once but treated as
  immutable; level-up HP growth is a code path that changes `max_hp` after init.
- **Recommended Fix:** In `_increment_stat`'s `"hp"` branch, also refresh the bar:
  ```gdscript
  "hp":
      data.max_hp += 1
      data.hp += 1
      if _hp_bar:
          _hp_bar.max_value = data.max_hp
          _hp_bar.value = data.hp
  ```
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/autoloads/GameState.gd:230` (`_restore_unit_data`).
- **Problem:** `data.active_modifiers = snap.get("active_modifiers", {}).duplicate(true)`
  — the default passed to `.get()` is `{}` (an empty **Dictionary**), but
  `UnitData.active_modifiers` is typed `Array[Dictionary]`. Every snapshot written by
  `_snapshot_unit_data` includes the key, so the default is never used today. But the
  surrounding code's explicit rationale (`:205` "so older snapshots missing newer
  fields don't crash") is exactly the scenario where this default *would* be used — and
  there it would assign a Dictionary to an `Array` field and throw. The neighbouring
  `skill_use_counters`/`proficiencies`/`growth_accumulators` defaults are correctly
  `{}` (they are Dictionaries) and `conditions`/`skills` are correctly `[]`; only
  `active_modifiers` has the wrong default type.
- **Root Cause:** Copy-paste from a Dictionary-typed neighbour without adjusting the
  default to match the Array type.
- **Recommended Fix:** Change the default to `[]`:
  `data.active_modifiers = snap.get("active_modifiers", []).duplicate(true)`.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/CombatResolver.gd:1-3` (file header comment).
- **Problem:** The header states: *"Stateless combat math engine. resolve_combat()
  returns a result dict; no unit fields are written until apply_combat_result() is
  called."* That is no longer accurate. `resolve_combat` → `_collect_combat_modifiers`
  fires `on_combat_start` skill triggers, and `_apply_resolve` writes
  `unit.data.active_modifiers` via `add_modifier`; `resolve_combat` also fires
  `on_combat_end` triggers (`:582-583`) and `_resolve_single_attack` fires `on_damaged`
  (Miracle can mutate state). `preview_combat` snapshots/restores *precisely because*
  these writes happen. The "no unit fields written" claim is true only of the raw
  HP/durability/EXP application, not of skill side effects — and a reader trusting the
  header could wrongly assume `resolve_combat` is safe to call speculatively.
- **Root Cause:** Header written before skill triggers were threaded through the
  resolver; not updated as triggers landed.
- **Recommended Fix:** Reword to scope the claim, e.g. *"HP, durability, and EXP are
  not applied until apply_combat_result(); note that skill triggers fired during
  resolve_combat (on_combat_start / on_combat_end / on_damaged) DO mutate unit state —
  preview_combat snapshots around this."*
- **Tradeoffs:** None — documentation only.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/MapCursor.gd:499-507` (`_finish_action`);
  `scripts/core/TurnManager.gd:124-129` (`set_unit_state`), `:218-221` (`_on_unit_died`).
- **Problem:** When a player unit attacks and dies in the exchange (mutual kill, or a
  Vantage counter-kill — see the High finding), the sequence is: `apply_combat_result`
  → `handle_death()` emits `unit_died` → `TurnManager._on_unit_died` **erases** the unit
  from `_unit_states` → control returns up through `_on_targeting_completed` →
  `_finish_action`, which calls `_turn.set_unit_state(_selected_unit,
  TurnManager.UnitState.DONE)`. `set_unit_state` then **re-inserts** the dead unit into
  `_unit_states` (`:127`) — and `_on_unit_died` has already run, so nothing erases it
  again. The node is `queue_free()`d at end of frame, leaving a stale freed-node key in
  `_unit_states` permanently. `set_unit_state` also calls `set_done_appearance()` on the
  about-to-be-freed node (`:128-129`); that node is still valid this frame so it does
  not crash, but it is wasted work. Not a crash and not unbounded (bounded by roster
  size), but it is a dictionary leak and a `get_unit_state` on that stale key would
  return `DONE` for a node that no longer exists.
- **Root Cause:** `_finish_action` assumes `_selected_unit` survived the action;
  combat can invalidate that assumption, and `set_unit_state` has no liveness check.
- **Recommended Fix:** Guard `_finish_action`'s state write with a liveness check:
  ```gdscript
  if _turn != null and is_instance_valid(_selected_unit) \
          and _selected_unit.data != null and _selected_unit.data.hp > 0:
      _turn.set_unit_state(_selected_unit, TurnManager.UnitState.DONE)
  ```
  A dead acting unit is already out of `_unit_states` and needs no DONE marker.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/TurnManager.gd:47` (`_apply_fort_healing`);
  `scripts/skills/SkillHandler.gd:164` (`_apply_renewal`).
- **Problem:** Two "heal 10% of max HP" mechanics round in opposite directions. Fort
  healing uses `ceili(u.data.max_hp * GameConstants.FORT_HEAL_FRACTION)`; Renewal uses
  `maxi(1, floori(unit.data.max_hp * 0.10))`. For a 25-HP unit, fort heals 3, Renewal
  heals 2. The discrepancy is small and may be intentional per GDD_02, but two
  hard-coded copies of "10%" (one as a named constant, one as the literal `0.10`)
  rounding differently is the kind of inconsistency that surfaces as a "why did this
  heal a different amount" bug report later.
- **Root Cause:** The two heals were implemented independently; neither references a
  shared "percent-of-max-HP heal" helper.
- **Recommended Fix:** If the GDD specifies one rounding rule, apply it to both. If not,
  decide one (rounding up is the friendlier default) and route both through a single
  helper, e.g. `Unit.heal_fraction(pct)`. At minimum, replace Renewal's literal `0.10`
  with a named constant so the two sites are greppable together.
- **Tradeoffs:** None — pick a rule and document it.

---

## 3. Positive Observations

1. **Session G's review backlog is fully and accurately implemented.** Every
   `code_review_2026-05-16c.md` finding is genuinely fixed and verified in this read:
   the Nihil negate pre-pass (`on_combat_start_negate`) resolves the `*_skills_blocked`
   flags before any modifier skill runs (`CombatResolver.gd:111-125`); durability is
   modelled inside `resolve_combat` via `_resolve_strike`/`weapon_uses`/`broken`;
   `is_healing_staff()` now gates `ActionMenu`, `EnemyAI._try_staff_heal`, and
   `GridManager.can_attack_from_tile`; enemy `start_of_turn` skills fire in
   `start_enemy_phase`; `HUD` clears its panel on `unit_died`; `preview_combat` exposes
   `defender_vantage`; the stat-cap gap is marked `NOT ENFORCED`. The two Nihil
   follow-ups (`NIHIL_EXEMPT_SKILLS` + the `skills_blocked` flag, and the Nihil-scope
   documentation) are clean and well-tested.
2. **Durability is now a first-class part of the simulation.** `_resolve_strike` +
   the `weapon_uses`/`broken` bookkeeping mean `resolve_combat`'s `exchanges` list is
   authoritative — `apply_combat_result` is now pure application with no skip logic,
   and skill triggers fire only for attacks that actually happen. The mid-combat-break
   test asserts both the exchange count and the resulting HP, so the contract is
   pinned.
3. **The Nihil exemption mechanism is a clean, single-source rule.**
   `NIHIL_EXEMPT_SKILLS` is one named constant, `apply_trigger`'s `skills_blocked`
   parameter is the one enforcement point, and the comment explains why `nihil` itself
   is listed even though its pre-pass makes it structurally exempt. The regression test
   (S-Rank Mastery applies while Swordfaire is negated on the same unit) locks it down.
4. **Comments consistently explain *why*, not *what*.** The negate-pre-pass rationale,
   the durability-in-simulation rationale, the distinct-source-per-stat reasoning in
   `_apply_resolve`, the "capture the weapon before the durability decrement" note in
   `MapCursorTargeting`, and the snapshot deep-copy reasoning in `GameState` all
   document decisions a future maintainer would otherwise have to reverse-engineer.
5. **Headless-testable architecture holds up.** `is_inside_tree()` guards, the
   `GridManager._terrain_fallback`, the dependency-injected `MapCursorTargeting`
   (a plain `RefCounted`), and the `MockUnit` in `test_combat` keep core logic
   exercisable without autoloads or a SceneTree — 249 tests run in `--script` mode.

---

## 4. Architectural Observations

- **The combat sequence has no single guarded "is this actor still alive?" check.**
  The High finding is the symptom: each strike loop (`Vantage`, attacker, counter,
  follow-up) independently re-derives which HP variable to test, and the attacker loop
  got it wrong. Four loops, four hand-written guards. A small `_run_strike_series(actor,
  target, ...)` helper that owns the "stop if either side is dead or a weapon broke"
  logic would make all four paths provably consistent and is the structural fix behind
  the one-line patch.
- **Three pathfinding floods, two queue strategies.** See Medium finding §3. The
  duplication is already drifting (`get_movement_range`/`get_movement_path` use a
  linear-scan frontier; `_flood_costs` uses an insertion-sorted heap). Consolidating
  before M9's movement-override skills land avoids wiring those overrides into three
  places.
- **`preview_combat`'s side-effect contract is scoped to the wrong set of units.**
  See Medium finding §2. The snapshot covers the two combatants, but
  `_collect_combat_modifiers` mutates whoever owns a fired use-limited skill — a wider
  set. A `dry_run` flag on `apply_trigger` would make the preview's read-only contract
  hold by construction rather than by snapshot bookkeeping.
- **Player/enemy phase logic is now closer to symmetric but still hand-maintained.**
  Session G added enemy `start_of_turn` skills, so `start_player_phase` and
  `start_enemy_phase` now run the same conceptual steps — but as two independently
  edited lists. The `_begin_phase(units)` helper suggested last review would make them
  provably consistent; still pending. (Carry-over.)
- **`MapCursor` remains a ~620-line FSM and the largest untested correctness surface.**
  The `MapCursorTargeting` slice landed cleanly; the `MapCursorInput` /
  `MapCursorSelection` slices are still pending, and `MapCursor` itself has no unit
  tests. (Carry-over.)

---

## 5. Test Coverage Gaps

The suite is strong on `CombatResolver` math, the data layer, and the grid — but two
gaps stand out, the first of which would have caught the High finding:

- **No `resolve_combat` test exercises Vantage.** `test_combat` covers counterattack
  range, follow-ups, Brave strike counts, mid-combat weapon break, mutual kill, and
  counter-kill EXP — but never a full Vantage fight. A test where a Vantage defender
  one-shots the attacker and then asserts `exchanges` contains **no attacker exchange**
  (and the defender takes zero damage) would have failed against the current code.
  Add it alongside the High fix.
- **`EnemyAI` has only 5 tests, all on `_find_nearest` (Manhattan path) and
  `_choose_move_tile`.** Untested: the `_act` profile dispatch (`passive` / `healer` /
  `basic` full turns), `_try_staff_heal`, `_choose_heal_move_tile`, `_flood_costs`
  (the real-grid pathfinding flood), and `_find_nearest`'s grid/Dijkstra branch
  (only the `grid == null` fallback is exercised). For a 251-line module with three
  behaviour profiles, that is thin — a healer that paths to the wrong tile or a
  `_flood_costs` regression would currently ship green.
- **No test for `apply_combat_result` exchange ordering.** The Vantage/counter
  interaction (who strikes first, who dies first, mutual death) is verified only for
  the simple mutual-kill case. A test that pins the *order* of exchanges in a
  Vantage + follow-up fight would protect the sequence logic during the
  `_run_strike_series` refactor suggested in §4.

---

## 6. Prioritized Action Plan

Ordered by impact-to-effort.

1. **Fix the Vantage dead-attacker bug** (High): add `or atk_sim_hp <= 0` to the
   attacker strike loop's break condition (`CombatResolver.gd:537`). One line. Add the
   missing Vantage `resolve_combat` regression test in the same change.
2. **Fix the `preview_combat` snapshot scope** (Medium): either snapshot every unit
   `_collect_combat_modifiers` can touch, or add a `dry_run` flag to `apply_trigger`
   that suppresses use-counter writes for `preview = true` callers. Cheap, removes a
   latent M9 use-burning bug.
3. **Low-severity polish, batched** (Low): refresh `_hp_bar.max_value` on HP level-up;
   fix the `active_modifiers` default type in `_restore_unit_data`; correct the
   `CombatResolver` header comment; guard `_finish_action`'s state write with a
   liveness check; unify the fort/Renewal 10%-heal rounding.
4. **Consolidate the three pathfinding floods** (Medium): extract one
   `GridManager._dijkstra_costs(...)` primitive behind the existing green grid/AI
   tests; pick one priority-queue strategy. Best done before M9 movement-override
   skills land.
5. **Deepen `EnemyAI` test coverage** (test debt): add tests for the three `_act`
   profiles, `_try_staff_heal`, `_choose_heal_move_tile`, and `_flood_costs`.
6. **Architectural, when convenient:** factor a `_run_strike_series` helper in
   `CombatResolver` and a `_begin_phase` helper in `TurnManager`; continue the
   `MapCursor` slicing and give it unit tests.

---

## Assumptions Flagged

- I assume Vantage is intended to fully pre-empt — a defender who kills the attacker
  before it acts takes zero retaliation (standard FE behavior, and consistent with the
  Vantage branch's own `atk_sim_hp` guard). If the attacker is meant to always get one
  swing, Finding 1 is a documentation gap instead.
- I assume offensive/limited-use aura skills are still planned for M9 (the
  `_apply_charm`/`_apply_anathema`/`_apply_daunt` stubs and their `# implement in M9`
  comments say so). If aura skills will never carry a `max_uses_per_map`, Finding 2 is
  cosmetic rather than a latent bug.
- I assume the fort/Renewal rounding difference is unintentional; if GDD_02 specifies
  per-mechanic rounding, Finding 8 reduces to "replace the magic literal `0.10` with a
  constant."
- Test suites were both read and re-run this pass: 11 suites / 249 tests green
  (`bash run_tests.sh`).
