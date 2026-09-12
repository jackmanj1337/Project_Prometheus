# Tactical RPG — Homebrew Classes Only

This document contains homebrew classes and promotions separated from official Awakening content.

# Tactical RPG — Awakening Classes & Skills Reference

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

**Reference basis.** Class base stats, class maximum stats, player class growth rates, and enemy class growth rates were adapted from the legacy tactical-RPG source material wherever the class exists there. Luck growth remains 0% for all player class growth tables, matching that source's class-growth convention.

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

## Bard
*Talented individuals who inspire their allies in battle.*

**Weapons:** Knife
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 16 | 1 | 1 | 5 | 8 | 0 | 3 | 1 | 5 | 5 | 4 |

### Stat Caps
*Bard is a homebrew class — no official FE:A data.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 30 | 30 | 40 | 40 | 45 | 30 | 30 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 70 | 30 | 0 | 50 | 50 | 50 | 15 | 10 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 35 | 5 | 0 | 25 | 25 | 0 | 5 | 5 |

### Skills
**Primary:** Canto
**Secondary:** —

### Promotes To
- Skald
- Troubadour

---

### → Skald
*Hardy warriors who inspire their allies from the frontlines.*

**Weapons:** Knife, Axe
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +8 | +4 | +4 | -1 | -2 | +0 | +3 | +5 | +1 |

#### Stat Caps
*Homebrew class — no official FE:A data.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 40 | 40 | 38 | 41 | 45 | 38 | 43 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 40 | 35 | 30 | 45 | 45 | 30 | 40 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 15 | 15 | 10 | 15 | 0 | 10 | 10 |

#### Skills
**Primary:** Battle Cry
**Secondary:** Encore

---

### → Troubadour
*Mounted performers whose sacred staves aid allies.*

**Weapons:** Knife, Staff
**Type:** Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +3 | -1 | +4 | -1 | +0 | +0 | +0 | +7 | +3 |

#### Stat Caps
*Homebrew promotion — see Valkyrie/Troubadour for nearest FE:A reference.*

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
**Primary:** Resonance
**Secondary:** Inspire

---



## Brigand
*Mighty axe-fighters who fell enemies with brute strength.*

**Weapons:** Axe
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 22 | 8 | 0 | 3 | 8 | 0 | 3 | 0 | 5 | 11 | 4 |

### Stat Caps
*Homebrew class — no FE:A equivalent (Brigand ≠ Barbarian).*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 30 | 20 | 23 | 27 | 30 | 22 | 20 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 40 | 0 | 20 | 30 | 20 | 20 | 5 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 25 | 0 | 15 | 20 | 0 | 5 | 5 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Berserker
- Brawler

---

### → Berserker
*Those skilled in killing blows who live to fight.*

**Weapons:** Axe
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +8 | +5 | +0 | +2 | +3 | +0 | +2 | +1 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 50 | 30 | 35 | 44 | 45 | 34 | 30 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 100 | 60 | 0 | 30 | 40 | 30 | 25 | 15 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 25 | 0 | 15 | 20 | 0 | 5 | 5 |

#### Skills
**Primary:** Frenzy
**Secondary:** Rage

---

### → Brawler
*Powerhouses who throw their opponents around with ease.*

**Weapons:** Axe, Sword
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +8 | +5 | +0 | +2 | +3 | +0 | +2 | +1 | +1 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 50 | 30 | 35 | 44 | 45 | 34 | 30 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 100 | 60 | 0 | 30 | 40 | 30 | 25 | 15 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 25 | 0 | 15 | 20 | 0 | 5 | 5 |

#### Skills
**Primary:** Bulldozer
**Secondary:** Cleave

---



## Druid
*Powerful wielders of the ancient dark magic arts.*

**Weapons:** Dark (Tome)
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 18 | 1 | 3 | 2 | 3 | 0 | 4 | 4 | 5 | 7 | 4 |

### Stat Caps
*Homebrew class — no FE:A equivalent. Use Dark Mage caps for reference.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 20 | 27 | 25 | 25 | 30 | 25 | 27 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 0 | 25 | 20 | 20 | 20 | 25 | 25 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 5 | 15 | 15 | 15 | 0 | 10 | 10 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Necromancer
- Warlock

