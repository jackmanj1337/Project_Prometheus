# Legacy Tactical-RPG Technical Reference Corpus
# Weapon Encyclopedia — Magic, Staves, and Stones

**File:** `awakening_weapons_magic.md`  
**Phase:** 8  
**Corpus Version:** `0.9.0-phase8`  
**Depends On:** `awakening_project_index.md`, `awakening_core_systems.md`, `awakening_lookup_tables.md`, `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_classes_special.md`, `awakening_skills.md`, `awakening_weapons_physical.md`  
**Scope:** Tomes, dark magic, staves, beaststones, and dragonstones only.

---

# Table of Contents

1. [Phase Boundary](#phase-boundary)
2. [Normalization Notes](#normalization-notes)
3. [Tomes](#tomes)
4. [Dark Magic](#dark-magic)
5. [Staves](#staves)
6. [Beaststones](#beaststones)
7. [Dragonstones](#dragonstones)

---

# Phase Boundary

This document includes:

| Weapon Family | Included |
|---|---|
| Standard tomes | Yes |
| Dark magic / dark tomes | Yes |
| Staves | Yes |
| Beaststones | Yes |
| Dragonstones | Yes |
| Swords | No; Phase 7 |
| Lances | No; Phase 7 |
| Axes | No; Phase 7 |
| Bows | No; Phase 7 |
| Monster natural weapons | No; special/enemy weapon appendix scope |
| Breath/natural boss weapons | No; special/enemy weapon appendix scope |

---

# Normalization Notes

## WEXP Requirements

Weapon rank is represented as both a rank label and numeric WEXP requirement.

| Rank | WEXP Requirement |
|---|---:|
| E | 1 |
| D | 31 |
| C | 71 |
| B | 121 |
| A | 181 |
| S | 251 |
| Unranked | 0 |

## Cost and Sell

`Cost` uses the listed weapon worth. `Sell` is normalized as:

```text
NormalSell = floor(Cost / 2)
QuarterSell = floor(Cost / 4)
UnsellableOrWorthZero = 0
```

Weapons with listed worth `0` are represented as `Cost = 0` and `Sell = 0`.

## Tome Damage

Standard tome and dark tome damage uses:

```text
Attack = MAG + TomeMight + AttackModifiers
DefenseStat = RES
```

## Dark Magic Access

Dark tomes require:

```text
CurrentClass has dark_magic_access
OR Unit has Shadowgift and CurrentClass can use tomes
OR Weapon/Unit/Map script grants explicit exception
```

Dark Mage and Sorcerer provide native dark-magic permission. Dark Knight does not natively provide dark-tome access unless another rule grants it.

## Staff Combat Fields

Staves are not standard attack weapons. For required schema compatibility:

```text
Mt = N/A
Hit = N/A
Crit = N/A
```

Staff `Range` uses staff range. Variable staff range is normalized as:

```text
1–floor(MAG / 2)
```

## Stone Rank Handling

Beaststones and dragonstones are represented as unranked transformation weapon categories:

```text
Rank = Unranked
WEXP Requirement = 0
```

Their stat boosts are represented in `Special Effects`.

---


# Tomes

## Fire

| Property | Value |
|---|---|
| Type | Tome |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 2 |
| Hit | 90 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 45 |
| Cost | 540 |
| Sell | 270 |
| Effective Against | None |
| Special Effects | None |

## Elfire

| Property | Value |
|---|---|
| Type | Tome |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 5 |
| Hit | 85 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 35 |
| Cost | 980 |
| Sell | 490 |
| Effective Against | None |
| Special Effects | None |

## Arcfire

| Property | Value |
|---|---|
| Type | Tome |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 8 |
| Hit | 80 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 30 |
| Cost | 1440 |
| Sell | 720 |
| Effective Against | None |
| Special Effects | None |

## Bolganone

| Property | Value |
|---|---|
| Type | Tome |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 12 |
| Hit | 75 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 2000 |
| Sell | 1000 |
| Effective Against | None |
| Special Effects | None |

## Valflame

| Property | Value |
|---|---|
| Type | Tome |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 16 |
| Hit | 80 |
| Crit | 10 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | MAG +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Thunder

| Property | Value |
|---|---|
| Type | Tome |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 3 |
| Hit | 80 |
| Crit | 5 |
| Range | 1–2 |
| Durability | 45 |
| Cost | 630 |
| Sell | 315 |
| Effective Against | None |
| Special Effects | None |

## Elthunder

| Property | Value |
|---|---|
| Type | Tome |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 6 |
| Hit | 75 |
| Crit | 5 |
| Range | 1–2 |
| Durability | 35 |
| Cost | 1050 |
| Sell | 525 |
| Effective Against | None |
| Special Effects | None |

## Arcthunder

| Property | Value |
|---|---|
| Type | Tome |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 10 |
| Hit | 70 |
| Crit | 10 |
| Range | 1–2 |
| Durability | 30 |
| Cost | 1620 |
| Sell | 810 |
| Effective Against | None |
| Special Effects | None |

## Thoron

| Property | Value |
|---|---|
| Type | Tome |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 14 |
| Hit | 65 |
| Crit | 10 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 2200 |
| Sell | 1100 |
| Effective Against | None |
| Special Effects | None |

## Mjölnir

| Property | Value |
|---|---|
| Type | Tome |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 18 |
| Hit | 70 |
| Crit | 20 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | SKL +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Wind

| Property | Value |
|---|---|
| Type | Tome |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 1 |
| Hit | 100 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 45 |
| Cost | 450 |
| Sell | 225 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. |

## Elwind

| Property | Value |
|---|---|
| Type | Tome |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 4 |
| Hit | 95 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 35 |
| Cost | 910 |
| Sell | 455 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. |

## Arcwind

| Property | Value |
|---|---|
| Type | Tome |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 6 |
| Hit | 90 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 30 |
| Cost | 1320 |
| Sell | 660 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. |

## Rexcalibur

| Property | Value |
|---|---|
| Type | Tome |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 10 |
| Hit | 85 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 1900 |
| Sell | 950 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. |

## Excalibur

| Property | Value |
|---|---|
| Type | Tome |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 13 |
| Hit | 100 |
| Crit | 30 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Cannot be forged or purchased from StreetPass teams. |

## Forseti

| Property | Value |
|---|---|
| Type | Tome |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 14 |
| Hit | 90 |
| Crit | 10 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | Flying |
| Special Effects | SPD +5 when equipped. Effective damage against flying units. Cannot be forged or purchased from StreetPass teams. |

## Book of Naga

| Property | Value |
|---|---|
| Type | Tome |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 15 |
| Hit | 80 |
| Crit | 15 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | Dragon |
| Special Effects | DEF +5 and RES +5 when equipped. Effective damage against dragon units. Cannot be forged or purchased from StreetPass teams. |

## Dying Blaze

| Property | Value |
|---|---|
| Type | Tome |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 10 |
| Hit | 75 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 3 |
| Cost | 600 |
| Sell | 150 |
| Effective Against | None |
| Special Effects | High might with very low durability. Sells for 1/4 of its worth. |

## Seraphine's Pyre

| Property | Value |
|---|---|
| Type | Tome |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 13 |
| Hit | 85 |
| Crit | 5 |
| Range | 1–2 |
| Durability | 15 |
| Cost | 2130 |
| Sell | 532 |
| Effective Against | None |
| Special Effects | DEF +2 and RES +2 when equipped. Sells for 1/4 of its worth. |

## Superior Jolt

| Property | Value |
|---|---|
| Type | Tome |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 14 |
| Hit | 60 |
| Crit | 15 |
| Range | 1–2 |
| Durability | 10 |
| Cost | 2320 |
| Sell | 580 |
| Effective Against | None |
| Special Effects | Grants Tomebreaker while equipped. Sells for 1/4 of its worth. |

## Katarina's Bolt

| Property | Value |
|---|---|
| Type | Tome |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 11 |
| Hit | 75 |
| Crit | 30 |
| Range | 1–2 |
| Durability | 20 |
| Cost | 1920 |
| Sell | 480 |
| Effective Against | None |
| Special Effects | High-critical lightning tome. Sells for 1/4 of its worth. |

## Wilderwind

| Property | Value |
|---|---|
| Type | Tome |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 2 |
| Hit | 70 |
| Crit | 35 |
| Range | 1–2 |
| Durability | 5 |
| Cost | 760 |
| Sell | 190 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. High critical rate. Sells for 1/4 of its worth. |

## Celica's Gale

| Property | Value |
|---|---|
| Type | Tome |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 4 |
| Hit | 80 |
| Crit | 5 |
| Range | 1–2 |
| Durability | 20 |
| Cost | 1720 |
| Sell | 430 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Brave effect: strikes twice consecutively. Sells for 1/4 of its worth. |


---

# Dark Magic

## Flux

| Property | Value |
|---|---|
| Type | Dark Tome |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 5 |
| Hit | 70 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 45 |
| Cost | 540 |
| Sell | 270 |
| Effective Against | None |
| Special Effects | Dark magic. Requires Dark Mage/Sorcerer dark-magic permission or Shadowgift. |

## Nosferatu

| Property | Value |
|---|---|
| Type | Dark Tome |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 7 |
| Hit | 65 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 20 |
| Cost | 980 |
| Sell | 490 |
| Effective Against | None |
| Special Effects | Dark magic. Restores HP equal to half the damage dealt. Requires Dark Mage/Sorcerer dark-magic permission or Shadowgift. |

## Ruin

| Property | Value |
|---|---|
| Type | Dark Tome |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 4 |
| Hit | 60 |
| Crit | 50 |
| Range | 1–2 |
| Durability | 20 |
| Cost | 1380 |
| Sell | 690 |
| Effective Against | None |
| Special Effects | Dark magic with high critical rate. Requires Dark Mage/Sorcerer dark-magic permission or Shadowgift. |

## Waste

| Property | Value |
|---|---|
| Type | Dark Tome |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 10 |
| Hit | 45 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 30 |
| Cost | 2160 |
| Sell | 1080 |
| Effective Against | None |
| Special Effects | Dark magic. Brave effect: strikes twice consecutively. Requires Dark Mage/Sorcerer dark-magic permission or Shadowgift. |

## Mire

| Property | Value |
|---|---|
| Type | Dark Tome |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 10 |
| Hit | 65 |
| Crit | 0 |
| Range | 3–10 |
| Durability | 10 |
| Cost | 2000 |
| Sell | 1000 |
| Effective Against | None |
| Special Effects | Dark magic. Cannot double attack, negates user's offensive trigger skills, and prevents support unit Dual Strikes. Requires Dark Mage/Sorcerer dark-magic permission or Shadowgift. |

## Goetia

| Property | Value |
|---|---|
| Type | Dark Tome |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 19 |
| Hit | 75 |
| Crit | 10 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Dark magic. Requires Dark Mage/Sorcerer dark-magic permission or Shadowgift. Cannot be forged or purchased from StreetPass teams. |

## Grima's Truth

| Property | Value |
|---|---|
| Type | Dark Tome |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 12 |
| Hit | 80 |
| Crit | 0 |
| Range | 1–2 |
| Durability | ∞ |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Enemy-associated dark magic. Requires scripted access, Dark Mage/Sorcerer dark-magic permission, or Shadowgift if made playable. |

## Aversa's Night

| Property | Value |
|---|---|
| Type | Dark Tome |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 15 |
| Hit | 75 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 10 |
| Cost | 2340 |
| Sell | 585 |
| Effective Against | None |
| Special Effects | Dark magic. Restores HP equal to half the damage dealt. Requires Dark Mage/Sorcerer dark-magic permission or Shadowgift. Sells for 1/4 of its worth. |


---

# Staves

## Heal

| Property | Value |
|---|---|
| Type | Staff |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1 |
| Durability | 30 |
| Cost | 600 |
| Sell | 300 |
| Effective Against | None |
| Special Effects | Restores a small amount of HP to an adjacent ally. Base staff EXP: 17. |

## Mend

| Property | Value |
|---|---|
| Type | Staff |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1 |
| Durability | 20 |
| Cost | 1000 |
| Sell | 500 |
| Effective Against | None |
| Special Effects | Restores a medium amount of HP to an adjacent ally. Base staff EXP: 22. |

## Physic

| Property | Value |
|---|---|
| Type | Staff |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1–floor(MAG / 2) |
| Durability | 10 |
| Cost | 1800 |
| Sell | 900 |
| Effective Against | None |
| Special Effects | Restores a small amount of HP to an ally in range. Base staff EXP: 30. |

## Recover

| Property | Value |
|---|---|
| Type | Staff |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1 |
| Durability | 15 |
| Cost | 1950 |
| Sell | 975 |
| Effective Against | None |
| Special Effects | Fully restores an adjacent ally's HP. Base staff EXP: 40. |

## Fortify

| Property | Value |
|---|---|
| Type | Staff |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1–floor(MAG / 2) |
| Durability | 5 |
| Cost | 2500 |
| Sell | 1250 |
| Effective Against | None |
| Special Effects | Restores a small amount of HP to all allies in range. Base staff EXP: 60. |

## Goddess Staff

| Property | Value |
|---|---|
| Type | Staff |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1–floor(MAG / 2) |
| Durability | 1 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Fully restores HP to all allies in range. Base staff EXP: 100. Cannot be purchased normally. |

## Rescue

| Property | Value |
|---|---|
| Type | Staff |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1–floor(MAG / 2) |
| Durability | 5 |
| Cost | 1280 |
| Sell | 640 |
| Effective Against | None |
| Special Effects | Moves a distant ally to an adjacent space. Base staff EXP: 40. |

## Ward

| Property | Value |
|---|---|
| Type | Staff |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1–floor(MAG / 2) |
| Durability | 5 |
| Cost | 2100 |
| Sell | 1050 |
| Effective Against | None |
| Special Effects | Boosts an ally's RES by 5; effect decreases by 1 each turn. Base staff EXP: 30. |

## Hammerne

| Property | Value |
|---|---|
| Type | Staff |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1 |
| Durability | 1 |
| Cost | 2000 |
| Sell | 1000 |
| Effective Against | None |
| Special Effects | Fully repairs an adjacent ally's weapon or staff. Base staff EXP: 50. |

## Kneader

| Property | Value |
|---|---|
| Type | Staff |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1 |
| Durability | 20 |
| Cost | 100 |
| Sell | 25 |
| Effective Against | None |
| Special Effects | Restores a tiny amount of HP to an adjacent ally. Base staff EXP: 12. Sells for 1/4 of its worth. |

## Balmwood Staff

| Property | Value |
|---|---|
| Type | Staff |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1 |
| Durability | 15 |
| Cost | 1200 |
| Sell | 300 |
| Effective Against | None |
| Special Effects | Restores HP to the wielder or an adjacent ally. Base staff EXP: 22. Sells for 1/4 of its worth. |

## Catharsis

| Property | Value |
|---|---|
| Type | Staff |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | N/A |
| Hit | N/A |
| Crit | N/A |
| Range | 1–floor(MAG / 2) |
| Durability | 5 |
| Cost | 2100 |
| Sell | 525 |
| Effective Against | None |
| Special Effects | Restores a medium amount of HP to an ally in range. Base staff EXP: 35. Sells for 1/4 of its worth. |


---

# Beaststones

## Beaststone

| Property | Value |
|---|---|
| Type | Beaststone |
| Rank | Unranked |
| WEXP Requirement | 0 |
| Mt | 6 |
| Hit | 80 |
| Crit | 0 |
| Range | 1 |
| Durability | 50 |
| Cost | 2000 |
| Sell | 1000 |
| Effective Against | None |
| Special Effects | Taguel only. Enables beast-form combat. Grants STR +3, SKL +5, SPD +5, LCK +4, DEF +1. |

## Beaststone+

| Property | Value |
|---|---|
| Type | Beaststone |
| Rank | Unranked |
| WEXP Requirement | 0 |
| Mt | 10 |
| Hit | 70 |
| Crit | 0 |
| Range | 1 |
| Durability | 35 |
| Cost | 3220 |
| Sell | 1610 |
| Effective Against | None |
| Special Effects | Taguel only. Enables stronger beast-form combat. Grants STR +5, SKL +8, SPD +8, LCK +6, DEF +4, RES +2. |


---

# Dragonstones

## Dragonstone

| Property | Value |
|---|---|
| Type | Dragonstone |
| Rank | Unranked |
| WEXP Requirement | 0 |
| Mt | 8 |
| Hit | 80 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 50 |
| Cost | 2300 |
| Sell | 1150 |
| Effective Against | None |
| Special Effects | Dragonkin only. Enables dragon-form combat. Grants STR +8, MAG +5, SKL +3, SPD +2, DEF +10, RES +7. |

## Dragonstone+

| Property | Value |
|---|---|
| Type | Dragonstone |
| Rank | Unranked |
| WEXP Requirement | 0 |
| Mt | 12 |
| Hit | 70 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 35 |
| Cost | 3780 |
| Sell | 1890 |
| Effective Against | None |
| Special Effects | Dragonkin only. Enables stronger dragon-form combat. Grants STR +11, MAG +6, SKL +5, SPD +4, DEF +13, RES +9. |


---

# Weapon Count Audit

| Family | Entries |
|---|---:|
| Tomes | 23 |
| Dark Magic | 8 |
| Staves | 12 |
| Beaststones | 2 |
| Dragonstones | 2 |
| Total | 47 |

---

# End of Phase 8 — Weapon Encyclopedia Part 2
