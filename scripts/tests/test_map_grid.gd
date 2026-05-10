extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_map_grid.gd
# Validates the MAP_001 string grid: row count, row length, and char set.

func _init() -> void:
	print("=== Map Grid Test ===")
	var passed := 0
	var failed := 0

	# Pull the constants from GameMap class. We can't instantiate GameMap (it
	# extends Node2D and would complain about missing children) but we can
	# read its constants statically via the class.
	var rows: Array = GameMap.MAP_001
	var width: int = GameMap.MAP_WIDTH
	var height: int = GameMap.MAP_HEIGHT

	if rows.size() == height:
		print("OK  row count: %d" % rows.size())
		passed += 1
	else:
		print("FAIL row count: got %d, want %d" % [rows.size(), height])
		failed += 1

	var valid_chars := ".FMTSDW"
	for y in rows.size():
		var row: String = rows[y]
		if row.length() != width:
			print("FAIL row %d length: got %d, want %d  [%s]" % [y, row.length(), width, row])
			failed += 1
			continue
		var bad := false
		for x in row.length():
			var ch: String = row[x]
			if not (ch in valid_chars):
				print("FAIL row %d col %d: bad char '%s'" % [y, x, ch])
				bad = true
				failed += 1
				break
		if not bad:
			passed += 1

	# Spot checks of named terrain features per GDD_06
	var spot_checks := [
		[Vector2i(7, 6), "T", "player-side fort"],
		[Vector2i(38, 9), "T", "sub-boss fort"],
		[Vector2i(38, 12), "T", "boss throne fort"],
		[Vector2i(0, 0), "W", "NW corner"],
		[Vector2i(41, 25), "W", "SE corner"],
		[Vector2i(20, 20), "D", "desert center"],
		[Vector2i(17, 4), "S", "sea N"],
		[Vector2i(3, 2), "F", "forest NW"],
	]
	for check in spot_checks:
		var t: Vector2i = check[0]
		var want: String = check[1]
		var label: String = check[2]
		var got: String = rows[t.y][t.x]
		if got == want:
			print("OK  spot %s at %s = '%s'" % [label, t, got])
			passed += 1
		else:
			print("FAIL spot %s at %s: got '%s', want '%s'" % [label, t, got, want])
			failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
