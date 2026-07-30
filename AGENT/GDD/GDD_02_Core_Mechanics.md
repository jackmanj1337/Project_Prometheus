# GDD_02 — Core Mechanics

**Status:** Active contract — split status per section (project behavior is
**Implemented**; corpus migration is **Target design**, tracked in
`GDD_Adoption_Matrix.md`).
**Last verified:** 2026-07-29
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This chapter owns combat resolution, the RNG/hit model, stats and derived combat
values, terrain combat application, combat-facing WEXP behavior, combat EXP,
leveling, and promotion *trigger timing*. `GDD_03` owns class definitions,
promotion targets, and progression relationships; `GDD_04` owns weapon/WEXP data
and economy; `GDD_06` owns terrain/movement authoring. Determinism architecture
(autoloads, snapshot/save) is owned by `GDD_01`.

---

## The Grid

Status: **Implemented**
Last verified: 2026-06-13

### Summary
A square, orthogonally-navigated tile grid; one unit per tile.

### Specs
- Implemented topology: square tile grid; orthogonal movement only (no diagonals).
  Optional hex topology is parked as `B8-HEX` and must enter through a topology
  profile/accessor seam, not scattered distance constants.
- Authored maps tested through 42×26 tiles.
- Each tile has a terrain type affecting movement cost, defense, and dodge.
- One unit per tile. Allied units can be passed through during movement; enemies cannot.
- Coordinates use Godot `Vector2i`; `(0,0)` = top-left.

### Anchors
- Code: `scripts/core/GridManager.gd`, `scripts/core/GameMap.gd`
- Roadmap: GDD_10 (shipped)

---

## Terrain (combat effects)

Status: **Split** — project values **Implemented**; corpus values **Target design** (RULE-010)
Last verified: 2026-06-13

### Summary
Terrain contributes authored DEF/Dodge values to the defender during combat and
may apply a start-of-phase heal. `GDD_06 §Terrain & Movement` owns terrain ids,
movement costs, movement categories, and the full authored value table.

### Specs

**Implemented (project behavior).** Terrain bonuses apply to the **defending unit
only**; attackers get none. `CombatResolver` reads the defender's terrain DEF and
Dodge during value calculation. These bonuses never permanently modify unit stats.

**Fort/throne heal (OPEN-7, Answered).** A unit standing on a healing tile recovers
`heal = max(1, floor(0.10 × max_hp))` at start of turn (Renewal rounding — guarantees
at least 1).

**Target design.** Terrain bonuses and healing profiles become authorable terrain/rule
data. Corpus values, movement categories, topology rules, and the unresolved terrain-id
mapping remain with `GDD_06`; combat consumes the resolved values without owning their
names or balance tables.

### Anchors
- Code: `scripts/core/GridManager.gd`; terrain data resources
- Decisions: SET-008, RULE-010, RULE-011, OPEN-7
- Owner of authored terrain/movement contracts: `GDD_06 §Terrain & Movement`

---

## Turn Structure

Status: **Implemented**
Last verified: 2026-06-16

### Summary
A data-driven faction phase scheduler; the default is a classic whole-phase round.

### Specs
Maps author `MapData.factions` (name, color, alliance group, controller),
`MapData.turn_order`, and `MapData.activation_mode` (shipped content uses
`WHOLE_PHASE`).

Default whole-phase loop:
```
Round Start
  └── BLUE PHASE: refresh → per-unit "turn" modifiers tick → fort heal + start_of_turn
        skills → player commands blue units until all DONE or End Turn
  └── GREEN / RED / YELLOW PHASES (if in turn_order): refresh → modifiers tick →
        fort heal + start_of_turn skills → controller runs faction (AI or hotseat)
  └── Round wraps to blue: all-units "map_turn" modifiers tick once → turn counter++
```

- Controllers: `blue` is the player; non-blue factions are AI or `HOTSEAT` per
  `FactionData.controller`.
