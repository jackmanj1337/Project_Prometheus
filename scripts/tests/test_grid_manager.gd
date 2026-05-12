extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_grid_manager.gd
# Tests GridManager movement range and pathfinding using a fallback terrain grid.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")
const SoldierData := preload("res://data/classes/soldier.tres")

# Mock unit that GridManager methods can read from
class MockUnit extends Node:
	var tile_position: Vector2i
	var team: String = "player"
	var data: Resource

	func has_quality(_q: String) -> bool:
		return false

	func _init(tile: Vector2i, mov: int = 6, class_id: String = "soldier") -> void:
		tile_position = tile
		var d := UnitData.new()
		d.movement = mov
		d.class_id = class_id
		data = d


func _init() -> void:
	print("=== GridManager Test ===")
	var passed := 0
	var failed := 0

	var grid := GridManager.new()

	# --- Tile/world conversion ---
	var ts := GameConstants.TILE_SIZE
	if grid.world_to_tile(Vector2(ts, ts * 2)) == Vector2i(1, 2):
		print("OK  world_to_tile(%d,%d) = (1,2)" % [ts, ts * 2])
		passed += 1
	else:
		print("FAIL world_to_tile")
		failed += 1
	if grid.tile_to_world(Vector2i(3, 4)) == Vector2(3 * ts, 4 * ts):
		print("OK  tile_to_world(3,4) = (%d,%d)" % [3 * ts, 4 * ts])
		passed += 1
	else:
		print("FAIL tile_to_world")
		failed += 1

	# --- Build a small 6x6 terrain grid ---
	#  All plains except (2,2) is forest, (3,3) is mountain, (4,4) is wall
	for x in 6:
		for y in 6:
			grid.set_terrain_fallback(Vector2i(x, y), "plain")
	grid.set_terrain_fallback(Vector2i(2, 2), "forest")
	grid.set_terrain_fallback(Vector2i(3, 3), "mountain")
	grid.set_terrain_fallback(Vector2i(4, 4), "wall")

	if grid.get_terrain_at(Vector2i(0, 0)) == "plain":
		print("OK  terrain plain at (0,0)")
		passed += 1
	else:
		print("FAIL terrain at (0,0): " + grid.get_terrain_at(Vector2i(0, 0)))
		failed += 1
	if grid.get_terrain_at(Vector2i(2, 2)) == "forest":
		print("OK  terrain forest at (2,2)")
		passed += 1
	else:
		print("FAIL terrain at (2,2)")
		failed += 1
	if grid.get_terrain_at(Vector2i(99, 99)) == "wall":
		print("OK  out-of-bounds = wall")
		passed += 1
	else:
		print("FAIL OOB terrain")
		failed += 1

	# --- Move costs ---
	var u := MockUnit.new(Vector2i(0, 0), 6, "soldier")
	if grid.get_move_cost(Vector2i(0, 0), u) == 1:
		print("OK  plain costs 1")
		passed += 1
	else:
		print("FAIL plain cost")
		failed += 1
	if grid.get_move_cost(Vector2i(2, 2), u) == 2:
		print("OK  forest costs 2")
		passed += 1
	else:
		print("FAIL forest cost")
		failed += 1
	if grid.get_move_cost(Vector2i(3, 3), u) == 3:
		print("OK  mountain costs 3")
		passed += 1
	else:
		print("FAIL mountain cost")
		failed += 1
	if grid.get_move_cost(Vector2i(4, 4), u) == 999:
		print("OK  wall cost 999")
		passed += 1
	else:
		print("FAIL wall cost")
		failed += 1

	# --- Movement range (mov=6 from (0,0)) ---
	# Wall at (4,4) is unreachable. (3,3) costs 3 + path to it ≥ 4 = at most reachable
	# Note: GameState.all_units is empty by default in --script mode (autoloads not active),
	# so get_unit_at returns null and movement won't be blocked by phantom units.
	var reachable := grid.get_movement_range(u)
	var has_origin := Vector2i(0, 0) in reachable
	var no_wall := not (Vector2i(4, 4) in reachable)
	var cant_reach_far := not (Vector2i(5, 5) in reachable)  # too far on plains alone (10 cost)
	if has_origin and no_wall and cant_reach_far:
		print("OK  movement range respects walls and cap (size=%d)" % reachable.size())
		passed += 1
	else:
		print("FAIL movement range: origin=%s no_wall=%s no_far=%s" % [has_origin, no_wall, cant_reach_far])
		failed += 1

	# --- Pathfinding ---
	var path := grid.get_movement_path(u, Vector2i(2, 0))
	# Path on plains from (0,0) to (2,0): expect 3 tiles total (start, (1,0), (2,0))
	if path.size() == 3 and path[0] == Vector2i(0, 0) and path[-1] == Vector2i(2, 0):
		print("OK  path (0,0)→(2,0) length=%d" % path.size())
		passed += 1
	else:
		print("FAIL path: " + str(path))
		failed += 1

	# Unreachable target returns empty path
	var unreach := grid.get_movement_path(u, Vector2i(4, 4))
	if unreach.is_empty():
		print("OK  unreachable returns empty path")
		passed += 1
	else:
		print("FAIL unreachable path: " + str(unreach))
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
