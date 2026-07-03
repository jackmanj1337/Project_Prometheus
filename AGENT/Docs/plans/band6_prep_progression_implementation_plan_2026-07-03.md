---
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-03
---

# Band 6 Prep Progression Implementation Plan (Bonus-EXP + Training Halls)

**Started:** 2026-07-03.

**Track IDs:** `B6-PREP-PROGRESSION`.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 6 rows. Drafted from the RESOLVED registers `[BEA-1..9]`
([`bonus_exp_arena_open_questions_2026-06-27.md`](../registers/bonus_exp_arena_open_questions_2026-06-27.md))
and `[THL-1..8]`
([`training_halls_open_questions_2026-06-27.md`](../registers/training_halls_open_questions_2026-06-27.md)),
confirmed **in v1** by the owner (2026-07-03d). Covers bonus-EXP + training halls +
recruit-purchase (`[THL-8]`, pulled in 2026-07-03d, Slice 5); **Arena** is the
sibling [`band7_arena_implementation_plan_2026-07-03.md`](band7_arena_implementation_plan_2026-07-03.md).

## Purpose

Build the two prep-hub **EXP/character-investment sinks** — almost entirely reuse.
Both are **F9 PHB opt-in prep panels** (`[PHB]`), on-map-placeable via `[SAC]`.
**Bonus-EXP** feeds a player-chosen amount from a banked campaign pool into
`Unit.add_exp()` (no new leveling code). **Training halls** generalize the firmed
proficiency-XP offer (`[PXP-9]`) to **all** non-transferable per-character benefits
(class XP, weapon XP, stat, skill, source, style), each routed to the system that
already owns it. The only genuinely new operations are the **permanent stat-gain
primitive** (`[THL-3]`, which also unlocks FE stat-booster items) and the
**two-scope resource wallet** (`[THL-4]`).

The training-hall offer is an **open registry of benefit types** ([EXT]) — adding a
benefit type is data + a route to an existing system, not an engine switch.

This is a build plan only. It does not authorize starting before the gates land.

## Scope

1. **Permanent stat-gain primitive (`[THL-3]`).** A shared
   `apply_permanent_stat_gain(stat, n, cap)` raising the **stored** stat
   (`[STM]` base / `extra_stats`), capped (default = class stat cap). The **same
   primitive backs FE stat-booster items** — one operation, two consumers.
2. **Two-scope resource wallet (`[THL-4]`).** Generalize `party_gold` to a
   roster-shared multi-resource wallet (`{resource_id: amount}`) + charge from the
   F7 per-unit pools (`[CEX-1..4]`); a cost references resources by `{id, scope}`.
   A **general** capability — any system can charge a roster or per-unit resource
   (extends `[SHP-1]`).
3. **Bonus-EXP panel (`[BEA-1..3]`, `[BEA-8]`).** A `bonus_exp` PHB panel; a banked
   campaign-wide pool (new save field) earned via a `grant_bonus_exp` award
   (objective/`[TCV]`/`[MET]` grant + optional `[DIF]` multiplier); spend feeds
   `Unit.add_exp()` → `level_up()` → `LevelUpScreen`; default 1:1 cost with an
   optional `[REQ-16]` level-scaled cost curve; capped at the level cap.
4. **Training-hall panel (`[THL-1..2]`, `[THL-5]`).** A uniform PHB panel of offers
   `{benefit_type, params, cost, gate?, cap?}`; each benefit routes to its owning
   system (`class_xp`→`add_exp`, `weapon_xp`→`advance_proficiency`, `stat`→the new
   primitive, `skill`→`earned_skills`, `source`→`[CEX]`, `style`→`[STY]`); per-offer
   `[REQ]` gate + PHB `one_shot`/`restock_every_n` cadence + optional per-offer cap.
