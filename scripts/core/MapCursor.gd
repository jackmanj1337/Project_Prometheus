class_name MapCursor extends Node2D
# The player's tile-position cursor. Handles keyboard, mouse, and camera scrolling.
# Emits EventBus.cursor_moved on every tile change so HUD panels can react.

# Tween rate for held-key cursor movement (GDD_01: 0.25s initial delay, 0.10s repeat)
const KEY_REPEAT_DELAY: float = 0.25
const KEY_REPEAT_RATE: float = 0.10

# Camera edge-scroll trigger: when cursor is within this many tiles of the edge
const CAMERA_EDGE_BUFFER: int = 2

var current_tile: Vector2i = Vector2i(0, 0)
var _grid: GridManager = null
var _camera: Camera2D = null
var _turn: TurnManager = null

# State machine — see GDD_01 MapCursor section
enum State {
	FREE,            # default; cursor moves freely
	UNIT_SELECTED,   # a player unit is highlighted; movement overlay shown
	UNIT_MOVED,      # unit has moved; ActionMenu is open
	TARGETING,       # player choosing an attack target
	PREVIEWING,      # attack preview panel is shown; awaiting confirm/cancel
	STAFF_TARGETING, # player choosing a heal target
	LOCKED,          # input suppressed (animation, enemy phase)
}
var _state: State = State.FREE

# Currently selected unit and the tiles it could move to (set on selection)
var _selected_unit: Unit = null
var _movement_tiles: Array[Vector2i] = []

# Tiles valid for the current targeting mode (attack or staff heal)
var _attack_tiles: Array[Vector2i] = []
var _heal_tiles: Array[Vector2i] = []

# Key-repeat timer state
var _held_dir: Vector2i = Vector2i.ZERO
var _held_timer: float = 0.0
var _held_initial: bool = true

# Assign these in the editor — the menu nodes that live in the HUD layer.
# Typed as Node so the script compiles in headless test mode where class_name lookup fails.
@export var action_menu: Node = null
@export var item_menu: Node = null
@export var map_menu: Node = null
@export var attack_preview: Node = null

# Whether the danger zone overlay is currently displayed
var _danger_zone_shown: bool = false
# Target cached while preview is shown
var _preview_target: Node = null
# True while the "end turn with unacted units?" ConfirmationDialog is open.
# Prevents _on_map_menu_closed from unlocking the cursor before the dialog resolves.
var _awaiting_end_turn_confirm: bool = false


func _ready() -> void:
	if action_menu:
		action_menu.action_chosen.connect(_on_action_chosen)
		action_menu.hidden_by_cancel.connect(_on_action_menu_cancelled)
	if item_menu:
		item_menu.item_chosen.connect(_on_item_chosen)
		item_menu.cancelled.connect(_on_item_menu_cancelled)
	if map_menu:
		map_menu.end_turn_requested.connect(_on_end_turn_requested)
		map_menu.menu_closed.connect(_on_map_menu_closed)
	# Lock cursor during enemy phase; unlock when player phase starts
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.phase_changed.connect(_on_phase_changed)


func _on_phase_changed(new_phase: int) -> void:
	# GameState.Phase: 0 = PLAYER, 1 = ENEMY
	if new_phase == 1:
		lock()
	else:
		unlock()


func setup(grid: GridManager, camera: Camera2D, turn: TurnManager = null) -> void:
	_grid = grid
	_camera = camera
	_turn = turn
	position = _grid.tile_to_world(current_tile)


