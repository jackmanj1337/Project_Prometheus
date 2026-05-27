# GDD_02 — Core Mechanics

---

## The Grid

- The battlefield is a **square tile grid**
- Tiles are navigated **orthogonally only** (no diagonal movement)
- MVP map size: up to **30×30 tiles**; system supports up to ~50×50
- Each tile has a **terrain type** that affects movement cost, defense, and dodge
- Units occupy exactly **one tile** at a time
- A tile can hold at most **one unit** (ally or enemy)
- Allied units can be **passed through** during movement; enemy units cannot

### Tile Coordinate System
Use Godot's `Vector2i` for all tile positions. `(0, 0)` = top-left corner.

---

## Terrain Types

| Terrain | DEF Bonus | Dodge Bonus | Move Cost | Notes |
|---|---|---|---|---|
| Plain | 0 | 0 | 1 | Standard |
| Forest | +1 | +15 | 2 | |
| Mountain | +2 | +20 | 3 | |
| Fort / Throne | +2 | +30 | 1 | Unit heals 10% max HP per turn |
| Sea | 0 | +10 | 2 | |
| Desert | 0 | +5 | 2 | Armoured/Mounted cost 3; Magic users/Thief line cost 1 |
| Wall / Building | — | — | Impassable | Blocks movement |

Terrain bonuses apply to **defending units only**. Attackers receive no terrain bonus.

Flying units ignore movement cost penalties and can cross most terrain types.
For MVP, **wall tiles remain impassable to all units including flying**. Per-map
exceptions (e.g. flying units crossing walls on specific maps) can be designated
in Phase 2 via a flag in `MapData`.

---

## Turn Structure

The live game now uses a **faction-based phase scheduler**. Every map can author:

- `MapData.factions` — display name, color, alliance group, controller
- `MapData.turn_order` — the order factions act in
- `MapData.activation_mode` — currently `WHOLE_PHASE` in shipped content

### Default Whole-Phase Loop

Most maps still play like a classic Fire Emblem round, but the implementation is
data-driven rather than hardcoded to player/enemy:

```
Round Start
  └── BLUE PHASE
        ├── Blue units refresh
        ├── per-unit "turn" modifiers tick
        ├── fort healing and start_of_turn skills resolve
        ├── player controls blue units until all are DONE or End Turn is chosen
  └── GREEN / RED / YELLOW PHASES (if authored in turn_order)
        ├── acting faction refreshes
        ├── per-unit "turn" modifiers tick
        ├── fort healing and start_of_turn skills resolve
        └── controller runs the faction (AI or hotseat)
  └── Round wraps back to blue
        ├── all-units "map_turn" modifiers tick once
        └── turn counter increments
```

### Controllers

- `blue` is the standard player-controlled faction
- non-blue factions may be AI-controlled or `HOTSEAT`-controlled per `FactionData.controller`
- objective checks run at phase boundaries, after combat deaths, and after Seize / Escape

### Alternating Mode

`ALTERNATING` exists in `TurnManager` as an engine primitive, but shipped maps and
manual validation currently target `WHOLE_PHASE`. Treat alternating activation as
implemented infrastructure, not production gameplay yet.

### Unit Action States
Each unit tracks one of three states per round:
- `READY` — Has not moved or acted
- `MOVED` — Has moved, can still act
- `DONE` — Cannot act further this round

### End of a Controlled Phase
- A controlled phase ends **automatically** when every unit in the acting faction
  is `DONE`.
- The acting human controller can also end the phase early from the Map Menu.
- Hotseat phases use the same commit flow as blue's phase; the difference is only
  which faction the cursor is allowed to command.

---

## Unit Stats

All stats are integers. All calculated values are **rounded down**. Negative results
become **0**.

| Stat | Description |
|---|---|
| **HP** | Hit points. At 0, unit is dead or incapacitated |
| **STR** | Strength. Adds to physical weapon damage |
| **MAG** | Magic. Adds to tome/staff damage and effectiveness |
| **DEF** | Defense. Reduces incoming physical damage |
| **RES** | Resistance. Reduces incoming magical damage |
| **SKL** | Skill. Affects hit rate and critical hit rate |
| **SPD** | Speed. Affects number of attacks and dodge rate |
| **LUK** | Luck. Affects hit, dodge, and crit avoidance |
| **MOV** | Movement. Tiles the unit can move per turn |
| **CON** | Constitution. Affects rescue/shove eligibility and related future carry systems |
| **LoS** | Line of Sight. Tiles visible in fog-of-war maps (Phase 2+) |

