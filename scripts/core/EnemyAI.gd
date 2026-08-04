extends Node
# Basic faction AI: move toward nearest hostile unit, attack if in range.
# Called by TurnManager.start_enemy_phase(); awaited until one AI faction has acted.

# Used to recognise (and skip) paired supports parked off the grid. See the guard
# in _living_hostiles_for_faction.
const _PairUpRegistryScript = preload("res://scripts/autoloads/PairUpRegistry.gd")
# Composition-engine seam: profile id -> AISpec (activation/disposition/engagement).
# Replaces the closed `match enemy.data.ai_profile` below (invariant 1). See
# AGENT/Docs/design/ai_first_build_design_2026-06-22.md §2.
const AIProfileRegistry = preload("res://scripts/core/AIProfileRegistry.gd")


# Runs one faction's living units sequentially.
# Bails early when the map has already ended (M16 Decision 7 / 2026-05-17 — the
# _map_over latch halts the cycle at the controller chokepoint, so a decided
# map does not keep playing out remaining enemy turns).
func run_phase(grid: GridManager, turn: TurnManager, faction_id: String) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null or grid == null:
		return
	var actors: Array[Node] = gs.get_living_units_of(faction_id)
	for enemy in actors:
		if turn._map_over or _debug_hotseat_override_active(turn):
			return
		if not is_instance_valid(enemy):
			continue
		# V021-01: skip a unit that already finished an activation. On an F9
		# control toggle the enemy phase is re-run for the same faction
		# (TurnManager.start_enemy_phase rewinds its guard and loops); without
		# this guard the AI would re-move every unit that already acted.
		if not turn.can_unit_act(enemy):
			continue
		# Pan the camera to the enemy and pause briefly so the player can
		# follow the enemy phase (#7), then let it act.
		await _focus_camera(enemy)
		if _debug_hotseat_override_active(turn):
			return
		# V021-01: snapshot the activation-start tile so a mid-activation F9
		# handoff can roll the unit back to where it began instead of leaving it
		# teleported-but-still-READY (the "moved without spending its turn" bug).
		turn.record_move_start(enemy)
		await _act(enemy, grid, turn, faction_id)
		# If F9 flipped while this unit was acting, _act bailed before finalizing
		# it (state still READY/MOVED). Roll it back to its activation-start tile
		# and READY so the new controller — or a later AI re-run — inherits a
		# clean, unspent unit. A unit that completed its turn stays DONE. (V021-01)
		if (
			is_instance_valid(enemy)
			and _debug_hotseat_override_active(turn)
			and turn.can_unit_act(enemy)
		):
			turn.undo_move(enemy)
			return
		# This is the only suspend point inside AI control: the action, death and
		# reward queues have unwound, and TurnManager synchronously seals the
		# activation ledger before asking the cursor to write the slot.
		if turn.complete_ai_activation_boundary():
			return


# Legacy aliases kept so older callers can still invoke the pre-M15 names while
# the shared controller contract settles on `run_phase()`.
func run_ai_phase(grid: GridManager, turn: TurnManager, faction_id: String) -> void:
	await run_phase(grid, turn, faction_id)


# Pans the camera onto `unit` (#7) by announcing it on EventBus.ai_unit_acting.
# No delay — used for the mid-turn re-pan after a unit moves.
func _pan_camera(unit: Node) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.ai_unit_acting.emit(unit)


# Pans the camera onto `unit` and pauses briefly so the move/attack is visible
# (#7). The pause scales with the movement_speed setting — instant players get
# no pause, fast players a short one — matching the cursor-movement feel.
func _focus_camera(unit: Node) -> void:
	_pan_camera(unit)
	var sm := get_node_or_null("/root/SettingsManager")
	var delay: float = 0.25
	match sm.movement_speed if sm != null else "normal":
		"instant":
			delay = 0.0
		"fast":
			delay = 0.12
	if delay > 0.0 and is_inside_tree():
		await get_tree().create_timer(delay).timeout


