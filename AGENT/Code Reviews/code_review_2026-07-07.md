# Pillar 1 - Code Review (2026-07-07)

Procedure: `AGENT/Review Procedures/01_Code_Pillar.md`  
Previous review: `AGENT/Code Reviews/code_review_2026-07-05.md`  
Snapshot: `v0.3.0-features` at `7c6378ed959a30ba5517b84f005126c4d9cc7829`  
Reviewed range: non-test `scripts/**/*.gd` changed since `914dd025`  
Working tree note: `AGENT/Docs/playtests/playtest_checklist_v0.3.0.md` was already dirty and was excluded from this code review.

**Score: 7/10**

The v0.3.0 surface is much stronger than the previous review pass: save/suspend is separated into clearer layers, runtime map state now has focused coverage, and the spawn seam findings from July 5 are fixed. The main risk before cutting the build is lifecycle, not local algorithm quality: `RngService.start_map()` exists and tests use it, but production fresh-map startup never calls it.

## Issues

### High - Fresh maps never seed or reset `RngService`

Location: `scripts/autoloads/RngService.gd:21`, `scripts/core/GameMap.gd:103`, `scripts/core/GameMap.gd:127`, `scripts/core/CombatResolver.gd:778`, `scripts/core/CombatResolver.gd:909`

Problem: fresh map startup reaches `_turn_manager.start_map(map_data, _grid)` without calling `/root/RngService.start_map()`. `CombatResolver` then records attack events through `RngService.begin_event()` and commits them, but the service still has its default `map_seed = 0` and `history_hash = 0`, or worse, the `history_hash` left by a prior map.

Why it matters: combat/growth dice on a new campaign map are not freshly seeded per map, and a later map can inherit deterministic history from the previous map. That undercuts the CRR/determinism work and makes save/replay investigation harder because the first runtime RNG state is wrong before any suspend save exists.

Root cause: the RNG lifecycle API was added at the service boundary, but only tests call `start_map()`. The scene lifecycle restores RNG on suspend resume, but fresh-map startup has no matching seed/reset hook.

Recommended fix: call `/root/RngService.start_map()` during fresh `GameMap` startup before any dice-bearing action can occur. Keep suspend resume on the restore path through `RngService.from_save_dict()` instead of reseeding. Add a scene-level test that a fresh `GameMap` initializes a non-zero `map_seed` and zeroed `history_hash`, and that suspend resume preserves the serialized RNG values.

Tradeoff: this makes map startup explicitly own RNG lifecycle. That is the right coupling because map runtime already owns turn, pair-up, unit snapshots, and suspend restore.

### Medium - Changing Input Mode in Settings does not refresh prompts immediately

Location: `scripts/ui/SettingsScreen.gd:104`, `scripts/ui/SettingsScreen.gd:350`, `scripts/autoloads/InputModeManager.gd:29`, `scripts/autoloads/InputModeManager.gd:53`, `scripts/autoloads/InputModeManager.gd:61`

Problem: the Settings row for `input_mode` has availability metadata but no apply hook. `_on_enum_setting_changed()` writes and saves `SettingsManager.input_mode`, then only invokes an apply method when the schema row declares one. `InputModeManager` refreshes on `_ready()`, raw input events, and joypad connection changes, so a user who explicitly switches Keyboard/Gamepad can see stale prompts until another input event or device event occurs.

Why it matters: the prompt-swapping work is user-facing. A Settings change should update `InputModeManager.active_input_mode` and emit `input_mode_changed` immediately so HUD, modal, attack preview, and unit details subscribers do not lag behind the selected mode.

Root cause: input-mode detection and explicit input-mode selection share the same backing setting, but Settings does not notify the input-mode service after writing that setting.

Recommended fix: expose a small public `refresh_active_input_mode()` method on `InputModeManager` that delegates to the existing refresh logic, then add that method as the Settings row apply hook for `input_mode`. Add a test that changes the Settings enum without sending another input event and asserts `active_input_mode` plus prompt subscribers update immediately.

Tradeoff: a public refresh method slightly widens the autoload API, but it keeps Settings from knowing internal detection rules.

### Medium - Rebind UI omits several shipped gameplay actions

Location: `scripts/ui/SettingsScreen.gd:629`, `project.godot:134`, `project.godot:140`, `project.godot:146`, `project.godot:153`, `project.godot:160`, `scripts/tests/test_input_bindings.gd:50`

