---
Role: dated
---

# v0.3.0 Release-Delta Code Review - 2026-07-07

Procedure:

- `AGENT/Review Procedures/00_Master_Review_Procedure.md`
- `AGENT/Review Procedures/01_Code_Pillar.md`
- `AGENT/Review Procedures/03_Scenes_Data_Assets_Pillar.md`
- `AGENT/Review Procedures/04_Tests_CI_Build_Pillar.md`

Prior reviews:

- `AGENT/Code Reviews/code_review_2026-07-05.md`
- `AGENT/Code Reviews/data_assets_review_2026-07-05.md`
- `AGENT/Code Reviews/tests_ci_build_review_2026-07-05.md`
- `AGENT/Code Reviews/code_review_2026-07-07.md`

Review type: document-only release-delta pass for the pre-build v0.3.0 snapshot.

- Base: `ab81a21` - v0.2.8 executable source.
- Head reviewed: `b7bcfd2ec6738e857faced0f92abb76bf4b2b3d8` - pre-build v0.3.0 snapshot.
- Branch: `v0.3.0-features`.
- Dirty-tree note: the working tree was clean before this review session's note
  and report edits. Those edits are excluded from the reviewed target.

**Score:** 6/10

The delta is mechanically much stronger than the v0.2.8 base: save/suspend,
controller input, prompt swapping, MRD overlays, and deterministic RNG seams now
have real automated coverage. It is not build-ready yet. One production lifecycle
bug still undermines map RNG state, two player-facing input surfaces are out of
sync with the feature docs, and release metadata/build-manifest work has not been
cut for v0.3.0.

## Issues

### High - Fresh maps never seed or reset `RngService`

Location: `scripts/autoloads/RngService.gd:21`,
`scripts/core/GameMap.gd:103`, `scripts/core/GameMap.gd:115`,
`scripts/core/GameMap.gd:127`, `scripts/autoloads/GameState.gd:632`,
`scripts/autoloads/GameState.gd:647`, `scripts/core/CombatResolver.gd:778`,
`scripts/core/CombatResolver.gd:909`, `scripts/core/TurnManager.gd:715`

Problem: `RngService.start_map()` rolls `map_seed` and resets
`history_hash`, but fresh `GameMap._ready()` never calls it. Fresh map startup
spawns units, calls `GameState.take_map_snapshot()`, and starts the turn manager.
Combat and non-dice actions then consume and commit RNG events through the
service, but the service can still be at `{map_seed: 0, history_hash: 0}` or
carry a previous map's history.

Why it matters: `GDD_01` requires all gameplay dice to derive from
`mix(map_seed, history_hash, event_record)` and requires `{map_seed,
history_hash}` in every Retry/suspend snapshot (`AGENT/GDD/GDD_01_Architecture.md:797`,
`AGENT/GDD/GDD_01_Architecture.md:810`). The production order currently captures
the Retry snapshot before a fresh seed exists. A first combat, growth event,
early suspend save, or later map can therefore start from zero/stale RNG state,
which breaks the determinism investigation contract.

Root cause: tests initialize the service directly, so the service API looks good
in isolation. `test_suspend_map_runtime.gd` explicitly calls
`rng.start_map(20260706)` before instantiating the map
(`scripts/tests/test_suspend_map_runtime.gd:43`), and `test_rng_snapshot.gd`
uses the service directly. The scene boundary test only asserts that
`TurnManager.start_map()` ran (`scripts/tests/test_game_map_scene.gd:215`).

Recommended fix: on non-resume `GameMap` startup, call
`/root/RngService.start_map()` before `GameState.take_map_snapshot()` and before
any turn/action can commit. Keep suspend resume on `RngService.from_save_dict()`
(`scripts/core/GameMap.gd:260`) rather than reseeding. Add a scene-level
regression that instantiates `GameMap.tscn` as a fresh map and asserts non-zero
`map_seed`, zero `history_hash`, and a Retry snapshot with the same values.

