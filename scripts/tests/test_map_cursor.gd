extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_map_cursor.gd
# FSM unit tests for MapCursor — pins the state-transition behavior as a safety net
# before the planned MapCursorInput / MapCursorSelection slicing. Tests drive the FSM
# by calling the handler methods directly (not by synthesising InputEvents), so they
# stay valid regardless of how input dispatch is later restructured.

const MapCursorS = preload("res://scripts/core/MapCursor.gd")
const UnitScene  = preload("res://scenes/units/Unit.tscn")

# MapCursor.State enum values (FREE, UNIT_SELECTED, UNIT_MOVED, TARGETING, LOCKED).
const FREE          := 0
const UNIT_SELECTED := 1
const UNIT_MOVED    := 2
const TARGETING     := 3
const LOCKED        := 4

var _grid: GridManager
var _gs: Node          # stub GameState at /root/GameState — feeds GridManager.get_unit_at


# Builds a real Unit (the cursor's _selection.selected_unit field is typed Unit, and get_unit_at
# returns whatever is registered, so stubs would not satisfy the type). Registers it in
# the stub GameState so GridManager.get_unit_at can find it.
func _make_unit(tile: Vector2i, team_name: String, hp: int = 20) -> Unit:
	var d := UnitData.new()
	d.hp = hp
	d.max_hp = 20
	d.movement = 5
	var u: Unit = UnitScene.instantiate()
	u.data = d
	u.team = team_name
	root.add_child(u)
	u.tile_position = tile
	_gs.all_units.append(u)
	return u


# Fresh cursor + camera + TurnManager, wired via setup(). add_child runs _ready() with
# action_menu null, so the menu-signal hookups are skipped — fine, tests call directly.
func _make_cursor(turn: TurnManager) -> MapCursor:
	var c: MapCursor = MapCursorS.new()
	root.add_child(c)
	var cam := Camera2D.new()
	root.add_child(cam)
	c.setup(_grid, cam, turn)
	return c


