---
Type: design
Status: Active design vision — being firmed
Last verified: 2026-06-23
---

# Items & Equipment — Unified Data-Model Review (ground-up)

**Started:** 2026-06-23
**Status:** Active design vision — ground-up review of the whole item/equipment/proficiency
stack. The weapon + WEXP halves are **Implemented** and re-derived here to confirm; the
equipment half is **half-built** and this doc defines its **Target** unified model. Open
decisions are walked in the paired register (`[IEQ-1..9]`,
`registers/items_equipment_model_open_questions_2026-06-23.md`); this doc is the **map**.
**Source:** owner-requested first-principles review (Session Note 2026-06-23k → Next session);
scope map `player_facing_scope_map_2026-06-23.md` §3b #3. **Supersedes** the piecemeal
`[EQP-1..5]` equip register (its code-audit is folded into Part 1 below).
**Schema owner:** GDD_01 (resources); **rules owner:** GDD_04 (weapons/items/WEXP);
**combat application:** GDD_02.

---

## 0. Why this review exists

The stack has **two healthy halves and one half-built one**. Weapons (`WeaponData`) and
weapon proficiency (WEXP/ranks) are coherent and match their "Implemented" GDD_04 claims.
**Equipment/accessories** are scaffolding only: a flat 4-field bonus applied passively, a
model split across two resources, an orphaned UI label, and stale comments. Rather than
firm equip piecemeal, this pass re-derives the whole stack so the equipment model is built
**consistent with** the weapon/proficiency model it sits beside.

---

## 1. State today (code-grounded — verified 2026-06-23)

### 1a. Weapons — `WeaponData.gd` (Implemented, healthy)
Richest model in the stack. Fields: `combat_family` (drives equip legality + triangle),
`wexp_track`, `required_rank` (E…S), `mt/hit/crit`, range-as-formula
(`range_min_formula`/`range_max_formula`, supports `"MAG/2"` dynamic range),
`wt/uses/cost/wexp`, `effect_tags: Array[String]`, `uses_mag`, `triangle_family` (hybrid
override), `strikes_per_attack` (Brave=2), `is_natural_weapon` (Laguz, deferred).
`is_healing_staff()` keys off `combat_family=="staff"` + `TAG_HEAL_PLUS_MAG`. **No debt.**

### 1b. Weapon proficiency / WEXP — `Unit.gd` (Implemented, healthy)
- `UnitData.weapon_wexp: Dictionary` holds per-track numeric totals; rank letters derive
  via `GameConstants.weapon_rank_for_wexp()`.
- **`Unit._can_equip_rank(weapon)` is the legality gate** (`Unit.gd:222`): a unit may
  equip a weapon iff **(1)** its `combat_family` is in the class's allowed families
  **AND (2)** `get_active_wexp(track) >= GameConstants.minimum_wexp_for_rank(required_rank)`.
- `get_active_wexp()` caps stored WEXP at the class cap; `add_wexp()` (`Unit.gd:1175`)
  gains on valid use, applies a `SkillHandler` multiplier, returns whether rank rose.
- Promotion/reclass raises a unit to at least the new class's WEXP baselines (`Unit.gd:797`).
- **This is the template the new item-proficiency gate generalizes from** (Part 2c). **No debt.**

### 1c. Items — `ItemData.gd` + `ItemHandler.gd` (Implemented, healthy)
- `ItemData`: `id`, `display_name`, `description`, `item_type`
  (`"healing"|"stat"|"promotion"|"equip"|"key"|"sellable"`), `uses` (−1 = infinite/equippable),
  `cost`, `effect_id`, `effect_params: Dictionary`.
- `ItemHandler.apply_item()` dispatches `effect_id` → `heal_flat | heal_full | promote |
  reclass | stat_buff`; `IMPLEMENTED_EFFECT_IDS` is cross-validated at startup.
- `stat_buff` already stamps an `active_modifier` via `unit.add_modifier(stat, delta,
  source, duration, duration_type)` — **the machinery the accessory model will reuse.** **No debt.**

