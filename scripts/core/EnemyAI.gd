extends Node
# Basic enemy AI: move toward nearest player unit, attack if in range.
# Called by TurnManager.start_enemy_phase(); awaited until all enemies have acted.

# Runs each living enemy sequentially, then hands control back to TurnManager.
func run_enemy_phase(grid: GridManager, turn: TurnManager) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null or grid == null:
		turn.start_player_phase()
		return
	# Get living enemies before iterating — combat may kill enemies mid-loop
	var enemies: Array[Node] = gs.get_living_enemy_units()
	for enemy in enemies:
		if is_instance_valid(enemy):
			await _act(enemy, grid, turn)
	turn.start_player_phase()


# One enemy's turn: dispatch on ai_profile, then mark DONE.
func _act(enemy: Node, grid: GridManager, turn: TurnManager) -> void:
	if enemy.data == null:
		return
	match enemy.data.ai_profile:
		"passive": await _act_passive(enemy, grid, turn); return
		"healer":  await _act_healer(enemy, grid, turn);  return
		_: pass  # "basic" falls through to standard logic

	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var players: Array[Node] = gs.get_living_player_units()
	if players.is_empty():
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)
		return

	var nearest: Node = _find_nearest(enemy, players, grid)
	var move_tiles: Array[Vector2i] = grid.get_movement_range(enemy)
	var best_tile: Vector2i = _choose_move_tile(enemy, nearest, players, move_tiles, grid)

	if best_tile != enemy.tile_position:
		var path := grid.get_movement_path(enemy, best_tile)
		if path.size() > 1:
			turn.record_move_start(enemy)
			await enemy.move_along_path(path)

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
func _act_passive(enemy: Node, grid: GridManager, turn: TurnManager) -> void:
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
func _act_healer(enemy: Node, grid: GridManager, turn: TurnManager) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)
		return
	var move_tiles: Array[Vector2i] = grid.get_movement_range(enemy)
	var best_tile: Vector2i = _choose_heal_move_tile(enemy, move_tiles, grid, gs)
	if best_tile != enemy.tile_position:
		var path := grid.get_movement_path(enemy, best_tile)
		if path.size() > 1:
			turn.record_move_start(enemy)
			await enemy.move_along_path(path)
	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.MOVED)
	if is_instance_valid(enemy):
		_try_staff_heal(enemy, grid)
	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)


# Pick the move tile that places the most-injured ally in staff range.
# Tie-break: prefer tiles with higher terrain DEF+Dodge bonus (safer positioning).
func _choose_heal_move_tile(enemy: Node, move_tiles: Array[Vector2i],
		grid: GridManager, gs: Node) -> Vector2i:
	var best_tile: Vector2i = enemy.tile_position
	var best_injury_pct: float = -1.0  # higher = more injured = higher priority
	var best_terrain_bonus: int = -1
	var allies: Array[Node] = gs.get_living_enemy_units()
	for tile in move_tiles:
		for ally in allies:
			if not is_instance_valid(ally) or ally == enemy:
				continue
			if ally.data == null or ally.data.hp >= ally.data.max_hp:
				continue
			if not grid.can_attack_from_tile(enemy, tile, ally):
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


# Heals the most-injured ally in range if the enemy carries a staff. Mirrors the
# player's _execute_staff_heal() formula: 10 + MAG, flat 10 EXP, consumes one use.
func _try_staff_heal(enemy: Node, grid: GridManager) -> void:
	if not enemy.has_method("get_equipped_weapon"):
		return
	var weapon: WeaponData = enemy.get_equipped_weapon()
	if weapon == null or weapon.weapon_type != "staff":
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
	var heal_amount: int = 10 + enemy.data.magic
	target.heal(heal_amount)
	enemy.use_weapon_durability(weapon.id)
	if enemy.has_method("add_wexp"):
		enemy.add_wexp(weapon.weapon_type, weapon.wexp)
	enemy.add_exp(10)


# Returns the unit from `units` with the lowest real pathfinding cost from `from_unit`.
# Uses a Dijkstra flood from from_unit's tile — same algorithm as GridManager but we
# only need the cost map, not the reachable set. Falls back to Manhattan distance if
# grid is null (tests / edge cases).
func _find_nearest(from_unit: Node, units: Array[Node], grid: GridManager = null) -> Node:
	if grid == null:
		return _find_nearest_manhattan(from_unit, units)
	# Build cost map from the enemy's position with a large movement budget so we
	# can reach any tile on the map, not just the unit's actual movement range.
	var costs := _flood_costs(from_unit.tile_position, grid)
	var nearest: Node = null
	var min_cost: int = GameConstants.INT_MAX
	for u in units:
		if not is_instance_valid(u):
			continue
		var c: int = costs.get(u.tile_position, GameConstants.INT_MAX)
		if c < min_cost:
			min_cost = c
			nearest = u
	# If no target is reachable at all (fully walled off), fall back to Manhattan.
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


# Dijkstra flood from `start` using terrain costs but ignoring unit movement cap
# and unit occupants — intentional for path-distance estimation. The actual movement
# calculation (GridManager.get_move_tiles) respects occupants; this only estimates
# path cost to a location across a clear map.
# Heap is an insertion-sorted Array of [cost, tile] pairs; pop_front always gives
# the cheapest unvisited tile. Stale entries (cheaper path found later) are skipped.
func _flood_costs(start: Vector2i, grid: GridManager) -> Dictionary:
	var costs: Dictionary = {start: 0}
	var heap: Array = [[0, start]]
	const DIRS: Array[Vector2i] = [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]
	while not heap.is_empty():
		var entry: Array = heap.pop_front()
		var current_cost: int = entry[0]
		var current: Vector2i = entry[1]
		if current_cost > costs.get(current, GameConstants.INT_MAX):
			continue  # stale entry — a shorter path was already settled
		for d in DIRS:
			var next: Vector2i = current + d
			if grid.get_terrain_at(next) == "wall":
				continue
			var step: int = grid.get_move_cost(next, null)
			var total: int = current_cost + step
			if total < costs.get(next, GameConstants.INT_MAX):
				costs[next] = total
				var insert_idx := heap.size()
				for i in heap.size():
					if total <= heap[i][0]:
						insert_idx = i
						break
				heap.insert(insert_idx, [total, next])
	return costs
