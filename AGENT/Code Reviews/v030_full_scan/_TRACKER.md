---
Role: dated
---

# v0.3.0 Full-Scan Tracker

Resume anchor for the resumable full code scan of the v0.3.0 production delta.
**On each invocation, read this file first**, find the first `TODO`/`IN-PROGRESS`
pass, and do exactly that one pass (read → write findings file → flip row to
`DONE` → commit → stop with a pointer to the next pass).

- Base: `ab81a21` (v0.2.8 exe source) · Head: `b7bcfd2` (pre-build v0.3.0 snapshot)
- Cadence: **one pass per invocation** (decided 2026-07-08).
- Type: document-only code-pillar review. No production edits; fixes land later.
- Procedure: `AGENT/Review Procedures/01_Code_Pillar.md`
- Scope detail + file→pass map: `00_scope.md`

| Pass | Subsystem | Files | Findings file | Status | Findings | Commit |
|---|---|---:|---|---|---:|---|
| 0 | Setup & scope lock | — | `00_scope.md` | DONE | — | (this commit) |
| 1 | Save/persistence codec | 3 | `01_save_persistence.md` | DONE | 7 (all Low) | (this commit) |
| 2 | Determinism: state+RNG+combat | 7 | `02_determinism.md` | DONE | 1 High, 2 Low | (this commit) |
| 3 | Input model & settings persist | 3 | `03_input_model.md` | DONE | 1 Med, 2 Low | (this commit) |
| 4 | Input display & rebind UI | 2 | `04_input_display.md` | DONE | 1 Med (+carried half), 2 Low | (this commit) |
| 5 | Map/turn core | 5 | `05_map_turn_core.md` | DONE | 1 High (carried), 4 Low | (this commit) |
| 6 | UI screens, selection & misc data | 18 | `06_ui_misc.md` | DONE | 1 Med (carried), 3 Low | (this commit) |
| 7 | General/integration & rollup | (all) | `code_review_v0.3.0_full_scan_2026-07-08.md` | DONE | 1 High, 3 Med, 20 Low | (this commit) |

Total production files covered by passes 1–6: **38** (3+7+3+2+5+18).

## Log

- 2026-07-08 — Pass 0: folder + tracker + scope created; boundary commits
  confirmed (`ab81a21`→`b7bcfd2`), working tree clean at `cef8e83`.
- 2026-07-08 — Pass 1 (save/persistence): read all 3 files at head + their test
  suites. 7 findings, all Low. Highlights: `has_continue_save()` dead if/else +
  needless index read on the MainMenu path (L1); dead `_vector_array_from_variant`
  (L2); non-atomic single-slot `save_suspend` write (L6). No correctness bugs; the
  carried High (`start_map`) is Pass 2/5. Next: Pass 2 (determinism: state+RNG+combat).
- 2026-07-08 — Pass 2 (determinism: state+RNG+combat): read all 7 files at head +
  their RNG/suspend tests, plus the `GameMap`/`TurnManager` seam (Pass 5) to confirm
  the carried High in-context. **1 High, 2 Low.** H1 = fresh maps never call
  `RngService.start_map()` (grep-confirmed: `GameMap.gd:127` calls
  `TurnManager.start_map`, not `RngService.start_map`) → `map_seed` stays `0` (zero
  cross-session entropy) and `history_hash` bleeds between maps; snapshot/resume are
  unaffected. Fix site is Pass 5 `GameMap` (seed before `take_map_snapshot`). L1 stale
  `_current_hit_formula` comment (campaign_rules already live); L2
  `_string_array_from_variant` duplicated ×4. `_original_tiles` stale-tile hazard is
  explicitly defused (positive). Next: Pass 3 (input model & settings persist).
- 2026-07-08 — Pass 3 (input model & settings persist): read all 3 files at head +
  their suites, cross-read `SettingsScreen`'s input_mode row (Pass 4) for the
  consumer side. **1 Medium (carried, re-confirmed), 2 Low.** M1 = changing Settings
  → Input Mode does not refresh active mode/prompts until the next input event:
  `InputModeManager._refresh_active_input_mode` is private + only runs on
  `_ready`/`_input`/joy-hotplug, and the `input_mode` row has no `"apply"` hook —
  so the setting looks inert until an unrelated event nudges the resolver. Fix spans
  Pass 3 (add a public `refresh_from_settings`) + Pass 4 (call it from the row +
  `reset_section_to_defaults`). L1 = input-mode vocab + `normalize_input_mode`
  duplicated across `SettingsManager`/`InputModeManager` (two sources of truth,
  extends Pass1 L4 / Pass2 L2). L2 = `available_modes()` rebuilt + `OS.has_feature`
  re-queried per input event (cache once). Flagged the `MapCursorInput` decode+poll
  double-drive seam for Pass 5's `MapCursor` (arm-on-decode ordering). Next: Pass 4
  (input display & rebind UI).
- 2026-07-08 — Pass 4 (input display & rebind UI): read both files at head + their
  suites (`test_settings_screen` 24, `test_input_display` 7), cross-read
  `InputModeManager` + `project.godot [input]`. **1 Medium (carried, re-CONFIRMED) +
  the Pass-4 half of Pass-3's Medium; 2 Low.** M1 = `_KEYBIND_LABELS`
  (`SettingsScreen.gd:630`) omits 5 shipped player actions (`more_info`, `peek_range`,
  `zoom_in/out/reset`) — grep-confirmed live consumers — so they're unbindable AND
  invisible to the conflict scan (rebinding a listed action onto e.g. default `F` =
  silent double-bind). M2 (not double-counted) = the input_mode row has no `"apply"`
  hook + reset doesn't refresh `InputModeManager`; fix-shape wrinkle: the `sm.call(apply)`
  hook can't reach an InputModeManager method — prefer a SettingsManager→manager
  settings-changed signal. L1 `pad_rebind` stored via node-path re-fetch vs in-scope
  local; L2 `more_info_hint_for` hardcodes "F" fallback when unbound. Contract check
  positive: InputDisplay/SettingsScreen mode strings match `InputModeManager` `MODE_*`
  exactly. No correctness bugs. Next: Pass 5 (map/turn core, 5 files) — includes the
  `GameMap.start_map()` High fix site + the `MapCursor` arm-on-decode ordering flagged
  in Pass 3.

