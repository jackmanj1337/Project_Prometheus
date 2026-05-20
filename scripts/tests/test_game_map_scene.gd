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

	# HUD must not eat mouse input (#5): a full-rect Control with the default
	# MOUSE_FILTER_STOP swallows clicks before they reach MapCursor. The root and
	# its panels must be MOUSE_FILTER_IGNORE so the mouse can drive the cursor.
	var hud := instance.get_node_or_null("HUDMainLayer/HUD")
	if hud != null:
		var hud_ok: bool = hud.mouse_filter == Control.MOUSE_FILTER_IGNORE
		for panel in ["UnitInfoPanel", "TerrainInfoPanel"]:
			var p := hud.get_node_or_null(panel)
			if p != null and p.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				hud_ok = false
		if hud_ok:
			print("OK  HUD + panels ignore mouse input (#5)")
			passed += 1
		else:
			print("FAIL HUD or a panel still captures mouse input (#5)")
			failed += 1
	else:
		print("FAIL HUDMainLayer/HUD not found")
		failed += 1

	# Verify Camera2D limits
	var cam: Camera2D = instance.get_node("Camera2D")
	if cam.limit_right == 42 * 64 and cam.limit_bottom == 26 * 64:
		print("OK  Camera limits: %d x %d" % [cam.limit_right, cam.limit_bottom])
		passed += 1
	else:
		print("FAIL camera limits: %d x %d" % [cam.limit_right, cam.limit_bottom])
		failed += 1

	# Camera follows the enemy phase (#7): _on_phase_changed enables position
	# smoothing only during the enemy phase, so the camera glides for AI moves
	# but stays snappy for the cursor during the player phase.
	instance._on_phase_changed(GameState.Phase.ENEMY)
	var smooth_on := cam.position_smoothing_enabled
	instance._on_phase_changed(GameState.Phase.PLAYER)
	var smooth_off := not cam.position_smoothing_enabled
	if smooth_on and smooth_off:
		print("OK  enemy phase enables camera smoothing, player phase disables it (#7)")
		passed += 1
	else:
		print("FAIL camera smoothing toggle: on=%s off=%s" % [smooth_on, smooth_off])
		failed += 1

	# Verify units spawned (6 player + 8 enemy = 14 total) if GameState is available
	var gs := root.get_node_or_null("GameState")
	if gs:
		# _on_ai_unit_acting centres the camera on the acting unit (#7).
		var grid_node: GridManager = instance.get_node("GridManager")
		var ai_units: Array = gs.get_living_enemy_units()
		if not ai_units.is_empty():
			var focus_unit = ai_units[0]
			instance._on_ai_unit_acting(focus_unit)
			var half := Vector2(64, 64) * 0.5
			var want := grid_node.tile_to_world(focus_unit.tile_position) + half
			if cam.position == want:
				print("OK  _on_ai_unit_acting centres the camera on the unit (#7)")
				passed += 1
			else:
				print("FAIL ai camera pan: cam=%s want=%s" % [cam.position, want])
				failed += 1

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
		if soldier and soldier.tile_position == Vector2i(1, 9) and soldier.team == "blue":
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
		if boss and boss.tile_position == Vector2i(39, 12) and boss.team == "red":
			print("OK  E8_Boss spawned at (39,12) as enemy")
			passed += 1
		else:
			print("FAIL E8_Boss placement: " + str(boss))
			failed += 1
		# Playtest 3 #1: HPBar (a ProgressBar Control) must not eat mouse input
		# over the unit, or MapCursor's _unhandled_input never sees the event.
		# Default Control.mouse_filter is STOP — the regression risk we're guarding.
		if soldier:
			var hpbar: ProgressBar = soldier.get_node_or_null("HPBar")
			if hpbar != null and hpbar.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				print("OK  Unit HPBar ignores mouse input (playtest 3 #1)")
				passed += 1
			else:
				print("FAIL Unit HPBar mouse_filter = %d, want IGNORE (2)" % (
					hpbar.mouse_filter if hpbar != null else -1))
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
	for ref_name in ["action_menu", "item_menu", "map_menu", "attack_preview", "settings_screen"]:
		if cursor.get(ref_name) != null:
			print("OK  MapCursor.%s resolved" % ref_name)
			passed += 1
		else:
			print("FAIL MapCursor.%s is null" % ref_name)
			failed += 1

	# Cursor starts on a player unit, not the map's (0,0) corner (#9).
	if gs:
		var cursor_unit = grid.get_unit_at(cursor.current_tile)
		if cursor.current_tile != Vector2i(0, 0) and cursor_unit != null \
				and cursor_unit.team == "blue":
			print("OK  cursor starts on a player unit at %s" % str(cursor.current_tile))
			passed += 1
		else:
			print("FAIL cursor start tile: %s" % str(cursor.current_tile))
			failed += 1

	# Camera keeps the cursor on-screen as it moves to a far map corner (#2).
	cursor._set_tile(Vector2i(40, 24))   # far corner of the 42x26 map
	var view: Vector2 = instance.get_viewport().get_visible_rect().size
	var cur_world: Vector2 = grid.tile_to_world(cursor.current_tile)
	var half: Vector2 = view * 0.5
	if cur_world.x >= cam.position.x - half.x and cur_world.x <= cam.position.x + half.x \
			and cur_world.y >= cam.position.y - half.y and cur_world.y <= cam.position.y + half.y:
		print("OK  camera keeps the cursor on-screen at a far tile")
		passed += 1
	else:
		print("FAIL cursor off-screen: cursor=%s cam=%s" % [str(cur_world), str(cam.position)])
		failed += 1

	# Enemy danger zone counts movement range, not just standstill attack (#11).
	if gs:
		var danger_count := grid.get_enemy_danger_tiles().size()
		# Reference: attack tiles from each enemy's CURRENT position only (old behaviour).
		var standstill := {}
		for eu in instance.get_node("UnitsContainer").get_children():
			if eu.team == "red" and eu.data and eu.data.hp > 0:
				var from_here: Array[Vector2i] = [eu.tile_position]
				for t in grid.get_all_attack_tiles(eu, from_here):
					standstill[t] = true
		if danger_count > standstill.size():
			print("OK  danger zone counts movement (%d tiles > %d standstill)" % [
				danger_count, standstill.size()])
			passed += 1
		else:
			print("FAIL danger zone ignores movement: %d vs %d standstill" % [
				danger_count, standstill.size()])
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