### Medium - Settings Input Mode changes do not refresh prompts immediately

Location: `scripts/ui/SettingsScreen.gd:104`,
`scripts/ui/SettingsScreen.gd:350`, `scripts/ui/SettingsScreen.gd:365`,
`scripts/ui/SettingsScreen.gd:369`, `scripts/autoloads/InputModeManager.gd:53`,
`scripts/autoloads/InputModeManager.gd:61`

Problem: the Settings row for `input_mode` saves the selected value but has no
apply hook. `InputModeManager` refreshes on `_ready()`, raw input detection, and
joypad connection changes, but not immediately after the explicit Settings
write.

Why it matters: `GDD_07` says prompts render the active scheme and re-render
live when the scheme changes (`AGENT/GDD/GDD_07_UI_UX.md:84`). A user can set
Gamepad/Keyboard in Settings and see stale prompt labels or focus state until
another qualifying input/device event causes a refresh.

Root cause: Settings writes `SettingsManager.input_mode`, while
`InputModeManager._refresh_active_input_mode()` remains private to the service.
The existing tests cover gray-state display and direct screen response to
`_on_input_mode_changed()` (`scripts/tests/test_settings_screen.gd:493`,
`scripts/tests/test_settings_screen.gd:532`), but not the end-to-end path from
selecting the enum row to `InputModeManager.input_mode_changed`.

Recommended fix: expose a small public refresh method on `InputModeManager` and
add it as the `input_mode` row's apply hook. Add a test that changes the Settings
enum without injecting another input event and asserts the active mode and a
prompt subscriber update immediately.

### Medium - Rebind UI omits shipped player-facing actions

Location: `scripts/ui/SettingsScreen.gd:629`,
`project.godot:134`, `project.godot:140`, `project.godot:146`,
`project.godot:153`, `project.godot:160`,
`scripts/tests/test_input_bindings.gd:50`,
`AGENT/Docs/plans/key_rebind_ui_implementation_plan_2026-06-21.md:152`,
`AGENT/GDD/GDD_07_UI_UX.md:47`

Problem: `_KEYBIND_LABELS` exposes movement, confirm/cancel, cycling,
menu/settings, inspect, and danger-zone actions. It omits shipped normal actions
`more_info`, `peek_range`, `zoom_in`, `zoom_out`, and `zoom_reset`, even though
they are defined in `project.godot`, described in `GDD_07`, and asserted by
`test_input_bindings.gd`.

Why it matters: these controls can be used but cannot be rebound through
Settings, and conflict detection cannot protect them. The omission is most
visible for `more_info`, which is now a prompt-swapped action across the combat
forecast, character sheet, and terrain panel.

Root cause: the editable action list is a closed hand-maintained dictionary, and
the InputMap grew after the first rebind UI work. The rebind implementation plan
says all non-debug actions are rebindable, with debug rows read-only.

Recommended fix: for v0.3.0, add labels for the missing actions. Then add a
drift test that every non-debug, player-facing InputMap action is either present
in the rebind registry/list or explicitly exempted.

### Medium - Author-facing vocabularies still use closed dispatch lists

Location: `scripts/autoloads/DataManager.gd:13`,
`scripts/autoloads/DataManager.gd:124`, `scripts/core/EnemyAI.gd:83`,
`scripts/items/ItemHandler.gd:6`, `scripts/items/ItemHandler.gd:28`,
`scripts/resources/ObjectiveCondition.gd:59`,
`scripts/shared/TileActions.gd:22`, `scripts/shared/TileActions.gd:42`,
`AGENT/GDD/GDD_01_Architecture.md:23`,
`AGENT/Docs/registers/authoring_extensibility_open_questions_2026-06-26.md:30`

Problem: several author-facing vocabularies still require engine edits for
content growth: objective types, AI profiles, item effect ids, skill stat names,
and tile actions are all examples of closed arrays/dictionaries plus `match`
dispatch.

