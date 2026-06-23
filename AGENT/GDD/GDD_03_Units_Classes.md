# GDD_03 — Units & Classes

**Status:** Active contract — split status per section (project roster/classes are
**Implemented**; corpus class adoption is **Target design**, AWR-2, tracked in
`GDD_Adoption_Matrix.md`).
**Last verified:** 2026-06-20
**Governance:** section template + status vocabulary in
`AGENT/Docs/documentation_governance_2026-06-13.md`.

This chapter owns unit/class data structure, the starter roster, progression counters,
promotion/reclass **relationships and class targets**, and the class-adoption plan.
Promotion **trigger timing** (the modal/interrupt behavior) is owned by `GDD_02`; combat
math, EXP earning, and leveling mechanics are owned by `GDD_02`.

---

## Unit vs Class

Status: **Implemented**
Last verified: 2026-06-13

### Summary
A **Unit** is an individual character (name, stats, inventory, level); a **Class** is a
template (bases, WEXP baselines/caps, growths, stat caps, skill unlocks, vulnerabilities,
promotion/reclass relationships).

### Specs
- Roster/map units are authored `UnitData` `.tres`; at spawn the resource is duplicated,
  placed, and granted the class skills it should already know at its authored level.
- Level-up/promotion modify `UnitData` directly; `ClassData` is re-read for growths,
  caps, promotion bonuses, skill unlocks, and reclass legality.
- Authoritative progression fields:
  - `UnitData.weapon_wexp` — numeric WEXP totals per track; rank letters derived.
  - `UnitData.earned_skills` (permanent pool) vs `UnitData.skills` (equipped subset).
  - `UnitData.internal_level` (replaces the old `effective_level`).
  - `ClassData.weapon_wexp_bases` / `weapon_wexp_caps` (replace the old proficiency array).
  - `ClassData.skill_unlocks` (replaces `starting_skills` / single-promotion-skill).

### Anchors
- Code: `scripts/resources/UnitData.gd`, `scripts/resources/ClassData.gd`, `scripts/units/Unit.gd`
- Schema owner: GDD_01 (`UnitData`/`ClassData` field definitions)

---

## Special Qualities

Status: **Implemented**
Last verified: 2026-06-13

### Specs
Tags on a unit (from class, or added by skills/items) affecting movement, combat, terrain:

| Quality | Effect |
|---|---|
| `flying` | **Movement type** + vulnerability tag; fliers pay 1 on every non-wall tile |
| `mounted` | **Movement type**: higher mobility/CON; anti-cavalry vulnerability; Canto deferred |
| `armoured` | **Movement type**: high DEF; affected by anti-armor weapons |
| `light_footed` | **Movement type**: mages/thieves; pays 1 in desert (no mount/armour penalty) |
| `infantry` | **Movement type** (explicit default): plain foot movement, no terrain penalty/bonus |
| `dragon` | Effectiveness tag (anti-dragon weapons) — **not** a movement type |
| `beast` | Effectiveness tag (Laguz land units) — **not** a movement type |
| `laguz` | Has a shift gauge (Phase 2+, M12) — **not** a movement type |

**Movement type (V021-11).** The first five tags above are the movement-type subset
(`GameConstants.VALID_MOVEMENT_TYPES`). Every class must declare **at least one**
(enforced by `check_docs.py` [13]); `infantry` is the explicit default. A class may
carry more than one (Great Knight = `armoured` + `mounted`), so
`GameConstants.movement_type_of()` resolves a single type by descending precedence
**`flying > mounted > armoured > light_footed > infantry`** for terrain cost and
display. `GridManager.get_move_cost()` keys terrain cost off the resolved type (after
skill overrides), and the character sheet shows it. Effectiveness is independent:
`vulnerability_groups` still reads every tag, so an armoured+mounted unit is hit by
all matching effective weapons regardless of its resolved movement type. The
non-movement tags (`dragon`/`beast`/`laguz`) are ignored by the resolver.

### Anchors
- Code: `scripts/units/Unit.gd` (`has_quality`, `has_vulnerability`, `movement_type`),
  `scripts/shared/GameConstants.gd` (`VALID_MOVEMENT_TYPES`, `movement_type_of`),
  `scripts/core/GridManager.gd` (`get_move_cost`, `get_move_costs_for_groups`)
- Owner of effectiveness/vulnerability detail: GDD_04

---

## Starter Roster & Classes

Status: **Split** — project roster/classes **Implemented**; corpus class definitions + growth replacement **Target design** (AWR-2)
Last verified: 2026-06-13

### Summary
Six authored starter units load via `GameState.load_default_roster()`. Their `.tres`
files are the authoritative source for stats/growths/skills; the table below is a
reference snapshot.

### Specs

**Implemented (project roster).** All units start level 1.

