---
Role: dated
Type: design
Status: Active - architecture contract
Last verified: 2026-06-28
---

# Resource Ledger / Cost Resolver Contract

**Started:** 2026-06-28. Created from M1 in
[`design_review_unimplemented_systems_2026-06-28.md`](../../Code%20Reviews/design_review_unimplemented_systems_2026-06-28.md).

**Managed by:** [`design_review_foundation_fix_todo_2026-06-28.md`](design_review_foundation_fix_todo_2026-06-28.md).

**Purpose.** This is the shared economy transaction contract. It keeps shops,
training, source/style costs, battalions, item uses, arena fees, redirects, and
future resource spends on one affordability/commit path.

## ResourceRegistry Entry

Each resource declares:
- `id`,
- `scope`: `party`, `unit`, `item_source`, `battalion`, `map_object`,
  `campaign_var`, or another registered scope,
- `display`: label/icon/text ids,
- `default_value`,
- `min_value` and optional `max_value`,
- `persistence`: F1 manifest field or transient counter,
- `spend_policy`: allow, block, floor, overflow, or custom handler,
- `refill_policy`: map start, turn start, restock, event, or none.

## CostSpec

Each cost declares:
- resource id and scope resolver,
- amount or formula term,
- subject binding used to find the wallet,
- whether the cost is previewable,
- whether the cost is refundable,
- whether overflow or partial payment is legal,
- UI summary keys.

## Transaction API

The resolver should expose three behaviors:
- `quote`: side-effect-free affordability and rendered cost summary.
- `reserve`: optional hold for multi-step UI flows.
- `commit`: atomic spend/refund/application with a result object.

All three return a structured result with:
- `ok`,
- missing resources,
- shortfalls,
- wallets touched,
- deltas,
- failure reason,
- display summary.

## Invariants

1. UI affordability checks and commit use the same resolver.
2. Multi-resource costs commit atomically.
3. Failed costs do not mutate state.
4. Refunds use recorded transaction data, not recalculated formulas.
5. Save fields map back to the F1 manifest.
6. Resource ids and scopes are registry entries, not closed switch values.
7. Action/effect primitives do not write wallets directly.

## Known Consumers

- shops and dynamic pricing,
- training halls and roster/per-unit pools,
- source/style combo costs,
- battalion charges, endurance, and rate limits,
- item/source uses and broken/degraded modes,
- arena fees and rewards,
- redirect/cover/interceptor costs,
- difficulty/economy multipliers.

## Test Obligations

Tests should cover:
- party, unit, and source-scoped costs,
- multi-resource atomic success and failure,
- preview equals commit for deterministic costs,
- dynamic price formula with a stable subject,
- refund from recorded transaction,
- unknown resource id validation failure,
- save/load round trip for persistent wallets.