### 1d. Equipment / accessories — half-built, model-split (THE DEBT)
- **`InventoryEntry`** (`entry_type=="equip"`) carries **four flat inline fields**
  `accuracy/damage/crit/dodge`. `forged_mods: Dictionary` is separate (forging/M10, no
  reader — genuinely deferred).
- **`CombatResolver._apply_equip_item_modifiers()` (`CombatResolver.gd:225`)** loops the
  inventory and, for **every** `is_equip()` entry, adds its 4 fields into the combat mod
  dict → **passive-while-held, no slot, no action, no exclusivity, combat-time only.**

**Six findings (the reconciliation surface):**
1. **Two disconnected "equip" representations.** `ItemData.item_type` has an `"equip"`
   value, but the actual mechanic lives entirely on `InventoryEntry`'s inline fields and
   **never touches `ItemData`**. An equip accessory is *not* an `ItemData`. There is no
   `make_equip()` factory (only `make_weapon`/`make_item`).
2. **"equip" is a misnomer** — nothing is equipped; bonuses are passive-while-held and
   stack without bound (5 held = 5 bonuses).
3. **`until_unequipped` is orphaned** — defined in `GameConstants`, rendered by
   `StatBreakdown` ("until unequipped"), **zero producers**. Equip bonuses never appear on
   the character sheet (combat-duration only).
4. **Stale/conflated comments** — `InventoryEntry.gd:21` headers the 4 equip fields as
   "equip type — M10 forging", conflating **accessories** with **forging**. (Note: the
   line-11 "no code reads this yet" comment is on `forged_mods` and is *accurate* — forging
   genuinely has no reader. The fix is the line-21 header, not line 11. The old `[EQP]`
   register mis-attributed this.)
5. **Named items exceed the 4-field model** — Full Guard, Iron Rune (crit-immunity),
   Knight Ring (move/canto), Wing Guard, Laguz Guard need stat/effect grants the 4 combat
   fields can't express (+STR/+MOV, movement-type, immunity).
6. **GDD_04 status mismatch** — its "Items & Economy" section lists equip items as
   "Planned (Phase 2)", but a half-built passive mechanic already exists in code.

---

## 2. Target unified model (owner-directed, 2026-06-23)

The owner's direction (the answers that shape this doc): support **both** held-benefit and
equipped-benefit accessories; gate them with **both** a parallel proficiency rank track
**and** per-item requirement flags; and allow an item's benefit to **differ or expand**
based on flags and/or experience level. Four axes:

### 2a. Conferral mode — held vs equipped (BOTH supported, per-item)
Each accessory declares **how its benefit is conferred**:
- **Held-benefit** — applies while simply carried in inventory (today's passive behavior,
  kept deliberately for some items, e.g. a passive ward).
- **Equipped-benefit** — applies only when equipped into an accessory slot (exclusivity,
  an equip action, sheet visibility).
- An item may, in principle, declare both a held baseline and an expanded equipped tier
  (ties into 2d scaling). → `[IEQ-1]`.

### 2b. Equip slots & exclusivity (for equipped-benefit items)
Equipped-benefit accessories occupy an **accessory slot**; equipping is an action (prep /
unit menu). Slot count + exclusivity → `[IEQ-2]` (rec: single accessory slot v1,
rule-driven N later). Held-benefit items are **not** slot-bound (only their own
held-stacking cap, if any).

### 2c. Legality gate — proficiency track **+** flags (COMBINED)
Generalize `_can_equip_rank()` beyond weapons. An accessory's legality is a **conjunction** of:
- **(i) a parallel proficiency rank track** — items/accessories gain their own
  WEXP-style tracks + ranks, mirroring `weapon_wexp`. A unit must meet the item's
  `required_rank` on its track to equip/hold-for-benefit it. Reuses the existing
  rank-threshold machinery (`GameConstants.minimum_wexp_for_rank`).
- **(ii) per-item requirement flags** — additional predicates an item declares
  (class group, unit tag, min level, named proficiency). Evaluated AND-wise with (i).
→ `[IEQ-3]`.

