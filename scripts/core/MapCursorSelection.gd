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
# Faction id whose units this cursor is allowed to select. Defaults to "blue"
# (the player) so existing test callers that don't pass a faction keep working.
# M14 stage 1: replaces the literal `unit.team != "player"` gate. Stage 2 widens
# this from "same faction" to "same alliance group" via the hostility helper.
var _controlling_faction: String = "blue"

# Public: MapCursor reads selected_unit; both MapCursor test suites read + inject these.
var selected_unit: Unit = null
var movement_tiles: Array[Vector2i] = []


# Inject scene-tree dependencies once, when MapCursor.setup() runs and _grid is known.
# controlling_faction defaults to "blue" so 2-arg test callers stay valid.
func setup(grid: GridManager, turn: TurnManager, controlling_faction: String = "blue") -> void:
	_grid = grid
	_turn = turn
	_controlling_faction = controlling_faction


# Called when the active controlling faction changes mid-map (M14 stage 5 — hotseat).
# Kept separate from setup() so the dependency wiring isn't duplicated.
func set_controlling_faction(faction_id: String) -> void:
	_controlling_faction = faction_id


# Port of MapCursor._try_select_unit_at_cursor minus the _state write and EventBus
# emit. Validates team / can_act, records the selected unit, computes the movement
# range, paints the movement + attack overlays. Returns true when a unit was selected.
func select_at(tile: Vector2i) -> bool:
	if _grid == null:
		return false
	var unit := _grid.get_unit_at(tile)
	if unit == null:
		return false
	if not ("team" in unit) or unit.team != _controlling_faction:
		return false
	# Can't select if the unit has already acted this turn.
	if _turn != null and not _turn.can_unit_act(unit):
		return false
	selected_unit = unit
	movement_tiles = _grid.get_movement_range(unit)
	_grid.repaint_overlays(overlay_specs())
	return true


# Selection overlay specs for the registry compose path. MapCursor merges these
# with retained threat/watch specs so movement range can coexist with danger
# overlays ([MRD-7]); direct unit tests still get a complete selection paint.
func overlay_specs() -> Dictionary:
	var specs: Dictionary = {}
	if selected_unit == null:
		return specs
	specs[GridManager.OVERLAY_LAYER_MOVE] = {
		"tiles": movement_tiles,
		"source": GridManager.OVERLAY_BLUE,
	}
	_add_action_overlay_specs(specs, selected_unit)
	return specs


# Branches the action-range overlay by what the unit has equipped: heal overlay
# for healing staves, attack overlay otherwise. Shared by select_at and
# undo_and_reselect so the two paths can't drift.
func _add_action_overlay_specs(specs: Dictionary, unit: Node) -> void:
	var w: WeaponData = (
		unit.get_equipped_weapon() if unit.has_method("get_equipped_weapon") else null
	)
	if w != null and w.is_healing_staff():
		specs[GridManager.OVERLAY_LAYER_HEAL] = {
			"tiles": _grid.get_staff_range_from_tiles(unit, movement_tiles),
			"source": GridManager.OVERLAY_HEAL,
		}
	else:
		specs[GridManager.OVERLAY_LAYER_ATTACK] = {
			"tiles": _grid.get_attack_range_from_tiles(unit, movement_tiles),
			"source": GridManager.OVERLAY_RED,
		}


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
		_grid.repaint_overlays(overlay_specs())


# Clears overlays, nulls the selected unit, empties the movement tiles. Used by both
# the cancel path (_deselect) and the completion path (_finish_action).
func clear() -> void:
	if _grid != null:
		_grid.clear_overlays()
	selected_unit = null
	movement_tiles.clear()
