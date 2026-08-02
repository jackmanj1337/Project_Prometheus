extends SceneTree
# Regression: activating Tier-2 content must not delete engine placement policy entries.

const Context = preload("res://scripts/placement/OccupancyContext.gd")
const DataManagerScript = preload("res://scripts/autoloads/DataManager.gd")


func _init() -> void:
	print("=== v0.6.0 Registry Baseline Regression Test ===")
	var registry: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	registry.name = "RegistryManager"
	root.add_child(registry)
	var service: Node = load("res://scripts/autoloads/OccupancyService.gd").new()
	service.name = "OccupancyService"
	root.add_child(service)
	var manager: Node = DataManagerScript.new()
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

	var passed: bool = (
		activated
		and registry.has_entry("occupancy_policies", "nearest_free")
		and placement.ok
		and placement.fallback_used
		and placement.to_tile == Vector2i(1, 0)
	)
	if passed:
		print("OK  Tier-2 activation preserves nearest_free through live placement")
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
	print("=== Results: %d passed, %d failed ===" % [1 if passed else 0, 0 if passed else 1])
	quit(0 if passed else 1)
