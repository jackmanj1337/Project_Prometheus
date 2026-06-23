---
Type: register
Status: RESOLVED 2026-06-23
Last verified: 2026-06-23
Register: IEQ-1..9
Resolved-in: 2026-06-23l
---

# Items & Equipment Unified Model — Player-Facing Design + Open Questions

**Started:** 2026-06-23
**Status:** RESOLVED 2026-06-23l. Pairs with the design doc
`design/items_equipment_unified_model_2026-06-23.md` (the map); this register is the
decision-of-record. **Supersedes `[EQP-1..5]`** (absorbed + generalized).
**Owner framing (2026-06-23):** support **both** held + equipped conferral; gate with a
parallel item-proficiency track **+** per-item flags; benefits **differ/expand** by
flag/experience. Walked in dependency order, re-evaluating after the keystone (`[IEQ-7]`).
**Pattern:** mirrors §1 ICD / §2 CST / `[EQP]`. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today
Code-grounded audit lives in the design doc Part 1 (not duplicated). Summary: weapons +
WEXP healthy; equipment half-built + model-split (passive 4-field `InventoryEntry` bonus
disconnected from `ItemData`, orphaned `until_unequipped`, stale comments, named items
exceed 4 fields, GDD_04 status mismatch).

## 2. What this pass produced
The unified **composition** item-definition model, per-component legality, the typed
accessory-slot system, benefit tiering, the stat/effect model + `until_unequipped` wiring,
the save-schema reservation, and the code-debt cleanup scope.

---

## 3. Resolved decisions

### [IEQ-7] Unified item-definition shape — **RESOLVED: base + optional components (composition)**
One **`ItemDef` base** resource holds genuinely-shared fields (`id`, `display_name`,
`description`, `cost`, `sellable`); it carries **optional component sub-resources**:
`weapon_component` (`WeaponComponent`), `consumable_component` (`ConsumableComponent`),
`accessory_component` (`AccessoryComponent`). Presence of a component = the item *has* that
capability; **an item may hold more than one at once** (multi-component, see below).
- **`InventoryEntry` stays the thin per-slot instance** — references the definition by
  `def_id`, holds runtime state only (`uses_remaining`, equipped pointer(s), `forged_mods`).
- Migrates: `WeaponData` → `weapon_component` (fields unchanged); `ItemData`
  (healing/stat/promotion effects) → `consumable_component`; the inline
  `accuracy/damage/crit/dodge` on `InventoryEntry` retire into the `accessory_component`
  modifier model (IEQ-5).
- **Cleanup wins:** the overloaded `ItemData.item_type` enum dissolves — `sellable` + `cost`
  are base fields; a "key" is an item with no functional component. `uses` lives on the
  components that have durability (weapon/consumable); accessories have none.
- **DataManager:** one definition registry + one getter (`get_item_def(id)`), replacing the
  split `_weapons`/`_items` + `get_weapon`/`get_item`. (Staged migration — see Notes.)

### [IEQ-3] Legality — **RESOLVED: per-component, independent**
Each component carries its own gate, checked **only for the capability being exercised**:
- **`weapon_component`** → existing weapon-WEXP track + `required_rank` + class weapon-family
  allowance (`Unit._can_equip_rank`, **unchanged/healthy**).
- **`accessory_component`** → new **item-proficiency** legality = a parallel rank track
  (`UnitData.item_wexp`, mirroring `weapon_wexp`; reuses `GameConstants.minimum_wexp_for_rank`)
  **AND** a per-item **flag predicate list** (`req_flags`: `class_group | unit_tag |
  min_level | named_proficiency`). Item-WEXP **gain source deferred** — v1 grants item-rank by
  class/level, not by use (no natural "use" event for a passive accessory).
- A unit may wield the weapon side without qualifying for the accessory side, and vice versa.

### Multi-component policy — **RESOLVED: ships in v1**
Capabilities are **independent and concurrent**. One item can grant several:
- weapon_component → usable as a weapon when it is the equipped weapon (inventory-front) AND weapon-legal.
- accessory_component **held** → bonus applies whenever the item is in inventory AND accessory-legal.
- accessory_component **equipped** → bonus applies when it occupies an accessory slot AND accessory-legal.
- consumable_component → usable via the Item action when consumable-legal.
- **Dual weapon+equipped-accessory item:** **weapon-equipped counts as equipped** — if the
  item is the equipped weapon, its equipped-accessory bonus is active too, consuming **no**
  separate accessory slot. One physical item, both capabilities live when wielded.

