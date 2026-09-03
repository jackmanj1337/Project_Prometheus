---
Role: dated
Type: plan
Status: Implemented
Last verified: 2026-07-15
---

# B1-LEDGER Review Handoff — everything since the v0.4.0 push — 2026-07-15

A review-prep map for the work that landed on
`agent/claude/2026-07-14/prep-deployment` **after** its last push (the v0.4.0
timeframe). It exists so a human reviewer can walk the diff in the right order,
knows which decisions were deliberate, and knows what was intentionally left for
later so nothing reads as a missing piece. Nothing here changes code.

## Scope & how to read the diff

- **Review range:** `69e5d22..HEAD` (HEAD = `4234b70`). Seven commits.
- **One diff command:** `git diff 69e5d22..HEAD` — 24 files, +1253 / −164.
- **Branch:** `agent/claude/2026-07-14/prep-deployment`. `69e5d22` is the pushed
  tip (the merge that consolidated the B1-CST + B4 handoff lines at the v0.4.0
  timeframe); everything after it is this review.
- **The v0.4.0 build is a *parallel* branch** (`agent/codex/2026-07-14/
  v0.4.0-windows-build`, tip `b55dffa`) — it is NOT in this range and nothing here
  touches it. A returned v0.4.0 playtest still preempts and belongs on that branch.
- **Tree is clean; all suites green** (80 suites) as of `4234b70`.

## What the range does (TL;DR)

It builds **B1-LEDGER Phases 0–2** — the foundation of the unified persistence/undo
system — off the design in
[`persistence_undo_unified_handoff_2026-07-15.md`](persistence_undo_unified_handoff_2026-07-15.md)
and the sequenced plan
[`persistence_undo_implementation_plan_2026-07-15.md`](persistence_undo_implementation_plan_2026-07-15.md).

The end state: the within-map "Retry snapshot" is now a **two-tier decaying
ledger** of suspend-complete board entries. Retry is one read of it
(`restore_history(0)`); suspend saves share the same board serializer; and the
ledger is built to grow into mid-map Rewind (Phase 3) and a unified slot namespace
(Phases 4–5) without another refactor. The old party-only snapshot path is deleted.

## Commit-by-commit

| Commit | Kind | What |
|---|---|---|
| `80d4214` | docs | Sequence the design into a 6-phase BUILD/SCRAP implementation plan (new `persistence_undo_implementation_plan_2026-07-15.md`). |
| `80733a9` | docs | Phase 0: add the `B1-LEDGER` row to the Project Control Plane; drop the plan/handoff role-manifest ownership entries the row now owns. |
| `30abefd` | code+tests+docs | Phase 1: extract `GameState._capture_map_runtime_entry()` — the ONE suspend-complete board serializer — shared by `capture_suspend_save` (byte-identical) and a new within-map history. New `test_ledger_entry.gd`. |
| `c16ff7a` | docs | Session note 2026-07-15b (Phases 0–1). |
| `1a1215d` | docs | Record the Phase-2 party-economy decision (per-entry) in the plan, so Phase 2 starts with the fork settled. |
| `4654f64` | code+tests+docs | Phase 2: the `MapLedger` object + `undo_activations`/`undo_rounds` budgets + party-economy-per-entry + Retry re-expressed as `restore_history(0)`; SCRAP the party-only snapshot path. New `test_map_ledger.gd`. |
| `4234b70` | docs | Session note 2026-07-15c (Phase 2). |

## Files to review

### Production code (the actual review target)
- **`scripts/save/MapLedger.gd`** (new, 93 lines). The two-tier ledger: a single
  reason-tagged entry list; `prune(keep_activations, keep_rounds)` keeps
  `(last A activations) UNION (last R round-starts)` plus the always-retained
  round-0 boundary. Tiers are DATA (a `reason` tag + two budgets), not a mode
  `match` — the open-registry principle. `-1` = infinite tier; `peek()` deep-copies.
- **`scripts/autoloads/GameState.gd`** (the big diff, +267/−). The ledger lives
  here as `_map_ledger`. Review the four moving parts:
  1. `_capture_map_runtime_entry()` — now returns a third sub-block, `party`
     (gold/items/roster), sibling to `map_runtime`/`suspend`.
  2. `push_history` / `history_size` / `peek_history` / `prune_history` — thin
     delegates to `_map_ledger`; `push_history` gained a `reason` arg.
  3. `restore_history(index)` — the new Retry restore: validate the entry, then
     apply roster-in-place + gold + items + PairUp + RNG (see risk area 3).
  4. `_validate_restore_entry` — replaces `validate_restore_snapshot_state`, now
     reading the entry's `party` block + `map_runtime` pair/rng.
- **`scripts/resources/CampaignRules.gd`** — `undo_activations` / `undo_rounds`
  (+11). **`scripts/save/SaveData.gd`** — their normalization + defaults (+5).
  **`scripts/ui/GameOverScreen.gd`** — Retry now calls `restore_history(0)` (+7).
  **`scripts/autoloads/PairUpRegistry.gd`** — header comment only (references the
  deleted field).

