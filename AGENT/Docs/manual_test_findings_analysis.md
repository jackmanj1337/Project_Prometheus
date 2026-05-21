# Manual Test Findings — Causes & Suggested Fixes

> **STATUS (2026-05-18, Session M): all 13 findings fixed and merged to `main`.**
> See `AGENT/Session Notes/2026-05-18c.md`. This document is kept as the
> diagnosis record; the "Suggested fix" sections describe what was implemented.
> Follow-up: the fixes are unit-tested — UI feel still needs a manual playtest.

Analysis of `playtest1_findings_2026-05-18.md` (playtest 1, 2026-05-18). Each entry lists the
likely cause with `file:line` references, a suggested fix, and a confidence rating.
Confidence reflects how sure I am of the *cause* without a live repro.

User decisions captured during analysis:
- **#5** — phase auto-end should be **fully automatic** (normal banner, no prompt).
- **#6** — staleness occurs **specifically after a unit finishes acting** (single fix covers it).
- **#8** — keybindings should be a **read-only display** (rebinding deferred to Phase 2).
- **#3** — Settings in-game via **both** a map-menu button and the `open_settings` hotkey.
- **#2** — keep **margin-follow** camera behaviour; fix the math, no smoothing.
- **#10 / #4** — **CONFIRMED ROOT CAUSE.** Playtester tried all open methods and the
  cursor kept moving each time → `MapCursor`'s exported menu node references resolve
  to `null` at runtime. This single bug causes **both** #4 and #10 (and the missing
  Item submenu). See #4 for the fix.
- **#12/#13** — MVP: **disable the threat toggle while a unit is selected**. (Roadmap:
  a general threat range *plus* per-enemy threat highlighting — see #13.)

---

## Audio bus verification (requested separately) — ✅ PASS

`default_bus_layout.tres` now defines **Music** (bus 1) and **SFX** (bus 2), both
routing `send = "Master"`. Master is bus 0 (implicit). `SettingsManager._apply_audio()`
(`scripts/autoloads/SettingsManager.gd:102-108`) looks the buses up by name via
`AudioServer.get_bus_index()`, so the volume sliders will now drive real buses
instead of silently skipping (the old "buses don't exist yet" path is dead).
No `[audio]` section is needed in `project.godot` — Godot auto-loads the layout
because it uses the default filename.

---

## #1 — Settings screen not opaque; needs better labels

**Confidence: Medium.** `SettingsScreen.tscn` root is a full-rect `Control` with
**no background** — only the centered `Panel` (PanelContainer) draws, so the scene
behind shows through everywhere around it. The five `OptionButton`s
(`OptMovementSpeed`, `OptPhaseBanner`, `OptLevelUpScreen`, `OptMouseTargeting`,
and the hidden `OptCombatAnim`) have **no adjacent title labels** — they show only
the selected value, unlike the volume rows which each have a `Label*Title`.

**Fix:**
- Add a full-rect `ColorRect` (e.g. `Color(0,0,0,0.6)`) as the first child of
  `SettingsScreen` to act as a modal dimmer, and/or give `Panel` an opaque
  `StyleBoxFlat` theme override.
- Wrap each `OptionButton` in an `HBoxContainer` with a title `Label`
  ("Movement Speed", "Phase Banner", "Level-Up Screen", "Mouse Targeting") —
  mirror the existing `HBoxMaster/LabelMasterTitle` pattern.

---

## #2 — Camera lags the cursor; cursor leaves the visible area

**Confidence: High.** `MapCursor._scroll_camera_if_needed()`
(`scripts/core/MapCursor.gd:568-592`) has a **camera-anchor mismatch**. `Camera2D`
defaults to `anchor_mode = DRAG_CENTER`: its `position` is the *center* of the view.
But the scroll math treats `cam_tile` (derived from `world_to_tile(_camera.position)`)
as the **top-left** tile of the view — e.g. `current_tile.x < cam_tile.x + BUFFER`
and `current_tile.x > cam_tile.x + tiles_w - BUFFER - 1`. Top-left vs. center is off
by half a screen, so the "keep the cursor inside the buffer" check is computed
against the wrong rectangle and the cursor can walk off-screen.

**Fix:** Make the math consistent with a centered camera. Treat `_camera.position`
as the view center and keep the cursor within
`[center − tiles_w/2 + BUFFER, center + tiles_w/2 − BUFFER]` (same for Y), then
clamp to the map limits already set in `GameMap._ready()`. Alternatively set the
Camera2D `anchor_mode` to top-left and keep the current math. Camera response is
already instant (`position_smoothing_enabled = false`); the fix is correctness,
not speed.

