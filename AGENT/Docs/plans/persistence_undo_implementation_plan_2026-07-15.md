---
Type: plan
Status: Target design
Last verified: 2026-07-15
---

# Unified Persistence & Undo — Implementation Plan — 2026-07-15

Turns the design in
[`persistence_undo_unified_handoff_2026-07-15.md`](persistence_undo_unified_handoff_2026-07-15.md)
into a sequenced BUILD/SCRAP plan. **Read the handoff first** — it carries the
decisions and the *why*; this file carries the *order*, the concrete code
anchors, and the exit test for each phase. Nothing here is built yet.

The handoff's five-step sequence is preserved but split into six phases: a
housekeeping Phase 0 (the tracker row + the snapshot-size measurement that gates
the deferrable Rewind phase) is prepended, and each design step gains verified
anchors, a scrap list, and a Definition-of-Done.

## Preconditions & guardrails

- **v0.4.0 Windows playtest still preempts.** A returned checklist pauses this
  work at a clean commit; its repairs go on the v0.4.0 build branch, never mixed
  into ledger work. (No return had landed as of the branch tip `69e5d22`.)
- **Branch:** continue on `agent/claude/2026-07-14/prep-deployment` (tip
  `69e5d22`), which already carries the design handoff. Keep phases as separate
  commits so Phase 3 (Rewind) can be dropped without unpicking the rest.
- **Interaction with B4 Slice 2 (Retry→prep reroute, commit `1df833e`, design
  only):** Retry becomes a ledger read in Phase 2. Land Phase 1–2 *before or
  together with* B4 Slice 2 so the reroute is written against the ledger API, not
  the old `restore_map_snapshot` path it would otherwise have to re-plumb.
- **Line numbers below were verified 2026-07-15** against the branch tip.
  Re-`grep` before editing; treat them as anchors, not addresses.

## Verified code anchors (the seams every phase touches)

| Seam | Location (2026-07-15) | Role after this plan |
|---|---|---|
| `GameState.capture_suspend_save` | `scripts/autoloads/GameState.gd:474` | The suspend-complete serializer → **the ledger entry codec** (Phase 1). |
| `GameState.take_map_snapshot` | `GameState.gd:735` | Party-only snapshot → **generalize to `push_history`** (Phase 1). |
| `GameState.restore_map_snapshot` | `GameState.gd:754` | → **`restore_history(index)`** (Phase 2); old path scrapped. |
| Snapshot capture call site | `scripts/core/GameMap.gd:130` (`take_map_snapshot`) | Becomes the round-0 ledger push. |
| Retry consumer | `scripts/ui/GameOverScreen.gd:211-212` | Re-point at `restore_history(0)` (Phase 2). |
| `GameState.next_map_deployment` | `GameState.gd:170` | Unchanged; noted so Retry-replay keeps the deployment plan (B4 Slice 1 decision). |
| Suspend storage API | `scripts/autoloads/SaveManager.gd:15` (`SUSPEND_FILENAME`), `:17` (`LAST_PLAYED_SUSPEND`), `:39/76/82/88` (`has/save/load/delete_suspend`) | **DELETE** in Phase 4; suspend becomes a normal slot. |
| Slot-id allow-list | `SaveManager.is_valid_slot_id` `:113` | **Keep** — the single namespace's id gate. |
| `capture_campaign_save` / `configure_campaign_resume` | `GameState.gd:511 / :537` | **Keep, Layer 1** — the between-map document, largely unchanged. |
| `map_runtime.map_path` load discriminator | already live | **Preserve** — the whole unification hangs on it. |
| Undo budgets | `scripts/resources/CampaignRules.gd:41` has only `rewind_charges_per_map`; **no** `undo_activations`/`undo_rounds`/`save_policy`/`autosave` yet, and the file has **no `to_dict`/`from_dict`** | New fields + their serialization land here (Phases 2/3/5). Find the existing rules codec (it lives outside `CampaignRules.gd`; `_campaign_rules_to_dict` in `GameState.gd`) and extend it in the same commit. |

## Phase 0 — Housekeeping (do first, tiny)

**Status: Implemented 2026-07-15** (commit `80733a9`). The `B1-LEDGER` row exists
in the control plane and directly links this plan + the handoff, so their
role-manifest ownership entries were dropped as redundant.