# One enemy's turn: resolve the unit's AISpec and dispatch to its disposition
# handler, then the handler marks the unit DONE. The disposition table is the
# composition-engine seam that replaced `match enemy.data.ai_profile` (invariant
# 1: no behavior hardcoded in a match) — adding a behavior is one registry id +
# one handler entry, never an engine `match` edit. The handlers still plan and
# execute inline; extracting a pure `plan_action` (the deferred action-preview
# dry-run + [VAL] prerequisite) rides build-slice step 3 with the new dispositions.
func _act(
	enemy: Node, grid: GridManager, turn: TurnManager, acting_faction: String = "red"
) -> void:
	if enemy.data == null:
		return
	if _debug_hotseat_override_active(turn):
		return
	var spec: RefCounted = AIProfileRegistry.resolve_ai_spec(enemy.data.ai_profile)
	var handler: Callable = _disposition_handlers().get(spec.disposition, Callable())
	if not handler.is_valid():
		# Unknown disposition is unreachable (boot validation rejects unknown
		# profiles); mirror the old `_: pass` by falling back to pursue_unit.
		handler = _disposition_pursue_unit
	# The resolved spec threads through so each handler's target-selection step can
	# honour the engagement policy (nearest vs weakest) instead of assuming nearest.
	await handler.call(enemy, grid, turn, acting_faction, spec)


# Disposition id -> handler Callable — the single seam a new AI behavior
# registers on. Rebuilt per call (cheap; a few entries) so the Callables always
# bind the live `self`.
func _disposition_handlers() -> Dictionary:
	return {
		AIProfileRegistry.DISP_PURSUE_UNIT: _disposition_pursue_unit,
		AIProfileRegistry.DISP_HOLD_TILE: _disposition_hold_tile,
		AIProfileRegistry.DISP_HEAL: _disposition_heal,
	}


# pursue_unit disposition (the former inline `basic` path): advance toward the
# nearest hostile, attack from the best reachable tile, staff-heal fallback, else
# commit a Wait. Behavior + RNG chain unchanged from the pre-registry dispatch.
func _disposition_pursue_unit(
	enemy: Node,
	grid: GridManager,
	turn: TurnManager,
	acting_faction: String = "red",
	spec: RefCounted = null
) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var hostiles: Array[Node] = _living_hostiles_for_faction(gs, acting_faction)
	if hostiles.is_empty():
		# Nothing to fight: this action is a committed Wait and must advance the
		# RNG chain like a player Wait would (RNG-1: AI chains identically).
		turn.commit_action_event("wait", turn.make_move_record(enemy))
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)
		return

	# Pick the unit to advance toward per the engagement policy (nearest / weakest);
	# `weakest` threads into the move-tile pick too (design §9).
	var pursue_target: Node = _select_target(enemy, hostiles, _engagement_of(spec), grid)
	var move_tiles: Array[Vector2i] = grid.get_movement_range(enemy)
	var best_tile: Vector2i = _choose_move_tile(enemy, pursue_target, hostiles, move_tiles, grid)

	if best_tile != enemy.tile_position:
		var path := grid.get_movement_path(enemy, best_tile)
		if path.size() > 1:
			turn.record_move_start(enemy)
			# [PCM-3] parity: the AI consumes the SAME resolved outcome a player's
			# animated move produces — the resolver runs inside move_along_path, so
			# there is no second code path here to drift.
			var outcome: CrossingOutcome = await enemy.move_along_path(path)
			if _debug_hotseat_override_active(turn):
				return
			if outcome != null and outcome.movement_permanent:
				turn.mark_move_permanent(enemy)
			if outcome != null and outcome.ends_activation and is_instance_valid(enemy):
				# [PCM-6]: the trigger ended the activation. This unit did neither
				# attack nor heal, so it commits a Wait — exactly one RNG event per
				# completed action (RNG-1), the same as any other actionless AI turn.
				turn.commit_action_event("wait", turn.make_move_record(enemy))
				turn.set_unit_state(enemy, TurnManager.UnitState.DONE)
				return
			# Re-centre the camera on the destination so combat resolves on-screen
			# even when the enemy moved far from where it started (#7).
			if is_instance_valid(enemy):
				_pan_camera(enemy)

	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.MOVED)

	# Attack the nearest targetable player from the new position; fall back to
	# staff heal. Exactly one RNG event commits per completed action: attack
	# commits in apply_combat_result, staff inside _try_staff_heal, and a unit
	# that did neither commits a Wait (RNG-1: AI chains identically to blue).
	if _debug_hotseat_override_active(turn):
		return
	var acted := false
	if is_instance_valid(enemy):
		var targets: Array[Node] = grid.get_attackable_enemies_from_tile(enemy, enemy.tile_position)
		if not targets.is_empty():
			var target: Node = _select_target(enemy, targets, _engagement_of(spec))
			var cr := get_node_or_null("/root/CombatResolver")
			if cr and is_instance_valid(target):
				# AI attacks chain identically to blue's (RNG-1): same canonical
				# event record, pre-move tile from the record_move_start above.
				var record: Array[String] = cr.make_attack_event_record(
					enemy, target, turn.get_action_start_tile(enemy)
				)
				var result: Dictionary = cr.resolve_combat(enemy, target, record)
				cr.apply_combat_result(result, enemy, target)
				acted = true
		else:
			acted = _try_staff_heal(enemy, grid, turn)

	if is_instance_valid(enemy):
		if not acted:
			turn.commit_action_event("wait", turn.make_move_record(enemy))
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)


