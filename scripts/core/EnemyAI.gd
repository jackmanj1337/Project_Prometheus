extends Node
# Basic faction AI: move toward nearest hostile unit, attack if in range.
# Called by TurnManager.start_enemy_phase(); awaited until one AI faction has acted.

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
		if turn._map_over:
			return
		if is_instance_valid(enemy):
			# Pan the camera to the enemy and pause briefly so the player can
			# follow the enemy phase (#7), then let it act.
			await _focus_camera(enemy)
			await _act(enemy, grid, turn, faction_id)


# Legacy aliases kept so older callers can still invoke the pre-M15 names while
# the shared controller contract settles on `run_phase()`.
func run_ai_phase(grid: GridManager, turn: TurnManager, faction_id: String) -> void:
	await run_phase(grid, turn, faction_id)


# Uses TurnManager.active_faction() when available.
func run_enemy_phase(grid: GridManager, turn: TurnManager) -> void:
	var faction_id: String = "red"
	if turn != null and turn.has_method("active_faction"):
		var active: String = turn.active_faction()
		if active != "":
			faction_id = active
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
	match (sm.movement_speed if sm != null else "normal"):
		"instant": delay = 0.0
		"fast":    delay = 0.12
	if delay > 0.0 and is_inside_tree():
		await get_tree().create_timer(delay).timeout


# One enemy's turn: dispatch on ai_profile, then mark DONE.
func _act(enemy: Node, grid: GridManager, turn: TurnManager, acting_faction: String = "red") -> void:
	if enemy.data == null:
		return
	match enemy.data.ai_profile:
		"passive": await _act_passive(enemy, grid, turn, acting_faction); return
		"healer":  await _act_healer(enemy, grid, turn, acting_faction);  return
		_: pass  # "basic" falls through to standard logic

	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var hostiles: Array[Node] = _living_hostiles_for_faction(gs, acting_faction)
	if hostiles.is_empty():
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)
		return

	var nearest: Node = _find_nearest(enemy, hostiles, grid)
	var move_tiles: Array[Vector2i] = grid.get_movement_range(enemy)
	var best_tile: Vector2i = _choose_move_tile(enemy, nearest, hostiles, move_tiles, grid)

	if best_tile != enemy.tile_position:
		var path := grid.get_movement_path(enemy, best_tile)
		if path.size() > 1:
			turn.record_move_start(enemy)
			await enemy.move_along_path(path)
			# Re-centre the camera on the destination so combat resolves on-screen
			# even when the enemy moved far from where it started (#7).
			if is_instance_valid(enemy):
				_pan_camera(enemy)

	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.MOVED)

	# Attack the nearest targetable player from the new position; fall back to staff heal.
	if is_instance_valid(enemy):
		var targets: Array[Node] = grid.get_attackable_enemies_from_tile(
			enemy, enemy.tile_position)
		if not targets.is_empty():
			var target: Node = _find_nearest(enemy, targets)
			var cr := get_node_or_null("/root/CombatResolver")
			if cr and is_instance_valid(target):
				var result: Dictionary = cr.resolve_combat(enemy, target)
				cr.apply_combat_result(result, enemy, target)
		else:
			_try_staff_heal(enemy, grid)

	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)


# Passive: hold position; only attack if a player is already in attack range.
func _act_passive(enemy: Node, grid: GridManager, turn: TurnManager, _acting_faction: String = "red") -> void:
	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.MOVED)
	if is_instance_valid(enemy):
		var targets: Array[Node] = grid.get_attackable_enemies_from_tile(
			enemy, enemy.tile_position)
		if not targets.is_empty():
			var target: Node = _find_nearest(enemy, targets)
			var cr := get_node_or_null("/root/CombatResolver")
			if cr and is_instance_valid(target):
				var result: Dictionary = cr.resolve_combat(enemy, target)
				cr.apply_combat_result(result, enemy, target)
	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)