- Unit action states per round: `READY` → `MOVED` → `DONE`.
- A controlled phase ends automatically when every acting-faction unit is `DONE`, or
  early via the Map Menu. Hotseat phases use blue's commit flow; only the commandable
  faction differs.
- `ALTERNATING` exists in `TurnManager` as infrastructure, not production gameplay.
- Debug-build F9 toggles a temporary all-faction hotseat override. While active, every
  faction uses the hotseat controller and the debug HUD lists `hotseat-all`; toggling
  it off during a normally AI-controlled phase cancels transient cursor UI/selection
  state and resumes that same faction through its authored AI controller.

### Anchors
- Code: `scripts/core/TurnManager.gd`, `scripts/core/HotseatController.gd`
- Tests: `scripts/tests/test_turn_manager.gd`

---

## Unit Stats & Derived Combat Values

Status: **Split** — project formulas **Implemented**; corpus combat-stat formulas **Target design** (SET-001)
Last verified: 2026-06-13

### Summary
Integer stats; combat values are derived per equipped weapon, rounded down, floored at 0.

### Specs

Base stats: HP, STR, MAG, DEF, RES, SKL, SPD, LUK, MOV, CON, LoS (LoS is Phase 2+).
This is the implemented starter stat set. The target stat model (`B3-STAT-REGISTRY`,
`[STM]`) moves stat names, display metadata, missing-stat behavior, and derived-value
inputs into a stat registry so adding Charisma/Command/etc. is data work plus engine
primitive support where needed.

**Implemented (project) derived values:**

| Derived | Formula |
|---|---|
| Battle Speed | `SPD - max(0, Wt - STR)` |
| Accuracy | `SKL × 2 + LUK + weapon.Hit` |
| Dodge | `Battle Speed × 2 + LUK` |
| To-Hit % | `Accuracy - target.Dodge` (clamped 0–100) |
| Damage | `(STR or MAG) + weapon.Mt - target.(DEF or RES)` (min 0) |
| Critical | `floor(SKL / 2) + weapon.Crit` |
| Crit Avoid | `LUK` |
| Crit % | `Critical - target.Crit Avoid` (clamped 0–100) |

Terrain DEF/Dodge add to the defender's values during combat only.

**Target design (SET-001).** Corpus combat-stat formulas are adopted as a target; the
exact formula set and provenance live in `GDD_Adoption_Matrix.md` (→ `awakening_core_systems.md`
Derived Combat Values / Attack Speed). Not yet implemented — do not treat as shipped.

### Anchors
- Code: `scripts/core/CombatResolver.gd`
- Tests: `scripts/tests/test_combat.gd`
- Decisions: SET-001
- Reference: `awakening_core_systems.md`; `GDD_Adoption_Matrix.md`

---

## Combat Modifier Pipeline Order

Status: **Target design** (ratified order; corpus formulas slot into it)
Last verified: 2026-06-13

### Summary
A single canonical order in which modifiers compose into final combat values.

### Specs
Canonical order (ratified 2026-06-13):

```
base stats → permanent modifiers → pair-up bonuses → combat-duration skill mods →
conditions → terrain → weapon triangle → S-rank bonus → clamps
```

Corpus combat migration (SET-001/SET-003, RULE-002) must slot into this order. The
**binding pipeline contract lives in `GDD_01`** (combat context); this is the
combat-facing summary. Enforced before M9b authoring.

### Anchors
- Owner of the binding contract: GDD_01 (combat context schema)
- Decisions: combat modifier pipeline order (decision_index → JUN)

---

## Weapon Triangle

Status: **Split** — flat project bonus **Implemented**; rank-scaled corpus bonuses **Target design** (SET-003)
Last verified: 2026-06-13

### Summary
Two triangles (physical + project magic), each giving advantage/disadvantage to
Accuracy and Damage.

### Specs

