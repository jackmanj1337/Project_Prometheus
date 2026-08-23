---
Role: dated
---

# Pass 2 — Determinism: state capture + RNG + combat

> Part of the v0.3.0 full-scan (`AGENT/Code Reviews/v030_full_scan/`).
> Boundary: `ab81a21`..`b7bcfd2`. Document-only; no production edits.

## Files read (at head `b7bcfd2`, via working tree — no production code lands after `b7bcfd2`)

- `scripts/autoloads/RngService.gd` (87 lines, new in delta)
- `scripts/autoloads/GameState.gd` (688 lines; +341/−154 in delta — suspend-save
  capture/restore machinery + RNG snapshot)
- `scripts/core/CombatResolver.gd` (read §hit-formula registry, §event records,
  §single-attack + §resolve/apply RNG plumbing; +157 in delta)
- `scripts/skills/SkillHandler.gd` (activation-roll RNG change; +14 in delta)
- `scripts/core/EnemyAI.gd` (per-action RNG commit change; +60 in delta)
- `scripts/resources/CampaignRules.gd` (stub → live; +16 in delta)
- `scripts/resources/UnitData.gd` (snapshot-contract doc update; +4 in delta)

Cross-referenced (Pass 5 files, read only to confirm the determinism seam):
`scripts/core/GameMap.gd` (map bring-up / resume), `scripts/core/TurnManager.gd`
(`_original_tiles` lifecycle, `commit_action_event`, `make_move_record`,
`get_action_start_tile`). Cross-referenced tests: `test_rng_service.gd`,
`test_rng_snapshot.gd`, `test_rng_combat_determinism.gd`, `test_rng_usage_lint.gd`,
`test_suspend_map_runtime.gd`.

## Summary

The determinism substrate is well-built. `RngService` is a frozen SplitMix64-style
mixer with a per-event `begin_event`/`commit_event` API; combat draws every roll
from the event RNG in canonical order (all draws consumed even on a miss, so roll
order never depends on outcome); the hit resolver is a clean open registry
(`_hit_resolvers` dict + predicate callables) matching the project's
open-registry principle; `SkillHandler` now draws activation from the event RNG
and **fails loudly** when a live path forgot to seed one; `EnemyAI` now commits
exactly one RNG event per completed action (attack in `apply_combat_result`, staff
in `_try_staff_heal`, else a Wait) so red chains identically to blue. The
`_original_tiles` stale-pre-move-tile hazard I chased is explicitly defused
(erased on `set_unit_state(DONE)` and on faction refresh, *after* the record is
built).

**One confirmed High** (carried from the 6/10 delta review, re-confirmed
in-context): fresh maps never seed the RNG. Everything else is Low.

## Findings

### H1 — Fresh maps never call `RngService.start_map()`; production RNG runs unseeded
`scripts/autoloads/RngService.gd:21` (never called in production) ·
`scripts/core/GameMap.gd:114-127` (fresh-map bring-up, the missing call site)

Confirmed by grep: the only non-test callers of `start_map` are
`TurnManager.start_map` (a *different* method) at `GameMap.gd:127` — nothing calls
`RngService.start_map`. Only `scripts/tests/*` call it (they seed manually).

On the fresh-map branch (`GameMap.gd:114`, `is_resuming == false`):
```gdscript
if not is_resuming:
    gs.call("take_map_snapshot")     # line 115 — captures RngService.to_save_dict()
...
_turn_manager.start_map(map_data, _grid)   # line 127 — TurnManager, NOT RngService
```
So `RngService.map_seed` is never rolled (stays `0`, the field default) and
`history_hash` is never reset to `0` at map start. Because
`begin_event` seeds each roll from `mix(map_seed, history_hash, record…)`
(`RngService.gd:33-40`), the consequences are:

1. **Zero entropy across sessions.** `_entropy_seed()` (`RngService.gd:83-86`)
   never runs, so `map_seed` is always `0`. Two playthroughs that make the same
   committed moves draw byte-identical dice — every hit/crit/skill-activation/
   level-up roll is predictable across runs. This defeats the point of
   `_entropy_seed()` and the design's per-map fresh seed (§2).
2. **`history_hash` bleeds between maps.** Without the `start_map` reset, map *N*'s
   dice chain continues from map *N−1*'s ending hash rather than restarting at `0`.
