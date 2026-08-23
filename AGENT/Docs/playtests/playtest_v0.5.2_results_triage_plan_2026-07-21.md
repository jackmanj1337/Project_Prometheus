---
Role: dated
Type: playtest
Status: Triaged - headless-verified + peer-reviewed; fixes pending on the v0.5 release line
Last verified: 2026-07-21
---

# v0.5.2 Playtest Results — Root-Cause Review & Fix Plan

Code-review-style triage of the v0.5.2 Windows return. Every file/line citation
is against the **exact build commit `06e0386`** (branch
`agent/playtest-release-v0.5-fixes`), which is what the tester ran — **not**
`agent/integration`, whose rewind/persistence code has since diverged (integration
*dropped* the multi-row rewind selector + decaying ledger the build shipped).
Re-verify each fix on the release line.

This revision incorporates **headless reproduction** (Godot `--headless` against
the build commit) and a **Codex (gpt-5.6) second-opinion review**. Both changed
the conclusions — most importantly, my first root cause for Issue 1 was
**falsified**, and a new latent bug was found.

### Decisions locked (2026-07-21, maintainer)

- **Issue 2:** replace the hold-tiles objective with a **pure survive**; optionally
  add a **loss-on-enemy-seize** later (needs new AI-seize behavior — see the issue).
- **Issue 5:** **keep `z`/`x`** as the primary confirm/cancel scheme; suppress the
  letter actions while a text field has focus, and make **Escape** the "exit the
  text box" key.
- **Issue 3a:** the two-map-skirmish pack gets **unbounded retention**; a budget cap
  may exist but is meaningless under `full_history` cost mode, so `full_history`
  ⇒ retention is not capped.
- **Issue 3c:** on manual turn-end, remaining units **Wait in roster order** (one
  history entry each), then refresh at end of phase — full visibility/rewindability.
- **Issue 7 (faction gold):** **deferred** — recorded for later, not addressed now.
- **Issue 6 (manual save):** drop the manual filename entirely — auto-generate the
  slot id from `<chapter>-<activity>-<timestamp>`; derive a human label from context;
  **confirm before overwriting a same-label save**. (See the fix plan §3.)
- **Base branch:** v0.5.3 fixes fork from `origin/agent/playtest-release-v0.5-fixes`
  (`db270cb`), not the stale local `cc17a0f` or the dead slash ref.

## Evidence

- Completed checklist: [`playtest_checklist_v0.5.2_returned_2026-07-21.md`](playtest_checklist_v0.5.2_returned_2026-07-21.md)
- Build manifest: [`playtest_build_v0.5.2.md`](playtest_build_v0.5.2.md)
- Logs + screenshots: `AGENT/Docs/archive/evidence/v0.5.2/`
- **Headless repros** (preserved, ran green against build 06e0386):
  `AGENT/Docs/archive/evidence/v0.5.2/repro_escape_together_vs_separate.gd.txt`,
  `repro_defend_and_rewind_truncation.gd.txt`
- **Codex second-opinion review** (verbatim):
  `AGENT/Docs/archive/evidence/v0.5.2/codex_second_opinion_review.md`

## Summary

| # | Severity | Area | Symptom | Status after headless verify + Codex review |
|---|----------|------|---------|----------------------------------------------|
| 1 | **High** | Campaign/escape | Pair escaping together → "Campaign Data Error" + "next battle is unavailable" | **Original cause FALSIFIED.** Error string is `MapResultsScreen` when `get_pending_successor_options()` is empty; both escape paths give **1** option in repro → escape mechanic does *not* cause it. Real defect nearby = Issue 9 (stale coordinate). |
| 2 | **High** | Objectives/data | Defend map never grants victory | **Confirmed + sharper:** winnable only by holding **unmarked** tiles `(3,5)/(3,6)` during turns 7–8; a passive survivor is *defeated* at turn 9 by the `turn_limit=8` defeat. |
| 3a | **High** | Rewind | Only ~5 actions retained | **Confirmed:** `prune_history()` caps activations at `charges+1` and ignores `rewind_cost_mode=="full_history"`. |
| 3b | **High** | Rewind | Forward history not discarded | **Confirmed by repro:** live ledger truncates to 2 but `next_map_suspend_payload.ledger` stays 5; reload resurrects 3 discarded entries. |
| 4 | **Med-High** | UI/input | Rewind selector cursor drifts onto map/Settings | **Confirmed:** neither MapMenu nor RewindSelector acquires the shared gameplay-modal lock; selector isn't modal. |
| 5 | **Med** | Input map | First `x` in Import field backs out | **Confirmed:** `x` (keycode 88) is bound to the global `cancel` action. |
| 6 | **Low-Med** | Save/UX | Manual save with spaces fails + logs error | **Confirmed:** raw slot-id field; `push_error` on user input. |
| 7 | **Low** | Economy/UI | Gold doesn't vary per faction | **Confirmed design gap** — single `party_gold` pool; not a regression. |
| 9 | **Med** | Pair Up/save | *(new, found in review)* Paired escape leaves the support's roster `UnitData.tile_position` at `(-1,-1)` | **Confirmed by repro** — contaminates between-map autosaves; masked today only because Prep re-deploys. |

