# GDD_03 — Units & Classes

---

## Unit vs Class

A **Unit** is an individual character with a name, current stats, inventory, and level.
A **Class** is a template that defines starting stats, proficiencies, available skills,
and promotion paths.

When a unit is created:
1. Copy base stats from `ClassData` into a new `UnitData`
2. Apply character-creation stat adjustments (point buy, roll, etc.)
3. Set starting proficiencies and skills from class

When a unit levels up or promotes, `UnitData` is modified directly — the `ClassData`
resource is only referenced again at promotion.

---

## Special Qualities

Special qualities are tags stored on a unit (inherited from class, can be added by
skills or items). They affect movement rules, combat interactions, and terrain.

| Quality | Effect |
|---|---|
| `flying` | Ignores terrain movement costs; can cross most obstacles; weak to bow/wind |
| `mounted` | Can move remainder of movement after acting (before final Wait); higher CON |
| `armoured` | Generally high DEF; affected by certain anti-armor weapons |
| `dragon` | Affected by dragon-effective weapons |
| `beast` | Affected by beast-effective weapons (Laguz land units) |
| `laguz` | Has shift gauge (Phase 2+) |

---

## MVP Classes (6 Classes)

These six classes provide a balanced party for the MVP map.
Each has a distinct tactical role. Promotion paths are designed but not implemented until Phase 2.

---

### 1. Soldier

**Role:** Balanced frontline fighter  
**Handbook Source:** Soldier

| Stat | Value |
|---|---|
| HP | 17 |
| STR | 7 |
| MAG | 0 |
| DEF | 6 |
| RES | 3 |
| SKL | 6 |
| SPD | 6 |
| LUK | 6 |
| MOV | 6 |
| CON | 8 |
| LoS | 4 |

**Proficiencies:** Lance (D)  
**Starting Skills:** —  
**Special Qualities:** —

**Growth Rates:**
```
HP: 75, STR: 50, MAG: 5, DEF: 45, RES: 25, SKL: 50, SPD: 45, LUK: 40
```

**Promotes To (Phase 2):** Commander, Halberdier

---

### 2. Mercenary

**Role:** Accurate, fast melee fighter  
**Handbook Source:** Mercenary

| Stat | Value |
|---|---|
| HP | 18 |
| STR | 7 |
| MAG | 0 |
| DEF | 5 |
| RES | 2 |
| SKL | 8 |
| SPD | 7 |
| LUK | 4 |
| MOV | 6 |
| CON | 8 |
| LoS | 4 |

**Proficiencies:** Sword (D)  
**Starting Skills:** —  
**Special Qualities:** —

**Growth Rates:**
```
HP: 60, STR: 50, MAG: 5, DEF: 35, RES: 20, SKL: 65, SPD: 60, LUK: 35
```

**Promotes To (Phase 2):** Hero, Sentinel

---

### 3. Archer

**Role:** Ranged physical attacker; cannot attack adjacent targets  
**Handbook Source:** Archer

| Stat | Value |
|---|---|
| HP | 17 |
| STR | 6 |
| MAG | 0 |
| DEF | 4 |
| RES | 3 |
| SKL | 9 |
| SPD | 7 |
| LUK | 5 |
| MOV | 6 |
| CON | 6 |
| LoS | 4 |

**Proficiencies:** Bow (D)  
**Starting Skills:** —  
**Special Qualities:** —

**Growth Rates:**
```
HP: 60, STR: 45, MAG: 5, DEF: 30, RES: 20, SKL: 70, SPD: 55, LUK: 40
```

> **Weapon note:** The Iron Bow (and all bows) has range_min = 2. Any unit
> with a bow equipped cannot attack or counterattack against adjacent (range 1)
> targets. This is a property of the weapon, not the class — a non-Archer unit
> who equips a bow is subject to the same restriction, and an Archer who somehow
> equips a melee weapon (e.g. via trade) could attack at range 1 normally.
> `CombatResolver` enforces this by checking the equipped weapon's range_min
> against the distance to the target.

**Promotes To (Phase 2):** Ranger, Sniper

---

### 4. Mage

**Role:** Magical attacker; targets RES instead of DEF; uses weapon triangle  
**Handbook Source:** Mage

| Stat | Value |
|---|---|
| HP | 15 |
| STR | 1 |
| MAG | 7 |
| DEF | 1 |
| RES | 8 |
| SKL | 8 |
| SPD | 6 |
| LUK | 5 |
| MOV | 6 |
| CON | 5 |
| LoS | 4 |

**Proficiencies:** Choose 2 from (Fire, Thunder, Wind). One chosen proficiency starts at **D rank** (primary); the other starts at **E rank**. This follows the general rule in GDD_02: a class's primary weapon type starts at D, additional proficiencies start at E.  
**Starting Skills:** —  
**Special Qualities:** —

**Growth Rates:**
```
HP: 50, STR: 5, MAG: 65, DEF: 15, RES: 60, SKL: 60, SPD: 50, LUK: 40
```

**Promotes To (Phase 2):** Mage Knight, Sage

---

### 5. Cleric

**Role:** Support / healer; uses staves to restore ally HP; cannot fight effectively  
**Handbook Source:** Cleric

| Stat | Value |
|---|---|
| HP | 16 |
| STR | 1 |
| MAG | 5 |
| DEF | 3 |
| RES | 9 |
| SKL | 5 |
| SPD | 6 |
| LUK | 6 |
| MOV | 6 |
| CON | 6 |
| LoS | 4 |

**Proficiencies:** Light (E), Staff (D)  
**Starting Skills:** —  
**Special Qualities:** —

**Growth Rates:**
```
HP: 55, STR: 10, MAG: 55, DEF: 20, RES: 70, SKL: 45, SPD: 45, LUK: 55
```