5. **Recruit-purchase (`[THL-8]`, pulled into v1 2026-07-03d).** A roster-**add**
   offer — same offer/cost/resource machinery, but it adds a unit via the `[RCR-3]`
   `recruit()` API. Four author-selectable source modes: `grunt` (generic template),
   `authored` (a named character), `generated` (the **shared parametric generator**,
   arena plan Slice 2), `ransom` (recruit a captured prisoner, `[RCR-5]`). This is
   also the `[PVP-3]` buy-phase mechanism.

## Non-Goals

- **Arena is a separate plan** —
  [`band7_arena_implementation_plan_2026-07-03.md`](band7_arena_implementation_plan_2026-07-03.md)
  (`B7-ARENA`, also pulled into v1 2026-07-03d). It is a sibling `[PHB]` panel, not
  part of this plan; recruit-purchase (Slice 5) reuses its parametric generator.
- **Recruit-purchase is now IN v1** (`[THL-8]`, owner 2026-07-03d — Slice 5). It
  reuses the arena plan's shared parametric generator (Slice 2 there) and the
  `[RCR-3]` `recruit()` API; the `B7-PVP` / `B7-PROPERTY-RECRUITMENT` cluster consume
  this slice rather than owning it.
- **No performance/efficiency-derived Bonus-EXP** (`[BEA-2]`) — authored awards only
  in v1; a metric-derived award can ride later.
- **No new leveling code** — Bonus-EXP reuses `add_exp`/`level_up`/`LevelUpScreen`
  and inherits the random-growth determinism caveat (atlas Phase C findings).
- **No new economy state for spending** beyond the wallet — the gold ledger already
  exists.

## Source Docs

- [`bonus_exp_arena_open_questions_2026-06-27.md`](../registers/bonus_exp_arena_open_questions_2026-06-27.md)
  (`[BEA-1..9]` RESOLVED — PHB panel, banked authored-award pool, `add_exp` spend,
  arena split to B7, `[BEA-8]` save/determinism, `[BEA-9]` reuse map).
- [`training_halls_open_questions_2026-06-27.md`](../registers/training_halls_open_questions_2026-06-27.md)
  (`[THL-1..8]` RESOLVED — uniform offer panel, benefit-type routing, stat-gain
  primitive, two-scope wallet, `[REQ]` gates + caps, `[THL-6]` save reserve).
- `[PHB]` container register (opt-in prep panels, `one_shot`/restock cadence),
  `[PXP-9]` (the firmed proficiency-XP offer this generalizes), `[STM]` (stat model),
  `[SHP-1]` (resource-keyed cost this wallet extends), `[REQ-16]` (cost curve).

## Decisions Not To Reopen

- `[BEA-1]`/`[BEA-4]`/`[THL-1]`: both are F9 `[PHB]` opt-in prep panels, on-map
  placeable via `[SAC]` — no new container.
- `[BEA-2]`: banked campaign pool, earned by **authored `grant_bonus_exp` awards**
  (+ optional `[DIF]` multiplier); not performance-derived in v1.
- `[BEA-3]`: spend feeds `add_exp`; default 1:1, optional `[REQ-16]` level-scaled
  cost curve off by default; capped at the level cap.
- `[THL-2]`: each benefit routes to the system that already owns it;
  **non-transferable, baked into `UnitData`** (not items/convoy).
- `[THL-3]`: one shared `apply_permanent_stat_gain(stat, n, cap)` (default cap =
  class stat cap), also backing stat-booster items.
- `[THL-4]`: two scopes — roster-shared multi-resource wallet + per-unit F7 pools;
  `{id, scope}` cost; a general capability.
- `[THL-5]`: per-offer `[REQ]` gate + PHB cadence + optional per-offer cap; cost is
  the main limiter.
- `[BEA-8]`/`[THL-6]`: new save surface = the Bonus-EXP bank + the party resource
  wallet + optional per-offer purchase counts; stat gains ride `[STM]` extra_stats,
  per-unit pools ride F7 (both already reserved).

## Dependency Note

Plan now; implement after gates. Minimum upstream gates:

