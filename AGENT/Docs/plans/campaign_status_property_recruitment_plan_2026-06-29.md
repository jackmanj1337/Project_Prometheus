---
Type: plan
Status: Active - planning input
Last verified: 2026-06-29
---

# Campaign Status, Property Capture, Recruit Stores, And Strategic AI

**Started:** 2026-06-29. Planning note for three owner-approved feature
directions that should enter the Project Control Plane without disrupting the
Band 1 save/determinism order.

**Purpose.** Keep these ideas buildable later by placing them on the tracker,
assigning dependencies, and recording the first implementation shape. This is
not an implementation plan yet; each row still needs a build plan when its
prerequisites exist.

## Decisions Captured

- Campaign run carry-forward should use a compact `CampaignStatusRecord`
  artifact, with completed-run records represented as a
  `CampaignCompletionRecord` subset.
- New campaign start should scan for compatible records, let the player choose
  one or choose none, and offer separate manual import for records from another
  system.
- Same-author sequel campaigns may import records from earlier campaigns when
  the author declares compatibility.
- The short web campaign should be able to export a record that can feed a
  larger second campaign; this makes the artifact V1-lean/stretch rather than
  purely post-v1.
- On-map property capture should be map-object driven, not terrain-switch
  driven.
- Property recruitment/production should reuse the PvP recruitment/buy screen
  shape and the existing reinforcement spawn occupancy policy.
- Recruit-store stock is author-defined at the store, store-group, or campaign
  default level, with predicates for visibility and price changes.
- Unit offers may point at fixed templates, generated-unit parameters, or fully
  custom named units.
- AI recruitment should start small, but the data shape should not block later
  smarter economic and role-coverage choices.

## CampaignStatusRecord Shape

`CampaignStatusRecord` is a portable artifact, not a full save. It should store
facts that future campaigns can read safely without inheriting all old runtime
state.

Suggested fields:

```json
{
  "format_version": 1,
  "record_id": "uuid-or-stable-generated-id",
  "author_id": "author",
  "campaign_id": "short_web_campaign",
  "campaign_version": "1.0.0",
  "created_at_utc": "2026-06-29T00:00:00Z",
  "completion": {
    "completed": true,
    "ending_id": "ending_a",
    "route_id": "main",
    "rank_id": "gold"
  },
  "facts": {
    "villages_saved": 3,
    "units_recruited": ["lin", "maro"],
    "story_flags": ["spared_rival"],
    "losses": ["unit_x"]
  },
  "counters": {
    "maps_completed": 5,
    "turns_taken": 91
  },
  "checksum": "content-and-record-hash"
}
```

The receiving campaign owns the import interpretation. It declares compatible
source campaign ids/versions and data-driven import rules that map record facts
to typed campaign variables, resources, unlocks, dialogue flags, or event
predicates.

Save impact:
- The artifact schema itself belongs to the campaign sharing/import path.
- A new run's save should record the chosen `record_id`, source campaign id,
  checksum, and the derived vars/resources it imported.
- Import rules should write through `CampaignVars`, resource ledger, and
  action/effect primitives instead of custom loader branches.

Tests:
- scan finds only compatible records,
- player can choose no record,
- manual import validates format/author/campaign compatibility,
- corrupted or incompatible records are rejected without changing new-run state,
- imported facts round-trip in the new save through normal save fields.

## On-Map Property Capture

Property capture is a `map_objects` component family. A property object can have
components such as:

- `capturable`: owner faction, capture points, eligible-unit predicate, capture
  power formula, reset policy, and completion action.
- `income_provider`: resource id, amount formula, timing, owner predicate.
- `repair_supply_provider`: HP/uses/pool restoration, costs, timing, and owner
  predicate.
- `hq_objective`: capture/loss objective hooks.
- `recruit_store_link`: opens a recruitment/production store when owned and
  permitted.

Capture state is saved per object:

```json
{
  "owner_faction": "blue",
  "capture_points_remaining": 12,
  "capturer_unit_id": "unit_014",
  "capture_started_turn": 4
}
```

The default capture model can mirror Advance-Wars-style capture without baking
it into the engine: `max_points = 20`, capture power formula reads current HP,
and progress resets when the capturer leaves, dies, or no longer satisfies the
predicate. Authors can override those values.

First slice:
- capture command appears for eligible units on capturable properties,
- progress and owner change save/load correctly,
- income can be awarded at faction turn start through the resource ledger,
- capture can drive objectives through typed vars or objective predicates.

Repair/supply and HQ objectives can follow. Recruitment/production is a
separate heavier slice because it touches UI, resources, spawning, and AI.

## Cursor-Activated Map Objects

Map objects need two activation modes:

- `unit_activatable`: an eligible unit stands on or adjacent to the object.
- `cursor_activatable`: the cursor can select the object directly without a
  unit occupying it.

Both modes should use permission predicates. Cursor activation is needed for
global map objects such as owned bases, aircraft hangars, command posts, puzzle
switches, or neutral inspectables. The action-menu label, valid faction, and
panel/action target all come from component data.

## Recruit Stores And Property Production

Recruitment/production stores should reuse the PHB panel shape and the PvP
recruitment/buy UI instead of creating a new screen.

Stock resolution priority:

1. Store-instance inventory.
2. Store-group inventory.
3. Campaign default recruitment inventory.

Each stock entry can define:

- visibility predicate,
- price/cost formula,
- resource costs,
- quantity or restock rule,
- unit source mode:
  - fixed template id,
  - generated-unit parameter set,
  - full custom named unit payload.

This allows themed stores without code changes. A magic school can stock spell
users; an aircraft hangar can stock airplane squadrons; a mercenary hall can
stock generated generic units.

Production from a map property should call the same occupancy transaction path
as reinforcements. Default blocked-spawn behavior should match the MET policy:
nearest valid free tile, then delay if no tile is available, with author
overrides for nearest-free, delay, or skip.

## AI Recruitment Direction

Start small:
- AI economic profiles can define budget rules, preferred stock tags, and
  minimum reserve resources.
- An AI-controlled store buys or produces from eligible visible stock when it
  can pay and a spawn tile is available.
- Initial scoring can be scripted and deterministic: "buy the highest-priority
  affordable offer that matches this store/faction profile."

Do not block future smarter AI:
- Stock entries should expose tags, roles, movement types, weapon/source access,
  cost, deployment timing, and counter tags as registry data.
- Later AI valuation can add terms for role coverage, anti-air need, healing
  shortage, capture pressure, property defense, and known enemy threats.
- These terms should feed the same AI profile/valuation registry used by combat
  AI, not a separate recruitment-only switch.

## Tracker Placement

Logical control-plane homes:

- `B6-CAMPAIGN-STATUS` — V1-lean/stretch artifact and import path.
- `B6-PROPERTY-CAPTURE` — map-object capture, ownership, income, and basic
  property effects.
- `B7-PROPERTY-RECRUITMENT` — store UI reuse, recruit inventory resolution, and
  property production/spawn.
- `B7-AI-RECRUITMENT` — small first-pass AI recruitment rules plus research
  path for smarter role/economy valuation.

These rows should not move ahead of the Band 1 save gate. They are recorded now
so F1, registry, map-object, resource, occupancy, and AI plans reserve the right
state seams.
