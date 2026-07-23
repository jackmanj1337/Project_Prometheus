> **Historical** — Superseded deferred content reference retained for provenance only.

# Fire Emblem TTRPG — Awakening Classes Only

This document contains official Fire Emblem: Awakening classes and promotions only.

# Fire Emblem TTRPG — Awakening Classes & Skills Reference

> **How to read this document:**
> - **Tier 1 (Base) classes** list base stats, stat caps, growth rates, primary/secondary skills, weapons, and promotion options.
> - **Tier 2 (Promoted) classes** are listed beneath their base class. They list class stat bonuses (applied at promotion), stat caps, growth rates, primary/secondary skills, and weapons.
> - **Enemy Growth Rates** are used to auto-level generic enemy units of that class.
> - **Player Growth Rates** are added to a player unit's individual growth rates while they are in that class.
> - Stat caps and growth rates previously marked `—` have been filled where possible. Official *Awakening* classes use historical FE:A values; homebrew/non-direct classes use explicitly labeled assumptions listed below.
> - Luck growth is **0%** for all classes (player growth rates).
> - All existing rules (promotion at level 20, max 4 skills, etc.) apply unless noted.

---

## Data Reconciliation Notes & Assumptions

**Reference basis.** Official *Fire Emblem: Awakening* class base stats, class maximum stats, player class growth rates, and enemy class growth rates were used wherever the class exists in FE:A. Luck growth remains 0% for all player class growth tables, matching FE:A class-growth convention.

**TTRPG-only fields retained.** `CON` and `LoS` are not FE:A class-table fields, so existing document values were retained unless already blank. FE:A movement values were applied to `MOV` where the class has official FE:A base movement.

**Class stat bonuses.** FE:A does not present promotion as tabletop-style “class stat bonuses” in the same document structure. For official promoted classes, this file now calculates promotion bonuses as: **promoted FE:A class base stats minus listed base-class FE:A base stats**. For homebrew/non-direct classes, the same calculation uses the assumed analogue listed below.

**Assumptions used for non-direct/homebrew classes.**
- **Bard:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Dancer** as the closest role/stat analogue.
- **Bishop:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Sage** as the closest role/stat analogue.
- **Brawler:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Berserker** as the closest role/stat analogue.
- **Brigand:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Barbarian** as the closest role/stat analogue.
- **Commander:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Paladin** as the closest role/stat analogue.
- **Dracoknight:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Wyvern Lord** as the closest role/stat analogue.
- **Druid:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Dark Mage** as the closest role/stat analogue.
- **Guardian:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **General** as the closest role/stat analogue.
- **Halberdier:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Soldier** as the closest role/stat analogue.
- **Mage Knight:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Dark Knight** as the closest role/stat analogue.
- **Necromancer:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Sorcerer** as the closest role/stat analogue.
- **Nomad:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Bow Knight** as the closest role/stat analogue.
- **Nomad Trooper:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Bow Knight** as the closest role/stat analogue.
- **Paragon:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Valkyrie** as the closest role/stat analogue.
- **Raider:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Bow Knight** as the closest role/stat analogue.
- **Ranger:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Bow Knight** as the closest role/stat analogue.
- **Rogue:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Trickster** as the closest role/stat analogue.
- **Sentinel:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Hero** as the closest role/stat analogue.
- **Skald:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **War Monk / War Cleric** as the closest role/stat analogue.
- **Soulblade:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Dark Knight** as the closest role/stat analogue.
- **Troubadour:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Valkyrie** as the closest role/stat analogue.
- **Vanguard:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Great Knight** as the closest role/stat analogue.
- **Warlock:** no direct FE:A class record found in the class tables used here; filled caps/growths and, where applicable, promotion bonuses using **Sorcerer** as the closest role/stat analogue.

**Important unresolved limitation.** Skill names/descriptions were not fully reconciled against FE:A in this pass; the requested data reconciliation focused on class numeric data: base stats, stat caps, growth rates, and promotion/class-stat bonuses.

---

---

## Skills Quick Reference

> Full skill descriptions are in the Skills section at the end of this document.