func _unhandled_input(event: InputEvent) -> void:
	if _state == State.LOCKED:
		return
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventMouseButton and event.pressed:
		_handle_mouse_button(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key_press(event)


func _process(delta: float) -> void:
	if _state == State.LOCKED or _held_dir == Vector2i.ZERO:
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
	elif event.is_action_pressed("next_unit"):
		_cycle_to_next_unit()
	elif event.is_action_pressed("open_menu") and _state == State.FREE:
		_open_map_menu()


func _direction_from_event(event: InputEventKey) -> Vector2i:
	if event.is_action_pressed("cursor_up"):    return Vector2i(0, -1)
	if event.is_action_pressed("cursor_down"):  return Vector2i(0, 1)
	if event.is_action_pressed("cursor_left"):  return Vector2i(-1, 0)
	if event.is_action_pressed("cursor_right"): return Vector2i(1, 0)
	return Vector2i.ZERO


# Reset key-repeat when the held key is released; handle danger zone hold
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed:
			var dir := Vector2i.ZERO
			if event.is_action_released("cursor_up"):    dir = Vector2i(0, -1)
			elif event.is_action_released("cursor_down"):  dir = Vector2i(0, 1)
			elif event.is_action_released("cursor_left"):  dir = Vector2i(-1, 0)
			elif event.is_action_released("cursor_right"): dir = Vector2i(1, 0)
			if dir != Vector2i.ZERO and _held_dir == dir:
				_held_dir = Vector2i.ZERO
			if event.is_action_released("show_danger_zone") and _danger_zone_shown:
				if _grid != null:
					_grid.clear_overlays()
				_danger_zone_shown = false
		elif event.pressed and not event.echo:
			if event.is_action_pressed("show_danger_zone") and _state == State.FREE:
				if _grid != null:
					_grid.show_enemy_danger_zone()
					_danger_zone_shown = true
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
			if not _danger_zone_shown:
				if _grid != null:
					_grid.show_enemy_danger_zone()
					_danger_zone_shown = true
		elif not event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE and _danger_zone_shown:
			if _grid != null:
				_grid.clear_overlays()
			_danger_zone_shown = false


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _camera == null or _grid == null:
		return
	# canvas_transform maps world → screen; its inverse converts screen pixels to world coords.
	# Using the camera's own transform here would be wrong — it doesn't account for viewport offset.
	var world := get_viewport().canvas_transform.affine_inverse() * event.position
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
	if _grid != null:
		position = _grid.tile_to_world(current_tile)
		_scroll_camera_if_needed()
	# Emit only when running inside a tree with EventBus loaded;
	# tests that load this script via --script don't have autoloads available.
	if is_inside_tree():
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.cursor_moved.emit(current_tile)


# State transitions:
# free             →(confirm on player unit)→  unit_selected
# unit_selected    →(confirm on move tile) →  unit_moved  (ActionMenu shown)
# unit_selected    →(cancel)              →  free
# unit_moved       →[ActionMenu: attack]  →  targeting
# unit_moved       →[ActionMenu: staff]   →  staff_targeting
# unit_moved       →[ActionMenu: item]    →  free  (item used, no target required)
# unit_moved       →[ActionMenu: wait]    →  free
# unit_moved       →[ActionMenu: cancel]  →  unit_selected  (undo move)
# targeting        →(confirm on enemy)    →  free  (combat resolved)
# targeting        →(cancel)             →  unit_moved  (back to ActionMenu)
# staff_targeting  →(confirm on ally)     →  free  (heal applied)
# staff_targeting  →(cancel)             →  unit_moved  (back to ActionMenu)
func _on_confirm() -> void:
	match _state:
		State.FREE:
			_try_select_unit_at_cursor()
		State.UNIT_SELECTED:
			_try_move_selected_to_cursor()
		State.UNIT_MOVED:
			pass  # ActionMenu drives confirms here; fallback in _show_action_menu when menu is null
		State.TARGETING:
			_show_attack_preview()
		State.PREVIEWING:
			_execute_attack_confirmed()
		State.STAFF_TARGETING:
			_execute_staff_heal()


func _on_cancel() -> void:
	match _state:
		State.UNIT_SELECTED:
			_deselect()
		State.UNIT_MOVED:
			# ActionMenu._input fires first and emits hidden_by_cancel → _on_action_menu_cancelled.
			# This is a safety fallback for when action_menu is null.
			if action_menu == null:
				_undo_move_and_reselect()
		State.TARGETING:
			_grid.clear_overlays()
			_attack_tiles.clear()
			_state = State.UNIT_MOVED
			_show_action_menu()
		State.PREVIEWING:
			_dismiss_attack_preview()
		State.STAFF_TARGETING:
			_grid.clear_overlays()
			_heal_tiles.clear()
			_state = State.UNIT_MOVED
			_show_action_menu()


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
	_state = State.UNIT_SELECTED
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_selected.emit(unit)


func _try_move_selected_to_cursor() -> void:
	if _selected_unit == null:
		return
	# Only allow moving to a tile in the unit's movement range
	if not (current_tile in _movement_tiles):
		return
	if not _grid.can_end_on_tile(current_tile, _selected_unit):
		return
	# Record original tile for potential undo
	if _turn != null:
		_turn.record_move_start(_selected_unit)
	var path := _grid.get_movement_path(_selected_unit, current_tile)
	_grid.clear_overlays()
	_state = State.LOCKED  # block input during the move animation
	await _selected_unit.move_along_path(path)
	_state = State.UNIT_MOVED
	_show_action_menu()


func _deselect() -> void:
	if _grid != null:
		_grid.clear_overlays()
	_selected_unit = null
	_movement_tiles.clear()
	_state = State.FREE
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_deselected.emit()


func _show_action_menu() -> void:
	if action_menu == null:
		# No menu wired up — fall back to Wait so the unit can always complete its turn
		_commit_wait()
		return
	# Place the menu just right of the unit's tile in screen space
	var world_pos := _grid.tile_to_world(_selected_unit.tile_position)
	var screen_pos: Vector2 = get_viewport().canvas_transform * world_pos
	action_menu.position = screen_pos + Vector2(GameConstants.TILE_SIZE, 0)
	action_menu.show_for(_selected_unit, _grid)


# Fired when ActionMenu's cancel key is pressed while the menu is open
func _on_action_menu_cancelled() -> void:
	# Ignore stale cancel signals that arrive while the move tween is still running.
	if _state == State.LOCKED:
		return
	_undo_move_and_reselect()


# Route the player's chosen action to the appropriate handler
func _on_action_chosen(action: String) -> void:
	match action:
		"attack":
			_begin_attack_targeting()
		"staff":
			_begin_staff_targeting()
		"item":
			_use_item()
		"wait":
			_commit_wait()


func _begin_attack_targeting() -> void:
	if _grid == null or _selected_unit == null:
		return
	var enemies := _grid.get_attackable_enemies_from_tile(_selected_unit, _selected_unit.tile_position)
	_attack_tiles.clear()
	for enemy in enemies:
		_attack_tiles.append(enemy.tile_position)
	if _attack_tiles.is_empty():
		# Shouldn't happen if ActionMenu disabled the button correctly, but handle gracefully
		_show_action_menu()
		return
	_grid.show_attack_overlay(_attack_tiles)
	# Snap cursor to the first valid target
	current_tile = _attack_tiles[0]
	position = _grid.tile_to_world(current_tile)
	_state = State.TARGETING


func _show_attack_preview() -> void:
	var target := _grid.get_unit_at(current_tile)
	if target == null or target.team == "player":
		return
	_preview_target = target
	if attack_preview and attack_preview.has_method("show_preview"):
		attack_preview.show_preview(_selected_unit, target)
		_state = State.PREVIEWING
	else:
		# No preview node wired — resolve immediately
		_do_resolve_attack(target)


func _dismiss_attack_preview() -> void:
	if attack_preview and attack_preview.has_method("hide_preview"):
		attack_preview.hide_preview()
	_preview_target = null
	_state = State.TARGETING


func _execute_attack_confirmed() -> void:
	var target: Node = _preview_target
	if attack_preview and attack_preview.has_method("hide_preview"):
		attack_preview.hide_preview()
	_preview_target = null
	_do_resolve_attack(target)


func _do_resolve_attack(target: Node) -> void:
	if target == null:
		_finish_action()
		return
	_grid.clear_overlays()
	_attack_tiles.clear()
	_state = State.LOCKED  # block input during combat resolution
	var cr := get_node_or_null("/root/CombatResolver")
	if cr:
		var result: Dictionary = cr.resolve_combat(_selected_unit, target)
		cr.apply_combat_result(result, _selected_unit, target)
	_finish_action()  # resets _state to "free"


func _begin_staff_targeting() -> void:
	if _grid == null or _selected_unit == null:
		return
	var allies := _grid.get_healable_allies(_selected_unit)
	_heal_tiles.clear()
	for ally in allies:
		_heal_tiles.append(ally.tile_position)
	if _heal_tiles.is_empty():
		_show_action_menu()
		return
	_grid.show_heal_overlay(_heal_tiles)
	current_tile = _heal_tiles[0]
	position = _grid.tile_to_world(current_tile)
	_state = State.STAFF_TARGETING


func _execute_staff_heal() -> void:
	var target := _grid.get_unit_at(current_tile)
	if target == null or target.team != "player":
		return
	_grid.clear_overlays()
	_heal_tiles.clear()
	# Heal formula: 10 + mag (GDD_02)
	var heal_amount: int = 10 + _selected_unit.data.magic
	target.heal(heal_amount)
	# Capture weapon before use_weapon_durability() — last-use removal would clear the entry
	# and a subsequent get_equipped_weapon() could return null or the wrong weapon type.
	var weapon: WeaponData = _selected_unit.get_equipped_weapon()
	if weapon != null:
		_selected_unit.use_weapon_durability(weapon.id)
		if _selected_unit.has_method("add_wexp"):
			_selected_unit.add_wexp(weapon.weapon_type, weapon.wexp)
	# Flat 10 EXP per staff use (GDD_02)
	_selected_unit.add_exp(10)
	_finish_action()


func _use_item() -> void:
	if _selected_unit == null or _selected_unit.data == null:
		_show_action_menu()
		return
	if item_menu != null:
		# Show the item submenu; result arrives via _on_item_chosen / _on_item_menu_cancelled
		var world_pos := _grid.tile_to_world(_selected_unit.tile_position)
		var screen_pos: Vector2 = get_viewport().canvas_transform * world_pos
		item_menu.position = screen_pos + Vector2(GameConstants.TILE_SIZE, 0)
		item_menu.show_for(_selected_unit)
		return
	# Fallback when ItemMenu is not wired: consume first valid item automatically
	for entry in _selected_unit.data.inventory:
		if entry.get("type", "") == "item" and entry.get("uses_remaining", 0) > 0:
			_apply_item_effect(entry)
			break
	_finish_action()


func _on_item_chosen(entry: Dictionary) -> void:
	if _selected_unit == null:
		_finish_action()
		return
	_apply_item_effect(entry)
	_finish_action()


func _on_item_menu_cancelled() -> void:
	_show_action_menu()


func _apply_item_effect(entry: Dictionary) -> void:
	var ih := get_node_or_null("/root/ItemHandler")
	if ih:
		ih.apply_item(_selected_unit, entry)
	else:
		push_warning("MapCursor: ItemHandler autoload not found")


# Commit the move as a Wait action — unit is marked DONE, no combat.
func _commit_wait() -> void:
	if _turn != null and _selected_unit != null:
		_turn.set_unit_state(_selected_unit, TurnManager.UnitState.DONE)
	_finish_action()


# Cancel from unit_moved: snap the unit back to its pre-move tile and re-enter selection.
func _undo_move_and_reselect() -> void:
	if _turn != null and _selected_unit != null:
		_turn.undo_move(_selected_unit)
	# Recompute and redisplay overlays so the player can pick a different destination.
	if _grid != null and _selected_unit != null:
		_movement_tiles = _grid.get_movement_range(_selected_unit)
		_grid.show_movement_overlay(_movement_tiles)
		_grid.show_attack_overlay(_grid.get_attack_range_from_tiles(_selected_unit, _movement_tiles))
	_state = State.UNIT_SELECTED


func _finish_action() -> void:
	if _grid != null:
		_grid.clear_overlays()
	_selected_unit = null
	_movement_tiles.clear()
	_attack_tiles.clear()
	_heal_tiles.clear()
	_state = State.FREE


# Cycles cursor to the next READY player unit (Tab key). Wraps around.
func _cycle_to_next_unit() -> void:
	if _state != State.FREE or _turn == null:
		return
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var ready_units: Array[Node] = []
	for u in gs.get_living_player_units():
		if _turn.get_unit_state(u) == TurnManager.UnitState.READY:
			ready_units.append(u)
	if ready_units.is_empty():
		return
	# Find the next unit after the one currently under the cursor
	var current_idx: int = -1
	for i in ready_units.size():
		if ready_units[i].tile_position == current_tile:
			current_idx = i
			break
	var next_unit: Node = ready_units[(current_idx + 1) % ready_units.size()]
	_set_tile(next_unit.tile_position)


func _open_map_menu() -> void:
	if map_menu == null:
		return
	lock()
	map_menu.open()


func _on_end_turn_requested() -> void:
	if _turn == null:
		return
	if _turn.are_all_player_units_done():
		_turn.end_player_phase()
		return
	# Some units haven't acted — keep cursor locked and ask for confirmation.
	_awaiting_end_turn_confirm = true
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Some units have not acted yet.\nEnd turn anyway?"
	dlg.confirmed.connect(func():
		_awaiting_end_turn_confirm = false
		_turn.end_player_phase()
		dlg.queue_free()
	)
	dlg.canceled.connect(func():
		_awaiting_end_turn_confirm = false
		unlock()
		dlg.queue_free()
	)
	add_child(dlg)
	dlg.popup_centered()


func _on_map_menu_closed() -> void:
	if _awaiting_end_turn_confirm:
		return
	# Don't unlock during the enemy phase — the phase_changed listener handles that.
	var gs := get_node_or_null("/root/GameState")
	if gs and not gs.is_player_turn():
		return
	unlock()


func lock() -> void:
	_state = State.LOCKED
	_held_dir = Vector2i.ZERO
	_held_timer = 0.0
	_held_initial = true


func unlock() -> void:
	_state = State.FREE


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


