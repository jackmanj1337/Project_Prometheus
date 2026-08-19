---
Type: plan
Status: Superseded in part 2026-08-18 — the convoy store and service stand; the panel and the shared selector abstraction move to PREP-V1
Last verified: 2026-08-18
Decision source: ../registers/convoy_inventory_open_questions_2026-06-23.md (CNV-1..8); ../registers/distribution_surface_open_questions_2026-08-15.md (DSX-S1..S3, DSX-S19, DSX-S21)
Tracker: B4-CONVOY-2026-07-23, BAND4-PREP-V1-BOUNDARY-2026-08-18-2026-08-18
---

# Band 4 Convoy Implementation Plan

> **Superseded in part — owner ruling 2026-08-18, `R1` §9.3.** Same boundary as
> [`band4_shop_economy_implementation_plan_2026-06-30.md`](band4_shop_economy_implementation_plan_2026-06-30.md),
> and less urgent only because an edge already exists: `PREP-V1-S03` depends on this row, so the
> *order* was never lost — the **boundary** was undrawn.
>
> **This row keeps the store and the service**: the `InventoryEntry` convoy store replacing
> `GameState.party_items`, `ConvoyService` (deposit, withdraw, transfer, overflow, capacity
> checks, reward routing), `max_inventory`/`convoy_capacity` enforcement with the story/key-item
> exemption, and the death-disposition and campaign-loop hooks.
>
> **Two scope items move out:**
>
> | Moves | To | Why |
> |---|---|---|
> | §Scope 5 — "a rough keyboard+mouse-first `B3-PHB` convoy panel with the `CNV-8` required functions" | `PREP-V1-S02` (shell) + `PREP-V1-S03` (convoy adapter) | `[DSX-S1..S3]`. `CNV-8`'s author-selected field set survives as `[DSX-S23]`'s priority order truncated per size class — the authoring lever is kept, not discarded. |
> | §Scope 6 — "the shared thin selector/detail-pane abstraction that the shop plan also consumes" | `PREP-V1-S02` | This sentence **is** the distribution shell, written before it was ruled. It is the one thing that must not be built twice: nine consumers depend on there being exactly one. |
>
> **What `PREP-V1-S03` adds on top**, and therefore what this plan need not anticipate: stable
> `InventoryEntry` instance ids (absent from the tree today, and required by four ratified
> rulings), the pending-items tray as a holder-region section, `[DSX-S24]`'s bulk-operation
> result panel, and effective-state display stacking.

**Started:** 2026-06-30.

**Track ID:** `B4-CONVOY`

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 4 rows. Drafted from
[`band4_implementation_plan_handoff_2026-06-30.md`](band4_implementation_plan_handoff_2026-06-30.md).

## Purpose

Turn the resolved convoy model into a code-ready build sequence. Convoy is the
party inventory store and the overflow destination for item growth sites. It is
also the first concrete `B3-PHB` service panel that must be useful enough for a
campaign-loop playtest.

This plan is a build plan only. It does not authorize starting `B4-CONVOY`
before the Band 1-3 gates and `B4-IEQ` item foundation land.

## Scope

This plan covers the first convoy implementation run:

1. Replace the flat `GameState.party_items: Array[String]` reward list with a
   state-preserving convoy store of `InventoryEntry` instances.
2. Add a small `ConvoyService` API for deposit, withdraw, unit-to-unit transfer,
   overflow, capacity checks, stacking display data, and reward routing.
3. Enforce `CampaignRules.max_inventory` at item growth sites and route overflow
   to convoy.
4. Add `CampaignRules.convoy_capacity` with default unlimited and story/key-item
   exemption.
5. ~~Build a rough keyboard+mouse-first `B3-PHB` convoy panel with the `CNV-8`
   required functions.~~ **Moved to `PREP-V1-S02` (shell) + `PREP-V1-S03` (convoy adapter)**,
   2026-08-18 — `[DSX-S1..S3]`. `CNV-8`'s required functions survive as adapter obligations.