1. **Add the Control Plane tracker row.** There is currently no dedicated
   persistence/undo row in
   [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md) —
   the work is parked under `B1-PKGA` ("suspend/rewind hooks") and `B1-CST`.
   Add a Band-1 row, proposed id **`B1-LEDGER`** ("Unified persistence & undo —
   decaying ledger"), status `Target design`, deps `B1-PKGA`, `B1-CST`,
   `B1-SUSPEND`, pointing at the handoff + this plan. This is the row every phase
   below flips as it lands.
2. **No code.** Docs-only commit (the pre-commit Godot suite auto-skips).

## Phase 1 — Generalize the snapshot to suspend-completeness (foundation)

**Status: Implemented 2026-07-15.** Everything downstream reads this. **Goal:**
one serializer produces a SUSPEND-complete entry (all factions' units + turn
state + cursor + RNG timeline + Pair Up), and the map records it as the round-0
history entry.

- **Built:** `GameState._capture_map_runtime_entry(turn_manager, cursor)` is the
  reusable codec (returns the `map_runtime` + `suspend` sub-blocks: all factions
  via `_runtime_units_to_array`, `turn`, `pair_carry`, `rng`, cursor/threat
  block). `capture_suspend_save` composes {campaign + party + roster} then MERGES
  the codec's keys onto the SaveData section defaults — byte-identical to the old
  inline block, so suspend/Retry behavior is unchanged.
- **Built:** the within-map history — `_map_history: Array[Dictionary]` with
  `push_history(turn_manager=null, cursor=null)`, `history_size()`, and
  `peek_history(index)` (deep-copy read). `take_map_snapshot()` now also clears
  and seeds the round-0 entry via `push_history()`; `reset_map_state()` clears the
  history (map-scoped). The `GameMap.gd` round-0 call site is unchanged (no-arg).
- **Retry unchanged this phase (revised from the original plan wording):**
  `restore_map_snapshot` still reads the party-only `_map_start_snapshot` +
  economy fields. It was deliberately NOT rewired to read the history entry,
  because the entry carries all factions but NOT party gold/items (those live in
  the `party` layer) — deciding where party economy sits in a ledger entry is
  Phase 2 ledger-shape work, and rewiring restore now would risk the gold-rollback
  Retry already gets. So Phase 1 is purely additive: the entry is written, proven,
  and measured, but not yet the restore source.
- **Exit measurement (gated Phase 3):** `test_ledger_entry.gd` logs it — one
  suspend-complete entry on a 14-unit board = **~28 KB binary / ~16 KB JSON
  (~2 KB/unit)**. Cheap: a 20-deep fine tier ≈ 560 KB, so **Rewind is NOT
  memory-bound** and Phase 3 is clear to build (not deferred on hardware grounds).
- **Tests:** new `test_ledger_entry.gd` (real-board harness) asserts the entry
  round-trips **enemy** HP/board-position/faction and turn state through JSON, and
  that `take_map_snapshot` seeds exactly one round-0 entry carrying all factions.
  `test_suspend_map_runtime` / `test_rng_snapshot` / `test_pair_up_registry` /
  `test_snapshot_coverage` stay green (the refactor is behavior-preserving).
- **DoD done:** `GDD_01_Runtime_Contracts.md` §Determinism, Snapshot & Online
  updated (the shared codec + history foundation; §8.1 was the right home, not
  Data_Contracts); `GDD_10_Roadmap.md` gained the `B1-LEDGER` phase table;
  `check_docs.py` + full Godot suite green.

## Phase 2 — The decaying ledger + Retry-on-ledger (the scrap moment)

**Status: Implemented 2026-07-15.** The ledger is `scripts/save/MapLedger.gd` (a
preloaded, no-`class_name` object): a single reason-tagged entry list whose
`prune(keep_activations, keep_rounds)` retains `(last A activations) UNION (last R
round-starts)` plus the always-kept round-0 boundary — tiers expressed as data, not
a mode `match`. `GameState._capture_map_runtime_entry()` now also folds the party
economy (`party` = gold/items/roster snapshot) into every entry per the decision
below, and `restore_history(index)` reapplies roster-in-place + gold + items +
PairUp + RNG. Retry is re-pointed at `restore_history(0)` (`GameOverScreen`), and
the party-only `_map_start_snapshot`/`_snapshot_*` fields + `restore_map_snapshot` +
`validate_restore_snapshot_state` are deleted; `take_map_snapshot()` is now just the
round-0 ledger seed. Budgets `undo_activations`/`undo_rounds` are on `CampaignRules`
+ the GameState codec + `SaveData` normalization/defaults. New `test_map_ledger.gd`
(prune 1/N/∞, round-0 retention, deep-copy peek); `test_rng_snapshot`,
`test_pair_up_registry`, `test_game_state`, `test_game_map_scene` migrated onto the
ledger API; `test_ledger_entry` gains a party-economy fold+rollback check. Live
per-activation pushes + the `prune_history()` call sites arrive with Rewind (Phase
3). DoD met: GDD_01 §CampaignRules Contract + §Determinism/Snapshot,
`campaign_rules.md`, roadmap row flipped.

**Goal:** a two-tier decaying ledger stores entries; Retry is re-expressed as a
read of it; the old separate Retry path is deleted.

- **DECIDED 2026-07-15 (user): party economy lives PER LEDGER ENTRY.** Fold party
  gold/items into each entry (alongside the all-factions unit array) so an entry is
  self-sufficient and a mid-map *rewind* (Phase 3) correctly undoes gold/items
  gained earlier in the map (a village/chest reward). This resolves the question
  Phase 1 deferred — Retry keeps its gold rollback and rewind gains it. Extend
  `_capture_map_runtime_entry` (or the entry it returns) to carry `party_gold` +
  `party_items`, and have `restore_history` reapply them. Note this diverges from
  the handoff's entry-contents list (which put party economy in the `party` layer);
  the rewind-correctness argument wins.
- **Build the ledger** as its own object (a preloaded script, no `class_name` —
  mirror `DeploymentPlan.gd`'s reimport-safe pattern): two tiers, `fine`
  (per-activation, keep last `undo_activations`) and `coarse` (per round-start,
  keep last `undo_rounds`, may be infinite). `push_history` routes to the tier by
  push reason (activation vs round-start).
- **Prune as data, not a `match`:** one prune function parameterized by
  `(A, R)`; keep `(last A activations) UNION (last R round-starts)`. The "current
  round + last x round-starts" preset is just `A` scoped to the round. (Open-
  registry principle — no hardcoded mode switch.)
- **Add budgets** `undo_activations` / `undo_rounds` to `CampaignRules` (next to
  `rewind_charges_per_map:41`) and to the rules codec (`_campaign_rules_to_dict`
  and its inverse). Round-0 boundary is always retained regardless of budget.
- **Re-express Retry:** `restore_map_snapshot` → `restore_history(0)` (the
  round-0 boundary). Re-point `GameOverScreen.gd:211-212` at it.
- **SCRAP:** the separate `_map_start_snapshot` / `_snapshot_*` retry fields and
  `take_map_snapshot`/`restore_map_snapshot` as a *distinct* path once Retry reads
  the ledger. Keep method *names* only if cheaper than updating call sites/tests;
  prefer the rename.
- **Tests:** ledger push/prune unit tests (budgets of 1, N, infinite);
  Retry-via-ledger equivalence test (a replayed map reproduces identical RNG
  outcomes — the determinism guarantee); migrate `test_rng_snapshot` /
  `test_pair_up_registry` onto the ledger API.
- **DoD:** `GDD_01` + `AGENT/Docs/guides/campaign_rules.md` (new undo budgets are
  campaign rules) updated; roadmap row flipped; docs index regenerated.

## Phase 3 — Rewind (**IMPLEMENTED 2026-07-15**)

**Goal:** the `undo_activations` / `undo_rounds` budgets are spendable by the
player mid-battle, not just retained by prune.

- **Decision gate:** if the Phase 1 byte measurement shows a full board snapshot
  is expensive at the intended tier depth, keep budgets small or **defer this
  phase** (the handoff explicitly allows it). Retry (Phase 2) already delivers the
  round-0 rewind without it.
- **Build:** a rewind action that calls `restore_history(index)` for a non-zero
  index, decrementing the relevant budget. `CampaignRules.rewind_charges_per_map`
  (currently authored-only, **no consumer** — confirmed) becomes the spend meter,
  or is reconciled with `undo_activations` (decide which is authoritative; do not
  ship two overlapping charge concepts).
- **Determinism note:** because each entry carries the RNG timeline, a rewind
  restores RNG-at-that-point — replaying identical actions is identical, so rewind
  is decision-undo only, never luck-scumming. This is *why* the Phase 5 warning
  keys on the rewind budget, not on luck.
- **Tests:** spend-a-charge, exhaust-the-budget, rewind-then-diverge changes
  outcome, rewind-then-replay-identical reproduces outcome.
- **DoD:** `GDD_01`/`GDD_06`, `campaign_rules.md`, roadmap row.

## Phase 4 — Unified slot namespace (**IMPLEMENTED 2026-07-15**)

**Goal:** one slot store; a suspend is just a slot whose document carries
`map_runtime`.

- **SCRAP:** `SUSPEND_FILENAME` (`SaveManager.gd:15`), `LAST_PLAYED_SUSPEND`
  (`:17`), `has_suspend`/`save_suspend`/`load_suspend`/`delete_suspend`
  (`:39/76/82/88`), and the `LAST_PLAYED_SUSPEND` continue-kind branch (`:52`,
  `:341`). Continue and Load already share a restore path (B1-CST Slice 3) and
  branch on the `map_path` discriminator — point them at slots only.
- **Build:** one "Save" captures whatever is live — board present → `mid_map`
  document (whole ledger included, per the handoff: a reloaded suspend can still
  rewind into its pre-suspend history); between maps → `between_map` document
  (the existing `capture_campaign_save`).
- **Add `origin` tag** to every saved doc now (`manual` | `auto`, + `rule_id` for
  autos) — Phase 5's hard invariant depends on it being present from here on.
- **`LoadGameScreen`** labels each slot by kind ("Resume battle — Turn 4" vs
  "Continue — Chapter 3") off the mirrored header; no need to open N files.
- **Keep** `is_valid_slot_id` (`:113`) and the numbered/named store as the one
  namespace.
- **Tests:** `test_save_manager.gd`, `test_main_menu.gd`, `test_map_menu.gd`,
  `test_game_over_sequencing.gd` — retarget the suspend-specific assertions onto
  the unified slot; add a "suspend slot carries the ledger" round-trip.
- **DoD:** `GDD_07_Screens_Panels.md` (Load/Save UI, suspend row), `GDD_01`
  (one save-document namespace), roadmap; index regenerated.

## Phase 5 — Save policy + autosave triggers + the two safety rules

**Goal:** author-tunable slot-class policy, an open-registry trigger set for
autosave, and both safety rules landed *with their checks*.

- **Save policy** = a LIST of slot-classes in `CampaignRules`:
  `{count, accepts (between_map|mid_map|any), consumed_on_load, label}`. The three
  target presets (GBA-FE 3+1, single-consumable, 30-interchangeable) are pure
  data. **Enforced at the save/load API + UI only — never the file format** (no
  crypto/checksums; a decision, not a gap).
- **Autosave** = triggered auto-written classes `{trigger, keep, label,
  consumed_on_load:false}`:
  - `trigger` is an **open-registry event id**, not a hardcoded enum. Ship
    `battle_start`, `battle_end` (**this is the existing commit-time autosave,
    generalized — not a new concept**), `menu_area_exit`/`shop_exit`, plus
    author-bindable custom events. Model on the objective-condition / AI-profile
    registries, not a `match`.
  - `keep` = the rule's own rotation depth; each rule owns its **own pool,
    separate from the manual `count`** (30 manual + keep-3 autos = 33 files; a full
    manual pool never blocks an autosave). Empty list = no autosave (hardcore).
- **Safety rule 1 — HARD INVARIANT (structural):** an autosave may rotate an
  older autosave of the SAME `rule_id`, but must NEVER overwrite a manual save.
  Enforce by candidate-set: rotation selects its overwrite target ONLY from
  `origin:auto` + matching `rule_id`, so manual slots (and other rules' autos) are
  physically absent from the set. Add a defensive
  `assert(target.origin != "manual")` + a unit test as belt-and-suspenders — but
  the guarantee is the candidate set, not the assert.
- **Safety rule 2 — NON-BLOCKING campaign-builder warning:** raise when
  `mid_map` saves are durable (`consumed_on_load:false`) AND rewind
  (`undo_activations`/`rewind_charges`) is NOT infinite. `between_map` durable
  slots are always safe (loading one is a full replay like Retry, never single-
  action undo). Per **DoD#2, land the check WITH the feature** — extend
  `AGENT/Docs/check_docs.py` (model on the existing checks; 31 today) so a durable-
  `mid_map` policy authored without infinite rewind trips CI. The provided
  documentation carries the same warning.
- **Tests:** policy-preset load tests (all three presets); autosave rotation
  keeps `keep` and never touches manual; the never-overwrite-manual invariant
  test; trigger-registry dispatch (`battle_end` == old autosave point); the
  durable-mid_map warning fires/clears correctly.
- **DoD:** `GDD_01` (save policy + autosave as campaign rules),
  `campaign_rules.md`, `GDD_07` (Save UI), roadmap `B1-LEDGER` → Implemented; the
  `check_docs.py` extension + `gen_docs_index.py` in the same commit.

## Cross-phase Definition-of-Done (every commit)

Preferred pre-commit sequence (from `config/CLAUDE.godot.md`):

```bash
bash scripts/check_env.sh
python3 AGENT/Docs/check_docs.py
bash scripts/ci/check_rng_usage.sh
bash run_tests.sh
```

- DoD#1: behavior change → update the affected `GDD_01`–`08` section AND flip the
  `GDD_10_Roadmap.md` status in the SAME commit; governance status vocabulary only
  (never "current"/"complete"/"canonical").
- DoD#2: any new checkable rule ships its `check_docs.py` check in the same change.
- After adding/retitling a doc, run `gen_docs_index.py` and commit the regenerated
  `INDEX.md`/`REGISTERS.md` (check 18).
- Commit trailers: `AI-Tool`/`AI-Model`/`AI-Run-ID`/`AI-Workspace`; **no**
  `Co-Authored-By`. Author stays the human identity.

## Deferral summary

Phase 3 (Rewind) is the single deferrable unit — gated on the Phase 1 byte
measurement. Phases 1, 2, 4, 5 are each independently shippable and leave the game
green; the recommended landing order is 0 → 1 → 2 → (4 → 5) with 3 slotted after 2
only if the measurement clears.
