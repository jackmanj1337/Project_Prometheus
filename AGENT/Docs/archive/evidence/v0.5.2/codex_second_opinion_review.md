> **ARCHIVED** — Codex (gpt-5.6) second-opinion review of the v0.5.2 root-cause findings, run read-only against build 06e0386 on 2026-07-21. Verbatim.

# Codex second-opinion review — v0.5.2 findings

- Victory requires turn number greater than 6 and a friendly on either hidden hold tile: `data/maps/battle_encounters/encounter_map_005_defend.tres:17-21,53-55`; evaluator at `scripts/core/TurnManager.gd:1244-1260`.
- Defeat fires after turn 8: `data/maps/battle_encounters/encounter_map_005_defend.tres:12-15,56-58`; evaluator at `scripts/core/TurnManager.gd:1104-1105`.
- The HUD says only “Hold for 6 turn(s)” and omits coordinates: `scripts/registries/ObjectiveConditionRegistry.gd:304-305`.

The turn-limit is not what makes turn 7 fail; the hidden tile condition does. It does make the natural “survive indefinitely” interpretation lose later.

Better fix:

- For a conventional defend map, remove `tiles` and remove the redundant turn-limit defeat. Keep `survive turns=6` plus `protect`.
- If holding a zone is intended, author/display a clearly marked zone and render “Hold (4,6) or (4,7) through turn 6.” The registry display handler should format all authored tiles, using the existing one-based display convention.

## Issue 3a — CONFIRMED

`prune_history()` ignores `rewind_cost_mode`. With four charges it retains at least five activation entries regardless of `"full_history"`: `scripts/autoloads/GameState.gd:870-878`. Yet `"full_history"` charges a flat one for any retained target: `scripts/autoloads/GameState.gd:893-904`.

Better fix: when mode is `"full_history"` and at least one rewind remains, make activation retention infinite—or introduce a separate authored history-retention budget. Charge count and retention depth should not be conflated. Add a test with more than five activations and one full-history charge.

## Issue 3b — CONFIRMED

The payload captures the full ledger before truncation (`scripts/autoloads/GameState.gd:956-969`), `configure_suspend_resume()` installs that full ledger and payload (`scripts/autoloads/GameState.gd:378-415`), then only the live ledger is truncated (`scripts/autoloads/GameState.gd:971-974`). Reload re-stages the payload (`scripts/core/GameMap.gd:58-75`), resurrecting the abandoned branch.

Cleanest fix: construct a truncated ledger copy and place it in `payload["ledger"]` before `configure_suspend_resume()`. This preserves the current validate-before-commit transaction ordering. Truncating the live ledger first weakens rollback safety.

Also assert both live ledger and staged payload contain exactly `target_index + 1` entries before scene reload.

## Issue 4 — CONFIRMED

The selector is not modal:

- MapMenu remains visible when opening it: `scripts/ui/MapMenu.gd:116-123`.
- RewindSelector merely grabs initial focus and handles Cancel: `scripts/ui/RewindSelector.gd:16-43`.
- MapCursor is blocked only by the shared gameplay-modal lock: `scripts/core/MapCursor.gd:300-314,470-476`.
- Neither MapMenu nor RewindSelector acquires that lock.

Better systemic fix: make MapMenu acquire/release the shared gameplay-modal lock for its entire visible lifetime, and disable/hide the parent button container while RewindSelector is open. Give the selector an explicit focus scope with deterministic neighbours. Apply the same selector-host behavior to `GameOverScreen`.

## Issue 5 — CONFIRMED

`cancel` includes letter X (`keycode=88`): `project.godot:97-103`. Binding ordinary typing characters to global UI actions conflicts with native text-entry controls such as FileDialog’s filename field.

Better fix: remove X and Z as global confirm/cancel bindings; retain Escape/Enter/Space and controller buttons. Suppressing actions only while a `LineEdit` has focus is a useful defensive layer, but global letter bindings remain fragile for native dialogs and future text fields.

## Issue 6 — CONFIRMED

Prep passes the trimmed raw ID unchanged (`scripts/ui/PrepScreen.gd:218-228`). Spaces are rejected by the slot allow-list (`scripts/autoloads/SaveManager.gd:63-72`), and `save_slot()` logs an engine error (`scripts/autoloads/SaveManager.gd:86-92`), followed by another error from CampaignManager (`scripts/autoloads/CampaignManager.gd:857-863`).

Better fix: treat the player text as a display label and generate a deterministic safe ID—slug plus short collision suffix. Validate in Prep before calling the persistence layer. Invalid user input should return structured/quiet failure; reserve `push_error` for violated internal contracts or I/O failures.

