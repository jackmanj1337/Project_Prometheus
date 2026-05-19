# GDD_04 — Weapons & Items

---

## Weapon System Overview

Weapons are `WeaponData` resources stored in `data/weapons/`. Units carry weapons
and items together in a single inventory (`UnitData.inventory`) — an
`Array[InventoryEntry]` where each `InventoryEntry` has an `entry_type` of
`"weapon"`, `"item"`, or `"equip"`. Any slot can hold either a weapon or an item.

See **GDD_01 → InventoryEntry.gd** for the full resource definition.

`Unit.get_equipped_weapon()` filters for `is_weapon()` entries only and returns the
first one the unit can use. Items are accessed separately via the Item action.

A unit can equip any inventory entry that:
1. Is a weapon entry (`is_weapon()`)
2. Matches one of the unit's proficiency types
3. Is at or below the unit's current rank for that type
4. Still has uses (`has_uses()` — `uses_remaining != 0`)

---

## Weapon Types and Triangle Membership

| Type | Triangle | Notes |
|---|---|---|
| Sword | Physical (beats Axe, loses to Lance) | |
| Lance | Physical (beats Sword, loses to Axe) | |
| Axe | Physical (beats Lance, loses to Sword) | |
| Bow | None | Minimum range 2; effective vs Flying |
| Knife | None | Range 1–2 on thrown variants |
| Fire tome | Anima (beats Light, loses to Dark); effective vs Beast | Uses MAG, targets RES |
| Thunder tome | Anima (beats Light, loses to Dark); effective vs Dragon | Uses MAG, targets RES |
| Wind tome | Anima (beats Light, loses to Dark); effective vs Flying | Uses MAG, targets RES |
| Light tome | Magic (beats Dark, loses to Anima) | Uses MAG, targets RES |
| Dark tome | Magic (beats Anima, loses to Light) | Uses MAG, targets RES |
| Staff | None | Targets allies (healing) or enemies (status — Phase 2) |
| Fang/Claw/Talon/Beak | None | Laguz only (Phase 2) |

---

## MVP Weapons

These are the minimum weapons needed for the MVP map. One weapon per role.
Expand freely from the handbook weapon tables in Phase 2.

### Swords

| Name | Rank | Mt | Hit | Crit | Range | Wt | Uses | Cost | wEXP |
|---|---|---|---|---|---|---|---|---|---|
| Iron Sword | E | 6 | 85 | 0 | 1 | 7 | 45 | 460 | 1 |
| Steel Sword | D | 9 | 75 | 0 | 1 | 12 | 35 | 700 | 2 |

### Lances

| Name | Rank | Mt | Hit | Crit | Range | Wt | Uses | Cost | wEXP |
|---|---|---|---|---|---|---|---|---|---|
| Iron Lance | E | 7 | 80 | 0 | 1 | 8 | 45 | 450 | 1 |
| Javelin | E | 6 | 75 | 0 | 1–2 | 11 | 25 | 500 | 1 |

### Bows

| Name | Rank | Mt | Hit | Crit | Range | Wt | Uses | Cost | Effect | wEXP |
|---|---|---|---|---|---|---|---|---|---|---|
| Iron Bow | E | 6 | 85 | 0 | 2 | 5 | 45 | 540 | effective_flying | 1 |

### Fire Tomes (Anima)

| Name | Rank | Mt | Hit | Crit | Range | Wt | Uses | Cost | Effect | wEXP |
|---|---|---|---|---|---|---|---|---|---|---|
| Fire | E | 4 | 80 | 0 | 1–2 | 2 | 40 | 600 | effective_beast | 1 |
| Elfire | D | 5 | 70 | 5 | 1–2 | 4 | 30 | 900 | effective_beast | 1 |

### Thunder Tomes (Anima)

| Name | Rank | Mt | Hit | Crit | Range | Wt | Uses | Cost | Effect | wEXP |
|---|---|---|---|---|---|---|---|---|---|---|
| Thunder | E | 5 | 75 | 0 | 1–2 | 3 | 40 | 700 | effective_dragon | 1 |

### Wind Tomes (Anima)

