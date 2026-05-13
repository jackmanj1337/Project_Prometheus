extends Node

enum Phase { PLAYER, ENEMY }

# Settings (kept in sync with SettingsManager)
var permadeath_enabled: bool = false
var leveling_method: String = "growth_random"
var max_skills: int = 4
var max_inventory: int = 8

# Current map state
var current_phase: Phase = Phase.PLAYER
var turn_number: int = 1
var all_units: Array[Node] = []
var _player_units: Array[Node] = []
var _enemy_units: Array[Node] = []
var map_data: MapData = null

# Persists between maps — the live roster and shared economy
var player_roster: Array[UnitData] = []
var party_gold: int = 0
var party_items: Array[String] = []  # item IDs awarded by completed maps

# Deep copy taken at map start; used by the Retry button to restore state
var _map_start_snapshot: Array[Dictionary] = []


# Pulls initial values from SettingsManager. Done here (not in SettingsManager.load_settings)
# because GameState autoload runs after SettingsManager — by now SettingsManager._ready()
# has finished and its values are valid.
func _ready() -> void:
	permadeath_enabled = (SettingsManager.permadeath == "on")
	leveling_method = SettingsManager.leveling_method


func register_unit(unit: Node) -> void:
	if unit in all_units:
		push_error("GameState.register_unit: %s already registered" % unit)
		return
	all_units.append(unit)
	if unit.team == "player":
		_player_units.append(unit)
	else:
		_enemy_units.append(unit)


func unregister_unit(unit: Node) -> void:
	all_units.erase(unit)
	_player_units.erase(unit)
	_enemy_units.erase(unit)


func set_phase(new_phase: Phase) -> void:
	current_phase = new_phase
	EventBus.phase_changed.emit(new_phase)


# filter() returns generic Array, so build Array[Node] explicitly
func get_living_player_units() -> Array[Node]:
	var result: Array[Node] = []
	for u in _player_units:
		if is_instance_valid(u) and u.data != null and u.data.hp > 0:
			result.append(u)
	return result


func get_living_enemy_units() -> Array[Node]:
	var result: Array[Node] = []
	for u in _enemy_units:
		if is_instance_valid(u) and u.data != null and u.data.hp > 0:
			result.append(u)
	return result


func is_player_turn() -> bool:
	return current_phase == Phase.PLAYER


func reset_map_state() -> void:
	all_units.clear()
	_player_units.clear()
	_enemy_units.clear()
	map_data = null
	turn_number = 1
	current_phase = Phase.PLAYER


# Loads the 6 default roster UnitData .tres files into player_roster.
# Called by MainMenu on "New Game" for MVP.
func load_default_roster() -> void:
	player_roster.clear()
	var roster_path := "res://data/roster/default/"
	var dir := DirAccess.open(roster_path)
	if dir == null:
		push_error("GameState: cannot open roster directory: " + roster_path)
		return
	# Load in filename order so slot numbering stays consistent
	var files: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()
	for f in files:
		var res: UnitData = load(roster_path + f).duplicate(true)
		if res:
			player_roster.append(res)


# Deep-copies all player UnitData fields into _map_start_snapshot.
# Call once immediately after units are spawned on the map.
func take_map_snapshot() -> void:
	_map_start_snapshot.clear()
	for unit_data in player_roster:
		_map_start_snapshot.append(_snapshot_unit_data(unit_data))


# Restores player_roster UnitData from snapshot, then reloads the current scene.
# Called by GameOverScreen's Retry button.
func restore_map_snapshot() -> void:
	for i in player_roster.size():
		if i < _map_start_snapshot.size():
			_restore_unit_data(player_roster[i], _map_start_snapshot[i])
	reset_map_state()
	# Caller is responsible for reloading the scene after this returns.


func _snapshot_unit_data(data: UnitData) -> Dictionary:
	# Snapshot only the fields that can change during a map.
	# Phase 2 runtime state (modifiers, conditions, counters) is included so a
	# mid-battle suspend save can serialize everything without scene tree traversal.
	return {
		"hp": data.hp,
		"max_hp": data.max_hp,
		"strength": data.strength,
		"magic": data.magic,
		"defense": data.defense,
		"resistance": data.resistance,
		"skill": data.skill,
		"speed": data.speed,
		"luck": data.luck,
		"exp": data.exp,
		"level": data.level,
		"effective_level": data.effective_level,
		"proficiencies": data.proficiencies.duplicate(true),
		"inventory": data.inventory.duplicate(true),
		"conditions": data.conditions.duplicate(true),
		"skills": data.skills.duplicate(),
		"is_incapacitated": data.is_incapacitated,
		# Phase 2 runtime state
		"active_modifiers": data.active_modifiers.duplicate(true),
		"skill_use_counters": data.skill_use_counters.duplicate(true),
		"damage_taken_this_map": data.damage_taken_this_map,
		"growth_accumulators": data.growth_accumulators.duplicate(true),
		"shift_gauge": data.shift_gauge,
		"is_shifted": data.is_shifted,
	}


func _restore_unit_data(data: UnitData, snap: Dictionary) -> void:
	data.hp = snap.hp
	data.max_hp = snap.max_hp
	data.strength = snap.strength
	data.magic = snap.magic
	data.defense = snap.defense
	data.resistance = snap.resistance
	data.skill = snap.skill
	data.speed = snap.speed
	data.luck = snap.luck
	data.exp = snap.exp
	data.level = snap.level
	data.effective_level = snap.effective_level
	data.proficiencies = snap.proficiencies.duplicate(true)
	data.inventory = snap.inventory.duplicate(true)
	data.conditions = snap.conditions.duplicate(true)
	data.skills = snap.skills.duplicate()
	data.is_incapacitated = snap.is_incapacitated
	# Phase 2 runtime state
	data.active_modifiers = snap.active_modifiers.duplicate(true)
	data.skill_use_counters = snap.skill_use_counters.duplicate(true)
	data.damage_taken_this_map = snap.damage_taken_this_map
	data.growth_accumulators = snap.growth_accumulators.duplicate(true)
	data.shift_gauge = snap.shift_gauge
	data.is_shifted = snap.is_shifted