---

### → Necromancer
*Masters of dark magic who use it to control the dead.*

**Weapons:** Dark (Tome)
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +5 | +1 | +3 | +2 | +1 | +0 | +3 | +3 | +1 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

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
**Primary:** Rise
**Secondary:** Army of the Dead

---

### → Warlock
*Wielders of both dark and anima magic who curse their foes.*

**Weapons:** Dark (Tome), Anima (Fire or Thunder or Wind — choose one)
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +5 | +1 | +3 | +2 | +1 | +0 | +3 | +3 | +1 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

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
**Primary:** Drain
**Secondary:** Hex

---



## Nomad
*Incredibly swift archers riding on horseback.*

**Weapons:** Bow
**Type:** Mounted

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 24 | 8 | 0 | 10 | 10 | 0 | 6 | 2 | 8 | 14 | 4 |

### Stat Caps
*Homebrew class — no FE:A equivalent.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 40 | 30 | 43 | 41 | 45 | 35 | 30 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 35 | 0 | 40 | 40 | 35 | 25 | 15 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 50 | 20 | 0 | 25 | 20 | 0 | 5 | 5 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Nomad Trooper
- Raider

---

### → Nomad Trooper
*Sword-swinging, arrow-flinging battle hardened nomadic warriors.*

**Weapons:** Bow, Sword
**Type:** Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +0 | +0 | +0 | +0 | +0 | +0 | +0 | +0 | +0 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

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
**Primary:** Flanking
**Secondary:** Master Horseman

---

### → Raider
*Nomads specializing in hit-and-run tactics with both lance and bow.*

**Weapons:** Bow, Lance
**Type:** Mounted

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +0 | +0 | +0 | +0 | +0 | +0 | +0 | +0 | +0 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

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
**Primary:** Trample
**Secondary:** Pierce

---



## Soldier
*Footsoldiers with great versatility and potential everywhere.*

**Weapons:** Lance
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 20 | 5 | 0 | 5 | 5 | 0 | 5 | 0 | 5 | 8 | 4 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 30 | 30 | 30 | 30 | 45 | 30 | 30 |

*(Soldier exists as a special class in FE:A — caps listed are for that version.)*

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 30 | 0 | 30 | 30 | 30 | 30 | 15 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 40 | 10 | 0 | 10 | 10 | 0 | 5 | 5 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Commander
- Halberdier

---

### → Commander
*Soldiers who have risen in the ranks and inspire their comrades.*

**Weapons:** Lance, Sword
**Type:** Armoured

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +5 | +4 | +1 | +2 | +3 | +0 | +5 | +6 | +3 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

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
**Primary:** Motivate
**Secondary:** Rally

---

### → Halberdier
*Skilled lancers capable of downing foes in a single thrust.*

**Weapons:** Lance
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +0 | +0 | +0 | +0 | +0 | +0 | +0 | +0 | +0 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 30 | 30 | 30 | 30 | 45 | 30 | 30 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 30 | 0 | 30 | 30 | 30 | 30 | 15 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 40 | 10 | 0 | 10 | 10 | 0 | 5 | 5 |

#### Skills
**Primary:** Lunge
**Secondary:** Impale

---



## Thief
*Fortune-seekers skilled both in and out of combat.*

**Weapons:** Knife
**Type:** —

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 16 | 3 | 0 | 6 | 8 | 0 | 2 | 0 | 5 | 5 | 6 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 22 | 20 | 30 | 28 | 30 | 21 | 20 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 20 | 0 | 40 | 40 | 20 | 20 | 5 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 35 | 15 | 5 | 25 | 25 | 0 | 5 | 5 |

### Skills
**Primary:** Pick
**Secondary:** —

### Promotes To
- Assassin
- Rogue
- Trickster *(Awakening alternative)*

---

### → Assassin
*Agile and powerful deliverers of instant death.*

