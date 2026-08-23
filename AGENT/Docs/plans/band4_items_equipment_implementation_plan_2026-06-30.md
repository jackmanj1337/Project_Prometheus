---
Role: dated
Type: plan
Status: Active - implementation plan
Last verified: 2026-06-30
---

# Band 4 Items And Equipment Implementation Plan

**Started:** 2026-06-30.

**Track ID:** `B4-IEQ`

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 4 rows. Drafted from
[`band4_implementation_plan_handoff_2026-06-30.md`](band4_implementation_plan_handoff_2026-06-30.md).

## Purpose

Turn the resolved items/equipment model into a code-ready staged migration.
Band 4 item work is an internal sub-foundation: convoy, shops, doors/chests,
PXP, prep deployment, rewards, and campaign-loop smoke tests all need item
instances to be stable before they can rely on them.

This plan is a build plan only. It does not authorize starting `B4-IEQ` before
the Band 1-3 gates land.

## Scope

This plan covers the first `B4-IEQ` implementation run:

1. Add the unified `ItemDef` base plus optional `WeaponComponent`,
   `ConsumableComponent`, and `AccessoryComponent` resources.
2. Add compatibility helpers so legacy `WeaponData`, `ItemData`, and
   `InventoryEntry` call sites can migrate in small commits.
3. Migrate weapons into `ItemDef.weapon_component` while preserving combat,
   equip, durability, WEXP, and weapon-menu behavior.
4. Migrate consumables into `ItemDef.consumable_component` while preserving
   `ItemHandler` behavior and item-menu visibility.
5. Build the accessory component path: held/equipped conferral, typed slots,
   tiered modifiers/effect hooks, and real `until_unequipped` modifier
   lifecycle.
6. Reserve the PXP integration seam without pulling the full `B4-PXP` track
   into this plan.
7. Remove the half-built passive equipment path after the new accessory path is
   covered by tests.

## Non-Goals

- Do not build convoy, shops, doors/chests, rewards, prep deployment, or the
  campaign loop here. Those consumers call this foundation later.
- Do not build the full `B4-PXP` proficiency store here. This plan adds the
  item-side declarations and adapter seam; PXP builds the rank/profile store.
- Do not build forging. `InventoryEntry.forged_mods` stays an instance overlay
  reserved for later work.
- Do not implement every future item effect hook. Add only the hooks needed by
  migrated fixtures; leave new effect ids to their owning tracks unless a test
  fixture requires one.
- Do not add saved item fields without F1 manifest rows first.
- Do not replace author-facing component ids, slot types, or effect hooks with
  closed `enum` + `match` switches.

## Source Docs

