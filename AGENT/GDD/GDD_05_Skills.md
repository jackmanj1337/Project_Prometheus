# GDD_05 — Skills

**Status:** Active contract — split status per section (the skill handler, proc-RNG
sourcing, and Pair Up pass 1 are **Implemented**; corpus skill acquisition, Pair Up
value migration, Dual Strike/Guard, and supports are **Target design / Planned /
Deferred**, tracked in `GDD_Adoption_Matrix.md`).
**Last verified:** 2026-07-13
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This chapter owns the skill system (data model, triggers, handler surface), **per-skill
condition/skill precedence exceptions**, skill acquisition, and the **Pair Up & support**
layers. The general condition-vs-skill rule and the combat exchange that fires triggers
are owned by `GDD_02`. The `SkillHandler` autoload contract and combat-context schema are
owned by `GDD_01`. Skill *unlock data per class/level* relates to class definitions in
`GDD_03`.

---

## Skill System Overview

Status: **Implemented**
Last verified: 2026-06-13

### Summary
Skills are data-defined modifiers or triggered effects attached to units; the handler is
a lookup table keyed by `effect_id` and trigger context in the implemented build.
Target skill/effect authoring resolves `effect_id` through the shared action/effect
registry (`B2-ACTION-EFFECT`, `B5-SKILLS-EFFECTS`) so data-composed effects do not need
new `SkillHandler` branches.

### Specs
- Skills are `SkillData` resources in `data/skills/`, executed by `SkillHandler.gd`.
  They are **not hardcoded per class** — a unit carries a list of skill IDs.
- **Equipped cap: 5** (`CampaignRules.max_skills`). No manual equip UI yet; the cap gates
  auto-equipped learned skills. Earned mastery skills (`UnitData.mastery_skills`, e.g.
  `s_rank_mastery`) **never** count against the cap. A future campaign-settings layer may
  override the default — the five-skill default is **Implemented**.

### Anchors
- Code: `scripts/skills/SkillHandler.gd` (autoload), `scripts/resources/SkillData.gd`,
  `data/skills/`, `scripts/resources/CampaignRules.gd` (`max_skills`)
- Tests: `scripts/tests/test_skill_item_handler.gd`
- Schema owner: GDD_01 (`SkillData`, combat-context); equipped/earned split owner: GDD_03

---

## Skill Categories

Status: **Reference** (taxonomy)
Last verified: 2026-06-13

### Specs

| Category | Description | Example |
|---|---|---|
| **Generic** | Any unit can hold these; not class-specific | Adept, Renewal, Nihil |
| **Class (Starting)** | Granted at class creation | Pick (Thief), Reinvigorate (Bard) |
| **Promotion** | Granted automatically at promotion | Hawkeye (Sniper) |
| **Occult** | Powerful; granted via Occult Scroll after promotion | Deadeye (Sniper) |
| **Laguz** | Laguz-only; granted at would-be promotion level | Nimble (Cat) |

---

## Skill Triggers

Status: **Implemented** (live set) + **Planned** (reserved hooks)
Last verified: 2026-06-13

### Summary
Skills fire at named points in the loop; authored data alone does not mean a trigger is
wired end to end.

### Specs

| Trigger ID | When It Fires |
|---|---|
| `passive` | Always active; modifies a stat or rule permanently |
| `start_of_turn` | At the start of the unit's turn |
| `on_combat_start_negate` | Pre-pass before `on_combat_start` — for skill-cancellers (Nihil) |
| `on_attack` | When this unit makes an attack (before damage) |
| `on_defend` | When this unit is attacked (before damage) |
| `on_hit` | When this unit's attack successfully hits |
| `on_kill` | When this unit kills an enemy |
| `on_damaged` | When this unit takes damage |
| `on_move` | After this unit moves |
| `on_combat_start` | Before any attacks in a combat exchange resolve |
| `on_combat_end` | After all attacks in a combat exchange resolve |
| `on_level_up` | When this unit levels up |
| `player_activated` | Player manually triggers the skill |

