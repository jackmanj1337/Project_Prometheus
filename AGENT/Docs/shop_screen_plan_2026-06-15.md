# Shop / Item-Purchase Screen — Implementation Plan

**Status:** Planned (approved 2026-06-15; implementation deferred)
**Last verified:** 2026-06-15
**Authority:** GDD_10 §1.0 Definition (D-D campaign prerequisites); GDD_04 §Items
**Depends on:** `campaign_rules_save_load_plan_2026-06-15.md` (persistent economy in the save)
**See also:** `campaign_prep_deployment_plan_2026-06-15.md` (shares the convoy)

## Context

A shop is the second D-D prerequisite for the 1.0 campaign. The economy primitives
already exist — `GameState.party_gold: int` and `party_items: Array[String]` (the
shared **convoy**), both save-snapshotted — and every `ItemData`/`WeaponData` carries
a `cost` field. What's missing is a buy/sell screen and the catalog data.

### Decision taken (2026-06-15)
**Per-shop authored inventory:** a `ShopData` resource lists the item/weapon ids for
sale at a given shop, so designers gate availability per chapter (FE-style varied
shops) rather than exposing every costed item everywhere.

### Adopted defaults (not asked)
- **Bought items land in the convoy** (`party_items`); distribution to units happens
  via deployment/trade (separate). Keeps the shop self-contained.
- **Sell price = `floor(cost / 2)`** (FE convention). Make it a future
  `CampaignRules` override (the contract already anticipates rule overrides) — noted,
  not built now.
- **Key items are not sellable** (`ItemData.type == "key"`); weapons/items otherwise
  sellable from the convoy.

## Key findings from exploration

- `ItemData.cost` (`scripts/resources/ItemData.gd:10`) and `WeaponData.cost`
  (`scripts/resources/WeaponData.gd:28`) already exist — pricing is data-driven.
- `DataManager.get_item(id)` / `get_weapon(id)` (`scripts/autoloads/DataManager.gd:597`,
  `:590`) resolve ids; `ItemData.type` includes a `"sellable"` and `"key"` taxonomy.
- `party_gold` / `party_items` are already serialized by the save/load plan and the
  Retry snapshot, so shop transactions persist for free once they mutate those fields.
- Map rewards already mutate the same fields (`TurnManager` ~line 997) — the shop is a
  second writer of the same economy, no new persistence needed.

## Design

1. **`ShopData` resource (`scripts/resources/ShopData.gd`,
   `class_name ShopData extends Resource`):** `@export var id: String`,
   `@export var stock_item_ids: Array[String]` (weapon or item ids), optional
   `@export var sell_multiplier_num/den` left out for v1 (use the floor(cost/2)
   constant). Authored `.tres` per shop under `data/shops/`.
2. **`ShopScreen` (`scripts/ui/ShopScreen.gd` + scene):** two tabs/panels — **Buy**
   (lists `stock_item_ids` with name + cost, greyed when `party_gold < cost`) and
   **Sell** (lists the convoy `party_items`, each with its sell value, key items
   excluded). A gold readout updates live. Reuse the `ModalScreen` base.
3. **Transaction logic (a small `ShopController` RefCounted, headless-testable):**
   - `buy(id)`: look up cost; if `party_gold >= cost`, `party_gold -= cost` and append
     `id` to `party_items`. Returns success.
   - `sell(index)`: read `party_items[index]`; reject if key item; else
     `party_gold += floor(cost/2)` and remove it.
   Pure data ops on `GameState` so they unit-test without UI.
4. **Entry point:** a Shop button on the between-map prep flow, driven by the
   `ShopData` named by the current `progress` step (from the save/load plan's progress
   model). A map-tile "Armory/Vendor" interaction is a later extension.

## Tests (headless, glob-discovered)
- **`test_shop.gd`** (new): `buy` deducts gold + adds to convoy; `buy` with
  insufficient gold is rejected and mutates nothing; `sell` adds `floor(cost/2)` and
  removes the item; selling a key item is rejected; an unknown id is handled, not
  crashed. Drive `ShopController` against a stubbed `GameState`.
- Round-trip with the save/load plan: a buy/sell then `SaveManager.save→load`
  preserves the new `party_gold` / `party_items` (covered by `test_save_manager`).

## Documentation (DoD#1)
- GDD_04 §Items: shop buy/sell rules, sell = floor(cost/2), key-item exclusion.
- GDD_07 §UI: the Shop screen surface.
- GDD_10: flip the D-D "shop / item-purchase screen" prerequisite to Implemented.
  Bump `Last verified`.
- DoD#2: a "every ShopData stock id resolves in DataManager" validator is a good
  candidate for `DataManager.validate_*` (mirrors the existing reward-item validation
  at `DataManager.gd:327`); add it if the rule is ratified.

## Out of scope
- Forging / weapon upgrade UI (Phase 3 backlog, separate).
- Per-unit purchasing direct-to-inventory (goes through convoy + trade instead).
- Dynamic/limited stock, restocking, or price scaling.

## Verification
- Headless `bash run_tests.sh` green incl. `test_shop`.
- Live: open a shop with a known `ShopData`, buy an item (gold drops, item in convoy),
  sell it back (gold rises by half), confirm a key item can't be sold; save + Continue
  preserves the gold/convoy state.