**Implemented (project).** Each triangle gives **+10 Accuracy / +2 Damage** at
advantage, **-10 / -2** at disadvantage.
- Physical: Sword → Axe → Lance → Sword.
- Magic: Dark → Anima (Fire/Thunder/Wind) → Light → Dark.
- Bows, knives, staves have no triangle interaction; a type has no advantage vs itself.
- Hybrid weapons (e.g. Sonic Sword, Bolt Axe) carry a magic `triangle_family` and their
  physical type simultaneously — use whichever gives advantage.
- Lookup: `DataManager.get_weapon_triangle_result("sword","axe") → "advantage"`.

**Target design (SET-003, RULE-013).** Adopt **rank-scaled** corpus triangle bonuses
for **both** triangles (same scaling table). Both project relationships are retained.
For hybrid weapons, the **equipped weapon's trained WEXP track** sets the bonus
magnitude; `triangle_family` only sets the relationship (no second hidden magic rank).
Provenance + variation: `GDD_Adoption_Matrix.md`.

**Design firmed 2026-06-24b — author-flexible triangle (`[CEX-9..12, 17]`, rides F4; build pending).**
The relationships (`matrix`), the magnitude `effects`, the family list, and `reaver_multiplier`
become a **`CampaignRules` `triangle` profile** (F4). The matrix is an **arbitrary directed graph**
(today's shape). `effects` generalize from Hit/Atk to **arbitrary stat-mods** (condition application
deferred to the **F5** build). **Default profile = the current flat ±10/±2 (non-breaking); the
rank-scaled table above ships as an opt-in built-in `rank_scaled` profile.** **Reaver weapons**
(`weapon_component.reverses_triangle`) — an **odd** number across the two combatants inverts the
result and ×`reaver_multiplier` (default 2); even cancels. See `[CEX]` block C.

### Anchors
- Code: `scripts/autoloads/DataManager.gd`
- Decisions: SET-003, RULE-013
- Owner of weapon-family/rank detail: GDD_04
- Reference: `awakening_weapons_physical.md`, `awakening_weapons_magic.md`, `awakening_lookup_tables.md`

---

## Combat Resolution & Hit RNG

Status: **Split** — exchange flow **Implemented**; two-RN hit model **Implemented**
(2026-07-06) as the default preset of the author-selectable resolver seam (CRR-1)
Last verified: 2026-07-06

### Summary
An attack resolves a pre-built exchange list; each strike rolls a hit (two-RN model)
and, on a hit, a crit. All randomness is sourced from the deterministic `RngService`.

### Specs

**Exchange list (Implemented).** Resolve in order:
1. Attacker's first attack.
2. Defender's counterattack (only if the target is within their equipped weapon's range).
3. Follow-up — if one unit's Battle Speed is **≥5** higher, it makes one extra attack.

All attacks are determined **before** any are resolved (follow-up and counter checks
run at the start), so mid-combat stat changes never alter the sequence. The shipped
follow-up threshold preset is 5; CampaignRules/profile data may override it.
- **Brave weapons** (`WeaponData.strikes_per_attack = 2`): the wielder strikes twice
  per attack slot, including counter and follow-up.
- **Vantage** (skill): the defender counters *first*, before the attacker's strike.

**Hit/crit per strike — two-RN model (RULE-001, Implemented 2026-07-06).** RULE-001
is the **default** among author-selectable hit resolvers (CRR-1). Hit resolution goes
through a pure-predicate seam (CRR-2): the engine draws the selected resolver's fixed
`rn_count` of 0–99 integers from the event RNG in canonical order, then calls a pure
`did_hit(displayed_hit, rns)` predicate. Two built-ins ship: `two_roll` (RULE-001
default — two RNs, hit when `floor((r1 + r2) / 2) < To-Hit %`) and `single_roll`
(one RN, `rns[0] < To-Hit %`); `CampaignRules.hit_formula` selects the resolver.
Both are immutable version-1 descriptors in `HitFormulaRegistry`; unknown ids and
wrong roll counts fail rather than silently selecting another formula. Its preview
reports probability without consuming RNG.
A crit roll is drawn **only if the hit landed**. All of a resolver's hit draws are
always consumed (two_roll: miss = 2 draws, hit = 3) so the roll order never depends
on the outcome.
- The former single-roll rule survives only as the selectable `single_roll` built-in;
  it is no longer the shipped default.
