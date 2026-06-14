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
signal phase_committed

enum UnitState { READY, MOVED, DONE }

# Node -> UnitState
var _unit_states: Dictionary = {}
# Saved tile when a unit starts moving so undo_move can restore it
var _original_tiles: Dictionary = {}
var _map_data: MapData = null
var _grid: GridManager = null
# Latches true on first map_victory/map_defeat emit to prevent double-fire.
var _map_over: bool = false

# M16 stage 2: per-group elimination tracking. Maps alliance-group id ("allies",
# "foes", ...) → turn_number when that group was first marked eliminated. A
# group not in the dict is still in the game. Drives the ranked-standings
# results screen (M16 stage 4); the evaluator below populates it and the
# get_group_eliminated_round() accessor reads it.
var _group_eliminated_round: Dictionary = {}

# M16 stage 3: per-record event tracking for the four new condition types.
# Seize is action-driven (record_seize); escape is movement-driven (the
# unit_moved signal hook). Both arrays are reset implicitly when a fresh
# TurnManager is instantiated for a new map.
#
# _seize_records: each entry = {tile: Vector2i, unit_id: String, faction: String}
#   — the unit that performed the Seize action on that tile. Multiple records
#   per tile are allowed (in case a future map design re-seizes after loss).
# _escape_records: each entry = {unit_id: String, faction: String} for a unit
#   that left the map via an escape zone. The escape evaluator passes when
#   every named unit appears here; the protect evaluator treats escaped ids as
#   still-alive because escape is not death.
var _seize_records: Array[Dictionary] = []
var _escape_records: Array[Dictionary] = []

# ── Scheduler state (M14 stage 3) ────────────────────────────────────────────
# The ordered list of faction ids this map cycles through. Set in start_map
# from MapData.turn_order; falls back to the default if the map didn't author one.
var _turn_order: Array[String] = []
# Index into _turn_order — the currently activating faction.
var _active_faction_idx: int = 0
# WHOLE_PHASE | ALTERNATING — set in start_map from MapData.activation_mode.
var _activation_mode: String = "WHOLE_PHASE"
# Optional AI driver override for deterministic tests. When null, the autoload
# /root/EnemyAI is used.
var _ai_controller: Node = null
var _hotseat_controller: Node = null
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
	# Hook into unit_died so victory checks fire after each kill. Escape used to
	# be wired on unit_moved (Decision 5 / 2026-05-17), but the 2026-05-20 review
	# reversed it — escape is now a deliberate ActionMenu entry like Seize, so
	# no movement hook is needed.
	var bus := get_node_or_null("/root/EventBus")
	if bus and not bus.unit_died.is_connected(_on_unit_died):
		bus.unit_died.connect(_on_unit_died)
	# Begin the first faction's phase.
	if active_faction() == "blue" or active_faction() == "":
		start_player_phase()
	else:
		# Stage 4: non-blue first faction dispatches through the per-faction AI
		# loop in WHOLE_PHASE mode. ALTERNATING handoff remains a later step.
		if _activation_mode == "WHOLE_PHASE":
			call_deferred("start_enemy_phase")
		else:
			var gs_for_first := get_node_or_null("/root/GameState")
			if gs_for_first:
				gs_for_first.set_phase(gs_for_first.Phase.ENEMY, active_faction())


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


# Test seam: inject an AI controller node that responds to
# run_phase(grid, turn, faction_id). Null resets to the autoload lookup.
func set_ai_controller(ai: Node) -> void:
	_ai_controller = ai


# Test seam: inject a hotseat controller node that responds to
# run_phase(grid, turn, faction_id). Null resets to the local hotseat driver.
func set_hotseat_controller(controller: Node) -> void:
	_hotseat_controller = controller


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


# Whole-phase maps refresh the acting faction at the start of that faction's
# turn, not just Blue. Hotseat and multi-faction validation maps rely on this
# so non-blue local factions do not stay latched in DONE across rounds.
func _refresh_faction_units(faction_id: String) -> void:
	if faction_id == "":
		return
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	for u in gs.get_living_units_of(faction_id):
		_unit_states[u] = UnitState.READY
		if u.has_method("reset_appearance"):
			u.reset_appearance()


