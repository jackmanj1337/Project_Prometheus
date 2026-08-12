> **ARCHIVED** — Codex (gpt-5.6) review of the v0.5.2 fix implementation plan, run read-only against the release line (agent/playtest-release-v0.5-fixes @ cc17a0f) on 2026-07-21. Verbatim; the plan was revised per this review.

# Codex review — v0.5.2 fix implementation plan

Improvement: register ownership first, create the new agent branch from exact SHA `cc17a0f`, and describe stable/integration advancement as a maintainer action after review. Do not promise a release→integration resync until the 50/30 divergence receives a conflict audit.

### 13. Out of scope — SOUND

The deferrals are reasonable and respect the open-registry architecture. Add the larger Pair Up runtime-position cleanup from Issue 9 to this list explicitly.

No files were modified.
tokens used
106,187
## Overall verdict: RISK

The plan identifies most defects correctly, but Issues 1, 3c, 4, and 5 need redesign before implementation. It also proposes redundant fixture changes and overstates branch exclusivity.

### 0. Branch base/divergence — RISK

Evidence:

- `agent/integration...HEAD` is genuinely divergent: 50 integration-only commits and 30 release-only commits.
- `scripts/ui/RewindSelector.gd` and `GameState.rewind_to_history()` are absent from integration/main/staging and present here.
- However, “exists only on `agent/playtest-release-v0.5-fixes`” is false: the selector also exists on `agent/playtest-release/v0.5-fixes` (slash form), the v0.5.1 build branch, and the regression-sweep branch.
- There are two confusing local refs: `agent/playtest-release-v0.5-fixes` at `cc17a0f` and `agent/playtest-release/v0.5-fixes` at `21b28df`.
- No local `agent/stable-release` ref exists, so §12’s merge route is not currently executable.

Improvement: name exact source SHA `cc17a0f`, distinguish the slash/hyphen refs, and compare commits rather than saying “only.” Reconciliation should be a reviewed merge/rebase plan, not an unconditional “re-sync”; integration has 50 commits that cannot safely be replaced wholesale.

### 1. Dependencies/sequencing — RISK

The order is broadly sensible, but Issue 5 is already partially implemented, and Issue 3c requires a new atomic batching seam before it can safely land. Move investigation of Issue 5 first; place 3c after its batching design/test.

The two-map fixture already contains both requested settings at `test_fixtures/campaign_packs/two_map_skirmish/data/campaign.json:8-11`. Do not schedule that data edit again.

### 2. Defend map — SOUND

Both duplicated definitions require the same edit:

- `data/maps/map_005_defend/map_005_defend_data.tres:6-20,38-39`
- `data/maps/battle_encounters/encounter_map_005_defend.tres:7-21,53-58`

Removing tiles and the defeat turn limit implements pure survival correctly. Improving `_display_survive` is also sound: `scripts/registries/ObjectiveConditionRegistry.gd:304-305` currently omits coordinates.

Improvement: the proposed “every map has a reachable victory” test is too ambitious for a generic static test. Add an exact evaluator regression for map 005 at turns 6/7 and a parity test ensuring the legacy `MapData` and `BattleEncounterDef` objective copies stay equivalent.

### 3. Manual-save labels — RISK

The diagnosis is correct:

- Raw ID: `scripts/ui/PrepScreen.gd:218-228`
- Invalid input emits an engine error: `scripts/autoloads/SaveManager.gd:86-92`
- The UI currently exposes two fields, including “Slot id”: `scenes/ui/PrepScreen.tscn:80-89`

But collision suffix behavior is underspecified and can make repeated saves create endless new slots instead of overwriting the intended save.

Improvement:

- Replace the two-field UI with one player-facing label, or clearly retain an advanced ID field.
- Centralize `label_to_available_slot_id(label, existing_ids)` as a pure helper.
- Define empty/non-ASCII-only labels, 64-character truncation before suffix, case collisions, deterministic suffixes, and whether saving the same label overwrites or creates a new slot.
- Only quiet expected invalid user input. Keep `push_error` for impossible internal IDs and failed I/O.
- Existing saves remain compatible because `save_label` and slot IDs already exist independently.

### 4. Paired escape coordinate — SOUND

The cause is exact:

- Persistent pass-through setter: `scripts/units/Unit.gd:14-20`
- Pairing writes the sentinel: `scripts/core/MapCursor.gd:1302-1307`
- Escape separates and frees without restoring position: `scripts/core/TurnManager.gd:1327-1365`

Approach A is appropriate for the release fix.

Improvement: capture `escape_tile := unit.tile_position` before calling registry separation, then restore every collected unit to it before unregistering. Test lead/support role swaps too, because swap changes which unit owns the live tile at `MapCursor.gd:1331-1368`. Verify the autosave payload, not only live `UnitData`.

### 5. Text-field input — WRONG

The proposed approach already exists in the exact v0.5.2 build:

- `scripts/autoloads/SettingsManager.gd:191-226` intercepts printable confirm/cancel keys for focused `LineEdit`/`TextEdit`.
- `scripts/tests/test_settings_manager.gd:836-856` tests X/Z insertion—but calls `_input()` directly and uses an ordinary root `LineEdit`, not an actual `FileDialog`.

Therefore the plan repeats the failed fix without identifying why native FileDialog still closes. `InputModeManager` is not the current arbitration owner.