- **`B3-PHB`** — the prep-panel container both panels are. Hard gate.
- **`B4-PXP`** — `Unit.add_exp` exists (l.610) but `advance_proficiency` (weapon-XP
  benefit) is the unbuilt `[PXP-9]` engine; the `class_xp`/Bonus-EXP path needs only
  `add_exp`.
- **`B3-STAT-REGISTRY` (`[STM]`)** — the stat model the permanent-gain primitive
  writes (`extra_stats`/base). Hard gate for the `stat` benefit + stat-boosters.
- **`B2-RESOURCE-LEDGER`** — the gold ledger + the multi-resource wallet
  generalization. Hard gate for costs.
- **`B3-TCV` / objective system** — the `grant_bonus_exp` award plumbing (+ `[DIF]`
  scaling). **`B3-REQ`** — per-offer gates.
- **`B4-RECRUIT-BASIC` (`recruit()`) + the arena plan's parametric generator +
  `[RCR-5]` (ransom)** — for the Slice 5 recruit-purchase modes only; slices 1-4
  don't need them.
- Nothing here is buildable against the live tree today beyond `add_exp` reuse —
  PHB, `[STM]`, the ledger, and `advance_proficiency` are all unbuilt; drafted
  against their planned APIs, same caveat as the other Band 6 plans.

## Existing Code Touchpoints

Verified 2026-07-03 against the live tree:

- **`Unit.add_exp` (l.610)** → **`Unit.level_up` (l.823)** → `scripts/ui/LevelUpScreen.gd`
  — the level path Bonus-EXP + the `class_xp` benefit feed. **No new leveling code**
  (`[BEA-3]`/`[THL-2]`); both inherit the random-growth roll.
- **`GameState.party_gold` (l.153)** + its snapshot (`_snapshot_party_gold` l.172,
  save/restore l.479/500) — the single-resource ledger the `[THL-4]` wallet
  generalizes to `{resource_id: amount}`; extend the snapshot the same way.
- **`TurnManager.gd:1028`** (`gs.party_gold += reward_gold`) — an existing ledger
  write site; the wallet charge/credit API centralizes writes like this.
- **No `prep_panels` / PHB / `bonus_exp` / `advance_proficiency` / `extra_stats` in
  code yet** (grep clean) — PHB, the stat model, and PXP are unbuilt; drafted against
  their planned APIs.
- Tests to create/extend: new `test_bonus_exp_panel.gd`, `test_training_hall.gd`,
  `test_stat_gain_primitive.gd`, `test_resource_wallet.gd`; extend
  `test_snapshot_coverage` (bank + wallet + purchase counts).

## Slice 1 - Permanent Stat-Gain Primitive

**Goal:** the one new operation — a shared, capped, permanent stat raise. **Gated on
`B3-STAT-REGISTRY` (`[STM]`).**

Files to touch:

- the stat-model owner (`[STM]` — `extra_stats`/base writer)
- a shared `apply_permanent_stat_gain` site (Unit or a stat service)
- `scripts/tests/test_stat_gain_primitive.gd` (new)

Implementation steps:

1. `apply_permanent_stat_gain(unit, stat, n, cap)`: raise the **stored** stat
   (`[STM]` base / `extra_stats`), clamped to `cap` (default = class stat cap).
   Permanent + baked (not a removable modifier).
2. Wire it as the backing op for FE-style stat-booster **items** too (Energy Drop)
   — one primitive, two consumers (`[THL-3]`).

Tests:

- Applying `n` raises the stored stat by `n`, clamped at `cap`; a second apply past
  cap is a no-op at the cap.
- A stat-booster item routes through the same primitive.

F1 obligations: baked gains ride `[STM]` `extra_stats`/base (already reserved) — no
new field.

DoD#1 obligations: update `GDD_03` (permanent stat gain / stat-boosters) when
slice 4 exposes it.

## Slice 2 - Two-Scope Resource Wallet

**Goal:** generalize `party_gold` to a multi-resource wallet + per-unit pool charge.
**Gated on `B2-RESOURCE-LEDGER`.**

Files to touch:

