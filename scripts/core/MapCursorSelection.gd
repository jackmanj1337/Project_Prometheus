class_name MapCursorSelection extends RefCounted
# Unit selection + movement-path planning, extracted from MapCursor (D-3 slice).
#
# A plain RefCounted, not a Node: the grid + turn dependencies are injected via
# setup(), so this whole flow is unit-testable without a SceneTree. The cursor FSM
# and the EventBus relays stay on MapCursor — this object only does grid queries,
# overlay painting, and selected-unit / movement-tile bookkeeping.

# Injected via setup(). Both may be referenced before injection, so methods null-guard.
var _grid: GridManager = null
var _turn: TurnManager = null

# Public: MapCursor reads selected_unit; both MapCursor test suites read + inject these.
var selected_unit: Unit = null
var movement_tiles: Array[Vector2i] = []


# Inject scene-tree dependencies once, when MapCursor.setup() runs and _grid is known.
func setup(grid: GridManager, turn: TurnManager) -> void:
	_grid = grid
	_turn = turn


# Port of MapCursor._try_select_unit_at_cursor minus the _state write and EventBus
# emit. Validates team / can_act, records the selected unit, computes the movement
# range, paints the movement + attack overlays. Returns true when a unit was selected.
func select_at(tile: Vector2i) -> bool:
	if _grid == null:
		return false
	var unit := _grid.get_unit_at(tile)
	if unit == null:
		return false
	if not ("team" in unit) or unit.team != "player":
		return false
	# Can't select if the unit has already acted this turn.
	if _turn != null and not _turn.can_unit_act(unit):
		return false
	selected_unit = unit
	movement_tiles = _grid.get_movement_range(unit)
	_grid.show_movement_overlay(movement_tiles)
	# Attack overlay on tiles adjacent to the movement range.
	_grid.show_attack_overlay(_grid.get_attack_range_from_tiles(unit, movement_tiles))
	return true


# Port of MapCursor._try_move_selected_to_cursor's validation half. If `tile` is a
# legal destination: records the move-start for undo, computes the path, clears the
# overlays, returns the path. Returns [] when the move is illegal — and in that case
# performs NO side effects (no record_move_start, no clear_overlays), so the caller
# can simply stay in UNIT_SELECTED. A non-empty result means "proceed with the move".
func plan_path_to(tile: Vector2i) -> Array[Vector2i]:
	if selected_unit == null:
		return []
	# Only allow moving to a tile in the unit's movement range.
	if not (tile in movement_tiles):
		return []
	# _grid is non-null in normal use — a null _grid means setup() never ran, in
	# which case movement_tiles is empty and the check above already returned.
	# The null guard here is belt-and-suspenders against a direct/test caller.
	if _grid == null or not _grid.can_end_on_tile(tile, selected_unit):
		return []
	# Record original tile for potential undo.
	if _turn != null:
		_turn.record_move_start(selected_unit)
	var path := _grid.get_movement_path(selected_unit, tile)
	_grid.clear_overlays()
	return path


# Port of MapCursor._undo_move_and_reselect's substance: undo the move, recompute the
# movement range, repaint the overlays. The caller owns the _state = UNIT_SELECTED write.
func undo_and_reselect() -> void:
	if _turn != null and selected_unit != null:
		_turn.undo_move(selected_unit)
	# Recompute and redisplay overlays so the player can pick a different destination.
	if _grid != null and selected_unit != null:
		movement_tiles = _grid.get_movement_range(selected_unit)
		_grid.show_movement_overlay(movement_tiles)
		_grid.show_attack_overlay(_grid.get_attack_range_from_tiles(selected_unit, movement_tiles))


# Clears overlays, nulls the selected unit, empties the movement tiles. Used by both
# the cancel path (_deselect) and the completion path (_finish_action).
func clear() -> void:
	if _grid != null:
		_grid.clear_overlays()
	selected_unit = null
	movement_tiles.clear()
