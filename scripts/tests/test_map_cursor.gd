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

	# ---- FREE + confirm on an empty tile → stays FREE ----
	c2._set_tile(Vector2i(5, 5))  # no unit here
	c2._on_confirm()
	if c2._state == FREE and c2._selection.selected_unit == null:
		print("OK  FREE + confirm on empty tile → stays FREE")
		passed += 1
	else:
		print("FAIL confirm-empty: _state=%d" % c2._state)
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
	c8._state = TARGETING
	c8._on_targeting_cancelled()
	if c8._state == UNIT_MOVED:
		print("OK  _on_targeting_cancelled: TARGETING → UNIT_MOVED")
		passed += 1
	else:
		print("FAIL targeting-cancel: _state=%d" % c8._state)
		failed += 1

	# ---- _cycle_to_next_unit is a no-op outside FREE ----
	var t9 := TurnManager.new(); root.add_child(t9)
	var c9 := _make_cursor(t9)
	c9._set_tile(Vector2i(3, 3))
	c9._state = UNIT_SELECTED
	c9._cycle_to_next_unit()
	if c9.current_tile == Vector2i(3, 3):
		print("OK  _cycle_to_next_unit does nothing outside FREE")
		passed += 1
	else:
		print("FAIL cycle-guard: tile moved to %s" % str(c9.current_tile))
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