### Derived Combat Stats (per equipped weapon)

These are calculated fresh each time and shown in the UI:

| Derived Stat | Formula |
|---|---|
| **Battle Speed** | `SPD - max(0, Wt - STR)` |
| **Accuracy** | `SKL × 2 + LUK + weapon.Hit` |
| **Dodge** | `Battle Speed × 2 + LUK` |
| **To-Hit %** | `Accuracy - target.Dodge` (clamped 0–100) |
| **Damage** | `(STR or MAG) + weapon.Mt - target.(DEF or RES)` (min 0) |
| **Critical** | `floor(SKL / 2) + weapon.Crit` |
| **Crit Avoid** | `LUK` |
| **Crit %** | `Critical - target.Crit Avoid` (clamped 0–100) |

> Note: Terrain DEF/Dodge bonuses are added to the defender's values during combat
> but do **not** permanently modify stats.

---

## Weapon Triangle

Two separate triangles. Each gives **+10 Accuracy and +2 Damage** when at advantage,
**-10 Accuracy and -2 Damage** when at disadvantage.

### Physical Weapons
```
Swords → Axes → Lances → Swords
(Swords beat Axes, Axes beat Lances, Lances beat Swords)
```

### Magic Tomes
```
Dark → Anima (Fire/Thunder/Wind) → Light → Dark
```

### Rules
- Weapons not in a triangle (bows, knives, staves) have no triangle interaction
- A weapon type has no advantage or disadvantage against **itself**
- Hybrid weapons (e.g. Sonic Sword, Bolt Axe) use a specified magic type for triangle
  purposes and their own physical type simultaneously — use whichever gives advantage

### Implementation Note
Store triangle relationships in `DataManager` as a lookup table:
```gdscript
# Returns "advantage", "disadvantage", or "neutral"
DataManager.get_weapon_triangle_result("sword", "axe")  # → "advantage"
```

---

## Combat Resolution

When a unit attacks, resolve the following **exchange sequence** in order:

1. **Attacker's first attack**
2. **Defender's counterattack** (only if target is within their equipped weapon's range)
3. **Follow-up attack** — if one unit's Battle Speed is **4 or more** higher than the
   other's, that unit makes one additional attack

> Both the follow-up check and the counterattack check happen at the **start** of
> combat resolution — determine all attacks before resolving any of them.
> This prevents mid-combat stat changes from affecting the sequence.

Two modifiers affect this sequence:
- **Brave weapons** (`WeaponData.strikes_per_attack = 2`) make the wielder strike
  twice per attack slot — including on the counterattack and the follow-up.
- **Vantage** (a skill) makes the defender take their counterattack *first*, before
  the attacker's strike.

`CombatResolver` resolves an exchange the instant the player confirms (MVP has no
combat animation): `resolve_combat()` builds the exchange list and rolls RNG, then
`apply_combat_result()` commits HP/durability/EXP. See GDD_01 → CombatResolver.

### Single Attack Resolution

For each individual attack. The roll is `randi() % 100`, yielding 0–99:

1. Calculate **To-Hit %** (factoring weapon triangle and terrain).
2. Roll RNG — if `roll < To-Hit %`, the attack connects; otherwise it misses.
3. If it hits, calculate **Crit %**.
4. Roll RNG again — if `roll < Crit %`, the hit is a critical.
5. **Damage** is already `(STR or MAG) + weapon.Mt - target.(DEF or RES)` (see the
   Derived Combat Stats table — DEF/RES is subtracted exactly once, here). A critical
   hit then **triples that final figure** (`damage × 3`); any skill damage-multiplier
   is applied last. The result is clamped to a minimum of 0.
6. Reduce the target's HP by the damage.
7. If the target's HP ≤ 0, stop the exchange — no further attacks land.

### Weapon Durability
- **Melee and thrown weapons**: lose 1 use only on a **successful hit**
- **Bows, tomes, staves**: lose 1 use on **any use**, hit or miss
- Durability is consumed whether the attack is made as the **initiator or as a counterattacker** — the same rules apply in both directions
- When a weapon's uses reach 0 it is **destroyed** and removed from inventory
- Units with no usable weapon in their equipped slot cannot attack
  (they can still counterattack if they have another weapon in inventory — Phase 2+)

---

## Weapon Proficiency (wEXP)

Each unit tracks weapon proficiency as numeric totals per WEXP track:
`{ "sword": 100, "lance": 40 }`

