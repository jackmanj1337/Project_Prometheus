# Code Review — 2026-05-19b (Playtest 3: Bugs & Immediate Action Items)

**Scope:** the seven bugs and two analysis requests captured in
`CLAUDE/Docs/playtest3_findings_2026-05-19.md` ("Bugs and immediate action
items"). This is a *diagnosis* review — root cause + recommended fix per item —
not a diff review; no code was changed. The "Add to later milestones" half of
that findings doc has already been merged into `GDD/GDD_10_Roadmap.md`.

Files examined: `MapCursor.gd`, `MapCursorSelection.gd`, `MapCursorTargeting.gd`,
`GridManager.gd`, `HUD.gd`, `LevelUpScreen.gd`, `ActionMenu.gd`,
`SettingsManager.gd`, `Unit.gd`/`Unit.tscn`, `CombatResolver.gd`, `ClassData.gd`.

---

## 1. Executive Summary

**Overall code quality (playtest-surfaced areas): 6 / 10.** The underlying
architecture is sound — the cursor FSM is cleanly sliced into testable
`RefCounted` helpers, signals decouple HUD from gameplay, and combat/terrain
math is centralised. The playtest 3 issues are not architectural rot; they are
**seven concentrated input/UX defects in the mouse and camera layer**, plus two
panels that don't follow the cursor. The most serious — a stray `Control` on
every unit silently eating mouse events, and a mouse-pan/camera feedback loop —
make mouse play unreliable. All seven have small, well-contained fixes.

Bugs by severity: **High ×3**, **Medium ×4**, Critical ×0.

---

## 2. Issues Found

### 2.1 — Unit HP bar consumes mouse input over every unit
**[SEVERITY: High]**
- **File & Line:** `scenes/units/Unit.tscn` — `HPBar` node (`type="ProgressBar"`,
  child of the `Unit` `Node2D`). Symptom surfaces in
  `MapCursor._unhandled_input()` (`scripts/core/MapCursor.gd:154`).
- **Problem:** Playtest finding #1, "Cannot select enemy with mouse movement."
  Each unit carries an `HPBar` `ProgressBar`. `ProgressBar` is a `Control`, and a
  `Control`'s default `mouse_filter` is `MOUSE_FILTER_STOP`. A `STOP` control
  under the pointer **consumes** `InputEventMouseMotion` and
  `InputEventMouseButton` before they reach `_unhandled_input`. So whenever the
  pointer is over the HP-bar rectangle of *any* unit, the cursor stops tracking
  the mouse and clicks are swallowed — the player cannot hover or click that
  unit. It reads as "can't select the enemy" because hovering enemies (to
  inspect) is the common mouse interaction with non-player units.
- **Root Cause:** The HP bar was added as a display widget; `mouse_filter` was
  left at the `Control` default. Display-only controls must opt out of input
  picking explicitly — an easy Godot gotcha.
- **Recommended Fix:** Set the HP bar to ignore the mouse. In `Unit.tscn`:
  ```
  [node name="HPBar" type="ProgressBar" parent="."]
  mouse_filter = 2   ; MOUSE_FILTER_IGNORE — display only, never eat cursor input
  ```
  Or, equivalently, in `Unit.gd._ready()`:
  ```gdscript
  $HPBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
  ```
  Audit every other in-world `Control` (any future name plate, status icon) for
  the same default.
- **Tradeoffs:** None — the HP bar is never meant to be interactive.

### 2.2 — Mouse click cannot dismiss the level-up screen
**[SEVERITY: Medium]**
- **File & Line:** `scripts/ui/LevelUpScreen.gd:93-101` (`_unhandled_input`).
- **Problem:** Playtest finding #2. The level-up panel only advances on
  `is_action_pressed("confirm")` / `"cancel")` — keyboard actions. A left click
  does nothing, so a mouse-only player is stuck staring at the panel until they
  reach for the keyboard.
- **Root Cause:** The dismiss handler was written for the keyboard confirm flow;
  the mouse path was never added. (The same class blocks the cursor correctly
  via `_input_suppressed`, so the screen is modal — it just has no mouse exit.)
- **Recommended Fix:** Accept a mouse-button press as a dismiss:
  ```gdscript
  func _unhandled_input(event: InputEvent) -> void:
      if not visible:
          return
      var sm := get_node_or_null("/root/SettingsManager")
      if sm and sm.level_up_screen == "auto":
          return  # timer handles dismissal; player input ignored in auto mode
      var clicked := event is InputEventMouseButton and event.pressed
      if event.is_action_pressed("confirm") or event.is_action_pressed("cancel") or clicked:
          get_viewport().set_input_as_handled()
          _advance()
  ```
- **Tradeoffs:** Any mouse button advances the panel, including right-click.
  That matches the "any confirm/cancel key" behaviour already there, so it is
  consistent; restrict to `MOUSE_BUTTON_LEFT` if a stricter feel is wanted.

### 2.3 — Staff (heal) range is not shown when a healer is selected
**[SEVERITY: Medium]**
- **File & Line:** `scripts/core/MapCursorSelection.gd:42` (`select_at`) and
  `:79` (`undo_and_reselect`); `GridManager.get_attack_range_from_tiles()`
  `scripts/core/GridManager.gd:288-304`.
- **Problem:** Playtest finding #3, "Staff range not shown." When a unit is
  selected, `select_at` paints the blue movement overlay and then a red attack
  overlay via `get_attack_range_from_tiles()`. For a healing-staff user that
  function early-returns `[]` (`_equipped_can_attack()` is false — line 291), so
  a selected healer shows **movement range only**. The heal range is painted
  (`show_heal_overlay`) solely inside `MapCursorTargeting.begin()` *after* the
  player has moved and chosen "Staff" — too late to plan the move.
- **Root Cause:** Range display is modelled as "attack range" specifically;
  staff reach was treated as part of the targeting flow, not the selection
  preview. Correct for offence, but a healer has no attack overlay to stand in
  for it.
- **Recommended Fix:** Add a staff-range query parallel to the attack one and
  paint it with the heal overlay when the equipped weapon is a healing staff.
  In `GridManager.gd`:
  ```gdscript
  # Heal reach around the movement range, for the selection-time overlay.
  # Mirrors get_attack_range_from_tiles but for a healing staff's range.
  func get_staff_range_from_tiles(unit: Node, from_tiles: Array[Vector2i]) -> Array[Vector2i]:
      var out: Array[Vector2i] = []
      var w: WeaponData = unit.get_equipped_weapon() if unit and unit.has_method("get_equipped_weapon") else null
      if w == null or not w.is_healing_staff():
          return out
      var wrange := _get_weapon_range(unit)
      var from_set: Dictionary = {}
      for t in from_tiles:
          from_set[t] = true
      var seen: Dictionary = {}
      for src in from_tiles:
          for tile in _tiles_in_range(src, wrange.x, wrange.y):
              if not from_set.has(tile):
                  seen[tile] = true
      for k in seen.keys():
          out.append(k)
      return out
  ```
  Then in `MapCursorSelection.select_at()` (and the identical block in
  `undo_and_reselect()`):
  ```gdscript
  var w: WeaponData = unit.get_equipped_weapon() if unit.has_method("get_equipped_weapon") else null
  if w != null and w.is_healing_staff():
      _grid.show_heal_overlay(_grid.get_staff_range_from_tiles(unit, movement_tiles))
  else:
      _grid.show_attack_overlay(_grid.get_attack_range_from_tiles(unit, movement_tiles))
  ```
- **Tradeoffs:** A unit carrying *both* a staff and a weapon shows only the
  equipped one's range — acceptable, and consistent with how combat already
  reads the equipped weapon. A future offensive staff would want the attack
  overlay; gating on `is_healing_staff()` (not weapon type) keeps that working.

### 2.4 — Action / item / weapon menus are clipped at the map's right & bottom edges
**[SEVERITY: High]**
- **File & Line:** `scripts/core/MapCursor.gd:447-451` (`_show_action_menu`),
  `:516-519` (`_use_item`), `:559-562` (`_open_weapon_menu`).
- **Problem:** Playtest finding #4. All three menus are placed at
  `screen_pos + Vector2(TILE_SIZE, 0)` — one tile to the *right* of the acting
  unit — with no check against the viewport. A unit on the right column pushes
  the 128-px-wide `ActionMenu` (`ActionMenu.tscn` `custom_minimum_size`) off the
  right edge; a unit on the bottom rows pushes the lower buttons below the
  screen. Keyboard navigation still works, but the player can't see the options.
- **Root Cause:** The placement assumes there is always room to the lower-right
  of the unit. No clamp / flip to keep the menu rect inside the viewport.
- **Recommended Fix:** Add a shared placement helper that flips left when the
  menu would overflow right and clamps into the visible rect:
  ```gdscript
  # Positions a HUD menu next to a unit's tile, kept fully on screen.
  func _place_menu_near(menu: Node, tile: Vector2i) -> void:
      var world_pos := _grid.tile_to_world(tile)
      var screen_pos: Vector2 = get_viewport().canvas_transform * world_pos
      var view: Vector2 = get_viewport().get_visible_rect().size
      var menu_size: Vector2 = menu.get_combined_minimum_size()
      var pos := screen_pos + Vector2(GameConstants.TILE_SIZE, 0)
      # Flip to the unit's left if the menu would run off the right edge.
      if pos.x + menu_size.x > view.x:
          pos.x = screen_pos.x - menu_size.x
      pos.x = clampf(pos.x, 0.0, maxf(0.0, view.x - menu_size.x))
      pos.y = clampf(pos.y, 0.0, maxf(0.0, view.y - menu_size.y))
      menu.position = pos
  ```
  Route `_show_action_menu`, `_use_item`, and `_open_weapon_menu` through it,
  passing `_selection.selected_unit.tile_position`.
- **Tradeoffs:** `get_combined_minimum_size()` is reliable for these
  container-based menus; if a menu's real size differs after `show_for()`
  populates it, call the helper *after* `show_for()` so the size is current
  (`ActionMenu` hides rows for unavailable actions, so its height varies).

### 2.5 — Camera is not returned to the cursor at the start of the player phase
**[SEVERITY: Medium]**
- **File & Line:** `scripts/core/MapCursor.gd:123-127` (`_on_phase_changed`),
  `:770-772` (`unlock`).
- **Problem:** Playtest finding #5. AI-phase camera tracking (commit f9e4e6d)
  leaves the camera wherever the last enemy acted. On the switch to the player
  phase, `_on_phase_changed` calls `unlock()`, which only sets `_state = FREE`.
  The camera is never brought back, so the player regains control with their
  cursor somewhere off-screen until they happen to move it near an edge.
- **Root Cause:** `unlock()` is a pure state transition; the camera-recentre
  step was never part of the phase-change path.
- **Recommended Fix:** Recentre on the cursor before handing control back:
  ```gdscript
  func _on_phase_changed(new_phase: int) -> void:
      if new_phase == GameState.Phase.ENEMY:
          lock()
      else:
          # AI-phase tracking left the camera on the last enemy to act — pull it
          # back onto the player's cursor before unlocking input (playtest 3 #5).
          _scroll_camera_if_needed()
          unlock()
  ```
  `_scroll_camera_if_needed()` already snaps the view so the cursor sits within
  the edge buffer, and clamps to the map — it handles a cursor far off-screen.
- **Tradeoffs:** The recentre is an instant jump. If a smooth pan is preferred,
  enable `Camera2D` position smoothing or tween `_camera.position`; an instant
  snap is the safe MVP behaviour and matches the existing scroll code.

### 2.6 — Unit info panel does not follow the cursor during move/attack/staff selection
**[SEVERITY: Medium]**
- **File & Line:** `scripts/ui/HUD.gd:71-77` (`_on_cursor_moved`), `:60-63`
  (`_on_unit_selected`).
- **Problem:** Playtest finding #6. While a unit is selected, `HUD._unit_is_selected`
  is `true`, and `_on_cursor_moved` then **skips** `_show_unit`. So during
  `UNIT_SELECTED` (planning a move) and `TARGETING` (picking an attack/heal
  target) the info panel stays latched on the acting unit — the player can't see
  the stats of the enemy they are about to attack or the ally they are about to
  heal.
- **Root Cause:** The HUD treats "a unit is selected" as "freeze the panel on
  that unit." That is right for keeping the panel up, but wrong about *which*
  unit: the cursor has moved away from the selected unit by then.
- **Recommended Fix:** Always show whatever the cursor is over; fall back to the
  selected unit only on an empty tile. Store the selected unit in the HUD:
  ```gdscript
  var _selected_unit: Node = null

  func _on_unit_selected(unit: Node) -> void:
      _unit_is_selected = true
      _selected_unit = unit
      _show_unit(unit)

  func _on_unit_deselected() -> void:
      _unit_is_selected = false
      _selected_unit = null
      _show_unit(_grid.get_unit_at(_cursor_tile) if _grid != null and _cursor_tile.x >= 0 else null)

  func _on_cursor_moved(tile: Vector2i) -> void:
      _cursor_tile = tile
      _update_terrain(tile)
      var hovered: Node = _grid.get_unit_at(tile) if _grid != null else null
      if hovered != null:
          _show_unit(hovered)            # whoever the cursor is on — incl. enemies/allies
      elif _unit_is_selected:
          _show_unit(_selected_unit)     # empty tile mid-action: keep the actor visible
      else:
          _show_unit(null)
  ```
- **Tradeoffs:** Decision point — on an *empty* tile during selection this keeps
  the acting unit shown; the alternative is to blank the panel. Showing the
  actor is the less jarring choice and is assumed here. Combat prediction is a
  separate panel (`AttackPreview`), so this does not conflict with it.

### 2.7 — Mouse-driven cursor + edge-scroll feedback loop ("map moves too fast")
**[SEVERITY: High]**
- **File & Line:** `scripts/core/MapCursor.gd:243-256` (`_handle_mouse_motion`),
  `:327-344` (`_set_tile`), `:788-816` (`_scroll_camera_if_needed`).
- **Problem:** Playtest finding #7. `_handle_mouse_motion` derives the cursor
  tile from the **absolute** mouse position (`canvas_transform.affine_inverse() *
  event.position`). When the cursor reaches the screen edge, `_set_tile` calls
  `_scroll_camera_if_needed`, which pans the camera. Panning changes the
  screen→world mapping, so the *same* mouse position now resolves to a tile
  further along — the next `InputEventMouseMotion` jumps the cursor again, which
  scrolls again. The result is a runaway pan that flings the map to its clamp.
  There is also no sensitivity/speed control: each scroll is a hard one-or-more
  tile jump with no smoothing.
- **Root Cause:** The cursor is positioned from an absolute pointer coordinate
  while the camera (which defines that coordinate system) is itself driven by
  the cursor — a closed loop with no damping. Edge-pan was designed for the
  keyboard cursor, where the input is a discrete step, not a re-sampled absolute
  position.
- **Recommended Fix:** Decouple the camera pan from mouse-driven cursor moves.
  The clean fix is a steady, rate-based edge pan:
  - In `_handle_mouse_motion`, move the cursor but **do not** trigger an
    edge scroll — clamp the resolved tile to the currently visible tile range so
    a mouse move alone cannot push the cursor off-screen.
  - Separately, in `_process`, if the pointer is within an edge margin of the
    *screen*, pan the camera by a fixed `pixels_per_second * delta` (a constant,
    later a Settings slider — see the roadmap "Camera settings" backlog item).
  ```gdscript
  # sketch — _process(): rate-based edge pan, independent of the cursor
  var m := get_viewport().get_mouse_position()
  var view := get_viewport().get_visible_rect().size
  var pan := Vector2.ZERO
  if m.x < EDGE_PX: pan.x = -1
  elif m.x > view.x - EDGE_PX: pan.x = 1
  if m.y < EDGE_PX: pan.y = -1
  elif m.y > view.y - EDGE_PX: pan.y = 1
  if pan != Vector2.ZERO and _camera:
      _camera.position += pan * PAN_SPEED * delta   # then clamp to map bounds
  ```
  A smaller interim fix: keep edge-scroll but skip it when the move came from the
  mouse (pass a `from_mouse` flag through `_set_tile`), which stops the runaway
  without adding the rate-based pan.
- **Tradeoffs:** The rate-based pan is the larger change and needs the camera
  clamp logic factored out of `_scroll_camera_if_needed`. The interim
  "skip-scroll-on-mouse" fix is one flag but means the mouse cursor can't reach
  tiles outside the current view without the player nudging the camera another
  way. Expose `PAN_SPEED` in Settings so #7's "make it variable" is satisfied
  (this is already on the roadmap under "Camera settings").

---

## 3. Positive Observations

1. **Clean FSM slicing.** `MapCursor` delegates to three injectable `RefCounted`
   helpers (`MapCursorSelection`, `MapCursorTargeting`, `MapCursorInput`). The
   state machine and EventBus relays stay in one place, and each slice is
   unit-testable without a `SceneTree` — the playtest 3 fixes for #3, #6 and #7
   all land in small, well-isolated functions because of this.
2. **Defence-in-depth already practised.** `camera_edge_buffer` is clamped both
   on load (`SettingsManager.gd:62`) and at the accessor (`MapCursor.gd:780`) —
   a model boundary *and* a use-site guard. The codebase clearly knows the
   "clamp where untrusted data enters" lesson; bugs #2.1 and #2.4 are the same
   lesson un-applied at a `Control` boundary and a viewport boundary.
3. **Terrain and combat math are centralised and consistent.** Terrain feeds
   combat through exactly two functions — `get_terrain_def_bonus()` (damage,
   `CombatResolver.gd:266`) and `get_terrain_dodge_bonus()` (hit, `:233`) — with
   no scattered duplication. EXP is a single table with one index formula.
4. **Comments explain *why*.** Most non-obvious code carries a rationale comment
   (the `canvas_transform` vs camera-transform note at `MapCursor.gd:246`, the
   `_finish_action` "#6" latch note). This made root-causing the playtest bugs
   fast.

---

## 4. Architectural Observations

- **The mouse-input layer is the weak seam.** Six of the seven bugs touch mouse
  or camera handling (#1, #4, #5, #6, #7; #2 is mouse on a UI screen). The
  keyboard path is mature and well-tested; the mouse path was added on top and
  has not had the same scrutiny. Worth a dedicated pass: a focused
  `test_map_cursor_input` already exists — extend it with mouse-motion cases
  (edge behaviour, tile resolution) once #7 is fixed.
- **"Range overlay" conflates *attack* with *reach*.** `get_attack_range_from_tiles`
  bakes in the "staves can't attack" rule, so it doubles as "should an overlay
  show at all" — which is why healers (#3) get no preview. A unit's *reach*
  (where its equipped weapon can act, offensive or supportive) and *whether that
  reach is hostile* are two concepts; separating them (one range function, an
  overlay-colour decision on top) would prevent the next staff/offensive-staff
  surprise.
- **Menu placement is duplicated three times.** `_show_action_menu`,
  `_use_item`, and `_open_weapon_menu` each repeat the
  `tile_to_world → canvas_transform → + TILE_SIZE` placement. Bug #4 exists in
  all three copies; the recommended `_place_menu_near()` helper removes the
  duplication and fixes them together — see also the `simplify` skill.
- **No regression test will currently catch #4 or #5.** These are layout/camera
  effects with no assertion surface. After fixing, consider a headless test that
  asserts a placed menu's rect stays within the viewport, and that the camera
  centre is within `buffer` tiles of the cursor after a phase change.

---

## 5. Prioritized Action Plan

Ordered by impact ÷ effort — the top three are near-trivial fixes for High-severity bugs.

1. **#2.1 — HP bar `mouse_filter = IGNORE`.** One scene property; unblocks all
   mouse interaction with units. *(High severity, trivial effort.)*
2. **#2.5 — Recentre camera on player-phase start.** One added line in
   `_on_phase_changed`. *(Medium severity, trivial effort.)*
3. **#2.2 — Accept mouse click to dismiss the level-up screen.** A few lines in
   `LevelUpScreen._unhandled_input`. *(Medium severity, trivial effort.)*
4. **#2.4 — Clamp/flip menu placement.** Add `_place_menu_near()`, route the
   three call sites through it. *(High severity, small effort.)*
5. **#2.3 — Staff range overlay on selection.** Add `get_staff_range_from_tiles`,
   branch the overlay in `select_at` + `undo_and_reselect`. *(Medium severity,
   small effort.)*
6. **#2.6 — HUD follows the cursor during selection/targeting.** Rework
   `HUD._on_cursor_moved`; store the selected unit. *(Medium severity, small
   effort.)*
7. **#2.7 — Fix the mouse-pan feedback loop.** Ship the interim
   "skip-scroll-on-mouse" flag first to stop the runaway, then schedule the
   rate-based edge pan + Settings slider with the roadmap "Camera settings"
   item. *(High severity, medium effort.)*

Each fix should ship with a unit test where one is reasonable (per `CLAUDE.md`):
#2.3 and #2.6 are directly testable in the existing headless suites; #2.1, #2.4,
#2.5, #2.7 need either a viewport-rect assertion or manual verification — note
which in the session notes.

---

## 6. Terrain Analysis (findings doc #8 — "how terrain should have affected the MVP playtest")

**Terrain is fully wired** — it is not a stub. Seven types are defined, each
with three independent effects:

| Terrain  | Move cost | DEF bonus (defender) | Dodge bonus (defender) |
| -------- | --------- | -------------------- | ---------------------- |
| plain    | 1         | 0                    | 0                      |
| forest   | 2         | +1                   | +15                    |
| mountain | 3         | +2                   | +20                    |
| fort     | 1         | +2                   | +30                    |
| sea      | 2         | 0                    | +10                    |
| desert   | 2         | 0                    | +5                     |
| wall     | 999 (impassable) | 0             | 0                      |

Sources: `GridManager._DEFAULT_MOVE_COSTS` (`:20`), `TERRAIN_DEF_BONUS` (`:32`),
`TERRAIN_DODGE_BONUS` (`:36`).

**How each effect reaches gameplay:**
- **Move cost** — consumed by `GridManager.get_move_cost()` (`:83`) inside the
  Dijkstra flood (`dijkstra_costs`, `:180`) that backs movement range,
  pathfinding, and AI distance. Forests/mountains shrink a unit's reach;
  `desert` has a unit-specific rule (mounted units pay extra via `has_quality`,
  `:97`); `wall` is impassable except with the Phasing skill.
- **DEF bonus** — `CombatResolver.compute_damage()` (`:266`) subtracts
  `defender.get_terrain_def_bonus()` from incoming damage.
- **Dodge bonus** — `CombatResolver.compute_hit_pct()` (`:233`) adds
  `defender.get_terrain_dodge_bonus()` to the defender's dodge.

Both combat bonuses are **defender-only** — a unit gains nothing from terrain on
the turn it attacks out of it, only when defending on it.

**Expected playtest impact, and what to verify:** A defender on a **fort** is
dramatically harder to fight (+2 DEF, **+30** dodge — effectively a different
unit). Mountains/forests create slow, defensible ground; walls form chokepoints.
**The single biggest variable is the playtest map's terrain painting.** If the
MVP map is mostly `plain`, terrain had near-zero effect on the playtest and the
systems above were simply never exercised — that would be a map-authoring gap,
not a code gap. Action item: confirm the playtest map actually contains forts /
mountains / forest in contested positions; if it doesn't, the playtest told us
nothing about terrain, and a terrain-rich test map is needed before the next
session draws conclusions.

---

## 7. Stat Growth & EXP Analysis (findings doc #9 — "MVP stat growths and exp gain formulas")

### Growth rates
- Each class carries a `growth_rates` dictionary (`ClassData.gd`, values 0–100)
  over eight stats: `hp, strength, magic, defense, resistance, skill, speed,
  luck` (`Unit._GROWTH_STATS`, `:514`). Movement is **not** a growth stat.
- On `level_up()` (`Unit.gd:516`) the method is chosen by
  `GameState.leveling_method`:
  - **`growth_random`** (default) — `_level_up_random` (`:551`): a rate of N
    gives `N / 100` guaranteed points plus an `N % 100`% chance of one more. So
    rate 75 → 75% chance of +1; rate 150 → +1 guaranteed, 50% chance of +2.
  - **`growth_fixed`** — `_level_up_fixed` (`:568`): a per-stat accumulator adds
    the rate each level and grants +1 per full 100, carrying the remainder in
    `data.growth_accumulators`. Perfectly predictable: rate 50 → +1 every 2
    levels exactly.
- **Known gap:** stat caps are **not enforced** — `_increment_stat` (`:585`)
  has an explicit `NOT ENFORCED` comment; a high-growth unit can exceed intended
  class limits because `ClassData` carries no cap data yet.

### EXP
- `CombatResolver.calculate_exp()` (`:306`) indexes a 13-entry table by
  `clamp(attacker_level - defender_level + 6, 0, 12)`:
  - Equal level (index 6): **30 EXP on kill, 10 on a landed hit**.
  - Fighting up: index 0 (defender 6+ levels higher) → 59 / 20.
  - Fighting down: index 12 (defender 6+ levels lower) → 1 / 0.
- `Unit.add_exp()` (`:496`) accumulates EXP, fires `level_up()` each time it
  crosses 100, carries the overflow, and discards EXP at `MAX_LEVEL`.
- EXP is awarded in `apply_combat_result` (`:658-667`) to whichever side landed
  a hit, *before* death handling so a unit gets kill EXP even as the target is
  freed.

### ⚠ Caveat that directly affects reading the playtest
Two **debug testing aids** are active in debug builds (`OS.is_debug_build()`):
- **`debug_force_levelup`** — `calculate_exp` returns a full 100 EXP on any
  landed hit (`CombatResolver.gd:307-313`).
- **`debug_growth_boost`** — `_debug_boosted_rate` adds +50 to every growth rate
  (`Unit.gd:538-547`).

If the playtest 3 build was a **debug build with either flag on**, the observed
level-up cadence and stat gains are **not representative of release behaviour**.
Before drawing growth/EXP conclusions from the playtest, confirm which build was
used and whether `debug_force_levelup` / `debug_growth_boost` were set on
`GameState`. (Both aids are slated for deletion — see `GDD_10_Roadmap.md`
§ Pre-Release Cleanup.)

---

*Review produced 2026-05-19 against branch `main` at commit `f9e4e6d`. No code
was modified — this document is diagnosis only, per the code review
instructions.*