**Weapons:** Knife *(FE:A: Sword, Bow)*
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +5 | +5 | +0 | +7 | +4 | +0 | +3 | +1 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 40 | 30 | 48 | 46 | 45 | 31 | 30 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 40 | 0 | 50 | 50 | 30 | 25 | 15 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 40 | 20 | 0 | 30 | 25 | 0 | 5 | 5 |

#### Skills
**Primary:** Reaper
**Secondary:** Lethality

---

### → Rogue
*Lightning-fast thieves who take what they please.*

**Weapons:** Knife, Bow
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +3 | +1 | +4 | +4 | +3 | +0 | +1 | +5 | +1 |

#### Stat Caps
*Homebrew promotion — no official FE:A data.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 35 | 38 | 45 | 43 | 45 | 30 | 40 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 70 | 40 | 35 | 45 | 45 | 35 | 25 | 25 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 35 | 10 | 15 | 25 | 20 | 0 | 5 | 10 |

#### Skills
**Primary:** Steal
**Secondary:** Fast Fingers

---

### → Trickster *(Awakening)*
*Thieves who learned to mend what they couldn't steal, combining magic utility with acrobatic swordsmanship.*

**Weapons:** Knife *(FE:A: Sword)*, Staff
**Type:** —

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|-----|-----|-----|-----|-----|-----|-----|-----|
| +2 | +2 | +2 | +3 | +3 | — | +1 | +2 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 35 | 38 | 45 | 43 | 45 | 30 | 40 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 70 | 40 | 35 | 45 | 45 | 35 | 25 | 25 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 35 | 10 | 15 | 25 | 20 | 0 | 5 | 10 |

#### Skills
**Primary:** Acrobat
**Secondary:** Pass

---



## Wyvern Rider
*Knights on wyvernback who are a terror to face on the ground or in the air.*

**Weapons:** Lance *(FE:A: Axe)*
**Type:** Dragon, Flying

### Base Stats
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV | CON | LoS |
|----|----|----|----|----|----|----|----|----|----|----|
| 19 | 7 | 0 | 6 | 5 | 0 | 8 | 0 | 7 | 24 | 5 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 60 | 28 | 20 | 24 | 24 | 30 | 28 | 20 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 40 | 0 | 25 | 25 | 30 | 30 | 5 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 30 | 0 | 15 | 15 | 0 | 10 | 5 |

### Skills
**Primary:** —
**Secondary:** —

### Promotes To
- Dracoknight
- Wyvern Lord
- Griffon Rider *(Awakening alternative)*

---

### → Dracoknight
*Knights who have an unbreakable bond with their flame-spewing wyvern.*

**Weapons:** Lance, Fire (Tome)
**Type:** Dragon, Flying

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +5 | +4 | +0 | +2 | +2 | +0 | +3 | +3 | +1 |

#### Stat Caps
*Homebrew promotion — no direct FE:A equivalent.*

| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 46 | 30 | 38 | 38 | 45 | 46 | 30 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 50 | 0 | 35 | 35 | 40 | 35 | 15 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 30 | 0 | 15 | 15 | 0 | 10 | 5 |

#### Skills
**Primary:** Firebreathing
**Secondary:** Inferno

---

### → Wyvern Lord
*Wyvern knights who rule the battlefield on enormous wyverns.*

**Weapons:** Lance, Axe
**Type:** Dragon, Flying

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|----|----|----|----|----|----|----|----|
| +5 | +4 | +0 | +2 | +2 | +0 | +3 | +3 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 80 | 46 | 30 | 38 | 38 | 45 | 46 | 30 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 90 | 50 | 0 | 35 | 35 | 40 | 35 | 15 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|----|----|----|----|----|----|----|
| 45 | 30 | 0 | 15 | 15 | 0 | 10 | 5 |

#### Skills
**Primary:** Ironhide
**Secondary:** Fearsome

---

### → Griffon Rider *(Awakening)*
*Wyvern riders who bonded with griffins instead — swift, resistant, and free of draconic weakness.*

**Weapons:** Axe
**Type:** Flying

