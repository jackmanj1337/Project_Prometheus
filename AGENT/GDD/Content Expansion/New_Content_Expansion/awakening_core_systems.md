
# Legacy Tactical-RPG Technical Reference Corpus
# Core Systems

**File:** `awakening_core_systems.md`  
**Phase:** 1  
**Corpus Version:** `0.2.0-phase1`  
**Depends On:** `awakening_project_index.md`  
**Scope:** Core mechanical systems only. No class encyclopedia tables, weapon encyclopedia entries, item encyclopedia entries, or skill encyclopedia entries are included in this file.

---

# Table of Contents

1. [Stat System](#stat-system)
2. [Growth Mechanics](#growth-mechanics)
3. [Leveling System](#leveling-system)
4. [Promotion System](#promotion-system)
5. [Reclassing](#reclassing)
6. [WEXP System](#wexp-system)
7. [Combat System](#combat-system)
8. [Pair Up](#pair-up)
9. [Enemy Generation](#enemy-generation)
10. [Child Mechanics](#child-mechanics)
11. [Vulnerability & Effectiveness](#vulnerability--effectiveness)
12. [Implementation Notes](#implementation-notes)

---

# Stat System

## Canonical Stat Set

The legacy tactical-RPG source material uses a fixed stat model for units. Stats are divided into:

- primary combat stats
- derived combat values
- movement/utility stats
- hidden/internal stats

## Primary Unit Stats

| Stat | Abbreviation | Type | Visible | Description |
|---|---:|---|---|---|
| Hit Points | HP | Primary | Yes | Unit health pool. Unit dies or retreats when HP reaches 0. |
| Strength | STR | Primary | Yes | Physical offensive stat used by physical weapons and physical damage formulas. |
| Magic | MAG | Primary | Yes | Magical offensive stat used by tomes, staves, magical weapons, and healing formulas. |
| Skill | SKL | Primary | Yes | Accuracy, critical rate, and many proc skill rates. |
| Speed | SPD | Primary | Yes | Avoid, attack speed, and follow-up attack eligibility. |
| Luck | LCK | Primary | Yes | Hit, avoid, dodge, and miscellaneous luck-based formulas. |
| Defense | DEF | Primary | Yes | Reduces physical damage. |
| Resistance | RES | Primary | Yes | Reduces magical damage. |
| Movement | MOV | Utility | Yes | Number of tiles a unit may move under normal conditions. |

## Hidden/Internal Values

| Value | Abbreviation | Visible | Description |
|---|---:|---|---|
| Internal Level | IL | No | Hidden level used for EXP gain and scaling. |
| Displayed Level | DL | Yes | Level shown to the player. |
| Class | N/A | Yes | Determines movement, weapon access, skills, class growths, and caps. |
| Class Tier | N/A | Partially | Determines promotion/reclass rules and internal level behavior. |
| Weapon Experience | WEXP | Partially | Numeric weapon proficiency; UI displays rank letter. |
| Support Rank | N/A | Yes | Relationship rank affecting Pair Up, Dual Strike, Dual Guard, and support bonuses. |
| Asset | N/A | Character Creation Only | Avatar boon affecting bases, growths, and modifiers. |
| Flaw | N/A | Character Creation Only | Avatar bane affecting bases, growths, and modifiers. |

---

## Stat Storage Model

Each unit's visible stats are represented as the result of multiple layered components.

```text
DisplayedStat =
BaseUnitStat
+ ClassBaseStatAdjustment
+ LevelUpGains
+ PromotionBonuses
+ ReclassAdjustments
+ PermanentBoosters
+ TemporaryBonuses
+ PairUpBonuses
+ SkillBonuses
+ RallyBonuses
+ TonicBonuses
+ EquipmentBonuses
```

For simulator implementation, it is recommended to separate:

```text
PermanentStat =
BaseUnitStat
+ LevelUpGains
+ PermanentBoosters
```

from:

```text
BattleStat =
PermanentStat
+ ClassAdjustment
+ TemporaryBonuses
+ PairUpBonuses
+ SkillBonuses
+ RallyBonuses
+ EquipmentBonuses
```

## Stat Cap Model

Each class has stat caps. Each character may also have personal stat modifiers. The final stat cap is:

```text
FinalStatCap =
ClassStatCap + UnitStatCapModifier
```

For Avatar-derived children and other inherited modifier cases:

```text
ChildStatCapModifier =
Parent1StatCapModifier + Parent2StatCapModifier + ChildBaseModifierAdjustment
```

The exact child cap modifier structure is expanded in [Child Mechanics](#child-mechanics).

## Cap Enforcement

A unit's permanent stat cannot exceed its final cap for that stat.

```text
PermanentStatAfterGain =
min(PermanentStatBeforeGain + StatGain, FinalStatCap)
```

Temporary bonuses may allow effective combat values above visible caps depending on the bonus source. For implementation, bonuses should be layered after permanent cap enforcement unless the source explicitly modifies the cap.

## HP Cap

HP uses a class/unit cap model like other stats. HP is handled separately in combat death checks because it is both:

- a maximum stat
- a mutable battle resource

```text
CurrentHP ≤ MaxHP
MaxHP ≤ FinalHPCap
```

## Movement

Movement is normally class-defined.

```text
DisplayedMOV =
ClassMOV
+ SkillMOVBonus
+ PairUpMOVBonus
+ TemporaryMOVBonus
```

Movement may be affected by:

- class movement value
- terrain cost
- movement type
- Pair Up bonuses
- skills
- status/restriction conditions
- scripted map rules

---

## Derived Combat Values

Derived combat values are calculated dynamically during combat preview and combat resolution.

### Attack

Physical weapon:

```text
Attack =
STR + WeaponMight + AttackBonuses
```

Magical weapon/tome:

```text
Attack =
MAG + WeaponMight + AttackBonuses
```

Hybrid/magical physical weapons use weapon-specific rules. For technical implementation, each weapon should define:

```text
DamageStat = STR | MAG | Special
DefenseStat = DEF | RES | Special
```

### Damage

Before effectiveness:

```text
BaseDamage =
Attack - TargetDefenseStat
```

After effectiveness:

```text
EffectiveAttackComponent =
WeaponMight × EffectivenessMultiplier
```

Recommended simulator decomposition:

```text
EffectiveAttack =
DamageStat + EffectiveWeaponMight + AttackBonuses
```

```text
RawDamage =
EffectiveAttack - TargetDefenseStat
```

Final non-lethal minimum handling:

```text
FinalDamage =
max(RawDamage, 0)
```

Some skills may alter damage after this stage.

### Hit Rate

Standard displayed hit approximation:

```text
Hit =
WeaponHit
+ (SKL × 3 + LCK) ÷ 2
+ HitBonuses
```

Use integer flooring at the end of fractional components unless a specific subcomponent is documented to floor earlier.

Recommended normalized implementation:

```text
UnitHit =
floor((SKL × 3 + LCK) / 2)
```

```text
DisplayedHit =
WeaponHit + UnitHit + HitBonuses
```

### Avoid

```text
Avoid =
(SPD × 3 + LCK) ÷ 2
+ AvoidBonuses
```

Normalized:

```text
UnitAvoid =
floor((SPD × 3 + LCK) / 2)
```

```text
DisplayedAvoid =
UnitAvoid + AvoidBonuses
```

### Critical Rate

```text
Crit =
WeaponCrit
+ floor(SKL / 2)
+ CritBonuses
```

### Dodge / Critical Avoid

```text
Dodge =
LCK + DodgeBonuses
```

### Staff Avoid / Staff Hit

Staff hit calculations are not identical to weapon hit in many tactical-RPG systems. For Awakening implementation, hostile staff handling should be represented as a separate resolver when applicable.

Recommended resolver fields:

| Field | Meaning |
|---|---|
| StaffBaseHit | Staff-defined hit value |
| UserMAG | Staff user Magic |
| TargetRES | Target Resistance |
| RangeModifier | Optional staff-specific modifier |
| SupportBonuses | Pair/support modifications if applicable |
| SkillModifiers | Relevant skill modifiers |

Hostile staff formula should be implemented as a distinct subsystem rather than folded into standard weapon hit.

---

## Attack Speed

The legacy tactical-RPG source material does not use constitution/build-style weapon weight penalties for normal attack speed.

```text
AttackSpeed =
SPD + AttackSpeedBonuses
```

In most cases:

```text
AttackSpeed = SPD
```

### Follow-Up Threshold

A unit performs a follow-up attack if:

```text
AttackerAttackSpeed - DefenderAttackSpeed ≥ 5
```

If true:

```text
AttackerNumberOfAttackRounds += 1
```

Follow-up eligibility may be prevented or altered by:

- weapon restrictions
- combat scripts
- skills
- enemy-only mechanics
- brave weapon sequencing

---

## Stat Recalculation Timing

Stats are recalculated when:

| Event | Recalculation Required |
|---|---|
| Level up | Yes |
| Promotion | Yes |
| Reclass | Yes |
| Equip/unequip weapon | Yes for derived values |
| Pair Up start/end | Yes |
| Rally applied/expires | Yes |
| Tonic applied/expires | Yes |
| Skill activation | Yes if stat-affecting |
| Support rank change | Yes for Pair Up/support-dependent values |
| Temporary buff/debuff expires | Yes |

Recommended engine model:

```text
RecalculateUnitStats(unit):
    CalculatePermanentStats(unit)
    ApplyClassCaps(unit)
    ApplyClassProperties(unit)
    ApplyTemporaryModifiers(unit)
    ApplyPairUpModifiers(unit)
    ApplyEquipmentModifiers(unit)
    CalculateDerivedCombatValues(unit)
```

---

# Growth Mechanics

## Growth Formula

The canonical growth formula is:

```text
FinalGrowth =
UnitGrowth + ClassGrowth
```

Where:

| Component | Description |
|---|---|
| UnitGrowth | Character-specific growth rate |
| ClassGrowth | Class-specific growth modifier |
| FinalGrowth | Probability model used on level up |

This applies independently to each stat:

```text
FinalHPGrowth  = UnitHPGrowth  + ClassHPGrowth
FinalSTRGrowth = UnitSTRGrowth + ClassSTRGrowth
FinalMAGGrowth = UnitMAGGrowth + ClassMAGGrowth
FinalSKLGrowth = UnitSKLGrowth + ClassSKLGrowth
FinalSPDGrowth = UnitSPDGrowth + ClassSPDGrowth
FinalLCKGrowth = UnitLCKGrowth + ClassLCKGrowth
FinalDEFGrowth = UnitDEFGrowth + ClassDEFGrowth
FinalRESGrowth = UnitRESGrowth + ClassRESGrowth
```

Movement normally does not grow by level up.

---

## Growth Resolution

For each stat during level up:

```text
Roll = RandomInteger(0, 99)

if Roll < FinalGrowth:
    StatGain += 1
```

This model must be extended for growths above 100%.

---

## Growths Above 100%

When `FinalGrowth ≥ 100`, the stat receives guaranteed gains plus a remainder roll.

```text
GuaranteedGain =
floor(FinalGrowth / 100)
```

```text
RemainderGrowth =
FinalGrowth mod 100
```

```text
AdditionalGain =
1 if RandomInteger(0, 99) < RemainderGrowth else 0
```

```text
TotalStatGain =
GuaranteedGain + AdditionalGain
```

Example:

```text
FinalGrowth = 135
GuaranteedGain = 1
RemainderGrowth = 35
TotalGain = 1 + Bernoulli(0.35)
```

---

## Negative Growths

Negative growths may exist in data contexts or through modifiers.

Recommended implementation:

```text
EffectiveGrowth =
max(FinalGrowth, 0)
```

Unless reverse-growth behavior is explicitly confirmed, negative values should not decrement stats during normal level-up resolution.

For strict data preservation, store both:

```text
RawFinalGrowth
EffectiveFinalGrowth
```

Where:

```text
EffectiveFinalGrowth =
max(RawFinalGrowth, 0)
```

---

## Expected Value Modeling

Expected stat gain per level:

```text
ExpectedGain =
FinalGrowth / 100
```

For values above 100:

```text
ExpectedGain =
floor(FinalGrowth / 100) + (FinalGrowth mod 100) / 100
```

For multiple levels:

```text
ExpectedTotalGain =
LevelsGained × FinalGrowth / 100
```

Cap-aware expected value requires truncation:

```text
ExpectedCappedStat =
min(CurrentStat + ExpectedTotalGain, FinalStatCap)
```

This is an approximation. Exact cap-aware distribution requires probability mass modeling.

---

## Level-Up Order

Recommended stat roll order:

1. HP
2. STR
3. MAG
4. SKL
5. SPD
6. LCK
7. DEF
8. RES

The display order should follow UI stat order unless internal RNG order is separately modeled.

---

## Growth Implementation Schema

```yaml
growths:
  hp:
    unit_growth: integer
    class_growth: integer
    final_growth: unit_growth + class_growth
    effective_growth: max(final_growth, 0)
  str:
    unit_growth: integer
    class_growth: integer
    final_growth: unit_growth + class_growth
    effective_growth: max(final_growth, 0)
```

---

# Leveling System

## Displayed Level

Displayed Level is the visible level shown to the player.

Normal ranges:

| Unit State | Displayed Level Range |
|---|---:|
| Base class | 1–20 |
| Promoted class | 1–20 |
| Special class | Class-dependent |
| Dragonkin/Taguel-style class | Class-dependent |
| DLC/special class | Class-dependent |

---

## Internal Level

Internal Level is used for scaling systems, including EXP and enemy generation.

Canonical formula for promoted units:

```text
Promoted Internal Level =
20 + Displayed Level
```

Examples:

| Class State | Displayed Level | Internal Level |
|---|---:|---:|
| Base | 10 | 10 |
| Base | 20 | 20 |
| Promoted | 1 | 21 |
| Promoted | 10 | 30 |
| Promoted | 20 | 40 |

---

## Level Up

A unit levels up when EXP reaches or exceeds 100.

```text
if EXP ≥ 100:
    DisplayedLevel += 1
    EXP -= 100
    ResolveLevelUp()
```

If multiple levels are possible through high EXP gain, repeat until:

```text
EXP < 100
```

or level cap is reached.

---

## EXP Storage

Recommended representation:

```yaml
level:
  displayed_level: integer
  internal_level: integer
  exp: 0-99
  class_tier: base | promoted | special
```

---

## Level Cap

A unit at class level cap cannot gain additional displayed levels in that class state.

```text
if DisplayedLevel == ClassLevelCap:
    EXPGain = 0
```

or:

```text
EXP = 99
```

depending on implementation convention.

For simulator clarity, use:

```text
CanGainEXP = DisplayedLevel < ClassLevelCap
```

---

## Level Reset Behavior

Promotion and reclassing may reset displayed level.

### Promotion Reset

When promoting from base to promoted class:

```text
NewDisplayedLevel = 1
NewInternalLevel = 21
```

The promoted internal level formula remains:

```text
20 + DisplayedLevel
```

### Second Seal Reclass Reset

Second Seal use may reset displayed level depending on source and target class category.

Recommended abstraction:

```text
ReclassedDisplayedLevel =
ClassRuleDefinedResetLevel
```

Internal level treatment depends on the unit's accumulated hidden level and target tier. For simulator systems, store:

```text
CumulativeInternalLevel
DisplayedLevel
ClassTierInternalAdjustment
```

rather than deriving all EXP behavior from visible level alone.

---

## Promoted Level Formula

Mandatory canonical formula:

```text
Promoted Internal Level =
20 + Displayed Level
```

This formula is used wherever promoted internal level is required.

---

# Promotion System

## Promotion Overview

Promotion changes a unit from a base class to a promoted class, normally using a Master Seal.

Promotion affects:

- class
- displayed level
- internal level
- stat bases
- stat caps
- weapon access
- class skills
- movement
- vulnerabilities
- WEXP maxima
- future reclass options

---

## Master Seal

A Master Seal promotes eligible base-class units.

### General Eligibility

```text
CanPromote =
UnitClassTier == Base
AND DisplayedLevel ≥ PromotionMinimumLevel
AND TargetPromotionClass is legal
AND Unit has usable Master Seal access
```

Typical minimum:

```text
PromotionMinimumLevel = 10
```

Class-specific and special-class exceptions must be defined in class data.

---

## Promotion Target Selection

A base class may have one or more promotion targets.

```yaml
promotion_targets:
  - promoted_class_a
  - promoted_class_b
```

If multiple targets exist, the player selects one.

---

## Promotion Bonuses

Promotion applies class transition stat bonuses.

```text
PostPromotionStat =
PrePromotionStat + PromotionBonus
```

Then cap enforcement is applied:

```text
PostPromotionStat =
min(PostPromotionStat, NewFinalStatCap)
```

Promotion bonuses may be modeled as:

```text
PromotionBonus =
TargetClassBase - SourceClassBase
```

or as an explicit transition table.

For implementation accuracy, use explicit transition tables when available.

---

## Promotion Recalculation

On promotion:

```text
OldClass = UnitClass
NewClass = SelectedPromotionClass

DisplayedLevel = 1
InternalLevel = 20 + DisplayedLevel

ApplyPromotionBonuses()
RecalculateClassCaps()
RecalculateMovement()
RecalculateWeaponAccess()
RecalculateSkills()
RecalculateDerivedCombatValues()
```

---

## Skill Progression on Promotion

Promotion changes the class skill progression track.

A promoted class has its own skill unlock levels.

Recommended model:

```yaml
class_skills:
  - level_required: integer
    skill: SkillName
```

When a unit enters a promoted class, future level-ups check the promoted class skill list.

Skill acquisition condition:

```text
if UnitDisplayedLevel == SkillLevelRequirement
AND UnitCurrentClass == SkillSourceClass
AND UnitDoesNotKnowSkill:
    LearnSkill
```

---

## Promotion and WEXP

Weapon experience carries over for weapon types retained by the promoted class.

```text
if WeaponType in NewClassAllowedWeapons:
    NewWEXP[WeaponType] = OldWEXP[WeaponType]
else:
    StoredWEXP[WeaponType] = OldWEXP[WeaponType]
```

A newly gained weapon type receives at least the class base WEXP:

```text
NewWEXP[WeaponType] =
max(ExistingStoredWEXP[WeaponType], NewClassBaseWEXP[WeaponType])
```

---

## Promotion and Stats at Cap

If a stat is capped before promotion:

```text
PostPromotionStat =
min(OldStat + PromotionBonus, NewCap)
```

Promotion may raise the final cap, allowing additional future growth.

---

# Reclassing

## Reclass Overview

Reclassing changes a unit's class using a Second Seal or special class-change item.

Reclassing affects:

- class
- displayed level
- internal level behavior
- stat bases/caps
- movement
- weapon access
- class skills available for future learning
- vulnerability group
- Pair Up bonuses
- weapon rank availability

Reclassing does not normally erase:

- learned skills
- permanent stat gains
- permanent stat boosters
- stored WEXP
- support ranks

---

## Second Seal

A Second Seal allows eligible units to change into another legal class.

### General Legality

```text
CanSecondSeal =
Unit has legal target class
AND Unit meets level requirement
AND Unit has usable Second Seal access
```

### Target Class Pool

A unit's reclass pool is derived from:

```text
PersonalClassSets
+ InheritedClassSets
+ SpecialClassAccess
+ DLCClassAccess
```

Avatar and child units require additional inheritance handling.

---

## Reclass Level Rules

Reclassing may map the unit to a new displayed level depending on source tier and target tier.

Recommended normalized model:

| Source State | Target State | Displayed Level Result | Notes |
|---|---|---:|---|
| Base | Base | 1 | Common Second Seal reset behavior |
| Base | Promoted | Not normally direct | Requires promotion path unless special rule |
| Promoted | Base | 1 | Re-enters base class track |
| Promoted | Promoted | 1 | Re-enters promoted class track |
| Special | Base | Class-dependent | Requires class-specific rule |
| Special | Promoted | Class-dependent | Requires class-specific rule |
| Special | Special | Class-dependent | Requires class-specific rule |

Because Awakening's Second Seal behavior is sensitive to class category and level threshold, simulator implementations should store explicit class-change rules rather than rely on a single universal reset formula.

---

## Internal Level and Reclassing

Awakening uses internal level/scaling behavior to reduce EXP gain after repeated reclassing.

Recommended implementation fields:

```yaml
level_state:
  displayed_level: integer
  visible_class_tier: base | promoted | special
  effective_internal_level: integer
  cumulative_reclass_level: integer
  reclass_count_or_modifier: integer
```

The following value should be treated as distinct from visible level:

```text
EffectiveInternalLevelForEXP
```

This prevents infinite low-level EXP gain abuse in simulation models.

---

## Reclass Stat Adjustment

When changing class, stats are recalculated against the target class bases/caps.

Recommended model:

```text
UnitPersonalStatComponent =
CurrentStat - OldClassBaseComponent - TemporaryModifiers
```

```text
NewStat =
UnitPersonalStatComponent + NewClassBaseComponent
```

Then:

```text
NewStat =
min(NewStat, NewFinalStatCap)
```

At minimum, a reclass operation must:

1. remove old class base adjustments
2. apply new class base adjustments
3. enforce new class caps
4. recalculate movement
5. recalculate weapon access
6. recalculate derived values

---

## Reclass Skill Access

A unit can learn skills from its current class when it reaches the relevant class level.

Previously learned skills are retained.

```text
KnownSkillsAfterReclass =
KnownSkillsBeforeReclass
```

Equippable skills remain limited by the active skill slot count.

---

## Child Interactions

Child reclass pools are derived from parents.

See [Child Mechanics](#child-mechanics).

Important rule:

```text
ChildClassPool =
ChildBaseClassPool
+ Parent1TransmittedClassPool
+ Parent2TransmittedClassPool
- IllegalGenderLockedOrRestrictedClasses
+ ReplacementClasses
```

Because this corpus normalizes gender-locked class definitions where mechanics are identical, the implementation must still preserve class inheritance legality separately from class mechanics.

---

## Reclass WEXP Retention

WEXP is retained even when the current class cannot use the weapon type.

```text
StoredWEXP[WeaponType] persists globally per unit
```

On entering a class:

```text
ActiveWEXP[WeaponType] =
max(StoredWEXP[WeaponType], ClassBaseWEXP[WeaponType])
```

If a class cannot use a weapon type:

```text
WeaponType not available for equipping
StoredWEXP unchanged
```

---

# WEXP System

## Overview

Weapon Experience (WEXP) is a numeric proficiency value for each weapon type.

The UI displays letter ranks, but the engine should represent numeric WEXP.

---

## Canonical Thresholds

| Rank | Minimum WEXP |
|---|---:|
| E | 1 |
| D | 31 |
| C | 71 |
| B | 121 |
| A | 181 |
| S | 251 |
| Cap | 400 |

---

## Rank Derivation

```text
if WEXP >= 251:
    Rank = S
elif WEXP >= 181:
    Rank = A
elif WEXP >= 121:
    Rank = B
elif WEXP >= 71:
    Rank = C
elif WEXP >= 31:
    Rank = D
elif WEXP >= 1:
    Rank = E
else:
    Rank = None
```

A unit cannot use a weapon unless:

```text
UnitWEXP[WeaponType] ≥ WeaponRequiredWEXP
AND WeaponType is allowed by CurrentClass
```

---

## Weapon Types

Core weapon types requiring WEXP:

| Weapon Type | Uses WEXP | Notes |
|---|---|---|
| Sword | Yes | Physical weapon family |
| Lance | Yes | Physical weapon family |
| Axe | Yes | Physical weapon family |
| Bow | Yes | Physical weapon family |
| Tome | Yes | Includes anima/light-style generic tomes as represented in Awakening |
| Dark Tome | Conditional | Class-restricted dark magic category |
| Staff | Yes | Utility/healing weapon family |
| Beaststone | Class/Special | Transformation weapon category |
| Dragonstone | Class/Special | Transformation weapon category |

For implementation, Beaststone and Dragonstone should still be represented as weapon categories even if their WEXP handling differs from standard rank progression.

---

## Base WEXP

Each class defines base WEXP for allowed weapon types.

```text
UnitWEXPOnClassEntry[WeaponType] =
max(StoredUnitWEXP[WeaponType], ClassBaseWEXP[WeaponType])
```

Class schema requirement:

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|

---

## Maximum WEXP

Each class defines maximum WEXP per allowed weapon type.

```text
EffectiveWEXPCap =
ClassWeaponMaxWEXP[WeaponType]
```

When gaining WEXP:

```text
NewWEXP =
min(CurrentWEXP + WEXPGain, EffectiveWEXPCap)
```

If the unit later enters a class with a higher cap, stored WEXP can continue increasing.

---

## WEXP Acquisition

WEXP is normally gained by using weapons or staves.

Generic structure:

```text
WEXPGain =
WeaponDefinedWEXPValue + SkillBonuses + DifficultyModifiers
```

Then:

```text
StoredWEXP[WeaponType] =
min(StoredWEXP[WeaponType] + WEXPGain, ClassMaxWEXP[WeaponType])
```

A miss may still grant WEXP depending on weapon/action category. For technical accuracy, each weapon/action should define:

```yaml
wexp_gain_on_hit: integer
wexp_gain_on_miss: integer
wexp_gain_on_kill: integer
wexp_gain_on_staff_use: integer
```

---

## Promotion Carryover

On promotion:

```text
StoredWEXP persists
```

For retained weapon types:

```text
ActiveWEXP =
StoredWEXP
```

For newly gained weapon types:

```text
ActiveWEXP =
max(StoredWEXP, ClassBaseWEXP)
```

For lost weapon types:

```text
StoredWEXP persists
ActiveAccess = False
```

---

## Reclass Retention

Reclassing does not delete WEXP.

```text
StoredWEXPBeforeReclass == StoredWEXPAfterReclass
```

Class access determines whether the unit can currently use that weapon type.

---

## Inheritance Behavior

Child units may inherit weapon ranks depending on recruitment state and game data. For simulator normalization:

```text
ChildInitialWEXP =
ClassBaseWEXPForRecruitmentClass
```

Optional advanced model:

```text
ChildInitialWEXP =
max(ClassBaseWEXP, InheritedOrScriptedWEXP)
```

If implementing strict vanilla behavior, child starting WEXP should be sourced from child unit data and recruitment class, not dynamically computed from parents unless such behavior is explicitly configured.

---

## Enemy Rank Assignment

Generic enemies receive WEXP based on:

- class allowed weapon types
- difficulty
- chapter/paralogue scaling
- inventory requirements
- weapon rank needed to equip assigned weapons

Recommended enemy assignment rule:

```text
EnemyWEXP[WeaponType] =
max(ClassBaseWEXP[WeaponType], RequiredWEXPForEquippedWeapon)
```

Then enforce:

```text
EnemyWEXP[WeaponType] ≤ ClassMaxWEXP[WeaponType]
```

If the weapon requires a rank above class maximum, the enemy must be treated as having a scripted exception or invalid loadout.

---

# Combat System

## Combat Sequence Overview

A combat exchange consists of:

1. combat initialization
2. stat snapshot
3. weapon validation
4. range validation
5. attack order determination
6. hit check
7. critical check
8. skill proc checks
9. damage calculation
10. HP modification
11. Dual Strike checks
12. Dual Guard checks
13. follow-up/brave continuation
14. death/defeat resolution
15. EXP/WEXP gain
16. post-combat skill/status effects

---

## Weapon Validation

A unit can attack if:

```text
CanAttack =
EquippedWeapon exists
AND WeaponDurability > 0
AND CurrentClass allows WeaponType
AND UnitWEXP[WeaponType] ≥ WeaponRequiredWEXP
AND Target is within WeaponRange
AND Unit is not prevented from attacking
```

---

## Range Validation

```text
Distance =
ManhattanDistance(AttackerTile, DefenderTile)
```

```text
WeaponRangeMin ≤ Distance ≤ WeaponRangeMax
```

Counterattack eligibility:

```text
CanCounter =
Defender has usable equipped weapon
AND Distance within DefenderWeaponRange
AND Defender not prevented from counterattacking
```

---

## Attack Formula

Physical:

```text
Attack =
STR + WeaponMight + AttackModifiers
```

Magical:

```text
Attack =
MAG + WeaponMight + AttackModifiers
```

Weapon-specific overrides must define:

```yaml
damage_stat: STR | MAG | Custom
defense_stat: DEF | RES | Custom
```

---

## Defense Selection

```text
TargetDefenseStat =
DEF if IncomingDamageType == Physical
RES if IncomingDamageType == Magical
Custom if weapon overrides defense stat
```

---

## Damage Formula

```text
Damage =
max(Attack - TargetDefenseStat, 0)
```

With effectiveness:

```text
EffectiveWeaponMight =
WeaponMight × EffectivenessMultiplier
```

```text
EffectiveAttack =
DamageStat + EffectiveWeaponMight + AttackModifiers
```

```text
Damage =
max(EffectiveAttack - TargetDefenseStat, 0)
```

With critical hit:

```text
CriticalDamage =
Damage × CriticalMultiplier
```

Canonical critical multiplier:

```text
CriticalMultiplier = 3
```

---

## Hit Formula

```text
DisplayedHit =
WeaponHit
+ floor((SKL × 3 + LCK) / 2)
+ HitModifiers
```

```text
DisplayedAvoid =
floor((SPD × 3 + LCK) / 2)
+ AvoidModifiers
```

```text
FinalHit =
DisplayedHit - DisplayedAvoid
```

Final hit is normally clamped for resolution:

```text
ResolvedHit =
clamp(FinalHit, 0, 100)
```

---

## Random Number Hit Resolution

Awakening uses a displayed hit model consistent with the modern two-random-number style family. Recommended simulator implementation:

```text
RN1 = RandomInteger(0, 99)
RN2 = RandomInteger(0, 99)
AverageRN = floor((RN1 + RN2) / 2)

HitSucceeds =
AverageRN < ResolvedHit
```

If modeling exact RNG engine behavior, separate the random stream implementation from the combat formula layer.

---

## Critical Formula

```text
DisplayedCrit =
WeaponCrit + floor(SKL / 2) + CritModifiers
```

```text
DisplayedDodge =
LCK + DodgeModifiers
```

```text
FinalCrit =
DisplayedCrit - DisplayedDodge
```

```text
ResolvedCrit =
clamp(FinalCrit, 0, 100)
```

Critical resolution:

```text
CriticalSucceeds =
RandomInteger(0, 99) < ResolvedCrit
```

Critical checks occur only if the attack hits, unless explicitly overridden by a special effect.

---

## Attack Speed and Follow-Up

```text
AttackSpeed =
SPD + AttackSpeedModifiers
```

Follow-up condition:

```text
CanFollowUp =
AttackerAttackSpeed - DefenderAttackSpeed ≥ 5
```

A defender may also follow up if their own speed advantage meets the same threshold during their attack opportunity.

---

## Brave Attacks

Brave weapons strike twice per attack opportunity.

If a unit has a brave effect:

```text
StrikesPerAttackOpportunity = 2
```

Without brave effect:

```text
StrikesPerAttackOpportunity = 1
```

A unit with both brave effect and follow-up may produce:

```text
TotalStrikes =
AttackOpportunities × 2
```

Where:

```text
AttackOpportunities =
1 + FollowUpOpportunity
```

Thus a brave weapon with a valid follow-up may strike up to four times before Dual Strike/support effects.

---

## Attack Order

Standard attack order:

| Step | Condition | Actor |
|---:|---|---|
| 1 | Initiator can attack | Initiator |
| 2 | Defender can counter | Defender |
| 3 | Initiator qualifies for follow-up | Initiator |
| 4 | Defender qualifies for follow-up | Defender |

Only one side normally receives a follow-up from speed advantage in a standard exchange.

Brave weapons duplicate strikes within each attack opportunity.

---

## Lethality and HP Resolution

```text
TargetCurrentHP =
TargetCurrentHP - Damage
```

```text
if TargetCurrentHP ≤ 0:
    TargetDefeated = True
```

Combat may terminate immediately when a unit is defeated unless a scripted or already-queued strike is explicitly resolved by the engine.

Recommended implementation:

```text
After each damaging strike:
    CheckDefeat()
    if DefenderDefeated:
        StopFurtherStrikesUnlessScripted()
```

---

## Skill Proc Integration

Proc skills should be modeled as event hooks.

Common hook points:

| Hook | Timing |
|---|---|
| BeforeCombat | Before attack sequence |
| BeforeHitCheck | Before hit RNG |
| OnHitCheck | During hit resolution |
| AfterHitBeforeDamage | Hit succeeded, before damage |
| BeforeDamage | Damage formula modification |
| AfterDamage | After HP loss |
| AfterCombat | Combat completed |
| OnDefeat | Unit defeated |
| OnKill | Target defeated by unit |

Proc skills must define:

```yaml
trigger:
  phase: CombatHook
  condition: expression
proc_rate:
  formula: expression
effect:
  formula_or_modifier: expression
stacking:
  rule: exclusive | additive | multiplicative | priority
```

---

## Weapon Triangle

Awakening uses a weapon triangle among swords, lances, and axes.

Canonical relation:

| Attacking Weapon | Advantage Against | Disadvantage Against |
|---|---|---|
| Sword | Axe | Lance |
| Lance | Sword | Axe |
| Axe | Lance | Sword |

Weapon triangle advantage modifies hit and attack based on weapon rank and system rules.

Recommended abstraction:

```text
WeaponTriangleModifier =
Lookup(AttackerWeaponType, DefenderWeaponType, AttackerWeaponRank)
```

Store as:

```yaml
weapon_triangle:
  attack_modifier: integer
  hit_modifier: integer
```

---

## Effective Damage

Effective damage modifies weapon might, not total attack.

```text
EffectiveWeaponMight =
WeaponMight × EffectivenessMultiplier
```

Then:

```text
Attack =
DamageStat + EffectiveWeaponMight + AttackModifiers
```

Canonical multiplier:

```text
EffectivenessMultiplier = 3
```

If difficulty, skill, or weapon-specific behavior changes this, the weapon/system entry must override it explicitly.

---

# Pair Up

## Pair Up Overview

Pair Up combines two allied units into one tile:

- lead unit participates directly in map movement and combat
- support unit provides stat bonuses
- support unit may perform Dual Strikes
- support unit may perform Dual Guards
- support level improves support mechanics

Terminology:

| Term | Meaning |
|---|---|
| Lead Unit | Active unit on map/combat front |
| Support Unit | Paired unit providing support |
| Pair Up Bonus | Stat modifier from support unit/class/support rank |
| Dual Strike | Support unit performs an additional attack |
| Dual Guard | Support unit blocks incoming damage |

---

## Pair Up Stat Bonuses

Pair Up bonuses are derived from:

```text
SupportUnitClassBonus
+ SupportUnitStatContribution
+ SupportRankBonus
+ SkillModifiers
```

Recommended normalized formula:

```text
PairUpBonus[Stat] =
ClassPairUpBonus[SupportClass][Stat]
+ SupportRankPairUpBonus[SupportRank][Stat]
+ SkillPairUpBonus[Stat]
```

Some implementations also model support unit stat thresholds as contributing to Pair Up bonuses. If used:

```text
PairUpBonus[Stat] =
ClassBasePairUpBonus
+ floor(SupportUnitRelevantStat / Threshold)
+ SupportRankBonus
+ SkillBonus
```

Because Pair Up bonus tables are class-specific, exact values belong in class documents and lookup tables.

---

## Pair Up Application

```text
LeadBattleStat =
LeadPermanentStat
+ PairUpBonus
+ OtherTemporaryModifiers
```

The support unit does not occupy a separate map tile while paired.

---

## Dual Strike

Dual Strike is a chance-based support attack by the paired/supporting unit.

Eligibility:

```text
CanDualStrike =
SupportUnit exists
AND SupportUnit has usable weapon
AND SupportUnit weapon can attack at combat range
AND SupportUnit is not prevented from attacking
AND DualStrikeChance succeeds
```

Dual Strike chance depends on:

- support rank
- relationship bonuses
- skills
- possibly lead/support stats
- system constants

Recommended normalized formula structure:

```text
DualStrikeRate =
BaseDualStrikeRate
+ SupportRankModifier
+ SkillModifier
+ StatModifier
```

Resolution:

```text
DualStrikeSucceeds =
RandomInteger(0, 99) < DualStrikeRate
```

Dual Strike attacks use the support unit's weapon and combat stats but occur inside the lead unit's combat sequence.

---

## Dual Guard

Dual Guard is a chance-based damage negation by the support unit.

Eligibility:

```text
CanDualGuard =
SupportUnit exists
AND IncomingAttack would hit
AND DualGuardChance succeeds
```

Effect:

```text
DamageTaken = 0
```

Recommended normalized formula structure:

```text
DualGuardRate =
BaseDualGuardRate
+ SupportRankModifier
+ SkillModifier
+ StatModifier
```

Resolution:

```text
DualGuardSucceeds =
RandomInteger(0, 99) < DualGuardRate
```

Dual Guard is checked after an incoming attack is determined to connect and before damage is applied.

---

## Support Scaling

Support rank affects Pair Up mechanics.

Canonical support rank order:

```text
None < C < B < A < S
```

For non-romantic/limited supports:

```text
None < C < B < A
```

Support rank may modify:

| Mechanic | Modified By Support Rank |
|---|---|
| Pair Up stat bonuses | Yes |
| Dual Strike rate | Yes |
| Dual Guard rate | Yes |
| Support bonuses while adjacent | Yes |
| Marriage eligibility | Yes, when S support exists |

---

## Adjacent Support vs Pair Up

Adjacent support and Pair Up are distinct states.

| State | Same Tile | Support Unit Gives Pair Up Stats | Dual Strike/Dual Guard Eligible |
|---|---|---|---|
| Adjacent | No | No | Yes, support mechanics may apply |
| Pair Up | Yes | Yes | Yes |
| Neither | No | No | No |

Engine implementations should not conflate adjacency support bonuses with Pair Up stat bonuses.

---

# Enemy Generation

## Enemy Unit Types

| Enemy Type | Description |
|---|---|
| Scripted Enemy | Explicit stats/inventory in chapter data |
| Generic Enemy | Generated or templated from class/chapter data |
| Boss | Scripted or semi-scripted with enhanced stats/skills |
| Risen | Random/skirmish enemy type using generation rules |
| Reinforcement | Spawned during map script execution |
| DLC Enemy | Defined by DLC map data |

---

## Enemy Generation Inputs

Generic enemy generation may depend on:

- chapter
- difficulty
- class
- displayed level
- internal level
- autolevel count
- base class stats
- class growths
- enemy growth package
- equipment
- weapon rank
- skills
- map script modifiers
- Lunatic/Lunatic+ rules

---

## Autoleveling

Autoleveling generates enemy stats by applying growths over a number of virtual levels.

Generic formula:

```text
EnemyStat =
EnemyBaseStat + AutolevelGain
```

Expected autolevel gain:

```text
ExpectedAutolevelGain =
AutolevelCount × EnemyFinalGrowth / 100
```

Randomized autolevel gain:

```text
For each virtual level:
    Roll stat growth
```

Deterministic average model:

```text
AutolevelGain =
floor(AutolevelCount × EnemyFinalGrowth / 100)
```

Random model:

```text
AutolevelGain =
sum(Bernoulli(EnemyFinalGrowth / 100), repeated AutolevelCount)
```

For growths above 100:

```text
AutolevelGainPerLevel =
floor(Growth / 100) + Bernoulli((Growth mod 100) / 100)
```

---

## Difficulty Scaling

Difficulty modifies enemy generation through:

| Difficulty | Typical Scaling Domains |
|---|---|
| Normal | Baseline enemy stats/skills/loadouts |
| Hard | Increased levels, stats, skills, density, equipment quality |
| Lunatic | Further increased stats, stronger skills, aggressive loadouts |
| Lunatic+ | Lunatic baseline plus randomized/enhanced enemy skills |

Recommended schema:

```yaml
difficulty_modifiers:
  normal:
    autolevel_bonus: integer
    stat_bonus: map
    skill_package: list
  hard:
    autolevel_bonus: integer
    stat_bonus: map
    skill_package: list
  lunatic:
    autolevel_bonus: integer
    stat_bonus: map
    skill_package: list
  lunatic_plus:
    autolevel_bonus: integer
    stat_bonus: map
    skill_package: randomized_or_scripted_list
```

---

## Lunatic Bonuses

Lunatic enemies may have:

- higher autolevel counts
- higher stats
- stronger weapons
- forged weapons
- additional skills
- altered AI aggression
- earlier promoted units
- stronger reinforcement pressure

Lunatic+ may add randomized high-impact enemy skills.

For implementation:

```text
LunaticEnemy =
BaseEnemy
+ LunaticStatAdjustments
+ LunaticSkillAdjustments
+ LunaticInventoryAdjustments
+ LunaticAIAdjustments
```

```text
LunaticPlusEnemy =
LunaticEnemy
+ LunaticPlusSkillPackage
```

---

## Generic Enemy Assumptions

Unless explicitly scripted:

```text
GenericEnemyStats =
ClassBaseStats
+ EnemyPersonalBase
+ AutolevelGains
+ DifficultyBonuses
```

```text
GenericEnemyGrowth =
EnemyArchetypeGrowth
+ ClassGrowth
```

```text
GenericEnemyWEXP =
max(ClassBaseWEXP, RequiredWEXPForEquippedWeapon)
```

```text
GenericEnemySkills =
ClassSkillsAvailableAtEnemyLevel
+ DifficultySkillPackage
+ ScriptedSkillOverrides
```

---

## Enemy Class Skill Assignment

For class skills:

```text
if EnemyDisplayedLevel ≥ SkillUnlockLevel
AND EnemyClass == SkillSourceClass:
    EnemyMayHaveSkill = True
```

Difficulty and chapter scripts may override this.

---

## Enemy Equipment Assignment

Enemy equipment must satisfy:

```text
WeaponType allowed by class
AND EnemyWEXP ≥ WeaponRequiredWEXP
AND Weapon not player-only restricted unless scripted
```

If the inventory violates normal legality, mark:

```yaml
scripted_exception: true
```

---

# Child Mechanics

## Child Overview

Child units are recruitable units whose properties are derived from:

- fixed child identity
- fixed mother or fixed parent relationship
- variable father or second parent
- inherited class sets
- inherited skills
- inherited growths
- inherited stat cap modifiers
- recruitment chapter scaling

---

## Growth Inheritance

Child growths are parent-derived.

Normalized formula:

```text
ChildUnitGrowth =
floor((Parent1Growth + Parent2Growth + ChildBaseGrowth) / 3)
```

Some data models represent child growths as a predefined base plus parent contribution. For implementation, store:

```yaml
child_growth_model:
  child_base_growth: map
  parent1_growth: map
  parent2_growth: map
  formula: expression
```

Mandatory final class-applied formula:

```text
FinalGrowth =
ChildUnitGrowth + ClassGrowth
```

---

## Class Inheritance

A child receives class access from:

```text
ChildDefaultClassSet
+ Parent1ClassSet
+ Parent2ClassSet
```

Then legality filters are applied:

```text
LegalChildClassSet =
InheritedClassSet
- RestrictedClasses
- IllegalGenderLockedClasses
+ ReplacementClasses
```

Because this corpus mechanically normalizes gender-locked classes, inheritance legality must be represented separately from class definitions.

---

## Gender-Locked Replacement Classes

If a transmitted class is illegal for the child due to gender or unit restriction, the game may substitute a replacement class.

Schema:

```yaml
class_inheritance:
  inherited_class: ClassName
  legal_for_child: true | false
  replacement_if_illegal: ClassName | N/A
```

---

## Skill Inheritance

Children inherit skills from parents when recruited.

Normalized model:

```text
InheritedSkillFromParent =
LastEquippedSkillInParentSkillList
```

For each transmitting parent:

```text
ChildInheritedSkills += ParentSelectedInheritedSkill
```

Restrictions may apply for:

- gender-locked skills
- character-locked skills
- DLC skills
- enemy-only skills
- special skills
- invalid class skills

Schema:

```yaml
skill_inheritance:
  parent: ParentName
  transmitted_skill: SkillName
  legal: true | false
  replacement: SkillName | N/A
```

---

## Stat Inheritance

Child stat caps use parental modifiers.

Canonical model:

```text
ChildCapModifier =
Parent1CapModifier
+ Parent2CapModifier
+ ChildAdjustment
```

Where `ChildAdjustment` is normally a fixed child-specific modifier, commonly represented as `+1` to each relevant inherited modifier model depending on the stat modifier system used.

Recommended implementation:

```yaml
cap_modifiers:
  hp: integer
  str: integer
  mag: integer
  skl: integer
  spd: integer
  lck: integer
  def: integer
  res: integer
source:
  parent1_modifier: integer
  parent2_modifier: integer
  child_adjustment: integer
```

---

## Recruitment Scaling

Child paralogue enemies and child unit recruitment may scale with story progress or parent levels depending on scenario data.

Recommended fields:

```yaml
recruitment_scaling:
  chapter_available_after: string
  child_level: integer
  child_class: ClassName
  inherited_skills_locked_at_spawn: true
  parent_state_sampled_at_recruitment: true
```

---

## Avatar Parent Interactions

If Avatar is a parent, child inheritance may include:

- Avatar asset/flaw modifiers
- Avatar class access
- Avatar growth modifiers
- Avatar cap modifiers
- expanded class inheritance options

Recommended model:

```text
AvatarDerivedChildClassSet =
ChildDefaultClassSet
+ OtherParentClassSet
+ AvatarClassSet
- IllegalClasses
+ ReplacementClasses
```

---

## Dragonkin/Taguel Inheritance

Transformation classes require explicit inheritance legality.

For each child:

```yaml
transformation_class_access:
  taguel: true | false
  manakete: true | false
  source_parent: ParentName | N/A
  weapon_category: Beaststone | Dragonstone | N/A
```

---

# Vulnerability & Effectiveness

## Vulnerability Groups

A unit may belong to zero or more vulnerability groups.

Core vulnerability groups:

| Group | Description |
|---|---|
| Armor | Armored units vulnerable to armor-effective weapons |
| Cavalry | Mounted ground units vulnerable to cavalry-effective weapons |
| Flying | Flying units vulnerable to bow/wind/flying-effective weapons |
| Dragon | Dragon units vulnerable to dragon-effective weapons |
| Beast | Beast/Taguel units vulnerable to beast-effective weapons |

---

## Multi-Group Vulnerability

Units may belong to multiple groups.

Example schema:

```yaml
vulnerability_groups:
  - Flying
  - Dragon
```

If an attacking weapon is effective against more than one of the defender's groups, effectiveness is normally applied once, not multiplicatively stacked, unless explicitly specified.

```text
IsEffective =
intersection(WeaponEffectiveGroups, DefenderVulnerabilityGroups) is not empty
```

```text
EffectivenessMultiplier =
3 if IsEffective else 1
```

---

## Armor

Armor vulnerability applies to armored classes.

```yaml
vulnerability_group: Armor
```

Common effective sources:

- armor-effective swords
- armor-effective lances
- armor-effective axes
- special weapons with armor effectiveness

---

## Cavalry

Cavalry vulnerability applies to mounted ground classes.

```yaml
vulnerability_group: Cavalry
```

Common effective sources:

- beast/cavalry-effective weapons
- anti-cavalry lances
- special weapons with cavalry effectiveness

---

## Flying

Flying vulnerability applies to airborne classes.

```yaml
vulnerability_group: Flying
```

Common effective sources:

- bows
- wind magic where applicable
- flying-effective weapons

---

## Dragon

Dragon vulnerability applies to dragon-type units.

```yaml
vulnerability_group: Dragon
```

Common effective sources:

- wyrmslayers
- dragon-effective weapons
- Falchion-type weapons
- specific legendary weapons

---

## Beast

Beast vulnerability applies to beast-type units, especially Taguel-style transformation classes.

```yaml
vulnerability_group: Beast
```

Common effective sources:

- beast-effective weapons
- anti-beast special weapons

---

## Effectiveness Formula

```text
WeaponIsEffective =
any(group in DefenderVulnerabilityGroups for group in WeaponEffectiveGroups)
```

```text
EffectiveWeaponMight =
WeaponMight × EffectivenessMultiplier
```

```text
EffectivenessMultiplier =
3 if WeaponIsEffective else 1
```

```text
Damage =
max((AttackingDamageStat + EffectiveWeaponMight + AttackModifiers) - DefendingDefenseStat, 0)
```

---

## Effectiveness and Critical Hits

Recommended order:

1. apply effectiveness to weapon might
2. calculate damage
3. apply critical multiplier if critical hit occurs

```text
CriticalEffectiveDamage =
DamageAfterEffectiveness × 3
```

---

## Effectiveness and Skills

Skills may modify:

- weapon might
- attack
- damage
- received damage
- effective multiplier
- vulnerability group
- effective immunity

Recommended hook order:

```text
DetermineVulnerabilityGroups
DetermineWeaponEffectiveGroups
ApplyEffectiveness
ApplyAttackModifiers
ApplyDefenseModifiers
ResolveHit
ResolveCrit
ApplyDamageModifiers
ApplyDamage
```

---

# Implementation Notes

## Recommended Core Unit Object

```yaml
unit:
  id: string
  name: string
  class: ClassName
  displayed_level: integer
  internal_level: integer
  exp: integer
  stats:
    hp: integer
    str: integer
    mag: integer
    skl: integer
    spd: integer
    lck: integer
    def: integer
    res: integer
    mov: integer
  current_hp: integer
  growths:
    hp: integer
    str: integer
    mag: integer
    skl: integer
    spd: integer
    lck: integer
    def: integer
    res: integer
  cap_modifiers:
    hp: integer
    str: integer
    mag: integer
    skl: integer
    spd: integer
    lck: integer
    def: integer
    res: integer
  wexp:
    sword: integer
    lance: integer
    axe: integer
    bow: integer
    tome: integer
    dark: integer
    staff: integer
    beaststone: integer
    dragonstone: integer
  skills_known:
    - SkillName
  skills_equipped:
    - SkillName
  support_ranks:
    UnitID: Rank
  vulnerability_groups:
    - GroupName
```

---

## Recommended Combat Context Object

```yaml
combat_context:
  attacker: UnitID
  defender: UnitID
  range: integer
  phase: player | enemy | other
  attacker_weapon: WeaponID
  defender_weapon: WeaponID
  terrain:
    attacker_tile: TerrainID
    defender_tile: TerrainID
  pair_up:
    attacker_support: UnitID | N/A
    defender_support: UnitID | N/A
  flags:
    attacker_initiated: true
    defender_can_counter: true | false
    attacker_can_follow_up: true | false
    defender_can_follow_up: true | false
```

---

## Deterministic Resolution Recommendation

For simulator reproducibility, all random systems should consume an explicit RNG stream.

```yaml
rng:
  seed: integer
  stream_position: integer
  method: two_rn_hit | single_rn | configured
```

Separate RNG calls by subsystem:

| Subsystem | RNG Type |
|---|---|
| Hit | Two-RN recommended |
| Critical | Single-RN |
| Skill Proc | Single-RN |
| Growth | Single-RN per stat |
| Dual Strike | Single-RN |
| Dual Guard | Single-RN |
| Enemy Skill Randomization | Single-RN or scripted list |

---

## Phase 1 Boundary

This file defines systems only.

The following are intentionally deferred:

| Deferred Content | Target File |
|---|---|
| Complete stat lookup tables | `awakening_lookup_tables.md` |
| Complete class data | `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_classes_special.md` |
| Complete skill data | `awakening_skills.md` |
| Complete weapon data | `awakening_weapons_physical.md`, `awakening_weapons_magic.md` |
| Complete item data | `awakening_items.md` |
| Archetype growth packages | `awakening_archetypes.md` |
| Graphs and matrices | `awakening_appendices.md` |

---

# End of Phase 1 — Core Systems