> **Staff Use:** The Cleric targets an ally within staff range (1 tile for Heal).
> Healing = 10 + MAG. Staff use is a turn-ending action. Grants EXP.

**Promotes To (Phase 2):** Bishop, Paragon

---

### 6. Knight

**Role:** Tank; very high DEF; slow; uses lance  
**Handbook Source:** Knight

| Stat | Value |
|---|---|
| HP | 21 |
| STR | 9 |
| MAG | 0 |
| DEF | 12 |
| RES | 0 |
| SKL | 5 |
| SPD | 3 |
| LUK | 2 |
| MOV | 5 |
| CON | 15 |
| LoS | 4 |

**Proficiencies:** Lance (D)  
**Starting Skills:** —  
**Special Qualities:** `armoured`

**Growth Rates:**
```
HP: 70, STR: 55, MAG: 0, DEF: 65, RES: 15, SKL: 45, SPD: 25, LUK: 25
```

**Promotes To (Phase 2):** General, Great Knight

---

## Character Creation (Digital Adaptation)

On the character creation screen, the player:

1. Enters a **name** for their unit `[PLACEHOLDER — name input field]`
2. Selects a **class** from available classes
3. Sees base stats displayed
4. Allocates **stat points** based on the campaign's difficulty setting:
   - Low: 4 points
   - Standard: 6 points
   - High: 7 points
5. Maximum +2 to any single stat at creation
6. Starts with **1,000 gold**
7. Can buy starting equipment from available weapons/items

---

## Adding Future Classes

All classes in the handbook (53 total) are intended for Phase 2+.
Priority order for implementation after MVP:

**Priority A (common archetypes):**
Fighter, Brigand, Cavalier, Myrmidon, Thief, Bard, Druid

**Priority B (mounted/flying):**
Pegasus Knight, Wyvern Rider, Nomad, Paladin, Great Knight

**Priority C (promoted only, no base class in MVP):**
General, Hero, Swordmaster, Sage, Berserker, Warrior, Sniper, etc.

**Priority D (Laguz — requires separate shift system):**
Cat, Tiger, Hawk, Raven, Heron

To add a class:
1. Create `data/classes/class_name.tres` using the `ClassData` resource
2. Fill all fields including promotion paths (set to empty array if not yet implemented)
3. Add class name to the character creation screen's class list
4. No code changes required unless the class introduces a new mechanic

---

## Promotion System (Phase 2)

When a Beorc unit reaches level 20 and gains enough EXP to level up once more
(or uses a promotion item):

1. A **Promote screen** opens showing both promotion options
2. Player selects one
3. The chosen class's `promotion_stat_increases` are added to the unit's stats
4. The unit's `class_id` is updated to the promoted class
5. The promotion skill is added to the unit's skill list
6. Proficiencies gained at promotion are added at E rank
7. Special qualities from the promoted class replace/extend the current list
8. `is_promoted = true`, `effective_level = pre_promotion_level + 1`
9. Growth rates increase by 5% and may be reassigned (if using growth rate method)

### Promotion Items (Phase 2)

| Item | Eligible Classes |
|---|---|
| Master Seal | Any non-promoted Beorc (promotes before level 20) |
| Knight Crest | Cavalier, Knight, Soldier |
| Hero Crest | Brigand, Fighter, Mercenary, Myrmidon |
| Guiding Ring | Bard, Cleric, Druid, Mage |
| Orion's Bolt | Archer, Nomad |
| Elysian Whip | Pegasus Knight, Wyvern Rider |
| Fell Contract | Thief |

Store eligibility in each promotion item's `effect_params`:
```gdscript
{ "eligible_classes": ["cavalier", "knight", "soldier"] }
```

---

## Default MVP Roster

Used when the player starts a new game in MVP (no character creation screen yet).
Six `UnitData` resources are generated at game start and stored in
`GameState.player_roster`. Each has `is_default_roster = true`.

All units start at **level 1** with **base class stats** (no creation point bonuses),
**1,000 gold**, and the inventory listed below. No skills are assigned by default.

Save these as `.tres` files in `data/roster/default/` so they can be loaded
directly by `GameState` without generating them in code.

| Slot | Name | Class | Weapon | Item |
|---|---|---|---|---|
| 1 | Unit_01 | Soldier | Iron Lance | Vulnerary |
| 2 | Unit_02 | Mercenary | Iron Sword | Vulnerary |
| 3 | Unit_03 | Archer | Iron Bow | Vulnerary |
| 4 | Unit_04 | Mage | Fire | Vulnerary |
| 5 | Unit_05 | Cleric | Heal Staff | Vulnerary |
| 6 | Unit_06 | Knight | Iron Lance | Vulnerary |

**Starting proficiency ranks:**
- Unit_01 (Soldier): Lance D
- Unit_02 (Mercenary): Sword D
- Unit_03 (Archer): Bow D
- Unit_04 (Mage): Fire D (primary), Thunder E (additional)
- Unit_05 (Cleric): Staff D, Light E
- Unit_06 (Knight): Lance D

**Deployment order on Map 001:**
Units are placed at player start tiles in slot order (Slot 1 → tile index 0, etc.).

| Unit | Start Tile |
|---|---|
| Unit_01 (Soldier) | (1, 9) |
| Unit_02 (Mercenary) | (1, 10) |
| Unit_03 (Archer) | (1, 11) |
| Unit_04 (Mage) | (2, 9) |
| Unit_05 (Cleric) | (2, 10) |
| Unit_06 (Knight) | (2, 11) |

> These names, classes, and positions are intentionally generic.
> Replace with named characters when a story and character creation screen
> are implemented in Phase 2.
