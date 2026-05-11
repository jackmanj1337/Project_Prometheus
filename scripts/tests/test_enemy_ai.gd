extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_enemy_ai.gd
# Tests EnemyAI._find_nearest and _choose_move_tile using real GridManager + stub units.

func _init() -> void:
	print("=== EnemyAI Test ===")
	var passed := 0
	var failed := 0

	var ai: Node = load("res://scripts/core/EnemyAI.gd").new()
	root.add_child(ai)

	# Stub script: a Node subclass with tile_position and team properties.
	# get_equipped_weapon returns null → GridManager._get_weapon_range → (1,1) default.
	var stub_script := GDScript.new()
	stub_script.source_code = "extends Node\nvar tile_position: Vector2i = Vector2i.ZERO\nvar team: String = \"enemy\"\nfunc get_equipped_weapon(): return null\n"
	stub_script.reload()

	# ---- _find_nearest: returns closer of two units ----
	var from_unit: Node = stub_script.new()
	from_unit.set("tile_position", Vector2i(0, 0))
	var far: Node = stub_script.new()
	far.set("tile_position", Vector2i(5, 0))   # dist 5
	var near: Node = stub_script.new()
	near.set("tile_position", Vector2i(2, 0))  # dist 2
	root.add_child(from_unit); root.add_child(far); root.add_child(near)

	var targets: Array[Node] = [far, near]
	var nearest: Node = ai._find_nearest(from_unit, targets)
	if nearest == near:
		print("OK  _find_nearest returns closer unit (dist 2 vs 5)")
		passed += 1
	else:
		print("FAIL _find_nearest: got wrong unit")
		failed += 1

	# ---- _find_nearest: equal distance → first wins ----
	var eq1: Node = stub_script.new(); eq1.set("tile_position", Vector2i(3, 0))
	var eq2: Node = stub_script.new(); eq2.set("tile_position", Vector2i(0, 3))
	root.add_child(eq1); root.add_child(eq2)
	var eq_targets: Array[Node] = [eq1, eq2]
	var eq_result: Node = ai._find_nearest(from_unit, eq_targets)
	if eq_result == eq1:
		print("OK  _find_nearest tie: first wins")
		passed += 1
	else:
		print("FAIL _find_nearest tie case")
		failed += 1

	# ---- _choose_move_tile: plain 5x5 grid, player at (4,0) ----
	# Enemy at (0,0), move_tiles [0..3 on x]. Default weapon range = 1..1
	# so tile (3,0) is the only moveable tile adjacent to player at (4,0).
	var grid := GridManager.new()
	grid.map_width = 5
	grid.map_height = 5
	for y in 5:
		for x in 5:
			grid.set_terrain_fallback(Vector2i(x, y), "plain")
	root.add_child(grid)

	var enemy: Node = stub_script.new(); enemy.set("tile_position", Vector2i(0, 0))
	var player: Node = stub_script.new()
	player.set("tile_position", Vector2i(4, 0))
	player.set("team", "player")
	root.add_child(enemy); root.add_child(player)

	var move_tiles: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
	]
	var all_players: Array[Node] = [player]
	var chosen: Vector2i = ai._choose_move_tile(enemy, player, all_players, move_tiles, grid)
	if chosen == Vector2i(3, 0):
		print("OK  _choose_move_tile picks attack tile (3,0) adjacent to player at (4,0)")
		passed += 1
	else:
		print("FAIL _choose_move_tile: expected (3,0), got %s" % str(chosen))
		failed += 1

	# ---- _choose_move_tile: player out of attack reach → just close distance ----
	var far_player: Node = stub_script.new()
	far_player.set("tile_position", Vector2i(10, 0))
	far_player.set("team", "player")
	root.add_child(far_player)
	var all_far: Array[Node] = [far_player]
	var chosen2: Vector2i = ai._choose_move_tile(enemy, far_player, all_far, move_tiles, grid)
	if chosen2 == Vector2i(3, 0):
		print("OK  _choose_move_tile moves toward unreachable player")
		passed += 1
	else:
		print("FAIL _choose_move_tile (no attack): expected (3,0), got %s" % str(chosen2))
		failed += 1

	# ---- _choose_move_tile: already at best tile → stays ----
	var enemy2: Node = stub_script.new(); enemy2.set("tile_position", Vector2i(3, 0))
	root.add_child(enemy2)
	var single_tile: Array[Vector2i] = [Vector2i(3, 0)]
	var chosen3: Vector2i = ai._choose_move_tile(enemy2, player, all_players, single_tile, grid)
	if chosen3 == Vector2i(3, 0):
		print("OK  _choose_move_tile stays when already adjacent")
		passed += 1
	else:
		print("FAIL _choose_move_tile stay: expected (3,0), got %s" % str(chosen3))
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
