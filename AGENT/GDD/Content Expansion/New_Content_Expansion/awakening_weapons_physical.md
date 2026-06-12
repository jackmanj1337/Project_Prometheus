# Fire Emblem Awakening Technical Reference Corpus
# Weapon Encyclopedia — Physical Weapons

**File:** `awakening_weapons_physical.md`  
**Phase:** 7  
**Corpus Version:** `0.8.0-phase7`  
**Depends On:** `awakening_project_index.md`, `awakening_core_systems.md`, `awakening_lookup_tables.md`, `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_classes_special.md`, `awakening_skills.md`  
**Scope:** Swords, lances, axes, and bows only.

---

# Table of Contents

1. [Phase Boundary](#phase-boundary)
2. [Normalization Notes](#normalization-notes)
3. [Swords](#swords)
4. [Lances](#lances)
5. [Axes](#axes)
6. [Bows](#bows)

---

# Phase Boundary

This document includes only physical weapon encyclopedia entries:

| Weapon Family | Included |
|---|---|
| Swords | Yes |
| Lances | Yes |
| Axes | Yes |
| Bows | Yes |
| Tomes | No; Phase 8 |
| Dark Magic | No; Phase 8 |
| Staves | No; Phase 8 |
| Beaststones | No; Phase 8 |
| Dragonstones | No; Phase 8 |
| Monster weapons / breath weapons | No; Phase 8 or special enemy appendices |

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

## Cost and Sell

`Cost` uses the listed weapon worth. `Sell` is normalized as:

```text
NormalSell = floor(Cost / 2)
QuarterSell = floor(Cost / 4)
UnsellableOrWorthZero = 0
```

Weapons with listed worth `0` are represented as `Cost = 0` and `Sell = 0`.

## Effectiveness

Effectiveness groups use corpus vocabulary:

| Listed Effect | Corpus Effective Against |
|---|---|
| Armored units | Armor |
| Dragon units | Dragon |
| Fell dragon units | Fell Dragon |
| Beast units | Beast/Cavalry |
| Flying units | Flying |
| Monster units | Monster |

Effectiveness normally modifies weapon might:

```text
EffectiveWeaponMight = WeaponMight × 3
```

## Magical Physical Weapons

A physical weapon family entry may use magical damage.

| Weapon | Weapon Type | Damage Stat | Defense Stat |
|---|---|---|---|
| Levin Sword | Sword | MAG | RES |
| Shockstick | Lance | MAG | RES |
| Bolt Axe | Axe | MAG | RES |

## Brave Weapons

Brave effects are encoded as:

```text
StrikesPerAttackOpportunity = 2
```

---


# Swords

## Bronze Sword

| Property | Value |
|---|---|
| Type | Sword |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 3 |
| Hit | 100 |
| Crit | 0 |
| Range | 1 |
| Durability | 50 |
| Cost | 350 |
| Sell | 175 |
| Effective Against | None |
| Special Effects | None |

## Iron Sword

| Property | Value |
|---|---|
| Type | Sword |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 5 |
| Hit | 95 |
| Crit | 0 |
| Range | 1 |
| Durability | 40 |
| Cost | 520 |
| Sell | 260 |
| Effective Against | None |
| Special Effects | None |

## Steel Sword

| Property | Value |
|---|---|
| Type | Sword |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 8 |
| Hit | 90 |
| Crit | 0 |
| Range | 1 |
| Durability | 35 |
| Cost | 840 |
| Sell | 420 |
| Effective Against | None |
| Special Effects | None |

## Silver Sword

| Property | Value |
|---|---|
| Type | Sword |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 11 |
| Hit | 85 |
| Crit | 0 |
| Range | 1 |
| Durability | 30 |
| Cost | 1410 |
| Sell | 705 |
| Effective Against | None |
| Special Effects | None |

## Brave Sword

| Property | Value |
|---|---|
| Type | Sword |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 9 |
| Hit | 80 |
| Crit | 0 |
| Range | 1 |
| Durability | 30 |
| Cost | 2100 |
| Sell | 1050 |
| Effective Against | None |
| Special Effects | Brave effect: strikes twice consecutively. |

## Armorslayer

| Property | Value |
|---|---|
| Type | Sword |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 8 |
| Hit | 80 |
| Crit | 0 |
| Range | 1 |
| Durability | 25 |
| Cost | 1450 |
| Sell | 725 |
| Effective Against | Armor |
| Special Effects | Effective damage against armored units. |

## Wyrmslayer

| Property | Value |
|---|---|
| Type | Sword |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 8 |
| Hit | 80 |
| Crit | 0 |
| Range | 1 |
| Durability | 25 |
| Cost | 1500 |
| Sell | 750 |
| Effective Against | Dragon |
| Special Effects | Effective damage against dragon units. |

## Killing Edge

| Property | Value |
|---|---|
| Type | Sword |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 9 |
| Hit | 90 |
| Crit | 30 |
| Range | 1 |
| Durability | 30 |
| Cost | 1470 |
| Sell | 735 |
| Effective Against | None |
| Special Effects | None |

## Levin Sword

| Property | Value |
|---|---|
| Type | Sword |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 10 |
| Hit | 80 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 1600 |
| Sell | 800 |
| Effective Against | None |
| Special Effects | Magical sword: uses MAG and targets RES. |

## Rapier

| Property | Value |
|---|---|
| Type | Sword |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 5 |
| Hit | 90 |
| Crit | 10 |
| Range | 1 |
| Durability | 35 |
| Cost | 1470 |
| Sell | 735 |
| Effective Against | Armor; Beast/Cavalry |
| Special Effects | Lord, Great Lord, and Lodestar only. Effective damage against beast/cavalry and armored units. |

## Noble Rapier

| Property | Value |
|---|---|
| Type | Sword |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 8 |
| Hit | 85 |
| Crit | 10 |
| Range | 1 |
| Durability | 25 |
| Cost | 2100 |
| Sell | 1050 |
| Effective Against | Armor; Beast/Cavalry |
| Special Effects | Lord, Great Lord, and Lodestar only. Effective damage against beast/cavalry and armored units. |

## Missiletainn

| Property | Value |
|---|---|
| Type | Sword |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 8 |
| Hit | 85 |
| Crit | 10 |
| Range | 1 |
| Durability | 35 |
| Cost | 1050 |
| Sell | 525 |
| Effective Against | None |
| Special Effects | Owain only. SKL +1 when equipped. Cannot be purchased from StreetPass teams. |

## Sol

| Property | Value |
|---|---|
| Type | Sword |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 12 |
| Hit | 85 |
| Crit | 5 |
| Range | 1 |
| Durability | 30 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Grants Sol while equipped. Cannot be forged or purchased from StreetPass teams. |

## Amatsu

| Property | Value |
|---|---|
| Type | Sword |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 12 |
| Hit | 60 |
| Crit | 5 |
| Range | 1–2 |
| Durability | 30 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Myrmidon and Swordmaster only. Cannot be forged or purchased from StreetPass teams. |

## Falchion

| Property | Value |
|---|---|
| Type | Sword |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 5 |
| Hit | 80 |
| Crit | 0 |
| Range | 1 |
| Durability | ∞ |
| Cost | 0 |
| Sell | 0 |
| Effective Against | Dragon |
| Special Effects | Chrom and Marth only. Cannot be sold, forged, or purchased from StreetPass teams. |

## Exalted Falchion

| Property | Value |
|---|---|
| Type | Sword |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 15 |
| Hit | 80 |
| Crit | 10 |
| Range | 1 |
| Durability | ∞ |
| Cost | 0 |
| Sell | 0 |
| Effective Against | Dragon; Fell Dragon |
| Special Effects | Chrom and Marth only. Usable item effect restores 20 HP. Cannot be sold, forged, or purchased from StreetPass teams. |

## Parallel Falchion

| Property | Value |
|---|---|
| Type | Sword |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 12 |
| Hit | 80 |
| Crit | 5 |
| Range | 1 |
| Durability | ∞ |
| Cost | 0 |
| Sell | 0 |
| Effective Against | Dragon; Fell Dragon |
| Special Effects | Lucina and Marth only. Usable item effect restores 20 HP. Cannot be sold, forged, or purchased from StreetPass teams. |

## Mercurius

| Property | Value |
|---|---|
| Type | Sword |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 17 |
| Hit | 95 |
| Crit | 5 |
| Range | 1 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Cannot be forged or purchased from StreetPass teams. |

## Tyrfing

| Property | Value |
|---|---|
| Type | Sword |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 15 |
| Hit | 85 |
| Crit | 10 |
| Range | 1 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | RES +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Balmung

| Property | Value |
|---|---|
| Type | Sword |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 14 |
| Hit | 85 |
| Crit | 15 |
| Range | 1 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | SKL +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Mystletainn

| Property | Value |
|---|---|
| Type | Sword |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 13 |
| Hit | 90 |
| Crit | 10 |
| Range | 1 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | SPD +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Sol Katti

| Property | Value |
|---|---|
| Type | Sword |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 8 |
| Hit | 100 |
| Crit | 50 |
| Range | 1 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Myrmidon and Swordmaster only. RES +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Ragnell

| Property | Value |
|---|---|
| Type | Sword |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 15 |
| Hit | 70 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | DEF +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Ragnell (Priam)

| Property | Value |
|---|---|
| Type | Sword |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 15 |
| Hit | 70 |
| Crit | 0 |
| Range | 1–2 |
| Durability | ∞ |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Enemy only. DEF +5 when equipped. Cannot be forged. |

## Tree Branch

| Property | Value |
|---|---|
| Type | Sword |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 1 |
| Hit | 100 |
| Crit | 0 |
| Range | 1 |
| Durability | 20 |
| Cost | 100 |
| Sell | 25 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Soothing Sword

| Property | Value |
|---|---|
| Type | Sword |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 8 |
| Hit | 85 |
| Crit | 0 |
| Range | 1 |
| Durability | 10 |
| Cost | 920 |
| Sell | 230 |
| Effective Against | None |
| Special Effects | Restores 10 HP to the user at the start of their phase when equipped. Sells for 1/4 of its worth. |

## Glass Sword

| Property | Value |
|---|---|
| Type | Sword |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 11 |
| Hit | 85 |
| Crit | 0 |
| Range | 1 |
| Durability | 3 |
| Cost | 600 |
| Sell | 150 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Superior Edge

| Property | Value |
|---|---|
| Type | Sword |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 11 |
| Hit | 80 |
| Crit | 0 |
| Range | 1 |
| Durability | 10 |
| Cost | 1950 |
| Sell | 487 |
| Effective Against | None |
| Special Effects | Grants Swordbreaker while equipped. Sells for 1/4 of its worth. |

## Eliwood's Blade

| Property | Value |
|---|---|
| Type | Sword |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 10 |
| Hit | 85 |
| Crit | 5 |
| Range | 1 |
| Durability | 20 |
| Cost | 960 |
| Sell | 240 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Roy's Blade

| Property | Value |
|---|---|
| Type | Sword |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 8 |
| Hit | 95 |
| Crit | 5 |
| Range | 1 |
| Durability | 25 |
| Cost | 900 |
| Sell | 225 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Alm's Blade

| Property | Value |
|---|---|
| Type | Sword |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 15 |
| Hit | 75 |
| Crit | 10 |
| Range | 1 |
| Durability | 10 |
| Cost | 1630 |
| Sell | 407 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Leif's Blade

| Property | Value |
|---|---|
| Type | Sword |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 4 |
| Hit | 95 |
| Crit | 30 |
| Range | 1 |
| Durability | 20 |
| Cost | 820 |
| Sell | 205 |
| Effective Against | None |
| Special Effects | Grants Despoil while equipped. Sells for 1/4 of its worth. |

## Eirika's Blade

| Property | Value |
|---|---|
| Type | Sword |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 6 |
| Hit | 95 |
| Crit | 10 |
| Range | 1 |
| Durability | 20 |
| Cost | 1220 |
| Sell | 305 |
| Effective Against | None |
| Special Effects | Brave effect: strikes twice consecutively. Sells for 1/4 of its worth. |

## Seliph's Blade

| Property | Value |
|---|---|
| Type | Sword |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 12 |
| Hit | 90 |
| Crit | 15 |
| Range | 1 |
| Durability | 15 |
| Cost | 1530 |
| Sell | 382 |
| Effective Against | None |
| Special Effects | SPD +2 and RES +2 when equipped. Sells for 1/4 of its worth. |


---

# Lances

## Bronze Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 3 |
| Hit | 90 |
| Crit | 0 |
| Range | 1 |
| Durability | 50 |
| Cost | 350 |
| Sell | 175 |
| Effective Against | None |
| Special Effects | None |

## Iron Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 6 |
| Hit | 85 |
| Crit | 0 |
| Range | 1 |
| Durability | 40 |
| Cost | 560 |
| Sell | 280 |
| Effective Against | None |
| Special Effects | None |

## Steel Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 9 |
| Hit | 80 |
| Crit | 0 |
| Range | 1 |
| Durability | 35 |
| Cost | 910 |
| Sell | 455 |
| Effective Against | None |
| Special Effects | None |

## Silver Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 13 |
| Hit | 75 |
| Crit | 0 |
| Range | 1 |
| Durability | 30 |
| Cost | 1560 |
| Sell | 780 |
| Effective Against | None |
| Special Effects | None |

## Brave Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 10 |
| Hit | 70 |
| Crit | 0 |
| Range | 1 |
| Durability | 30 |
| Cost | 2220 |
| Sell | 1110 |
| Effective Against | None |
| Special Effects | Brave effect: strikes twice consecutively. |

## Javelin

| Property | Value |
|---|---|
| Type | Lance |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 2 |
| Hit | 80 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 700 |
| Sell | 350 |
| Effective Against | None |
| Special Effects | None |

## Short Spear

| Property | Value |
|---|---|
| Type | Lance |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 5 |
| Hit | 75 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 1600 |
| Sell | 800 |
| Effective Against | None |
| Special Effects | None |

## Spear

| Property | Value |
|---|---|
| Type | Lance |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 8 |
| Hit | 70 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 2400 |
| Sell | 1200 |
| Effective Against | None |
| Special Effects | None |

## Beast Killer

| Property | Value |
|---|---|
| Type | Lance |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 9 |
| Hit | 70 |
| Crit | 0 |
| Range | 1 |
| Durability | 25 |
| Cost | 1650 |
| Sell | 825 |
| Effective Against | Beast/Cavalry |
| Special Effects | Effective damage against beast/cavalry units. |

## Blessed Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 11 |
| Hit | 70 |
| Crit | 0 |
| Range | 1 |
| Durability | 35 |
| Cost | 1540 |
| Sell | 770 |
| Effective Against | Monster |
| Special Effects | Effective damage against monster units. Restores 10 HP to the user at the start of their phase when equipped. |

## Killer Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 10 |
| Hit | 80 |
| Crit | 30 |
| Range | 1 |
| Durability | 30 |
| Cost | 1680 |
| Sell | 840 |
| Effective Against | None |
| Special Effects | None |

## Luna

| Property | Value |
|---|---|
| Type | Lance |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 14 |
| Hit | 80 |
| Crit | 5 |
| Range | 1 |
| Durability | 30 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Grants Luna while equipped. Cannot be forged or purchased from StreetPass teams. |

## Gradivus

| Property | Value |
|---|---|
| Type | Lance |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 19 |
| Hit | 85 |
| Crit | 5 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Usable item effect fully restores the user's HP. Cannot be forged or purchased from StreetPass teams. |

## Gáe Bolg

| Property | Value |
|---|---|
| Type | Lance |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 16 |
| Hit | 70 |
| Crit | 10 |
| Range | 1 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | STR +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Gungnir

| Property | Value |
|---|---|
| Type | Lance |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 15 |
| Hit | 75 |
| Crit | 10 |
| Range | 1 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | DEF +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Log

| Property | Value |
|---|---|
| Type | Lance |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 1 |
| Hit | 90 |
| Crit | 0 |
| Range | 1 |
| Durability | 20 |
| Cost | 100 |
| Sell | 25 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Miniature Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 1 |
| Hit | 55 |
| Crit | 35 |
| Range | 1–2 |
| Durability | 10 |
| Cost | 650 |
| Sell | 162 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Shockstick

| Property | Value |
|---|---|
| Type | Lance |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 11 |
| Hit | 85 |
| Crit | 10 |
| Range | 1 |
| Durability | 20 |
| Cost | 1200 |
| Sell | 300 |
| Effective Against | None |
| Special Effects | Magical lance: uses MAG and targets RES. Sells for 1/4 of its worth. |

## Glass Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 13 |
| Hit | 75 |
| Crit | 0 |
| Range | 1 |
| Durability | 3 |
| Cost | 600 |
| Sell | 150 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Superior Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 13 |
| Hit | 70 |
| Crit | 0 |
| Range | 1 |
| Durability | 10 |
| Cost | 2100 |
| Sell | 525 |
| Effective Against | None |
| Special Effects | Grants Lancebreaker while equipped. Sells for 1/4 of its worth. |

## Sigurd's Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 14 |
| Hit | 85 |
| Crit | 15 |
| Range | 1 |
| Durability | 15 |
| Cost | 1920 |
| Sell | 480 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Ephraim's Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 11 |
| Hit | 80 |
| Crit | 10 |
| Range | 1 |
| Durability | 20 |
| Cost | 1220 |
| Sell | 305 |
| Effective Against | None |
| Special Effects | STR +2 and SPD +2 when equipped. Sells for 1/4 of its worth. |

## Finn's Lance

| Property | Value |
|---|---|
| Type | Lance |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 8 |
| Hit | 85 |
| Crit | 10 |
| Range | 1 |
| Durability | 25 |
| Cost | 950 |
| Sell | 237 |
| Effective Against | None |
| Special Effects | LCK +2 and DEF +2 when equipped. Sells for 1/4 of its worth. |


---

# Axes

## Bronze Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 4 |
| Hit | 80 |
| Crit | 0 |
| Range | 1 |
| Durability | 50 |
| Cost | 400 |
| Sell | 200 |
| Effective Against | None |
| Special Effects | None |

## Iron Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 7 |
| Hit | 75 |
| Crit | 0 |
| Range | 1 |
| Durability | 40 |
| Cost | 600 |
| Sell | 300 |
| Effective Against | None |
| Special Effects | None |

## Steel Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 11 |
| Hit | 70 |
| Crit | 0 |
| Range | 1 |
| Durability | 35 |
| Cost | 980 |
| Sell | 490 |
| Effective Against | None |
| Special Effects | None |

## Silver Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 15 |
| Hit | 65 |
| Crit | 0 |
| Range | 1 |
| Durability | 30 |
| Cost | 1740 |
| Sell | 870 |
| Effective Against | None |
| Special Effects | None |

## Brave Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 12 |
| Hit | 60 |
| Crit | 0 |
| Range | 1 |
| Durability | 30 |
| Cost | 2400 |
| Sell | 1200 |
| Effective Against | None |
| Special Effects | Brave effect: strikes twice consecutively. |

## Hand Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 3 |
| Hit | 70 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 750 |
| Sell | 375 |
| Effective Against | None |
| Special Effects | None |

## Short Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 7 |
| Hit | 65 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 1750 |
| Sell | 875 |
| Effective Against | None |
| Special Effects | None |

## Tomahawk

| Property | Value |
|---|---|
| Type | Axe |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 10 |
| Hit | 60 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 2550 |
| Sell | 1275 |
| Effective Against | None |
| Special Effects | None |

## Hammer

| Property | Value |
|---|---|
| Type | Axe |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 10 |
| Hit | 60 |
| Crit | 0 |
| Range | 1 |
| Durability | 25 |
| Cost | 1850 |
| Sell | 925 |
| Effective Against | Armor |
| Special Effects | Effective damage against armored units. |

## Bolt Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 14 |
| Hit | 70 |
| Crit | 5 |
| Range | 1–2 |
| Durability | 30 |
| Cost | 1920 |
| Sell | 960 |
| Effective Against | None |
| Special Effects | Magical axe: uses MAG and targets RES. |

## Killer Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 12 |
| Hit | 70 |
| Crit | 30 |
| Range | 1 |
| Durability | 30 |
| Cost | 1860 |
| Sell | 930 |
| Effective Against | None |
| Special Effects | None |

## Vengeance

| Property | Value |
|---|---|
| Type | Axe |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 16 |
| Hit | 75 |
| Crit | 5 |
| Range | 1 |
| Durability | 30 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Grants Vengeance while equipped. Cannot be forged or purchased from StreetPass teams. |

## Wolf Berg

| Property | Value |
|---|---|
| Type | Axe |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 18 |
| Hit | 75 |
| Crit | 5 |
| Range | 1–2 |
| Durability | 35 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Walhart only. Cannot be forged or purchased from StreetPass teams. |

## Hauteclere

| Property | Value |
|---|---|
| Type | Axe |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 21 |
| Hit | 70 |
| Crit | 5 |
| Range | 1 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | Usable item effect fully restores the user's HP. Cannot be forged or purchased from StreetPass teams. |

## Helswath

| Property | Value |
|---|---|
| Type | Axe |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 18 |
| Hit | 60 |
| Crit | 10 |
| Range | 1–2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | DEF +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Armads

| Property | Value |
|---|---|
| Type | Axe |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 17 |
| Hit | 80 |
| Crit | 10 |
| Range | 1 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | None |
| Special Effects | DEF +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Ladle

| Property | Value |
|---|---|
| Type | Axe |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 1 |
| Hit | 80 |
| Crit | 0 |
| Range | 1 |
| Durability | 20 |
| Cost | 100 |
| Sell | 25 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Imposing Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 14 |
| Hit | 35 |
| Crit | 10 |
| Range | 1 |
| Durability | 10 |
| Cost | 830 |
| Sell | 207 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Volant Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 8 |
| Hit | 55 |
| Crit | 0 |
| Range | 1–2 |
| Durability | 10 |
| Cost | 1510 |
| Sell | 377 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Sells for 1/4 of its worth. |

## Glass Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 15 |
| Hit | 65 |
| Crit | 0 |
| Range | 1 |
| Durability | 3 |
| Cost | 600 |
| Sell | 150 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Superior Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 15 |
| Hit | 60 |
| Crit | 0 |
| Range | 1 |
| Durability | 10 |
| Cost | 2150 |
| Sell | 537 |
| Effective Against | None |
| Special Effects | Grants Axebreaker while equipped. Sells for 1/4 of its worth. |

## Titania's Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 12 |
| Hit | 80 |
| Crit | 10 |
| Range | 1 |
| Durability | 20 |
| Cost | 1320 |
| Sell | 330 |
| Effective Against | None |
| Special Effects | Grants Patience while equipped. Sells for 1/4 of its worth. |

## Orsin's Hatchet

| Property | Value |
|---|---|
| Type | Axe |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 4 |
| Hit | 85 |
| Crit | 5 |
| Range | 1–2 |
| Durability | 20 |
| Cost | 960 |
| Sell | 240 |
| Effective Against | None |
| Special Effects | Sells for 1/4 of its worth. |

## Hector's Axe

| Property | Value |
|---|---|
| Type | Axe |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 15 |
| Hit | 75 |
| Crit | 15 |
| Range | 1 |
| Durability | 15 |
| Cost | 2010 |
| Sell | 502 |
| Effective Against | None |
| Special Effects | STR +2 and DEF +2 when equipped. Sells for 1/4 of its worth. |


---

# Bows

## Bronze Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 3 |
| Hit | 90 |
| Crit | 0 |
| Range | 2 |
| Durability | 50 |
| Cost | 350 |
| Sell | 175 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. |

## Iron Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 6 |
| Hit | 85 |
| Crit | 0 |
| Range | 2 |
| Durability | 40 |
| Cost | 560 |
| Sell | 280 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. |

## Steel Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 9 |
| Hit | 80 |
| Crit | 0 |
| Range | 2 |
| Durability | 35 |
| Cost | 910 |
| Sell | 455 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. |

## Silver Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 13 |
| Hit | 75 |
| Crit | 0 |
| Range | 2 |
| Durability | 30 |
| Cost | 1560 |
| Sell | 780 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. |

## Brave Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 10 |
| Hit | 70 |
| Crit | 0 |
| Range | 2 |
| Durability | 30 |
| Cost | 2220 |
| Sell | 1110 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Brave effect: strikes twice consecutively. |

## Blessed Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 11 |
| Hit | 70 |
| Crit | 0 |
| Range | 2 |
| Durability | 35 |
| Cost | 1540 |
| Sell | 770 |
| Effective Against | Flying; Monster |
| Special Effects | Effective damage against flying and monster units. Restores 10 HP to the user at the start of their phase when equipped. |

## Killer Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 10 |
| Hit | 80 |
| Crit | 30 |
| Range | 2 |
| Durability | 30 |
| Cost | 1680 |
| Sell | 840 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. |

## Longbow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 9 |
| Hit | 70 |
| Crit | 0 |
| Range | 2–3 |
| Durability | 25 |
| Cost | 2150 |
| Sell | 1075 |
| Effective Against | Flying |
| Special Effects | Archer and Sniper only. Effective damage against flying units. |

## Astra

| Property | Value |
|---|---|
| Type | Bow |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 14 |
| Hit | 75 |
| Crit | 5 |
| Range | 2 |
| Durability | 30 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Grants Astra while equipped. Cannot be forged or purchased from StreetPass teams. |

## Parthia

| Property | Value |
|---|---|
| Type | Bow |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 19 |
| Hit | 95 |
| Crit | 5 |
| Range | 2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Usable item effect grants RES +5; buff decays by 1 per turn. Cannot be forged or purchased from StreetPass teams. |

## Yewfelle

| Property | Value |
|---|---|
| Type | Bow |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 15 |
| Hit | 85 |
| Crit | 10 |
| Range | 2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. SPD +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Nidhogg

| Property | Value |
|---|---|
| Type | Bow |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 16 |
| Hit | 75 |
| Crit | 10 |
| Range | 2 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. LCK +10 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Double Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | A |
| WEXP Requirement | 181 |
| Mt | 13 |
| Hit | 70 |
| Crit | 10 |
| Range | 2–3 |
| Durability | 25 |
| Cost | 0 |
| Sell | 0 |
| Effective Against | Flying |
| Special Effects | Archer and Sniper only. Effective damage against flying units. STR +5 when equipped. Cannot be forged or purchased from StreetPass teams. |

## Slack Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 1 |
| Hit | 90 |
| Crit | 0 |
| Range | 2 |
| Durability | 20 |
| Cost | 100 |
| Sell | 25 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Sells for 1/4 of its worth. |

## Towering Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 3 |
| Hit | 80 |
| Crit | 0 |
| Range | 2–3 |
| Durability | 10 |
| Cost | 810 |
| Sell | 202 |
| Effective Against | Flying |
| Special Effects | Archer and Sniper only. Effective damage against flying units. Sells for 1/4 of its worth. |

## Underdog Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | D |
| WEXP Requirement | 31 |
| Mt | 9 |
| Hit | 75 |
| Crit | 5 |
| Range | 2 |
| Durability | 15 |
| Cost | 990 |
| Sell | 247 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Grants Underdog while equipped. Sells for 1/4 of its worth. |

## Glass Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | E |
| WEXP Requirement | 1 |
| Mt | 13 |
| Hit | 75 |
| Crit | 0 |
| Range | 2 |
| Durability | 3 |
| Cost | 600 |
| Sell | 150 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Sells for 1/4 of its worth. |

## Superior Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 13 |
| Hit | 70 |
| Crit | 0 |
| Range | 2 |
| Durability | 10 |
| Cost | 2160 |
| Sell | 540 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Grants Bowbreaker while equipped. Sells for 1/4 of its worth. |

## Wolt's Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | C |
| WEXP Requirement | 71 |
| Mt | 10 |
| Hit | 85 |
| Crit | 5 |
| Range | 2 |
| Durability | 25 |
| Cost | 950 |
| Sell | 237 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Usable item effect restores 20 HP. Sells for 1/4 of its worth. |

## Innes' Bow

| Property | Value |
|---|---|
| Type | Bow |
| Rank | B |
| WEXP Requirement | 121 |
| Mt | 13 |
| Hit | 115 |
| Crit | 10 |
| Range | 2 |
| Durability | 15 |
| Cost | 1710 |
| Sell | 427 |
| Effective Against | Flying |
| Special Effects | Effective damage against flying units. Sells for 1/4 of its worth. |


---

# Weapon Count Audit

| Family | Entries |
|---|---:|
| Swords | 34 |
| Lances | 23 |
| Axes | 24 |
| Bows | 20 |
| Total | 101 |

---

# End of Phase 7 — Weapon Encyclopedia Part 1