If Data is missing, try pulling from https://fireemblem.fandom.com/wiki/List_of_classes_in_Fire_Emblem_Awakening

### Skills Already in the Base Handbook
| Awakening Skill | Handbook Equivalent |
|-----------------|---------------------|
| Vantage | Vantage |
| Wrath | Wrath |
| Miracle | Miracle |
| Nihil | Nihil |
| Renewal | Renewal |
| Astra | Astra (Swordmaster Secondary) |
| Pavise | Pavise (Great Knight Primary) |
| Aegis | Aegis (Mage Knight Primary) |
| Locktouch | Pick (Thief line) |
| Movement +1 | Celerity |
| Counter | Counter (Vanguard Primary) |
| Hex | Hex (Warlock Secondary) |
| Savior | Savior |

---

---

# TIER 1 — BASE CLASSES

## Archer
*Lightly armored warriors who attack from a distance.*

**Weapons:** Bow
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 16 | 5 | 0 | 8 | 6 | 0 | 5 | 0 | 5 | 6 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 26 | 20 | 29 | 25 | 30 | 25 | 21 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 25 | 0 | 40 | 25 | 25 | 25 | 15 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 15 | 0 | 30 | 15 | 0 | 10 | 5 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Ranger
- Sniper
- Bow Knight *(Awakening alternative)*

---

### → Ranger
*Soldiers of the wilderness who utilize both the sword and bow to deadly effect.*

**Weapons:** Bow, Sword
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +8 | +3 | +0 | +2 | +4 | +0 | +1 | +2 | +3 |

#### Stat Caps
*Ranger is a homebrew promotion — no official FE:A data.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 40 | 30 | 43 | 41 | 45 | 35 | 30 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 35 | 0 | 40 | 40 | 35 | 25 | 15 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 20 | 0 | 25 | 20 | 0 | 5 | 5 |

#### Skills
**Primary:** Swiftfoot
**Secondary:** Multishot

---

### → Sniper
*Veteran archers whose skill with the bow is unmatched.*

**Weapons:** Bow
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +4 | +2 | +1 | +4 | +3 | +0 | +5 | +3 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 41 | 30 | 48 | 40 | 45 | 40 | 31 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 35 | 0 | 50 | 40 | 35 | 30 | 25 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 15 | 0 | 30 | 15 | 0 | 15 | 5 |

#### Skills
**Primary:** Hawkeye
**Secondary:** Deadeye

---

### → Bow Knight *(Awakening alternative)*
*Mounted warriors who blend swordsmanship with deadly long-range archery.*

**Promotes From:** Archer or Mercenary
**Weapons:** Sword, Bow
**Type:** Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|-----|-----|-----|-----|-----|-----|-----|-----|
| +2 | +3 | +0 | +3 | +2 | — | +2 | +1 | +2 |

> *Proficiency gained: Sword (if from Archer) or Bow (if from Mercenary).*

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 40 | 30 | 43 | 41 | 45 | 35 | 30 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 90 | 35 | 0 | 40 | 40 | 35 | 25 | 15 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 50 | 20 | 0 | 25 | 20 | 0 | 5 | 5 |

#### Skills
**Primary:** Bowfaire
**Secondary:** Rally Skill

---



## Barbarian *(Awakening)*
*Wild, brutal axe fighters who rely on raw power and aggression.*

> Distinct from the Brigand class. Barbarians are faster and slightly less bulky, favoring aggression over raw power.

**Weapons:** Axe
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| 25 | 9 | 0 | 4 | 6 | 4 | 2 | 1 | 5 | 10 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 60 | 30 | 20 | 23 | 27 | 30 | 22 | 20 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 90 | 40 | 0 | 20 | 30 | 20 | 20 | 5 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 50 | 25 | 0 | 15 | 20 | 0 | 5 | 5 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Berserker *(see Brigand → Berserker)*
- Warrior *(see Fighter → Warrior)*

---



## Cavalier
*Mounted knights with superior movement.*

