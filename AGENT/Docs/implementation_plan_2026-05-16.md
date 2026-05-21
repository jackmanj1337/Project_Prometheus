# Implementation Plan — 2026-05-16

Derived from `AGENT/Code Reviews/code_review_2026-05-16.md`. Six phases, ordered so low-risk
correctness fixes land before the MapCursor refactor. Each phase ends green via `run_tests.sh`
(baseline: 10 suites, 222 tests). One commit per item unless noted.

---

## Decisions locked in this session

- **Settings split:** gameplay rules (`permadeath`, `leveling_method`) become per-save state on
  `GameState`, set once on a New Game screen. Audio/video/keybindings stay global in
  `settings.cfg`. UX preferences (`combat_animations`, `movement_speed`, `phase_banner`,
  `level_up_screen`) also stay global.
- **Infinite-use sentinel:** `-1` means infinite, applied consistently to `InventoryEntry`.
- **Mouse behavior in targeting mode:** made a **player setting** (`mouse_targeting`), not a fixed
  choice — see C3 / D1.
- **D-1 refactor:** started as a staged slice. The input-gating bug fix (D1) lands first; the
  `MapCursorTargeting` extraction (D2) is gated behind its own design pass.

---

## Phase A — Correctness fixes (independent, fast)

### A1. Counter-kill EXP bug
- `CombatResolver.gd:566` — drop the `not attacker_died` clause:
  `var def_exp := calculate_exp(defender, attacker, attacker_died) if def_hit else 0`.
  The `not defender_died` award guard at `:573` is correct and stays.
- Test (`test_combat.gd`): defender counter-kills attacker → assert `defender_exp` > 0 and equals
  kill-tier EXP.
- Commit: `Fix defender earning zero EXP on a counter-kill`

### A2. Snapshot inventory deep-copy
- `GameState._snapshot_unit_data` — build the inventory array by `entry.duplicate(true)` per
  element, not `inventory.duplicate(true)` (which shares Resource references).
- `GameState._restore_unit_data` — replace `inventory.assign(...)` with clear + append
  `entry.duplicate(true)` per element, so repeated Retries stay isolated.
- Test (`test_snapshot_coverage.gd`): snapshot → decrement `uses_remaining` / erase an entry →
  restore → assert original uses restored.
- Commit: `Deep-copy InventoryEntry resources in map snapshot`

### A3. `load()` null-checks
- `GameState.load_default_roster:129` and `GameMap._spawn_units:127` — null-check the `load()`
  result before `.duplicate()`; `push_error` + `continue` on failure.
- Commit: `Guard against null resource loads in unit spawning`

### A4. `assert` → `push_error` for data validation
- `DataManager._validate_cross_references` (both asserts), `GameMap._spawn_units:129`,
  `GameState.load_default_roster:131` — convert to `push_error` and `continue` past bad data so it
  survives release builds.
- Commit: `Replace stripped asserts with push_error in data validation`

---

## Phase B — `-1 = infinite` uses sentinel

### B1. Convention pass
- Add `InventoryEntry.has_uses() -> bool: return uses_remaining != 0` (`-1` and positive = usable;
  `0` = empty). `equip`-type entries are exempt — they are gated by `is_equip()`, not uses.
- Route usability checks through it: `Unit._find_equipped_weapon`, `ActionMenu.show_for`,
  `ItemMenu.show_for`, `MapCursor._use_item` fallback.
- Guard the two decrement sites — `Unit.use_weapon_durability` and `ItemHandler.apply_item` — to
  skip decrement/removal when `uses_remaining == -1`.
- `InventoryEntry.validate()` — accept `-1`; keep default `0`, document the sentinel.
- Tests: `-1` weapon never breaks; `-1` item never consumed.

### B2. Test-case data
- The MVP keeps finite durability on all gear by design, with one deliberate exception so the
  sentinel is exercised in normal play: set `uses_remaining = -1` on the **lance and vulnerary**
  `InventoryEntry` entries in the first player unit's inventory
  (`data/roster/default/unit_01_soldier.tres`).
- Commit (B1 + B2 together): `Adopt -1 as infinite-use sentinel for inventory entries`

---

## Phase C — Settings architecture + New Game screen

### C1. New Game setup screen
- New `scenes/ui/NewGameScreen.tscn` + `scripts/ui/NewGameScreen.gd`: permadeath (Off/On),
  leveling method (Random/Fixed), Start, Back.
- Implemented as an **overlay child of `MainMenu`**, matching the `SettingsScreen` pattern
  (`open()` / `hide()`, Back/cancel returns to MainMenu — no scene reload).
- `MainMenu` "New Game" button → `NewGameScreen.open()` instead of loading `GameMap` directly.
- Start → sets `GameState.permadeath_enabled` / `leveling_method`, calls `load_default_roster()`,
  `change_scene_to_file` to `GameMap`.
- After authoring `NewGameScreen.tscn`, validate every `@onready` path with the godot-analyzer MCP
  `validate_onready_paths` tool (the `SettingsScreen.tscn` work hit this exact problem).

