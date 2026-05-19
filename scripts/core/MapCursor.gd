class_name MapCursor extends Node2D
# The player's tile-position cursor. Handles keyboard, mouse, and camera scrolling.
# Emits EventBus.cursor_moved on every tile change so HUD panels can react.
#
# Three concerns have been sliced out into RefCounted helpers: MapCursorTargeting
# (attack/staff flow, D-2), MapCursorSelection (unit selection + move planning, D-3),
# and MapCursorInput (key decode + auto-repeat, D-3). MapCursor keeps the cursor FSM,
# camera, menus, and the thin input/mouse receiver shells.
#
# State machine: see State enum below and the transition diagram above _on_confirm().

# Camera-pan trigger distance — the default when SettingsManager is unavailable
# (headless tests). The live value is read per-scroll via _camera_edge_buffer()
# so the in-game Camera Pan Buffer setting (#17) takes effect immediately.
# Key-repeat timings now live in MapCursorInput.
const CAMERA_EDGE_BUFFER: int = GameConstants.CURSOR_CAMERA_EDGE_BUFFER

var current_tile: Vector2i = Vector2i(0, 0)
var _grid: GridManager = null
var _camera: Camera2D = null
var _turn: TurnManager = null

# State machine — see GDD_01 MapCursor section
enum State {
	FREE,            # default; cursor moves freely
	UNIT_SELECTED,   # a player unit is highlighted; movement overlay shown
	UNIT_MOVED,      # unit has moved; ActionMenu is open
	TARGETING,       # MapCursorTargeting owns the flow (attack or staff heal)
	LOCKED,          # input suppressed (animation, enemy phase)
}
var _state: State = State.FREE

# Unit selection + movement-path planning — see MapCursorSelection.gd (D-3 slice).
# The cursor FSM stays here; this object owns the selected unit and its move range.
var _selection: MapCursorSelection = MapCursorSelection.new()

# Attack / staff-heal targeting flow — see MapCursorTargeting.gd. The cursor FSM
# above stays here; this object owns the CHOOSING/PREVIEWING sub-state.
var _targeting: MapCursorTargeting = MapCursorTargeting.new()

# Keyboard decoding + held-key auto-repeat — see MapCursorInput.gd (D-3 slice).
# Named _input_handler, not _input, to avoid colliding with the _input() callback.
var _input_handler: MapCursorInput = MapCursorInput.new()

# Assign these in the editor — the menu nodes that live in the HUD layer.
# Typed as Node so the script compiles in headless test mode where class_name lookup fails.
@export var action_menu: Node = null
@export var item_menu: Node = null
@export var map_menu: Node = null
@export var attack_preview: Node = null
@export var settings_screen: Node = null
@export var weapon_menu: Node = null
@export var unit_details: Node = null

# Whether the danger zone overlay is currently displayed
var _danger_zone_shown: bool = false
# True while the level-up screen is on-screen. Suppresses all cursor input
# independently of _state, so a post-combat _finish_action setting _state=FREE
# can't re-enable the cursor underneath the level-up screen (#12).
var _input_suppressed: bool = false
# True while the "end turn with unacted units?" ConfirmationDialog is open.
# Prevents _on_map_menu_closed from unlocking the cursor before the dialog resolves.
var _awaiting_end_turn_confirm: bool = false


# ── Setup & Lifecycle ──────────────────────────────────────────────────────

func _ready() -> void:
	# The @export NodePaths to the HUDLayer menus resolve to null at scene-build
	# time — the menus are declared after MapCursor in GameMap.tscn, so they don't
	# exist yet when the exports are applied. _ready() runs after the whole tree is
	# built, so re-resolve any that came back null before wiring their signals.
	_resolve_menu_refs()
	if action_menu:
		action_menu.action_chosen.connect(_on_action_chosen)
		action_menu.hidden_by_cancel.connect(_on_action_menu_cancelled)
	if item_menu:
		item_menu.item_chosen.connect(_on_item_chosen)
		item_menu.cancelled.connect(_on_item_menu_cancelled)
	if weapon_menu:
		weapon_menu.weapon_chosen.connect(_on_weapon_chosen)
		weapon_menu.cancelled.connect(_on_weapon_menu_cancelled)
	if unit_details:
		unit_details.closed.connect(_on_unit_details_closed)
	if map_menu:
		map_menu.end_turn_requested.connect(_on_end_turn_requested)
		map_menu.menu_closed.connect(_on_map_menu_closed)
		map_menu.settings_requested.connect(_on_settings_requested)
	if settings_screen:
		settings_screen.back_pressed.connect(_on_settings_closed)
	# Lock cursor during enemy phase; unlock when player phase starts
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.phase_changed.connect(_on_phase_changed)
		# Freeze the cursor while the level-up screen is up (#12).
		bus.level_up_started.connect(_on_level_up_started)
		bus.level_up_finished.connect(_on_level_up_finished)
	# React to the targeting flow finishing or being backed out of.
	_targeting.completed.connect(_on_targeting_completed)
	_targeting.cancelled.connect(_on_targeting_cancelled)


