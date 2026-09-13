---
Role: dated
Type: plan
Status: Superseded in part 2026-08-18 — the data and service layer stands; the panel, the selector abstraction and the on-map presentation move to PREP-V1
Last verified: 2026-08-18
Decision source: ../design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md (EPUX-16, EPUX-17); ../registers/shop_economy_open_questions_2026-06-23.md (SHP-1..6); ../registers/distribution_surface_open_questions_2026-08-15.md (DSX-S1..S3, DSX-S16, DSX-S17)
Tracker: B4-SHOP-ECONOMY-2026-07-23, BAND4-PREP-V1-BOUNDARY-2026-08-18-2026-08-18
---

# Band 4 Shop Economy Implementation Plan

> **Superseded in part — owner ruling 2026-08-18, `R1` §9.3.** This plan was last verified
> 2026-06-30, before `EPUX` (07-26), `TSV`, `CUR`, `SHC` (08-13) and `DSX` (08-15). It and
> `PREP-V1-S05` were both building the shop, from plans seven weeks apart, **with no dependency
> edge in either direction**. The boundary is now drawn:
>
> **This row keeps the data and service layer** — resource-keyed cost/yield, the stock schema,
> conditional stock and dynamic pricing over the shopper subject, sell-price formulae
> (`[SHP-6]`), buy routing to shopper-then-convoy, and the `shop` tile-action declaration. It is
> now an **upstream dependency of `PREP-V1-S05`**.
>
> **Three things move out**, each to a home ratified since:
>
> | Moves | To | Why |
> |---|---|---|
> | §Scope 5 — "a rough keyboard+mouse-first `B3-PHB` shop panel using the shared selector/detail-pane abstraction" | `PREP-V1-S02` (shell) + `PREP-V1-S05` (shop adapter) | `[DSX-S1..S3]` — one shell, N registered adapters, holder · pool · detail, shell-owned verb slot. The shop is a data block, not a screen. |
> | §Scope 7 — on-map shop **presentation** | `PREP-V1-S06` + `[DSX-S16]`/`[DSX-S17]` | Map placement is a general property of *any* Explore activity, not a shop capability; the on-map surface takes the canvas region only, with a context-declared verb set. The **tile-action declaration** stays here. |
> | §Scope 2 — quote/commit **through `ResourceLedger`** | `PREP-V1-S05` | `ResourceLedger` is a wallet, not the `[TSV-3]` transaction core; the prep/economy plan **deletes `ResourceLedger.reserve()`** and `CostSpec.allow_partial`, both of which have zero callers and are contradicted by ratified rulings. |
>
> **And one correction that is not a move — read it before writing the schema.** The Non-Goals
> below still say *"do not build limited stock/restocking quantities in the first v1 shop pass …
> stock is author-defined and infinite unless a later slice explicitly adds persistent stock
> state."* **That deferral is dead.** `[EPUX-16]` (owner, 2026-07-25) ruled option **C pulled
> forward and generalized**: because `[EPUX-01]`'s revisitable overworld nodes require a defined
> second-visit behaviour, *"shop nodes persist stock and restock on an author-defined cadence,
> defaulting to infinite/non-scarce so simple campaigns stay simple."*
>
> **Infinite is the default value, not a shipping stage.** The restocking store is the end state,
> and the way to fail it is to ship a stock schema here that cannot carry **durable per-shop
> counts** — retrofitting persistence into a schema that never had it is the expensive path, and
> it is the one this plan's original wording leads to. `PREP-V1-S05` makes stock a first-class
> named entity subscribing to the cadence trigger engine built at `PREP-V1-S01`; **this plan owes
> that entity a schema it can save.** See `EPUX` §Node traversal and cadence model — stock is one
> subscriber of four, not a shop feature.

**Started:** 2026-06-30.

**Track ID:** `B4-SHOP-ECONOMY`

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 4 rows. Drafted from
[`band4_implementation_plan_handoff_2026-06-30.md`](band4_implementation_plan_handoff_2026-06-30.md).

## Purpose

Turn the resolved shop/economy model into a code-ready build sequence. Shops are
the first major resource sink and the first concrete consumer that ties together
PHB panels, resource-ledger quotes, item definitions, shopper-subject predicates,
and convoy overflow.

This plan is a build plan only. It does not authorize starting
`B4-SHOP-ECONOMY` before the Band 1-3 gates, `B4-IEQ`, and `B4-CONVOY` land.