- Every successful hit with a weapon grants `weapon.wexp` points to that track
- Rank letters are derived from the stored total using `GameConstants.WEXP_RANK_THRESHOLDS`
- **S rank bonus**: +10 Hit, +5 Crit, +1 Damage with that weapon type
- A unit can only equip weapons at or below their current rank for that type
- Class resources author WEXP baselines/caps; promotion and reclass raise a unit to at
  least the new class's authored baselines for any gained weapon tracks

---

## Actions Available on a Unit's Turn

A unit may **Move** and then take **one action**, or skip movement and act in place.
Some actions end the turn; some do not.

| Action | Ends Turn? | Notes |
|---|---|---|
| **Move** | No | Up to MOV tiles; can be undone unless unit revealed an enemy |
| **Attack** | Yes | Must have a valid target in weapon range |
| **Staff** | Yes | Heal an allied unit in range; awards EXP and wEXP |
| **Use Item** | Yes | Consumes one use of a healing/utility item |
| **Equip Weapon** | No | Switch active weapon; does not consume turn |
| **Trade** | No* | Swap items with adjacent ally; if unit has already moved, trading ends their turn; if unit has not yet moved, they may still take an action after trading |
| **Shove** | Yes | Push adjacent non-mounted ally 1 tile |
| **Pair Up** | Yes | Combine with an adjacent unpaired ally when campaign Pair Up is enabled |
| **Swap** | Yes | Swap lead/support roles inside an existing pair |
| **Separate** | Yes | Drop the support unit onto an adjacent valid tile |
| **Wait** | Yes | End turn without acting |
| **Seize** | Yes | Map objective action on specific tile |
| **Escape** | Yes | Map objective action on specific tile |
| **Class Ability** | Yes | If the ability requires an action |

> *Trade: after trading, the unit may still act if they have not yet moved this turn; otherwise the trade ends their turn.

> **Current implementation:** the shipped action flow supports **Move, Attack, Staff,
> Item, Equip, Wait, Seize, Escape, Pair Up, Swap, and Separate**. Trade, Shove,
> Rescue/carry, and other class-specific field actions remain future work.

### Mounted / Flying Unit Exception
After any turn-ending action (other than Wait), a **mounted or flying unit** may move
any remaining movement tiles, but must then Wait.

> This is still a design target, not a shipped runtime rule. The current codebase
> does **not** implement post-action remainder movement / Canto yet.

---

## Experience Points (EXP)

Units gain EXP through combat, staff use, and certain class abilities.
At 100 EXP, the unit levels up and resets to 0 (carrying over any excess).

### Combat EXP Table

EXP is symmetric — it goes to whichever unit dealt a blow, not just the player.
Level difference = **the acting unit's level minus the opponent's level**; positive
means the acting unit is higher level. `CombatResolver.calculate_exp()` indexes this
table with `clamp(level_diff + 6, 0, 12)`.

| Level Difference (acting unit minus opponent) | EXP for Kill | EXP for Damage Only |
|---|---|---|
| 6+ levels lower | 59 | 20 |
| 5 lower | 57 | 19 |
| 4 lower | 53 | 18 |
| 3 lower | 47 | 16 |
| 2 lower | 41 | 14 |
| 1 lower | 35 | 12 |
| Equal | 30 | 10 |
| 1 higher | 25 | 8 |
| 2 higher | 19 | 6 |
| 3 higher | 13 | 4 |
| 4 higher | 7 | 2 |
| 5 higher | 3 | 1 |
| 6+ higher | 1 | 0 |

> EXP is granted once per **combat exchange**, not per hit.
> wEXP increases per successful **hit**.

### Staff EXP (MVP — Heal only)

A staff use awards a **flat 10 EXP** to the healer (`GameConstants.STAFF_HEAL_EXP`),
regardless of staff type or promotion status. A pre-/post-promotion staff-EXP curve
is a Phase 2 refinement.

---

## Leveling Up

When a unit reaches 100 EXP:
1. Level increases by 1, EXP resets (overflow carries)
2. Stats increase using the selected leveling method (see below)
3. Level-up animation plays `[PLACEHOLDER]`
4. New stats are saved to `UnitData`

### Leveling Methods (per-save setting)

The leveling method is chosen on the New Game screen and stored in
`GameState.leveling_method`. **Two methods are implemented:**

| Method (`leveling_method`) | Description |
|---|---|
| `growth_random` (default) | Each stat has a growth-rate %, rolled per stat each level. A rate above 100 grants that many guaranteed points plus a roll for the remainder. The classic FE growth-rate system. |
| `growth_fixed` | Deterministic accumulator: each level adds the growth rate to a per-stat carry; every full 100 accumulated yields +1. Perfectly predictable. The carry persists in `UnitData.growth_accumulators`. |

