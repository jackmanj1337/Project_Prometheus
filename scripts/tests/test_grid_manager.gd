extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_grid_manager.gd
# Tests GridManager movement range and pathfinding using a fallback terrain grid.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")
const SoldierData := preload("res://data/classes/soldier.tres")

# Mock unit that GridManager methods can read from
class MockUnit extends Node:
	var tile_position: Vector2i
	var team: String = "blue"
	var data: Resource

	func has_quality(_q: String) -> bool:
		return false

	func _init(tile: Vector2i, mov: int = 6, class_id: String = "soldier") -> void:
		tile_position = tile
		var d := UnitData.new()
		d.movement = mov
		d.class_id = class_id
		data = d


# Mock with a configurable special_qualities set, for the V021-11 movement-type tests.
class MockTypedUnit extends Node:
	var tile_position: Vector2i
	var team: String = "blue"
	var data: Resource
	var qualities: Array = []

	func has_quality(q: String) -> bool:
		return q in qualities

	func _init(tile: Vector2i, quals: Array, mov: int = 8) -> void:
		tile_position = tile
		qualities = quals
		var d := UnitData.new()
		d.movement = mov
		data = d


# Mock whose equipped weapon is a healing staff — used to prove a healer
# contributes no threat tiles ([TUR-1]).
class MockHealerUnit extends Node:
	var tile_position: Vector2i
	var team: String = "red"
	var data: Resource
	var _weapon: WeaponData

	func has_quality(_q: String) -> bool:
		return false

	func get_equipped_weapon() -> WeaponData:
		return _weapon

	func _init(tile: Vector2i, weapon: WeaponData, mov: int = 6) -> void:
		tile_position = tile
		_weapon = weapon
		var d := UnitData.new()
		d.movement = mov
		d.class_id = "cleric"
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

	# --- Staff range (playtest 3 #3) ---
	# Stub unit that returns a healing staff from get_equipped_weapon(); the
	# real Unit pulls weapons via DataManager which isn't always loaded in tests.
	var staff_unit_script := GDScript.new()
	staff_unit_script.source_code = """
extends Node
var tile_position: Vector2i = Vector2i.ZERO
var _w
func _set_staff(weapon) -> void: _w = weapon
func get_equipped_weapon(): return _w
"""
	staff_unit_script.reload()
	var staff_unit: Node = staff_unit_script.new()
	root.add_child(staff_unit)
	var heal_staff := WeaponData.new()
	heal_staff.combat_family = "staff"
	heal_staff.wexp_track = "staff"
	heal_staff.required_rank = "E"
	# Typed-array literal — bare [] won't satisfy Array[String]; assign via local.
	var tags: Array[String] = [GameConstants.TAG_HEAL_PLUS_MAG]
	heal_staff.effect_tags = tags
	# Range fields default to "1"/"1" formulas — no need to set them.
	staff_unit._set_staff(heal_staff)
	# A 3x3 movement-tile footprint centred at (2,2). The staff reach should be
	# the ring of tiles adjacent to that footprint and NOT inside it.
	var movement_tiles: Array[Vector2i] = [
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
		Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2),
		Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3),
	]
	var heal_ring := grid.get_staff_range_from_tiles(staff_unit, movement_tiles)
	var has_outside := Vector2i(0, 2) in heal_ring and Vector2i(4, 2) in heal_ring
	var no_inside := not (Vector2i(2, 2) in heal_ring)
	if has_outside and no_inside:
		print("OK  get_staff_range_from_tiles paints the ring outside the move range (#3)")
		passed += 1
	else:
		print("FAIL staff range: outside=%s no_inside=%s ring=%s" % [has_outside, no_inside, heal_ring])
		failed += 1
	# A non-staff unit must get nothing back — gates the heal-overlay branch.
	var non_staff_ring := grid.get_staff_range_from_tiles(u, movement_tiles)
	if non_staff_ring.is_empty():
		print("OK  get_staff_range_from_tiles returns [] for non-healing-staff users")
		passed += 1
	else:
		print("FAIL non-staff ring should be empty, got %s" % non_staff_ring)
		failed += 1
	staff_unit.queue_free()

	# --- get_terrain_bonuses returns matching {def, dodge} per tile (B1) ---
	# The grid above seeds (2,2)=forest, (3,3)=mountain, (4,4)=wall. Wall has no
	# defender bonus by design (impassable; counterattacks from wall tiles never
	# happen) — confirms the accessor zeros out unknown / no-bonus terrain too.
	var b_forest: Dictionary = grid.get_terrain_bonuses(Vector2i(2, 2))
	var b_mountain: Dictionary = grid.get_terrain_bonuses(Vector2i(3, 3))
	var b_wall: Dictionary = grid.get_terrain_bonuses(Vector2i(4, 4))
	var b_plain: Dictionary = grid.get_terrain_bonuses(Vector2i(0, 0))
	if b_forest == {"def": 1, "dodge": 15} \
			and b_mountain == {"def": 2, "dodge": 20} \
			and b_wall == {"def": 0, "dodge": 0} \
			and b_plain == {"def": 0, "dodge": 0}:
		print("OK  get_terrain_bonuses returns {def,dodge} per terrain (B1)")
		passed += 1
	else:
		print("FAIL get_terrain_bonuses: forest=%s mountain=%s wall=%s plain=%s" % [
			b_forest, b_mountain, b_wall, b_plain])
		failed += 1

	# --- V021-11: movement-type resolver + terrain costs ---
	var mt_ok: bool = (
		GameConstants.movement_type_of(["armoured", "mounted"]) == "mounted"  # precedence
		and GameConstants.movement_type_of([]) == "infantry"                  # default
		and GameConstants.movement_type_of(["laguz", "flying"]) == "flying"   # ignores non-move tag
		and GameConstants.movement_type_of(["light_footed"]) == "light_footed"
	)
	if mt_ok:
		print("OK  V021-11 movement_type_of resolves by precedence, ignores non-move tags"); passed += 1
	else:
		print("FAIL V021-11 movement_type_of"); failed += 1

	# Flying ignores ground terrain (flat 1) but walls still block.
	var flier := MockTypedUnit.new(Vector2i(0, 0), ["flying"])
	if grid.get_move_cost(Vector2i(2, 2), flier) == 1 \
			and grid.get_move_cost(Vector2i(3, 3), flier) == 1 \
			and grid.get_move_cost(Vector2i(4, 4), flier) == GridManager.IMPASSABLE_MOVE_COST:
		print("OK  V021-11 flier pays 1 on forest/mountain, blocked by wall"); passed += 1
	else:
		print("FAIL V021-11 flier costs: forest=%d mountain=%d wall=%d" % [
			grid.get_move_cost(Vector2i(2, 2), flier), grid.get_move_cost(Vector2i(3, 3), flier),
			grid.get_move_cost(Vector2i(4, 4), flier)]); failed += 1

	# Desert: armoured/mounted pay 3, light_footed 1, infantry the base (2).
	grid.set_terrain_fallback(Vector2i(0, 5), "desert")
	var armoured := MockTypedUnit.new(Vector2i(0, 0), ["armoured"])
	var light := MockTypedUnit.new(Vector2i(0, 0), ["light_footed"])
	var foot := MockTypedUnit.new(Vector2i(0, 0), ["infantry"])
	if grid.get_move_cost(Vector2i(0, 5), armoured) == 3 \
			and grid.get_move_cost(Vector2i(0, 5), light) == 1 \
			and grid.get_move_cost(Vector2i(0, 5), foot) == 2:
		print("OK  V021-11 desert costs by resolved type (armoured 3, light 1, infantry 2)"); passed += 1
	else:
		print("FAIL V021-11 desert costs: armoured=%d light=%d infantry=%d" % [
			grid.get_move_cost(Vector2i(0, 5), armoured), grid.get_move_cost(Vector2i(0, 5), light),
			grid.get_move_cost(Vector2i(0, 5), foot)]); failed += 1
	flier.queue_free(); armoured.queue_free(); light.queue_free(); foot.queue_free()

	# get_move_costs_for_groups exposes the flying column (1 except wall).
	if int(GridManager.get_move_costs_for_groups("mountain").get("flying", -1)) == 1 \
			and int(GridManager.get_move_costs_for_groups("wall").get("flying", -1)) == GridManager.IMPASSABLE_MOVE_COST:
		print("OK  V021-11 get_move_costs_for_groups includes flying (1 / wall impassable)"); passed += 1
	else:
		print("FAIL V021-11 flying group column"); failed += 1

	# --- [TUR-1] / B6-MRD Slice 1: per-unit threat extraction ---
	# Build a fresh open 6x6 plains grid so movement isn't blocked by the earlier
	# terrain fixture, and place one range-1 armed unit centrally.
	var tgrid := GridManager.new()
	for x in 6:
		for y in 6:
			tgrid.set_terrain_fallback(Vector2i(x, y), "plain")
	var armed := MockUnit.new(Vector2i(3, 3), 2)  # mov 2, default range (1,1)
	armed.data.max_hp = 10
	armed.data.hp = 10
	var threat := tgrid.get_unit_threat_tiles(armed)
	# An armed unit threatens its reachable tiles' attack rings — strictly more
	# than the 4 tiles adjacent to its start (movement widens the footprint).
	var start_adjacent := 0
	for d in GridManager.DIRS:
		if threat.has(armed.tile_position + d):
			start_adjacent += 1
	if threat.size() > 4 and start_adjacent == 4:
		print("OK  [TUR-1] get_unit_threat_tiles = reach ∪ attack-from-reach (%d tiles)" % threat.size()); passed += 1
	else:
		print("FAIL [TUR-1] threat tiles: size=%d adj=%d" % [threat.size(), start_adjacent]); failed += 1

	# A null unit and a dead unit both threaten nothing.
	var dead := MockUnit.new(Vector2i(2, 2), 4)
	dead.data.hp = 0
	if tgrid.get_unit_threat_tiles(null).is_empty() and tgrid.get_unit_threat_tiles(dead).is_empty():
		print("OK  [TUR-1] null/dead unit threatens no tiles"); passed += 1
	else:
		print("FAIL [TUR-1] null/dead unit produced threat tiles"); failed += 1

	# A healer (equipped healing staff) threatens no tiles even though it can move.
	var staff := load("res://data/weapons/heal_staff.tres") as WeaponData
	var healer := MockHealerUnit.new(Vector2i(3, 3), staff, 4)
	healer.data.max_hp = 10
	healer.data.hp = 10
	if staff != null and staff.is_healing_staff() and tgrid.get_unit_threat_tiles(healer).is_empty():
		print("OK  [TUR-1] a healer contributes no threat tiles"); passed += 1
	else:
		print("FAIL [TUR-1] healer threat: staff=%s tiles=%d" % [
			staff, tgrid.get_unit_threat_tiles(healer).size()]); failed += 1

	# --- [MRD-1] overlay precedence registry ---
	# The watch layer must out-rank the faction layer (wins shared cells in
	# `combined`); range layers sit below both (they blend under threat).
	var p_move := GridManager.overlay_layer_precedence(GridManager.OVERLAY_LAYER_MOVE)
	var p_faction := GridManager.overlay_layer_precedence(GridManager.OVERLAY_LAYER_FACTION_THREAT)
	var p_watch := GridManager.overlay_layer_precedence(GridManager.OVERLAY_LAYER_WATCH_THREAT)
	if p_move < p_faction and p_faction < p_watch:
		print("OK  [MRD-1] built-in overlay precedence: move < faction < watch"); passed += 1
	else:
		print("FAIL [MRD-1] precedence order: move=%d faction=%d watch=%d" % [p_move, p_faction, p_watch]); failed += 1

	# Adding an overlay is a REGISTRATION, not a repaint edit: a fixture layer
	# registered between faction and watch reports its precedence and sorts there.
	GridManager.register_overlay_layer("fixture_healing_zone", 25, true)
	var p_fix := GridManager.overlay_layer_precedence("fixture_healing_zone")
	var layer_ids := [
		GridManager.OVERLAY_LAYER_WATCH_THREAT, "fixture_healing_zone",
		GridManager.OVERLAY_LAYER_MOVE, GridManager.OVERLAY_LAYER_FACTION_THREAT,
	]
	layer_ids.sort_custom(func(a, b): return GridManager.overlay_layer_precedence(a) < GridManager.overlay_layer_precedence(b))
	var order_ok: bool = layer_ids[0] == GridManager.OVERLAY_LAYER_MOVE \
		and layer_ids[1] == GridManager.OVERLAY_LAYER_FACTION_THREAT \
		and layer_ids[2] == "fixture_healing_zone" \
		and layer_ids[3] == GridManager.OVERLAY_LAYER_WATCH_THREAT
	# An unregistered layer sorts last (paints on top).
	var p_unknown := GridManager.overlay_layer_precedence("never_registered")
	if p_fix == 25 and order_ok and p_unknown > p_watch:
		print("OK  [MRD-1] a newly-registered layer slots by precedence (no repaint edit)"); passed += 1
	else:
		print("FAIL [MRD-1] fixture layer: p=%d order=%s unknown=%d" % [p_fix, order_ok, p_unknown]); failed += 1

	# --- [MRD-1] repaint_overlays paints in precedence order onto a real overlay ---
	# With the source-4 darker-red watch tile authored, verify the whole
	# precedence→paint path: watch (src 4) wins a cell shared with faction (src 3).
	var pgrid := GridManager.new()
	var ov := TileMapLayer.new()
	ov.tile_set = load("res://assets/overlay_tileset.tres")
	pgrid._overlay = ov
	var faction_tiles: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	var watch_tiles: Array[Vector2i] = [Vector2i(1, 0)]  # overlaps faction at (1,0)
	pgrid.repaint_overlays({
		GridManager.OVERLAY_LAYER_FACTION_THREAT: {"tiles": faction_tiles, "source": GridManager.OVERLAY_DARK_RED},
		GridManager.OVERLAY_LAYER_WATCH_THREAT: {"tiles": watch_tiles, "source": GridManager.OVERLAY_DARKER_RED},
	})
	var shared_src := ov.get_cell_source_id(Vector2i(1, 0))       # watch wins → 4
	var faction_only_src := ov.get_cell_source_id(Vector2i(0, 0)) # faction → 3
	if shared_src == GridManager.OVERLAY_DARKER_RED and faction_only_src == GridManager.OVERLAY_DARK_RED:
		print("OK  [MRD-1] repaint_overlays: watch (src4) wins the shared cell, faction (src3) elsewhere"); passed += 1
	else:
		print("FAIL [MRD-1] paint order: shared=%d faction=%d" % [shared_src, faction_only_src]); failed += 1
	ov.free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