Why it matters: this conflicts with the ratified `[EXT]` direction: content
authors should compose data against engine primitives and registries, not extend
content by editing switches. The issue is carried-forward architecture debt, not
a new v0.3.0 regression.

Root cause: these systems predate the open-registry rule and were not migrated
as part of the save/input/MRD work.

Recommended fix: avoid adding new closed vocabulary surfaces during the release
cut. Track migrations by seam: objective predicates, AI profile handlers, item
effect handlers, stat vocabulary, and tile actions can move behind registry data
with load-time validation.

## Coverage Matrix

| Area | Delta size | Review handling |
|---|---:|---|
| Production GDScript | 38 files | July 5 covered MRD/threat overlay and spawn-seam work through `914dd025`; July 7 covered save/suspend/RNG/input through `7c6378e`; this pass rechecked the carried findings plus later prompt-selector changes. |
| Tests | 56 files | Full `./run_tests.sh` passed 66 suites. The RNG/input gaps above are coverage-shape gaps: existing tests initialize the missing lifecycle manually or test screen callbacks directly. |
| Scenes/resources/project settings | 5 files | Scene integrity check passed. MRD overlay asset/project changes were sampled against the July 5 data/assets review and the later `test_mrd_scene` coverage. |
| Export/build tooling | 1 file | `export_presets.cfg` excludes internal docs/tests/tools correctly, but v0.3.0 metadata has not been bumped from v0.2.9 yet. |
| AGENT docs/reviews/notes | 87 files | Docs checks passed. The v0.3.0 checklist is explicitly draft and calls out the same input/rebind rechecks before shipping. |
| Total release delta | 197 files | No full-audit rollup was produced in this pass; this is a targeted release-delta review using the two July code reviews as prior coverage. |

Production GDScript changed in the reviewed range:

`scripts/autoloads/DataManager.gd`, `scripts/autoloads/GameState.gd`,
`scripts/autoloads/InputModeManager.gd`, `scripts/autoloads/PairUpRegistry.gd`,
`scripts/autoloads/RngService.gd`, `scripts/autoloads/SaveManager.gd`,
`scripts/autoloads/SettingsManager.gd`, `scripts/core/CombatResolver.gd`,
`scripts/core/EnemyAI.gd`, `scripts/core/GameMap.gd`,
`scripts/core/GridManager.gd`, `scripts/core/MapCursor.gd`,
`scripts/core/MapCursorInput.gd`, `scripts/core/MapCursorTargeting.gd`,
`scripts/core/TurnManager.gd`, `scripts/resources/CampaignRules.gd`,
`scripts/resources/MapData.gd`, `scripts/resources/UnitData.gd`,
`scripts/save/SaveCodec.gd`, `scripts/save/SaveData.gd`,
`scripts/shared/InputDisplay.gd`, `scripts/skills/SkillHandler.gd`,
`scripts/tools/generate_placeholder_assets.gd`,
`scripts/tools/generate_tilesets.gd`, `scripts/ui/ActionMenu.gd`,
`scripts/ui/AttackPreview.gd`, `scripts/ui/GameOverScreen.gd`,
`scripts/ui/HUD.gd`, `scripts/ui/LevelUpScreen.gd`, `scripts/ui/MainMenu.gd`,
`scripts/ui/MapMenu.gd`, `scripts/ui/MenuScale.gd`,
`scripts/ui/ModalScreen.gd`, `scripts/ui/NewGameScreen.gd`,
`scripts/ui/SelectionCursor.gd`, `scripts/ui/SettingsScreen.gd`,
`scripts/ui/UnitDetailsScreen.gd`, `scripts/units/Unit.gd`.

## Verification

- `python3 AGENT/Docs/check_docs.py`: PASS.
- Prep-listed `scripts/tools/check_rng_usage.sh`: stale path in this checkout.
- `bash scripts/ci/check_rng_usage.sh`: PASS.
- Direct `scripts/ci/check_rng_usage.sh`: fails with permission denied because
  the file is not executable; hooks and CI call it through `bash`.
