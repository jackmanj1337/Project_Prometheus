> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# Playtest 2 — Bug & Oversight Fix Plan (2026-05-19)

Code-review-style plan for the 17 items under "playtest bugs and oversight
features" in `playtest2_findings_2026-05-19.md`. The 8 "features to add to the
to-do list" were merged into `GDD_10_Roadmap.md` § UI / UX & Settings and are
**not** covered here.

> **Note on intent:** several items are *oversight features* (new behaviour the
> player expected), not defects in existing code. These are flagged
> **[FEATURE]**. Where I assumed designer intent it is called out explicitly.

---

## 1. Executive Summary

**Overall code quality: 8 / 10.** The codebase is well-sliced (the MapCursor
RefCounted helpers, the GridManager flood-fill reuse), heavily commented with
*why* not just *what*, and backed by 372 passing tests. The playtest items are
mostly UX polish and missing-feature gaps rather than logic defects.

Biggest concerns: one genuine **High** input bug (mouse fully dead in battle),
two modality bugs (level-up screen and New Game screen don't block the layer
beneath them), and a cluster of small settings/UX gaps. None risk data loss or
crashes.

---

## 2. Issues Found

### #5 — Mouse does not control cursor or confirm/cancel
**[SEVERITY: High]**
- **File & Line:** `scenes/ui/HUD.tscn:5` (HUD root `Control`); consumed before
  `scripts/core/MapCursor.gd:122` `_unhandled_input`.
- **Problem:** Mouse motion and clicks never reach the cursor, so the entire
  mouse control scheme is dead in battle. Keyboard still works.
- **Root Cause:** The HUD root is a full-rect `Control` (`anchors_preset = 15`)
  on `HUDMainLayer`. A `Control`'s default `mouse_filter` is `STOP`, so the HUD
  swallows every `InputEventMouse*` before it can fall through to the
  `MapCursor` node's `_unhandled_input`. Keyboard events are unaffected because
  `Control` mouse-filtering only gates mouse events — which is exactly the
  observed symptom.
- **Recommended Fix:** Set `mouse_filter = 2` (`MOUSE_FILTER_IGNORE`) on the HUD
  root and on its non-interactive children (`UnitInfoPanel`, `TerrainInfoPanel`,
  and their labels). The HUD has no clickable widgets, so ignoring mouse input
  entirely is correct.
  ```
  [node name="HUD" type="Control"]
  mouse_filter = 2          # was STOP (default) — let clicks reach MapCursor
  ```