- `scripts/autoloads/GameState.gd` (`party_gold` → `{resource_id: amount}` wallet +
  snapshot)
- a charge/credit API (`{id, scope}`) reading the wallet or the F7 pool
- `scripts/tests/test_resource_wallet.gd` (new)

Implementation steps:

1. Generalize the ledger: keep `gold` as a wallet entry; add author-defined
   roster-shared resources (e.g. activity points). Extend the snapshot exactly like
   `_snapshot_party_gold` (l.172/479/500).
2. `charge(cost, payer)` where a cost is `[{id, scope, amount}]`; `scope=roster`
   draws the party wallet, `scope=unit` draws the F7 per-unit pool (`[CEX-1..4]`).
   General capability — any system can charge (`[THL-4]`).

Tests:

- A roster charge debits the wallet; insufficient funds is refused atomically.
- A per-unit charge debits that unit's F7 pool only.
- The wallet round-trips through the snapshot.

F1 obligations: the party multi-resource wallet is a new save field (`[THL-6]`) —
reserve at the F1 lock.

DoD#1 obligations: update `GDD_02` (resource ledger) + flip `GDD_10`.

## Slice 3 - Bonus-EXP Panel

**Goal:** a banked pool poured into `add_exp`. **Gated on `B3-PHB` + `B3-TCV`.**

Files to touch:

- a `bonus_exp` PHB panel
- the banked pool save field + the `grant_bonus_exp` award (objective/`[TCV]`/`[MET]`)
- `scripts/tests/test_bonus_exp_panel.gd` (new)

Implementation steps:

1. Register a `bonus_exp` entry in a node's `prep_panels` (reuse `[PHB]` wholesale).
2. Add the banked campaign-wide EXP pool (new save field, `[BEA-8]`); earn via a
   `grant_bonus_exp` award fired by objectives / `[MET]` actions (same grant plumbing
   as flags/items) + optional `[DIF]` multiplier.
3. In the panel, select a unit and pour pool EXP → `Unit.add_exp()` (reuses
   `level_up` + `LevelUpScreen`). Default **1 pool point = 1 EXP**; optional
   `[REQ-16]`/`CampaignRules` level-scaled cost curve, off by default. Cap spend at
   the level cap (`add_exp` already discards past-cap + surfaces promotion).

Tests:

- A `grant_bonus_exp` award raises the pool; the pool round-trips through save.
- Pouring EXP feeds `add_exp` and levels the unit; spend is capped at the level cap.
- The optional cost curve scales cost by level when enabled; 1:1 when off.

F1 obligations: the banked pool is a new save field (`[BEA-8]`) — reserve at the F1
lock.

DoD#1 obligations: update `GDD_02`/`GDD_03` (bonus-EXP) + flip `GDD_10`.

## Slice 4 - Training-Hall Panel (Benefit Routing)

**Goal:** the uniform offer panel routing every benefit type to its owning system.
**Gated on `B3-PHB` + slices 1-2 + the per-system owners.**

Files to touch:

- a `training_hall` PHB panel + the offer model `{benefit_type, params, cost, gate?, cap?}`
- the benefit routers (add_exp / advance_proficiency / stat primitive / earned_skills
  / `[CEX]` source / `[STY]` style)
- `scripts/tests/test_training_hall.gd` (new)

Implementation steps:

