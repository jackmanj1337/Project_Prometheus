---
Role: dated
Type: design
Status: Active - architecture contract
Last verified: 2026-06-29
---

# Map Object Component Contract

**Started:** 2026-06-28. Created from M2 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Purpose.** This is the shared contract for `map_objects`: doors, chests,
levers, shops, arenas, panel triggers, breakables, stationary weapons, braziers,
and future activatables. Object behavior is composed from registry-backed
components instead of branching by object type.

## MapObjectType Entry

Each type declares:
- `id`,
- `label_key`,
- `components`,
- default state fields,
- F1 serializer refs,
- tile footprint,
- priority for action-menu ordering,
- validation schema,
- optional scene/presentation refs.

## Component Families

Initial component families:
- `passability_provider`: supplies blocking, terrain override, or state-based
  passability.
- `activatable`: creates one or more tile actions with labels, predicates, and
  action/effect primitive refs.
- `cursor_activatable`: creates object actions that can be selected directly
  with the cursor without a unit standing on the object tile.
- `panel_trigger`: launches PHB/shop/arena/training panels with caller context.
- `capturable_property`: tracks property owner, capture progress, eligibility
  predicates, reset rules, income/repair hooks, and owner-change actions.
- `vision_source`: emits LoS/fog/perception contributions such as lit braziers.
- `attackable_object`: exposes HP, defenses, death/break route, and object-unit
  quarantine behavior.
- `ammo_or_uses`: tracks uses for stationary weapons and similar objects.
- `state_serializer`: maps object state into the F1 manifest.
- `on_event`: subscribes to MET or EventBus events through registered actions.

## Lifecycle

Object lifecycle should be explicit:
1. Load authored object data and type registry.
2. Validate components and default state.
3. Instantiate runtime state and optional presentation.
4. Register passability, vision, actions, and event hooks.
5. Mutate state only through component handlers.
6. Serialize state through the declared serializer.
7. Remove/destroy through the component teardown path.

## Object-Unit Quarantine

Breakables that are represented as Units must be marked and filtered:
- excluded from roster, convoy, support, AI profile assignment, and normal
  objective unit counts unless a component explicitly opts in,
- routed through death lifecycle on break,
- placed through the occupancy transaction service,
- serialized as object state, not roster unit state.

## Invariants

1. Adding a new object type means adding registry data/components, not editing a
   type switch.
2. TileActions asks object components for actions.
3. Cursor-driven object actions use component predicates instead of requiring a
   unit to stand on every interactive tile.
4. GridManager asks passability components for overlays.
5. FOW/perception asks vision components for light/vision sources.
6. Save/load asks state serializers for fields.
7. State mutations route through action/effect primitives when they affect game
   state.

## Test Obligations

Tests should cover:
- two objects on one tile exposing distinct action labels,
- a state change updating passability and actions,
- a cursor-activated object exposing actions without a unit on its tile,
- a capturable property changing owner and preserving capture state on save/load,
- breakable object-unit excluded from roster loops,
- stationary weapon use/ammo state save/load,
- brazier lit state contributing to vision,
- unknown component id failing validation.
