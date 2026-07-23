> **Historical** — External Awakening reference corpus; not active Project Prometheus rules or public-pack content.

# Fire Emblem Awakening Technical Reference Corpus
# Item Encyclopedia

**File:** `awakening_items.md`  
**Phase:** 9  
**Corpus Version:** `0.10.0-phase9`  
**Depends On:** `awakening_project_index.md`, `awakening_core_systems.md`, `awakening_lookup_tables.md`, `awakening_classes_base.md`, `awakening_classes_promoted.md`, `awakening_classes_special.md`, `awakening_skills.md`, `awakening_weapons_physical.md`, `awakening_weapons_magic.md`  
**Scope:** Non-weapon inventory items, healing items, consumables, valuables, seals, permanent boosters, utility items, and DLC items.

---

# Table of Contents

1. [Phase Boundary](#phase-boundary)
2. [Normalization Notes](#normalization-notes)
3. [Healing Items](#healing-items)
4. [Consumables and Temporary Buffs](#consumables-and-temporary-buffs)
5. [Permanent Boosters](#permanent-boosters)
6. [Seals and Class-Change Items](#seals-and-class-change-items)
7. [Valuables](#valuables)
8. [Utility Items](#utility-items)
9. [DLC Skill Items](#dlc-skill-items)
10. [Item Count Audit](#item-count-audit)

---

# Phase Boundary

This document includes inventory items that are not weapons.

| Item Family | Included |
|---|---|
| Healing items | Yes |
| Consumables | Yes |
| Temporary stat boosters | Yes |
| Permanent stat boosters | Yes |
| Valuables | Yes |
| Master Seal / Second Seal | Yes |
| DLC class-change items | Yes |
| Utility keys | Yes |
| World-map utility items | Yes |
| DLC skill-teaching items | Yes |
| DLC placeholder items | Yes |
| Weapons | No; Phases 7–8 |
| Skills as learned effects | Defined here only as item-granted unlocks; full skill mechanics are in Phase 6 |

---

# Normalization Notes

## Sell Value

Normal item sell value:

```text
Sell = floor(Worth / 2)
```

Special/event item sell value:

```text
Sell = floor(Worth / 4)
```

Valuables with explicit sell values use their explicit sale value.

## Temporary Buff Duration

Tonic/confect-style temporary buffs last until the end of the current chapter or skirmish.

```text
TemporaryBuffExpires = ChapterEnd
```

Pure Water is handled separately because it decays by 1 point per turn.

## Permanent Booster Cap Enforcement

Permanent stat boosters cannot raise a stat beyond the final cap.

```text
PermanentStatAfterBooster =
min(PermanentStatBeforeBooster + BoosterAmount, FinalStatCap)
```

## Uses

`Uses = 0` indicates a non-use valuable that exists only to be sold.  
`Uses = 1` indicates a single-use item or key-item-like DLC item state.

---


# Healing Items

## Vulnerary

| Property | Value |
|---|---|
| Category | Healing |
| Uses | 3 |
| Worth | 300 |
| Sell | 150 |
| Target | Self |
| Timing | Command item use during map combat preparation/action context |
| Effect | Restores 10 HP to the user. |
| Formula | `CurrentHP = min(CurrentHP + 10, MaxHP)` |
| Restrictions | None |
| Availability | Base game |

## Concoction

| Property | Value |
|---|---|
| Category | Healing |
| Uses | 3 |
| Worth | 600 |
| Sell | 300 |
| Target | Self |
| Timing | Command item use during map combat preparation/action context |
| Effect | Restores 20 HP to the user. |
| Formula | `CurrentHP = min(CurrentHP + 20, MaxHP)` |
| Restrictions | None |
| Availability | Base game |

## Elixir

| Property | Value |
|---|---|
| Category | Healing |
| Uses | 3 |
| Worth | 900 |
| Sell | 450 |
| Target | Self |
| Timing | Command item use during map combat preparation/action context |
| Effect | Fully restores the user's HP. |
| Formula | `CurrentHP = MaxHP` |
| Restrictions | None |
| Availability | Base game |

## Sweet Tincture

| Property | Value |
|---|---|
| Category | Healing / Event Consumable |
| Uses | 3 |
| Worth | 150 |
| Sell | 37 |
| Target | Self |
| Timing | Command item use during map combat preparation/action context |
| Effect | Restores 5 HP to the user. |
| Formula | `CurrentHP = min(CurrentHP + 5, MaxHP)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Special/event-style consumable; sells for one-quarter of listed worth.


---

# Consumables and Temporary Buffs

## Pure Water

| Property | Value |
|---|---|
| Category | Temporary Stat Buff |
| Uses | 3 |
| Worth | 600 |
| Sell | 300 |
| Target | Self |
| Timing | Command item use; effect begins immediately |
| Effect | Grants +5 RES on the turn used; bonus decreases by 1 each turn afterward. |
| Formula | `RESBuff(t) = max(5 - TurnsElapsed, 0)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Unlike tonics, Pure Water decays over turns rather than lasting at full value for the entire map.

## HP Tonic

| Property | Value |
|---|---|
| Category | Temporary Stat Buff / Tonic |
| Uses | 1 |
| Worth | 150 |
| Sell | 75 |
| Target | Self |
| Timing | Pre-battle or map item use depending on inventory context |
| Effect | Max HP +5 until the chapter/skirmish ends. |
| Formula | `TemporaryMaxHP += 5` |
| Restrictions | None |
| Availability | Base game |

## Strength Tonic

| Property | Value |
|---|---|
| Category | Temporary Stat Buff / Tonic |
| Uses | 1 |
| Worth | 150 |
| Sell | 75 |
| Target | Self |
| Timing | Pre-battle or map item use depending on inventory context |
| Effect | STR +2 until the chapter/skirmish ends. |
| Formula | `TemporarySTR += 2` |
| Restrictions | None |
| Availability | Base game |

## Magic Tonic

| Property | Value |
|---|---|
| Category | Temporary Stat Buff / Tonic |
| Uses | 1 |
| Worth | 150 |
| Sell | 75 |
| Target | Self |
| Timing | Pre-battle or map item use depending on inventory context |
| Effect | MAG +2 until the chapter/skirmish ends. |
| Formula | `TemporaryMAG += 2` |
| Restrictions | None |
| Availability | Base game |

## Skill Tonic

| Property | Value |
|---|---|
| Category | Temporary Stat Buff / Tonic |
| Uses | 1 |
| Worth | 150 |
| Sell | 75 |
| Target | Self |
| Timing | Pre-battle or map item use depending on inventory context |
| Effect | SKL +2 until the chapter/skirmish ends. |
| Formula | `TemporarySKL += 2` |
| Restrictions | None |
| Availability | Base game |

## Speed Tonic

| Property | Value |
|---|---|
| Category | Temporary Stat Buff / Tonic |
| Uses | 1 |
| Worth | 150 |
| Sell | 75 |
| Target | Self |
| Timing | Pre-battle or map item use depending on inventory context |
| Effect | SPD +2 until the chapter/skirmish ends. |
| Formula | `TemporarySPD += 2` |
| Restrictions | None |
| Availability | Base game |

## Luck Tonic

| Property | Value |
|---|---|
| Category | Temporary Stat Buff / Tonic |
| Uses | 1 |
| Worth | 150 |
| Sell | 75 |
| Target | Self |
| Timing | Pre-battle or map item use depending on inventory context |
| Effect | LCK +2 until the chapter/skirmish ends. |
| Formula | `TemporaryLCK += 2` |
| Restrictions | None |
| Availability | Base game |

## Defense Tonic

| Property | Value |
|---|---|
| Category | Temporary Stat Buff / Tonic |
| Uses | 1 |
| Worth | 150 |
| Sell | 75 |
| Target | Self |
| Timing | Pre-battle or map item use depending on inventory context |
| Effect | DEF +2 until the chapter/skirmish ends. |
| Formula | `TemporaryDEF += 2` |
| Restrictions | None |
| Availability | Base game |

## Resistance Tonic

| Property | Value |
|---|---|
| Category | Temporary Stat Buff / Tonic |
| Uses | 1 |
| Worth | 150 |
| Sell | 75 |
| Target | Self |
| Timing | Pre-battle or map item use depending on inventory context |
| Effect | RES +2 until the chapter/skirmish ends. |
| Formula | `TemporaryRES += 2` |
| Restrictions | None |
| Availability | Base game |

## Kris's Confect

| Property | Value |
|---|---|
| Category | Temporary Stat Buff / Event Consumable |
| Uses | 5 |
| Worth | 1000 |
| Sell | 250 |
| Target | Self |
| Timing | Command item use; effect lasts until chapter/skirmish ends |
| Effect | Max HP +5, DEF +2, and RES +2 until the chapter/skirmish ends. |
| Formula | `TemporaryMaxHP += 5; TemporaryDEF += 2; TemporaryRES += 2` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Special/event-style consumable; sells for one-quarter of listed worth.

## Gaius's Confect

| Property | Value |
|---|---|
| Category | Temporary Stat Buff / Event Consumable |
| Uses | 5 |
| Worth | 2000 |
| Sell | 500 |
| Target | Self |
| Timing | Command item use; effect lasts until chapter/skirmish ends |
| Effect | STR +2, SKL +2, and SPD +2 until the chapter/skirmish ends. |
| Formula | `TemporarySTR += 2; TemporarySKL += 2; TemporarySPD += 2` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Special/event-style consumable; sells for one-quarter of listed worth.

## Tiki's Tear

| Property | Value |
|---|---|
| Category | Temporary Stat Buff / Event Consumable |
| Uses | 1 |
| Worth | 1000 |
| Sell | 250 |
| Target | Self |
| Timing | Command item use; effect lasts until chapter/skirmish ends |
| Effect | Max HP +5 and all other non-MOV stats +2 until the chapter/skirmish ends. |
| Formula | `TemporaryMaxHP += 5; TemporarySTR/MAG/SKL/SPD/LCK/DEF/RES += 2` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Special/event-style consumable; sells for one-quarter of listed worth.


---

# Permanent Boosters

## Seraph Robe

| Property | Value |
|---|---|
| Category | Permanent Stat Booster |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use |
| Effect | Permanently raises Max HP by 5. |
| Formula | `PermanentMaxHP = min(PermanentMaxHP + 5, FinalHPCap)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Subject to stat cap enforcement.

## Energy Drop

| Property | Value |
|---|---|
| Category | Permanent Stat Booster |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use |
| Effect | Permanently raises STR by 2. |
| Formula | `PermanentSTR = min(PermanentSTR + 2, FinalSTRCap)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Subject to stat cap enforcement.

## Spirit Dust

| Property | Value |
|---|---|
| Category | Permanent Stat Booster |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use |
| Effect | Permanently raises MAG by 2. |
| Formula | `PermanentMAG = min(PermanentMAG + 2, FinalMAGCap)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Subject to stat cap enforcement.

## Secret Book

| Property | Value |
|---|---|
| Category | Permanent Stat Booster |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use |
| Effect | Permanently raises SKL by 2. |
| Formula | `PermanentSKL = min(PermanentSKL + 2, FinalSKLCap)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Subject to stat cap enforcement.

## Speedwing

| Property | Value |
|---|---|
| Category | Permanent Stat Booster |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use |
| Effect | Permanently raises SPD by 2. |
| Formula | `PermanentSPD = min(PermanentSPD + 2, FinalSPDCap)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Subject to stat cap enforcement.

## Goddess Icon

| Property | Value |
|---|---|
| Category | Permanent Stat Booster |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use |
| Effect | Permanently raises LCK by 2. |
| Formula | `PermanentLCK = min(PermanentLCK + 2, FinalLCKCap)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Subject to stat cap enforcement.

## Dracoshield

| Property | Value |
|---|---|
| Category | Permanent Stat Booster |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use |
| Effect | Permanently raises DEF by 2. |
| Formula | `PermanentDEF = min(PermanentDEF + 2, FinalDEFCap)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Subject to stat cap enforcement.

## Talisman

| Property | Value |
|---|---|
| Category | Permanent Stat Booster |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use |
| Effect | Permanently raises RES by 2. |
| Formula | `PermanentRES = min(PermanentRES + 2, FinalRESCap)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Subject to stat cap enforcement.

## Naga's Tear

| Property | Value |
|---|---|
| Category | Permanent Stat Booster / Multi-Stat |
| Uses | 1 |
| Worth | 5000 |
| Sell | 2500 |
| Target | Self |
| Timing | Command item use |
| Effect | Permanently raises Max HP by 5 and STR/MAG/SKL/SPD/LCK/DEF/RES by 2. |
| Formula | `PermanentMaxHP += 5; PermanentSTR/MAG/SKL/SPD/LCK/DEF/RES += 2; enforce caps` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Subject to stat cap enforcement for every affected stat.

## Boots

| Property | Value |
|---|---|
| Category | Permanent Utility Booster |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use |
| Effect | Permanently raises MOV by 2. |
| Formula | `PermanentMOVBonus += 2` |
| Restrictions | Cannot be used on the same character more than once. |
| Availability | Base game |

### Mechanical Notes
- Movement increase is not a standard level-up stat gain. Track a per-character Boots-used flag.

## Arms Scroll

| Property | Value |
|---|---|
| Category | Permanent Weapon-Rank Booster |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use |
| Effect | Raises all displayed weapon ranks available to the user's current class by one rank tier. |
| Formula | `For each active weapon type: WEXP = max(WEXP, NextRankThreshold(CurrentRank))` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Fire Emblem Wiki describes the effect as raising weapon levels in all weapon types available to the current class by one tier.
- Does not grant ranks for weapon types the current class cannot use.


---

# Seals and Class-Change Items

## Master Seal

| Property | Value |
|---|---|
| Category | Class Change / Promotion |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use outside or during class-change context |
| Effect | Promotes an eligible level 10+ base-class unit to a promoted class. |
| Formula | `If UnitTier == Base and DisplayedLevel >= 10 and PromotionTarget exists: ChangeClass(PromotedClass)` |
| Restrictions | Base-class units only; requires legal promotion target; special classes and already promoted units do not use Master Seal for standard promotion. |
| Availability | Base game |

## Second Seal

| Property | Value |
|---|---|
| Category | Class Change / Reclass |
| Uses | 1 |
| Worth | 2500 |
| Sell | 1250 |
| Target | Self |
| Timing | Command item use outside or during class-change context |
| Effect | Reclasses an eligible unit to another legal class. |
| Formula | `If eligibility passes: ChangeClass(TargetClass); apply Second Seal level/reclass rules` |
| Restrictions | Target class must be legal for the unit; eligibility depends on current level and class-tier status. |
| Availability | Base game |

## Dread Scroll

| Property | Value |
|---|---|
| Category | DLC Class Change |
| Uses | 1 |
| Worth | 0 |
| Sell | 0 |
| Target | Self |
| Timing | Command item use outside or during class-change context |
| Effect | Changes an eligible male unit to Dread Fighter. |
| Formula | `If UnitGender == Male and eligibility passes: ChangeClass(DreadFighter)` |
| Restrictions | DLC only. Male units only. Requires level 10+ base or any promoted-class level. |
| Availability | DLC |

## Wedding Bouquet

| Property | Value |
|---|---|
| Category | DLC Class Change |
| Uses | 1 |
| Worth | 0 |
| Sell | 0 |
| Target | Self |
| Timing | Command item use outside or during class-change context |
| Effect | Changes an eligible female unit to Bride. |
| Formula | `If UnitGender == Female and eligibility passes: ChangeClass(Bride)` |
| Restrictions | DLC only. Female units only. Requires level 10+ base or any promoted-class level. |
| Availability | DLC |


---

# Valuables

## Bullion (S)

| Property | Value |
|---|---|
| Category | Valuable |
| Uses | 0 |
| Worth | 2000 |
| Sell | 1000 |
| Target | N/A |
| Timing | Inventory/shop sale |
| Effect | Sells for 1,000G. |
| Formula | `Gold += 1000` |
| Restrictions | Cannot be used as a command item. |
| Availability | Base game |

## Bullion (M)

| Property | Value |
|---|---|
| Category | Valuable |
| Uses | 0 |
| Worth | 10000 |
| Sell | 5000 |
| Target | N/A |
| Timing | Inventory/shop sale |
| Effect | Sells for 5,000G. |
| Formula | `Gold += 5000` |
| Restrictions | Cannot be used as a command item. |
| Availability | Base game |

## Bullion (L)

| Property | Value |
|---|---|
| Category | Valuable |
| Uses | 0 |
| Worth | 20000 |
| Sell | 10000 |
| Target | N/A |
| Timing | Inventory/shop sale |
| Effect | Sells for 10,000G. |
| Formula | `Gold += 10000` |
| Restrictions | Cannot be used as a command item. |
| Availability | Base game |

## Supreme Emblem

| Property | Value |
|---|---|
| Category | Valuable / Renown Reward |
| Uses | 1 |
| Worth | N/A |
| Sell | 99999 |
| Target | N/A |
| Timing | Inventory/shop sale |
| Effect | Reward for maximum Renown; sells for 99,999G. |
| Formula | `Gold += 99999` |
| Restrictions | No normal command-use effect. |
| Availability | Base game |

### Mechanical Notes
- Worth field is represented as N/A because source tables list no ordinary worth but define sell value.


---

# Utility Items

## Seed of Trust

| Property | Value |
|---|---|
| Category | Support Utility / Event Consumable |
| Uses | 1 |
| Worth | 1000 |
| Sell | 250 |
| Target | Paired partner |
| Timing | Command item use while paired up |
| Effect | Slightly boosts support relationship between user and current paired partner. |
| Formula | `SupportPoints[user, partner] += SeedOfTrustSupportValue` |
| Restrictions | Can only be used while paired up with a unit capable of supporting the user. |
| Availability | Base game |

### Mechanical Notes
- Exact support-point value should be represented as a support-system constant if discovered from internal data.
- Special/event-style item; sells for one-quarter of listed worth.

## Door Key

| Property | Value |
|---|---|
| Category | Map Utility / Key |
| Uses | 1 |
| Worth | 300 |
| Sell | 150 |
| Target | Door |
| Timing | Map interaction |
| Effect | Opens one locked door. |
| Formula | `OpenDoor(TargetDoor); consume item` |
| Restrictions | None |
| Availability | Base game |

## Chest Key

| Property | Value |
|---|---|
| Category | Map Utility / Key |
| Uses | 1 |
| Worth | 300 |
| Sell | 150 |
| Target | Chest |
| Timing | Map interaction |
| Effect | Opens one chest. |
| Formula | `OpenChest(TargetChest); consume item` |
| Restrictions | None |
| Availability | Base game |

## Master Key

| Property | Value |
|---|---|
| Category | Map Utility / Key |
| Uses | 1 |
| Worth | 500 |
| Sell | 250 |
| Target | Door or chest |
| Timing | Map interaction |
| Effect | Opens one locked door or one chest. |
| Formula | `OpenDoorOrChest(TargetObject); consume item` |
| Restrictions | None |
| Availability | Base game |

## Reeking Box

| Property | Value |
|---|---|
| Category | World Map Utility |
| Uses | 1 |
| Worth | 500 |
| Sell | 125 |
| Target | Current world-map location |
| Timing | World-map item use |
| Effect | Summons Risen soldiers onto the player's current location. |
| Formula | `SpawnRisen(CurrentLocation)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Serenes Forest notes cost is 500G normally and 4,800G on Hard mode and above.
- Sells for one-quarter of listed worth.

## Rift Door

| Property | Value |
|---|---|
| Category | World Map Utility |
| Uses | 1 |
| Worth | 1000 |
| Sell | 250 |
| Target | Current world-map location |
| Timing | World-map item use |
| Effect | Summons a merchant onto the player's current location. |
| Formula | `SpawnMerchant(CurrentLocation)` |
| Restrictions | None |
| Availability | Base game |

### Mechanical Notes
- Sells for one-quarter of listed worth.

## Silver Card

| Property | Value |
|---|---|
| Category | DLC Shop Utility |
| Uses | 1 |
| Worth | 0 |
| Sell | 0 |
| Target | Global shop pricing |
| Timing | Passive inventory/key-item effect |
| Effect | Allows the user/player to purchase items for half price. |
| Formula | `ShopPrice = floor(BaseShopPrice / 2)` |
| Restrictions | DLC only. |
| Availability | DLC |

### Mechanical Notes
- Fire Emblem Wiki describes the effect as dropping shop prices by half for all units; Serenes Forest phrases it as the user can purchase items for half price. Implement as a player/shop-pricing flag unless reproducing unit-specific behavior.

## Outrealm Item

| Property | Value |
|---|---|
| Category | DLC Placeholder |
| Uses | 1 |
| Worth | 0 |
| Sell | 0 |
| Target | N/A |
| Timing | Placeholder display state |
| Effect | Displayed when a DLC-exclusive item is viewed without required DLC installed/resolved. |
| Formula | `ResolvedItem = LookupDLCItem() else Placeholder` |
| Restrictions | DLC placeholder; no independent normal-use effect. |
| Availability | DLC Placeholder |

### Mechanical Notes
- Implement as a proxy/placeholder, not as an ordinary consumable effect.


---

# DLC Skill Items

## All Stats +2

| Property | Value |
|---|---|
| Category | DLC Skill Item |
| Uses | 1 |
| Worth | 0 |
| Sell | 0 |
| Target | Self |
| Timing | Command item use |
| Effect | Teaches the All Stats +2 skill to one unit. |
| Formula | `KnownSkills += All Stats +2` |
| Restrictions | DLC only. Unit must be able to learn/hold skill items under normal rules. |
| Availability | DLC |

## Paragon

| Property | Value |
|---|---|
| Category | DLC Skill Item |
| Uses | 1 |
| Worth | 0 |
| Sell | 0 |
| Target | Self |
| Timing | Command item use |
| Effect | Teaches the Paragon skill to one unit. |
| Formula | `KnownSkills += Paragon` |
| Restrictions | DLC only. Unit must be able to learn/hold skill items under normal rules. |
| Availability | DLC |

## Iote's Shield

| Property | Value |
|---|---|
| Category | DLC Skill Item |
| Uses | 1 |
| Worth | 0 |
| Sell | 0 |
| Target | Self |
| Timing | Command item use |
| Effect | Teaches the Iote's Shield skill to one unit. |
| Formula | `KnownSkills += Iote's Shield` |
| Restrictions | DLC only. Unit must be able to learn/hold skill items under normal rules. |
| Availability | DLC |

## Limit Breaker

| Property | Value |
|---|---|
| Category | DLC Skill Item |
| Uses | 1 |
| Worth | 0 |
| Sell | 0 |
| Target | Self |
| Timing | Command item use |
| Effect | Teaches the Limit Breaker skill to one unit. |
| Formula | `KnownSkills += Limit Breaker` |
| Restrictions | DLC only. Unit must be able to learn/hold skill items under normal rules. |
| Availability | DLC |


---

# Item Count Audit

| Category Section | Entries |
|---|---:|
| Healing Items | 4 |
| Consumables and Temporary Buffs | 12 |
| Permanent Boosters | 11 |
| Seals and Class-Change Items | 4 |
| Valuables | 4 |
| Utility Items | 8 |
| DLC Skill Items | 4 |
| Total Unique Item Entries | 47 |

## Machine-Readable Category Map

| Item | Category | Availability |
|---|---|---|

| Vulnerary | Healing | Base game |

| Concoction | Healing | Base game |

| Elixir | Healing | Base game |

| Sweet Tincture | Healing / Event Consumable | Base game |

| Pure Water | Temporary Stat Buff | Base game |

| HP Tonic | Temporary Stat Buff / Tonic | Base game |

| Strength Tonic | Temporary Stat Buff / Tonic | Base game |

| Magic Tonic | Temporary Stat Buff / Tonic | Base game |

| Skill Tonic | Temporary Stat Buff / Tonic | Base game |

| Speed Tonic | Temporary Stat Buff / Tonic | Base game |

| Luck Tonic | Temporary Stat Buff / Tonic | Base game |

| Defense Tonic | Temporary Stat Buff / Tonic | Base game |

| Resistance Tonic | Temporary Stat Buff / Tonic | Base game |

| Kris's Confect | Temporary Stat Buff / Event Consumable | Base game |

| Gaius's Confect | Temporary Stat Buff / Event Consumable | Base game |

| Tiki's Tear | Temporary Stat Buff / Event Consumable | Base game |

| Seraph Robe | Permanent Stat Booster | Base game |

| Energy Drop | Permanent Stat Booster | Base game |

| Spirit Dust | Permanent Stat Booster | Base game |

| Secret Book | Permanent Stat Booster | Base game |

| Speedwing | Permanent Stat Booster | Base game |

| Goddess Icon | Permanent Stat Booster | Base game |

| Dracoshield | Permanent Stat Booster | Base game |

| Talisman | Permanent Stat Booster | Base game |

| Naga's Tear | Permanent Stat Booster / Multi-Stat | Base game |

| Boots | Permanent Utility Booster | Base game |

| Arms Scroll | Permanent Weapon-Rank Booster | Base game |

| Seed of Trust | Support Utility / Event Consumable | Base game |

| Master Seal | Class Change / Promotion | Base game |

| Second Seal | Class Change / Reclass | Base game |

| Dread Scroll | DLC Class Change | DLC |

| Wedding Bouquet | DLC Class Change | DLC |

| Bullion (S) | Valuable | Base game |

| Bullion (M) | Valuable | Base game |

| Bullion (L) | Valuable | Base game |

| Supreme Emblem | Valuable / Renown Reward | Base game |

| Door Key | Map Utility / Key | Base game |

| Chest Key | Map Utility / Key | Base game |

| Master Key | Map Utility / Key | Base game |

| Reeking Box | World Map Utility | Base game |

| Rift Door | World Map Utility | Base game |

| Silver Card | DLC Shop Utility | DLC |

| Outrealm Item | DLC Placeholder | DLC Placeholder |

| All Stats +2 | DLC Skill Item | DLC |

| Paragon | DLC Skill Item | DLC |

| Iote's Shield | DLC Skill Item | DLC |

| Limit Breaker | DLC Skill Item | DLC |


---

# End of Phase 9 — Item Encyclopedia