> **Designed but not yet implemented:** Point Buy (assign N points/level), Coin Flip
> (50% per stat), and Dice Roll. These are Phase 2 refinements — the New Game screen
> currently offers only Random and Fixed.

### Growth Rates (per class)

`ClassData.growth_rates` is a Dictionary keyed by **full stat names** (not the
abbreviations), values 0–100+:
```gdscript
@export var growth_rates: Dictionary
# e.g. { "hp": 75, "strength": 50, "magic": 5, "defense": 45,
#         "resistance": 25, "skill": 50, "speed": 45, "luck": 40 }
```

---

## Class Promotion

- Beorc units promote at **level 20** (or earlier with a promotion item)
- At promotion: unit chooses one of two promoted class options
- Promotion stat bonuses are added immediately
- Promotion skill is granted automatically
- Occult skill can be granted via Occult Scroll item (Phase 2)
- Post-promotion levels are tracked separately; effective level = pre + post
- Growth rates increase by 5% across all stats at promotion (if using growth rate method)

---

## Permadeath System

Controlled by `GameState.permadeath_enabled` (bool).

### Permadeath ON
- Unit is removed from the map when HP reaches 0
- Unit's `UnitData` is retained — stats, level, inventory preserved
- Unit is **flagged** as `is_incapacitated = true`
- Incapacitated units cannot be deployed in future maps
- The unit data is never deleted — it can be "revived" by the designer later
  (e.g. via story event) or the player can view their fallen units

### Permadeath OFF
- Unit collapses on the map, is removed from play for that map
- Unit is fully available in the next map
- No `is_incapacitated` flag is set

### Game Over Condition
Regardless of permadeath setting, if a **designated required unit** (e.g. the lord
character) dies, the map ends in defeat and the player is returned to a retry screen.

---

## Status Conditions

Phase 2+ (listed here for architectural awareness — build condition slots into `UnitData`
from the start).

| Condition | Effect | Duration |
|---|---|---|
| **Berserk** | Auto-attacks the target with the **highest projected damage** in range; tiebreak nearest → lowest unit id; can hit allies | 3 turns |
| **Silence** | Cannot use weapons whose `weapon_type` is `TOME` or `STAFF` (physical weapons unaffected) | 4 turns |
| **Sleep** | Cannot move, act, or counterattack; dodge disabled | 3 turns |
| **Poison** | -3 HP at start of turn; **floors at 1 HP by default** (source-supplied `can_be_lethal` opts in to killing); -10 Accuracy and Dodge | 5 turns |
| **Stun** | Cannot move, act, or counterattack; dodge disabled | 1 turn |

Store conditions on `UnitData` as:
```gdscript
@export var conditions: Array[Dictionary]
# Standard schema: { "type": String, "turns_remaining": int }.
# Do not pre-add source_id / magnitude / tags — extend only when a specific
# condition (e.g. Hex's skill payload) genuinely needs an extra field.
# e.g. [{ "type": "poison", "turns_remaining": 3 }]
```

**Locked 2026-05-25:** see `AGENT/Docs/campaign_rules_firming_notes_2026-05-25.md`
and the M8 section of `GDD_10_Roadmap.md`. The Poison `can_be_lethal` flag,
Berserk's projected-damage targeting, Silence's tome/staff filter, and the
minimal condition schema were settled before M8 implementation begins.

---

## Rescue and Shove

### Shove
- Non-mounted units only
- Push an adjacent unit (ally or enemy — GM discretion) 1 tile in a direction
- Target tile must be unoccupied
- Some units cannot be shoved (implement as a special quality flag: `no_shove`)
- Ends the shoving unit's turn

### Rescue (Phase 2)
- Unit picks up an adjacent ally with lower CON
- Rescued unit is carried; loses its turn while carried
- Rescuing unit loses ½ SPD and ½ SKL while carrying
- Rescued unit can be dropped to any adjacent unoccupied tile

---

## Gold and Economy

- Each unit has their own gold pool stored in `UnitData`
- Units start with **1,000 gold** at campaign start
- Gold is used to buy weapons and items at shops (Phase 2 — shop scenes)
- Items can be sold for **½ their base value**, reduced proportionally by remaining uses:
  `sale_price = floor(base_cost * (uses_remaining / max_uses) / 2)`
