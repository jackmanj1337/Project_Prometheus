extends SceneTree

const DataManagerS = preload("res://scripts/autoloads/DataManager.gd")
const ENTRIES := [
	["map_001", "res://data/maps/map_001_rout/map_001_data.tres"],
	["map_001_c3_factions", "res://data/maps/map_001_rout/map_001_c3_factions_data.tres"],
	["map_002_seize", "res://data/maps/map_002_seize/map_002_seize_data.tres"],
	["map_003_defeat_boss", "res://data/maps/map_003_defeat_boss/map_003_defeat_boss_data.tres"],
	["map_004_escape", "res://data/maps/map_004_escape/map_004_escape_data.tres"],
	["map_005_defend", "res://data/maps/map_005_defend/map_005_defend_data.tres"],
	[
		"map_900_hotseat_validation",
		"res://data/maps/map_900_hotseat_validation/map_900_hotseat_validation_data.tres"
	],
	[
		"map_950_promotion_validation",
		"res://data/maps/map_950_promotion_validation/map_950_promotion_validation_data.tres"
	],
]

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String, detail: String = "") -> void:
	if ok:
		passed += 1
		print("OK  " + message)
	else:
		failed += 1
		print("FAIL %s%s" % [message, " — " + detail if detail != "" else ""])


func _run() -> void:
	await process_frame
	var dm := root.get_node_or_null("DataManager")
	_check(dm != null, "DataManager booted the split catalogues")
	if dm == null:
		quit(1)
		return
	for row in ENTRIES:
		var map_id: String = row[0]
		var legacy: MapData = load(row[1])
		var split: ResolvedBattleData = dm.resolve_battle_source("encounter_" + map_id)
		var adapted: ResolvedBattleData = dm.resolve_battle_source(row[1])
		_check(split != null and not split.legacy_adapter, map_id + " resolves through split data")
		_check(
			adapted != null and adapted.legacy_adapter, map_id + " resolves through legacy adapter"
		)
		_check(
			_map_projection(legacy) == _split_map_projection(split.battle_map),
			map_id + " terrain/camera/deployment projection is equivalent"
		)
		_check(
			_encounter_projection(legacy) == _split_encounter_projection(split.encounter),
			map_id + " placement/rules/reward projection is equivalent"
		)
		_check(
			split.encounter.enemy_placements == adapted.encounter.enemy_placements,
			map_id + " preserves authored placement order and overrides"
		)
	var bad_map := BattleMapDef.new()
	bad_map.id = "bad"
	bad_map.display_name = "Bad"
	bad_map.grid.assign(["..", "."])
	bad_map.player_start_tiles.assign([Vector2i(4, 4)])
	var bad_encounter := BattleEncounterDef.new()
	bad_encounter.id = "bad_encounter"
	bad_encounter.battle_map_id = "missing"
	bad_encounter.activation_mode = "SIMULTANEOUS"
	var errors := DataManagerS.collect_battle_catalogue_validation_errors(
		{"bad": bad_map}, {"bad_encounter": bad_encounter}, {}, {}
	)
	_check(
		(
			errors.any(func(e: String): return "not rectangular" in e)
			and errors.any(func(e: String): return "out-of-bounds" in e)
			and errors.any(func(e: String): return "unknown battle map" in e)
			and errors.any(func(e: String): return "invalid activation_mode" in e)
		),
		"catalogue validation rejects malformed grids, starts, references, and activation",
		str(errors)
	)
	var gs := root.get_node_or_null("GameState")
	gs.load_default_roster()
	gs.configure_next_map("encounter_map_002_seize", "default_roster", "")
	var scene: PackedScene = load("res://scenes/core/GameMap.tscn")
	var game_map := scene.instantiate()
	root.add_child(game_map)
	await process_frame
	_check(
		(
			game_map.battle_data != null
			and not game_map.battle_data.legacy_adapter
			and game_map.map_data.id == "map_002_seize"
			and game_map.encounter_data.id == "encounter_map_002_seize"
		),
		"GameMap consumes the split map and encounter halves through one bundle"
	)
	_check(
		game_map.get_node("UnitsContainer").get_child_count() == 10,
		"split GameMap launch preserves player and enemy spawn behavior"
	)
	_check(
		gs._current_map_path() == "encounter_map_002_seize",
		"retry/suspend identity remains the staged encounter source"
	)
	game_map.queue_free()
	await process_frame
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed else 0)


func _map_projection(data: MapData) -> Dictionary:
	return {
		"display_name": data.display_name,
		"tilemap_scene_path": data.tilemap_scene_path,
		"grid": data.grid,
		"camera_start_tile": data.camera_start_tile,
		"player_start_tiles": data.player_start_tiles,
	}


func _split_map_projection(data: BattleMapDef) -> Dictionary:
	return {
		"display_name": data.display_name,
		"tilemap_scene_path": data.tilemap_scene_path,
		"grid": data.grid,
		"camera_start_tile": data.camera_start_tile,
		"player_start_tiles": data.player_start_tiles,
	}


func _encounter_projection(data: MapData) -> Dictionary:
	return {
		"enemy_placements": data.enemy_placements,
		"factions": _normalize(data.factions),
		"turn_order": data.turn_order,
		"activation_mode": data.activation_mode,
		"victory_conditions": _normalize(data.victory_conditions),
		"defeat_conditions": _normalize(data.defeat_conditions),
		"reward_gold": data.reward_gold,
		"reward_items": data.reward_items,
	}


func _split_encounter_projection(data: BattleEncounterDef) -> Dictionary:
	return {
		"enemy_placements": data.enemy_placements,
		"factions": _normalize(data.factions),
		"turn_order": data.turn_order,
		"activation_mode": data.activation_mode,
		"victory_conditions": _normalize(data.victory_conditions),
		"defeat_conditions": _normalize(data.defeat_conditions),
		"reward_gold": data.reward_gold,
		"reward_items": data.reward_items,
	}


func _normalize(value: Variant) -> Variant:
	if value is Resource:
		var result := {}
		for property in value.get_property_list():
			if int(property.get("usage", 0)) & PROPERTY_USAGE_STORAGE:
				var name: String = property.get("name", "")
				if name != "resource_path" and name != "resource_name" and name != "script":
					result[name] = _normalize(value.get(name))
		return result
	if value is Array:
		var result: Array = []
		for entry in value:
			result.append(_normalize(entry))
		return result
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _normalize(value[key])
		return result
	return value
