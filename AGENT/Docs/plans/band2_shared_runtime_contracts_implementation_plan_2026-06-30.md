---
Type: plan
Status: Active - implementation plan
Last verified: 2026-06-30
---

# Band 2 Shared Runtime Contracts Implementation Plan

**Started:** 2026-06-30.

**Track IDs:** `B2-REGISTRY`, `B2-ACTION-EFFECT`, `B2-RESOURCE-LEDGER`,
`B2-OCCUPANCY`, `B2-DEATH-LIFECYCLE`, `B2-PROJECTION`,
`B2-DATAMANAGER-SEAMS`

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 2 rows.

## Purpose

Turn the Band 2 architecture contracts into a code-ready sequence. Band 2 is the
shared authoring/runtime layer that prevents later features from building their
own private registries, action runners, resource edits, placement rules, death
paths, or forecast paths.

This plan is a build plan only. It does not authorize starting Band 2 code before
Band 1 gates land.

## Scope

This plan covers the first Band 2 implementation run:

1. Registry manifest foundation and first small registry families.
2. Action/effect primitive runner and one shared primitive.
3. Resource ledger / cost resolver over existing gold fields.
4. Occupancy transaction service for map-start spawn and forced-placement
   consumers.
5. Death lifecycle funnel around combat death, with disposition hooks ready for
   later inventory/key-item rules.
6. Projection service, first as a combat-preview adapter with no-mutation guards.
7. `DataManager` load/validate/report phases and replace-load campaign seam.

## Non-Goals

- Do not implement Band 2 before `B1-PKGA` and `B1-F1` are in place.
- Do not convert every author-facing vocabulary in one pass.
- Do not collapse MET, dialogue, source/style, shops, objectives, and panels
  into one vocabulary. They stay separate domains that share primitive
  execution.
- Do not build full MET, DLG, SAC, STY, PHB, TCV, REQ, conditions, shops,
  training, arena, activities, or public campaign tooling here.
- Do not build campaign `user://` seed-copy, import/export, or package
  enumeration in Band 2. The DataManager seam is replace-load only.
- Do not add saved state unless the F1 manifest has the owner/default/fixture
  row first.

## Source Docs

