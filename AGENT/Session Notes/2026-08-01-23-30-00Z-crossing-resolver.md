# Session Note - 2026-08-01-23-30-00Z-crossing-resolver

## Branch context

- Branch: `agent/from-integration/crossing-resolver`
- Base branch: `agent/integration`
- Base SHA: `7b1bffd6665f036733a37e02cf591fd97669b58e`
- Coordination Work ID: `IMPL-CROSSING-RESOLVER-2026-08-01`

## What was done

Built the shared crossing resolver settled yesterday as `[PCM-1..7]`
(`AGENT/Docs/design/position_change_model_decisions_2026-08-01.md`). This was
picked as the next implementable section because four ratified features wait on
it — `[FOW-4]` ambush interrupt, `[TER-7]` pass-through terrain, `[PER-8]`
`on_cross`, and traversing displacement `[PCM-4]` — and the row is explicit that
whoever builds first owns it.

**Shape.** `CrossingResolver` (`scripts/core/CrossingResolver.gd`) is an open
registry: consumers register a probe `Callable`, and nothing in the resolver
knows what fog or terrain are. It walks the path as data and returns a
`CrossingOutcome` carrying the effective (possibly truncated) path, the fired
trigger ids, `ends_activation`, and `movement_permanent`. `CrossingService` is
the autoload that owns the single instance.

**Where it hooks.** Inside `Unit.move_along_path`, before either movement
branch, rather than at the three call sites. That is the load-bearing choice:
it is the one place the Instant-speed `snap_to_tile` branch and the tween branch
both pass through, so a halt cannot fire for animated players and silently not
fire at Instant speed. `move_along_path` now returns the outcome; `MapCursor`
and both `EnemyAI` move sites consume it.

**Decisions honoured.** Halt is the default and an *unknown* interrupt value
falls back to halt, not continue (`[PCM-5]` — the safe default is the one that
cannot hide). `interrupt` and `ends_activation` stay independent axes
(`[PCM-6]`). The origin tile is not a crossing; the destination tile is.
Co-located triggers all fire even when one of them halts — the unit did enter
the tile; only further movement stops.

**Judgement call worth flagging.** `[PCM-7]` says the move is permanent "the
moment a crossing trigger resolves an effect". I made *any* fired trigger set
`movement_permanent`, including one that carries no effect callable, because a
halt with no effect still reveals the trap that caused it — which is exactly the
zero-cost scouting the clause exists to stop. If the owner reads that clause
more narrowly, it is a one-line change in `CrossingResolver._fire`.

**Undo guard.** `TurnManager` gained `mark_move_permanent` / `is_move_permanent`
/ `can_undo_move`; `undo_move` refuses a permanent move. The six sites that
erased `_original_tiles` now route through one `_forget_move` helper, so the
pre-move tile and its permanence flag can never outlive each other and leak a
refusal into the unit's *next* move (there is a regression for that).
`MapCursor._undo_move_and_reselect` bails early too — `undo_move` alone would
refuse the snap-back but the cursor would still return to `UNIT_SELECTED` and
let the unit re-move off the tile it was stopped on.

**Inert by design.** No consumer registers yet, so with an empty registry every
path passes through unchanged and shipped play is identical. That is what makes
it safe to land ahead of fog Slice 3.

Also noted, not changed: `EnemyAI`'s V021-01 F9-handoff rollback calls
`turn.undo_move(enemy)`, which a permanent move will now refuse. That looks
correct — rolling back would unwind an effect that already applied — but it has
no consumer to exercise it yet.

## Commits claimed

- `d5e54d6a2f4f378b2238e30f4d3e420e2ec35e2f` — Build the shared crossing resolver over path-as-data [PCM-1][PCM-3]

## Gates

- `bash run_tests.sh` — **PASS: all suites green** (114 suites; run twice, once
  before the commit and once inside `agent-commit.sh`'s check worktree).
  Receipt: `audit/check-receipts/Project_Prometheus-full.json`.
- `scripts/tests/test_crossing_resolver.gd` — 29 passed, 0 failed. Includes
  DoD#2's required case: the same trigger on the same path halts on the same
  tile for an animated move, an Instant-speed move and an AI move, and the
  effect fires once per move rather than once per tween step.
- `python3 AGENT/Docs/check_docs.py` — clean (the four `.uid` sidecars it
  flagged are committed).
- `gdformat` / `gdlint` — clean.
- DoD#1: `GDD_02 §Movement Crossings` added (Split status — seam Implemented,
  consumers Target design), the Actions table's Move row amended, and
  `GDD_10_Roadmap.md` carries the matching Implemented paragraph, all in the
  same commit.

## Next

Fog Slice 3 registers the first consumer (`[FOW-4]` ambush reveal =
`{interrupt: halt, ends_activation: false}`) — it should now be materially
smaller than its plan estimated, since the seam it under-costed exists. Nothing
here needs a Windows visual pass: no rendering changed.
