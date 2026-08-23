---
Role: dated
Type: plan
Status: Active - implementation plan
Last verified: 2026-06-30
---

# Band 4 Map Objects Implementation Plan

**Started:** 2026-06-30.

**Track ID:** `B4-MAP-OBJECTS`

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 4 rows. Drafted from
[`band4_implementation_plan_handoff_2026-06-30.md`](band4_implementation_plan_handoff_2026-06-30.md).

## Purpose

Turn the map-object component contract into a code-ready build sequence.
`B4-MAP-OBJECTS` is the second internal Band 4 sub-foundation: doors, chests,
villages, on-map shops, panel triggers, breakables, properties, stationary
weapons, and later activity launches must all compose through one activation
and state model.

This plan is a build plan only. It does not authorize starting `B4-MAP-OBJECTS`
before the Band 1-3 gates land.

## Scope

This plan covers the first map-object implementation run:

1. Add registry-backed map object types and component definitions.
2. Add authored object instances to `MapData`.
3. Build runtime object state with F1-backed serializers.
4. Replace the placeholder `TileActions` shop/visit/activate path with
   component-provided action records.
5. Add passability-provider integration.
6. Add activatable, cursor-activatable, panel-trigger, and state-serializer
   component handlers.
7. Add object-unit quarantine hooks for breakables represented as units.
8. Provide fixtures that prove the contract without implementing every consumer
   feature.

## Non-Goals

- Do not implement doors/chests, villages, shops, properties, stationary
  weapons, arena, training, or minigames here. This plan builds the substrate
  those consumers use.
- Do not build a bespoke shop, village, or chest action system.
- Do not add property ownership/capture beyond an inert component contract and
  validation fixture unless a Band 6 property row is pulled forward.
- Do not build fog/perception behavior here; `vision_source` can validate and
  stay idle until the owning track consumes it.
- Do not add saved object state without F1 manifest rows first.
- Do not add closed object-type switches. Object type, component type, action
  labels, and serializers are registry/data entries.

## Source Docs

