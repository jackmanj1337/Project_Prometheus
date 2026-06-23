---
Type: register
Status: OPEN
Last verified: 2026-06-23
Register: IEQ-1..9
---

# Items & Equipment Unified Model — Player-Facing Design + Open Questions

**Started:** 2026-06-23
**Status:** Planning draft — register OPEN. Pairs with the design doc
`design/items_equipment_unified_model_2026-06-23.md` (the map); this register holds the
decisions to walk. **Supersedes `[EQP-1..5]`** (its 5 piecemeal questions are absorbed and
generalized below).
**Owner framing already set (2026-06-23):** support **both** held-benefit and
equipped-benefit accessories (IEQ-1); gate with **both** a parallel proficiency rank track
**and** per-item flags (IEQ-3); allow benefits to **differ/expand** by flag or experience
level (IEQ-4). The OPEN questions below are the remaining *how-in-data* forks.
**Pattern:** mirrors §1 ICD / §2 CST / `[EQP]`. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today
Code-grounded audit lives in the design doc Part 1 (not duplicated). Summary: weapons +
WEXP healthy; equipment half-built (passive 4-field bonus, model split across `ItemData`
vs `InventoryEntry`, orphaned `until_unequipped`, stale comments, named items exceed 4
fields, GDD_04 status mismatch).

## 2. What this pass produces
The unified accessory data model (conferral, slots, legality, scaling, stat/effect model),
the data-model unification + save-schema reservation, and the code-debt cleanup that lands
with the build.

## 3. Open questions register

### [IEQ-1] Conferral declaration — how an item picks held vs equipped  **[OPEN]**
Owner: support both. Open: the data shape.
- **A — `conferral` enum field** on the accessory (`held | equipped | both`); `both` =
  held baseline + an expanded equipped tier (ties to IEQ-4). Default `equipped`.
- **B — Two separate modifier lists** (`held_modifiers` / `equipped_modifiers`); presence
  of each implies the mode. More flexible, more fields.
- **Rec: A** — one explicit enum is readable, authorable, and validates cleanly; `both`
  covers the "stronger when equipped" case via the IEQ-4 tier table. **Resolution:** _[OPEN]_

### [IEQ-2] Equip slots — count & exclusivity (equipped-benefit items)  **[OPEN]**
- **A — Single accessory slot** v1 (one equipped accessory per unit); rule-driven N later.
- **B — N slots now** (`max_accessory_slots`, author/rule).
- **Rec: A** — one slot gives exclusivity + balance for v1; `N` is later data growth (same
  pattern as convoy `max_inventory`). Held-benefit items are not slot-bound (own cap → IEQ-1).
- **Resolution:** _[OPEN]_

### [IEQ-3] Legality model — proficiency track + flags (combined)  **[OPEN]**
Owner: combine both. Open: the track's shape and flag composition.
- **A — Reuse the WEXP machinery generalized.** Accessories declare a `wexp_track`-style
  proficiency track + `required_rank`; unit totals live in a new `UnitData.item_wexp`
  (parallel to `weapon_wexp`); legality = `item_rank >= required` **AND** all per-item flags
  pass. Flags = predicate list (`class_group | unit_tag | min_level | named_proficiency`).
- **B — Separate bespoke item-proficiency system** (not WEXP-derived).
- **Rec: A** — reusing `minimum_wexp_for_rank` + the `_can_equip_rank` pattern keeps one
  rank vocabulary across weapons and items; flags are an extra AND-predicate. (Defer the
  gain *source* for item-WEXP — see IEQ-4/Notes; v1 may grant by class/level not by use.)
- **Resolution:** _[OPEN]_

### [IEQ-4] Benefit scaling / tiering — by flag and/or proficiency level  **[OPEN]**
Owner: support differ/expand by flag or experience.
- **A — Tier table** keyed by item-rank (and/or flag match) → a modifier-set + effect-hook
  list. The held baseline is tier 0; equipped/high-rank tiers expand it. Author-friendly.
- **B — Formula-scaled** single modifier set (delta * f(rank)). Compact but only scales
  magnitude, can't *add* an effect.
- **Rec: A** — a tier table can both grow magnitude AND add effects (what "expand" needs);
  reuses the IEQ-5 modifier/hook shape per tier. **Resolution:** _[OPEN]_