| Name | Rank | Mt | Hit | Crit | Range | Wt | Uses | Cost | Effect | wEXP |
|---|---|---|---|---|---|---|---|---|---|---|
| Wind | E | 3 | 85 | 0 | 1–2 | 1 | 40 | 500 | effective_flying | 1 |

### Staves

| Name | Rank | Hit | Effect | Range | Wt | Uses | Cost | wEXP |
|---|---|---|---|---|---|---|---|---|
| Heal | E | — | Heals 10 + MAG HP to target | 1 | 2 | 40 | 700 | 1 |

---

## Effectiveness Mechanic

When a weapon has an `effective_*` tag matching a defending unit's special quality,
the weapon's Mt is treated as **3× its listed value** for damage calculation.

```gdscript
var effective_mt = weapon.mt
if weapon.effect_tags.has("effective_flying") and defender.has_quality("flying"):
    effective_mt = weapon.mt * 3
var damage = (attacker.str_or_mag() + effective_mt) - defender.def_or_res()
```

---

## Effect Tags Reference

Effect tags are strings stored in `WeaponData.effect_tags`. **Reference them via the
`GameConstants.TAG_*` constants — never raw strings — so a typo is a compile error,
not a silent miss.**

### Implemented tags

| Tag | `GameConstants` constant | Effect |
|---|---|---|
| `effective_flying` | `TAG_EFFECTIVE_FLYING` | 3× Mt vs units with the `flying` quality |
| `effective_armoured` | `TAG_EFFECTIVE_ARMOURED` | 3× Mt vs `armoured` |
| `effective_mounted` | `TAG_EFFECTIVE_MOUNTED` | 3× Mt vs `mounted` |
| `effective_dragon` | `TAG_EFFECTIVE_DRAGON` | 3× Mt vs `dragon` |
| `effective_beast` | `TAG_EFFECTIVE_BEAST` | 3× Mt vs `beast` |
| `heal_10_plus_mag` | `TAG_HEAL_PLUS_MAG` | Marks a staff as a healing staff (`is_healing_staff()`) |

The effectiveness multiplier is **3×** normally, **4×** with the Giantkiller skill.

### Not tags — dedicated `WeaponData` fields

| Mechanic | Field |
|---|---|
| 2 strikes before the counter (Brave weapons) | `strikes_per_attack = 2` |
| Uses MAG, targets RES (tomes) | `uses_mag = true` |
| Hybrid-weapon magic triangle | `magic_triangle_type` |

### Designed but not yet implemented (Phase 2)

`poison` (apply Poison on hit), `heal_on_hit` (lifesteal), `ignores_def` /
`ignores_half_def`, `always_hits`. Each needs a `GameConstants.TAG_*` constant and a
matching check in `CombatResolver.gd` when added.

---

## S-Rank Weapon Bonus

When a unit's proficiency for a weapon type reaches S rank, they gain:
- +10 Hit with that weapon type
- +5 Crit with that weapon type
- +1 Damage with that weapon type

Apply as a modifier when computing derived combat stats, not as a permanent stat change.

---

## Items

Items are non-weapon inventory entries with single-use or equippable effects.
Stored in `data/items/` as `ItemData` resources.

### `ItemData.gd` (extends Resource)
```gdscript
@export var id: String
@export var display_name: String
@export var description: String
@export var item_type: String     # "healing", "stat", "promotion", "equip", "key", "sellable"
@export var uses: int             # -1 = infinite / equippable
@export var cost: int
@export var effect_id: String     # dispatched by ItemHandler — MVP: "heal_flat" | "heal_full"
@export var effect_params: Dictionary   # e.g. { "amount": 20 } for heal_flat
```

### MVP Items

#### Healing Items
| Name | Effect | Uses | Cost |
|---|---|---|---|
| Vulnerary | Restore 10 HP | 3 | 600 |
| Elixir | Restore all HP | 3 | 3,000 |

#### Keys (Phase 2)
| Name | Effect | Uses | Cost |
|---|---|---|---|
| Chest Key | Opens 1 chest | 2 | 400 |
| Door Key | Opens 1 door | 2 | 200 |

