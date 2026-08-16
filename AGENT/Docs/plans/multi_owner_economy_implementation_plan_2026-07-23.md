---
Type: plan
Status: Planned — approved contract; implementation not started
Last verified: 2026-07-23
Decision source: campaign_data_ownership_research_findings_2026-07-23.md
Tracker: IMPL-ECONOMY-WALLET-CORE, IMPL-ECONOMY-PLAYABLE-MIGRATION
---

# Multi-Owner, Multi-Resource Economy — Implementation Plan

## Outcome and shape

Economy state is a validated wallet table keyed by structured ownership, with
`gold`, `bonus_exp`, and `training_points` supported in the first slice. Resource
definitions remain open-registry pack data; executable wallet/transaction handlers
remain engine code.

```json
{"wallets":{"faction:blue":{"owner_ref":{"kind":"faction","id":"blue"},
"lifetime":"campaign","balances":{"gold":500,"bonus_exp":20,"training_points":3}}}}
```

Allowed first-slice kinds are `faction`, `shop`, `campaign`, `unit`, `arena`.
Canonical key is `<kind>:<id>` after strict id validation, but structured refs are
serialized and key/ref agreement is verified. Shop/arena definitions must declare
`campaign`, `map`, or `transaction` lifetime; no implicit default. Campaign/faction
last the run; unit follows durable unit id. Unknown owners/resources fail closed.

## Current-state inventory

- `GameState.party_gold`; `configure_*_resume`, `capture_*_save`,
  `_capture_map_runtime_entry`, `rewind_last_action`, `restore_history`.
- `ResourceLedger.quote`, `commit`, `refund`, `_resolve_wallet`; current handlers
  resolve party/unit gold from `CostSpec.resource_id` and `scope`.
- `CostSpec.scope`, `subject_binding`, `formula_term`; binding must resolve a context
  subject to an owner ref, not gain a faction-only field.
- `TurnManager._apply_victory_rewards` credits `party_gold/party` and emits
  `total_gold`; `MapMenu._refresh_resource_summary` reads scalar gold.
- `ProjectionService` purity checks, `SaveData`/`SaveIntegrity` header codecs,
  `SaveBudgetMeasurement`, `test_ledger_entry`, save/game-state/UI tests encode the
  scalar assumption.

## Transaction and checkpoint contract

A quote contains normalized debit/credit legs `{owner_ref, resource_id, delta}` plus
a stable state version/digest. Resolve all `scope`/`subject_binding` values to owner
refs, validate owner lifecycle/resource compatibility and final non-negative bounds,
then return a side-effect-free quote. Commit revalidates every leg/version and applies
all balances atomically; any failure applies none. Refund is a new validated inverse
transaction, not an unchecked assignment. Resource definitions may later allow debt,
but v1 balances cannot finish below zero.

Every Retry/Rewind ledger entry stores the complete ordinary-wallet snapshot. Restore
validates the whole table before swapping it. Projection compares a stable full-table
snapshot/digest and may never mutate. Rewind charges remain a separate durable,
non-rewindable timeline budget: restore checkpoint first, then spend the charge from
the timeline state. They are not an ordinary wallet resource in v1.

## Incremental slices and dependencies

1. **`IMPL-ECONOMY-WALLET-CORE`** depends on pack-save schema/load seams. Add
   `OwnerRef`, wallet codec/table, three resource definitions, lifetime validation and
   multi-leg quote/commit/refund behind compatibility adapters. Migrate legacy
   `party_gold` at load to the player/blue campaign wallet only; never serialize the
   scalar again. Add full checkpoint capture/validate/restore and projection purity.
2. **`IMPL-ECONOMY-PLAYABLE-MIGRATION`** is the first shippable/playable economy
   slice and must be one green delivery sequence: migrate `GameState`, reward receiver
   context in `TurnManager`, `ResourceLedger`, `MapMenu`, results totals,
   `ProjectionService`, save/header/index codecs, measurement tools and all tests;
   remove runtime scalar reads/writes. A hotseat map rewards a selected faction owner,
   its controller sees that wallet, a shop/arena owner with explicit lifetime can be
   quoted, insufficient-resource text names resource/owner, save/load preserves all
   wallets, and Retry/Rewind restores them atomically.

Do not merge a storage-only state in which UI, rewards, headers or results still read
`party_gold`. Temporary compatibility exists only within the feature branch and old
save import boundary.

## Player rules and verification

- HUD resolves the locally viewed/acting controller's configured display wallet;
  never infer ownership from faction colour. Hotseat switching refreshes it.
- Reward definitions/context provide receiver owner; results show per-recipient deltas
  and configured campaign totals. Shop/arena panels show their owner and lifetime.
- Insufficient messages include display label, required/available amount and owner.
- Tests: owner/key validation, every kind/lifetime, unknown/duplicate owner, three
  resources, multi-wallet atomicity/refund/stale quote, legacy migration, save/header
  round trip, checkpoint corruption rollback, projection byte purity, hotseat HUD,
  reward/results and save budget.
- Windows: hotseat wallet switching, reward/results, insufficient purchase and
  Retry/Rewind display. No bespoke economy screen is required.

## Documentation, enforcement, exclusions

Product work targets `agent/integration`. Update GDD 01/04/06/07, save-schema
manifest, GDD 10, Feature Index and Control Plane. Add `check_docs.py` enforcement
for allowed owner-ref keys/lifetime vocabulary and ban new canonical `party_gold`
schema paths when those rules land. This supersedes `PP-FACTION-GOLD-ECONOMY`'s
faction-only wording and the scalar economy portions of older save/ledger plans.
Exclude rewind-resource unification, debt/interest/exchange rates, trading UI,
network ownership, faction-colour inference and general formula work beyond the
formula-registry seam.
