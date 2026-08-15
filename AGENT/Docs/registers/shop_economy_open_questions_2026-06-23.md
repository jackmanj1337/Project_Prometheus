---
Type: register
Status: RESOLVED 2026-07-02
Last verified: 2026-07-02
Register: SHP-1..6
Resolved-in: 2026-06-23k; SHP-6 in 2026-07-02 audit follow-up
---

# Shop / Economy Firming (branch E, economy spine) — Player-Facing Design + Open Questions

> **2026-07-25 interaction follow-up:** the economic decisions here remain ratified.
> Comparative evidence and complete Shop UI option analysis are in
> [`prep_economy_bundle_comparative_research_and_questions_2026-07-25.md`](../design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md)
> (`EPUX-13..17`). `EPUX-14` clarifies the earlier prep-destination/shopper wording.

**Started:** 2026-06-23k
**Status:** RESOLVED — every question below carries an owner resolution (2026-06-23k; `SHP-6` 2026-07-02).
> The inline `[OPEN]` markers were stale until 2026-08-15; see the `DSX` precedence diff, finding F1.
**Was:** Planning draft — register OPEN. Second of the **economy spine** (convoy → **shop** → gold);
depends on convoy (`[CNV-1..7]`) — purchases land in the shared convoy store.
**Source:** `player_facing_scope_map_2026-06-23.md` §3b #2 (FIRM v1; forge = later); firmed intent
`campaign_save_player_facing_firming_2026-06-21.md` branch **E**.
**Container:** the shop is a **PHB option panel** (`[PHB-1..7]`, opt-in `prep_panels`, node-scoped).
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)
- **`WeaponData.cost: int = 0`** and **`ItemData.cost: int = 0`** already exist — a per-item value field.
- **`ItemData.item_type`** already enumerates `"sellable"` and `"key"` (+ healing/stat/promotion/equip) —
  sellable vs non-sellable/key is already modeled.
- **`party_gold`:** one **source** (`TurnManager` adds `_map_data.reward_gold` on map completion); **zero
  sinks** today. Snapshotted for Retry (`_snapshot_party_gold`).
- **No shop** scene/script exists.

## 2. What this pass produces
The player-facing shop spec + the v1 gold ledger (sources/sinks) — feeds the §2 save (`party_gold`
already persists) and the §4a authoring contract (per-node shop stock).

## 3. Open questions register

### [SHP-1] Price model — buy source + sell ratio  **[RESOLVED]**
- **A — Reuse `cost` as buy price; sell = author-defined % of `cost`** (default 50%, FE-classic), a
  `CampaignRules`/`GameConstants` knob (mandate-or-default per `[CST-6]`). One value field per item.
- **B — Separate explicit buy/sell price fields** per item.
- **Rec: A** — `cost` already exists as the canonical value; a single global sell-% is simplest and
  consistent with the author-rule pattern; per-item sell overrides can be added later as data growth.
