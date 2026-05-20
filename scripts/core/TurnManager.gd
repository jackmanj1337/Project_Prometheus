class_name TurnManager extends Node
# Authority on phase progression and per-unit action state. The cursor and
# action menu read from here to know what's selectable and when input is locked.

signal turn_changed(turn_number: int)

enum UnitState { READY, MOVED, DONE }

# Node -> UnitState
var _unit_states: Dictionary = {}
# Saved tile when a unit starts moving so undo_move can restore it
var _original_tiles: Dictionary = {}
var _map_data: MapData = null
var _grid: GridManager = null
# Latches true on first map_victory/map_defeat emit to prevent double-fire.
var _map_over: bool = false


# Called by GameMap after units have spawned.
func start_map(map_data: MapData, grid: GridManager = null) -> void:
	_map_data = map_data
	_grid = grid
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


# Heals units standing on fort tiles by 10% max HP (GDD_02 terrain table).
# Called at the start of each phase (player and enemy) so both sides benefit.
func _apply_fort_healing(units: Array[Node]) -> void:
	if _grid == null:
		return
	for u in units:
		if not is_instance_valid(u) or u.data == null:
			continue
		if u.data.hp <= 0 or u.data.hp >= u.data.max_hp:
			continue
		if _grid.get_terrain_at(u.tile_position) == "fort":
			# Round down per GDD_02:76 — matches Renewal and the global rounding rule.
			var heal_amount: int = floori(u.data.max_hp * GameConstants.PERCENT_HP_HEAL_FRACTION)
			u.heal(heal_amount)


# Fires SkillHandler.start_of_turn trigger for each unit (e.g. Renewal healing).
func _apply_start_of_turn_skills(units: Array[Node]) -> void:
	var sh := get_node_or_null("/root/SkillHandler")
	if sh == null:
		return
	for u in units:
		if is_instance_valid(u):
			sh.apply_trigger(u, "start_of_turn", {"unit": u})


# Ticks duration-based modifiers for a list of units. duration_type is "turn"
# (per unit's own phase) or "map_turn" (once per full round for all units).
func _tick_unit_modifiers(units: Array[Node], duration_type: String) -> void:
	for u in units:
		if is_instance_valid(u) and u.has_method("tick_modifiers"):
			u.tick_modifiers(duration_type)


# The per-phase routine shared by both phases: tick each unit's "turn"-duration
# modifiers, apply fort/throne healing, then fire start_of_turn skills. Keeping the
# three steps in one place means the player and enemy phases cannot drift apart.
func _begin_phase(units: Array[Node]) -> void:
	_tick_unit_modifiers(units, "turn")
	_apply_fort_healing(units)
	_apply_start_of_turn_skills(units)


# Resets all player units to READY, restores their appearance, sets the phase.
# Does NOT increment turn_number directly — that happens in end_player_phase
# at the moment the player commits to ending their turn.
func start_player_phase() -> void:
	# Check victory/defeat first — if the map is already over (e.g. last enemy died
	# during the enemy phase) we must not reset unit states or call start-of-turn effects
	# on freed nodes.
	check_victory_conditions()
	if _map_over:
		return
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.set_phase(gs.Phase.PLAYER)
		# map_turn ticks once per round (at the start of player phase, for all units)
		_tick_unit_modifiers(gs.all_units, "map_turn")
		_begin_phase(gs.get_living_player_units())
	for u in _unit_states.keys():
		if u and is_instance_valid(u) and u.team == "player":
			_unit_states[u] = UnitState.READY
			if u.has_method("reset_appearance"):
				u.reset_appearance()


# Called via the map menu's End Turn request (MapCursor._on_end_turn_requested).
# Increments the turn counter and transitions to the enemy phase.
func end_player_phase() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.turn_number += 1
		turn_changed.emit(gs.turn_number)
	start_enemy_phase()