### [IEQ-2] Accessory slots — **RESOLVED: typed slots + per-type capacity**
- **`accessory_component.slot_type: String`** (e.g. `helmet`, `ring`, `cloak`; author-extensible).
- A unit has a **per-type capacity map** (e.g. `{helmet: 1, ring: 2}` → "one helmet, two
  rings, not two helmets"). Equipping consumes a slot of the item's type; can't exceed capacity.
- **Capacity ownership:** **campaign base default** (`CampaignRules`/`GameConstants` slot map)
  → **`ClassData` override** that can **add or remove** slot types/counts → **per-unit slot
  modifiers DEFERRED** (later growth). Matches the ClassData-authors-families/caps pattern.

### [IEQ-1] Conferral declaration — **RESOLVED: `conferral` enum**
`accessory_component.conferral: held | equipped | both`. `both` = a held baseline plus an
expanded equipped tier (via the IEQ-4 tier table). Held-benefit items are **not** slot-bound;
equipped-benefit items occupy a typed slot (IEQ-2).

### [IEQ-4] Benefit scaling/tiering — **RESOLVED: tier table**
`accessory_component.tiers` = a list keyed by item-rank (and/or flag match) → a modifier-set +
effect-hook list (IEQ-5 shape per tier). Held baseline = tier 0; equipped/high-rank tiers
**expand** it (grow magnitude AND/OR add effects). Satisfies "differ/expand by flag/experience".

### [IEQ-5] Grantable stat/effect model — **RESOLVED: general modifiers + effect hooks**
Per tier: `modifiers` (stat → delta, **any** stat incl. STR/DEF/MOV) applied at
`until_unequipped` duration, plus optional `effect_hooks` (movement-type change, skill grant,
crit-immunity) for the named items (Knight Ring move, Iron Rune immunity, Laguz/Wing Guard).
Reuses `Unit.add_modifier` / `active_modifiers`. The legacy 4 flat combat fields migrate in as
a convenience subset.

### [IEQ-6] `until_unequipped` wiring — **RESOLVED: wire it up**
Equipping (and held-benefit application) produces real `until_unequipped` `active_modifiers`,
removed on unequip/drop → bonuses show on the character sheet **in + out of combat**, giving
the orphaned `GameConstants`/`StatBreakdown` label its producer. Supersedes combat-time-only
application in `CombatResolver._apply_equip_item_modifiers()`.

### [IEQ-8] Save / schema reservation — **RESOLVED: reserve in §2 now**
Reserve in the save-cluster schema: `InventoryEntry.def_id`; **per-slot-type equipped
pointers** per unit; `UnitData.item_wexp` (parallel to `weapon_wexp`); the resolved
**slot-capacity map** (base + class override). Serialize like `weapon_wexp` + inventory order
(already serialized). Fill on build.

### [IEQ-9] Code-debt + GDD reconciliation — **RESOLVED: lands with the build (DoD#1+#2)**
- Fix `InventoryEntry.gd:21` header (separate accessories from forging; `forged_mods` stays
  forging/deferred — line-11 comment is accurate, leave it); status-fix GDD_04 finding #6.
- Update GDD_01 (schemas → `ItemDef` + components) + GDD_04 (items/equip/proficiency) + flip
  `GDD_10_Roadmap`, **same commit**; add `test_equip_items.gd` + composition migration tests.

## 4. Notes
- **Staged migration (NOT a single drop):** define the `ItemDef`/component model, then migrate
  weapons → consumables → accessories in phases so healthy combat code (~15 weapon + ~11 item
  call sites, 11+8 `.tres`, DataManager validators, manifests, tests) isn't rewritten at once.
- **Forging (M10) stays deferred + distinct** — `forged_mods` (instance) overlays the
  `weapon_component` (definition); this review only disentangles the comments, never absorbs forging.
- **Item-WEXP gain source** deferred inside IEQ-3 — revisit when the tier table needs a
  progression driver.
- **Reconcile-don't-relitigate:** weapon triangle/WEXP (GDD_04), `break_behavior` (`[BWN]`),
  convoy `Array[InventoryEntry]` (`[CNV]`), resource-keyed `cost` (`[SHP-1]`). The `ItemDef.cost`
  base field is the seam to the economy spine.
- **DoD:** GDD chapter + `GDD_Feature_Index` row + roadmap flip land **with the build**, not now.