- [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
- [`band1_determinism_save_implementation_plan_2026-06-30.md`](band1_determinism_save_implementation_plan_2026-06-30.md)
- [`design_review_foundation_fix_todo_2026-06-28.md`](../design/design_review_foundation_fix_todo_2026-06-28.md)
- [`registry_manifest_contract_2026-06-28.md`](../design/registry_manifest_contract_2026-06-28.md)
- [`open_registry_conversion_checklist_2026-06-28.md`](../design/open_registry_conversion_checklist_2026-06-28.md)
- [`action_effect_primitive_contract_2026-06-28.md`](../design/action_effect_primitive_contract_2026-06-28.md)
- [`resource_ledger_cost_resolver_contract_2026-06-28.md`](../design/resource_ledger_cost_resolver_contract_2026-06-28.md)
- [`occupancy_transaction_contract_2026-06-28.md`](../design/occupancy_transaction_contract_2026-06-28.md)
- [`death_lifecycle_contract_2026-06-28.md`](../design/death_lifecycle_contract_2026-06-28.md)
- [`projection_forecast_contract_2026-06-28.md`](../design/projection_forecast_contract_2026-06-28.md)
- [`datamanager_decomposition_open_questions_2026-06-21.md`](../registers/datamanager_decomposition_open_questions_2026-06-21.md)

## Decisions Not To Reopen

- Author-facing extension points are open registries, not closed enum+match
  additions.
- F1 owns saved-field manifest rows before feature code adds saved state.
- The action/effect runner shares execution context and result handling, but it
  does not merge every feature vocabulary.
- Resource spending goes through a ledger; feature code does not mutate wallets
  directly once the ledger owns that wallet.
- Non-standard placement goes through occupancy transactions; public spawn does
  not bypass occupancy policy once that service owns spawn.
- Death producers route through one lifecycle funnel once the funnel exists.
- Projection is side-effect-free and does not advance committed RNG history.
- Campaign content loading is replace-load for self-contained campaign packs,
  not runtime overlay merge.

## Dependency Note

Plan now; implement later. Minimum upstream gates:

- `B1-PKGA` Step 1 for deterministic RNG policy.
- `B1-PKGA` Step 2 for snapshot/RNG restore when projection and actions touch
  retryable map state.
- `B1-F1` before any Band 2 slice adds or claims saved fields.

`B1-SAVECODEC` is not required for every Band 2 code slice, but any slice that
adds persistent data must reserve F1 rows and fixture obligations before code.

## Existing Code Touchpoints

Verified 2026-06-30:

- `scripts/autoloads/DataManager.gd` still loads class/weapon/item/skill
  directories directly in `_ready()` and validates through fixed lists such as
  `_VALID_OBJECTIVE_TYPES` and `_VALID_AI_PROFILES`.
- `scripts/items/ItemHandler.gd` uses `IMPLEMENTED_EFFECT_IDS` plus a
  `match item.effect_id`; this is a good first action/effect migration target.
- `scripts/core/GameMap.gd` `_spawn_unit()` instances a unit, sets the tile, adds
  it to the scene, and registers it with `GameState` without an occupancy
  service.
- `scripts/units/Unit.gd` `handle_death()` owns incapacitation, Pair Up release,
  unregister, event emission, and `queue_free()`.
- `scripts/core/CombatResolver.gd` `apply_combat_result()` calls
  `handle_death()` directly after all exchanges.
- `scripts/core/CombatResolver.gd` `preview_combat()` snapshots and restores
  unit state because modifier skills mutate during preview.
- `scripts/autoloads/GameState.gd` owns `party_gold`, `party_items`, map-start
  snapshots, and roster state.
- Existing tests to extend first: `test_data_manager.gd`, `test_combat.gd`,
  `test_game_map_scene.gd`, `test_snapshot_coverage.gd`, and focused new
  `test_*` suites under `scripts/tests/`.

## Slice 0 - Preflight After Band 1 Gates

**Goal:** make the first Band 2 code pass small and reviewable.

Implementation checklist:

- Re-check the final autoload order after `RngService` lands. `RegistryManager`
  should load before `DataManager` if DataManager validation asks registries.
- Run `rg -n "_VALID_|IMPLEMENTED_EFFECT_IDS|match .*effect|match .*type|handle_death|_spawn_unit|party_gold|preview_combat|randi|randf" scripts`.
- Confirm the F1 manifest has rows for existing fields Band 2 will touch:
  `GameState.party_gold`, `GameState.party_items`, `UnitData.gold`,
  `UnitData.tile_position`, `UnitData.inventory`, `UnitData.is_incapacitated`,
  `UnitData.active_modifiers`, and map/suspend placement state as applicable.
- Decide whether each first slice is behavior-preserving or behavior-changing.
  Behavior-changing commits must update the affected GDD chapter and control
  plane row in the same commit.

Tests:

- No new tests required in preflight.

Docs:

- If the final Band 1 autoload order changes this plan's assumptions, patch this
  plan before coding Band 2.

## Slice 1 - `B2-REGISTRY`: Registry Manifest Foundation

**Goal:** add the minimum open-registry loader/validator before any broad
vocabulary conversion.

Files to create or touch:

- `project.godot`
- `scripts/autoloads/RegistryManager.gd`
- `scripts/resources/RegistryEntry.gd`
- `scripts/registries/RegistryCatalog.gd`
- `data/registries/action_primitives/`
- `data/registries/resource_types/`
- `data/registries/occupancy_policies/`
- `scripts/autoloads/DataManager.gd`
- `scripts/tests/test_registry_manager.gd`
- `scripts/tests/test_data_manager.gd`

Implementation steps:

1. Add `RegistryEntry.gd` as a simple resource with:
   `id`, `family`, `label_key`, `owner_feature`, `version`, `kind`,
   `primitive_handler`, `params_schema`, `subjects`, `composition`,
   `projection_support`, `save_fields`, `docs_text`, and `test_fixture`.
2. Add `RegistryCatalog.gd` as the pure data structure:
   `register_entry(entry)`, `has_entry(family, id)`, `entry(family, id)`,
   `ids(family)`, and `validate_entry(entry) -> Array[String]`.
3. Add `RegistryManager.gd` as the autoload wrapper.
   - Seed built-in primitive handler ids first.
   - Load developer preset `RegistryEntry` resources second.
   - Later campaign registry entries can load through the same API.
4. Register `RegistryManager` before `DataManager`, after confirming the final
   Band 1 autoload order.
5. Add first preset entries only:
   - one action primitive entry: `apply_active_modifier`,
   - one resource type entry: `party_gold`,
   - one occupancy policy entry: `nearest_free`.
6. Add DataManager validation helpers that ask `RegistryManager` for known ids.
   Do not migrate every validator in this slice.
7. Keep deterministic output sorted by explicit priority if present, then stable
   id.
8. Fail unknown handler ids, duplicate ids, malformed schema dictionaries, and
   bad composition references with structured error strings.

Tests:

- `test_registry_manager.gd`
  - duplicate id fails without replacing the first entry,
  - unknown primitive handler fails validation,
  - malformed parameter schema fails validation,
  - `ids(family)` returns stable sorted order,
  - a data-defined entry loads without an engine switch edit.
- Extend `test_data_manager.gd`
  - DataManager can ask `RegistryManager` during validation,
  - one deliberately unknown registry id reports a useful error.

F1 obligations:

- No saved state is added in this slice.
- If registry package identity or selected campaign registry version is saved,
  add F1 rows before code.

DoD#2 obligations:

- Add either a docs/check script rule or a GDScript lint test that registry
  entries carry required handler/schema metadata.
- Do not add a broad closed-vocabulary scanner until registry paths and family
  names are stable enough to avoid noisy failures.

## Slice 2 - `B2-ACTION-EFFECT`: Action/Effect Primitive Runner

**Goal:** build one mutation runner with shared validation, commit, RNG,
resource, save-side-effect, and result reporting rules.

Files to create or touch:

- `scripts/actions/ActionContext.gd`
- `scripts/actions/ActionResult.gd`
- `scripts/actions/ActionPrimitiveRunner.gd`
- `scripts/autoloads/ActionEffectRunner.gd`
- `scripts/items/ItemHandler.gd`
- `scripts/autoloads/RegistryManager.gd`
- `scripts/tests/test_action_effect_runner.gd`
- `scripts/tests/test_skill_item_handler.gd`

Implementation steps:

1. Add `ActionContext` with typed top-level fields and dictionaries for
   `subjects`, `target_refs`, `source_ref`, `event_metadata`, `state_view`,
   `resource_sink`, `rng_stream`, `safe_point`, `dry_run`, and result/error
   collectors.
2. Add `ActionResult` with `ok`, `failure_reason`, `affected_ids`,
   `events_emitted`, `resources_spent`, `rng_draws`, `save_fields_touched`, and
   `messages`.
3. Add `ActionPrimitiveRunner`.
   - `validate(primitive_id, params, ctx) -> ActionResult`
   - `commit(primitive_id, params, ctx) -> ActionResult`
   - no live mutation after a validation failure.
4. Register the first primitive: `apply_active_modifier`.
   - Required subjects: actor or source, target unit.
   - Params: `stat`, `delta`, `duration`, `duration_type`, `source`.
   - Save fields touched: `UnitData.active_modifiers`.
5. Migrate `ItemHandler` `stat_buff` to call `ActionEffectRunner` instead of
   adding modifiers directly.
6. Add a second domain caller as a small test fixture using domain
   `map_event`. Do not build MET in this slice.
7. Wire RNG policy to `RngService` for future random primitives, but keep the
   first primitive no-RNG.
8. Add a result contract for resource delegation, but keep resource spending as
   a later ledger slice.

Tests:

- Unknown primitive id fails validation.
- Malformed params fail and do not mutate the target.
- `ItemHandler` `stat_buff` still applies one modifier and consumes the item
  exactly as before.
- The same `apply_active_modifier` primitive can be called from `item` and
  `map_event` domains.
- Dry-run/validation path does not mutate `UnitData.active_modifiers`.

F1 obligations:

- Confirm `UnitData.active_modifiers` has an F1 row before this migration lands.
- New action-result logs are transient unless a later feature adds persisted
  event history.

DoD#2 obligations:

- Add a guard that new registered state-mutating primitives declare
  `save_fields`.
- Once two real domains call the runner, add a lint/check that they do not add
  private mutation switches for registered primitive ids.

## Slice 3 - `B2-RESOURCE-LEDGER`: Resource Ledger / Cost Resolver

**Goal:** route affordability, spending, refunds, and wallet deltas through one
transaction API before shops, training, arena, source/style costs, or custom
resources consume it.

Files to create or touch:

- `scripts/resources/CostSpec.gd`
- `scripts/resources/ResourceTransaction.gd`
- `scripts/autoloads/ResourceLedger.gd`
- `scripts/core/TurnManager.gd`
- `scripts/autoloads/GameState.gd`
- `scripts/tests/test_resource_ledger.gd`
- `scripts/tests/test_turn_manager.gd`

Implementation steps:

1. Add resource registry entries for `party_gold` and `unit_gold`.
2. Add `CostSpec` with `resource_id`, `scope`, `amount`, `formula_term`,
   `subject_binding`, `previewable`, `refundable`, `allow_partial`, and UI
   summary metadata.
3. Add ledger APIs:
   - `quote(costs, ctx) -> ResourceTransaction`
   - `reserve(costs, ctx) -> ResourceTransaction`
   - `commit(costs, ctx) -> ResourceTransaction`
   - `refund(transaction, ctx) -> ResourceTransaction`
4. Implement party wallet access over `GameState.party_gold`.
5. Implement unit wallet access over `UnitData.gold`.
6. Migrate `TurnManager._apply_victory_rewards()` gold gain through a ledger
   credit path. Item rewards can stay as party item appends until item-ledger
   ownership is planned.
7. Keep dynamic price formulas as fixed amounts in this slice unless B3-REQ has
   already landed.
8. Return recorded transaction data for refunds; do not recalculate formulas.

Tests:

- Party gold quote, spend, credit, and refund.
- Unit gold quote and spend.
- Multi-resource spend succeeds atomically.
- Multi-resource spend failure mutates nothing.
- Refund uses recorded transaction deltas.
- Unknown resource id fails validation.
- Existing victory reward gold behavior stays the same through the ledger.

F1 obligations:

- Confirm F1 rows for `GameState.party_gold`, `GameState.party_items`, and
  `UnitData.gold`.
- `reserve` state is transient unless a later multi-step UI needs suspend-safe
  reservations.

DoD#2 obligations:

- After `party_gold` is migrated, add a lint/check for direct `party_gold +=`,
  `party_gold -=`, and assignment outside `GameState` initialization, snapshot,
  save codec, and `ResourceLedger`.

## Slice 4 - `B2-OCCUPANCY`: Occupancy Transaction Service

**Goal:** make non-standard placement use one legal transaction path, starting
with map-start spawn.

Files to create or touch:

- `scripts/placement/OccupancyContext.gd`
- `scripts/placement/PlacementResult.gd`
- `scripts/autoloads/OccupancyService.gd`
- `scripts/core/GameMap.gd`
- `scripts/autoloads/DataManager.gd`
- `scripts/tests/test_occupancy_service.gd`
- `scripts/tests/test_game_map_scene.gd`
- `scripts/tests/test_data_manager.gd`

Implementation steps:

1. Add `OccupancyContext` with source, subject, from tile, desired tile, reason,
   collision policy, passability policy, fallback policy, and result sink.
2. Add `PlacementResult` with `ok`, `failure_reason`, `from_tile`, `to_tile`,
   `fallback_used`, `queued`, `skipped`, and affected ids.
3. Add policies:
   `require_empty`, `nearest_free`, `delay`, `skip`, `swap`,
   `overlap_hidden`, and `object_unit`.
4. Implement deterministic nearest-free search:
   tile distance first, then `y`, then `x`, then source order for batch
   placement.
5. Add a validation-mode path that checks placement without instancing nodes.
6. Migrate `GameMap._spawn_units()` to ask `OccupancyService` before each
   `_spawn_unit()` call.
7. Keep `_spawn_unit()` private to instancing after a successful placement
   result. Public spawn APIs should call the service.
8. Extend DataManager map validation to catch player/enemy start overlap through
   the same validation rules where practical.

Tests:

- Spawn into an empty tile succeeds.
- Spawn into blocked tile with `require_empty` fails.
- Spawn into blocked tile with `nearest_free` picks the stable fallback tile.
- `skip` reports skipped and mutates nothing.
- `delay` queues a placement without instancing a unit.
- Map-start duplicate placement is reported before live spawn.
- Existing map scene boot still spawns the same units on the same tiles.

F1 obligations:

- Confirm rows for `UnitData.tile_position`, delayed spawn queues if added, and
  object occupancy fields if object-units enter this slice.

DoD#2 obligations:

- Add a guard that public spawn helpers call `OccupancyService`.
- Add a narrow direct `tile_position` write lint only after allowed writers are
  documented, because normal movement still writes legal movement state.

## Slice 5 - `B2-DEATH-LIFECYCLE`: Death Funnel And Disposition Hooks

**Goal:** route combat deaths through one `handle_death(ctx)` service while
leaving hooks for inventory/key-item disposition, object-unit teardown, and
later non-combat death causes.

Files to create or touch:

- `scripts/death/DeathContext.gd`
- `scripts/death/DeathResult.gd`
- `scripts/death/DeathDisposition.gd`
- `scripts/autoloads/DeathLifecycle.gd`
- `scripts/core/CombatResolver.gd`
- `scripts/units/Unit.gd`
- `scripts/autoloads/EventBus.gd`
- `scripts/tests/test_death_lifecycle.gd`
- `scripts/tests/test_combat.gd`

Implementation steps:

1. Add `DeathContext` with subject, source domain, source id, responsible actor,
   timing bucket, inventory snapshot, map/tile context, simultaneous group id,
   death-mode refs, and result sink.
2. Add `DeathResult` with `ok`, `subject_id`, `removed_from_map`,
   `incapacitated`, `custody_events`, `inventory_events`, `objective_events`,
   and UI/log messages.
3. Add `DeathDisposition` as the single place for inventory/key-item/battalion
   hooks. The first implementation can preserve today's no-inventory behavior.
4. Add `DeathLifecycle.handle_death(ctx)`.
   - Set incapacitation according to existing `GameState.permadeath_enabled`.
   - Release Pair Up support through the existing registry hook.
   - Unregister the unit.
   - Emit one death event/result.
   - Queue-free the unit.
5. Change `Unit.handle_death()` into a compatibility wrapper that builds a basic
   combat-less context and delegates to `DeathLifecycle`.
6. Change `CombatResolver.apply_combat_result()` to build explicit
   `DeathContext` objects for defender and attacker deaths.
7. Preserve the existing simultaneous-death ordering: snapshot both death states
   before disposition, then resolve defender first, attacker second.

Tests:

- Combat death uses `DeathLifecycle` and leaves the same visible result as
  today's behavior.
- Mutual death snapshots both units before either is removed.
- Permadeath sets `UnitData.is_incapacitated`; non-permadeath does not.
- Pair Up support release still fires.
- Death event emits once per dead unit.
- A DeathDisposition no-op keeps inventory untouched in this first slice.

F1 obligations:

- Confirm rows for `UnitData.is_incapacitated`, `UnitData.inventory`, key-item
  custody fields if added, and battalion/object fields if those hooks move from
  no-op to mutation.

DoD#2 obligations:

- When a second non-combat death cause lands, add a guard that direct
  death/disposition paths are not called outside `DeathLifecycle` or the
  compatibility wrapper.

## Slice 6 - `B2-PROJECTION`: Projection / Forecast Service

**Goal:** introduce one dry-run path without duplicating combat math or advancing
committed RNG history.

Files to create or touch:

- `scripts/projection/ProjectionContext.gd`
- `scripts/projection/ProjectionResult.gd`
- `scripts/autoloads/ProjectionService.gd`
- `scripts/core/CombatResolver.gd`
- `scripts/ui/AttackPreview.gd`
- `scripts/tests/test_projection_service.gd`
- `scripts/tests/test_combat.gd`

Implementation steps:

1. Add `ProjectionContext` with kind, audience, actor, subject, targets, source,
   action spec, state view, knowledge policy, RNG mode, pipeline flags, reason,
   parent id, and budget.
2. Add `ProjectionResult` with valid, failure reason, visible outcome,
   knowledge flags, state deltas, projected events, RNG summary, warnings, and a
   debug/test-only real outcome.
3. Add `ProjectionService.project(ctx)`.
4. First adapter: `kind = "combat"` delegates to `CombatResolver.preview_combat`
   and wraps the result in `ProjectionResult`.
5. Add no-mutation guards around the adapter:
   - unit HP and stats,
   - `UnitData.active_modifiers`,
   - skill counters,
   - resources,
   - event latches if present,
   - `RngService` committed state.
6. Switch `AttackPreview` to call `ProjectionService.project_combat()` once the
   wrapper passes tests.
7. Defer deeper effect/condition/AI projection until those systems attach.

Tests:

- Combat projection returns the same displayed numbers as `preview_combat`.
- Projection leaves unit state unchanged after modifier-bearing preview.
- Projection reports odds or displayed chance without committed RNG draws.
- Projection leaves `GameState.party_gold` and other resource fields unchanged.
- Invalid target returns a structured failure, not a crash.

F1 obligations:

- No saved state is added in this slice.
- Add explicit no-save/no-mutation fixture coverage before AI or predicate
  consumers attach.

DoD#2 obligations:

- Add a test guard that projection does not mutate known save fields.
- Do not add a lint against preview helpers yet; combat preview remains the first
  adapter until the service owns the call site.

## Slice 7 - `B2-DATAMANAGER-SEAMS`: Load/Validate/Replace-Load Seams

**Goal:** split DataManager into explicit load, validate, and report phases, and
add the self-contained campaign replace-load seam without building campaign
sharing/import.

Files to touch:

- `scripts/autoloads/DataManager.gd`
- `scripts/shared/ResourceManifest.gd` if source enumeration needs one helper
- `scripts/tests/test_data_manager.gd`
- `scripts/tests/test_data_layer.gd`

Implementation steps:

1. Add content source constants for the existing `res://data/` directories.
2. Add `_clear_content()` to reset `_classes`, `_weapons`, `_items`, and
   `_skills`.
3. Add `_load_all(source := DEFAULT_CONTENT_SOURCE)` that loads the four
   catalogues from the selected source.
4. Add `_validate_all() -> Array[String]` that folds:
   - `skill.validate()` warnings that can be represented as strings,
   - `collect_validation_errors(...)`,
   - `collect_map_registry_validation_errors(...)`,
   - registry validation checks from `RegistryManager`.
5. Add `_report(errors: Array[String])`.
6. Change `_ready()` to:
   `_clear_content(); _load_all(DEFAULT_CONTENT_SOURCE); _report(_validate_all())`.
7. Add `select_campaign(campaign)` or `select_campaign_source(source)` as the
   replace-load seam:
   `_clear_content(); _load_all(source); _report(_validate_all())`.
8. Do not add `_apply_overlay()` or merge semantics.
9. Do not enumerate `user://` campaigns or copy seed data in this slice.

Tests:

- Existing direct boot loads the same catalogue ids as before.
- `_validate_all()` returns no errors for live data.
- A fixture with bad skill/class/map references returns all expected errors
  through one channel.
- `select_campaign_source(DEFAULT_CONTENT_SOURCE)` produces the same ids as
  direct boot.
- A fake alternate source replace-load clears old ids before loading new ids.
- Passing a non-default source with missing catalogues fails loud.

F1 obligations:

- If selected campaign source id is persisted, reserve the row before wiring it
  into save/load.
- The seam itself can stay unsaved until campaign selection exists.

DoD#2 obligations:

- No new checkable rule is ratified by this refactor.
- When campaign import/export lands later, add checks for package identity,
  content id stability, and registry reference validation in that change.

## Implementation Commit Order

Recommended logical commits:

1. `B2-REGISTRY` loader and first registry tests.
2. `B2-ACTION-EFFECT` runner plus `ItemHandler.stat_buff` migration.
3. `B2-RESOURCE-LEDGER` party/unit gold transactions plus direct-write guard.
4. `B2-OCCUPANCY` service plus map-start spawn migration.
5. `B2-DEATH-LIFECYCLE` combat death funnel.
6. `B2-PROJECTION` service and `AttackPreview` adapter.
7. `B2-DATAMANAGER-SEAMS` load/validate/replace-load refactor.

If a slice changes player-visible behavior, update the affected `GDD_01`,
`GDD_02`, `GDD_04`, `GDD_06`, `GDD_07`, `GDD_08`, and/or `GDD_10_Roadmap.md`
status rows in the same commit.

## Verification Checklist

Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Run targeted tests as the slice demands:

```bash
godot --headless --path /workspace --script res://scripts/tests/test_registry_manager.gd
godot --headless --path /workspace --script res://scripts/tests/test_action_effect_runner.gd
godot --headless --path /workspace --script res://scripts/tests/test_resource_ledger.gd
godot --headless --path /workspace --script res://scripts/tests/test_occupancy_service.gd
godot --headless --path /workspace --script res://scripts/tests/test_death_lifecycle.gd
godot --headless --path /workspace --script res://scripts/tests/test_projection_service.gd
godot --headless --path /workspace --script res://scripts/tests/test_data_manager.gd
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
git diff --check
```
