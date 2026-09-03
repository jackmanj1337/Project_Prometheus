---
Role: dated
Type: register
Status: RESOLVED
Last verified: 2026-07-01
Register: FRG-1..20
Resolved-in: this register — Walkthrough Decisions (2026-07-01c), §3c; downstream B7-FORGING implementation plan
---

# Forging / Weapon-and-Item Modification (`B7-FORGING`) — Research + Player-Facing Design + Open Questions

> **2026-07-25 research refresh:** the operation-overlay and open-registry direction here
> remains the mechanical source. Updated comparative evidence and a complete player-facing
> option analysis are in
> [`prep_economy_bundle_comparative_research_and_questions_2026-07-25.md`](../design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md)
> (`EPUX-23..28`).

**Started:** 2026-07-01.
**Status:** Register **RESOLVED** by the 2026-07-01c owner walkthrough (all of
`[FRG-1..20]` settled — see **§3c Walkthrough Decisions (2026-07-01c)**, the
authoritative answers). Elevated from parked to a near-term design pass by the
2026-07-01 Band 5-8 walkthrough (Q15): the v1 demo campaign includes forging.
Next artifact is the `B7-FORGING` implementation plan built from §3c.
**Row:** `B7-FORGING` (control plane — flag for a status bump to near-term).
**Source:** `band5_plus_preimplementation_questions_review_2026-06-30.md` → Walkthrough
Decisions (2026-07-01) Q15; substrate reserved by `items_equipment_unified_model_2026-06-23.md`
(`forged_mods`, M10) and `resource_ledger_cost_resolver_contract_2026-06-28.md`.
**Pattern:** forging is a **service + PHB/on-map/dialogue panel consumer** that mirrors
`ShopService`/`ShopPanel` (`band4_shop_economy_implementation_plan_2026-06-30.md`), spends
through the `ResourceLedger`, and writes **per-instance** state onto `InventoryEntry`.
**Architecture stance (AGENTS.md):** the forge vocabulary is an **open registry of upgrade
operations + recipes read by an engine service**, NOT a hardcoded `enum`+`match` forge table.
Adding a forge upgrade, cost model, or gate must stay pure data. Aligns with `[EXT]`.
Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. Research — how forging has worked

### 1a. Fire Emblem series (design axes)

| Game | Model | Cost | Limit | Notes |
|---|---|---|---|---|
| **Path of Radiance (FE9)** | **Free-point allocation** onto a stock weapon: Mt ±5, Hit ±25 (steps of 5), Crit ±9 (steps of 3), Wt ±5 | Gold only | **1 forge / chapter** | Player names + recolors the result; a *unique customized instance*. |
| **Radiant Dawn (FE10)** | Same allocation model | Gold **+ ores/materials** (each ore biases which stat can be raised & by how much) | Unlimited (gold/material-gated) | Materials sourced from maps/shops. |
| **Shadow Dragon / New Mystery (DS)** | Smithy: spend gold to raise Mt/Hit/Crit up to a per-weapon cap | Gold | Per-weapon cap | Forge counter on the weapon. |
| **Fates (FE14)** | **+1…+7** stat tiers (mostly Mt) | Needs **2 copies of the same weapon** + minerals (type-specific) | Cost scales with level | My-Castle smithy building. |
| **Three Houses (FE16)** | Blacksmith: **improve stats + repair (restore durability)**; higher smith rank unlocks **crafting new/higher-tier weapons** | Gold + **Smithing Stones** (+ rarer stones for better tiers) | Smith rank gate | Durability is back; forging both upgrades and repairs. |
| **Engage (FE17)** | **Refine** to **+1…+5** (exponential cost) *and* **Transform** (cheaper, resets to Lv1, becomes a new weapon). Separately, **Engrave**: apply an Emblem **stat-package** (exclusive — one weapon per engrave, tradeoffs like −avo/+wt) | Refine: gold + 3 materials. Engrave: **Bond Fragments** | Lv5 cap; engrave exclusivity | Refine and engrave stack on one weapon. |
| *(Awakening / SoV)* | No forge (SoV had passive item evolution instead) | — | — | Baseline for "forging is optional." |

**FE takeaways:** two recurring upgrade shapes — **(a) budgeted stat allocation** (PoR/RD, most
flexible/author-light) and **(b) fixed +N levels** (Fates/Engage, simplest UX). Costs trend from
**gold-only → gold + materials**. Recent games add **repair** (durability) and **effect-package
engraving** as separate services sharing the same smithy. Forged weapons are **unique instances**.

