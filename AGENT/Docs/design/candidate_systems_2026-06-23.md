---
Type: design
Status: Active exploration — initial designs, open questions pending
Last verified: 2026-06-23
---

# Candidate Systems — Initial Designs, Feasibility & Scope

**Started:** 2026-06-23 (session 2026-06-23l)
**Status:** Active exploration. Owner-requested initial designs + feasibility/scope research for
five candidate systems, with a **player-interaction question list** to walk later (register
`[CEX-1..N]`, `registers/candidate_systems_open_questions_2026-06-23.md`). **Not firmed** —
input to the pending priority re-evaluation. None of these is built or scheduled yet.
**Relation:** extends the firmed items/equipment composition model (`[IEQ]`), the
Proficiency/XP framework (`[PXP]`), and the CampaignRules author-profile pattern.

The throughline: each candidate **reuses existing machinery** rather than adding a parallel
engine. The questions to firm are mostly about **player interaction → designer authoring →
structural impact**, not feasibility.

---

## A. Shared resource pools  (stamina / mana / cast-from-HP)

**Concept.** Capabilities draw a per-use **cost** from a shared per-unit pool instead of (or
alongside) per-weapon `uses`. E.g. swords/axes spend **stamina**; spells spend **mana** or **HP**.

**Initial design.**
- New per-unit pools: `UnitData.resource_pools: Dictionary` (`{stamina: cur, mana: cur, …}`) +
  maxes; **HP is already a pool**, so "cast from health" reuses it.
- A component declares a cost: `{pool, amount}` on `weapon_component` / `consumable_component` /
  the spell capability — generalizing the `uses` field into a cost model.
- Use sites (CombatResolver attack, ItemHandler, staff) **deduct + gate** on sufficient pool.
- **Refill** rule in `CampaignRules` (per-map reset / per-turn regen / rest-at-hub / never).
- Pool **types** are author-defined in `CampaignRules` (like PXP profiles); class/unit sets maxes.

**Feasibility — Moderate.** No new engine; a per-use cost layered where `uses` is consumed today.
Work = save-schema add (pools), the cost field, deduction/gating hooks, refill rules, UI (show
pools), balance. ~1–2 build phases. Reuses the resource-keyed cost concept (`[SHP-1]`) for the
*in-combat* cost analogue.

**Scope.** v1: 1–2 pool types, per-map reset, cost on weapons + spells. Later: regen/rest refill,
pool-gated skills/movement.

**Dependencies.** Underpins **B (spells-from-pools)**. Pairs with the `[IEQ]` component model.

---

## B. Learned spell system  (Three Houses-style)

**Concept.** Units **learn** spells (not carried in inventory), each with **per-map charges** or
a **pool cost** (A). Learned via class levels / item-proficiency thresholds / items / training halls.

**Initial design.**
- A **known-spells list** on the unit (`UnitData.known_spells: Array[String]`, like `skills`).
  Spells are `ItemDef`s (with a spell/weapon component) referenced by id, **outside inventory**.
- **Casting:** a spell is a weapon-like capability sourced from the known list, not inventory —
  either folded into weapon selection (`get_equipped_weapon` considers known spells) or a
  dedicated **Cast** action + spell menu.
- **Charges:** per-map uses reuse the `skill_use_counters` + `reset_map_state` pattern; or a
  pool cost (A). Author picks per spell.
- **Learning hooks — all already exist or are firmed:**
  - class levels → `ClassData.skill_unlocks` (extend to spell unlocks).
  - item-proficiency thresholds → **`[PXP-4]` on-crossing event** (`grant_spell`).
  - items → a `learn_spell` consumable effect_id.
  - training halls → **`[PXP-9]`** panel grants a spell.

**Feasibility — High (feature-sized).** No single novel piece, but it's a **parallel
capability-source to inventory**: touches the equip/cast flow, a spell-select UI, save schema
(`known_spells` + per-spell charges), and the multi-source learning. Scale ≈ the accessory system.

**Scope.** v1: known list + per-map charges + a Cast action; learn via class-level + PXP-threshold.
Later: pool-cost spells, item/hall learning, forget/swap with a loadout cap.

**Dependencies.** Wants **A** (pool-cost spells); reuses **`[PXP]`** learning hooks + **`[IEQ]`**
ItemDef. Reconcile with current **tome-weapons** (inventory) — coexist vs migrate (open question).

---

## C. Author-flexible weapon triangle  (custom hierarchy + arbitrary effects)

> **RESOLVED 2026-06-24b** → `[CEX-9..12, 17]` (register `candidate_systems_open_questions_2026-06-23.md`):
> an F4 `triangle` profile (arbitrary matrix + author-extensible families + stat-mod `effects`,
> flat default / opt-in `rank_scaled`), plus reaver weapons (`reverses_triangle`, odd-count inverts
> ×`reaver_multiplier`). Conditions slice deferred to the F5 build.

