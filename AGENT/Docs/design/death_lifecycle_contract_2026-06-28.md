---
Type: design
Status: Active - architecture contract
Last verified: 2026-06-28
---

# Death Lifecycle Contract

**Started:** 2026-06-28. Created from M7 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Purpose.** This is the enforcement contract for unit/object death and
disposition. It turns the DTH rule into a shared funnel before F5 ticks,
hazards, ring-out, MET scripts, redirects, cover, arena, and battalion
host-death add more death causes.

## DeathContext

Every death route builds a context with:
- subject id,
- death source id and domain,
- responsible actor when any,
- timing bucket,
- snapshot of relevant inventory/key-item/battalion/object state,
- map/object/tile context,
- simultaneous-death group id when needed,
- death-mode and difficulty refs,
- event/result sink.

## Required Funnel

All death causes call:
- `handle_death(ctx)` for death entry,
- `DeathDisposition` for inventory, key items, retreat/permadeath, battalion,
  object break, EXP credit, objective notification, and cleanup.

Feature code does not directly:
- remove units from roster/map,
- drop or delete inventory,
- transfer key items,
- detach battalions,
- award death credit,
- mark objectives complete/failed from a private death branch.

## Invariants

1. Snapshot simultaneous deaths before resolving disposition.
2. Resolve disposition in deterministic order.
3. Key-item custody changes emit structured events.
4. Object-unit deaths use map-object component teardown.
5. Death side effects map to F1 manifest fields.
6. UI/log messages come from DeathResult, not feature-specific branches.

## Required Consumers

- combat lethal damage,
- F5 condition ticks,
- terrain/hazard damage,
- displacement/ring-out,
- MET/scripted kills,
- arena outcomes,
- redirect/cover/interceptor outcomes,
- battalion host death,
- attackable map objects.

## DoD#2 Hooks

Once a second non-combat death cause lands, add checks that:
- direct death/disposition helpers are not called outside the funnel,
- inventory/key-item transfer routes through DeathDisposition,
- tests cover each registered death source family,
- object-unit deaths use map-object teardown.

## Test Obligations

Tests should cover:
- combat death and condition death using the same funnel,
- simultaneous mutual death snapshot behavior,
- key-item custody transfer/drop,
- battalion detach/disposition on host death,
- object-unit break excluded from roster disposition,
- objective notification emitted once.
