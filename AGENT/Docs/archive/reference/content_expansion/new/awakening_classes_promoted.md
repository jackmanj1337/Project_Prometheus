> **Historical** — External Awakening reference corpus; not active Project Prometheus rules or public-pack content.

# Fire Emblem Awakening Technical Reference Corpus
# Promoted Classes

**File:** `awakening_classes_promoted.md`  
**Phase:** 4  
**Corpus Version:** `0.5.0-phase4`  
**Depends On:** `awakening_project_index.md`, `awakening_core_systems.md`, `awakening_lookup_tables.md`, `awakening_classes_base.md`  
**Scope:** Regular promoted/tier-2 classes only. DLC, special, boss-only, NPC-only, transformation, and other irregular classes are deferred to `awakening_classes_special.md`.

---

# Table of Contents

1. [Phase Boundary](#phase-boundary)
2. [Normalization Notes](#normalization-notes)
3. [Promoted Class Entries](#promoted-class-entries)

---

# Phase Boundary

This document includes the regular promoted-class set:

| Included Class Family | Included Here | Notes |
|---|---|---|
| Great Lord | Yes | Split into male/female definitions because mechanics differ. |
| Grandmaster | Yes | Universal definition. |
| Paladin | Yes | Universal definition. |
| Great Knight | Yes | Universal definition. |
| General | Yes | Universal definition. |
| Swordmaster | Yes | Universal definition. |
| Assassin | Yes | Universal definition. |
| Trickster | Yes | Universal definition. |
| Hero | Yes | Universal definition. |
| Bow Knight | Yes | Universal definition. |
| Warrior | Yes | Universal definition. |
| Berserker | Yes | Universal mechanics; vanilla access is male-gated through Barbarian access. |
| Sniper | Yes | Universal definition. |
| Falcon Knight | Yes | Universal mechanics; vanilla access is female-gated through Pegasus Knight access. |
| Dark Flier | Yes | Universal mechanics; vanilla access is female-gated through Pegasus Knight access. |
| Wyvern Lord | Yes | Universal definition. |
| Griffon Rider | Yes | Universal definition. |
| Valkyrie | Yes | Universal mechanics; vanilla access is female-gated through Troubadour access. |
| War Monk / War Cleric | Yes | Unified because mechanics are identical. |
| Sage | Yes | Universal definition. |
| Dark Knight | Yes | Universal definition. |
| Sorcerer | Yes | Universal definition. |

The following are intentionally deferred to Phase 5:

| Deferred Class | Reason |
|---|---|
| Lodestar | DLC/special class |
| Dread Fighter | DLC/special class |
| Bride | DLC/special class |
| Conqueror | Special / character-associated class |
| Villager | Special single-tier class |
| Dancer | Special single-tier class |
| Taguel | Transformation class |
| Manakete | Transformation class |
| Soldier | NPC/enemy class |
| Merchant | NPC/enemy class |
| Revenant | Enemy class |
| Entombed | Enemy class |
| Grima | Boss-only class |
| Outrealm Class | DLC/placeholder class |

---

# Normalization Notes

## Gender-Locked Class Handling

Gender-locked access is represented as an access legality flag unless class mechanics differ.

| Case | Corpus Handling |
|---|---|
| Great Lord male/female | Split definitions because bases and caps differ. |
| War Monk / War Cleric | Unified definition because listed mechanics are identical. |
| Falcon Knight / Dark Flier / Valkyrie | Universal mechanical definitions with vanilla access flags. |
| Berserker | Universal mechanical definition with vanilla access flag. |

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

Promotion and reclassing do not erase stored WEXP. Existing weapon types retain stored WEXP, while newly gained weapon types receive at least the class base WEXP.

## Stat Table Order

All class stat tables use:

```text
HP, STR, MAG, SKL, SPD, LCK, DEF, RES, MOV
```

Growth and cap tables omit MOV because movement does not grow by standard level-up mechanics.

## Promoted Level Rule

All regular promoted classes use:

```text
Promoted Internal Level = 20 + Displayed Level
```

Regular promoted displayed level range:

```text
1–20
```

## Luck

Class base Luck is `0` for all regular classes. Class growth contribution to Luck is also `0` for all listed classes.

---

# Promoted Class Entries


## Great Lord (Male)

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Personal promoted class |
| Movement | 6 |
| Movement Type | Special |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Lord (Male); Chrom personal promoted line; Second Seal access from promoted personal class state where legal. |
| Internal Flags | promoted_class; personal_class; male_variant; sword_access; lance_access; rapier_access; noble_rapier_access; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Lance | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 23 | 10 | 0 | 7 | 9 | 0 | 10 | 3 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 20 | 0 | 20 | 20 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 43 | 30 | 40 | 41 | 45 | 42 | 40 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Aether | 5 | Proc | Skill ÷ 2%; two-hit attack sequence with Sol effect then Luna effect. |
| Rightful King | 15 | Passive proc modifier | Adds +10 percentage points to user skill activation rates. |


### Terrain / Mobility Notes

Uses Special movement category. Infantry-style promoted personal class; receives normal terrain bonuses unless map/script overrides.


### Mechanical Notes

- Promoted form of Lord (Male).
- Mechanically distinct from Great Lord (Female) through bases and stat caps.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Lance access is gained on promotion.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Great Lord (Female)

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Personal promoted class |
| Movement | 6 |
| Movement Type | Special |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Lord (Female); Lucina personal promoted line; Second Seal access from promoted personal class state where legal. |
| Internal Flags | promoted_class; personal_class; female_variant; sword_access; lance_access; rapier_access; noble_rapier_access; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Lance | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 8 | 1 | 9 | 11 | 0 | 8 | 4 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 20 | 0 | 20 | 20 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 40 | 30 | 42 | 44 | 45 | 40 | 40 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Aether | 5 | Proc | Skill ÷ 2%; two-hit attack sequence with Sol effect then Luna effect. |
| Rightful King | 15 | Passive proc modifier | Adds +10 percentage points to user skill activation rates. |


### Terrain / Mobility Notes

Uses Special movement category. Infantry-style promoted personal class; receives normal terrain bonuses unless map/script overrides.


### Mechanical Notes

- Promoted form of Lord (Female).
- Mechanically distinct from Great Lord (Male) through bases and stat caps.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Lance access is gained on promotion.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Grandmaster

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class / Avatar line |
| Movement | 6 |
| Movement Type | Special |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Tactician; Avatar/Morgan promoted class access; Second Seal access from promoted Avatar-line class state where legal. |
| Internal Flags | promoted_class; regular_class; avatar_line; sword_access; tome_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Tome | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 7 | 6 | 7 | 7 | 0 | 7 | 5 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 15 | 15 | 15 | 15 | 0 | 10 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 40 | 40 | 40 | 40 | 45 | 40 | 40 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Ignis | 5 | Proc | Skill%; adds MAG ÷ 2 to physical attacks or STR ÷ 2 to magical attacks. |
| Rally Spectrum | 15 | Command | All non-HP/non-MOV stats +4 to allies within 3 tiles for one turn. |


### Terrain / Mobility Notes

Uses Special movement category. Infantry-style hybrid class.


### Mechanical Notes

- Promoted form of Tactician.
- Male and female Grandmaster mechanics are normalized into one universal definition.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Retains sword/tome dual access from Tactician.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Paladin

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 8 |
| Movement Type | Cavalry B |
| Vulnerability Group | Cavalry; mounted/beast-type effectiveness where applicable |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Cavalier; Second Seal from legal promoted class pools tied to Cavalier access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; mounted; sword_access; lance_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Lance | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 25 | 9 | 1 | 7 | 8 | 0 | 10 | 6 | 8 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 20 | 0 | 20 | 20 | 0 | 10 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 42 | 30 | 40 | 40 | 45 | 42 | 42 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Defender | 5 | Passive | All non-HP/non-MOV stats +1 while paired up. |
| Aegis | 15 | Proc defensive | Skill%; halves damage from bows, tomes, and dragonstones. |


### Terrain / Mobility Notes

Uses Cavalry B movement costs. High-mobility mounted ground class; subject to cavalry terrain restrictions and mounted effectiveness.


### Mechanical Notes

- Promoted option from Cavalier.
- Emphasizes mobility and balanced defenses relative to Great Knight.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Great Knight

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 7 |
| Movement Type | Cavalry B |
| Vulnerability Group | Armor; Cavalry; mounted/beast-type effectiveness where applicable |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Cavalier or Knight; Second Seal from legal promoted class pools tied to Cavalier/Knight access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; mounted; armored; sword_access; lance_access; axe_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Lance | 1 | E | 250 | A |
| Axe | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 26 | 11 | 0 | 6 | 5 | 0 | 14 | 1 | 7 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 25 | 0 | 15 | 15 | 0 | 15 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 48 | 20 | 34 | 37 | 45 | 48 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Luna | 5 | Proc | Skill%; ignores half of target DEF or RES for the attack. |
| Dual Guard+ | 15 | Passive support modifier | Adds +10 percentage points to Dual Guard rate. |


### Terrain / Mobility Notes

Uses Cavalry B movement costs but also carries armor vulnerability. Ground-mounted armored profile.


### Mechanical Notes

- Promoted option from Cavalier and Knight.
- Adds axe access relative to Cavalier promotion path.
- Carries both mounted and armor-class vulnerability semantics for rules-engine purposes.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## General

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 5 |
| Movement Type | Armor |
| Vulnerability Group | Armor |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Knight; Second Seal from legal promoted class pools tied to Knight access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; armored; lance_access; axe_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Lance | 1 | E | 250 | A |
| Axe | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 28 | 12 | 0 | 7 | 4 | 0 | 15 | 3 | 5 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 25 | 0 | 15 | 10 | 0 | 15 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 50 | 30 | 41 | 35 | 45 | 50 | 35 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Rally Defense | 5 | Command | DEF +4 to allies within 3 tiles for one turn. |
| Pavise | 15 | Proc defensive | Skill%; halves damage from swords, lances, axes, magical variants of those weapons, and beaststones. |


### Terrain / Mobility Notes

Uses Armor movement costs. Low-mobility armored promoted class with high defensive caps.


### Mechanical Notes

- Promoted option from Knight.
- Gains axe access on promotion.
- Armor vulnerability applies to armor-effective weapons.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Swordmaster

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 6 |
| Movement Type | Infantry C |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Myrmidon; Second Seal from legal promoted class pools tied to Myrmidon access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; infantry; sword_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 7 | 2 | 11 | 13 | 0 | 6 | 4 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 20 | 0 | 25 | 25 | 0 | 5 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 38 | 34 | 44 | 46 | 45 | 33 | 38 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Astra | 5 | Proc | Skill ÷ 2%; performs five consecutive half-damage strikes. |
| Swordfaire | 15 | Passive weapon modifier | STR +5 while equipped with a sword; MAG +5 when using Levin Sword-style magical sword behavior. |


### Terrain / Mobility Notes

Uses Infantry C movement costs. Advanced infantry movement profile.


### Mechanical Notes

- Promoted option from Myrmidon.
- Single-weapon promoted sword class with high speed/skill profile.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Assassin

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 6 |
| Movement Type | Infantry C |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Myrmidon or Thief; Second Seal from legal promoted class pools tied to Myrmidon/Thief access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; infantry; sword_access; bow_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Bow | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 21 | 8 | 0 | 13 | 12 | 0 | 5 | 1 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 20 | 0 | 30 | 25 | 0 | 5 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 40 | 30 | 48 | 46 | 45 | 31 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Lethality | 5 | Proc | Skill ÷ 4%; instantly defeats target if activation and hit resolution succeed and target is not immune. |
| Pass | 15 | Passive movement | Allows movement through enemy-occupied tiles where terrain and destination legality allow. |


### Terrain / Mobility Notes

Uses Infantry C movement costs. Advanced infantry movement profile.


### Mechanical Notes

- Promoted option from Myrmidon and Thief.
- Adds bow access relative to Myrmidon/Thief base classes.
- High SKL/SPD caps make it a strong proc and support-attack class.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Trickster

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 6 |
| Movement Type | Infantry C |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Thief; Second Seal from legal promoted class pools tied to Thief access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; infantry; sword_access; staff_access; lock_utility; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Staff | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 19 | 4 | 4 | 10 | 11 | 0 | 3 | 5 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 10 | 15 | 25 | 20 | 0 | 5 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 35 | 38 | 45 | 43 | 45 | 30 | 40 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Lucky Seven | 5 | Passive timed combat bonus | Hit and Avoid +20 through turn 7. |
| Acrobat | 15 | Passive movement | All traversable terrain costs 1 movement point. |


### Terrain / Mobility Notes

Uses Infantry C movement costs before Acrobat. With Acrobat active, all traversable terrain costs 1 movement point.


### Mechanical Notes

- Promoted option from Thief.
- Adds staff access while retaining sword access.
- Maintains thief-line utility identity through Locktouch inheritance if learned in base class.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Hero

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 6 |
| Movement Type | Infantry C |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Mercenary or Fighter; Second Seal from legal promoted class pools tied to Mercenary/Fighter access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; infantry; sword_access; axe_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Axe | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 22 | 8 | 1 | 11 | 10 | 0 | 8 | 3 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 20 | 0 | 25 | 20 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 42 | 30 | 46 | 42 | 45 | 40 | 36 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Sol | 5 | Proc | Skill%; heals user for half damage dealt. |
| Axebreaker | 15 | Passive breaker | Hit and Avoid +50 when enemy is equipped with an axe. |


### Terrain / Mobility Notes

Uses Infantry C movement costs. Advanced infantry movement profile.


### Mechanical Notes

- Promoted option from Mercenary and Fighter.
- Dual weapon access gives sword/axe weapon-triangle flexibility.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Bow Knight

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 8 |
| Movement Type | Cavalry B |
| Vulnerability Group | Cavalry; mounted/beast-type effectiveness where applicable |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Mercenary or Archer; Second Seal from legal promoted class pools tied to Mercenary/Archer access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; mounted; sword_access; bow_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Bow | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 24 | 8 | 0 | 10 | 10 | 0 | 6 | 2 | 8 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 20 | 0 | 25 | 20 | 0 | 5 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 40 | 30 | 43 | 41 | 45 | 35 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Rally Skill | 5 | Command | SKL +4 to allies within 3 tiles for one turn. |
| Bowbreaker | 15 | Passive breaker | Hit and Avoid +50 when enemy is equipped with a bow. |


### Terrain / Mobility Notes

Uses Cavalry B movement costs. High-mobility ground-mounted bow/sword class.


### Mechanical Notes

- Promoted option from Mercenary and Archer.
- Adds sword access relative to Archer and bow access relative to Mercenary.
- Bows normally attack at range 2 unless weapon-specific rules say otherwise.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Warrior

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 6 |
| Movement Type | Infantry C |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Fighter or Barbarian; Second Seal from legal promoted class pools tied to Fighter/Barbarian access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; infantry; axe_access; bow_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Axe | 1 | E | 250 | A |
| Bow | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 28 | 12 | 0 | 8 | 7 | 0 | 7 | 3 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 25 | 0 | 20 | 15 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 48 | 30 | 42 | 40 | 45 | 40 | 35 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Rally Strength | 5 | Command | STR +4 to allies within 3 tiles for one turn. |
| Counter | 15 | Passive damage reflection | Returns damage when attacked by adjacent enemy, except damage that KOs the user. |


### Terrain / Mobility Notes

Uses Infantry C movement costs. Advanced infantry movement profile.


### Mechanical Notes

- Promoted option from Fighter and Barbarian.
- Adds bow access to axe-specialist base lines.
- Class is available through male-gated base-class access in vanilla but represented as a universal mechanical class.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Berserker

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 6 |
| Movement Type | Infantry C |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Barbarian; Second Seal from legal promoted class pools tied to Barbarian access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; infantry; axe_access; male_access_in_vanilla; normalized_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Axe | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 30 | 13 | 0 | 5 | 11 | 0 | 5 | 1 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 25 | 0 | 15 | 20 | 0 | 5 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 50 | 30 | 35 | 44 | 45 | 34 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Wrath | 5 | Passive critical modifier | Critical +20 when under half HP. |
| Axefaire | 15 | Passive weapon modifier | STR +5 while equipped with an axe; MAG +5 when using Bolt Axe-style magical axe behavior. |


### Terrain / Mobility Notes

Uses Infantry C movement costs. Advanced infantry movement profile.


### Mechanical Notes

- Promoted option from Barbarian.
- Class is male-access in vanilla but normalized as a universal mechanical class because no separate female mechanical version exists.
- High STR cap and axe-only weapon identity.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Sniper

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 6 |
| Movement Type | Infantry C |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Archer; Second Seal from legal promoted class pools tied to Archer access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; infantry; bow_access; standard_2_range_physical; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Bow | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 7 | 1 | 12 | 9 | 0 | 10 | 3 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 15 | 0 | 30 | 15 | 0 | 15 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 41 | 30 | 48 | 40 | 45 | 40 | 31 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Hit Rate +20 | 5 | Passive combat bonus | Hit +20. |
| Bowfaire | 15 | Passive weapon modifier | STR +5 while equipped with a bow. |


### Terrain / Mobility Notes

Uses Infantry C movement costs. Advanced infantry movement profile.


### Mechanical Notes

- Promoted option from Archer.
- Bow-only promoted class with high SKL cap.
- Bows normally attack at range 2 unless weapon-specific rules say otherwise.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Falcon Knight

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 8 |
| Movement Type | Flier |
| Vulnerability Group | Flying; mounted/beast-type effectiveness where applicable |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Pegasus Knight; Second Seal from legal promoted class pools tied to Pegasus Knight access; inherited class-set access where legal or replaced if gender-illegal. |
| Internal Flags | promoted_class; regular_class; flying; lance_access; staff_access; female_access_in_vanilla; normalized_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Lance | 1 | E | 250 | A |
| Staff | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 6 | 3 | 10 | 11 | 0 | 6 | 9 | 8 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 15 | 10 | 25 | 25 | 0 | 5 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 38 | 35 | 45 | 44 | 45 | 33 | 40 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Rally Speed | 5 | Command | SPD +4 to allies within 3 tiles for one turn. |
| Lancefaire | 15 | Passive weapon modifier | STR +5 while equipped with a lance; MAG +5 when using Shockstick-style magical lance behavior. |


### Terrain / Mobility Notes

Flying movement. Ignores most ground movement costs; vulnerable to flying-effective attacks. Terrain defensive bonuses should follow flying terrain rules.


### Mechanical Notes

- Promoted option from Pegasus Knight.
- Class is female-access in vanilla but normalized as a universal mechanical class because no separate male mechanical version exists.
- Adds staff access on promotion.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Dark Flier

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 8 |
| Movement Type | Flier |
| Vulnerability Group | Flying; mounted/beast-type effectiveness where applicable |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Pegasus Knight; Second Seal from legal promoted class pools tied to Pegasus Knight access; inherited class-set access where legal or replaced if gender-illegal. |
| Internal Flags | promoted_class; regular_class; flying; lance_access; tome_access; female_access_in_vanilla; normalized_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Lance | 1 | E | 250 | A |
| Tome | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 19 | 5 | 6 | 8 | 10 | 0 | 5 | 9 | 8 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 10 | 15 | 20 | 20 | 0 | 5 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 36 | 42 | 41 | 42 | 45 | 32 | 41 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Rally Movement | 5 | Command | MOV +1 to allies within 3 tiles for one turn. |
| Galeforce | 15 | Passive action economy | Allows one additional full action after defeating an enemy during the user's turn; once per turn. |


### Terrain / Mobility Notes

Flying movement. Ignores most ground movement costs; vulnerable to flying-effective attacks. Terrain defensive bonuses should follow flying terrain rules.


### Mechanical Notes

- Promoted option from Pegasus Knight.
- Class is female-access in vanilla but normalized as a universal mechanical class because no separate male mechanical version exists.
- Adds tome access and supports hybrid physical/magical combat.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Wyvern Lord

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 8 |
| Movement Type | Flier |
| Vulnerability Group | Flying; Dragon |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Wyvern Rider; Second Seal from legal promoted class pools tied to Wyvern Rider access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; flying; dragon_mount; lance_access; axe_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Lance | 1 | E | 250 | A |
| Axe | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 24 | 11 | 0 | 8 | 7 | 0 | 11 | 3 | 8 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 30 | 0 | 15 | 15 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 46 | 30 | 38 | 38 | 45 | 46 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Quick Burn | 5 | Passive timed combat bonus | Hit and Avoid +15 at chapter start; bonus decreases by 1 each turn. |
| Swordbreaker | 15 | Passive breaker | Hit and Avoid +50 when enemy is equipped with a sword. |


### Terrain / Mobility Notes

Flying movement. Ignores most ground movement costs; vulnerable to flying-effective attacks and dragon-effective attacks where applicable.


### Mechanical Notes

- Promoted option from Wyvern Rider.
- Gains lance access on promotion while retaining axe access.
- High STR/DEF flying class profile.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Griffon Rider

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 8 |
| Movement Type | Flier |
| Vulnerability Group | Flying; mounted/beast-type effectiveness where applicable |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Wyvern Rider; Second Seal from legal promoted class pools tied to Wyvern Rider access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; flying; axe_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Axe | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 22 | 9 | 0 | 10 | 9 | 0 | 8 | 3 | 8 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 25 | 0 | 20 | 20 | 0 | 5 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 40 | 30 | 43 | 41 | 45 | 40 | 30 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Deliverer | 5 | Passive movement | MOV +2 while paired up. |
| Lancebreaker | 15 | Passive breaker | Hit and Avoid +50 when enemy is equipped with a lance. |


### Terrain / Mobility Notes

Flying movement. Ignores most ground movement costs; vulnerable to flying-effective attacks.


### Mechanical Notes

- Promoted option from Wyvern Rider.
- Axe-only flying promoted class with mobility emphasis.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Valkyrie

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 8 |
| Movement Type | Cavalry B |
| Vulnerability Group | Cavalry; mounted/beast-type effectiveness where applicable |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Troubadour; Second Seal from legal promoted class pools tied to Troubadour access; inherited class-set access where legal or replaced if gender-illegal. |
| Internal Flags | promoted_class; regular_class; mounted; tome_access; staff_access; female_access_in_vanilla; normalized_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Tome | 1 | E | 250 | A |
| Staff | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 19 | 0 | 5 | 4 | 8 | 0 | 3 | 8 | 8 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 0 | 20 | 10 | 20 | 0 | 5 | 15 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 30 | 42 | 38 | 43 | 45 | 30 | 45 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Rally Resistance | 5 | Command | RES +4 to allies within 3 tiles for one turn. |
| Dual Support+ | 15 | Passive support modifier | Increases support bonus effect. |


### Terrain / Mobility Notes

Uses Cavalry B movement costs. High-mobility mounted tome/staff class.


### Mechanical Notes

- Promoted option from Troubadour.
- Class is female-access in vanilla but normalized as a universal mechanical class because no separate male mechanical version exists.
- Adds tome access to staff-mounted line.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## War Monk / War Cleric

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 6 |
| Movement Type | Mage |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Priest / Cleric or Troubadour; Second Seal from legal promoted class pools tied to Priest/Cleric/Troubadour access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; infantry; axe_access; staff_access; gender_name_alias; normalized_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Axe | 1 | E | 250 | A |
| Staff | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 24 | 5 | 5 | 4 | 6 | 0 | 6 | 6 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 15 | 15 | 10 | 15 | 0 | 10 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 40 | 40 | 38 | 41 | 45 | 38 | 43 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Rally Luck | 5 | Command | LCK +8 to allies within 3 tiles for one turn. |
| Renewal | 15 | Passive healing | Recover 30% HP at the start of the user's turn. |


### Terrain / Mobility Notes

Uses Mage movement costs. Infantry healer-combat hybrid profile.


### Mechanical Notes

- Promoted option from Priest / Cleric and Troubadour.
- War Monk and War Cleric are unified because listed mechanics are identical; name differs by gender presentation.
- Adds axe combat to staff line.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Sage

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 6 |
| Movement Type | Mage |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Mage or Priest / Cleric; Second Seal from legal promoted class pools tied to Mage/Priest/Cleric access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; infantry; tome_access; staff_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Tome | 1 | E | 250 | A |
| Staff | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 1 | 7 | 5 | 7 | 0 | 4 | 5 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 0 | 20 | 20 | 20 | 0 | 5 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 30 | 46 | 43 | 42 | 45 | 31 | 40 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Rally Magic | 5 | Command | MAG +4 to allies within 3 tiles for one turn. |
| Tomefaire | 15 | Passive weapon modifier | MAG +5 while equipped with a tome. |


### Terrain / Mobility Notes

Uses Mage movement costs. Infantry tome/staff promoted class.


### Mechanical Notes

- Promoted option from Mage and Priest / Cleric.
- Adds staff access to Mage or tome access to Priest / Cleric path.
- High MAG cap and standard tome/staff support profile.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Dark Knight

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 8 |
| Movement Type | Cavalry B |
| Vulnerability Group | Cavalry; mounted/beast-type effectiveness where applicable |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Mage or Dark Mage; Second Seal from legal promoted class pools tied to Mage/Dark Mage access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; mounted; sword_access; tome_access; no_native_dark_tome_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Sword | 1 | E | 250 | A |
| Tome | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 25 | 4 | 5 | 6 | 5 | 0 | 9 | 5 | 8 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 15 | 15 | 15 | 15 | 0 | 10 | 5 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 38 | 41 | 40 | 40 | 45 | 42 | 38 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Slow Burn | 5 | Passive timed combat bonus | Hit and Avoid increase by 1 each turn, up to turn 15. |
| Lifetaker | 15 | Passive post-kill healing | Recover 50% HP after defeating an enemy during the user's turn. |


### Terrain / Mobility Notes

Uses Cavalry B movement costs. Mounted hybrid sword/tome class.


### Mechanical Notes

- Promoted option from Mage and Dark Mage.
- Does not natively preserve Dark Tome access from Dark Mage; dark magic requires Shadowgift or other explicit permission.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



## Sorcerer

### Metadata

| Property | Value |
|---|---|
| Tier | Promoted / Tier 2 |
| Internal Category | Regular promoted class |
| Movement | 6 |
| Movement Type | Mage |
| Vulnerability Group | None |
| Promotion Targets | N/A |
| Reclass Sources | Promotion from Dark Mage; Second Seal from legal promoted class pools tied to Dark Mage access; inherited class-set access where legal. |
| Internal Flags | promoted_class; regular_class; infantry; tome_access; dark_magic_access; gender_universal_mechanics; terminal_promotion |


### Weapon Proficiency

| Weapon | Base WEXP | Rank | Max WEXP | Max Rank |
|---|---:|---|---:|---|
| Tome | 1 | E | 250 | A |
| Dark Tome | 1 | E | 250 | A |


### Base Stats

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 23 | 2 | 6 | 4 | 4 | 0 | 7 | 7 | 6 |


### Growth Modifiers

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 0 | 20 | 15 | 15 | 0 | 10 | 10 |


### Stat Caps

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 80 | 30 | 44 | 38 | 40 | 45 | 41 | 44 |


### Skills

| Skill | Unlock Level | Type | Notes |
|---|---:|---|---|
| Vengeance | 5 | Proc | Skill × 2%; adds `(MaxHP - CurrentHP) ÷ 2` damage. |
| Tomebreaker | 15 | Passive breaker | Hit and Avoid +50 when enemy is equipped with a tome. |


### Terrain / Mobility Notes

Uses Mage movement costs. Infantry dark-magic promoted class.


### Mechanical Notes

- Promoted option from Dark Mage.
- Retains standard tome access and native dark magic permission.
- Dark Tome is represented separately for simulator clarity even though in-game UI commonly displays tome rank plus dark access.
- Displayed promoted level range is 1–20; promoted internal level uses `20 + Displayed Level`.
- Vanilla Awakening uses A as the normal attainable weapon-rank ceiling; this corpus stores active class max as 250/A while preserving the global WEXP cap convention from Phase 0–2.



---

# End of Phase 4 — Promoted Classes
