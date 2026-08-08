extends SceneTree
# Regression: activating Tier-2 content must not delete engine placement policy entries.

const Context = preload("res://scripts/placement/OccupancyContext.gd")
const DataManagerScript = preload("res://scripts/autoloads/DataManager.gd")


func _init() -> void:
	print("=== v0.6.0 Registry Baseline Regression Test ===")
	var passed := 0
	var failed := 0
	var registry: Node = root.get_node_or_null("RegistryManager")
	var service: Node = root.get_node_or_null("OccupancyService")
	var manager: Node = root.get_node_or_null("DataManager")
	if registry == null:
		registry = load("res://scripts/autoloads/RegistryManager.gd").new()
		registry.name = "RegistryManager"
		root.add_child(registry)
	if service == null:
		service = load("res://scripts/autoloads/OccupancyService.gd").new()
		service.name = "OccupancyService"
		root.add_child(service)
	if manager == null:
		manager = DataManagerScript.new()
		manager.name = "DataManager"
		root.add_child(manager)
	await process_frame

	var source := "res://test_fixtures/campaign_packs/two_map_skirmish"
	var activated: bool = manager.activate_campaign_package(source, "two_map_skirmish", "1.0")
	var grid := GridManager.new()
	grid.map_width = 2
	grid.map_height = 1
	grid.set_terrain_fallback(Vector2i(0, 0), "plain")
	grid.set_terrain_fallback(Vector2i(1, 0), "plain")
	root.add_child(grid)
	var occupied: Array[Vector2i] = [Vector2i(0, 0)]
	var placement: RefCounted = service.place(
		Context.create(null, Vector2i(0, 0), "nearest_free"), grid, occupied
	)

	var placement_passed: bool = (
		activated
		and registry.has_entry("occupancy_policies", "nearest_free")
		and placement.ok
		and placement.fallback_used
		and placement.to_tile == Vector2i(1, 0)
	)
	if placement_passed:
		print("OK  Tier-2 activation preserves nearest_free through live placement")
		passed += 1
	else:
		print(
			(
				"FAIL activation=%s policy=%s placement_ok=%s reason=%s tile=%s"
				% [
					activated,
					registry.has_entry("occupancy_policies", "nearest_free"),
					placement.ok,
					placement.failure_reason,
					placement.to_tile,
				]
			)
		)
		failed += 1

	var gs: Node = root.get_node_or_null("GameState")
	if gs == null:
		gs = load("res://scripts/autoloads/GameState.gd").new()
		gs.name = "GameState"
		root.add_child(gs)
	await process_frame
	for fixture: Dictionary in [
		{
			"path": "res://test_fixtures/campaign_packs/two_map_skirmish",
			"package": "two_map_skirmish",
			"map": "skirmish_01",
			"blue": 2,
			"red": 3,
		},
		{
			"path": "res://test_fixtures/campaign_packs/branching_skirmish",
			"package": "branching_skirmish",
			"map": "skirmish_01",
			"blue": 2,
			"red": 3,
		},
	]:
		var package_id := String(fixture["package"])
		var selected: bool = manager.select_tier2_campaign_source(
			String(fixture["path"]), package_id, "1.0"
		)
		var entry: Dictionary = manager.get_map_registry_entry(String(fixture["map"]))
		var roster_id := String(entry.get("roster_source", ""))
		gs.reset_map_state()
		gs.configure_next_map(
			String(entry.get("map_data_path", "")),
			String(entry.get("roster_policy", "")),
			roster_id
		)
		var roster_ready: bool = gs.load_roster_resources(
			manager.get_campaign_pack_roster(roster_id), "campaign_pack_roster", roster_id
		)
		var map_instance: Node = load("res://scenes/core/GameMap.tscn").instantiate()
		root.add_child(map_instance)
		await process_frame
		var blue := 0
		var red := 0
		for unit: Node in map_instance.get_node("UnitsContainer").get_children():
			if unit.get("team") == "blue":
				blue += 1
			elif unit.get("team") == "red":
				red += 1
		var launch_passed: bool = (
			selected
			and roster_ready
			and blue == int(fixture["blue"])
			and red == int(fixture["red"])
		)
		if launch_passed:
			print("OK  %s reaches its first map with %d blue / %d red" % [package_id, blue, red])
			passed += 1
		else:
			print(
				(
					"FAIL %s launch: selected=%s roster=%s blue=%d red=%d entry=%s"
					% [package_id, selected, roster_ready, blue, red, entry]
				)
			)
			failed += 1
		map_instance.queue_free()
		await process_frame

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