1. Generalize `[PXP-9]`'s entry to an **offer** `{benefit_type, params, cost, gate?,
   cap?}`; one uniform panel, an **open registry** of benefit types.
2. Route each benefit to its owning system (all **non-transferable, baked into
   `UnitData`**): `class_xp`→`add_exp` (same path as Bonus-EXP), `weapon_xp`→
   `advance_proficiency` (`[PXP-9]`), `stat`→slice 1's primitive, `skill`→
   `earned_skills` (equip via `[LDC]` cap), `source`→`[CEX]` granted-source list,
   `style`→`[STY]` `learned_styles` (equip via `[LDC]` caps).
3. Cost via slice 2's `charge`. Gate per-offer with `[REQ]`; limit with the PHB
   `one_shot`/`restock_every_n` cadence + an optional per-offer cap.

Tests:

- Each benefit type applies through its owning system (e.g. `stat` calls the
  primitive; `class_xp` levels via `add_exp`).
- A gated offer is hidden/disabled until its `[REQ]` gate passes.
- A per-offer cap + `one_shot` cadence enforce purchase limits; the charge debits the
  right resource/scope.

F1 obligations: optional per-offer purchase counts are the only new field
(`[THL-6]`); benefit grants ride already-reserved fields (`[STM]`/`[CEX]`/`[STY]`/
`earned_skills`/F7).

DoD#1 obligations: update `GDD_03` (training hall / character investment) +
`GDD_07` (panel) + flip `GDD_10`.

DoD#2 obligations: the benefit-type set is an **open registry**, not an enum — no
closed-set `check_docs` guard (adding a type is data + a route, per [EXT]).

## Slice 5 - Recruit-Purchase

**Goal:** a roster-add offer with four source modes. **Gated on `B4-RECRUIT-BASIC`
(`recruit()`) + the arena plan's generator (Slice 2) + `[RCR-5]` for ransom.**

Files to touch:

- a recruit-purchase offer (reuse the slice-4 offer/cost/gate/cap machinery)
- the source-mode resolvers (grunt / authored / generated / ransom)
- `scripts/tests/test_recruit_purchase.gd` (new)

Implementation steps:

1. A recruit-purchase offer: same `{cost, gate?, cap?}` machinery as slice 4, but
   the effect **adds a unit** to the faction roster via the `[RCR-3]` `recruit()`
   API rather than improving one.
2. Four author-selectable source modes (`[THL-8]`): `grunt` (a generic author
   template), `authored` (a named character from the campaign pool), `generated`
   (the **shared parametric generator** — reuse the arena plan Slice 2 service, do
   not build a second one), `ransom` (a captured prisoner recruited via `recruit()`
   on the `[RCR-5]` capture end-state).
3. Charge via slice 2's `charge`; gate with `[REQ]`; cap with the PHB cadence +
   an optional roster-size cap.

Tests:

- Each source mode adds a unit: `grunt` from a template, `authored` the named unit,
  `generated` a spec-built unit (via the shared generator), `ransom` a captured
  prisoner.
- The charge debits the right resource/scope; a roster-size cap refuses over-cap
  purchases; a `[REQ]` gate hides the offer until it passes.

F1 obligations: bought recruits are new roster units (ride the roster/`UnitData`
save, already reserved); the generator param specs + grunt/authored templates are
**authoring data**, not save — no new field (`[THL-6]`).

DoD#1 obligations: update `GDD_03` (recruit-purchase / unit sources) + `GDD_07`
(panel) + flip `GDD_10`.

## Implementation Commit Order

1. Slice 1 stat-gain primitive — **trails `B3-STAT-REGISTRY`**.
2. Slice 2 two-scope resource wallet — **trails `B2-RESOURCE-LEDGER`**.
3. Slice 3 Bonus-EXP panel — **trails `B3-PHB` + `B3-TCV`**.
4. Slice 4 training-hall panel — **trails `B3-PHB` + slices 1-2 + the per-system
   owners** (`[PXP-9]`, `[CEX]`, `[STY]`, `[LDC]`).
5. Slice 5 recruit-purchase — **trails `B4-RECRUIT-BASIC` + the arena generator +
   `[RCR-5]`** (reuses slice 4's offer machinery).

Slices 3 and 4 both reuse the level path (`add_exp`, live today) but are gated by
their PHB container. Slice 5 (recruit-purchase) reuses the arena plan's shared
parametric generator — build it once, whichever consumer lands first. Arena itself
is the sibling [`band7_arena_implementation_plan_2026-07-03.md`](band7_arena_implementation_plan_2026-07-03.md).

## Verification Checklist

Same as the Band 2/3/4/5 plans. Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
```
