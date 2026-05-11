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


# One enemy's turn: find best move tile, move, attack if in range, mark DONE.
func _act(enemy: Node, grid: GridManager, turn: TurnManager) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var players: Array[Node] = gs.get_living_player_units()
	if players.is_empty():
		turn.set_unit_state(enemy, TurnManager.UnitState.DONE)
		return

	var nearest: Node = _find_nearest(enemy, players)
	var move_tiles: Array[Vector2i] = grid.get_movement_range(enemy)
	var best_tile: Vector2i = _choose_move_tile(enemy, nearest, players, move_tiles, grid)

	if best_tile != enemy.tile_position:
		var path := grid.get_movement_path(enemy, best_tile)
		if path.size() > 1:
			turn.record_move_start(enemy)
			await enemy.move_along_path(path)

	if is_instance_valid(enemy):
		turn.set_unit_state(enemy, TurnManager.UnitState.MOVED)

	# Attack the nearest targetable player from the new position
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


# Among move_tiles, pick the tile from which the enemy can attack a player.
# Prefer tiles adjacent to the nearest player; fall back to simply closing distance.
func _choose_move_tile(enemy: Node, nearest: Node, all_players: Array[Node],
		move_tiles: Array[Vector2i], grid: GridManager) -> Vector2i:
	var best_attack_tile: Vector2i = enemy.tile_position
	var best_attack_dist: int = 999999
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
	if best_attack_dist < 999999:
		return best_attack_tile

	# No attack possible — move as close to nearest player as possible
	var best_move: Vector2i = enemy.tile_position
	var best_dist: int = 999999
	for tile in move_tiles:
		var d: int = absi(tile.x - nearest.tile_position.x) \
			+ absi(tile.y - nearest.tile_position.y)
		if d < best_dist:
			best_dist = d
			best_move = tile
	return best_move


func _find_nearest(from_unit: Node, units: Array[Node]) -> Node:
	var nearest: Node = null
	var min_dist: int = 999999
	for u in units:
		if not is_instance_valid(u):
			continue
		var d: int = absi(u.tile_position.x - from_unit.tile_position.x) \
			+ absi(u.tile_position.y - from_unit.tile_position.y)
		if d < min_dist:
			min_dist = d
			nearest = u
	return nearest