func _init() -> void:
	print("=== MapCursor FSM Test ===")
	var passed := 0
	var failed := 0

	# Shared 6x6 plain grid.
	_grid = GridManager.new()
	_grid.map_width = 6
	_grid.map_height = 6
	for y in 6:
		for x in 6:
			_grid.set_terrain_fallback(Vector2i(x, y), "plain")
	root.add_child(_grid)

	# Stub GameState — GridManager.get_unit_at reads /root/GameState.all_units (duck-typed).
	var gs_script := GDScript.new()
	gs_script.source_code = "extends Node\nvar all_units: Array[Node] = []\nfunc get_living_player_units() -> Array[Node]: return all_units\nfunc is_player_turn() -> bool: return true\n"
	gs_script.reload()
	_gs = gs_script.new()
	_gs.name = "GameState"
	root.add_child(_gs)
	await process_frame

	# ---- Initial state ----
	var t1 := TurnManager.new(); root.add_child(t1)
	var c1 := _make_cursor(t1)
	if c1._state == FREE and c1.current_tile == Vector2i(0, 0):
		print("OK  fresh cursor starts FREE at (0,0)")
		passed += 1
	else:
		print("FAIL initial state: _state=%d tile=%s" % [c1._state, str(c1.current_tile)])
		failed += 1

	# ---- lock() / unlock() ----
	c1._input_handler._held_dir = Vector2i(1, 0)
	c1.lock()
	if c1._state == LOCKED and c1._input_handler._held_dir == Vector2i.ZERO:
		print("OK  lock() → LOCKED and clears held direction")
		passed += 1
	else:
		print("FAIL lock(): _state=%d _input_handler._held_dir=%s" % [c1._state, str(c1._input_handler._held_dir)])
		failed += 1
	c1.unlock()
	if c1._state == FREE:
		print("OK  unlock() → FREE")
		passed += 1
	else:
		print("FAIL unlock(): _state=%d" % c1._state)
		failed += 1

	# ---- _on_phase_changed: ENEMY locks, PLAYER unlocks ----
	c1._on_phase_changed(1)  # GameState.Phase.ENEMY
	var locked_on_enemy := c1._state == LOCKED
	c1._on_phase_changed(0)  # GameState.Phase.PLAYER
	if locked_on_enemy and c1._state == FREE:
		print("OK  _on_phase_changed: ENEMY → LOCKED, PLAYER → FREE")
		passed += 1
	else:
		print("FAIL _on_phase_changed: locked_on_enemy=%s now=%d" % [locked_on_enemy, c1._state])
		failed += 1

	# ---- _place_menu_near keeps the menu fully inside the viewport (playtest 3 #4) ----
	# Action / Item / Weapon menus used to be pinned `+ TILE_SIZE` right of the
	# unit with no viewport check — units near the right or bottom edge pushed
	# the menu off-screen.
	var stub_menu: Control = Control.new()
	stub_menu.size = Vector2(200, 100)
	root.add_child(stub_menu)
	var view: Vector2 = c1.get_viewport().get_visible_rect().size
	# Cursor at world (0,0) — menu placed normally one tile to the right.
	c1._place_menu_near(stub_menu, Vector2i(0, 0))
	var top_left_ok: bool = (stub_menu.position.x >= 0
			and stub_menu.position.y >= 0
			and stub_menu.position.x + stub_menu.size.x <= view.x
			and stub_menu.position.y + stub_menu.size.y <= view.y)
	# Move camera so tile (5,5) sits at the bottom-right viewport edge and the
	# menu would overflow without the flip + clamp. Camera2D centres the view,
	# so we put the tile near the camera's bottom-right.
	c1._camera.position = _grid.tile_to_world(Vector2i(5, 5)) - view * 0.5 + Vector2(40, 30)
	c1._place_menu_near(stub_menu, Vector2i(5, 5))
	var bottom_right_ok: bool = (stub_menu.position.x >= 0
			and stub_menu.position.y >= 0
			and stub_menu.position.x + stub_menu.size.x <= view.x
			and stub_menu.position.y + stub_menu.size.y <= view.y)
	if top_left_ok and bottom_right_ok:
		print("OK  _place_menu_near keeps menu inside viewport (playtest 3 #4)")
		passed += 1
	else:
		print("FAIL _place_menu_near: top_left=%s bottom_right=%s pos=%s view=%s" % [
			top_left_ok, bottom_right_ok, stub_menu.position, view])
		failed += 1
	stub_menu.queue_free()

	# ---- _set_tile(from_mouse=true) skips edge-scroll (playtest 3 #7) ----
	# Mouse-driven cursor moves used to cascade into a camera-pan feedback loop.
	# The fix: skip edge-scroll on the from_mouse path, and clamp the mouse-
	# resolved tile to the visible area. Force the scroll precondition by
	# bumping the grid to 30×30 so the view doesn't already contain everything,
	# then restore — other tests in this file rely on the 6×6 size.
	var saved_w := _grid.map_width
	var saved_h := _grid.map_height
	_grid.map_width = 30
	_grid.map_height = 30
	c1._camera.position = _grid.tile_to_world(Vector2i(2, 2))
	c1._set_tile(Vector2i(2, 2))
	var cam_before := c1._camera.position
	c1._set_tile(Vector2i(29, 29), true)  # mouse-driven, far corner — must NOT scroll
	var no_pan_on_mouse := c1._camera.position == cam_before
	c1._set_tile(Vector2i(2, 2))
	cam_before = c1._camera.position
	c1._set_tile(Vector2i(29, 29))        # keyboard path, default arg — pans as before
	var pans_on_keyboard := c1._camera.position != cam_before
	if no_pan_on_mouse and pans_on_keyboard:
		print("OK  _set_tile(from_mouse=true) skips edge-scroll (playtest 3 #7)")
		passed += 1
	else:
		print("FAIL mouse vs keyboard scroll: no_pan_on_mouse=%s pans_on_keyboard=%s" % [
			no_pan_on_mouse, pans_on_keyboard])
		failed += 1
	# _clamp_tile_to_view keeps a tile inside the camera's current view rect.
	c1._camera.position = _grid.tile_to_world(Vector2i(10, 10))
	var view_size_clamp: Vector2 = c1.get_viewport().get_visible_rect().size
	var tiles_w := int(view_size_clamp.x / GameConstants.TILE_SIZE)
	var tiles_h := int(view_size_clamp.y / GameConstants.TILE_SIZE)
	var tl: Vector2i = _grid.world_to_tile(c1._camera.position - view_size_clamp * 0.5)
	var clamped := c1._clamp_tile_to_view(Vector2i(1000, 1000))
	if clamped.x == tl.x + tiles_w - 1 and clamped.y == tl.y + tiles_h - 1:
		print("OK  _clamp_tile_to_view clamps to the visible tile range (playtest 3 #7)")
		passed += 1
	else:
		print("FAIL _clamp_tile_to_view: got %s want bottom-right of view (tl=%s tw=%d th=%d)" % [
			clamped, tl, tiles_w, tiles_h])
		failed += 1
	_grid.map_width = saved_w
	_grid.map_height = saved_h

	# ---- _on_phase_changed → PLAYER recentres camera on the cursor (playtest 3 #5) ----
	# AI-phase tracking leaves the camera wherever the last enemy acted; the
	# handover must pull it back onto the player's cursor before unlock.
	c1._set_tile(Vector2i(0, 0))
	c1._camera.position = Vector2(10_000, 10_000)  # simulate camera far from cursor
	c1._on_phase_changed(0)  # PLAYER — should call _scroll_camera_if_needed before unlock
	# After recentre the cursor (tile 0,0 = world centre 32,32) must sit inside
	# the camera's visible rect, not 10k pixels away. Allow some slack — the
	# scroll math clamps the view to the map bounds, so the centre lands at a
	# specific edge position rather than dead-on the cursor.
	var view_size: Vector2 = c1.get_viewport().get_visible_rect().size
	var cam_rect := Rect2(c1._camera.position - view_size * 0.5, view_size)
	var cursor_world: Vector2 = _grid.tile_to_world(c1.current_tile)
	if cam_rect.has_point(cursor_world):
		print("OK  _on_phase_changed: PLAYER recentres camera onto cursor (playtest 3 #5)")
		passed += 1
	else:
		print("FAIL phase-change recentre: cam=%s cursor_world=%s rect=%s" % [
			c1._camera.position, cursor_world, cam_rect])
		failed += 1

	# ---- _on_phase_changed → ENEMY saves camera, PLAYER restores it (PT4 #2) ----
	# Bump the grid wider than the viewport (~20x11 tiles) so _scroll_camera_if_needed
	# doesn't clamp the camera back to the map centre; on a 6x6 grid the safety net
	# would always dominate and mask the actual restore. Same trick as the #7 block.
	var pt4_saved_w := _grid.map_width
	var pt4_saved_h := _grid.map_height
	_grid.map_width = 30
	_grid.map_height = 30
	# Cursor mid-map so the saved view contains it; the PT3 #5 safety net is then
	# a no-op and the restore is the only force on the camera. Pre-align the camera
	# via _scroll_camera_if_needed so the saved position is a fixed point of the
	# scroll math (which tile-aligns its output) — otherwise the restore would land
	# on a different tile-aligned position than what we saved.
	c1._set_tile(Vector2i(15, 15))
	c1._scroll_camera_if_needed()
	var saved_view: Vector2 = c1._camera.position
	c1._on_phase_changed(1)  # ENEMY — controller captures the current view
	# Save state lives on the CameraController now (B4); read it through there.
	var saved_ok: bool = c1._camera_ctrl._has_saved and c1._camera_ctrl._saved_position == saved_view
	c1._camera.position = Vector2(9_000, 9_000)  # AI-phase pan to "the last enemy"
	c1._on_phase_changed(0)  # PLAYER — controller restores the saved view
	var restored_ok: bool = c1._camera.position == saved_view
	_grid.map_width = pt4_saved_w
	_grid.map_height = pt4_saved_h
	if saved_ok and restored_ok:
		print("OK  _on_phase_changed: ENEMY saves camera, PLAYER restores it (PT4 #2)")
		passed += 1
	else:
		print("FAIL camera save/restore: saved_ok=%s restored_ok=%s pos=%s" % [
			saved_ok, restored_ok, c1._camera.position])
		failed += 1

	# ---- _set_tile clamps to map bounds ----
	c1._set_tile(Vector2i(99, 99))
	var clamped_hi := c1.current_tile == Vector2i(5, 5)
	c1._set_tile(Vector2i(-9, -9))
	var clamped_lo := c1.current_tile == Vector2i(0, 0)
	if clamped_hi and clamped_lo:
		print("OK  _set_tile clamps cursor to map bounds")
		passed += 1
	else:
		print("FAIL _set_tile clamp: hi=%s lo=%s" % [clamped_hi, clamped_lo])
		failed += 1

	# ---- move_cursor moves within bounds ----
	c1._set_tile(Vector2i(0, 0))
	c1.move_cursor(Vector2i(1, 0))
	if c1.current_tile == Vector2i(1, 0):
		print("OK  move_cursor steps the cursor in-bounds")
		passed += 1
	else:
		print("FAIL move_cursor: tile=%s" % str(c1.current_tile))
		failed += 1

	# ---- FREE + confirm on a player unit → UNIT_SELECTED ----
	_gs.all_units.clear()
	var t2 := TurnManager.new(); root.add_child(t2)
	var c2 := _make_cursor(t2)
	var p_unit := _make_unit(Vector2i(2, 2), "player")
	c2._set_tile(Vector2i(2, 2))
	c2._on_confirm()
	if c2._state == UNIT_SELECTED and c2._selection.selected_unit == p_unit:
		print("OK  FREE + confirm on player unit → UNIT_SELECTED")
		passed += 1
	else:
		print("FAIL select: _state=%d selected=%s" % [c2._state, str(c2._selection.selected_unit)])
		failed += 1

	# ---- UNIT_SELECTED + cancel → deselect → FREE ----
	c2._on_cancel()
	if c2._state == FREE and c2._selection.selected_unit == null:
		print("OK  UNIT_SELECTED + cancel → FREE, unit deselected")
		passed += 1
	else:
		print("FAIL deselect: _state=%d selected=%s" % [c2._state, str(c2._selection.selected_unit)])
		failed += 1

	# ---- FREE + confirm on an empty tile → opens the map menu ----
	# Wire a stub map_menu; _open_map_menu locks the cursor and calls open().
	var map_menu_script := GDScript.new()
	map_menu_script.source_code = "extends Node\nsignal end_turn_requested\nsignal menu_closed\nvar opened := false\nfunc open(): opened = true\n"
	map_menu_script.reload()
	c2.map_menu = map_menu_script.new()
	root.add_child(c2.map_menu)
	c2._set_tile(Vector2i(5, 5))  # no unit here
	c2._on_confirm()
	if c2._state == LOCKED and c2.map_menu.opened and c2._selection.selected_unit == null:
		print("OK  FREE + confirm on empty tile → opens the map menu (LOCKED)")
		passed += 1
	else:
		print("FAIL confirm-empty-menu: _state=%d opened=%s" % [c2._state, c2.map_menu.opened])
		failed += 1

	# ---- FREE + cancel on an empty tile → opens the map menu ----
	c2.unlock()                   # back to FREE
	c2.map_menu.opened = false
	c2._set_tile(Vector2i(4, 4))  # still empty
	c2._on_cancel()
	if c2._state == LOCKED and c2.map_menu.opened:
		print("OK  FREE + cancel on empty tile → opens the map menu (LOCKED)")
		passed += 1
	else:
		print("FAIL cancel-empty-menu: _state=%d opened=%s" % [c2._state, c2.map_menu.opened])
		failed += 1

	# ---- FREE + confirm on an enemy unit → stays FREE ----
	_gs.all_units.clear()
	var t3 := TurnManager.new(); root.add_child(t3)
	var c3 := _make_cursor(t3)
	_make_unit(Vector2i(3, 3), "enemy")
	c3._set_tile(Vector2i(3, 3))
	c3._on_confirm()
	if c3._state == FREE and c3._selection.selected_unit == null:
		print("OK  FREE + confirm on enemy unit → stays FREE (not selectable)")
		passed += 1
	else:
		print("FAIL confirm-enemy: _state=%d" % c3._state)
		failed += 1

	# ---- FREE + confirm on an already-acted unit → stays FREE ----
	_gs.all_units.clear()
	var t4 := TurnManager.new(); root.add_child(t4)
	var c4 := _make_cursor(t4)
	var acted := _make_unit(Vector2i(1, 1), "player")
	t4.set_unit_state(acted, TurnManager.UnitState.DONE)
	c4._set_tile(Vector2i(1, 1))
	c4._on_confirm()
	if c4._state == FREE and c4._selection.selected_unit == null:
		print("OK  FREE + confirm on a DONE unit → stays FREE (can_unit_act false)")
		passed += 1
	else:
		print("FAIL confirm-acted: _state=%d" % c4._state)
		failed += 1

	# ---- _on_action_chosen("wait") → _finish_action → FREE, unit marked DONE ----
	_gs.all_units.clear()
	var t5 := TurnManager.new(); root.add_child(t5)
	var c5 := _make_cursor(t5)
	var waiter := _make_unit(Vector2i(0, 0), "player")
	c5._selection.selected_unit = waiter
	c5._state = UNIT_MOVED
	c5._on_action_chosen("wait")
	if c5._state == FREE and c5._selection.selected_unit == null \
			and t5.get_unit_state(waiter) == TurnManager.UnitState.DONE:
		print("OK  action 'wait' → FREE and the unit is marked DONE")
		passed += 1
	else:
		print("FAIL wait: _state=%d selected=%s unit_state=%d" \
			% [c5._state, str(c5._selection.selected_unit), t5.get_unit_state(waiter)])
		failed += 1

	# ---- _finish_action liveness guard: a dead unit is NOT written into _unit_states ----
	# Regression for code review 2026-05-16d — a unit that died mid-action must not be
	# re-inserted into TurnManager._unit_states as a stale freed-node key.
	_gs.all_units.clear()
	var t6 := TurnManager.new(); root.add_child(t6)
	var c6 := _make_cursor(t6)
	var dead := _make_unit(Vector2i(0, 0), "player", 0)  # hp 0 → dead
	c6._selection.selected_unit = dead
	c6._state = UNIT_MOVED
	c6._finish_action()
	if c6._state == FREE and not t6._unit_states.has(dead):
		print("OK  _finish_action: a dead unit is not re-inserted into _unit_states")
		passed += 1
	else:
		print("FAIL liveness guard: _state=%d has_dead=%s" % [c6._state, t6._unit_states.has(dead)])
		failed += 1

	# ---- _undo_move_and_reselect: UNIT_MOVED → UNIT_SELECTED ----
	_gs.all_units.clear()
	var t7 := TurnManager.new(); root.add_child(t7)
	var c7 := _make_cursor(t7)
	var mover := _make_unit(Vector2i(2, 2), "player")
	c7._selection.selected_unit = mover
	c7._state = UNIT_MOVED
	c7._undo_move_and_reselect()
	if c7._state == UNIT_SELECTED:
		print("OK  _undo_move_and_reselect: UNIT_MOVED → UNIT_SELECTED")
		passed += 1
	else:
		print("FAIL undo-reselect: _state=%d" % c7._state)
		failed += 1

	# ---- _on_targeting_cancelled → UNIT_MOVED (ActionMenu reopens) ----
	_gs.all_units.clear()
	var t8 := TurnManager.new(); root.add_child(t8)
	var c8 := _make_cursor(t8)
	var menu_script := GDScript.new()
	menu_script.source_code = "extends Node2D\nsignal action_chosen(a)\nsignal hidden_by_cancel\nfunc show_for(_u, _g): pass\n"
	menu_script.reload()
	c8.action_menu = menu_script.new()
	root.add_child(c8.action_menu)
	c8._selection.selected_unit = _make_unit(Vector2i(1, 1), "player")
	c8._set_tile(Vector2i(4, 4))  # cursor parked on a far tile (a target tile)
	c8._state = TARGETING
	c8._on_targeting_cancelled()
	if c8._state == UNIT_MOVED:
		print("OK  _on_targeting_cancelled: TARGETING → UNIT_MOVED")
		passed += 1
	else:
		print("FAIL targeting-cancel: _state=%d" % c8._state)
		failed += 1
	# Cursor must snap back onto the acting unit, not linger on the target (#9).
	if c8.current_tile == Vector2i(1, 1):
		print("OK  _on_targeting_cancelled snaps cursor to acting unit (#9)")
		passed += 1
	else:
		print("FAIL targeting-cancel cursor: tile=%s" % str(c8.current_tile))
		failed += 1

	# ---- _cycle_to_next_unit is a no-op outside FREE ----
	var t9 := TurnManager.new(); root.add_child(t9)
	var c9 := _make_cursor(t9)
	c9._set_tile(Vector2i(3, 3))
	c9._state = UNIT_SELECTED
	c9._cycle_to_next_unit(1)
	if c9.current_tile == Vector2i(3, 3):
		print("OK  _cycle_to_next_unit does nothing outside FREE")
		passed += 1
	else:
		print("FAIL cycle-guard: tile moved to %s" % str(c9.current_tile))
		failed += 1

	# ---- _cycle_to_next_unit steps forward and backward (#3) ----
	_gs.all_units.clear()
	var t_cyc := TurnManager.new(); root.add_child(t_cyc)
	var c_cyc := _make_cursor(t_cyc)
	# Three actable player units at distinct tiles.
	_make_unit(Vector2i(0, 0), "player")
	_make_unit(Vector2i(2, 2), "player")
	_make_unit(Vector2i(4, 4), "player")
	c_cyc._state = FREE
	c_cyc._set_tile(Vector2i(2, 2))       # park on the middle unit
	c_cyc._cycle_to_next_unit(1)          # forward → (4,4)
	var fwd_ok := c_cyc.current_tile == Vector2i(4, 4)
	c_cyc._cycle_to_next_unit(-1)         # back → (2,2)
	var back_ok := c_cyc.current_tile == Vector2i(2, 2)
	c_cyc._cycle_to_next_unit(-1)         # back again → (0,0)
	var back2_ok := c_cyc.current_tile == Vector2i(0, 0)
	c_cyc._cycle_to_next_unit(-1)         # wraps → (4,4)
	var wrap_ok := c_cyc.current_tile == Vector2i(4, 4)
	if fwd_ok and back_ok and back2_ok and wrap_ok:
		print("OK  _cycle_to_next_unit steps forward, backward, and wraps (#3)")
		passed += 1
	else:
		print("FAIL cycle dir: fwd=%s back=%s back2=%s wrap=%s" % [
			fwd_ok, back_ok, back2_ok, wrap_ok])
		failed += 1

	# ---- danger-zone toggle (#12) + FREE-state gating (#13) ----
	var t10 := TurnManager.new(); root.add_child(t10)
	var c10 := _make_cursor(t10)
	c10._state = FREE
	c10._toggle_danger_zone()         # off → on
	var dz_on := c10._danger_zone_shown
	c10._toggle_danger_zone()         # on → off
	var dz_off := not c10._danger_zone_shown
	c10._state = UNIT_SELECTED
	c10._toggle_danger_zone()         # gated while a unit is selected — stays off
	var dz_gated := not c10._danger_zone_shown
	if dz_on and dz_off and dz_gated:
		print("OK  danger zone toggles in FREE, ignored while a unit is selected")
		passed += 1
	else:
		print("FAIL danger toggle: on=%s off=%s gated=%s" % [dz_on, dz_off, dz_gated])
		failed += 1

	# ---- open_settings hotkey: locks the cursor and opens Settings (#3) ----
	var t11 := TurnManager.new(); root.add_child(t11)
	var c11 := _make_cursor(t11)
	var settings_script := GDScript.new()
	settings_script.source_code = "extends Node\nsignal back_pressed\nvar opened := false\nfunc open(): opened = true\n"
	settings_script.reload()
	c11.settings_screen = settings_script.new()
	root.add_child(c11.settings_screen)
	c11._state = FREE
	c11._open_settings_via_hotkey()
	if c11._state == LOCKED and c11.settings_screen.opened:
		print("OK  open_settings hotkey locks the cursor and opens Settings")
		passed += 1
	else:
		print("FAIL open_settings: state=%d opened=%s" % [c11._state, c11.settings_screen.opened])
		failed += 1

	# ---- open_settings from a unit selection drops the selection first (#3) ----
	c11.settings_screen.opened = false
	c11.unlock()
	c11._selection.selected_unit = _make_unit(Vector2i(2, 2), "player")
	c11._state = UNIT_SELECTED
	c11._open_settings_via_hotkey()
	if c11._state == LOCKED and c11._selection.selected_unit == null and c11.settings_screen.opened:
		print("OK  open_settings from UNIT_SELECTED deselects, then opens")
		passed += 1
	else:
		print("FAIL settings-deselect: state=%d unit=%s opened=%s" % [
			c11._state, str(c11._selection.selected_unit), c11.settings_screen.opened])
		failed += 1

	# ---- open_settings is ignored mid-action (UNIT_MOVED) ----
	c11.settings_screen.opened = false
	c11._state = UNIT_MOVED
	c11._open_settings_via_hotkey()
	if not c11.settings_screen.opened and c11._state == UNIT_MOVED:
		print("OK  open_settings ignored during an action (UNIT_MOVED)")
		passed += 1
	else:
		print("FAIL settings-gate: opened=%s state=%d" % [c11.settings_screen.opened, c11._state])
		failed += 1

	# ---- level-up screen suppresses cursor input (#12) ----
	var t_lvl := TurnManager.new(); root.add_child(t_lvl)
	var c_lvl := _make_cursor(t_lvl)
	c_lvl._state = FREE
	c_lvl._on_level_up_started()
	var suppressed := c_lvl._input_suppressed
	# A held direction must not move the cursor while suppressed: _process clears
	# the repeat and bails instead of stepping.
	c_lvl._set_tile(Vector2i(2, 2))
	c_lvl._input_handler.arm_repeat(Vector2i(1, 0))
	c_lvl._process(1.0)
	var frozen := c_lvl.current_tile == Vector2i(2, 2)
	c_lvl._on_level_up_finished()
	var resumed := not c_lvl._input_suppressed
	if suppressed and frozen and resumed:
		print("OK  level-up screen freezes the cursor, then releases it (#12)")
		passed += 1
	else:
		print("FAIL level-up freeze: suppressed=%s frozen=%s resumed=%s" % [
			suppressed, frozen, resumed])
		failed += 1

	# ---- end-turn confirm focuses the Cancel button, not OK (#15/#16) ----
	_gs.all_units.clear()
	var t_et := TurnManager.new(); root.add_child(t_et)
	var c_et := _make_cursor(t_et)
	_make_unit(Vector2i(0, 0), "player")   # an actable unit → the confirm prompt
	c_et._on_end_turn_requested()
	await process_frame
	var dlg: ConfirmationDialog = null
	for ch in root.get_children():
		if ch is ConfirmationDialog:
			dlg = ch
	if dlg != null and dlg.get_cancel_button().has_focus():
		print("OK  end-turn confirm focuses the Cancel button (#15/#16)")
		passed += 1
	else:
		print("FAIL end-turn confirm focus: dlg=%s" % str(dlg))
		failed += 1
	if dlg != null:
		dlg.queue_free()

	# ---- Unit.set_equipped_weapon reorders the inventory (#8) ----
	var swap_unit := _make_unit(Vector2i(0, 0), "player")
	var w_a := InventoryEntry.make_weapon("iron_sword", 40)
	var w_b := InventoryEntry.make_weapon("iron_lance", 40)
	var w_c := InventoryEntry.make_weapon("javelin", 40)
	swap_unit.data.inventory = [w_a, w_b, w_c]
	swap_unit.set_equipped_weapon(w_c)        # equip the javelin → moves to front
	var reorder_ok: bool = swap_unit.data.inventory == [w_c, w_a, w_b]
	swap_unit.set_equipped_weapon(w_c)        # already first → no-op
	var noop_ok: bool = swap_unit.data.inventory == [w_c, w_a, w_b]
	if reorder_ok and noop_ok:
		print("OK  Unit.set_equipped_weapon moves the weapon to the front (#8)")
		passed += 1
	else:
		print("FAIL set_equipped_weapon: %s" % str(swap_unit.data.inventory))
		failed += 1

	# ---- PT4 #1: mouse_cursor="disabled" ignores motion in FREE/UNIT_SELECTED ----
	# Drive _handle_mouse_motion directly with a synthesized event. The function
	# reads SettingsManager.mouse_cursor and bails before touching _set_tile when
	# the setting is "disabled", so the cursor must stay put. When "enabled", the
	# same motion must move it. Skips cleanly if the autoload isn't registered
	# (e.g. someone runs this suite in isolation without --path).
	var sm_mc := root.get_node_or_null("SettingsManager")
	if sm_mc != null:
		var t_mc := TurnManager.new(); root.add_child(t_mc)
		var c_mc := _make_cursor(t_mc)
		# Park the camera on (3,3) so _clamp_tile_to_view doesn't clip (4,4) out.
		c_mc._camera.position = _grid.tile_to_world(Vector2i(3, 3))
		c_mc._set_tile(Vector2i(0, 0))
		var ev := InputEventMouseMotion.new()
		# canvas_transform is identity here (no Camera2D offset applied to the
		# root viewport), so screen pos == world pos for the test.
		ev.position = _grid.tile_to_world(Vector2i(4, 4))

		sm_mc.mouse_cursor = "disabled"
		c_mc._handle_mouse_motion(ev)
		var stayed: bool = c_mc.current_tile == Vector2i(0, 0)

		sm_mc.mouse_cursor = "enabled"
		c_mc._handle_mouse_motion(ev)
		var moved: bool = c_mc.current_tile == Vector2i(4, 4)

		sm_mc.mouse_cursor = "enabled"  # restore default
		if stayed and moved:
			print("OK  mouse_cursor=disabled ignores motion; enabled resumes (PT4 #1)")
			passed += 1
		else:
			print("FAIL mouse_cursor gate: stayed=%s moved=%s tile=%s" % [
				stayed, moved, str(c_mc.current_tile)])
			failed += 1
	else:
		print("SKIP mouse_cursor gate (SettingsManager autoload absent)")

	# ---- _camera_edge_buffer clamps an out-of-range SettingsManager value ----
	var sm_buf := root.get_node_or_null("SettingsManager")
	if sm_buf != null:
		var t_buf := TurnManager.new(); root.add_child(t_buf)
		var c_buf := _make_cursor(t_buf)
		sm_buf.camera_edge_buffer = 999          # corrupt / hand-edited value
		var hi_ok: bool = c_buf._camera_edge_buffer() == 5
		sm_buf.camera_edge_buffer = -3
		var lo_ok: bool = c_buf._camera_edge_buffer() == 0
		sm_buf.camera_edge_buffer = 2            # restore the default
		if hi_ok and lo_ok:
			print("OK  _camera_edge_buffer clamps to 0-5"); passed += 1
		else:
			print("FAIL camera buffer clamp: hi=%s lo=%s" % [hi_ok, lo_ok]); failed += 1
	else:
		print("SKIP camera buffer clamp (SettingsManager autoload absent)")

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
