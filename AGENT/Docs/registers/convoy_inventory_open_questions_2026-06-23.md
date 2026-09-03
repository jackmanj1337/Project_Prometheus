---
Role: dated
Type: register
Status: RESOLVED 2026-06-23
Last verified: 2026-06-30
Register: CNV-1..8
Resolved-in: 2026-06-23k (CNV-1..7) / 2026-06-30 (CNV-8 panel UI)
---

# Convoy / Inventory Firming (branch D, economy spine) — Player-Facing Design + Open Questions

> **Reconciled 2026-08-29 by DRC Slice 0:** Trade and designated-provider Convoy move item
> instances through one inventory-transfer authority. Trade commits one transaction per swap;
> captive/passenger/provider permission is a predicate on the shared interaction descriptor, not a
> controller or faction mutation. Prison-disposition overflow uses the pending-items tray.

> **2026-07-25 interaction follow-up:** the storage/mechanical decisions here remain
> ratified. Comparative evidence and complete UI option analysis are in
> [`prep_economy_bundle_comparative_research_and_questions_2026-07-25.md`](../design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md)
> (`EPUX-08..12`).

**Started:** 2026-06-23k
**Status:** Planning draft — register OPEN. First of the **economy spine** (convoy → shop → gold);
convoy firms first because it is where bought/sold/looted items live.
**Source:** `player_facing_scope_map_2026-06-23.md` §3b #1 (FIRM v1); firmed intent in
`campaign_save_player_facing_firming_2026-06-21.md` branch **D** (quantities + shared store +
per-unit `max_inventory=8` enforcement; save-schema note "convoy store + per-unit inventory").
**Container:** the convoy is a **PHB option panel** (`[PHB-1..7]`, opt-in `prep_panels`).
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)
- **Per-unit:** `UnitData.inventory: Array[InventoryEntry]` (`scripts/resources/InventoryEntry.gd`) —
  typed weapon/item/equip entries; `uses_remaining` (-1 infinite / 0 empty / >0 finite); equipped
  weapon = first usable entry (`Unit.set_equipped_weapon` reorders).
- **Party-level:** `GameState.party_items: Array[String]` — a **flat id list** of loot from completed
  maps (`TurnManager` appends on reward); **no quantities, no per-item state**. `party_gold: int`.
  Both snapshot for Retry (`_snapshot_party_items`/`_snapshot_party_gold`).
- **`max_inventory = 8`** on `GameState` (comment: "future-facing") **and** `CampaignRules` (`@export`)
  — **defined, NOT enforced** anywhere today.
- **No convoy** exists; no trade UI; no prep inventory management. `party_items` is the embryonic
  shared store but cannot preserve a half-used weapon's durability (ids only).

