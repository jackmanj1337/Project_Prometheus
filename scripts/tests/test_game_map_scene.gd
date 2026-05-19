extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_game_map_scene.gd
# Loads GameMap.tscn and verifies it instantiates and paints terrain correctly.

func _init() -> void:
	print("=== GameMap Scene Test ===")
	var passed := 0
	var failed := 0

	var packed := load("res://scenes/core/GameMap.tscn")
	if packed == null:
		print("FAIL could not load GameMap.tscn")
		quit(1)
		return
	print("OK  GameMap.tscn loaded")
	passed += 1

	var instance: Node = packed.instantiate()
	if instance == null:
		print("FAIL instantiate() returned null")
		quit(1)
		return
	print("OK  instantiate() returned a node")
	passed += 1

	# Add to root so @onready and _ready run
	root.add_child(instance)
	# One frame to let _ready complete
	await process_frame

	# Verify expected child nodes exist
	for child in ["TileMapLayer_Terrain", "TileMapLayer_Overlay", "UnitsContainer",
			"MapCursor", "Camera2D", "GridManager"]:
		if instance.has_node(child):
			print("OK  child node: " + child)
			passed += 1
		else:
			print("FAIL missing child: " + child)
			failed += 1

	# Verify the terrain layer was painted (one cell at corner should be wall)
	var terrain: TileMapLayer = instance.get_node("TileMapLayer_Terrain")
	var tile_data := terrain.get_cell_tile_data(Vector2i(0, 0))
	if tile_data and tile_data.get_custom_data("terrain_type") == "wall":
		print("OK  (0,0) painted as wall")
		passed += 1
	else:
		print("FAIL (0,0) terrain")
		failed += 1
	tile_data = terrain.get_cell_tile_data(Vector2i(7, 6))
	if tile_data and tile_data.get_custom_data("terrain_type") == "fort":
		print("OK  (7,6) painted as fort (player-side)")
		passed += 1
	else:
		print("FAIL (7,6) fort")
		failed += 1
	tile_data = terrain.get_cell_tile_data(Vector2i(20, 20))
	if tile_data and tile_data.get_custom_data("terrain_type") == "desert":
		print("OK  (20,20) painted as desert")
		passed += 1
	else:
		print("FAIL (20,20) desert")
		failed += 1

	# Verify GridManager was wired up (map dimensions set)
	var grid: GridManager = instance.get_node("GridManager")
	if grid.map_width == 42 and grid.map_height == 26:
		print("OK  GridManager dimensions: 42x26")
		passed += 1
	else:
		print("FAIL GridManager: %dx%d" % [grid.map_width, grid.map_height])
		failed += 1

	# Verify Camera2D limits
	var cam: Camera2D = instance.get_node("Camera2D")
	if cam.limit_right == 42 * 64 and cam.limit_bottom == 26 * 64:
		print("OK  Camera limits: %d x %d" % [cam.limit_right, cam.limit_bottom])
		passed += 1
	else:
		print("FAIL camera limits: %d x %d" % [cam.limit_right, cam.limit_bottom])
		failed += 1

	# Verify units spawned (6 player + 8 enemy = 14 total) if GameState is available
	var gs := root.get_node_or_null("GameState")
	if gs:
		var units_container: Node2D = instance.get_node("UnitsContainer")
		var unit_count := units_container.get_child_count()
		if unit_count == 14:
			print("OK  spawned 14 units (6 player + 8 enemy)")
			passed += 1
		else:
			print("FAIL unit count: got %d, want 14" % unit_count)
			failed += 1
		# Player Unit_01 should be at tile (1,9)
		var soldier: Unit = null
		for child in units_container.get_children():
			if child.data and child.data.unit_name == "Unit_01":
				soldier = child
				break
		if soldier and soldier.tile_position == Vector2i(1, 9) and soldier.team == "player":
			print("OK  Unit_01 spawned at (1,9) as player")
			passed += 1
		else:
			print("FAIL Unit_01 placement: " + str(soldier))
			failed += 1
		# Boss enemy E8 should be at (39, 12)
		var boss: Unit = null
		for child in units_container.get_children():
			if child.data and child.data.unit_name == "E8_Boss":
				boss = child
				break
		if boss and boss.tile_position == Vector2i(39, 12) and boss.team == "enemy":
			print("OK  E8_Boss spawned at (39,12) as enemy")
			passed += 1
		else:
			print("FAIL E8_Boss placement: " + str(boss))
			failed += 1
	else:
		print("SKIP unit spawn checks (GameState autoload not present in --script mode)")

	# TurnManager wiring
	var tm: TurnManager = instance.get_node("TurnManager")
	if tm and tm._map_data != null and tm._map_data.id == "map_001":
		print("OK  TurnManager.start_map called with map_001")
		passed += 1
	else:
		print("FAIL TurnManager not initialized")
		failed += 1

	# MapCursor menu references must resolve at runtime. If they are null the
	# action menu and map menu never open and the Item submenu never shows
	# (playtest findings #4 / #10).
	var cursor: MapCursor = instance.get_node("MapCursor")
	for ref_name in ["action_menu", "item_menu", "map_menu", "attack_preview"]:
		if cursor.get(ref_name) != null:
			print("OK  MapCursor.%s resolved" % ref_name)
			passed += 1
		else:
			print("FAIL MapCursor.%s is null" % ref_name)
			failed += 1

	# All player units should be READY at start
	if gs:
		var all_ready := true
		for u in gs.get_living_player_units():
			if tm.get_unit_state(u) != TurnManager.UnitState.READY:
				all_ready = false
				break
		if all_ready:
			print("OK  all player units start as READY")
			passed += 1
		else:
			print("FAIL units not READY at start")
			failed += 1

		# Turn number is 1 at start
		if gs.turn_number == 1:
			print("OK  turn_number = 1 at start")
			passed += 1
		else:
			print("FAIL turn_number = %d at start" % gs.turn_number)
			failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