# Resets all blue units to READY, restores their appearance, sets the phase.
# turn_number advances at the full faction-cycle wrap before this begins.
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
		gs.set_phase(gs.Phase.PLAYER, "blue")
		# WHOLE_PHASE (today's mode): map_turn ticks at the start of blue's phase
		# (= round start in the 2-faction default cycle), then _begin_phase fires
		# for blue's units only. ALTERNATING does both at round start in start_map
		# / _alternating_round_wrap, not here.
		if _activation_mode == "WHOLE_PHASE":
			_refresh_faction_units("blue")
			_tick_unit_modifiers(gs.all_units, "map_turn")
			_begin_phase(gs.get_living_units_of("blue"))
		else:
			# ALTERNATING handoff: control returns to blue without per-phase refresh.
			return
	for u in _unit_states.keys():
		# M14 stage 1: literal "player" became the "blue" faction id. Stage 3
		# replaces this loop with `gs.get_living_units_of("blue")` when the
		# per-faction buckets become the only source of truth.
		if u and is_instance_valid(u) and u.team == "blue":
			_unit_states[u] = UnitState.READY
			if u.has_method("reset_appearance"):
				u.reset_appearance()


# Called via the map menu's End Turn request (MapCursor._on_end_turn_requested).
# Transitions to the remaining faction phases. The round counter does not
# advance until the scheduler wraps back to blue.
func end_player_phase() -> void:
	start_enemy_phase()


# Enemy phase: run each consecutive non-blue controller in turn order, then
# return control to blue. The loop is bounded so a malformed turn_order that
# omits "blue" fails with push_error instead of hanging forever.
func start_enemy_phase() -> void:
	# Advance the scheduler from blue to the next non-empty faction. The skip
	# logic in _advance_faction handles the default cycle's empty green/yellow.
	# Guard: only advance if we're sitting on blue — start_enemy_phase can also
	# be reached via a direct test call where the index is already correct.
	if active_faction() == "blue":
		if _advance_faction():
			_complete_round()
	# Stage 4/5: run each consecutive non-blue faction controller, then hand back to blue.
	var guard: int = _turn_order.size() + 1
	while active_faction() != "blue" and active_faction() != "":
		guard -= 1
		if guard < 0:
			push_error("TurnManager: enemy-phase loop never returned to blue — turn_order is missing 'blue'")
			break
		# Decision 7 phase-boundary sweep: the evaluator runs at the start of every
		# faction's phase (not just blue's).
		check_victory_conditions()
		if _map_over:
			return
		var gs := get_node_or_null("/root/GameState")
		if gs:
			gs.set_phase(gs.Phase.ENEMY, active_faction())
			if _activation_mode == "WHOLE_PHASE":
				# Same _begin_phase routine as the player phase — turn-modifier tick, fort
				# healing, then start_of_turn skills (e.g. Renewal) — kept symmetric.
				_refresh_faction_units(active_faction())
				_begin_phase(gs.get_living_units_of(active_faction()))
		var controller := _controller_for(active_faction())
		if controller != null:
			await controller.run_phase(_grid, self, active_faction())
		if _map_over:
			return
		# For now M14 stage 4 is WHOLE_PHASE-only AI dispatch; ALTERNATING
		# controller handoff lands with the stage-5/hotseat flow.
		if _activation_mode != "WHOLE_PHASE":
			break
		if _advance_faction():
			_complete_round()
	# Victory/defeat during AI phases is caught by _on_unit_died (signal), and
	# start_player_phase() covers the turn-limit check at the top of blue's phase.
	start_player_phase()


# Completes one full faction cycle. WHOLE_PHASE calls this when the scheduler
# wraps to blue; ALTERNATING uses the same round semantics in its own refresh
# path below.
func _complete_round() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	gs.turn_number += 1
	turn_changed.emit(gs.turn_number)


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


# True when the faction should be driven by EnemyAI in M14 stage 4.
# For maps without authored FactionData entries, every non-blue faction defaults
# to AI so existing content keeps working.
func _is_ai_controlled(faction_id: String) -> bool:
	if faction_id == "" or faction_id == "blue":
		return false
	if _map_data != null:
		for f in _map_data.factions:
			if f != null and f.id == faction_id:
				return f.controller == "" or f.controller == "AI"
	return true


func _is_hotseat_controlled(faction_id: String) -> bool:
	if faction_id == "" or faction_id == "blue":
		return false
	if _map_data != null:
		for f in _map_data.factions:
			if f != null and f.id == faction_id:
				return f.controller == "HOTSEAT"
	return false