# Healer: move toward injured allies, heal the most-injured one in range.
func _act_healer(enemy: Node, grid: GridManager, turn: TurnManager,
		acting_faction: String = "red") -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)
		return
	var move_tiles: Array[Vector2i] = grid.get_movement_range(enemy)
	var best_tile: Vector2i = _choose_heal_move_tile(enemy, move_tiles, grid, gs, acting_faction)
	if best_tile != enemy.tile_position:
		var path := grid.get_movement_path(enemy, best_tile)
		if path.size() > 1:
			turn.record_move_start(enemy)
			await enemy.move_along_path(path)
			# Re-centre on the destination so the heal resolves on-screen (#7).
			if is_instance_valid(enemy):
				_pan_camera(enemy)
	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.MOVED)
	if is_instance_valid(enemy):
		_try_staff_heal(enemy, grid)
	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)


# Pick the move tile that places the most-injured ally in staff range.
# Tie-break: prefer tiles with higher terrain DEF+Dodge bonus (safer positioning).
func _choose_heal_move_tile(enemy: Node, move_tiles: Array[Vector2i],
		grid: GridManager, gs: Node, acting_faction: String = "red") -> Vector2i:
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
			var terrain_bonus: int = GridManager.TERRAIN_DEF_BONUS.get(terrain, 0) \
				+ GridManager.TERRAIN_DODGE_BONUS.get(terrain, 0)
			var injury_pct: float = float(ally.data.max_hp - ally.data.hp) / float(ally.data.max_hp)
			if injury_pct > best_injury_pct or \
					(injury_pct == best_injury_pct and terrain_bonus > best_terrain_bonus):
				best_injury_pct = injury_pct
				best_terrain_bonus = terrain_bonus
				best_tile = tile
	return best_tile


# Among move_tiles, pick the tile from which the enemy can attack a player.
# Prefer tiles adjacent to the nearest player; fall back to simply closing distance.
func _choose_move_tile(enemy: Node, nearest: Node, all_players: Array[Node],
		move_tiles: Array[Vector2i], grid: GridManager) -> Vector2i:
	var best_attack_tile: Vector2i = enemy.tile_position
	var best_attack_dist: int = GameConstants.INT_MAX
	for tile in move_tiles:
		for player in all_players:
			if not is_instance_valid(player):
				continue
			if grid.can_attack_from_tile(enemy, tile, player):
				var d: int = absi(tile.x - nearest.tile_position.x) \
					+ absi(tile.y - nearest.tile_position.y)
				if d < best_attack_dist:
					best_attack_dist = d
					best_attack_tile = tile
	if best_attack_dist < GameConstants.INT_MAX:
		return best_attack_tile

	# No attack possible — move as close to nearest player as possible
	var best_move: Vector2i = enemy.tile_position
	var best_dist: int = GameConstants.INT_MAX
	for tile in move_tiles:
		var d: int = absi(tile.x - nearest.tile_position.x) \
			+ absi(tile.y - nearest.tile_position.y)
		if d < best_dist:
			best_dist = d
			best_move = tile
	return best_move


# Heals the most-injured ally in range if the enemy carries a staff.
func _try_staff_heal(enemy: Node, grid: GridManager) -> void:
	if not enemy.has_method("get_equipped_weapon"):
		return
	var weapon: WeaponData = enemy.get_equipped_weapon()
	if weapon == null or not weapon.is_healing_staff():
		return
	var heal_targets: Array[Node] = grid.get_healable_allies(enemy)
	if heal_targets.is_empty():
		return
	# Pick most injured ally (lowest current HP)
	var target: Node = heal_targets[0]
	for t in heal_targets:
		if is_instance_valid(t) and t.data.hp < target.data.hp:
			target = t
	if not is_instance_valid(target):
		return
	enemy.perform_staff_heal(target, weapon)


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
		var d: int = absi(u.tile_position.x - from_unit.tile_position.x) \
			+ absi(u.tile_position.y - from_unit.tile_position.y)
		if d < min_dist:
			min_dist = d
			nearest = u
	return nearest


# Returns every living unit hostile to `acting_faction`, based on the
# alliance-group model (M14 stage 2/3).
func _living_hostiles_for_faction(gs: Node, acting_faction: String) -> Array[Node]:
	var out: Array[Node] = []
	for fid in gs.get_registered_faction_ids():
		if not gs.are_hostile(acting_faction, fid):
			continue
		out.append_array(gs.get_living_units_of(fid))
	return out


# NOTE: the former _flood_costs helper was folded into GridManager.dijkstra_costs —
# _find_nearest now calls grid.dijkstra_costs(start, INT_MAX, true, null) directly.