## Issue 7 — CONFIRMED design gap

There is one global `party_gold`: `scripts/autoloads/GameState.gd:158`. ResourceLedger’s party handler writes that property rather than selecting a faction wallet: `scripts/autoloads/ResourceLedger.gd:131-140`.

This is not a regression under the existing single-party economy model. It becomes a feature gap for hotseat/PvP or independently funded factions. Implement it through an open resource-owner registry/wallet model, not a hardcoded faction switch.

## New bug

Paired escape leaves the support’s campaign-roster `UnitData.tile_position` at `OFF_MAP_TILE`. It is currently masked by prep deployment overwriting the position, but it contaminates between-map autosaves and could break future prep consumers, save inspection, or launch paths without explicit deployment. The fix belongs in the Pair Up/escape state boundary, with a campaign-save regression test.
tokens used
123,262
# Review

## Issue 1 — ALTERNATE-CAUSE

The proposed roster-empty/advance failure is refuted. The paired and separate paths both retain `player_roster`; `prepare_pending_advance()` only checks that roster through `is_roster_ready_for_launch()`.

Evidence:

- Escaped nodes are removed only from `GameState.all_units`, not `player_roster`: `scripts/core/TurnManager.gd:1348-1364`.
- `keep_current_roster` accepts any non-empty roster: `scripts/autoloads/GameState.gd:517-542`.
- The successor is correctly authored: `data/campaigns/proving_grounds.json:29-38`.
- Successor options are derived solely from `_pending_result.node_id` and campaign graph edges, with no Pair Up, unit-position, deployment, or frame-state dependency: `scripts/autoloads/CampaignManager.gd:584-606`.
- The reported “Campaign Data Error / next battle is unavailable” is rendered before `prepare_pending_advance()` and means `get_pending_successor_options()` returned empty: `scripts/ui/MapResultsScreen.gd:125-134`.
- The supplied repro confirms both paths produce the same pending result and successful preparation.

There is one real paired-only state difference: `Unit.tile_position` is a pass-through to `UnitData.tile_position` (`scripts/units/Unit.gd:14-20`). Pairing therefore writes the roster support’s persistent position to `(-1,-1)` (`scripts/core/MapCursor.gd:1302-1307`). `record_escape()` clears only registry bookkeeping and never restores that position (`scripts/core/TurnManager.gd:1348-1364`; `scripts/autoloads/PairUpRegistry.gd:90-100`). A normal Separate restores it first (`scripts/core/MapCursor.gd:1372-1388`).

That stale coordinate is a new bug, but it does not explain the observed results-screen error: prep ignores roster coordinates (`scripts/ui/PrepScreen.gd:54-60`), and an explicit deployment overwrites them during spawn (`scripts/core/GameMap.gd:273-300`, `scripts/units/Unit.gd:34-37`).

Best-supported conclusion: the together/separate correlation is a red herring or the live run had a different campaign/DataManager state. The displayed error requires the pending result or active campaign graph to be absent/stale, not a launch/spawn failure.

Better fix:

- Restore every escaping unit’s roster `UnitData.tile_position` to its escape/lead tile before separation/removal, or make Pair Up’s off-map location node-runtime state rather than persistent roster state.
- Add diagnostics to the error UI containing pending campaign/node IDs and authored successor IDs.
- Do not change branch/deployment logic without reproducing a failure there.

Decisive test: drive the real scene flow across frames:

1. Launch `node_04_escape` through `CampaignManager`.
2. Pair through `MapCursor`.
3. Escape via `_commit_escape()`.
4. Await one process frame.
5. Assert `MapResultsScreen` has one successor option.
6. Invoke Continue, await prep, build its plan, begin battle, await `GameMap._ready`.
7. Assert both player IDs spawn on authored start tiles and no error was logged.

Run the identical sequence after a normal Separate. Also assert the support roster position immediately after victory; that will expose the confirmed stale-coordinate bug.

## Issue 2 — CONFIRMED

The map is technically winnable but misleadingly authored.

- Victory requires turn number greater than 6 and a friendly on either hidden hold tile: `data/maps/battle_encounters/encounter_map_005_defend.tres:17-21,53-55`; evaluator at `scripts/core/TurnManager.gd:1244-1260`.
- Defeat fires after turn 8: `data/maps/battle_encounters/encounter_map_005_defend.tres:12-15,56-58`; evaluator at `scripts/core/TurnManager.gd:1104-1105`.
- The HUD says only “Hold for 6 turn(s)” and omits coordinates: `scripts/registries/ObjectiveConditionRegistry.gd:304-305`.