> Griffon Riders do **not** have the Dragon special quality. They are not subject to Dragon-effective weapons.

#### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|-----|-----|-----|-----|-----|-----|-----|-----|
| +3 | +2 | +0 | +2 | +3 | — | +2 | +2 | +1 |

#### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 40 | 30 | 43 | 41 | 45 | 40 | 30 |

#### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 90 | 40 | 0 | 40 | 40 | 40 | 30 | 15 |

#### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 45 | 25 | 0 | 20 | 20 | 0 | 5 | 5 |

#### Skills
**Primary:** Deliverer
**Secondary:** Lancebreaker

---

---

# TIER 2 — STANDALONE PROMOTED CLASSES (DLC)

*These classes can be promoted into from various base classes at GM discretion.*

---



## Dread Fighter *(DLC)*
*Elite warriors who pushed past their limits through forbidden training, mastering multiple weapon forms.*

**Promotes From:** Any physical base class (Brigand, Fighter, Mercenary, Myrmidon, Soldier, or Barbarian) at GM discretion
**Weapons:** Sword, Axe, Dark (Tome)
**Type:** —

### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|-----|-----|-----|-----|-----|-----|-----|-----|
| +3 | +3 | +1 | +3 | +3 | — | +2 | +2 | +1 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 42 | 38 | 40 | 41 | 45 | 39 | 43 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 40 | 20 | 40 | 40 | 40 | 25 | 25 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 40 | 20 | 10 | 20 | 20 | 0 | 10 | 10 |

### Skills
**Primary:** Aggressor
**Secondary:** Swordfaire

---



## Bride *(DLC)*
*Those who channel love and unity into combat support, excelling at keeping allies fighting.*

**Promotes From:** Any base class at GM discretion
**Weapons:** Lance, Bow, Staff (choose one at promotion if not already held)
**Type:** —

### Class Stat Bonuses
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES | MOV |
|----|-----|-----|-----|-----|-----|-----|-----|-----|
| +2 | +2 | +2 | +2 | +2 | — | +1 | +2 | +1 |

### Stat Caps
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 40 | 39 | 42 | 42 | 45 | 41 | 40 |

### Enemy Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 80 | 40 | 20 | 40 | 40 | 40 | 25 | 25 |

### Player Growth Rates
| HP | STR | MAG | SKL | SPD | LUK | DEF | RES |
|----|-----|-----|-----|-----|-----|-----|-----|
| 40 | 20 | 10 | 20 | 20 | 0 | 10 | 10 |

### Skills
**Primary:** Charm
**Secondary:** Rally Spectrum

---

---

# SKILLS REFERENCE

> Maximum 4 skills per unit (expandable at GM discretion). Skills marked **\*** are activated by choice.

---



## Generic Skills

Available to any unit regardless of class.

| Skill | Effect |
|-------|--------|
| Adept | SKL/2% chance during this unit's non-additional attacks: 1 additional attack |
| Barrier | +2 RES |
| Cancel | SKL/2% chance during this unit's attacks: Negate enemy's next attack |
| Celerity | +2 Movement |
| Clear Vision | +2 LoS |
| Corrosion | SKL/2% during this unit's attacks: Enemy's equipped weapon loses uses equal to this unit's level |
| Daunt | Reduces the Accuracy and Critical of enemies in a 3-space-radius by 10 |
| Discipline | Negates weapon triangle |
| Focus | +2 MAG |
| Fortunate | +2 LUK |
| Gamble\* | When initiating combat: Halve Accuracy to double Critical |
| Loot | Gain 20 gold every time this unit defeats an enemy |
| Miracle | LUK% chance to halve a fatal blow |
| Nihil | Negate enemy's battle-related skills |
| Nullify | Negates any bonus damage |
| Perceptive | +2 Line of Sight |
| Prowess | +2 SKL |
| Renewal | Restore 10% of this unit's max HP at the start of this unit's turn |
| Resolve | +50% STR, MAG, SKL, and SPD when this unit is at ½ HP or less |
| Savior | No penalties from rescuing |
| Smite\* | Shoves a unit 2 spaces instead of 1 space |
| Swift | +2 SPD |
| Tough | +2 DEF |
| Unorthodox | Reverses weapon triangle |
| Vantage | Always go first in combat |
| Vigor | +5 Max HP |
| Wrath | +50 Critical when at ½ health or less |
| Zeal | +2 STR |