### 1b. Similar SRPGs

- **Triangle Strategy** — Smithy: spend **materials + coin** to raise a weapon through **ranks**;
  each rank both boosts base attack **and unlocks weapon abilities** (skills). Per-character weapons.
  → upgrade = *tiered node tree that grants stats **and** abilities*, material-gated.
- **Disgaea (Item World)** — dive a procedurally generated dungeon *inside* an item to raise its
  Item Level / rarity and subdue "Innocents" (residents granting % bonuses). → an *infinite,
  play-driven* upgrade loop; deep but a very different genre fit (out of scope, noted for contrast).
- **Final Fantasy Tactics** — no forge; upgrades come from poaching/Bazaar loot chains. → "upgrade
  by content acquisition" alternative.

**Cross-title takeaways:** the modern norm is **material + currency cost → discrete upgrade
nodes** that may grant **stats and/or abilities**, gated by a **smith rank / story flag**, producing
**per-instance** upgraded gear. Free-point allocation (PoR) is the most author-flexible but hardest
to balance/UI; fixed +N is the simplest to ship.

---

## 2. State today (code-grounded substrate)

- **`InventoryEntry.forged_mods: Dictionary = {}`** — already exists as a **per-instance overlay**,
  **no reader today** (genuinely reserved for this work). `InventoryEntry` is the per-slot runtime
  instance keyed by `def_id`; definition data never lives on the instance (`[IEQ]`). ✅ This is the
  per-instance room Q15 asked us to verify — **B4-IEQ leaves it reserved** and its Non-Goals
  explicitly say "Do not build forging; `InventoryEntry.forged_mods` stays an instance overlay."
- **Weapon stats** live on `WeaponData` (→ `WeaponComponent` after B4-IEQ): `mt`, `hit`, `crit`,
  `wt`, `uses`, plus `effect_tags: Array[String]`, `strikes_per_attack`, range formulas.
  **Combat/UI read these directly** (`CombatResolver`, range calc, weapon menu) — so a forge overlay
  needs an **effective-weapon-stat seam** (read `base + forged_mods`), not scattered call-site edits.
- **`ResourceLedger` cost resolver contract** (`resource_ledger_cost_resolver_contract_2026-06-28.md`)
  already lists **"item/source uses and broken/degraded modes"** and generic spends among consumers;
  `quote`/`reserve`/`commit` + `CostSpec` (resource id, formula, refundable, preview) is exactly the
  path forge costs should use. Resource ids are registry entries, not switch values.
- **`ShopService` + `ShopPanel`** (B4-SHOP-ECONOMY) is the template: a service that quotes/commits via
  `ResourceLedger`, a PHB panel using `PanelSelector`/`FocusedDetailPane`, an on-map trigger, and a
  dialogue command — all reusable shapes for a forge.
- **Effect / modifier machinery** — `unit.add_modifier(...)` + `until_unequipped` lifecycle (accessory
  model) exist for *unit* stats; the Source/Style **effect registry** (Band 5 Q5) is the natural home
  if forging can grant **effect packages** (engrave-style). Forge stat deltas, by contrast, modify the
  **weapon**, so they need the effective-weapon-stat resolver above, not `add_modifier`.
- **Broken-weapon mode** (`[BWN-1..5]` RESOLVED) already models durability/`break_behavior` — the hook
  a **repair** service (Hammerne / smith repair) would drive.

---

## 3. What this pass produces

The player-facing forging spec + the data model: (1) an **upgrade-operation / recipe registry**,
(2) the **`forged_mods` per-instance schema** + the **effective-weapon-stat resolver seam**, (3) the
**cost model** wired to `ResourceLedger`, (4) the **forge service + panel** consumer surface, and
(5) the **minimum v1 demo slice**. It feeds a later `B7-FORGING` implementation plan and confirms the
`InventoryEntry`/F1 save rows forging needs.

---

## 3b. Direction recorded (2026-07-01b)

Owner steer on the first round. Details fold into the individual questions below
(affected ones now **[ASKED]**); exact parameters still to finalize before a plan.

- **`[FRG-1]` — both shapes wanted, eventually.** (1) A **point-allocation** upgrade
  with **author-controlled step counts + per-stat maximums** (PoR/RD family), and
  (2) a **fixed-shape / transform** upgrade where the old item is **consumed and
  transformed into an author-created base item** (Iron Sword→Steel Sword, or
  Fire→Fire +3) — **possibly surfaced through the shop interface**. v1 still ships
  one concrete path ([FRG-17]); the registry must accommodate both.
