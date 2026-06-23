---
Type: register
Status: OPEN
Last verified: 2026-06-23
Register: SHP-1..5
---

# Shop / Economy Firming (branch E, economy spine) — Player-Facing Design + Open Questions

**Started:** 2026-06-23k
**Status:** Planning draft — register OPEN. Second of the **economy spine** (convoy → **shop** → gold);
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

### [SHP-1] Price model — buy source + sell ratio  **[OPEN]**
- **A — Reuse `cost` as buy price; sell = author-defined % of `cost`** (default 50%, FE-classic), a
  `CampaignRules`/`GameConstants` knob (mandate-or-default per `[CST-6]`). One value field per item.
- **B — Separate explicit buy/sell price fields** per item.
- **Rec: A** — `cost` already exists as the canonical value; a single global sell-% is simplest and
  consistent with the author-rule pattern; per-item sell overrides can be added later as data growth.
- **Resolution:** _[OPEN]_

### [SHP-2] Buy and sell, or buy-only  **[OPEN]**
- **A — Both buy and sell.** Sellable gated by `item_type` (key/non-sellable can't be sold); weapons
  sellable by default. Selling is a `party_gold` source.
- **B — Buy-only** (selling disabled).
- **Rec: A** — the `item_type` "sellable"/"key" split already exists; both directions is the genre norm
  and gives the economy a second gold source. An author could disable selling via a rule later.
- **Resolution:** _[OPEN]_

### [SHP-3] Stock model — what a shop offers  **[OPEN]**
- **A — Author-defined per-shop stock list, infinite quantity, one generic shop panel.** Each shop-panel
  instance (on a node) declares its item/weapon ids; quantities are infinite in v1; a single panel lists
  mixed weapons + items (no hardcoded armory/vendor split — "secret shop" = author stock + which node
  exposes it; categories are display-only). Limited/restocking stock = the deferred PHB-3 cadence flag.
- **B — Limited/restocking quantities** now.
- **C — Global shared catalog** (every shop sells the same list).
- **Rec: A** — author-controlled per-shop stock, infinite qty, one flexible panel; restock cadence rides
  the economy-deferred PHB-3 flag; typed shops are unnecessary structure.
- **Resolution:** _[OPEN]_

### [SHP-4] Where bought items go  **[OPEN]**
- **A — To convoy** (the single shared store, `[CNV-6]`); the player distributes via the adjacent convoy
  panel. Shop never touches per-unit `max_inventory`.
- **B — Directly onto a chosen unit** (inline, with `max_inventory` enforcement + convoy overflow).
- **Rec: A** — purchases land in convoy; equipping/distributing is the convoy panel's job. Clean
  separation, no inline cap-handling in the shop. (B as a later convenience.)
- **Resolution:** _[OPEN]_

### [SHP-5] v1 gold ledger — sources & sinks  **[OPEN]**
Today: only source = map `reward_gold`; no sinks. Shop is the first sink — the economy needs a stated
ledger to be balanceable.
- **A — v1 ledger:** **sources** = map `reward_gold` + **selling** (`[SHP-2]`); **sink** = **shop buy**.
  **Forward** (each rides its own system, reserve nothing structural): sources = chests/villages/arena/
  skirmish/bonus-EXP-adjacent; sinks = forge / arena bet / training-hall. Document, don't build.
- **Rec: A** — record the ledger so balance is trackable; v1 is reward+sell vs shop-buy. Other flows land
  with their own firming registers.
- **Resolution:** _[OPEN]_

## 4. Notes
- **Save impact (§2):** none new — `party_gold` already persists + snapshots. Shop stock is **campaign
  content/authoring** (per-node), not save state.
- **Forge (E3) deferred** (scope map); the unified weapon-stat-delta display is reserved for weapon-upgrades
  (`[BWN]` note). Repair-at-shop for broken weapons is the `[BWN-1..5]` deferral target.
- DoD: GDD chapter + `GDD_Feature_Index` row + roadmap status flip land **with the build**, not now.