- `./run_tests.sh`: PASS, 66 suites green.
- `python3 scripts/ci/check_scene_integrity.py`: PASS, 17 scene-attached scripts
  validated.
- `python3 tools/godot-analyzer-mcp/tests/test_tools.py`: PASS, 12 tests.
- Tool probe: Godot `4.6.stable.official.89cea1439`; Python `3.10.12`.

## Prior-Review Coverage Notes

- July 5 reviewed the earlier MRD/threat-overlay work and found spawn-seam
  issues plus registry debt. The spawn-seam findings are fixed in the reviewed
  head: `GameMap` now resolves exactly one placement source and preserves
  authored `ai_profile` unless a placement override exists.
- The three production files that predated the July 7 code-review delta
  (`GridManager.gd`, `generate_placeholder_assets.gd`,
  `generate_tilesets.gd`) were sampled here. Their changes are MRD overlay
  registry/source-tile work from `e043411`, `3997e10`, `a506fc3`, and
  `2a2e48b`; full tests and scene integrity are green.
- July 7's code review findings still reproduce at `b7bcfd2`. The input prompt
  work after that review did not fix the Settings refresh path or rebind action
  omissions.

## Release Metadata And Build State

The v0.3.0 release has not been cut yet:

- `export_presets.cfg:3` and `export_presets.cfg:11` still name/output v0.2.9.
- `export_presets.cfg:46` still sets `application/product_version="0.2.9"`.
- `scenes/ui/MainMenu.tscn:66` still displays `v0.2.9`.
- `AGENT/Docs/guides/environment_setup.md:123` and the build commands at
  `AGENT/Docs/guides/environment_setup.md:155` still reference v0.2.9.
- `AGENT/Docs/playtests/playtest_checklist_v0.3.0.md:3` marks the checklist as
  draft and explicitly requires known blocker fixes plus final build
  manifest/hash before shipping.

This is not a code defect by itself because the snapshot is intentionally
pre-build. It is a release gate: the version bump, menu label, environment guide,
build manifest, executable size, and SHA-256 must be updated together when the
build is cut.

## Positive Observations

- Save/suspend is now split into sensible ownership: `SaveData` for envelope and
  validation, `SaveCodec` for typed conversion, `SaveManager` for disk I/O, and
  `GameState` for runtime capture/restore.
- Suspend resume coverage is broad: units, scheduler state, Pair Up, RNG, cursor
  tile, watch set, and danger mode all round-trip in tests.
- MRD overlays moved toward a registry shape in `GridManager`, which is aligned
  with the project's open-extension principle.
- Prompt formatting is centralized in `InputDisplay`, avoiding duplicated
  controller-label code across UI screens.
- The v0.3.0 checklist is correctly marked draft and already flags the input
  mode/rebind rechecks instead of silently presenting the build as shippable.

## Remaining Build Blockers

1. Fix fresh-map `RngService.start_map()` lifecycle before any v0.3.0 tester
   build.
2. Fix or explicitly defer the Settings Input Mode refresh bug; it directly
   affects the tester checklist's prompt-swapping pass.
3. Add the missing rebind actions or document explicit exemptions before the
   tester checklist asks players to verify rebinding.
4. Bump v0.3.0 release metadata and create the build manifest/hash in the same
   release step.
5. Run live controller and display validation where hardware/display access is
   required.

## Prioritized Action Plan

1. Patch `GameMap` to seed/reset RNG on fresh map startup, add scene regression
   coverage, then rerun the full suite.
2. Add `InputModeManager` public refresh and a Settings apply hook for
   `input_mode`; add end-to-end prompt/focus coverage.
3. Add the missing rebind labels plus a drift test for non-debug player-facing
   actions.
4. Cut v0.3.0 metadata/build-manifest updates only after the blocker fixes land.
5. Track registry migrations as follow-up architecture work rather than blocking
   the v0.3.0 tester build on the whole migration.