- **`[FRG-3]` — repair defaults to YES**, included in forging, but **author
  discretion**: an author may charge extra for it or exclude it per forge.
- **`[FRG-4]` — transform is WANTED** (the fixed-shape half of `[FRG-1]`): consume
  old `def_id` → new author base def, rebasing `forged_mods`.
- **`[FRG-5]` — gold-only for v1 confirmed.** Other resources **will** be required
  eventually, **including special *items* consumed as a forge cost** that don't
  otherwise occupy a resource slot (an inventory/convoy item as material) — see the
  expanded `[FRG-8]` and new `[FRG-19]`.
- **`[FRG-9]` — store changes as operation overlays** (option B) — CONFIRMED.
- **`[FRG-18]` — effect / effect-bundle grants WANTED eventually.** Worked examples
  the model must express (mapped to substrate in the expanded `[FRG-18]`):
  "+5 RES / −5 DEF while equipped"; "usable to restore 20 HP at the cost of 2
  durability"; "grants a specific combat art while equipped"; "effective vs ghosts".
- **New `[FRG-19]`** (item-as-forge-cost) and **`[FRG-20]`** (forge ⇄ shop shared
  interface) added from this steer.

## 3c. Walkthrough Decisions (2026-07-01c) — register RESOLVED

Owner walked the full `[FRG-1..20]` register one question at a time (same pattern as
the Band 5-8 review). These are the **authoritative settled answers**; the per-question
sections below (§4) are kept for rationale but every tag is now RESOLVED. Notable
outcome: the **v1 slice is larger than the earlier "+N stat bump" lean** — v1 ships
**point allocation + live durability/repair + player-rename**, so the v1 content floor
and engine seams grow accordingly.

**Group A — upgrade model**
- **[FRG-1] Upgrade shape — v1 = POINT ALLOCATION** (Group A option B), not `+N`. The
  registry still accommodates `+N` (A) and transform (C) as data; only allocation is
  authored for the demo.
- **[FRG-2] Forgeable attributes — v1 = numeric weapon stats** (`mt/hit/crit/wt`, plus
  `uses` via repair). Effect/ability grants land with [FRG-18]. Each target is a
  registry-declared upgrade target, not a hardcoded field.
- **[FRG-3] Repair — DEFAULT ON, and LIVE in v1** (durability is enabled in the demo).
  Repair cost = an **author-provided formula** with access to: **base item, current
  durability, max durability, item value, and current modifications**. Author may zero
  it or exclude repair per forge/campaign. Same REQ-16 formula path as upgrade costs.
- **[FRG-4] Transform — WANTED, not v1.** Overlay handling on transform is
  **author-declared per transform op** (`rebase` = carry the overlay forward re-clamped,
  or `reset` = fresh at the new base). Both are data on the op.

**Group B — cost / resources**
- **[FRG-5] Currency — gold-only for v1**; multi-resource + item-as-cost ([FRG-19]) later.
- **[FRG-6] Cost curve — author-defined REQ-16 formula per op, DEFAULT FLAT.** Escalation
  is opt-in data, no hardcoded cost table.
- **[FRG-7] Frequency — v1 is RESOURCE-GATED ONLY** (no count cap). Eventually a
  **per-map forge charge/allowance tied to the shop refresh cadence, sharing the same
  gates as shop inventory** — a later author rule, not v1 engine work.
- **[FRG-8] Materials — deferred past v1**; both resource-scoped and item-scoped
  ([FRG-19]) reuse existing reward/shop/drop paths.

**Group C — per-instance state**
- **[FRG-9] `forged_mods` schema — OPERATION OVERLAY** (option B), confirmed: stores
  applied ops (ids + params); registry derives effective deltas.
- **[FRG-10] Effective-weapon-stat resolver — ACCEPTED as one seam** (`base + forged
  deltas`); route CombatResolver, range, weapon menu, character sheet through it. The
  load-bearing engine change; guard test that no combat path reads raw `weapon.mt` after.
- **[FRG-11] Instance identity — PLAYER-RENAMABLE + NON-MERGEABLE.** Forged entry is
  non-stackable/un-mergeable and carries a **saved player-set custom name** (new F1
  field). Convoy merge keys off `forged_mods` emptiness.