3. **Retry snapshots the unseeded chain.** `take_map_snapshot` (line 115) captures
   `_snapshot_rng = {map_seed: 0, history_hash: <carried>}` (`GameState.gd:647-648`),
   so a Retry replays on the zero seed too.

**Scope of the damage (what it does *not* break):** in-session determinism still
holds (same committed sequence → same rolls), and suspend/resume is unaffected —
the resume branch (`GameMap.gd:120` → `_apply_suspend_resume` →
`RngService.from_save_dict`) correctly restores both ints. The defect is purely
the *fresh*-map seeding: no cross-session entropy, no per-map history reset.

**Root cause:** `start_map()` was written and unit-tested, but never wired into
production bring-up. Every RNG test seeds manually (`test_rng_service`,
`test_rng_snapshot`, `test_rng_combat_determinism` all call `start_map(seed)`), so
the suite is green while production never rolls a seed — the classic
"tests seed, production forgets" gap.

**Recommended fix (lands in Pass 5's `GameMap`):** on the fresh-map branch call
`RngService.start_map()` **before** `take_map_snapshot()` (i.e. before line 115),
so the snapshot captures the freshly-rolled seed. Leave the resume branch alone.
A regression test should assert `map_seed != 0` after a fresh
`GameMap` bring-up (not just after a manual `start_map`).

### L1 — Stale "not yet wired" comment in `_current_hit_formula`
`scripts/core/CombatResolver.gd:124-126`
```gdscript
# CampaignRules.hit_formula selects the resolver (CRR-4; campaign-default
# scope). GameState.campaign_rules lands with the Slice 6 CampaignRules
# consolidation — until then gs.get() returns null and the default applies.
```
`GameState.campaign_rules` already landed (B1-CST, `625c00d`, 2026-07-06) and is a
live object; `gs.get("campaign_rules")` no longer returns `null`, so the
`hit_formula` lookup on line 132 is live, not defaulted. The code is correct — the
comment is stale and now misleading. Fix: drop the "until then … null" clause.

### L2 — `_string_array_from_variant` duplicated across 4 files
`scripts/autoloads/GameState.gd:577` · `scripts/core/TurnManager.gd:235` ·
`scripts/save/SaveCodec.gd:232` · `scripts/save/SaveData.gd:440`

The same typed-coercer body is copied four times (and `GameState._variant_int`
overlaps SaveCodec/SaveData's int coercers — see Pass 1 L4). Three-plus copies of
identical logic is the shared-helper threshold in the code-pillar checklist (§4.B).
`SaveCodec` already holds the static save-layer coercers; the loose ones on
`GameState`/`TurnManager` could delegate to it (or a small `Coerce` util). Low —
pure cleanup, no behavior change; extends Pass 1 L4 to the determinism files.

## Carried-finding disposition

- **High — `RngService.start_map()` on fresh maps** → **CONFIRMED in-context** as H1
  above. The fix site is Pass 5 (`GameMap` startup order); the root determinism
  defect is owned here.

## Positive observations

1. **Roll order is outcome-independent.** `_resolve_single_attack` draws the
   resolver's full `hit_rn_count` even on a miss (`CombatResolver.gd:544-547`), and
   crit is a single draw only after a hit — so the dice cursor advances the same
   amount regardless of hit/miss, which is exactly what keeps replay stable.
2. **`EnemyAI` now chains identically to blue.** Every completed AI action commits
   exactly one event — attack (`apply_combat_result`), staff (`_try_staff_heal`),
   or an explicit Wait fallback on every early/no-op branch
   (`EnemyAI.gd:95,140,144,161,171,186,204`) — closing a real red-vs-blue desync.
3. **Loud-fail over silent desync.** `SkillHandler.apply_trigger` `push_error`s and
   draws nothing when a non-preview activation roll has no `context["rng"]`
   (`SkillHandler.gd:189-197`) instead of falling back to raw `randi()` — a plumbing
   bug surfaces instead of quietly corrupting the chain.
4. **`_original_tiles` stale-tile hazard is explicitly handled.** Erased on
   `set_unit_state(DONE)` (`TurnManager.gd:604-609`) and faction refresh
   (`:386,592`), *after* the event record is built, with comments naming the
   replay-desync risk it guards.
