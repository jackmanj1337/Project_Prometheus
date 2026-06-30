# Band 1 Implementation Questions Review (2026-06-30)

**Scope:** review-style follow-up for questions encountered while drafting the
Band 1 implementation plan. This document records risks and recommended fixes;
it does not change implementation scope by itself.

## Executive Summary

The Band 1 plan is implementation-ready, but two integration questions should be
reviewed before the relevant code slice lands. Neither should block writing
`RngService` or the F1 manifest. The highest-risk item is the combat RNG event
record, because the ratified RNG identity includes the pre-move tile but the
current `CombatResolver.resolve_combat(attacker, defender)` API receives only
current unit nodes.

## Issues Found

### [Medium] Combat RNG event records need an explicit pre-move tile source

- **File & Line:** `scripts/core/CombatResolver.gd:658`,
  `scripts/core/MapCursorTargeting.gd:197`, `scripts/core/EnemyAI.gd:125`,
  `scripts/core/EnemyAI.gd:149`, `scripts/core/TurnManager.gd:550`
- **Problem:** The RNG contract requires attack records shaped like
  `[attacker_id, from_tile, to_tile, defender_id]`, but the current combat API
  only receives `attacker` and `defender` after movement. Player and AI movement
  both call `TurnManager.record_move_start`, but that source tile is private to
  `TurnManager`.
- **Impact:** If implementation derives `from_tile` inside `CombatResolver`, it
  can accidentally use the destination tile as both `from` and `to`. That makes
  the RNG history less precise than the ratified contract and could make two
  distinct move-then-attack choices share dice.
- **Root Cause:** Combat resolution predates Package A and was designed around
  unit nodes, not action identity records.
- **Recommended Fix:** Add an explicit handoff in the first RNG slice:
  `TurnManager.get_action_start_tile(unit)` returns the recorded origin or the
  current tile, and combat callers pass an event record into
  `resolve_combat(attacker, defender, event_record := [])`. Store the same record
  on the result so `apply_combat_result` can commit exactly what was rolled.
- **Tradeoffs:** This widens `resolve_combat`'s signature and requires test/mock
  updates. The upside is a clear, reviewable action identity that works for
  player actions, AI actions, and headless tests.

### [Low] `[CST-13]` still needs a later owner decision at campaign/save kickoff

- **File & Line:** `AGENT/Docs/registers/campaign_save_open_decisions_2026-06-21.md:422`
- **Problem:** With Package A built first, the full Turnwheel mechanic is
  technically unblocked. The register leaves open whether it ships inside the
  campaign/save spine or as the immediate follow-on.
- **Impact:** Folding Turnwheel into the first `B1-CST` implementation pass could
  make the campaign/save spine too large. Deferring too far could leave defeat
  menu hooks feeling incomplete.
- **Root Cause:** `[CST-12]` re-sequenced Package A ahead of campaign/save after
  the original campaign/save plan had already scoped rewind as hooks-first.
- **Recommended Fix:** Keep this Band 1 plan hooks/kickoff-only. Revisit
  `[CST-13]` after `SaveCodec`, `SaveData`, and CampaignRules charge persistence
  exist. Default recommendation remains hooks in the spine, full mechanic as the
  immediate follow-on.
- **Tradeoffs:** The user will need one small scope call later, but the first
  campaign/save implementation remains reviewable.

## Positive Observations

- Package A algorithm and sequencing are already resolved; no RNG design
  re-litigation is needed.
- F1 already has a strong source inventory and manifest contract, so the schema
  lock can be mostly mechanical.
- Existing tests cover combat, skills/items, TurnManager, and snapshot coverage,
  giving the first RNG/save slices good regression anchors.

## Architectural Observations

- The RNG event-record handoff is the first practical pressure test of the
  project's "one action identity" discipline. It is worth making explicit now,
  before MET, DLG, Source+Style, and map objects add more action types.
- Keeping `SaveCodec` pure and file-I/O-free is important. `SaveManager` should
  not appear until the dict/envelope fixtures are stable.

## Prioritized Action Plan

1. Before editing combat RNG, add the explicit combat event-record API and tests.
2. Keep `[CST-13]` as a review item until charge persistence exists.
3. When `B1-CST` starts, decide whether Turnwheel is a spine slice or immediate
   follow-on based on the size of the completed save/flow diff.
