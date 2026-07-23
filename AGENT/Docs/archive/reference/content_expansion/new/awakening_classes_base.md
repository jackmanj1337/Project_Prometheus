> **Historical** — External Awakening reference corpus; not active Project Prometheus rules or public-pack content.

# Fire Emblem Awakening Technical Reference Corpus
# Base Classes

**File:** `awakening_classes_base.md`  
**Phase:** 3  
**Corpus Version:** `0.4.0-phase3`  
**Depends On:** `awakening_project_index.md`, `awakening_core_systems.md`, `awakening_lookup_tables.md`  
**Scope:** Regular tier-1/base classes only. Special single-tier classes are deferred to `awakening_classes_special.md`.

---

# Table of Contents

1. [Phase Boundary](#phase-boundary)
2. [Normalization Notes](#normalization-notes)
3. [Base Class Entries](#base-class-entries)

---

# Phase Boundary

This document includes the regular base-class set:

| Included Class Family | Included Here | Notes |
|---|---|---|
| Lord | Yes | Split into male/female definitions because mechanics differ. |
| Tactician | Yes | Universal definition. |
| Cavalier | Yes | Universal definition. |
| Knight | Yes | Universal definition. |
| Myrmidon | Yes | Universal definition. |
| Thief | Yes | Universal definition. |
| Mercenary | Yes | Universal definition. |
| Fighter | Yes | Universal mechanics; vanilla access is male-gated. |
| Barbarian | Yes | Universal mechanics; vanilla access is male-gated. |
| Archer | Yes | Universal definition. |
| Pegasus Knight | Yes | Universal mechanics; vanilla access is female-gated. |
| Wyvern Rider | Yes | Universal definition. |
| Troubadour | Yes | Universal mechanics; vanilla access is female-gated. |
| Priest / Cleric | Yes | Unified because mechanics are identical. |
| Mage | Yes | Universal definition. |
| Dark Mage | Yes | Universal definition. |

The following are intentionally deferred to Phase 5 because they are special, single-tier, transformation, DLC, SpotPass, NPC, enemy-only, or otherwise non-regular classes:

| Deferred Class | Target Phase |
|---|---|
| Villager | Phase 5 |
| Dancer | Phase 5 |
| Taguel | Phase 5 |
| Manakete | Phase 5 |
| Lodestar | Phase 5 |
| Dread Fighter | Phase 5 |
| Bride | Phase 5 |
| Conqueror | Phase 5 |
| Soldier | Phase 5 |
| Merchant | Phase 5 |
| Revenant | Phase 5 |
| Entombed | Phase 5 |
| Mirage | Phase 5 |
| Grima | Phase 5 |
| Outrealm Class | Phase 5 |

---

# Normalization Notes

## Gender-Locked Class Handling

Gender-locked access is represented as an access legality flag, not as a separate mechanical class, unless data differs mechanically.

| Case | Corpus Handling |
|---|---|
| Identical male/female mechanics | One universal class definition |
| Different base stats, caps, or mechanics | Separate class definitions |
| Gender-only access restriction | Universal mechanical class with vanilla access flag |

## Weapon Proficiency Handling

All weapon proficiency values use numeric WEXP.

| Rank | WEXP |
|---|---:|
| E | 1 |
| D | 31 |
| C | 71 |
| B | 121 |
| A | 181 |
| S | 251 |
| Cap | 400 |

For vanilla Awakening class entries in this file:

```text
Base WEXP = 1
Starting Rank = E
Normal Active Max WEXP = 250
Normal Active Max Rank = A
Global Stored WEXP Cap = 400
```

Awakening does not normally expose player-attainable S-rank weapon levels. The S threshold is retained for corpus-wide compatibility and rules-engine normalization.

## Stat Table Order

All class stat tables use:

```text
HP, STR, MAG, SKL, SPD, LCK, DEF, RES, MOV
```

Growth and cap tables omit MOV because movement does not grow by standard level-up mechanics.

## Base Stats and Luck

Class base Luck is `0` for all regular classes.

---

# Base Class Entries


## Lord (Male)

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Personal regular base class |
| Movement | 5 |
| Movement Type | Special |
| Vulnerability Group | None |
| Promotion Targets | Great Lord (Male) |
| Reclass Sources | Chrom initial/personal class set; not normally inherited by children except Lucina's own Lord class line uses the female variant; excluded from normal Avatar/all-regular-class pools. |
| Internal Flags | base_class; personal_class; promotable; male_variant; rapier_access; noble_rapier_access; lord_inheritance_restricted |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 6 | 0 | 5 | 7 | 0 | 7 | 0 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 20 | 0 | 20 | 20 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 27 | 20 | 25 | 26 | 30 | 26 | 25 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Dual Strike+ | 1 | Passive | Base-class skill 1 |
| Charm | 10 | Passive aura | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Special terrain movement category. Infantry-style unit; receives normal terrain bonuses unless a map/script overrides.


### Mechanical Notes

- Mechanically distinct from Lord (Female) in base stats, caps, and pair-up bonus profile.
- Pair Up bonuses: STR +0, MAG +0, SKL +0, SPD +3, LCK +3, DEF +0, RES +0, MOV +0.
- Can use Rapier and Noble Rapier according to class weapon restrictions.
- Promotion target is gender-matched Great Lord (Male).



## Lord (Female)

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Personal regular base class |
| Movement | 5 |
| Movement Type | Special |
| Vulnerability Group | None |
| Promotion Targets | Great Lord (Female) |
| Reclass Sources | Lucina initial/personal class set; not inherited as a normal child class option; excluded from normal Avatar/all-regular-class pools. |
| Internal Flags | base_class; personal_class; promotable; female_variant; rapier_access; noble_rapier_access; lord_inheritance_restricted |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 5 | 1 | 6 | 8 | 0 | 6 | 1 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 20 | 0 | 20 | 20 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 25 | 20 | 26 | 28 | 30 | 25 | 25 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Dual Strike+ | 1 | Passive | Base-class skill 1 |
| Charm | 10 | Passive aura | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Special terrain movement category. Infantry-style unit; receives normal terrain bonuses unless a map/script overrides.


### Mechanical Notes

- Mechanically distinct from Lord (Male) in base stats, caps, and pair-up bonus profile.
- Pair Up bonuses: STR +0, MAG +0, SKL +0, SPD +3, LCK +3, DEF +0, RES +0, MOV +0.
- Can use Rapier and Noble Rapier according to class weapon restrictions.
- Promotion target is gender-matched Great Lord (Female).



## Tactician

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class / Avatar line |
| Movement | 5 |
| Movement Type | Special |
| Vulnerability Group | None |
| Promotion Targets | Grandmaster |
| Reclass Sources | Avatar initial class; Morgan variable initial/inherited access; DLC/SpotPass all-regular-class access where applicable; otherwise not a normal non-Avatar class-set option. |
| Internal Flags | base_class; regular_class; promotable; avatar_line; sword_access; tome_access; gender_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Tome | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 4 | 3 | 5 | 5 | 0 | 5 | 3 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 15 | 15 | 15 | 15 | 0 | 10 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 25 | 25 | 25 | 25 | 30 | 25 | 25 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Veteran | 1 | Passive | Base-class skill 1 |
| Solidarity | 10 | Passive aura | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Special terrain movement category. Infantry-style movement and terrain interaction.


### Mechanical Notes

- Male and female Tactician entries are mechanically identical and normalized into one universal definition.
- Pair Up bonuses: STR +1, MAG +1, SKL +2, SPD +2, LCK +0, DEF +0, RES +0, MOV +0.
- Has dual physical/magical weapon access at base tier.
- Promotion target is Grandmaster.



## Cavalier

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 7 |
| Movement Type | Cavalry A |
| Vulnerability Group | Cavalry; Beast-type mounted effectiveness where applicable |
| Promotion Targets | Paladin; Great Knight |
| Reclass Sources | Avatar; Chrom; Frederick; Sully; Stahl; Ricken; Lucina; Brady; Kjelle; DLC/SpotPass all-regular-class access; inherited regular class where legal. |
| Internal Flags | base_class; regular_class; promotable; mounted; sword_access; lance_access; gender_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Lance | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 6 | 0 | 5 | 6 | 0 | 7 | 0 | 7 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 20 | 0 | 20 | 20 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 26 | 20 | 25 | 25 | 30 | 26 | 26 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Discipline | 1 | Passive | Base-class skill 1 |
| Outdoor Fighter | 10 | Passive conditional combat bonus | Base-class skill 2 |


### Terrain / Mobility Notes

Uses cavalry movement costs. Ground-mounted class; affected by cavalry terrain restrictions and mounted effectiveness.


### Mechanical Notes

- Male and female variants are normalized because core class mechanics are equivalent for simulator purposes.
- Pair Up bonuses: STR +2, MAG +0, SKL +1, SPD +1, LCK +0, DEF +2, RES +0, MOV +0.
- Can promote into either mobility/resistance Paladin or armored Great Knight.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Knight

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 4 |
| Movement Type | Armor |
| Vulnerability Group | Armor |
| Promotion Targets | General; Great Knight |
| Reclass Sources | Avatar; Frederick; Kellam; Sumia; Tharja; Basilio; Flavia; Walhart; Kjelle; Cynthia; Noire; DLC/SpotPass all-regular-class access; inherited regular class where legal. |
| Internal Flags | base_class; regular_class; promotable; armored; lance_access; gender_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Lance | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 8 | 0 | 4 | 2 | 0 | 11 | 0 | 4 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 25 | 0 | 15 | 10 | 0 | 15 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 30 | 20 | 26 | 23 | 30 | 30 | 22 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Defense +2 | 1 | Passive stat bonus | Base-class skill 1 |
| Indoor Fighter | 10 | Passive conditional combat bonus | Base-class skill 2 |


### Terrain / Mobility Notes

Uses armor movement costs. Low movement; restricted by terrain more severely than standard infantry.


### Mechanical Notes

- Pair Up bonuses: STR +2, MAG +0, SKL +0, SPD +0, LCK +0, DEF +4, RES +0, MOV +0.
- Armor vulnerability applies to armor-effective weapons.
- Can promote into General or Great Knight.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Myrmidon

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 5 |
| Movement Type | Infantry A |
| Vulnerability Group | None |
| Promotion Targets | Swordmaster; Assassin |
| Reclass Sources | Avatar; Sully; Stahl; Lon'qu; Gaius; Gregor; Say'ri; Yen'fay; Priam; Owain; Inigo; Kjelle; DLC/SpotPass all-regular-class access; inherited regular class where legal. |
| Internal Flags | base_class; regular_class; promotable; infantry; sword_access; gender_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 4 | 1 | 9 | 10 | 0 | 4 | 1 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 20 | 0 | 25 | 25 | 0 | 5 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 24 | 22 | 27 | 28 | 30 | 22 | 24 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Avoid +10 | 1 | Passive combat bonus | Base-class skill 1 |
| Vantage | 10 | Passive combat-order modifier | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Infantry A movement costs. Standard light infantry terrain interaction.


### Mechanical Notes

- Pair Up bonuses: STR +0, MAG +0, SKL +0, SPD +4, LCK +2, DEF +0, RES +0, MOV +0.
- Can use certain sword-restricted legendary/personal swords where class legality permits.
- Promotes into Swordmaster or Assassin.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Thief

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 5 |
| Movement Type | Infantry C |
| Vulnerability Group | None |
| Promotion Targets | Assassin; Trickster |
| Reclass Sources | Avatar; Vaike; Kellam; Lon'qu; Panne; Gaius; Anna; Henry; Flavia; Gangrel; Yarne; DLC/SpotPass all-regular-class access; inherited regular class where legal. |
| Internal Flags | base_class; regular_class; promotable; infantry; sword_access; lock_utility; gender_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 3 | 0 | 6 | 8 | 0 | 2 | 0 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 15 | 5 | 25 | 25 | 0 | 5 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 22 | 20 | 29 | 28 | 30 | 21 | 20 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Locktouch | 1 | Passive utility | Base-class skill 1 |
| Movement +1 | 10 | Passive movement bonus | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Infantry C movement costs. Mobile infantry profile with utility emphasis.


### Mechanical Notes

- Pair Up bonuses: STR +0, MAG +0, SKL +2, SPD +2, LCK +0, DEF +0, RES +0, MOV +1.
- Locktouch allows opening doors and chests without keys when the skill is equipped/active.
- Promotes into Assassin or Trickster.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Mercenary

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 5 |
| Movement Type | Infantry A |
| Vulnerability Group | None |
| Promotion Targets | Hero; Bow Knight |
| Reclass Sources | Avatar; Donnel; Cordelia; Gregor; Flavia; Priam; Inigo; Severa; DLC/SpotPass all-regular-class access; inherited regular class where legal. |
| Internal Flags | base_class; regular_class; promotable; infantry; sword_access; gender_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 5 | 0 | 8 | 7 | 0 | 5 | 0 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 20 | 0 | 25 | 20 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 26 | 20 | 28 | 26 | 30 | 25 | 23 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Armsthrift | 1 | Passive durability conservation proc | Base-class skill 1 |
| Patience | 10 | Passive enemy-phase combat bonus | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Infantry A movement costs. Standard light infantry terrain interaction.


### Mechanical Notes

- Pair Up bonuses: STR +0, MAG +0, SKL +2, SPD +3, LCK +0, DEF +1, RES +0, MOV +0.
- Promotes into Hero or Bow Knight.
- Serves as a balanced physical infantry base class.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Fighter

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 5 |
| Movement Type | Infantry B |
| Vulnerability Group | None |
| Promotion Targets | Hero; Warrior |
| Reclass Sources | Avatar (male legality); Vaike; Donnel; Basilio; Priam; Gerome; DLC/SpotPass male all-regular-class access; inherited regular class where legal or replaced if gender-illegal. |
| Internal Flags | base_class; regular_class; promotable; infantry; axe_access; male_access_in_vanilla; normalized_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Axe | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 8 | 0 | 5 | 5 | 0 | 4 | 0 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 25 | 0 | 20 | 15 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 29 | 20 | 26 | 25 | 30 | 25 | 23 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| HP +5 | 1 | Passive stat bonus | Base-class skill 1 |
| Zeal | 10 | Passive critical bonus | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Infantry B movement costs. Infantry profile with heavier rough-terrain behavior than Infantry A.


### Mechanical Notes

- Class is male-access in vanilla but normalized as a universal mechanical class because no separate female mechanical version exists.
- Pair Up bonuses: STR +4, MAG +0, SKL +0, SPD +0, LCK +0, DEF +2, RES +0, MOV +0.
- Promotes into Hero or Warrior.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Barbarian

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 5 |
| Movement Type | Infantry B |
| Vulnerability Group | None |
| Promotion Targets | Berserker; Warrior |
| Reclass Sources | Avatar (male legality); Vaike; Gregor; Henry; Basilio; Gangrel; Owain; Inigo; Laurent; Yarne; DLC/SpotPass male all-regular-class access; inherited regular class where legal or replaced if gender-illegal. |
| Internal Flags | base_class; regular_class; promotable; infantry; axe_access; male_access_in_vanilla; normalized_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Axe | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 22 | 8 | 0 | 3 | 8 | 0 | 3 | 0 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 25 | 0 | 15 | 20 | 0 | 5 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 30 | 20 | 23 | 27 | 30 | 22 | 20 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Despoil | 1 | Luck-based post-kill item proc | Base-class skill 1 |
| Gamble | 10 | Passive hit/crit tradeoff | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Infantry B movement costs. Infantry profile suited to rougher terrain than mounted classes.


### Mechanical Notes

- Class is male-access in vanilla but normalized as a universal mechanical class because no separate female mechanical version exists.
- Pair Up bonuses: STR +4, MAG +0, SKL +0, SPD +2, LCK +0, DEF +0, RES +0, MOV +0.
- Promotes into Berserker or Warrior.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Archer

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 5 |
| Movement Type | Infantry A |
| Vulnerability Group | None |
| Promotion Targets | Sniper; Bow Knight |
| Reclass Sources | Avatar; Chrom; Virion; Stahl; Ricken; Tharja; Anna; Yen'fay; Lucina; Noire; DLC/SpotPass all-regular-class access; inherited regular class where legal. |
| Internal Flags | base_class; regular_class; promotable; infantry; bow_access; standard_2_range_physical; gender_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Bow | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 5 | 0 | 8 | 6 | 0 | 5 | 0 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 15 | 0 | 30 | 15 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 26 | 20 | 29 | 25 | 30 | 25 | 21 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Skill +2 | 1 | Passive stat bonus | Base-class skill 1 |
| Prescience | 10 | Passive player-phase combat bonus | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Infantry A movement costs. Standard light infantry terrain interaction.


### Mechanical Notes

- Pair Up bonuses: STR +2, MAG +0, SKL +2, SPD +0, LCK +0, DEF +2, RES +0, MOV +0.
- Bow attacks are normally range 2 and cannot counter at range 1 unless weapon-specific rules allow.
- Bow weapons normally provide flying effectiveness where the weapon entry defines it.
- Promotes into Sniper or Bow Knight.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Pegasus Knight

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 7 |
| Movement Type | Flier |
| Vulnerability Group | Flying; Beast-type mount effectiveness where applicable |
| Promotion Targets | Falcon Knight; Dark Flier |
| Reclass Sources | Avatar (female legality); Lissa; Sumia; Maribelle; Cordelia; Olivia; Say'ri; Emmeryn; Aversa; Cynthia; Severa; DLC/SpotPass female all-regular-class access; inherited regular class where legal or replaced if gender-illegal. |
| Internal Flags | base_class; regular_class; promotable; flying; lance_access; female_access_in_vanilla; normalized_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Lance | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 4 | 2 | 7 | 8 | 0 | 4 | 6 | 7 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 15 | 5 | 25 | 25 | 0 | 5 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 24 | 23 | 28 | 27 | 30 | 22 | 25 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Speed +2 | 1 | Passive stat bonus | Base-class skill 1 |
| Relief | 10 | Conditional start-of-turn healing | Base-class skill 2 |


### Terrain / Mobility Notes

Flying movement. Ignores most ground movement costs; vulnerable to flying-effective attacks. Terrain defensive bonuses should be handled by flying terrain rules from lookup tables.


### Mechanical Notes

- Class is female-access in vanilla but normalized as a universal mechanical class because no separate male mechanical version exists.
- Pair Up bonuses: STR +0, MAG +0, SKL +0, SPD +3, LCK +0, DEF +0, RES +3, MOV +0.
- Promotes into Falcon Knight or Dark Flier.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Wyvern Rider

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 7 |
| Movement Type | Flier |
| Vulnerability Group | Flying; Dragon |
| Promotion Targets | Wyvern Lord; Griffon Rider |
| Reclass Sources | Avatar; Frederick; Sully; Virion; Lon'qu; Panne; Nowi; Cherche; Say'ri; Tiki; Walhart; Yen'fay; Aversa; Kjelle; Gerome; Nah; DLC/SpotPass all-regular-class access; inherited regular class where legal. |
| Internal Flags | base_class; regular_class; promotable; flying; dragon_mount; axe_access; gender_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Axe | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 19 | 7 | 0 | 6 | 5 | 0 | 8 | 0 | 7 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 30 | 0 | 15 | 15 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 28 | 20 | 24 | 24 | 30 | 28 | 20 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Strength +2 | 1 | Passive stat bonus | Base-class skill 1 |
| Tantivy | 10 | Conditional combat bonus | Base-class skill 2 |


### Terrain / Mobility Notes

Flying movement. Ignores most ground movement costs; vulnerable to flying-effective attacks and dragon-effective attacks where those groups apply.


### Mechanical Notes

- Pair Up bonuses: STR +3, MAG +0, SKL +0, SPD +0, LCK +0, DEF +3, RES +0, MOV +0.
- Promotes into Wyvern Lord or Griffon Rider.
- Uses axe access at base tier; Wyvern Lord gains lances on promotion.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Troubadour

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 7 |
| Movement Type | Cavalry A |
| Vulnerability Group | Cavalry; Beast-type mounted effectiveness where applicable |
| Promotion Targets | Valkyrie; War Cleric |
| Reclass Sources | Avatar (female legality); Lissa; Miriel; Maribelle; Cherche; Emmeryn; DLC/SpotPass female all-regular-class access; inherited regular class where legal or replaced if gender-illegal. |
| Internal Flags | base_class; regular_class; promotable; mounted; staff_access; female_access_in_vanilla; normalized_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Staff | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 0 | 3 | 2 | 5 | 0 | 1 | 5 | 7 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 0 | 20 | 10 | 20 | 0 | 5 | 15 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 20 | 26 | 24 | 26 | 30 | 20 | 28 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Resistance +2 | 1 | Passive stat bonus | Base-class skill 1 |
| Demoiselle | 10 | Passive aura | Base-class skill 2 |


### Terrain / Mobility Notes

Uses cavalry movement costs. Ground-mounted staff class; affected by cavalry terrain restrictions and mounted effectiveness.


### Mechanical Notes

- Class is female-access in vanilla but normalized as a universal mechanical class because no separate male mechanical version exists.
- Pair Up bonuses: STR +0, MAG +2, SKL +0, SPD +1, LCK +0, DEF +0, RES +3, MOV +0.
- Cannot attack with standard staves; combat capability depends on promotion or special staff/item behavior.
- Promotes into Valkyrie or War Cleric.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Priest / Cleric

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 5 |
| Movement Type | Mage |
| Vulnerability Group | None |
| Promotion Targets | Sage; War Monk / War Cleric |
| Reclass Sources | Avatar; Lissa; Sumia; Kellam; Libra; Cherche; Emmeryn; Owain; Brady; Cynthia; Gerome; DLC/SpotPass all-regular-class access where gender naming applies; inherited regular class where legal. |
| Internal Flags | base_class; regular_class; promotable; staff_access; priest_cleric_gender_name_alias; normalized_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Staff | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 0 | 3 | 2 | 4 | 0 | 1 | 6 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 5 | 15 | 15 | 15 | 0 | 5 | 15 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 22 | 25 | 24 | 25 | 30 | 22 | 27 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Miracle | 1 | Luck-based survival proc | Base-class skill 1 |
| Healtouch | 10 | Passive healing bonus | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Mage movement costs. Infantry staff class with magic-user movement profile.


### Mechanical Notes

- Priest and Cleric are normalized into one definition because listed bases, growths, caps, weapon access, and skills are mechanically identical.
- Pair Up bonuses: STR +0, MAG +2, SKL +0, SPD +0, LCK +2, DEF +0, RES +2, MOV +0.
- Promotion label varies by gender: Priest promotes to War Monk; Cleric promotes to War Cleric. Sage is shared.
- Cannot attack with standard staves; offensive capability depends on promotion or special staff behavior.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Mage

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 5 |
| Movement Type | Mage |
| Vulnerability Group | None |
| Promotion Targets | Sage; Dark Knight |
| Reclass Sources | Avatar; Virion; Miriel; Ricken; Maribelle; Nowi; Libra; Anna; Tiki; Brady; Laurent; Nah; DLC/SpotPass all-regular-class access; inherited regular class where legal. |
| Internal Flags | base_class; regular_class; promotable; tome_access; magic_infantry; gender_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Tome | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 0 | 4 | 3 | 4 | 0 | 2 | 3 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 0 | 20 | 20 | 20 | 0 | 5 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 20 | 28 | 27 | 26 | 30 | 21 | 25 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Magic +2 | 1 | Passive stat bonus | Base-class skill 1 |
| Focus | 10 | Conditional critical bonus | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Mage movement costs. Infantry magic class with magic-user movement profile.


### Mechanical Notes

- Pair Up bonuses: STR +0, MAG +4, SKL +2, SPD +0, LCK +0, DEF +0, RES +0, MOV +0.
- Uses standard tomes. Dark magic access requires Dark Mage/Sorcerer-style class permission or special rules.
- Promotes into Sage or Dark Knight.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Dark Mage

### Metadata

| Property | Value |
|---|---|
| Tier | Base / Tier 1 |
| Internal Category | Regular base class |
| Movement | 5 |
| Movement Type | Mage |
| Vulnerability Group | None |
| Promotion Targets | Sorcerer; Dark Knight |
| Reclass Sources | Avatar; Miriel; Cordelia; Libra; Tharja; Henry; Gangrel; Aversa; Severa; Laurent; Noire; DLC/SpotPass all-regular-class access; inherited regular class where legal. |
| Internal Flags | base_class; regular_class; promotable; tome_access; dark_magic_access; magic_infantry; gender_universal_mechanics |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Tome | 1 | E | 250 | A |
| Dark Tome | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 1 | 3 | 2 | 3 | 0 | 4 | 4 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 5 | 15 | 15 | 15 | 0 | 10 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 20 | 27 | 25 | 25 | 30 | 25 | 27 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Hex | 1 | Passive enemy debuff aura | Base-class skill 1 |
| Anathema | 10 | Passive enemy debuff aura | Base-class skill 2 |


### Terrain / Mobility Notes

Uses Mage movement costs. Infantry magic class with more defensive growth/cap profile than Mage.


### Mechanical Notes

- Pair Up bonuses: STR +0, MAG +3, SKL +0, SPD +0, LCK +0, DEF +3, RES +0, MOV +0.
- Can use dark magic through class permission.
- Promotes into Sorcerer or Dark Knight.
- Dark Tome row is represented separately for simulator clarity even though in-game UI commonly displays tome rank plus dark access.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



---

# End of Phase 3 — Base Classes