Problem: `_KEYBIND_LABELS` exposes cursor movement, confirm/cancel, cycling, menu/settings, inspect, and danger-zone actions. It does not expose shipped gameplay actions `more_info`, `peek_range`, `zoom_reset`, `zoom_in`, or `zoom_out`, even though these actions have default keyboard/gamepad bindings and tests assert those defaults.

Why it matters: players can use these controls but cannot rebind them through Settings, and conflict detection cannot protect them during rebinding. This is especially visible for `more_info`, which is now a first-class prompt-swapped action across UI surfaces.

Root cause: the InputMap grew, but the editable-actions list remained a closed hardcoded list.

Recommended fix: add the missing gameplay actions to `_KEYBIND_LABELS`, or better, introduce a small rebindable-action registry with explicit exemptions for actions that should stay hidden. Add a coverage test that every non-debug, player-facing InputMap action is either represented in the rebind UI or intentionally exempted.

Tradeoff: adding the labels is fastest for v0.3.0. A registry aligns better with the project author-extensibility rule and prevents this class of omission from recurring.

### Medium - Author-facing vocabularies still depend on closed dispatch lists

Location: `scripts/autoloads/DataManager.gd:13`, `scripts/core/EnemyAI.gd:83`, `scripts/core/TurnManager.gd:919`, `scripts/items/ItemHandler.gd:6`, `scripts/resources/ObjectiveCondition.gd:60`

Problem: several content-facing vocabularies still use closed arrays plus `match` dispatch: objective types, AI profiles, and item effect ids are the clearest examples.

Why it matters: this is the recurring extension-point smell documented in the author-extensibility model. Adding content in these areas still requires engine edits, which is exactly the failure mode the open-registry rule is meant to avoid.

Root cause: these systems predate the registry decision and were not migrated as part of the v0.3.0 feature work.

Recommended fix: do not add more closed cases while cutting v0.3.0. Track each migration as a registry-backed seam: objective predicates, AI profiles, and item/effect handlers can all move behind data-driven registries without changing authored content semantics.

Tradeoff: this is likely not a v0.3.0 build blocker unless new content is being added in those vocabularies, but it remains architectural debt.

## Positive Observations

- Save architecture is cleanly separated: `SaveData` owns format normalization/validation, `SaveCodec` owns typed conversion, `SaveManager` owns disk paths, and `GameState` owns runtime capture/restore.
- Suspend resume coverage is meaningfully broad. The runtime payload covers live units, turn scheduler state, pair-up state, RNG state, cursor/watch UI state, and clears the payload after application.
- The July 5 spawn seam findings are fixed. Runtime placement now rejects ambiguous unit sources, and placement overrides preserve authored `ai_profile` unless an override is explicitly present.
- `InputModeManager` centralizes mode and brand prompt state instead of scattering joypad-label logic across UI screens.
- The new More Info surfaces consume input explicitly and reuse the shared `SelectionCursor`, keeping modal behavior consistent across attack preview, HUD, and unit details.

## Architectural Observations

- `RngService` has the right seam shape, but lifecycle ownership must move from tests into production map startup. This should be verified at the scene boundary because local unit tests already make the service look correct.
- The input-context work still relies on screen-local input consumption rather than a richer context owner stack. That is acceptable for the current build, but more modal surfaces will make the B6 Rebuild C decision harder to defer.
- The remaining closed vocabularies are known debt, not a regression in this branch. The important near-term guardrail is to avoid adding any new content extension point as an enum-plus-match switch.

## Delta vs. Previous Review

- Fixed: inline enemy placements no longer lose authored `ai_profile` values when no override is provided.
- Fixed: runtime placement resolution now matches validation by requiring exactly one source: `unit_data` or `unit_data_path`.
- New: fresh-map RNG lifecycle is not wired into production startup.
- New: explicit Settings changes to Input Mode do not immediately refresh `InputModeManager`.
- New: the rebind UI does not cover all shipped player-facing actions.
- Still open: closed author-facing vocabularies should be migrated to registry-backed seams over time.

## Prioritized Action Plan

1. Fix fresh-map `RngService.start_map()` lifecycle and add scene-level regression coverage before cutting v0.3.0.
2. Add an immediate Input Mode refresh path from Settings and test the no-extra-input case.
3. Expose or explicitly exempt all player-facing InputMap actions in the rebind UI, with coverage to prevent drift.
4. Keep registry migrations on the roadmap and avoid new closed dispatch surfaces while finishing the build.