func _controller_for(faction_id: String) -> Node:
	if _is_hotseat_controlled(faction_id):
		return _hotseat_controller
	if _is_ai_controlled(faction_id):
		return _ai_controller if _ai_controller != null else get_node_or_null("/root/EnemyAI")
	return null


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
	# When the last locally-human-controlled unit finishes, end the phase
	# automatically (#5 / M15 Part A). Deferred so the current action fully
	# unwinds first; _auto_end_active_phase re-checks the conditions, so a
	# redundant deferred call is harmless.
	if state == UnitState.DONE:
		var active_faction_id: String = _active_or_default_faction()
		if _should_auto_end_faction(active_faction_id) and are_all_units_done(active_faction_id):
			call_deferred("_auto_end_active_phase")


# Deferred from set_unit_state / _on_unit_died — ends the active locally-human
# phase once every unit is done. Re-validates because state may have changed
# between defer and call; bails when the map already ended so it can't run an
# enemy phase after a victory/defeat.
func _auto_end_active_phase() -> void:
	if _map_over:
		return
	# The player can switch auto-end off (#2); the phase then ends only via the
	# map menu's End Turn, even when every unit has already acted. Hotseat uses
	# the same local preference.
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null and not sm.auto_end_turn:
		return
	var active_faction_id: String = _active_or_default_faction()
	if not _should_auto_end_faction(active_faction_id):
		return
	if are_all_units_done(active_faction_id):
		request_end_phase()


# Legacy entry point kept for the existing tests and call sites.
func _auto_end_player_phase() -> void:
	_auto_end_active_phase()


func get_unit_state(unit: Node) -> UnitState:
	return _unit_states.get(unit, UnitState.READY)


# A unit can act when it has not yet committed its turn (READY or MOVED).
func can_unit_act(unit: Node) -> bool:
	var s: UnitState = get_unit_state(unit)
	return s == UnitState.READY or s == UnitState.MOVED


# True when no living player unit can still act. Used by the End Turn flow to
# decide whether to skip the "some units have not acted" confirmation prompt.
func are_all_player_units_done() -> bool:
	return are_all_units_done("blue")


func are_all_units_done(faction_id: String) -> bool:
	var gs := get_node_or_null("/root/GameState")
	if gs == null or faction_id == "":
		return false
	var living_units: Array[Node] = []
	if gs.has_method("get_living_units_of"):
		living_units = gs.get_living_units_of(faction_id)
	elif faction_id == "blue" and gs.has_method("get_living_player_units"):
		living_units = gs.get_living_player_units()
	else:
		return false
	for u in living_units:
		if can_unit_act(u):
			return false
	return true


func request_end_phase() -> void:
	if _map_over:
		return
	var faction_id: String = _active_or_default_faction()
	if faction_id == "":
		return
	if faction_id == "blue":
		end_player_phase()
		return
	phase_committed.emit()


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


