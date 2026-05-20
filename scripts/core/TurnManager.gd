class_name TurnManager extends Node
# Authority on phase progression and per-unit action state. The cursor and
# action menu read from here to know what's selectable and when input is locked.
#
# M14 stage 3: rebuilt as an activation scheduler. Public surface unchanged
# (start_player_phase / end_player_phase / start_enemy_phase still exist for
# the existing controllers + tests), but underneath the cycle is now a list
# of faction ids with a configurable activation policy. A 2-faction map in
# the default WHOLE_PHASE mode runs identically to pre-stage-3.
#
# Activation modes (per Decision 9 / 2026-05-17):
#   WHOLE_PHASE  — exhaust one faction's units, then advance. Today's FE-style
#                  I-Go-You-Go; the default. _begin_phase fires per army phase.
#   ALTERNATING  — advance one faction per single unit committed. _begin_phase
#                  fires once per round (when the cycle wraps), not per phase.

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

# ── Scheduler state (M14 stage 3) ────────────────────────────────────────────
# The ordered list of faction ids this map cycles through. Set in start_map
# from MapData.turn_order; falls back to the default if the map didn't author one.
var _turn_order: Array[String] = []
# Index into _turn_order — the currently activating faction.
var _active_faction_idx: int = 0
# WHOLE_PHASE | ALTERNATING — set in start_map from MapData.activation_mode.
var _activation_mode: String = "WHOLE_PHASE"
# Default cycle when neither MapData.turn_order nor MapData.factions provides one.
# Per GDD_10 § Milestone 14 and the feasibility doc §5: blue → green → red → yellow.
# Stage-1/2 maps only spawn blue + red, so the zero-unit skip in _advance_faction
# collapses this to blue → red automatically.
const _DEFAULT_TURN_ORDER: Array[String] = ["blue", "green", "red", "yellow"]


# Called by GameMap after units have spawned.
func start_map(map_data: MapData, grid: GridManager = null) -> void:
	_map_data = map_data
	_grid = grid
	_turn_order = _derive_turn_order(map_data)
	_activation_mode = _derive_activation_mode(map_data)
	_active_faction_idx = 0
	# In ALTERNATING mode the round-start _begin_phase fires once for all units
	# now (since this IS the start of round 1). WHOLE_PHASE defers begin-phase
	# to start_faction_phase as before.
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.turn_number = 1
		for u in gs.all_units:
			_unit_states[u] = UnitState.READY
	if _activation_mode == "ALTERNATING" and gs != null:
		_begin_phase(gs.all_units)
	# Hook into unit_died so victory checks fire after each kill
	var bus := get_node_or_null("/root/EventBus")
	if bus and not bus.unit_died.is_connected(_on_unit_died):
		bus.unit_died.connect(_on_unit_died)
	# Begin the first faction's phase. For 2-faction WHOLE_PHASE maps the first
	# active faction is "blue", so this is the same as the pre-stage-3 call.
	#
	# Maps that start with a non-blue faction (a stage-4+ content design choice)
	# set up the phase state but DO NOT auto-loop through AI here — the caller
	# (GameMap, or stage-4's run_ai_phase dispatch) is responsible for driving
	# the first non-blue phase. Otherwise the deferred "back to blue" call would
	# fire before any caller could observe the initial scheduler state, and
	# tests asserting "active faction after start_map" become race-prone.
	if active_faction() == "blue" or active_faction() == "":
		start_player_phase()
	else:
		# Non-blue first-faction: set ENEMY phase + per-army begin-phase, but
		# don't await AI / queue start_player_phase. Stage 4 will plumb the
		# controller dispatch here.
		var gs_for_first := get_node_or_null("/root/GameState")
		if gs_for_first:
			gs_for_first.set_phase(gs_for_first.Phase.ENEMY)
			if _activation_mode == "WHOLE_PHASE":
				_begin_phase(gs_for_first.get_living_units_of(active_faction()))


# Reads MapData.turn_order, MapData.factions, or falls back to the default
# four-army cycle. A faction id is allowed even if it has zero living units —
# _advance_faction's skip logic handles that at runtime.
func _derive_turn_order(map_data: MapData) -> Array[String]:
	if map_data != null and not map_data.turn_order.is_empty():
		# Defensive copy — MapData lives in a Resource that could be shared
		# across loads; we mutate _active_faction_idx, not the array, but a
		# future _advance might want to write to _turn_order too.
		return map_data.turn_order.duplicate()
	if map_data != null and not map_data.factions.is_empty():
		var out: Array[String] = []
		for f in map_data.factions:
			if f != null and f.id != "":
				out.append(f.id)
		if not out.is_empty():
			return out
	# Default — copy so callers can't mutate the constant via the returned ref.
	var fallback: Array[String] = []
	for fid in _DEFAULT_TURN_ORDER:
		fallback.append(fid)
	return fallback


func _derive_activation_mode(map_data: MapData) -> String:
	if map_data != null and map_data.activation_mode != "":
		return map_data.activation_mode
	return "WHOLE_PHASE"


# The faction whose phase / activation is currently in flight.
func active_faction() -> String:
	if _turn_order.is_empty():
		return ""
	return _turn_order[_active_faction_idx]