### 2d. Benefit scaling / tiering — by flag and/or proficiency level
An accessory's effect is **not fixed**: it can differ or expand based on its proficiency
**rank** and/or which **flags** the holder satisfies (e.g. a stronger bonus at higher item
rank, or an extra effect for a matching class). Modeled as a **tier table** keyed by
rank/flag → modifier-set. → `[IEQ-4]`.

### 2e. Grantable stat/effect model — beyond the 4 combat fields
An accessory grants a list of **general modifiers** (stat → delta, any stat incl.
STR/DEF/MOV) applied at `until_unequipped` duration, **plus** optional **effect hooks**
(movement-type change, skill grant, crit-immunity) for the named items. Reuses
`add_modifier`/`active_modifiers`. The 4 flat fields become a convenience subset or migrate
in. → `[IEQ-5]`. Wiring these as real `until_unequipped` modifiers gives the orphaned label
(finding #3) its producer and makes bonuses sheet-visible → `[IEQ-6]`.

### 2f. Data-model unification (the architectural fork)
Resolve finding #1: where does an accessory's definition live, and how does
`InventoryEntry` reference it? Options span "extend `ItemData`" vs "new `AccessoryData`
resource", with the inline 4 fields retired/migrated and `InventoryEntry.equip` reduced to
a reference + an equipped-state pointer. → `[IEQ-7]`. Save/schema impact (per-unit equipped
pointer; item-proficiency totals parallel to `weapon_wexp`) → `[IEQ-8]`.

---

## 3. Reconcile — don't relitigate

Firmed elsewhere; this review **builds on**, does not reopen:
- **Weapon triangle / families** — project Sword→Axe→Lance, Dark→Anima→Light; rank-scaled
  bonus is Target design (SET-003 / RULE-013, GDD_04). Don't touch here.
- **WEXP thresholds/caps/gain** — Implemented project values; corpus is Target (SET-004 /
  RULE-003/004, GDD_04). The item-proficiency track (2c) **mirrors** this, not replaces it.
- **Broken-weapon mode** — `break_behavior` (`[BWN-1..5]` RESOLVED). Out of scope.
- **Forging (M10)** — stays **deferred and distinct** from accessories. `forged_mods` is
  forging's; this review only **disentangles the comments** (finding #4), never absorbs forging.
- **Economy spine** — convoy = `Array[InventoryEntry]` shared store (`[CNV]`); resource-keyed
  buy/sell, gold-only v1 (`[SHP-1]`). Accessories live in inventory/convoy like any entry; the
  resource-keyed `cost` model is the seam where their price connects to the economy.

---

## 4. Open decisions → register `[IEQ-1..9]`

The owner has set the **framing** (both conferral modes; track+flags legality; scaling on).
The remaining forks — how each is declared in data, slot/exclusivity specifics, track design,
the data-model unification, save schema, and the code-debt cleanup — are walked in
`registers/items_equipment_model_open_questions_2026-06-23.md`.

## 5. Definition of done (when the build lands, not now)
- Affected GDD_01 (schemas) + GDD_04 (items/equip/proficiency) sections updated AND the
  matching `GDD_10_Roadmap` status flipped, **same commit** (DoD#1).
- Code-debt reconciled in the same change: fix `InventoryEntry.gd:21` header, disentangle
  accessories from forging, status-fix GDD_04 finding #6, add `test_equip_items.gd` (DoD#2).

## Anchors
- Code: `scripts/resources/{WeaponData,ItemData,InventoryEntry,UnitData}.gd`,
  `scripts/units/Unit.gd` (`_can_equip_rank`, `add_wexp`), `scripts/core/CombatResolver.gd`
  (`_apply_equip_item_modifiers`), `scripts/items/ItemHandler.gd`, `scripts/shared/GameConstants.gd`.
- Register: `registers/items_equipment_model_open_questions_2026-06-23.md` (`[IEQ-1..9]`).
- Supersedes: `registers/equip_items_open_questions_2026-06-23.md` (`[EQP-1..5]`).
- GDDs: GDD_01 (schemas), GDD_04 (weapons/items/WEXP/economy), GDD_02 (combat application),
  GDD_03 (class WEXP caps / vulnerability groups).