## 2. What this pass produces
The player-facing convoy spec + the data-model decision (convoy store shape) — the schema the §2
save serializer and the §4a authoring contract build on. Equip-items (#3) firms separately but pairs here.

## 3. Open questions register

### [CNV-1] Convoy item representation — state-preserving entries vs counts  **[OPEN]**
- **A — `Array[InventoryEntry]`:** convoy stores full entries; each item keeps its own
  `uses_remaining` + forge mods (FE-accurate — a half-used Vulnerary/weapon stays half-used).
  `party_items` (loot ids) migrates into convoy entries. Stacking is a *display* concern.
- **B — Quantity by id** (`{item_id: count}`): simpler, but **loses per-item uses/durability** — wrong
  for finite-use weapons.
- **C — Hybrid:** stack consumables by (id, uses) bucket; weapons/forged as individual entries.
- **Rec: A** — reuses the existing `InventoryEntry` type, preserves durability, and matches the firmed
  "convoy store + per-unit inventory" note. Stacking lives in the UI (CNV-7), not storage.
- **Resolution:** **[RESOLVED → A]** (owner 2026-06-23k) — convoy stores `Array[InventoryEntry]`
  (state-preserving: per-item `uses_remaining` + forge mods).

### [CNV-2] Convoy capacity — unlimited vs capped  **[OPEN]**
- **A — Unlimited shared convoy** (FE-classic). No management pressure; simplest; serves as the
  overflow sink for the per-unit cap (CNV-3).
- **B — Capped** (author/ruleset `convoy_capacity`).
- **Rec: A** — FE convoys are effectively unlimited; a cap adds friction without clear v1 value. A
  `CampaignRules.convoy_capacity` can be added later as pure data growth.
- **Resolution:** **[RESOLVED → author rule, default unlimited]** (owner 2026-06-23k) — add
  `CampaignRules.convoy_capacity` (mandate-or-default) with a **sentinel default = unlimited**
  (e.g. `-1`); an author may set a finite cap. Mirrors the CNV-3 author-defined per-unit cap.
  - **Cross-ref `[CEX-16]` (2026-06-24d):** **key/story items (`ItemDef.story`) are exempt from
    `convoy_capacity`** (never count against the cap, can't be lost) and surface in a dedicated
    convoy **"Key Items" view**. The capacity count excludes story items.

### [CNV-3] `max_inventory = 8` enforcement — where/when  **[OPEN]**
- **A — Enforce the per-unit 8-slot cap at every growth site** (prep trade, shop buy, on-map pickup,
  map reward); overflow routes to the (unlimited) convoy rather than the unit. Map-reward loot
  (`TurnManager` → today `party_items`) routes to **convoy**, so a full unit never blocks a reward.
- **B — Keep unenforced for v1.**
- **Rec: A** — enforcement is the *point* of convoy; enforce at mutation sites with convoy as the
  overflow sink. (Uses `CampaignRules.max_inventory`, already a per-save rule.)
- **Resolution:** **[RESOLVED → A, author-defined cap]** (owner 2026-06-23k) — enforce at every growth
  site, overflow → convoy; **the cap is an author-defined variable**, not a hardcoded 8. Use the existing
  `CampaignRules.max_inventory` (`@export`, default 8) as a **mandate-or-default** rule per `[CST-6]`.

### [CNV-4] Prep trade / management surface  **[OPEN]**
- **A — Full prep management:** in the convoy panel, move items unit↔convoy and unit↔unit across the
  **whole roster** (not just deployed), arrange/equip. Unrestricted out of battle.
- **B — Restricted** (deployed units only / trade-adjacency even in prep).
- **Rec: A** — out of battle, free reorganization is the genre norm and the low-friction default;
  battle-time restriction is the separate CNV-5 case.
- **Resolution:** **[RESOLVED → A, faction-scoped]** (owner 2026-06-23k) — unrestricted move
  unit↔convoy / unit↔unit across the **active roster of the faction being controlled**. **Forward note:**
  this implies the convoy/store is **per-controlled-faction** — in hotseat/PvP each human faction manages
  its own; the standard single player-faction campaign sees one party convoy. (Forward, not v1 build work.)

### [CNV-5] On-map convoy access — v1 or deferred  **[OPEN]**
Branch D listed "on-map convoy access" as forward intent. The mid-battle access mechanic is a real fork.
- **A — Prep-only in v1:** no mid-battle convoy access; convoy is a hub panel only. Simplest; defers
  the on-map mechanic (and any supply-unit/tile design) cleanly.
- **B — On-map access for all units** (Awakening-style): any unit may deposit/withdraw on its turn.
- **C — On-map access via a designated supplier** unit/tile (classic FE supply convoy).
- **Rec: A for v1** — keep convoy a prep panel; revisit B/C alongside on-map trade + the supplier
  concept. (No battle-time trade action exists in code today, so A adds nothing new to combat.)
- **Resolution:** **[RESOLVED → A v1, richer forward space]** (owner 2026-06-23k) — **prep-only in v1**.
  **Forward intent (post-v1, likely author-selectable which model):** (1) mid-battle **unit↔unit trade**,
  (2) a **special convoy unit/class** with access, (3) a **per-unit access action** for some-or-all units.
  Each is its own later mechanic; the v1 store/schema must not preclude them (the shared store + entry
  model already doesn't).
- **Amendment (owner 2026-07-27):** bring ordinary mid-battle **unit↔unit Trade** into v1 to support
  adjacent allies and captive/Rescue/Pair Up occupants in the actor's or an adjacent space. Use an
  FE7-style item-or-empty-slot swap through the ordinary item-instance ledger. This does **not**
  make convoy access universal. Also bring designated-provider on-map convoy access into v1: a unit
  may deposit/withdraw through an eligible designated convoy provider according to the provider's
  authored adjacency/range policy. Universal access remains deferred. Detailed Trade eligibility,
  action cost, spatial-query reuse, and custody behavior are specified by `[DRC-30]`.
  Provider behavior while attached is author-tunable in v1. The shipped default lets a friendly Pair
  Up support or Rescue passenger project convoy access from its lead/carrier's tile, but a unit held
  through aggressive custody/capture does not project access. Provider relation, attachment role,
  availability conditions, and range are evaluated by the registered provider policy rather than a
  special-case check in the convoy UI.
  Follow the FE7 partial-action precedent for v1: opening and cancelling without a transfer is free;
  the first committed deposit/withdrawal commits the actor's location; the session may contain
  multiple transfers; closing returns to the remaining-action menu; and Convoy may be initiated at
  most once by that actor during the activation. Trade and Convoy keep separate once-per-activation
  usage marks, so an eligible unit may perform each once from the committed location before taking a
  concluding action. Provider activation is unaffected when another unit accesses it. Route any
  move-again behavior through the shared post-action movement policy.

  As with Trade, keep action cost, successful-session limit, whether Trade and Convoy share or keep
  separate limits, post-action movement, provider range/metric, and eligible attachment roles as
  author-tunable policy fields. V1 exposes the validated FE7-like preset above; later presets may use
  other combinations only after their action-menu and AI behavior are supported.

### [CNV-6] Convoy as the single shared item sink  **[OPEN]**
- **A — Yes:** convoy replaces `party_items` as the one shared store. Map rewards, enemy drops, and
  shop purchases without a target unit all land in convoy. No parallel loose-item list.
- **B — Keep `party_items` separate** from a managed convoy.
- **Rec: A** — one shared store is the clean model the firmed save-schema note anticipated; `party_items`
  migrates into the convoy entries (data growth, not a reshape). Retry snapshot covers the convoy.
- **Resolution:** **[RESOLVED → A]** (owner 2026-06-23k) — convoy is the single shared store; `party_items`
  migrates in; map rewards / drops / untargeted shop buys all land in convoy.

### [CNV-7] Stacking / display  **[OPEN]**
- **A — Stack identical full items by id** with a count badge (5× Vulnerary); partially-used items
  show separately or grouped by uses. Display-only over the CNV-1 entry list.
- **B — One row per entry**, no stacking.
- **Rec: A** — stacked display keeps a large convoy readable; storage stays per-entry. Low stakes.
- **Resolution:** **[RESOLVED → A]** (owner 2026-06-23k) — stack identical items by id with a count
  badge (display only); partially-used items grouped by uses. Storage stays per-entry.

### [CNV-8] Convoy panel UI — required functions (owner 2026-06-30)  **[RESOLVED]**
The convoy `[PHB]` panel must eventually provide these functions (functional
skeleton first per the Band 4 Q3 timing decision in
[`band4_implementation_plan_handoff_2026-06-30.md`](../plans/band4_implementation_plan_handoff_2026-06-30.md);
visual polish + full control-scheme support follow via `B6-INPUT`):
- **Per-character inventory view** — show a selected unit's own inventory
  alongside the convoy.
- **Author-defined groups** — the convoy is broken into author-defined
  categories, **plus an extra "All" category** that lists every item, with
  **author-defined sorting options**.
- **Per-item row fields (author-selected)** — name, uses info, count, base value,
  stack value.
- **Focused-item detail pane** — a "more info" section at the top giving a full
  breakdown of the currently-focused item.
Builds on the `[PHB]` panel surface + the `B6-INPUT` shared selector (a
focus-driven detail pane). Storage stays the `[CNV-1]` per-entry
`Array[InventoryEntry]`; groups, sorting, and stacking (`[CNV-7]`) are display
concerns over it.
- **Resolution:** **[RESOLVED → owner 2026-06-30]** — per-unit inventory view +
  author-defined groups + an All category with author sorting + author-selected
  row fields (name/uses/count/base value/stack value) + a focused-item detail
  pane; functional-first, polish and full control schemes via `B6-INPUT`.

## 4. Notes
- **Save impact (§2):** convoy serializes as state-by-id `InventoryEntry` records (uses + forge mods)
  on the per-save party; replaces/absorbs `party_items`; covered by the Retry snapshot + integrity hash.
  **Per-controlled-faction** store (forward, for hotseat/PvP — `[CNV-4]`).
- **New `CampaignRules` rules (mandate-or-default, `[CST-6]`):** `max_inventory` (already exists, now
  *enforced* — `[CNV-3]`) + new `convoy_capacity` (sentinel default = unlimited — `[CNV-2]`).
- **Pairs with equip-items (#3)** — equip entries already live in `InventoryEntry`; their lifecycle is
  a *separate* register, but they ride the same convoy store.
- DoD: GDD chapter + `GDD_Feature_Index` row + roadmap status flip land **with the build**, not now.

---

# Resolution Log
(newest first)

- **2026-06-30 — `[CNV-8]` convoy panel UI functions added (owner).** Per-unit
  inventory view; author-defined groups + an All category with author sorting;
  author-selected row fields (name/uses/count/base value/stack value); a
  focused-item detail pane. Functional-first (keyboard+mouse), polish + full
  control schemes via `B6-INPUT`. Captured for the Band 4 convoy plan.
- **2026-06-23k — Detail batch (CNV-2/4/7) — register COMPLETE.** [CNV-2] **author rule, default
  unlimited** (`convoy_capacity`, sentinel `-1`). [CNV-4] **A, faction-scoped** — unrestricted across the
  controlled faction's active roster; implies a per-controlled-faction store (hotseat/PvP forward note).
  [CNV-7] **A** stack-by-id display only.
- **2026-07-27 — CNV-5 amendment.** Ordinary FE7-style mid-battle unit↔unit Trade and access through
  designated on-map convoy providers move into v1 for `[DRC-30]`; universal on-map access remains
  deferred.
- **2026-06-23k — Schema batch (CNV-1/3/5/6).** [CNV-1] **A** convoy = `Array[InventoryEntry]`
  (state-preserving). [CNV-3] **A + author-defined cap** — enforce `max_inventory` at growth sites,
  overflow → convoy. [CNV-5] **A v1 (prep-only)** + forward space (unit↔unit battle trade / convoy
  unit-or-class / per-unit access action, likely author-selectable). [CNV-6] **A** convoy = single shared
  store; `party_items` migrates in.