- Damage = the Derived value (DEF/RES subtracted once). A critical **triples the final
  figure** (`×3`); any skill damage-multiplier applies last; clamp to ≥0.
- If the target's HP ≤ 0, the exchange stops — no further attacks land.

**Determinism (RNG-1…4, see GDD_01).** All gameplay dice — combat hit/crit, skill
activation, and level-up growth (chained `levelup` events) — come from `RngService`
(hash-chained, context-seeded, Implemented 2026-07-06), not `randi()`. The
**canonical roll order** per
attack — the selected resolver's fixed `rn_count` of hit RNs, then a crit RN on a
hit, then skill activation rolls at their trigger slots — is the binding contract;
reordering it (including changing a resolver's draw count) is a save/replay-breaking
change. Architecture, autoload order, snapshot persistence, accepted exploits, and
the online model are owned by `GDD_01 → Determinism & RNG`; the build/implementation
plan is `AGENT/Docs/design/rng_determinism_design_2026-06-11.md`.

**Mid-exchange weapon breakage (OPEN-3, Answered).** If a weapon breaks mid-exchange,
it **cancels that unit's remaining strikes** in the exchange (consistent with
attacks-determined-upfront and the deterministic roll order); the weapon is gone after
combat.

`CombatResolver` resolves an exchange the instant the player confirms (no combat
animation yet): `resolve_combat()` builds the list and draws rolls; `apply_combat_result()`
commits HP/durability/EXP. See GDD_01 → CombatResolver.

`project_exchange()` is the side-effect-free ordered projection sibling. It branches
bounded hit/crit outcomes through the same Vantage, multi-strike, follow-up,
death-stop, and durability-break sequence without consuming RNG or mutating HP,
inventory, durability, or skill counters. Both combatants carry a reserved style
slot; the defender's remains null under STY-8. Forecast caches are separated by
proc policy and keyed by attacker, defender, source, and attacker-terrain bucket,
deliberately excluding the literal tile. No shipped AI profile consumes this API in
Slice A.

### Known gaps
- Resolvers are two engine built-ins for now; registry promotion + author tiers are
  `B3-COMBAT-ROLL-RESOLVER` (CRR-8).
- Units with no usable equipped weapon cannot attack; counterattacking from a non-equipped
  inventory weapon is Phase 2+.

### Anchors
- Code: `scripts/core/CombatResolver.gd`, `scripts/autoloads/RngService.gd`
- Tests: `scripts/tests/test_combat.gd`, `scripts/tests/test_project_exchange.gd`,
  `scripts/tests/test_rng_service.gd`,
  `scripts/tests/test_rng_combat_determinism.gd` (T1/T3/T7),
  `scripts/tests/test_rng_usage_lint.gd` (T5); T2 pending (Step 2), T6 pending
  (`B1-SUSPEND`)
- Decisions: RULE-001, RNG-1…4, CRR-1..8, OPEN-3, pipeline order
- Reference: `GDD_Adoption_Matrix.md`; `AGENT/Docs/design/rng_determinism_design_2026-06-11.md`

---

## Weapon Durability

Status: **Implemented**; broken-weapon degraded mode **Planned** (OPEN-5)
Last verified: 2026-07-19

### Specs
- Melee/thrown weapons lose 1 use only on a **successful hit**.
- Bows, tomes, staves lose 1 use on **any use**, hit or miss.
- Durability is consumed as initiator or counterattacker alike.
- At 0 uses the weapon is **destroyed** and removed from inventory.
- Mid-exchange breakage cancels the unit's remaining strikes (OPEN-3 — see Combat
  Resolution).