# hold_tile disposition (the former `passive` path): hold position; only attack
# if a player is already in attack range. Behavior + RNG chain unchanged.
func _disposition_hold_tile(
	enemy: Node,
	grid: GridManager,
	turn: TurnManager,
	_acting_faction: String = "red",
	spec: RefCounted = null
) -> void:
	if _debug_hotseat_override_active(turn):
		return
	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.MOVED)
	if _debug_hotseat_override_active(turn):
		return
	var attacked := false
	if is_instance_valid(enemy):
		var targets: Array[Node] = grid.get_attackable_enemies_from_tile(enemy, enemy.tile_position)
		if not targets.is_empty():
			var target: Node = _select_target(enemy, targets, _engagement_of(spec))
			var cr := get_node_or_null("/root/CombatResolver")
			if cr and is_instance_valid(target):
				# Passive units attack in place — from_tile == live tile.
				var record: Array[String] = cr.make_attack_event_record(
					enemy, target, turn.get_action_start_tile(enemy)
				)
				var result: Dictionary = cr.resolve_combat(enemy, target, record)
				cr.apply_combat_result(result, enemy, target)
				attacked = true
	if is_instance_valid(enemy):
		# A passive unit with nothing in range committed a Wait (RNG-1).
		if not attacked:
			turn.commit_action_event("wait", turn.make_move_record(enemy))
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)