# M16: generic per-group victory/defeat evaluator (Decision 8 / 2026-05-17).
# Loops every alliance group that has at least one registered faction OR an
# authored condition set. Per group:
#   victory = AND of every condition in MapData.victory_conditions[group]
#   defeat  = OR  of any condition in MapData.defeat_conditions[group]
# A group is eliminated only by an authored defeat condition. After defeats
# are marked: <=1 group still in play -> last-standing wins; 0 -> draw.
#
# Blue-perspective EventBus signals: blue's alliance group winning →
# map_victory; blue eliminated or draw → map_defeat. The ranked-standings UI
# (GameOverScreen) listens to map_resolved instead, which carries the full
# per-group standings.
func check_victory_conditions() -> void:
	# _map_over prevents double-emit when this is called from both unit_died signal
	# and phase-transition hooks in the same frame.
	if _map_over or _map_data == null:
		return
	var gs := get_node_or_null("/root/GameState")
	var bus := get_node_or_null("/root/EventBus")
	if gs == null or bus == null:
		return

	var groups: Array[String] = _all_evaluated_groups(gs)
	var victory_by_group: Dictionary = {}
	var defeat_by_group: Dictionary = {}
	for g in groups:
		victory_by_group[g] = _conditions_for_group(_map_data.victory_conditions, g)
		defeat_by_group[g]  = _conditions_for_group(_map_data.defeat_conditions, g)

	var round_n: int = gs.turn_number

	# Step 1: mark newly-eliminated groups (defeat = OR of conditions).
	for g in groups:
		if _group_eliminated_round.has(g):
			continue
		for cond in defeat_by_group[g]:
			if _evaluate_condition(cond, g, gs):
				_group_eliminated_round[g] = round_n
				break

	# Step 2: check victory among groups still in play (victory = AND of conditions).
	var winner: String = ""
	for g in groups:
		if _group_eliminated_round.has(g):
			continue
		var vlist: Array = victory_by_group[g]
		if vlist.is_empty():
			continue
		var all_met: bool = true
		for cond in vlist:
			if not _evaluate_condition(cond, g, gs):
				all_met = false
				break
		if all_met:
			winner = g
			break

	# Step 3: last-group-standing / draw fallback.
	var in_play: Array[String] = []
	for g in groups:
		if not _group_eliminated_round.has(g):
			in_play.append(g)
	if winner == "":
		if in_play.size() == 1:
			var sole_survivor: String = in_play[0]
			if not _group_has_authored_victory_conditions(sole_survivor):
				winner = sole_survivor
		elif in_play.size() == 0:
			# Simultaneous wipe-out — draw. Map ends with no victor; blue is in
			# the eliminated set so the legacy signal is map_defeat. The
			# standings screen leads with "DRAW" instead of a winner.
			_map_over = true
			phase_committed.emit()
			bus.map_defeat.emit()
			bus.map_resolved.emit("", _build_standings("", groups, gs))
			return

	if winner == "":
		# No winner decided this evaluation pass — map continues.
		return

	# Map decided. Fire the blue-perspective signal for the existing GameOverScreen,
	# then map_resolved with the ranked standings for the M16 results screen.
	_map_over = true
	phase_committed.emit()
	var blue_group: String = gs.get_alliance_group("blue")
	if winner == blue_group:
		_apply_victory_rewards(gs)
		bus.map_victory.emit()
	else:
		bus.map_defeat.emit()
	bus.map_resolved.emit(winner, _build_standings(winner, groups, gs))


# Builds the ranked standings array for the M16 results screen. Winner gets
# rank 1; remaining groups are sorted by elimination round DESCENDING (a group
# that fell later survived longer, so it ranks higher than one that fell
# earlier). For a draw (winner == ""), no rank 1 is emitted — losers start at
# rank 1; the results screen renders "DRAW" in the top slot.
func _build_standings(winner: String, all_groups: Array[String], gs: Node) -> Array:
	var standings: Array = []
	var blue_group: String = gs.get_alliance_group("blue")
	if winner != "":
		standings.append({
			"group": winner,
			"eliminated_round": -1,
			"rank": 1,
			"is_blue_group": winner == blue_group,
		})
	# Snapshot losers with their elimination round.
	var losers: Array = []
	for g in all_groups:
		if g == winner:
			continue
		losers.append({
			"group": g,
			"eliminated_round": _group_eliminated_round.get(g, -1),
			"is_blue_group": g == blue_group,
		})
	# Sort losers by elimination round descending; ties keep insertion order
	# (sort_custom is stable in Godot 4).
	losers.sort_custom(func(a, b): return a["eliminated_round"] > b["eliminated_round"])
	var next_rank: int = 2 if winner != "" else 1
	for l in losers:
		l["rank"] = next_rank
		standings.append(l)
		next_rank += 1
	return standings


# Union of (groups with at least one registered faction) and (groups named in
# either authored condition dict). A condition authored against a group with
# no registered factions still evaluates — useful for an authored escape
# victory whose unit_ids belong to a group that's already been wiped from
# living units (the escape_records bookkeeping survives the wipe).
func _all_evaluated_groups(gs: Node) -> Array[String]:
	var seen: Dictionary = {}
	for fid in gs.get_registered_faction_ids():
		seen[gs.get_alliance_group(fid)] = true
	for g in _map_data.victory_conditions.keys():
		seen[g] = true
	for g in _map_data.defeat_conditions.keys():
		seen[g] = true
	var out: Array[String] = []
	for g in seen.keys():
		out.append(g)
	return out


func _group_has_authored_victory_conditions(group: String) -> bool:
	return not _conditions_for_group(_map_data.victory_conditions, group).is_empty()


# Reads MapData.{victory|defeat}_conditions[group] as an Array. Missing,
# explicitly empty, and non-Array values all mean "no authored conditions."
func _conditions_for_group(dict: Dictionary, group: String) -> Array:
	var raw: Variant = dict.get(group, null)
	if raw is Array:
		return raw
	return []