---



## Awakening Generic Skills
*Available to any unit; found, awarded, or purchased at GM discretion.*

### Combat Skills

| Skill | Effect |
|-------|--------|
| Sol | SKL/2% during this unit's attacks: Restore HP equal to half the damage dealt in that attack |
| Luna | SKL/2% during this unit's attacks: This attack ignores half of the target's DEF or RES |
| Ignis | SKL/2% during this unit's attacks: Add half of this unit's MAG to a physical attack's damage (vs DEF), or half of this unit's STR to a magical attack's damage (vs RES) |
| Aether | SKL/2% during this unit's attacks: This attack triggers both Sol and Luna simultaneously |
| Galeforce | After this unit defeats an enemy on its own turn: This unit may immediately take another full turn. Triggers once per map turn |
| Aggressor | +10 damage when this unit initiates combat |
| Vengeance | SKL/2% during this unit's attacks: Add half of all damage this unit has taken so far this map to this attack's damage |
| Lifetaker | After this unit defeats an enemy on its own turn: Restore HP equal to half the damage dealt in the killing blow |

### Defensive Skills

| Skill | Effect |
|-------|--------|
| Patience | +10 Hit and Dodge when this unit is the defending unit in combat |
| Solidarity | When this unit is the Support unit in a Pair Up: The Lead unit gains +10 Crit Avoid |
| Iote's Shield | Negate all weapon effectiveness against this unit's Flying special quality |

### Utility Skills

| Skill | Effect |
|-------|--------|
| Acrobat | This unit treats all terrain movement costs as 1 |
| Pass\* | This unit may move through enemy-occupied spaces during its movement phase |
| Lucky Seven | This unit gains +20 Hit and +20 Dodge for the first 7 turns of each map |
| Odd Rhythm | +15 Hit and +15 Dodge on odd-numbered turns (1, 3, 5, 7…) |
| Even Rhythm | +15 Hit and +15 Dodge on even-numbered turns (2, 4, 6, 8…) |
| Prescience | +15 Hit and +15 Dodge when this unit initiates combat |
| Underdog | +15 Hit and +15 Dodge when fighting an enemy of higher level |

### Aura / Social Skills

| Skill | Effect |
|-------|--------|
| Charm | Allied units within 3 spaces gain +10 Hit and +10 Dodge during combat |
| Anathema | Enemy units within 3 spaces suffer −10 Hit and −10 Dodge during combat |
| Demoiselle | Male allied units within 3 spaces take −4 damage from all attacks |
| Gentilhomme | Female allied units within 3 spaces take −4 damage from all attacks |

### Faire Skills

| Skill | Effect |
|-------|--------|
| Swordfaire | +5 damage when attacking with a Sword |
| Lancefaire | +5 damage when attacking with a Lance |
| Axefaire | +5 damage when attacking with an Axe |
| Bowfaire | +5 damage when attacking with a Bow or Knife |
| Tomefaire | +5 damage when attacking with a Tome |

### Breaker Skills

| Skill | Effect |
|-------|--------|
| Swordbreaker | +50 Hit and +50 Dodge when fighting a unit equipped with a Sword |
| Lancebreaker | +50 Hit and +50 Dodge when fighting a unit equipped with a Lance |
| Axebreaker | +50 Hit and +50 Dodge when fighting a unit equipped with an Axe |
| Bowbreaker | +50 Hit and +50 Dodge when fighting a unit equipped with a Bow or Knife |
| Tomebreaker | +50 Hit and +50 Dodge when fighting a unit equipped with a Tome |

### Rally Skills
*Used as an action, ending this unit's turn. Affect all allies (not this unit) within 3 spaces for 1 full round.*

