class_name ResolvedBattleData extends Resource

@export var battle_map: BattleMapDef
@export var encounter: BattleEncounterDef
@export var source_id: String = ""
@export var legacy_adapter: bool = false


static func from_split(
	map_def: BattleMapDef, encounter_def: BattleEncounterDef, resolved_source_id: String
) -> ResolvedBattleData:
	var result := ResolvedBattleData.new()
	result.battle_map = map_def
	result.encounter = encounter_def
	result.source_id = resolved_source_id
	return result


static func from_legacy(map_data: MapData, resolved_source_id: String) -> ResolvedBattleData:
	if map_data == null:
		return null
	var map_def := BattleMapDef.new()
	map_def.id = map_data.id
	map_def.display_name = map_data.display_name
	map_def.tilemap_scene_path = map_data.tilemap_scene_path
	map_def.grid = map_data.grid.duplicate()
	map_def.camera_start_tile = map_data.camera_start_tile
	map_def.player_start_tiles = map_data.player_start_tiles.duplicate()
	var encounter_def := BattleEncounterDef.new()
	encounter_def.id = map_data.id
	encounter_def.battle_map_id = map_data.id
	encounter_def.enemy_placements = map_data.enemy_placements.duplicate(true)
	encounter_def.factions = map_data.factions.duplicate()
	encounter_def.turn_order = map_data.turn_order.duplicate()
	encounter_def.activation_mode = map_data.activation_mode
	encounter_def.victory_conditions = map_data.victory_conditions.duplicate(true)
	encounter_def.defeat_conditions = map_data.defeat_conditions.duplicate(true)
	encounter_def.reward_gold = map_data.reward_gold
	encounter_def.reward_items = map_data.reward_items.duplicate()
	var result := from_split(map_def, encounter_def, resolved_source_id)
	result.legacy_adapter = true
	return result