- 2026-07-08 — Pass 5 (map/turn core): read all 5 files at head + their diffs and
  suites, cross-read `RngService`/`MapCursorInput`. **1 High (carried, re-CONFIRMED)
  + 4 Low (1 nit).** H1 = `GameMap._ready()` never calls `RngService.start_map()` on
  the fresh path — `map_seed` stays `0` and `history_hash` bleeds across maps; fix site
  localized to `GameMap.gd:114-115` (seed before `take_map_snapshot`, fresh branch
  only; resume path already restores via `from_save_dict`). L1 dead
  `TurnManager._array_from_variant` (`:231`); L2 unused overlay `blend` metadata +
  `overlay_layer_blends()` (`GridManager.gd:562-576` — `repaint_overlays` uses
  precedence+opacity, never the flag); L3 nit `_pending_item_id` not cleared on
  promotion cancel (benign); L4 keyboard-held zoom now auto-repeats via
  `_poll_held_zoom` (behavior change, likely intended). Positives: no raw RNG in any
  of the 5; **the Pass-3 arm-on-decode concern resolves CLEAN** (edge arms `_held_dir`
  before the same-frame poll ticks the DELAY timer → no double-move); `_original_tiles.erase()`
  guards defuse the stale pre-move-tile desync in the RNG record path; overlay
  precedence registry is a proper open registry. Next: Pass 6 (UI screens, selection &
  misc data, 18 files) — carries the Pass-6 registry-debt Medium (`DataManager`).

- 2026-07-08 — Pass 7 (general/integration & rollup, FINAL): read across passes 1–6,
  hunted cross-cutting/seam issues, and wrote the consolidated
  `code_review_v0.3.0_full_scan_2026-07-08.md`. **Rollup totals: 1 High, 3 Medium, 20
  Low; zero new correctness bugs across all 38 files. Overall health 6/10** (holds with
  the composed 6/10 delta review — same carried High + Mediums, more thoroughly read).
  Carried findings folded: H1 = fresh `GameMap` never calls `RngService.start_map()`
  (fix site `GameMap.gd:114-115`, release blocker); M1 = Settings input-mode change
  doesn't refresh prompts (Pass 3 root + Pass 4 wiring, counted once); M2 = rebind UI
  omits 5 actions + conflict blind spot; M3 = DataManager closed vocabularies
  (pre-existing registry debt → register resolutions). Four cross-cutting themes named:
  closed-vocabulary-vs-open-registry (×3), duplicated coercers/vocab (×3), "tests seed,
  production forgets" (H1), and speculative-abstraction/dead code. §4 records the seams
  verified CLEAN so re-reviews don't re-chase them; §5 asserts 38/38 coverage.
  check_docs 26/26 + RNG guard green (docs-only). **Scan COMPLETE — no next pass.**

- 2026-07-08 — Pass 6 (UI screens, selection & misc data): read full diffs for all 18
  files + full current context for the new/refactored cores (`SelectionCursor`,
  `ModalScreen` seam, `UnitDetailsScreen`, `AttackPreview`, `HUD` terrain pager,
  `MenuScale._recenter`); cross-read `RngService` event API + `SaveCodec` `has_weapon`
  consumer + `NewGameScreen._on_start`; sampled the selector/data/details suites.
  **1 Medium (carried, re-CONFIRMED) + 3 Low (1 nit). No new correctness bugs.** M1 =
  DataManager closed author-facing vocabularies (`_VALID_AI_PROFILES` `[AIP]` /
  `_VALID_OBJECTIVE_TYPES` `[TCV-4]` / `_VALID_STATS` `[STM]` / roster-policy /
  activation-mode) — closed allow-lists needing an engine edit to extend; PRE-EXISTING,
  not introduced by this delta (diff only touched the placement XOR validation +
  `has_weapon`); fix belongs to the register resolutions. L1 `SelectionCursor.configure()`
  sets `index=-1` on shrink without emitting `changed` (benign; all 3 consumers
  re-render after configure). L2 `NewGameScreen._on_start` launches even when
  `_persist_rules` no-ops on null `campaign_rules` (dead-defensive; GameState always
  inits rules). L3 nit re-clicking the selected entry is now a no-op. **Positives:**
  `Unit.level_up()` RNG begin/commit is CORRECT per the documented contract (dice =
  begin+commit, non-dice = commit-only, `begin_event` is pure) — the `growth_fixed`
  commit-only path is intended, not an asymmetry bug; no raw RNG except the annotated
  headless fallback drawing from the passed event RNG; CampaignRules read-migration
  consistent + null-guarded across all 5 consumers; MenuScale reactive re-center has a
  sound re-entrancy guard; ModalScreen focus seam is a clean virtual-override design;
  SelectionCursor has real targeted coverage. Next: Pass 7 (general/integration &
  rollup) — the consolidated `code_review_v0.3.0_full_scan_*.md` with the 38/38
  coverage assertion + updated score.
