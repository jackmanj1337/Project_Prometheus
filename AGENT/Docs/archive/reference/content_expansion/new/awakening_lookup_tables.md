
> **Historical** — External Awakening reference corpus; not active Project Prometheus rules or public-pack content.

# Fire Emblem Awakening Technical Reference Corpus
# Canonical Lookup Tables

**File:** `awakening_lookup_tables.md`  
**Phase:** 2  
**Corpus Version:** `0.3.0-phase2`  
**Depends On:** `awakening_project_index.md`, `awakening_core_systems.md`  
**Scope:** Canonical lookup/reference tables only.

---

# Table of Contents

1. [Stats Reference](#stats-reference)
2. [Weapon Types](#weapon-types)
3. [Numeric WEXP Thresholds](#numeric-wexp-thresholds)
4. [Movement Types](#movement-types)
5. [Terrain Categories](#terrain-categories)
6. [Vulnerability Groups](#vulnerability-groups)
7. [Effectiveness Matrix](#effectiveness-matrix)
8. [Damage Multipliers](#damage-multipliers)
9. [Rank Progression Tables](#rank-progression-tables)

---

# Stats Reference

## Primary Stats

| Canonical Stat | Abbreviation | Domain | Visible | Can Level Up | Has Class Cap | Used For |
|---|---:|---|---|---|---|---|
| Hit Points | HP | Integer | Yes | Yes | Yes | Maximum health, survival checks |
| Strength | STR | Integer | Yes | Yes | Yes | Physical attack power |
| Magic | MAG | Integer | Yes | Yes | Yes | Magical attack power, staff output |
| Skill | SKL | Integer | Yes | Yes | Yes | Hit rate, critical rate, proc rates |
| Speed | SPD | Integer | Yes | Yes | Yes | Avoid, attack speed, follow-up attacks |
| Luck | LCK | Integer | Yes | Yes | Yes | Hit, avoid, dodge, miscellaneous rates |
| Defense | DEF | Integer | Yes | Yes | Yes | Physical damage reduction |
| Resistance | RES | Integer | Yes | Yes | Yes | Magical damage reduction |
| Movement | MOV | Integer | Yes | No | Class-defined | Tile movement allowance |

## Derived Combat Stats

| Derived Value | Abbreviation | Formula / Definition | Primary Inputs | Notes |
|---|---:|---|---|---|
| Physical Attack | ATK | `STR + WeaponMight + AttackModifiers` | STR, weapon Mt | Used by most swords, lances, axes, bows, stones |
| Magical Attack | ATK | `MAG + WeaponMight + AttackModifiers` | MAG, weapon Mt | Used by tomes and magical weapons |
| Hit Rate | HIT | `WeaponHit + floor((SKL × 3 + LCK) / 2) + HitModifiers` | SKL, LCK, weapon Hit | Before defender avoid subtraction |
| Avoid | AVO | `floor((SPD × 3 + LCK) / 2) + AvoidModifiers` | SPD, LCK | Subtracted from attacker hit |
| Critical Rate | CRT | `WeaponCrit + floor(SKL / 2) + CritModifiers` | SKL, weapon Crit | Before defender dodge subtraction |
| Dodge | DDG | `LCK + DodgeModifiers` | LCK | Critical avoidance |
| Attack Speed | AS | `SPD + AttackSpeedModifiers` | SPD | No standard weapon-weight penalty |
| Final Hit | F-HIT | `AttackerHIT - DefenderAVO` | HIT, AVO | Clamp for RNG resolution |
| Final Crit | F-CRT | `AttackerCRT - DefenderDDG` | CRT, DDG | Clamp for RNG resolution |
| Damage | DMG | `max(Attack - DefenseStat, 0)` | ATK, DEF/RES | Before or after crit depending on stage |
| Rating | RTG | `STR + MAG + SKL + SPD + LCK + DEF + RES` | Non-HP primary stats | UI/comparison aggregate |

## Defensive Stat Selection

| Incoming Damage Type | Defender Stat Used | Notes |
|---|---|---|
| Physical | DEF | Used by standard physical weapons |
| Magical | RES | Used by tomes and magical weapons |
| Fixed Damage | N/A | Ignores DEF/RES unless source says otherwise |
| Scripted Damage | Source-defined | Map/event/skill-specific |
| Staff Effect | RES or source-defined | Hostile staff logic should be handled separately |

## Stat Cap Fields

| Field | Type | Formula / Rule |
|---|---|---|
| ClassStatCap | Integer | Defined by class |
| UnitCapModifier | Integer | Defined by unit or inherited modifier |
| FinalStatCap | Integer | `ClassStatCap + UnitCapModifier` |
| PermanentStat | Integer | Stat after level-ups and permanent boosters |
| EffectiveBattleStat | Integer | Permanent stat plus temporary battle modifiers |

## Stat Modifier Source Types

| Modifier Source | Duration | Applies Before Cap | Applies After Cap | Notes |
|---|---|---|---|---|
| Level-up gain | Permanent | Yes | No | Cannot raise permanent stat above final cap |
| Permanent stat booster | Permanent | Yes | No | Subject to cap enforcement |
| Promotion bonus | Permanent/class transition | Yes | No | Applied during class transition |
| Reclass base adjustment | Class-state | Yes | No | Recomputed after class change |
| Pair Up bonus | Temporary/stateful | No | Yes | Active while paired |
| Rally bonus | Temporary/turn-based | No | Yes | Expires by timing rule |
| Tonic bonus | Temporary/map-based | No | Yes | Expires after map |
| Skill stat bonus | Source-defined | Usually No | Usually Yes | Skill-specific |
| Weapon/equipment bonus | Temporary/equipment | No | Yes | Active while equipped |

---

# Weapon Types

## Canonical Weapon Type Table

| Weapon Type | Category | Damage Class | Uses STR | Uses MAG | Uses WEXP | Can Counterattack | Standard Range Classes | Notes |
|---|---|---|---|---|---|---|---|---|
| Sword | Physical | Physical | Yes | No | Yes | Yes | 1, 1–2 special | Part of weapon triangle |
| Lance | Physical | Physical | Yes | No | Yes | Yes | 1, 1–2 special | Part of weapon triangle |
| Axe | Physical | Physical | Yes | No | Yes | Yes | 1, 1–2 special | Part of weapon triangle |
| Bow | Physical | Physical | Yes | No | Yes | Yes | 2, special variants | Effective against flying by default category rules where weapon defines it |
| Tome | Magical | Magical | No | Yes | Yes | Yes | 1–2, special variants | Generic magic category |
| Dark Tome | Magical | Magical | No | Yes | Yes / restricted | Yes | 1–2, special variants | Requires class permission for dark magic |
| Staff | Utility | Healing / status | No | Yes | Yes | No standard attack | Staff-defined | Healing, rescue, status, utility |
| Beaststone | Stone | Physical / transformation | Yes | No | Special / class-defined | Yes | 1 | Taguel weapon category |
| Dragonstone | Stone | Physical / transformation | STR or source-defined | MAG or source-defined | Special / class-defined | Yes | 1 | Manakete weapon category |
| Magical Sword | Hybrid | Magical | No | Yes | Sword WEXP | Yes | Usually 1–2 | Sword type, magical damage |
| Magical Lance | Hybrid | Magical | No | Yes | Lance WEXP | Yes | Usually 1–2 | Lance type, magical damage |
| Magical Axe | Hybrid | Magical | No | Yes | Axe WEXP | Yes | Usually 1–2 | Axe type, magical damage |

## Weapon Triangle Participation

| Weapon Type | Participates in Weapon Triangle | Beats | Loses To |
|---|---|---|---|
| Sword | Yes | Axe | Lance |
| Lance | Yes | Sword | Axe |
| Axe | Yes | Lance | Sword |
| Bow | No | N/A | N/A |
| Tome | No | N/A | N/A |
| Dark Tome | No | N/A | N/A |
| Staff | No | N/A | N/A |
| Beaststone | No | N/A | N/A |
| Dragonstone | No | N/A | N/A |

## Damage Stat by Weapon Family

| Weapon Family | Default Attack Stat | Default Defense Stat | Override Required |
|---|---|---|---|
| Sword | STR | DEF | Yes, for magical swords |
| Lance | STR | DEF | Yes, for magical lances |
| Axe | STR | DEF | Yes, for magical axes |
| Bow | STR | DEF | Rare/special only |
| Tome | MAG | RES | Rare/special only |
| Dark Tome | MAG | RES | Rare/special only |
| Staff healing | MAG | N/A | Staff-specific |
| Offensive staff | MAG | RES or staff-specific | Yes |
| Beaststone | STR | DEF | Class/weapon-specific |
| Dragonstone | Source-defined | Source-defined | Yes |

## Standard Weapon Access Validation

| Check | Required Condition |
|---|---|
| Weapon type access | `WeaponType ∈ CurrentClassAllowedWeaponTypes` |
| Rank access | `UnitWEXP[WeaponType] ≥ WeaponRequiredWEXP` |
| Durability | `WeaponDurability > 0` |
| Range | `WeaponMinRange ≤ Distance ≤ WeaponMaxRange` |
| Restrictions | Character/class/skill flags permit use |

---

# Numeric WEXP Thresholds

## Canonical Rank Thresholds

| Rank | Minimum WEXP | Maximum WEXP Before Next Rank | Interval Size | Corpus Status |
|---|---:|---:|---:|---|
| None | 0 | 0 | 1 | No usable rank |
| E | 1 | 30 | 30 | Canonical |
| D | 31 | 70 | 40 | Canonical |
| C | 71 | 120 | 50 | Canonical |
| B | 121 | 180 | 60 | Canonical |
| A | 181 | 250 | 70 | Canonical |
| S | 251 | 400 | 150 | Corpus-normalized high rank |
| Cap | 400 | 400 | N/A | Absolute stored cap |

## Rank Derivation Table

| WEXP Range | Derived Rank |
|---:|---|
| 0 | None |
| 1–30 | E |
| 31–70 | D |
| 71–120 | C |
| 121–180 | B |
| 181–250 | A |
| 251–400 | S |

## Rank Requirement Lookup

| Required Rank | Required WEXP |
|---|---:|
| E | 1 |
| D | 31 |
| C | 71 |
| B | 121 |
| A | 181 |
| S | 251 |

## WEXP Storage Fields

| Field | Type | Description |
|---|---|---|
| StoredWEXP | Integer 0–400 | Unit-level WEXP retained across class changes |
| ActiveWEXP | Integer 0–400 | WEXP usable by current class for allowed weapon type |
| ClassBaseWEXP | Integer | Minimum WEXP granted by class access |
| ClassMaxWEXP | Integer | Maximum usable WEXP in current class |
| WeaponRequiredWEXP | Integer | Minimum WEXP required to equip weapon |
| RankLabel | Enum | Derived from WEXP thresholds |

## WEXP Class Entry Rule

| Situation | Rule |
|---|---|
| Weapon type retained | `ActiveWEXP = min(StoredWEXP, ClassMaxWEXP)` |
| Weapon type newly gained | `ActiveWEXP = min(max(StoredWEXP, ClassBaseWEXP), ClassMaxWEXP)` |
| Weapon type unavailable | `ActiveWEXP = N/A`; `StoredWEXP` persists |
| Weapon type above class max | `ActiveWEXP = ClassMaxWEXP`; `StoredWEXP` persists unless engine caps globally |
| Weapon type at global cap | `StoredWEXP = 400` |

## WEXP Gain Rule Table

| Action | Base WEXP Gain | Notes |
|---|---:|---|
| Weapon combat round | 2 | Standard Awakening normalized value |
| Staff use | 2 | Standard Awakening normalized value |
| Discipline active | ×2 | Doubles WEXP gain |
| Arms Scroll | Rank increment | Raises weapon level according to item behavior |
| No valid weapon use | 0 | No WEXP |
| Class cannot use weapon type | 0 | Cannot perform action legally |
| At class max | 0 effective gain | Stored value does not exceed active class cap unless modeled separately |
| At global cap | 0 | Stored WEXP cannot exceed 400 |

---

# Movement Types

## Terrain Movement Categories

Awakening uses terrain movement categories separate from effectiveness vulnerability groups.

| Movement Category | Category ID | Representative Classes | Terrain Model Role |
|---|---:|---|---|
| Special | MOV_SPECIAL | Lord, Tactician, Taguel, Manakete, Dancer, Mirage | Special baseline terrain group |
| Infantry A | MOV_INF_A | Myrmidon, Mercenary, Archer | Light infantry movement profile |
| Infantry B | MOV_INF_B | Barbarian, Fighter, Villager, Soldier, Merchant, Revenant, Entombed | Heavy/rough infantry movement profile |
| Infantry C | MOV_INF_C | Great Lord, Grandmaster, Lodestar, Grima, Thief, Swordmaster, Assassin, Trickster, Berserker, Warrior, Hero, Sniper, Dread Fighter, Bride | Advanced infantry movement profile |
| Armor | MOV_ARMOR | Knight, General | Armored movement profile |
| Cavalry A | MOV_CAV_A | Cavalier, Troubadour | Base cavalry movement profile |
| Cavalry B | MOV_CAV_B | Paladin, Great Knight, Bow Knight, Valkyrie, Dark Knight, Conqueror | Advanced cavalry movement profile |
| Mages | MOV_MAGE | Priest, Cleric, War Monk, War Cleric, Mage, Sage, Dark Mage, Sorcerer | Mage/staff movement profile |
| Fliers | MOV_FLIER | Pegasus Knight, Falcon Knight, Dark Flier, Wyvern Rider, Wyvern Lord, Griffon Rider | Flying movement profile |

## High-Level Movement Families

| Movement Family | Includes Terrain Categories | Vulnerability Implication | Notes |
|---|---|---|---|
| Foot | Special, Infantry A, Infantry B, Infantry C, Mages | None by default | Movement cost depends on category |
| Armor | Armor | Armor | Slow/limited terrain profile |
| Cavalry | Cavalry A, Cavalry B | Cavalry | Mounted ground movement |
| Flying | Fliers | Flying | Ignores most ground movement penalties; does not receive most terrain stat bonuses |
| Transformation | Special or class-specific | Beast or Dragon if applicable | Taguel/Manakete handled by class flags |

## Movement Cost Symbol Key

| Symbol | Meaning |
|---|---|
| `1` | Costs 1 movement point |
| `2` | Costs 2 movement points |
| `3` | Costs 3 movement points |
| `4` | Costs 4 movement points |
| `5` | Costs 5 movement points |
| `6` | Costs 6 movement points |
| `X` | Cannot cross |
| `X*` | Special scripted restriction / cannot normally cross or stop |
| `PassOnly` | Can cross but cannot end movement or act there |
| `N/A` | Not applicable |

---

# Terrain Categories

## Terrain Stat and Movement Table

| Terrain Category | Included Terrain Names | DEF | AVO | HP Recovery | Special | Infantry A | Infantry B | Infantry C | Armor | Cavalry A | Cavalry B | Mages | Fliers |
|---|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Floor | Plain, Bridge, Floor, Waste, Back, Wing | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| Village / House | Village, House | 0 | 5 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| Stairs | Stairs | 0 | 10 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| Woods / Pillar | Woods, Pillar | 1 | 10 | 0 | 2 | 2 | 2 | 2 | 2 | 3 | 3 | 2 | 1 |
| Desert / Beach | Desert, Beach | 0 | 0 | 0 | 2 | 2 | 2 | 2 | 2 | 3 | 3 | 1 | 1 |
| Fort | Fort | 2 | 20 | 20% | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 1 |
| Gate | Gate | 3 | 20 | 20% | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 |
| Throne | Throne | 3 | 20 | 20% | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| Mountain | Mountain | 2 | 20 | 0 | 4 | 4 | 3 | 3 | X | X | 6 | 4 | 1 |
| Water | Water | 0 | 0 | 0 | 5 | X | X | 5 | X | X | X | X | 1 |
| Aerial | Cliff, Peak, Bones, Sea, Lake, Sky, Spring | 0 | 0 | 0 | X | X | X | X | X | X | X | X | 1 |
| Hazard | Hazard | 0 | 0 | -10 HP | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 1 |
| Sigil | Sigil | 1 | 10 | 0 | X* | X* | X* | X* | X* | X* | X* | X* | X* |
| Ire | Ire | 3 | 20 | 0 | X* | X* | X* | X* | X* | X* | X* | X* | X* |
| Breach | Breach | N/A | N/A | N/A | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| Low Obstacle | Edifice, Building, Chest, Partition, Supplies, Ship, Lava, Fence, Rubble, Grave, Coffin | N/A | N/A | N/A | X | X | X | X | X | X | X | X | 1 |
| High Obstacle | Wall, Door, Mast, Altar | N/A | N/A | N/A | X | X | X | X | X | X | X | X | X |

## Terrain Bonus Application

| Terrain Field | Applies To | Formula / Rule |
|---|---|---|
| DEF | Defender | Added to defender DEF for physical damage calculations |
| AVO | Defender | Added to defender avoid for hit calculations |
| HP Recovery | Occupying unit | Applied by terrain timing rule at phase start |
| Movement Cost | Moving unit | Subtracted from available movement budget |
| Flying Terrain Stat Bonus | Fliers | Fliers generally do not receive terrain stat bonuses except HP recovery where applicable |
| Impassable Terrain | Moving unit | Cannot enter/cross unless class/script grants exception |

## Terrain Category Normalization

| Raw Terrain Name | Canonical Category |
|---|---|
| Plain | Floor |
| Bridge | Floor |
| Floor | Floor |
| Waste | Floor |
| Back | Floor |
| Wing | Floor |
| Village | Village / House |
| House | Village / House |
| Stairs | Stairs |
| Woods | Woods / Pillar |
| Pillar | Woods / Pillar |
| Desert | Desert / Beach |
| Beach | Desert / Beach |
| Fort | Fort |
| Gate | Gate |
| Throne | Throne |
| Mountain | Mountain |
| Water | Water |
| Cliff | Aerial |
| Peak | Aerial |
| Bones | Aerial |
| Sea | Aerial |
| Lake | Aerial |
| Sky | Aerial |
| Spring | Aerial |
| Hazard | Hazard |
| Sigil | Sigil |
| Ire | Ire |
| Breach | Breach |
| Edifice | Low Obstacle |
| Building | Low Obstacle |
| Chest | Low Obstacle |
| Partition | Low Obstacle |
| Supplies | Low Obstacle |
| Ship | Low Obstacle |
| Lava | Low Obstacle |
| Fence | Low Obstacle |
| Rubble | Low Obstacle |
| Grave | Low Obstacle |
| Coffin | Low Obstacle |
| Wall | High Obstacle |
| Door | High Obstacle |
| Mast | High Obstacle |
| Altar | High Obstacle |

---

# Vulnerability Groups

## Canonical Vulnerability Group Table

| Vulnerability Group | Group ID | Description | Typical Class Sources | Typical Effective Sources |
|---|---:|---|---|---|
| Armor | VULN_ARMOR | Armored unit classification | Knight, General | Armorslayer, Hammer, armor-effective weapons |
| Cavalry | VULN_CAVALRY | Mounted ground unit classification | Cavalier, Paladin, Great Knight, Troubadour-line classes | Beast Killer, Ridersbane, cavalry-effective weapons |
| Flying | VULN_FLYING | Flying unit classification | Pegasus Knight, Falcon Knight, Dark Flier, Wyvern Rider, Wyvern Lord, Griffon Rider | Bows, wind/flying-effective weapons |
| Dragon | VULN_DRAGON | Dragon unit classification | Manakete, dragon bosses, dragon-tagged enemies | Falchion-type weapons, Wyrmslayer, dragon-effective weapons |
| Beast | VULN_BEAST | Beast or Taguel-style classification | Taguel, beast-tagged units | Beast Killer, beast-effective weapons |

## Vulnerability Group Storage

| Field | Type | Example |
|---|---|---|
| vulnerability_groups | List | `[Flying, Dragon]` |
| effective_against | List | `[Armor]` |
| effectiveness_immunity | List | `[Flying]` |
| effectiveness_override | Map | `{Dragon: 2}` |

## Multi-Group Rule

| Case | Rule |
|---|---|
| Defender has no vulnerability groups | No effectiveness applies |
| Defender has one matching vulnerability group | Effectiveness applies once |
| Defender has multiple matching groups | Effectiveness applies once unless source explicitly stacks |
| Weapon has no effective groups | No effectiveness applies |
| Immunity item/skill negates group | Remove that group before effectiveness check |
| Scripted override exists | Use override rule |

---

# Effectiveness Matrix

## Weapon Source vs Vulnerability Group

| Effective Source / Weapon Family | Armor | Cavalry | Flying | Dragon | Beast | Notes |
|---|---:|---:|---:|---:|---:|---|
| Standard Sword | No | No | No | No | No | No default effectiveness |
| Standard Lance | No | No | No | No | No | No default effectiveness |
| Standard Axe | No | No | No | No | No | No default effectiveness |
| Standard Bow | No | No | Yes | No | No | Bow-family flying effectiveness when weapon defines standard bow effectiveness |
| Standard Tome | No | No | No | No | No | No default effectiveness |
| Dark Tome | No | No | No | No | No | No default effectiveness |
| Staff | No | No | No | No | No | Utility category; offensive staves source-defined |
| Beaststone | No | No | No | No | No | Transformation weapon; no default broad effectiveness |
| Dragonstone | No | No | No | No | No | Transformation weapon; no default broad effectiveness |
| Armor-effective weapon | Yes | No | No | No | No | Weapon-specific |
| Cavalry-effective weapon | No | Yes | No | No | Yes / source-defined | Some weapons target both cavalry and beast-like mounted categories depending on data |
| Flying-effective weapon | No | No | Yes | No | No | Includes bows and flying-effective special weapons |
| Dragon-effective weapon | No | No | No | Yes | No | Falchion/Wyrmslayer-style weapons |
| Beast-effective weapon | No | Source-defined | No | No | Yes | Beast Killer-style weapons |
| Universal effective weapon | Yes | Yes | Yes | Yes | Yes | Only if explicitly scripted |

## Effectiveness Resolver

| Step | Operation |
|---:|---|
| 1 | Read defender `vulnerability_groups` |
| 2 | Read weapon `effective_against` groups |
| 3 | Remove groups negated by immunity |
| 4 | Compute intersection |
| 5 | If intersection is non-empty, set `IsEffective = True` |
| 6 | Apply weapon/source multiplier once unless source says otherwise |

## Effectiveness Boolean Table

| `WeaponEffectiveGroups ∩ DefenderVulnerabilityGroups` | Immunity Present | Result |
|---|---|---|
| Empty | No | Not effective |
| Empty | Yes | Not effective |
| Non-empty | No | Effective |
| Non-empty | Yes, all matching groups negated | Not effective |
| Non-empty | Yes, only some matching groups negated | Effective if at least one matching group remains |

---

# Damage Multipliers

## Core Damage Multiplier Table

| Multiplier Type | Multiplier | Applies To | Formula Placement | Stack Rule |
|---|---:|---|---|---|
| Normal damage | ×1 | Weapon might | Baseline | Default |
| Effective damage | ×3 | Weapon might | Before attack-defense subtraction | Applies once by default |
| Critical hit | ×3 | Final damage after defense | After damage calculation | Applies after effectiveness |
| Brave effect | ×2 strikes | Attack count | Attack sequence | Not a damage multiplier |
| Astra-style multi-hit | Source-defined | Attack sequence/damage packets | Skill-specific | Skill-specific |
| Dual Strike | Additional support attack | Attack sequence | After lead strike trigger | Not a direct multiplier |
| Dual Guard | ×0 damage | Incoming resolved damage | Before HP loss | Negates damage packet |
| Damage reduction skill | Source-defined | Incoming damage | Skill hook | Skill-specific |
| Fixed damage | N/A | HP directly or damage packet | Source-defined | Ignores standard multiplier unless specified |

## Effective Damage Formula Table

| Stage | Formula |
|---|---|
| Base weapon might | `WeaponMight` |
| Effective weapon might | `WeaponMight × EffectivenessMultiplier` |
| Attack after effectiveness | `DamageStat + EffectiveWeaponMight + AttackModifiers` |
| Damage before crit | `max(AttackAfterEffectiveness - DefenseStat, 0)` |
| Critical effective damage | `DamageBeforeCrit × 3` |

## Critical Damage Table

| Condition | Formula |
|---|---|
| Non-critical | `Damage` |
| Critical | `Damage × 3` |
| Effective non-critical | `DamageAfterEffectiveness` |
| Effective critical | `DamageAfterEffectiveness × 3` |

## Hit Resolution Clamp Table

| Value | Lower Bound | Upper Bound | Notes |
|---|---:|---:|---|
| FinalHit | 0 | 100 | Clamp before RNG resolution |
| FinalCrit | 0 | 100 | Clamp before RNG resolution |
| ProcRate | 0 | 100 | Clamp unless skill explicitly exceeds bounds |
| DualStrikeRate | 0 | 100 | Clamp before RNG resolution |
| DualGuardRate | 0 | 100 | Clamp before RNG resolution |

---

# Rank Progression Tables

## Weapon Rank Progression

| Current Rank | Current WEXP Range | Next Rank | WEXP Required for Next Rank | Additional WEXP Needed from Rank Floor |
|---|---:|---|---:|---:|
| None | 0 | E | 1 | 1 |
| E | 1–30 | D | 31 | 30 |
| D | 31–70 | C | 71 | 40 |
| C | 71–120 | B | 121 | 50 |
| B | 121–180 | A | 181 | 60 |
| A | 181–250 | S | 251 | 70 |
| S | 251–400 | Cap | 400 | 149 |

## WEXP Gain Count to Next Rank

Assuming standard `+2 WEXP` per valid weapon/staff action.

| From Rank Floor | Starting WEXP | Target Rank | Target WEXP | WEXP Needed | Standard Actions Needed |
|---|---:|---|---:|---:|---:|
| None | 0 | E | 1 | 1 | 1 |
| E | 1 | D | 31 | 30 | 15 |
| D | 31 | C | 71 | 40 | 20 |
| C | 71 | B | 121 | 50 | 25 |
| B | 121 | A | 181 | 60 | 30 |
| A | 181 | S | 251 | 70 | 35 |
| S | 251 | Cap | 400 | 149 | 75 |

## WEXP Gain Count to Next Rank With Discipline

Assuming Discipline doubles `+2 WEXP` to `+4 WEXP` per valid weapon/staff action.

| From Rank Floor | Starting WEXP | Target Rank | Target WEXP | WEXP Needed | Discipline Actions Needed |
|---|---:|---|---:|---:|---:|
| None | 0 | E | 1 | 1 | 1 |
| E | 1 | D | 31 | 30 | 8 |
| D | 31 | C | 71 | 40 | 10 |
| C | 71 | B | 121 | 50 | 13 |
| B | 121 | A | 181 | 60 | 15 |
| A | 181 | S | 251 | 70 | 18 |
| S | 251 | Cap | 400 | 149 | 38 |

## Weapon Rank Bonus Table

| Weapon Type | C Rank Bonus | B Rank Bonus | A Rank Bonus | S Rank Bonus | Notes |
|---|---|---|---|---|---|
| Sword | Attack +1 | Attack +2 | Attack +3 | Corpus-defined / source-defined | Bonus applies only while matching weapon is equipped |
| Lance | Attack +1 | Attack +1, Hit +5 | Attack +2, Hit +5 | Corpus-defined / source-defined | Shared bonus profile with bow/tome |
| Axe | Hit +5 | Hit +10 | Attack +1, Hit +10 | Corpus-defined / source-defined | Accuracy-heavy bonus profile |
| Bow | Attack +1 | Attack +1, Hit +5 | Attack +2, Hit +5 | Corpus-defined / source-defined | Shared bonus profile with lance/tome |
| Tome | Attack +1 | Attack +1, Hit +5 | Attack +2, Hit +5 | Corpus-defined / source-defined | Applies to standard tome rank |
| Dark Tome | Attack +1 | Attack +1, Hit +5 | Attack +2, Hit +5 | Corpus-defined / source-defined | Use tome-like profile unless dark-specific data overrides |
| Staff | Recovery +1 | Recovery +2 | Recovery +3 | Corpus-defined / source-defined | Healing output bonus, not attack |
| Beaststone | Source-defined | Source-defined | Source-defined | Source-defined | Transformation category |
| Dragonstone | Source-defined | Source-defined | Source-defined | Source-defined | Transformation category |

## Weapon Triangle Advantage Table

| Advantageous Weapon Rank | Advantage Bonus | Disadvantage Penalty |
|---|---|---|
| E | Hit +5 | Hit -5 |
| D | Hit +5 | Hit -5 |
| C | Hit +10 | Hit -10 |
| B | Hit +10, Attack +1 | Hit -10, Attack -1 |
| A | Hit +15, Attack +1 | Hit -15, Attack -1 |
| S | Corpus-defined / source-defined | Corpus-defined / source-defined |

## Weapon Triangle Relation Table

| Attacker Weapon | Defender Weapon | Attacker State | Defender State |
|---|---|---|---|
| Sword | Axe | Advantage | Disadvantage |
| Sword | Lance | Disadvantage | Advantage |
| Sword | Sword | Neutral | Neutral |
| Lance | Sword | Advantage | Disadvantage |
| Lance | Axe | Disadvantage | Advantage |
| Lance | Lance | Neutral | Neutral |
| Axe | Lance | Advantage | Disadvantage |
| Axe | Sword | Disadvantage | Advantage |
| Axe | Axe | Neutral | Neutral |
| Bow | Any | Neutral | Neutral |
| Tome | Any | Neutral | Neutral |
| Dark Tome | Any | Neutral | Neutral |
| Staff | Any | Neutral | Neutral |
| Stone | Any | Neutral | Neutral |

## Weapon Rank Bonus Cancellation Table

| Condition | Weapon Rank Bonus Applies |
|---|---|
| Unit has matching weapon rank C or higher and no triangle disadvantage | Yes |
| Unit has matching weapon rank below C | No |
| Unit faces enemy with weapon triangle advantage | No |
| Weapon type does not use standard rank bonus | Source-defined |
| Staff is used for healing | Staff recovery bonus applies |
| Staff is used offensively | Source-defined |

## Rank Label Sort Order

| Sort Index | Rank |
|---:|---|
| 0 | None |
| 1 | E |
| 2 | D |
| 3 | C |
| 4 | B |
| 5 | A |
| 6 | S |
| 7 | Cap |

## Rank Comparison Rules

| Operation | Rule |
|---|---|
| `RankA > RankB` | Compare sort index |
| `CanUseWeapon` | `UnitWEXP ≥ WeaponRequiredWEXP` |
| `RankAtLeast(Unit, Rank)` | `UnitWEXP ≥ RankRequirement[Rank]` |
| `IncreaseRankByOne` | Set WEXP to next rank threshold if below it |
| `ClampWEXP` | `min(max(WEXP, 0), 400)` |

---

# End of Phase 2 — Canonical Lookup Tables
