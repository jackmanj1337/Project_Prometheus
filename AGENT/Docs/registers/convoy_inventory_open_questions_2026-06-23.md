---
Type: register
Status: OPEN
Last verified: 2026-06-23
Register: CNV-1..7
---

# Convoy / Inventory Firming (branch D, economy spine) — Player-Facing Design + Open Questions

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
- **Resolution:** _[OPEN]_

### [CNV-2] Convoy capacity — unlimited vs capped  **[OPEN]**
- **A — Unlimited shared convoy** (FE-classic). No management pressure; simplest; serves as the
  overflow sink for the per-unit cap (CNV-3).
- **B — Capped** (author/ruleset `convoy_capacity`).
- **Rec: A** — FE convoys are effectively unlimited; a cap adds friction without clear v1 value. A
  `CampaignRules.convoy_capacity` can be added later as pure data growth.
- **Resolution:** _[OPEN]_

### [CNV-3] `max_inventory = 8` enforcement — where/when  **[OPEN]**
- **A — Enforce the per-unit 8-slot cap at every growth site** (prep trade, shop buy, on-map pickup,
  map reward); overflow routes to the (unlimited) convoy rather than the unit. Map-reward loot
  (`TurnManager` → today `party_items`) routes to **convoy**, so a full unit never blocks a reward.
- **B — Keep unenforced for v1.**
- **Rec: A** — enforcement is the *point* of convoy; enforce at mutation sites with convoy as the
  overflow sink. (Uses `CampaignRules.max_inventory`, already a per-save rule.)
- **Resolution:** _[OPEN]_

### [CNV-4] Prep trade / management surface  **[OPEN]**
- **A — Full prep management:** in the convoy panel, move items unit↔convoy and unit↔unit across the
  **whole roster** (not just deployed), arrange/equip. Unrestricted out of battle.
- **B — Restricted** (deployed units only / trade-adjacency even in prep).
- **Rec: A** — out of battle, free reorganization is the genre norm and the low-friction default;
  battle-time restriction is the separate CNV-5 case.
- **Resolution:** _[OPEN]_

### [CNV-5] On-map convoy access — v1 or deferred  **[OPEN]**
Branch D listed "on-map convoy access" as forward intent. The mid-battle access mechanic is a real fork.
- **A — Prep-only in v1:** no mid-battle convoy access; convoy is a hub panel only. Simplest; defers
  the on-map mechanic (and any supply-unit/tile design) cleanly.
- **B — On-map access for all units** (Awakening-style): any unit may deposit/withdraw on its turn.
- **C — On-map access via a designated supplier** unit/tile (classic FE supply convoy).
- **Rec: A for v1** — keep convoy a prep panel; revisit B/C alongside on-map trade + the supplier
  concept. (No battle-time trade action exists in code today, so A adds nothing new to combat.)
- **Resolution:** _[OPEN]_

### [CNV-6] Convoy as the single shared item sink  **[OPEN]**
- **A — Yes:** convoy replaces `party_items` as the one shared store. Map rewards, enemy drops, and
  shop purchases without a target unit all land in convoy. No parallel loose-item list.
- **B — Keep `party_items` separate** from a managed convoy.
- **Rec: A** — one shared store is the clean model the firmed save-schema note anticipated; `party_items`
  migrates into the convoy entries (data growth, not a reshape). Retry snapshot covers the convoy.
- **Resolution:** _[OPEN]_

### [CNV-7] Stacking / display  **[OPEN]**
- **A — Stack identical full items by id** with a count badge (5× Vulnerary); partially-used items
  show separately or grouped by uses. Display-only over the CNV-1 entry list.
- **B — One row per entry**, no stacking.
- **Rec: A** — stacked display keeps a large convoy readable; storage stays per-entry. Low stakes.
- **Resolution:** _[OPEN]_

## 4. Notes
- **Save impact (§2):** convoy serializes as state-by-id entries (uses included) on the per-save
  party; replaces/absorbs `party_items`; covered by the Retry snapshot + integrity hash.
- **Pairs with equip-items (#3)** — equip entries already live in `InventoryEntry`; their lifecycle is
  a *separate* register, but they ride the same convoy store.
- DoD: GDD chapter + `GDD_Feature_Index` row + roadmap status flip land **with the build**, not now.
