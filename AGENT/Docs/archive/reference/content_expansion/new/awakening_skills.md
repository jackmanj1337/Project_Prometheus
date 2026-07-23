> **Historical** — External Awakening reference corpus; not active Project Prometheus rules or public-pack content.

# Fire Emblem Awakening Technical Reference Corpus
# Skill Encyclopedia

**File:** `awakening_skills.md`  
**Phase:** 6  
**Corpus Version:** `0.7.0-phase6`  
**Depends On:** `awakening_project_index.md`, `awakening_core_systems.md`, `awakening_lookup_tables.md`, `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_classes_special.md`  
**Scope:** Every Fire Emblem Awakening skill category: base-game class skills, personal skills, DLC/outrealm skills, placeholder skills, and enemy-exclusive skills.

---

# Table of Contents

1. [Phase Boundary](#phase-boundary)
2. [Global Skill Rules](#global-skill-rules)
3. [Skill Entries](#skill-entries)

---

# Phase Boundary

This document includes skill definitions only.

Deferred content:

| Deferred Topic | Target File |
|---|---|
| Full class tables | `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_classes_special.md` |
| Weapon encyclopedia interactions | `awakening_weapons_physical.md`, `awakening_weapons_magic.md` |
| Skill inheritance legality matrix | `awakening_appendices.md` |
| Item descriptions for skill-granting items | `awakening_items.md` |

---

# Global Skill Rules

## Equipped Skill Limit

A unit may equip up to five active skills.

```text
MaxEquippedSkills = 5
```

Learned skills persist through promotion and reclassing.

```text
KnownSkillsAfterClassChange = KnownSkillsBeforeClassChange
```

## Duplicate Skill Rule

A unit cannot benefit from two equipped copies of the same named skill in normal play.

```text
DuplicateNamedSkillStacking = False
```

## Rally Resolution

When the `Rally` command is used:

```text
ActivateAllEquippedRallySkillsSimultaneously
```

Named Rally effects do not stack with themselves.

```text
RallyStrength + RallyStrength = RallyStrength
```

Distinct Rally effects may stack.

```text
RallyStrength + RallySpectrum + RallyHeart = combined applicable bonuses
```

## Offensive Proc Exclusivity

Only one standard offensive proc skill may activate for a single attack strike.

```text
MaxOffensiveProcPerStrike = 1
```

Canonical offensive proc priority:

```text
Lethality > Aether > Astra > Sol > Luna > Ignis > Vengeance
```

Critical hits may still occur on attacks affected by offensive proc skills unless the specific proc/weapon/script prevents critical resolution.

## Proc Rate Modifiers

General proc calculation:

```text
FinalProcRate =
clamp(BaseProcFormula + ProcRateModifiers, 0, 100)
```

Applicable modifiers include:

| Modifier | Value |
|---|---:|
| Rightful King | +10 |
| Rightful God | +30 |

## Defensive Proc Notes

Aegis and Pavise effects do not apply to Dual Strike damage packets under the documented footnote.

```text
AegisAppliesToDualStrike = False
PaviseAppliesToDualStrike = False
```

## Phase Terminology

| Term | Meaning |
|---|---|
| User phase | Phase controlled by the unit's army/faction |
| Enemy phase | Phase where the unit is defending against the opposing army/faction |
| Adjacent | Manhattan distance 1 |
| Within 3 tiles | Manhattan distance ≤ 3 unless map script defines otherwise |
| Dodge | Critical avoid |

---

# Skill Entries


## Dual Strike+

| Property | Value |
|---|---|
| Category | Pair Up / Support Modifier |
| Trigger | Passive; evaluated when calculating Dual Strike rate. |
| Formula | `DualStrikeRate = BaseDualStrikeRate + 10` |
| Proc Rate | N/A; deterministic rate modifier. |
| Stacking Rules | Additive with other Dual Strike rate modifiers; only one copy of the same skill can be equipped. |
| AI Usage | AI benefits automatically when paired or adjacent under support-attack rules. |
| Source Classes | Lord, level 1 |


### Mechanical Notes

- Does not create Dual Strike eligibility by itself; support-unit weapon/range legality must still pass.

- Modifier is applied before final rate clamp.




## Charm

| Property | Value |
|---|---|
| Category | Aura / Proximity Support |
| Trigger | Passive; active while allies are within 3 tiles of the skill holder. |
| Formula | `AllyHit += 5; AllyAvoid += 5` |
| Proc Rate | N/A; deterministic aura. |
| Stacking Rules | Additive with other named aura/support bonuses; duplicate self-stacking should be treated as invalid because duplicate equipped skills are not legal. |
| AI Usage | AI benefits automatically; AI positioning may not intentionally optimize aura coverage unless scripted. |
| Source Classes | Lord, level 10 |


### Mechanical Notes

- Applies to allied units, not the skill holder unless another ally with Charm is affecting them.

- Radius is tile distance within 3 tiles.




## Aether

| Property | Value |
|---|---|
| Category | Offensive Proc / Multi-Strike |
| Trigger | During user's attack, after attack eligibility and before damage resolution for the selected strike. |
| Formula | `Strike1 = Sol-effect strike; Strike2 = Luna-effect strike; both strikes resolve consecutively.` |
| Proc Rate | floor(SKL / 2)%; modified by Rightful King/Rightful God, then clamped 0–100. |
| Stacking Rules | Mutually exclusive with other offensive proc skills on the same attack. Offensive proc priority: Lethality > Aether > Astra > Sol > Luna > Ignis > Vengeance. |
| AI Usage | AI uses automatically if equipped; no command decision required. |
| Source Classes | Great Lord, level 5 |


### Mechanical Notes

- Each Aether strike may still miss or crit under normal hit/crit rules unless a separate effect overrides hit.

- The Sol half heals based on damage dealt; the Luna half halves the target defensive stat for that strike.

- Does not create an additional attack opportunity outside the proc strike sequence.




## Rightful King

| Property | Value |
|---|---|
| Category | Proc Rate Modifier |
| Trigger | Passive; applied when calculating equipped skill activation rates. |
| Formula | `ProcRate += 10` |
| Proc Rate | N/A; deterministic modifier. |
| Stacking Rules | Additive with base proc formulas and Rightful God if an enemy/modded unit has both; clamp final proc rate to 0–100. |
| AI Usage | AI benefits automatically. |
| Source Classes | Great Lord, level 15 |


### Mechanical Notes

- Applies to compatible skill activation rates, including offensive and defensive proc skills.

- Does not affect deterministic passive bonuses.




## Veteran

| Property | Value |
|---|---|
| Category | Experience Modifier / Pair Up |
| Trigger | Passive; evaluated when awarding EXP while unit is paired up. |
| Formula | `FinalEXP = floor(BaseEXP × 1.5)` |
| Proc Rate | N/A; deterministic EXP modifier. |
| Stacking Rules | Multiplicative with other EXP modifiers unless implementation explicitly orders modifiers; clamp EXP by normal level-cap rules. |
| AI Usage | AI benefits only if enemy EXP gain is modeled; usually irrelevant for enemy combat AI. |
| Source Classes | Tactician, level 1 |


### Mechanical Notes

- Requires Pair Up state, not merely adjacency.

- Does not modify WEXP.




## Solidarity

| Property | Value |
|---|---|
| Category | Aura / Proximity Support |
| Trigger | Passive; active for adjacent allies. |
| Formula | `AdjacentAllyCrit += 10; AdjacentAllyDodge += 10` |
| Proc Rate | N/A; deterministic aura. |
| Stacking Rules | Additive with other named aura/support bonuses. |
| AI Usage | AI benefits automatically; AI positioning may not intentionally optimize aura coverage unless scripted. |
| Source Classes | Tactician, level 10 |


### Mechanical Notes

- Affects allies adjacent to the holder.

- Dodge is critical avoid.




## Ignis

| Property | Value |
|---|---|
| Category | Offensive Proc / Damage Modifier |
| Trigger | During user's attack before damage calculation. |
| Formula | `If damage uses STR: Attack += floor(MAG / 2). If damage uses MAG: Attack += floor(STR / 2).` |
| Proc Rate | SKL%; modified by Rightful King/Rightful God, then clamped 0–100. |
| Stacking Rules | Mutually exclusive with other offensive proc skills on the same attack. Offensive proc priority: Lethality > Aether > Astra > Sol > Luna > Ignis > Vengeance. |
| AI Usage | AI uses automatically if equipped. |
| Source Classes | Grandmaster, level 5 |


### Mechanical Notes

- For magical physical weapons, use the actual damage stat to determine which half-stat is added.

- The added value modifies attack/damage before final damage is applied.




## Rally Spectrum

| Property | Value |
|---|---|
| Category | Command / Rally |
| Trigger | Command action; affects allies within 3 tiles for one turn. |
| Formula | `Target STR/MAG/SKL/SPD/LCK/DEF/RES += 4` |
| Proc Rate | N/A; command effect. |
| Stacking Rules | All active Rally skills trigger simultaneously when Rally is used. Does not stack with another Rally Spectrum from a second use, but stacks with distinct Rally skills and Rally Heart. |
| AI Usage | AI may use Rally only if its action script permits rally behavior; otherwise no autonomous use. |
| Source Classes | Grandmaster, level 15 |


### Mechanical Notes

- Does not affect HP or MOV.

- Consumes the user's action.




## Discipline

| Property | Value |
|---|---|
| Category | Progression Modifier / WEXP |
| Trigger | Passive; evaluated when gaining WEXP from weapon/staff use. |
| Formula | `FinalWEXPGain = BaseWEXPGain × 2` |
| Proc Rate | N/A; deterministic WEXP modifier. |
| Stacking Rules | Multiplicative with base WEXP gain; final gain is still capped by class/global WEXP caps. |
| AI Usage | AI irrelevant unless enemy WEXP progression is modeled. |
| Source Classes | Cavalier, level 1 |


### Mechanical Notes

- Affects WEXP, not EXP.

- Does not bypass weapon-rank caps.




## Outdoor Fighter

| Property | Value |
|---|---|
| Category | Conditional Combat Bonus |
| Trigger | Passive; active in combat when terrain/environment is classified as outdoors. |
| Formula | `Hit += 10; Avoid += 10` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically when condition is true. |
| Source Classes | Cavalier, level 10 |


### Mechanical Notes

- Requires map/terrain environment classification.

- Does not apply in indoor-classified combat.




## Defender

| Property | Value |
|---|---|
| Category | Pair Up / Stat Bonus |
| Trigger | Passive; active while unit is paired up. |
| Formula | `STR/MAG/SKL/SPD/LCK/DEF/RES += 1` |
| Proc Rate | N/A; deterministic stat modifier. |
| Stacking Rules | Additive with other stat bonuses; does not modify HP or MOV. |
| AI Usage | AI benefits automatically if paired. |
| Source Classes | Paladin, level 5 |


### Mechanical Notes

- Requires Pair Up state.

- Does not apply from simple adjacency.




## Aegis

| Property | Value |
|---|---|
| Category | Defensive Proc / Damage Reduction |
| Trigger | When receiving damage from bows, tomes, or dragonstones. |
| Formula | `Damage = floor(Damage / 2)` |
| Proc Rate | SKL%; modified by Rightful King/Rightful God, then clamped 0–100. |
| Stacking Rules | Does not stack with Aegis+ because Aegis+ is deterministic and should take precedence. Defensive reduction should apply once to a damage packet. |
| AI Usage | AI benefits automatically if equipped. |
| Source Classes | Paladin, level 15 |


### Mechanical Notes

- Does not apply to Dual Strike damage packets under the documented footnote.

- Applies to eligible weapon categories, not all magical damage sources unless classified as tome/dragonstone.




## Luna

| Property | Value |
|---|---|
| Category | Offensive Proc / Defense Reduction |
| Trigger | During user's attack before damage calculation. |
| Formula | `TargetDefenseStat = floor(TargetDefenseStat / 2)` |
| Proc Rate | SKL%; modified by Rightful King/Rightful God, then clamped 0–100. |
| Stacking Rules | Mutually exclusive with other offensive proc skills on the same attack. Offensive proc priority: Lethality > Aether > Astra > Sol > Luna > Ignis > Vengeance. |
| AI Usage | AI uses automatically if equipped. |
| Source Classes | Great Knight, level 5 |


### Mechanical Notes

- Uses DEF for physical damage and RES for magical damage.

- The target's stat is reduced for this damage calculation only.




## Dual Guard+

| Property | Value |
|---|---|
| Category | Pair Up / Support Modifier |
| Trigger | Passive; evaluated when calculating Dual Guard rate. |
| Formula | `DualGuardRate += 10` |
| Proc Rate | N/A; deterministic rate modifier. |
| Stacking Rules | Additive with other Dual Guard modifiers; final rate is clamped 0–100. |
| AI Usage | AI benefits automatically when paired/support-guard eligible. |
| Source Classes | Great Knight, level 15 |


### Mechanical Notes

- Does not create Dual Guard eligibility by itself.

- Applies before final rate clamp.




## Defense +2

| Property | Value |
|---|---|
| Category | Stat Bonus |
| Trigger | Passive; active while equipped. |
| Formula | `DEF += 2` |
| Proc Rate | N/A; deterministic stat modifier. |
| Stacking Rules | Additive with other DEF modifiers; applies after permanent cap enforcement as an equipped-skill bonus. |
| AI Usage | AI benefits automatically. |
| Source Classes | Knight, level 1 |


### Mechanical Notes

- Temporary/equipped stat modifier, not a permanent stat gain.




## Indoor Fighter

| Property | Value |
|---|---|
| Category | Conditional Combat Bonus |
| Trigger | Passive; active in combat when terrain/environment is classified as indoors. |
| Formula | `Hit += 10; Avoid += 10` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically when condition is true. |
| Source Classes | Knight, level 10 |


### Mechanical Notes

- Requires map/terrain environment classification.

- Does not apply in outdoor-classified combat.




## Rally Defense

| Property | Value |
|---|---|
| Category | Command / Rally |
| Trigger | Command action; affects allies within 3 tiles for one turn. |
| Formula | `TargetDEF += 4` |
| Proc Rate | N/A; command effect. |
| Stacking Rules | All active Rally skills trigger simultaneously. Does not stack with another Rally Defense from a second use; stacks with Rally Spectrum and Rally Heart. |
| AI Usage | AI may use Rally only if its action script permits rally behavior. |
| Source Classes | General, level 5 |


### Mechanical Notes

- Consumes the user's action.

- Does not affect the user unless a separate unit rallies them.




## Pavise

| Property | Value |
|---|---|
| Category | Defensive Proc / Damage Reduction |
| Trigger | When receiving damage from swords, lances, axes, magical variants of those weapons, beaststones, or blights. |
| Formula | `Damage = floor(Damage / 2)` |
| Proc Rate | SKL%; modified by Rightful King/Rightful God, then clamped 0–100. |
| Stacking Rules | Does not stack with Pavise+ because Pavise+ is deterministic and should take precedence. Defensive reduction should apply once to a damage packet. |
| AI Usage | AI benefits automatically if equipped. |
| Source Classes | General, level 15 |


### Mechanical Notes

- Does not apply to Dual Strike damage packets under the documented footnote.

- Weapon category, not damage type alone, determines eligibility.




## Avoid +10

| Property | Value |
|---|---|
| Category | Stat Bonus / Combat Modifier |
| Trigger | Passive; active while equipped. |
| Formula | `Avoid += 10` |
| Proc Rate | N/A; deterministic combat modifier. |
| Stacking Rules | Additive with other Avoid modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Myrmidon, level 1 |


### Mechanical Notes

- Applies to displayed/effective Avoid, not terrain cost.




## Vantage

| Property | Value |
|---|---|
| Category | Combat Order Modifier |
| Trigger | Enemy-phase combat when user is at half HP or lower and can counterattack. |
| Formula | `If CurrentHP ≤ floor(MaxHP / 2), user attacks before the initiating enemy.` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Does not stack with Vantage+; Vantage+ supersedes it. Multiple combat-order overrides require priority handling. |
| AI Usage | AI benefits automatically; can alter enemy-phase risk calculations if AI simulates combat order. |
| Source Classes | Myrmidon, level 10 |


### Mechanical Notes

- Requires counterattack legality unless a script allows otherwise.

- Only relevant when attacked on enemy phase.




## Astra

| Property | Value |
|---|---|
| Category | Offensive Proc / Multi-Hit |
| Trigger | During user's attack before damage calculation. |
| Formula | `Resolve 5 consecutive strikes, each with Damage = floor(StandardDamage / 2).` |
| Proc Rate | floor(SKL / 2)%; modified by Rightful King/Rightful God, then clamped 0–100. |
| Stacking Rules | Mutually exclusive with other offensive proc skills on the same attack. Offensive proc priority: Lethality > Aether > Astra > Sol > Luna > Ignis > Vengeance. |
| AI Usage | AI uses automatically if equipped. |
| Source Classes | Swordmaster, level 5 |


### Mechanical Notes

- Each hit is a separate strike and may independently hit/crit under normal rules unless strict engine behavior overrides.

- Total damage may be reduced by flooring each half-damage strike.




## Swordfaire

| Property | Value |
|---|---|
| Category | Faire / Weapon Stat Bonus |
| Trigger | Passive; active while equipped with a sword. |
| Formula | `If physical sword: STR += 5. If Levin Sword-style magical sword: MAG += 5.` |
| Proc Rate | N/A; deterministic weapon-conditional modifier. |
| Stacking Rules | Additive with other stat/attack modifiers; only applies while the relevant weapon type is equipped. |
| AI Usage | AI benefits automatically and may rate damage higher if combat forecast accounts for it. |
| Source Classes | Swordmaster, level 15 |


### Mechanical Notes

- Applies to sword weapon type.

- Magical sword exception uses MAG bonus.




## Armsthrift

| Property | Value |
|---|---|
| Category | Utility Proc / Durability |
| Trigger | When user attacks with a weapon that would consume durability. |
| Formula | `If proc succeeds: WeaponDurabilityCost = 0` |
| Proc Rate | LCK × 2%; modified by Rightful King/Rightful God if implementation treats it as skill activation, then clamped 0–100. |
| Stacking Rules | Does not stack with itself; if durability is already not consumed, no additional effect. |
| AI Usage | AI benefits automatically if enemy durability is modeled; usually irrelevant for short-lived enemies. |
| Source Classes | Mercenary, level 1 |


### Mechanical Notes

- Applies to weapon-use durability consumption.

- Does not restore durability; it prevents one consumption event.




## Patience

| Property | Value |
|---|---|
| Category | Phase Combat Bonus |
| Trigger | Passive; active during enemy phase. |
| Formula | `Hit += 10; Avoid += 10` |
| Proc Rate | N/A; deterministic phase modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically when defending on enemy phase. |
| Source Classes | Mercenary, level 10 |


### Mechanical Notes

- Enemy phase means the skill holder is not the phase controller.




## Sol

| Property | Value |
|---|---|
| Category | Offensive Proc / Healing |
| Trigger | During user's attack after hit and damage are resolved. |
| Formula | `HealAmount = floor(DamageDealt / 2)` |
| Proc Rate | SKL%; modified by Rightful King/Rightful God, then clamped 0–100. |
| Stacking Rules | Mutually exclusive with other offensive proc skills on the same attack. Offensive proc priority: Lethality > Aether > Astra > Sol > Luna > Ignis > Vengeance. |
| AI Usage | AI uses automatically if equipped. |
| Source Classes | Hero, level 5 |


### Mechanical Notes

- Healing cannot exceed MaxHP.

- No healing occurs if no damage is dealt.




## Axebreaker

| Property | Value |
|---|---|
| Category | Breaker / Weapon Matchup Modifier |
| Trigger | Passive; active in combat when enemy is equipped with an axe. |
| Formula | `Hit += 50; Avoid += 50` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers; multiple breaker skills can apply only if the enemy weapon matches their conditions. |
| AI Usage | AI benefits automatically and may rate combat more favorably if forecast accounts for it. |
| Source Classes | Hero, level 15 |


### Mechanical Notes

- Applies against axe weapon type, including magical axe variants if classified as axes.




## HP +5

| Property | Value |
|---|---|
| Category | Stat Bonus |
| Trigger | Passive; active while equipped. |
| Formula | `MaxHP += 5; CurrentHP handling should preserve missing HP unless engine explicitly heals on equip.` |
| Proc Rate | N/A; deterministic stat modifier. |
| Stacking Rules | Additive with other HP modifiers; equipped-skill bonus, not permanent growth. |
| AI Usage | AI benefits automatically. |
| Source Classes | Fighter, level 1 |


### Mechanical Notes

- Recommended implementation: when equipping, increase MaxHP and CurrentHP by same delta only if matching vanilla menu behavior is modeled; otherwise preserve HP ratio/state consistently.




## Zeal

| Property | Value |
|---|---|
| Category | Combat Modifier / Critical |
| Trigger | Passive; active while equipped. |
| Formula | `Crit += 5` |
| Proc Rate | N/A; deterministic combat modifier. |
| Stacking Rules | Additive with other Crit modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Fighter, level 10 |


### Mechanical Notes

- Modifies displayed critical rate before defender Dodge subtraction.




## Rally Strength

| Property | Value |
|---|---|
| Category | Command / Rally |
| Trigger | Command action; affects allies within 3 tiles for one turn. |
| Formula | `TargetSTR += 4` |
| Proc Rate | N/A; command effect. |
| Stacking Rules | All active Rally skills trigger simultaneously. Does not stack with another Rally Strength from a second use; stacks with Rally Spectrum and Rally Heart. |
| AI Usage | AI may use Rally only if its action script permits rally behavior. |
| Source Classes | Warrior, level 5 |


### Mechanical Notes

- Consumes the user's action.




## Counter

| Property | Value |
|---|---|
| Category | Reactive Damage / Enemy-Phase Punisher |
| Trigger | After user survives an adjacent attack that dealt damage. |
| Formula | `AttackerHP -= DamageReceived` |
| Proc Rate | N/A; deterministic reactive effect. |
| Stacking Rules | Negated by Dragonskin. Does not trigger if the Counter holder is KO'd by the attack. |
| AI Usage | AI benefits automatically; AI may or may not avoid attacking Counter units depending on AI sophistication. |
| Source Classes | Warrior, level 15 |


### Mechanical Notes

- Requires adjacent/1-range attack.

- Reflected damage is based on damage received, not damage before reductions.

- Does not trigger on lethal damage to the skill holder.




## Despoil

| Property | Value |
|---|---|
| Category | Post-Kill Proc / Economy |
| Trigger | After user defeats an enemy. |
| Formula | `If proc succeeds: add Bullion (S) drop/reward.` |
| Proc Rate | LCK%; modified by Rightful King/Rightful God if implementation treats it as skill activation, then clamped 0–100. |
| Stacking Rules | Does not stack with itself; item-drop conflicts should be resolved by inventory/drop rules. |
| AI Usage | AI generally irrelevant unless enemy drops are simulated for AI-side units. |
| Source Classes | Barbarian, level 1 |


### Mechanical Notes

- Requires the unit with Despoil to land the kill.

- Reward is Bullion (S).




## Gamble

| Property | Value |
|---|---|
| Category | Combat Modifier / Hit-Crit Tradeoff |
| Trigger | Passive; active while equipped. |
| Formula | `Hit -= 5; Crit += 10` |
| Proc Rate | N/A; deterministic combat modifier. |
| Stacking Rules | Additive with other Hit/Crit modifiers. |
| AI Usage | AI benefits automatically in forecast; may lower hit reliability. |
| Source Classes | Barbarian, level 10 |


### Mechanical Notes

- Applies before final Hit/Crit clamping.




## Wrath

| Property | Value |
|---|---|
| Category | Conditional Combat Modifier / Critical |
| Trigger | Passive; active while user is at half HP or lower. |
| Formula | `If CurrentHP ≤ floor(MaxHP / 2): Crit += 20` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Additive with other Crit modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Berserker, level 5 |


### Mechanical Notes

- Condition should be evaluated at combat-stat calculation time.




## Axefaire

| Property | Value |
|---|---|
| Category | Faire / Weapon Stat Bonus |
| Trigger | Passive; active while equipped with an axe. |
| Formula | `If physical axe: STR += 5. If Bolt Axe-style magical axe: MAG += 5.` |
| Proc Rate | N/A; deterministic weapon-conditional modifier. |
| Stacking Rules | Additive with other stat/attack modifiers; only applies while the relevant weapon type is equipped. |
| AI Usage | AI benefits automatically. |
| Source Classes | Berserker, level 15 |


### Mechanical Notes

- Applies to axe weapon type.

- Magical axe exception uses MAG bonus.




## Skill +2

| Property | Value |
|---|---|
| Category | Stat Bonus |
| Trigger | Passive; active while equipped. |
| Formula | `SKL += 2` |
| Proc Rate | N/A; deterministic stat modifier. |
| Stacking Rules | Additive with other SKL modifiers; affects derived Hit/Crit/proc calculations after stat recalculation. |
| AI Usage | AI benefits automatically. |
| Source Classes | Archer, level 1 |


### Mechanical Notes

- Because SKL feeds hit, crit, and proc formulas, this has indirect effects.




## Prescience

| Property | Value |
|---|---|
| Category | Phase Combat Bonus |
| Trigger | Passive; active during player phase. |
| Formula | `Hit += 15; Avoid += 15` |
| Proc Rate | N/A; deterministic phase modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically when the unit is acting on its own phase. |
| Source Classes | Archer, level 10 |


### Mechanical Notes

- Player phase means the skill holder belongs to the active side for that phase.




## Hit Rate +20

| Property | Value |
|---|---|
| Category | Combat Modifier / Hit |
| Trigger | Passive; active while equipped. |
| Formula | `Hit += 20` |
| Proc Rate | N/A; deterministic combat modifier. |
| Stacking Rules | Additive with other Hit modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Sniper, level 5 |


### Mechanical Notes

- Applies before final hit clamp.




## Bowfaire

| Property | Value |
|---|---|
| Category | Faire / Weapon Stat Bonus |
| Trigger | Passive; active while equipped with a bow. |
| Formula | `STR += 5` |
| Proc Rate | N/A; deterministic weapon-conditional modifier. |
| Stacking Rules | Additive with other stat/attack modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Sniper, level 15 |


### Mechanical Notes

- Applies to bow weapon type.




## Rally Skill

| Property | Value |
|---|---|
| Category | Command / Rally |
| Trigger | Command action; affects allies within 3 tiles for one turn. |
| Formula | `TargetSKL += 4` |
| Proc Rate | N/A; command effect. |
| Stacking Rules | All active Rally skills trigger simultaneously. Does not stack with another Rally Skill from a second use; stacks with Rally Spectrum and Rally Heart. |
| AI Usage | AI may use Rally only if its action script permits rally behavior. |
| Source Classes | Bow Knight, level 5 |


### Mechanical Notes

- Consumes the user's action.




## Bowbreaker

| Property | Value |
|---|---|
| Category | Breaker / Weapon Matchup Modifier |
| Trigger | Passive; active in combat when enemy is equipped with a bow. |
| Formula | `Hit += 50; Avoid += 50` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Bow Knight, level 15 |


### Mechanical Notes

- Applies against bow weapon type.




## Locktouch

| Property | Value |
|---|---|
| Category | Utility / Map Interaction |
| Trigger | Passive; active when interacting with doors or chests. |
| Formula | `CanOpenLockedObjectWithoutKey = True` |
| Proc Rate | N/A; deterministic utility effect. |
| Stacking Rules | Does not stack; one valid Locktouch effect is sufficient. |
| AI Usage | AI may use only if map script permits enemy/NPC chest or door behavior. |
| Source Classes | Thief, level 1 |


### Mechanical Notes

- Allows opening doors and chests without consuming keys.

- Does not grant movement through locked doors without using the interaction.




## Movement +1

| Property | Value |
|---|---|
| Category | Stat Bonus / Movement |
| Trigger | Passive; active while equipped. |
| Formula | `MOV += 1` |
| Proc Rate | N/A; deterministic movement modifier. |
| Stacking Rules | Additive with other MOV modifiers unless a map cap/script limits movement. |
| AI Usage | AI benefits automatically if movement planning accounts for it. |
| Source Classes | Thief, level 10 |


### Mechanical Notes

- Affects movement allowance, not terrain costs.




## Lethality

| Property | Value |
|---|---|
| Category | Offensive Proc / Instant Defeat |
| Trigger | During user's attack after attack eligibility; resolves if the attack connects and target is not immune. |
| Formula | `If proc and hit succeed: TargetHP = 0` |
| Proc Rate | floor(SKL / 4)%; modified by Rightful King/Rightful God, then clamped 0–100. |
| Stacking Rules | Mutually exclusive with other offensive proc skills on the same attack. Highest offensive proc priority. Negated by Dragonskin. |
| AI Usage | AI uses automatically if equipped. |
| Source Classes | Assassin, level 5 |


### Mechanical Notes

- Does not bypass immunity flags such as Dragonskin.

- Requires normal hit success unless Hawkeye or another effect guarantees hit.




## Pass

| Property | Value |
|---|---|
| Category | Movement Utility |
| Trigger | Passive; active during movement pathfinding. |
| Formula | `MayMoveThroughEnemyOccupiedTiles = True` |
| Proc Rate | N/A; deterministic movement modifier. |
| Stacking Rules | Does not stack; does not allow ending movement on an occupied tile unless another rule permits it. |
| AI Usage | AI may use if pathfinder supports Pass-enabled routing. |
| Source Classes | Assassin, level 15 |


### Mechanical Notes

- Terrain must still be traversable.

- Destination tile must still be legal.




## Lucky Seven

| Property | Value |
|---|---|
| Category | Turn-Limited Combat Bonus |
| Trigger | Passive; active during turns 1–7. |
| Formula | `If TurnNumber ≤ 7: Hit += 20; Avoid += 20` |
| Proc Rate | N/A; deterministic turn-based modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Trickster, level 5 |


### Mechanical Notes

- Expires after turn 7.

- Turn count should use map turn number, not unit action count.




## Acrobat

| Property | Value |
|---|---|
| Category | Movement Utility / Terrain |
| Trigger | Passive; active during movement cost calculation. |
| Formula | `All traversable terrain costs 1 movement point.` |
| Proc Rate | N/A; deterministic movement modifier. |
| Stacking Rules | Does not permit crossing impassable terrain; combines with MOV modifiers after terrain-cost override. |
| AI Usage | AI may use if pathfinder accounts for modified terrain costs. |
| Source Classes | Trickster, level 15 |


### Mechanical Notes

- Only affects terrain that is already traversable.

- Does not grant flying movement.




## Speed +2

| Property | Value |
|---|---|
| Category | Stat Bonus |
| Trigger | Passive; active while equipped. |
| Formula | `SPD += 2` |
| Proc Rate | N/A; deterministic stat modifier. |
| Stacking Rules | Additive with other SPD modifiers; affects Avoid, Attack Speed, and follow-up eligibility. |
| AI Usage | AI benefits automatically. |
| Source Classes | Pegasus Knight, level 1 |


### Mechanical Notes

- Temporary/equipped stat modifier.




## Relief

| Property | Value |
|---|---|
| Category | Start-of-Turn Healing |
| Trigger | Start of user's turn if no units are within 3 tiles. |
| Formula | `HealAmount = floor(MaxHP × 0.20)` |
| Proc Rate | N/A; deterministic conditional healing. |
| Stacking Rules | Stacks with other start-of-turn healing skills as separate healing events unless engine ordering says otherwise; cannot exceed MaxHP. |
| AI Usage | AI benefits automatically. |
| Source Classes | Pegasus Knight, level 10 |


### Mechanical Notes

- Condition counts all units unless implementation distinguishes allies/enemies; use 'no units' within 3 tiles.

- Healing occurs at start of user phase.




## Rally Speed

| Property | Value |
|---|---|
| Category | Command / Rally |
| Trigger | Command action; affects allies within 3 tiles for one turn. |
| Formula | `TargetSPD += 4` |
| Proc Rate | N/A; command effect. |
| Stacking Rules | All active Rally skills trigger simultaneously. Does not stack with another Rally Speed from a second use; stacks with Rally Spectrum and Rally Heart. |
| AI Usage | AI may use Rally only if its action script permits rally behavior. |
| Source Classes | Falcon Knight, level 5 |


### Mechanical Notes

- Consumes the user's action.




## Lancefaire

| Property | Value |
|---|---|
| Category | Faire / Weapon Stat Bonus |
| Trigger | Passive; active while equipped with a lance. |
| Formula | `If physical lance: STR += 5. If Shockstick-style magical lance: MAG += 5.` |
| Proc Rate | N/A; deterministic weapon-conditional modifier. |
| Stacking Rules | Additive with other stat/attack modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Falcon Knight, level 15 |


### Mechanical Notes

- Applies to lance weapon type.

- Magical lance exception uses MAG bonus.




## Rally Movement

| Property | Value |
|---|---|
| Category | Command / Rally |
| Trigger | Command action; affects allies within 3 tiles for one turn. |
| Formula | `TargetMOV += 1` |
| Proc Rate | N/A; command effect. |
| Stacking Rules | All active Rally skills trigger simultaneously. Does not stack with another Rally Movement from a second use; stacks with Rally Heart's MOV component only if distinct stacking is enabled by Rally rules; otherwise use highest/explicit buff model. |
| AI Usage | AI may use Rally only if its action script permits rally behavior. |
| Source Classes | Dark Flier, level 5 |


### Mechanical Notes

- Consumes the user's action.

- MOV bonuses expire after one turn.




## Galeforce

| Property | Value |
|---|---|
| Category | Action Economy / Post-Kill |
| Trigger | After user defeats an enemy during the user's phase. |
| Formula | `If GaleforceUnusedThisTurn: grant one additional full action; set GaleforceUsedThisTurn = True` |
| Proc Rate | N/A; deterministic conditional effect. |
| Stacking Rules | Once per turn per unit. Does not grant repeated actions from multiple kills in the same turn. |
| AI Usage | AI may benefit if enemy action system supports extra actions; many map scripts may not exploit it intentionally. |
| Source Classes | Dark Flier, level 15 |


### Mechanical Notes

- Triggers only on the user's own phase.

- The unit must be the killer.

- Support/Dual Strike kill ownership should be resolved by engine kill-credit rules.




## Strength +2

| Property | Value |
|---|---|
| Category | Stat Bonus |
| Trigger | Passive; active while equipped. |
| Formula | `STR += 2` |
| Proc Rate | N/A; deterministic stat modifier. |
| Stacking Rules | Additive with other STR modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Wyvern Rider, level 1 |


### Mechanical Notes

- Temporary/equipped stat modifier.




## Tantivy

| Property | Value |
|---|---|
| Category | Proximity Combat Bonus |
| Trigger | Passive; active when no allies are within 3 tiles. |
| Formula | `Hit += 10; Avoid += 10` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically; AI positioning may not intentionally isolate units unless scripted. |
| Source Classes | Wyvern Rider, level 10 |


### Mechanical Notes

- Condition checks allies, not all units.




## Quick Burn

| Property | Value |
|---|---|
| Category | Turn-Scaling Combat Bonus |
| Trigger | Passive; active from chapter start through turn 15. |
| Formula | `Bonus = max(16 - TurnNumber, 0); Hit += Bonus; Avoid += Bonus` |
| Proc Rate | N/A; deterministic turn-based modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Wyvern Lord, level 5 |


### Mechanical Notes

- Turn 1 grants +15; decreases by 1 each turn; reaches +0 after turn 15.

- Use map turn number.




## Swordbreaker

| Property | Value |
|---|---|
| Category | Breaker / Weapon Matchup Modifier |
| Trigger | Passive; active in combat when enemy is equipped with a sword. |
| Formula | `Hit += 50; Avoid += 50` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Wyvern Lord, level 15 |


### Mechanical Notes

- Applies against sword weapon type, including magical swords if classified as swords.




## Deliverer

| Property | Value |
|---|---|
| Category | Pair Up / Movement |
| Trigger | Passive; active while paired up. |
| Formula | `MOV += 2` |
| Proc Rate | N/A; deterministic movement modifier. |
| Stacking Rules | Additive with other MOV modifiers unless a map cap/script limits movement. |
| AI Usage | AI benefits automatically if movement planning accounts for it. |
| Source Classes | Griffon Rider, level 5 |


### Mechanical Notes

- Requires Pair Up state.

- Does not apply from simple adjacency.




## Lancebreaker

| Property | Value |
|---|---|
| Category | Breaker / Weapon Matchup Modifier |
| Trigger | Passive; active in combat when enemy is equipped with a lance. |
| Formula | `Hit += 50; Avoid += 50` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Griffon Rider, level 15 |


### Mechanical Notes

- Applies against lance weapon type, including magical lances if classified as lances.




## Magic +2

| Property | Value |
|---|---|
| Category | Stat Bonus |
| Trigger | Passive; active while equipped. |
| Formula | `MAG += 2` |
| Proc Rate | N/A; deterministic stat modifier. |
| Stacking Rules | Additive with other MAG modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Mage, level 1 |


### Mechanical Notes

- Temporary/equipped stat modifier.




## Focus

| Property | Value |
|---|---|
| Category | Proximity Combat Bonus / Critical |
| Trigger | Passive; active when no allies are within 3 tiles. |
| Formula | `Crit += 10` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Additive with other Crit modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Mage, level 10 |


### Mechanical Notes

- Condition checks allies, not all units.




## Rally Magic

| Property | Value |
|---|---|
| Category | Command / Rally |
| Trigger | Command action; affects allies within 3 tiles for one turn. |
| Formula | `TargetMAG += 4` |
| Proc Rate | N/A; command effect. |
| Stacking Rules | All active Rally skills trigger simultaneously. Does not stack with another Rally Magic from a second use; stacks with Rally Spectrum and Rally Heart. |
| AI Usage | AI may use Rally only if its action script permits rally behavior. |
| Source Classes | Sage, level 5 |


### Mechanical Notes

- Consumes the user's action.




## Tomefaire

| Property | Value |
|---|---|
| Category | Faire / Weapon Stat Bonus |
| Trigger | Passive; active while equipped with a tome. |
| Formula | `MAG += 5` |
| Proc Rate | N/A; deterministic weapon-conditional modifier. |
| Stacking Rules | Additive with other stat/attack modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Sage, level 15 |


### Mechanical Notes

- Applies to standard tome weapon type; dark tome handling should use tome/dark-permission rules from the weapon system.




## Hex

| Property | Value |
|---|---|
| Category | Debuff Aura / Proximity |
| Trigger | Passive; affects adjacent enemies. |
| Formula | `AdjacentEnemyAvoid -= 15` |
| Proc Rate | N/A; deterministic aura. |
| Stacking Rules | Additive with other enemy Avoid modifiers. |
| AI Usage | AI benefits automatically; AI positioning may not intentionally optimize aura coverage unless scripted. |
| Source Classes | Dark Mage, level 1 |


### Mechanical Notes

- Affects enemies adjacent to the holder.

- Does not affect Hit directly.




## Anathema

| Property | Value |
|---|---|
| Category | Debuff Aura / Proximity |
| Trigger | Passive; affects enemies within 3 tiles. |
| Formula | `EnemyAvoid -= 10; EnemyDodge -= 10` |
| Proc Rate | N/A; deterministic aura. |
| Stacking Rules | Additive with other enemy Avoid/Dodge modifiers. |
| AI Usage | AI benefits automatically; AI positioning may not intentionally optimize aura coverage unless scripted. |
| Source Classes | Dark Mage, level 10 |


### Mechanical Notes

- Dodge is critical avoid.

- Radius is within 3 tiles.




## Vengeance

| Property | Value |
|---|---|
| Category | Offensive Proc / Damage Modifier |
| Trigger | During user's attack before damage application. |
| Formula | `BonusDamage = floor((MaxHP - CurrentHP) / 2); Damage += BonusDamage` |
| Proc Rate | SKL × 2%; modified by Rightful King/Rightful God, then clamped 0–100. |
| Stacking Rules | Mutually exclusive with other offensive proc skills on the same attack. Lowest offensive proc priority among standard offensive procs. |
| AI Usage | AI uses automatically if equipped. |
| Source Classes | Sorcerer, level 5 |


### Mechanical Notes

- Uses missing HP at time of attack.

- Can have high activation due to SKL × 2.




## Tomebreaker

| Property | Value |
|---|---|
| Category | Breaker / Weapon Matchup Modifier |
| Trigger | Passive; active in combat when enemy is equipped with a tome. |
| Formula | `Hit += 50; Avoid += 50` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Sorcerer, level 15 |


### Mechanical Notes

- Applies against tome weapon type; include dark tomes if represented under tome weapon-family matching.




## Slow Burn

| Property | Value |
|---|---|
| Category | Turn-Scaling Combat Bonus |
| Trigger | Passive; active as turns progress up to turn 15. |
| Formula | `Bonus = min(TurnNumber, 15); Hit += Bonus; Avoid += Bonus` |
| Proc Rate | N/A; deterministic turn-based modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Dark Knight, level 5 |


### Mechanical Notes

- Turn 1 grants +1; increases by 1 per turn up to +15.

- Use map turn number.




## Lifetaker

| Property | Value |
|---|---|
| Category | Post-Kill Healing |
| Trigger | After user defeats an enemy during the user's phase. |
| Formula | `HealAmount = floor(MaxHP × 0.50)` |
| Proc Rate | N/A; deterministic conditional healing. |
| Stacking Rules | Stacks with other post-kill healing only as separate events; cannot exceed MaxHP. |
| AI Usage | AI benefits automatically. |
| Source Classes | Dark Knight, level 15 |


### Mechanical Notes

- Triggers only during user's own phase.

- The unit must be the killer.




## Miracle

| Property | Value |
|---|---|
| Category | Defensive Proc / Survival |
| Trigger | When receiving damage that would reduce CurrentHP to 0, if CurrentHP > 1 before the hit. |
| Formula | `If proc succeeds: CurrentHP = 1 instead of 0` |
| Proc Rate | LCK%; modified by Rightful King/Rightful God if implementation treats it as skill activation, then clamped 0–100. |
| Stacking Rules | Does not stack with itself; survival effects require deterministic priority if multiple are present. |
| AI Usage | AI benefits automatically. |
| Source Classes | Priest / Cleric, level 1 |


### Mechanical Notes

- Does not activate if user already has 1 HP.

- Damage is otherwise lethal but converted to survival at 1 HP.




## Healtouch

| Property | Value |
|---|---|
| Category | Staff / Healing Modifier |
| Trigger | When user heals an ally with a staff. |
| Formula | `HealAmount += 5` |
| Proc Rate | N/A; deterministic healing modifier. |
| Stacking Rules | Additive with other healing modifiers; cannot heal above target MaxHP. |
| AI Usage | AI benefits automatically when using healing staves. |
| Source Classes | Priest / Cleric, level 10 |


### Mechanical Notes

- Applies to staff healing, not necessarily all HP restoration sources.




## Rally Luck

| Property | Value |
|---|---|
| Category | Command / Rally |
| Trigger | Command action; affects allies within 3 tiles for one turn. |
| Formula | `TargetLCK += 8` |
| Proc Rate | N/A; command effect. |
| Stacking Rules | All active Rally skills trigger simultaneously. Does not stack with another Rally Luck from a second use; stacks with Rally Spectrum and Rally Heart. |
| AI Usage | AI may use Rally only if its action script permits rally behavior. |
| Source Classes | War Monk / War Cleric, level 5 |


### Mechanical Notes

- Consumes the user's action.




## Renewal

| Property | Value |
|---|---|
| Category | Start-of-Turn Healing |
| Trigger | Start of user's turn. |
| Formula | `HealAmount = floor(MaxHP × 0.30)` |
| Proc Rate | N/A; deterministic healing. |
| Stacking Rules | Stacks with other start-of-turn healing skills as separate healing events unless engine ordering says otherwise; cannot exceed MaxHP. |
| AI Usage | AI benefits automatically. |
| Source Classes | War Monk / War Cleric, level 15 |


### Mechanical Notes

- No proximity condition.




## Resistance +2

| Property | Value |
|---|---|
| Category | Stat Bonus |
| Trigger | Passive; active while equipped. |
| Formula | `RES += 2` |
| Proc Rate | N/A; deterministic stat modifier. |
| Stacking Rules | Additive with other RES modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Troubadour, level 1 |


### Mechanical Notes

- Temporary/equipped stat modifier.




## Demoiselle

| Property | Value |
|---|---|
| Category | Aura / Gendered Proximity Support |
| Trigger | Passive; active for male allies within 3 tiles. |
| Formula | `MaleAllyAvoid += 10; MaleAllyDodge += 10` |
| Proc Rate | N/A; deterministic aura. |
| Stacking Rules | Additive with other aura/support bonuses. |
| AI Usage | AI benefits automatically if applicable ally-gender and positioning conditions are met. |
| Source Classes | Troubadour, level 10 |


### Mechanical Notes

- Affects male allies only.

- Dodge is critical avoid.




## Rally Resistance

| Property | Value |
|---|---|
| Category | Command / Rally |
| Trigger | Command action; affects allies within 3 tiles for one turn. |
| Formula | `TargetRES += 4` |
| Proc Rate | N/A; command effect. |
| Stacking Rules | All active Rally skills trigger simultaneously. Does not stack with another Rally Resistance from a second use; stacks with Rally Spectrum and Rally Heart. |
| AI Usage | AI may use Rally only if its action script permits rally behavior. |
| Source Classes | Valkyrie, level 5 |


### Mechanical Notes

- Consumes the user's action.




## Dual Support+

| Property | Value |
|---|---|
| Category | Support Modifier |
| Trigger | Passive; evaluated when support bonus effects are calculated. |
| Formula | `SupportBonus = EnhancedSupportBonus(SupportRank, adjacency_or_pair_state)` |
| Proc Rate | N/A; deterministic support modifier. |
| Stacking Rules | Does not duplicate the same support bonus; modifies the support bonus table/effect. |
| AI Usage | AI benefits automatically. |
| Source Classes | Valkyrie, level 15 |


### Mechanical Notes

- Exact bonus expansion should be resolved in Pair Up/support tables.

- Does not create support rank by itself.




## Aptitude

| Property | Value |
|---|---|
| Category | Growth Modifier |
| Trigger | During level-up growth calculation. |
| Formula | `FinalGrowth[each stat] += 20` |
| Proc Rate | N/A; deterministic growth modifier. |
| Stacking Rules | Additive with class/unit growth rates; subject to >100% growth handling and stat caps. |
| AI Usage | AI irrelevant unless enemy growth/level-up simulation is modeled. |
| Source Classes | Villager, level 1 |


### Mechanical Notes

- Affects level-up growth rates, not current stats.

- Does not affect MOV.




## Underdog

| Property | Value |
|---|---|
| Category | Level-Comparison Combat Bonus |
| Trigger | Passive; active in combat if user's effective level is lower than enemy's effective level. |
| Formula | `If UserEffectiveLevel < EnemyEffectiveLevel: Hit += 15; Avoid += 15` |
| Proc Rate | N/A; deterministic conditional modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Villager, level 15 |


### Mechanical Notes

- Promoted units count as DisplayedLevel + 20 for this comparison.

- Use internal/effective level normalization for special classes if simulating edge cases.




## Luck +4

| Property | Value |
|---|---|
| Category | Stat Bonus |
| Trigger | Passive; active while equipped. |
| Formula | `LCK += 4` |
| Proc Rate | N/A; deterministic stat modifier. |
| Stacking Rules | Additive with other LCK modifiers; affects Hit, Avoid, Dodge, and luck-based proc formulas after recalculation. |
| AI Usage | AI benefits automatically. |
| Source Classes | Dancer, level 1 |


### Mechanical Notes

- Temporary/equipped stat modifier.




## Special Dance

| Property | Value |
|---|---|
| Category | Dance Command Modifier / Buff |
| Trigger | When user successfully refreshes an ally with Dance. |
| Formula | `DancedUnitSTR += 2; DancedUnitMAG += 2; DancedUnitDEF += 2; DancedUnitRES += 2 for one turn` |
| Proc Rate | N/A; deterministic command rider. |
| Stacking Rules | Buff does not stack with another Special Dance application of the same named effect; may stack with Rally effects if both are active. |
| AI Usage | AI may use only if AI-controlled dance/refresh action is scripted. |
| Source Classes | Dancer, level 15 |


### Mechanical Notes

- Affects the unit receiving Dance, not all allies in radius.

- Does not modify SKL/SPD/LCK/MOV.




## Even Rhythm

| Property | Value |
|---|---|
| Category | Turn-Parity Combat Bonus |
| Trigger | Passive; active on even-numbered turns. |
| Formula | `If TurnNumber mod 2 == 0: Hit += 10; Avoid += 10` |
| Proc Rate | N/A; deterministic turn-based modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Taguel, level 1 |


### Mechanical Notes

- Use map turn number.




## Beastbane

| Property | Value |
|---|---|
| Category | Effectiveness Modifier |
| Trigger | Passive; active while user is in Taguel class/form and attacks a beast/mounted-class effective target. |
| Formula | `If target in BeastbaneEffectiveGroups: EffectivenessMultiplier = 3 for user's eligible attack` |
| Proc Rate | N/A; deterministic effectiveness modifier. |
| Stacking Rules | Effectiveness normally applies once; does not multiply multiple times with other effectiveness sources unless a specific weapon says otherwise. |
| AI Usage | AI benefits automatically if forecast accounts for effectiveness. |
| Source Classes | Taguel, level 15 |


### Mechanical Notes

- Applies only while user is a Taguel.

- Effective target set includes beast-tagged/mounted categories according to class data.




## Odd Rhythm

| Property | Value |
|---|---|
| Category | Turn-Parity Combat Bonus |
| Trigger | Passive; active on odd-numbered turns. |
| Formula | `If TurnNumber mod 2 == 1: Hit += 10; Avoid += 10` |
| Proc Rate | N/A; deterministic turn-based modifier. |
| Stacking Rules | Additive with other Hit/Avoid modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Manakete, level 1 |


### Mechanical Notes

- Use map turn number.




## Wyrmsbane

| Property | Value |
|---|---|
| Category | Effectiveness Modifier |
| Trigger | Passive; active while user is in Manakete class/form and attacks a dragon-class target. |
| Formula | `If target has Dragon vulnerability: EffectivenessMultiplier = 3 for user's eligible attack` |
| Proc Rate | N/A; deterministic effectiveness modifier. |
| Stacking Rules | Effectiveness normally applies once; does not multiply multiple times with other effectiveness sources unless a specific weapon says otherwise. |
| AI Usage | AI benefits automatically if forecast accounts for effectiveness. |
| Source Classes | Manakete, level 15 |


### Mechanical Notes

- Applies only while user is a Manakete.

- Dragon vulnerability must be present after immunity/override checks.




## Shadowgift

| Property | Value |
|---|---|
| Category | Weapon Access Modifier / Personal |
| Trigger | Passive; active while equipped by a tome-using unit. |
| Formula | `CanUseDarkTomes = True if CurrentClass can use tomes` |
| Proc Rate | N/A; deterministic access modifier. |
| Stacking Rules | Does not stack; one source of dark-tome permission is sufficient. |
| AI Usage | AI benefits automatically if inventory/loadout includes dark tomes. |
| Source Classes | Personal-only: Aversa; Morgan as Aversa's daughter; DLC Micaiah; DLC Katarina |


### Mechanical Notes

- Does not grant normal tome access to a class with no tome access.

- Allows dark tome use in tome-wielding classes.




## Conquest

| Property | Value |
|---|---|
| Category | Effectiveness Immunity / Personal |
| Trigger | Passive; active while equipped by a beast or armor unit. |
| Formula | `Negate beast and armor weakness/effective damage against the user` |
| Proc Rate | N/A; deterministic immunity modifier. |
| Stacking Rules | Does not stack; removes matching vulnerability groups for effectiveness resolution. |
| AI Usage | AI benefits automatically if combat forecast accounts for immunity. |
| Source Classes | Personal-only: Walhart; Morgan as Walhart's son; Zephiel; DLC Ephraim |


### Mechanical Notes

- Negates beast and armor type weaknesses.

- Does not inherently negate flying or dragon weakness.




## Outrealm Skill

| Property | Value |
|---|---|
| Category | Placeholder / DLC Compatibility |
| Trigger | Passive placeholder displayed when corresponding DLC skill data is unavailable. |
| Formula | `No mechanical effect after unresolved placeholder state, or proxy to missing DLC skill if resolved.` |
| Proc Rate | N/A. |
| Stacking Rules | Should not stack; replace with actual DLC skill when DLC data is installed/resolved. |
| AI Usage | AI should treat unresolved placeholder as no effect unless a mod/script maps it. |
| Source Classes | DLC placeholder / unresolved DLC skill state |


### Mechanical Notes

- Represents missing DLC skill data.

- Rules engines should implement as a proxy/alias state, not a normal skill effect.




## Resistance +10

| Property | Value |
|---|---|
| Category | Stat Bonus / DLC |
| Trigger | Passive; active while equipped. |
| Formula | `RES += 10` |
| Proc Rate | N/A; deterministic stat modifier. |
| Stacking Rules | Additive with other RES modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Dread Fighter, level 1 |


### Mechanical Notes

- DLC class skill.

- Temporary/equipped stat modifier.




## Aggressor

| Property | Value |
|---|---|
| Category | Phase Damage Modifier / DLC |
| Trigger | Passive; active during user's phase. |
| Formula | `Attack += 10 during user-initiated/player-phase combat` |
| Proc Rate | N/A; deterministic phase modifier. |
| Stacking Rules | Additive with other attack/damage modifiers; does not apply during enemy phase. |
| AI Usage | AI benefits automatically when acting on its own phase. |
| Source Classes | Dread Fighter, level 15 |


### Mechanical Notes

- Applies during the user's turn/phase.

- Does not improve enemy-phase counterattacks.




## Rally Heart

| Property | Value |
|---|---|
| Category | Command / Rally / DLC |
| Trigger | Command action; affects allies within 3 tiles for one turn. |
| Formula | `TargetSTR/MAG/SKL/SPD/LCK/DEF/RES += 2; TargetMOV += 1` |
| Proc Rate | N/A; command effect. |
| Stacking Rules | All active Rally skills trigger simultaneously. Does not stack with another Rally Heart from a second use; stacks with Rally Spectrum and distinct stat Rally skills. |
| AI Usage | AI may use Rally only if its action script permits rally behavior. |
| Source Classes | Bride, level 1 |


### Mechanical Notes

- Consumes the user's action.

- Does not affect HP.




## Bond

| Property | Value |
|---|---|
| Category | Start-of-Turn Ally Healing / DLC |
| Trigger | Start of user's turn; affects allies within 3 tiles. |
| Formula | `EachAllyInRadiusHP += 10` |
| Proc Rate | N/A; deterministic healing. |
| Stacking Rules | Can combine with other healing sources as separate events; cannot heal above MaxHP. |
| AI Usage | AI benefits automatically if allies are in range. |
| Source Classes | Bride, level 15 |


### Mechanical Notes

- Heals allies, not the skill holder unless another unit's Bond affects them.

- Radius is within 3 tiles.




## All Stats +2

| Property | Value |
|---|---|
| Category | Stat Bonus / DLC Item Skill |
| Trigger | Passive; active while equipped. |
| Formula | `STR/MAG/SKL/SPD/LCK/DEF/RES += 2` |
| Proc Rate | N/A; deterministic stat modifier. |
| Stacking Rules | Additive with other stat modifiers; does not affect HP or MOV. |
| AI Usage | AI benefits automatically. |
| Source Classes | All Stats +2 item |


### Mechanical Notes

- Learned through DLC item use.

- Affects seven primary non-HP stats.




## Paragon

| Property | Value |
|---|---|
| Category | Experience Modifier / DLC Item Skill |
| Trigger | Passive; evaluated when awarding EXP. |
| Formula | `FinalEXP = BaseEXP × 2` |
| Proc Rate | N/A; deterministic EXP modifier. |
| Stacking Rules | Multiplicative with other EXP modifiers unless implementation specifies an order; level-cap rules still apply. |
| AI Usage | AI irrelevant unless enemy EXP gain is modeled. |
| Source Classes | Paragon item |


### Mechanical Notes

- Learned through DLC item use.

- Does not modify WEXP.




## Iote's Shield

| Property | Value |
|---|---|
| Category | Effectiveness Immunity / DLC Item Skill |
| Trigger | Passive; active while equipped by a flying unit. |
| Formula | `Negate flying weakness/effective damage against the user` |
| Proc Rate | N/A; deterministic immunity modifier. |
| Stacking Rules | Does not stack; removes Flying vulnerability for effectiveness resolution. |
| AI Usage | AI benefits automatically if combat forecast accounts for immunity. |
| Source Classes | Iote's Shield item |


### Mechanical Notes

- Learned through DLC item use.

- Does not negate armor, cavalry, beast, or dragon effectiveness.




## Limit Breaker

| Property | Value |
|---|---|
| Category | Stat Cap Modifier / DLC Item Skill |
| Trigger | Passive; active while equipped. |
| Formula | `FinalStatCap[STR/MAG/SKL/SPD/LCK/DEF/RES] += 10` |
| Proc Rate | N/A; deterministic cap modifier. |
| Stacking Rules | Additive cap modifier; does not itself raise current stats unless current stat growth/boosters later fill the increased cap. |
| AI Usage | AI benefits automatically if generated units use stats above normal caps. |
| Source Classes | Limit Breaker item |


### Mechanical Notes

- Learned through DLC item use.

- Raises maximum stat caps for Strength, Magic, Skill, Speed, Luck, Defense, and Resistance; HP and MOV are not included in standard listed stat set.




## Dragonskin

| Property | Value |
|---|---|
| Category | Enemy-Exclusive Defensive Modifier / Immunity |
| Trigger | Passive; active while equipped. |
| Formula | `Damage = floor(Damage / 2); CounterNegated = True; LethalityNegated = True` |
| Proc Rate | N/A; deterministic defensive modifier. |
| Stacking Rules | Damage halving should not stack multiplicatively with itself; combine with other reductions by explicit priority. Negates Counter and Lethality. |
| AI Usage | AI benefits automatically. |
| Source Classes | Enemy-exclusive; Grima and Hard-mode-or-higher Validar; also appears in Apotheosis enemy sets |


### Mechanical Notes

- Enemy-only skill.

- Halves all damage after applicable attack calculations unless a script states otherwise.

- Explicitly negates Counter and Lethality.




## Hit Rate +10

| Property | Value |
|---|---|
| Category | Enemy-Exclusive Combat Modifier / Hit |
| Trigger | Passive; active while equipped. |
| Formula | `Hit += 10` |
| Proc Rate | N/A; deterministic combat modifier. |
| Stacking Rules | Additive with other Hit modifiers. |
| AI Usage | AI benefits automatically. |
| Source Classes | Enemy-exclusive; Lunatic and Lunatic+ difficulty enemies; also appears in Apotheosis enemy sets |


### Mechanical Notes

- Enemy-only skill.




## Rightful God

| Property | Value |
|---|---|
| Category | Enemy-Exclusive Proc Rate Modifier |
| Trigger | Passive; applied when calculating equipped skill activation rates. |
| Formula | `ProcRate += 30` |
| Proc Rate | N/A; deterministic modifier. |
| Stacking Rules | Additive with base proc formulas and other proc-rate modifiers; clamp final proc rate to 0–100. |
| AI Usage | AI benefits automatically. |
| Source Classes | Enemy-exclusive; Grima; Lunatic and Lunatic+ / Apotheosis enemy sets |


### Mechanical Notes

- Enemy-only analogue to Rightful King with larger bonus.




## Vantage+

| Property | Value |
|---|---|
| Category | Enemy-Exclusive Combat Order Modifier |
| Trigger | Enemy-phase combat/order resolution. |
| Formula | `User attacks first regardless of HP threshold when attacked and able to counter.` |
| Proc Rate | N/A; deterministic combat-order modifier. |
| Stacking Rules | Supersedes Vantage. Multiple combat-order overrides require priority handling. |
| AI Usage | AI benefits automatically. |
| Source Classes | Enemy-exclusive; Lunatic+ difficulty; Apotheosis enemy sets |


### Mechanical Notes

- Enemy-only skill.

- No HP threshold.




## Luna+

| Property | Value |
|---|---|
| Category | Enemy-Exclusive Offensive Always-On Effect |
| Trigger | Every user attack. |
| Formula | `TargetDefenseStat = floor(TargetDefenseStat / 2)` |
| Proc Rate | 100%; deterministic effect. |
| Stacking Rules | Treat as always-on Luna effect. Does not stack with Luna on the same strike; offensive proc exclusivity should treat Luna+ as occupying the Luna effect layer. |
| AI Usage | AI benefits automatically. |
| Source Classes | Enemy-exclusive; Lunatic+ difficulty; Apotheosis enemy sets |


### Mechanical Notes

- Enemy-only skill.

- Every attack has Luna effect.




## Hawkeye

| Property | Value |
|---|---|
| Category | Enemy-Exclusive Hit Override |
| Trigger | During user's attack hit resolution. |
| Formula | `HitSucceeds = True` |
| Proc Rate | N/A; deterministic hit override. |
| Stacking Rules | Supersedes displayed hit chance and hit RNG; does not necessarily bypass target immunities or non-hit defensive effects. |
| AI Usage | AI benefits automatically. |
| Source Classes | Enemy-exclusive; Lunatic+ difficulty; The Future Past 3 and Apotheosis enemy sets |


### Mechanical Notes

- Enemy-only skill.

- Attack always strikes the target unless a script/immunity prevents the attack itself.




## Pavise+

| Property | Value |
|---|---|
| Category | Enemy-Exclusive Defensive Always-On Reduction |
| Trigger | When receiving damage from swords, lances, axes, magical variants of those weapons, or beaststones. |
| Formula | `Damage = floor(Damage / 2)` |
| Proc Rate | 100%; deterministic effect. |
| Stacking Rules | Supersedes Pavise. Defensive reduction applies once to a damage packet. Does not apply to Dual Strikes under documented Pavise/Aegis footnote. |
| AI Usage | AI benefits automatically. |
| Source Classes | Enemy-exclusive; Lunatic+ difficulty; Apotheosis enemy sets |


### Mechanical Notes

- Enemy-only skill.

- Always-on Pavise effect against eligible weapon categories.




## Aegis+

| Property | Value |
|---|---|
| Category | Enemy-Exclusive Defensive Always-On Reduction |
| Trigger | When receiving damage from bows, tomes, or dragonstones. |
| Formula | `Damage = floor(Damage / 2)` |
| Proc Rate | 100%; deterministic effect. |
| Stacking Rules | Supersedes Aegis. Defensive reduction applies once to a damage packet. Does not apply to Dual Strikes under documented Pavise/Aegis footnote. |
| AI Usage | AI benefits automatically. |
| Source Classes | Enemy-exclusive; Lunatic+ difficulty; Apotheosis enemy sets |


### Mechanical Notes

- Enemy-only skill.

- Always-on Aegis effect against eligible weapon categories.



---

# Skill Count Audit

| Category | Count |
|---|---:|
| Total skill entries | 103 |
| Base-game class/special/personal/placeholder skills | 87 |
| DLC/outrealm skills | 8 |
| Enemy-exclusive skills | 8 |

## Duplicate Name Audit

No duplicate skill names are intentionally defined in this file.

---

# End of Phase 6 — Skill Encyclopedia