**Weapons:** Axe, Lance, or Sword (choose one)
**Type:** Mounted

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 18 | 6 | 0 | 5 | 6 | 0 | 7 | 0 | 7 | 18 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 26 | 20 | 25 | 25 | 30 | 26 | 26 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 35 | 0 | 30 | 30 | 35 | 30 | 15 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 20 | 0 | 20 | 20 | 0 | 10 | 5 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Paladin
- Vanguard

---

### → Paladin
*Talented cavaliers dedicated to the art of horsemanship.*

**Weapons:** Sword, Lance (+ one additional at promotion)
**Type:** Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +7 | +3 | +1 | +2 | +2 | +0 | +3 | +6 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 42 | 30 | 40 | 40 | 45 | 42 | 42 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 45 | 0 | 40 | 40 | 45 | 35 | 30 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 20 | 0 | 20 | 20 | 0 | 10 | 10 |

#### Skills
**Primary:** Strike True
**Secondary:** Challenge

---

### → Vanguard
*Battle-hardened cavaliers who excel on the frontlines.*

**Weapons:** Axe, Lance, or Sword (as held)
**Type:** Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +8 | +5 | +0 | +1 | -1 | +0 | +7 | +1 | +0 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 48 | 20 | 34 | 37 | 45 | 48 | 30 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 95 | 45 | 0 | 30 | 30 | 40 | 35 | 15 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 25 | 0 | 15 | 15 | 0 | 15 | 5 |

#### Skills
**Primary:** Counter
**Secondary:** Supremacy

---



## Cleric
*Holy wielders of radiant magic and staves.*

**Weapons:** Light, Staff
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 16 | 0 | 3 | 2 | 4 | 0 | 1 | 6 | 5 | 6 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 22 | 25 | 24 | 25 | 30 | 22 | 27 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 0 | 20 | 20 | 20 | 40 | 15 | 35 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 35 | 5 | 15 | 15 | 15 | 0 | 5 | 15 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Bishop
- Paragon
- War Monk / War Cleric *(Awakening alternative)*

---

### → Bishop
*An honorary given to those who have reached enlightenment.*

**Weapons:** Light, Staff
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +4 | +1 | +4 | +3 | +3 | +0 | +3 | -1 | +1 |

#### Stat Caps
*Homebrew promotion — no direct FE:A Bishop equivalent (nearest: War Cleric).*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 30 | 46 | 43 | 42 | 45 | 31 | 40 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 70 | 0 | 40 | 40 | 40 | 40 | 20 | 35 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 35 | 0 | 20 | 20 | 20 | 0 | 5 | 10 |

#### Skills
**Primary:** Blessing
**Secondary:** Holy Aura

---

### → Paragon
*Blessed warriors who fight for holy causes.*

**Weapons:** Light, Lance, Staff
**Type:** Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +3 | +0 | +2 | +2 | +4 | +0 | +2 | +2 | +3 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 30 | 42 | 38 | 43 | 45 | 30 | 45 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 70 | 0 | 40 | 30 | 50 | 50 | 20 | 45 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 35 | 0 | 20 | 10 | 20 | 0 | 5 | 15 |

#### Skills
**Primary:** Boon
**Secondary:** Judgement

---

### → War Monk / War Cleric *(Awakening)*
*Clerics who discovered that healing and smiting are not mutually exclusive.*

**Weapons:** Axe (War Monk) or Bow (War Cleric), Staff
**Type:** —

> At promotion, choose either War Monk (gains Axe) or War Cleric (gains Bow).

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|-----|-----|-----|-----|-----|-----|-----|-----|
| +3 | +4 | +0 | +1 | +1 | — | +2 | +1 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 40 | 40 | 38 | 41 | 45 | 38 | 43 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 90 | 40 | 35 | 30 | 45 | 45 | 30 | 40 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 45 | 15 | 15 | 10 | 15 | 0 | 10 | 10 |

#### Skills
**Primary:** Sol
**Secondary:** Odd Rhythm *(War Monk)* / Even Rhythm *(War Cleric)*

---



## Dancer *(Special — no promotion)*
*Graceful performers whose art energizes exhausted allies to fight on.*

