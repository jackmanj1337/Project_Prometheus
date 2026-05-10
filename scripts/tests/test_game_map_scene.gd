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

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
