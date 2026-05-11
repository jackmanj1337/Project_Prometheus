class_name MapCursor extends Node2D
# The player's tile-position cursor. Handles keyboard, mouse, and camera scrolling.
# Emits EventBus.cursor_moved on every tile change so HUD panels can react.

# Tween rate for held-key cursor movement (GDD_01: 0.25s initial delay, 0.10s repeat)
const KEY_REPEAT_DELAY: float = 0.25
const KEY_REPEAT_RATE: float = 0.10

# Camera edge-scroll trigger: when cursor is within this many tiles of the edge
const CAMERA_EDGE_BUFFER: int = 2

# Phase-2 zoom architecture (per GDD_01) — placeholders for future implementation
const ZOOM_LEVELS: Array[float] = [0.75, 1.0, 1.5]
const DEFAULT_ZOOM_INDEX: int = 1

var current_tile: Vector2i = Vector2i(0, 0)
var _grid: GridManager = null
var _camera: Camera2D = null
var _turn: TurnManager = null
var _zoom_index: int = DEFAULT_ZOOM_INDEX

# State machine — see GDD_01 MapCursor section
# "free" | "unit_selected" | "unit_moved" | "targeting" | "locked"
var _state: String = "free"

# Currently selected unit and the tiles it could move to (set on selection)
var _selected_unit: Unit = null
var _movement_tiles: Array[Vector2i] = []

# Key-repeat timer state
var _held_dir: Vector2i = Vector2i.ZERO
var _held_timer: float = 0.0
var _held_initial: bool = true


func setup(grid: GridManager, camera: Camera2D, turn: TurnManager = null) -> void:
	_grid = grid
	_camera = camera
	_turn = turn
	position = _grid.tile_to_world(current_tile)