| Skill | Effect |
|-------|--------|
| Rally Strength | All allies within 3 spaces gain +4 STR |
| Rally Speed | All allies within 3 spaces gain +4 SPD |
| Rally Skill | All allies within 3 spaces gain +4 SKL |
| Rally Luck | All allies within 3 spaces gain +4 LUK |
| Rally Defense | All allies within 3 spaces gain +4 DEF |
| Rally Resistance | All allies within 3 spaces gain +4 RES |
| Rally Magic | All allies within 3 spaces gain +4 MAG |
| Rally Spectrum | All allies within 3 spaces gain +2 to all stats |

### Pair Up Skills
*Only relevant if the optional Pair Up rules are in use.*

| Skill | Effect |
|-------|--------|
| Dual Strike+ | +10% Dual Strike activation chance when this unit is the Support in a Pair |
| Dual Guard+ | +10% Dual Guard activation chance when this unit is the Support in a Pair |
| Dual Support+ | Stat bonuses granted to the Lead unit while this unit is the Support increase by +1 |

---



## Class-Specific Skills

| Skill | Effect | Class |
|-------|--------|-------|
| Pick\* | Opens doors or chests without a key | Thief line — from start |
| Canto\* | 1 adjacent ally without Canto that has already acted can move and act again | Bard line — from start |
| Veteran | This unit gains 1.5× EXP from all sources (rounded up) | Tactician — from start |
| Special Dance | See Dancer class entry above | Dancer — from start |
| Underdog | +15 Hit and +15 Dodge when fighting an enemy of higher level | Villager — from start |
| Anathema | Enemy units within 3 spaces suffer −10 Hit and −10 Dodge | Dark Mage — from start |
| Charm | Allied units within 3 spaces gain +10 Hit and +10 Dodge | Lord — from start; Bride — promotion |

---



## Promotion Skills

Granted automatically upon promotion.

| Skill | Effect | Class |
|-------|--------|-------|
| Swiftfoot | Ignore terrain movement penalties; +1 MOV | Ranger |
| Hawkeye | +15 Hit, +15 Critical | Sniper |
| Bowfaire | +5 damage when attacking with Bow or Knife | Bow Knight |
| Battle Cry | Canto targets gain +3 STR, MAG, and SPD until end of the turn | Skald |
| Resonance | Canto targets up to 2 adjacent allies, not 1 | Troubadour |
| Frenzy | +50% STR when at ½ health or less | Berserker |
| Bulldozer | After this unit shoves an enemy: That unit's movement is 0 until end of its next turn | Brawler |
| Strike True\* | If this unit missed by 10% or less: Re-roll the attack roll, once per combat | Paladin |
| Counter | SKL/2% when this unit takes damage from 1 range: Inflict the same amount to the attacker | Vanguard |
| Blessing | Can use staves at 2× their normal range | Bishop |
| Boon | Restores all adjacent allies to normal condition at the start of this unit's turn | Paragon |
| Sol | SKL/2% during attacks: Restore HP equal to half the damage dealt | War Monk / War Cleric |
| Rise\* | When killing an enemy, revive it as an ally with 1 HP, up to 3× per map | Necromancer |
| Drain | On a critical hit, restore ½ of the damage dealt to this unit's HP | Warlock |
| Cripple | Critical hits cause the target to lose 50% of its STR for 2 turns | Warrior |
| Redirect\* | Once per turn: Take the damage an attack would deal to an adjacent ally | Guardian |
| Bastion\* | As an action: Enemies cannot pass through 1 unoccupied adjacent space until this unit's next turn | General |
| Pavise | Negate all critical hits against this unit | Great Knight |
| Aegis | Add 25% of this unit's RES to this unit's DEF | Mage Knight |
| Phasing\* | As an action: This unit can pass through obstacles using regular movement; turn ends after | Sage |
| Dash\* | During movement, this unit can move diagonally once; increases at levels 6, 11, and 16 | Hero |
| Vigilance\* | +25 Dodge | Sentinel |
| Infuse\* | When initiating combat with a sword at 1 range: Reduce Critical to 0 to add ½ MAG to damage (vs RES) | Soulblade |
| Finesse | +25 Critical | Swordmaster |
| Flanking | +3 STR, SKL, and SPD when fighting an enemy with an ally on the opposite side | Nomad Trooper |
| Trample\* | 4 damage to each enemy adjacent to movement path; 2 damage to this unit per enemy hit | Raider |
| Air Superiority | +4 STR, SKL, and SPD when fighting flying enemies | Falcoknight |
| Holy Conduit | Critical hits restore HP to 1 adjacent ally equal to damage dealt with light tomes | Valkyrie |
| Galeforce | After defeating an enemy on own turn: Take another full turn. Triggers once per map turn | Dark Flier |
| Motivate | Adjacent allies get +3 DEF, RES, and LUK | Commander |
| Lunge\* | Initiate combat with a 1-range weapon as though its range was 2; +10 Critical when doing so | Halberdier |
| Rightful King | All percentage-based skill activations gain a flat +10% bonus | Great Lord |
| Ignis | SKL/2%: Add ½ MAG to physical damage (vs DEF) or ½ STR to magical damage (vs RES) | Grandmaster |
| Vengeance | SKL/2%: Add half of all damage received this map to this attack's damage | Sorcerer |
| Lifetaker | After defeating an enemy on own turn: Restore HP equal to half the damage dealt | Dark Knight |
| Acrobat | This unit treats all terrain movement costs as 1 | Trickster |
| Reaper | 2× SKL when using a dagger/knife | Assassin |
| Steal\* | Steal 1 unequipped item from adjacent enemy as an action | Rogue |
| Firebreathing\* | Fire spells target up to 2 spaces in a straight line simultaneously | Dracoknight |
| Ironhide | This unit takes no damage from E or D rank weapons (tomes still deal damage) | Wyvern Lord |
| Deliverer | No stat penalties or movement penalty when rescuing an allied unit | Griffon Rider |
| Aggressor | +10 damage when this unit initiates combat | Dread Fighter |
| Charm | Allied units within 3 spaces gain +10 Hit and +10 Dodge | Bride |