Improvement: first reproduce via an actual `FileDialog` receiving a dispatched key event. Check whether its filename editor belongs to a separate `Window`/viewport; the current guard queries only `SettingsManager.get_viewport().gui_get_focus_owner()`. Implement guarding at the dialog/owning window or remove mirrored `ui_cancel` handling while that dialog is visible. Test lowercase and uppercase X/Z, WASD, selection replacement, key repeat, Escape, and all three FileDialog call sites.

### 6. Full-history retention — SOUND, with redundant data work

`GameState.prune_history()` ignores `rewind_cost_mode`: `scripts/autoloads/GameState.gd:872-878`. Making activation retention infinite for `full_history` matches pricing at `GameState.gd:893-930`.

But the two-map fixture is already `full_history` plus `undo_activations=-1`; no data edit is needed.

Improvement: test both modes and round retention. Confirm that `full_history` makes only activation retention infinite; `undo_rounds` should remain independently authored unless the intended rule is truly “retain every ledger entry.”

### 7. Forward-history discard — SOUND

The ordering defect is exactly present at `scripts/autoloads/GameState.gd:956-974`: the full ledger is staged before the live ledger is truncated.

Improvement: add a pure `MapLedger.to_save_array_through(index)` or clone-and-truncate helper rather than manually slicing its serialized representation in `GameState`. Test:

- staged payload length and contents;
- scene reload restoration;
- rollback when `configure_suspend_resume()` rejects;
- charge debit appears both live and in the staged entry;
- target index after prior pruning.

### 8. Manual end-turn Waits — WRONG

The proposed loop will not create N history entries. `set_unit_state(DONE)` calls `_queue_activation_history_push`, but that method stores only one pending metadata dictionary and coalesces all same-frame calls into one deferred push:

- `scripts/core/TurnManager.gd:674-706`
- `scripts/core/TurnManager.gd:709-722`

It may also auto-end the phase while the batch is still being produced. `commit_action_event()` only advances RNG; it does not lodge history (`TurnManager.gd:861-870`).

Improvement: add one TurnManager-owned `commit_remaining_waits(faction_id, ordered_units)` transaction that:

1. suppresses auto-end during the batch;
2. commits each Wait RNG event;
3. marks that unit DONE;
4. flushes one snapshot immediately per unit;
5. requests phase end only after the final snapshot.

Define roster order for non-blue locally controlled factions; `GameState.player_roster` only naturally orders blue. Test N>1, mixed READY/MOVED/DONE, paired/off-map units, auto-end enabled, hotseat factions, and deterministic RNG/history hashes.

### 9. Modal rewind selector — RISK

The diagnosis is correct for MapMenu: it owns no lock and leaves its buttons active (`scripts/ui/MapMenu.gd:57-70,100-146`). The selector is a plain `Control` with minimal cancel handling (`scripts/ui/RewindSelector.gd:1-43`).

However:

- EventBus already implements an owner-refcounted lock; do not add a second counter (`scripts/autoloads/EventBus.gd:61-98`).
- GameOverScreen already holds that lock for its entire visible lifetime (`scripts/ui/GameOverScreen.gd:124-128,311-326`).
- Merely extending `ModalScreen` does not acquire gameplay locks; `ModalScreen.gd:331-348` only handles focus/cancel.

Improvement: make MapMenu an owner of the existing EventBus lock, with idempotent acquire/release on every exit path and `_exit_tree`. Give hosts explicit `open_rewind_selector()`/`close_rewind_selector()` methods that hide/disable and restore their own panels. Test Settings transitions, menu teardown, rewind success/reload, cancel, and node destruction for leaked locks.

### 10. Campaign Data Error — WRONG

Treating every “victory + empty options” as completion can silently corrupt progression. Empty options also mean:

- no pending victory (`CampaignManager.gd:584-587`);
- missing campaign/node (`:588-592`);
- authored successors that fail lookup (`:593-605`).

Only `_pending_result.campaign_complete == true` is safe completion, and that case is already handled at `MapResultsScreen.gd:125-129`. If the pending result is empty, `_on_continue()` cannot commit it (`MapResultsScreen.gd:167-180`, `CampaignManager.gd:637-645`).

Improvement: keep the error state, add structured diagnostics, and make the UI offer “Return to Menu” rather than falsely “Finish Campaign.” Warn distinctly for inactive campaign versus active campaign with missing `_active_node_id` at `CampaignManager.gd:517-529`. The full-flow reproduction is mandatory before any semantic fallback.

### 11. Verification strategy — RISK

Good issue coverage, but add:

- real dispatched FileDialog input, not direct method invocation;
- scene-reload verification for rewind truncation;
- autosave document inspection for paired escape;
- multi-unit same-frame test for manual end-turn;
- modal-lock leak tests on every close/scene-change path;
- old-save load using absent/new rule fields;
- deterministic RNG hash comparison after manual Wait batching and rewind/replay.

### 12. Rollout — RISK

Separate commits and DoD documentation updates are appropriate. The stated protected-ref flow conflicts with the available refs and the workspace lifecycle rule: agents should work/push only on `agent/**`, while humans advance protected refs. `agent/stable-release` is absent locally.

Improvement: register ownership first, create the new agent branch from exact SHA `cc17a0f`, and describe stable/integration advancement as a maintainer action after review. Do not promise a release→integration resync until the 50/30 divergence receives a conflict audit.

### 13. Out of scope — SOUND

The deferrals are reasonable and respect the open-registry architecture. Add the larger Pair Up runtime-position cleanup from Issue 9 to this list explicitly.

No files were modified.
