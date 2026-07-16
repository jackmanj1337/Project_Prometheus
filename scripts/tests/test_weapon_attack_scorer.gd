extends SceneTree

const Scorer = preload("res://scripts/core/WeaponAttackScorer.gd")


func _init() -> void:
	var passed := 0
	var failed := 0

	var fixtures := [
		[0, 20, {}, Scorer.PRESET_SHIPPED_COMPATIBILITY],
		[2_000_000, 20, {}, Scorer.PRESET_SHIPPED_COMPATIBILITY],
		[0, 1, {"attacker_damage": 2_000_000, "attacker_attacks": 1000,
			"can_counter": true, "defender_damage": 2_000_000,
			"defender_attacks": 1000}, Scorer.PRESET_TACTICAL_FORECAST],
	]
	var bounded := true
	var deterministic := true
	for fixture in fixtures:
		var first: int = Scorer.score(fixture[0], fixture[1], fixture[2], fixture[3])
		bounded = bounded and first >= Scorer.SCORE_MIN and first <= Scorer.SCORE_MAX
		for repeat in 100:
			deterministic = deterministic \
				and Scorer.score(fixture[0], fixture[1], fixture[2], fixture[3]) == first
	if bounded:
		print("OK  every scorer fixture stays inside the declared closed bounds"); passed += 1
	else:
		print("FAIL scorer escaped its declared bounds"); failed += 1
	if deterministic:
		print("OK  integer scorer repeats identically"); passed += 1
	else:
		print("FAIL scorer changed across identical calls"); failed += 1

	var stub := GDScript.new()
	stub.source_code = "extends Node\nvar tile_position := Vector2i.ZERO\nvar data := UnitData.new()\n"
	stub.reload()
	var attacker: Node = stub.new(); attacker.tile_position = Vector2i.ZERO
	var first_target: Node = stub.new(); first_target.tile_position = Vector2i(2, 0)
	var second_target: Node = stub.new(); second_target.tile_position = Vector2i(0, 2)
	root.add_child(attacker); root.add_child(first_target); root.add_child(second_target)
	var targets: Array[Node] = [first_target, second_target]
	var preview_calls := [0]
	var provider := func(_a, _t) -> Dictionary:
		preview_calls[0] += 1
		return {"attacker_damage": 999999}
	var chosen: Node = Scorer.choose_target(attacker, targets, provider,
		Scorer.PRESET_SHIPPED_COMPATIBILITY)
	if chosen == first_target and preview_calls[0] == 0:
		print("OK  compatibility preset preserves nearest/first-tie behavior without forecasts"); passed += 1
	else:
		print("FAIL compatibility parity: chosen=%s preview_calls=%d" % [chosen, preview_calls[0]]); failed += 1

	# Exhaustively compare the preset with the replaced implementation over a
	# bounded grid and both candidate orders. This proves the compatibility seam,
	# rather than relying on a few favorable examples.
	var parity := true
	for attacker_x in 3:
		for attacker_y in 3:
			attacker.tile_position = Vector2i(attacker_x, attacker_y)
			for first_x in 3:
				for first_y in 3:
					first_target.tile_position = Vector2i(first_x, first_y)
					for second_x in 3:
						for second_y in 3:
							second_target.tile_position = Vector2i(second_x, second_y)
							for ordered in [[first_target, second_target],
									[second_target, first_target]]:
								var typed: Array[Node] = [ordered[0], ordered[1]]
								parity = parity and Scorer.choose_target(attacker, typed,
									Callable(), Scorer.PRESET_SHIPPED_COMPATIBILITY) \
									== _legacy_nearest(attacker, typed)
	if parity:
		print("OK  compatibility preset matches every bounded legacy decision fixture"); passed += 1
	else:
		print("FAIL compatibility preset diverged from the legacy algorithm"); failed += 1

	first_target.data.hp = 20
	second_target.data.hp = 20
	var tactical_provider := func(_a, target) -> Dictionary:
		return {"attacker_damage": 5 if target == first_target else 20,
			"attacker_attacks": 1, "can_counter": false}
	if Scorer.choose_target(attacker, targets, tactical_provider,
			Scorer.PRESET_TACTICAL_FORECAST) == second_target:
		print("OK  tactical preset can prefer a forecasted kill"); passed += 1
	else:
		print("FAIL tactical preset did not prefer the kill"); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _legacy_nearest(attacker: Node, targets: Array[Node]) -> Node:
	var nearest: Node = null
	var min_distance: int = GameConstants.INT_MAX
	for target in targets:
		var distance: int = absi(target.tile_position.x - attacker.tile_position.x) \
			+ absi(target.tile_position.y - attacker.tile_position.y)
		if distance < min_distance:
			min_distance = distance
			nearest = target
	return nearest