# Fallback lookup for the menu @exports — see _ready(). Each path mirrors the
# NodePath set on the export in GameMap.tscn; only applied when the export is
# null so an editor-assigned reference still wins.
func _resolve_menu_refs() -> void:
	if action_menu == null:
		action_menu = get_node_or_null("../HUDLayer/ActionMenu")
	if item_menu == null:
		item_menu = get_node_or_null("../HUDLayer/ItemMenu")
	if map_menu == null:
		map_menu = get_node_or_null("../HUDLayer/MapMenu")
	if attack_preview == null:
		attack_preview = get_node_or_null("../HUDLayer/AttackPreview")
	if settings_screen == null:
		settings_screen = get_node_or_null("../SettingsLayer/SettingsScreen")
	if weapon_menu == null:
		weapon_menu = get_node_or_null("../HUDLayer/WeaponMenu")
	if unit_details == null:
		unit_details = get_node_or_null("../UnitDetailsLayer/UnitDetailsScreen")


func _on_phase_changed(new_phase: int) -> void:
	if new_phase == GameState.Phase.ENEMY:
		lock()
	else:
		# AI-phase tracking pans the camera onto each enemy as it acts (#7), so
		# at handover the camera is usually somewhere far from the player cursor.
		# Pull it back before unlocking input — otherwise the player regains
		# control with their cursor off-screen. Playtest 3 #5.
		_scroll_camera_if_needed()
		unlock()


# Level-up screen opened — suppress cursor input until it closes (#12).
func _on_level_up_started() -> void:
	_input_suppressed = true
	_input_handler.clear_repeat()


# Level-up queue exhausted — the cursor may resume.
func _on_level_up_finished() -> void:
	_input_suppressed = false


func setup(grid: GridManager, camera: Camera2D, turn: TurnManager = null) -> void:
	_grid = grid
	_camera = camera
	_turn = turn
	position = _grid.tile_to_world(current_tile)
	# Inject the targeting flow's scene-tree dependencies now that _grid is known.
	_targeting.setup(_grid, attack_preview, get_node_or_null("/root/CombatResolver"))
	# The selection slice needs the grid + turn manager for its queries.
	_selection.setup(_grid, _turn)