### C2. Move gameplay rules off the global settings layer
- Remove `permadeath` and `leveling_method` from `SettingsManager` (vars, `load_settings`,
  `save`, `reset_section_to_defaults`).
- Remove the permadeath option + handler from `SettingsScreen`.
- `GameState._ready` — stop pulling those from `SettingsManager`; keep GameState's own defaults for
  the direct-boot dev path. `_ready()` likely becomes empty afterward — if so, remove it (this also
  eliminates one documented autoload-ordering workaround; don't leave a dead stub).
- Old `settings.cfg` files keep stale `permadeath`/`leveling_method` keys — harmless, no migration
  code needed.
- Note: the save-system milestone will serialize `GameState.permadeath_enabled` /
  `leveling_method` (and later `max_skills` / `max_inventory`) into the save file. No GameState
  changes needed now beyond keeping the fields.

### C3. PhaseBanner, mouse-targeting setting, combat_animations honesty
- **First verify** `PhaseBanner` (and `CombatHUD`) are actually instanced in a live scene via the
  godot-analyzer `find_scenes_with_script` tool — fixing dead nodes is wasted work.
- `PhaseBanner._on_phase_changed` — early-return when `SettingsManager.phase_banner == "skip"`.
- **New setting `mouse_targeting`** (global UX preference, `settings.cfg`):
  - `SettingsManager` — `var mouse_targeting: String = "snap"`; values `"snap"` | `"disabled"`.
    Add to `load_settings`, `save`, `reset_section_to_defaults("gameplay")`.
  - `SettingsScreen` — add `_opt_mouse_targeting` OptionButton, labels "Snap to Target" /
    "Keyboard Only".
  - Consumed in D1 (see below).
- Hide the `combat_animations` option in `SettingsScreen` until a combat-animation system exists
  (keep the field in `SettingsManager` for later).
- Commits: `Add New Game setup screen for gameplay rules`,
  `Move gameplay rules out of global settings`,
  `Add mouse-targeting setting; honor phase_banner; hide inert combat_animations option`

---

## Phase D — MapCursor input-gating fix + D-1 first slice

### D1. Fix input gating (behavior change, in place)
- Gate `_unhandled_input` / `_handle_mouse_motion`: suppress free cursor movement in `UNIT_MOVED`;
  in `TARGETING` / `STAFF_TARGETING` make arrow keys cycle `current_tile` among
  `_attack_tiles` / `_heal_tiles`.
- Mouse motion in targeting modes obeys the `mouse_targeting` setting:
  - `"snap"` — snap the cursor to the nearest valid target tile (Manhattan distance).
  - `"disabled"` — ignore mouse *motion* only. Left/right click still confirm/cancel the
    keyboard-selected target as normal (rebindable via keybindings).
- **No automated test** — input gating cannot be exercised headlessly (this is the core D-1
  motivation). Verified by manual testing until D2 makes targeting testable.
- Commit: `Gate MapCursor input by state; cycle targets in targeting modes`

### D2. Extract `MapCursorTargeting` (refactor + input re-point, no behavior change)
- **Design complete** — see `AGENT/Docs/d2_mapcursortargeting_design.md`. Ready to implement.
- Summary: `MapCursorTargeting extends RefCounted` with injected `grid` / `attack_preview` /
  `combat_resolver`. The cursor FSM stays on `MapCursor`; `TARGETING`/`PREVIEWING`/`STAFF_TARGETING`
  collapse into one `State.TARGETING` plus internal sub-state on the targeting object. `MapCursor`
  delegates via `begin()` / `handle_confirm()` / `handle_cancel()` and reacts to `completed` /
  `cancelled` signals.
- Moves `_begin_attack_targeting`, `_show_attack_preview`, `_dismiss_attack_preview`,
  `_execute_attack_confirmed`, `_do_resolve_attack`, `_begin_staff_targeting`,
  `_execute_staff_heal` and `_attack_tiles` / `_heal_tiles` / `_preview_target`.
- Also re-points the D1 input layer at `_targeting.target_tiles()` / `can_change_target()`.
- Two commits: `Extract MapCursorTargeting from MapCursor (D-1 slice 1)`, then
  `Add test_targeting.gd coverage`. `test_unit_selection.gd` is the regression net for the first.

---

## Phase E — Minor polish (batch)

- `HUD` — connect `unit_damaged` / `unit_healed`, refresh the panel if the changed unit is the one
  displayed.
- `MapCursor._cycle_to_next_unit` — use `_turn.can_unit_act(u)` so `MOVED` units aren't skipped.
- `TurnManager.gd:141` — fix the stale "auto-end-phase" comment.
- Commit: `HUD live HP refresh and minor cursor/comment fixes`

---

## Sequencing

A → B → C → E may proceed in any order. D1 goes after C3 (it consumes the `mouse_targeting`
setting). D2 goes after D1 (it re-points D1's input layer). All items are now ready to start.
