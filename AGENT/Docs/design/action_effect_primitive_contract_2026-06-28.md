---
Role: dated
Type: design
Status: Active - architecture contract
Last verified: 2026-06-28
---

# Action / Effect Primitive Contract

**Started:** 2026-06-28. Created from H2 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Purpose.** This is the master mutation contract for state-changing authored
primitives. It prevents separate MET, dialogue, activation, shop, source/style,
and objective runners from developing incompatible behavior.

## Required Consumers

All state-mutating primitives should route through this contract:
- MET actions and DTR `on_break` actions,
- DLG commands that mutate game state,
- SAC `activate` actions and panel side effects,
- STY `EffectSpec` commit behavior,
- TCV variable/objective actions such as `set_var` and `end_map`,
- FOW/map-object actions such as lighting a brazier,
- shop, arena, training, battalion, and resource side effects.

Presentation-only effects may use a separate presentation registry, but any
state mutation still delegates here.

## Primitive Declaration

Each primitive declares:
- `id`: registry id for the primitive.
- `domain`: `map_event`, `dialogue`, `source_style`, `map_object`, `economy`,
  `objective`, or another registered domain.
- `schema`: parameter shape and defaults.
- `subjects`: required actor, target, item/source, object, tile, event, or
  variable bindings.
- `safe_point`: when the primitive may run.
- `preview_support`: none, validation-only, or full projection.
- `rng_policy`: no RNG, committed stream, latched result, or delegated RNG.
- `cost_policy`: whether it asks the ResourceLedger for a transaction.
- `save_side_effects`: manifest fields it can touch.
- `events_emitted`: event ids and result ids emitted after commit.

## ActionContext

Runtime execution receives a context object with:
- acting unit/object/event id,
- source id and domain,
- target refs and tile refs,
- trigger/event metadata,
- loaded state view,
- active safe point,
- resource transaction sink,
- RNG stream handle,
- projection/dry-run flag,
- result collector,
- validation error collector.

Consumers do not pass loose dictionaries directly into feature-specific
branches; they build this context and ask the primitive registry to validate or
commit.

## ActionResult

Every commit returns:
- `ok`,
- structured `failure_reason`,
- committed state deltas or affected ids,
- events emitted,
- resources spent/refunded,
- RNG draws consumed,
- save fields touched,
- UI/result messages safe to present.

## Invariants

1. Validation, projection, and commit share ids and subject binding rules.
2. Commit is atomic at the primitive level. Partial failure reports a result
   instead of silently applying half the effect.
3. RNG access goes through the registered RNG policy.
4. Resource spending goes through the ResourceLedger.
5. Death effects route through `handle_death(ctx)`.
6. Placement effects route through the occupancy transaction service.
7. Save side effects map back to the F1 schema manifest.

## Relation To Other Contracts

- Projection asks what would happen; this contract commits it.
- Registry manifests define how primitive ids are declared and validated.
- ResourceLedger owns affordability and spending.
- DeathLifecycle owns unit death and disposition.
- OccupancyTransaction owns non-move placement and forced movement.

## Test Obligations

Tests should cover:
- unknown primitive id fails load validation,
- malformed parameters fail with structured errors,
- validation-only and commit paths agree on subject requirements,
- dry-run/projection does not mutate state,
- failed resource transaction prevents commit,
- RNG use is recorded through the expected stream,
- one primitive can be called from at least two domains without duplicate logic.