> Dancers do not promote. Their power lies entirely in their unique ability to refresh allies.

**Weapons:** Sword
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| 15 | 2 | 4 | 5 | 9 | 10 | 1 | 4 | 6 | 5 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 30 | 30 | 40 | 40 | 45 | 30 | 30 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 70 | 30 | 0 | 50 | 50 | 50 | 15 | 10 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 35 | 5 | 0 | 25 | 25 | 0 | 5 | 5 |

### Skills
**Primary:** Special Dance
**Secondary:** —

> **Special Dance:** Once per turn as an action, target 1 adjacent ally who has already acted this turn. That ally may immediately take another full turn. The Dancer also chooses one stat (STR, SPD, SKL, or LUK); the target gains +4 to that stat until the start of the next turn. Cannot target the same unit twice in a row, and cannot target the Dancer itself.

---



## Dark Mage *(Awakening)*
*Students of forbidden dark arts whose power comes at a cost.*

> Distinct from the Druid class. Dark Mages are a more offensive, glass-cannon dark magic user.

**Weapons:** Dark (Tome)
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| 19 | 2 | 8 | 5 | 4 | 3 | 3 | 6 | 5 | 6 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 60 | 20 | 27 | 25 | 25 | 30 | 25 | 27 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 0 | 25 | 20 | 20 | 20 | 25 | 25 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 50 | 5 | 15 | 15 | 15 | 0 | 10 | 10 |

### Skills
**Primary:** Anathema
**Secondary:** —

### Promotes To
- Sorcerer
- Dark Knight

---

### → Sorcerer
*Dark Mages who have plumbed the depths of forbidden power and emerged changed.*

**Weapons:** Dark (Tome)
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +5 | +1 | +3 | +2 | +1 | +0 | +3 | +3 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 30 | 44 | 38 | 40 | 45 | 41 | 44 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 0 | 40 | 30 | 30 | 30 | 30 | 35 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 0 | 20 | 15 | 15 | 0 | 10 | 10 |

#### Skills
**Primary:** Vengeance
**Secondary:** Tomebreaker

---

### → Dark Knight
*Dark mages who took to horseback, blending steel and sorcery.*

**Weapons:** Sword, Dark (Tome)
**Type:** Mounted

> Also available as a promotion for the Mage class.

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +7 | +3 | +2 | +4 | +2 | +0 | +5 | +1 | +3 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 38 | 41 | 40 | 40 | 45 | 42 | 38 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 95 | 35 | 40 | 40 | 30 | 30 | 35 | 30 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 15 | 15 | 15 | 15 | 0 | 10 | 5 |

#### Skills
**Primary:** Lifetaker
**Secondary:** Shadowgift

---



## Fighter
*Combatants whose strength and hardiness carry them to glory.*

**Weapons:** Axe
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 20 | 8 | 0 | 5 | 5 | 0 | 4 | 0 | 5 | 9 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 29 | 20 | 26 | 25 | 30 | 25 | 23 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 85 | 40 | 0 | 30 | 20 | 35 | 25 | 10 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 25 | 0 | 20 | 15 | 0 | 10 | 5 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Guardian
- Warrior

---

### → Guardian
*Fighters who have gotten their allies through countless perils.*

**Weapons:** Axe, Lance
**Type:** Armoured

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +8 | +4 | +0 | +2 | -1 | +0 | +11 | +3 | +0 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 50 | 30 | 41 | 35 | 45 | 50 | 35 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 100 | 50 | 0 | 35 | 25 | 40 | 35 | 20 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 25 | 0 | 15 | 10 | 0 | 15 | 10 |

#### Skills
**Primary:** Redirect
**Secondary:** Parry

---

### → Warrior
*Battle-tested warriors who have proven their strength.*

**Weapons:** Axe, Bow
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +8 | +4 | +0 | +3 | +2 | +0 | +3 | +3 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 48 | 30 | 42 | 40 | 45 | 40 | 35 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 95 | 50 | 0 | 40 | 30 | 45 | 30 | 20 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 25 | 0 | 20 | 15 | 0 | 10 | 5 |