## Scope

This plan covers the first shop/economy implementation run:

1. Add resource-keyed shop config and stock entries. **Amended 2026-08-18: the stock entry
   carries a durable per-shop count**, defaulting to the `unlimited` sentinel. `[EPUX-16]`.
2. ~~Add shop transaction quoting and committing through `ResourceLedger`.~~ **Moved to
   `PREP-V1-S05`** — `ResourceLedger` is a wallet, not the `[TSV-3]` transaction core, and
   `reserve()` is deleted there. This plan supplies the price and stock *data* the core quotes
   over.
3. Add dynamic pricing and conditional stock over the shopper subject. **Stands**, refined by
   `[EPUX-17]`'s final-price-in-list / formula-in-detail split.
4. Add buy/sell support with v1 gold fixtures, while keeping the data shape
   multi-resource. **Stands, and the multi-resource shape is now load-bearing**: `CUR-1..7`
   ruled multi-currency, so "gold only" is a fixture, never a schema.
5. ~~Build a rough keyboard+mouse-first `B3-PHB` shop panel using the shared
   selector/detail-pane abstraction from the convoy plan.~~ **Moved to `PREP-V1-S02`
   (shell) + `PREP-V1-S05` (adapter)** — `[DSX-S1..S3]`.
6. Route buys to shopper first, then convoy overflow; add an author override for
   direct-to-convoy prep shops. **Stands.**
7. Add on-map shop trigger integration through `B4-MAP-OBJECTS`. **Split**: the `shop`
   tile-action declaration stays here; the on-map **presentation** moves to `PREP-V1-S06`'s
   general map placement, under `[DSX-S16]`/`[DSX-S17]`.
8. Reserve the dialogue command hook without forcing the dialogue runtime into
   the first shop slice. **Stands.**

## Non-Goals

- Do not build forging, repair shops, arena bets, training halls, or bonus-EXP
  spending here.
- ~~Do not build limited stock/restocking quantities in the first v1 shop pass.
  Stock is author-defined and infinite unless a later slice explicitly adds
  persistent stock state.~~ **RETIRED 2026-08-18 — this is the one Non-Goal that had to go.**
  `[EPUX-16]` pulled restocking *forward*, because `[EPUX-01]`'s revisitable nodes require a
  defined second-visit behaviour. **The restocking store is the end state.** Infinite is the
  **default value** of an author-set quantity, not a stage to be replaced later. This plan ships
  the schema that can carry durable counts; `PREP-V1-S05` makes stock a first-class entity
  subscribing to the cadence engine at `PREP-V1-S01`.
- Do not mutate `party_gold` or any wallet directly; all affordability and
  commits go through the transaction core (**was**: `ResourceLedger`; see scope item 2).
- Do not build a separate shop UI stack. Shop is a PHB panel and on-map panel
  trigger consumer. **Restated 2026-08-18 and now stronger**: the shop is an **adapter on the
  one distribution shell**, and `[DSX-S1]`'s escape hatch is *declared*, never improvised —
  widen the shell for everyone or use the declared opt-out, never a bespoke screen.
- Do not build polished UI or full control-scheme support; `B6-INPUT` owns that
  follow-up.
- ~~Do not add saved shop stock unless persistent stock/restock is pulled into
  scope with F1 rows.~~ **RETIRED with the bullet above** — it *was* pulled into scope, on
  2026-07-25. Saved stock counts are named in the prep/economy plan's save contract.

## Source Docs

