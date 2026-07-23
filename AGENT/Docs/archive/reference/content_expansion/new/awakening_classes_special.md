> **Historical** — External Awakening reference corpus; not active Project Prometheus rules or public-pack content.

# Fire Emblem Awakening Technical Reference Corpus
# Special / NPC / Enemy / DLC Classes

**File:** `awakening_classes_special.md`  
**Phase:** 5  
**Corpus Version:** `0.6.0-phase5`  
**Depends On:** `awakening_project_index.md`, `awakening_core_systems.md`, `awakening_lookup_tables.md`, `awakening_classes_base.md`, `awakening_classes_promoted.md`  
**Scope:** Special classes, boss-only classes, enemy-only classes, NPC classes, SpotPass-associated classes, DLC classes, transformation classes, and placeholder classes.

---

# Table of Contents

1. [Phase Boundary](#phase-boundary)
2. [Normalization Notes](#normalization-notes)
3. [Special Class Entries](#special-class-entries)

---

# Phase Boundary

This document includes classes that are not ordinary regular base or promoted classes.

| Included Class | Category |
|---|---|
| Villager | Playable special single-tier |
| Dancer | Playable special single-tier |
| Taguel (Male) | Playable transformation special class |
| Taguel (Female) | Playable transformation special class |
| Manakete | Playable transformation special class |
| Lodestar | Special / DLC-associated |
| Dread Fighter | DLC special class |
| Bride | DLC special class |
| Conqueror | Special / character-associated / boss-associated |
| Soldier | NPC/enemy |
| Merchant | NPC/enemy utility |
| Revenant | Enemy monster |
| Entombed | Enemy monster |
| Grima | Boss-only |
| Mirage | Placeholder/internal special class |
| Outrealm Class | DLC placeholder/proxy class |

Regular base classes are defined in `awakening_classes_base.md`.  
Regular promoted classes are defined in `awakening_classes_promoted.md`.

---

# Normalization Notes

## Special Class Leveling

Most playable special classes use a displayed level cap of 30 and do not promote with a Master Seal.

```text
SpecialClassDisplayedLevelRange = 1–30
```

Special classes generally learn class skills at:

```text
Skill1Level = 1
Skill2Level = 15
```

NPC, enemy, boss-only, and placeholder classes do not necessarily follow playable skill-learning behavior.

## Reclassing

Special classes can interact with Second Seal rules differently from ordinary base/promoted classes.

General model:

```text
SpecialClassSecondSealEligibility =
DisplayedLevel ≥ 10 for reclass to valid base-class options
OR DisplayedLevel = 30 for expanded special/max-level behavior
```

DLC class-change items:

| Item | Target Class |
|---|---|
| Dread Scroll | Dread Fighter |
| Wedding Bouquet | Bride |

These items function like special class-change items rather than ordinary Master Seals.

## Weapon Proficiency Handling

All standard ranked weapon access uses numeric WEXP.

| Rank | WEXP |
|---|---:|
| E | 1 |
| D | 31 |
| C | 71 |
| B | 121 |
| A | 181 |
| S | 251 |
| Cap | 400 |

For standard weapon categories in vanilla Awakening class entries:

```text
Base WEXP = 1
Starting Rank = E
Normal Active Max WEXP = 250
Normal Active Max Rank = A
Global Stored WEXP Cap = 400
```

For unranked natural, monster, placeholder, beaststone, or dragonstone categories:

```text
Base WEXP = 0
Rank = Unranked
Max WEXP = 0
Max Rank = Unranked
```

This preserves the required schema while preventing simulator engines from treating unranked natural weapons as normal ranked weapon families.

## Gender / Variant Normalization

| Class | Corpus Handling |
|---|---|
| Taguel | Split into male/female definitions because base stats and growth modifiers differ. |
| Dread Fighter | Universal mechanical definition with vanilla access legality flag. |
| Bride | Universal mechanical definition with vanilla access legality flag. |
| Villager | Universal mechanical definition with vanilla male/inheritance legality flags. |

## Stat Table Order

All class stat tables use:

```text
HP, STR, MAG, SKL, SPD, LCK, DEF, RES, MOV
```

Growth and cap tables omit MOV because movement does not grow by standard level-up mechanics.

---

# Special Class Entries


## Villager

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Single-tier |
| Internal Category | Playable special class |
| Movement | 5 |
| Movement Type | Infantry B |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Donnel initial class; male children may inherit Villager through Donnel inheritance rules; Avatar cannot normally access through all-regular-class rule. |
| Internal Flags | special_class; playable; single_tier; level_cap_30; lance_access; male_access_in_vanilla; limited_inheritance; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Lance | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 1 | 0 | 1 | 1 | 0 | 1 | 0 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 10 | 0 | 5 | 5 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 20 | 20 | 20 | 20 | 30 | 20 | 20 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Aptitude | 1 | Passive growth modifier | Adds +20 percentage points to all stat growth rates while equipped. |
| Underdog | 15 | Passive combat bonus | Hit and Avoid +15 when user is at lower level than the enemy. |


### Terrain / Mobility Notes

Uses Infantry B movement costs. Low-tier special infantry profile.


### Mechanical Notes

- Special single-tier class with displayed level cap 30.
- Cannot use Master Seal for a direct promotion.
- Can use Second Seal according to special-class rules.
- Villager is a special class but has limited inheritance behavior through Donnel for male children.
- Uses standard lance WEXP progression with normal active A-rank ceiling in vanilla Awakening.



## Dancer

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Single-tier |
| Internal Category | Playable special class |
| Movement | 5 |
| Movement Type | Special |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Olivia initial/personal special class; not normally inherited; Avatar cannot normally access through all-regular-class rule. |
| Internal Flags | special_class; playable; personal_class; single_tier; level_cap_30; sword_access; dance_command; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 1 | 1 | 5 | 8 | 0 | 3 | 1 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 5 | 0 | 25 | 25 | 0 | 5 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 30 | 30 | 40 | 40 | 45 | 30 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Luck +4 | 1 | Passive stat bonus | LCK +4 while equipped. |
| Special Dance | 15 | Command modifier | Dance grants STR/MAG/DEF/RES +2 to the refreshed ally for one turn. |


### Terrain / Mobility Notes

Uses Special movement category. Infantry-style support class.


### Mechanical Notes

- Special single-tier class with displayed level cap 30.
- Dance refreshes an allied unit, allowing another action under normal refresh rules.
- Cannot use Master Seal for a direct promotion.
- Can use Second Seal according to special-class rules.
- Dancer is not normally inherited by children.



## Taguel (Male)

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Single-tier / Transformation |
| Internal Category | Playable transformation class |
| Movement | 6 |
| Movement Type | Special |
| Vulnerability Group | Beast |
| Promotion Targets | N/A |
| Reclass Sources | Yarne initial/inherited special class; Morgan can inherit Taguel from a Taguel parent; otherwise not normally available. |
| Internal Flags | special_class; playable; transformation_class; single_tier; level_cap_30; beaststone_access; male_variant; limited_inheritance; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Beaststone | 0 | Unranked | 0 | Unranked |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 3 | 0 | 4 | 4 | 0 | 4 | 1 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 20 | 0 | 15 | 15 | 0 | 15 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 35 | 30 | 40 | 40 | 45 | 35 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Even Rhythm | 1 | Passive turn-parity bonus | Hit and Avoid +10 on even-numbered turns. |
| Beastbane | 15 | Passive effectiveness modifier | Attacks are effective against beast/mounted-class targets where weapon and class rules permit. |


### Terrain / Mobility Notes

Uses Special movement category. Transformation class using beaststone mechanics.


### Mechanical Notes

- Mechanically distinct from Taguel (Female) in base stats and growth modifiers.
- Special single-tier class with displayed level cap 30.
- Cannot use Master Seal for a direct promotion.
- Can use Second Seal according to special-class rules.
- Uses Beaststone category rather than standard ranked weapon progression.
- Unranked or natural weapon categories are encoded as Base WEXP 0 / Rank Unranked / Max WEXP 0 / Max Rank Unranked to preserve the required schema while reflecting that the class does not use standard WEXP rank progression for that category.



## Taguel (Female)

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Single-tier / Transformation |
| Internal Category | Playable transformation class |
| Movement | 6 |
| Movement Type | Special |
| Vulnerability Group | Beast |
| Promotion Targets | N/A |
| Reclass Sources | Panne initial/personal special class; Morgan can inherit Taguel from a Taguel parent; otherwise not normally available. |
| Internal Flags | special_class; playable; transformation_class; single_tier; level_cap_30; beaststone_access; female_variant; limited_inheritance; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Beaststone | 0 | Unranked | 0 | Unranked |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 2 | 0 | 4 | 5 | 0 | 3 | 2 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 15 | 0 | 20 | 20 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 35 | 30 | 40 | 40 | 45 | 35 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Even Rhythm | 1 | Passive turn-parity bonus | Hit and Avoid +10 on even-numbered turns. |
| Beastbane | 15 | Passive effectiveness modifier | Attacks are effective against beast/mounted-class targets where weapon and class rules permit. |


### Terrain / Mobility Notes

Uses Special movement category. Transformation class using beaststone mechanics.


### Mechanical Notes

- Mechanically distinct from Taguel (Male) in base stats and growth modifiers.
- Special single-tier class with displayed level cap 30.
- Cannot use Master Seal for a direct promotion.
- Can use Second Seal according to special-class rules.
- Uses Beaststone category rather than standard ranked weapon progression.
- Unranked or natural weapon categories are encoded as Base WEXP 0 / Rank Unranked / Max WEXP 0 / Max Rank Unranked to preserve the required schema while reflecting that the class does not use standard WEXP rank progression for that category.



## Manakete

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Single-tier / Transformation |
| Internal Category | Playable transformation class |
| Movement | 6 |
| Movement Type | Special |
| Vulnerability Group | Dragon |
| Promotion Targets | N/A |
| Reclass Sources | Nowi, Tiki, and Nah special class access; Morgan can inherit Manakete from a Manakete parent; otherwise not normally available. |
| Internal Flags | special_class; playable; transformation_class; single_tier; level_cap_30; dragonstone_access; limited_inheritance; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Dragonstone | 0 | Unranked | 0 | Unranked |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 2 | 0 | 1 | 1 | 0 | 2 | 2 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 20 | 5 | 20 | 20 | 0 | 15 | 15 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 40 | 35 | 35 | 35 | 45 | 40 | 40 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Odd Rhythm | 1 | Passive turn-parity bonus | Hit and Avoid +10 on odd-numbered turns. |
| Wyrmsbane | 15 | Passive effectiveness modifier | Attacks are effective against dragon-class targets where weapon and class rules permit. |


### Terrain / Mobility Notes

Uses Special movement category. Transformation class using dragonstone mechanics.


### Mechanical Notes

- Special single-tier class with displayed level cap 30.
- Cannot use Master Seal for a direct promotion.
- Can use Second Seal according to special-class rules.
- Dragon vulnerability applies to dragon-effective weapons.
- Uses Dragonstone category rather than standard ranked weapon progression.
- Unranked or natural weapon categories are encoded as Base WEXP 0 / Rank Unranked / Max WEXP 0 / Max Rank Unranked to preserve the required schema while reflecting that the class does not use standard WEXP rank progression for that category.



## Lodestar

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Single-tier / DLC-associated |
| Internal Category | Playable special class |
| Movement | 6 |
| Movement Type | Infantry C |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Marth-associated DLC/SpotPass-style special class access; not normally available through Avatar all-regular-class access. |
| Internal Flags | special_class; playable; dlc_or_spotpass_associated; single_tier; level_cap_30; sword_access; rapier_access; noble_rapier_access; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 21 | 9 | 1 | 10 | 10 | 0 | 8 | 4 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 20 | 0 | 20 | 20 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 41 | 30 | 43 | 43 | 45 | 41 | 40 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| N/A | N/A | N/A | No class skills listed in the canonical class table. |


### Terrain / Mobility Notes

Uses Infantry C movement costs. Advanced infantry-style special class.


### Mechanical Notes

- Special single-tier class with displayed level cap 30.
- Can use Rapier and Noble Rapier according to class restriction notes.
- Cannot use Master Seal for a direct promotion.
- Can use Second Seal according to special-class rules.
- Represents Marth-style special class behavior rather than the Lord/Great Lord class line.



## Dread Fighter

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Single-tier / DLC |
| Internal Category | Playable DLC special class |
| Movement | 6 |
| Movement Type | Infantry C |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Dread Scroll item; DLC class access; can be re-entered via Dread Scroll rather than normal Master Seal promotion. |
| Internal Flags | special_class; playable; dlc_class; single_tier; level_cap_30; sword_access; axe_access; tome_access; male_access_in_vanilla_item_use; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Axe | 1 | E | 250 | A |
| Tome | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 22 | 8 | 4 | 8 | 9 | 0 | 7 | 10 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 20 | 10 | 20 | 20 | 0 | 10 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 42 | 38 | 40 | 41 | 45 | 39 | 43 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Resistance +10 | 1 | Passive stat bonus | RES +10 while equipped. |
| Aggressor | 15 | Passive player-phase damage modifier | Damage +10 during user-initiated combat. |


### Terrain / Mobility Notes

Uses Infantry C movement costs. Advanced infantry special class with mixed physical/magical weapon access.


### Mechanical Notes

- Special DLC class with displayed level cap 30.
- Dread Scroll functions like a Second Seal but sends the unit to Dread Fighter.
- Cannot use Master Seal for a direct promotion.
- Can use Second Seal according to special-class rules.
- In vanilla access, Dread Fighter is male-oriented; corpus treats the mechanical class as universal unless access legality is being simulated.



## Bride

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Single-tier / DLC |
| Internal Category | Playable DLC special class |
| Movement | 6 |
| Movement Type | Infantry C |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Wedding Bouquet item; DLC class access; can be re-entered via Wedding Bouquet rather than normal Master Seal promotion. |
| Internal Flags | special_class; playable; dlc_class; single_tier; level_cap_30; lance_access; bow_access; staff_access; female_access_in_vanilla_item_use; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Lance | 1 | E | 250 | A |
| Bow | 1 | E | 250 | A |
| Staff | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 21 | 7 | 6 | 11 | 10 | 0 | 7 | 6 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 20 | 10 | 20 | 20 | 0 | 10 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 40 | 39 | 42 | 42 | 45 | 41 | 40 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Rally Heart | 1 | Command | All non-HP/non-MOV stats +2 and MOV +1 to allies within 3 tiles for one turn. |
| Bond | 15 | Passive turn-start support | Restores 10 HP to adjacent allies at the start of the user's turn. |


### Terrain / Mobility Notes

Uses Infantry C movement costs. Advanced infantry support/combat special class.


### Mechanical Notes

- Special DLC class with displayed level cap 30.
- Wedding Bouquet functions like a Second Seal but sends the unit to Bride.
- Cannot use Master Seal for a direct promotion.
- Can use Second Seal according to special-class rules.
- In vanilla access, Bride is female-oriented; corpus treats the mechanical class as universal unless access legality is being simulated.



## Conqueror

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Single-tier / Character-associated |
| Internal Category | Playable special class / boss-associated class |
| Movement | 8 |
| Movement Type | Cavalry B |
| Vulnerability Group | Armor; Cavalry; Beast-type mounted effectiveness where applicable |
| Promotion Targets | N/A |
| Reclass Sources | Walhart personal special class; not normally available through Avatar all-regular-class access. |
| Internal Flags | special_class; playable_spotpass; boss_associated; single_tier; level_cap_30; sword_access; lance_access; axe_access; armored; mounted; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Lance | 1 | E | 250 | A |
| Axe | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 24 | 10 | 2 | 9 | 8 | 0 | 12 | 5 | 8 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 20 | 5 | 15 | 15 | 0 | 10 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 45 | 25 | 40 | 40 | 45 | 45 | 35 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| N/A | N/A | N/A | No class skills listed in the canonical class table. |


### Terrain / Mobility Notes

Uses Cavalry B movement costs. Mounted armored profile.


### Mechanical Notes

- Special single-tier class with displayed level cap 30.
- Carries both armor and mounted/cavalry vulnerability semantics.
- Cannot use Master Seal for a direct promotion.
- Can use Second Seal according to special-class rules.
- Character-associated with Walhart and boss/SpotPass-style use.



## Soldier

### Metadata

| Property | Value |
|---|---|
| Tier | Special / NPC / Enemy |
| Internal Category | NPC/enemy class |
| Movement | 5 |
| Movement Type | Infantry B |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Enemy/NPC data only; not normally available to player units. |
| Internal Flags | special_class; npc_class; enemy_class; lance_access; no_player_reclass; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Lance | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 3 | 0 | 3 | 3 | 0 | 3 | 0 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 10 | 0 | 10 | 10 | 0 | 5 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 30 | 30 | 30 | 30 | 45 | 30 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| N/A | N/A | N/A | No class skills listed in the canonical class table. |


### Terrain / Mobility Notes

Uses Infantry B movement costs.


### Mechanical Notes

- NPC/enemy-only lance infantry class.
- Not part of normal playable class-change flow.
- Enemy instances may receive scripted skills independent of class skills.



## Merchant

### Metadata

| Property | Value |
|---|---|
| Tier | Special / NPC / Enemy |
| Internal Category | NPC/enemy utility class |
| Movement | 5 |
| Movement Type | Infantry B |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | NPC/enemy data only; not normally available to player units. |
| Internal Flags | special_class; npc_class; utility_class; lance_access; no_player_reclass; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Lance | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 3 | 0 | 2 | 2 | 0 | 4 | 1 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 20 | 20 | 20 | 20 | 30 | 20 | 20 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| N/A | N/A | N/A | No class skills listed in the canonical class table. |


### Terrain / Mobility Notes

Uses Infantry B movement costs.


### Mechanical Notes

- NPC/utility class used for merchant-style map entities.
- Not part of normal playable class-change flow.
- Player-facing shops and merchant behavior are map/entity systems, not class skills.



## Revenant

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Enemy / Monster |
| Internal Category | Enemy monster class |
| Movement | 5 |
| Movement Type | Infantry B |
| Vulnerability Group | Monster |
| Promotion Targets | N/A |
| Reclass Sources | Enemy data only; not normally available to player units. |
| Internal Flags | special_class; enemy_class; monster_class; risen_associated; natural_weapon_or_scripted_attack; no_player_reclass; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Monster Natural Weapon | 0 | Unranked | 0 | Unranked |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 30 | 20 | 25 | 25 | 30 | 30 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| N/A | N/A | N/A | No learnable class skills; enemy skill packages may assign weak/strong enemy skills. |


### Terrain / Mobility Notes

Uses Infantry B movement costs.


### Mechanical Notes

- Enemy monster/Risen-associated class.
- Not part of normal playable class-change flow.
- Canonical class table lists enemy skill package associations rather than class-learned skills.
- Unranked or natural weapon categories are encoded as Base WEXP 0 / Rank Unranked / Max WEXP 0 / Max Rank Unranked to preserve the required schema while reflecting that the class does not use standard WEXP rank progression for that category.



## Entombed

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Enemy / Monster |
| Internal Category | Enemy monster class |
| Movement | 6 |
| Movement Type | Infantry B |
| Vulnerability Group | Monster |
| Promotion Targets | N/A |
| Reclass Sources | Enemy data only; not normally available to player units. |
| Internal Flags | special_class; enemy_class; monster_class; risen_associated; natural_weapon_or_scripted_attack; no_player_reclass; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Monster Natural Weapon | 0 | Unranked | 0 | Unranked |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 3 | 1 | 2 | 2 | 0 | 2 | 1 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 40 | 30 | 35 | 35 | 45 | 35 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| N/A | N/A | N/A | No learnable class skills; enemy skill packages may assign weak/strong enemy skills. |


### Terrain / Mobility Notes

Uses Infantry B movement costs.


### Mechanical Notes

- Enemy monster/Risen-associated class.
- Not part of normal playable class-change flow.
- Higher cap profile than Revenant.
- Unranked or natural weapon categories are encoded as Base WEXP 0 / Rank Unranked / Max WEXP 0 / Max Rank Unranked to preserve the required schema while reflecting that the class does not use standard WEXP rank progression for that category.



## Grima

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Boss-only |
| Internal Category | Boss-only class |
| Movement | 0 |
| Movement Type | Infantry C |
| Vulnerability Group | Fell Dragon; Dragon |
| Promotion Targets | N/A |
| Reclass Sources | Boss data only; not available to player units. |
| Internal Flags | special_class; boss_only; fell_dragon; natural_weapon_or_scripted_attack; no_player_reclass; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Fell Dragon Natural Weapon | 0 | Unranked | 0 | Unranked |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 30 | 15 | 15 | 15 | 15 | 0 | 15 | 10 | 0 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 99 | 50 | 40 | 50 | 45 | 45 | 50 | 50 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| N/A | N/A | N/A | No class skills listed in the canonical class table; boss skills are instance/script-defined. |


### Terrain / Mobility Notes

Uses Infantry C terrain group for table compatibility, but map behavior is boss/script-defined and may ignore normal movement assumptions.


### Mechanical Notes

- Boss-only class.
- Not part of normal playable class-change flow.
- Vulnerability is represented as Fell Dragon plus Dragon for effectiveness modeling; exact effective-weapon exceptions must be handled by weapon/boss script data.
- Unranked or natural weapon categories are encoded as Base WEXP 0 / Rank Unranked / Max WEXP 0 / Max Rank Unranked to preserve the required schema while reflecting that the class does not use standard WEXP rank progression for that category.



## Mirage

### Metadata

| Property | Value |
|---|---|
| Tier | Special / Placeholder |
| Internal Category | Special placeholder class |
| Movement | 0 |
| Movement Type | Special |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Internal/placeholder data only; not normally available to player units. |
| Internal Flags | special_class; placeholder_class; no_player_reclass; no_master_seal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| N/A | 0 | Unranked | 0 | Unranked |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 20 | 20 | 20 | 20 | 30 | 20 | 20 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| N/A | N/A | N/A | No class skills listed in the canonical class table. |


### Terrain / Mobility Notes

Uses Special terrain group for table compatibility; actual use is placeholder/script-defined.


### Mechanical Notes

- Special placeholder class in class listings.
- Not part of normal playable class-change flow.
- Should not be treated as a normal combat class unless a mod or script explicitly uses it.
- Unranked or natural weapon categories are encoded as Base WEXP 0 / Rank Unranked / Max WEXP 0 / Max Rank Unranked to preserve the required schema while reflecting that the class does not use standard WEXP rank progression for that category.



## Outrealm Class

### Metadata

| Property | Value |
|---|---|
| Tier | Special / DLC Placeholder |
| Internal Category | DLC loading placeholder class |
| Movement | Variable |
| Movement Type | Variable |
| Vulnerability Group | Variable |
| Promotion Targets | N/A |
| Reclass Sources | Temporary class representation for DLC/Outrealm units when the actual DLC class/resource is unavailable or unresolved. |
| Internal Flags | special_class; dlc_placeholder; variable_stats; variable_weapon_access; no_standard_progression; should_resolve_to_actual_class |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Variable | 0 | Variable | 400 | Variable |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Variable | Variable | Variable | Variable | Variable | Variable | Variable | Variable | Variable |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| Variable | Variable | Variable | Variable | Variable | Variable | Variable | Variable |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| Variable | Variable | Variable | Variable | Variable | Variable | Variable | Variable |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Variable | Variable | Variable | Uses the stats, skills, and available weapons of the actual unresolved class/unit. |


### Terrain / Mobility Notes

Variable. Use the resolved class terrain group if available.


### Mechanical Notes

- Placeholder class rather than a normal mechanical class.
- Stats, growths, caps, weapons, skills, and mobility should be read from the actual class/unit once DLC data resolves.
- Fire Emblem Wiki describes Outrealm Class as using Tactician-like graphics while retaining actual unit/class mechanics.
- Rules engines should implement this as an alias/proxy state, not as an independent class with fixed stats.



---

# End of Phase 5 — Special / NPC / Enemy / DLC Classes
