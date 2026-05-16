extends Node
# [NOTE — M-1] class_name cannot be used on autoload scripts in Godot 4, even with a
# name that differs from the autoload name — Godot refuses to register the class_name.
# TODO save-system: the current snapshot (_map_start_snapshot) is in-memory only and
# covers player UnitData. Suspend saves additionally need: (a) live enemy UnitData state
# (enemies are re-spawned fresh today — see GameMap._spawn_units), and (b) live terrain
# mutations if MapData.grid ever diverges at runtime. Neither is in scope until the
# save-system milestone — see §0b N2 in code_review_2026-05-13c.

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
	# Access SettingsManager at runtime via get_node to avoid a compile-time ordering
	# issue in headless mode: GDScript may compile GameState.gd before SettingsManager.gd.
	var sm := get_node_or_null("/root/SettingsManager")
	if sm == null:
		push_error("GameState: SettingsManager autoload missing — check autoload ordering in Project Settings")
		return
	permadeath_enabled = sm.get("permadeath")
	leveling_method = sm.get("leveling_method")


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
	# Use emit_signal to avoid a compile-time dependency on EventBus identifier
	# (autoloads must not reference each other by identifier — use get_node_or_null).
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.emit_signal("phase_changed", new_phase)


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
		# Emit defeat so the game doesn't silently start with zero player units
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.map_defeat.emit()
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
			assert(res.unit_id != "", "GameState: roster file '%s' has empty unit_id — set it in the .tres" % f)
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
		"tile_position": data.tile_position,
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
		"skills": data.skills.duplicate(true),
		"mastery_skills": data.mastery_skills.duplicate(true),
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
	# Use .get() with defaults so older snapshots missing newer fields don't crash.
	data.tile_position = snap.get("tile_position", Vector2i.ZERO)
	data.hp = snap.get("hp", data.max_hp)
	data.max_hp = snap.get("max_hp", data.max_hp)
	data.strength = snap.get("strength", data.strength)
	data.magic = snap.get("magic", data.magic)
	data.defense = snap.get("defense", data.defense)
	data.resistance = snap.get("resistance", data.resistance)
	data.skill = snap.get("skill", data.skill)
	data.speed = snap.get("speed", data.speed)
	data.luck = snap.get("luck", data.luck)
	data.exp = snap.get("exp", 0)
	data.level = snap.get("level", data.level)
	data.effective_level = snap.get("effective_level", data.effective_level)
	data.proficiencies = snap.get("proficiencies", {}).duplicate(true)
	data.inventory.clear()
	data.inventory.assign(snap.get("inventory", []))
	data.conditions = snap.get("conditions", []).duplicate(true)
	data.skills = snap.get("skills", []).duplicate(true)
	data.mastery_skills = snap.get("mastery_skills", []).duplicate(true)
	data.is_incapacitated = snap.get("is_incapacitated", false)
	# Phase 2 runtime state
	data.active_modifiers = snap.get("active_modifiers", {}).duplicate(true)
	data.skill_use_counters = snap.get("skill_use_counters", {}).duplicate(true)
	data.damage_taken_this_map = snap.get("damage_taken_this_map", 0)
	data.growth_accumulators = snap.get("growth_accumulators", {}).duplicate(true)
	data.shift_gauge = snap.get("shift_gauge", 0.0)
	data.is_shifted = snap.get("is_shifted", false)