Plus the manual-turn-end request (3c) and the strategic data-ownership follow-up.

---

## Headless verification (what actually ran)

Two SceneTree tests drove the **real autoloads** against the build commit.

**`repro_escape_together_vs_separate.gd`** — pairs cavalier+mercenary on
`map_004_escape`, escapes the lead (together) vs escapes each (separate), through
to `CampaignManager`:

```
---- A (paired, together) ----      ---- B (separate) ----
 has_pending_victory = true          has_pending_victory = true
 pending next_node   = node_05_defend pending next_node   = node_05_defend
 successor_options   = 1              successor_options   = 1   (node_05_defend)
 roster merc tile    = (-1, -1)  <–   roster merc tile    = (0, 0)
 prepare_advance     = true (ok)      prepare_advance     = true (ok)
```

Both paths are identical at the campaign layer — **the escape does not empty the
successor options or fail the advance.** The *only* difference is the stale
`(-1,-1)` roster coordinate on the paired support (Issue 9).

**`repro_defend_and_rewind_truncation.gd`** — see Issues 2 and 3b.

---

## Issue 1 — "Campaign Data Error / next battle is unavailable" — **High (cause corrected)**

**Report.** On the Proving Grounds escape mission, cavalier paired with mercenary;
escaping *together* produced "next battle is unavailable" + "Campaign Data Error".
Escaping *separately* did not.

**My first writeup blamed an emptied roster failing `prepare_pending_advance`.
That is FALSIFIED** — see the repro: `player_roster` stays size 2, `keep_current_roster`
accepts any non-empty roster (`GameState.gd:517-542`), and `prepare_pending_advance`
returns true in both paths.

**Where the strings actually come from.** `MapResultsScreen._refresh_result`
(`scripts/ui/MapResultsScreen.gd:125-133`):

```gdscript
var options := cm.call("get_pending_successor_options")
if result_complete:            _continue_button.text = "Finish Campaign"; return
if options.is_empty():
    _continue_button.text = "Campaign Data Error"
    _save_status_label.text = "Save: next battle is unavailable"
    return
```

So both exact phrases fire **iff `get_pending_successor_options()` returns empty
while the result is not flagged `campaign_complete`.** In the shipped
`proving_grounds` campaign, `node_04_escape → [node_05_defend]`, so the repro
returns **1** option for both escape styles — the escape mechanic never empties it.

**Best-supported conclusion (with Codex).** The together/separate correlation is a
**red herring or a live-state artifact**. Empty successor options require the
pending result / active campaign graph to be absent — not anything the escape path
itself does in the repro.

**Leading testable mechanism (from the §6 cross-check).** Checklist §6 *passed*:
"a true terminal result reads Finish Campaign" and "a generated one-map campaign
returns to Main Menu without a failed advance" are both `[x]`. So the normal
terminal / `campaign_complete` path works — the error is **not** a mis-flagged
terminal node. That leaves an **empty pending result** as the cause:
`MapResultsScreen` calls `get_pending_successor_options()`, which is empty whenever
no pending victory was recorded. And `CampaignManager._record_result`
(`CampaignManager.gd:517-518`) **silently returns** if `_active_node_id == ""`:

```gdscript
func _record_result(victory: bool) -> void:
    if not is_campaign_active() or _active_node_id == "":
        return  # no pending result recorded → results screen shows "Campaign Data Error"
```

So if anything clears `_active_node_id` (or ends the campaign) before the escape
`map_victory` fires, no pending result is stored and the tester sees exactly this
error. The escape node is node_04 in the *linear* proving_grounds (it has a
successor), so a successorless-node explanation does not apply here. My repro can't
exercise this because it pokes `_active_node_id` directly — only the real launch
flow can, which is why the decisive test below drives the full scene flow.

