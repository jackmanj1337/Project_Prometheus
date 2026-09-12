---
Role: dated
Type: design
Status: Active - architecture contract
Last verified: 2026-06-28
---

# Occupancy Transaction Contract

**Started:** 2026-06-28. Created from M3 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Purpose.** This is the shared placement contract for non-standard occupancy
changes: spawn, forced movement, displacement, carry/drop, hidden overlap,
object-unit placement, and delayed placement. It prevents direct tile mutation
from bypassing occupancy policy.

## Transaction Context

Every non-move placement request declares:
- `actor` or system source,
- `subject` being placed,
- `from_tile`,
- desired `to_tile`,
- placement reason,
- collision policy,
- passability policy,
- hidden/visible occupancy knowledge policy,
- fallback policy,
- event/result sink.

## Placement Policies

Supported policies should include:
- `require_empty`: fail if occupied.
- `nearest_free`: search deterministic nearest legal tile.
- `delay`: queue the placement until a legal tile exists.
- `skip`: do nothing and report skipped.
- `swap`: legal only when an explicit swap primitive allows it.
- `overlap_hidden`: allow masked overlap only under perception/DSP rules.
- `object_unit`: place attackable objects with quarantine flags.

## Required Consumers

- MET spawn actions,
- DataManager/map-start unit placement validation,
- DisplacementService relocate/drop/push/swap variants,
- Pair-Up/carry/drop resolution,
- hidden unit overlap cleanup,
- destructible object-unit placement,
- stationary weapon operator/object state transitions,
- terrain or event effects that move a unit.

## Invariants

1. Public spawn never writes tile position directly.
2. Forced movement and carry/drop use the same occupancy service.
3. Hidden overlap is an explicit policy, not an accidental double-occupancy bug.
4. Fallback search order is deterministic.
5. Placement emits structured results for UI, logs, and tests.
6. Save state is updated through the same successful transaction.
7. Object-unit placement respects map-object component quarantine.

## Relation To Movement

Normal player movement may keep its existing move path, but any placement that
does not come from legal path traversal should enter through this transaction
contract. If the normal movement path later needs collision policy reuse, it can
delegate to the same service for final occupancy commit.

## Test Obligations

Tests should cover:
- spawn blocked tile with nearest-free fallback,
- spawn blocked tile with fail/skip/delay policy,
- forced displacement into occupied tile,
- hidden overlap resolution,
- object-unit placement and removal,
- deterministic nearest-free tie-break,
- no direct public spawn path bypasses occupancy checks.