#### Skills
**Primary:** Cripple
**Secondary:** No Escape

---



## Knight
*Heavily armoured knights whose great defense acts like a wall against all.*

**Weapons:** Lance
**Type:** Armoured

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 18 | 8 | 0 | 4 | 2 | 0 | 11 | 0 | 4 | 15 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 30 | 20 | 26 | 23 | 30 | 30 | 22 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 40 | 0 | 25 | 15 | 30 | 30 | 10 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 25 | 0 | 15 | 10 | 0 | 15 | 5 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- General
- Great Knight

---

### → General
*Seasoned knights who can hold off whole battalions by themselves.*

**Weapons:** Lance, Axe
**Type:** Armoured

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +10 | +4 | +0 | +3 | +2 | +0 | +4 | +3 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 50 | 30 | 41 | 35 | 45 | 50 | 35 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 100 | 50 | 0 | 35 | 25 | 40 | 35 | 20 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 25 | 0 | 15 | 10 | 0 | 15 | 10 |

#### Skills
**Primary:** Bastion
**Secondary:** Iron Wall

---

### → Great Knight
*Mounted knights who crash down upon their foes as a highly mobile wall of steel.*

**Weapons:** Sword, Lance, Axe
**Type:** Armoured, Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +8 | +3 | +0 | +2 | +3 | +0 | +3 | +1 | +3 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 48 | 20 | 34 | 37 | 45 | 48 | 30 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 95 | 45 | 0 | 30 | 30 | 40 | 35 | 15 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 25 | 0 | 15 | 15 | 0 | 15 | 5 |

#### Skills
**Primary:** Pavise
**Secondary:** Charge

---



## Lord *(Awakening)*
*Noble leaders who fight for their people with sword in hand.*

**Weapons:** Sword
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| 19 | 8 | 0 | 7 | 7 | 7 | 6 | 2 | 6 | 9 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 60 | 25 | 20 | 26 | 28 | 30 | 25 | 25 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 70 | 40 | 0 | 30 | 30 | 40 | 25 | 20 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 40 | 20 | 0 | 20 | 20 | 0 | 10 | 5 |

### Skills
**Primary:** Charm
**Secondary:** —

### Promotes To
- Great Lord

---

### → Great Lord *(Awakening)*
*Lords who have realized their full potential as warriors and leaders.*

**Weapons:** Sword, Lance
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|-----|-----|-----|-----|-----|-----|-----|-----|
| +3 | +2 | +0 | +2 | +2 | — | +2 | +2 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 43 | 30 | 40 | 41 | 45 | 42 | 40 |

*(Male variant — Female variant: STR 40, SKL 42, SPD 44)*

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 50 | 0 | 40 | 40 | 50 | 30 | 25 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 40 | 20 | 0 | 20 | 20 | 0 | 10 | 5 |

#### Skills
**Primary:** Rightful King
**Secondary:** Aether

---



## Mage
*Those schooled in anima magic who buffet foes with the elements.*

**Weapons:** Anima (choose two: Fire, Thunder, Wind)
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 16 | 0 | 4 | 3 | 4 | 0 | 2 | 3 | 5 | 5 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 20 | 28 | 27 | 26 | 30 | 21 | 25 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 0 | 35 | 30 | 30 | 30 | 15 | 25 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 35 | 0 | 20 | 20 | 20 | 0 | 5 | 10 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Mage Knight
- Sage
- Dark Knight *(Awakening alternative)*

---

### → Mage Knight
*Mobile mages who found excellence on the battlefield.*

**Weapons:** Anima (as held)
**Type:** Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +9 | +4 | +1 | +3 | +1 | +0 | +7 | +2 | +3 |

#### Stat Caps
*Homebrew promotion — no direct FE:A equivalent.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 38 | 41 | 40 | 40 | 45 | 42 | 38 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 95 | 35 | 40 | 40 | 30 | 30 | 35 | 30 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 15 | 15 | 15 | 15 | 0 | 10 | 5 |

#### Skills
**Primary:** Aegis
**Secondary:** Flare

---