# Enemy phase: fort healing, then AI moves each enemy, then player phase resumes.
# EnemyAI.run_enemy_phase() is awaited; without the autoload it falls back instantly.
func start_enemy_phase() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.set_phase(gs.Phase.ENEMY)
		# Same _begin_phase routine as the player phase — turn-modifier tick, fort
		# healing, then start_of_turn skills (e.g. Renewal) — kept provably symmetric.
		_begin_phase(gs.get_living_enemy_units())
	var ai := get_node_or_null("/root/EnemyAI")
	if ai:
		await ai.run_enemy_phase(_grid, self)
	else:
		call_deferred("start_player_phase")
	# Victory/defeat during the enemy phase is caught by _on_unit_died (via signal).
	# start_player_phase() covers the turn-limit check at the top of each new turn.


func set_unit_state(unit: Node, state: UnitState) -> void:
	if unit == null:
		return
	_unit_states[unit] = state
	if state == UnitState.DONE and unit.has_method("set_done_appearance"):
		unit.set_done_appearance()
	# When the last player unit finishes, end the phase automatically (#5).
	# Deferred so the current action fully unwinds first; _auto_end_player_phase
	# re-checks the conditions, so a redundant deferred call is harmless.
	if state == UnitState.DONE:
		var gs := get_node_or_null("/root/GameState")
		if gs and gs.is_player_turn() and are_all_player_units_done():
			call_deferred("_auto_end_player_phase")


# Deferred from set_unit_state / _on_unit_died — ends the player phase once every
# player unit is done. Re-validates because state may have changed between defer
# and call; bails when the map already ended so it can't run an enemy phase after
# a victory/defeat.
func _auto_end_player_phase() -> void:
	if _map_over:
		return
	# The player can switch auto-end off (#2); the phase then ends only via the
	# map menu's End Turn, even when every unit has already acted.
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null and not sm.auto_end_turn:
		return
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.is_player_turn() and are_all_player_units_done():
		end_player_phase()


func get_unit_state(unit: Node) -> UnitState:
	return _unit_states.get(unit, UnitState.READY)


# A unit can act when it has not yet committed its turn (READY or MOVED).
func can_unit_act(unit: Node) -> bool:
	var s: UnitState = get_unit_state(unit)
	return s == UnitState.READY or s == UnitState.MOVED


# True when no living player unit can still act. Used by the End Turn flow to
# decide whether to skip the "some units have not acted" confirmation prompt.
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
	# _map_over prevents double-emit when this is called from both unit_died signal
	# and phase-transition hooks in the same frame.
	if _map_over or _map_data == null:
		return
	var gs := get_node_or_null("/root/GameState")
	var bus := get_node_or_null("/root/EventBus")
	if gs == null or bus == null:
		return
	# Turn limit defeat (0 = no limit)
	if _map_data.turn_limit > 0 and gs.turn_number > _map_data.turn_limit:
		_map_over = true
		bus.map_defeat.emit()
		return
	# MVP supports rout only
	if _map_data.objective_type == "rout":
		if gs.get_living_enemy_units().is_empty():
			_map_over = true
			_apply_victory_rewards(gs)
			bus.map_victory.emit()
			return
	# Defeat: all player units dead
	if gs.get_living_player_units().is_empty():
		_map_over = true
		bus.map_defeat.emit()
		return
	# Defeat: a required survivor was killed (matched by unit_id)
	for required_id in _map_data.required_survivor_ids:
		var alive := false
		for u in gs.get_living_player_units():
			if u.data and u.data.unit_id == required_id:
				alive = true
				break
		if not alive:
			_map_over = true
			bus.map_defeat.emit()
			return


func _apply_victory_rewards(gs: Node) -> void:
	if _map_data.reward_gold > 0:
		gs.party_gold += _map_data.reward_gold
	for item_id in _map_data.reward_items:
		gs.party_items.append(item_id)


func _on_unit_died(unit: Node) -> void:
	_unit_states.erase(unit)
	_original_tiles.erase(unit)
	check_victory_conditions()
	# A death (e.g. a mutual kill on the last unit's own action) can leave every
	# remaining player unit already DONE — set_unit_state never ran for the dead
	# unit, so auto-end it here too (#5). _auto_end_player_phase bails if the map
	# just ended via the check_victory_conditions call above.
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.is_player_turn() and are_all_player_units_done():
		call_deferred("_auto_end_player_phase")