**Concept.** Authors define their **own** attack-type hierarchy and **what each advantage/
disadvantage applies** — beyond flat Hit/Dmg, into stat bonuses/debuffs and **condition applications**.

**Initial design.**
- Move `GameConstants.WEAPON_TRIANGLE` into **`CampaignRules`** as an author-defined relationship
  graph, with a **default profile reproducing today's** Sword→Axe→Lance / Dark→Anima→Light + ±10/±2
  (non-breaking) — **the exact PXP rank-profile pattern**.
- Generalize the advantage **effect** from flat Hit/Dmg to an **effect set**: a modifier list
  (any stat, bonus/debuff — reuses the modifier model) **+ optional condition application** (apply
  Poison/Sleep/… on advantage — reuses `ConditionManager`).
- Magnitude can scale by the equipped rank (reuse a PXP-style profile), matching GDD_04's
  rank-scaled-triangle target.
- `WeaponData.triangle_family` / `combat_family` are already author-set strings — the data side is
  half-there; only the table + effect are hardcoded.

**Feasibility — Moderate.** Table-to-CampaignRules is the PXP-profile pattern; stat-effect
generalization reuses modifiers. **The condition slice is blocked on `ConditionManager`** (a stub).

**Scope.** v1: author hierarchy + stat-mod effects + non-breaking default. Later (post-condition
system): condition-application effects, rank-scaled magnitude.

**Dependencies.** **`ConditionManager` build** (currently a stub) for the condition slice; reuses
CampaignRules profiles + the modifier model.

---

## D. Per-map-use items  (recharging consumables)

**Concept.** Items whose uses **reset each map** (per-map charges) rather than decrementing
permanently — e.g. a "3×/map" healing trinket.

**Initial design.** A `uses_per_map` field on `consumable_component`; the instance tracks a per-map
counter that **reuses the `skill_use_counters` + `reset_map_state` pattern** (reset at map start),
instead of permanently decrementing `InventoryEntry.uses_remaining`. Player-facing: distinguish
"3/3 this map" (recharges) from "3 uses" (consumed).

**Feasibility — Easy.** Directly reuses an existing per-map-counter pattern; small save + UI add.

**Scope.** v1: per-map-use consumables. Later: per-N-turns recharge, charge-on-rest.

**Dependencies.** Slots into the `[IEQ]` `consumable_component`. Overlaps the spell charge model (B).

---

## E. Story / plot-relevant item tracking

**Concept.** Mark items as **plot-relevant** and **track** them, so the campaign/story layer can
drive changes (events, branches) off who holds what — and so the player/designer can see them.

**Initial design.**
- A **story flag** on the item def (`is_story_item` / a `story` tag) → locks it from sell/drop/trade
  (like a key), and surfaces it distinctly in inventory.
- A **tracking tool**: a registry/panel listing plot-relevant items + current holder (designer view;
  optional player "quest items" readout).
- **Story-driven changes** hang off the **`[MET]` map-events/triggers** framework: a trigger
  predicate like "unit holds item X" / "item X in convoy" fires an event/branch.

**Feasibility — Moderate, with a real dependency.** The item flag + lock + panel are easy. The
**story-driven changes need a campaign-flag / story-state store that does NOT exist yet** — so this
couples to a broader story/branching system (and the `[MET]` triggers). Tracking ≠ branching:
*tracking* (flag + panel + sell-lock) is cheap and independently useful; *branching* on it is the
larger dependency.

**Scope.** v1: the story-item flag + sell/drop lock + a tracking panel. Later: holder-based `[MET]`
triggers (needs the story-state store).

**Dependencies.** `[MET]` map-events/triggers; a campaign-flag/story-state store (**not yet built**);
the `[IEQ]` item model + `[CNV]` convoy.

---

## Cross-cutting dependencies (worth surfacing for the priority re-eval)
- **`ConditionManager` is a stub** but is now wanted by **C** (triangle-conditions) **and** the
  earlier effect gaps (poison weapon tag, condition immunity). It's trending toward a **foundational
  build**, not a one-off.
- **Resource pools (A)** underpin **spells-from-pools (B)**.
- **A campaign-flag / story-state store** is the missing piece behind **E**'s branching (and likely
  other narrative features). Tracking is independent of it; branching is not.
- The **CampaignRules author-profile pattern** (default-reproduces-current, non-breaking) recurs in
  **A** (pool types), **C** (triangle), and `[PXP]` (rank profiles) — a reusable design idiom.

## Next step
Walk the player-interaction questions in `[CEX-1..N]` to define, per system, how players interact →
how designers author/modify → how that shapes the underlying structure. Firming order = the pending
priority re-evaluation.
