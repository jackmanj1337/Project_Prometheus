class_name FogService extends RefCounted
# Band 6 fog of war, Slice 1: the vision primitive, behind ONE seam.
# Plan: [FOW-1]
# Register: [FOW-1]
#
# [FOW-1] A: visibility is a flat radius disc per unit — terrain does NOT block
# sight. The whole point of routing every query through compute_visible_tiles is
# that the deferred expansion (true LoS with occlusion, [FOW-1] B) replaces the
# disc with a shadowcast here and NO caller changes. Do not let a caller compute
# a disc of its own.
#
# [FOW-6] A: the radius is the resolved `unit.data.line_of_sight` with no
# modifiers in v1. Terrain vision bonuses, torch items and a concealment axis are
# designed fast-follows that also land here rather than at call sites.
#
# Everything is static: vision is derived state with no lifetime of its own
# (F1 `no_save_guard` — nothing here is persisted, it recomputes from positions).


# Distance metric. Manhattan, matching GridManager._tiles_in_range, so vision
# reads the same shape as weapon range rather than introducing a second notion of
# "within N tiles" that only fog uses. Public so the ambush probe measures with
# the same ruler the visible set is built from.
static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# The vision radius a unit contributes. Non-positive radii still see the unit's
# own tile — a blinded unit knows where it stands.
static func vision_radius(unit: Node) -> int:
	if unit == null or unit.get("data") == null:
		return 0
	return maxi(0, int(unit.data.line_of_sight))


# [FOW-2]: fog is an encounter-layer property, not a global rule. Callers gate on
# this BEFORE using a visible set — an empty visible set means "nothing is
# visible", which is a very different thing from "this map has no fog".
static func is_fog_enabled(map_data: Resource) -> bool:
	return map_data != null and bool(map_data.get("fog_enabled"))


# THE SEAM. Returns the set of tiles `faction_id` can see, as a Dictionary used
# as a set ({Vector2i: true}) so membership tests stay O(1) for the render mask
# and the per-step crossing check.
#
# `game_state` supplies the living roster; `grid` supplies map bounds so the set
# never contains off-map tiles (the fog mask paints the complement of this set,
# and an off-map tile in it would silently punch a hole in nothing).
static func compute_visible_tiles(faction_id: String, game_state: Node, grid: Node) -> Dictionary:
	var visible: Dictionary = {}
	if game_state == null or not game_state.has_method("get_living_units_of"):
		return visible
	for unit in game_state.get_living_units_of(faction_id):
		if unit == null or not is_instance_valid(unit):
			continue
		_add_disc(visible, unit.tile_position, vision_radius(unit), grid)
	return visible


# Adds one vision disc to the accumulating set. Separate from the loop above so a
# non-unit vision source ([FOW-7] lit braziers, slice 6) contributes through the
# same primitive instead of growing a parallel one.
static func _add_disc(visible: Dictionary, center: Vector2i, radius: int, grid: Node) -> void:
	var width: int = int(grid.get("map_width")) if grid != null else 0
	var height: int = int(grid.get("map_height")) if grid != null else 0
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if absi(dx) + absi(dy) > radius:
				continue
			var tile := center + Vector2i(dx, dy)
			# A zero-size grid means "bounds unknown" (tests, tools) — keep the
			# raw disc rather than silently returning nothing.
			if width > 0 and height > 0:
				if tile.x < 0 or tile.y < 0 or tile.x >= width or tile.y >= height:
					continue
			visible[tile] = true


# Whether a specific tile is visible to a faction. Convenience over the set so
# callers do not have to know it is a Dictionary-as-set.
static func is_tile_visible(visible: Dictionary, tile: Vector2i) -> bool:
	return visible.has(tile)


# The units of `faction_id` standing on tiles the viewer can see. Used by the
# render filter (slice 2) and by the ambush check (slice 3); both need "which
# hostile is exposed", not just "which tile is lit".
static func visible_units_of(
	faction_id: String, visible: Dictionary, game_state: Node
) -> Array[Node]:
	var out: Array[Node] = []
	if game_state == null or not game_state.has_method("get_living_units_of"):
		return out
	for unit in game_state.get_living_units_of(faction_id):
		if unit != null and is_instance_valid(unit) and visible.has(unit.tile_position):
			out.append(unit)
	return out