#### Stat Items (Phase 2)
| Name | Effect | Cost |
|---|---|---|
| Energy Drop | Permanent +2 STR | 8,000 |
| Spirit Dust | Permanent +2 MAG | 8,000 |
| Seraph Robe | Permanent +7 max HP | 8,000 |
| Secret Book | Permanent +2 SKL | 8,000 |
| Speedwing | Permanent +2 SPD | 8,000 |
| Dracoshield | Permanent +2 DEF | 8,000 |
| Talisman | Permanent +2 RES | 8,000 |
| Goddess Icon | Permanent +2 LUK | 8,000 |
| Boots | Permanent +2 MOV | 8,000 |
| Statue Frag | Permanent +2 CON | 8,000 |
| Arms Scroll | Advance 1 proficiency rank | 8,000 |

#### Equip Items (Phase 2)
These occupy the equip slot and cannot be swapped during combat.
| Name | Effect | Cost |
|---|---|---|
| Full Guard | Negate all effectiveness bonuses | 8,500 |
| Iron Rune | Negate all critical hits | 6,500 |
| Knight Ring | Unit gains mounted post-action movement | 8,500 |
| Wing Guard | Negate Flying effectiveness | 6,000 |
| Laguz Guard | Negate Laguz effectiveness | 6,000 |

---

## Forging System (Phase 2)

Weapons can be upgraded at a forge (designated map event or between-map screen).
Rules:

- Can only forge a weapon once, at time of purchase
- Staves cannot be forged
- Stats that can be changed:
  - Mt: ±5 in increments of 1
  - Hit: ±25 in increments of 5
  - Crit: ±15 in increments of 3
  - Wt: ±5 in increments of 1
- Total modifications: up to 20 across all stats

### Forging Cost Table
| Increment | Cost | Running Total |
|---|---|---|
| 1st | 150g | 150g |
| 2nd | 300g | 450g |
| 3rd | 450g | 900g |
| 4th | 600g | 1,500g |
| 5th | 750g | 2,250g |

Each stat tracked independently. Max cost for fully forging all 4 stats = 9,000g.

### Data Representation
Forged weapons use the same `InventoryEntry` weapon slot with a populated
`forged_mods` dictionary; unforged weapons leave it empty. The `forged_mods` field
already exists on `InventoryEntry` (reserved — no code reads it yet; M10).
```gdscript
# An InventoryEntry weapon slot (see GDD_01 → InventoryEntry.gd):
entry_type     = "weapon"
weapon_id      = "iron_sword"
uses_remaining = 45
forged_mods    = { "mt": 2, "hit": 5, "crit": 0, "wt": -1 }
```

---

## Selling Items

Any item or weapon entry in inventory can be sold for:
```
sale_value = floor(base_cost * (uses_remaining / max_uses) / 2)
```
`max_uses` is read from the corresponding `WeaponData.uses` or `ItemData.uses`.
Equip items (uses = -1) sell for `floor(base_cost / 2)`.

---

## Inventory Management

- Each unit has one inventory: `UnitData.inventory` — a flat `Array[InventoryEntry]`
- Each entry's `entry_type` is `"weapon"`, `"item"`, or `"equip"` — slots interchange
- **Limit:** 8 slots (`GameState.max_inventory`) — NOT yet enforced (no inventory UI)
- Units can trade entries with adjacent allies on their turn (Trade action)
- Items and weapons cannot be used during the enemy phase

---

## Stationary Weapons (Phase 2)

Found on the battlefield; usable by non-mounted units with bow proficiency (any rank).

| Name | Mt | Hit | Crit | Range | Effect |
|---|---|---|---|---|---|
| Ballista | 18 | 100 | 0 | 3–10 | Effective vs Flying; ignores user STR |
| Iron Ballista | 22 | 90 | 0 | 3–15 | Effective vs Flying; ignores user STR |
| Killer Ballista | 20 | 95 | 15 | 3–10 | Effective vs Flying; ignores user STR |
| Onager | 20 | Always hits | Cannot crit | 3–10 | AoE (target + adjacent); ignores user STR |

Stationary weapons are map objects, not inventory items. Implement as interactable
tiles with a weapon definition embedded in `MapData`.
