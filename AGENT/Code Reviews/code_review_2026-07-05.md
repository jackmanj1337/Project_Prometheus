---
Role: dated
---

# Pillar 1 - Code Review (2026-07-05)

> **Pillar:** 1 - Code
> **Procedure:** `AGENT/Review Procedures/01_Code_Pillar.md`
> **Snapshot:** branch `v0.3.0-features`, commit `914dd025ea8fbd898e5dbbc7c8ed7a6441cbf4dc`
> **Previous review:** `AGENT/Code Reviews/code_review_2026-06-19.md`

**Score:** 7/10

## Executive Summary

Recent gameplay code is generally careful: headless autoload access uses `/root`
lookups, the MRD overlay work uses a registry instead of repaint-order switches,
and the core test suite is green. The largest issue is the new inline spawn seam:
it has two contract mismatches that can silently change generated/editor-baked
encounter behavior.

## Issues

### High - Inline enemy placements lose their authored `ai_profile`

Location: `scripts/core/GameMap.gd:206`, `scripts/core/GameMap.gd:209`,
`scripts/resources/MapData.gd:14`, `scripts/resources/UnitData.gd:66`

`_resolve_placement_unit_data()` now accepts an inline `UnitData` and returns a
fresh duplicate. Immediately after that, `_spawn_units()` does:

```gdscript
u_data.ai_profile = placement.get("ai_profile", "basic")
```

For generated/editor-baked inline units, omitting the optional placement-level
`ai_profile` erases the `UnitData.ai_profile` already on the object and resets it to
`basic`. That is wrong for the seam's stated consumers: generated skirmish forces,
editor-baked units, and reinforcements may legitimately carry their AI selection on
the generated `UnitData`.

Recommended fix: default the override to the duplicated unit's existing profile:
`u_data.ai_profile = String(placement.get("ai_profile", u_data.ai_profile))`. Add a
spawn-seam test where inline `UnitData.ai_profile = "healer"` survives when the
placement omits `ai_profile`, and a second test where an explicit placement override
still wins.

### Medium - Runtime placement resolver still accepts a shape validation rejects

Location: `scripts/core/GameMap.gd:224`, `scripts/autoloads/DataManager.gd:416`,
`scripts/tests/test_spawn_seam.gd:62`

`DataManager` rejects placements that provide both `unit_data_path` and inline
`unit_data`. The runtime resolver still silently accepts that malformed placement by
letting inline `unit_data` win, and the test suite still asserts "instance wins when
both keys are present." Validation errors are emitted at boot, but they do not make
the runtime branch unreachable; the resolver should follow the same exactly-one
contract and fail loud.

Recommended fix: make `_resolve_placement_unit_data()` return `null` and log an
error when both sources are present, then update `test_spawn_seam.gd`.

### Medium - Several author-facing vocabularies still use closed code dispatch

Location: `scripts/autoloads/DataManager.gd:13`, `scripts/autoloads/DataManager.gd:15`,
`scripts/autoloads/DataManager.gd:16`, `scripts/autoloads/DataManager.gd:124`,
`scripts/core/EnemyAI.gd:83`, `scripts/core/TurnManager.gd:731`,
`scripts/resources/ObjectiveCondition.gd:60`, `scripts/items/ItemHandler.gd:6`,
`scripts/shared/TileActions.gd:33`

The project architecture rule says growing author vocabularies should be open
registries, not hardcoded enum/match lists. Live code still has closed lists for
roster policy, activation mode, objective types, AI profiles, stat names, item
effects, and tile actions. Some are already targeted by Band 2/Band 5 work, but
today an author-visible addition still requires engine edits in multiple places.

Recommended fix: keep routing these through the existing tracked build rows
(`B2-REGISTRY`, `B5-AI-COMPOSITION`, `B5-SKILLS-EFFECTS`, `B4-MAP-OBJECTS`,
`B3-STAT-REGISTRY`) and avoid adding new cases to these switches except as a
temporary compatibility bridge with a removal owner.

## Positive Observations

- `GridManager`'s MRD overlay registry is the right local pattern: new overlay layers
  register precedence instead of editing repaint switches.
- Recent overlay lifecycle fixes added focused regression tests and real
  `TileMapLayer` assertions.
- `DataManager.collect_map_data_validation_errors()` is now pure enough to test
  directly, which made the inline-placement validation fix straightforward.

## Delta Vs Previous Review

The 2026-06-19 slice review's low-severity findings were acted on. New findings are
clustered around the 2026-07-05 spawn-seam work and the broader open-registry
migration debt surfaced by the later design sweep.

## Prioritized Action Plan

1. Fix inline `ai_profile` preservation and add tests.
2. Align `_resolve_placement_unit_data()` with DataManager's exactly-one contract.
3. Treat each future addition to the closed vocabularies as a trigger to build the
   relevant registry slice rather than adding another branch.
