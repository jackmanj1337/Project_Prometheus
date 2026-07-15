extends Node

const PlacementResultScript = preload("res://scripts/placement/PlacementResult.gd")

# Delays are scene-runtime requests only in this groundwork slice. No saved
# delayed-spawn state is introduced before its F1 manifest row exists.
var delayed_requests: Array[RefCounted] = []

var _handlers: Dictionary = {
	"require_empty_placement": _require_empty,
	"nearest_free_placement": _nearest_free,
	"delay_placement": _delay,
	"skip_placement": _skip,
	"unimplemented_placement": _unimplemented,
}


# Grid supplies bounds/terrain. occupied_tiles makes validation mode usable
# without instancing nodes; live callers may omit it and use GridManager state.
func place(context: RefCounted, grid: Node, occupied_tiles: Array[Vector2i] = []) -> RefCounted:
	if context == null or grid == null:
		return _failure("invalid_context", context)
	var registry := get_node_or_null("/root/RegistryManager")
	if registry == null or not registry.call("has_entry", "occupancy_policies", context.collision_policy):
		return _finish(context, PlacementResultScript.failure("unknown_policy", context))
	var entry: Resource = registry.call("entry", "occupancy_policies", context.collision_policy)
	var handler: Callable = _handlers.get(entry.primitive_handler, Callable())
	if not handler.is_valid():
		return _finish(context, PlacementResultScript.failure("unknown_handler", context))
	return _finish(context, handler.call(context, grid, occupied_tiles))


func validate(context: RefCounted, grid: Node, occupied_tiles: Array[Vector2i]) -> RefCounted:
	return place(context, grid, occupied_tiles)


func clear_delayed() -> void:
	delayed_requests.clear()


func _require_empty(context: RefCounted, grid: Node, occupied: Array[Vector2i]) -> RefCounted:
	if not _is_passable(context.desired_tile, grid):
		return PlacementResultScript.failure("impassable", context)
	if _is_occupied(context.desired_tile, grid, occupied):
		return PlacementResultScript.failure("occupied", context)
	return _success(context, context.desired_tile)


func _nearest_free(context: RefCounted, grid: Node, occupied: Array[Vector2i]) -> RefCounted:
	var direct := _require_empty(context, grid, occupied)
	if direct.ok:
		return direct
	var candidates: Array[Vector2i] = []
	for y in int(grid.get("map_height")):
		for x in int(grid.get("map_width")):
			var tile := Vector2i(x, y)
			if _is_passable(tile, grid) and not _is_occupied(tile, grid, occupied):
				candidates.append(tile)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := absi(a.x - context.desired_tile.x) + absi(a.y - context.desired_tile.y)
		var db := absi(b.x - context.desired_tile.x) + absi(b.y - context.desired_tile.y)
		if da != db:
			return da < db
		if a.y != b.y:
			return a.y < b.y
		return a.x < b.x)
	if candidates.is_empty():
		return PlacementResultScript.failure("no_free_tile", context)
	var result := _success(context, candidates[0])
	result.fallback_used = true
	return result


func _delay(context: RefCounted, _grid: Node, _occupied: Array[Vector2i]) -> RefCounted:
	delayed_requests.append(context)
	var result := PlacementResultScript.failure("delayed", context)
	result.queued = true
	return result


func _skip(context: RefCounted, _grid: Node, _occupied: Array[Vector2i]) -> RefCounted:
	var result := PlacementResultScript.failure("skipped", context)
	result.skipped = true
	return result


func _unimplemented(context: RefCounted, _grid: Node, _occupied: Array[Vector2i]) -> RefCounted:
	return PlacementResultScript.failure("not_implemented", context)


func _success(context: RefCounted, tile: Vector2i) -> RefCounted:
	var result := PlacementResultScript.new()
	result.ok = true
	result.from_tile = context.from_tile
	result.to_tile = tile
	if context.subject_id != "":
		result.affected_ids.append(context.subject_id)
	return result


func _failure(reason: String, context: RefCounted) -> RefCounted:
	if context == null:
		var result := PlacementResultScript.new()
		result.failure_reason = reason
		return result
	return PlacementResultScript.failure(reason, context)


func _finish(context: RefCounted, result: RefCounted) -> RefCounted:
	if context != null and context.result_sink.is_valid():
		context.result_sink.call(result)
	return result


func _is_passable(tile: Vector2i, grid: Node) -> bool:
	return tile.x >= 0 and tile.y >= 0 \
		and tile.x < int(grid.get("map_width")) and tile.y < int(grid.get("map_height")) \
		and String(grid.call("get_terrain_at", tile)) != "wall"


func _is_occupied(tile: Vector2i, grid: Node, occupied: Array[Vector2i]) -> bool:
	return tile in occupied or grid.call("get_unit_at", tile) != null