func _unhandled_input(event: InputEvent) -> void:
	if _state == "locked":
		return
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventMouseButton and event.pressed:
		_handle_mouse_button(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key_press(event)


func _process(delta: float) -> void:
	if _state == "locked" or _held_dir == Vector2i.ZERO:
		return
	# Held-key auto-repeat: initial 0.25s pause, then 0.10s per step
	_held_timer -= delta
	if _held_timer <= 0.0:
		move_cursor(_held_dir)
		_held_timer = KEY_REPEAT_RATE if not _held_initial else KEY_REPEAT_DELAY
		_held_initial = false


func _handle_key_press(event: InputEventKey) -> void:
	var dir := _direction_from_event(event)
	if dir != Vector2i.ZERO:
		move_cursor(dir)
		_held_dir = dir
		_held_timer = KEY_REPEAT_DELAY
		_held_initial = true
		return
	if event.is_action_pressed("confirm"):
		_on_confirm()
	elif event.is_action_pressed("cancel"):
		_on_cancel()


func _direction_from_event(event: InputEventKey) -> Vector2i:
	if event.is_action_pressed("cursor_up"):    return Vector2i(0, -1)
	if event.is_action_pressed("cursor_down"):  return Vector2i(0, 1)
	if event.is_action_pressed("cursor_left"):  return Vector2i(-1, 0)
	if event.is_action_pressed("cursor_right"): return Vector2i(1, 0)
	return Vector2i.ZERO


# Reset key-repeat when the held key is released
func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.pressed:
		var dir := Vector2i.ZERO
		if event.is_action_released("cursor_up"):    dir = Vector2i(0, -1)
		elif event.is_action_released("cursor_down"):  dir = Vector2i(0, 1)
		elif event.is_action_released("cursor_left"):  dir = Vector2i(-1, 0)
		elif event.is_action_released("cursor_right"): dir = Vector2i(1, 0)
		if dir != Vector2i.ZERO and _held_dir == dir:
			_held_dir = Vector2i.ZERO


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _camera == null:
		return
	# Convert mouse screen pos -> world via the camera, then to tile
	var world := _camera.get_global_transform().affine_inverse() * event.position
	var tile := _grid.world_to_tile(world)
	if tile != current_tile:
		_set_tile(tile)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_on_confirm()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_on_cancel()


func move_cursor(direction: Vector2i) -> void:
	_set_tile(current_tile + direction)


func _set_tile(tile: Vector2i) -> void:
	# Clamp to map bounds (using GridManager's known map_width/height)
	if _grid != null:
		tile.x = clamp(tile.x, 0, _grid.map_width - 1)
		tile.y = clamp(tile.y, 0, _grid.map_height - 1)
	if tile == current_tile:
		return
	current_tile = tile
	position = _grid.tile_to_world(current_tile)
	_scroll_camera_if_needed()
	# Emit only when running inside a tree with EventBus loaded;
	# tests that load this script via --script don't have autoloads available.
	if is_inside_tree():
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.cursor_moved.emit(current_tile)


# Selection state machine.
# free  →(confirm on player unit)→ unit_selected (movement overlay shown)
# unit_selected →(confirm on movement tile)→ unit_moved (committed; for MVP
#                                                        immediately DONE)
# unit_selected →(cancel)→ free (deselect)
# unit_moved   →(cancel)→ unit_selected (undo move; not yet wired — needs M4)
func _on_confirm() -> void:
	match _state:
		"free":
			_try_select_unit_at_cursor()
		"unit_selected":
			_try_move_selected_to_cursor()


func _on_cancel() -> void:
	match _state:
		"unit_selected":
			_deselect()


func _try_select_unit_at_cursor() -> void:
	if _grid == null:
		return
	var unit := _grid.get_unit_at(current_tile)
	if unit == null:
		return
	if not ("team" in unit) or unit.team != "player":
		return
	# Can't select if the unit has already acted this turn
	if _turn != null and not _turn.can_unit_act(unit):
		return
	_selected_unit = unit
	_movement_tiles = _grid.get_movement_range(unit)
	_grid.show_movement_overlay(_movement_tiles)
	# Attack overlay on tiles adjacent to the movement range
	_grid.show_attack_overlay(_grid.get_attack_range_from_tiles(unit, _movement_tiles))
	_state = "unit_selected"
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_selected.emit(unit)


func _try_move_selected_to_cursor() -> void:
	if _selected_unit == null:
		return
	# Only allow moving to a tile in the unit's movement range
	if not (current_tile in _movement_tiles):
		return
	# Don't allow moving onto another unit's tile
	if _grid.get_unit_at(current_tile) != null and _grid.get_unit_at(current_tile) != _selected_unit:
		return
	# Record original tile for potential undo
	if _turn != null:
		_turn.record_move_start(_selected_unit)
	var path := _grid.get_movement_path(_selected_unit, current_tile)
	_grid.clear_overlays()
	_state = "locked"  # block input during the move animation
	await _selected_unit.move_along_path(path)
	_state = "unit_moved"
	# MVP: no ActionMenu yet, immediately commit to DONE
	if _turn != null:
		_turn.set_unit_state(_selected_unit, TurnManager.UnitState.DONE)
	_finish_action()


func _deselect() -> void:
	if _grid != null:
		_grid.clear_overlays()
	_selected_unit = null
	_movement_tiles.clear()
	_state = "free"
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_deselected.emit()


func _finish_action() -> void:
	if _grid != null:
		_grid.clear_overlays()
	_selected_unit = null
	_movement_tiles.clear()
	_state = "free"


func lock() -> void:
	_state = "locked"
	_held_dir = Vector2i.ZERO


func unlock() -> void:
	_state = "free"


# When the cursor approaches the screen edge, pan the camera to keep it visible.
func _scroll_camera_if_needed() -> void:
	if _camera == null or _grid == null:
		return
	var viewport := get_viewport().get_visible_rect().size
	# How many tiles fit on screen at current zoom
	var tiles_w: int = int(viewport.x / GameConstants.TILE_SIZE)
	var tiles_h: int = int(viewport.y / GameConstants.TILE_SIZE)
	var cam_tile := _grid.world_to_tile(_camera.position)

	# If cursor is too close to the visible edge, recenter the camera by 1 tile
	if current_tile.x < cam_tile.x + CAMERA_EDGE_BUFFER:
		cam_tile.x = current_tile.x - CAMERA_EDGE_BUFFER
	elif current_tile.x > cam_tile.x + tiles_w - CAMERA_EDGE_BUFFER - 1:
		cam_tile.x = current_tile.x - tiles_w + CAMERA_EDGE_BUFFER + 1
	if current_tile.y < cam_tile.y + CAMERA_EDGE_BUFFER:
		cam_tile.y = current_tile.y - CAMERA_EDGE_BUFFER
	elif current_tile.y > cam_tile.y + tiles_h - CAMERA_EDGE_BUFFER - 1:
		cam_tile.y = current_tile.y - tiles_h + CAMERA_EDGE_BUFFER + 1

	# Clamp camera so it never shows space beyond the map edges
	var max_x: int = max(0, _grid.map_width - tiles_w)
	var max_y: int = max(0, _grid.map_height - tiles_h)
	cam_tile.x = clamp(cam_tile.x, 0, max_x)
	cam_tile.y = clamp(cam_tile.y, 0, max_y)
	_camera.position = _grid.tile_to_world(cam_tile)


# [PLACEHOLDER Phase 2] Three-step zoom levels: 0.75, 1.0, 1.5
func _handle_zoom(direction: int) -> void:
	_zoom_index = clamp(_zoom_index + direction, 0, ZOOM_LEVELS.size() - 1)
	_apply_zoom()


func _apply_zoom() -> void:
	if _camera != null:
		_camera.zoom = Vector2.ONE * ZOOM_LEVELS[_zoom_index]
