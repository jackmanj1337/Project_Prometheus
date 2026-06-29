# GDD_02 — Core Mechanics

**Status:** Active contract — split status per section (project behavior is
**Implemented**; corpus migration is **Target design**, tracked in
`GDD_Adoption_Matrix.md`).
**Last verified:** 2026-06-29
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This chapter owns combat resolution, the RNG/hit model, stats and derived combat
values, terrain combat, WEXP, combat EXP, leveling, and promotion *trigger timing*.
Class definitions, promotion targets, and progression *relationships* are owned by
`GDD_03`. Determinism architecture (autoloads, snapshot/save) is owned by `GDD_01`.

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
Terrain grants the defender DEF/Dodge and sets movement cost; some tiles heal.

### Specs

**Implemented (project values).** Terrain bonuses apply to the **defending unit only**;
attackers get none. Bonuses are added during combat and never permanently modify stats.

| Terrain | DEF | Dodge | Move | Notes |
|---|---|---|---|---|
| Plain | 0 | 0 | 1 | |
| Forest | +1 | +15 | 2 | |
| Mountain | +2 | +20 | 3 | |
| Fort | +2 | +30 | 1 | Heals per turn (see fort heal below) |
| Sea | 0 | +10 | 2 | |
| Desert | 0 | +5 | 2 | Armoured/Mounted cost 3; Magic/Thief line cost 1 |
| Wall / Building | — | — | Impassable | |

**Fort/throne heal (OPEN-7, Answered).** A unit standing on a healing tile recovers
`heal = max(1, floor(0.10 × max_hp))` at start of turn (Renewal rounding — guarantees
at least 1).

**Target design (corpus terrain, SET-008/RULE-010).** Corpus terrain values and
movement categories are an adopted target; show both tables until code/data/maps
migrate. Flying uses terrain movement-cost categories (Planned), never a
terrain-ignoring special case.

The tables above are shipped/developer preset data. Terrain bonuses, healing profiles,
movement categories, and topology-specific distance rules should be loaded from
authorable terrain/rule data as the CampaignRules and map-schema work lands.

### Known gaps
- **Throne art currently reuses Fort behavior** — terrain ID mapping (sea, wall/building
  variants, throne) is **Open decision**, deferred to roadmap **AWR-8** (RULE-011). Do
  not assume name-equality mappings.

### Anchors
- Code: `scripts/core/GridManager.gd`; terrain data resources
- Decisions: SET-008, RULE-010, RULE-011, OPEN-7
- Reference: `awakening_lookup_tables.md` (terrain/movement); `GDD_Adoption_Matrix.md`
- Owner of authored map/terrain schema: GDD_06

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

Status: **Split** — exchange flow **Implemented**; two-RN hit model **Target design** (RULE-001)
Last verified: 2026-06-13

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

**Hit/crit per strike — two-RN model (RULE-001, Target design).** Each strike draws
**two** integers 0–99 (`r1`, `r2`) and hits when `floor((r1 + r2) / 2) < To-Hit %`.
A crit roll is drawn **only if the hit landed**. Both hit draws are always consumed
(miss = 2 draws, hit = 3) so the roll order never depends on the outcome.
- This **supersedes** the former single-roll rule (`randi() % 100`, `roll < pct`).
- Damage = the Derived value (DEF/RES subtracted once). A critical **triples the final
  figure** (`×3`); any skill damage-multiplier applies last; clamp to ≥0.
- If the target's HP ≤ 0, the exchange stops — no further attacks land.

**Determinism (RNG-1…4, see GDD_01).** All gameplay dice come from `RngService` (hash-
chained, context-seeded), not `randi()`. The **canonical roll order** per attack — two
hit RNs, then a crit RN on a hit, then skill activation rolls at their trigger slots —
is the binding contract; reordering it is a save/replay-breaking change. Architecture,
autoload order, snapshot persistence, accepted exploits, and the online model are owned
by `GDD_01 → Determinism & RNG`; the build/implementation plan is
`AGENT/Docs/design/rng_determinism_design_2026-06-11.md`.