**Recommended fixes.**
1. **Defensive UI (do regardless):** treat "victory + no successors" as completion
   — show "Finish Campaign", not "Campaign Data Error" — and log the pending
   campaign_id/node_id + authored successor ids so the *next* occurrence is
   diagnosable instead of a dead-end string.
2. Add the **decisive full-scene-flow test** Codex specified: launch `node_04_escape`
   through `CampaignManager`, pair via `MapCursor`, escape, await a frame, assert
   `MapResultsScreen` shows one successor option and no error; repeat for the
   separate path; and assert the support's roster tile immediately after victory
   (which exposes Issue 9).
3. Do **not** rework branch/deployment logic until a failure is reproduced there.

---

## Issue 2 — Defend map is a trap as authored — **High (sharpened)**

`data/maps/map_005_defend/map_005_defend_data.tres`: victory `survive turns=6
tiles=[(3,5),(3,6)]`; defeat `protect unit_01_cavalier` + `turn_limit=8`; player
starts at (1,4)…(2,6).

**Headless result:**

```
turn 7, NOT on a hold tile : victory=false
turn 7, ON a hold tile     : victory=true    <- the ONLY win path
turn 9, ON a hold tile     : victory=false   <- turn_limit=8 defeat fires first
```

So the map *is* winnable, but only by occupying `(3,5)/(3,6)` during the turn 7–8
window. It fails the player three ways: (1) the hold tiles are not start tiles and
`_display_survive` shows only `"Hold for 6 turn(s)"` without coordinates
(`ObjectiveConditionRegistry.gd:304-305`); (2) the natural "just survive"
interpretation is *punished* — `turn_limit=8` is a **defeat**, so reaching turn 9
without holding is a loss; (3) it was clearly never tested.

**DECISION — pure survive.** Re-author `map_005_defend` as a straight survive map:
drop `tiles` from `cond_survive_hold` (win = survive to turn N) and **remove the
`turn_limit=8` defeat**. Keep the `protect unit_01_cavalier` defeat. This is a
trivial data change; add a data test asserting every shipped map is resolvable.

**Optional follow-up — loss on enemy seize (sequence behind the Band 5 AI scorer).**
Enemy AI does not seize *today* (`record_seize` is only called from `MapCursor` on a
player confirm; `EnemyAI`'s built dispositions are pursue_unit / hold_tile / heal —
none seize). The *defeat condition* itself needs no new evaluator code: author a
`seize` **victory** under `victory_conditions["foes"]` on the throne tile and the
existing all-groups sweep resolves a foe win (→ player defeat) when a foe seizes.

