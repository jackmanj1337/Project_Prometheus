extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_map_cursor_selection.gd
# Unit tests for the MapCursorSelection slice (D-3): unit selection, move-path
# planning, undo, and clear — exercised directly, without the MapCursor FSM.

const UnitScene = preload("res://scenes/units/Unit.tscn")

var _grid: GridManager
var _gs: Node          # stub GameState — GridManager.get_unit_at reads /root/GameState


# Builds a real Unit and registers it in the stub GameState so get_unit_at finds it.
func _make_unit(tile: Vector2i, team_name: String) -> Unit:
	var d := UnitData.new()
	d.hp = 20
	d.max_hp = 20
	d.movement = 5
	var u: Unit = UnitScene.instantiate()
	u.data = d
	u.team = team_name
	root.add_child(u)
	u.tile_position = tile
	_gs.all_units.append(u)
	return u


func _init() -> void:
	print("=== MapCursorSelection Test ===")
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

	# Stub GameState — GridManager.get_unit_at reads /root/GameState.all_units.
	var gs_script := GDScript.new()
	gs_script.source_code = "extends Node\nvar all_units: Array[Node] = []\n"
	gs_script.reload()
	_gs = gs_script.new()
	_gs.name = "GameState"
	root.add_child(_gs)
	await process_frame

	var turn := TurnManager.new()
	root.add_child(turn)
	var sel := MapCursorSelection.new()
	sel.setup(_grid, turn)

	var p := _make_unit(Vector2i(2, 2), "player")
	_make_unit(Vector2i(4, 4), "enemy")

	# ---- select_at on a player unit → true, fields populated ----
	var ok := sel.select_at(Vector2i(2, 2))
	if ok and sel.selected_unit == p and sel.movement_tiles.size() > 0:
		print("OK  select_at on a player unit → true, unit + range set")
		passed += 1
	else:
		print("FAIL select_at player: ok=%s unit=%s tiles=%d" \
			% [ok, str(sel.selected_unit), sel.movement_tiles.size()])
		failed += 1

	# ---- select_at on an empty tile → false ----
	if not sel.select_at(Vector2i(5, 5)):
		print("OK  select_at on an empty tile → false")
		passed += 1
	else:
		print("FAIL select_at empty: expected false")
		failed += 1

	# ---- select_at on an enemy unit → false ----
	if not sel.select_at(Vector2i(4, 4)):
		print("OK  select_at on an enemy unit → false")
		passed += 1
	else:
		print("FAIL select_at enemy: expected false")
		failed += 1

	# ---- plan_path_to an in-range tile → non-empty path ----
	# select_at above left `p` selected with its range painted.
	var path := sel.plan_path_to(Vector2i(2, 3))
	if not path.is_empty():
		print("OK  plan_path_to an in-range tile → non-empty path (%d tiles)" % path.size())
		passed += 1
	else:
		print("FAIL plan_path_to in-range: got empty path")
		failed += 1

	# ---- plan_path_to the unit's own tile → non-empty size-1 path ----
	# Confirming on the unit's own tile is a legal "stand still and act" move;
	# get_movement_path special-cases start == target to [start]. _try_move_selected_
	# to_cursor relies on this being non-empty so the ActionMenu still opens.
	var own_path := sel.plan_path_to(Vector2i(2, 2))
	if own_path.size() == 1 and own_path[0] == Vector2i(2, 2):
		print("OK  plan_path_to the unit's own tile → size-1 path [own tile]")
		passed += 1
	else:
		print("FAIL plan_path_to own tile: got %s" % str(own_path))
		failed += 1

	# ---- plan_path_to an out-of-range tile → [] ----
	# Find any tile not in movement_tiles — either out of cost range, or excluded
	# because it is occupied (the enemy at (4,4)). plan_path_to must reject it.
	var out_tile := Vector2i(-1, -1)
	for y in 6:
		for x in 6:
			if not (Vector2i(x, y) in sel.movement_tiles):
				out_tile = Vector2i(x, y)
				break
		if out_tile != Vector2i(-1, -1):
			break
	if sel.plan_path_to(out_tile).is_empty():
		print("OK  plan_path_to an out-of-range tile %s → []" % str(out_tile))
		passed += 1
	else:
		print("FAIL plan_path_to out-of-range: expected []")
		failed += 1

	# ---- undo_and_reselect: unit kept, range recomputed ----
	sel.undo_and_reselect()
	if sel.selected_unit == p and sel.movement_tiles.size() > 0:
		print("OK  undo_and_reselect keeps the unit and recomputes the range")
		passed += 1
	else:
		print("FAIL undo_and_reselect: unit=%s tiles=%d" \
			% [str(sel.selected_unit), sel.movement_tiles.size()])
		failed += 1

	# ---- clear: nulls the unit, empties the tiles ----
	sel.clear()
	if sel.selected_unit == null and sel.movement_tiles.is_empty():
		print("OK  clear nulls the selected unit and empties movement_tiles")
		passed += 1
	else:
		print("FAIL clear: unit=%s tiles=%d" \
			% [str(sel.selected_unit), sel.movement_tiles.size()])
		failed += 1

	# ---- select_at on an already-acted unit → false ----
	turn.set_unit_state(p, TurnManager.UnitState.DONE)
	if not sel.select_at(Vector2i(2, 2)):
		print("OK  select_at on a DONE unit → false (can_unit_act false)")
		passed += 1
	else:
		print("FAIL select_at acted: expected false")
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