### [IEQ-5] Grantable stat/effect model — beyond the 4 combat fields  **[OPEN]**
- **A — General modifier list + effect hooks.** `active_modifiers` (stat→delta, any stat)
  applied `until_unequipped`, plus optional hooks (movement-type, skill grant, crit-immunity)
  for the named items. The 4 flat `accuracy/damage/crit/dodge` fields migrate in as a subset.
- **B — Keep 4 combat fields for v1;** defer stat/skill/movement grants.
- **Rec: A** — the planned named items (Knight Ring move, Iron Rune immunity, Laguz Guard)
  require it; reuses `add_modifier`/`active_modifiers`; gives IEQ-6 its producer.
- **Resolution:** _[OPEN]_

### [IEQ-6] `until_unequipped` wiring — give the orphaned label a producer  **[OPEN]**
- **A — Wire it up.** Equipping (and held-benefit application) produces real
  `until_unequipped` `active_modifiers`, removed on unequip/drop, so bonuses show on the
  character sheet (in + out of combat). Supersedes combat-time-only application.
- **B — Remove the orphaned label;** keep combat-time-only (bonus invisible on sheet).
- **Rec: A** — removes the "no producer" debt + makes bonuses sheet-visible; the granted
  modifiers from IEQ-5 *are* the `until_unequipped` ones. **Resolution:** _[OPEN]_

### [IEQ-7] Data-model unification — where an accessory is defined  **[OPEN]**
Resolves finding #1 (the `ItemData.item_type=="equip"` vs `InventoryEntry` inline-fields split).
- **A — Accessory is `ItemData`-backed.** Extend `ItemData` (or a sibling block) to carry
  the conferral/legality/tier/modifier model; `InventoryEntry` (`entry_type=="equip"`)
  becomes a thin **reference by `item_id`** + an equipped-state pointer; retire the inline
  4 fields (migrate to the modifier model). One definition source, like weapons.
- **B — New `AccessoryData` resource** (parallel to `WeaponData`/`ItemData`);
  `InventoryEntry` references it. Cleanest separation, most new code.
- **Rec: A** — accessories already nominally live under `ItemData.item_type=="equip"`;
  consolidating there (not a third resource) matches the "inventory entry references a data
  resource by id" pattern weapons/items already use, and kills the inline-field split.
- **Resolution:** _[OPEN]_

### [IEQ-8] Save / schema impact (§2 reservation)  **[OPEN]**
- Equipped-accessory state = a per-unit **equipped pointer** (which slot holds which entry);
  item-proficiency = a new `UnitData.item_wexp` dict (parallel to `weapon_wexp`). Both are
  small per-save additions — **reserve room in the §2 save schema** now, fill on build.
- **Rec:** reserve both fields in the save-cluster schema; serialize like `weapon_wexp` +
  inventory order (already serialized). **Resolution:** _[OPEN]_

### [IEQ-9] Code-debt cleanup + GDD reconciliation (lands with the build)  **[OPEN]**
- Fix `InventoryEntry.gd:21` header (separate accessories from forging; `forged_mods` stays
  forging/deferred — line-11 comment is accurate, leave it); status-fix GDD_04 finding #6
  (equip is half-built, not "Planned"); update GDD_01 schema + GDD_04 rules + flip
  `GDD_10_Roadmap` (DoD#1) **same commit**; add `test_equip_items.gd` (DoD#2).
- **Rec: A — reconcile in the same change as the build;** no standalone doc-only churn.
- **Resolution:** _[OPEN]_

## 4. Notes
- **Forging (M10) stays deferred and distinct** — this register only disentangles the
  comments (finding #4), never absorbs forging. `forged_mods` is forging's.
- **Item-WEXP gain source** is deliberately deferred inside IEQ-3: v1 may grant item rank by
  class/level rather than by use (no obvious "use" event for a passive accessory). Revisit
  when the tier table (IEQ-4) needs a progression driver.
- **Reconcile-don't-relitigate:** weapon triangle/WEXP (GDD_04), `break_behavior` (`[BWN]`),
  convoy `Array[InventoryEntry]` (`[CNV]`), resource-keyed `cost` (`[SHP-1]`).
- **DoD:** GDD chapter + `GDD_Feature_Index` row + roadmap flip land **with the build**, not now.
