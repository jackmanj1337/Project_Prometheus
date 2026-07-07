extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_selection_cursor.gd

const SelectionCursor = preload("res://scripts/ui/SelectionCursor.gd")


func _init() -> void:
	print("=== SelectionCursor Test ===")
	var passed := 0
	var failed := 0

	var cursor: RefCounted = SelectionCursor.new()
	var seen: Array[int] = []
	cursor.changed.connect(func(index: int): seen.append(index))
	cursor.configure(3)
	cursor.advance(1)
	cursor.advance(1)
	cursor.advance(1)
	cursor.advance(1)
	if cursor.index == 0 and seen == [0, 1, 2, 0]:
		print("OK  advance starts from inactive and wraps forward")
		passed += 1
	else:
		print("FAIL forward wrap: index=%s seen=%s" % [cursor.index, str(seen)])
		failed += 1

	seen.clear()
	cursor.reset()
	cursor.advance(-1)
	if cursor.index == 2 and seen == [-1, 2]:
		print("OK  reverse advance from inactive lands on the last entry")
		passed += 1
	else:
		print("FAIL reverse first move: index=%s seen=%s" % [cursor.index, str(seen)])
		failed += 1

	seen.clear()
	cursor.configure(2, 1, true, true)
	cursor.set_index(1)
	cursor.advance(1)
	if cursor.index == -1 and seen == [1, -1]:
		print("OK  inactive stop participates when requested")
		passed += 1
	else:
		print("FAIL inactive stop: index=%s seen=%s" % [cursor.index, str(seen)])
		failed += 1

	seen.clear()
	cursor.configure(5, 2)
	cursor.set_index(1)
	cursor.move_2d(1, 0)
	var down_ok: bool = cursor.index == 3
	cursor.move_2d(1, 0)
	var ragged_ok: bool = cursor.index == 4
	cursor.move_2d(1, 0)
	var wrap_ok: bool = cursor.index == 0
	if down_ok and ragged_ok and wrap_ok:
		print("OK  grid movement keeps nearest column and wraps ragged rows")
		passed += 1
	else:
		print("FAIL grid movement: down=%s ragged=%s wrap=%s index=%d" % [
			down_ok, ragged_ok, wrap_ok, cursor.index])
		failed += 1

	var sparse: RefCounted = SelectionCursor.new()
	sparse.configure_positions([
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(2, 1),
		Vector2i(3, 0),
		Vector2i(3, 1),
	])
	sparse.set_index(0)
	sparse.move_2d(1, 0)
	var hp_ok: bool = sparse.index == 1
	sparse.set_index(3)
	sparse.move_2d(1, 0)
	var nearest_col_ok: bool = sparse.index == 5
	if hp_ok and nearest_col_ok:
		print("OK  sparse grid positions preserve visual rows and nearest columns")
		passed += 1
	else:
		print("FAIL sparse grid: hp=%s nearest_col=%s index=%d" % [
			hp_ok, nearest_col_ok, sparse.index])
		failed += 1

	var quiet_cursor: RefCounted = SelectionCursor.new()
	var quiet_seen: Array[int] = []
	quiet_cursor.changed.connect(func(index: int): quiet_seen.append(index))
	quiet_cursor.configure(2)
	quiet_cursor.set_index(0)
	quiet_cursor.set_index(0)
	quiet_cursor.advance(0)
	if quiet_seen == [0]:
		print("OK  changed fires only when the index changes")
		passed += 1
	else:
		print("FAIL duplicate signals: %s" % str(quiet_seen))
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
