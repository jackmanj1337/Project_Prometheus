---
Type: register
Status: OPEN
Last verified: 2026-07-01
Register: FRG-1..18
Resolved-in: (open)
---

# Forging / Weapon-and-Item Modification (`B7-FORGING`) — Research + Player-Facing Design + Open Questions

**Started:** 2026-07-01.
**Status:** Planning draft — register **OPEN**. Elevated from parked to a near-term
design pass by the 2026-07-01 Band 5-8 walkthrough (Q15): the v1 demo campaign will
include forging, so this must settle before any implementation plan.
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

## 4. Open questions register

### Group A — Upgrade model (what forging *does*)

#### [FRG-1] Upgrade shape for v1  **[OPEN]**
- **A — Fixed `+N` levels** (Fates/Engage): each level applies an authored stat bundle; simplest UX,
  simplest cost curve, simplest UI.
- **B — Budgeted free-point allocation** (PoR/RD): player spends a point budget across Mt/Hit/Crit/Wt;
  most flexible, hardest to balance + UI.
- **C — Discrete recipe/upgrade nodes** (Triangle/3H): named upgrades that grant stats and/or abilities.
- **Rec: model all three as an OPEN REGISTRY of upgrade operations, ship A as the v1 default UX.**
  A `ForgeUpgradeDef` (id, applies-to filter, stat deltas / effect grants, cost, req/gate) is data;
  "+N" is just an authored chain of upgrade ops. B and C are later authored data on the same registry,
  not engine rewrites. *(End-shape: what does the player click in the demo — a "+1" button, or a
  point allocator?)*

#### [FRG-2] Which attributes are forgeable  **[OPEN]**
- Candidates: `mt`, `hit`, `crit`, `wt`, `uses`, and **`effect_tags` / ability grants** (engrave-style).
- **Rec:** v1 = numeric weapon stats (`mt/hit/crit/wt`, maybe `uses`); **ability/effect grants deferred
  to [FRG-18]**. Each forgeable attribute is a registry-declared upgrade target, not a hardcoded field
  list — so adding "forge range" or "forge strikes" later is data.

#### [FRG-3] Is **repair** (durability restore) part of forging?  **[OPEN]**
- **A** — Repair is a forge service using `break_behavior`/uses (3H-style shared blacksmith).
- **B** — Repair stays the deferred Hammerne staff (Band 5 Q6 deferred it) / out of scope.
- **Rec: B for v1** unless the demo campaign uses durability; keep the seam so a repair op can register
  on the same service later. *(Depends on whether the demo turns on finite weapon durability.)*

#### [FRG-4] New-tier **transform** (Iron→Steel / Engage Transform) in scope?  **[OPEN]**
- **Rec: out of v1**, but note it's expressible as an upgrade op that swaps `def_id` + resets
  `forged_mods` — a later registered op, not a special case.

### Group B — Cost / resource model

#### [FRG-5] Cost currency for v1  **[OPEN]**
- **A — Gold only** (mirrors `[SHP-1]` v1), schema still multi-resource.
- **B — Gold + materials/ores** (RD/3H/Engage), materials as registry resource ids.
- **Rec: A**, with `CostSpec` shaped so a material resource id drops in without a code change
  (`ResourceLedger` already multi-resource). Materials become content, not engine work.

#### [FRG-6] Cost curve  **[OPEN]**
- Flat per-op vs **exponential per level** (Engage). **Rec:** author-defined per upgrade op / via a
  `REQ-16` formula term over the current forge level; default flat. No hardcoded cost table.

#### [FRG-7] Forge frequency limit  **[OPEN]**
- **A** — Unlimited, gold/material-gated (RD). **B** — Per-map/chapter cap (PoR). **C** — Smith-rank
  gate only. **Rec: A** (simplest, economy-gated); a per-map cap is an optional author rule later.

#### [FRG-8] Material sourcing *(only if [FRG-5]=B)*  **[OPEN]**
- Map drops / shop stock / event rewards. **Rec:** defer with [FRG-5]; if adopted, materials are
  `ResourceLedger` resources filled by existing reward/shop/drop paths — no new sink system.

### Group C — Per-instance state (`forged_mods`)

#### [FRG-9] `forged_mods` schema  **[OPEN]**
- **A — Raw stat-delta dict** (`{"mt": 2, "hit": 5}`): tiny, but lossy (can't audit/re-derive/reset).
- **B — Applied-upgrade record** (`{"level": 2, "ops": ["forge_mt","forge_mt"], "params": {...}}`):
  replayable, supports caps/reset/UI history, larger.
- **Rec: B** — store the applied upgrade ops; **derive** effective deltas via the registry. Enables
  reset ([FRG-12]), caps ([FRG-13]), and honest previews. F1 must reserve the richer field.

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
- **Rec:** mirror shops exactly — a `ForgeService` (quote/commit via `ResourceLedger`) + a PHB
  **forge panel** (prep), an **on-map** panel-trigger, and a **dialogue command**. One service, one
  panel, three entry points; reuse `PanelSelector`/`FocusedDetailPane`. Confirm this is the desired
  surface (vs forge-inside-shop as a tab).

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

### Group F — Effect-package engraving (stretch)

#### [FRG-18] Engrave-style effect packages  **[OPEN]**
- Named packages that grant an **effect bundle** with tradeoffs, **exclusive** per weapon (Engage
  engrave). **Rec: v2, and route through the Source/Style effect registry (Band 5 Q5)** rather than a
  forge-specific effect system — an engrave is "attach an effect package to a weapon instance,"
  which is the same effect vocabulary. Note the dependency; do not build in the v1 forging slice.

---

## 5. Dependencies & downstream

- **Upstream:** `B4-IEQ` (`ItemDef`/`WeaponComponent`, `InventoryEntry.forged_mods`, F1 rows),
  `B2-RESOURCE-LEDGER` + `B3-RESOURCE-POOLS` (cost path), `B3-REQ`/`REQ-16` (gates + cost formulas),
  `B3-PHB` + `PanelSelector` (panel), `B4-MAP-OBJECTS` (on-map trigger), `B4-DIALOGUE-V1` (command).
- **F1 (save) reservations to confirm:** the richer `forged_mods` schema ([FRG-9]=B), any smith-rank
  campaign var ([FRG-15]), and non-mergeable-instance identity ([FRG-11]).
- **`B2-REGISTRY` families to add:** forge upgrade ops, forge cost resources (if materials), forgeable
  attribute targets. All open registries, per AGENTS.md.
- **Effect-package engraving ([FRG-18]) depends on Band 5 Q5** Source/Style effect registry landing.

---

## 6. Verification recorded this pass

- **B4-IEQ leaves room for per-instance upgrade state — CONFIRMED.** `InventoryEntry.forged_mods`
  exists, is unread, and B4-IEQ explicitly reserves it as an instance overlay (Non-Goals + Existing
  Code Touchpoints). No B4-IEQ change is required to keep forging buildable later; the only new engine
  seam forging introduces is the **effective-weapon-stat resolver** ([FRG-10]).
