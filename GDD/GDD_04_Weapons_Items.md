# GDD_04 — Weapons & Items

---

## Weapon System Overview

Weapons are `WeaponData` resources stored in `data/weapons/`. Units carry weapons
and items together in a single inventory (`UnitData.inventory`) — an `Array[Dictionary]`
where every entry has a `"type"` field of either `"weapon"` or `"item"`. This means
any inventory slot can hold either a weapon or an item interchangeably.

See **GDD_01 → Inventory Entry Format** for the full dictionary structure.

`Unit.get_equipped_weapon()` filters for `type == "weapon"` entries only and returns
the first one the unit can use. Items are accessed separately via the Item action.

A unit can equip any weapon entry in their inventory that:
1. Has `type == "weapon"`
2. Matches their proficiency types
3. Is at or below their current rank for that type
4. Has `uses_remaining > 0`

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

Effect tags are strings stored in `WeaponData.effect_tags`. The `CombatResolver`
checks for these tags during combat.

| Tag | Effect |
|---|---|
| `effective_flying` | 3× Mt vs units with `flying` quality |
| `effective_armoured` | 3× Mt vs units with `armoured` quality |
| `effective_mount` | 3× Mt vs units with `mounted` quality |
| `effective_dragon` | 3× Mt vs units with `dragon` quality |
| `effective_beast` | 3× Mt vs units with `beast` quality |
| `effective_laguz` | 3× Mt vs units with `laguz` quality |
| `poison` | Applies Poison condition on hit (Phase 2) |
| `2x_strikes` | Unit makes 2 attacks before defender counterattacks |
| `uses_mag` | Uses MAG instead of STR; targets RES instead of DEF |
| `magic_triangle_wind` | Uses Wind magic triangle, even if physical weapon |
| `magic_triangle_fire` | Uses Fire magic triangle |
| `magic_triangle_thunder` | Uses Thunder magic triangle |
| `magic_triangle_light` | Uses Light magic triangle |
| `magic_triangle_dark` | Uses Dark magic triangle |
| `heal_on_hit` | User regains HP equal to damage dealt (e.g. Nosferatu, Runesword) |
| `ignores_def` | Damage ignores DEF/RES entirely (e.g. Eclipse) |
| `ignores_half_def` | Damage ignores half of DEF/RES (e.g. some occult skills) |
| `always_hits` | Bypasses hit roll (e.g. Onager) |

Add new tags here as needed. Each tag needs a corresponding check in `CombatResolver.gd`.

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
@export var effect_id: String     # Links to ItemHandler logic
@export var effect_params: Dictionary
```

### MVP Items

#### Healing Items
| Name | Effect | Uses | Cost |
|---|---|---|---|
| Vulnerary | Restore 20 HP | 3 | 600 |
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
Forged weapons use the same `"weapon"` inventory entry format with an additional
`forged_mods` dictionary. Unforged weapons have an empty `forged_mods` dict.
```gdscript
{
  "type": "weapon",
  "weapon_id": "iron_sword",
  "uses_remaining": 45,
  "forged_mods": { "mt": 2, "hit": 5, "crit": 0, "wt": -1 }
}
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

- Each unit has one inventory: `UnitData.inventory` — a flat `Array[Dictionary]`
- Every entry has `"type": "weapon"` or `"type": "item"` — slots are interchangeable
- **Limit:** 8 slots total across weapons and items (configurable via `GameState.max_inventory`)
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