# Dispatcher. Returns true iff `cond` is satisfied right now for the
# conditioning group `for_group`. Covers the seven authored M16 types.
func _evaluate_condition(cond: ObjectiveCondition, for_group: String, gs: Node) -> bool:
	if cond == null:
		return false
	match cond.type:
		"rout":
			return _eval_rout(cond, for_group, gs)
		"turn_limit":
			# defeat when turn_number > turns; mirrors the legacy strict-greater check.
			return gs.turn_number > cond.turns
		"protect":
			# defeat-condition truth = ANY protected unit is dead/missing.
			return _eval_protect_failed(cond, gs)
		"defeat_boss":
			# defeat-condition truth = ANY named unit is dead. Same shape as
			# protect_failed but authored as a foe-eliminating victory ("boss
			# down → I win") on the conditioning group's victory_conditions.
			return _eval_all_named_dead(cond, gs)
		"seize":
			return _eval_seize(cond, for_group, gs)
		"escape":
			return _eval_escape(cond)
		"survive":
			return _eval_survive(cond, for_group, gs)
		_:
			push_warning("ObjectiveCondition: unimplemented type '%s' — treated as unmet" % cond.type)
			return false


# rout: a named faction id, or a named alliance group, has zero living units.
# Empty faction_id means "every faction hostile to the conditioning group" —
# the natural authoring shortcut for "blue wins when everyone else is dead",
# and the translation target for legacy `objective_type == "rout"`.
#
# An unknown faction_id (matches neither a registered faction nor an alliance
# group on this map) is treated as unmet and logged via push_warning so the
# typo surfaces in the editor output. DataManager validation (M16 follow-up)
# will promote this to a load-time push_error.
func _eval_rout(cond: ObjectiveCondition, for_group: String, gs: Node) -> bool:
	# Rout counts TRUE liveness via get_all_living_units_of: a paired support is an
	# undefeated unit even though it sits off-map, so it must keep a faction/group
	# "not routed". get_living_units_of excludes supports (for selection/turn-end)
	# and must NOT be used here — doing so let a Rout resolve while a hidden support
	# was still alive (playtest v0.1.4 #4).
	var faction_ids: Array[String] = gs.get_registered_faction_ids()
	if cond.faction_id != "":
		# Faction id first; fall back to "alliance-group name" interpretation.
		if cond.faction_id in faction_ids:
			return gs.get_all_living_units_of(cond.faction_id).is_empty()
		var matched := false
		for fid in faction_ids:
			if gs.get_alliance_group(fid) == cond.faction_id:
				matched = true
				if not gs.get_all_living_units_of(fid).is_empty():
					return false
		if not matched:
			push_warning("ObjectiveCondition rout: faction_id '%s' matches no faction or group" % cond.faction_id)
			return false
		return true
	# faction_id == "" → all hostiles to the conditioning group wiped.
	for fid in faction_ids:
		if gs.get_alliance_group(fid) == for_group:
			continue
		if not gs.get_all_living_units_of(fid).is_empty():
			return false
	return true


# protect-failed (= defeat truth value): TRUE iff ANY named unit is missing
# or has hp <= 0 AND has not escaped. May include green units, per the M16
# spec — so this scans every registered unit, not just blue (which is what
# the legacy required_survivor_ids check did under the old blue-only model).
#
# Escape exclusion: a unit that left the map via an escape zone is not "dead"
# (it survived the map by definition); the spec ties protect-failure to
# "death" specifically. Without this carve-out an escape victory would
# simultaneously trigger a protect defeat for the same unit.
func _eval_protect_failed(cond: ObjectiveCondition, gs: Node) -> bool:
	for required_id in cond.unit_ids:
		if _has_unit_escaped(required_id):
			continue
		if not _is_unit_id_alive(required_id, gs):
			return true
	return false


func _has_unit_escaped(unit_id: String) -> bool:
	for record in _escape_records:
		if record.get("unit_id", "") == unit_id:
			return true
	return false


# all-named-dead (defeat_boss truth value): TRUE iff EVERY unit_id in the
# condition is dead. Mirrors protect_failed inverted (any-vs-all + alive-vs-dead);
# kept as its own helper so the spec-level "boss is down" reads cleanly.
func _eval_all_named_dead(cond: ObjectiveCondition, gs: Node) -> bool:
	if cond.unit_ids.is_empty():
		return false
	for target_id in cond.unit_ids:
		if _is_unit_id_alive(target_id, gs):
			return false
	return true