The missing half — an enemy that actually paths to and seizes — is **already
designed** in the Band 5 AI scorer plan, not net-new work:
`AGENT/Docs/plans/band5_ai_implementation_plan_2026-07-03.md` enumerates **capture**
as a scored action ("a non-lethal option scored via the same forecast", lines
258-260), defines an **objective-pressure** scorer term ("progress toward the map
objective", line 266), and even has the test *"Objective-pressure term moves a
seize-profile unit toward the objective"* (line 290). It is gated to the
**widened-palette slice (B5-AI-MIN-SCORER Slice 3B)** — the current handoff
(`b5_ai_min_scorer_slice3a_handoff_2026-07-16.md`) scores weapon attacks only ("No
scored staves, styles, refresh, AoE, gambits, capture"). Owner decisions for that
track were ratified in tracker task `AI-SCORER-DECISIONS-2026-07-19`.

So the enemy-seize defend variant is a **dependent of B5-AI-MIN-SCORER Slice 3B**
(capture + objective-pressure + a seize AI profile), not a from-scratch AI feature.
The pure-survive fix above ships now regardless; add the enemy-seize loss when 3B
lands.

---

## Issue 3a — Rewind retains only `charges+1` entries — **High**

`GameState.prune_history()` sets `fine_keep = max(undo_activations,
rewind_charges_per_map+1)`, INFINITE only when charges `< 0`, and **ignores
`rewind_cost_mode`**. `"full_history"` cost mode charges a flat 1 per row but the
retention is still capped at 5 — the two are conflated.

**DECISION — full_history ⇒ uncapped retention.** Decouple retention from charge
count: when `rewind_cost_mode == "full_history"`, activation retention is
**unbounded** (a flat one-charge "go back any distance" is meaningless if the
history behind it was pruned). A budget cap may still exist for the escalating
cost mode, but does not apply under `full_history`. Set the **two-map-skirmish**
campaign to `full_history` + unbounded retention. Test: >5 activations with one
full-history charge, assert all remain rewindable.

## Issue 3b — Rewind doesn't discard forward history — **High (confirmed by repro)**

`rewind_to_history` captures the **full** ledger into `payload["ledger"]`
(`GameState.gd:956-969`) *before* `_map_ledger.truncate_after()`
(`GameState.gd:971-974`); `configure_suspend_resume` stores that payload in
`next_map_suspend_payload`, and `GameMap._ready` re-applies it on reload
(`GameMap.gd:58-75`). Repro: live ledger → 2 after rewind, but staged payload
ledger → 5, so the reload resurrects the 3 discarded entries.

**Fix (Codex's cleaner variant).** Build a **truncated copy** and put it in
`payload["ledger"]` before `configure_suspend_resume()` — this preserves the
validate-before-commit ordering (truncating the live ledger first weakens rollback
safety). Assert both live and staged ledgers equal `target_index+1` before reload.

## Issue 3c — Manual turn-end should expend units and lodge history

**DECISION — Wait in roster order, then refresh at phase end.** On a confirmed
manual end-turn, expend each remaining READY unit by having it **Wait, in roster
order**, pushing one activation ledger entry per unit so each is individually
rewindable ("full visibility"). The normal end-of-phase READY refresh still runs
afterward. Today `MapCursor._on_end_turn_requested` just calls `request_end_phase`
with no per-unit Wait/push, so the skipped units leave no rewind points.

---

## Issue 4 — Rewind selector / map-menu input bleed — **Med-High (systemic)**

Neither `MapMenu` nor `RewindSelector` acquires the shared gameplay-modal lock, and
`MapMenu._on_rewind` opens the selector without hiding its own buttons, so focus
wanders (confirm lands on Settings) and the map cursor still moves. The tester also
saw the **selector's visible state survive a menu-close** ("closing Settings closed
all menus, but reopening the map menu showed the rewind menu already open") — the
selector is not reset/hidden when the menu stack tears down, a second facet of the
same missing modal-lifecycle ownership.

**Fix (Codex-endorsed systemic).** MapMenu acquires/releases the shared
gameplay-modal lock for its whole visible lifetime; disable/hide the parent button
container while the selector is open; give the selector an explicit focus scope
with deterministic neighbours; apply the same host behaviour to `GameOverScreen`
(which reuses the selector). See §"Modal input scope" for the reusable contract +
regression.

---

## Issue 5 — `x` closes the Import filename field — **Med**

`project.godot` binds the `cancel` action to keycode 88 (`X`), so it fires as a UI
action before the FileDialog's native LineEdit gets it as text (`z`=confirm types
fine; paste works).

**DECISION — keep `z`/`x`; text fields use Escape to exit.** Retain `z`=confirm /
`x`=cancel as the primary scheme game-wide. The fix is scoped to text entry:
**while a text control (`LineEdit`, incl. FileDialog's filename field) has focus,
suppress the letter-bound UI actions** (`x`/`z`/WASD) so they type as characters,
and make **Escape** the "get out of the text box" action (which also cancels/closes
the dialog). Verify the input suppression covers the native FileDialog LineEdit, not
just the game's own fields.

---

## Issue 6 — Manual save rejects spaces + logs an engine error — **Low-Med**

`PrepScreen._on_save` passes a raw slot-id; `SaveManager.is_valid_slot_id` rejects
spaces and `save_slot` (+ `CampaignManager.write_campaign_slot`) `push_error` — two
engine errors from a user typo, tripping checklist §9.

**Fix.** Treat the player text as a display **label** and derive a deterministic
safe id (slug + short collision suffix); validate in Prep before the persistence
layer; return a quiet/structured failure instead of `push_error` (reserve
`push_error` for violated internal contracts). Dovetails with the human-readable
labels follow-up.

---

## Issue 7 — Gold doesn't vary by active faction — **Low (design gap)**

Single `party_gold` pool; `ResourceLedger`'s party handler writes that property
(`ResourceLedger.gd:131-140`). Not a regression under the single-party model; a
feature gap for hotseat/PvP.

**DECISION — deferred, recorded for later.** Not addressed in v0.5. Captured here
(and in the tracker) as a future design item: if pursued, implement per-faction
economy via an **open resource-owner / wallet registry**, not a hardcoded faction
switch (matches the project's open-registry principle). The HUD/MapMenu gold
readout would then bind to the active faction's wallet.

---

## Issue 9 — Paired escape leaves a stale `(-1,-1)` roster coordinate — **Med (new)**

*Found during the Codex review, confirmed by repro.* `Unit.tile_position` is a
pass-through setter to `UnitData.tile_position` (`scripts/units/Unit.gd:15-20`), so
pairing (`MapCursor._on_pair_up_resolved:1302-1307`) writes the support's
**persistent** roster position to `OFF_MAP_TILE (-1,-1)`. A normal Separate restores
it (`MapCursor.gd:1372-1388`), but `record_escape` clears only registry bookkeeping
(`TurnManager.gd:1348-1364`; `PairUpRegistry.separate`) and never restores it. The
repro shows the escaped support's roster tile stuck at `(-1,-1)`.

Today it is masked (Prep re-deploys and GameMap spawn overwrites positions), but it
**contaminates between-map autosaves** and would break any future prep consumer,
save-inspector, or launch path that trusts roster coordinates.

**Fix.** Restore each escaping unit's roster `UnitData.tile_position` to its
escape/lead tile before removal, **or** make Pair Up's off-map location
node-runtime state rather than persistent roster state. Add a campaign-save
regression test.

---

## Modal input scope — preventing the recurring overlay/input bug class

Issues 4 (and 5) are the same defect: an overlay that doesn't own input while up.
Adopt one contract, enforced by a test:

1. **One focus scope.** An opening overlay hides/disables the controls beneath (or
   lives on a dedicated CanvasLayer) so directional focus can't wander out.
2. **Consume input at the top** (`mouse_filter`/`gui_input`; mark owned actions
   handled).
3. **Lock the map cursor via the shared gameplay-modal lock** while *any* overlay
   is open; release only when the last closes (a counter, not a boolean — the
   Settings-over-Rewind-over-MapMenu stack needs it).
4. **Route overlays through `ModalScreen.gd`**; `RewindSelector` currently does not.
5. **Regression:** open the selector over the map menu; assert map-cursor input is
   inert, focus stays inside the selector, and closing the top overlay returns focus
   to its opener, not a sibling.

---

## Strategic follow-up (from the checklist footer) — design pass first, no code yet

- Remove engine-baked campaign/unit data; make everything ride the campaign packs.
- Replace Main Menu New Game / Load Game with a **campaign selector**, then
  per-campaign "load save" vs "new file".
- Review pack + save serialization for dedup; add human-readable labels (dovetails
  with Issue 6).

---

## Checklist re-read: cross-checks & process gaps

A second pass over the returned checklist for anything the issue list didn't
already carry:

- **§6 cross-check (feeds Issue 1).** "Terminal → Finish Campaign" and "generated
  one-map → clean return" both passed `[x]`, which is why Issue 1's error is *not*
  the terminal path — see the refined Issue 1 mechanism above.
- **§5 also passed its scripted checks.** The full-history rewind checklist items
  (4 charges, per-row cost, restore fidelity, charge persistence, AI-boundary
  resume, exhaustion→disable) were all `[x]`; the depth/truncation/input problems
  live only in the free-text notes (Issues 3a/3b/4). So the *scripted* rewind
  behaviour is sound; the defects are budget, forward-branch discard, and modality.
- **Provenance is incomplete.** Build-identity fields (tester name/date, Windows
  version, device/GPU, controller) are blank, the identity/hash checkboxes are
  unchecked, and **Final result PASS/FAIL is left blank**. §9's per-failure record
  (exact steps, save name, original-resolution screenshot each) was also not filled
  in. This matters because Issue 1 needs a Windows repro and we don't have the
  tester's GPU/OS or the exact campaign variant they were on. **Ask the tester to
  record these on the next return**, and specifically: was the escape mission the
  linear proving_grounds run or a generated one-map campaign, and the exact click
  sequence before the error.
- **Return path.** The checklist expected the return under `AGENT/Incoming/v0.5.2/`;
  it arrived under `AGENT/v0.5.2/`. Resolved by this filing (evidence →
  `AGENT/Docs/archive/evidence/v0.5.2/`, docs → `AGENT/Docs/playtests/`), but the
  build's return instructions and the actual drop location should be reconciled.

## Disposition & next actions

All product decisions are now locked (see "Decisions locked" up top), so Issues 2,
3a, 3b, 3c, 4, 5, 6, 9 are ready to implement on the **v0.5 release line** and
verify on a Windows host — no further design input needed. Issue 1's on-screen error
is understood (empty successor options / an empty pending result); ship the
defensive UI fix + diagnostics + the decisive scene-flow test rather than guessing
the live trigger. Deferred: Issue 7 (per-faction economy) and the loss-on-enemy-seize
option (needs AI-seize behavior), both recorded for later; and the strategic
data-ownership pass, which the tester asked to design before building.