# Advances _active_faction_idx to the next faction in the cycle, skipping any
# faction with zero living units (Decision 2 / 2026-05-17). Returns true iff
# the cycle wrapped past the end of _turn_order — i.e. a new round began.
# If EVERY faction has zero living units (e.g. mutual wipe), the cycle is
# halted and the function returns false without changing the index.
func _advance_faction() -> bool:
	if _turn_order.is_empty():
		return false
	var gs := get_node_or_null("/root/GameState")
	var wrapped := false
	var checked := 0
	while checked < _turn_order.size():
		var next_idx: int = _active_faction_idx + 1
		if next_idx >= _turn_order.size():
			next_idx = 0
			wrapped = true
		_active_faction_idx = next_idx
		checked += 1
		if gs == null:
			# No GameState in this scope — accept the advance as-is rather than loop.
			return wrapped
		if not gs.get_living_units_of(active_faction()).is_empty():
			return wrapped
	# All factions empty — halt.
	return wrapped


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


# Resets all blue units to READY, restores their appearance, sets the phase.
# Does NOT increment turn_number directly — that happens in end_player_phase
# at the moment the player commits to ending their turn.
#
# Stage 3 keeps this name + behaviour intact so MapCursor, EnemyAI, and the
# existing test suite work unchanged. Routes through the new scheduler so
# _active_faction_idx is always in sync with what's actually on-screen.
func start_player_phase() -> void:
	# Sync the scheduler — start_player_phase can be called from EnemyAI's tail
	# (after the enemy phase) or from start_map (initial blue phase); both must
	# leave _active_faction_idx pointing at blue so end_player_phase advances
	# from the right slot.
	_jump_active_faction_to("blue")
	# Check victory/defeat first — if the map is already over (e.g. last enemy died
	# during the enemy phase) we must not reset unit states or call start-of-turn effects
	# on freed nodes.
	check_victory_conditions()
	if _map_over:
		return
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.set_phase(gs.Phase.PLAYER)
		# WHOLE_PHASE (today's mode): map_turn ticks at the start of blue's phase
		# (= round start in the 2-faction default cycle), then _begin_phase fires
		# for blue's units only. ALTERNATING does both at round start in start_map
		# / _alternating_round_wrap, not here.
		if _activation_mode == "WHOLE_PHASE":
			_tick_unit_modifiers(gs.all_units, "map_turn")
			_begin_phase(gs.get_living_units_of("blue"))
	for u in _unit_states.keys():
		# M14 stage 1: literal "player" became the "blue" faction id. Stage 3
		# replaces this loop with `gs.get_living_units_of("blue")` when the
		# per-faction buckets become the only source of truth.
		if u and is_instance_valid(u) and u.team == "blue":
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
#
# Stage 3: advances the scheduler one slot past blue (skipping empties via
# _advance_faction). In a 2-faction default cycle that lands on red exactly
# as pre-stage-3. Stage 4 replaces this single-AI path with a per-faction
# AI loop driven by FactionData.controller.
func start_enemy_phase() -> void:
	# Advance the scheduler from blue to the next non-empty faction. The skip
	# logic in _advance_faction handles the default cycle's empty green/yellow.
	# Guard: only advance if we're sitting on blue — start_enemy_phase can also
	# be reached via a direct test call where the index is already correct.
	if active_faction() == "blue":
		_advance_faction()
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.set_phase(gs.Phase.ENEMY)
		if _activation_mode == "WHOLE_PHASE":
			# Same _begin_phase routine as the player phase — turn-modifier tick, fort
			# healing, then start_of_turn skills (e.g. Renewal) — kept provably symmetric.
			_begin_phase(gs.get_living_units_of(active_faction()))
	var ai := get_node_or_null("/root/EnemyAI")
	if ai:
		await ai.run_enemy_phase(_grid, self)
	else:
		call_deferred("start_player_phase")
	# Victory/defeat during the enemy phase is caught by _on_unit_died (via signal).
	# start_player_phase() covers the turn-limit check at the top of each new turn.


# Scheduler primitive: snap _active_faction_idx onto a specific faction id, if
# it appears in _turn_order. No-op when the id isn't in the cycle (a misconfigured
# map). Stage 3 uses this from start_player_phase to keep the scheduler honest
# under the legacy API; stage 5 (hotseat) and stage 4 (per-AI-faction) will
# call _advance_faction directly instead.
func _jump_active_faction_to(faction_id: String) -> void:
	if faction_id == "":
		return
	var idx: int = _turn_order.find(faction_id)
	if idx >= 0:
		_active_faction_idx = idx


# ── ALTERNATING-mode primitive (M14 stage 3) ─────────────────────────────────
# In ALTERNATING mode the controller (cursor or AI) commits ONE unit, then
# yields back here. _end_alternating_activation advances the scheduler one
# slot, refreshing everyone + ticking map_turn + firing _begin_phase exactly
# at the round boundary (Decision 9 — "_begin_phase timing mode-aware").
#
# Pre-stage-3 single-mode controllers don't call this — they end whole phases
# via start_player_phase / end_player_phase, which keeps WHOLE_PHASE behaviour
# identical. ALTERNATING maps wire their controllers into this primitive in a
# follow-up; tests below pin the primitive directly.
func end_alternating_activation() -> void:
	if _activation_mode != "ALTERNATING":
		return
	var wrapped: bool = _advance_faction()
	if not wrapped:
		return
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	# Round boundary: refresh + map_turn tick + begin-phase across all units.
	gs.turn_number += 1
	turn_changed.emit(gs.turn_number)
	for u in _unit_states.keys():
		if u and is_instance_valid(u):
			_unit_states[u] = UnitState.READY
			if u.has_method("reset_appearance"):
				u.reset_appearance()
	_tick_unit_modifiers(gs.all_units, "map_turn")
	_begin_phase(gs.all_units)
# ─────────────────────────────────────────────────────────────────────────────


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
