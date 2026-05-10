# GDD_05 — Skills

---

## Skill System Overview

Skills are modifiers or triggered effects attached to units. They are defined as
`SkillData` resources in `data/skills/` and executed by `SkillHandler.gd`.

Skills are **not hardcoded per class** — they are data entries. A unit carries a list
of skill IDs. The skill handler is a lookup table: given a skill ID and a trigger
context, it applies the effect.

**Maximum skills per unit:** 4 (configurable in `GameState.max_skills`).

---

## Skill Categories

| Category | Description | Example |
|---|---|---|
| **Generic** | Any unit can hold these; not class-specific | Adept, Renewal, Nihil |
| **Class (Starting)** | Granted at class creation; some classes start with one | Pick (Thief), Canto (Bard) |
| **Promotion** | Granted automatically at promotion | Hawkeye (Sniper) |
| **Occult** | Powerful; granted via Occult Scroll after promotion | Deadeye (Sniper) |
| **Laguz** | Laguz-only; granted at would-be promotion level | Nimble (Cat) |

---

## Skill Triggers

Skills fire at specific points in the game loop. `SkillHandler.gd` provides hook
methods for each trigger. Every relevant code path calls the appropriate hook.

| Trigger ID | When It Fires |
|---|---|
| `passive` | Always active; modifies a stat or rule permanently |
| `start_of_turn` | At the start of the unit's turn |
| `start_of_enemy_turn` | At the start of an enemy unit's turn (for aura effects) |
| `on_attack` | When this unit makes an attack (before damage) |
| `on_defend` | When this unit is attacked (before damage) |
| `on_hit` | When this unit's attack successfully hits |
| `on_kill` | When this unit kills an enemy |
| `on_damaged` | When this unit takes damage |
| `on_move` | After this unit moves |
| `on_combat_start` | Before any attacks in a combat exchange resolve |
| `on_combat_end` | After all attacks in a combat exchange resolve |
| `on_level_up` | When this unit levels up |
| `player_activated` | Player manually triggers the skill (costs the action or is free) |

---

## `SkillHandler.gd` Architecture

```gdscript
# scripts/skills/SkillHandler.gd
extends Node

# Called by CombatResolver, TurnManager, etc.
# context is a Dictionary with relevant data (attacker, defender, damage, etc.)

func apply_trigger(unit: Unit, trigger: String, context: Dictionary) -> Dictionary:
    for skill_id in unit.data.skills:
        var skill: SkillData = DataManager.get_skill(skill_id)
        if skill.trigger == trigger:
            context = _execute_skill(skill, unit, context)
    return context

func _execute_skill(skill: SkillData, unit: Unit, context: Dictionary) -> Dictionary:
    match skill.effect_id:
        "stat_bonus":       return _apply_stat_bonus(skill, unit, context)
        "renewal":          return _apply_renewal(skill, unit, context)
        "adept":            return _apply_adept(skill, unit, context)
        "cancel":           return _apply_cancel(skill, unit, context)
        "vantage":          return _apply_vantage(skill, unit, context)
        "nihil":            return _apply_nihil(skill, unit, context)
        "canto":            return _apply_canto(skill, unit, context)
        "hawkeye":          return _apply_hawkeye(skill, unit, context)
        # ... add new effect_ids here as skills are implemented
        _:
            push_warning("Unknown skill effect_id: " + skill.effect_id)
            return context
```

The `context` dictionary is the shared data structure passed between skill applications.
Skills can read and modify it. After all skills are applied, `CombatResolver` reads
the final values.

Example context for `on_attack`:
```gdscript
{
  "attacker": Unit,
  "defender": Unit,
  "weapon": WeaponData,
  "accuracy": int,         # can be modified by skills
  "damage": int,           # can be modified
  "crit_rate": int,        # can be modified
  "additional_attacks": int,
  "cancel_counter": bool,  # if true, defender cannot counterattack
  "is_critical": bool,
  "skill_blocked": bool    # if true (from Nihil), enemy skills don't fire
}
```