### → Sage
*Arcane masters who delved into their art and came out with greater knowledge.*

**Weapons:** Anima (as held), + one additional (Dark, Light, Fire, Staff, Thunder, or Wind)
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +4 | +1 | +3 | +2 | +3 | +0 | +2 | +2 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 30 | 46 | 43 | 42 | 45 | 31 | 40 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 70 | 0 | 40 | 40 | 40 | 40 | 20 | 35 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 35 | 0 | 20 | 20 | 20 | 0 | 5 | 10 |

#### Skills
**Primary:** Phasing
**Secondary:** Deeper Knowledge

---



## Mercenary
*Professional soldiers with superior combat prowess.*

**Weapons:** Sword
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 18 | 5 | 0 | 8 | 7 | 0 | 5 | 0 | 5 | 8 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 26 | 20 | 28 | 26 | 30 | 25 | 23 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 35 | 0 | 40 | 35 | 30 | 25 | 15 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 20 | 0 | 25 | 20 | 0 | 10 | 5 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Hero
- Sentinel
- Bow Knight *(Awakening alternative)*

---

### → Hero
*The finest of mercenaries who have proven their capabilities.*

**Weapons:** Sword, Axe
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +4 | +3 | +1 | +3 | +3 | +0 | +3 | +3 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 42 | 30 | 46 | 42 | 45 | 40 | 36 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 45 | 0 | 50 | 45 | 40 | 30 | 25 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 20 | 0 | 25 | 20 | 0 | 10 | 5 |

#### Skills
**Primary:** Dash
**Secondary:** Disarm

---

### → Sentinel
*Professional fighters with a keen awareness of their surroundings.*

**Weapons:** Sword, Lance
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | LoS |
|----|----|----|----|----|----|----|----|----|----|
| +4 | +3 | +1 | +3 | +3 | +0 | +3 | +3 | +1 | — |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 42 | 30 | 46 | 42 | 45 | 40 | 36 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 45 | 0 | 50 | 45 | 40 | 30 | 25 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 20 | 0 | 25 | 20 | 0 | 10 | 5 |

#### Skills
**Primary:** Vigilance
**Secondary:** Diehard

---



## Myrmidon
*Swordsmen specialized in killing blade strokes.*

**Weapons:** Sword
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 16 | 4 | 1 | 9 | 10 | 0 | 4 | 1 | 5 | 6 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 24 | 22 | 27 | 28 | 30 | 22 | 24 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 70 | 30 | 0 | 40 | 40 | 40 | 20 | 20 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 40 | 20 | 0 | 25 | 25 | 0 | 5 | 5 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Soulblade
- Swordmaster

---

### → Soulblade
*Swordsmen wielding arcane blades which can bypass armour.*

**Weapons:** Sword, + one magic type (Dark, Fire, Light, Thunder, or Wind)
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +9 | +0 | +4 | -3 | -5 | +0 | +5 | +4 | +3 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 38 | 41 | 40 | 40 | 45 | 42 | 38 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 95 | 35 | 40 | 40 | 30 | 30 | 35 | 30 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 15 | 15 | 15 | 15 | 0 | 10 | 5 |

#### Skills
**Primary:** Infuse
**Secondary:** Arcane Rush

---

### → Swordmaster
*Those dedicated to the sword who can cut down foes faster than lightning.*

**Weapons:** Sword
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +4 | +3 | +1 | +2 | +3 | +0 | +2 | +3 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 38 | 34 | 44 | 46 | 45 | 33 | 38 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 40 | 0 | 50 | 50 | 50 | 25 | 30 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 40 | 20 | 0 | 25 | 25 | 0 | 5 | 10 |

#### Skills
**Primary:** Finesse
**Secondary:** Astra

---



## Pegasus Knight
*Mounted knights who travel the skies on pegasi.*

**Weapons:** Lance
**Type:** Flying, Mounted

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 16 | 4 | 2 | 7 | 8 | 0 | 4 | 6 | 7 | 16 | 5 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 24 | 23 | 28 | 27 | 30 | 22 | 25 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 70 | 20 | 0 | 40 | 40 | 50 | 20 | 35 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 40 | 15 | 5 | 25 | 25 | 0 | 5 | 10 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Falcoknight
- Valkyrie
- Dark Flier *(Awakening alternative)*