- **[FRG-12] Reversibility — PERMANENT** in v1. Reset/re-forge op trivial to add later
  ([FRG-9]=B).
- **[FRG-13] Caps / allocation model — author-written per-item rules:** a **total upgrade
  point max**, a **per-stat upgrade max**, and a **per-stat upgrade step size**. **PLUS a
  campaign rule:** whether adding **special effects counts against the forge upgrade-point
  budget OR occupies its own slot resource** (a separate effect-slot pool). This is the
  `ForgeUpgradeDef` schema shape the engine enforces.

**Group D — service / UI / gating**
- **[FRG-14] / [FRG-20] Surface — STANDALONE PHB forge panel for v1, on a SHARED
  ResourceLedger transaction core** (option C) with an optional trade-in/consume input so
  the shop can reuse it when transform lands. On-map / dialogue entry points come later.
- **[FRG-15] Gating — v1 resource-gated only.** Availability + smith-rank become `B3-REQ`
  predicates / shop-style gates later (per the [FRG-7] "same gates as shop inventory" steer).
- **[FRG-16] Preview — before→after stat diff + `ResourceLedger.quote()` cost summary**
  before commit; preview must equal commit (ledger invariant). Confirmed.

**Group E — v1 slice**
- **[FRG-17] v1 forging slice (settled):** **point-allocation** upgrade (total-point +
  per-stat max + step size) on a weapon family, **gold** cost via author formula,
  **durability + repair LIVE**, **standalone prep PHB forge panel**, **permanent**,
  **player-renamable non-mergeable instances**, persisting per-instance through
  save/convoy. Proves: upgrade registry, allocation UI, `forged_mods` op-overlay write,
  effective-stat resolver, ledger spend (upgrade + repair formulas), rename + non-merge,
  panel. Deferred: transform, effect grants, materials/item-cost, on-map/dialogue,
  per-map charge cap, shop-folding.

**Group F/G — stretch & extensions**
- **[FRG-18] Effect / effect-bundle grants — WANTED (v2), ALWAYS STACKABLE, CAP-GATED.**
  No exclusivity flag: bundles are limited only by the forge point/slot budget from the
  [FRG-13] campaign rule. Routes through the Band 5 Q5 Source/Style effect registry; the
  effective-weapon resolver ([FRG-10]) returns granted tags/actions/modifiers, not just stats.
- **[FRG-19] Item-as-forge-cost — new `item` CostSpec scope on the ledger** (option A),
  later. Atomic multi-cost commit (gold + item) with rollback on failure.
- **[FRG-20] Forge⇄shop — shared transaction core, standalone forge panel in v1**; fold
  the transform "trade-in → new def" flow into a shared surface when transform lands.

## 3d. Refinements (2026-07-01c, continued)

Further owner detail after §3c, folding into [FRG-13], [FRG-14], [FRG-15], [FRG-20]:

- **Per-forge-instance capability envelope (extends [FRG-13] + [FRG-15]).** Each forge
  instance declares the envelope of upgrades it will perform, and may **clamp below the
  item's own author-declared limits** — a lower **total modification-point cap** and lower
  **per-stat caps**, each **fixed OR derived from the forge's predicate**. Effective cap at
  a forge = **min(item author caps, forge-instance caps)**. This reuses the **same gating
  shops use to hide inventory** (REQ predicates), so no bespoke forge-gating code.