- A **broken-weapon degraded mode** (optional: stat penalty + infinite uses while
  broken, repairable later) is a **deferred backlog** item (OPEN-5), likely a
  CampaignRules toggle.

### Anchors
- Decisions: OPEN-3, OPEN-5
- Owner of per-weapon data: GDD_04

---

## Weapon Proficiency (WEXP)

Status: **Split** — project thresholds/gain **Implemented**; corpus migration **Target design** (SET-004/005)
Last verified: 2026-06-13

### Summary
Successful combat hits grant the equipped weapon's authored WEXP to its trained track;
rank and cap data are owned by `GDD_04` and class baselines/caps by `GDD_03`.

### Specs

**Implemented (project combat behavior).** Each successful combat hit calls
`Unit.add_wexp(weapon.wexp_track, weapon.wexp)`. Equip eligibility reads the derived
rank for that track, and the S-rank bonus occupies its declared combat-pipeline step.

**Target design.** RULE-004 changes award timing to each valid use, with authored
exceptions. SET-005/RULE-002 move rank bonuses into the combat engine instead of the
`s_rank_mastery` pseudo-skill. Threshold values, caps, proportional migration, and
bonus magnitudes are intentionally not repeated here; see `GDD_04 §Weapon Proficiency`
and `§S-Rank Weapon Bonus`.

### Anchors
- Code: `scripts/core/CombatResolver.gd`, `scripts/units/Unit.gd`
- Decisions: SET-004, SET-005, RULE-002, RULE-003, RULE-004
- Owner of weapon-rank detail/economy: GDD_04
- Reference: `awakening_lookup_tables.md`; `GDD_Adoption_Matrix.md`

---

## Actions on a Unit's Turn

Status: **Implemented** (with noted future actions)
Last verified: 2026-06-13

### Specs
A unit may Move then take **one action**, or act in place. The shipped Action Menu
offers context-valid **Attack, Staff, Item, Equip, Seize, Escape, Pair Up, Swap,
Separate,** and **Wait**. Movement precedes the menu; Equip is a free menu operation
that returns to it.

| Action | Ends turn? | Notes |
|---|---|---|
| Move | No | Up to MOV; undoable until an action commits |
| Attack | Yes | Valid target in range |
| Staff | Yes | Heal ally in range; awards EXP + WEXP |
| Use Item | Yes | Consumes one use |
| Equip Weapon | No | Switch active weapon |
| Pair Up / Swap / Separate | Yes | When campaign Pair Up enabled |
| Wait / Seize / Escape | Yes | Wait ends turn; Seize/Escape are objective actions |

> **Swap** trades the lead and support roles within an existing pair: the new
> lead (the former support) takes the on-map tile and becomes visible, the former
> lead moves off-map and hides, and the joint action is spent (both units DONE).
> Code: `MapCursor._commit_swap_roles`; off-map placement uses `PairUpRegistry.OFF_MAP_TILE`.

### Known gaps
- Trade, Shove, Rescue/carry, and class-specific field actions are future work.
- **Secondary Movement / post-action remainder movement** (move after a turn-ending action, then
  Wait) — **design firmed 2026-06-24a as a parameterized skill** (`[SMV-1..11]`;
  `effect_id="secondary_movement"`, `movement_mode remaining|flat`, author `secondary_move_actions`,
  granted via the skill-grant mechanisms); **not** implemented. Build adds a `UNIT_SECONDARY_MOVE`
  action-flow state here (`scripts/core/MapCursor.gd`).

### Anchors
- Code: `scripts/core/TurnManager.gd`, `scripts/core/MapCursorSelection.gd`

---

## Experience Points (EXP)

Status: **Split** — class EXP behavior **Implemented**; authored award profiles **Target design**
Last verified: 2026-06-29

### Summary
Symmetric combat/staff EXP; 100 EXP = one level, overflow carries.

### Specs
- EXP goes to whichever unit dealt a blow (player and enemy alike), once per **combat
  exchange** (not per hit). WEXP increases per successful **hit**.
