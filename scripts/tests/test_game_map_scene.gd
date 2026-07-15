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

	var bus := root.get_node_or_null("EventBus")
	if bus == null:
		bus = load("res://scripts/autoloads/EventBus.gd").new()
		bus.name = "EventBus"
		root.add_child(bus)
	var dm := root.get_node_or_null("DataManager")
	if dm == null:
		dm = load("res://scripts/autoloads/DataManager.gd").new()
		dm.name = "DataManager"
		root.add_child(dm)
	var gs := root.get_node_or_null("GameState")
	if gs == null:
		gs = load("res://scripts/autoloads/GameState.gd").new()
		gs.name = "GameState"
		root.add_child(gs)
	var rng_svc := root.get_node_or_null("RngService")
	if rng_svc == null:
		rng_svc = load("res://scripts/autoloads/RngService.gd").new()
		rng_svc.name = "RngService"
		root.add_child(rng_svc)
	await process_frame
	gs.reset_map_state()
	gs.load_default_roster()
	gs.configure_next_map("res://data/maps/map_001_rout/map_001_data.tres", "default_roster", "")
	var occupancy := root.get_node_or_null("OccupancyService")
	if occupancy != null:
		occupancy.delayed_requests.append(RefCounted.new())

	# Add to root so @onready and _ready run
	root.add_child(instance)
	# One frame to let _ready complete
	await process_frame
	if occupancy != null and occupancy.delayed_requests.is_empty():
		print("OK  map start clears scene-scoped delayed placement requests")
		passed += 1
	else:
		print("FAIL map start retained delayed placement requests")
		failed += 1

	# Verify expected child nodes exist
	for child in [
		"TileMapLayer_Terrain",
		"TileMapLayer_Overlay",
		"UnitsContainer",
		"MapCursor",
		"Camera2D",
		"GridManager"
	]:
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
		# find_child (recursive) so the check survives the terrain panels being
		# re-parented under the TerrainCorner stack. The new corner wrapper and
		# the scrollable More Info box must also stay click-through.
		for panel in [
			"UnitInfoPanel", "TerrainCorner", "TerrainInfoPanel", "TerrainMoreInfoPanel", "Scroll"
		]:
			var p := hud.find_child(panel, true, false)
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

	# HUD More Info priority hosts should be injected by GameMap rather than
	# resolved through hard-coded scene paths.
	if hud != null:
		var injected_preview: Variant = hud.get("_attack_preview")
		var injected_details: Variant = hud.get("_unit_details_screen")
		if (
			injected_preview == instance.get_node("HUDLayer/AttackPreview")
			and injected_details == instance.get_node("UnitDetailsLayer/UnitDetailsScreen")
		):
			print("OK  HUD More Info hosts injected from GameMap")
			passed += 1
		else:
			print("FAIL HUD More Info hosts were not injected correctly")
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

	# Verify units spawned (6 player + 8 enemy = 14 total)
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
	# Map-start placement defaults to nearest_free. A collision must displace the
	# later unit instead of dropping it or aborting the map.
	if soldier:
		var fallback_data: UnitData = soldier.data.duplicate(true)
		fallback_data.unit_id = "fallback_spawn_test"
		fallback_data.unit_name = "FallbackSpawnTest"
		var fallback_unit: Unit = instance._place_and_spawn(
			fallback_data, soldier.tile_position, "red"
		)
		if fallback_unit != null and fallback_unit.tile_position != soldier.tile_position:
			print("OK  occupied map-start tile falls back to a nearest free tile")
			passed += 1
		else:
			print("FAIL map-start nearest-free fallback: %s" % str(fallback_unit))
			failed += 1
		if fallback_unit != null:
			gs.unregister_unit(fallback_unit)
			fallback_unit.queue_free()
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
			print(
				(
					"FAIL Unit HPBar mouse_filter = %d, want IGNORE (2)"
					% (hpbar.mouse_filter if hpbar != null else -1)
				)
			)
			failed += 1

	# TurnManager wiring
	var tm: TurnManager = instance.get_node("TurnManager")
	if tm and tm._map_data != null and tm._map_data.id == "map_001":
		print("OK  TurnManager.start_map called with map_001")
		passed += 1
	else:
		print("FAIL TurnManager not initialized")
		failed += 1

	# Fresh maps seed the gameplay RNG before the round-0 ledger entry, so Retry
	# (restore_history(0)) starts from a real per-map seed, not the default zero seed.
	var first_rng_snapshot: Dictionary = (
		gs.peek_history(0).get("map_runtime", {}).get("rng", {}) if gs else {}
	)
	if (
		rng_svc != null
		and int(rng_svc.get("map_seed")) != 0
		and int(rng_svc.get("history_hash")) == 0
		and int(first_rng_snapshot.get("map_seed", 0)) != 0
		and int(first_rng_snapshot.get("history_hash", -1)) == 0
	):
		print("OK  fresh GameMap seeds RngService before the Retry snapshot")
		passed += 1
	else:
		print(
			(
				"FAIL fresh map rng seed/snapshot: live=%s snapshot=%s"
				% [rng_svc.call("to_save_dict") if rng_svc else {}, first_rng_snapshot]
			)
		)
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
		if (
			cursor.current_tile != Vector2i(0, 0)
			and cursor_unit != null
			and cursor_unit.team == "blue"
		):
			print("OK  cursor starts on a player unit at %s" % str(cursor.current_tile))
			passed += 1
		else:
			print("FAIL cursor start tile: %s" % str(cursor.current_tile))
			failed += 1

	# Camera keeps the cursor on-screen as it moves to a far map corner (#2).
	cursor._set_tile(Vector2i(40, 24))  # far corner of the 42x26 map
	var view: Vector2 = instance.get_viewport().get_visible_rect().size
	var cur_world: Vector2 = grid.tile_to_world(cursor.current_tile)
	var half: Vector2 = view * 0.5
	if (
		cur_world.x >= cam.position.x - half.x
		and cur_world.x <= cam.position.x + half.x
		and cur_world.y >= cam.position.y - half.y
		and cur_world.y <= cam.position.y + half.y
	):
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
			print(
				(
					"OK  danger zone counts movement (%d tiles > %d standstill)"
					% [danger_count, standstill.size()]
				)
			)
			passed += 1
		else:
			print(
				(
					"FAIL danger zone ignores movement: %d vs %d standstill"
					% [danger_count, standstill.size()]
				)
			)
			failed += 1

	# Danger zone is computed from the viewer faction's perspective: from red's
	# POV, the tiles blue threatens are dangerous (not the tiles red threatens).
	# Code review 2026-06-10 issue 2.4.
	if gs:
		var blue_pov: Array[Vector2i] = grid.get_enemy_danger_tiles("blue")
		var red_pov: Array[Vector2i] = grid.get_enemy_danger_tiles("red")
		var blue_set := {}
		for t in blue_pov:
			blue_set[t] = true
		var red_set := {}
		for t in red_pov:
			red_set[t] = true
		# blue's POV must NOT include tiles only blue threatens, and red's POV
		# must include at least one such tile (the asymmetry is the test).
		var only_in_red: int = 0
		for t in red_pov:
			if not blue_set.has(t):
				only_in_red += 1
		var only_in_blue: int = 0
		for t in blue_pov:
			if not red_set.has(t):
				only_in_blue += 1
		if only_in_red > 0 and only_in_blue > 0:
			print(
				(
					"OK  danger zone is per-faction (blue-only=%d, red-only=%d tiles)"
					% [only_in_blue, only_in_red]
				)
			)
			passed += 1
		else:
			print(
				(
					"FAIL danger zone perspective: blue-only=%d red-only=%d"
					% [only_in_blue, only_in_red]
				)
			)
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

		# Map selector override: a second GameMap instance should honor the
		# selected map path and fixed test roster instead of the exported default.
		gs.reset_map_state()
		gs.load_roster_from_directory(
			"res://data/roster/test/map_900_hotseat_validation/", "fixed_test_roster"
		)
		gs.configure_next_map(
			"res://data/maps/map_900_hotseat_validation/map_900_hotseat_validation_data.tres",
			"fixed_test_roster",
			"res://data/roster/test/map_900_hotseat_validation/"
		)
		rng_svc.call("commit_event", "wait", ["rng_test_unit", "1,1", "1,1"] as Array[String])
		var hotseat_instance: Node = packed.instantiate()
		root.add_child(hotseat_instance)
		await process_frame
		var hotseat_tm: TurnManager = hotseat_instance.get_node("TurnManager")
		var hotseat_units: Node2D = hotseat_instance.get_node("UnitsContainer")
		var hotseat_green_found := false
		for child in hotseat_units.get_children():
			if child.team == "green":
				hotseat_green_found = true
				break
		if hotseat_tm._map_data != null and hotseat_tm._map_data.id == "map_900_hotseat_validation":
			print("OK  GameMap honors GameState.next_map_data_path for the selected map")
			passed += 1
		else:
			print("FAIL selected map override not applied")
			failed += 1
		if hotseat_units.get_child_count() == 7 and hotseat_green_found:
			print("OK  selected hotseat map spawns the fixed roster plus green/red/yellow units")
			passed += 1
		else:
			print(
				(
					"FAIL hotseat map spawn count/factions: count=%d green=%s"
					% [hotseat_units.get_child_count(), hotseat_green_found]
				)
			)
			failed += 1
		var second_rng_snapshot: Dictionary = gs.peek_history(0).get("map_runtime", {}).get(
			"rng", {}
		)
		if (
			int(rng_svc.get("map_seed")) != 0
			and int(rng_svc.get("history_hash")) == 0
			and int(second_rng_snapshot.get("map_seed", 0)) != 0
			and int(second_rng_snapshot.get("history_hash", -1)) == 0
		):
			print("OK  second same-session fresh GameMap resets RNG history before snapshot")
			passed += 1
		else:
			print(
				(
					"FAIL second fresh map rng history: live=%s snapshot=%s"
					% [rng_svc.call("to_save_dict"), second_rng_snapshot]
				)
			)
			failed += 1

		# A fresh map boot must wipe stale map-scoped GameState data left behind
		# by a prior battle/menu transition instead of appending on top of it.
		gs.all_units.append(Node.new())
		gs.turn_number = 9
		var clean_boot_instance: Node = packed.instantiate()
		root.add_child(clean_boot_instance)
		await process_frame
		var clean_units: Node2D = clean_boot_instance.get_node("UnitsContainer")
		if gs.turn_number == 1 and gs.all_units.size() == clean_units.get_child_count():
			print("OK  GameMap resets stale GameState map state before spawning")
			passed += 1
		else:
			print(
				(
					"FAIL stale map state leaked into fresh GameMap: turn=%d all_units=%d scene_units=%d"
					% [gs.turn_number, gs.all_units.size(), clean_units.get_child_count()]
				)
			)
			failed += 1

		# Objective showcase smoke: each newly-authored selector map should boot
		# through the selected-map override path with the default roster.
		var objective_maps := [
			{
				"id": "map_002_seize",
				"path": "res://data/maps/map_002_seize/map_002_seize_data.tres",
				"enemy_count": 4
			},
			{
				"id": "map_003_defeat_boss",
				"path": "res://data/maps/map_003_defeat_boss/map_003_defeat_boss_data.tres",
				"enemy_count": 5
			},
			{
				"id": "map_004_escape",
				"path": "res://data/maps/map_004_escape/map_004_escape_data.tres",
				"enemy_count": 4
			},
			{
				"id": "map_005_defend",
				"path": "res://data/maps/map_005_defend/map_005_defend_data.tres",
				"enemy_count": 5
			},
		]
		for map_info in objective_maps:
			gs.reset_map_state()
			gs.load_default_roster()
			gs.configure_next_map(map_info["path"], "default_roster", "")
			var objective_instance: Node = packed.instantiate()
			root.add_child(objective_instance)
			await process_frame
			var objective_tm: TurnManager = objective_instance.get_node("TurnManager")
			var objective_units: Node2D = objective_instance.get_node("UnitsContainer")
			var expected_total: int = gs.player_roster.size() + int(map_info["enemy_count"])
			if objective_tm._map_data != null and objective_tm._map_data.id == map_info["id"]:
				print("OK  GameMap boots %s via selected-map override" % map_info["id"])
				passed += 1
			else:
				print(
					(
						"FAIL objective map override: got=%s want=%s"
						% [
							objective_tm._map_data.id if objective_tm._map_data != null else "null",
							map_info["id"]
						]
					)
				)
				failed += 1
			if objective_units.get_child_count() == expected_total:
				print("OK  %s spawns default roster + authored enemies" % map_info["id"])
				passed += 1
			else:
				print(
					(
						"FAIL %s unit count: got=%d want=%d"
						% [map_info["id"], objective_units.get_child_count(), expected_total]
					)
				)
				failed += 1

		# Missing explicit roster prep should fail loud instead of silently loading
		# the default roster from inside GameMap.
		gs.reset_map_state()
		gs.player_roster.clear()
		gs.roster_initialized = false
		gs.roster_load_failed = false
		gs.active_roster_policy = ""
		gs.active_roster_source = ""
		gs.configure_next_map(
			"res://data/maps/map_001_rout/map_001_data.tres", "default_roster", ""
		)
		var bad_boot_instance: Node = packed.instantiate()
		root.add_child(bad_boot_instance)
		await process_frame
		var bad_units: Node2D = bad_boot_instance.get_node("UnitsContainer")
		if bad_units.get_child_count() == 0:
			print("OK  GameMap refuses to silently bootstrap a missing roster")
			passed += 1
		else:
			print(
				(
					"FAIL GameMap silently spawned %d units without explicit roster prep"
					% bad_units.get_child_count()
				)
			)
			failed += 1

		# An individual no-free-tile result is logged and skipped, but is not a
		# structural boot failure. Use a zero-sized grid to force that result.
		var blocked_data := UnitData.new()
		blocked_data.unit_id = "blocked_spawn_test"
		blocked_data.unit_name = "BlockedSpawnTest"
		gs.player_roster.assign([blocked_data])
		gs.roster_initialized = true
		gs.roster_load_failed = false
		gs.configure_next_map("res://test_map.tres", "keep_current_roster", "")
		var blocked_map := MapData.new()
		blocked_map.player_start_tiles.assign([Vector2i.ZERO])
		bad_boot_instance.map_data = blocked_map
		var blocked_grid: GridManager = bad_boot_instance.get_node("GridManager")
		var saved_width: int = blocked_grid.map_width
		var saved_height: int = blocked_grid.map_height
		blocked_grid.map_width = 0
		blocked_grid.map_height = 0
		var placement_failure_nonfatal: bool = bad_boot_instance._spawn_units()
		blocked_grid.map_width = saved_width
		blocked_grid.map_height = saved_height
		if placement_failure_nonfatal and bad_units.get_child_count() == 0:
			print("OK  a no-free-tile placement skips the unit without failing map spawn")
			passed += 1
		else:
			print("FAIL placement failure aborted map spawn or created a unit")
			failed += 1

	# ---- B4-PREP-DEPLOYMENT Slice 1: the explicit deployment plan ----
	# The plan is the whole point of prep: deployment stops being INFERRED from
	# roster order and becomes a choice GameMap consumes.
	var map_for_plan: MapData = load("res://data/maps/map_001_rout/map_001_data.tres")
	var start_tiles: Array[Vector2i] = map_for_plan.player_start_tiles

	gs.reset_map_state()
	gs.load_default_roster()
	gs.configure_next_map("res://data/maps/map_001_rout/map_001_data.tres", "default_roster", "")
	var roster: Array[UnitData] = gs.player_roster
	# Deliberately NOT roster order: the THIRD roster unit takes the FIRST start
	# tile. Roster-order inference could never produce this placement, so passing
	# proves the plan was consumed rather than re-derived.
	(
		gs
		. set_next_map_deployment(
			{
				roster[2].unit_id: start_tiles[0],
				roster[0].unit_id: start_tiles[1],
			}
		)
	)
	var plan_instance: Node = packed.instantiate()
	root.add_child(plan_instance)
	await process_frame
	var planned: Array[Node] = _blue_units(plan_instance)
	if (
		planned.size() == 2
		and _tile_of(planned, roster[2].unit_id) == start_tiles[0]
		and _tile_of(planned, roster[0].unit_id) == start_tiles[1]
	):
		print("OK  an explicit plan deploys the named units on the named tiles")
		passed += 1
	else:
		print("FAIL plan spawned %d blue units: %s" % [planned.size(), _describe(planned)])
		failed += 1

	# An illegal plan must refuse to launch rather than spawn a half-legal board —
	# prep gates Begin Battle, so a bad plan here means the party or map changed
	# underneath it.
	var before_illegal: int = plan_instance.get_node("UnitsContainer").get_child_count()
	gs.set_next_map_deployment({"not_in_the_party": start_tiles[0]})
	var illegal_spawned: bool = plan_instance._spawn_units()
	if (
		not illegal_spawned
		and plan_instance.get_node("UnitsContainer").get_child_count() == before_illegal
	):
		print("OK  GameMap refuses an illegal plan instead of spawning a partial board")
		passed += 1
	else:
		print("FAIL GameMap spawned from an illegal deployment plan")
		failed += 1
	plan_instance.queue_free()
	await process_frame

	# No plan = every launch path that has no prep screen (the bare single-map
	# launch). It must behave EXACTLY as it did before this slice: roster slot N
	# onto player_start_tiles[N], truncated by the tile count.
	gs.reset_map_state()
	gs.load_default_roster()
	gs.configure_next_map("res://data/maps/map_001_rout/map_001_data.tres", "default_roster", "")
	gs.clear_next_map_deployment()
	var fallback_instance: Node = packed.instantiate()
	root.add_child(fallback_instance)
	await process_frame
	var fallback_blue: Array[Node] = _blue_units(fallback_instance)
	var expected_count: int = mini(gs.player_roster.size(), start_tiles.size())
	if (
		fallback_blue.size() == expected_count
		and _tile_of(fallback_blue, gs.player_roster[0].unit_id) == start_tiles[0]
		and _tile_of(fallback_blue, gs.player_roster[1].unit_id) == start_tiles[1]
	):
		print("OK  an absent plan falls back to the roster-order rule unchanged")
		passed += 1
	else:
		print(
			(
				"FAIL fallback spawned %d blue units (expected %d): %s"
				% [fallback_blue.size(), expected_count, _describe(fallback_blue)]
			)
		)
		failed += 1
	fallback_instance.queue_free()
	await process_frame

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


# The player-faction units spawned into a GameMap instance. UnitsContainer holds
# the enemy placements too, so the deployment assertions must filter by faction.
static func _blue_units(map_instance: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in map_instance.get_node("UnitsContainer").get_children():
		if "team" in child and child.team == "blue":
			out.append(child)
	return out


# Tile the named unit stands on, or (-999, -999) if it never deployed — a
# sentinel no start tile can equal, so a missing unit fails its assertion.
static func _tile_of(units: Array[Node], unit_id: String) -> Vector2i:
	for unit in units:
		if unit.data != null and unit.data.unit_id == unit_id:
			return unit.tile_position
	return Vector2i(-999, -999)


static func _describe(units: Array[Node]) -> String:
	var out: Array[String] = []
	for unit in units:
		out.append("%s@%s" % [unit.data.unit_id, unit.tile_position])
	return ", ".join(out)