- **Target-item predicate context (new engine requirement).** The forge's offering/hide
  predicates must be able to read the **candidate item instance** being worked on — its
  **def/tags and current `forged_mods` (forge level)** — not just campaign/roster state.
  This lets an author declare a smith that **refuses a key/quest item** (predicate over item
  tags) or **refuses an item already upgraded beyond what the smith can perform** (predicate
  over current forge level vs the forge's cap). This extends the shop-hide predicate subject
  set — the one genuinely new gating dimension forging adds over shops.
- **This is NOT a depleting per-visit charge count.** "How many upgrades" = the capped
  envelope + eligibility above, not a consumable stock. No per-instance charge save field.
  A separate per-map forge allowance ([FRG-7]) remains a later, distinct author rule.
- **Forge panel UI = two modes ([FRG-14]).** (1) a **point-allocation grid** (per-stat +/−
  under the effective caps, with live cost), and (2) a shared **"item operation" list** that
  **reuses the transform UI**, where **repair and transform** both appear as selectable ops
  on a chosen item (item-in → restored, or item-in → new def). Repair is thus a distinct,
  transform-shaped UI action, not a row in the allocation grid.

## 3e. Forge panel UI format — initial draft (2026-07-01c)

Chosen layout: **two-pane, inline forecast**, reusing the shop panel's
`PanelSelector` + `FocusedDetailPane` shape (per the [FRG-20] shared core). Panes
collapse to a single stacked column on narrow / mobile-web screens.

- **Left pane — item picker:** the forgeable items in inventory/convoy, each showing
  its current forge state (e.g. `Iron Sword +2`, with any player name).
- **Right pane — detail with mode tabs `[Upgrade] [Modify]`:**
  - **Upgrade (point-allocation grid):** one row per forgeable stat showing
    `base → new` **inline**, a `◂ +N ▸` stepper (step size = author data), the
    **effective per-stat max** (`min(item, forge-instance)`), a running **Points x/total**
    against the effective total-point cap, the **gold Cost** from `ResourceLedger.quote()`,
    a **Name** field (rename → saved custom-name), and the **Forge** (commit) button.
  - **Modify (reuses the transform UI):** an **item-operation list** — **Repair**
    (`uses → uses`, formula cost) and **Transform** (`→ new def`, cost) as selectable
    ops on the chosen item, with a **Confirm** button.
- **Forecast is inline** on each row; the shown result must equal the committed result
  (ledger preview==commit invariant, [FRG-16]).

```
UPGRADE                                            Gold 3,200
┌Items─────┐ ┌ Iron Sword +2 ───────────────────┐
│▸IronSwd+2│ │ [Upgrade]  Modify                 │
│ SteelLnc │ │ Mt   6 → 7   ◂ +1 ▸   max +2      │
│ Fire     │ │ Hit 85 → 85  ◂ +0 ▸   max +10     │
│ Iron Bow │ │ Crit 0 → 0   ◂ +0 ▸   max +9      │
│          │ │ Wt   5 → 5   ◂ -0 ▸   max -2      │
│          │ │ Points 1/5          Cost 400g     │
│          │ │ Name[Betrayer_]        [ Forge ]  │
└──────────┘ └───────────────────────────────────┘

MODIFY  (item-op list, reuses transform UI)
             ┌ Iron Sword +2 ───────────────────┐
             │  Upgrade  [Modify]                │
             │ ▸ Repair    30/45 → 45/45    60g  │
             │   Transform → Steel Sword   250g  │
             │                     [ Confirm ]   │
             └───────────────────────────────────┘
```

## 4. Open questions register

### Group A — Upgrade model (what forging *does*)

#### [FRG-1] Upgrade shape  **[ASKED]**
- **A — Fixed `+N` levels** (Fates/Engage): each level applies an authored stat bundle; simplest UX.
- **B — Budgeted point allocation** (PoR/RD): player spends a point budget across Mt/Hit/Crit/Wt.
- **C — Fixed-shape / transform** (Triangle/3H/Engage): consume the old item → an author-created new
  base item (Iron→Steel, Fire→Fire +3), possibly via the shop interface ([FRG-20]).
- **Direction (2026-07-01b): support B and C, eventually.** B must expose **author-controlled step
  counts + per-stat maximums**; C consumes/transforms into a new author base def ([FRG-4]). Model all
  shapes as an **OPEN REGISTRY of upgrade operations** — a `ForgeUpgradeDef` (id, applies-to filter,
  stat deltas / effect grants / transform-target, cost, req/gate) is data; "+N" is just an authored
  chain of ops. **v1 ships one concrete path** ([FRG-17]); the schema must not preclude B or C.
- **Open parameter:** which single shape is the v1 demo path (lean: A/`+N` stat bump for the smallest
  showcase, with the allocation + transform ops registerable but not necessarily authored in the demo).

#### [FRG-2] Which attributes are forgeable  **[ASKED]**
- Candidates: `mt`, `hit`, `crit`, `wt`, `uses`, and **`effect_tags` / effect-bundle / ability grants**
  (the [FRG-18] archetypes).
- **Direction (2026-07-01b):** both numeric stats **and** effect/ability grants are in scope eventually
  (owner confirmed the [FRG-18] examples). v1 = numeric weapon stats (`mt/hit/crit/wt`, maybe `uses`);
  effect grants land with [FRG-18]. Each forgeable attribute is a **registry-declared upgrade target**,
  not a hardcoded field list — so adding "forge range" or "forge strikes" later is data.

#### [FRG-3] Is **repair** (durability restore) part of forging?  **[ASKED]**
- **Direction (2026-07-01b): YES by default** — repair is a forge op on the shared service (3H-style),
  restoring `uses`/clearing `break_behavior`. **Author discretion:** an author may **charge extra** for
  it or **exclude** it per forge/campaign. So repair is a **default-on, author-toggleable, priced**
  registered op — not a separate system, and not the Hammerne staff (which stays deferred, Band 5 Q6).
- **Open parameter:** whether the v1 demo actually turns on finite weapon durability (if off, the repair
  op registers but has nothing to restore in the demo). Confirm the repair cost default (free vs priced).

#### [FRG-4] New-tier **transform** (Iron→Steel / Fire→Fire +3 / Engage Transform)  **[ASKED]**
- **Direction (2026-07-01b): WANTED** (this is the fixed-shape half of [FRG-1]). A transform op
  **consumes the old `def_id`** and produces an **author-created new base def**, rebasing
  `forged_mods`. May be surfaced through the **shop interface** ([FRG-20]). Registered op, not a
  special case; **out of the minimum v1 slice** unless the demo campaign needs it.
- **Open parameter:** does a transform carry forward existing forged overlays onto the new base, or
  reset them (Engage resets to Lv1)? Lean: **rebase** — new base def's stats + a fresh (or
  author-mapped) overlay.

