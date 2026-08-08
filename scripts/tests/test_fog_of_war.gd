extends SceneTree
# Band 6 fog of war — slices 1 and 3.
#
# Slice 1: the vision seam (LoS-disc union, dead units contribute nothing,
# bounds clamping, the fog_enabled gate).
# Slice 3: reveal-on-move + the ambush interrupt, built as the FIRST consumer of
# the shared crossing resolver rather than as a movement hook of its own. The
# assertions that matter are that a move halts on the exact revealing step and
# that it does so identically at Instant speed — fog inherits that parity from
# [PCM-3] by using the resolver, and this suite proves it rather than assuming.

const ServiceScript = preload("res://scripts/autoloads/CrossingService.gd")
const UnitScene = preload("res://scenes/units/Unit.tscn")

var passed := 0
var failed := 0


func check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s%s" % [label, "" if detail.is_empty() else ": " + detail])
		failed += 1


# Minimal GameState stand-in: FogService/FogRuntime only need the roster.
class RosterStub:
	extends Node
	var all_units: Array[Node] = []

	func get_living_units_of(faction_id: String) -> Array[Node]:
		var out: Array[Node] = []
		for unit in all_units:
			if (
				unit != null
				and is_instance_valid(unit)
				and String(unit.team) == faction_id
				and unit.data != null
				and unit.data.hp > 0
			):
				out.append(unit)
		return out


class GridStub:
	extends Node
	var map_width: int = 0
	var map_height: int = 0


func _init() -> void:
	print("=== Fog of War Test ===")
	await _test_vision_seam()
	await _test_ambush_interrupt()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


# Returns the live autoload, or installs one under that exact name if this run
# has none. Never adds a duplicate: after autoloads attach on the first frame a
# second node with the same name is renamed, and Unit would resolve the autoload
# instead of the one this suite registered its consumer on.
func _autoload(node_name: String, script: Script) -> Node:
	var existing := root.get_node_or_null("/root/" + node_name)
	if existing != null:
		return existing
	var made: Node = script.new()
	made.name = node_name
	root.add_child(made)
	return made


func _make_unit(team: String, tile: Vector2i, los: int, hp: int = 10) -> Unit:
	var unit: Unit = UnitScene.instantiate()
	unit.data = UnitData.new()
	unit.data.tile_position = tile
	unit.data.line_of_sight = los
	unit.data.max_hp = hp
	unit.data.hp = hp
	unit.team = team
	root.add_child(unit)
	return unit


func _encounter(fog: bool) -> BattleEncounterDef:
	var encounter := BattleEncounterDef.new()
	encounter.fog_enabled = fog
	return encounter


# ── Slice 1: the vision seam ─────────────────────────────────────────────────


func _test_vision_seam() -> void:
	var gs := RosterStub.new()
	root.add_child(gs)
	var grid := GridStub.new()
	grid.map_width = 20
	grid.map_height = 20
	root.add_child(grid)
	await process_frame

	var scout := _make_unit("blue", Vector2i(5, 5), 2)
	gs.all_units = [scout]

	var visible := FogService.compute_visible_tiles("blue", gs, grid)
	# A Manhattan disc of radius 2 is 13 tiles (1 + 4 + 8), matching
	# GridManager._tiles_in_range rather than a square.
	check(visible.size() == 13, "radius-2 disc is the Manhattan 13 tiles", str(visible.size()))
	check(visible.has(Vector2i(5, 3)) and visible.has(Vector2i(7, 5)), "disc reaches full radius")
	check(not visible.has(Vector2i(7, 6)), "disc excludes the Chebyshev corner (Manhattan 3)")

	# A second unit extends the set.
	var second := _make_unit("blue", Vector2i(12, 5), 1)
	gs.all_units = [scout, second]
	var widened := FogService.compute_visible_tiles("blue", gs, grid)
	check(widened.size() == 13 + 5, "a second unit's disc unions in", str(widened.size()))

	# A dead unit contributes nothing.
	second.data.hp = 0
	var after_death := FogService.compute_visible_tiles("blue", gs, grid)
	check(after_death.size() == 13, "a dead unit contributes no vision", str(after_death.size()))

	# Bounds clamping: a unit in the corner sees no off-map tiles.
	var corner := _make_unit("blue", Vector2i(0, 0), 3)
	gs.all_units = [corner]
	var clamped := FogService.compute_visible_tiles("blue", gs, grid)
	var off_map := false
	for tile in clamped.keys():
		if tile.x < 0 or tile.y < 0:
			off_map = true
	check(not off_map, "the visible set never contains off-map tiles")

	# The gate is separate from the math: an empty visible set means "sees
	# nothing", which is NOT the same as "this map has no fog".
	check(not FogService.is_fog_enabled(_encounter(false)), "fog_enabled false gates fog off")
	check(FogService.is_fog_enabled(_encounter(true)), "fog_enabled true gates fog on")

	gs.all_units = []
	corner.queue_free()
	scout.queue_free()
	second.queue_free()
	gs.queue_free()
	grid.queue_free()
	await process_frame


# ── Slice 3: reveal-on-move + ambush interrupt ───────────────────────────────