---



## Occult / Secondary Skills

Powerful skills available to promoted units. Granted via Occult Scroll or at GM discretion after promotion.

| Skill | Effect | Class |
|-------|--------|-------|
| Multishot | SKL/2% when initiating combat with bow: Extra attack against adjacent enemy; no counterattack from that unit | Ranger |
| Deadeye | SKL/2% during attacks: 2× damage and inflicts Sleep | Sniper |
| Rally Skill | All allies within 3 spaces gain +4 SKL | Bow Knight |
| Encore | SKL/2% after initiating combat: Canto on self, up to twice per turn | Skald |
| Inspire | Canto targets gain +1 SPD, LUK, and Movement | Troubadour |
| Rage | Immune to Sleep. When attacking after receiving damage, adds ½ damage received to Critical | Berserker |
| Cleave | SKL/2% when initiating adjacent combat: Extra attack against adjacent enemy; no counterattack | Brawler |
| Challenge\* | 3×/map: +3 STR, SPD, SKL, DEF against 1 chosen enemy | Paladin |
| Supremacy | +20 Accuracy and Dodge when fighting units without special qualities | Vanguard |
| Holy Aura | LUK/2% at start of this unit's turn: Allies in 2-space radius gain 20% of their total HP | Bishop |
| Judgement | SKL/2% when attacking with a lance: Add ½ MAG to damage; target is stunned | Paragon |
| Odd Rhythm | +15 Hit and +15 Dodge on odd-numbered turns (1, 3, 5, 7…) | War Monk |
| Even Rhythm | +15 Hit and +15 Dodge on even-numbered turns (2, 4, 6, 8…) | War Cleric |
| Army of the Dead | SKL/2% at start of turn: Create undead minion in adjacent space with ½ this unit's stats | Necromancer |
| Hex | SKL/2% after combat: Enemy gains −6 STR and MAG for 3 turns | Warlock |
| No Escape | SKL/2% when an enemy leaves an adjacent space: 1 attack against that enemy, no counterattack | Warrior |
| Parry | SKL/2% when adjacent ally would take ≥½ their current HP as damage: Negate all damage and reflect ½ to attacker | Guardian |
| Iron Wall | SKL/2% when this unit is attacked: Negate all damage | General |
| Charge | +50% damage when initiating combat after a full movement | Great Knight |
| Flare | SKL/2% during attacks: Ignore ½ RES | Mage Knight |
| Deeper Knowledge | SKL/2% during attacks: 4× beneficial weapon triangle; no detrimental weapon triangle | Sage |
| Disarm | SKL/2% during attacks: Enemy un-equips its equipped weapon | Hero |
| Diehard | SKL/2% at start of this unit's turn: This unit gains 20% of its total HP | Sentinel |
| Arcane Rush | SKL/2% during sword attacks at 1 range: 2 consecutive attacks; second uses MAG vs RES | Soulblade |
| Astra | SKL/2% during attacks: 5 consecutive attacks at ½ damage; consumes only one weapon use | Swordmaster |
| Master Horseman | SKL/2% when moving after an action that ends turn: Perform another action after moving | Nomad Trooper |
| Pierce | SKL/2% during attacks: Ignore ½ DEF | Raider |
| Giantkiller | Effective weapons deal 4× Mt instead of 3× | Falcoknight |
| Favoured | 1×/map: A lethal blow leaves this unit at 1 HP instead if above 50% HP; no further damage that turn | Valkyrie |
| Rally Magic | All allies within 3 spaces gain +4 MAG | Dark Flier |
| Rally | SKL/2% at start of this unit's turn: Adjacent allies gain +2 to 1 attribute of choice for 1 turn | Commander |
| Impale | SKL/2% during attacks: Attack deals 4× damage | Halberdier |
| Aether | SKL/2% during attacks: This attack triggers both Sol and Luna simultaneously | Great Lord |
| Rally Spectrum | All allies within 3 spaces gain +2 to all stats | Grandmaster; Bride |
| Tomebreaker | +50 Hit and +50 Dodge when fighting a unit equipped with a Tome | Sorcerer |
| Shadowgift | This unit may equip and use Dark tomes regardless of class restrictions | Dark Knight |
| Pass\* | This unit may move through enemy-occupied spaces during movement | Trickster |
| Lethality | Critical/2% during attacks from 1 range: Automatically kill most units | Assassin |
| Fast Fingers | SKL/2% during melee attacks: Steal 1 unequipped item from the enemy | Rogue |
| Inferno | MAG/2% when initiating combat with a fire tome: Adjacent enemies take ½ MAG damage next turn | Dracoknight |
| Fearsome | STR/2% at the start of enemy turns: Enemies adjacent to this unit become stunned | Wyvern Lord |
| Lancebreaker | +50 Hit and +50 Dodge when fighting a unit equipped with a Lance | Griffon Rider |
| Swordfaire | +5 damage when attacking with a Sword | Dread Fighter |

---



## Optional Rule: Pair Up

*Pair Up is the signature mechanic of Awakening, allowing two units to share a space.*

Two allied units in the same space form a **Pair**. One is the **Lead** (acts normally); one is the **Support** (passive, cannot be directly targeted).

### Stat Bonuses While Paired

| Support Class Type | Bonus |
|-------------------|-------|
| Physical (STR-primary) | +2 STR |
| Magical (MAG-primary) | +2 MAG |
| Fast (SPD 9+) | +2 SPD |
| Armoured / Mounted | +2 DEF |
| Support (Cleric, Bard, Heron) | +2 LUK and +2 RES |

*At GM discretion, a mutual A-rank or higher Support bond may increase these bonuses by +1.*

### Dual Strike
When the Lead unit makes a successful attack: **SKL/2%** chance the Support unit also attacks for **50% normal damage**. The Dual Strike does not trigger counterattacks.

### Dual Guard
When the Lead unit is attacked: **SPD/2%** (of the Support unit) chance the Support unit **nullifies all damage** from that one attack. Can trigger at most once per combat.


<!-- Data reconciliation pass completed: official FE:A numeric data applied where available; assumptions listed at top. -->