- Level difference = acting unit's level − opponent's; `CombatResolver.calculate_exp()`
  indexes the table with `clamp(level_diff + 6, 0, 12)`.

The table is the shipped EXP-curve preset. Expanded campaign rules should load EXP curves
or formula profiles from data rather than baking new balance tables into the resolver.
Class EXP storage/lifecycle remains separate from PXP; the shared direction is authored
award/profile data, not merged progression storage.

| Lvl diff (acting − opp) | Kill | Damage only |
|---|---|---|
| 6+ lower | 59 | 20 |
| 5 / 4 / 3 / 2 / 1 lower | 57 / 53 / 47 / 41 / 35 | 19 / 18 / 16 / 14 / 12 |
| Equal | 30 | 10 |
| 1 / 2 / 3 / 4 / 5 higher | 25 / 19 / 13 / 7 / 3 | 8 / 6 / 4 / 2 / 1 |
| 6+ higher | 1 | 0 |

- **Enemy/AI EXP gating (OPEN-4, Target):** `CampaignRules.exp_gaining_factions`
  exists on the live per-save rule object; `CombatResolver` still needs to consume
  it. The shipped preset is Blue + Green, Red none.
  Owner of the CampaignRules contract: GDD_01 (Stage 3.5).
- **Staff/action EXP (Implemented):** heal staff currently awards a flat preset amount
  (`GameConstants.STAFF_HEAL_EXP`). Target `[AGT §6]`/`B4-PXP` moves non-combat EXP to
  authored action data (`exp_award`) with campaign defaults, not hardcoded staff logic.
- **Class EXP / PXP boundary (Target design):** `UnitData.exp`, `level`,
  `internal_level`, and `Unit.add_exp()` remain the class-level progression path.
  PXP owns proficiency tracks (`weapon`, `item`, `source`, `action`). Training,
  Bonus EXP, and authored actions should call sibling benefit handlers:
  `class_exp -> add_exp(amount)` and `proficiency_xp -> advance_proficiency(track, amount)`.
  See
  `AGENT/Docs/plans/class_exp_pxp_boundary_plan_2026-06-29.md`.

### Anchors
- Code: `scripts/core/CombatResolver.gd` (`calculate_exp`), `GameConstants`
- Decisions: OPEN-4

---

## Leveling Up

Status: **Implemented** (Random + Fixed); other methods **Planned**
Last verified: 2026-07-06

### Specs
At 100 EXP: level +1, EXP resets (overflow carries), stats rise per the save's
`GameState.campaign_rules.leveling_method`.

| Method | Description |
|---|---|
| `growth_random` (default) | Per-stat growth %, rolled each level; >100 grants guaranteed points + a roll for the remainder |
| `growth_fixed` | Deterministic accumulator in `UnitData.growth_accumulators`; every full 100 yields +1 |

Growth dicts use full stat names. Blue units add personal `UnitData.growth_rates` to
`ClassData.player_growth_rates`; non-blue generation uses `enemy_growth_rates`.

Level-up rolls are a chained `levelup` RNG event (one per level on overflow), drawing
one growth roll per stat in `ClassData.STAT_KEYS` order — see the determinism contract.

### Known gaps
- Point Buy, Coin Flip, Dice Roll are **Planned** (New Game screen offers only Random
  and Fixed).
- **Class-growth adoption (RULE-008, Target):** effective growth becomes corpus
  archetype + corpus class growth; authored personal growths are replaced. Owned by
  GDD_03.

### Anchors
- Code: `scripts/units/Unit.gd` (`level_up`)
- Tests: `scripts/tests/test_level_up_screen.gd`
- Decisions: RULE-008 (GDD_03)

---

## Promotion — Trigger Timing

Status: **Split** — project eligibility **Implemented**; corpus timing + modal **Target design** (RULE-005)
Last verified: 2026-06-13

### Summary
*When* promotion fires and how the modal interrupts play. Class targets, bonuses, and
progression relationships are owned by **GDD_03**.