**Wired (Implemented):** `start_of_turn`, `on_combat_apply_modifiers`,
`on_combat_start_negate`, `on_combat_start`, `on_attack`, `on_hit`, `on_damaged`,
`on_kill`, `on_combat_end`, plus the WEXP and staff helper seams.
**Reserved (Planned):** `on_defend`, `on_move`, `on_level_up`, `player_activated` —
until callers are implemented.

The table is the built-in trigger registry for the current engine. New trigger points
are engine primitives; new skill behavior should first try existing trigger + context
flags + action/effect composition before adding another trigger id.

### Known gaps
- **Trigger discipline (M9, locked 2026-05-25):** do not add a new trigger during M9
  unless an existing trigger + a `context.flags.*` value provably cannot express the
  skill (see Full Skill Reference).

### Anchors
- Code: `scripts/skills/SkillHandler.gd`; callers in `CombatResolver.gd`, `TurnManager.gd`, `GridManager.gd`
- Owner of the combat exchange that fires triggers: GDD_02 §Combat Resolution

---

## SkillHandler Architecture

Status: **Implemented**
Last verified: 2026-06-13

### Summary
An autoload that, given a unit + trigger + context, fires every matching skill and
mutates a shared combat-context `Dictionary` in place.

### Specs
`CombatResolver`, `TurnManager`, and `GridManager` call `apply_trigger()`; it iterates
equipped (`UnitData.skills`) **and** earned mastery skills (`UnitData.mastery_skills`).
Preview calls exclude random activations, Nihil-blocked calls admit only explicit
exemptions, and dry runs apply forecast effects without persisting limited-use counters.
The exact callable signature and combat-context fields live with the runtime contract in
`GDD_01` and production code.

- Per skill, `apply_trigger` enforces `max_uses_per_map` / `max_uses_per_combat`, rolls
  `activation_chance_stat / activation_divisor` if set, then dispatches via a
  `{ effect_id: Callable }` table built in `_ready()`. Unknown IDs are startup errors;
  known-future IDs dispatch to `_apply_unimplemented` and warn at runtime.
- `SkillData.release_available` is the shared release-content capability flag.
  Unimplemented skills set it false, excluding them generically from player-facing
  choices while legacy/debug data stays loadable and retains the development warning.
- A handler returns `true` only when its effect actually applied, so a limited use is
  consumed only on a real activation.
- Combat-context channels: `atk_mod` / `def_mod` (`accuracy`, `damage`, `crit`,
  `crit_avoid`, `dodge`, `strikes`, `damage_multiplier`) and `flags` (`vantage`,
  `skip_effectiveness`, lifesteal, …). Nihil sets
  `attacker_skills_blocked` / `defender_skills_blocked`. Full schema: `CombatResolver.gd`
  file header (binding contract owned by GDD_01).

### Anchors
- Code: `scripts/skills/SkillHandler.gd`
- Owner of the combat-context schema: GDD_01

---

## Skill Activation & RNG

Status: **Implemented**
Last verified: 2026-07-13

### Summary
Random-activation ("proc") skills roll an activation chance; that roll must come from the
deterministic event stream, not `randi()`.

### Specs
- Rate = `activation_chance_stat / activation_divisor` (for example, SKL-based); combat
  preview excludes random-activation skills so the forecast stays deterministic.
- Live proc skills draw from the current `RngService` event's private RNG supplied in
  the trigger context. A missing RNG on a live random trigger is an error and consumes
  no fallback randomness.
- Proc draws occur at their declared trigger slots in the canonical roll order. Moving
  a skill roll or changing its draw count is a save/replay-breaking change.

### Anchors
- Code: `scripts/skills/SkillHandler.gd` (`apply_trigger` activation gate)
- Decisions: RNG-1, OPEN-2
- Owner of the canonical roll order: GDD_02 / GDD_01

---

## Condition / Skill Precedence (per-skill exceptions)

Status: **Target design** (per OPEN-2; general rule owned by GDD_02)
Last verified: 2026-06-13

### Summary
The general "conditions are not skills" rule lives in `GDD_02 §Status Conditions`. This
section owns the **per-skill exceptions** to it.

