# Code Review — 2026-05-19 (Session N: Playtest 2 fixes)

**Scope:** the 37 files / +1113 −48 lines changed since `4db4816` — the 17
playtest-2 fixes (Session N). Emphasis on the recently-affected code; broader
observations are flagged as such.

---

## 1. Executive Summary

**Overall code quality: 8 / 10.** The session's changes are consistent with the
existing codebase: every fix shipped with a unit test (372 → 400 tests, all
green), comments explain *why*, and signal-based decoupling was preferred over
new hard references. The main concerns are an unclamped settings value read from
disk, and accepted-but-accumulating UI debt (modality and settings wiring are
still hand-rolled per screen).

---

## 2. Issues Found

### Unclamped `camera_edge_buffer` loaded from disk
**[SEVERITY: Medium]**
- **File & Line:** `scripts/autoloads/SettingsManager.gd:60`; consumed in
  `scripts/core/MapCursor.gd:778` `_camera_edge_buffer()`.
- **Problem:** The SettingsScreen slider clamps the camera-pan buffer to 0–5, but
  `load_settings()` reads `camera_edge_buffer` straight from `settings.cfg` with
  no clamp. A hand-edited or corrupt cfg can set it to any int. A buffer larger
  than half the visible tile count makes both edge tests in
  `_scroll_camera_if_needed()` true at once, so the camera can jump or oscillate.
- **Root Cause:** The clamp lives only in the UI control (`HSlider.min/max`), not
  at the model boundary where untrusted data enters.
- **Recommended Fix:** Clamp on load (and ideally in the accessor as a
  belt-and-braces guard):
  ```gdscript
  # SettingsManager.load_settings()
  camera_edge_buffer = clampi(
      cfg.get_value("gameplay", "camera_edge_buffer", camera_edge_buffer), 0, 5)
  ```
- **Tradeoffs:** Hard-codes the 0–5 range in a second place; acceptable, or
  promote the range to a `const`. The fix plan for #17 explicitly called for this
  clamp — it was missed in implementation.

### HUD panel children not explicitly set mouse-transparent
**[SEVERITY: Low]**
- **File & Line:** `scenes/ui/HUD.tscn` — `UnitInfoPanel`/`TerrainInfoPanel`
  `VBox` + `Label` children.
- **Problem:** #5 set `mouse_filter = IGNORE` on the HUD root, the two panels and
  their VBoxes. The `Label` children rely on `Label`'s default being `IGNORE`.
  If that assumption is ever wrong, a click landing exactly on a panel label
  would still be eaten.
- **Root Cause:** The fix targeted the containers; label transparency is implicit.
- **Recommended Fix:** Confirm in-engine that clicks through the two info panels
  reach `MapCursor`. `Label` does default to `MOUSE_FILTER_IGNORE` in Godot 4, so
  this is almost certainly fine — but it is worth one explicit check, and the
  dynamically-created `_mastery_label` (`HUD.gd`) should be confirmed too.
- **Tradeoffs:** None; verification only.

### AI camera pans to the enemy's pre-move tile only
**[SEVERITY: Low]**
- **File & Line:** `scripts/core/EnemyAI.gd:17` (`_focus_camera` call in
  `run_enemy_phase`).
- **Problem:** The camera is panned onto each enemy *before* it acts. A
  high-movement enemy can then move several tiles and fight partly off-screen —
  the very symptom #7 set out to fix, just reduced rather than eliminated.
- **Root Cause:** A single focus call site was chosen for simplicity; there is no
  post-move re-pan.
- **Recommended Fix:** Emit `ai_unit_acting` again after `move_along_path` in
  `_act` / `_act_healer` (no extra delay needed — the camera is already smoothed),
  so the view re-centres on the destination before combat resolves.
- **Tradeoffs:** Two emit sites instead of one. Minor; acceptable to defer.

### AI-phase pacing delay ignores the "fast" movement setting
**[SEVERITY: Low]**
- **File & Line:** `scripts/core/EnemyAI.gd:30-32` `_focus_camera`.
- **Problem:** The 0.25 s per-enemy pause is skipped only when `movement_speed`
  is `"instant"`. A player on `"fast"` still waits the full 0.25 s per enemy.
