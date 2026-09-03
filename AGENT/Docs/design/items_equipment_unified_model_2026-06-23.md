---
Role: dated
Type: design
Status: Target design — firmed, awaiting staged build
Last verified: 2026-06-23
---

# Items & Equipment — Unified Data-Model Review (ground-up)

**Started:** 2026-06-23
**Status:** Target design — ground-up review of the whole item/equipment/proficiency stack;
the model is **firmed** (register `[IEQ-1..9]` RESOLVED 2026-06-23l) and awaits a **staged
build**. The weapon + WEXP halves are **Implemented** and re-derived here to confirm; the
equipment half was **half-built** and this doc now defines the **decided** unified
(composition) model. Decisions-of-record live in the paired register (`[IEQ-1..9]`,
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
   Knight Ring (move/secondary-movement), Wing Guard, Laguz Guard need stat/effect grants the 4 combat
   fields can't express (+STR/+MOV, movement-type, immunity).
6. **GDD_04 status mismatch** — its "Items & Economy" section lists equip items as
   "Planned (Phase 2)", but a half-built passive mechanic already exists in code.

---

## 2. The decided unified model (firmed 2026-06-23l)

Re-derived ground-up and firmed via `[IEQ-1..9]`. The keystone (`[IEQ-7]`) is **composition**;
everything else attaches to it. Full decisions-of-record → the register; this is the shape.

### 2a. Composition — one `ItemDef` base + optional components (`[IEQ-7]`)
A single **`ItemDef`** definition resource holds the genuinely-shared fields and carries
**optional component sub-resources**; **an item may hold more than one** (multi-component):

```
ItemDef (base, shared by id)
  id, display_name, description, cost, sellable
  story, no_sell, no_drop, no_trade          # [CEX-14] key/story-item flag + author locks
  weapon_component:     WeaponComponent     = null
  consumable_component: ConsumableComponent = null
  accessory_component:  AccessoryComponent  = null

InventoryEntry (thin per-slot INSTANCE)
  entry_type retired → def_id -> ItemDef
  uses_remaining, map_uses_remaining, equipped pointer(s), forged_mods   # runtime state only
```

**Per-map-use consumables (`[CEX-13]`, firmed 2026-06-24c).** `ConsumableComponent` gains
`uses_per_map: int` (-1 = not a per-map item). When set, the item is **pure-recharge**:
`InventoryEntry.uses_remaining` stays **-1** (never consumed) and a per-instance
**`map_uses_remaining`** counter (refilled to `uses_per_map` by `reset_map_state` at map start,
mirroring `skill_use_counters`) gates use. Player readout = a **distinct "N/max ⟳" badge** + a
"resets each map" tooltip (consumed items show `×N`). Future (out of v1): per-N-turns / charge-on-rest
recharge intervals.

- **Definition vs instance** stays a two-layer split: `ItemDef` (shared template) vs
  `InventoryEntry` (per-slot runtime). Only the **definition** layer consolidates.
- Migrates: `WeaponData` → `WeaponComponent` (fields unchanged); `ItemData` effects →
  `ConsumableComponent`; the inline `accuracy/damage/crit/dodge` retire into the
  `AccessoryComponent` modifier model (2d).
- **Cleanup wins:** the overloaded `ItemData.item_type` enum dissolves — `sellable`/`cost`
  are base fields, a "key" is an item with no functional component; `uses` lives only on
  durability-bearing components. `DataManager` gets one registry + `get_item_def(id)`.
- **Staged migration** (NOT one drop): define the model, then migrate weapons → consumables
  → accessories so healthy combat code (~15 weapon + ~11 item call sites, manifests, tests)
  isn't rewritten at once.

### 2b. Per-component, independent legality (`[IEQ-3]`)
Each component gates itself, checked only for the capability being used:
- **`WeaponComponent`** → weapon-family proficiency track + `required_rank` + class family
  (`Unit._can_equip_rank`, behavior preserved).
- **`AccessoryComponent`** → an **item-proficiency track** (group or item-bond) + a per-item
  `req_flags` predicate list (`class_group | unit_tag | min_level | named_proficiency`).
- **Ranks/tracks/gain are owned by the unified Proficiency / XP Framework** (`[PXP-1..8]`,
  `registers/proficiency_xp_framework_open_questions_2026-06-23.md`): one `proficiency_xp`
  store, campaign-rules named rank profiles, item-group + item-bond tracks, and the
  author-defined multi-source gain model. (This supersedes the earlier "parallel `item_wexp`,
  gain deferred" sketch — gain is now resolved there.)

### 2c. Multi-component (ships v1) — independent, concurrent capabilities
One item can be several things at once; each capability lives independently. The one
coupling rule: **a dual weapon + equipped-accessory item gets its accessory bonus free when
it is the equipped weapon** (weapon-equipped counts as equipped; no separate slot consumed).

### 2d. Conferral, typed slots, tiers, effects (`[IEQ-1/2/4/5/6]`)
- **Conferral** (`[IEQ-1]`): `AccessoryComponent.conferral = held | equipped | both`. Held =
  applies while carried; equipped = occupies a slot; `both` = held baseline + an expanded
  equipped tier.
- **Typed slots** (`[IEQ-2]`): `AccessoryComponent.slot_type` (`helmet`, `ring`, …,
  author-extensible) + a per-type **capacity map** (e.g. `{helmet:1, ring:2}`). Capacity =
  **campaign base default → `ClassData` override (add/remove)** → per-unit modifiers deferred.
- **Tiers** (`[IEQ-4]`): `AccessoryComponent.tiers`, keyed by item-rank and/or flag → a
  modifier-set + effect-hook list. Held baseline = tier 0; higher tiers grow magnitude
  and/or **add** effects.
- **Stat/effect model** (`[IEQ-5]`): per tier, `modifiers` (any stat → delta, incl.
  STR/DEF/MOV) + optional `effect_hooks` (movement-type, skill grant, crit-immunity) for the
  named items. Reuses `add_modifier`/`active_modifiers`; the 4 flat fields migrate in.
- **`until_unequipped` wiring** (`[IEQ-6]`): granted modifiers are real `until_unequipped`
  active modifiers (removed on unequip/drop) → bonuses visible on the character sheet in +
  out of combat, giving the orphaned label its producer.

### 2e. Save/schema reservation (`[IEQ-8]`)
Reserve in §2: `InventoryEntry.def_id`; per-slot-type equipped pointers; `UnitData.item_wexp`;
the slot-capacity map. Serialize like `weapon_wexp` + inventory order (already serialized).

---

## 2f. Effect & trigger coverage for the drafted items (build checklist)

The drafted accessories/items resolve onto the existing effect subsystems (modifiers + the
skill trigger/dispatch system + consumable effect_ids) with a **small, enumerated** set of
additions. **GDD_05's trigger discipline holds** — don't add a trigger if a wired trigger +
`context.flags.*` can express it; `on_combat_apply_modifiers` is **already wired**, so the
defensive effects need new **effect_ids**, not new triggers.

| Drafted item | Mechanism | Add (owner) | Exists? |
|---|---|---|---|
| Knight Ward (+2 DEF/RES) | stat modifiers | — (modifier model, IEQ-5) | ✅ |
| Full Guard | negate **all** effectiveness bonus | `negate_effectiveness` effect_id, params `{groups:"all"}`, trigger `on_combat_apply_modifiers` defender (GDD_05 + GDD_02) | ❌ new effect_id |
| Wing Guard | negate **flying** effectiveness | `negate_effectiveness` `{groups:["flying"]}` | ❌ (same effect_id) |
| Laguz Guard | negate **laguz** effectiveness | `negate_effectiveness` `{groups:["beast","dragon"]}` | ❌ (same effect_id) |
| Iron Rune | defender crit immunity | `negate_crit` effect_id, `on_combat_apply_modifiers` defender (GDD_05 + GDD_02) | ❌ new effect_id |
| Knight Ring | move-after-action (Secondary Movement) | accessory effect_id **grants a `secondary_movement` skill** — firmed 2026-06-24a (`[SMV]`, F10); was a mechanic gap | ❌ build pending (`[SMV]`) |
| Knight Ward (+30% SPD growth) | growth-**rate** bonus | growth-rate modifier (affects level-up rolls / `growth_rates`, **not** flat `active_modifiers`) | ❌ model gap |
| Arms Scroll | advance a proficiency rank | `advance_proficiency` consumable effect_id (shared with training halls, `[PXP-9]`) | ❌ new effect_id |
| Boots / Dracoshield / Energy Drop / Secret Book / Goddess Icon / Seraph Robe | **permanent** stat boost | `permanent_stat` consumable effect_id (mutates base stat; current `stat_buff` is **temporary** only) | ❌ new effect_id |

**Model gaps flagged for designers** (beyond "add an effect_id"):
1. **Secondary Movement / move-after-action** (Knight Ring) — **firmed 2026-06-24a as a granted
   skill** (`[SMV]`, F10): the accessory effect_id grants a `secondary_movement` skill, so the
   accessory just *grants* it (no longer an open model gap; build pending with `[SMV]`).
2. **Growth-rate modifiers** (Knight Ward's +30% SPD growth) are distinct from flat stat
   modifiers — they alter level-up rolls (`UnitData.growth_rates`/`growth_accumulators`), so
   the modifier model (IEQ-5) needs a second "growth" channel, or these stay weapon/consumable-only.

**Obvious gaps a future campaign designer will ask for** (none need a new trigger; each is an
effect_id on a wired trigger + `context.flags`, unless noted):
- **Status/condition immunity** (immune to poison/sleep/etc.) — `negate_condition` effect_id.
- **Weapon `effect_tags` still unbuilt** (GDD_04 known gaps): `poison`, `heal_on_hit`,
  `ignores_def`/`ignores_half_def`, `always_hits` — each = a `TAG_*` const + a `CombatResolver`
  check (GDD_02/GDD_04).
- **Movement-type grant/override** beyond Secondary Movement (e.g. "treated as flying over water") — reuses
  the movement-override stubs (`get_move_cost_override`, `can_pass_through_enemies`).
- **Conditional stat bonuses** ("+DEF while HP full", "+Hit vs fliers") — `on_combat_apply_modifiers`
  + `context.flags`, no new trigger.
- **Skill grant** while held/equipped, and **on-rank-crossing** skill grant — already covered
  (IEQ-5 effect grants + `[PXP-4]`).

Owners at build: skill effect_ids → GDD_05; consumable effect_ids → GDD_04 / `ItemHandler`;
combat hooks (effectiveness/crit) → GDD_02; Secondary Movement → `[SMV]` (M10). Land per DoD with each build phase.

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

## 4. Decisions-of-record → register `[IEQ-1..9]` (RESOLVED 2026-06-23l)

All nine questions plus the composition-driven additions (multi-component policy, typed
slots, slot-capacity ownership, dual-occupancy rule) are **resolved** in
`registers/items_equipment_model_open_questions_2026-06-23.md`. What remains is the **staged
build**, not further design: define `ItemDef` + components → migrate weapons → consumables →
accessories, reserving the §2 save fields and landing the code-debt cleanup with each phase.

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