- [`band4_implementation_plan_handoff_2026-06-30.md`](band4_implementation_plan_handoff_2026-06-30.md)
- [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
- [`items_equipment_model_open_questions_2026-06-23.md`](../registers/items_equipment_model_open_questions_2026-06-23.md)
  (`IEQ-1..9`)
- [`items_equipment_unified_model_2026-06-23.md`](../design/items_equipment_unified_model_2026-06-23.md)
- [`proficiency_xp_framework_open_questions_2026-06-23.md`](../registers/proficiency_xp_framework_open_questions_2026-06-23.md)
- [`band1_determinism_save_implementation_plan_2026-06-30.md`](band1_determinism_save_implementation_plan_2026-06-30.md)
- [`band2_shared_runtime_contracts_implementation_plan_2026-06-30.md`](band2_shared_runtime_contracts_implementation_plan_2026-06-30.md)
- [`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](band3_core_authoring_foundations_implementation_plan_2026-06-30.md)
- [`stat_registry_implementation_plan_2026-06-29.md`](stat_registry_implementation_plan_2026-06-29.md)

## Decisions Not To Reopen

- One `ItemDef` base owns shared fields; optional components add weapon,
  consumable, and accessory capabilities.
- One physical item may have multiple components. A dual weapon+accessory item
  counts as equipped for its accessory side while it is the equipped weapon.
- `InventoryEntry` is the per-slot runtime instance. Definition data does not
  live on the instance.
- Accessory conferral is `held | equipped | both`; equipped conferral consumes a
  typed author-defined slot.
- Accessory bonuses are real modifiers/effect hooks, not combat-only four-field
  bonuses.
- `until_unequipped` must get a producer and remover. Bonuses must appear on the
  character sheet outside combat.
- PXP owns proficiency tracks, rank profiles, and gain. IEQ declares item-side
  requirements and consumes the PXP result once `B4-PXP` lands.
- Save fields are reserved through F1 before code.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates before `B4-IEQ` code:

- `B1-F1` for saved-field manifest rows covering `InventoryEntry.def_id`,
  item runtime counters, equipped accessory pointers, and compatibility
  migration defaults.
- `B2-REGISTRY` for item component families, accessory slot types, and effect
  hook ids.
- `B2-DATAMANAGER-SEAMS` for staged load/validate/report behavior.
- `B3-STAT-REGISTRY` before accessory modifiers can target author-defined stats.
- `B3-REQ` for accessory `req_flags` and component legality predicates.

`B4-PXP` follows this plan. Until it lands, rank-gated accessory tiers should
validate their declarations but use fixtures with no PXP requirement, or route
through a narrow adapter that returns the default rank only.

## Existing Code Touchpoints

Verified 2026-06-30:

- `scripts/resources/InventoryEntry.gd` has `entry_type`, `weapon_id`,
  `item_id`, `uses_remaining`, `forged_mods`, and four passive equipment fields.
- `scripts/resources/WeaponData.gd` is the healthy weapon definition model used
  by combat, range, WEXP, and durability.
- `scripts/resources/ItemData.gd` is the consumable/key/sellable definition
  model used by `ItemHandler`.
- `scripts/items/ItemHandler.gd` dispatches `effect_id` through a closed
  `match` and `IMPLEMENTED_EFFECT_IDS`; Band 2 action/effect work should own
  the open-registry migration before broad new item effects land.
- `scripts/autoloads/DataManager.gd` loads separate `_weapons` and `_items`
  dictionaries and exposes `get_weapon(id)` / `get_item(id)`.
- `scripts/units/Unit.gd` treats inventory order as weapon equip state; the
  first usable weapon is equipped.
- `scripts/core/CombatResolver.gd` still applies passive equip fields in
  `_apply_equip_item_modifiers()`.
- `scripts/autoloads/GameState.gd` snapshots `UnitData.inventory` by duplicating
  each `InventoryEntry`; new runtime fields must stay deep-copy safe.
- Existing tests to extend first: `test_data_manager.gd`,
  `test_snapshot_coverage.gd`, `test_combat.gd`, `test_action_menu.gd`,
  `test_unit_details_screen.gd`, and new focused item/equipment suites.

## Slice 0 - Preflight After Band 1-3 Gates

**Goal:** confirm the migration can be sliced without breaking the healthy
weapon/item paths.

Implementation checklist:

- Run `rg -n "get_weapon|get_item|weapon_id|item_id|entry_type|is_equip|uses_remaining|IMPLEMENTED_EFFECT_IDS|_apply_equip_item_modifiers" scripts data`.
- Confirm F1 rows exist or reserve them before code:
  `InventoryEntry.def_id`, `InventoryEntry.instance_id`,
  `InventoryEntry.uses_remaining`, `InventoryEntry.map_uses_remaining`,
  `InventoryEntry.forged_mods`, equipped accessory pointers by slot type, and
  per-unit slot capacity overrides if this run adds them.
- Confirm `RegistryManager`, DataManager validate/report phases, `B3-REQ`, and
  `B3-STAT-REGISTRY` are in place.
- Identify which compatibility shims can be behavior-preserving. Behavior
  changes must update `GDD_01`, `GDD_04`, `GDD_Feature_Index`, and `GDD_10` in
  the same commit.

Tests: none required in preflight.

## Slice 1 - ItemDef And Component Resources

**Goal:** add the unified definition shape without moving live data yet.

Files to create or touch:

- `scripts/resources/ItemDef.gd`
- `scripts/resources/item_components/WeaponComponent.gd`
- `scripts/resources/item_components/ConsumableComponent.gd`
- `scripts/resources/item_components/AccessoryComponent.gd`
- `scripts/autoloads/DataManager.gd`
- `scripts/tests/test_item_def.gd`
- developer preset data under `data/items_unified/` or the project-standard
  registry path chosen by `B2-REGISTRY`

Implementation steps:

1. Add `ItemDef` with base fields: `id`, `display_name`, `description`,
   `cost`, `sellable`, and author locks such as `no_sell`, `no_drop`,
   `no_trade`, and `story`.
2. Add optional component resource fields: `weapon_component`,
   `consumable_component`, and `accessory_component`.
3. Move the `WeaponData` field set into `WeaponComponent` without changing
   field names where compatibility is useful.
4. Move the `ItemData` consumable fields into `ConsumableComponent`:
   durability/use fields, `effect_id`, and `effect_params`.
5. Add `AccessoryComponent` fields: `conferral`, `slot_type`, `tiers`,
   `req_flags`, and effect-hook declarations.
6. Register component families and slot-type ids through `RegistryManager`.
7. Add pure validators for missing ids, no-component key items, bad component
   combinations, unknown slot types, and unknown effect hooks.

Tests:

- A base-only key item validates.
- A multi-component item validates without engine switch edits.
- Unknown component family, slot type, or effect hook reports a useful error.
- Item defs sort/load deterministically.

F1 obligations: no saved state added in this slice.

DoD#2 obligations: add a validator test that a new component-bearing `ItemDef`
loads through registry data, not a hardcoded type switch.

## Slice 2 - InventoryEntry Compatibility Scaffold

**Goal:** let runtime inventory entries point at `ItemDef` while old entries
continue to work during migration.

Files to touch:

- `scripts/resources/InventoryEntry.gd`
- `scripts/autoloads/GameState.gd`
- `scripts/tests/test_inventory_entry.gd`
- `scripts/tests/test_snapshot_coverage.gd`

Implementation steps:

1. Add `def_id` as the preferred definition reference.
2. Add `instance_id`: a save-stable unique id assigned at entry creation
   (Slice 5's modifier sources and convoy/transfer identity depend on it — two
   identical Iron Swords must not share a key). Old saves/snapshots without
   one get an id assigned on load; duplication for Retry deep-copies preserves
   it, while creating a genuinely new entry mints a new id.
3. Keep `weapon_id`, `item_id`, and `entry_type` as compatibility fields until
   their data is migrated.
4. Add helper methods:
   `get_definition_id()`, `has_weapon_component()`,
   `has_consumable_component()`, `has_accessory_component()`, and
   `is_legacy_entry()`.
5. Add `map_uses_remaining` for per-map consumables, defaulting to `-1`.
6. Add factory helpers for unified entries while keeping old factories intact.
7. Update snapshot coverage for every new mutable runtime field (including
   `instance_id` stability across snapshot/restore).

Tests:

- Legacy weapon/item entries still validate.
- Unified entries with `def_id` validate.
- Snapshot/restore deep-copies unified runtime fields.
- Bad mixed ids report warnings or errors according to the migration policy.

F1 obligations: `InventoryEntry.def_id`, `InventoryEntry.instance_id`, and
`map_uses_remaining` rows must exist before code.

## Slice 3 - Weapon Migration

**Goal:** move weapons to `ItemDef.weapon_component` while preserving player
behavior.

Files to touch:

- weapon data resources under `data/weapons/` or the chosen unified path
- `scripts/autoloads/DataManager.gd`
- `scripts/units/Unit.gd`
- `scripts/ui/WeaponMenu.gd`
- `scripts/core/GridManager.gd`
- `scripts/core/CombatResolver.gd`
- `scripts/tests/test_combat.gd`
- `scripts/tests/test_unit_stats.gd`

Implementation steps:

1. Add `DataManager.get_item_def(id)` and `get_weapon_component(id)`.
2. Keep `get_weapon(id)` as a compatibility shim until all weapon call sites are
   migrated, either returning a component adapter or a temporary legacy mirror.
3. Convert weapon resources to item definitions with `weapon_component`.
   **Id-parity invariant:** every migrated `ItemDef.id` must equal its source
   `WeaponData`/`ItemData` id — old saves, `MapData.reward_items`, and fixture
   references carry legacy ids, and the `def_id` migration is mechanical only
   if ids match 1:1. Add a validation check that fails a migrated def whose id
   differs from its source id.
4. Update `Unit._find_equipped_weapon()`, range checks, durability, weapon
   menus, and combat to read the weapon component.
5. Preserve inventory-front weapon equip semantics for this slice.
6. Keep WEXP behavior unchanged. PXP generalization happens later.

Tests:

- Existing combat tests stay green.
- Weapon range formulas still resolve against effective stats.
- Weapon durability decrements and breaks on the same exchanges as before.
- Weapon-menu entries and equip swapping still use inventory order.
- Legacy `get_weapon(id)` callers fail no tests during the migration window.

F1 obligations: no new saved fields beyond Slice 2 unless the migration changes
serialized entry identity.

## Slice 4 - Consumable And Key-Item Migration

**Goal:** move `ItemData` behavior to `ItemDef.consumable_component` and base
item fields.

Files to touch:

- item data resources under `data/items/` or the chosen unified path
- `scripts/items/ItemHandler.gd`
- `scripts/ui/ItemMenu.gd`
- `scripts/autoloads/DataManager.gd`
- `scripts/units/Unit.gd`
- `scripts/tests/test_items.gd` or a new `test_consumables.gd`

Implementation steps:

1. Add `DataManager.get_consumable_component(id)` and update `ItemHandler` to
   resolve item definitions.
2. Preserve existing effects: `heal_flat`, `heal_full`, `promote`, `reclass`,
   and `stat_buff`.
3. Route effect id validation through `B2-ACTION-EFFECT` registry helpers once
   they exist. Do not grow `IMPLEMENTED_EFFECT_IDS` as the long-term extension
   point.
4. Move `cost`, `sellable`, and key/story flags to `ItemDef` base fields.
5. Implement `uses_per_map` / `map_uses_remaining` only if fixtures require it;
   otherwise leave the field validated and idle.

Tests:

- Existing item-use behavior and use consumption are unchanged.
- Unknown consumable effect ids fail through registry validation.
- Promotion/reclass items still refuse direct `ItemHandler` resolution.
- Base-only key items validate and are not offered as consumables.

F1 obligations: add `map_uses_remaining` coverage before enabling per-map-use
items.

## Slice 5 - Accessory Runtime And Slots

**Goal:** replace passive four-field equipment bonuses with the resolved
accessory component model.

Files to touch:

- `scripts/resources/InventoryEntry.gd`
- `scripts/resources/UnitData.gd`
- `scripts/units/Unit.gd`
- `scripts/core/CombatResolver.gd`
- `scripts/shared/StatBreakdown.gd`
- `scripts/ui/UnitDetailsScreen.gd`
- `scripts/tests/test_equip_items.gd`
- `scripts/tests/test_unit_details_screen.gd`
- `scripts/tests/test_combat.gd`

Implementation steps:

1. Add unit runtime state for equipped accessory pointers by slot type.
2. Add capacity resolution: campaign default -> class override. Per-unit
   modifiers stay deferred unless explicitly pulled forward.
3. Add `AccessoryService` or a small unit-local helper that applies and removes
   `until_unequipped` modifiers with stable sources keyed by the Slice 2
   `InventoryEntry.instance_id`: `item:<instance_id>:<stat>`.
   **This slice owns and creates the shared `LifecycleStore`** — the single
   duration-lifecycle engine (`{ source_key, payload_ref, mode, remaining }`,
   `mode` as registry data). `until_unequipped` is its first mode; Band 5's
   `B5-DURATION-LIFECYCLE` adds the `until_end_of_map` + fixed-N modes and
   registers conditions/skills as producers into this same store (C1, resolved
   2026-07-03 — one engine, many producers, not two implementations). Build the
   store generically here (register / remove / tick / clear-end-of-map), even
   though IEQ only needs `until_unequipped`.
4. Implement held conferral, equipped conferral, and `both`.
5. Implement dual weapon+accessory behavior: equipped weapon counts as equipped
   for its accessory side without consuming another slot.
6. Stop `CombatResolver._apply_equip_item_modifiers()` from reading the legacy
   four fields once fixtures are migrated.
7. Fix the stale `InventoryEntry.gd` equipment comment with the build.

Tests:

- Held accessory bonus appears on the character sheet and affects combat.
- Equipped accessory consumes the correct typed slot and rejects overflow.
- Unequip/drop removes `until_unequipped` modifiers.
- A dual weapon+accessory item grants equipped-tier effects while wielded.
- Legacy passive equip fixtures either migrate or fail with a clear validation
  error.

F1 obligations: equipped accessory pointers and any slot-capacity runtime fields
must have manifest rows before code.

DoD#1 obligations: update `GDD_01`, `GDD_04`, `GDD_Feature_Index`, and `GDD_10`
with the accessory behavior change.

## Slice 6 - PXP Adapter Seam

**Goal:** let IEQ declare item proficiency requirements without owning PXP
storage.

Files to touch:

- `scripts/units/Unit.gd`
- `scripts/resources/item_components/AccessoryComponent.gd`
- `scripts/tests/test_item_proficiency_adapter.gd`

Implementation steps:

1. Add a narrow query helper such as `unit.get_item_proficiency_rank(track_id)`.
2. Before `B4-PXP`, return the safe default rank — the **lowest/base rank of
   the track, the one that gates nothing** — and validate that rank-gated
   content is not active in fixtures.
3. After `B4-PXP`, route the helper to the real proficiency store.
4. Keep item tier selection data-driven and predicate-based.

Tests:

- No-PXP fixtures use default legality.
- Rank-gated tier data validates but does not silently grant higher-tier
  benefits before PXP owns the rank.

F1 obligations: no PXP saved fields here; `B4-PXP` owns them.

## Slice 7 - Migration Cleanup

**Goal:** remove compatibility scaffolding after every live call site uses the
unified path.

Implementation checklist:

- Remove or archive legacy `WeaponData` / `ItemData` data paths only after all
  callers use `ItemDef` helpers.
- Remove `InventoryEntry.entry_type`, `weapon_id`, and `item_id` only after save
  migration and fixtures prove `def_id` round-trips.
- Delete the passive equipment fields only after accessory tests cover the
  replacement behavior.
- Replace stale comments and update docs with the final field names.
- Run the full suite and `python3 AGENT/Docs/check_docs.py`.

Tests:

- Full Godot suite.
- Data validation with a deliberately stale legacy item fixture.
- Save/load or snapshot fixture covering unified entries.

DoD#2 obligations: add a guard that new item definitions use registry-backed
components and do not add another closed item-type switch.

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