### Specs

**Implemented (project timing).** Reaching the class eligibility gate queues the
promotion screen after EXP/action processing. Promotion items enter the same screen
through the eligibility contract. The target list and resulting class/stat/WEXP/skill
changes are owned by `GDD_03 §Promotion` and `§Promotion Items`.

**Target design (RULE-005).**
- **Seals** permit promotion at **level 10**; **campaign settings** may additionally
  allow **automatic** promotion when a unit reaches its class level cap.
- The promotion modal opens **only after the triggering action fully commits** (combat
  resolves and EXP is applied) — not mid-action.
- While open, **all controllers are blocked** until the owning player selects a class;
  it may interrupt other players' turns, with control returning afterward.
- Promotion is **mandatory once triggered — no cancel**.
- Rationale: keeps the deterministic event stream and online sync unambiguous (the
  interrupt point is the post-commit eligibility check).

### Anchors
- Decisions: RULE-005, SET-006
- Owner of class targets/progression: GDD_03
- Reference: `awakening_core_systems.md` (Promotion System); `GDD_Adoption_Matrix.md`

---

## Permadeath

Status: **Implemented**
Last verified: 2026-07-13

### Specs
Controlled by `GameState.campaign_rules.permadeath_enabled`.
- **ON:** at 0 HP the unit leaves the map; `UnitData` is retained and flagged
  `is_incapacitated = true`; cannot be deployed later; never deleted (revival/viewing
  possible).
- **OFF:** the unit is removed for that map only and is fully available next map; no
  flag set.
- Battle results distinguish these dispositions as `Name — Fallen` when the
  incapacitation flag is set and `Name — Retreated` otherwise. Escape is not a death
  lifecycle event and is not listed as a casualty.
- **Game Over:** if a designated required unit (e.g. the lord) dies, the map ends in
  defeat → retry screen, regardless of the setting.
- Combat now delegates both classic and casual removal through the shared death
  lifecycle. Mutual-death contexts are snapshotted before either unit is disposed
  and resolve defender first, then attacker, preserving deterministic ordering.
  Resolver-level coverage verifies the shared group, responsible actors, entry
  tiles, and inventory snapshots across that disposition boundary.

### Anchors
- Code: `scripts/autoloads/GameState.gd`, `scripts/autoloads/DeathLifecycle.gd`

---

## Win/Loss Evaluation

Status: **Target design** (ruling ratified) — project objective checks **Implemented**
Last verified: 2026-06-13

### Summary
Objective checks run at phase boundaries, after combat deaths, and after Seize/Escape.
This section owns the **simultaneous victory/defeat** tiebreak.

### Specs
**Simultaneous victory/defeat (OPEN-6, Answered).** Evaluate **defeat before victory**.
If multiple groups still satisfy victory in one pass, prefer the **acting faction's**
group; otherwise declare the existing draw.

Objective *types* (Rout, Seize, Defeat Boss, Escape, Survive/Defend, Protect) and
authored-map objective contracts are owned by **GDD_06**.

### Anchors
- Code: `scripts/core/TurnManager.gd` (objective checks)
- Decisions: OPEN-6
- Owner of objective types: GDD_06

---

## Status Conditions

Status: **Target design** (locked design; build slots from the start) — Phase 2+ (M8)
Last verified: 2026-06-20

### Summary
Timed conditions stored on `UnitData`. Conditions are **not** skills.

### Specs

Condition rows below are developer-provided built-in condition presets. The target
condition/effect build treats condition ids, potency/duration params, projection, and
application effects as registry data backed by engine primitives (`B5-CONDITIONS`,
`B2-ACTION-EFFECT`, `B3-REQ`).