| Slot | Unit | Class | Start WEXP | Skills | Qualities | Promotes To |
|---|---|---|---|---|---|---|
| 1 | Unit_01 | Cavalier | Lance D | `discipline` | mounted | Paladin, Great Knight |
| 2 | Unit_02 | Mercenary | Sword D | `vantage`, `swordfaire` | — | Hero, Sentinel* |
| 3 | Unit_03 | Archer | Bow D | `bowfaire` | — | Ranger, Sniper |
| 4 | Unit_04 | Mage | Elemental Magic D | `wrath` | — | Mage Knight*, Sage |
| 5 | Unit_05 | Cleric | Staff D, Light E† | `renewal`, `miracle` | — | Bishop*, Paragon* |
| 6 | Unit_06 | Knight | Lance D | `resolve` | armoured | General, Great Knight |

Base stats and personal growth rates are authored per unit in `data/roster/default/`
(`.tres` = source of truth). Bows have `range_min_formula = "2"` — any bow-equipped unit
cannot hit adjacent targets (a weapon property, not a class trait; enforced by
`GridManager` + `CombatResolver.can_counterattack()`).

\* **Project-only promotion targets** (Sentinel, Mage Knight, Bishop, Paragon) are
**Rejected** under RULE-007 — archived to Git history at class migration.
† **Cleric "Light E"** is an **Open decision** (OPEN-10), deferred to the Light/Dark
design pass (RULE-009); do not author a one-off tome or drop it prematurely.

**Target design (corpus class adoption — SET-009 / RULE-007 / RULE-008, AWR-2).**
- Replace project starter classes wholesale with corpus base/promoted classes; provenance
  in `GDD_Adoption_Matrix.md` → `awakening_classes_base.md` / `_promoted.md`.
- **Growths (RULE-008):** effective growth = corpus archetype growth + corpus class
  growth. **Authored personal growths are replaced** (recoverable via Git); the roster is
  rebalanced once combined totals are visible.
- Gender-locked classes normalize to universal definitions unless mechanics diverge.

### Known gaps
- **Soldier class (OPEN-9):** identity resolved at corpus class migration (AWR-2);
  interim, Map 001 keeps a **placeholder enemy-only Soldier**. Marked **Open decision**.
  The placeholder Soldier intentionally authors **no `skill_unlocks`**, so promoting
  or reclassing into it grants **no class skill** — this is by design (decision
  2026-06-14), not a defect. The reclass flow still grants a level-1 skill for any
  class that *does* author one (e.g. Mercenary → `armsthrift`); a class with an empty
  `skill_unlocks` simply has none to grant. Personal earned skills are preserved
  across the reclass regardless.
- **Light/Dark magic class lines (RULE-009):** a dedicated design task (class lines,
  promotion paths, tome access, skill identity, magic-triangle balance) precedes bulk
  class authoring. **Planned.**

### Anchors
- Code: `scripts/autoloads/GameState.gd` (`load_default_roster`), `data/roster/default/`,
  `data/classes/`
- Tests: `scripts/tests/test_unit_stats.gd`
- Decisions: SET-009, RULE-007, RULE-008, RULE-009, OPEN-9, OPEN-10
- Reference: `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_archetypes.md`; `GDD_Adoption_Matrix.md`

---

## Progression Counters

Status: **Split** — `internal_level` **Implemented**; corpus counter model **Target design** (RULE-006/SET-007)
Last verified: 2026-06-13

### Summary
The fields that drive EXP-gain scaling and reclass behavior.

### Specs

**Target model (RULE-006 / SET-007), three separated counters:**
- `displayed_level` — current class-track level (visible).
- `exp_basis_level` — drives EXP-gain bonuses; **resets on reclass** (SET-007).
- `lifetime_levels_gained` — monotonic; reserved for analytics / future enemy
  autoscaling. **Never** used to reduce player EXP unless a campaign rule says so.

Internal level follows the corpus rule `Promoted Internal Level = 20 + Displayed Level`.

**Implemented today:** `UnitData.internal_level` carries hidden progression for
promotion/reclass; the explicit `exp_basis_level` / `lifetime_levels_gained` split is
**Target design** (lands with the corpus progression work).

### Anchors
- Code: `scripts/resources/UnitData.gd` (`internal_level`), `scripts/units/Unit.gd`
- Decisions: SET-007, RULE-006
- Reference: `awakening_core_systems.md` (Leveling / Internal Level)

---

## Promotion (relationships & targets)

Status: **Split** — project eligibility **Implemented**; corpus promotion model **Target design** (SET-006)
Last verified: 2026-06-13

### Summary
*What* a unit promotes into and the state changes applied. ***When* promotion fires and
the modal/interrupt behavior is owned by `GDD_02 → Promotion — Trigger Timing` (RULE-005).**

### Specs