The turn-limit is not what makes turn 7 fail; the hidden tile condition does. It does make the natural “survive indefinitely” interpretation lose later.

Better fix:

- For a conventional defend map, remove `tiles` and remove the redundant turn-limit defeat. Keep `survive turns=6` plus `protect`.
- If holding a zone is intended, author/display a clearly marked zone and render “Hold (4,6) or (4,7) through turn 6.” The registry display handler should format all authored tiles, using the existing one-based display convention.

## Issue 3a — CONFIRMED

`prune_history()` ignores `rewind_cost_mode`. With four charges it retains at least five activation entries regardless of `"full_history"`: `scripts/autoloads/GameState.gd:870-878`. Yet `"full_history"` charges a flat one for any retained target: `scripts/autoloads/GameState.gd:893-904`.

Better fix: when mode is `"full_history"` and at least one rewind remains, make activation retention infinite—or introduce a separate authored history-retention budget. Charge count and retention depth should not be conflated. Add a test with more than five activations and one full-history charge.

## Issue 3b — CONFIRMED

The payload captures the full ledger before truncation (`scripts/autoloads/GameState.gd:956-969`), `configure_suspend_resume()` installs that full ledger and payload (`scripts/autoloads/GameState.gd:378-415`), then only the live ledger is truncated (`scripts/autoloads/GameState.gd:971-974`). Reload re-stages the payload (`scripts/core/GameMap.gd:58-75`), resurrecting the abandoned branch.

Cleanest fix: construct a truncated ledger copy and place it in `payload["ledger"]` before `configure_suspend_resume()`. This preserves the current validate-before-commit transaction ordering. Truncating the live ledger first weakens rollback safety.

Also assert both live ledger and staged payload contain exactly `target_index + 1` entries before scene reload.

## Issue 4 — CONFIRMED

The selector is not modal:

- MapMenu remains visible when opening it: `scripts/ui/MapMenu.gd:116-123`.
- RewindSelector merely grabs initial focus and handles Cancel: `scripts/ui/RewindSelector.gd:16-43`.
- MapCursor is blocked only by the shared gameplay-modal lock: `scripts/core/MapCursor.gd:300-314,470-476`.
- Neither MapMenu nor RewindSelector acquires that lock.

Better systemic fix: make MapMenu acquire/release the shared gameplay-modal lock for its entire visible lifetime, and disable/hide the parent button container while RewindSelector is open. Give the selector an explicit focus scope with deterministic neighbours. Apply the same selector-host behavior to `GameOverScreen`.

## Issue 5 — CONFIRMED

`cancel` includes letter X (`keycode=88`): `project.godot:97-103`. Binding ordinary typing characters to global UI actions conflicts with native text-entry controls such as FileDialog’s filename field.

Better fix: remove X and Z as global confirm/cancel bindings; retain Escape/Enter/Space and controller buttons. Suppressing actions only while a `LineEdit` has focus is a useful defensive layer, but global letter bindings remain fragile for native dialogs and future text fields.

## Issue 6 — CONFIRMED

Prep passes the trimmed raw ID unchanged (`scripts/ui/PrepScreen.gd:218-228`). Spaces are rejected by the slot allow-list (`scripts/autoloads/SaveManager.gd:63-72`), and `save_slot()` logs an engine error (`scripts/autoloads/SaveManager.gd:86-92`), followed by another error from CampaignManager (`scripts/autoloads/CampaignManager.gd:857-863`).

Better fix: treat the player text as a display label and generate a deterministic safe ID—slug plus short collision suffix. Validate in Prep before calling the persistence layer. Invalid user input should return structured/quiet failure; reserve `push_error` for violated internal contracts or I/O failures.

## Issue 7 — CONFIRMED design gap

There is one global `party_gold`: `scripts/autoloads/GameState.gd:158`. ResourceLedger’s party handler writes that property rather than selecting a faction wallet: `scripts/autoloads/ResourceLedger.gd:131-140`.

This is not a regression under the existing single-party economy model. It becomes a feature gap for hotseat/PvP or independently funded factions. Implement it through an open resource-owner registry/wallet model, not a hardcoded faction switch.

## New bug

Paired escape leaves the support’s campaign-roster `UnitData.tile_position` at `OFF_MAP_TILE`. It is currently masked by prep deployment overwriting the position, but it contaminates between-map autosaves and could break future prep consumers, save inspection, or launch paths without explicit deployment. The fix belongs in the Pair Up/escape state boundary, with a campaign-save regression test.
