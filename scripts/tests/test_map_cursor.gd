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
	d.class_id = "soldier"
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
	gs_script.source_code = "extends Node\nconst CampaignRulesScript = preload(\"res://scripts/resources/CampaignRules.gd\")\nvar all_units: Array[Node] = []\nvar map_data = null\nvar campaign_rules = CampaignRulesScript.make_default()\nfunc get_living_player_units() -> Array[Node]: return all_units\nfunc get_living_units_of(faction_id: String) -> Array[Node]:\n\tvar out: Array[Node] = []\n\tfor unit in all_units:\n\t\tif unit != null and unit.team == faction_id and unit.data != null and unit.data.hp > 0:\n\t\t\tout.append(unit)\n\treturn out\nfunc is_player_turn() -> bool: return true\nfunc find_unit_by_id(unit_id: String) -> Node:\n\tfor unit in all_units:\n\t\tif unit != null and unit.data != null and unit.data.unit_id == unit_id:\n\t\t\treturn unit\n\treturn null\n"
	gs_script.reload()
	_gs = gs_script.new()
	_gs.name = "GameState"
	root.add_child(_gs)
	var pair_reg: Node = load("res://scripts/autoloads/PairUpRegistry.gd").new()
	pair_reg.name = "PairUpRegistry"
	root.add_child(pair_reg)
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

	# ---- cancel_transient_control_for_handoff backs out an uncommitted move ----
	var t_cleanup := TurnManager.new()
	root.add_child(t_cleanup)
	var c_cleanup := _make_cursor(t_cleanup)
	var cleanup_unit := _make_unit(Vector2i(1, 1), "blue")
	t_cleanup.record_move_start(cleanup_unit)
	cleanup_unit.snap_to_tile(Vector2i(2, 1))
	c_cleanup._selection.selected_unit = cleanup_unit
	c_cleanup._state = UNIT_MOVED
	var cleanup_menu := Control.new()
	cleanup_menu.show()
	root.add_child(cleanup_menu)
	c_cleanup.action_menu = cleanup_menu
	c_cleanup.cancel_transient_control_for_handoff()
	var cleanup_ok: bool = c_cleanup._state == FREE \
		and c_cleanup._selection.selected_unit == null \
		and cleanup_unit.tile_position == Vector2i(1, 1) \
		and not cleanup_menu.visible \
		and not c_cleanup._input_suppressed
	if cleanup_ok:
		print("OK  controller handoff cleanup hides menus and undoes an uncommitted move")
		passed += 1
	else:
		print("FAIL handoff cleanup: state=%d selected=%s tile=%s menu=%s suppressed=%s" % [
			c_cleanup._state, c_cleanup._selection.selected_unit,
			cleanup_unit.tile_position, cleanup_menu.visible, c_cleanup._input_suppressed])
		failed += 1
	cleanup_menu.queue_free()

	# ---- _on_phase_changed: ENEMY locks, PLAYER unlocks, controlling faction follows phase ----
	c1.set_controlling_faction("green")
	c1._on_phase_changed(1, "green")  # GameState.Phase.ENEMY
	var locked_on_enemy := c1._state == LOCKED
	c1._on_phase_changed(0, "blue")  # GameState.Phase.PLAYER
	if locked_on_enemy and c1._state == FREE and c1._controlling_faction == "blue":
		print("OK  _on_phase_changed: ENEMY → LOCKED, PLAYER → FREE, control returns to blue")
		passed += 1
	else:
		print("FAIL _on_phase_changed: locked_on_enemy=%s now=%d faction=%s" % [
			locked_on_enemy, c1._state, c1._controlling_faction])
		failed += 1

	# ---- Hotseat menu close/cancel unlocks because green is still locally controlled ----
	var hot_tm := TurnManager.new()
	root.add_child(hot_tm)
	var hot_md := MapData.new()
	var hot_green := FactionData.new()
	hot_green.id = "green"
	hot_green.controller = "HOTSEAT"
	hot_md.factions = [hot_green]
	hot_tm._map_data = hot_md
	hot_tm._turn_order = ["green"]
	hot_tm._active_faction_idx = 0
	var c_hot := _make_cursor(hot_tm)
	c_hot.lock()
	c_hot._on_map_menu_closed()
	var closed_unlocks: bool = c_hot._state == FREE
	c_hot.lock()
	c_hot._on_quit_to_menu_requested()
	await process_frame
	var hot_dlg: ConfirmationDialog = null
	for ch in root.get_children():
		if ch is ConfirmationDialog:
			hot_dlg = ch
	if hot_dlg != null:
		hot_dlg.canceled.emit()
		hot_dlg.queue_free()
	await process_frame
	var cancel_unlocks: bool = c_hot._state == FREE
	if closed_unlocks and cancel_unlocks:
		print("OK  hotseat menu close and quit-cancel unlock the cursor for local non-blue control")
		passed += 1
	else:
		print("FAIL hotseat unlock: close=%s cancel=%s state=%d" % [
			closed_unlocks, cancel_unlocks, c_hot._state])
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
	stub_menu.scale = Vector2.ONE * 2.0
	c1._place_menu_near(stub_menu, Vector2i(5, 5))
	var scaled_size: Vector2 = stub_menu.size * stub_menu.scale
	var scaled_ok: bool = (stub_menu.position.x >= 0
			and stub_menu.position.y >= 0
			and stub_menu.position.x + scaled_size.x <= view.x
			and stub_menu.position.y + scaled_size.y <= view.y)
	if top_left_ok and bottom_right_ok and scaled_ok:
		print("OK  _place_menu_near keeps menu inside viewport (playtest 3 #4)")
		passed += 1
	else:
		print("FAIL _place_menu_near: top_left=%s bottom_right=%s scaled=%s pos=%s view=%s" % [
			top_left_ok, bottom_right_ok, scaled_ok, stub_menu.position, view])
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
	# Save state lives on the CameraController now (B4); per-faction keys (code
	# review 2026-06-09) — the outgoing faction was blue, so the save lands
	# under "blue".
	var saved_ok: bool = c1._camera_ctrl._saved_positions.get("blue", Vector2.INF) == saved_view
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

	# ---- multi-faction phase transitions don't clobber blue's saved view ----
	# Code review 2026-06-09: with hotseat (blue → green → red → blue) every
	# Phase.ENEMY transition fired save_view. The green→red hop overwrote
	# blue's saved view, so when blue resumed the camera restored to green's
	# last position. Per-faction keys keep each save independent.
	_grid.map_width = 30
	_grid.map_height = 30
	c1.set_controlling_faction("blue")
	c1._set_tile(Vector2i(15, 15))
	c1._scroll_camera_if_needed()
	var blue_view: Vector2 = c1._camera.position
	# Blue → green (hotseat). Save lands under outgoing "blue".
	c1._on_phase_changed(1, "green")
	# Green pans somewhere very different, then green ends → red.
	c1._camera.position = Vector2(4_000, 4_000)
	c1._on_phase_changed(1, "red")  # save under outgoing "green", NOT "blue"
	# Red pans even further, then red ends → blue.
	c1._camera.position = Vector2(8_000, 8_000)
	c1._on_phase_changed(0, "blue")  # restore "blue"'s view
	var multi_restore_ok: bool = c1._camera.position == blue_view
	# Per-faction memory: simulate going back to green and verify green's
	# saved-position is still its own value, not blue's.
	c1.set_controlling_faction("green")
	c1._camera.position = Vector2.ZERO
	var green_restored: bool = c1._camera_ctrl.restore_view("green")
	var green_view_ok: bool = green_restored and c1._camera.position == Vector2(4_000, 4_000)
	_grid.map_width = pt4_saved_w
	_grid.map_height = pt4_saved_h
	c1.set_controlling_faction("blue")
	if multi_restore_ok and green_view_ok:
		print("OK  multi-faction camera save/restore keeps each faction's view separate")
		passed += 1
	else:
		print("FAIL multi-faction camera: blue_restore_ok=%s green_view_ok=%s" % [
			multi_restore_ok, green_view_ok])
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
	var p_unit := _make_unit(Vector2i(2, 2), "blue")
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

	# ---- V021-16: FREE + cancel over an unselected unit → opens its sheet ----
	_gs.all_units.clear()
	var t_v16 := TurnManager.new(); root.add_child(t_v16)
	var c_v16 := _make_cursor(t_v16)
	var details_script := GDScript.new()
	details_script.source_code = "extends Node\nsignal closed\nvar opened_unit = null\nfunc open(u): opened_unit = u\n"
	details_script.reload()
	c_v16.unit_details = details_script.new()
	root.add_child(c_v16.unit_details)
	var v16_unit := _make_unit(Vector2i(3, 3), "blue")
	c_v16._set_tile(Vector2i(3, 3))
	c_v16._on_cancel()  # FREE + cancel while hovering an unselected unit
	if c_v16.unit_details.opened_unit == v16_unit:
		print("OK  V021-16 FREE + cancel over an unselected unit opens its sheet")
		passed += 1
	else:
		print("FAIL V021-16 sheet: opened=%s" % str(c_v16.unit_details.opened_unit))
		failed += 1
	# Cancel on an empty tile still opens the map menu, not the sheet.
	c_v16.unit_details.opened_unit = null
	c_v16.map_menu = map_menu_script.new()
	root.add_child(c_v16.map_menu)
	c_v16._set_tile(Vector2i(5, 5))  # empty
	c_v16._on_cancel()
	if c_v16.map_menu.opened and c_v16.unit_details.opened_unit == null:
		print("OK  V021-16 FREE + cancel on empty tile still opens the map menu")
		passed += 1
	else:
		print("FAIL V021-16 empty: menu=%s sheet=%s" % [
			c_v16.map_menu.opened, str(c_v16.unit_details.opened_unit)])
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
	_make_unit(Vector2i(3, 3), "red")
	c3._set_tile(Vector2i(3, 3))
	c3._on_confirm()
	if c3._state == FREE and c3._selection.selected_unit == null:
		print("OK  FREE + confirm on enemy unit → stays FREE (not selectable)")
		passed += 1
	else:
		print("FAIL confirm-enemy: _state=%d" % c3._state)
		failed += 1

	# ---- set_controlling_faction retargets selection to the new faction ----
	_gs.all_units.clear()
	var t3b := TurnManager.new(); root.add_child(t3b)
	var c3b := _make_cursor(t3b)
	_make_unit(Vector2i(1, 1), "blue")
	var green_unit := _make_unit(Vector2i(2, 2), "green")
	c3b.set_controlling_faction("green")
	c3b._set_tile(Vector2i(2, 2))
	c3b._on_confirm()
	if c3b._state == UNIT_SELECTED and c3b._selection.selected_unit == green_unit:
		print("OK  set_controlling_faction retargets selection to the new faction")
		passed += 1
	else:
		print("FAIL set_controlling_faction select: _state=%d selected=%s" % [
			c3b._state, str(c3b._selection.selected_unit)])
		failed += 1

	# ---- FREE + confirm on an already-acted unit → stays FREE ----
	_gs.all_units.clear()
	var t4 := TurnManager.new(); root.add_child(t4)
	var c4 := _make_cursor(t4)
	var acted := _make_unit(Vector2i(1, 1), "blue")
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
	var waiter := _make_unit(Vector2i(0, 0), "blue")
	c5._selection.selected_unit = waiter
	c5._state = UNIT_MOVED
	# B1-PKGA Slice 1d: a committed Wait must advance the RNG chain (RNG-1/RNG-3
	# Wait-to-reroll). This suite runs with the REAL RngService autoload.
	var rng_svc := root.get_node_or_null("/root/RngService")
	rng_svc.start_map(4242)
	var wait_hash_before: int = rng_svc.history_hash
	c5._on_action_chosen("wait")
	if c5._state == FREE and c5._selection.selected_unit == null \
			and t5.get_unit_state(waiter) == TurnManager.UnitState.DONE:
		print("OK  action 'wait' → FREE and the unit is marked DONE")
		passed += 1
	else:
		print("FAIL wait: _state=%d selected=%s unit_state=%d" \
			% [c5._state, str(c5._selection.selected_unit), t5.get_unit_state(waiter)])
		failed += 1
	if rng_svc.history_hash != wait_hash_before:
		print("OK  1d: a committed Wait advances the RNG chain")
		passed += 1
	else:
		print("FAIL 1d: Wait did not advance history_hash")
		failed += 1

	# ---- T4 equip neutrality: the weapon-swap flow never touches the chain ----
	# Equip is free and repeatable mid-turn; if it ever committed an RNG event it
	# would be an infinite zero-cost reroll crank (design §4 "Never advances").
	# A stub ActionMenu is required: with action_menu null, _show_action_menu's
	# headless fallback commits a Wait, which is NOT the production equip path.
	var equip_menu_script := GDScript.new()
	equip_menu_script.source_code = "extends Control\nsignal action_chosen(a)\nsignal hidden_by_cancel\nfunc show_for(_u, _tile, _g): pass\n"
	equip_menu_script.reload()
	c5.action_menu = equip_menu_script.new()
	root.add_child(c5.action_menu)
	var equipper := _make_unit(Vector2i(3, 0), "blue")
	equipper.data.inventory = [InventoryEntry.make_weapon("iron_sword", 10)]
	c5._selection.selected_unit = equipper
	var equip_hash_before: int = rng_svc.history_hash
	c5._on_weapon_chosen(equipper.data.inventory[0])
	c5._on_weapon_chosen(equipper.data.inventory[0])  # repeat swap — still free
	c5._selection.selected_unit = null
	if rng_svc.history_hash == equip_hash_before:
		print("OK  1d/T4: equip swaps never advance the RNG chain")
		passed += 1
	else:
		print("FAIL 1d/T4: equip advanced history_hash")
		failed += 1

	# ---- _finish_action liveness guard: a dead unit is NOT written into _unit_states ----
	# Regression for code review 2026-05-16d — a unit that died mid-action must not be
	# re-inserted into TurnManager._unit_states as a stale freed-node key.
	_gs.all_units.clear()
	var t6 := TurnManager.new(); root.add_child(t6)
	var c6 := _make_cursor(t6)
	var dead := _make_unit(Vector2i(0, 0), "blue", 0)  # hp 0 → dead
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
	var mover := _make_unit(Vector2i(2, 2), "blue")
	c7._selection.selected_unit = mover
	c7._state = UNIT_MOVED
	# W6f: park the cursor on the post-move tile so the snap-back is observable.
	c7._set_tile(Vector2i(5, 5))
	c7._undo_move_and_reselect()
	if c7._state == UNIT_SELECTED:
		print("OK  _undo_move_and_reselect: UNIT_MOVED → UNIT_SELECTED")
		passed += 1
	else:
		print("FAIL undo-reselect: _state=%d" % c7._state)
		failed += 1
	# W6f: cursor must snap back onto the acting unit's pre-move tile so the
	# player isn't stranded on the cancelled destination.
	if c7.current_tile == Vector2i(2, 2):
		print("OK  W6f _undo_move_and_reselect snaps cursor to acting unit")
		passed += 1
	else:
		print("FAIL W6f undo-cursor: tile=%s" % str(c7.current_tile))
		failed += 1

	# ---- _on_targeting_cancelled → UNIT_MOVED (ActionMenu reopens) ----
	_gs.all_units.clear()
	var t8 := TurnManager.new(); root.add_child(t8)
	var c8 := _make_cursor(t8)
	var menu_script := GDScript.new()
	menu_script.source_code = "extends Control\nsignal action_chosen(a)\nsignal hidden_by_cancel\nfunc show_for(_u, _tile, _g): pass\n"
	menu_script.reload()
	c8.action_menu = menu_script.new()
	root.add_child(c8.action_menu)
	c8._selection.selected_unit = _make_unit(Vector2i(1, 1), "blue")
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
	_make_unit(Vector2i(0, 0), "blue")
	_make_unit(Vector2i(2, 2), "blue")
	_make_unit(Vector2i(4, 4), "blue")
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

	# ---- [TUR] threat watch-set + danger-mode resolver (B6-MRD slice 2, #12/#13) ----
	_gs.all_units.clear()
	var t10 := TurnManager.new(); root.add_child(t10)
	var c10 := _make_cursor(t10)
	c10._state = FREE
	var enemyA := _make_unit(Vector2i(1, 1), "red"); enemyA.data.unit_id = "enemyA"
	var enemyB := _make_unit(Vector2i(4, 4), "red"); enemyB.data.unit_id = "enemyB"
	var ally1 := _make_unit(Vector2i(2, 2), "blue"); ally1.data.unit_id = "ally1"

	# Press routing: MMB over empty terrain cycles the mode (start none→full).
	c10.current_tile = Vector2i(5, 0)
	c10._on_danger_zone_press()
	var route_cycle := c10._danger_mode == "full" and c10._watch_set.is_empty()

	# MMB over a hostile enemy edits the watch set + auto-promote/demote.
	c10._danger_mode = "none"; c10._watch_set.clear()
	c10.current_tile = enemyA.tile_position
	c10._on_danger_zone_press()
	var added := c10._watch_set.has("enemyA")
	var promoted := c10._danger_mode == "selected"          # none→selected on first add
	c10._on_danger_zone_press()
	var removed := not c10._watch_set.has("enemyA")
	var demoted := c10._danger_mode == "none"               # selected→none on last remove
	if route_cycle and added and promoted and removed and demoted:
		print("OK  [TUR] resolver: empty cycles mode; enemy edits watch-set + auto-promote/demote"); passed += 1
	else:
		print("FAIL [TUR] resolver: cycle=%s add=%s promo=%s rm=%s demo=%s" % [
			route_cycle, added, promoted, removed, demoted]); failed += 1

	# Two-member watch set: threat union + a "D" marker on each watched tile.
	c10._danger_mode = "none"; c10._watch_set.clear()
	c10.current_tile = enemyA.tile_position; c10._on_danger_zone_press()
	c10.current_tile = enemyB.tile_position; c10._on_danger_zone_press()
	var two_members := c10._watch_set.size() == 2
	var watch_tiles := c10._watch_set_threat_tiles()
	var union_ok := watch_tiles.has(Vector2i(0, 1)) and watch_tiles.has(Vector2i(3, 4))
	var markers := c10._watched_marker_tiles()
	var marker_ok := markers.has(Vector2i(1, 1)) and markers.has(Vector2i(4, 4))
	if two_members and union_ok and marker_ok:
		print("OK  [TUR] two-member watch set unions threat + marks both tiles"); passed += 1
	else:
		print("FAIL [TUR] watch set: n=%d union=%s markers=%s" % [
			c10._watch_set.size(), union_ok, marker_ok]); failed += 1

	# full→combined on first add; combined→full on last remove (faction layer kept).
	c10._danger_mode = "full"; c10._watch_set.clear()
	c10.current_tile = enemyA.tile_position; c10._on_danger_zone_press()
	var full_to_combined := c10._danger_mode == "combined"
	c10.current_tile = enemyA.tile_position; c10._on_danger_zone_press()
	var combined_to_full := c10._danger_mode == "full" and c10._watch_set.is_empty()
	if full_to_combined and combined_to_full:
		print("OK  [TUR] auto-promote full→combined, demote combined→full"); passed += 1
	else:
		print("FAIL [TUR] full/combined: f2c=%s c2f=%s" % [full_to_combined, combined_to_full]); failed += 1

	# Manual mode cycle over empty terrain: full→selected→combined→none→full.
	c10._danger_mode = "full"; c10._watch_set.clear()
	c10.current_tile = Vector2i(5, 0)
	c10._on_danger_zone_press(); var m1 := c10._danger_mode
	c10._on_danger_zone_press(); var m2 := c10._danger_mode
	c10._on_danger_zone_press(); var m3 := c10._danger_mode
	c10._on_danger_zone_press(); var m4 := c10._danger_mode
	if m1 == "selected" and m2 == "combined" and m3 == "none" and m4 == "full":
		print("OK  [TUR] mode cycles full→selected→combined→none→full"); passed += 1
	else:
		print("FAIL [TUR] cycle: %s→%s→%s→%s" % [m1, m2, m3, m4]); failed += 1

	# Prune-on-death: a watched enemy dying is removed + auto-demotes if last.
	c10._danger_mode = "none"; c10._watch_set.clear()
	c10.current_tile = enemyA.tile_position; c10._on_danger_zone_press()  # {enemyA}, selected
	enemyA.data.hp = 0
	c10._on_unit_died(enemyA)
	var pruned := not c10._watch_set.has("enemyA")
	var death_demote := c10._danger_mode == "none"
	if pruned and death_demote:
		print("OK  [TUR] prune-on-death removes the watched enemy + auto-demotes"); passed += 1
	else:
		print("FAIL [TUR] prune-on-death: pruned=%s demote=%s" % [pruned, death_demote]); failed += 1
	enemyA.data.hp = 20

	# Persistence: teardown clears the paint but RETAINS _watch_set + _danger_mode.
	c10._danger_mode = "combined"; c10._watch_set.clear(); c10._watch_set["enemyB"] = true
	c10._clear_overlay_paint()
	var retained := c10._danger_mode == "combined" and c10._watch_set.has("enemyB")
	c10._state = FREE
	c10.repaint()  # return to FREE recomputes without error
	if retained:
		print("OK  [TUR] teardown clears paint but retains watch-set + mode"); passed += 1
	else:
		print("FAIL [TUR] state not retained through teardown"); failed += 1

	# FREE-state gating (#13): the resolver is a no-op outside FREE.
	c10._danger_mode = "none"; c10._watch_set.clear()
	c10._state = UNIT_SELECTED
	c10.current_tile = enemyB.tile_position
	c10._on_danger_zone_press()
	if c10._watch_set.is_empty() and c10._danger_mode == "none":
		print("OK  [TUR] danger-zone resolver ignored while a unit is selected (#13)"); passed += 1
	else:
		print("FAIL [TUR] resolver not gated outside FREE"); failed += 1

	# ---- Simulated gamepad R3 routing (gamepad plan §4 slice 4, engine side) ----
	# The real project.godot joypad bindings land with gamepad slice 1; here we
	# bind R3 → show_danger_zone at test runtime and prove _input routes a raw
	# InputEventJoypadButton through the same resolver as Q/MMB (the key/mouse
	# type gates used to silently drop all pad events).
	var r3_bind := InputEventJoypadButton.new()
	r3_bind.button_index = JOY_BUTTON_RIGHT_STICK
	r3_bind.device = -1
	InputMap.action_add_event("show_danger_zone", r3_bind)
	var r3_press := InputEventJoypadButton.new()
	r3_press.button_index = JOY_BUTTON_RIGHT_STICK
	r3_press.pressed = true

	# R3 over empty terrain cycles the mode.
	c10._state = FREE
	c10._danger_mode = "none"; c10._watch_set.clear()
	c10.current_tile = Vector2i(5, 0)
	c10._input(r3_press)
	var pad_cycle := c10._danger_mode == "full" and c10._watch_set.is_empty()

	# R3 over a hostile enemy toggles watch membership with auto-promote/demote.
	c10._danger_mode = "none"; c10._watch_set.clear()
	c10.current_tile = enemyA.tile_position
	c10._input(r3_press)
	var pad_added := c10._watch_set.has("enemyA") and c10._danger_mode == "selected"
	c10._input(r3_press)
	var pad_removed := not c10._watch_set.has("enemyA") and c10._danger_mode == "none"

	# An R3 RELEASE (pressed=false) must not fire the resolver.
	var r3_release := InputEventJoypadButton.new()
	r3_release.button_index = JOY_BUTTON_RIGHT_STICK
	r3_release.pressed = false
	c10._input(r3_release)
	var pad_release_inert := c10._watch_set.is_empty() and c10._danger_mode == "none"

	# Suppressed input (menu open etc.) swallows pad presses like key/mouse.
	c10._input_suppressed = true
	c10._input(r3_press)
	var pad_suppressed := c10._watch_set.is_empty() and c10._danger_mode == "none"
	c10._input_suppressed = false
	if pad_cycle and pad_added and pad_removed and pad_release_inert and pad_suppressed:
		print("OK  [PAD] simulated R3 routes through the danger-zone resolver (cycle/toggle/release/suppress)"); passed += 1
	else:
		print("FAIL [PAD] R3 routing: cycle=%s add=%s rm=%s release=%s suppress=%s" % [
			pad_cycle, pad_added, pad_removed, pad_release_inert, pad_suppressed]); failed += 1
	InputMap.action_erase_event("show_danger_zone", r3_bind)

	# Pad peek parity: a pad-bound peek_range press arms the peek, release ends
	# it (the pad button choice is test-local; peek's real pad home is undecided).
	var peek_bind := InputEventJoypadButton.new()
	peek_bind.button_index = JOY_BUTTON_LEFT_STICK
	peek_bind.device = -1
	InputMap.action_add_event("peek_range", peek_bind)
	var peek_press := InputEventJoypadButton.new()
	peek_press.button_index = JOY_BUTTON_LEFT_STICK
	peek_press.pressed = true
	var peek_release := InputEventJoypadButton.new()
	peek_release.button_index = JOY_BUTTON_LEFT_STICK
	peek_release.pressed = false
	c10.current_tile = enemyA.tile_position
	c10._input(peek_press)
	var pad_peek_on := c10._peek_active and not c10._peek_move.is_empty()
	c10._input(peek_release)
	var pad_peek_off := not c10._peek_active and c10._peek_move.is_empty()
	if pad_peek_on and pad_peek_off:
		print("OK  [PAD] simulated pad peek_range press arms hover-peek, release clears it"); passed += 1
	else:
		print("FAIL [PAD] pad peek: on=%s off=%s" % [pad_peek_on, pad_peek_off]); failed += 1
	InputMap.action_erase_event("peek_range", peek_bind)

	# ---- [MRD-2] hover-to-peek range (B6-MRD slice 3) ----
	c10._danger_mode = "none"; c10._watch_set.clear()
	c10._state = FREE
	c10.current_tile = enemyA.tile_position
	c10._begin_peek()
	var peek_on := c10._peek_active and not c10._peek_move.is_empty()
	var count_after_press := c10._peek_compute_count
	c10._refresh_peek()                                  # same unit → cache hit
	var cache_hit := c10._peek_compute_count == count_after_press
	c10.current_tile = enemyB.tile_position
	c10._on_cursor_moved_overlays(enemyB.tile_position)  # new unit → recompute
	var recomputed := c10._peek_compute_count == count_after_press + 1 and c10._peek_unit == enemyB
	c10._end_peek()
	var peek_off := not c10._peek_active and c10._peek_move.is_empty()
	if peek_on and cache_hit and recomputed and peek_off:
		print("OK  [MRD-2] hover-peek: press paints reach, same-unit cache-hit, new-unit recompute, release clears"); passed += 1
	else:
		print("FAIL [MRD-2] peek: on=%s hit=%s recompute=%s off=%s" % [peek_on, cache_hit, recomputed, peek_off]); failed += 1

	c10._state = UNIT_SELECTED
	c10._begin_peek()
	if not c10._peek_active:
		print("OK  [MRD-2] hover-peek ignored outside FREE state"); passed += 1
	else:
		print("FAIL [MRD-2] peek armed outside FREE"); failed += 1
	c10._state = FREE

	c10.current_tile = enemyA.tile_position
	c10._begin_peek()
	var stale_count := c10._peek_compute_count
	c10._state = UNIT_SELECTED
	c10.current_tile = enemyB.tile_position
	c10._on_cursor_moved_overlays(enemyB.tile_position)
	var stale_cancelled := not c10._peek_active \
		and c10._peek_move.is_empty() \
		and c10._peek_attack.is_empty() \
		and c10._peek_compute_count == stale_count
	c10._state = FREE
	c10.current_tile = enemyA.tile_position
	c10._begin_peek()
	c10.current_tile = ally1.tile_position
	c10._try_select_unit_at_cursor()
	var select_cleared_peek := c10._state == UNIT_SELECTED \
		and c10._selection.selected_unit == ally1 \
		and not c10._peek_active \
		and c10._peek_move.is_empty() \
		and c10._peek_attack.is_empty()
	c10._deselect()
	if stale_cancelled and select_cleared_peek:
		print("OK  [MRD-2] hover-peek cancels cleanly when FREE control hands off to selection")
		passed += 1
	else:
		print("FAIL [MRD-2] peek handoff: stale=%s select=%s" % [
			stale_cancelled, select_cleared_peek])
		failed += 1

	var saved_overlay := _grid._overlay
	var finish_overlay := TileMapLayer.new()
	finish_overlay.tile_set = load("res://assets/overlay_tileset.tres")
	_grid._overlay = finish_overlay
	c10._danger_mode = "selected"
	c10._watch_set.clear()
	c10._watch_set["enemyA"] = true
	c10._selection.selected_unit = ally1
	c10._state = UNIT_MOVED
	c10._finish_action()
	var finish_repainted := c10._state == FREE \
		and c10._selection.selected_unit == null \
		and finish_overlay.get_cell_source_id(Vector2i(0, 1)) == GridManager.OVERLAY_DARKER_RED
	_grid._overlay = saved_overlay
	finish_overlay.free()
	if finish_repainted:
		print("OK  [TUR] committed actions restore retained watched-threat overlay")
		passed += 1
	else:
		print("FAIL [TUR] finish action did not repaint retained watched-threat overlay")
		failed += 1

	# ---- movement path arrows (B6-MRD slice 4) ----
	_gs.all_units.clear()
	var t_pa := TurnManager.new(); root.add_child(t_pa)
	var c_pa := _make_cursor(t_pa)
	var pa_mover := _make_unit(Vector2i(0, 0), "blue"); pa_mover.data.unit_id = "mover"
	c_pa._selection.selected_unit = pa_mover         # inject a selection
	c_pa._state = UNIT_SELECTED
	c_pa.current_tile = Vector2i(2, 0)
	c_pa._refresh_path_arrows()
	var pa_path := c_pa._path_arrow_tiles
	var pa_dirs := c_pa._path_arrow_directions()
	var ref_path := _grid.get_movement_path(pa_mover, Vector2i(2, 0))
	var path_ends_ok := pa_path.size() >= 2 and pa_path[0] == Vector2i(0, 0) \
		and pa_path[pa_path.size() - 1] == Vector2i(2, 0)
	var dirs_ok := pa_dirs.size() == ref_path.size() - 1 and pa_path == ref_path
	var all_cardinal := true
	for d in pa_dirs:
		if absi(d.x) + absi(d.y) != 1:
			all_cardinal = false
	# Recompute follows the cursor to a new tile ([MRD-4] B — cheap path only).
	c_pa.current_tile = Vector2i(3, 1)
	c_pa._on_cursor_moved_overlays(Vector2i(3, 1))
	var followed := c_pa._path_arrow_tiles.size() >= 2 \
		and c_pa._path_arrow_tiles[c_pa._path_arrow_tiles.size() - 1] == Vector2i(3, 1)
	# Clears when no unit is selected.
	c_pa._state = FREE
	c_pa._refresh_path_arrows()
	var pa_cleared := c_pa._path_arrow_tiles.is_empty()
	if path_ends_ok and dirs_ok and all_cardinal and followed and pa_cleared:
		print("OK  [MRD] path arrows track get_movement_path to the cursor; clear when unselected"); passed += 1
	else:
		print("FAIL [MRD] path arrows: ends=%s dirs=%s cardinal=%s follow=%s cleared=%s" % [
			path_ends_ok, dirs_ok, all_cardinal, followed, pa_cleared]); failed += 1

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
	c11._selection.selected_unit = _make_unit(Vector2i(2, 2), "blue")
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
	_make_unit(Vector2i(0, 0), "blue")   # an actable unit → the confirm prompt
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

	# ---- end-turn routes through are_all_units_done(active_faction) + request_end_phase ----
	var tm_end_script := GDScript.new()
	tm_end_script.source_code = "extends \"res://scripts/core/TurnManager.gd\"\nvar last_faction := \"\"\nvar request_calls := 0\nfunc active_faction() -> String:\n\treturn \"green\"\nfunc are_all_units_done(faction_id: String) -> bool:\n\tlast_faction = faction_id\n\treturn true\nfunc request_end_phase() -> void:\n\trequest_calls += 1\n"
	tm_end_script.reload()
	var t_end: TurnManager = tm_end_script.new()
	root.add_child(t_end)
	var c_end := _make_cursor(t_end)
	c_end._on_end_turn_requested()
	if t_end.get("last_faction") == "green" and t_end.get("request_calls") == 1:
		print("OK  end-turn uses the active faction and routes through request_end_phase")
		passed += 1
	else:
		print("FAIL end-turn routing: faction=%s calls=%s" % [
			t_end.get("last_faction"), t_end.get("request_calls")])
		failed += 1

	# ---- Unit.set_equipped_weapon reorders the inventory (#8) ----
	var swap_unit := _make_unit(Vector2i(0, 0), "blue")
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

	# ---- W4a: pair creation marks both lead and support DONE so the phase can
	# auto-end. The support is hidden after pairing — without an explicit DONE,
	# the turn manager would still see an actionable unit and refuse to advance.
	var tm_pair := TurnManager.new(); root.add_child(tm_pair)
	var c_pair := _make_cursor(tm_pair)
	var pc_lead := _make_unit(Vector2i(1, 1), "blue")
	var pc_support := _make_unit(Vector2i(1, 2), "blue")
	pc_lead.data.unit_id = "pc_lead"
	pc_support.data.unit_id = "pc_support"
	var pair_reg_pc := root.get_node_or_null("PairUpRegistry")
	pair_reg_pc.call("clear")
	c_pair._selection.selected_unit = pc_lead
	c_pair._state = UNIT_MOVED
	c_pair._on_pair_up_resolved(pc_lead, pc_support)
	var pair_create_ok: bool = pair_reg_pc.call("is_paired", "pc_lead") \
		and pair_reg_pc.call("is_paired", "pc_support") \
		and tm_pair.get_unit_state(pc_lead) == TurnManager.UnitState.DONE \
		and tm_pair.get_unit_state(pc_support) == TurnManager.UnitState.DONE \
		and c_pair._state == FREE
	if pair_create_ok:
		print("OK  W4a: pair creation marks lead and support DONE so auto-end is not blocked")
		passed += 1
	else:
		print("FAIL W4a pair create: paired_lead=%s paired_support=%s lead_state=%s support_state=%s state=%d" % [
			pair_reg_pc.call("is_paired", "pc_lead"),
			pair_reg_pc.call("is_paired", "pc_support"),
			tm_pair.get_unit_state(pc_lead),
			tm_pair.get_unit_state(pc_support),
			c_pair._state])
		failed += 1

	# ---- Swap flips roles AND physically swaps the pair (playtest v0.1.4 #2) ----
	# Set up a realistic paired state via _on_pair_up_resolved so the support is
	# off-map and hidden, exactly as it is mid-game. The bug was that Swap only
	# flipped the registry role labels, leaving the on-map unit in place and the
	# hidden off-map unit tagged "lead". Assert the new lead (old support) now
	# holds the on-map tile and is visible, and the old lead is off-map + hidden.
	var OFF_MAP_TILE: Vector2i = load("res://scripts/autoloads/PairUpRegistry.gd").OFF_MAP_TILE
	var tm_swap := TurnManager.new(); root.add_child(tm_swap)
	var c_swap := _make_cursor(tm_swap)
	var on_map_tile := Vector2i(1, 1)
	var pair_lead := _make_unit(on_map_tile, "blue")
	var pair_support := _make_unit(Vector2i(1, 2), "blue")
	pair_lead.data.unit_id = "lead"
	pair_support.data.unit_id = "support"
	var pair_reg_live := root.get_node_or_null("PairUpRegistry")
	pair_reg_live.call("clear")
	# Pair through the real flow: support goes to OFF_MAP_TILE + visible=false.
	c_swap._selection.selected_unit = pair_lead
	c_swap._state = UNIT_MOVED
	c_swap._on_pair_up_resolved(pair_lead, pair_support)
	# Now swap. selected_unit was cleared by pairing's _finish_action; re-arm it.
	c_swap._selection.selected_unit = pair_lead
	c_swap._state = UNIT_MOVED
	c_swap._commit_swap_roles()
	var swap_roles_ok: bool = pair_reg_live.call("is_support", "lead") \
		and pair_reg_live.call("is_lead", "support") \
		and tm_swap.get_unit_state(pair_lead) == TurnManager.UnitState.DONE \
		and tm_swap.get_unit_state(pair_support) == TurnManager.UnitState.DONE \
		and c_swap._state == FREE
	# The physical swap is the actual regression guard:
	var swap_positions_ok: bool = pair_support.tile_position == on_map_tile \
		and pair_support.visible \
		and pair_lead.tile_position == OFF_MAP_TILE \
		and not pair_lead.visible
	if swap_roles_ok and swap_positions_ok:
		print("OK  Swap flips roles, swaps positions/visibility, and spends both units")
		passed += 1
	else:
		print("FAIL swap: roles_ok=%s pos_ok=%s | support@%s vis=%s lead@%s vis=%s" % [
			swap_roles_ok, swap_positions_ok,
			pair_support.tile_position, pair_support.visible,
			pair_lead.tile_position, pair_lead.visible])
		failed += 1

	# ---- Swap with an unresolvable partner does NOT flip roles (review #2) ----
	# Defensive guard: if the partner Node can't be resolved, _commit_swap_roles must
	# bail BEFORE swap_roles(), so the registry is never left with roles flipped but
	# positions unswapped (an on-map unit tagged "support"). Pair the lead with a
	# partner id that has no registered Unit node.
	var tm_orphan := TurnManager.new(); root.add_child(tm_orphan)
	var c_orphan := _make_cursor(tm_orphan)
	var orphan_lead := _make_unit(Vector2i(2, 2), "blue")
	orphan_lead.data.unit_id = "orphan_lead"
	pair_reg_live.call("clear")
	pair_reg_live.call("pair", "orphan_lead", "ghost_partner")   # ghost has no Unit node
	c_orphan._selection.selected_unit = orphan_lead
	c_orphan._state = UNIT_MOVED
	c_orphan._commit_swap_roles()
	# Roles must be unchanged (lead still lead), the unit stays on its tile + visible.
	var orphan_no_flip: bool = pair_reg_live.call("is_lead", "orphan_lead") \
		and orphan_lead.tile_position == Vector2i(2, 2) and orphan_lead.visible \
		and c_orphan._state == FREE
	if orphan_no_flip:
		print("OK  Swap with an unresolvable partner bails without flipping roles (review #2)")
		passed += 1
	else:
		print("FAIL swap orphan: is_lead=%s tile=%s vis=%s state=%d" % [
			pair_reg_live.call("is_lead", "orphan_lead"),
			orphan_lead.tile_position, orphan_lead.visible, c_orphan._state])
		failed += 1

	# ---- PT4 #1 / V021-17: mouse_cursor gates hover; click mode relocates then confirms ----
	# Drive _handle_mouse_motion directly with a synthesized event. The function
	# reads SettingsManager.mouse_cursor and only lets follow mode move on hover.
	# Click mode then uses the left button as first-click relocate, second-click confirm.
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

		sm_mc.mouse_cursor = "click"
		c_mc._handle_mouse_motion(ev)
		var click_hover_stayed: bool = c_mc.current_tile == Vector2i(0, 0)

		sm_mc.mouse_cursor = "follow"
		c_mc._handle_mouse_motion(ev)
		var moved: bool = c_mc.current_tile == Vector2i(4, 4)

		_gs.all_units.clear()
		var t_click := TurnManager.new(); root.add_child(t_click)
		var c_click := _make_cursor(t_click)
		var click_unit := _make_unit(Vector2i(4, 4), "blue")
		c_click._set_tile(Vector2i(0, 0))
		var click_ev := InputEventMouseButton.new()
		click_ev.button_index = MOUSE_BUTTON_LEFT
		click_ev.position = _grid.tile_to_world(Vector2i(4, 4))
		sm_mc.mouse_cursor = "click"
		c_click._handle_mouse_button(click_ev)
		var click_moved_only: bool = c_click.current_tile == Vector2i(4, 4) \
			and c_click._state == FREE and c_click._selection.selected_unit == null
		c_click._handle_mouse_button(click_ev)
		var click_confirmed: bool = c_click._state == UNIT_SELECTED \
			and c_click._selection.selected_unit == click_unit

		var hud_script := GDScript.new()
		hud_script.source_code = "extends Node\nvar cycles := 0\nfunc terrain_corner_contains_screen_position(_pos): return true\nfunc cycle_terrain_more_page(): cycles += 1\n"
		hud_script.reload()
		var hud_stub: Node = hud_script.new()
		hud_stub.add_to_group("hud")
		root.add_child(hud_stub)
		var t_panel := TurnManager.new(); root.add_child(t_panel)
		var c_panel := _make_cursor(t_panel)
		c_panel._set_tile(Vector2i(0, 0))
		c_panel._handle_mouse_button(click_ev)
		var terrain_click_ok: bool = hud_stub.cycles == 1 and c_panel.current_tile == Vector2i(0, 0)
		hud_stub.queue_free()

		# Mouse motion near the viewport edge should nudge the camera on large maps
		# instead of freezing camera follow entirely.
		sm_mc.mouse_cursor = "follow"
		var mouse_pan_w := _grid.map_width
		var mouse_pan_h := _grid.map_height
		_grid.map_width = 30
		_grid.map_height = 30
		c_mc._camera.position = _grid.tile_to_world(Vector2i(10, 10))
		var mouse_cam_before: Vector2 = c_mc._camera.position
		ev.position = Vector2(c_mc.get_viewport().get_visible_rect().size.x - 1.0, 64.0)
		c_mc._handle_mouse_motion(ev)
		var camera_panned: bool = c_mc._camera.position != mouse_cam_before
		_grid.map_width = mouse_pan_w
		_grid.map_height = mouse_pan_h

		sm_mc.mouse_cursor = "follow"  # restore default
		if stayed and click_hover_stayed and moved and click_moved_only and click_confirmed \
				and terrain_click_ok and camera_panned:
			print("OK  mouse_cursor disabled/click/follow modes gate hover, click-select, and terrain paging")
			passed += 1
		else:
			print("FAIL mouse_cursor modes: disabled_stayed=%s click_hover=%s moved=%s click_move=%s click_confirm=%s terrain=%s camera_panned=%s tile=%s" % [
				stayed, click_hover_stayed, moved, click_moved_only, click_confirmed,
				terrain_click_ok, camera_panned, str(c_mc.current_tile)])
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

	# V023-03 / V025-03 / V027-02: contextual menus remember their tile anchor and
	# re-anchor on zoom. Placement anchors to the tile's FAR edge plus a constant
	# 4px gap (AttackPreview's model): the tile-width term scales with zoom but the
	# gap beyond the edge does not, so the menu hugs the unit without covering it.
	# (The old V025-03 cap on the WHOLE offset left the menu inside the zoomed tile
	# at zoom > 1 — v0.2.7 §1.3.) The menu also keeps its chosen side across
	# repositions instead of flipping.
	var t_anchor := TurnManager.new(); root.add_child(t_anchor)
	var c_anchor := _make_cursor(t_anchor)
	var menu_anchor := Control.new()
	menu_anchor.size = Vector2(120, 80)
	menu_anchor.show()
	root.add_child(menu_anchor)
	c_anchor._camera.zoom = Vector2.ONE
	c_anchor._place_menu_near(menu_anchor, Vector2i(1, 1))
	# screen_pos is stub-fixed in this harness (the canvas transform ignores the
	# camera), so the anchor corner is the same at both zooms — only tile_px moves.
	var anchor_screen: Vector2 = c_anchor.get_viewport().canvas_transform \
		* _grid.tile_to_world(Vector2i(1, 1))
	var gap_1x: Vector2 = menu_anchor.position
	var side_1x: String = String(c_anchor._context_menu_anchor.get("side", ""))
	var edge_1x_ok: bool = absf(
		gap_1x.x - (anchor_screen.x + GameConstants.TILE_SIZE + 4.0)) <= 1.0
	# Zoom way in and reposition: the on-screen tile is 4× wide, so the menu must
	# sit fully clear of the ZOOMED tile rect, gap+ε past its far edge.
	c_anchor._camera.zoom = Vector2(4.0, 4.0)
	c_anchor._reposition_context_menu_anchor()
	var gap_4x: Vector2 = menu_anchor.position
	var tile_px_4x: float = GameConstants.TILE_SIZE * 4.0
	var edge_4x_ok: bool = absf(
		gap_4x.x - (anchor_screen.x + tile_px_4x + 4.0)) <= 1.0 and gap_4x.y == gap_1x.y
	var clear_of_tile: bool = gap_4x.x >= anchor_screen.x + tile_px_4x
	var side_kept: bool = String(c_anchor._context_menu_anchor.get("side", "")) == side_1x \
		and side_1x == "right"
	if edge_1x_ok and edge_4x_ok and clear_of_tile and side_kept:
		print("OK  contextual menu hugs the zoomed tile's far edge + side sticky (V027-02)")
		passed += 1
	else:
		print("FAIL contextual menu anchor: gap_1x=%s gap_4x=%s anchor=%s edge1x=%s edge4x=%s clear=%s side_1x=%s side_after=%s" % [
			gap_1x, gap_4x, anchor_screen, edge_1x_ok, edge_4x_ok, clear_of_tile,
			side_1x, c_anchor._context_menu_anchor.get("side", "")])
		failed += 1
	menu_anchor.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
