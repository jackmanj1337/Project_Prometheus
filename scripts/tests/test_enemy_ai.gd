extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_enemy_ai.gd
# Tests EnemyAI._find_nearest and _choose_move_tile using real GridManager + stub units.

func _init() -> void:
	print("=== EnemyAI Test ===")
	var passed := 0
	var failed := 0

	var ai: Node = load("res://scripts/core/EnemyAI.gd").new()
	root.add_child(ai)

	# Stub script: a Node subclass with the members EnemyAI reads. _weapon defaults to
	# null → GridManager._get_weapon_range → (1,1). perform_staff_heal records that it
	# was called so the staff-heal tests can assert on it.
	var stub_script := GDScript.new()
	stub_script.source_code = "extends Node\nvar tile_position: Vector2i = Vector2i.ZERO\nvar team: String = \"enemy\"\nvar data = null\nvar _weapon = null\nvar staff_heal_called: bool = false\nfunc get_equipped_weapon(): return _weapon\nfunc perform_staff_heal(_t, _w): staff_heal_called = true\n"
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

	# ---- dijkstra_costs: terrain cost accumulates; walled tiles are unreachable ----
	# Row-0 corridor: plain, plain, forest (cost 2), plain. Every other tile is unset
	# and so reads as "wall" in headless mode, keeping the flood on row 0.
	var cost_grid := GridManager.new()
	cost_grid.map_width = 5
	cost_grid.map_height = 5
	cost_grid.set_terrain_fallback(Vector2i(0, 0), "plain")
	cost_grid.set_terrain_fallback(Vector2i(1, 0), "plain")
	cost_grid.set_terrain_fallback(Vector2i(2, 0), "forest")
	cost_grid.set_terrain_fallback(Vector2i(3, 0), "plain")
	root.add_child(cost_grid)
	var flood := cost_grid.dijkstra_costs(Vector2i(0, 0), 1_000_000, true, null)
	# (3,0): enter(1,0)=1 + enter(2,0)=2 (forest) + enter(3,0)=1 = 4.
	if flood.get(Vector2i(0, 0), -1) == 0 and flood.get(Vector2i(3, 0), -1) == 4:
		print("OK  dijkstra_costs: forest tile adds +2 to accumulated path cost")
		passed += 1
	else:
		print("FAIL dijkstra_costs: (0,0)=%s (3,0)=%s, want 0 / 4" \
			% [flood.get(Vector2i(0,0), -1), flood.get(Vector2i(3,0), -1)])
		failed += 1
	if not flood.has(Vector2i(0, 1)):
		print("OK  dijkstra_costs: walled (unset) tile is unreachable")
		passed += 1
	else:
		print("FAIL dijkstra_costs: walled tile (0,1) was reached")
		failed += 1

	# ---- _find_nearest (grid branch): lowest path cost wins, not Manhattan distance ----
	# A wall at (1,0) forces a 4-step detour to target A at (2,0); target B at (0,3) is
	# a straight 3-step corridor. Manhattan would pick A (dist 2 < 3); the terrain-aware
	# Dijkstra flood must pick B.
	var fn_grid := GridManager.new()
	fn_grid.map_width = 6
	fn_grid.map_height = 6
	for t in [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3),
			Vector2i(1,1), Vector2i(2,1), Vector2i(2,0)]:
		fn_grid.set_terrain_fallback(t, "plain")
	root.add_child(fn_grid)
	var fn_from: Node = stub_script.new(); fn_from.set("tile_position", Vector2i(0, 0))
	var fn_a: Node = stub_script.new(); fn_a.set("tile_position", Vector2i(2, 0))
	var fn_b: Node = stub_script.new(); fn_b.set("tile_position", Vector2i(0, 3))
	root.add_child(fn_from); root.add_child(fn_a); root.add_child(fn_b)
	var fn_targets: Array[Node] = [fn_a, fn_b]
	if ai._find_nearest(fn_from, fn_targets, fn_grid) == fn_b:
		print("OK  _find_nearest (grid): terrain-cheaper target beats Manhattan-nearer one")
		passed += 1
	else:
		print("FAIL _find_nearest (grid): expected the detoured-around target B")
		failed += 1

	# ---- _choose_heal_move_tile: routes to a tile that puts an injured ally in range ----
	var heal_grid := GridManager.new()
	heal_grid.map_width = 6
	heal_grid.map_height = 6
	for x in 6:
		heal_grid.set_terrain_fallback(Vector2i(x, 0), "plain")
	root.add_child(heal_grid)
	var healer: Node = stub_script.new(); healer.set("tile_position", Vector2i(0, 0))
	var injured: Node = stub_script.new(); injured.set("tile_position", Vector2i(4, 0))
	var injured_data := UnitData.new()
	injured_data.hp = 5
	injured_data.max_hp = 20
	injured.set("data", injured_data)
	root.add_child(healer); root.add_child(injured)
	var gs_stub_script := GDScript.new()
	gs_stub_script.source_code = "extends Node\nvar units: Array[Node] = []\nfunc get_living_enemy_units() -> Array[Node]: return units\n"
	gs_stub_script.reload()
	var gs_stub: Node = gs_stub_script.new()
	var heal_allies: Array[Node] = [healer, injured]
	gs_stub.set("units", heal_allies)
	root.add_child(gs_stub)
	var heal_tiles: Array[Vector2i] = [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)]
	var heal_choice: Vector2i = ai._choose_heal_move_tile(healer, heal_tiles, heal_grid, gs_stub)
	# Range 1 (no weapon) → only (3,0) is adjacent to the injured ally at (4,0).
	if heal_choice == Vector2i(3, 0):
		print("OK  _choose_heal_move_tile: routes to a tile adjacent to the injured ally")
		passed += 1
	else:
		print("FAIL _choose_heal_move_tile: expected (3,0), got %s" % str(heal_choice))
		failed += 1

	# ---- _try_staff_heal: a non-staff weapon heals nobody ----
	var staff_grid := GridManager.new()
	root.add_child(staff_grid)
	var sword_enemy: Node = stub_script.new()
	sword_enemy.set("_weapon", load("res://data/weapons/iron_sword.tres"))
	root.add_child(sword_enemy)
	ai._try_staff_heal(sword_enemy, staff_grid)
	if not sword_enemy.get("staff_heal_called"):
		print("OK  _try_staff_heal: a non-staff weapon performs no heal")
		passed += 1
	else:
		print("FAIL _try_staff_heal: healed while wielding a non-staff weapon")
		failed += 1

	# ---- _try_staff_heal: a staff with no healable allies in range heals nobody ----
	var staff_enemy: Node = stub_script.new()
	staff_enemy.set("_weapon", load("res://data/weapons/heal_staff.tres"))
	root.add_child(staff_enemy)
	ai._try_staff_heal(staff_enemy, staff_grid)
	if not staff_enemy.get("staff_heal_called"):
		print("OK  _try_staff_heal: a staff with no healable target performs no heal")
		passed += 1
	else:
		print("FAIL _try_staff_heal: healed with no valid target")
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