- [`band4_implementation_plan_handoff_2026-06-30.md`](band4_implementation_plan_handoff_2026-06-30.md)
- [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
- [`shop_economy_open_questions_2026-06-23.md`](../registers/shop_economy_open_questions_2026-06-23.md)
  (`SHP-1..6`)
- [`shop_activate_configs_open_questions_2026-06-27.md`](../registers/shop_activate_configs_open_questions_2026-06-27.md)
  (`SAC-5..9`)
- [`convoy_inventory_open_questions_2026-06-23.md`](../registers/convoy_inventory_open_questions_2026-06-23.md)
- [`resource_ledger_cost_resolver_contract_2026-06-28.md`](../design/resource_ledger_cost_resolver_contract_2026-06-28.md)
- [`prep_hub_open_questions_2026-06-23.md`](../registers/prep_hub_open_questions_2026-06-23.md)
- [`band4_items_equipment_implementation_plan_2026-06-30.md`](band4_items_equipment_implementation_plan_2026-06-30.md)
- [`band4_convoy_implementation_plan_2026-06-30.md`](band4_convoy_implementation_plan_2026-06-30.md)
- [`band4_map_objects_implementation_plan_2026-06-30.md`](band4_map_objects_implementation_plan_2026-06-30.md)

## Decisions Not To Reopen

- Price data is resource-keyed cost/yield, not a single gold int plus sell
  percentage.
- V1 populates gold only, but the schema supports multiple resource ids.
- Shops support both buy and sell.
- Stock is author-defined per shop, mixed weapons/items, ~~infinite quantity in
  v1~~ **with an author-set quantity whose default is the `unlimited` sentinel**
  (`[EPUX-16]` 2026-07-25, `[DSX-S19]` for how the sentinel renders — a hatched
  bar, not a fraction, because "62 items · uncapped" has no denominator).
- Every shop session has a shopper. Prep shops require selecting a shopper
  before opening; on-map shops use the activating unit.
- Buy destination is shopper first, convoy overflow second. Author may route a
  prep shop directly to convoy for bulk buying.
- Conditional stock and dynamic pricing use `B3-REQ` / `REQ-16` over the shopper
  subject.
- Sell price is a **campaign-default author-set formula** (`[SHP-6]`, owner
  2026-07-02): a `REQ-16` value term over the item, default **50% of value ×
  percent durability remaining** (no-durability items sell at the full formula
  result). Each shop may declare an **incoming-price modifier** formula applied
  to sells, symmetric with the outgoing buy-side modifiers. Stock-entry
  `sell_yields` is an optional per-entry override of the campaign formula
  result, applied before the shop incoming modifier.
- Dialogue-wrapped shops use a dialogue command that launches the same shop
  panel; no shop-specific conversation system.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates before
`B4-SHOP-ECONOMY` code:

- `B2-RESOURCE-LEDGER` and `B3-RESOURCE-POOLS` for resource-keyed wallet quote
  and commit.
- `B3-PHB` for the shop panel container.
- `B3-REQ` and `REQ-16` for stock gates and price modifiers.
- `B4-IEQ` for `ItemDef` ids, value/cost fields, sellability/story flags, and
  `InventoryEntry` instances.
- `B4-CONVOY` for overflow and direct-to-convoy shop destinations.
- `B4-MAP-OBJECTS` before on-map shops.

`B4-DIALOGUE-V1` is required only for the dialogue command integration slice.

## Existing Code Touchpoints

Verified 2026-06-30:

- `scripts/resources/WeaponData.gd` and `scripts/resources/ItemData.gd` have
  `cost` fields; `B4-IEQ` moves value data to `ItemDef`.
- `scripts/autoloads/GameState.gd` owns `party_gold`, and the Band 3 plan
  generalizes it into a keyed resource wallet.
- `scripts/core/TurnManager.gd` grants `reward_gold`; there are no runtime gold
  sinks today.
- No shop scene/script exists.
- `scripts/shared/TileActions.gd` lists `shop`, but it is a placeholder until
  `B4-MAP-OBJECTS` supplies dynamic object actions.
- `B3-PHB` is planned as the panel container; concrete shop panels are Band 4
  consumers.
- Existing tests to extend first: `test_resource_pools.gd`,
  `test_data_manager.gd`, `test_tile_actions.gd`, `test_action_menu.gd`,
  `test_game_state.gd`, plus new shop-focused suites.

## Slice 0 - Preflight After Gates

**Goal:** confirm the wallet, item, convoy, and PHB foundations are ready.

Implementation checklist:

- Run `rg -n "party_gold|ResourceLedger|cost|sellable|shop|prep_panels|TileActions|party_convoy|InventoryEntry" scripts data`.
- Confirm F1 rows exist for the roster multi-resource wallet and convoy store.
- Confirm `ResourceLedger.quote()` and `commit()` support party-scoped costs.
- Confirm `B4-CONVOY` exposes `give_item_to_unit_or_convoy()` or equivalent.
- Confirm `PanelSelector` (and the `SelectionCursor` core it is built on) exists
  from the convoy plan, or schedule it as the first shared UI slice before shop
  UI. Per the 2026-07-01 review Q11, `PanelSelector` wraps the pure
  `SelectionCursor` navigation core (Component 1 of the selector-extraction
  design), which lands in Band 4; the shop reuses both.
- Decide whether the first shop slice is prep-only. Recommended first build is
  prep shop first, then on-map shop once `B4-MAP-OBJECTS` is ready.

Tests: none required in preflight.

## Slice 1 - Shop Config And Stock Data

**Goal:** represent shops and stock as author data with resource-keyed pricing.

Files to create or touch:

- `scripts/resources/shop/ShopConfig.gd`
- `scripts/resources/shop/ShopStockEntry.gd`
- `scripts/autoloads/DataManager.gd`
- registry preset data for PHB panel type and shop config refs
- `scripts/tests/test_shop_config.gd`

Implementation steps:

1. Add `ShopConfig` with `id`, `label_key`, `stock`, optional category/group
   display data, `destination_mode`, an optional `incoming_price_modifier`
   (`REQ-16` value term applied to sells, symmetric with the buy-side
   modifiers), and optional named theme/presentation refs.
2. Add `ShopStockEntry` with `item_def_id`, `buy_costs`, optional `sell_yields`
   (per-entry override of the campaign sell formula, `[SHP-6]`),
   optional `stock_gate`, `stock_unavailable_mode`, and optional dynamic price
   modifiers.

   **Amended 2026-08-18 — this is the field the original plan did not have, and the reason the
   boundary ruling exists.** The entry also carries a **`quantity`** (author-set, defaulting to
   the `unlimited` sentinel) and a **restock cadence reference**. Both are *schema* here; the
   behaviour is `PREP-V1-S05`'s, subscribing to the cadence trigger engine built at
   `PREP-V1-S01`. Ship the field even while every fixture authors `unlimited` — a stock schema
   with no place to put a count is what makes the restocking store a retrofit instead of a
   default, and `[EPUX-16]` ruled the restocking store the end state on 2026-07-25.

   **Amended again 2026-08-18 by `[CVS-S6]`, which gave the reference its semantics.** The cadence
   reference belongs on the **stock entity**, with the per-entry field as an **optional override**
   for the one-off rare item — one pool depleting across the on-map storefront and the Explore-tab
   shop cannot restock on two schedules (`[EPUX-16]`). A tick **resets** the count to the authored
   quantity by default, with **increment by N up to that quantity as a ceiling** author-selectable;
   **re-roll of the entry set is out of v1** because a randomized offer makes stock depend on `RNG`
   policy, seeded runs and the determinism rules. Two further stock rulings bind the presentation
   this schema feeds: `[CVS-S5]` makes remaining stock a seventh `[DSX-S19]` cap, with the
   after-action projection required only when the stock is finite, and `[CVS-S7]` makes restock
   **disclosure** an author-declared per-shop field defaulting to off, phrasable only for the
   counter trigger families. A sold-out entry is a gated row under `[EPUX-07]`, never a hidden one.
3. Make `buy_costs` and `sell_yields` dictionaries keyed by resource id/scope.
4. Add the campaign-default sell formula as a `CampaignRules` field
   (e.g. `sell_formula`, a `REQ-16` value term over the item subject) with the
   built-in default preset `0.5 × value × durability_pct`
   (`durability_pct = uses_remaining / max_uses`; `1.0` for no-durability
   items). The formula scales each resource amount of the item's resource-keyed
   value, so multi-resource yields need no reshape.
5. Validate item ids through `B4-IEQ`, resource ids through the resource
   registry, predicates through `B3-REQ`, and price formulas (including
   `sell_formula` and `incoming_price_modifier`) through `REQ-16`.
6. Seed one gold-only test shop fixture.

Tests:

- A data-defined shop loads without an engine switch edit.
- Unknown item id, resource id, predicate id, or formula term fails validation.
- Mixed weapon/item stock validates through `ItemDef`.
- Gold-only fixtures use the same resource-keyed shape as multi-resource data.

F1 obligations: **amended 2026-08-18** — the `ShopStockEntry.quantity` field is authored data,
but a *depleted* count is saved state, so this slice reserves the save key rather than
declaring none. `PREP-V1-S05` writes it. (`[EPUX-16]`; the original line read "no saved state
for infinite v1 stock", which was true only under the retired Non-Goal.)

DoD#2 obligations: add validation that shop stock references registry-backed
resource ids and item defs.

## Slice 2 - Shop Quote And Transaction Service

**Goal:** centralize buy/sell affordability and commits through
`ResourceLedger`.

Files to create or touch:

- `scripts/shop/ShopService.gd`
- `scripts/shop/ShopTransactionResult.gd` or a simple result dictionary helper
- `scripts/autoloads/ResourceLedger.gd`
- `scripts/tests/test_shop_transactions.gd`

Implementation steps:

1. Add `quote_buy(shop, stock_entry, shopper, ctx)` and
   `commit_buy(shop, stock_entry, shopper, ctx)`.
2. Add `quote_sell(entry, seller, ctx)` and `commit_sell(entry, seller, ctx)`.
   Sell-yield resolution order (`[SHP-6]`): matching stock-entry `sell_yields`
   override if present, else the `CampaignRules.sell_formula` result over the
   item's value and durability; then apply the shop's
   `incoming_price_modifier`. Any sellable inventory item quotes a price —
   membership in the shop's stock list is not required to sell.
3. Use `ResourceLedger.quote()` for UI affordability and
   `ResourceLedger.commit()` for final mutation.
4. Apply dynamic price modifiers before quote and record the resolved cost in
   the transaction result so refunds/debug logs do not recalculate it.
5. Failed commits must not mutate wallets, inventory, or convoy.
6. First v1 sell source is the shopper inventory. A prep-only convoy sell tab
   can be added after the convoy panel is stable, but on-map shops must not
   browse/withdraw convoy.

Tests:

- Affordable buy spends gold and returns a structured transaction result.
- Shortfall buy mutates nothing.
- Sell credits the wallet and removes the sold entry from the seller.
- An item in no stock entry of the shop sells at the campaign formula price.
- A half-durability weapon sells for half its full-durability yield under the
  default formula; a no-durability item sells at the undiscounted result.
- A stock-entry `sell_yields` override wins over the campaign formula; the
  shop `incoming_price_modifier` applies in both cases.
- Key/story/non-sellable items are rejected.
- Dynamic price quote equals commit for the same shopper/context (both
  directions).

F1 obligations: wallet rows are owned by `B3-RESOURCE-POOLS`; shop stock rows land **when a
shop authors a finite quantity**, which `[EPUX-16]` made a default-off field rather than a
deferred feature (*was*: "no shop stock rows unless persistent stock lands").

## Slice 3 - Destination And Convoy Overflow

**Goal:** route bought items to the right inventory destination.

Files to touch:

- `scripts/shop/ShopService.gd`
- `scripts/convoy/ConvoyService.gd`
- `scripts/tests/test_shop_destinations.gd`

Implementation steps:

1. Create a bought `InventoryEntry` through `B4-IEQ` helpers.
2. Route to shopper first using `ConvoyService.give_item_to_unit_or_convoy()`.
3. Support an author `destination_mode = "convoy"` for bulk prep shops.
4. Return a transaction result that names the final destination:
   `shopper_inventory`, `convoy_overflow`, or `convoy_direct`.
5. Roll back resource spend if destination placement fails.

Tests:

- Shopper with space receives the item.
- Full shopper routes item to convoy.
- Full finite convoy rolls back the purchase.
- Direct-to-convoy shop skips the shopper inventory.
- Destination results are stable for UI messages.

F1 obligations: no new saved fields beyond wallet/convoy mutation.

## Slice 4 - Prep Shop Panel Skeleton

**Goal:** build the rough PHB shop panel for prep shops.

Files to create or touch:

- `scripts/ui/panels/ShopPanel.gd`
- `scenes/ui/panels/ShopPanel.tscn`
- `scripts/ui/shared/PanelSelector.gd`
- `scripts/ui/shared/FocusedDetailPane.gd`
- PHB panel registry data
- `scripts/tests/test_shop_panel.gd`

Implementation steps:

1. Register a `shop` PHB panel type.
2. Add a shopper selection step before opening the stock list.
3. Add buy and sell views. Minimum sell view lists shopper inventory; a convoy
   sell source can follow once the convoy panel's grouping/detail logic is
   reusable.
4. Use `PanelSelector` for stock rows and sell rows.
5. Show detail pane data for the focused item and a ResourceLedger quote summary
   for the focused transaction.
6. Disable or hide rows according to stock gate policy.
7. Commit transactions immediately to party state; no PHB UI state is saved.

Tests:

- Prep node with a shop panel opens the shopper picker first.
- Focused stock row updates item detail and quoted price.
- Buy button calls `ShopService.commit_buy()`.
- Sell button calls `ShopService.commit_sell()`.
- Gated stock honors hidden vs disabled display policy where the rough UI
  supports it.

F1 obligations: no saved UI state.

DoD#2 obligations: add a test that shop UI consumes `PanelSelector`, avoiding a
second private selector implementation.

## Slice 5 - Dynamic Pricing And Conditional Stock

**Goal:** make shopper-dependent shop behavior real and testable.

Files to touch:

- `scripts/shop/ShopService.gd`
- `scripts/resources/shop/ShopStockEntry.gd`
- `scripts/tests/test_dynamic_shop_rules.gd`

Implementation steps:

1. Bind the shopper as the primary `B3-REQ` subject.
2. Evaluate stock gates before rendering stock.
3. Evaluate dynamic price modifiers through `REQ-16` value terms over the
   shopper — buy-side modifiers on quotes/commits of buys, and the shop
   `incoming_price_modifier` on quotes/commits of sells (`[SHP-6]` symmetry).
4. Clamp or reject invalid prices according to the ResourceLedger cost policy.
5. Keep default behavior flat and author-optional.

Tests:

- High-stat shopper receives the authored discount or markup.
- Stock gated by shopper item/tag/flag appears or hides correctly.
- Disabled gated stock cannot be bought.
- Missing shopper fails validation for prep shop launch.

F1 obligations: no new saved fields; gates read existing campaign/unit state.

## Slice 6 - On-Map Shop Trigger

**Goal:** expose shops through `B4-MAP-OBJECTS` without a second shop system.

Files to touch:

- `scripts/map_objects` panel-trigger handlers from the map-object plan
- `scripts/shop/ShopService.gd`
- `scripts/ui/panels/ShopPanel.gd`
- `scripts/tests/test_on_map_shop.gd`

Implementation steps:

1. Add a `panel_trigger` config that references a shop id or inline shop config.
2. Bind the activating unit as the shopper.
3. Apply the object action cost policy: consumes action by default, author
   `free` flag can override.
4. Reuse the same `ShopPanel` scene and `ShopService`.
5. Prevent on-map shops from browsing convoy for withdrawals; overflow to convoy
   remains allowed.

Tests:

- On-map shop action opens the same shop panel with activator as shopper.
- Buy uses activator inventory then convoy overflow.
- Default action-cost policy marks the unit done after the transaction/session
  closes, according to the map-object action result.
- Prep shop and on-map shop share transaction tests.

F1 obligations: shop config is authoring; object used/toggled state is owned by
`B4-MAP-OBJECTS` if the map object persists it.

## Slice 7 - Dialogue Command Hook

**Goal:** reserve and then wire `shop` as a dialogue command once
`B4-DIALOGUE-V1` exists.

Files to touch:

- dialogue command registry from `B4-DIALOGUE-V1`
- `scripts/shop/ShopService.gd`
- `scripts/ui/panels/ShopPanel.gd`
- `scripts/tests/test_dialogue_shop_command.gd`

Implementation steps:

1. Register a `shop` dialogue command that launches a shop panel by id or inline
   config.
2. Carry the shopper subject into the dialogue context.
3. Return to dialogue after the atomic shop panel closes.
4. Keep dialogue-specific branch/pacing behavior in the dialogue runtime, not in
   shop code.

Tests:

- Dialogue command launches the same shop service/panel.
- Shopper context is preserved for dynamic pricing.
- Closing the shop resumes or completes the dialogue according to
  `B4-DIALOGUE-V1` atomic playback rules.

F1 obligations: no shop-specific save state.

## Slice 8 - Cleanup And Economy Guards

**Goal:** prevent wallet and shop drift after the first implementation.

Implementation checklist:

- Remove direct shop-side `party_gold` mutations if any appeared during
  migration.
- Update docs and fixtures so item `cost` is only the gold buy amount projection
  of the resource-keyed price data, and sell prices flow only from the
  `[SHP-6]` pipeline (campaign formula / stock override / incoming modifier) —
  no hardcoded sell percentage anywhere.
- Add a validation fixture for unknown resource ids and unknown item ids.
- Run full Godot suite and docs checks.

DoD#1 obligations: update `GDD_01`, `GDD_04`, `GDD_07`,
`GDD_Feature_Index`, and `GDD_10` in the behavior-changing commit.

DoD#2 obligations: add a test/check that shop transactions use
`ResourceLedger`, not direct wallet mutation.

## Verification Checklist

Same as the Band 2/3 plans. Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
git diff --check
```