# heal disposition (the former `healer` path): move toward injured allies, heal
# the most-injured one in range. Behavior + RNG chain unchanged.
func _disposition_heal(
	enemy: Node,
	grid: GridManager,
	turn: TurnManager,
	acting_faction: String = "red",
	_spec: RefCounted = null
) -> void:
	# Engagement policy does not apply to healing — the heal target is the most-
	# injured ally, not a hostile — so `_spec` is accepted only for a uniform
	# handler signature (the dispatch calls every handler the same way).
	if _debug_hotseat_override_active(turn):
		return
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		turn.commit_action_event("wait", turn.make_move_record(enemy))
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)
		return
	var move_tiles: Array[Vector2i] = grid.get_movement_range(enemy)
	var best_tile: Vector2i = _choose_heal_move_tile(enemy, move_tiles, grid, gs, acting_faction)
	if best_tile != enemy.tile_position:
		var path := grid.get_movement_path(enemy, best_tile)
		if path.size() > 1:
			turn.record_move_start(enemy)
			# [PCM-3] parity: the AI consumes the SAME resolved outcome a player's
			# animated move produces — the resolver runs inside move_along_path, so
			# there is no second code path here to drift.
			var outcome: CrossingOutcome = await enemy.move_along_path(path)
			if _debug_hotseat_override_active(turn):
				return
			if outcome != null and outcome.movement_permanent:
				turn.mark_move_permanent(enemy)
			if outcome != null and outcome.ends_activation and is_instance_valid(enemy):
				# [PCM-6]: the trigger ended the activation. This unit did neither
				# attack nor heal, so it commits a Wait — exactly one RNG event per
				# completed action (RNG-1), the same as any other actionless AI turn.
				turn.commit_action_event("wait", turn.make_move_record(enemy))
				turn.set_unit_state(enemy, TurnManager.UnitState.DONE)
				return
			# Re-centre on the destination so the heal resolves on-screen (#7).
			if is_instance_valid(enemy):
				_pan_camera(enemy)
	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.MOVED)
	if _debug_hotseat_override_active(turn):
		return
	var healed := false
	if is_instance_valid(enemy):
		healed = _try_staff_heal(enemy, grid, turn)
	if is_instance_valid(enemy):
		# A healer with no valid heal committed a Wait (RNG-1); the heal itself
		# commits a "staff" event inside _try_staff_heal.
		if not healed:
			turn.commit_action_event("wait", turn.make_move_record(enemy))
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)


func _debug_hotseat_override_active(turn: TurnManager) -> bool:
	return (
		turn != null
		and turn.has_method("is_debug_hotseat_override_active")
		and turn.is_debug_hotseat_override_active()
	)


# Pick the move tile that places the most-injured ally in staff range.
# Tie-break: prefer tiles with higher terrain DEF+Dodge bonus (safer positioning).
func _choose_heal_move_tile(
	enemy: Node,
	move_tiles: Array[Vector2i],
	grid: GridManager,
	gs: Node,
	acting_faction: String = "red"
) -> Vector2i:
	var best_tile: Vector2i = enemy.tile_position
	var best_injury_pct: float = -1.0  # higher = more injured = higher priority
	var best_terrain_bonus: int = -1
	var allies: Array[Node] = gs.get_living_units_of(acting_faction)
	for tile in move_tiles:
		for ally in allies:
			if not is_instance_valid(ally) or ally == enemy:
				continue
			if ally.data == null or ally.data.hp >= ally.data.max_hp:
				continue
			# Staff reach, not attack reach — can_attack_from_tile rejects staves.
			if not grid.in_weapon_range_from_tile(enemy, tile, ally):
				continue
			var terrain: String = grid.get_terrain_at(tile)
			var bonuses: Dictionary = grid.terrain_bonuses_for(terrain)
			var terrain_bonus: int = int(bonuses["def"]) + int(bonuses["dodge"])
			var injury_pct: float = float(ally.data.max_hp - ally.data.hp) / float(ally.data.max_hp)
			if (
				injury_pct > best_injury_pct
				or (injury_pct == best_injury_pct and terrain_bonus > best_terrain_bonus)
			):
				best_injury_pct = injury_pct
				best_terrain_bonus = terrain_bonus
				best_tile = tile
	return best_tile


