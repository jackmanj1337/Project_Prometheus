> **Historical** — External Awakening reference corpus; not active Project Prometheus rules or public-pack content.

# Fire Emblem Awakening Technical Reference Corpus
# Archetype Templates

**File:** `awakening_archetypes.md`  
**Phase:** 10  
**Corpus Version:** `0.11.0-phase10`  
**Depends On:** `awakening_project_index.md`, `awakening_core_systems.md`, `awakening_lookup_tables.md`, `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_classes_special.md`, `awakening_skills.md`, `awakening_weapons_physical.md`, `awakening_weapons_magic.md`, `awakening_items.md`  
**Scope:** Simulation-ready generic growth packages and role templates.

---

# Table of Contents

1. [Phase Boundary](#phase-boundary)
2. [Archetype Normalization Rules](#archetype-normalization-rules)
3. [Schema](#schema)
4. [Archetype Entries](#archetype-entries)
5. [Archetype Count Audit](#archetype-count-audit)

---

# Phase Boundary

This document defines generic simulation archetypes.

It does **not** replace:

| Data Type | Canonical File |
|---|---|
| Class growth modifiers | `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_classes_special.md` |
| Character growths | Future character corpus / external unit data |
| Enemy autolevel constants | `awakening_core_systems.md`, `awakening_appendices.md` |
| Skill mechanics | `awakening_skills.md` |
| Weapon stats | `awakening_weapons_physical.md`, `awakening_weapons_magic.md` |

The archetypes below are reusable templates for:

- simulator-generated generic units
- enemy generation
- balance testing
- rules-engine fixtures
- RAG retrieval tags
- synthetic character modeling
- benchmark combat profiles
- modding prototypes

---

# Archetype Normalization Rules

## Growth Package Meaning

Each archetype growth table defines a **unit growth component**.

The simulator must still apply class growths:

```text
FinalGrowth =
ArchetypeUnitGrowth + ClassGrowth
```

Example:

```text
FinalSTRGrowth =
ArchetypeSTRGrowth + ClassSTRGrowth
```

## Growth Scale

All growth values are percentages.

```text
35 = 35%
100 = 100%
```

Values may exceed 100 after class growths, skills, or modifiers.

## Base Stat Template Meaning

Base stat templates are recommended level-1 generic unit starting points before chapter scaling, autoleveling, difficulty modifiers, Pair Up, weapons, or skills.

```text
GeneratedBaseStat =
ArchetypeBaseStat
+ ClassBaseAdjustment
+ DifficultyAdjustment
+ AutolevelGain
```

## Cap Bias Meaning

Cap bias values are qualitative generator hints, not numeric caps.

Actual caps are class-defined:

```text
FinalStatCap =
ClassStatCap + UnitCapModifier
```

## Luck Handling

Unlike class growth modifiers, archetype unit growths include Luck.

## AI Role Handling

AI role fields are deterministic intent labels. They do not override map scripts.

Recommended AI priority model:

```text
ScriptedAI > BossAI > ArchetypeAI > GenericClassAI
```

---

# Schema

Each archetype uses this schema:

```yaml
archetype:
  id: string
  role_category: string
  recommended_class_families: list|string
  weapon_profile: list|string
  movement_profile: string
  vulnerability_profile: string
  ai_role: string
  generation_scope: string
  internal_tags: list
  growth_package:
    hp: integer
    str: integer
    mag: integer
    skl: integer
    spd: integer
    lck: integer
    def: integer
    res: integer
  base_stat_template:
    hp: integer
    str: integer
    mag: integer
    skl: integer
    spd: integer
    lck: integer
    def: integer
    res: integer
    mov: integer
  cap_bias:
    hp: string
    str: string
    mag: string
    skl: string
    spd: string
    lck: string
    def: string
    res: string
  skill_package_bias: string
  mechanical_notes: list
```

---

# Archetype Entries


## Lord

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_LORD |
| Role Category | Balanced protagonist / command unit |
| Recommended Class Families | Lord, Great Lord, Lodestar-style personal classes, Grandmaster-adjacent hybrid leadership builds |
| Weapon Profile | Sword primary; optional lance on promotion; optional personal sword access |
| Movement Profile | Infantry / Special |
| Vulnerability Profile | None by default |
| AI Role | Balanced frontliner; prioritizes safe kills, support adjacency, and aura coverage |
| Generation Scope | Playable lead, plot unit, lord-style boss mirror, generic protagonist simulation |
| Internal Tags | balanced; leadership; sword; support-aura; personal-class |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 35 | 15 | 35 | 35 | 45 | 30 | 25 | 265 | 135 | 40 | 100 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 6 | 2 | 6 | 7 | 5 | 6 | 2 | 5 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium | Medium | Low/Medium | Medium/High | Medium/High | High | Medium | Medium |


### Skill Package Bias

Dual Strike+, Charm, Aether-like proc, Rightful King-like proc modifier, leadership aura


### Mechanical Notes

- Use for a unit intended to remain relevant across the whole campaign without extreme specialization.
- Pairs well with class growths that add STR, SKL, SPD, and DEF.
- For lord-like enemies, increase HP/DEF and reduce LCK if a less player-like profile is desired.



## Cavalier

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_CAVALIER |
| Role Category | Mounted balanced physical unit |
| Recommended Class Families | Cavalier, Paladin, Great Knight, Bow Knight, Dark Knight variants |
| Weapon Profile | Sword/lance baseline; optional bow, axe, or tome after promotion/reclass |
| Movement Profile | Cavalry |
| Vulnerability Profile | Cavalry / mounted effectiveness |
| AI Role | Mobile engagement unit; prioritizes reachable kills, rescue pressure, and formation support |
| Generation Scope | Playable generic, enemy generic, reinforcement, skirmish unit |
| Internal Tags | mounted; balanced; physical; mobility; weapon-triangle |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 35 | 10 | 30 | 30 | 35 | 30 | 20 | 240 | 125 | 30 | 100 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 7 | 1 | 6 | 6 | 4 | 7 | 1 | 7 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium/High | Medium | Low | Medium | Medium | Medium | Medium/High | Low/Medium |


### Skill Package Bias

Discipline, Outdoor Fighter, Defender, Aegis, mobility/support skills


### Mechanical Notes

- Use as the default all-purpose mounted template.
- For Paladin-like simulations, raise RES and SPD slightly.
- For Great Knight-like simulations, raise STR/DEF and lower SPD/RES.



## Knight

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_KNIGHT |
| Role Category | Armored physical tank |
| Recommended Class Families | Knight, General, Great Knight armor-leaning builds |
| Weapon Profile | Lance baseline; axe access after promotion in General/Great Knight routes |
| Movement Profile | Armor / low-mobility ground |
| Vulnerability Profile | Armor; optionally cavalry if mounted promoted variant |
| AI Role | Chokepoint holder; prioritizes blocking terrain, protecting fragile allies, and enemy-phase durability |
| Generation Scope | Playable generic, enemy formation anchor, fortress guard, boss guard |
| Internal Tags | armor; tank; physical-defense; slow; chokepoint |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 40 | 5 | 25 | 15 | 25 | 45 | 15 | 230 | 125 | 20 | 120 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 22 | 8 | 0 | 5 | 3 | 3 | 11 | 1 | 4 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| High | High | Low | Medium | Low | Medium | Very High | Low |


### Skill Package Bias

Defense +2, Indoor Fighter, Rally Defense, Pavise, guard/tank skills


### Mechanical Notes

- Use for enemy wall units and defensive objectives.
- Low SPD should create follow-up vulnerability unless the unit is heavily overleveled.
- On Lunatic-style enemies, combine with Pavise/Pavise+ or forged weapons for threat without high mobility.



## Fighter

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_FIGHTER |
| Role Category | High-HP physical brawler |
| Recommended Class Families | Fighter, Warrior, Hero physical routes |
| Weapon Profile | Axe primary; optional bow or sword after promotion |
| Movement Profile | Infantry B / Infantry C after promotion |
| Vulnerability Profile | None by default |
| AI Role | Aggressive melee unit; prioritizes high-damage engagements and trades accuracy for power |
| Generation Scope | Playable generic, brigand enemy, reinforcement, physical boss subordinate |
| Internal Tags | axe; high-hp; physical; strength; bruiser |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 60 | 45 | 5 | 30 | 25 | 30 | 30 | 15 | 240 | 130 | 20 | 105 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 22 | 9 | 0 | 5 | 5 | 3 | 5 | 0 | 5 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| High | High | Low | Medium | Medium/Low | Medium | Medium | Low |


### Skill Package Bias

HP +5, Zeal, Rally Strength, Counter, axe-oriented passives


### Mechanical Notes

- Use when the unit should hit hard but remain vulnerable to magic and evasion problems.
- Warrior variant increases ranged threat through bows.
- Hero variant reduces raw HP/STR bias and improves SKL/SPD consistency.



## Barbarian

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_BARBARIAN |
| Role Category | Fast offensive axe raider |
| Recommended Class Families | Barbarian, Berserker, Warrior raider variants |
| Weapon Profile | Axe primary |
| Movement Profile | Infantry B / Infantry C after promotion |
| Vulnerability Profile | None by default |
| AI Role | Aggressive raider; prioritizes exposed targets, villages/chests if scripted, and high-crit attacks |
| Generation Scope | Enemy bandit, playable high-risk attacker, skirmish raider, ambush reinforcement |
| Internal Tags | axe; crit; speed; low-defense; raider |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 65 | 45 | 0 | 25 | 35 | 25 | 20 | 10 | 225 | 125 | 10 | 95 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 23 | 9 | 0 | 4 | 8 | 2 | 3 | 0 | 5 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| High | Very High | Low | Low/Medium | High | Medium | Low | Low |


### Skill Package Bias

Despoil, Gamble, Wrath, Axefaire, crit-oriented weapon packages


### Mechanical Notes

- Use for high-variance axe enemies or playable glassy strength units.
- Pairs well with Killer Axe, Gamble, and Wrath-style critical packages.
- Keep HIT modest unless intentionally building a high-pressure Lunatic-style threat.



## Mercenary

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_MERCENARY |
| Role Category | Reliable physical infantry |
| Recommended Class Families | Mercenary, Hero, Bow Knight sword routes |
| Weapon Profile | Sword primary; optional axe or bow after promotion |
| Movement Profile | Infantry A / Infantry C after promotion |
| Vulnerability Profile | None by default |
| AI Role | Reliable engagement unit; prioritizes accurate combat and sustainable enemy-phase trades |
| Generation Scope | Playable generic, enemy mercenary, hired guard, skirmish infantry |
| Internal Tags | sword; reliable; balanced; skill; durability |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 35 | 5 | 40 | 35 | 35 | 30 | 20 | 250 | 140 | 25 | 100 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 6 | 0 | 8 | 7 | 4 | 5 | 1 | 5 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium/High | Medium/High | Low | High | Medium/High | Medium | Medium | Low/Medium |


### Skill Package Bias

Armsthrift, Patience, Sol, Axebreaker, reliability/passive sustain


### Mechanical Notes

- Use as the baseline competent physical infantry archetype.
- Hero variant emphasizes sustain and dual-weapon flexibility.
- Bow Knight variant trades infantry terrain identity for mobility.



## Hero

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_HERO |
| Role Category | Sustaining promoted physical infantry |
| Recommended Class Families | Hero, Mercenary-to-Hero, Fighter-to-Hero |
| Weapon Profile | Sword and axe |
| Movement Profile | Infantry C |
| Vulnerability Profile | None by default |
| AI Role | Frontline sustain unit; prioritizes trades where Sol or high durability improves survival |
| Generation Scope | Playable promoted generic, enemy elite infantry, boss lieutenant |
| Internal Tags | promoted; sword; axe; sustain; balanced-frontline |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 55 | 40 | 5 | 45 | 35 | 35 | 35 | 20 | 270 | 155 | 25 | 110 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 25 | 10 | 1 | 11 | 10 | 5 | 8 | 3 | 6 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| High | High | Low | Very High | High | Medium/High | High | Medium |


### Skill Package Bias

Sol, Axebreaker, Patience, Armsthrift, weapon-breaker packages


### Mechanical Notes

- Use as a promoted archetype for sustained enemy-phase performance.
- Compared with Mercenary, raise HP/STR/SKL/DEF and broaden weapon access.
- Works well as a player-facing generic partner or enemy elite.



## Myrmidon

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_MYRMIDON |
| Role Category | Fast sword evasion unit |
| Recommended Class Families | Myrmidon, Swordmaster, Assassin |
| Weapon Profile | Sword primary |
| Movement Profile | Infantry A / Infantry C after promotion |
| Vulnerability Profile | None by default |
| AI Role | Evasion duelist; prioritizes doubling and high-avoid engagements |
| Generation Scope | Playable generic, enemy swordfighter, duel boss, skirmish unit |
| Internal Tags | sword; speed; avoid; skill; low-defense |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 30 | 10 | 45 | 50 | 40 | 20 | 20 | 255 | 145 | 30 | 80 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 17 | 5 | 1 | 9 | 10 | 5 | 4 | 1 | 5 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium/Low | Medium | Low/Medium | High | Very High | High | Low | Medium/Low |


### Skill Package Bias

Avoid +10, Vantage, Astra, Swordfaire, crit/evasion packages


### Mechanical Notes

- Use when SPD and SKL should define the unit more than raw STR.
- Avoid-focused enemies can become frustrating if terrain and breaker skills are stacked; tune HIT carefully.
- Assassin variant adds bow utility and Lethality-style lethality pressure.



## Swordmaster

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_SWORDMASTER |
| Role Category | Promoted speed/skill duelist |
| Recommended Class Families | Swordmaster, high-speed sword personal classes |
| Weapon Profile | Sword only |
| Movement Profile | Infantry C |
| Vulnerability Profile | None by default |
| AI Role | Duelist elite; targets enemies it can double and crit while avoiding heavy retaliation |
| Generation Scope | Playable promoted generic, enemy elite swordfighter, duel boss |
| Internal Tags | promoted; sword; high-speed; high-skill; crit |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 35 | 10 | 55 | 55 | 40 | 20 | 25 | 285 | 165 | 35 | 90 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 22 | 8 | 2 | 12 | 13 | 6 | 6 | 4 | 6 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium | Medium | Low/Medium | Very High | Very High | High | Low/Medium | Medium |


### Skill Package Bias

Astra, Swordfaire, Vantage, Avoid +10, high-crit sword packages


### Mechanical Notes

- Use as the promoted expression of the Myrmidon template.
- Damage should come from doubling, criticals, weapon quality, and proc skills rather than raw STR alone.
- Avoid excessive DEF growth unless intentionally creating a boss variant.



## Archer

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_ARCHER |
| Role Category | Accurate ranged physical unit |
| Recommended Class Families | Archer, Sniper, Bow Knight |
| Weapon Profile | Bow primary |
| Movement Profile | Infantry A / Infantry C or Cavalry B after promotion |
| Vulnerability Profile | None by default |
| AI Role | Ranged pressure unit; prioritizes safe 2-range attacks and flying-effective targets |
| Generation Scope | Playable generic, enemy backliner, anti-flier reinforcement |
| Internal Tags | bow; ranged; anti-flier; skill; accuracy |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 35 | 5 | 50 | 30 | 35 | 25 | 15 | 240 | 140 | 20 | 85 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 6 | 0 | 8 | 6 | 4 | 5 | 1 | 5 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium | Medium/High | Low | Very High | Medium | Medium | Medium | Low |


### Skill Package Bias

Skill +2, Prescience, Hit Rate +20, Bowfaire, Bowbreaker


### Mechanical Notes

- Use for enemies that pressure fliers and force enemy-phase positioning.
- Bow lock should be preserved unless using Bow Knight or special weapons.
- For Sniper, increase SKL/STR/DEF and keep MOV moderate.



## Mage

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_MAGE |
| Role Category | Standard offensive magic unit |
| Recommended Class Families | Mage, Sage, Dark Knight magic route |
| Weapon Profile | Tome primary; staff after Sage promotion |
| Movement Profile | Mage / Infantry magic; optional cavalry after Dark Knight |
| Vulnerability Profile | None by default |
| AI Role | Magical backliner; prioritizes low-RES targets and safe 1–2 range engagements |
| Generation Scope | Playable generic, enemy mage, reinforcement, magic boss subordinate |
| Internal Tags | magic; tome; low-defense; ranged; resistance-targeting |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 5 | 45 | 35 | 35 | 35 | 15 | 35 | 240 | 90 | 80 | 85 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 17 | 0 | 6 | 4 | 5 | 4 | 2 | 4 | 5 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Low/Medium | Low | Very High | High | High | Medium | Low | High |


### Skill Package Bias

Magic +2, Focus, Rally Magic, Tomefaire, elemental tome packages


### Mechanical Notes

- Use as the default offensive magic template.
- Sage variant raises MAG/SKL/RES and adds staff utility.
- Dark Knight variant raises HP/DEF/STR and adds mobility at the cost of pure magical ceiling.



## Dark Mage

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_DARK_MAGE |
| Role Category | Bulky debuff magic unit |
| Recommended Class Families | Dark Mage, Sorcerer, Dark Knight dark-mage route |
| Weapon Profile | Tome and dark tome access where legal |
| Movement Profile | Mage / Infantry magic; optional cavalry through Dark Knight |
| Vulnerability Profile | None by default |
| AI Role | Debuff caster; prioritizes Nosferatu sustain, enemy debuff aura positioning, and high-threat magic engagements |
| Generation Scope | Playable generic, enemy dark mage, elite caster, sorcerer boss |
| Internal Tags | dark-magic; debuff; sustain; bulk; tome |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 10 | 40 | 30 | 25 | 25 | 30 | 35 | 245 | 95 | 75 | 115 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 1 | 5 | 3 | 4 | 2 | 5 | 5 | 5 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| High | Low | High | Medium | Medium/Low | Medium/Low | Medium/High | High |


### Skill Package Bias

Hex, Anathema, Vengeance, Tomebreaker, Nosferatu/dark-magic packages


### Mechanical Notes

- Use for casters who should be harder to remove than normal mages.
- Nosferatu access dramatically changes durability; flag it explicitly in loadout generation.
- Vengeance scales with missing HP, so bulk and HP should be high enough to survive retaliation.



## Cleric

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_CLERIC |
| Role Category | Foot staff support / healer |
| Recommended Class Families | Priest, Cleric, Sage, War Monk, War Cleric |
| Weapon Profile | Staff primary; tome or axe after promotion depending on route |
| Movement Profile | Mage / Infantry support |
| Vulnerability Profile | None by default |
| AI Role | Healer/support unit; prioritizes healing, rescue utility, rally, and survival positioning |
| Generation Scope | Playable healer, NPC ally, enemy support unit, staff reinforcement |
| Internal Tags | staff; healer; support; low-offense; resistance |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 10 | 40 | 30 | 30 | 45 | 15 | 45 | 250 | 85 | 85 | 95 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 17 | 0 | 5 | 3 | 4 | 5 | 2 | 6 | 5 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Low/Medium | Low/Medium | High | Medium | Medium | High | Low | High |


### Skill Package Bias

Miracle, Healtouch, Rally Luck, Renewal, staff utility packages


### Mechanical Notes

- Use for units whose primary role is action economy and sustain rather than damage.
- War Cleric/War Monk variants should add STR/DEF and axe access.
- Sage variants should add MAG/SKL and tome access.



## Troubadour

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_TROUBADOUR |
| Role Category | Mounted healer / magical support |
| Recommended Class Families | Troubadour, Valkyrie |
| Weapon Profile | Staff primary; tome after Valkyrie promotion |
| Movement Profile | Cavalry |
| Vulnerability Profile | Cavalry / mounted effectiveness |
| AI Role | Mobile support unit; prioritizes healing high-value allies, rescue positioning, and avoiding physical exposure |
| Generation Scope | Playable healer, enemy staff support, mobile rescue/heal reinforcement |
| Internal Tags | staff; mounted; support; resistance; mobility |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 5 | 40 | 25 | 35 | 45 | 15 | 50 | 250 | 80 | 90 | 100 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 17 | 0 | 4 | 3 | 6 | 5 | 1 | 6 | 7 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Low/Medium | Low | High | Medium | High | High | Low | Very High |


### Skill Package Bias

Resistance +2, Demoiselle, Rally Resistance, Dual Support+, staff and support packages


### Mechanical Notes

- Use when healer mobility is more important than raw durability.
- Enemy Troubadours should have conservative AI to avoid suicide charges.
- Valkyrie variant adds offensive tome pressure and high RES.



## Pegasus

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_PEGASUS |
| Role Category | Fast flying lance unit |
| Recommended Class Families | Pegasus Knight, Falcon Knight, Dark Flier |
| Weapon Profile | Lance primary; staff or tome after promotion |
| Movement Profile | Flying |
| Vulnerability Profile | Flying; mounted/beast effectiveness where applicable |
| AI Role | Flier skirmisher; prioritizes mobility, rescue pressure, anti-isolated-target attacks, and retreat routes |
| Generation Scope | Playable flier, enemy flier, reinforcement, objective pressure unit |
| Internal Tags | flying; lance; speed; resistance; low-defense |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 30 | 20 | 40 | 45 | 40 | 20 | 35 | 270 | 135 | 55 | 95 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 17 | 5 | 2 | 7 | 8 | 5 | 4 | 6 | 7 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium/Low | Medium | Medium | High | Very High | High | Low | High |


### Skill Package Bias

Speed +2, Relief, Rally Speed, Lancefaire, Rally Movement, Galeforce


### Mechanical Notes

- Use for high mobility with clear bow/wind vulnerability.
- Falcon Knight variant emphasizes support and staff utility.
- Dark Flier variant emphasizes magic access and Galeforce-style action economy.



## Falcon Knight

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_FALCON_KNIGHT |
| Role Category | Promoted flying support lancer |
| Recommended Class Families | Falcon Knight |
| Weapon Profile | Lance and staff |
| Movement Profile | Flying |
| Vulnerability Profile | Flying; mounted/beast effectiveness where applicable |
| AI Role | Mobile support flier; heals or rallies when useful, otherwise targets fragile enemies with lances |
| Generation Scope | Playable promoted flier, enemy elite flier, rescue/heal reinforcement |
| Internal Tags | promoted; flying; lance; staff; speed; resistance |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 35 | 25 | 45 | 45 | 40 | 20 | 40 | 295 | 145 | 65 | 105 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 22 | 7 | 4 | 10 | 11 | 6 | 6 | 9 | 8 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium | Medium | Medium/High | Very High | Very High | High | Low/Medium | High |


### Skill Package Bias

Rally Speed, Lancefaire, Relief, Speed +2, staff utility


### Mechanical Notes

- Use as the support-leaning promoted Pegasus archetype.
- Can serve as a mobile healer while retaining offensive lance threat.
- Avoid giving excessive DEF unless building a boss or late-game elite.



## Dark Flier

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_DARK_FLIER |
| Role Category | Promoted flying hybrid attacker |
| Recommended Class Families | Dark Flier |
| Weapon Profile | Lance and tome |
| Movement Profile | Flying |
| Vulnerability Profile | Flying; mounted/beast effectiveness where applicable |
| AI Role | Mobile hybrid attacker; targets whichever defensive stat is lower and values kill-confirming action-economy effects |
| Generation Scope | Playable promoted flier, enemy elite flier, late-game hybrid threat |
| Internal Tags | promoted; flying; lance; tome; hybrid; galeforce |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 30 | 40 | 40 | 45 | 35 | 20 | 40 | 290 | 135 | 80 | 100 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 21 | 6 | 7 | 8 | 11 | 5 | 5 | 9 | 8 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium | Medium | High | High | High/Very High | High | Low | High |


### Skill Package Bias

Rally Movement, Galeforce, Speed +2, Relief, tome/lance hybrid packages


### Mechanical Notes

- Use when mobility and mixed damage are the defining features.
- Galeforce-like behavior should be explicitly enabled as an action-economy rule.
- Enemy Dark Fliers become high-threat if equipped with forged tomes and aggressive AI.



## Wyvern

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_WYVERN |
| Role Category | Physical flying bruiser |
| Recommended Class Families | Wyvern Rider, Wyvern Lord, Griffon Rider |
| Weapon Profile | Axe primary; lance after Wyvern Lord promotion |
| Movement Profile | Flying |
| Vulnerability Profile | Flying; Dragon for wyvern-dragon mount classes where modeled |
| AI Role | Flying bruiser; prioritizes high-damage engagements, terrain bypass, and pressure on weak backliners |
| Generation Scope | Playable flier, enemy wyvern, reinforcement, elite physical flier |
| Internal Tags | flying; axe; strength; defense; low-resistance |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 55 | 50 | 5 | 30 | 30 | 25 | 40 | 15 | 250 | 150 | 20 | 110 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 21 | 8 | 0 | 6 | 5 | 3 | 9 | 0 | 7 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| High | Very High | Low | Medium | Medium | Medium/Low | High | Low |


### Skill Package Bias

Strength +2, Tantivy, Quick Burn, Swordbreaker, Deliverer, Lancebreaker


### Mechanical Notes

- Use as the physical counterpart to Pegasus.
- Keep RES low to preserve magical weakness.
- Wyvern Lord variant raises STR/DEF and adds lances; Griffon variant raises mobility/speed consistency.



## Griffon

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_GRIFFON |
| Role Category | Mobile flying axe specialist |
| Recommended Class Families | Griffon Rider |
| Weapon Profile | Axe primary |
| Movement Profile | Flying |
| Vulnerability Profile | Flying; mounted/beast effectiveness where applicable |
| AI Role | Mobility specialist; uses high movement to flank and exploit isolated targets |
| Generation Scope | Playable promoted flier, enemy elite flier, map-pressure unit |
| Internal Tags | promoted; flying; axe; mobility; deliverer |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 40 | 5 | 40 | 40 | 30 | 30 | 20 | 255 | 150 | 25 | 100 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 24 | 10 | 0 | 10 | 10 | 4 | 8 | 3 | 8 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| High | High | Low | High | High | Medium | Medium/High | Low/Medium |


### Skill Package Bias

Deliverer, Lancebreaker, Strength +2, Tantivy, mobility packages


### Mechanical Notes

- Use for the mobility-focused branch of the Wyvern family.
- Compared with Wyvern Lord, lower raw DEF/STR ceiling and increase SKL/SPD utility.
- Deliverer-like movement bonuses should require Pair Up state.



## Trickster

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_TRICKSTER |
| Role Category | Utility sword/staff hybrid |
| Recommended Class Families | Thief, Trickster, Assassin utility variants |
| Weapon Profile | Sword and staff; thief utility; optional lock/chest access |
| Movement Profile | Infantry C |
| Vulnerability Profile | None by default |
| AI Role | Utility skirmisher; prioritizes support actions, staff use, terrain mobility, and finishing exposed targets |
| Generation Scope | Playable utility unit, enemy thief, staff/sword hybrid, map objective thief |
| Internal Tags | utility; sword; staff; thief; mobility; support |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 40 | 25 | 30 | 45 | 45 | 45 | 20 | 30 | 280 | 135 | 60 | 90 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 19 | 4 | 4 | 10 | 11 | 6 | 3 | 5 | 6 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium/Low | Medium/Low | Medium/High | Very High | High | High | Low | Medium/High |


### Skill Package Bias

Locktouch, Movement +1, Lucky Seven, Acrobat, staff utility packages


### Mechanical Notes

- Use when map utility matters as much as combat.
- Acrobat-style terrain rules should modify traversable terrain costs but not permit crossing impassable terrain.
- Enemy Tricksters can be objective-driven rather than kill-driven.



## Hybrid

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_HYBRID |
| Role Category | Mixed physical/magical attacker |
| Recommended Class Families | Tactician, Grandmaster, Dark Knight, Dark Flier, Dread Fighter, Bride, hybrid personal builds |
| Weapon Profile | Any mixed physical/magical pairing; common pairs include sword+tome, lance+tome, axe+tome, lance+staff |
| Movement Profile | Variable |
| Vulnerability Profile | Class-dependent |
| AI Role | Damage-stat selector; targets the lower defensive stat and values flexible counter coverage |
| Generation Scope | Avatar-like unit, elite enemy, DLC unit, flexible simulator test profile |
| Internal Tags | hybrid; mixed-damage; flexible; avatar-like; multi-weapon |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 45 | 35 | 35 | 35 | 35 | 35 | 30 | 30 | 280 | 135 | 65 | 105 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 5 | 5 | 6 | 6 | 5 | 5 | 5 | 6 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium | Medium/High | Medium/High | Medium/High | Medium/High | Medium/High | Medium | Medium |


### Skill Package Bias

Ignis, Rally Spectrum, Defender, Lifetaker, mixed-faire or damage-stat conversion packages


### Mechanical Notes

- Use as a neutral testbed for rules-engine validation because it interacts with both STR and MAG formulas.
- Avoid making both defenses and both offenses extreme unless modeling a boss or Avatar-like overperformer.
- Weapon loadout should include both physical and magical damage options for the archetype to matter.



## Tank

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_TANK |
| Role Category | Generic high-survivability defender |
| Recommended Class Families | Knight, General, Great Knight, Manakete, Conqueror, bulky Sorcerer variants |
| Weapon Profile | Class-dependent; often lance, axe, dragonstone, or Nosferatu |
| Movement Profile | Low or moderate; class-dependent |
| Vulnerability Profile | Usually Armor, Dragon, or class-dependent |
| AI Role | Defensive anchor; prioritizes holding tiles, baiting attacks, guarding bosses, and surviving enemy phase |
| Generation Scope | Enemy guard, boss guard, playable defensive specialist, Risen elite |
| Internal Tags | durable; defense; resistance-optional; chokepoint; enemy-phase |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 65 | 35 | 20 | 25 | 15 | 25 | 50 | 35 | 270 | 125 | 55 | 150 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 25 | 7 | 3 | 5 | 3 | 3 | 12 | 6 | 4 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Very High | Medium/High | Variable | Medium/Low | Low | Medium | Very High | Medium/High |


### Skill Package Bias

Pavise, Aegis, Renewal, Defender, Dragonskin-like boss reduction, Guard support packages


### Mechanical Notes

- Use as a role archetype independent of class.
- To avoid unkillable units, define at least one exploitable weakness: low RES, low SPD, effectiveness, low MOV, or poor player-phase reach.
- Boss tanks may use deterministic reduction skills rather than inflated raw stats.



## Glass Cannon

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_GLASS_CANNON |
| Role Category | High-offense low-survivability attacker |
| Recommended Class Families | Mage, Berserker, Swordmaster, Dark Flier, Sniper, Assassin |
| Weapon Profile | High-might, high-crit, brave, or effective weapons depending on class |
| Movement Profile | Variable |
| Vulnerability Profile | Class-dependent; intentionally fragile |
| AI Role | Threat projection unit; prioritizes kills and high-damage targets even if survival is limited |
| Generation Scope | Enemy ambusher, player offensive specialist, reinforcement threat, miniboss attacker |
| Internal Tags | offense; fragile; high-damage; high-speed; high-risk |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 45 | 45 | 45 | 45 | 25 | 10 | 15 | 265 | 145 | 60 | 60 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 17 | 7 | 7 | 8 | 8 | 3 | 2 | 3 | 6 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Low | High | High | High | High | Medium/Low | Very Low | Low |


### Skill Package Bias

Faire skills, Aggressor, Gamble, Wrath, Focus, Vengeance, breaker skills


### Mechanical Notes

- Use when the simulator needs lethal but fragile pressure.
- Avoid combining high durability with this template; doing so collapses its role into Boss or Hybrid elite.
- Works well with brave weapons, killer weapons, or forged tomes.



## Boss

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_BOSS |
| Role Category | High-value commander or map objective enemy |
| Recommended Class Families | Any class; common forms include General, Sorcerer, Great Knight, Conqueror, Manakete, Grima-style boss |
| Weapon Profile | Scripted high-quality weapon, personal weapon, forged weapon, legendary weapon, or dark/stone weapon |
| Movement Profile | Stationary, limited, or full movement depending on map design |
| Vulnerability Profile | Class-dependent; may include scripted immunities |
| AI Role | Objective anchor; prioritizes survival, high-threat attacks, terrain bonuses, and scripted behavior |
| Generation Scope | Chapter boss, paralogue boss, DLC boss, Risen chief, final boss |
| Internal Tags | boss; scripted; high-stats; skills; terrain; objective |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 70 | 45 | 45 | 40 | 30 | 20 | 45 | 40 | 335 | 160 | 85 | 155 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 35 | 12 | 12 | 10 | 8 | 5 | 12 | 10 | 0 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Very High | High/Very High | High/Very High | High | Medium | Low/Medium | High/Very High | High |


### Skill Package Bias

Rightful King/God, Pavise/Aegis, Dragonskin, Vengeance, Luna, Counter, breaker skills, map-script skills


### Mechanical Notes

- Use explicit boss flags rather than only higher growths.
- Boss MOV may be 0 for throne/stationary bosses or normal for roaming bosses.
- Scripted skills and immunities should be stored separately from class-learned skills.
- For final bosses, use class/boss-specific caps rather than generic player class caps.



## Risen

### Metadata

| Property | Value |
|---|---|
| Archetype ID | ARCH_RISEN |
| Role Category | Generic undead/skirmish enemy package |
| Recommended Class Families | Any generic class; Revenant and Entombed for monster forms |
| Weapon Profile | Class-dependent; often random, low-to-mid quality, forged or scaled by difficulty in skirmishes |
| Movement Profile | Class-dependent |
| Vulnerability Profile | Class-dependent; Monster for Revenant/Entombed forms |
| AI Role | Aggressive generic enemy; prioritizes nearest reachable targets and simple kill forecasts |
| Generation Scope | Skirmish enemy, random encounter, monster enemy, reinforcement pack |
| Internal Tags | enemy; generic; risen; autolevel; random-loadout; skirmish |


### Growth Package

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | Total | Physical Bias | Magical Bias | Bulk Bias |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 30 | 25 | 25 | 25 | 10 | 25 | 20 | 210 | 105 | 45 | 95 |


### Base Stat Template

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES | MOV |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 5 | 4 | 4 | 4 | 0 | 4 | 3 | 5 |


### Stat Cap Bias

| HP | STR | MAG | SKL | SPD | LCK | DEF | RES |
|---|---|---|---|---|---|---|---|
| Medium/High | Variable | Variable | Variable | Variable | Very Low | Variable | Variable |


### Skill Package Bias

Difficulty-generated skills, class skills by level, enemy-exclusive packages on high difficulty, monster package where applicable


### Mechanical Notes

- Use as a generator seed rather than a fixed class.
- Apply class growths and difficulty modifiers after this unit-growth component.
- For Revenant/Entombed, use monster class entries and natural-weapon handling from Phase 5.
- Luck is intentionally low to distinguish generic undead enemies from playable templates.



---

# Archetype Count Audit


| Archetype | ID | Growth Total | Primary Bias | Recommended Use |

|---|---|---:|---|---|

| Lord | ARCH_LORD | 265 | HP 45, LCK 45, STR 35 | Balanced protagonist / command unit |

| Cavalier | ARCH_CAVALIER | 240 | HP 50, STR 35, LCK 35 | Mounted balanced physical unit |

| Knight | ARCH_KNIGHT | 230 | HP 60, DEF 45, STR 40 | Armored physical tank |

| Fighter | ARCH_FIGHTER | 240 | HP 60, STR 45, SKL 30 | High-HP physical brawler |

| Barbarian | ARCH_BARBARIAN | 225 | HP 65, STR 45, SPD 35 | Fast offensive axe raider |

| Mercenary | ARCH_MERCENARY | 250 | HP 50, SKL 40, STR 35 | Reliable physical infantry |

| Hero | ARCH_HERO | 270 | HP 55, SKL 45, STR 40 | Sustaining promoted physical infantry |

| Myrmidon | ARCH_MYRMIDON | 255 | SPD 50, SKL 45, HP 40 | Fast sword evasion unit |

| Swordmaster | ARCH_SWORDMASTER | 285 | SKL 55, SPD 55, HP 45 | Promoted speed/skill duelist |

| Archer | ARCH_ARCHER | 240 | SKL 50, HP 45, STR 35 | Accurate ranged physical unit |

| Mage | ARCH_MAGE | 240 | MAG 45, HP 35, SKL 35 | Standard offensive magic unit |

| Dark Mage | ARCH_DARK_MAGE | 245 | HP 50, MAG 40, RES 35 | Bulky debuff magic unit |

| Cleric | ARCH_CLERIC | 250 | LCK 45, RES 45, MAG 40 | Foot staff support / healer |

| Troubadour | ARCH_TROUBADOUR | 250 | RES 50, LCK 45, MAG 40 | Mounted healer / magical support |

| Pegasus | ARCH_PEGASUS | 270 | SPD 45, HP 40, SKL 40 | Fast flying lance unit |

| Falcon Knight | ARCH_FALCON_KNIGHT | 295 | HP 45, SKL 45, SPD 45 | Promoted flying support lancer |

| Dark Flier | ARCH_DARK_FLIER | 290 | SPD 45, HP 40, MAG 40 | Promoted flying hybrid attacker |

| Wyvern | ARCH_WYVERN | 250 | HP 55, STR 50, DEF 40 | Physical flying bruiser |

| Griffon | ARCH_GRIFFON | 255 | HP 50, STR 40, SKL 40 | Mobile flying axe specialist |

| Trickster | ARCH_TRICKSTER | 280 | SKL 45, SPD 45, LCK 45 | Utility sword/staff hybrid |

| Hybrid | ARCH_HYBRID | 280 | HP 45, STR 35, MAG 35 | Mixed physical/magical attacker |

| Tank | ARCH_TANK | 270 | HP 65, DEF 50, STR 35 | Generic high-survivability defender |

| Glass Cannon | ARCH_GLASS_CANNON | 265 | STR 45, MAG 45, SKL 45 | High-offense low-survivability attacker |

| Boss | ARCH_BOSS | 335 | HP 70, STR 45, MAG 45 | High-value commander or map objective enemy |

| Risen | ARCH_RISEN | 210 | HP 50, STR 30, MAG 25 | Generic undead/skirmish enemy package |


## Required Archetype Coverage

| Required Archetype | Included |
|---|---|

| Lord | Yes |

| Cavalier | Yes |

| Knight | Yes |

| Fighter | Yes |

| Barbarian | Yes |

| Mercenary | Yes |

| Hero | Yes |

| Myrmidon | Yes |

| Swordmaster | Yes |

| Archer | Yes |

| Mage | Yes |

| Dark Mage | Yes |

| Cleric | Yes |

| Troubadour | Yes |

| Pegasus | Yes |

| Falcon Knight | Yes |

| Dark Flier | Yes |

| Wyvern | Yes |

| Griffon | Yes |

| Trickster | Yes |

| Hybrid | Yes |

| Tank | Yes |

| Glass Cannon | Yes |

| Boss | Yes |

| Risen | Yes |


| Total Required | 25 |
| Total Included | 25 |

---

# End of Phase 10 — Archetype Templates