### Specs
- General rule (GDD_02, OPEN-2): conditions are **not** skills — Nihil/skill-negators
  never block conditions; a condition that disables acting (Sleep, Stun) also suppresses
  that unit's combat-start skills.
- **Per-skill exceptions** are logged **here** as each skill is authored (none recorded
  yet beyond the general rule). When a skill must deviate (e.g. a skill that explicitly
  interacts with a condition), record the exception in this section with its `effect_id`.

### Anchors
- Decisions: OPEN-2
- Owner of the general rule + condition definitions: GDD_02 §Status Conditions

---

## MVP Skills

Status: **Implemented**
Last verified: 2026-06-13

### Summary
Skills with `.tres` files in `data/skills/` and a live handler. `effect_id` is the
dispatch key; several skills share one handler via `effect_params`.

### Specs

**Generic battle skills**

| Skill (`.tres` id) | Trigger | effect_id | Effect |
|---|---|---|---|
| `renewal` | `start_of_turn` | `renewal` | Heal 10% of max HP (rounded down, min 1). |
| `vantage` | `on_combat_start` | `vantage` | When defending, this unit's counter strikes first. |
| `nihil` | `on_combat_start_negate` | `nihil` | Negates the opponent's battle skills this combat (except mastery skills and Nihil itself). |
| `resolve` | `on_combat_start` | `resolve` | +50% STR/MAG/SKL/SPD while HP ≤ 50%, as combat-duration modifiers. |
| `wrath` | `on_combat_start` | `wrath` | +50 Crit while HP ≤ 50%. |
| `miracle` | `on_damaged` | `miracle` | (LUK / divisor) % chance to survive an otherwise-lethal blow at 1 HP. |

**Shared-handler combat/passive skills**

| Skill (`.tres` id) | Trigger | effect_id | Effect |
|---|---|---|---|
| `skill_plus_2` / `magic_plus_2` / `defense_plus_2` | `on_combat_start` | `stat_bonus` | Add authored combat-duration stat modifier (`effect_params.stat` / `amount`). |
| `prescience` | `on_combat_start` | `prescience` | Attacker-only hit/avoid bonus. |
| `patience` | `on_combat_start` | `patience` | Defender-only hit/avoid bonus. |
| `focus` | `on_combat_start` | `focus` | Crit bonus when no ally is within the authored radius. |
| `discipline` | `passive` | `discipline` | Doubles WEXP gain via `get_wexp_multiplier()`; not a combat modifier. |
| `healtouch` | `passive` | `healtouch` | Flat staff-heal bonus via `get_staff_heal_bonus()`; not a combat modifier. |

**Weapon-type skills** (one `.tres` per type, shared handler)

| Skills | Trigger | effect_id | Effect |
|---|---|---|---|
| `swordfaire` / `lancefaire` / `bowfaire` | `on_combat_start` | `faire` | +N damage with the matching weapon type. |
| `swordbreaker` / `lancebreaker` / `bowbreaker` | `on_combat_start` | `breaker` | +Hit attacking / +Dodge defending vs the matching opposing weapon type. |

**Earned mastery skill**

| Skill | Trigger | effect_id | Effect |
|---|---|---|---|
| `s_rank_mastery` | `on_combat_start` | `s_rank_mastery` | +10 Hit, +5 Crit, +1 Damage with a weapon type held at S rank. Auto-granted by `Unit.add_wexp()` on first S rank; stored in `UnitData.mastery_skills`; never assignable in a `.tres`. |

### Known gaps
- **Still deferred:** aura handlers (`charm`, `anathema`, `daunt`); terrain/mobility
  helpers (`get_move_cost_override`, `can_pass_through_enemies`, `can_phase_through`);
  the Phase-2 catalogue below.
- **`s_rank_mastery` retirement (SET-005/RULE-002, Target):** the S-rank bonus migrates
  into the combat engine and this pseudo-skill is retired — owned by GDD_04 §S-Rank Weapon
  Bonus.

