extends SceneTree

const Context = preload("res://scripts/placement/OccupancyContext.gd")


func _init() -> void:
	print("=== OccupancyService Test ===")
	var passed := 0
	var failed := 0

	var registry: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	registry.name = "RegistryManager"
	root.add_child(registry)
	var service: Node = load("res://scripts/autoloads/OccupancyService.gd").new()
	service.name = "OccupancyService"
	root.add_child(service)
	var grid := GridManager.new()
	grid.map_width = 4
	grid.map_height = 4
	for y in 4:
		for x in 4:
			grid.set_terrain_fallback(Vector2i(x, y), "plain")
	root.add_child(grid)
	await process_frame

	var empty: RefCounted = service.place(Context.create(null, Vector2i(2, 2)), grid)
	if empty.ok and empty.to_tile == Vector2i(2, 2):
		print("OK  empty tile succeeds")
		passed += 1
	else:
		print("FAIL empty tile: %s" % empty.failure_reason)
		failed += 1

	var occupied: Array[Vector2i] = [Vector2i(2, 2)]
	var blocked: RefCounted = service.validate(Context.create(null, Vector2i(2, 2)), grid, occupied)
	if not blocked.ok and blocked.failure_reason == "occupied":
		print("OK  require_empty rejects occupied tile")
		passed += 1
	else:
		print("FAIL occupied tile: ok=%s reason=%s" % [blocked.ok, blocked.failure_reason])
		failed += 1

	var nearest: RefCounted = service.validate(
		Context.create(null, Vector2i(2, 2), "nearest_free"), grid, occupied
	)
	# Four distance-one candidates tie; y then x selects (2, 1).
	if nearest.ok and nearest.fallback_used and nearest.to_tile == Vector2i(2, 1):
		print("OK  nearest_free tie-break is distance, y, x")
		passed += 1
	else:
		print("FAIL nearest fallback: ok=%s tile=%s" % [nearest.ok, nearest.to_tile])
		failed += 1

	var skipped: RefCounted = service.place(Context.create(null, Vector2i(1, 1), "skip"), grid)
	if not skipped.ok and skipped.skipped and service.delayed_requests.is_empty():
		print("OK  skip reports without mutation")
		passed += 1
	else:
		print("FAIL skip result")
		failed += 1

	var delayed: RefCounted = service.place(Context.create(null, Vector2i(1, 1), "delay"), grid)
	if not delayed.ok and delayed.queued and service.delayed_requests.size() == 1:
		print("OK  delay queues without placement")
		passed += 1
	else:
		print("FAIL delay result")
		failed += 1

	var reserved: RefCounted = service.place(Context.create(null, Vector2i(1, 1), "swap"), grid)
	if not reserved.ok and reserved.failure_reason == "not_implemented":
		print("OK  reserved policy fails structurally")
		passed += 1
	else:
		print("FAIL reserved policy: %s" % reserved.failure_reason)
		failed += 1

	var unknown: RefCounted = service.place(Context.create(null, Vector2i(1, 1), "bogus"), grid)
	if not unknown.ok and unknown.failure_reason == "unknown_policy":
		print("OK  unknown policy fails validation")
		passed += 1
	else:
		print("FAIL unknown policy: %s" % unknown.failure_reason)
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