- **Root Cause:** A binary instant/not-instant check instead of scaling with the
  speed setting (the #7 fix-plan entry suggested honouring `movement_speed`).
- **Recommended Fix:** Map the delay to the setting, e.g. reuse the spirit of
  `SettingsManager.get_movement_speed_seconds()` — `0.0` instant, `~0.12` fast,
  `~0.25` normal.
- **Tradeoffs:** None of substance; one small helper.

### Tests mutate shared autoload singletons
**[SEVERITY: Low]**
- **File & Line:** `test_turn_manager.gd` (`SettingsManager.auto_end_turn`),
  `test_combat.gd` (`GameState.debug_force_levelup`), `test_unit_stats.gd`
  (`GameState.debug_growth_boost`).
- **Problem:** Each test flips a live autoload field and restores it. Correct
  today only because `run_tests.sh` runs every suite in its own `godot` process,
  so leakage cannot cross suites. Within a suite, a failure between the set and
  the restore leaves the singleton dirty for later assertions in that suite.
- **Root Cause:** No fixture/teardown harness — tests are linear `_init()` scripts.
- **Recommended Fix:** Restore in the assertion's *else* branch too, or capture
  the original value and restore unconditionally before the next block. Low
  priority given the process isolation.
- **Tradeoffs:** Slightly more verbose tests.

---

## 3. Positive Observations

1. **One mechanism reused for two fixes.** `MapCursor._input_suppressed` was
   added for #12 (level-up freeze) and reused unchanged for #1 (unit details).
   It is deliberately independent of the FSM `_state`, which is the correct call
   — `_finish_action()` resets `_state` to `FREE` mid-combat, so a state-based
   lock would have been wrong for #12.
2. **Shared helper extracted, not copy-pasted.** `InputDisplay` (key→string with
   modifiers) was created once and used by both #13 (level-up prompt) and #3
   (keybind list), and it deliberately omits `class_name` so headless `--script`
   tests need no class-cache entry — the same discipline applied to `WeaponMenu`
   and `UnitDetailsScreen`.
3. **New menus mirror an existing pattern.** `WeaponMenu` follows `ItemMenu`'s
   structure (dynamic buttons, `_input` focus handling, `mouse_filter = 2`) so
   there is nothing novel to learn.
4. **Every fix is test-backed.** 28 new assertions across 2 new suites and ~10
   extended ones; the pre-commit hook kept the suite green on all 17 commits.
5. **Signal-based decoupling.** `level_up_started/finished` and `ai_unit_acting`
   keep `EnemyAI`/`LevelUpScreen` from reaching into `MapCursor`/`GameMap`
   directly — consistent with the existing EventBus design.

---

## 4. Architectural Observations

- **Modality is still reinvented per screen.** This session added
  `UnitDetailsScreen` and gave `NewGameScreen` a Dimmer — both hand-roll the
  Dimmer + open/hide + input-blocking pattern that `SettingsScreen` also has.
  Four screens now duplicate it. The shared `ModalScreen` base proposed in the
  playtest-2 fix plan (§4) was not built; the debt is now larger, not smaller.
- **Two parallel input-gating mechanisms in `MapCursor`.** Input is now gated by
  *both* the FSM `LOCKED` state *and* the `_input_suppressed` flag, both checked
  at the top of `_unhandled_input`. This is intentional and correct (suppression
  preserves a live selection; `lock()` does not), but it is a subtlety a future
  reader must absorb. The distinction is commented at the field — keep it that
  way, and prefer `_input_suppressed` for any future "overlay is up" case.
- **Three writers of `Camera2D.position`.** `MapCursor._scroll_camera_if_needed`,
  `GameMap._on_ai_unit_acting`, and `GameMap`'s initial placement now all move
  the camera. This reinforces the fix plan's §4 suggestion of a single
  `CameraController` — defer until a third feature needs the camera, but the
  bar has now been reached.
- **`_input_suppressed` correctness depends on paired signals.** It is only
  cleared by `level_up_finished` / `unit_details.closed`. Today every dismissal
  path routes through `LevelUpScreen._advance()` / `UnitDetailsScreen._close()`,
  so the pairing holds. Any future early-exit from those screens that bypasses
  those methods would strand the cursor frozen — worth a comment on each screen.
- **Settings wiring scales linearly by hand.** #2/#17 added two more
  `@onready` + connect + `_on_*_changed` triplets to `SettingsScreen`. The fix
  plan's §4 note about a data-driven settings schema still stands and the case
  is now stronger.

---

## 5. Prioritized Action Plan

Ordered by impact ÷ effort.

1. **Clamp `camera_edge_buffer` on load** — one line, closes a real robustness
   gap that the #17 fix plan already specified.
2. **Verify HUD click-through in-engine** — confirm #5 fully landed (clicks pass
   through the two info panels); zero-code if `Label` defaults hold.
3. **Re-pan the AI camera after movement** — small `EnemyAI` change, materially
   improves the #7 experience.
4. **Scale the AI pacing delay with `movement_speed`** — small, polish.
5. **Tighten the singleton-mutating tests** — restore-in-`else`; low urgency.
6. **(Backlog) Extract a `ModalScreen` base and a `CameraController`** — pay down
   the two debts above before the next UI/camera feature, not reactively.

## Constraints

- Documentation only — no code was changed by this review.
- This reviews the reviewer's own Session N work; findings were sought
  adversarially rather than assumed absent. No Critical or High issues found —
  the #5 fix (the one High in the playtest-2 plan) is verified by
  `test_game_map_scene` and behaves correctly.
