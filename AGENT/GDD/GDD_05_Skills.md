# GDD_05 — Skills

---

## Skill System Overview

Skills are modifiers or triggered effects attached to units. They are defined as
`SkillData` resources in `data/skills/` and executed by `SkillHandler.gd`.

Skills are **not hardcoded per class** — they are data entries. A unit carries a list
of skill IDs. The skill handler is a lookup table: given a skill ID and a trigger
context, it applies the effect.

**Maximum skills per unit:** 4 (`GameState.max_skills`) — the cap is defined but
**not yet enforced** (no skill-equip UI exists). Earned mastery skills
(`UnitData.mastery_skills`, e.g. `s_rank_mastery`) never count against this cap.

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
| `on_combat_start_negate` | A pre-pass before `on_combat_start` — for skill-cancellers (Nihil) |
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

`SkillHandler` is an autoload. `CombatResolver`, `TurnManager`, and `GridManager`
call `apply_trigger()` at the appropriate moments; it iterates the unit's skills —
equipped (`UnitData.skills`) **and** earned mastery skills (`UnitData.mastery_skills`)
— and fires every one whose `trigger` matches.

```gdscript
# scripts/skills/SkillHandler.gd  (autoload)
extends Node

# preview        — exclude random-activation skills (a combat forecast must be deterministic)
# skills_blocked — set by an opponent's Nihil; only NIHIL_EXEMPT_SKILLS still fire
# dry_run        — run effects but do NOT persist limited-use counters (preview only)
func apply_trigger(unit: Node, trigger: String, context: Dictionary,
        preview := false, skills_blocked := false, dry_run := false) -> Dictionary
```

For each matching skill, `apply_trigger` enforces `max_uses_per_map` /
`max_uses_per_combat`, rolls `activation_chance_stat / activation_divisor` if set,
then dispatches through a `{ effect_id: Callable }` table built in `_ready()` — an
unknown `effect_id` is a startup `push_error`, never a silent no-op. A handler
returns `true` only when its effect actually applied, so a limited use is consumed
only on a real activation.

Skills mutate a shared **combat context** `Dictionary` in place. Its modifier
channels are `atk_mod` / `def_mod` (sub-dictionaries with `accuracy`, `damage`,
`crit`, `crit_avoid`, `dodge`, `strikes`, `damage_multiplier`) and `flags`
(`vantage`, `skip_effectiveness`, lifesteal, …). Nihil sets
`attacker_skills_blocked` / `defender_skills_blocked`. The full context schema is
documented in the `CombatResolver.gd` file header.

---

## MVP Skills (Implemented)

These skills are implemented and have `.tres` files in `data/skills/`. The
`effect_id` is the `SkillHandler` dispatch key; the `.tres` `id` is the skill name.
Several skills share one handler, configured via `effect_params`.

### Generic battle skills

| Skill (`.tres` id) | Trigger | effect_id | Effect |
|---|---|---|---|
| `renewal` | `start_of_turn` | `renewal` | Heal 10% of max HP (rounded down, min 1). |
| `vantage` | `on_combat_start` | `vantage` | When defending, this unit's counter strikes first. |
| `nihil` | `on_combat_start_negate` | `nihil` | Negates the opponent's battle skills this combat (except mastery skills and Nihil itself). |
| `resolve` | `on_combat_start` | `resolve` | +50% STR/MAG/SKL/SPD while HP ≤ 50%, applied as combat-duration modifiers. |
| `wrath` | `on_combat_start` | `wrath` | +50 Crit while HP ≤ 50%. |
| `miracle` | `on_damaged` | `miracle` | (LUK / divisor) % chance to survive an otherwise-lethal blow at 1 HP. |

### Weapon-type skills (one `.tres` per type, shared handler)

| Skills (`.tres` ids) | Trigger | effect_id | Effect |
|---|---|---|---|
| `swordfaire` / `lancefaire` / `bowfaire` | `on_combat_start` | `faire` | +N damage with the matching weapon type (`effect_params`: `weapon_type`, `bonus`). |
| `swordbreaker` / `lancebreaker` / `bowbreaker` | `on_combat_start` | `breaker` | +Hit attacking / +Dodge defending against the matching opposing weapon type. |

### Earned mastery skill

| Skill (`.tres` id) | Trigger | effect_id | Effect |
|---|---|---|---|
| `s_rank_mastery` | `on_combat_start` | `s_rank_mastery` | +10 Hit, +5 Crit, +1 Damage with a weapon type held at S rank. Granted automatically by `Unit.add_wexp()` on the first S rank; stored in `UnitData.mastery_skills`; never assignable in a `.tres`. |

> **Stub handlers:** `stat_bonus`, `charm`, `anathema`, and `daunt` exist as keys in
> the `SkillHandler` dispatch table, but their handlers are stubs — no `.tres` uses
> them yet. Full implementation is M9.

---

### Class / Promotion / Occult skills (designed, not implemented)

`Pick` (Thief), `Canto` (Bard), `Hawkeye` / `Finesse` (promotion `stat_bonus`
skills), `Bastion` (General), and the rest are designed in the Full Skill Reference
below and scheduled for M9 / the promotion milestone — see GDD_10.

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

### Implementing a shared handler (the `faire` pattern)

A handler reads `effect_params` and writes into the context's `atk_mod` / `def_mod`
channel for the relevant side. It returns `true` only when it actually applied — so
a limited-use skill is not charged a use when it declines:
```gdscript
func _apply_faire(skill: SkillData, unit: Node, context: Dictionary) -> bool:
    var is_atk: bool = (unit == context.get("attacker"))
    var w: WeaponData = context.get("attacker_weapon") if is_atk \
        else context.get("defender_weapon")
    if w == null or w.weapon_type != skill.effect_params.get("weapon_type", ""):
        return false                       # declined — no limited use consumed
    var mod: Dictionary = context["atk_mod"] if is_atk else context["def_mod"]
    mod["damage"] += skill.effect_params.get("bonus", 5)
    return true
```