- [`band4_implementation_plan_handoff_2026-06-30.md`](band4_implementation_plan_handoff_2026-06-30.md)
- [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
- [`map_object_component_contract_2026-06-28.md`](../design/map_object_component_contract_2026-06-28.md)
- [`shop_activate_configs_open_questions_2026-06-27.md`](../registers/shop_activate_configs_open_questions_2026-06-27.md)
  (`SAC-1..12`)
- [`doors_chests_open_questions_2026-06-21.md`](../registers/doors_chests_open_questions_2026-06-21.md)
- [`village_events_open_questions_2026-06-25.md`](../registers/village_events_open_questions_2026-06-25.md)
- [`prep_hub_open_questions_2026-06-23.md`](../registers/prep_hub_open_questions_2026-06-23.md)
- [`map_events_triggers_open_questions_2026-06-21.md`](../registers/map_events_triggers_open_questions_2026-06-21.md)
- [`band2_shared_runtime_contracts_implementation_plan_2026-06-30.md`](band2_shared_runtime_contracts_implementation_plan_2026-06-30.md)
- [`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](band3_core_authoring_foundations_implementation_plan_2026-06-30.md)

## Decisions Not To Reopen

- `map_objects` is the one activation model. Doors, chests, shops, villages,
  panel triggers, and levers are specialized object/component data.
- Each activate behavior carries its own author label. A tile with multiple
  activatables must expose distinct action-menu entries.
- Activation consumes the unit action by default, with an author `free` flag.
- Gating and persistence reuse `B3-REQ` and `B3-TCV`/MET state. No private flag
  store.
- Panels reuse the `B3-PHB` dual-surface: prep panel or on-map trigger, one
  panel definition.
- Per-instance panel variation lives inline on the map object, with optional
  named refs for reuse.
- State mutations route through `B2-ACTION-EFFECT` primitives when they affect
  game state.
- Object state is serialized as object state, not as hidden roster/unit state.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates before
`B4-MAP-OBJECTS` code:

- `B1-F1` for object state manifest rows.
- `B2-REGISTRY` for map object types, component families, and serializer ids.
- `B2-ACTION-EFFECT` for activation mutations.
- `B2-OCCUPANCY` for object placement, object-unit quarantine, and passability
  changes that affect occupied tiles.
- `B2-DATAMANAGER-SEAMS` for load/validate/report phases.
- `B3-REQ` for object action gates.
- `B3-MET` for event-backed actions and object event hooks.
- `B3-PHB` for panel-trigger surfaces.

## Existing Code Touchpoints

Verified 2026-06-30:

- `scripts/resources/MapData.gd` has no `map_objects` field yet.
- `scripts/shared/TileActions.gd` lists `shop`, `visit`, and `activate`, but
  they are placeholders that always return false.
- `scripts/ui/ActionMenu.gd` only reads fixed `seize`/`escape` TileActions
  records today; dynamic object actions need a row model or a generated submenu.
- `scripts/ui/HUD.gd` already displays TileActions in terrain More Info, so
  dynamic object action labels must flow through the same helper.
- `scripts/autoloads/DataManager.gd` validates map data but has no map-object
  schema checks.
- `scripts/core/GridManager.gd` owns terrain passability and movement costs but
  has no object passability providers yet.
- `scripts/core/GameMap.gd` owns map setup and unit spawning. Runtime object
  instantiation should happen beside map setup, not in scattered consumers.
- Existing tests to extend first: `test_data_manager.gd`,
  `test_tile_actions.gd`, `test_action_menu.gd`, `test_hud.gd`,
  `test_game_map_scene.gd`, and new focused map-object suites.

## Slice 0 - Preflight After Band 1-3 Gates

**Goal:** confirm the shared services are present and keep the substrate small.

Implementation checklist:

- Run `rg -n "TileActions|can_seize|can_escape|map_objects|activate|shop|visit|GridManager|passability|MapData" scripts data`.
- Confirm F1 rows exist or reserve them before code:
  `MapData.map_objects`, per-map object state, per-object latches, opened/used
  flags, object HP/uses where implemented, and panel-trigger instance state if
  persisted.
- Confirm `RegistryManager`, `ActionEffectRunner`, `OccupancyService`,
  `B3-REQ`, `B3-MET`, and `B3-PHB` exist.
- Decide which first object fixtures are behavior-preserving. Behavior-changing
  commits update the affected GDD chapter and control-plane row in the same
  commit.

Tests: none required in preflight.

## Slice 1 - Type And Component Registries

**Goal:** represent object types and components as data, not switches.

Files to create or touch:

- `scripts/resources/map_objects/MapObjectType.gd`
- `scripts/resources/map_objects/MapObjectInstance.gd`
- `scripts/resources/map_objects/MapObjectComponent.gd`
- `scripts/autoloads/DataManager.gd`
- registry preset data under the project-standard registry path
- `scripts/tests/test_map_object_registry.gd`

Implementation steps:

1. Add `MapObjectType` fields from the contract: `id`, `label_key`,
   `components`, default state fields, F1 serializer refs, footprint, action
   priority, validation schema, and optional presentation refs.
2. Add `MapObjectInstance` with authored `id`, `type_id`, `tile` or footprint,
   inline config, optional named-ref config, and initial state overrides.
3. Add component family entries for:
   `passability_provider`, `activatable`, `cursor_activatable`,
   `panel_trigger`, `state_serializer`, and `on_event`.
4. Validate duplicate object ids, unknown type ids, unknown component ids,
   missing serializer ids, invalid footprints, and malformed inline configs.
5. Seed only test fixture types: a toggle lever, a blocking gate, and a dummy
   panel trigger.

Tests:

- A data-defined object type loads without an engine switch edit.
- Duplicate object ids fail validation.
- Unknown component id fails validation.
- Two object instances can occupy one tile if their components permit it.

F1 obligations: no runtime state added in this slice beyond authored data.

DoD#2 obligations: add a validator or test that new object component families
are registry entries, not hardcoded type cases.

## Slice 2 - Runtime Object State And Serializers

**Goal:** instantiate per-map object state and make it save/snapshot safe.

Files to create or touch:

- `scripts/map_objects/MapObjectRuntime.gd`
- `scripts/map_objects/MapObjectStateStore.gd`
- `scripts/core/GameMap.gd`
- `scripts/autoloads/GameState.gd` or the Band 1 save/campaign owner selected
  for per-map state
- `scripts/tests/test_map_object_state.gd`

Implementation steps:

1. Instantiate object runtime records during map setup from `MapData.map_objects`
   plus each type's default state.
2. Keep state in a single store keyed by object id.
3. Mutate state only through component handlers or action/effect primitives.
4. Add serializer callbacks declared by component/type data.
5. Add reset/retry/suspend coverage according to the Band 1 save spine.
6. Keep authored object config separate from mutable state.

Tests:

- Default state instantiates once per object.
- State mutation survives save/load or snapshot/restore according to the active
  save path.
- Unknown serializer id fails validation.
- Authored config is not mutated when runtime state changes.

F1 obligations: object-state rows must exist before code.

## Slice 3 - Dynamic TileActions And ActionMenu Surface

**Goal:** expose object-provided actions in the same place as Seize/Escape.

Files to touch:

- `scripts/shared/TileActions.gd`
- `scripts/ui/ActionMenu.gd`
- `scripts/ui/HUD.gd`
- `scripts/core/MapCursor.gd`
- `scripts/tests/test_tile_actions.gd`
- `scripts/tests/test_action_menu.gd`
- `scripts/tests/test_hud.gd`

Implementation steps:

1. Replace placeholder `shop`/`visit`/`activate` logic with a generic object
   action query that asks map-object components for available actions.
2. Return action records, not just action ids: `id`, `object_id`,
   `component_id`, `label_key` or label, priority, availability mode
   (`hidden` or `shown_disabled`), and action-cost policy.
3. Preserve `seize` and `escape` behavior.
4. Add ActionMenu support for dynamic object rows while keeping fixed combat
   rows stable.
5. Keep HUD terrain More Info reading the same TileActions result so available
   actions do not drift.
6. On commit, route selection through a single object-action execution entry
   point.

Tests:

- Two objects on one tile expose distinct labels.
- Hidden object actions do not appear.
- Shown-disabled object actions appear disabled when ActionMenu supports that
  state; until then, keep them hidden and document the deferred UI state —
  specifically: note the temporary `shown_disabled -> hidden` degradation on
  the `SAC` register (`[SAC-1..12]`) and in the `GDD_07` section this slice
  touches, and add a control-plane note on `B4-MAP-OBJECTS` so the degradation
  is lifted when ActionMenu grows a disabled-row state (with `B6-INPUT`/UI
  polish at the latest).
- HUD More Info and ActionMenu show the same enabled object actions.
- Seize/Escape regression tests stay green.

F1 obligations: no new saved state unless action selection mutates object state
in the same slice.

## Slice 4 - Passability Provider Integration

**Goal:** let object state affect movement and tile blocking through components.

Files to touch:

- `scripts/core/GridManager.gd`
- `scripts/map_objects/MapObjectStateStore.gd`
- `scripts/tests/test_map_object_passability.gd`
- movement/threat-range tests that read passability

Implementation steps:

1. Add a passability query hook to GridManager that asks map-object runtime
   state for overlays.
2. Model blocking and state-based passability through `passability_provider`
   data.
3. Recompute affected movement/threat data after a state mutation.
4. Route occupied-tile edge cases through `B2-OCCUPANCY`; do not displace units
   ad hoc.

Tests:

- A closed gate blocks movement.
- Toggling the gate updates passability and available actions.
- A unit standing on an affected tile routes through occupancy policy or blocks
  the state change with a useful result.

F1 obligations: passability state is object state and uses Slice 2 serializers.

## Slice 5 - Activatable And Panel Trigger Handlers

**Goal:** execute object actions through shared primitives and PHB surfaces.

Files to create or touch:

- `scripts/map_objects/MapObjectActionExecutor.gd`
- `scripts/map_objects/components/ActivatableComponentHandler.gd`
- `scripts/map_objects/components/PanelTriggerComponentHandler.gd`
- `scripts/map_objects/components/OnEventComponentHandler.gd`
- `scripts/tests/test_map_object_activation.gd`

Implementation steps:

1. Build a single `execute_object_action(ctx)` entry point.
2. Resolve `B3-REQ` gates against a context containing unit, object, map, and
   campaign subjects.
3. Execute state changes and rewards through `B2-ACTION-EFFECT`.
4. Launch PHB panels through `panel_trigger` with caller context and inline or
   named-ref variation.
5. Support author `free` activation; default consumes the unit action.
6. Add `on_event` subscription hooks only through MET/EventBus bridges.

Tests:

- A toggle lever changes object state through an action primitive.
- Default activation consumes the unit action; `free` does not.
- A dummy panel trigger launches the registered PHB panel with object context.
- Gated actions respect hidden/disabled author policy.

F1 obligations: any object state mutation must use Slice 2 serializers.

## Slice 6 - Cursor Activatable Objects

**Goal:** support object actions that do not require a unit standing on the
object tile.

Files to touch:

- `scripts/shared/TileActions.gd`
- `scripts/core/MapCursor.gd`
- `scripts/tests/test_map_object_cursor_activation.gd`

Implementation steps:

1. Add cursor-action queries for selected object tiles.
2. Keep unit-on-tile actions and cursor-object actions separate in context.
3. Validate range/eligibility through component predicates.
4. Reuse the same execution entry point from Slice 5.

Tests:

- A cursor-activated object exposes an action without a unit on the tile.
- A unit-required action does not leak into cursor-only mode.
- Selection cancellation returns to the prior cursor/menu state.

F1 obligations: no additional saved fields beyond action side effects.

## Slice 7 - Object-Unit Quarantine

**Goal:** support breakables represented by units without polluting roster,
support, AI, or objective loops.

Files to touch:

- `scripts/core/GameMap.gd`
- `scripts/autoloads/GameState.gd`
- `scripts/units/Unit.gd`
- `scripts/core/CombatResolver.gd`
- `scripts/tests/test_map_object_unit_quarantine.gd`

Implementation steps:

1. Add an object-unit marker and object id back-reference.
2. Spawn object-units through `B2-OCCUPANCY`.
3. Exclude object-units from roster, convoy, support, normal AI profile
   assignment, and normal objective unit counts unless a component opts in.
4. Route break/death through `B2-DEATH-LIFECYCLE`.
5. Serialize object-unit HP/state as object state, not roster unit state.

Tests:

- Breakable object-unit is targetable when its component allows it.
- It is absent from roster/support loops.
- Breaking it mutates object state through death lifecycle.
- Save/load restores object state without creating a roster unit.

F1 obligations: object-unit state rows must exist before code.

## Slice 8 - Consumer Fixture And Cleanup Pass

**Goal:** prove the substrate is ready for DCH/shop/village consumers without
building those consumers yet.

Implementation checklist:

- Keep fixture object types clearly marked as test/dev presets.
- Add one blocking/toggle fixture, one labeled multi-action fixture, and one
  dummy panel-trigger fixture.
- Confirm `B4-DCH`, `B4-VILLAGE`, and `B4-SHOP-ECONOMY` can express their first
  action through the component schema without engine changes.
- Update `GDD_06`, `GDD_07`, `GDD_Feature_Index`, and `GDD_10` with the behavior
  changes when the build lands.
- Run the full Godot suite and docs checks.

DoD#2 obligations: add a guard that prevents new map-object features from adding
parallel `shop`/`visit`/`activate` switches instead of component records.

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
