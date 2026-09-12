extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_map_000_drill.gd
# Gate for the Proving Grounds acceptance fixture (V0715-09).
#
# WHY THIS EXISTS. The v0.7.15 return asked for a campaign whose FIRST battle is
# trivial, because every repeated save / campaign-infrastructure playtest had to
# clear a full eight-enemy balance scenario before it could reach the thing under
# test. The fix is content, not engine code, so nothing in the engine stops the
# next author from growing this map back or re-pointing the campaign's start node
# at a long chapter. These assertions are that stop.
#
# The properties below are the tester's literal request -- one enemy, 1 HP, no
# defences -- plus the two that make the request actually pay off: the map has to
# be SMALL, and it has to be the campaign's START node. A trivial map nobody
# launches first would satisfy the letter of the finding and none of it.

const REGISTRY_PATH := "res://data/maps/map_registry.json"
const CAMPAIGN_PATH := "res://data/campaigns/proving_grounds.json"
const MAP_ID := "map_000_drill"
const ENCOUNTER_ID := "encounter_map_000_drill"
# The default roster's slowest unit is the knight at movement 5, so a start tile
# within 5 steps of a tile adjacent to the enemy means EVERY deployed unit can
# reach the fight on turn 1.
const SLOWEST_ROSTER_MOVEMENT := 5
# 12x9 as authored. Generous enough to allow a re-cut, tight enough that turning
# this back into a full battlefield fails here first.
const MAX_GRID_TILES := 150

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== map_000 Drill Yard acceptance-fixture gate ===")
	var entry := _registry_entry()
	if entry.is_empty():
		print("FAIL map_registry.json has no entry for %s" % MAP_ID)
		_finish()
		return
	_check(true, "registry entry present")
	_check(
		not bool(entry.get("is_dev_only", true)),
		"the fixture ships in release builds (is_dev_only false)"
	)
	_check(
		String(entry.get("roster_policy", "")) == "default_roster",
		"the fixture seeds the default roster",
		String(entry.get("roster_policy", ""))
	)

	var map_data: Resource = _load_map(String(entry.get("map_data_path", "")))
	if map_data == null:
		_finish()
		return
	_check_shape(map_data)
	_check_enemy(map_data)
	_check_reachable(map_data)
	_check_campaign_entry_point()
	_finish()


func _registry_entry() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY_PATH))
	if not (parsed is Array):
		return {}
	for row in parsed:
		if row is Dictionary and String(row.get("id", "")) == MAP_ID:
			return row
	return {}


func _load_map(path: String) -> Resource:
	if path == "" or not ResourceLoader.exists(path):
		print("FAIL map_data_path missing: '%s'" % path)
		_failed += 1
		return null
	var map_data: Resource = load(path)
	if map_data == null:
		print("FAIL map data did not load: %s" % path)
		_failed += 1
		return null
	_check(true, "map data .tres loads")
	return map_data


# Small enough that crossing it is not the exercise.
func _check_shape(map_data: Resource) -> void:
	var grid: Array = map_data.get("grid")
	var tiles := 0
	for row in grid:
		tiles += String(row).length()
	_check(
		tiles > 0 and tiles <= MAX_GRID_TILES,
		"grid stays small (%d tiles, cap %d)" % [tiles, MAX_GRID_TILES]
	)
	var victory: Dictionary = map_data.get("victory_conditions")
	var allied: Array = victory.get("allies", [])
	_check(
		allied.size() == 1 and String(allied[0].get("type")) == "rout",
		"victory is a plain rout, so the single kill ends the map"
	)


# The tester's literal request: one enemy, 1 HP, no defences.
func _check_enemy(map_data: Resource) -> void:
	var placements: Array = map_data.get("enemy_placements")
	if placements.size() != 1:
		print("FAIL expected exactly 1 enemy placement, got %d" % placements.size())
		_failed += 1
		return
	_check(true, "exactly one enemy placement")
	var unit_path := String(placements[0].get("unit_data_path", ""))
	if unit_path == "" or not ResourceLoader.exists(unit_path):
		print("FAIL enemy unit_data_path does not resolve: '%s'" % unit_path)
		_failed += 1
		return
	var unit: Resource = load(unit_path)
	if unit == null:
		print("FAIL enemy unit did not load: %s" % unit_path)
		_failed += 1
		return
	_check(
		int(unit.get("max_hp")) == 1 and int(unit.get("hp")) == 1,
		"the enemy has 1 HP",
		"max_hp=%d hp=%d" % [int(unit.get("max_hp")), int(unit.get("hp"))]
	)
	_check(
		int(unit.get("defense")) == 0 and int(unit.get("resistance")) == 0,
		"the enemy has no defences",
		"def=%d res=%d" % [int(unit.get("defense")), int(unit.get("resistance"))]
	)


# Reaching the enemy must not itself cost turns.
func _check_reachable(map_data: Resource) -> void:
	var placements: Array = map_data.get("enemy_placements")
	if placements.size() != 1:
		return
	var enemy_tile: Vector2i = placements[0].get("tile")
	var starts: Array = map_data.get("player_start_tiles")
	var best := 1 << 30
	for start in starts:
		var tile: Vector2i = start
		var steps: int = absi(tile.x - enemy_tile.x) + absi(tile.y - enemy_tile.y) - 1
		best = mini(best, steps)
	_check(
		best <= SLOWEST_ROSTER_MOVEMENT,
		(
			"a deployed unit can engage on turn 1 (%d steps, slowest movement %d)"
			% [best, SLOWEST_ROSTER_MOVEMENT]
		)
	)


# The whole point of the finding: this is what the campaign opens with.
func _check_campaign_entry_point() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAMPAIGN_PATH))
	if not (parsed is Dictionary):
		print("FAIL proving_grounds.json did not parse")
		_failed += 1
		return
	var campaign: Dictionary = parsed
	var start_id := String(campaign.get("start_node_id", ""))
	var start_node: Dictionary = {}
	for node in campaign.get("nodes", []):
		if node is Dictionary and String(node.get("node_id", "")) == start_id:
			start_node = node
			break
	_check(
		String(start_node.get("encounter_id", "")) == ENCOUNTER_ID,
		"the campaign's start node launches the drill",
		"start_node=%s encounter=%s" % [start_id, start_node.get("encounter_id", "")]
	)


func _check(condition: bool, label: String, detail: String = "") -> void:
	if condition:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s%s" % [label, "" if detail == "" else "  [%s]" % detail])
		_failed += 1


func _finish() -> void:
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