# Among move_tiles, pick the tile from which the enemy can attack a player.
# Prefer tiles adjacent to the nearest player; fall back to simply closing distance.
func _choose_move_tile(
	enemy: Node,
	approach_target: Node,
	all_players: Array[Node],
	move_tiles: Array[Vector2i],
	grid: GridManager
) -> Vector2i:
	# `approach_target` is the engagement-selected unit to close on (nearest or, for
	# focus-fire profiles, the weakest); the pick threads through to the move tile.
	var best_attack_tile: Vector2i = enemy.tile_position
	var best_attack_dist: int = GameConstants.INT_MAX
	for tile in move_tiles:
		for player in all_players:
			if not is_instance_valid(player):
				continue
			if grid.can_attack_from_tile(enemy, tile, player):
				var d: int = (
					absi(tile.x - approach_target.tile_position.x)
					+ absi(tile.y - approach_target.tile_position.y)
				)
				if d < best_attack_dist:
					best_attack_dist = d
					best_attack_tile = tile
	if best_attack_dist < GameConstants.INT_MAX:
		return best_attack_tile

	# No attack possible — move as close to the approach target as possible
	var best_move: Vector2i = enemy.tile_position
	var best_dist: int = GameConstants.INT_MAX
	for tile in move_tiles:
		var d: int = (
			absi(tile.x - approach_target.tile_position.x)
			+ absi(tile.y - approach_target.tile_position.y)
		)
		if d < best_dist:
			best_dist = d
			best_move = tile
	return best_move


# Heals the most-injured ally in range if the enemy carries a staff.
# Returns true when a heal actually happened (the caller commits a Wait RNG
# event otherwise, so every completed AI action advances the chain exactly once).
func _try_staff_heal(enemy: Node, grid: GridManager, turn: TurnManager = null) -> bool:
	if not enemy.has_method("get_equipped_weapon"):
		return false
	var weapon: WeaponData = enemy.get_equipped_weapon()
	if weapon == null or not weapon.is_healing_staff():
		return false
	var heal_targets: Array[Node] = grid.get_healable_allies(enemy)
	if heal_targets.is_empty():
		return false
	# Pick most injured ally (lowest current HP)
	var target: Node = heal_targets[0]
	for t in heal_targets:
		if is_instance_valid(t) and t.data.hp < target.data.hp:
			target = t
	if not is_instance_valid(target):
		return false
	# Commit the staff RNG event BEFORE the heal, mirroring the player path
	# (§3 record; heal EXP level-ups must chain on the post-staff hash, §4).
	if turn != null:
		(
			turn
			. commit_action_event(
				"staff",
				(
					[
						turn.unit_event_id(enemy),
						TurnManager.tile_field(turn.get_action_start_tile(enemy)),
						TurnManager.tile_field(enemy.tile_position),
						turn.unit_event_id(target),
					]
					as Array[String]
				)
			)
		)
	enemy.perform_staff_heal(target, weapon)
	return true


# Engagement-policy dispatch: which hostile a targeting disposition goes after.
# "nearest" preserves the pre-registry behavior byte-for-byte (so existing profiles'
# RNG chain is unchanged); "weakest" focus-fires the lowest-HP hostile. Any other
# value (incl. a null spec on the fallback path) is treated as nearest.
func _select_target(
	from_unit: Node, units: Array[Node], engagement: String, grid: GridManager = null
) -> Node:
	if engagement == AIProfileRegistry.ENG_WEAKEST:
		return _find_weakest(from_unit, units, grid)
	return _find_nearest(from_unit, units, grid)


# Null-safe read of the engagement axis; defaults to nearest when the spec is
# absent (the unreachable-disposition fallback, or a direct handler call in a test).
func _engagement_of(spec: RefCounted) -> String:
	if spec == null:
		return AIProfileRegistry.ENG_NEAREST
	return spec.engagement