# A unit_id resolves to a living registered unit (escapes are tracked separately).
func _is_unit_id_alive(unit_id: String, gs: Node) -> bool:
	for u in gs.all_units:
		if not is_instance_valid(u) or u.data == null:
			continue
		if u.data.unit_id == unit_id and u.data.hp > 0:
			return true
	return false


# seize: TRUE iff the configured tile has a seize record from a unit that
# belongs to the conditioning group and carries UnitData.can_seize.
# Decision 4 / 2026-05-17 — Seize is a deliberate ActionMenu entry; the cursor
# calls record_seize on confirm.
func _eval_seize(cond: ObjectiveCondition, for_group: String, gs: Node) -> bool:
	if cond.tile == Vector2i(-1, -1):
		return false
	for record in _seize_records:
		var rec_tile: Vector2i = record.get("tile", Vector2i.ZERO)
		if rec_tile != cond.tile:
			continue
		var unit_id: String = record.get("unit_id", "")
		var faction: String = record.get("faction", "")
		if gs.get_alliance_group(faction) != for_group:
			continue
		var unit: Node = gs.find_unit_by_id(unit_id)
		if _unit_can_seize(unit):
			return true
	return false


# escape: TRUE iff every unit_id in cond.unit_ids appears in _escape_records
# (the runtime escape log; player commits Escape from the ActionMenu and
# MapCursor calls record_escape, post-2026-05-20 review).
func _eval_escape(cond: ObjectiveCondition) -> bool:
	if cond.unit_ids.is_empty():
		return false
	for required_id in cond.unit_ids:
		if not _has_unit_escaped(required_id):
			return false
	return true


# survive: TRUE once turn_number > cond.turns AND (if cond.tiles is authored)
# at least one conditioning-group unit currently stands on a `tiles` tile.
# The optional tile clause keeps the eval simple — a strict "held for N
# consecutive rounds" requires per-round bookkeeping; map authors can model
# that with stage 5's hybrid triggers if needed.
func _eval_survive(cond: ObjectiveCondition, for_group: String, gs: Node) -> bool:
	if gs.turn_number <= cond.turns:
		return false
	if cond.tiles.is_empty():
		return true
	for fid in gs.get_registered_faction_ids():
		if gs.get_alliance_group(fid) != for_group:
			continue
		for u in gs.get_living_units_of(fid):
			if u.tile_position in cond.tiles:
				return true
	return false


# Returns the turn_number when `group` was first marked eliminated, or -1 if
# the group is still in play. Drives the ranked-standings results screen in
# M16 stage 4.
func get_group_eliminated_round(group: String) -> int:
	return _group_eliminated_round.get(group, -1)


# ── M16 stage 3: seize / escape public APIs ──────────────────────────────────

# Called by MapCursor when the player commits the Seize ActionMenu entry on
# `unit`'s current tile. Records the {tile, unit_id, faction} triple so the
# next victory sweep can resolve seize conditions, then runs the sweep
# immediately (Decision 7's event-driven path — wins shouldn't have to wait
# for the next phase boundary).
func record_seize(unit: Node) -> void:
	if unit == null or unit.data == null:
		return
	_seize_records.append({
		"tile": unit.tile_position,
		"unit_id": unit.data.unit_id,
		"faction": unit.team,
	})
	check_victory_conditions()


# True iff at least one authored seize condition (anywhere in the map's
# victory or defeat condition sets) would accept `unit` performing a Seize on
# `tile`. The ActionMenu reads this to decide whether to show the Seize
# button (Decision 4: a deliberate, gated entry — not a passive occupation).
func can_seize(unit: Node, tile: Vector2i) -> bool:
	if _map_data == null or unit == null or unit.data == null:
		return false
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var unit_group: String = gs.get_alliance_group(unit.team)
	for dict in [_map_data.victory_conditions, _map_data.defeat_conditions]:
		for group_id in dict.keys():
			for cond in _conditions_for_group(dict, group_id):
				if cond == null or cond.type != "seize":
					continue
				if cond.tile != tile:
					continue
				if group_id == unit_group and _unit_can_seize(unit):
					return true
	return false


func _unit_can_seize(unit: Node) -> bool:
	if unit == null or unit.data == null:
		return false
	return bool(unit.data.get("can_seize"))


