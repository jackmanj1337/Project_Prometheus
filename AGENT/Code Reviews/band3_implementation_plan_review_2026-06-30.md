---
Role: dated
---

# Band 3 Implementation Plan Review — Owner Questions (2026-06-30)

**Scope:** review-style follow-up for the three sequencing/scope decisions
surfaced while drafting
[`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](../Docs/plans/band3_core_authoring_foundations_implementation_plan_2026-06-30.md).
The plan picks a provisional answer for each so drafting could continue; this
doc records the forks so we can confirm or change them. None blocks the plan
existing — they may reorder or trim slices once decided.

## Executive Summary

The combined Band 3 plan is implementation-ready behind the Band 1/2 gates. The
bootstrap order (`B2-REGISTRY` -> stat/movement registries -> `TEXT` -> `TCV` ->
`REQ` -> `CAMPAIGN-RULES` -> `COMBAT-ROLL-RESOLVER` -> `MET`/`PHB` ->
`RESOURCE-POOLS`) is fixed by hard dependencies and is not in question. Only the
three items below are genuine owner forks.

## Questions

### Q1 — Per-map override scope in v1?

- **Question:** Does any Band 3 vocabulary need a per-map override scope in v1,
  or is campaign-default scope enough for the first plan?
- **Provisional answer (in the plan):** Campaign-default scope only, matching
  `CRR-4`. `TCV` map-scope variables stay part of `TCV` core (per-map transient
  vars are a defined `TCV-1` scope, not an "override"). `CampaignRules`/tunables
  and `hit_formula` are campaign-scope; no per-map rule override is built.
- **Why:** Per-map overrides multiply the save surface and the validation matrix
  for no named v1 consumer. The `MET` `set_var` action already gives authors a
  per-map *runtime* change without a separate override scope.
- **Cost if we change later:** Low — adding a per-map override layer is additive
  (a scope tag on the var/knob def + a resolution order), not a rewrite.
- **Recommendation:** Keep campaign-default-only for v1.
- **Resolution (owner, 2026-06-30):** Accepted — campaign-default-only for v1.
  Per-map overrides are **delayed but given a named scheduled slot**: control-
  plane row `B6-PER-MAP-OVERRIDES` (Band 6 stretch, status Deferred), depending
  on `B3-TCV`/`B3-CAMPAIGN-RULES`/`B3-REQ` so it can only follow those
  foundations.

### Q2 — `B3-COMBAT-ROLL-RESOLVER`: late slice or its own follow-on plan?

- **Question:** Sequence the resolver registry promotion as a late slice (after
  `B3-CAMPAIGN-RULES`) inside this combined plan, or split it into its own
  follow-on plan like the movement/stat sub-plans?
- **Provisional answer (in the plan):** Late slice (Slice 7) inside this plan.
- **Why:** Unlike movement/stat (which are large, self-contained registry
  conversions with their own contracts), the resolver work is small — promote
  two already-shipped built-ins (`single_roll`/`two_roll`) to registry data and
  add one sandboxed-expression author tier. It is tightly coupled to
  `B3-CAMPAIGN-RULES` (reads `hit_formula`) and `B2-REGISTRY`, so it reads
  cleanly as a slice.
- **Recommendation:** Keep it as Slice 7. Split only if the sandboxed-expression
  tier grows its own contract doc.

### Q3 — Is `B3-RESOURCE-POOLS` in the first Band 3 plan?

- **Question:** Include `B3-RESOURCE-POOLS` in the first plan, or defer it until
  a concrete training/shop consumer pulls it forward?
- **Provisional answer (in the plan):** Included as a **substrate-only** slice
  (Slice 10) — the `resource_type` registry + the two-scope wallet/pool data
  model over the Band 2 ledger — with **all** training/shop wiring deferred to
  Band 4 consumers.
- **Why:** The `REQ-12` `pool:<id>` value-term sources and the `B2-RESOURCE-
  LEDGER` keyed-resource path both reference this model, so defining the data
  shape now keeps those clean. Building the *substrate* is cheap; building
  *consumers* (training hall, shop) is what should wait.
- **Tension to confirm:** The control plane lists `B2-RESOURCE-LEDGER` with a
  dependency on `B3-RESOURCE-POOLS`. If we want the ledger's custom-resource
  path to land in Band 2, the resource-type registry must exist by then —
  another reason to keep the substrate in this plan rather than defer it whole.
- **Recommendation:** Keep the substrate-only slice in this plan; defer
  consumers.

### Q4 — `B3-CALENDAR-LITE`: deferred, or a real Band 3 slice? (owner-raised)

- **Why it was deferred originally:** the prior decision (unified-GDD-pass
  follow-ups) introduced only two speculative counters
  (`total_maps_played`/`story_maps_played`) with **no consumer reading them**.
  The standing rule (don't build vocabulary before a consumer needs it) parked
  it. "Needs a use case" meant *no named consumer*, not *hard*.
- **Owner input (2026-06-30):** named four consumers — in-world date in
  dialogue, overworld encounter spawning, post-combat date-advance
  events/dialogue, and shop inventory refresh — which removes the deferral
  basis.
- **Resolution (owner):** promote to a **substrate-only** Band 3 slice
  (Slice 11). Advance model = **per-node authored advance** (`advance_days` per
  progression node). Representation = **structured calendar** (authored
  months/seasons, derived from a flat day counter). Consumers stay in their own
  bands (dialogue = Band 4, shop refresh = Band 4 / PHB cadence, overworld
  spawns = post-v1 overworld).

## Decision Capture

Record answers here when reviewed; if any answer changes, update the plan's
slice order and the **Open Owner Questions** section in the same commit.

- Q1: **Accepted** (owner) — campaign-default-only for v1; per-map overrides
  tracked as the deferred `B6-PER-MAP-OVERRIDES` control-plane row.
- Q2: **Accepted** (owner: "looks fine") — combat-roll-resolver is Slice 7.
- Q3: **Accepted** (owner: "looks fine") — resource-pools is a substrate-only
  slice.
- Q4: **Resolved** (owner) — calendar-lite promoted to Slice 11, per-node
  advance + structured calendar, substrate only.