**Mid-exchange weapon breakage (OPEN-3, Answered).** If a weapon breaks mid-exchange,
it **cancels that unit's remaining strikes** in the exchange (consistent with
attacks-determined-upfront and the deterministic roll order); the weapon is gone after
combat.

`CombatResolver` resolves an exchange the instant the player confirms (no combat
animation yet): `resolve_combat()` builds the list and draws rolls; `apply_combat_result()`
commits HP/durability/EXP. See GDD_01 → CombatResolver.

### Known gaps
- Two-RN model and `RngService` are **Target design** — not yet implemented (Package A,
  RngService Build Order Step 1).
- Units with no usable equipped weapon cannot attack; counterattacking from a non-equipped
  inventory weapon is Phase 2+.

### Anchors
- Code: `scripts/core/CombatResolver.gd` (target: `scripts/autoloads/RngService.gd`)
- Tests: `scripts/tests/test_combat.gd` (target: RNG determinism T1–T7)
- Decisions: RULE-001, RNG-1…4, OPEN-3, pipeline order
- Reference: `GDD_Adoption_Matrix.md`; `AGENT/Docs/design/rng_determinism_design_2026-06-11.md`

---

## Weapon Durability

Status: **Split** — project model **Implemented**; breakage-cancels-strikes **Target design** (OPEN-3)
Last verified: 2026-06-13

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
Units accumulate numeric WEXP per weapon track; rank letters derive from thresholds.

### Specs

**Implemented (project).**
- Per-track totals, e.g. `{ "sword": 100, "lance": 40 }`.
- Each successful hit grants `weapon.wexp` to that track; ranks derive via
  `GameConstants.WEXP_RANK_THRESHOLDS`.
- A unit equips only weapons at/below its current rank for that type.
- Class resources author WEXP baselines/caps; promotion/reclass raise a unit to at
  least the new class's baselines for gained tracks. Gain stops at the class's authored
  cap (default A; explicit S-cap classes may exist).
- **S-rank bonus:** applies at the S-rank step of the pipeline; values owned by
  GDD_04 §S-Rank Weapon Bonus (not restated here).

**Target design.**
- **WEXP thresholds/caps (SET-004):** corpus values E=1, D=31, C=71, B=121, A=181,
  S=251, Cap=400.
- **Gain timing (RULE-004):** per **valid use** (corpus-style), weapon-defined
  exceptions; may change in a balance pass.
- **Migration (RULE-003):** proportional within current rank; no persistent save to
  migrate, so this governs runtime/in-session conversion. Formula in the register.
- **Rank bonuses (SET-005/RULE-002):** move rank bonuses into the **combat engine**;
  retire `s_rank_mastery` as a pseudo/equipped skill. The S-rank extension
  is the project variation (values owned by GDD_04 §S-Rank Weapon Bonus).

### Anchors
- Code: `scripts/autoloads/DataManager.gd`, `GameConstants` (`WEXP_RANK_THRESHOLDS`)
- Decisions: SET-004, SET-005, RULE-002, RULE-003, RULE-004
- Owner of weapon-rank detail/economy: GDD_04
- Reference: `awakening_lookup_tables.md`; `GDD_Adoption_Matrix.md`

---

## Actions on a Unit's Turn

Status: **Implemented** (with noted future actions)
Last verified: 2026-06-13

### Specs
A unit may Move then take **one action**, or act in place. Shipped action flow:
**Move, Attack, Staff, Item, Equip, Wait, Seize, Escape, Pair Up, Swap, Separate**.