**User decision:** keep the margin-follow behaviour (camera moves only when the
cursor nears an edge) — just fix the centered-vs-top-left math. No smoothing.

---

## #3 — Cannot open Settings from inside a battle

**Confidence: High (confirmed).** `SettingsScreen.tscn` is only instanced inside
`MainMenu.tscn`. `GameMap.tscn` has no `SettingsScreen` node, and `MapMenu` offers
only **End Turn** and **Close** (`scripts/ui/MapMenu.gd`). The `open_settings`
action is handled *only* by `MainMenu._unhandled_input()`
(`scripts/ui/MainMenu.gd:41-45`). In a battle there is no code path to settings.

**Fix (user chose: both):**
- Instance `SettingsScreen.tscn` into `GameMap.tscn` under a high `CanvasLayer`
  (above the HUD).
- Add a **Settings** button to `MapMenu` that emits a new `settings_requested`
  signal; `MapCursor`/`GameMap` opens the screen.
- Also handle the `open_settings` action in-game (e.g. in `GameMap` or `MapCursor`).
- The cursor must `lock()` while Settings is open and `unlock()` on close.

---

## #4 — Action menu does not appear

**Confidence: High — confirmed by the #10 diagnosis.** The cause is **not** scene
sizing — it is the same bug as #10: `MapCursor`'s exported menu node references
resolve to `null` at runtime. `_show_action_menu()` (`MapCursor.gd:354-356`)
begins with `if action_menu == null: _commit_wait(); return` — so when
`action_menu` is null, a unit that finishes moving silently commits **Wait** and
no menu ever appears. The same null affects `item_menu`: `_use_item()`
(`MapCursor.gd:419`) falls back to auto-using the first item, so the **Item
submenu never shows either**.

**Why the exports are null:** `MapCursor` declares `@export var action_menu: Node`
(plus `item_menu`, `map_menu`, `attack_preview`), wired in `GameMap.tscn` as
`NodePath("../HUDLayer/…")`. Exported-Node references are resolved at scene-*build*
time; here they come back null — most likely a forward-reference quirk (the
`HUDLayer` menus are declared *after* `MapCursor` in the .tscn) or an
instanced-sub-scene resolution issue. By the time `_ready()` runs the whole tree
exists, so those paths *are* resolvable then — just not when the export
mechanism tried.

