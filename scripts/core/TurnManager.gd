class_name TurnManager extends Node
# Authority on phase progression and per-unit action state. The cursor and
# action menu read from here to know what's selectable and when input is locked.

enum UnitState { READY, MOVED, DONE }

# Node -> UnitState
var _unit_states: Dictionary = {}
# Saved tile when a unit starts moving so undo_move can restore it
var _original_tiles: Dictionary = {}
# True while combat or movement animations are playing — input is suppressed
var _combat_lock: bool = false

var _map_data: MapData = null


# Called by GameMap after units have spawned.
func start_map(map_data: MapData) -> void:
	_map_data = map_data
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.turn_number = 1
		for u in gs.all_units:
			_unit_states[u] = UnitState.READY
	# Hook into unit_died so victory checks fire after each kill
	var bus := get_node_or_null("/root/EventBus")
	if bus and not bus.unit_died.is_connected(_on_unit_died):
		bus.unit_died.connect(_on_unit_died)
	# First player phase — does NOT increment turn_number (we're already on turn 1)
	start_player_phase()


# Resets all player units to READY, restores their appearance, sets the phase.
# Does NOT increment turn_number directly — that happens in end_player_phase
# at the moment the player commits to ending their turn.
func start_player_phase() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.set_phase(gs.Phase.PLAYER)
	for u in _unit_states.keys():
		if u and is_instance_valid(u) and u.team == "player":
			_unit_states[u] = UnitState.READY
			if u.has_method("reset_appearance"):
				u.reset_appearance()


# Called by the End Turn button or by auto-end when all player units are DONE.
# Increments the turn counter and transitions to the enemy phase.
func end_player_phase() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.turn_number += 1
	start_enemy_phase()


# Enemy phase. AI runs in M6; for now this is a stub that flips back to player
# phase on the next idle frame (call_deferred avoids recursion through start_*).
func start_enemy_phase() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.set_phase(gs.Phase.ENEMY)
	# TODO M6: EnemyAI.run_enemy_phase() — for now immediately end the phase
	call_deferred("start_player_phase")


func set_unit_state(unit: Node, state: UnitState) -> void:
	if unit == null:
		return
	_unit_states[unit] = state
	if state == UnitState.DONE and unit.has_method("set_done_appearance"):
		unit.set_done_appearance()


func get_unit_state(unit: Node) -> UnitState:
	return _unit_states.get(unit, UnitState.READY)


# A unit can act when it has not yet committed its turn (READY or MOVED).
func can_unit_act(unit: Node) -> bool:
	var s: UnitState = get_unit_state(unit)
	return s == UnitState.READY or s == UnitState.MOVED


# True when every living player unit's state is DONE (used for auto-end-phase
# and to enable the "End Turn" confirmation prompt).
func are_all_player_units_done() -> bool:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return false
	for u in gs.get_living_player_units():
		if can_unit_act(u):
			return false
	return true


# Called when player picks "Cancel" after moving a unit but before committing.
# Returns the unit to its pre-move tile and resets state to READY.
func record_move_start(unit: Node) -> void:
	if unit:
		_original_tiles[unit] = unit.tile_position


func undo_move(unit: Node) -> void:
	if unit == null:
		return
	var orig: Vector2i = _original_tiles.get(unit, unit.tile_position)
	unit.snap_to_tile(orig)
	_unit_states[unit] = UnitState.READY
	_original_tiles.erase(unit)


# Called after every unit death (via EventBus.unit_died) and on enemy phase end.
# Reads MapData.objective_type and emits map_victory/map_defeat accordingly.
func check_victory_conditions() -> void:
	if _map_data == null:
		return
	var gs := get_node_or_null("/root/GameState")
	var bus := get_node_or_null("/root/EventBus")
	if gs == null or bus == null:
		return
	# MVP supports rout only
	if _map_data.objective_type == "rout":
		if gs.get_living_enemy_units().is_empty():
			bus.map_victory.emit()
			return
	# Defeat: any required survivor dead, OR all player units dead
	if gs.get_living_player_units().is_empty():
		bus.map_defeat.emit()
		return
	for required_name in _map_data.required_survivor_names:
		var alive := false
		for u in gs.get_living_player_units():
			if u.data and u.data.unit_name == required_name:
				alive = true
				break
		if not alive:
			bus.map_defeat.emit()
			return


func _on_unit_died(_unit: Node) -> void:
	check_victory_conditions()