| Action | Ends turn? | Notes |
|---|---|---|
| Move | No | Up to MOV; undoable until an action commits |
| Attack | Yes | Valid target in range |
| Staff | Yes | Heal ally in range; awards EXP + WEXP |
| Use Item | Yes | Consumes one use |
| Equip Weapon | No | Switch active weapon |
| Trade | No* | Adjacent ally; ends turn only if already moved |
| Shove | Yes | Push adjacent non-mounted ally 1 tile |
| Pair Up / Swap / Separate | Yes | When campaign Pair Up enabled |
| Wait / Seize / Escape | Yes | Wait ends turn; Seize/Escape are objective actions |
| Class Ability | Yes | If it requires an action |

> *Trade: may still act if not yet moved this turn.

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

Status: **Implemented**
Last verified: 2026-06-13

### Summary
Symmetric combat/staff EXP; 100 EXP = one level, overflow carries.

### Specs
- EXP goes to whichever unit dealt a blow (player and enemy alike), once per **combat
  exchange** (not per hit). WEXP increases per successful **hit**.
- Level difference = acting unit's level − opponent's; `CombatResolver.calculate_exp()`
  indexes the table with `clamp(level_diff + 6, 0, 12)`.

The table is the shipped EXP-curve preset. Expanded campaign rules should load EXP curves
or formula profiles from data rather than baking new balance tables into the resolver.

| Lvl diff (acting − opp) | Kill | Damage only |
|---|---|---|
| 6+ lower | 59 | 20 |
| 5 / 4 / 3 / 2 / 1 lower | 57 / 53 / 47 / 41 / 35 | 19 / 18 / 16 / 14 / 12 |
| Equal | 30 | 10 |
| 1 / 2 / 3 / 4 / 5 higher | 25 / 19 / 13 / 7 / 3 | 8 / 6 / 4 / 2 / 1 |
| 6+ higher | 1 | 0 |

- **Enemy/AI EXP gating (OPEN-4, Target):** EXP gain is faction-gated via
  `CampaignRules.exp_gaining_factions`; the shipped preset is Blue + Green, Red none.
  Owner of the CampaignRules contract: GDD_01 (Stage 3.5).
- **Staff/action EXP (Implemented):** heal staff currently awards a flat preset amount
  (`GameConstants.STAFF_HEAL_EXP`). Target `[AGT §6]`/`B4-PXP` moves non-combat EXP to
  authored action data (`exp_award`) with campaign defaults, not hardcoded staff logic.

### Anchors
- Code: `scripts/core/CombatResolver.gd` (`calculate_exp`), `GameConstants`
- Decisions: OPEN-4

---

## Leveling Up

Status: **Implemented** (Random + Fixed); other methods **Planned**
Last verified: 2026-06-13

### Specs
At 100 EXP: level +1, EXP resets (overflow carries), stats rise per the save's
`GameState.leveling_method`.

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

**Implemented (project).** A unit may promote at its class `max_level` with an authored
`promotes_to`; promotion items use the same gate (no early promotion). Visible level
resets to 1; progression preserved in `internal_level`; promoted skills learn at their
`skill_unlocks` levels.

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
Last verified: 2026-06-13

### Specs
Controlled by `GameState.permadeath_enabled`.
- **ON:** at 0 HP the unit leaves the map; `UnitData` is retained and flagged
  `is_incapacitated = true`; cannot be deployed later; never deleted (revival/viewing
  possible).
- **OFF:** the unit is removed for that map only and is fully available next map; no
  flag set.
- **Game Over:** if a designated required unit (e.g. the lord) dies, the map ends in
  defeat → retry screen, regardless of the setting.

### Anchors
- Code: `scripts/autoloads/GameState.gd`

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

Status: **Implemented** (shops **Planned**)
Last verified: 2026-06-13

### Specs
- Shared `GameState.party_gold` treasury; map rewards add once on map resolve.
- Sale price: `floor(base_cost × (uses_remaining / max_uses) / 2)`.
- Shops are Phase 2 (scenes); a campaign-mode prerequisite (D-D).

### Anchors
- Code: `scripts/autoloads/GameState.gd`
- Owner of item/economy detail: GDD_04
- Decisions: D-D