6. ~~Add the shared thin selector/detail-pane abstraction that the shop plan also
   consumes and `B6-INPUT` later fills out.~~ **Moved to `PREP-V1-S02`** — this sentence is the
   distribution shell, described a month and a half before `[DSX-S1]` ruled it. Nine consumers
   share it, so it is built once, there.
7. Add hooks for death-disposition and campaign-loop consumers without building
   their full features here.

## Non-Goals

- Do not build on-map convoy access in v1. Mid-battle unit-to-unit trade,
  convoy units, and per-unit convoy actions are later mechanics.
- Do not build the shop panel here. The convoy panel exposes the destination and
  transfer APIs shop calls. **Restated 2026-08-18: neither panel is built here.** Both are
  adapters on the one distribution shell at `PREP-V1-S02`; what this row exposes is the
  service.
- Do not build polished UI or full control-scheme support. The first panel is
  functional and keyboard+mouse-first; `B6-INPUT` owns gamepad/key-rebind polish.
- Do not add a quantity-only convoy store. Storage preserves item instance
  state; stacking is display-only.
- Do not add saved convoy fields without F1 manifest rows first.
- Do not create a second loose-item list beside convoy.

## Source Docs

- [`band4_implementation_plan_handoff_2026-06-30.md`](band4_implementation_plan_handoff_2026-06-30.md)
- [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
- [`convoy_inventory_open_questions_2026-06-23.md`](../registers/convoy_inventory_open_questions_2026-06-23.md)
  (`CNV-1..8`)
- [`prep_hub_open_questions_2026-06-23.md`](../registers/prep_hub_open_questions_2026-06-23.md)
  (`PHB-1..7`)
- [`items_equipment_model_open_questions_2026-06-23.md`](../registers/items_equipment_model_open_questions_2026-06-23.md)
  (`IEQ-1..9`)
- [`band4_items_equipment_implementation_plan_2026-06-30.md`](band4_items_equipment_implementation_plan_2026-06-30.md)
- [`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](band3_core_authoring_foundations_implementation_plan_2026-06-30.md)

## Decisions Not To Reopen

- Convoy storage is `Array[InventoryEntry]`, not `{item_id: count}`.
- `party_items` migrates into convoy; convoy becomes the single shared item
  store.
- `CampaignRules.max_inventory` is author-defined and enforced at growth sites.
- Overflow routes to convoy.
- Convoy is prep-only in v1.
- Prep convoy management is unrestricted across the active roster of the
  controlled faction.
- Convoy capacity is an author rule with default unlimited; story/key items do
  not count against capacity. **Amended 2026-08-18 by `[CVS-S1]` and `[CVS-S2]`.** Capacity
  **counts instances, not stack rows**: five identical vulneraries are one displayed row and five
  units of capacity, so a stacked row reading `×5` and a cap figure reading five agree, and
  `[DSX-S20]`'s projection stays computable. Stack-counting was rejected because spending one use
  of one copy would split an `[EPUX-10]` stack and move a cap figure with no action in the surface.
  And the exemption is no longer a *class* test: **capacity-exempt is a per-instance property**,
  one of four that the "key item" authoring preset sets together (with unsellable `[SHP-2]`,
  bulk-transfer-excluded `[EPUX-12]`, and the `[DTH-5]` disposition chain). Step 2's "excludes
  story/key items" therefore reads the instance property, not an item type.
- Stacking is display-only over state-preserving entries. **Note (2026-08-18):** because
  `[CVS-S2]`'s properties are per instance, they enter `[EPUX-10]`'s effective-state stacking key —
  a story-critical copy never stacks with an ordinary one.
- The first convoy panel must include per-character inventory, author-defined
  groups plus "All", author sorting, author-selected row fields, and a focused
  item detail pane. **Still binding, but as `PREP-V1-S03`'s adapter obligations** — this is
  `CNV-8`, not a licence to draw a panel here (2026-08-18). `[DSX-S23]` resolves the collision
  the responsive programme created with the last item: the author supplies a row-field
  **priority order** and the size class truncates it against a per-class budget, so the
  authoring lever is kept rather than either discarded or allowed to break the 360x640 floor.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates before `B4-CONVOY` code:

- `B1-F1`, `B1-SAVECODEC`, and `B1-CST` for convoy save rows, map reward
  persistence, Retry/suspend behavior, and CampaignRules access.
- `B3-PHB` for the prep-panel container and immediate transaction semantics.
- `B4-IEQ` through at least the `InventoryEntry.def_id` compatibility scaffold,
  so convoy entries can preserve item instance state.
- `B3-REQ` only for author-gated panel availability or row filters; the core
  store does not need private predicate logic.

`B2-DEATH-LIFECYCLE` is not required for the first convoy store/panel slice, but
the death-disposition integration slice must wait for it.

## Existing Code Touchpoints

Verified 2026-06-30:

- `scripts/autoloads/GameState.gd` owns `party_items: Array[String]`,
  `party_gold: int`, `max_inventory`, and Retry snapshots for party items/gold.
- `scripts/core/TurnManager.gd` `_apply_victory_rewards()` appends
  `MapData.reward_items` ids into `party_items`.
- `scripts/resources/MapData.gd` exposes `reward_items: Array[String]`.
- `scripts/resources/CampaignRules.gd` has `max_inventory: int = 8`, but it is
  not enforced.
- `scripts/resources/InventoryEntry.gd` is already the per-slot item instance
  type, with `uses_remaining` and `forged_mods`.
- `scripts/ui/ItemMenu.gd` and `scripts/ui/WeaponMenu.gd` are small list-menu
  patterns, but they are battle menus, not PHB panels.
- Existing tests to extend first: `test_game_state.gd`,
  `test_snapshot_coverage.gd`, `test_data_manager.gd`, `test_action_menu.gd`,
  `test_unit_details_screen.gd`, plus new convoy-focused suites.

## Slice 0 - Preflight After Gates

**Goal:** confirm the item, save, and PHB foundations are ready.

Implementation checklist:

- Run `rg -n "party_items|reward_items|max_inventory|InventoryEntry|uses_remaining|forged_mods|prep_panels" scripts data`.
- Confirm F1 rows exist or reserve them before code:
  `party_convoy`, map-start convoy snapshot, `CampaignRules.convoy_capacity`,
  and compatibility migration from `party_items`.
- Confirm `B4-IEQ` has a stable `InventoryEntry.def_id` path or an adapter that
  can create unified entries from old item/weapon ids.
- Confirm `B3-PHB` can register a concrete panel type and launch it from prep.
- Decide which commits are behavior-changing. The store migration and cap
  enforcement are behavior changes and must update `GDD_01`, `GDD_04`,
  `GDD_07`, `GDD_Feature_Index`, and `GDD_10` with the build.

Tests: none required in preflight.

## Slice 1 - Convoy Store And Migration

**Goal:** replace `party_items` with a state-preserving convoy store while
keeping existing map rewards working.

Files to create or touch:

- `scripts/autoloads/GameState.gd`
- `scripts/convoy/ConvoyService.gd`
- `scripts/core/TurnManager.gd`
- `scripts/resources/MapData.gd` validation helpers if reward id handling
  changes
- `scripts/tests/test_convoy_service.gd`
- `scripts/tests/test_game_state.gd`

Implementation steps:

1. Add `GameState.party_convoy: Array[InventoryEntry]`.
2. Keep `party_items` as a compatibility getter or migration input only until
   save fixtures no longer need it.
3. Add `ConvoyService` helpers:
   `add_entry(entry, reason)`, `remove_entry(entry)`, `entries()`,
   `has_space_for(entry)`, `capacity_used()`, and `capacity_limit()`.
4. Migrate existing reward item ids into full `InventoryEntry` instances using
   `B4-IEQ` item definition helpers.
5. Update `TurnManager._apply_victory_rewards()` so `reward_items` route to
   convoy, not `party_items`.
6. Preserve Retry behavior by snapshotting and restoring convoy entries with
   deep copies.

Tests:

- Map reward item ids become convoy entries.
- Convoy entries preserve `uses_remaining`, `map_uses_remaining`, and
  `forged_mods`.
- Retry restores convoy contents after rewards or deposits.
- No code path writes a second loose item list.

F1 obligations: `party_convoy` and its map-start snapshot/migration defaults.

## Slice 2 - Capacity And Overflow

**Goal:** enforce per-unit inventory caps and convoy capacity at mutation sites.

Files to touch:

- `scripts/resources/CampaignRules.gd`
- `scripts/autoloads/GameState.gd`
- `scripts/convoy/ConvoyService.gd`
- unit/item mutation call sites identified in Slice 0
- `scripts/tests/test_inventory_overflow.gd`

Implementation steps:

1. Add `CampaignRules.convoy_capacity: int = -1` as unlimited sentinel.
2. Add capacity calculation, counting **instances** (`[CVS-S1]`) and excluding entries whose
   **instance property** marks them capacity-exempt (`[CVS-S2]`) — not a story/key item *type*
   test. Over-capacity is a **legal state** (`[CVS-S3]`): the cap blocks additions with the ordinary
   `[EPUX-07]` reason, a holder found over its cap on load spills into the pending-items tray at
   **next prep entry** rather than on load, and the tray is durable in the save because
   quit-to-menu is not the prep exit `[DSX-S21]`'s gate watches.
3. Add a single `ConvoyService.give_item_to_unit_or_convoy(unit, entry,
   reason)` helper (owned by `ConvoyService`, matching the shop plan's call
   sites): target unit first, convoy overflow second, structured failure if
   both are full.
4. Route map rewards, future shop purchases, chest loot, village rewards, and
   death-disposition item transfers through this helper as they land.
5. Enforce `CampaignRules.max_inventory` on every item-add helper, not by
   scattered length checks in UI code.

Tests:

- A unit below cap receives the item.
- A full unit routes overflow to convoy.
- A full finite convoy returns a failure result without losing the item.
- Story/key items ignore convoy capacity.
- `max_inventory` comes from campaign rules, not a hardcoded `8`.

F1 obligations: `convoy_capacity` and migration default.

DoD#2 obligations: add a focused test that inventory growth uses the shared
helper so a future direct `unit.data.inventory.append()` growth path is caught.

## Slice 3 - Transfer Operations

**Goal:** support prep management across roster and convoy without building the
final UI polish.

Files to create or touch:

- `scripts/convoy/ConvoyService.gd`
- `scripts/convoy/InventoryTransferResult.gd` or a simple result dictionary
  helper
- `scripts/units/Unit.gd`
- `scripts/tests/test_convoy_transfers.gd`

Implementation steps:

1. Add transfer APIs for `unit -> convoy`, `convoy -> unit`, and
   `unit -> unit`.
2. Preserve item identity during transfers.
3. Validate source ownership before mutation.
4. Enforce destination caps and return structured failures.
5. Preserve equipped-weapon order and accessory equip pointers when moving items;
   unequip or reject transfers that would leave invalid equipped state according
   to the `B4-IEQ` accessory rules.
6. Restrict roster scope to the active controlled faction's roster; leave
   multi-faction convoy stores as a forward-compatible data shape.

Tests:

- Unit-to-convoy and convoy-to-unit transfer preserve instance state.
- Unit-to-unit transfer enforces destination cap.
- Moving an equipped item updates or blocks equipped state consistently.
- A unit outside the controlled faction cannot be managed through this panel.

F1 obligations: no new fields beyond convoy/equip state rows.

## Slice 4 - Shared Selector And Convoy Panel Skeleton

**Goal:** build the rough PHB convoy panel and the reusable selector/detail-pane
surface that shop also consumes.

Files to create or touch:

- `scripts/ui/panels/ConvoyPanel.gd`
- `scenes/ui/panels/ConvoyPanel.tscn`
- `scripts/ui/shared/SelectionCursor.gd`
- `scripts/ui/shared/PanelSelector.gd`
- `scripts/ui/shared/FocusedDetailPane.gd`
- `scripts/autoloads/RegistryManager.gd` or PHB panel registry data
- `scripts/tests/test_convoy_panel.gd`
- `scripts/tests/test_selection_cursor.gd`
- `scripts/tests/test_panel_selector.gd`

Implementation steps:

1. Register a `convoy` PHB panel type.
2. Add a selected-unit column and a convoy column.
3. Add a shared `PanelSelector` **built on the pure `SelectionCursor` logic core**
   (Component 1 of `shared_selector_extraction_design_2026-06-20.md`, pulled
   forward into Band 4 per the 2026-07-01 review decision Q11). `SelectionCursor`
   is a headless-testable `RefCounted` owning the index/wrap/inactive navigation;
   `PanelSelector` wraps it with keyboard and mouse focus, selection,
   cancellation, disabled rows, and a focus-changed signal. Keep the API narrow so
   `B6-INPUT` can EXTEND (not replace) it later; the arbiter / input-context owner
   and gamepad wiring (Components 2-3) stay in Band 6.
4. Add a focused item detail pane at the top.
5. Render author-defined groups plus the required `All` group.
6. Render author-selected row fields from:
   `name`, `uses_info`, `count`, `base_value`, and `stack_value`.
7. Implement display-only stacking by item id and uses bucket.
8. Wire basic transfer commands: deposit, withdraw, and send-to-unit.

Tests:

- A PHB node with the `convoy` panel id launches the panel.
- Focus changes update the detail pane.
- Author group/sort config changes row order without changing storage order.
- Stacked display groups identical full items while preserving separate entries
  in storage.
- Deposit/withdraw buttons call the same transfer APIs as headless tests.

F1 obligations: no saved UI state. Panel state is re-derived from party state.

DoD#2 obligations: add a test that convoy UI uses `PanelSelector` rather than a
private list-input loop.

## Slice 5 - Death-Disposition And Reward Hooks

**Goal:** make convoy available as the shared sink for systems that need it
without implementing those systems here.

Files to touch:

- `scripts/convoy/ConvoyService.gd`
- `scripts/death/DeathDispositionResolver.gd` or the Band 2 death lifecycle
  owner file once it exists
- `scripts/core/TurnManager.gd`
- `scripts/tests/test_convoy_death_hooks.gd`

Implementation steps:

1. Expose a narrow `to_convoy` sink used by death-disposition rules.
2. Add key/story-item transfer guarantees expected by `DTH-5` and `DTH-10` once
   death disposition lands.
3. Keep map rewards on the same `add_entry` path as shops and death
   disposition.
4. Do not build drop-on-tile or chest/village reward behavior here; those
   consumers call the convoy API when they land.

Tests:

- Death lifecycle can call the convoy sink without knowing the convoy storage
  internals.
- A key/story item routed to convoy is not capacity-blocked.
- Reward and death transfer paths produce the same entry shape.

F1 obligations: no additional saved fields beyond convoy state.

## Slice 6 - Cleanup And Migration Guard

**Goal:** finish the migration away from `party_items` and prevent drift.

Implementation checklist:

- Remove direct writes to `party_items` once save migration is complete.
- Update docs and tests that still describe `party_items` as the shared item
  store.
- Add a data/save migration fixture for old `party_items` ids.
- Run the full Godot suite and docs checks.

DoD#1 obligations: update `GDD_01`, `GDD_04`, `GDD_07`,
`GDD_Feature_Index`, and `GDD_10` in the behavior-changing commit.

DoD#2 obligations: add a test/check that rejects new direct writes to the legacy
loose party item list.

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
