
# Fire Emblem Awakening Technical Reference Corpus
# Appendices

**File:** `awakening_appendices.md`  
**Phase:** 11  
**Corpus Version:** `0.12.0-phase11`  
**Depends On:** `awakening_project_index.md`, `awakening_core_systems.md`, `awakening_lookup_tables.md`, `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_classes_special.md`, `awakening_skills.md`, `awakening_weapons_physical.md`, `awakening_weapons_magic.md`, `awakening_items.md`, `awakening_archetypes.md`  
**Scope:** Supplemental graphs, matrices, legality tables, conversion tables, examples, and compatibility notes.

---

# Table of Contents

1. [Promotion Graph](#promotion-graph)
2. [Reclass Graph](#reclass-graph)
3. [Vulnerability Matrix](#vulnerability-matrix)
4. [Effective Damage Matrix](#effective-damage-matrix)
5. [Skill Inheritance Legality](#skill-inheritance-legality)
6. [Internal Level Conversion](#internal-level-conversion)
7. [Enemy Stat Generation Examples](#enemy-stat-generation-examples)
8. [DLC Compatibility Notes](#dlc-compatibility-notes)
9. [Appendix Implementation Constants](#appendix-implementation-constants)

---

# Promotion Graph

## Promotion Edge Table

| Base Class | Promotion Target A | Promotion Target B | Requirement | Notes |
| --- | --- | --- | --- | --- |
| Lord (Male) | Great Lord (Male) | N/A | Master Seal; displayed level ≥ 10 | Personal line; Chrom |
| Lord (Female) | Great Lord (Female) | N/A | Master Seal; displayed level ≥ 10 | Personal line; Lucina |
| Tactician | Grandmaster | N/A | Master Seal; displayed level ≥ 10 | Avatar-line promotion |
| Cavalier | Paladin | Great Knight | Master Seal; displayed level ≥ 10 | Regular branched promotion |
| Knight | General | Great Knight | Master Seal; displayed level ≥ 10 | Regular branched promotion |
| Myrmidon | Swordmaster | Assassin | Master Seal; displayed level ≥ 10 | Regular branched promotion |
| Thief | Assassin | Trickster | Master Seal; displayed level ≥ 10 | Regular branched promotion |
| Mercenary | Hero | Bow Knight | Master Seal; displayed level ≥ 10 | Regular branched promotion |
| Fighter | Hero | Warrior | Master Seal; displayed level ≥ 10 | Vanilla access is male-gated; mechanics universal |
| Barbarian | Berserker | Warrior | Master Seal; displayed level ≥ 10 | Vanilla access is male-gated; mechanics universal |
| Archer | Sniper | Bow Knight | Master Seal; displayed level ≥ 10 | Regular branched promotion |
| Pegasus Knight | Falcon Knight | Dark Flier | Master Seal; displayed level ≥ 10 | Vanilla access is female-gated; mechanics universal |
| Wyvern Rider | Wyvern Lord | Griffon Rider | Master Seal; displayed level ≥ 10 | Regular branched promotion |
| Troubadour | Valkyrie | War Monk / War Cleric | Master Seal; displayed level ≥ 10 | Vanilla access is female-gated; mechanics universal |
| Priest / Cleric | Sage | War Monk / War Cleric | Master Seal; displayed level ≥ 10 | War Monk/War Cleric name varies by gender presentation |
| Mage | Sage | Dark Knight | Master Seal; displayed level ≥ 10 | Regular branched promotion |
| Dark Mage | Sorcerer | Dark Knight | Master Seal; displayed level ≥ 10 | Dark Knight does not natively preserve dark tome access |

## Promotion Edge List

```text
Lord (Male) -> Great Lord (Male)
Lord (Female) -> Great Lord (Female)
Tactician -> Grandmaster
Cavalier -> Paladin
Cavalier -> Great Knight
Knight -> General
Knight -> Great Knight
Myrmidon -> Swordmaster
Myrmidon -> Assassin
Thief -> Assassin
Thief -> Trickster
Mercenary -> Hero
Mercenary -> Bow Knight
Fighter -> Hero
Fighter -> Warrior
Barbarian -> Berserker
Barbarian -> Warrior
Archer -> Sniper
Archer -> Bow Knight
Pegasus Knight -> Falcon Knight
Pegasus Knight -> Dark Flier
Wyvern Rider -> Wyvern Lord
Wyvern Rider -> Griffon Rider
Troubadour -> Valkyrie
Troubadour -> War Monk / War Cleric
Priest / Cleric -> Sage
Priest / Cleric -> War Monk / War Cleric
Mage -> Sage
Mage -> Dark Knight
Dark Mage -> Sorcerer
Dark Mage -> Dark Knight
```

## Promotion Adjacency Object

```yaml
promotion_graph:
  Lord (Male): [Great Lord (Male)]
  Lord (Female): [Great Lord (Female)]
  Tactician: [Grandmaster]
  Cavalier: [Paladin, Great Knight]
  Knight: [General, Great Knight]
  Myrmidon: [Swordmaster, Assassin]
  Thief: [Assassin, Trickster]
  Mercenary: [Hero, Bow Knight]
  Fighter: [Hero, Warrior]
  Barbarian: [Berserker, Warrior]
  Archer: [Sniper, Bow Knight]
  Pegasus Knight: [Falcon Knight, Dark Flier]
  Wyvern Rider: [Wyvern Lord, Griffon Rider]
  Troubadour: [Valkyrie, War Monk / War Cleric]
  Priest / Cleric: [Sage, War Monk / War Cleric]
  Mage: [Sage, Dark Knight]
  Dark Mage: [Sorcerer, Dark Knight]
```

## Non-Promoting Special Classes

| Class | Category | Class-Change Handling |
| --- | --- | --- |
| Villager | Special single-tier | Second Seal only; no Master Seal promotion |
| Dancer | Special single-tier | Second Seal only; no Master Seal promotion |
| Taguel (Male) | Transformation single-tier | Second Seal only; no Master Seal promotion |
| Taguel (Female) | Transformation single-tier | Second Seal only; no Master Seal promotion |
| Manakete | Transformation single-tier | Second Seal only; no Master Seal promotion |
| Lodestar | Special/DLC-associated single-tier | Second Seal only; no Master Seal promotion |
| Dread Fighter | DLC single-tier | Dread Scroll target; Second Seal rules afterward |
| Bride | DLC single-tier | Wedding Bouquet target; Second Seal rules afterward |
| Conqueror | Special character-associated single-tier | Second Seal only where unit access allows |

## Promotion Resolver

```text
CanPromote =
CurrentClass in promotion_graph
AND CurrentClassTier == Base
AND DisplayedLevel >= 10
AND MasterSealAvailable == True
AND SelectedTarget in promotion_graph[CurrentClass]
```

```text
OnPromotion:
    OldClass = CurrentClass
    NewClass = SelectedPromotionTarget
    DisplayedLevel = 1
    InternalLevel = 20 + DisplayedLevel
    ApplyPromotionStatDelta(OldClass, NewClass)
    RetainKnownSkills()
    RetainStoredWEXP()
    RecalculateAllowedWeapons()
    RecalculateCaps()
    RecalculateDerivedStats()
```

---

# Reclass Graph

## Reclass Model

Awakening reclassing is not a single universal class-to-class graph. It is generated per unit from that unit's legal class set.

```text
UnitReclassGraph =
GenerateFrom(UnitClassSet, UnitGender, UnitSpecialAccess, DLCFlags, StoryFlags)
```

A class-set node contains:

```text
BaseClass
PromotionTargetA
PromotionTargetB
```

The graph is generated from the unit's available class-family nodes.

## Class-Family Closure Table

| Class-Set Node | Base / Special Class | Promoted Closure | Notes |
| --- | --- | --- | --- |
| Lord (Male) | Lord (Male) | Great Lord (Male) | Personal; not normal inherited class-set node |
| Lord (Female) | Lord (Female) | Great Lord (Female) | Personal; not normal inherited class-set node |
| Tactician | Tactician | Grandmaster | Avatar-line; not normal non-Avatar class-set node |
| Cavalier | Cavalier | Paladin; Great Knight | Regular class-set node |
| Knight | Knight | General; Great Knight | Regular class-set node |
| Myrmidon | Myrmidon | Swordmaster; Assassin | Regular class-set node |
| Thief | Thief | Assassin; Trickster | Regular class-set node |
| Mercenary | Mercenary | Hero; Bow Knight | Regular class-set node |
| Fighter | Fighter | Hero; Warrior | Male-access in vanilla; replacement rules for illegal inheritance |
| Barbarian | Barbarian | Berserker; Warrior | Male-access in vanilla; replacement rules for illegal inheritance |
| Archer | Archer | Sniper; Bow Knight | Regular class-set node |
| Pegasus | Pegasus Knight | Falcon Knight; Dark Flier | Female-access in vanilla; replacement rules for illegal inheritance |
| Wyvern | Wyvern Rider | Wyvern Lord; Griffon Rider | Regular class-set node |
| Troubadour | Troubadour | Valkyrie; War Monk / War Cleric | Female-access in vanilla; replacement rules for illegal inheritance |
| Priest / Cleric | Priest / Cleric | Sage; War Monk / War Cleric | Regular class-set node; gender name alias |
| Mage | Mage | Sage; Dark Knight | Regular class-set node |
| Dark Mage | Dark Mage | Sorcerer; Dark Knight | Regular class-set node |
| Villager | Villager | N/A | Special inheritance node; Donnel-linked |
| Dancer | Dancer | N/A | Personal special node; normally not inherited |
| Taguel | Taguel (Male/Female) | N/A | Transformation inheritance node where legal |
| Manakete | Manakete | N/A | Transformation inheritance node where legal |
| Lodestar | Lodestar | N/A | Special/DLC-associated node |
| Dread Fighter | Dread Fighter | N/A | DLC item target |
| Bride | Bride | N/A | DLC item target |
| Conqueror | Conqueror | N/A | Character-associated special node |

## Reclass Eligibility Table

| Current State | Displayed Level Requirement | Second Seal Targets | Notes |
| --- | --- | --- | --- |
| Base class | ≥ 10 | Legal base classes in unit class set | Displayed level resets to 1 |
| Promoted class | Any displayed level | Legal base classes in unit class set | Displayed level resets to target class rule |
| Promoted class | ≥ 10 | Legal base classes and corresponding promoted classes in unit class set | Expanded promoted-target reclass set |
| Special class | ≥ 10 | Legal base classes in unit class set | Special-class Second Seal behavior |
| Special class | 30 | Legal base classes and corresponding promoted classes in unit class set | Max-level special-class expanded behavior |
| Max-level current class | At class cap | May reclass into current class again | Allows level reset in same class |
| Dread Scroll | Item-specific | Dread Fighter | Functions like Second Seal but fixed target |
| Wedding Bouquet | Item-specific | Bride | Functions like Second Seal but fixed target |

## Reclass Edge Generation Algorithm

```text
GenerateReclassTargets(unit):
    family_nodes = ResolveClassSet(unit)
    legal_base_targets = []
    legal_promoted_targets = []

    for node in family_nodes:
        if IsClassLegalForUnit(node.base, unit):
            legal_base_targets.append(node.base)

        if CanAccessPromotedReclassTargets(unit):
            for promoted in node.promoted_closure:
                if IsClassLegalForUnit(promoted, unit):
                    legal_promoted_targets.append(promoted)

    if UnitAtClassCap(unit):
        legal_base_targets.append(unit.current_class)
        legal_promoted_targets.append(unit.current_class)

    return Unique(legal_base_targets + legal_promoted_targets)
```

## Unit Class-Set Resolver

```text
ResolveClassSet(unit):
    if unit == Avatar:
        return AllRegularClassFamiliesAllowedByGender
               - SpecialClassFamilies
               - PersonalClassFamilies
               + DLCClassFamiliesIfItemOrFlagPresent

    if unit is Child:
        return ChildBaseClassSet
               + MotherClassSet
               + FatherClassSet
               - IllegalRestrictedClasses
               + GenderReplacementClasses
               + SpecialInheritedClassesIfAllowed

    return PersonalClassSet
```

## Reclass State Preservation

| State Component | Preserved On Reclass | Rule |
| --- | --- | --- |
| Known skills | Yes | KnownSkillsAfter = KnownSkillsBefore |
| Equipped skills | Conditional | Retain if still legal/available in slot; otherwise unequip only if rules engine requires |
| Stored WEXP | Yes | Stored WEXP persists for all weapon types |
| Active weapon access | Recomputed | Allowed by target class weapon set |
| Permanent stat gains | Yes | Rebased through class-base delta and cap enforcement |
| Temporary buffs | Usually Yes until normal expiration | Buffs are not class identity; recalculate affected stats after class switch |
| Support ranks | Yes | Support data is unit relationship state |
| Pair Up state | No during class-change UI | Class change occurs outside active combat movement state |
| Inventory | Yes | Illegal equipped weapon must be unequipped or retained in inventory |

## Gender-Locked Replacement Handling

```text
if InheritedClass is illegal for ChildGender:
    InheritedClass = ReplacementClassMap[InheritedClass, ChildGender]
```

Recommended replacement table fields:

```yaml
replacement_rule:
  source_class: ClassName
  blocked_gender: male | female
  replacement_class: ClassName
  source_parent: ParentID
  applies_to_child: ChildID
```

---

# Vulnerability Matrix

## Class Family to Vulnerability Group Matrix

| Class Family / Group | Vulnerability Groups | Notes |
| --- | --- | --- |
| Lord / Tactician / Infantry sword/magic/support classes | None | No default effectiveness group |
| Cavalier / Paladin / Troubadour / Valkyrie / Bow Knight / Dark Knight | Cavalry | Also treated as beast/mounted by Beast Killer-style effects where source data uses that grouping |
| Knight / General | Armor | Armor-effective weapons apply |
| Great Knight / Conqueror | Armor; Cavalry | Both armor and mounted/cavalry effectiveness can apply; default effectiveness applies once unless source stacks |
| Pegasus Knight / Falcon Knight / Dark Flier / Griffon Rider | Flying | Bow/wind/flying-effective sources apply |
| Wyvern Rider / Wyvern Lord | Flying; Dragon | Flying-effective and dragon-effective sources can apply |
| Taguel | Beast | Beast-effective effects apply |
| Manakete | Dragon | Dragon-effective effects apply |
| Revenant / Entombed | Monster | Monster-effective sources such as Blessed weapons apply |
| Grima | Fell Dragon; Dragon | Dragon/Fell Dragon weapon exceptions must be handled by weapon/boss script data |

## Binary Vulnerability Matrix

| Defender Type | Armor | Cavalry | Flying | Dragon | Beast | Monster | Fell Dragon |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Unarmored infantry | No | No | No | No | No | No | No |
| Armor infantry | Yes | No | No | No | No | No | No |
| Cavalry | No | Yes | No | No | Conditional | No | No |
| Armored cavalry | Yes | Yes | No | No | Conditional | No | No |
| Pegasus/falcon/dark flier | No | Conditional | Yes | No | Conditional | No | No |
| Wyvern | No | No | Yes | Yes | No | No | No |
| Taguel | No | No | No | No | Yes | No | No |
| Manakete | No | No | No | Yes | No | No | No |
| Monster | No | No | No | No | No | Yes | No |
| Grima/Fell Dragon | No | No | No | Yes | No | No | Yes |

## Vulnerability Resolver

```text
ResolveVulnerabilityGroups(unit):
    groups = ClassVulnerabilityGroups[unit.current_class]

    groups += ScriptedUnitVulnerabilityGroups[unit.id]
    groups -= EffectivenessImmunityGroups(unit)

    return Unique(groups)
```

## Multi-Group Rule

```text
IsEffective =
Intersection(WeaponEffectiveGroups, DefenderVulnerabilityGroups) != Empty
```

```text
EffectivenessMultiplier =
3 if IsEffective else 1
```

By default, multiple matching vulnerability groups do **not** multiply effectiveness more than once.

```text
MultipleMatchesDoNotStack = True
```

---

# Effective Damage Matrix

## Source vs Vulnerability Matrix

| Effective Source | Armor | Cavalry | Flying | Dragon | Beast | Monster | Fell Dragon | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Standard sword/lance/axe | No | No | No | No | No | No | No | No default effectiveness |
| Standard bow | No | No | Yes | No | No | No | No | Bows are flying-effective |
| Wind tome family | No | No | Yes | No | No | No | No | Wind/Elwind/Arcwind/Rexcalibur/Excalibur/Forseti are flying-effective |
| Armorslayer / Hammer | Yes | No | No | No | No | No | No | Armor-effective weapon group |
| Rapier / Noble Rapier | Yes | Yes | No | No | Yes | No | No | Lord/Lodestar-restricted sword line; treats mounted/beast categories as effective |
| Beast Killer | No | Yes | No | No | Yes | No | No | Effective against beast/cavalry grouping |
| Wyrmslayer / Falchion / dragon-effective weapons | No | No | No | Yes | No | No | Conditional | Fell Dragon applicability is weapon-specific |
| Book of Naga | No | No | No | Yes | No | No | Conditional | Dragon-effective tome; Fell Dragon handling requires script/weapon tag |
| Blessed Lance / Blessed Bow | No | No | Bow remains Flying | No | No | Yes | No | Monster-effective; Blessed Bow also flying-effective |
| Volant Axe | No | No | Yes | No | No | No | No | Flying-effective axe |
| Beastbane | No | Yes | No | No | Yes | No | No | Taguel class skill; class/form-gated |
| Wyrmsbane | No | No | No | Yes | No | No | Conditional | Manakete class skill; class/form-gated |

## Effective Damage Formula

```text
EffectiveWeaponMight =
WeaponMight × EffectivenessMultiplier
```

```text
AttackAfterEffectiveness =
DamageStat + EffectiveWeaponMight + AttackModifiers
```

```text
Damage =
max(AttackAfterEffectiveness - DefenseStat, 0)
```

## Critical and Effective Damage Ordering

```text
Step 1: Determine hit
Step 2: Determine effective weapon might
Step 3: Calculate damage after defense
Step 4: Determine critical
Step 5: If critical, multiply final damage by 3
```

```text
CriticalEffectiveDamage =
DamageAfterEffectivenessAndDefense × 3
```

## Immunity Handling

| Immunity Source | Negated Groups | Implementation Rule |
| --- | --- | --- |
| Iote's Shield | Flying | Remove Flying from defender vulnerability groups for effectiveness check |
| Conquest | Armor; Beast/Mounted as defined | Remove Armor and beast/mounted weakness groups for effectiveness check |
| Dragonskin | Counter and Lethality; also halves damage | Not a vulnerability removal by default; implement as damage/skill immunity layer |
| Weapon/script immunity | Source-defined | Apply before effectiveness intersection if it negates group; after damage if it is damage reduction |

---

# Skill Inheritance Legality

## Skill Inheritance Timing

Recommended simulator snapshot:

```text
ChildInheritedSkillFromParent =
LastEquippedSkillInParentSkillList at ChildSpawnInitialization
```

Strict vanilla-compatible implementations should expose this as a configuration flag:

```yaml
skill_inheritance_snapshot:
  timing: paralogue_initialization | child_recruitment | map_load
```

Default corpus recommendation:

```text
timing = child_recruitment_initialization
```

## Parent Skill Slot Rule

```text
For each transmitting parent:
    TransmittedSkill = ParentEquippedSkills[last_slot]
```

If the last slot is empty or invalid:

```text
SearchBackwardForLastValidEquippedSkill
```

or:

```text
NoSkillInherited
```

depending on strict implementation mode.

## Skill Inheritance Legality Matrix

| Skill Category | Can Be Inherited | Condition | Notes |
| --- | --- | --- | --- |
| Standard class skill | Yes | Parent must know the skill and place it in the transmitted skill slot | Applies to base/promoted/special class skills unless another row overrides |
| Gender-locked class skill | Yes | Parent must know/equip it; child may receive even if child cannot naturally access source class | Example: Galeforce-style inheritance into a male child if passed by mother; Counter-style inheritance into a female child if passed by father |
| DLC class skill | Conditional | DLC data must be installed/resolved and parent must know/equip the skill | Dread Fighter/Bride skills use DLC compatibility flags |
| DLC skill-item skill | Conditional | DLC data must be installed/resolved and parent must know/equip the learned skill | All Stats +2, Paragon, Iote's Shield, Limit Breaker |
| Personal-only skill | Conditional | Only when vanilla/scripted inheritance explicitly permits it | Shadowgift/Conquest are treated as scripted/personal exceptions, especially Morgan cases |
| Enemy-exclusive skill | No | Never legal through normal child inheritance | Dragonskin, Hawkeye, Luna+, Aegis+, Pavise+, etc. |
| Placeholder skill | No until resolved | Resolve to actual DLC skill first; otherwise no inherited effect | Outrealm Skill is a proxy state |
| Weapon-granted skill effect | No | Skill is not learned; it exists only while weapon is equipped | Sol sword, Luna lance, Astra bow, breaker weapons |
| Item-granted learned skill | Conditional | Legal only after item teaches a real skill and DLC is resolved | Then follows DLC skill-item skill row |
| Chrom-specific inheritance | Hardcoded conditional | Daughters receive Aether; sons receive Rightful King under vanilla rules | Use explicit parent/child override rather than generic last-slot rule |
| Avatar-specific inheritance | Yes, broad | Avatar can pass learned/equipped skills subject to explicit forbidden categories | Morgan and Avatar children may also inherit expanded class/growth/cap context |

## Chrom Override Table

| Parent | Child Gender | Inherited Skill Override | Notes |
| --- | --- | --- | --- |
| Chrom | Daughter | Aether | Applies to Lucina and applicable daughters under vanilla rules |
| Chrom | Son | Rightful King | Applies to sons under vanilla rules |
| Chrom | Lucina | Aether | Lucina receives lord-line inheritance context |

## Skill Inheritance Resolver

```text
ResolveInheritedSkills(child):
    inherited = []

    for parent in child.parents:
        if HasHardcodedInheritanceOverride(parent, child):
            inherited.append(GetHardcodedInheritedSkill(parent, child))
            continue

        candidate = GetLastEquippedSkill(parent)

        if IsSkillInheritanceLegal(candidate, parent, child):
            inherited.append(candidate)

    return UniqueOrOrdered(inherited)
```

## Illegal Skill Filter

```text
IsSkillInheritanceLegal(skill):
    if skill.category == EnemyExclusive:
        return False
    if skill.category == Placeholder and not ResolvedToRealSkill:
        return False
    if skill.effect_source == WeaponGrantedOnly:
        return False
    if skill.requires_dlc and DLCInstalled == False:
        return False
    if skill.personal_only and not ScriptedPersonalInheritanceAllowed:
        return False
    return True
```

---

# Internal Level Conversion

## Core Formulas

```text
BaseInternalLevel =
DisplayedLevel
```

```text
PromotedInternalLevel =
20 + DisplayedLevel
```

```text
SpecialInternalLevel =
SpecialClassRule(DisplayedLevel, ClassID)
```

## Conversion Table

| Class State | Displayed Level | Internal Level | Formula |
| --- | ---: | ---: | --- |
| Base | 1 | 1 | DisplayedLevel |
| Base | 2 | 2 | DisplayedLevel |
| Base | 3 | 3 | DisplayedLevel |
| Base | 4 | 4 | DisplayedLevel |
| Base | 5 | 5 | DisplayedLevel |
| Base | 6 | 6 | DisplayedLevel |
| Base | 7 | 7 | DisplayedLevel |
| Base | 8 | 8 | DisplayedLevel |
| Base | 9 | 9 | DisplayedLevel |
| Base | 10 | 10 | DisplayedLevel |
| Base | 11 | 11 | DisplayedLevel |
| Base | 12 | 12 | DisplayedLevel |
| Base | 13 | 13 | DisplayedLevel |
| Base | 14 | 14 | DisplayedLevel |
| Base | 15 | 15 | DisplayedLevel |
| Base | 16 | 16 | DisplayedLevel |
| Base | 17 | 17 | DisplayedLevel |
| Base | 18 | 18 | DisplayedLevel |
| Base | 19 | 19 | DisplayedLevel |
| Base | 20 | 20 | DisplayedLevel |
| Promoted | 1 | 21 | 20 + DisplayedLevel |
| Promoted | 2 | 22 | 20 + DisplayedLevel |
| Promoted | 3 | 23 | 20 + DisplayedLevel |
| Promoted | 4 | 24 | 20 + DisplayedLevel |
| Promoted | 5 | 25 | 20 + DisplayedLevel |
| Promoted | 6 | 26 | 20 + DisplayedLevel |
| Promoted | 7 | 27 | 20 + DisplayedLevel |
| Promoted | 8 | 28 | 20 + DisplayedLevel |
| Promoted | 9 | 29 | 20 + DisplayedLevel |
| Promoted | 10 | 30 | 20 + DisplayedLevel |
| Promoted | 11 | 31 | 20 + DisplayedLevel |
| Promoted | 12 | 32 | 20 + DisplayedLevel |
| Promoted | 13 | 33 | 20 + DisplayedLevel |
| Promoted | 14 | 34 | 20 + DisplayedLevel |
| Promoted | 15 | 35 | 20 + DisplayedLevel |
| Promoted | 16 | 36 | 20 + DisplayedLevel |
| Promoted | 17 | 37 | 20 + DisplayedLevel |
| Promoted | 18 | 38 | 20 + DisplayedLevel |
| Promoted | 19 | 39 | 20 + DisplayedLevel |
| Promoted | 20 | 40 | 20 + DisplayedLevel |
| Special | 1 | SpecialRule(1) | Use class-specific special/internal-level rule; commonly treated as special-tier effective level for Second Seal eligibility |
| Special | 5 | SpecialRule(5) | Use class-specific special/internal-level rule; commonly treated as special-tier effective level for Second Seal eligibility |
| Special | 10 | SpecialRule(10) | Use class-specific special/internal-level rule; commonly treated as special-tier effective level for Second Seal eligibility |
| Special | 15 | SpecialRule(15) | Use class-specific special/internal-level rule; commonly treated as special-tier effective level for Second Seal eligibility |
| Special | 20 | SpecialRule(20) | Use class-specific special/internal-level rule; commonly treated as special-tier effective level for Second Seal eligibility |
| Special | 25 | SpecialRule(25) | Use class-specific special/internal-level rule; commonly treated as special-tier effective level for Second Seal eligibility |
| Special | 30 | SpecialRule(30) | Use class-specific special/internal-level rule; commonly treated as special-tier effective level for Second Seal eligibility |

## Internal Level Use Cases

| System | Uses Internal Level | Notes |
| --- | --- | --- |
| EXP gain | Yes | Compare attacker/healer/support unit effective level against target or action context |
| Promotion | Yes after promotion | Promoted displayed level 1 is internal level 21 |
| Second Seal | Yes | Repeated reclassing should preserve accumulated level pressure |
| Child paralogue scaling | Conditional | Use scenario/recruitment scaling rules |
| Enemy autoleveling | Yes | Autolevel count and effective level drive stat generation |
| Underdog skill | Yes/effective level | Promoted enemies count as displayed level + 20 |
| Class skill acquisition | No, displayed class level | Skill unlocks use displayed level within current class |

## Reclass Internal-Level State Object

```yaml
level_state:
  displayed_level: integer
  class_state: base | promoted | special
  effective_internal_level: integer
  cumulative_reclass_pressure: integer
  class_change_count: integer
  last_class_change_method: master_seal | second_seal | dread_scroll | wedding_bouquet | scripted
```

## Displayed-Level Reset Table

| Class Change Method | New Displayed Level | Internal-Level Rule | Notes |
| --- | --- | --- | --- |
| Master Seal promotion | 1 | 20 + 1 = 21 | Base to promoted only |
| Second Seal to base class | 1 | Base/special rule plus accumulated reclass pressure | Unit class-set target |
| Second Seal to promoted class | 1 | 20 + 1 plus accumulated reclass pressure | Requires promoted-level eligibility |
| Second Seal to same max-level class | 1 | Same tier rule plus accumulated reclass pressure | Allowed at class cap |
| Dread Scroll | 1 | Special/DLC class rule plus accumulated reclass pressure | Target Dread Fighter |
| Wedding Bouquet | 1 | Special/DLC class rule plus accumulated reclass pressure | Target Bride |
| Scripted class change | Script-defined | Script-defined | Boss/NPC/story events |

---

# Enemy Stat Generation Examples

## Example 1 — Generic Fighter, Deterministic Average Autolevel

Inputs:

| Input | Value | Notes |
| --- | ---: | --- |
| Archetype | Fighter | From Phase 10 |
| Class | Fighter | From Phase 3 |
| Autolevel Count | 8 | Virtual level-ups |
| Difficulty Bonus | None | Normal-mode baseline example |
| Autolevel Model | floor(AutolevelCount × FinalGrowth / 100) | Deterministic average |

Final growths:

| Stat | Base | Growth | Gain | Final |
| --- | ---: | ---: | ---: | ---: |
| HP | 20 | 105 | 8 | 28 |
| STR | 8 | 70 | 5 | 13 |
| MAG | 0 | 5 | 0 | 0 |
| SKL | 5 | 50 | 4 | 9 |
| SPD | 5 | 40 | 3 | 8 |
| LCK | 0 | 30 | 2 | 2 |
| DEF | 4 | 40 | 3 | 7 |
| RES | 0 | 20 | 1 | 1 |

Formula:

```text
FinalStat =
ClassBaseStat + floor(AutolevelCount × (ArchetypeGrowth + ClassGrowth) / 100)
```

Result object:

```yaml
enemy:
  archetype: Fighter
  class: Fighter
  displayed_level: 9
  autolevel_count: 8
  stats:
    hp: 28
    str: 13
    mag: 0
    skl: 9
    spd: 8
    lck: 2
    def: 7
    res: 1
```

## Example 2 — Hard-Mode Great Knight, Promoted Enemy

Inputs:

| Input | Value | Notes |
| --- | ---: | --- |
| Archetype | Tank | From Phase 10 |
| Class | Great Knight | From Phase 4 |
| Displayed Level | 5 | Promoted |
| Internal Level | 25 | 20 + 5 |
| Autolevel Count | 24 | Example promoted enemy scaling |
| Difficulty Bonus | HP +3, STR +2, SKL +1, DEF +2, RES +1 | Example hard-mode modifier |
| Autolevel Model | floor(AutolevelCount × FinalGrowth / 100) | Deterministic average |

Final growths and stats:

| Stat | Base | Growth | Gain | Difficulty Bonus | Final |
| --- | ---: | ---: | ---: | --- | ---: |
| HP | 26 | 115 | 27 | 3 | 56 |
| STR | 11 | 60 | 14 | 2 | 27 |
| MAG | 0 | 20 | 4 | 0 | 4 |
| SKL | 6 | 40 | 9 | 1 | 16 |
| SPD | 5 | 30 | 7 | 0 | 12 |
| LCK | 0 | 25 | 6 | 0 | 6 |
| DEF | 14 | 65 | 15 | 2 | 31 |
| RES | 1 | 40 | 9 | 1 | 11 |

Formula:

```text
FinalStat =
ClassBaseStat
+ floor(AutolevelCount × (ArchetypeGrowth + ClassGrowth) / 100)
+ DifficultyBonus
```

Result object:

```yaml
enemy:
  archetype: Tank
  class: Great Knight
  displayed_level: 5
  internal_level: 25
  autolevel_count: 24
  difficulty: Hard
  stats:
    hp: 56
    str: 27
    mag: 4
    skl: 16
    spd: 12
    lck: 6
    def: 31
    res: 11
```

## Example 3 — Risen Revenant, Skirmish Monster

Inputs:

| Input | Value | Notes |
| --- | ---: | --- |
| Archetype | Risen | From Phase 10 |
| Class | Revenant | From Phase 5 |
| Autolevel Count | 12 | Example skirmish scaling |
| Difficulty Bonus | None | Baseline skirmish package |
| Autolevel Model | floor(AutolevelCount × FinalGrowth / 100) | Deterministic average |

Final growths and stats:

| Stat | Base | Growth | Gain | Final |
| --- | ---: | ---: | ---: | ---: |
| HP | 18 | 50 | 6 | 24 |
| STR | 3 | 30 | 3 | 6 |
| MAG | 0 | 25 | 3 | 3 |
| SKL | 0 | 25 | 3 | 3 |
| SPD | 0 | 25 | 3 | 3 |
| LCK | 0 | 10 | 1 | 1 |
| DEF | 0 | 25 | 3 | 3 |
| RES | 0 | 20 | 2 | 2 |

Result object:

```yaml
enemy:
  archetype: Risen
  class: Revenant
  autolevel_count: 12
  vulnerability_groups: [Monster]
  stats:
    hp: 24
    str: 6
    mag: 3
    skl: 3
    spd: 3
    lck: 1
    def: 3
    res: 2
```

## Randomized Autolevel Alternative

For each virtual level:

```text
For each stat:
    GuaranteedGain = floor(Growth / 100)
    Remainder = Growth mod 100
    StatGain += GuaranteedGain
    if RNG(0,99) < Remainder:
        StatGain += 1
```

Deterministic average is recommended for reproducible baseline simulation. Randomized autoleveling is recommended when modeling actual game variance.

---

# DLC Compatibility Notes

## DLC Class-Change Compatibility

| DLC Item | Target Class | Eligibility | Corpus Handling |
| --- | --- | --- | --- |
| Dread Scroll | Dread Fighter | Male unit; level 10+ base or any promoted level | Treat as Second Seal-like fixed-target class change |
| Wedding Bouquet | Bride | Female unit; level 10+ base or any promoted level | Treat as Second Seal-like fixed-target class change |

## DLC Skill-Item Compatibility

| DLC Skill Item | Learned Skill | Requires DLC Resolved | Inheritance Handling |
| --- | --- | --- | --- |
| All Stats +2 | All Stats +2 | Yes | Conditional; skill must be resolved and learned |
| Paragon | Paragon | Yes | Conditional; skill must be resolved and learned |
| Iote's Shield | Iote's Shield | Yes | Conditional; skill must be resolved and learned |
| Limit Breaker | Limit Breaker | Yes | Conditional; skill must be resolved and learned |

## Placeholder States

| Placeholder | Meaning | Resolver |
| --- | --- | --- |
| Outrealm Class | Class data unavailable or unresolved | Replace with actual DLC/SpotPass class when data resolves |
| Outrealm Skill | Skill data unavailable or unresolved | Replace with actual skill when data resolves |
| Outrealm Item | Item data unavailable or unresolved | Replace with actual item when data resolves |

## DLC Installation Flags

```yaml
dlc_flags:
  dlc_installed: true | false
  outrealm_gate_available: true | false
  dlc_class_items_available:
    dread_scroll: true | false
    wedding_bouquet: true | false
  dlc_skill_items_available:
    all_stats_plus_2: true | false
    paragon: true | false
    iotes_shield: true | false
    limit_breaker: true | false
  dlc_maps_available:
    champions_of_yore: true | false
    lost_bloodlines: true | false
    smash_brethren: true | false
    rogues_and_redeemers: true | false
    challenge_pack: true | false
    scramble_pack: true | false
    future_past: true | false
    apotheosis: true | false
```

## Platform Availability Note

As of this corpus date, new Nintendo 3DS eShop purchases are not available after the 2023 shutdown. Previously purchased Nintendo 3DS content and DLC may still be redownloaded for the foreseeable future, and software updates remain downloadable under Nintendo's support guidance.

Rules-engine implication:

```text
DLCUsableInSimulation =
DLCDataInstalledOrProvidedByDataset
```

Do not infer DLC availability from current purchase availability.

## DLC Compatibility Matrix

| Corpus Feature | Requires DLC Data | Works Without DLC Data | Fallback |
| --- | --- | --- | --- |
| Dread Fighter class | Yes | No | Outrealm Class or unavailable target |
| Bride class | Yes | No | Outrealm Class or unavailable target |
| Dread Scroll | Yes | No | Outrealm Item |
| Wedding Bouquet | Yes | No | Outrealm Item |
| All Stats +2 skill item | Yes | No | Outrealm Item / Outrealm Skill |
| Paragon skill item | Yes | No | Outrealm Item / Outrealm Skill |
| Iote's Shield skill item | Yes | No | Outrealm Item / Outrealm Skill |
| Limit Breaker skill item | Yes | No | Outrealm Item / Outrealm Skill |
| DLC weapons/items | Yes | Partial | Outrealm Item if unresolved |
| SpotPass characters | Character data required | Partial | Generic unit fallback if class/skill data exists |
| StreetPass teams | No DLC required for core mechanics | Yes | Use local team/unit payload |

---

# Appendix Implementation Constants

## Effectiveness

```yaml
effectiveness:
  default_multiplier: 3
  stacks_multiple_groups: false
  applies_to_weapon_might: true
```

## Critical

```yaml
critical:
  multiplier: 3
  order: after_effectiveness_and_defense
```

## Leveling

```yaml
leveling:
  base_internal_level_formula: DisplayedLevel
  promoted_internal_level_formula: 20 + DisplayedLevel
  special_internal_level_formula: SpecialClassRule
```

## Class Change

```yaml
class_change:
  promotion_min_level: 10
  second_seal_base_min_level: 10
  second_seal_promoted_min_level_for_promoted_targets: 10
  second_seal_special_max_level_for_promoted_targets: 30
  displayed_level_after_class_change: 1
```

## Skill Inheritance

```yaml
skill_inheritance:
  parent_skill_slot: last_equipped_skill
  hardcoded_chrom_override: true
  enemy_exclusive_skills_inheritable: false
  placeholder_skills_inheritable: false
  weapon_granted_effects_inheritable: false
  dlc_skills_require_resolved_dlc: true
```

---

# End of Phase 11 — Appendices