# Builds a fog map with one blue scout at (0,0) and one hidden enemy, and returns
# [runtime, service, scout, enemy, roster].
func _build_ambush(enemy_tile: Vector2i, los: int = 1) -> Array:
	var gs := RosterStub.new()
	root.add_child(gs)
	var grid := GridStub.new()
	grid.map_width = 20
	grid.map_height = 20
	root.add_child(grid)
	var service: Node = _autoload("CrossingService", ServiceScript)
	service.clear_consumers()

	var scout := _make_unit("blue", Vector2i(0, 0), los)
	var enemy := _make_unit("red", enemy_tile, 1)
	gs.all_units = [scout, enemy]

	var fog := FogRuntime.new()
	fog.setup(_encounter(true), gs, grid, "blue", null)
	for error in fog.register(service):
		check(false, "fog consumer registered", error)
	return [fog, service, scout, enemy, gs, grid]


func _straight_path(length: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	for x in length:
		path.append(Vector2i(x, 0))
	return path


func _test_ambush_interrupt() -> void:
	var settings: Node = _autoload(
		"SettingsManager", load("res://scripts/autoloads/SettingsManager.gd")
	)
	await process_frame

	# The enemy sits at (6,0); a scout with LoS 1 walking east along y=0 first
	# comes within 1 tile of it when it reaches (5,0).
	var built := _build_ambush(Vector2i(6, 0), 1)
	var fog: FogRuntime = built[0]
	var service: Node = built[1]
	var scout: Unit = built[2]
	var enemy: Unit = built[3]

	check(not fog.is_discovered(enemy), "the enemy starts hidden")
	check(fog.is_active(), "fog runtime is active on a fog encounter")

	settings.movement_speed = "fast"
	var outcome = await scout.move_along_path(_straight_path(9))
	check(
		scout.tile_position == Vector2i(5, 0),
		"the move HALTS on the exact step that reveals the enemy",
		str(scout.tile_position)
	)
	check(outcome.halted and outcome.fired == ["fog_ambush"], "the ambush trigger fired")
	check(fog.is_discovered(enemy), "the revealed enemy enters discovered_units")
	# [PCM-6]: an ambush costs you the rest of the move, not your action.
	check(not outcome.ends_activation, "an ambush does not end the unit's activation")
	# [PCM-7]: the reveal is real information, so the move cannot be taken back.
	check(outcome.movement_permanent, "an ambushed move is permanent")

	# Already-discovered units do not re-ambush: walking back past the same enemy
	# completes normally.
	scout.snap_to_tile(Vector2i(0, 0))
	var second_outcome = await scout.move_along_path(_straight_path(6))
	check(
		not second_outcome.halted and scout.tile_position == Vector2i(5, 0),
		"a known enemy does not ambush again",
		str(scout.tile_position)
	)

	service.clear_consumers()
	_free_all(built)
	await process_frame

	# Instant speed must halt on the same tile. Fog gets this for free by using
	# the resolver instead of the tween — this is the regression that would catch
	# anyone "optimising" the ambush back into move_along_path's loop.
	var instant_built := _build_ambush(Vector2i(6, 0), 1)
	var instant_scout: Unit = instant_built[2]
	settings.movement_speed = "instant"
	var instant_outcome = await instant_scout.move_along_path(_straight_path(9))
	check(
		instant_scout.tile_position == Vector2i(5, 0) and instant_outcome.halted,
		"INSTANT speed halts on the same tile",
		str(instant_scout.tile_position)
	)
	instant_built[1].clear_consumers()
	_free_all(instant_built)
	await process_frame

	# A move with nothing to reveal completes normally (the plan's regression).
	var clear_built := _build_ambush(Vector2i(19, 19), 1)
	var clear_scout: Unit = clear_built[2]
	var clear_outcome = await clear_scout.move_along_path(_straight_path(9))
	check(
		not clear_outcome.halted and clear_scout.tile_position == Vector2i(8, 0),
		"a move with nothing to reveal completes",
		str(clear_scout.tile_position)
	)
	clear_built[1].clear_consumers()
	_free_all(clear_built)
	await process_frame

	# fog_enabled=false: the probe is inert even if a runtime is somehow present,
	# so a non-fog encounter can never halt a move.
	var off_built := _build_ambush(Vector2i(6, 0), 1)
	var off_fog: FogRuntime = off_built[0]
	off_fog.map_data = _encounter(false)
	var off_scout: Unit = off_built[2]
	var off_outcome = await off_scout.move_along_path(_straight_path(9))
	check(
		not off_outcome.halted and off_scout.tile_position == Vector2i(8, 0),
		"fog_enabled=false never halts a move",
		str(off_scout.tile_position)
	)
	off_built[1].clear_consumers()
	_free_all(off_built)
	await process_frame

	# settings is the shared autoload — restore the default rather than freeing it.
	settings.movement_speed = "normal"


# Frees the per-case nodes. Index 1 is the shared CrossingService autoload and is
# deliberately NOT freed — only its consumers are cleared.
func _free_all(built: Array) -> void:
	for i in [2, 3, 4, 5]:
		var node: Node = built[i]
		if is_instance_valid(node):
			node.queue_free()