| Condition | Effect | Duration |
|---|---|---|
| Berserk | Auto-attacks highest projected-damage target in range; tiebreak nearest → lowest unit id; can hit allies | 3 turns |
| Silence | Cannot use `TOME`/`STAFF` weapons (physical unaffected) | 4 turns |
| Sleep | Cannot move/act/counter; dodge disabled | 3 turns |
| Poison | −3 HP at start of turn; **floors at 1 HP** unless source `can_be_lethal`; −10 Accuracy & Dodge | 5 turns |
| Stun | Cannot move/act/counter; dodge disabled | 1 turn |

Storage:
```gdscript
@export var conditions: Array[Dictionary]
# { "type": String, "turns_remaining": int }; extend only when a condition needs more.
```

**Tick timing (amended 2026-06-20, supersedes the activation-based framing in the
2026-05-25 lock).** Split duration ticking from behavioural enforcement:

- **Duration ticking** — Poison's −3 HP and every condition's `turns_remaining`
  decrement at the **start of the holder's faction phase**: the same tick point as
  per-unit `"turn"`-duration modifiers and fort heal (see the whole-phase loop above).
  Poison is therefore parallel to fort heal — a "start of your phase" HP effect. In
  `ALTERNATING` mode (no discrete faction phase) this degrades to **round start**, exactly
  like `"turn"` modifiers already do.
- **Behavioural enforcement** — Sleep/Stun skipping the action, Berserk hijacking the
  target choice, and Silence filtering the action menu are applied at the affected unit's
  **activation** (when it would act), not at the duration tick. A unit asleep at its
  faction-phase tick stays unable to act for that phase even though the tick already ran.

This keeps "lasts N turns" counted once per round (so M10 extra-turn activations do not
double-tick a condition) while preserving the activation-time feel of the disabling
effects. `tick_conditions` (GDD_01) handles the duration half; `TurnManager` /
`EnemyAI` / `ActionMenu` handle the enforcement half.

**Condition/skill precedence (OPEN-2, Answered) — one general rule:**
- Conditions are **not** skills: Nihil/skill-negators **never** block conditions.
- A condition that disables acting (Sleep, Stun) **also suppresses that unit's
  combat-start skills**.
- Per-skill exceptions are logged in `GDD_05`, not here.

### Known gaps
- Phase 2+ (M8). Design locked 2026-05-25 (see `campaign_rules_firming_notes_2026-05-25.md`
  and GDD_10 §M8): Poison `can_be_lethal`, Berserk targeting, Silence filter, schema.

### Anchors
- Code: `scripts/autoloads/ConditionManager.gd`
- Decisions: OPEN-2
- Owner of per-skill interactions: GDD_05

---

## Rescue & Shove

Status: **Split** — Shove design **Target**; Rescue **Planned** (Phase 2)
Last verified: 2026-06-13

### Specs
- **Shove:** non-mounted units push an adjacent unit 1 tile to an unoccupied tile;
  `no_shove` quality blocks it; ends the shover's turn. (Not in the shipped action flow
  yet — see Actions.)
- **Rescue (Phase 2):** pick up an adjacent ally with lower CON; carried unit loses its
  turn; carrier loses ½ SPD and ½ SKL; droppable to an adjacent unoccupied tile.

### Anchors
- Owner of CON/carry systems: GDD_03

---

## Gold & Economy (combat-adjacent)

Status: **Implemented - ledger groundwork** (shops **Planned**)
Last verified: 2026-07-13

### Specs
- Combat/map resolution credits the shared `GameState.party_gold` treasury through
  `ResourceLedger`'s registered party-wallet path.
- Fixed party/unit costs and the bounded `quantity_times_unit_price` formula support
  side-effect-free quote, atomic commit, overflow rejection, and recorded-delta refunds.
  Resource pools and broader economy consumers remain Planned.
- Selling, price formulas, shops, forging, and inventory economy are owned by
  `GDD_04 §Items & Economy`; none are combat-resolution contracts.

### Anchors
- Code: `scripts/autoloads/GameState.gd`, `scripts/autoloads/ResourceLedger.gd`
- Owner of item/economy detail: GDD_04
- Decisions: D-D