### Anchors
- Code: `scripts/skills/SkillHandler.gd`, `data/skills/`
- Tests: `scripts/tests/test_skill_item_handler.gd`
- Decisions: SET-005, RULE-002 (GDD_04)

---

## Skill Acquisition

Status: **Split** — project auto-grant **Implemented**; corpus acquisition-by-class/level **Target design**
Last verified: 2026-06-13

### Summary
How a unit comes to know a skill.

### Specs
- **Implemented:** spawn grants the class skills a unit should already know at its
  authored level; promotion grants `ClassData.skill_unlocks`; earned mastery skills are
  granted by gameplay (first S rank). Earned pool = `UnitData.earned_skills`; equipped
  subset = `UnitData.skills` (capped at 5).
- **Target design:** adopt corpus **skill acquisition by class and level** (which class
  learns which skill at which level); provenance `GDD_Adoption_Matrix.md` →
  `awakening_skills.md`, `awakening_classes_*`. Proc-skill rate formulas adopted as
  target (draw from event RNG — see Skill Activation & RNG).

### Known gaps
- **Cleric "Light E" (OPEN-10 / RULE-009):** whether the Cleric line gets Light-tome
  access is an **Open decision**, resolved by the Light/Dark design pass. Owned with the
  class roster in GDD_03 §Starter Roster; do not author a one-off tome here.

### Anchors
- Code: `scripts/units/Unit.gd` (skill grants), `data/classes/` (`skill_unlocks`)
- Decisions: RULE-009, OPEN-10
- Owner of class skill-unlock data: GDD_03; Reference: `awakening_skills.md`

---

## Full Skill Reference (Phase 2)

Status: **Target design / Planned** (Phase 2, M9)
Last verified: 2026-06-13

### Summary
The handbook skill catalogue, listed to reserve built-in `effect_id` strings before
implementation. These reservations are planned primitives or developer presets, not a
closed ceiling on author-created data compositions.

### Specs

> **Implementation rules.** Exact state and sequencing are owned by control-plane row
> `B5-SKILLS-EFFECTS` and its linked plan.
> 1. Close each required engine primitive and its focused tests before bulk-authoring
>    the corresponding skill `.tres` data.
> 2. **Trigger discipline — strict reuse, flags first** (see Skill Triggers).
> 3. **Effect computation — hybrid.** Threshold/state-dependent effects (Resolve's ≤50%
>    gate, Frenzy, Aegis halving) are evaluated **at query time**; static passives (Zeal,
>    Tough) remain stored modifiers added at initialisation.
> 4. **Pair Up / Rescue remain separate consumers.** Skill-effect work must not depend on
>    `pair_up`, `support`, or `rescue` semantics — those are campaign-rule features (see
>    Pair Up & Support System below, and
>    `AGENT/Docs/archive/reference/campaign_rules_firming_notes_2026-05-25.md`).

**Generic skills (Phase 2):** Adept, Barrier (+2 RES), Cancel, Celerity (+2 MOV), Clear
Vision (+2 LoS), Corrosion, Daunt (aura, reserved), Discipline, Focus, Fortunate (+2 LUK),
Gamble, Loot, Nihil*, Nullify, Perceptive, Prowess (+2 SKL), Renewal*, Resolve*, Savior,
Smite, Swift (+2 SPD), Tough (+2 DEF), Unorthodox, Vantage*, Vigor (+5 HP), Wrath*, Zeal
(+2 STR). (* already in MVP.)

**Promotion skills (Phase 2):** one per promoted class — Swiftfoot (Ranger), Hawkeye
(Sniper), Frenzy (Berserker), Strike True (Paladin), Counter (Vanguard), Bastion
(General), Pavise (Great Knight), Phasing (Sage), Dash (Hero), Reaper (Assassin), Steal
(Rogue), and the remaining handbook set authored alongside each class. Promotion-skill
mapping follows the adopted corpus class roster (GDD_03); project-only class skills tied
to Rejected classes (RULE-007) are dropped with their classes.