- **Tradeoffs:** When the HUD later gains clickable widgets (e.g. the unit
  details page, #1), those specific controls must be set back to `STOP`/`PASS`.
  Document this on the HUD root.

### #4 — New Game screen needs a background
**[SEVERITY: Medium]**
- **File & Line:** `scenes/ui/NewGameScreen.tscn:5-13`.
- **Problem:** When the New Game screen opens over `MainMenu`, the menu's
  title, buttons and background bleed through around the `PanelContainer`, and
  the menu buttons behind it may still be interactable.
- **Root Cause:** `NewGameScreen` is a full-rect `Control` whose only visible
  child is a `PanelContainer` sized to its content. There is no opaque
  full-rect backing layer — unlike `SettingsScreen`, which was given a `Dimmer`
  in Session M (playtest 1, #1).
- **Recommended Fix:** Mirror the `SettingsScreen` fix: add a full-rect opaque
  `ColorRect` named `Dimmer` as the first child of `NewGameScreen` so it both
  hides the menu and blocks click-through. Confirm the inner `PanelContainer`
  uses an opaque `StyleBox`.
  ```
  [node name="Dimmer" type="ColorRect" parent="."]
  anchors_preset = 15
  color = Color(0, 0, 0, 0.85)
  ```
- **Tradeoffs:** None. Keep it consistent with `SettingsScreen` so both overlays
  behave identically.

### #12 — Cursor not frozen during the level-up screen
**[SEVERITY: Medium]**
- **File & Line:** `scripts/ui/LevelUpScreen.gd:70-79`; interacts with
  `scripts/core/MapCursor.gd:517` `_finish_action`.
- **Problem:** While the level-up screen is showing, the map cursor can still
  be moved with the arrow/WASD keys underneath it.
- **Root Cause:** `LevelUpScreen` pops up via `EventBus.unit_leveled_up`, which
  fires from `add_exp()` *inside* `apply_combat_result()`. By the time the
  screen is visible, `MapCursorTargeting` has emitted `completed` and
  `_finish_action()` has already set `_state = FREE`. `LevelUpScreen._unhandled_input`
  consumes only `confirm`/`cancel` — direction keys fall through to the now-FREE
  cursor.
- **Recommended Fix:** Have `LevelUpScreen` lock input while visible. Cleanest:
  in `_on_unit_leveled_up`/`_show_next`, call `get_tree().paused`-style gating
  is overkill — instead lock the cursor explicitly. Add a `cursor` reference (or
  an `EventBus` signal pair `level_up_shown` / `level_up_dismissed`) and have
  `MapCursor` `lock()`/`unlock()` around it. Alternatively, the minimal fix:
  make `LevelUpScreen._unhandled_input` call `set_input_as_handled()` for *all*
  events while visible, not just confirm/cancel.
- **Tradeoffs:** The signal approach is cleaner but touches `EventBus`,
  `MapCursor` and `LevelUpScreen`; the "consume all input" approach is one line
  but leaves the cursor technically FREE (harmless, since nothing reaches it).
  Recommend the signal approach for correctness and testability.

### #3 — Previous-unit keybinding display missing the Shift modifier
**[SEVERITY: Medium]**
- **File & Line:** `scripts/ui/SettingsScreen.gd:186-190`; related:
  `scripts/core/MapCursorInput.gd:27-41`.
- **Problem:** Two distinct bugs behind one finding:
  1. The keybinding list shows `prev_unit` as "Tab" — identical to `next_unit` —
     with no "Shift+" prefix, so the player can't tell them apart.
  2. **`prev_unit` is not wired up at all.** `MapCursorInput.decode_key`
     decodes `next_unit` but never `prev_unit`, so Shift+Tab does nothing —
     `_cycle_to_next_unit` only ever steps forward.
- **Root Cause:** (1) `_populate_keybindings` reads only `ev.keycode` and calls
  `OS.get_keycode_string(code)`, ignoring `ev.shift_pressed` / `ctrl_pressed` /
  `alt_pressed`. `prev_unit` in `project.godot:87` is `Shift+Tab`. (2) The
  `next_unit` slice (Session M) added forward cycling only; the reverse intent
  was never added.
- **Recommended Fix:**
  - Display: build the key string from modifiers, e.g.
    ```gdscript
    var parts: Array[String] = []
    if ev.shift_pressed: parts.append("Shift")
    if ev.ctrl_pressed:  parts.append("Ctrl")
    if ev.alt_pressed:   parts.append("Alt")
    parts.append(OS.get_keycode_string(code))
    keys.append("+".join(parts))
    ```
  - Wiring: add a `PREV_UNIT` intent to `MapCursorInput.Intent`, decode
    `prev_unit` in `decode_key`, handle it in `MapCursor._handle_key_press`, and
    give `_cycle_to_next_unit` a direction argument (+1 / -1).
- **Tradeoffs:** None for the display fix. The wiring fix should get a unit test
  in `test_map_cursor_input.gd` mirroring the existing `next_unit` coverage.

### #7 — Camera should track the selected unit during the AI phase
**[SEVERITY: Medium]** *[FEATURE]*
- **File & Line:** `scripts/core/EnemyAI.gd:20-63`; camera owned by
  `scripts/core/GameMap.gd:44` and panned only by
  `scripts/core/MapCursor.gd:662` `_scroll_camera_if_needed`.
- **Problem:** During the enemy phase the cursor is `LOCKED`, so nothing pans
  the camera; enemy units can move and fight entirely off-screen.
- **Root Cause:** Camera scrolling is coupled exclusively to cursor movement.
  `EnemyAI` has no camera reference and never requests a pan.
- **Recommended Fix:** Give the camera a small public `pan_to_tile(tile)` (or
  emit an `EventBus.ai_unit_acting(unit)` signal that `GameMap` listens for).
  In `EnemyAI._act`, before `move_along_path` and before resolving combat, pan
  the camera to the acting enemy and `await` a short settle delay so the player
  can follow the action. Re-enable `position_smoothing_enabled` during the AI
  phase for a smooth follow.
- **Tradeoffs:** Adds pacing delays to the enemy phase — keep them short
  (~0.2-0.3s) and ideally honour the `movement_speed` setting so "instant"
  players aren't slowed.

### #8 — Option to swap weapons after selecting Attack
**[SEVERITY: Medium]** *[FEATURE]*
- **File & Line:** `scripts/ui/ActionMenu.gd`; `scripts/core/MapCursorTargeting.gd`.
- **Problem:** Once "Attack" is chosen, the unit is locked to its currently
  equipped weapon; the player can't switch to a different weapon (e.g. for
  weapon-triangle advantage or range) without cancelling out.
- **Root Cause:** No weapon-equip step exists. `Unit.get_equipped_weapon()`
  returns the first usable weapon entry; targeting reads it once in
  `MapCursorTargeting.begin`.
- **Recommended Fix (decided with designer):** Weapon swap is **free** as long
  as the attack has not been confirmed — standard FE behaviour. Add an "Equip"
  action to `ActionMenu` (or a weapon sub-list shown when entering Attack
  targeting) listing the unit's usable weapons. On change, re-run
  `_targeting.begin` so the valid-target set and overlay refresh. Requires a
  `Unit.set_equipped_weapon(entry)` method.
- **Tradeoffs:** Touches the targeting flow's assumption that the weapon is
  fixed for a session — `MapCursorTargeting` must support a mid-session weapon
  change. No action cost, so the swap must be fully reversible until the attack
  is confirmed.

### #9 — Cancelling attack should return the cursor to the attacking unit
**[SEVERITY: Low]**
- **File & Line:** `scripts/core/MapCursor.gd:455-457` `_on_targeting_cancelled`.
- **Problem:** Backing out of target selection leaves the cursor sitting on the
  last highlighted enemy tile instead of returning to the unit taking the
  action.
- **Root Cause:** `_on_targeting_cancelled` sets `_state = UNIT_MOVED` and
  reopens the ActionMenu but never moves `current_tile`.
- **Recommended Fix:** Snap the cursor back to the acting unit before reopening
  the menu:
  ```gdscript
  func _on_targeting_cancelled() -> void:
      _state = State.UNIT_MOVED
      if _selection.selected_unit != null:
          _set_tile(_selection.selected_unit.tile_position)
      _show_action_menu()
  ```
- **Tradeoffs:** None. Matches the cursor placement done when entering
  targeting (`_enter_targeting` snaps to `tiles[0]`).

### #15 / #16 — End-turn confirmation: prevent accidental early turn-end
**[SEVERITY: Low]**
- **File & Line:** `scripts/core/MapCursor.gd:572-593` `_on_end_turn_requested`.
- **Problem:** The "some units have not acted — end turn anyway?" prompt is too
  easy to confirm by accident. Confirm is the default-focused button, so a
  player mashing or holding the confirm key (e.g. to clear menus) can end the
  turn before acting with every unit. Also (#16) the game's `cancel` key is not
  a guaranteed, tested way to dismiss the prompt.
- **Root Cause:** The prompt is a stock `ConfirmationDialog` with its OK button
  focused by default — nothing makes the *safe* choice (Cancel) the default.
  `cancel` is mirrored onto `ui_cancel` (`SettingsManager._mirror_game_keys_to_ui`)
  so Escape/X *should* trigger `canceled`, but the behaviour is not explicit.
- **Recommended Fix (decided with designer):** Make the **Cancel button the
  default-focused button** so an accidental or held confirm press dismisses the
  prompt instead of ending the turn — call `dlg.get_cancel_button().grab_focus()`
  after `popup_centered()`. Also explicitly verify the game `cancel` action
  dismisses it. The designer accepted "Cancel is the default button" as
  sufficient on its own; a visual swap of the button *positions* is optional
  polish.
- **Tradeoffs:** Focusing the Cancel button is effectively a one-liner and fully
  resolves the accidental end-turn — low effort, high value. If the buttons
  should *also* be visually reordered, note that `ConfirmationDialog` button
  order is not reliably controllable across platforms; that would require
  swapping to a small custom in-scene panel (consistent with `MapMenu`). Treat
  the position swap as deferred polish unless the designer asks for it. Add a
  test asserting the Cancel button holds focus on open.

### #1 — Unit details page
**[SEVERITY: Medium]** *[FEATURE]*
- **File & Line:** New screen; current info shown only by `scripts/ui/HUD.gd:93`
  `_show_unit` (name, class, HP, weapon, mastery).
- **Problem:** No way to inspect a unit's full stats (Str/Mag/Def/Res/Skl/Spd/
  Luck, level, EXP, inventory, skills, growth).
- **Recommended Fix (decided with designer):** Add a `UnitDetailsScreen` (its
  own `CanvasLayer`, opaque Dimmer like `SettingsScreen`), opened by a **new
  `inspect_unit` input action** while the cursor is over a unit. Populate from
  `unit.data`. Lock the `MapCursor` while open (same pattern as Settings).
  Scope is **display-only** — editing/equipping is deferred to the inventory
  milestone.
- **Tradeoffs:** Needs a new input action and a scene. Add the `inspect_unit`
  binding to the `SettingsScreen` keybinding list (`_KEYBIND_LABELS`) so it
  shows up alongside the other controls.

### #6 — Healing range highlight colour (try orange)
**[SEVERITY: Low]**
- **File & Line:** `scripts/core/GridManager.gd:383,402-403` (`OVERLAY_GREEN`,
  `show_heal_overlay`); the overlay `TileMapLayer` tileset.
- **Problem:** The staff/heal overlay is green; the designer wants to trial
  orange for better contrast against terrain and the red attack overlay.
- **Root Cause:** Intentional original choice — purely a visual tweak.
- **Recommended Fix:** Add an orange tile to the overlay tileset (or recolour
  source ID 2) and keep `OVERLAY_GREEN` pointing at it, or rename the constant
  to `OVERLAY_HEAL` to decouple the name from the colour. The latter avoids a
  misleading constant name after the recolour.
- **Tradeoffs:** None. Trivial; confirm the new colour reads clearly against the
  dark-red danger overlay (source 3).

### #13 — Level-up message should show the real confirm keybinding
**[SEVERITY: Low]**
- **File & Line:** `scripts/ui/LevelUpScreen.gd:58`.
- **Problem:** The prompt hardcodes `"Press A to continue"`. The confirm action
  is bound to Z (and Enter/Space) — "A" is wrong.
- **Root Cause:** Hardcoded string, written before key display was a concern.
- **Recommended Fix:** Build the label from the live `InputMap`:
  ```gdscript
  var key := "confirm"
  for ev in InputMap.action_get_events("confirm"):
      if ev is InputEventKey:
          key = OS.get_keycode_string(ev.keycode if ev.keycode != 0 else ev.physical_keycode)
          break
  _label_prompt.text = "Press %s to continue" % key
  ```
  Reuse the same helper proposed for #3 so modifier display stays consistent.
- **Tradeoffs:** None.

### #2 — Make auto-end turn optional
**[SEVERITY: Low]** *[FEATURE]*
- **File & Line:** `scripts/core/TurnManager.gd:139-142` (`set_unit_state`),
  `:149-154` (`_auto_end_player_phase`), `:251-253` (`_on_unit_died`).
- **Problem:** The phase auto-ends the moment the last unit finishes (added in
  Session M, finding #5). Some players want to end the turn manually even when
  every unit has acted.
- **Root Cause:** Auto-end is unconditional.
- **Recommended Fix:** Add `auto_end_turn: bool = true` to `SettingsManager`
  (persisted; new `SettingsScreen` row) and gate the two `call_deferred(
  "_auto_end_player_phase")` sites and `_auto_end_player_phase` itself on it.
- **Tradeoffs:** None. When off, the player must open the map menu → End Turn;
  ensure that path still works with all units DONE (it does — `end_player_phase`
  is called directly when `are_all_player_units_done()`).

### #17 — Make the camera movement buffer adjustable
**[SEVERITY: Low]** *[FEATURE]*
- **File & Line:** `scripts/core/MapCursor.gd:13` (`CAMERA_EDGE_BUFFER`),
  `scripts/shared/GameConstants.gd:34` (`CURSOR_CAMERA_EDGE_BUFFER`).
- **Problem:** The edge-pan buffer is a compile-time constant; the player can't
  tune how early the camera scrolls.
- **Root Cause:** Constant by design.
- **Recommended Fix:** Add a `camera_edge_buffer` setting to `SettingsManager`
  (default 2), and have `_scroll_camera_if_needed` read it at call time instead
  of the `const`. See also the broader "Camera settings" backlog item in
  `GDD_10_Roadmap.md` § UI / UX & Settings.
- **Tradeoffs:** `MapCursor.CAMERA_EDGE_BUFFER` becomes a runtime lookup; keep
  the `GameConstants` value as the default. Clamp to a sane range (0-5).

### #10 — Temporarily make any attack grant a level-up *(testing aid)*
**[SEVERITY: Low]** *[FEATURE / TEST]*
- **File & Line:** `scripts/core/CombatResolver.gd:306-309` `calculate_exp`.
- **Problem:** Testing the level-up flow currently requires grinding EXP.
- **Recommended Fix:** Add a debug flag (e.g. `GameState.debug_force_levelup`)
  that, when set, makes `calculate_exp` return ≥100 for a hit. Gate it behind
  `OS.is_debug_build()` so it can't ship.
- **Tradeoffs:** Debug-only code in a hot path — keep it a single early
  `if`. **Decided: debug-gate it and track removal** — the deletion is logged
  as a RELEASE BLOCKER in `GDD_10_Roadmap.md` § Pre-Release Cleanup.

### #11 — Increase MVP units' stat gains for testing
**[SEVERITY: Low]** *[FEATURE / TEST]*
- **File & Line:** `data/roster/*` `UnitData` / their `ClassData.growth_rates`.
- **Problem:** Default growth rates make level-up stat changes hard to observe
  while testing.
- **Recommended Fix:** Do **not** edit the shipping `ClassData.growth_rates` —
  that changes game balance. Instead temporarily bump growths on the MVP roster
  units only, or add a debug multiplier applied in `Unit._level_up_random` /
  `_level_up_fixed` gated on `OS.is_debug_build()`.
- **Tradeoffs:** Editing real data risks the temporary values being committed
  and shipped. **Decided: use the debug-gated multiplier (do not edit shipping
  `ClassData`) and track removal** — logged as a RELEASE BLOCKER in
  `GDD_10_Roadmap.md` § Pre-Release Cleanup.

### #14 — Vulnerary should heal 10 HP
**[SEVERITY: Low]**
- **File & Line:** `data/items/vulnerary.tres:9,14`.
- **Problem:** The Vulnerary heals 20 HP; the designer wants 10.
- **Root Cause:** Data value.
- **Recommended Fix:** Change `effect_params = {"amount": 20}` to `{"amount": 10}`
  **and** update the `description` string ("Restores 20 HP" → "Restores 10 HP")
  so UI text and effect stay in sync. Check `GDD_04_Weapons_Items.md` for a
  Vulnerary entry and update it too.
- **Tradeoffs:** Pure balance change — confirm 10 is the intended value (FE
  convention is often 10, so this is plausible). Verify no test asserts 20.

---

## 3. Positive Observations

1. **Defensive coding throughout** — `is_instance_valid` guards before touching
   units that may have died mid-action (`CombatResolver.apply_combat_result`,
   `EnemyAI._act`), and `get_node_or_null` for every autoload so headless
   `--script` tests run without the autoload tree.
2. **The MapCursor slice architecture** — extracting `MapCursorInput`,
   `MapCursorSelection` and `MapCursorTargeting` as plain `RefCounted` objects
   keeps the FSM on `MapCursor` while making each concern unit-testable without
   a `SceneTree`. The state-machine transition diagram in the comments is
   genuinely useful.
3. **Comments explain *why*** — e.g. the centre-vs-top-left camera-math note,
   the "capture the weapon before perform_staff_heal" note, the `_map_over`
   double-emit guard. These document past bugs so they don't regress.
4. **Shared code paths kept provably symmetric** — `TurnManager._begin_phase`
   deliberately runs the identical routine for both phases so they can't drift.

---

## 4. Architectural Observations

- **Camera ownership is implicit.** The `Camera2D` is configured by `GameMap`
  but only ever moved by `MapCursor._scroll_camera_if_needed`. Items #7 and #17
  both push on this. Consider a small dedicated `CameraController` (or at least
  a documented public pan API) so the AI phase, cursor, and future cutscenes
  can all drive the camera without each reaching into `Camera2D` directly.
- **Modality is handled ad-hoc per screen.** `SettingsScreen` has a Dimmer;
  `NewGameScreen` doesn't (#4); `LevelUpScreen` doesn't lock the cursor (#12).
  There is no shared "modal overlay" pattern — each screen reinvents open/hide
  and input-blocking. A small `ModalScreen` base class (Dimmer + open/close +
  cursor lock signal) would prevent this class of bug recurring.
- **Keybinding display logic is duplicated and incomplete.** #3 and #13 both
  need "render an InputEvent as a human string, with modifiers." Extract one
  helper (e.g. `InputDisplay.event_to_string`) and use it everywhere.
- **Settings surface is growing.** #2, #6(no), #17 and four roadmap items all
  add `SettingsManager` fields + `SettingsScreen` rows. The current pattern
  (one hand-wired `_on_*_changed` per field) will get unwieldy — consider a
  data-driven settings schema before adding the next batch.

---

## 5. Prioritized Action Plan

Ordered by impact ÷ effort.

1. **#5 — HUD `mouse_filter`** — one scene-property change, restores an entire
   input method. Highest impact, lowest effort.
2. **#14 — Vulnerary 10 HP** & **#13 — level-up prompt key** — trivial data /
   string fixes; do them while in the area.
3. **#9 — cursor returns to unit on attack cancel** — one small `MapCursor`
   change, removes a daily UX papercut.
4. **#4 — New Game screen Dimmer** — copy the `SettingsScreen` pattern;
   straightforward modality fix.
5. **#3 — prev-unit display + wiring** — small, but ships a feature (Shift+Tab)
   that is currently dead. Add the shared key-display helper here.
6. **#12 — freeze cursor on level-up** — do with the modal-overlay cleanup so it
   isn't another one-off.
7. **#2, #17 — auto-end-turn toggle, camera buffer setting** — batch together
   as one "settings additions" pass.
8. **#6 — heal overlay colour** — quick tileset tweak; bundle with art passes.
9. **#15 / #16 — end-turn confirm safety** — focus the Cancel button by default
   (one-liner) so a mashed/held confirm can't end the turn early; verify the
   cancel key dismisses it. Low effort — can be batched with the quick wins
   above (steps 2-3).
10. **#7 — camera tracks AI** — medium; best done after the camera-controller
    refactor noted in §4.
11. **#8 — weapon swap before attack** — medium feature; needs a designer
    decision on action cost.
12. **#1 — unit details page** — largest item; new screen + input action.
13. **#10, #11 — testing aids** — debug-gated (`OS.is_debug_build()`), lowest
    priority. Removal is tracked as a RELEASE BLOCKER in `GDD_10_Roadmap.md`
    § Pre-Release Cleanup.

---

## Constraints Noted

- This is a *plan* — no code was changed. The roadmap merge (separate request)
  is the only file edited.
- Items #1, #2, #7, #8, #17 are oversight *features*, not defects; #10/#11 are
  explicitly temporary test aids. Designer sign-off recommended on #8 (action
  cost), #14 (final heal value) and #6 (final colour).
- Per AGENTS.md, each fix above should land as its own commit with the test
  suite green, and reasonable items should gain unit tests (notably #3 wiring,
  #2 toggle, #9 cursor placement).