---

## MVP Skills

Implement these for the first playable build. They cover the most common interactions.

---

### Generic Skills (MVP)

#### Renewal
- **Trigger:** `start_of_turn`
- **Effect:** Restore 10% of unit's max HP
- **Always active:** Yes
- **effect_id:** `renewal`

```gdscript
func _apply_renewal(skill, unit, context):
    var heal = max(1, floor(unit.data.max_hp * 0.10))
    unit.heal(heal)
    return context
```

#### Vantage
- **Trigger:** `on_combat_start`
- **Effect:** This unit always attacks first in combat (even when defending)
- **effect_id:** `vantage`

```gdscript
func _apply_vantage(skill, unit, context):
    context["vantage_unit"] = unit
    return context
# CombatResolver checks for vantage_unit and reorders attacks accordingly
```

#### Nihil
- **Trigger:** `on_combat_start`
- **Effect:** Negate all battle-related skills on the opponent for this combat
- **effect_id:** `nihil`

```gdscript
func _apply_nihil(skill, unit, context):
    context["skill_blocked"] = true
    return context
```

#### Resolve
- **Trigger:** `passive` (recalculated each stat query)
- **Effect:** +50% STR, MAG, SKL, SPD when HP ≤ 50% of max
- **effect_id:** `resolve`

#### Miracle
- **Trigger:** `on_damaged`
- **Effect:** LUK% chance to halve a fatal blow (damage that would kill)
- **effect_id:** `miracle`

#### Wrath
- **Trigger:** `passive`
- **Effect:** +50 Critical when HP ≤ 50% of max
- **effect_id:** `wrath`

---

### Class-Specific Skills (MVP)

#### Pick (Thief line — Phase 2)
- **Trigger:** `player_activated`
- **Effect:** Open an adjacent door or chest without a key
- **effect_id:** `pick`

#### Canto (Bard line — Phase 2)
- **Trigger:** `player_activated`
- **Effect:** One adjacent ally without Canto that has already acted can move and act again
- **effect_id:** `canto`

---

### Promotion Skills (MVP — implement at Phase 2 alongside promotion system)

#### Hawkeye (Sniper)
- **Trigger:** `passive`
- **Effect:** +15 Hit, +15 Critical
- **effect_id:** `stat_bonus`
- **effect_params:** `{ "hit": 15, "crit": 15 }`

#### Finesse (Swordmaster)
- **Trigger:** `passive`
- **Effect:** +25 Critical
- **effect_id:** `stat_bonus`
- **effect_params:** `{ "crit": 25 }`

#### Renewal (also a generic skill)
Already listed above.

#### Bastion (General)
- **Trigger:** `player_activated`
- **Effect:** As an action: block 1 adjacent unoccupied tile until next turn
- **effect_id:** `bastion`

---

## Full Skill Reference (All Handbook Skills — Phase 2+)

The following skills are deferred to Phase 2. They are listed here so their
`effect_id` strings can be reserved and their design understood before implementation.

### Generic Skills (All Phase 2)

