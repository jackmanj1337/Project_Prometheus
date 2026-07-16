class_name BattleEncounterDef extends Resource

@export var id: String = ""
@export var battle_map_id: String = ""
@export var enemy_placements: Array[Dictionary] = []
@export var factions: Array[FactionData] = []
@export var turn_order: Array[String] = []
@export var activation_mode: String = "WHOLE_PHASE"
@export var victory_conditions: Dictionary = {}
@export var defeat_conditions: Dictionary = {}
@export var reward_gold: int = 0
@export var reward_items: Array[String] = []


func get_faction(faction_id: String) -> FactionData:
	for faction in factions:
		if faction != null and faction.id == faction_id:
			return faction
	return null