# Removes a unit from the map under the "escape" semantics: tracks its
# unit_id in _escaped_unit_ids, unregisters from GameState, and queue_frees
# the node. Unlike unit_died this does NOT emit map_defeat-by-protect — the
# unit survived; it just isn't on the map any more.
func record_escape(unit: Node) -> void:
	if unit == null or unit.data == null:
		return
	var escaping_units: Array[Node] = _collect_escape_units(unit)
	for escaping_unit in escaping_units:
		if escaping_unit == null or escaping_unit.data == null:
			continue
		if not _has_unit_escaped(escaping_unit.data.unit_id):
			_escape_records.append({
				"unit_id": escaping_unit.data.unit_id,
				"faction": escaping_unit.team,
			})
	# Order: log the escape (above) → unregister from GameState → drop the
	# per-unit bookkeeping (state + original tile) → free the node → re-evaluate.
	# Reordering risks evaluator passes seeing a half-escaped unit (e.g.
	# unregistered but still in _unit_states), so keep the steps in this order.
	var gs := get_node_or_null("/root/GameState")
	var registry := get_node_or_null("/root/PairUpRegistry")
	if registry != null and unit.data.unit_id != "" and registry.call("is_paired", unit.data.unit_id):
		registry.call("separate", unit.data.unit_id)
	for escaping_unit in escaping_units:
		if escaping_unit == null:
			continue
		if gs and escaping_unit in gs.all_units:
			gs.unregister_unit(escaping_unit)
		_unit_states.erase(escaping_unit)
		_original_tiles.erase(escaping_unit)
		if is_instance_valid(escaping_unit):
			escaping_unit.queue_free()
	check_victory_conditions()


func _collect_escape_units(unit: Node) -> Array[Node]:
	var escaping_units: Array[Node] = [unit]
	if unit == null or unit.data == null or unit.data.unit_id == "":
		return escaping_units
	var registry := get_node_or_null("/root/PairUpRegistry")
	if registry == null or not registry.call("is_lead", unit.data.unit_id):
		return escaping_units
	var gs := get_node_or_null("/root/GameState")
	if gs == null or not gs.has_method("find_unit_by_id"):
		return escaping_units
	var support_id: String = registry.call("get_partner_id", unit.data.unit_id)
	if support_id == "":
		return escaping_units
	var support: Node = gs.find_unit_by_id(support_id)
	if support != null and support != unit:
		escaping_units.append(support)
	return escaping_units


# True iff at least one authored escape condition (anywhere in the map's
# victory or defeat condition sets) names `unit` AND has `tile` inside its
# escape zone. The ActionMenu reads this to decide whether to show the Escape
# button — same shape as can_seize, post-2026-05-20-review (replaces the old
# unit_moved auto-escape hook that fired during the move await and left the
# cursor with a stale selected_unit).
func can_escape(unit: Node, tile: Vector2i) -> bool:
	if _map_data == null or unit == null or unit.data == null:
		return false
	for dict in [_map_data.victory_conditions, _map_data.defeat_conditions]:
		for group_id in dict.keys():
			for cond in _conditions_for_group(dict, group_id):
				if cond == null or cond.type != "escape":
					continue
				if cond.unit_ids.is_empty():
					continue
				if not (unit.data.unit_id in cond.unit_ids):
					continue
				if tile in cond.tiles:
					return true
	return false


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
	# remaining locally-human-controlled unit already DONE — set_unit_state
	# never ran for the dead unit, so auto-end it here too (#5 / M15 Part A).
	# _auto_end_active_phase bails if the map just ended via the
	# check_victory_conditions call above.
	var active_faction_id: String = _active_or_default_faction()
	if _should_auto_end_faction(active_faction_id) and are_all_units_done(active_faction_id):
		call_deferred("_auto_end_active_phase")


func _active_or_default_faction() -> String:
	var faction_id: String = active_faction()
	if faction_id != "":
		return faction_id
	var gs := get_node_or_null("/root/GameState")
	if gs != null and gs.is_player_turn():
		return "blue"
	return ""


func is_locally_controlled_faction(faction_id: String) -> bool:
	if faction_id == "":
		return false
	if faction_id == "blue":
		var gs := get_node_or_null("/root/GameState")
		return gs != null and gs.is_player_turn()
	return _is_hotseat_controlled(faction_id)


func _should_auto_end_faction(faction_id: String) -> bool:
	return is_locally_controlled_faction(faction_id)