---

### → Falcoknight
*Pegasus knights who rule the skies with their blistering speed.*

**Weapons:** Lance, Sword
**Type:** Flying, Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +4 | +2 | +1 | +3 | +3 | +0 | +2 | +3 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 38 | 35 | 45 | 44 | 45 | 33 | 40 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 35 | 30 | 50 | 50 | 60 | 25 | 45 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 40 | 15 | 10 | 25 | 25 | 0 | 5 | 10 |

#### Skills
**Primary:** Air Superiority
**Secondary:** Giantkiller

---

### → Valkyrie
*Blessed Pegasus knights renowned for their grace and magic.*

**Weapons:** Lance, Light, Staff *(also uses Tome and Staff per FE:A)*
**Type:** Flying, Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +3 | -4 | +3 | -3 | +0 | +0 | -1 | +2 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 30 | 42 | 38 | 43 | 45 | 30 | 45 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 70 | 0 | 40 | 30 | 50 | 50 | 20 | 45 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 35 | 0 | 20 | 10 | 20 | 0 | 5 | 15 |

#### Skills
**Primary:** Holy Conduit
**Secondary:** Favoured

---

### → Dark Flier *(Awakening)*
*Pegasus knights who traded divine light for arcane darkness, gaining tremendous magical power.*

**Weapons:** Lance, Dark (Tome)
**Type:** Flying, Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|-----|-----|-----|-----|-----|-----|-----|-----|
| +2 | +1 | +4 | +1 | +2 | — | +1 | +2 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 36 | 42 | 41 | 42 | 45 | 32 | 41 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 75 | 25 | 35 | 40 | 45 | 55 | 25 | 45 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 40 | 10 | 15 | 20 | 20 | 0 | 5 | 10 |

#### Skills
**Primary:** Galeforce
**Secondary:** Rally Magic

---



## Tactician *(Awakening)*
*Strategic battlefield commanders who combine swordplay with elemental magic.*

**Weapons:** Sword, Anima (Fire, Thunder, or Wind — choose one)
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| 17 | 5 | 6 | 7 | 6 | 5 | 3 | 5 | 6 | 7 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 60 | 25 | 25 | 25 | 25 | 30 | 25 | 25 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 70 | 30 | 30 | 30 | 30 | 30 | 20 | 20 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 40 | 15 | 15 | 15 | 15 | 0 | 10 | 10 |

### Skills
**Primary:** Veteran
**Secondary:** —

> **Veteran:** This unit gains 1.5× EXP from all sources (rounded up).

### Promotes To
- Grandmaster

---

### → Grandmaster *(Awakening)*
*Tacticians who have mastered both the art of war and arcane power.*

**Weapons:** Sword, Anima (two types — gains one additional at promotion)
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|-----|-----|-----|-----|-----|-----|-----|-----|
| +2 | +2 | +2 | +2 | +1 | — | +2 | +2 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 40 | 40 | 40 | 40 | 45 | 40 | 40 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 40 | 40 | 40 | 40 | 40 | 25 | 25 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 40 | 15 | 15 | 15 | 15 | 0 | 10 | 10 |

#### Skills
**Primary:** Ignis
**Secondary:** Rally Spectrum

---



## Villager *(Awakening)*
*Ordinary people with extraordinary potential — untrained, but full of luck and grit.*

**Weapons:** Lance
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| 16 | 5 | 0 | 5 | 5 | 8 | 3 | 2 | 6 | 7 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 60 | 20 | 20 | 20 | 20 | 30 | 20 | 20 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 20 | 0 | 20 | 20 | 20 | 20 | 5 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 35 | 10 | 0 | 5 | 5 | 0 | 10 | 5 |

### Skills
**Primary:** Underdog
**Secondary:** —

### Promotes To
GM's discretion — any non-mounted, non-magical base class from the handbook, reflecting the Villager's potential to become anything.

---
