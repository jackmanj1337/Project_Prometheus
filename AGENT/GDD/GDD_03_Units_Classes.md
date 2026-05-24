# GDD_03 — Units & Classes

---

## Unit vs Class

A **Unit** is an individual character with a name, current stats, inventory, and level.
A **Class** is a template that defines base stats, WEXP baselines/caps, growth tables,
stat caps, skill unlocks, vulnerabilities, and promotion/reclass relationships.

When a unit is created:
1. Copy base stats from `ClassData` into a new `UnitData`
2. Apply the unit's personal growth table / authored roster fields
3. Seed class-line metadata, WEXP totals, and learned skills
4. Grant any class skills that should already be known at the unit's current level

When a unit levels up or promotes, `UnitData` is modified directly — the `ClassData`
resource is referenced again for growths, caps, promotion bonuses, skill unlocks,
and reclass legality.

Current authored progression fields:

- `UnitData.weapon_wexp` stores numeric WEXP totals per track; rank letters are derived
  from these totals rather than stored separately.
- `UnitData.earned_skills` is the permanent learned pool; `UnitData.skills` is the
  currently equipped subset.
- `UnitData.internal_level` replaces the old `effective_level` field for promotion /
  reclass calculations.
- `ClassData.weapon_wexp_bases` / `weapon_wexp_caps` replace the older
  proficiency-array schema.
- `ClassData.skill_unlocks` replaces the older `starting_skills` / single-promotion-skill
  model.

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

## Current Starter Roster

The live default roster loaded by `GameState.load_default_roster()` is:

- `Unit_01` — `cavalier`
- `Unit_02` — `mercenary`
- `Unit_03` — `archer`
- `Unit_04` — `mage`
- `Unit_05` — `cleric`
- `Unit_06` — `knight`

Each unit has authored personal growths, starting WEXP, equipped skills, and
reclass options in its `.tres` file under `data/roster/default/`. The older
"generated six-class MVP starter set" description is deprecated.

---

### 1. Cavalier

**Role:** Mobile frontline fighter  
**Handbook Source:** Cavalier line

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
| MOV | 7 |
| CON | 8 |
| LoS | 4 |

**Starting WEXP:** Lance D (`weapon_wexp = {"lance": 100}`)  
**Starter Skills:** `discipline`  
**Special Qualities:** `mounted`

**Growth Rates:**
```
HP: 75, STR: 50, MAG: 5, DEF: 45, RES: 25, SKL: 50, SPD: 45, LUK: 40
```

**Promotes To:** Paladin, Great Knight

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

**Starting WEXP:** Sword D  
**Starter Skills:** `vantage`, `swordfaire`  
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

**Starting WEXP:** Bow D  
**Starter Skills:** `bowfaire`  
**Special Qualities:** —

**Growth Rates:**
```
HP: 60, STR: 45, MAG: 5, DEF: 30, RES: 20, SKL: 70, SPD: 55, LUK: 40
```

> **Weapon note:** The Iron Bow (and all bows) has `range_min_formula = "2"`. Any
> unit with a bow equipped cannot attack or counterattack against adjacent (range 1)
> targets. This is a property of the weapon, not the class — a non-Archer who equips
> a bow is subject to the same restriction, and an Archer who equips a melee weapon
> (e.g. via trade) could attack at range 1 normally. Range is enforced by
> `GridManager`'s attackable-tile queries and `CombatResolver.can_counterattack()`,
> both reading `WeaponData.get_range_min()` / `get_range_max()`.

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

**Starting WEXP:** Elemental Magic D  
**Starter Skills:** `wrath`  
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

**Starting WEXP:** Staff D, Light E  
**Starter Skills:** `renewal`, `miracle`  
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

**Starting WEXP:** Lance D  
**Starter Skills:** `resolve`  
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

## Promotion and Reclass

Promotion and Second Seal reclassing are now implemented.

When a unit promotes:

1. `PromotionScreen` offers the entries from `ClassData.promotes_to`
2. The chosen class's `promotion_stat_bonuses` are applied immediately
3. `class_id` changes to the promoted class and `is_promoted` becomes `true`
4. `weapon_wexp` is raised to at least the promoted class's authored WEXP baselines
5. Class skills are granted from the promoted class's `skill_unlocks`
6. `internal_level` is recalculated from the promoted class's internal-level rule

When a unit uses a Second Seal:

1. `ReclassScreen` offers the legal results from `Unit.get_second_seal_options()`
2. The selected class resets the unit's visible level to 1
3. The unit keeps its broader progression state through `internal_level`
4. Promotion stat bonuses from the previous promoted class are removed before the
   new class state is applied

The older single `promotion_skill` / `effective_level` model is deprecated.

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

Used when the player starts a new game or launches a default-roster validation map.
Six authored `UnitData` resources are loaded into `GameState.player_roster`. Each
has `is_default_roster = true`.

All units start at **level 1** with **1,000 gold** and the inventory listed below.
Unlike the original MVP draft, the roster now ships with authored personal growths,
equipped skills, and reclass options.

Save these as `.tres` files in `data/roster/default/` so they can be loaded
directly by `GameState` without generating them in code.

| Slot | Name | Class | Weapon | Item |
|---|---|---|---|---|
| 1 | Unit_01 | Cavalier | Iron Lance | Vulnerary |
| 2 | Unit_02 | Mercenary | Iron Sword | Vulnerary |
| 3 | Unit_03 | Archer | Iron Bow | Vulnerary |
| 4 | Unit_04 | Mage | Fire | Vulnerary |
| 5 | Unit_05 | Cleric | Heal Staff | Vulnerary |
| 6 | Unit_06 | Knight | Iron Lance | Vulnerary |

**Starting proficiency ranks:**
- Unit_01 (Cavalier): Lance D
- Unit_02 (Mercenary): Sword D
- Unit_03 (Archer): Bow D
- Unit_04 (Mage): Elemental Magic D
- Unit_05 (Cleric): Staff D, Light E
- Unit_06 (Knight): Lance D

**Deployment order on Map 001:**
Units are placed at player start tiles in slot order (Slot 1 → tile index 0, etc.).

| Unit | Start Tile |
|---|---|
| Unit_01 (Cavalier) | (1, 9) |
| Unit_02 (Mercenary) | (1, 10) |
| Unit_03 (Archer) | (1, 11) |
| Unit_04 (Mage) | (2, 9) |
| Unit_05 (Cleric) | (2, 10) |
| Unit_06 (Knight) | (2, 11) |

> These names, classes, and positions are intentionally generic.
> Replace with named characters when a story and character creation screen
> are implemented in Phase 2.