- **Resolution:** **[RESOLVED → B+, resource-keyed]** (owner 2026-06-23k) — **separate buy and sell
  amounts**, modeled as a **resource cost (required to buy) / resource yield (gained on sell)** structure
  **organized by resource type**, NOT a single gold int + sell-%. v1 resource = **gold** (existing `cost`
  becomes the gold buy amount); the structure is **extensible to other resources** (e.g. training-hall
  points — scope map §3b #19). **[SHP-1b → multi-resource, gold-only in v1]** (owner) — build the
  resource-keyed cost/yield structure (`resource_type → amount`) supporting N currencies; **v1 populates
  only gold**; other currencies slot in later with no reshape (do NOT enumerate the currency set yet).

### [SHP-2] Buy and sell, or buy-only  **[RESOLVED]**
- **A — Both buy and sell.** Sellable gated by `item_type` (key/non-sellable can't be sold); weapons
  sellable by default. Selling is a `party_gold` source.
- **B — Buy-only** (selling disabled).
- **Rec: A** — the `item_type` "sellable"/"key" split already exists; both directions is the genre norm
  and gives the economy a second gold source. An author could disable selling via a rule later.
- **Resolution:** **[RESOLVED → A]** (owner 2026-06-23k) — both buy and sell; key/non-sellable gated by
  `item_type`; weapons sellable by default.

### [SHP-3] Stock model — what a shop offers  **[RESOLVED]**
- **A — Author-defined per-shop stock list, infinite quantity, one generic shop panel.** Each shop-panel
  instance (on a node) declares its item/weapon ids; quantities are infinite in v1; a single panel lists
  mixed weapons + items (no hardcoded armory/vendor split — "secret shop" = author stock + which node
  exposes it; categories are display-only). Limited/restocking stock = the deferred PHB-3 cadence flag.
- **B — Limited/restocking quantities** now.
- **C — Global shared catalog** (every shop sells the same list).
- **Rec: A** — author-controlled per-shop stock, infinite qty, one flexible panel; restock cadence rides
  the economy-deferred PHB-3 flag; typed shops are unnecessary structure.
- **Resolution:** **[RESOLVED → A]** (owner 2026-06-23k) — author-defined per-shop stock list, infinite
  quantity in v1, one generic panel (mixed weapons+items; categories display-only); restock cadence rides
  the deferred PHB-3 flag.

### [SHP-4] Where bought items go  **[RESOLVED]**
- **A — To convoy** (the single shared store, `[CNV-6]`); the player distributes via the adjacent convoy
  panel. Shop never touches per-unit `max_inventory`.
- **B — Directly onto a chosen unit** (inline, with `max_inventory` enforcement + convoy overflow).
- **Rec: A** — purchases land in convoy; equipping/distributing is the convoy panel's job. Clean
  separation, no inline cap-handling in the shop. (B as a later convenience.)
- **Resolution:** **[RESOLVED → context-dependent]** (owner 2026-06-23k; **unified 2026-06-27d `[SAC-6]`**:
  with a **shopper** subject now assumed for prep too — on-map activator / prep selected-first — the rule
  collapses to **buy→shopper, overflow→convoy** for all shops; an author may still route a prep shop to
  convoy for bulk buying) — **prep-hub shop → convoy**
  (A); **battlefield shop → the accessing unit, overflow → convoy** (B). Surfaces a new **battlefield-shop**
  context (a mid-battle armory/vendor the player *visits*). **Note:** the overflow-write to convoy is
  narrower than full on-map convoy *management* — the `[CNV-5]` prep-only-convoy deferral still stands
  (you can't browse/withdraw convoy at a battlefield shop, only overflow into it). **[SHP-4b → record rule now,
  mechanic later]** (owner) — lock the destination rule now; **design the on-map shop-access mechanic
  (visit-tile) with the village / Map-Events `[MET]` cluster** (#11), not this register's first build.
  Shop firming's build focus = **prep shops**.

### [SHP-5] v1 gold ledger — sources & sinks  **[RESOLVED]**
Today: only source = map `reward_gold`; no sinks. Shop is the first sink — the economy needs a stated
ledger to be balanceable.
- **A — v1 ledger:** **sources** = map `reward_gold` + **selling** (`[SHP-2]`); **sink** = **shop buy**.
  **Forward** (each rides its own system, reserve nothing structural): sources = chests/villages/arena/
  skirmish/bonus-EXP-adjacent; sinks = forge / arena bet / training-hall. Document, don't build.
- **Rec: A** — record the ledger so balance is trackable; v1 is reward+sell vs shop-buy. Other flows land
  with their own firming registers.
- **Resolution:** **[RESOLVED → A]** (owner 2026-06-23k) — v1 sources = map `reward_gold` + selling;
  v1 sink = shop buy. Forward sources/sinks (chests/villages/arena/skirmish/bonus; forge/arena-bet/
  training) ride their own registers. Ledger generalizes to the SHP-1 resource model.

### [SHP-6] Sell-price source for items not in the shop's stock list  **[RESOLVED]**
Raised by the Band 1-6 plan audit (`AGENT/Code Reviews/band_plans_audit_2026-07-02.md` finding 4S-1):
`sell_yields` lives on `ShopStockEntry`, but the sell view lists the **shopper's whole inventory** —
items that may match no stock entry of this shop. Where does their sell yield come from?
- **A — Campaign-default sell formula** (an author-set `[REQ-16]` value term) applied to the item's
  resource-keyed value; stock-entry `sell_yields` becomes an optional per-entry override.
- **B — Only items matching a stock entry are sellable.**
- **C — Optional `sell_yields` on `ItemDef` itself,** with stock-entry override.
- **Resolution:** **[RESOLVED → A, durability-scaled + shop incoming modifier]** (owner 2026-07-02) —
  sell price is a **campaign-default author-set formula** (a `[REQ-16]` value term over the item
  subject). **Default: 50% of the item's value, further scaled by percent durability remaining**
  (`uses_remaining / max_uses`; items without durability sell at the full formula result). In addition,
  each shop may declare an **incoming-price modifier formula** applied to sells, **symmetric with the
  outgoing (buy-side) dynamic price modifiers** from `[SAC-5..9]` — one shop can pay more/less for
  goods exactly as it can charge more/less. Per-entry `sell_yields` on a stock entry overrides the
  campaign formula result (before the shop incoming modifier). The formula scales each resource amount
  of the item's resource-keyed value (`[SHP-1]`), so multi-resource yields need no reshape. No new save
  surface — formulas are authoring data.

## 4. Notes
- **NEW schema — resource-keyed pricing (`[SHP-1]`):** a `resource_type → amount` cost/yield structure
  replaces the flat single-`cost`-int + sell-% model for transactions; v1 populates **gold only**. Per-save
  resource balances beyond `party_gold` are **forward** (added when a system needs them, e.g. training
  points); v1 keeps `party_gold` (already persists/snapshots). Item `cost` field → the gold buy amount.
  > **Now needed (`[THL-4]`, 2026-06-27d):** training halls are that system — `party_gold` becomes a
  > **roster multi-resource wallet** (`{resource_id: amount}`, e.g. gold + activity points), alongside
  > **per-unit F7 pools** (motivation); a cost references a resource by `{id, scope}`. General capability.
- **Save impact (§2):** none new in v1 — `party_gold` already persists + snapshots. Shop stock is
  **campaign content/authoring** (per-node), not save state.
- **NEW forward surface — battlefield shops (`[SHP-4]`):** an on-map visit-tile armory/vendor; destination
  rule fixed here (buy→accessing unit, overflow→convoy), access mechanic designed with village/`[MET]` (#11).
- **Forge (E3) deferred** (scope map); the unified weapon-stat-delta display is reserved for weapon-upgrades
  (`[BWN]` note). Repair-at-shop for broken weapons is the `[BWN-1..5]` deferral target.
- **FORWARD — parked future-discussion (2026-06-27b, owner): requirement-driven dynamic shops + dialogue
  integration. → RESOLVED 2026-06-27d (full design + build) in `[SAC-5..9]`**
  (`registers/shop_activate_configs_open_questions_2026-06-27.md`): every shop assumes a **shopper**
  subject (on-map activator / prep selected-first), against which **dynamic pricing** (per-entry
  `requirement→[REQ-16] modifier`, `price=base×f(shopper.charm)`), **conditional stock** (per-entry F16
  gate, `[VIL-6/7]` hidden/shown-disabled), and **dialogue-wrapped shops** (`shop` as a `[DLG]` command)
  resolve; destination unified to **buy→shopper, overflow→convoy** (SAC-6). Original note retained:
  *look into* making shop behavior conditional on **who is shopping** and on **map/campaign
  flags**, and on wrapping/entering shops through the dialogue system. Concretely:
  - **Dynamic pricing** — per-transaction price modifiers gated by an **F16 Requirement** (`[REQ]`), the
    multiplier computed by an **F16 arithmetic value-term** (`[REQ-16]`): e.g. *better prices for a high-Charm
    shopper* = `price = base × f(stat:charm)`. This is exactly the REQ-16 "scale a magnitude by a derived
    number" worked-example pattern; the resource-keyed cost/yield structure (`[SHP-1]`) gains an optional
    per-entry requirement→modifier.
  - **Conditional stock (reveal/hide)** — per-stock-entry **F16 gate** (a trait, an item like a *membership
    card*, or an `[F6]` flag) using the **already-designed hidden / shown-disabled model** from `[VIL-6/7]`
    (tile-action discovery) and `[DLG-14]` (gated dialogue options) — *extra stock for members*, secret
    shops, flag-revealed wares. No new gating machinery; another F16 consumer.
  - **Dialogue integration (F15)** — a shop entered via / wrapped in a `[DLG]` conversation (shopkeeper
    banter, haggling), and dialogue choices branching to the shop panel — i.e. `shop` as a dialogue
    `command`, or a dialogue launching the `[VIL-2]`/`activate`/`shop` interactive-trigger. Reuses the F15
    entry model + the F16 branch gating, doesn't invent shop-specific conversation code.
  - **Status:** ADDITIVE + NON-BLOCKING (base shop economics stand without it; no F1/save impact beyond what
    F16/F15 already reserve). **Revisit during/after the A5 shop on-map-mechanic walk** (`[SHP-4b]`), when
    the `shop`/`activate` configs and the EXP/economy cluster are on the table.
- DoD: GDD chapter + `GDD_Feature_Index` row + roadmap status flip land **with the build**, not now.

---

# Resolution Log
(newest first)

- **2026-07-02 — [SHP-6] RESOLVED (owner, audit follow-up).** Sell price = campaign-default
  author-set `[REQ-16]` formula; default 50% of value × percent durability remaining; per-shop
  **incoming**-price modifier formula symmetric with the outgoing buy modifiers; stock-entry
  `sell_yields` = per-entry override. Raised by `band_plans_audit_2026-07-02.md` finding 4S-1.
- **2026-06-23k — register COMPLETE.** [SHP-1] **B+ resource-keyed** (separate buy/sell, `resource_type→
  amount` cost/yield; **[SHP-1b]** multi-resource model, gold-only in v1). [SHP-2] **A** buy+sell, key
  unsellable. [SHP-3] **A** author per-shop stock, infinite qty, generic panel. [SHP-4] **context-dependent**
  — prep shop→convoy, battlefield shop→unit + convoy overflow; **[SHP-4b]** record rule now, on-map mechanic
  designed with village/`[MET]`, build focus = prep shops. [SHP-5] **A** v1 ledger (sources reward+sell /
  sink shop), generalizes to the resource model.