### Tests
- **`scripts/tests/test_map_ledger.gd`** (new). Pure-RefCounted prune/peek unit
  tests: budgets 1 / N / infinite, round-0 always retained, deep-copy `peek`.
- **`scripts/tests/test_ledger_entry.gd`** (new in this range at Phase 1; Phase 2
  adds a party-economy fold+rollback check on a real board).
- **Migrated onto the ledger API:** `test_rng_snapshot` (RNG now in
  `map_runtime.rng`), `test_pair_up_registry`, `test_game_state` (roster-count and
  malformed-entry guards), `test_game_map_scene` (reads the round-0 entry's rng).

### Docs (DoD#1)
- `GDD_01_Runtime_Contracts.md` — §CampaignRules Contract (two budget rows) +
  §Determinism, Snapshot & Online (Phase 1 + 2 paragraphs, Status line).
- `GDD_10_Roadmap.md` — B1-LEDGER phase table, Phases 0–2 → Implemented.
- `guides/campaign_rules.md` — the budget fields + a meaning subsection.
- `plans/persistence_undo_implementation_plan_2026-07-15.md` — per-phase Status.
- `project_control_plane_2026-06-29.md`, the doc role manifest (since deleted,
  2026-08-23), `INDEX.md`, session notes.

## What to scrutinize (the load-bearing decisions)

1. **Party economy lives PER LEDGER ENTRY (your decision, 2026-07-15).** Each
   entry carries a `party` block (gold/items + a roster snapshot). This *duplicates*
   the player party: once as the live board in `map_runtime.units` (all factions),
   once as `party.roster`. Intentional — it makes an entry self-sufficient so a
   mid-map rewind (Phase 3) undoes a village/chest reward with the board. Confirm
   you still want the duplication vs. a single source; it mirrors how a suspend
   document already carries both `roster.units` and `map_runtime.units`.
2. **Suspend byte-identity.** Adding `party` to the entry is safe because
   `capture_suspend_save` merges only the `map_runtime` and `suspend` sub-blocks
   onto the SaveData defaults, ignoring `party`. The claim to check: a suspend
   document is unchanged — `test_suspend_map_runtime` stays green.
3. **`restore_history(0)` ≡ the old `restore_map_snapshot`.** Same order:
   validate → apply roster **in place** → gold/items → `reset_map_state` → reapply
   PairUp → restore RNG. Roster is matched **by index** (`party.roster` is
   `player_roster` serialized in order at capture), same as the old
   `_map_start_snapshot`. The one behavioral subtlety worth a look: capture reads
   the copy *before* `reset_map_state` clears the ledger (`peek` returns a deep
   copy), so the reset can't pull the data out from under the restore.
4. **Prune is built but not wired live.** Nothing pushes per-activation entries
   yet, so in live play the ledger holds only round-0 and `prune` is a no-op —
   Retry works, deeper undo does not. That is deliberate (Phase 3). `prune`/tiers
   are proven by `test_map_ledger`, not by gameplay. Don't flag the absent live
   pushes as a defect.
5. **Budget defaults `0/0` and the `-1` sentinel.** Defaults retain nothing beyond
   round-0 (rewind depth is opt-in per campaign); `-1` = infinite (the coarse
   round tier may legitimately be infinite). Confirm these defaults are what you
   want shipped.

## Deliberately NOT in this range (so it doesn't read as missing)

- **Phase 3 — Rewind:** live per-activation `push_history` / `prune_history` call
  sites in the turn flow, and a player-spendable checkpoint. Also the reconciliation
  of `rewind_charges_per_map` (authored-only, no consumer) vs `undo_activations`
  into ONE spend meter — do not ship two overlapping charge concepts.
- **Phase 4 — unified slot namespace:** collapsing `suspend.json` into the slot
  store; the `origin: manual|auto` tag.
- **Phase 5 — save policy + autosave + the two safety rules.**
- **B4 Slice 2's Retry→prep reroute** can now be written against `restore_history` /
  the ledger API instead of the old snapshot path.

## How to verify

Preferred pre-commit sequence (also runs in the hook):

```bash
bash scripts/check_env.sh
python3 AGENT/Docs/check_docs.py          # 31 checks
bash scripts/ci/check_rng_usage.sh
bash run_tests.sh                          # 80 suites
```

All green at `4234b70`. Fastest single-feature check:
`godot --headless --path . --script res://scripts/tests/test_map_ledger.gd`.

## Attribution / DoD

Commits carry `AI-Tool`/`AI-Model`/`AI-Run-ID`/`AI-Workspace` trailers; author is
the human identity; no `Co-Authored-By`. DoD#1 met per phase (GDD section + roadmap
status flipped in the same commit). No new mechanical rule was ratified, so DoD#2
adds no `check_docs.py` check this range (that arrives with Phase 5's durable-mid_map
warning).