| Skill | Trigger | effect_id | Notes |
|---|---|---|---|
| Adept | on_attack | `adept` | SKL/2% for 1 extra attack |
| Barrier | passive | `stat_bonus` | +2 RES |
| Cancel | on_attack | `cancel` | SKL/2%: negate enemy's next attack |
| Celerity | passive | `stat_bonus` | +2 MOV |
| Clear Vision | passive | `stat_bonus` | +2 LoS |
| Corrosion | on_hit | `corrosion` | SKL/2%: enemy weapon loses uses |
| Daunt | start_of_enemy_turn | `daunt` | -10 Acc/Crit to enemies in 3-radius |
| Discipline | passive | `discipline` | Negate weapon triangle |
| Focus | passive | `stat_bonus` | +2 MAG |
| Fortunate | passive | `stat_bonus` | +2 LUK |
| Gamble | player_activated | `gamble` | Halve Acc, double Crit |
| Loot | on_kill | `loot` | Gain 20 gold |
| Nihil | on_combat_start | `nihil` | Already in MVP |
| Nullify | on_defend | `nullify` | Negate effectiveness bonus |
| Perceptive | passive | `stat_bonus` | +2 LoS |
| Prowess | passive | `stat_bonus` | +2 SKL |
| Renewal | start_of_turn | `renewal` | Already in MVP |
| Resolve | passive | `resolve` | Already in MVP |
| Savior | passive | `savior` | No rescue penalty |
| Smite | player_activated | `smite` | Shove 2 tiles instead of 1 |
| Swift | passive | `stat_bonus` | +2 SPD |
| Tough | passive | `stat_bonus` | +2 DEF |
| Unorthodox | passive | `unorthodox` | Reverse weapon triangle |
| Vantage | on_combat_start | `vantage` | Already in MVP |
| Vigor | passive | `stat_bonus` | +5 max HP |
| Wrath | passive | `wrath` | Already in MVP |
| Zeal | passive | `stat_bonus` | +2 STR |

### Promotion Skills (All Phase 2 — add alongside each promoted class)

| Skill | Class | effect_id |
|---|---|---|
| Swiftfoot | Ranger | `swiftfoot` |
| Hawkeye | Sniper | `stat_bonus` |
| Battle Cry | Skald | `battle_cry` |
| Resonance | Troubadour | `resonance` |
| Frenzy | Berserker | `frenzy` |
| Bulldozer | Brawler | `bulldozer` |
| Strike True | Paladin | `strike_true` |
| Counter | Vanguard | `counter` |
| Blessing | Bishop | `blessing` |
| Boon | Paragon | `boon` |
| Rise | Necromancer | `rise` |
| Drain | Warlock | `drain` |
| Cripple | Warrior | `cripple` |
| Redirect | Guardian | `redirect` |
| Bastion | General | `bastion` |
| Pavise | Great Knight | `pavise` |
| Aegis | Mage Knight | `aegis` |
| Phasing | Sage | `phasing` |
| Dash | Hero | `dash` |
| Vigilance | Sentinel | `vigilance` |
| Infuse | Soulblade | `infuse` |
| Finesse | Swordmaster | `stat_bonus` |
| Flanking | Nomad Trooper | `flanking` |
| Trample | Raider | `trample` |
| Air Superiority | Falcoknight | `air_superiority` |
| Holy Conduit | Valkyrie | `holy_conduit` |
| Motivate | Commander | `motivate` |
| Lunge | Halberdier | `lunge` |
| Reaper | Assassin | `reaper` |
| Steal | Rogue | `steal` |
| Firebreathing | Dracoknight | `firebreathing` |
| Ironhide | Wyvern Lord | `ironhide` |
| Nimble | Cat | `nimble` |
| Tailwind | Hawk | `tailwind` |
| Grace | Heron | `grace` |
| Vortex | Raven | `vortex` |
| Rend | Tiger | `rend` |

---

## How to Add a New Skill

1. Create `data/skills/skill_name.tres` (New Resource → SkillData)
2. Fill in all fields, including a unique `effect_id`
3. If `effect_id` already exists (e.g. `stat_bonus`), configure via `effect_params`
4. If `effect_id` is **new**, add an implementation case to `SkillHandler.gd`
5. No other files need changing

### Implementing `stat_bonus` (reusable for many skills)
```gdscript
func _apply_stat_bonus(skill: SkillData, unit: Unit, context: Dictionary) -> Dictionary:
    var params = skill.effect_params
    # Apply each bonus to the context's computed stats
    if params.has("hit"):   context["accuracy"] += params["hit"]
    if params.has("crit"):  context["crit_rate"] += params["crit"]
    if params.has("str"):   context["damage"]   += params["str"]
    # etc.
    return context
```