**Implemented (project).** When a unit promotes:
1. `PromotionScreen` offers `ClassData.promotes_to`.
2. The chosen class's `promotion_stat_bonuses` apply immediately.
3. `class_id` changes; `is_promoted = true`.
4. `weapon_wexp` is raised to at least the promoted class's authored baselines.
5. Class skills granted from `skill_unlocks`.
6. `internal_level` recalculated from the promoted class's internal-level rule.
- No blanket growth-rate bonus on promotion. The old single `promotion_skill` /
  `effective_level` model is deprecated.

**Target design (SET-006).** Adopt the corpus promotion model + targets; provenance in
`GDD_Adoption_Matrix.md` → `awakening_core_systems.md` (Promotion System) /
`awakening_appendices.md` (promotion graph). Eligibility begins at corpus level 10 (see
trigger timing in GDD_02).

### Anchors
- Code: `scripts/units/Unit.gd` (`promote`), `scripts/ui/PromotionScreen.gd`
- Manual: `data/maps/map_950_promotion_validation/` — its fixed roster's cavalier
  carries the `debuff_tonic` validation item (V020-14): a `stat_buff` with a
  negative delta so testers can confirm lowered stats render red on previews and
  the character sheet. Validation-only; kept out of the regular roster/shop pipeline.
- Decisions: SET-006, RULE-005 (timing → GDD_02)
- Reference: `awakening_core_systems.md`, `awakening_appendices.md`

---

## Reclass (Second Seal)

Status: **Split** — Second Seal flow **Implemented**; corpus reclass + growth-to-caps **Target design** (SET-007/D-E)
Last verified: 2026-06-13

### Summary
Reclassing reassigns a unit's class via a Second Seal, resetting visible level and the
EXP basis.

### Specs

**Implemented (project).** On Second Seal:
1. `ReclassScreen` offers `Unit.get_second_seal_options()`.
2. The selected class resets visible level to 1.
3. Broader progression preserved via `internal_level`.
4. Promotion stat bonuses from the previous promoted class are removed before applying
   the new class state.

**Target design.**
- **EXP basis reset (SET-007):** reclass resets `exp_basis_level` (see Progression
  Counters); `lifetime_levels_gained` continues to accumulate.
- **Reclass growth to caps (D-E):** Second Seal growth up to **stat caps** is sanctioned;
  stat caps are the balance lever — **no anti-grind guards**.
- Corpus reclass legality/graph: `GDD_Adoption_Matrix.md` → `awakening_appendices.md`.

### Anchors
- Code: `scripts/units/Unit.gd` (`can_reclass`, `get_second_seal_options`, `reclass`),
  `scripts/ui/ReclassScreen.gd`
- Decisions: SET-007, RULE-006, D-E

---

## Promotion Items

Status: **Implemented** (Master Seal, Orion Bolt, Guiding Ring, Second Seal)
Last verified: 2026-06-13

### Specs

| Item | Eligible |
|---|---|
| Master Seal | Any eligible unit at its current class maximum |
| Orion Bolt | `allowed_classes = ["archer"]` |
| Guiding Ring | `allowed_class_groups = ["mystic"]` |
| Second Seal | Any unit with a legal reclass option |

Promotion items use the same eligibility gate as level-up promotion (no early
promotion). Eligibility lives in each item's `effect_params`
(`{ "allowed_classes": [...] }` / `{ "allowed_class_groups": [...] }`). Other handbook
promotion items remain Planned content (not live resources).

### Anchors
- Code: `scripts/items/ItemHandler.gd`, `data/items/`
- Owner of item data schema: GDD_04

---

## New Game Runtime Setup

Status: **Implemented**
Last verified: 2026-06-13

### Specs
`NewGameScreen` does not do character creation; it sets per-run rules + launch state:
select a map (`map_registry.json`), toggle Permadeath, toggle Auto Promote, choose
Leveling (Random/Fixed), toggle Pair Up. Roster identity comes from authored `UnitData`.
Character creation is a separate future milestone.

### Anchors
- Code: `scripts/ui/NewGameScreen.gd`
- Owner of launch/roster-policy flow: GDD_01

---

## Adding Future Classes (operational)

Status: **Reference** (process, not a rule)
Last verified: 2026-06-13

### Specs
To add a class: author `data/classes/<id>.tres` (`ClassData`), fill all fields incl.
promotion paths (empty array if none), update referencing roster/map data, add/extend
tests or validation maps if progression/equipment flow changes. No code changes unless a
new mechanic is introduced. Every usable WEXP track needs an authored `weapon_wexp_caps`
entry (current classes default to A = 400 WEXP; S caps are opt-in).

> Class **priority/order** for the corpus migration is owned by the roadmap
> (`GDD_10`, AWR-2), not this chapter.

### Anchors
- Guide: `AGENT/Docs/guides/map_authoring_guide.md` (authoring), GDD_01 (`ClassData` schema)
- Roadmap: AWR-2