# ── Input Handling ──────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _input_suppressed or _state == State.LOCKED:
		return
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventMouseButton and event.pressed:
		_handle_mouse_button(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key_press(event)


func _process(delta: float) -> void:
	# Auto-repeat only applies to free cursor movement. If the state changed
	# while a key was held (e.g. confirmed into TARGETING), drop the held dir
	# so the cursor doesn't drift out of a menu/targeting context.
	if _input_suppressed:
		_input_handler.clear_repeat()
		return
	if _state != State.FREE and _state != State.UNIT_SELECTED:
		_input_handler.clear_repeat()
		return
	var d := _input_handler.tick(delta)
	if d != Vector2i.ZERO:
		move_cursor(d)


func _handle_key_press(event: InputEventKey) -> void:
	# MapCursorInput decodes the key into a state-agnostic intent; the FSM here
	# decides what a MOVE means per _state (free move / target cycle / ignored).
	var decoded := _input_handler.decode_key(event)
	match decoded["intent"]:
		MapCursorInput.Intent.MOVE:
			var dir: Vector2i = decoded["dir"]
			match _state:
				State.FREE, State.UNIT_SELECTED:
					# Free cursor movement, with held-key auto-repeat.
					move_cursor(dir)
					_input_handler.arm_repeat(dir)
				State.TARGETING:
					# Arrows step between valid targets instead of moving freely.
					_cycle_target(dir)
				# UNIT_MOVED (ActionMenu owns input) ignores direction keys entirely.
		MapCursorInput.Intent.CONFIRM:
			_on_confirm()
		MapCursorInput.Intent.CANCEL:
			_on_cancel()
		MapCursorInput.Intent.NEXT_UNIT:
			_cycle_to_next_unit(1)
		MapCursorInput.Intent.PREV_UNIT:
			_cycle_to_next_unit(-1)
		MapCursorInput.Intent.OPEN_MENU:
			if _state == State.FREE:
				_open_map_menu()
		MapCursorInput.Intent.OPEN_SETTINGS:
			_open_settings_via_hotkey()
		MapCursorInput.Intent.INSPECT_UNIT:
			_open_unit_details()


# Resets cursor key-repeat on key release, and flips the enemy danger-zone
# toggle on a show_danger_zone press or a middle-mouse click (#12).
func _input(event: InputEvent) -> void:
	if _input_suppressed:
		return
	if event is InputEventKey:
		if not event.pressed:
			# Clear cursor key-repeat when the held direction key is released.
			_input_handler.note_key_released(event)
		elif not event.echo and event.is_action_pressed("show_danger_zone"):
			_toggle_danger_zone()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
			_toggle_danger_zone()


# Flips the enemy danger-zone overlay on/off (#12). Available only in the FREE
# cursor state: while a unit is selected the overlay layer is showing that unit's
# movement range, and the danger zone would wipe it (#13).
func _toggle_danger_zone() -> void:
	if _grid == null or _state != State.FREE:
		return
	if _danger_zone_shown:
		_grid.clear_overlays()
		_danger_zone_shown = false
	else:
		_grid.show_enemy_danger_zone()
		_danger_zone_shown = true


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _camera == null or _grid == null:
		return
	# canvas_transform maps world → screen; its inverse converts screen pixels to world coords.
	# Using the camera's own transform here would be wrong — it doesn't account for viewport offset.
	var world := get_viewport().canvas_transform.affine_inverse() * event.position
	var tile := _grid.world_to_tile(world)
	match _state:
		State.FREE, State.UNIT_SELECTED:
			if tile != current_tile:
				_set_tile(tile)
		State.TARGETING:
			_handle_targeting_mouse_motion(tile)
		# UNIT_MOVED (menu open) ignores mouse motion.


# Mouse motion while choosing a target obeys the mouse_targeting UX setting:
#   "snap"     — cursor jumps to the valid target nearest the pointer (Manhattan).
#   "disabled" — motion is ignored; only keyboard cycling moves the cursor.
# Mouse *clicks* still confirm/cancel regardless — handled in _handle_mouse_button.
func _handle_targeting_mouse_motion(tile: Vector2i) -> void:
	if not _targeting.can_change_target():
		return  # frozen while the attack preview is showing
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null and sm.mouse_targeting == "disabled":
		return
	var tiles := _targeting.target_tiles()
	if tiles.is_empty():
		return
	var nearest: Vector2i = tiles[0]
	var best: int = _manhattan(tile, nearest)
	for t in tiles:
		var d := _manhattan(tile, t)
		if d < best:
			best = d
			nearest = t
	if nearest != current_tile:
		_set_tile(nearest)


# Step the cursor to the next/previous valid target. Right/Down advance, Left/Up
# go back; the list wraps. dir is a unit cardinal vector decoded by MapCursorInput.
func _cycle_target(dir: Vector2i) -> void:
	if not _targeting.can_change_target():
		return  # frozen while the attack preview is showing
	var tiles := _targeting.target_tiles()
	if tiles.is_empty():
		return
	var idx: int = tiles.find(current_tile)
	if idx == -1:
		idx = 0
	var step: int = 1 if (dir.x > 0 or dir.y > 0) else -1
	idx = (idx + step + tiles.size()) % tiles.size()
	_set_tile(tiles[idx])


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_on_confirm()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_on_cancel()


func move_cursor(direction: Vector2i) -> void:
	_set_tile(current_tile + direction)


# Public entry point for code outside the input flow (e.g. GameMap placing the
# initial cursor after units spawn, #9) to move the cursor onto a tile and let
# the HUD react. No camera scroll — the caller positions the camera itself.
func center_on_tile(tile: Vector2i) -> void:
	current_tile = tile
	if _grid != null:
		position = _grid.tile_to_world(current_tile)
	if is_inside_tree():
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.cursor_moved.emit(current_tile)


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


# ── State Machine ──────────────────────────────────────────────────────────
#
# State transitions:
# free          →(confirm on player unit)→  unit_selected
# free          →(confirm/cancel on empty tile, or the open_menu key)→ map menu (locked)
# unit_selected →(confirm on move tile) →  unit_moved  (ActionMenu shown)
# unit_selected →(cancel)              →  free
# unit_moved    →[ActionMenu: attack]  →  targeting   (MapCursorTargeting, ATTACK)
# unit_moved    →[ActionMenu: staff]   →  targeting   (MapCursorTargeting, STAFF)
# unit_moved    →[ActionMenu: item]    →  free  (item used, no target required)
# unit_moved    →[ActionMenu: wait]    →  free
# unit_moved    →[ActionMenu: cancel]  →  unit_selected  (undo move)
# targeting     →(MapCursorTargeting `completed`)→  free  (action resolved)
# targeting     →(MapCursorTargeting `cancelled`)→  unit_moved  (back to ActionMenu)
# While in `targeting`, confirm/cancel are delegated to MapCursorTargeting, which
# tracks the choosing-vs-previewing sub-state internally.
func _on_confirm() -> void:
	match _state:
		State.FREE:
			_try_select_unit_at_cursor()
		State.UNIT_SELECTED:
			_try_move_selected_to_cursor()
		State.UNIT_MOVED:
			pass  # ActionMenu drives confirms here; fallback in _show_action_menu when menu is null
		State.TARGETING:
			_targeting.handle_confirm(current_tile)


func _on_cancel() -> void:
	match _state:
		State.FREE:
			# Cancel on an empty tile opens the map menu (GDD_07).
			if _is_cursor_on_empty_tile():
				_open_map_menu()
		State.UNIT_SELECTED:
			_deselect()
		State.UNIT_MOVED:
			# ActionMenu._input fires first and emits hidden_by_cancel → _on_action_menu_cancelled.
			# This is a safety fallback for when action_menu is null.
			if action_menu == null:
				_undo_move_and_reselect()
		State.TARGETING:
			_targeting.handle_cancel()


# ── State: FREE — unit selection ────────────────────────────────────────────

# True when the cursor sits on a tile with no unit — the trigger for the
# confirm/cancel-on-empty-tile map-menu open.
func _is_cursor_on_empty_tile() -> bool:
	return _grid != null and _grid.get_unit_at(current_tile) == null


func _try_select_unit_at_cursor() -> void:
	# A shown danger zone shares the one overlay layer with the selection overlays.
	# Clear it before selecting so it can't bleed through the move range (#13).
	if _danger_zone_shown:
		if _grid != null:
			_grid.clear_overlays()
		_danger_zone_shown = false
	# MapCursorSelection does the grid validation + overlay painting; the FSM state
	# write and the EventBus relay stay here (a RefCounted slice can't get_node).
	if _selection.select_at(current_tile):
		_state = State.UNIT_SELECTED
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.unit_selected.emit(_selection.selected_unit)
	elif _is_cursor_on_empty_tile():
		# Confirm on an empty tile opens the map menu (GDD_07).
		_open_map_menu()


# ── State: UNIT_SELECTED — movement ─────────────────────────────────────────

func _try_move_selected_to_cursor() -> void:
	# plan_path_to returns [] (and does nothing) for an illegal destination — the
	# cursor then simply stays in UNIT_SELECTED.
	var path := _selection.plan_path_to(current_tile)
	if path.is_empty():
		return
	_state = State.LOCKED  # block input during the move animation
	await _selection.selected_unit.move_along_path(path)
	_state = State.UNIT_MOVED
	_show_action_menu()


func _deselect() -> void:
	_selection.clear()
	_state = State.FREE
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_deselected.emit()


# ── State: UNIT_MOVED — ActionMenu dispatch ──────────────────────────────────

# Position a HUD menu one tile to the right of `tile`, but flip it to the left
# and clamp it inside the viewport if it would otherwise run off-screen
# (playtest 3 #4). Used by every per-unit popup — Action / Item / Weapon menus —
# so the fix lands in one place. Call this AFTER the menu's show_for() so its
# real size is known (menus hide unavailable rows, so the height varies).
func _place_menu_near(menu: Node, tile: Vector2i) -> void:
	if menu == null or _grid == null:
		return
	var world_pos := _grid.tile_to_world(tile)
	var screen_pos: Vector2 = get_viewport().canvas_transform * world_pos
	var view: Vector2 = get_viewport().get_visible_rect().size
	# size is updated after show_for() populates the menu; for containers this
	# matches get_combined_minimum_size(). Fall back to the latter when size is 0.
	var menu_size: Vector2 = menu.size
	if menu_size.x <= 0 or menu_size.y <= 0:
		menu_size = menu.get_combined_minimum_size()
	var pos := screen_pos + Vector2(GameConstants.TILE_SIZE, 0)
	# Flip to the unit's left if the menu would run off the right edge.
	if pos.x + menu_size.x > view.x:
		pos.x = screen_pos.x - menu_size.x
	pos.x = clampf(pos.x, 0.0, maxf(0.0, view.x - menu_size.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, view.y - menu_size.y))
	menu.position = pos


func _show_action_menu() -> void:
	if action_menu == null:
		# No menu wired up — fall back to Wait so the unit can always complete its turn
		_commit_wait()
		return
	# show_for() before placement — ActionMenu hides unavailable rows, so the
	# real height is only known once the contents are populated (playtest 3 #4).
	action_menu.show_for(_selection.selected_unit, _grid)
	_place_menu_near(action_menu, _selection.selected_unit.tile_position)


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
			_enter_targeting(MapCursorTargeting.Mode.ATTACK)
		"staff":
			_enter_targeting(MapCursorTargeting.Mode.STAFF)
		"item":
			_use_item()
		"equip":
			_open_weapon_menu()
		"wait":
			_commit_wait()


# ── State: TARGETING — delegated to MapCursorTargeting ───────────────────────

# Hand off to the targeting flow. begin() returns the valid target tiles; if there
# are none (ActionMenu should have prevented this) reopen the menu instead.
func _enter_targeting(mode: int) -> void:
	var tiles := _targeting.begin(mode, _selection.selected_unit)
	if tiles.is_empty():
		_show_action_menu()
		return
	_state = State.TARGETING
	# Snap the cursor to the first valid target via _set_tile, so cursor_moved fires
	# (HUD updates to the target) and the camera scrolls to keep it on screen.
	_set_tile(tiles[0])


# MapCursorTargeting resolved the action (combat done / heal applied).
func _on_targeting_completed() -> void:
	_finish_action()


# Player backed out of target choice — return to the ActionMenu.
func _on_targeting_cancelled() -> void:
	_state = State.UNIT_MOVED
	# Snap the cursor back onto the acting unit (#9). Without this the cursor is
	# left on the last highlighted enemy tile, away from the unit taking the
	# action — mirrors how _enter_targeting snapped it onto the first target.
	if _selection.selected_unit != null:
		_set_tile(_selection.selected_unit.tile_position)
	_show_action_menu()


# ── Item Use ────────────────────────────────────────────────────────────────

func _use_item() -> void:
	if _selection.selected_unit == null or _selection.selected_unit.data == null:
		_show_action_menu()
		return
	if item_menu != null:
		# Show the item submenu; result arrives via _on_item_chosen / _on_item_menu_cancelled
		item_menu.show_for(_selection.selected_unit)
		_place_menu_near(item_menu, _selection.selected_unit.tile_position)
		return
	# Fallback when ItemMenu is not wired: consume first valid item automatically
	for entry in _selection.selected_unit.data.inventory:
		if entry.is_item() and entry.has_uses():
			_apply_item_effect(entry)
			break
	_finish_action()


func _on_item_chosen(entry: InventoryEntry) -> void:
	if _selection.selected_unit == null:
		_finish_action()
		return
	_apply_item_effect(entry)
	_finish_action()


func _on_item_menu_cancelled() -> void:
	_show_action_menu()


func _apply_item_effect(entry: InventoryEntry) -> void:
	var ih := get_node_or_null("/root/ItemHandler")
	if ih:
		ih.apply_item(_selection.selected_unit, entry)
	else:
		push_warning("MapCursor: ItemHandler autoload not found")


# ── Weapon Swap (#8) ─────────────────────────────────────────────────────────
#
# Equipping is free: it doesn't consume the action. The flow stays in UNIT_MOVED
# — picking a weapon or cancelling just reopens the ActionMenu, which re-evaluates
# Attack/Staff availability against the newly equipped weapon.

func _open_weapon_menu() -> void:
	if weapon_menu == null or _selection.selected_unit == null:
		_show_action_menu()  # no menu wired / no unit — fall back to the ActionMenu
		return
	weapon_menu.show_for(_selection.selected_unit)
	_place_menu_near(weapon_menu, _selection.selected_unit.tile_position)


func _on_weapon_chosen(entry: InventoryEntry) -> void:
	if _selection.selected_unit != null:
		_selection.selected_unit.set_equipped_weapon(entry)
	_show_action_menu()


func _on_weapon_menu_cancelled() -> void:
	_show_action_menu()


# ── Shared Action Completion ─────────────────────────────────────────────────

# Commit the move as a Wait action — unit is marked DONE via _finish_action().
func _commit_wait() -> void:
	_finish_action()


# Cancel from unit_moved: snap the unit back to its pre-move tile and re-enter selection.
func _undo_move_and_reselect() -> void:
	if _state == State.LOCKED:
		return
	# The LOCKED guard owns _state; the slice handles the undo + overlay recompute.
	_selection.undo_and_reselect()
	_state = State.UNIT_SELECTED


func _finish_action() -> void:
	# Mark the acting unit DONE so it can't be selected again this turn. Skip this
	# when the unit died mid-action (mutual kill / Vantage counter-kill): it is
	# already out of TurnManager._unit_states, and set_unit_state would re-insert a
	# stale freed-node key.
	var u := _selection.selected_unit
	if _turn != null and is_instance_valid(u) and u.data != null and u.data.hp > 0:
		_turn.set_unit_state(u, TurnManager.UnitState.DONE)
	_selection.clear()
	_state = State.FREE
	# Tell the HUD the unit is no longer selected. Without this the HUD stays
	# latched on the unit that just acted and stops following the cursor (#6).
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_deselected.emit()


# ── Map Menu / End Turn ──────────────────────────────────────────────────────

# Cycles the cursor to the next/previous player unit that can still act.
# step +1 = forward (Tab / next_unit), step -1 = backward (Shift+Tab / prev_unit).
# Wraps around. Uses can_unit_act so MOVED units (mid-action) are included, not
# just READY ones.
func _cycle_to_next_unit(step: int) -> void:
	if _state != State.FREE or _turn == null:
		return
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var actable_units: Array[Node] = []
	for u in gs.get_living_player_units():
		if _turn.can_unit_act(u):
			actable_units.append(u)
	if actable_units.is_empty():
		return
	# Find the unit currently under the cursor, if any.
	var current_idx: int = -1
	for i in actable_units.size():
		if actable_units[i].tile_position == current_tile:
			current_idx = i
			break
	var target_idx: int
	if current_idx == -1:
		# Cursor not on an actable unit — forward starts at the first, backward
		# at the last, so a single press always lands somewhere sensible.
		target_idx = 0 if step > 0 else actable_units.size() - 1
	else:
		target_idx = (current_idx + step + actable_units.size()) % actable_units.size()
	_set_tile(actable_units[target_idx].tile_position)


func _open_map_menu() -> void:
	if map_menu == null:
		return
	lock()
	map_menu.open()
	# Consume the triggering press. Without this the same keystroke keeps
	# propagating to MapMenu._unhandled_input, which treats open_menu/cancel as
	# a close — flickering the menu shut on the very keystroke that opened it.
	if is_inside_tree():
		get_viewport().set_input_as_handled()


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
	get_tree().root.add_child(dlg)
	dlg.popup_centered()
	# Focus the Cancel button, not OK (#15/#16): the safe choice is the default,
	# so a mashed or held confirm key dismisses the prompt instead of ending the
	# turn early. The game cancel key still closes it via the dialog's ui_cancel.
	dlg.get_cancel_button().grab_focus()


func _on_map_menu_closed() -> void:
	if _awaiting_end_turn_confirm:
		return
	# Don't unlock during the enemy phase — the phase_changed listener handles that.
	var gs := get_node_or_null("/root/GameState")
	if gs and not gs.is_player_turn():
		return
	unlock()


# ── Settings ─────────────────────────────────────────────────────────────────

# open_settings hotkey (#3). Opens Settings from free roam, or from a unit
# selection — the selection is dropped first. Ignored mid-action (ActionMenu /
# targeting) so a half-finished action can't be stranded behind the overlay.
func _open_settings_via_hotkey() -> void:
	if _state == State.UNIT_SELECTED:
		_deselect()
	elif _state != State.FREE:
		return
	_open_settings()


# Map-menu "Settings" button (#3). The map menu has hidden itself; the cursor is
# already LOCKED — just show the settings overlay.
func _on_settings_requested() -> void:
	_open_settings()


# Shows the settings overlay and locks the cursor until it is closed.
func _open_settings() -> void:
	if settings_screen == null:
		return
	lock()
	settings_screen.open()


# Settings closed (Back / cancel) — unlock unless the enemy phase owns the lock.
func _on_settings_closed() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs and not gs.is_player_turn():
		return
	unlock()


# ── Unit Details (#1) ────────────────────────────────────────────────────────

# inspect_unit hotkey. Opens the read-only details page for the unit under the
# cursor. Available in free roam and while a unit is selected; ignored mid-action
# so a half-finished action can't be stranded. Uses the _input_suppressed flag
# (not lock()) so a live unit selection and its overlays survive the inspection.
func _open_unit_details() -> void:
	if unit_details == null or _grid == null:
		return
	if _state != State.FREE and _state != State.UNIT_SELECTED:
		return
	var unit := _grid.get_unit_at(current_tile)
	if unit == null:
		return
	_input_suppressed = true
	_input_handler.clear_repeat()
	unit_details.open(unit)
	# Consume the triggering press so UnitDetailsScreen._unhandled_input doesn't
	# treat the same inspect_unit keystroke as a close.
	if is_inside_tree():
		get_viewport().set_input_as_handled()


# Details page closed — resume cursor input. The FSM _state was never touched,
# so a unit that was selected stays selected.
func _on_unit_details_closed() -> void:
	_input_suppressed = false


# ── Lock / Unlock ────────────────────────────────────────────────────────────

func lock() -> void:
	_state = State.LOCKED
	_input_handler.clear_repeat()
	# Drop the danger zone when input is suppressed (map menu, enemy phase) — it is
	# a FREE-state toggle, and leaving it painted would show a stale threat area
	# after enemies move during their phase.
	if _danger_zone_shown:
		if _grid != null:
			_grid.clear_overlays()
		_danger_zone_shown = false


func unlock() -> void:
	_state = State.FREE


# ── Camera Scrolling ─────────────────────────────────────────────────────────

# The live camera-pan buffer — the player-set value (#17) when SettingsManager
# is loaded, otherwise the GameConstants default. Clamped to 0-5 as belt-and-
# braces: SettingsManager also clamps on load, but guarding here keeps the
# scroll math sound regardless of how the value was set.
func _camera_edge_buffer() -> int:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null:
		return clampi(sm.camera_edge_buffer, 0, 5)
	return CAMERA_EDGE_BUFFER


# When the cursor approaches the screen edge, pan the camera to keep it visible.
func _scroll_camera_if_needed() -> void:
	if _camera == null or _grid == null:
		return
	var buffer: int = _camera_edge_buffer()
	var view: Vector2 = get_viewport().get_visible_rect().size
	# How many tiles fit on screen (zoom assumed 1:1, as elsewhere).
	var tiles_w: int = int(view.x / GameConstants.TILE_SIZE)
	var tiles_h: int = int(view.y / GameConstants.TILE_SIZE)
	# Camera2D.position is the view CENTRE (anchor_mode = DRAG_CENTER). Convert to
	# the top-left tile of the visible area so the edge-margin checks are correct —
	# treating the centre as the top-left is the bug that let the cursor scroll off.
	var tl: Vector2i = _grid.world_to_tile(_camera.position - view * 0.5)

	# Pull the view so the cursor never sits within `buffer` tiles of an edge.
	if current_tile.x < tl.x + buffer:
		tl.x = current_tile.x - buffer
	elif current_tile.x > tl.x + tiles_w - buffer - 1:
		tl.x = current_tile.x - tiles_w + buffer + 1
	if current_tile.y < tl.y + buffer:
		tl.y = current_tile.y - buffer
	elif current_tile.y > tl.y + tiles_h - buffer - 1:
		tl.y = current_tile.y - tiles_h + buffer + 1

	# Clamp the view so it never shows space beyond the map edges.
	tl.x = clamp(tl.x, 0, max(0, _grid.map_width - tiles_w))
	tl.y = clamp(tl.y, 0, max(0, _grid.map_height - tiles_h))

	# Convert the top-left tile back to a centre position for the camera.
	_camera.position = _grid.tile_to_world(tl) + view * 0.5