# Returns the unit from `units` with the lowest current HP (focus-fire). Ties break
# toward the nearer unit — path cost when `grid` is supplied, else Manhattan — then
# by array order (first wins), so the pick is fully deterministic given a
# deterministic candidate list. No RNG is drawn here; combat draws happen later.
func _find_weakest(from_unit: Node, units: Array[Node], grid: GridManager = null) -> Node:
	var costs: Dictionary = {}
	if grid != null:
		costs = grid.dijkstra_costs(from_unit.tile_position, GameConstants.INT_MAX, true, null)
	var best: Node = null
	var best_hp: int = GameConstants.INT_MAX
	var best_dist: int = GameConstants.INT_MAX
	for u in units:
		if not is_instance_valid(u) or u.data == null:
			continue
		var hp: int = u.data.hp
		var dist: int
		if grid != null:
			dist = costs.get(u.tile_position, GameConstants.INT_MAX)
		else:
			dist = (
				absi(u.tile_position.x - from_unit.tile_position.x)
				+ absi(u.tile_position.y - from_unit.tile_position.y)
			)
		# Strictly-less on the (hp, dist) pair — first-in-array wins a full tie,
		# mirroring _find_nearest's tie discipline.
		if hp < best_hp or (hp == best_hp and dist < best_dist):
			best_hp = hp
			best_dist = dist
			best = u
	return best


# Returns the unit from `units` with the lowest real pathfinding cost from `from_unit`.
# Uses a Dijkstra flood from from_unit's tile — same algorithm as GridManager but we
# only need the cost map, not the reachable set. Falls back to Manhattan distance if
# grid is null (tests / edge cases).
func _find_nearest(from_unit: Node, units: Array[Node], grid: GridManager = null) -> Node:
	if grid == null:
		return _find_nearest_manhattan(from_unit, units)
	# Build a whole-map cost flood from the enemy's position (INT_MAX cap) so we can
	# reach any tile, not just the actual movement range. ignore_occupants=true: this
	# only estimates path distance — the real move calc respects occupants.
	var costs := grid.dijkstra_costs(from_unit.tile_position, GameConstants.INT_MAX, true, null)
	var nearest: Node = null
	var min_cost: int = GameConstants.INT_MAX
	for u in units:
		if not is_instance_valid(u):
			continue
		var c: int = costs.get(u.tile_position, GameConstants.INT_MAX)
		if c < min_cost:
			min_cost = c
			nearest = u
	# If all targets are at INT_MAX cost (fully walled off map), fall back to Manhattan.
	# Manhattan ignores actual terrain and may pick a different unit than Dijkstra would
	# through open terrain — this is a last-resort heuristic, not a correct pathfinding result.
	return nearest if nearest != null else _find_nearest_manhattan(from_unit, units)


func _find_nearest_manhattan(from_unit: Node, units: Array[Node]) -> Node:
	var nearest: Node = null
	var min_dist: int = GameConstants.INT_MAX
	for u in units:
		if not is_instance_valid(u):
			continue
		var d: int = (
			absi(u.tile_position.x - from_unit.tile_position.x)
			+ absi(u.tile_position.y - from_unit.tile_position.y)
		)
		if d < min_dist:
			min_dist = d
			nearest = u
	return nearest


# Returns every living unit hostile to `acting_faction`, based on the
# alliance-group model (M14 stage 2/3).
#
# Off-map guard (playtest v0.1.4 #4): any unit parked at OFF_MAP_TILE is excluded
# regardless of Pair Up role. get_living_units_of already drops registry-tagged
# supports, but this is a position-based backstop — a role desync (e.g. a future
# Swap/Separate bug) must never make the AI target or path toward the (-1, -1)
# sentinel, which clamps to the top-left corner and makes enemies beeline to (1,1).
func _living_hostiles_for_faction(gs: Node, acting_faction: String) -> Array[Node]:
	var out: Array[Node] = []
	for fid in gs.get_registered_faction_ids():
		if not gs.are_hostile(acting_faction, fid):
			continue
		for u in gs.get_living_units_of(fid):
			if is_instance_valid(u) and u.tile_position != _PairUpRegistryScript.OFF_MAP_TILE:
				out.append(u)
	return out

# NOTE: the former _flood_costs helper was folded into GridManager.dijkstra_costs —
# _find_nearest now calls grid.dijkstra_costs(start, INT_MAX, true, null) directly.