### Anchors
- Code: `scripts/skills/SkillHandler.gd` (`_apply_unimplemented` placeholders)
- Tracking: `B5-SKILLS-EFFECTS`
- Owner of class roster: GDD_03; Reference: `awakening_skills.md`

---

## Pair Up & Support System

Status: **Split** — Pair Up pass 1 **Implemented**; corpus bonus values **Planned** (RULE-012/SET-010); Dual Strike/Guard **Target design**; supports 4–8 **Deferred** (OPEN-1)
Last verified: 2026-06-16

### Summary
Pair Up layers a support unit onto a lead. Pass 1 (stat bonuses + pairing actions) ships
today; the deeper layers are scheduled or deferred.

### Specs

**Implemented (pass 1).**
- `PairUpRegistry` (autoload) is the single source of truth: `unit_id → { partner_id,
  role }`, both sides stored. Snapshotted by `GameState` with the map-start snapshot so a
  Retry rewinds pairings (roles `lead` / `support`; a paired support occupies the
  `OFF_MAP_TILE` sentinel).
- `PairUpBonusResolver` (autoload) computes the support's stat bonus to its lead from a
  `PairUpBonusTable` resource. Both combat preview and live combat call `bonuses_for()`,
  so forecast and fight never disagree; bonuses apply as `duration_type="combat"`
  modifiers at the **pair-up step** of the modifier pipeline (GDD_02). Each stat is
  stamped under a **distinct modifier source** (`pair_up:<support_id>:<stat>`) — a
  shared source made each stat's `add_modifier` wipe the previous one, so only the last
  bonus survived and a paired lead's combat stats never actually changed (playtest
  v0.1.4 #8.5; fixed 2026-06-14).
- Pairing actions (Pair Up / Swap / Separate) are in the shipped action flow (GDD_02
  §Actions), gated by the campaign Pair Up toggle (`NewGameScreen`).
- `PairUpRegistry` emits `EventBus.pair_up_changed()` after pair, separate, swap,
  clear, and restore operations. `Unit` nodes use that signal to show the on-map
  `PU` badge for paired leads, and `UnitDetailsScreen` uses the registry plus
  `GameState.find_unit_by_id()` to open the paired partner's sheet.

**Planned — value migration (RULE-012 / SET-010).** The pass-1 *mechanism* is
Implemented; migrating the bonus **values** to corpus numbers is **Planned** (re-author
`pair_up_bonus_table.tres`; no engine change). Corpus is the eventual target.

**Target design — Dual Strike (layer 2) & Dual Guard (layer 3).** Scheduled together
under the AWR combat foundation (RULE-012); not yet built.

**Deferred (post-1.0, OPEN-1) — layers 4–8.** Adjacent support, support ranks /
conversations, S-rank / marriage, and child units / inheritance are a committed feature
deferred **post-1.0**. Do not author them now.

### Known gaps
- M9 skill content must not depend on Pair Up/support/rescue semantics (see Full Skill
  Reference, locked rule 4).

### Anchors
- Code: `scripts/autoloads/PairUpRegistry.gd`, `scripts/autoloads/PairUpBonusResolver.gd`,
  `scripts/resources/PairUpBonusTable.gd`, `data/pair_up/pair_up_bonus_table.tres`
- Tests: `test_pair_up_registry.gd`, `test_pair_up_bonus_resolver.gd`, `test_pair_up_combat_context.gd`
- Decisions: SET-010, RULE-012, OPEN-1
- Owner of pipeline order + pairing actions: GDD_02; Reference: `awakening_core_systems.md`; `GDD_Adoption_Matrix.md`

---

## Adding a New Skill (operational)

Status: **Reference** (process, not a rule)
Last verified: 2026-06-13

### Specs
The operational checklist lives in `AGENT/Docs/guides/map_authoring_guide.md`
(`Skill authoring`). This chapter retains trigger semantics, player-facing effects,
acquisition, and precedence contracts.

### Anchors
- Code: `scripts/skills/SkillHandler.gd`, `scripts/resources/SkillData.gd`
- Guide: `AGENT/Docs/guides/map_authoring_guide.md`
- Schema owner: GDD_01