### Group B — Cost / resource model

#### [FRG-5] Cost currency for v1  **[ASKED]**
- **Direction (2026-07-01b): gold only for v1**, but the model must anticipate **(a) other
  `ResourceLedger` resources** (materials/ores) and **(b) special *items* consumed as a forge cost**
  that don't otherwise occupy a resource slot ([FRG-19]). Shape `CostSpec` so a material resource id
  drops in with no code change (`ResourceLedger` already multi-resource); the item-as-cost path is the
  one genuinely new dimension — see [FRG-19]. Materials remain content, not engine work.

#### [FRG-6] Cost curve  **[OPEN]**
- Flat per-op vs **exponential per level** (Engage). **Rec:** author-defined per upgrade op / via a
  `REQ-16` formula term over the current forge level; default flat. No hardcoded cost table.

#### [FRG-7] Forge frequency limit  **[OPEN]**
- **A** — Unlimited, gold/material-gated (RD). **B** — Per-map/chapter cap (PoR). **C** — Smith-rank
  gate only. **Rec: A** (simplest, economy-gated); a per-map cap is an optional author rule later.

#### [FRG-8] Material sourcing  **[ASKED]**
- Map drops / shop stock / event rewards. **Direction (2026-07-01b):** deferred past v1, but confirmed
  as an eventual need. Two flavors: **resource-scoped materials** (`ResourceLedger` ids filled by
  existing reward/shop/drop paths — no new sink system) and **item-scoped materials** (a real inventory
  item consumed — [FRG-19]). No new sourcing system either way; both reuse rewards/shop/drops.

### Group C — Per-instance state (`forged_mods`)