**Fix (shared with #10 — do this first, it blocks core gameplay):** stop relying
on exported-Node resolution. In `MapCursor._ready()`, *before* the
signal-connection block, fall back to `get_node_or_null()` for any menu reference
that is null — or have `GameMap` inject them. `_ready()` runs after the full tree
is built, so `get_node()` is reliable there. One fix restores the action menu,
the map menu (#10), the Item submenu, and the attack preview.

**Secondary (verify only after the export fix):** `ActionMenu.tscn`'s root
`Control` has no anchors and only `custom_minimum_size = (128, 0)` (zero height);
its child `Panel` is anchored to fill that. Once the menu actually shows, confirm
it renders at a sensible size — if not, change `Panel` to a `PanelContainer` that
sizes to its `VBox` and give the root real extents.

---

## #5 — Player phase does not end automatically when all units are expended

**Confidence: High (confirmed).** There is **no auto-end logic**. `TurnManager`
exposes `are_all_player_units_done()` (`scripts/core/TurnManager.gd:150-157`) but
it is consulted *only* inside the manual End-Turn confirmation flow
(`MapCursor._on_end_turn_requested()`). Nothing calls `end_player_phase()` when
the last unit becomes `DONE`.

**Fix (user chose: fully automatic):** In `TurnManager.set_unit_state()`, after
setting a unit to `DONE`, if the current phase is PLAYER and
`are_all_player_units_done()` is true, `call_deferred("end_player_phase")`.
Centralizing it here covers every path that finishes a unit (Wait, attack, item,
staff). The normal phase banner already fires on the phase change — no prompt.

---

## #6 — Unit info box shows stale data

**Confidence: High (confirmed).** `MapCursor._finish_action()`
(`MapCursor.gd:470-479`) clears the selection and resets state to `FREE` but
**never emits `EventBus.unit_deselected`**. The HUD only flips its
`_unit_is_selected` flag back to `false` on that signal
(`scripts/ui/HUD.gd:65-68`). So after *any* unit completes an action, the HUD
still believes a unit is selected, and `_on_cursor_moved()` skips `_show_unit()`
(`HUD.gd:71-77`) — the info box freezes on the unit that last acted and never
follows the cursor again until the next genuine deselect.

**Fix:** Emit `bus.unit_deselected.emit()` at the end of `_finish_action()` (the
`_deselect()` path already emits it; the action-completion path does not).

**User confirmed** the staleness appeared *only* after a unit finished acting —
which matches this cause exactly, so the single emit is the complete fix. The
HP-signal routing (`EventBus.unit_damaged`/`unit_healed`, which `HUD` already
listens for) is worth a quick sanity check but is not implicated here.

---

## #7 — Keyboard does not control the main menu

**Confidence: High.** The menus rely entirely on Godot's built-in `ui_*` actions
for focus navigation and activation. Those default to **arrow keys** (`ui_up`/
`ui_down`) and **Enter/Space** (`ui_accept`). The game's own scheme uses
`cursor_up/down` bound to **W/S + arrows** and `confirm` bound to **Z, Enter,
Space** (from `project.godot`). A player who learned W/S and Z in battle presses
W/S/Z on the menu and nothing happens — only arrows + Enter/Space work. There is
no `ui_*` override in `project.godot`, so the menus and the game speak different
input languages.

**Fix:** Add the game's keys as extra events on the built-in actions in
`project.godot` — W/A/S/D onto `ui_up/ui_down/ui_left/ui_right`, Z onto
`ui_accept`, X onto `ui_cancel`. That fixes every menu at once. (Alternative:
have each menu script handle `cursor_*`/`confirm`/`cancel` directly, but the
input-map approach is far less code.)

*Note:* focus itself is grabbed correctly — `NewGameScreen._ready()` grabs focus
to its (hidden) Start button, but `MainMenu._ready()` runs last as the parent and
re-grabs `NewGameButton`, so initial focus is fine.

---

## #8 — Keybindings not shown in Settings

**Confidence: High (confirmed).** `SettingsScreen` has no keybinding UI at all —
only volume sliders and gameplay `OptionButton`s. It is simply unimplemented
(GDD_07 already notes "no rebind").

**Fix (user chose: read-only):** Add a keybindings section to `SettingsScreen`
that lists each game action and its current key, read from `InputMap` at `open()`
(iterate the relevant actions, format `InputEventKey` via
`OS.get_keycode_string()`). Full rebinding is deferred to Phase 2.

---

## #9 — Map cursor start position should use the `-1,-1` auto-placement sentinel

**Confidence: High (confirmed).** `MapCursor.current_tile` is hardcoded to
`(0, 0)` (`MapCursor.gd:15`) and `setup()` places the cursor there — the map's
top-left corner, far from the player units (which spawn around tiles (1,9)–(2,11)
on `map_001`). `MapData` has a `camera_start_tile` sentinel for the camera but no
equivalent for the cursor.

**Fix:** Either add a `cursor_start_tile` field to `MapData` with a
`Vector2i(-1,-1)` sentinel, or — simpler — have `GameMap` place the cursor on the
first player unit's tile (or the camera-start tile) after spawning when no
explicit start is given. Recommend the latter for the MVP: less data churn,
matches the camera's centroid behaviour.

---

## #10 — Map menu did not appear

**Confidence: High — confirmed.** Playtester reports the **cursor kept moving**
after every failed attempt (M key, confirm-on-empty-tile, cancel-on-empty-tile).
All three route through `_open_map_menu()` (`MapCursor.gd:508-517`), which calls
`lock()` *before* `map_menu.open()`. A locked cursor cannot move — so the cursor
still moving proves `_open_map_menu()` **early-returned at line 509 because
`map_menu` is `null`**. The exported reference did not resolve.

This is the **same root cause as #4**. `map_menu`, `action_menu`, `item_menu`
(and almost certainly `attack_preview`) are all null at runtime — see #4 for why
the exported-Node references fail to resolve.

**Fix:** the single fix in #4 — resolve `MapCursor`'s menu references in
`_ready()` via `get_node_or_null()` instead of relying on the `@export` — covers
#10 as well. Note `attack_preview` feeds `MapCursorTargeting.setup()`
(`MapCursor.gd:90`); if it is null the attack preview during targeting is also
broken, so fix all four references together.

---

## Additional requirement — opening a menu must deselect the active unit

**Source:** playtester note (2026-05-18). Opening the **Settings** screen or the
**Map menu** should clear any currently selected unit.

**Current behaviour:** the Map menu can *only* be opened from `State.FREE`
(`MapCursor.gd:142-144` and the empty-tile paths), so today a unit can never be
selected when it opens — the requirement is already satisfied for that path *by
omission*. It becomes real once:
- the in-game **Settings hotkey** (#3) lands — `open_settings` can fire while a
  unit is selected (`State.UNIT_SELECTED`); and/or
- the Map menu is later made openable from `UNIT_SELECTED`.

**Fix:** before opening either menu, if `_state == State.UNIT_SELECTED` call the
existing `_deselect()` (clears `_selection`, resets `_state` to `FREE`, emits
`EventBus.unit_deselected`), then proceed to open + `lock()`. Do **not** deselect
from `UNIT_MOVED`/`TARGETING` — a unit mid-action should not be silently
abandoned; either block the menu in those states or route through the existing
cancel/undo flow first. Recommend: gate the in-game Settings open to
`FREE`/`UNIT_SELECTED` only, deselecting in the latter case.

---

## #11 — Enemy threat area ignores enemy movement range

**Confidence: High (confirmed).** `GridManager.show_enemy_danger_zone()`
(`scripts/core/GridManager.gd:408-424`) paints, per enemy, only
`_tiles_in_range(u.tile_position, …)` — the attack range from the enemy's
**current tile**. It never adds where the enemy could *move*. A true threat area
is every reachable tile **plus** attack range from each of those tiles.

**Fix:** For each living enemy, compute `get_movement_range(enemy)` (include the
current tile), then paint `get_all_attack_tiles(enemy, move_tiles)` — that helper
already returns the union of move tiles and their attack reach
(`GridManager.gd:308-318`). Keep skipping healing-staff enemies.

---

## #12 — Enemy threat area should be a toggle

**Confidence: High (confirmed).** It is currently **hold-to-show**: painted on
`show_danger_zone` key/MMB press and cleared on release
(`MapCursor._input()`, `MapCursor.gd:148-171`).

**Fix:** On each `show_danger_zone` press, flip `_danger_zone_shown` — paint when
turning on, `clear_overlays()` when turning off. Remove the key-release and
MMB-release branches.

---

## #13 — Showing the threat area wipes the selected unit's move range without cancelling the move

**Confidence: High (confirmed).** The danger zone paints onto the **same**
`_overlay` `TileMapLayer` used by the movement/attack overlays, and there is no
save/restore. When a unit is selected (`UNIT_SELECTED`, move overlay shown) and
the player shows the danger zone, releasing it calls `_grid.clear_overlays()`
(`MapCursor.gd:155-156, 169-171`) which wipes **everything**, including the
selection's move overlay — yet `_state` stays `UNIT_SELECTED`, so the move is not
cancelled, just visually erased. Also note the keyboard path is gated to
`_state == State.FREE` but the **middle-mouse path has no state guard**
(`MapCursor.gd:162-171`), so MMB can trigger this mid-selection.

**Fix (user chose: disable while selecting, for the MVP):** Gate the threat
toggle to `State.FREE` only — and crucially add that guard to the **middle-mouse
path**, which currently has none (`MapCursor.gd:162-171`). With the toggle simply
unavailable once a unit is selected, the overlay-wipe can never happen: the move
range and the threat zone are never on screen at the same time, so there is
nothing to restore. This is both the simplest fix and removes the bug entirely.

**Roadmap (not MVP):** the eventual design wants a *general* threat range **plus**
a way to highlight specific enemies for individual threat monitoring. That will
need the danger zone painted on its **own overlay layer** (separate from the
selection overlay) so both can display together. When that lands, revisit this
to allow the threat toggle during selection.

---

## Suggested fix order

1. **Blocking gameplay bug (do first):** #4 + #10 — one shared fix (resolve
   `MapCursor`'s menu references in `_ready()`). Until this lands there is no
   action menu, no map menu, and no Item submenu — core combat is unplayable.
2. **Quick logic fixes, low risk:** #5 (auto-end), #6 (emit `unit_deselected`),
   #9 (cursor start), #11 (threat = move+attack), #12 (toggle), #13 (gate threat
   toggle to `FREE` state). Mostly small script edits; each is unit-testable.
3. **Input map:** #7 (add game keys to `ui_*`) — one `project.godot` edit.
4. **Scene/visual fixes:** #1 (Settings opacity/labels), #2 (camera math), and
   verifying #4's secondary `ActionMenu.tscn` sizing once the menu shows.
5. **New UI surface:** #3 (in-game Settings access), #8 (read-only keybind list).
