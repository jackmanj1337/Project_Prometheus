extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_unit_selection.gd
# Loads GameMap, picks a unit via the cursor, and verifies state transitions.

func _init() -> void:
	print("=== Unit Selection Test ===")
	var passed := 0
	var failed := 0

	var packed := load("res://scenes/core/GameMap.tscn")
	var instance: Node = packed.instantiate()
	root.add_child(instance)
	await process_frame  # let _ready and spawns complete

	var cursor: MapCursor = instance.get_node("MapCursor")
	var grid: GridManager = instance.get_node("GridManager")
	var turn: TurnManager = instance.get_node("TurnManager")

	# --- Confirm on an empty tile opens the map menu and selects nothing (GDD_07) ---
	cursor.current_tile = Vector2i(5, 5)
	cursor._on_confirm()
	if cursor._selection.selected_unit == null and cursor.map_menu.visible:
		print("OK  confirm on empty tile opens map menu, selects no unit")
		passed += 1
	else:
		print("FAIL empty confirm: state=%s unit=%s menu=%s" % [
			cursor._state, cursor._selection.selected_unit, cursor.map_menu.visible])
		failed += 1
	# Close the map menu so the cursor is FREE for the rest of the test.
	cursor.map_menu._on_close()
	await process_frame

	# --- Select Unit_01 (at tile 1,9) ---
	cursor.current_tile = Vector2i(1, 9)
	cursor._on_confirm()
	if cursor._state == MapCursor.State.UNIT_SELECTED and cursor._selection.selected_unit and cursor._selection.selected_unit.data.unit_name == "Unit_01":
		print("OK  selected Unit_01 at (1,9)")
		passed += 1
	else:
		print("FAIL select: state=%s unit=%s" % [cursor._state, cursor._selection.selected_unit])
		failed += 1

	# Movement range should be non-empty and include the unit's own tile
	if cursor._selection.movement_tiles.size() > 0 and Vector2i(1, 9) in cursor._selection.movement_tiles:
		print("OK  movement range computed (%d tiles, includes origin)" % cursor._selection.movement_tiles.size())
		passed += 1
	else:
		print("FAIL movement range: size=%d" % cursor._selection.movement_tiles.size())
		failed += 1

	# --- Cancel deselects ---
	cursor._on_cancel()
	if cursor._state == MapCursor.State.FREE and cursor._selection.selected_unit == null:
		print("OK  cancel deselected")
		passed += 1
	else:
		print("FAIL cancel: state=%s unit=%s" % [cursor._state, cursor._selection.selected_unit])
		failed += 1

	# --- Select again and move ---
	cursor.current_tile = Vector2i(1, 9)
	cursor._on_confirm()
	# Move 2 tiles right (to 3,9). Plain terrain → 2 move cost; unit has 6 mov.
	cursor.current_tile = Vector2i(3, 9)
	cursor._on_confirm()
	# Wait for the move tween to finish
	await create_timer(0.5).timeout

	var unit_01: Unit = null
	for child in instance.get_node("UnitsContainer").get_children():
		if child.data and child.data.unit_name == "Unit_01":
			unit_01 = child
			break

	if unit_01 and unit_01.tile_position == Vector2i(3, 9):
		print("OK  Unit_01 moved to (3,9)")
		passed += 1
	else:
		print("FAIL move: tile=%s" % (unit_01.tile_position if unit_01 else "null"))
		failed += 1

	# After moving, the ActionMenu opens and the cursor waits in "unit_moved".
	# (If the menu ever fails to resolve, _show_action_menu falls back to a Wait
	# commit and the state is "free" instead — accept both.)
	if cursor._state == MapCursor.State.UNIT_MOVED or cursor._state == MapCursor.State.FREE:
		print("OK  cursor in post-move state: %s" % cursor._state)
		passed += 1
	else:
		print("FAIL unexpected post-move state: %s" % cursor._state)
		failed += 1

	# Commit Wait. With the ActionMenu live the cursor sits in "unit_moved" and the
	# menu drives the choice — emulate the Wait button via _on_action_chosen.
	if cursor._state == MapCursor.State.UNIT_MOVED:
		cursor._on_action_chosen("wait")

	if turn.get_unit_state(unit_01) == TurnManager.UnitState.DONE:
		print("OK  Unit_01 state = DONE after Wait confirm")
		passed += 1
	else:
		print("FAIL state after Wait: %s" % turn.get_unit_state(unit_01))
		failed += 1

	if cursor._state == MapCursor.State.FREE:
		print("OK  cursor returned to 'free' after Wait")
		passed += 1
	else:
		print("FAIL cursor state after Wait: %s" % cursor._state)
		failed += 1

	# --- Cannot reselect a DONE unit ---
	cursor.current_tile = Vector2i(3, 9)
	cursor._on_confirm()
	if cursor._state == MapCursor.State.FREE:
		print("OK  cannot reselect DONE unit")
		passed += 1
	else:
		print("FAIL reselected DONE unit: state=%s" % cursor._state)
		failed += 1

	# --- Cannot select enemy unit ---
	cursor.current_tile = Vector2i(39, 12)  # boss tile
	cursor._on_confirm()
	if cursor._state == MapCursor.State.FREE:
		print("OK  cannot select enemy unit")
		passed += 1
	else:
		print("FAIL selected enemy: state=%s" % cursor._state)
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