#### [FRG-9] `forged_mods` schema  **[ASKED]**
- **A — Raw stat-delta dict** (`{"mt": 2, "hit": 5}`): tiny, but lossy (can't audit/re-derive/reset).
- **B — Applied-upgrade record** (`{"level": 2, "ops": ["forge_mt","forge_mt"], "params": {...}}`):
  replayable, supports caps/reset/UI history, larger.
- **Direction (2026-07-01b): B — store changes as operation overlays (CONFIRMED).** `forged_mods`
  holds the applied upgrade **ops** (ids + params); the registry **derives** effective deltas. Enables
  reset ([FRG-12]), caps ([FRG-13]), transform rebasing ([FRG-4]), effect-bundle grants ([FRG-18]), and
  honest previews. F1 must reserve the richer field, not a flat delta dict.

#### [FRG-10] Effective-weapon-stat resolver seam  **[OPEN]**
- **Rec:** add one resolver (e.g. `WeaponStats.effective(component, entry)`) that returns
  `base + forged deltas`; route `CombatResolver`, range, weapon menu, and the character sheet through
  it. **This is the load-bearing engine change** — do it once, not at each call site. Verify no combat
  path reads raw `weapon.mt` after the migration (a DoD#2-style guard test).

#### [FRG-11] Instance identity / stacking  **[OPEN]**
- Forged weapons are **unique instances** (FE norm). Does forging make an entry non-stackable /
  un-mergeable in convoy, and can it be renamed? **Rec:** a forged entry is non-mergeable and carries an
  optional author/player display suffix (e.g. "Iron Sword +2"); persists through save/convoy/trade
  (already mandated by Q15). Confirm convoy's grouping/merge logic keys off `forged_mods` emptiness.

#### [FRG-12] Reversibility  **[OPEN]**
- Permanent vs re-forge/reset (Engage Transform resets). **Rec:** permanent by default; a `reset`/
  re-forge op is optional later, trivial if [FRG-9]=B.

#### [FRG-13] Caps  **[OPEN]**
- Max forge level and/or per-stat ceilings, and who enforces them. **Rec:** author data on the upgrade
  registry (per-op max level, per-stat clamp); engine enforces the declared cap, no hardcoded ceiling.

### Group D — Service / UI / where forging lives

#### [FRG-14] Container surface  **[OPEN]**
- **Rec:** mirror shops — a `ForgeService` (quote/commit via `ResourceLedger`) + a PHB **forge panel**
  (prep), an **on-map** panel-trigger, and a **dialogue command**. One service, three entry points;
  reuse `PanelSelector`/`FocusedDetailPane`. **Note (2026-07-01b):** the owner wants fixed-shape /
  transform upgrades ([FRG-1]C/[FRG-4]) **possibly surfaced through the shop interface** — so the forge
  and shop panels may share a surface for the "buy the upgraded item / trade item in" flow. See
  [FRG-20] for how forge and shop relate.

#### [FRG-15] Availability / smith-rank gating  **[OPEN]**
- Smithy available by story/campaign flag; smith "rank" gating which upgrades are offered (3H/Triangle).
- **Rec:** availability + rank are **`B3-REQ` predicates** over campaign/roster state; smith rank is a
  campaign resource/var, so higher-tier upgrade ops just declare a `req`. No bespoke gating code.

#### [FRG-16] Preview / forecast  **[OPEN]**
- **Rec:** show a before→after stat diff + `ResourceLedger.quote()` cost summary before commit (reuse
  the generalized effect-forecast idiom from Band 5 Q5). Preview must equal commit (ledger invariant).

### Group E — v1 demo scope

#### [FRG-17] Minimum v1 forging slice  **[OPEN]**
- **Rec (smallest showcase):** one registered `+N` **stat-bump** upgrade path (e.g. Mt) on one weapon
  family, **gold** cost, **prep PHB forge panel**, **permanent**, persisting per-instance through
  save/convoy. Proves: upgrade registry, `forged_mods` write, effective-stat resolver, ledger spend,
  panel. Everything else (materials, allocation UI, repair, engrave, on-map/dialogue) layers on after.

### Group F — Effect / effect-bundle grants (stretch)

#### [FRG-18] Effect / effect-bundle grants  **[ASKED]**
- **Direction (2026-07-01b): WANTED eventually.** Named packages/ops that grant an **effect bundle**
  (often with tradeoffs, and possibly exclusive per weapon, Engage-engrave style). **Route through the
  Source/Style effect registry (Band 5 Q5)**, not a forge-specific effect system — a forge effect-grant
  is "attach an effect package to a weapon instance," the same effect vocabulary. **v2 / not in the v1
  slice.** Worked examples the model must express, mapped to substrate:

  | Worked example | Mechanic | Substrate it reuses |
  |---|---|---|
  | "+5 RES / −5 DEF while equipped" | conditional **stat-swap bundle** on equip | accessory-style `until_unequipped` modifiers (`add_modifier`, StatBreakdown source); a bundle = several deltas under one grant |
  | "usable to restore 20 HP at cost of 2 durability" | grants an **active ability** with a **durability cost** | Source/Style effect (heal) + `ResourceLedger` cost scoped to the item's `uses` (broken/degraded seam) |
  | "grants a specific combat art while equipped" | grants an **action / combat art** while wielded | Source/Style **grant** (a granted action source, same idiom as Band 5 loadout "granted sources") |
  | "effective against ghosts" | adds an **effectiveness / `effect_tag`** | `WeaponComponent.effect_tags` — a forge op appends a tag to the effective tag set |

- **Design consequence:** because effect grants target the **weapon instance**, they layer through the
  same `forged_mods` op-overlay ([FRG-9]) + effective-weapon resolver ([FRG-10]); "effective-tags" and
  "granted actions/modifiers" become part of what the resolver returns, not just numeric stats.
- **Open parameter:** are these grants **exclusive** (one bundle per weapon, Engage-style) or stackable
  under the cap logic? Lean: author-declared per bundle (some exclusive, some stackable).

---

### Group G — Cost/interface extensions (from 2026-07-01b steer)

#### [FRG-19] Special **item** consumed as a forge cost  **[ASKED]**
- **Direction (2026-07-01b): wanted eventually.** An author must be able to require a **specific
  inventory/convoy item** as a forge material (consumed on commit) — a "special item that doesn't
  normally occupy a resource slot," distinct from a `ResourceLedger` numeric resource.
- **Design question:** model this as (A) a **new `CostSpec` scope** `item` (subject = an item def-id +
  count located in shopper inventory/convoy, removed atomically on commit) — keeps one cost path and
  one atomic commit; or (B) wrap every consumable item as an auto-registered `ResourceLedger` resource
  whose balance = count-in-inventory. **Rec: A** — a first-class `item` cost scope on the ledger
  keeps items as items (tradeable, stackable, story-flaggable) rather than shadow-resources, and the
  ledger's atomic multi-cost commit already covers "gold + item" in one transaction. Confirm removal
  order + rollback (a failed forge must not consume the item).
- **F1:** no new saved field (items already persist); the forge just calls an item-removal on commit.

#### [FRG-20] How do **forge and shop** relate?  **[OPEN]**
- The owner wants fixed-shape/transform upgrades ([FRG-1]C/[FRG-4]) "possibly utilizing the shop
  interface where the old item is consumed/transformed to create a new base item."
- **Options:** (A) **separate panels**, forge references shop-style stock rows; (B) **forge is a shop
  `destination_mode`/entry variant** — a stock row whose "buy" consumes a trade-in item + resources and
  yields the upgraded/new def; (C) **shared transaction core**, two thin panels.
- **Rec: C** — one `ResourceLedger`-backed transaction core with an optional **trade-in / consume**
  input, presented as either a shop row or a forge row. This keeps "spend gold + consume Iron Sword →
  receive Steel Sword" and "spend gold → +1 Mt on this instance" on the same commit path, differing
  only in whether the output is a **new def** (transform) or a **mutated instance** (`forged_mods`).
- **Open:** is the v1 demo forge a standalone panel, or already folded into the shop? Lean: standalone
  forge panel for the v1 slice ([FRG-17]); shared-core refactor when transform lands.

## 5. Dependencies & downstream

- **Upstream:** `B4-IEQ` (`ItemDef`/`WeaponComponent`, `InventoryEntry.forged_mods`, F1 rows),
  `B2-RESOURCE-LEDGER` + `B3-RESOURCE-POOLS` (cost path), `B3-REQ`/`REQ-16` (gates + cost formulas),
  `B3-PHB` + `PanelSelector` (panel), `B4-MAP-OBJECTS` (on-map trigger), `B4-DIALOGUE-V1` (command).
- **F1 (save) reservations to confirm:** the richer op-overlay `forged_mods` schema ([FRG-9]=B), any
  smith-rank campaign var ([FRG-15]), and non-mergeable-instance identity ([FRG-11]).
- **`ResourceLedger` extension:** an **`item` cost scope** ([FRG-19]) so a forge can consume a specific
  inventory item atomically alongside gold — the one genuinely new cost dimension from the 2026-07-01b
  steer; and a shared **transaction core** with an optional trade-in/consume input ([FRG-20]).
- **`B2-REGISTRY` families to add:** forge upgrade ops (incl. point-allocation, transform, repair, and
  effect-grant op kinds), forge cost resources (if materials), forgeable attribute targets. All open
  registries, per AGENTS.md.
- **Effect / effect-bundle grants ([FRG-18]) depend on Band 5 Q5** Source/Style effect registry (for
  granted actions/combat-arts and effect bundles) plus the accessory `until_unequipped` modifier path
  (for equipped stat-swap bundles).

---

## 6. Verification recorded this pass

- **B4-IEQ leaves room for per-instance upgrade state — CONFIRMED.** `InventoryEntry.forged_mods`
  exists, is unread, and B4-IEQ explicitly reserves it as an instance overlay (Non-Goals + Existing
  Code Touchpoints). No B4-IEQ change is required to keep forging buildable later; the only new engine
  seam forging introduces is the **effective-weapon-stat resolver** ([FRG-10]).
