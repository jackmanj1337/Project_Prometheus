extends SceneTree

const GameConstants = preload("res://scripts/shared/GameConstants.gd")
const UnitDataScript = preload("res://scripts/resources/UnitData.gd")
const WeaponDataScript = preload("res://scripts/resources/WeaponData.gd")

var _passed := 0
var _failed := 0


class MockUnit extends Node:
	var data: Resource
	var tile_position := Vector2i.ZERO
	var team := "blue"
	var weapon: Resource

	func get_equipped_weapon() -> Resource:
		return weapon

	func has_quality(_quality: String) -> bool:
		return false

	func has_vulnerability(_quality: String) -> bool:
		return false

	func has_skill(skill_id: String) -> bool:
		return skill_id in data.skills

	func get_effective_stat(stat_name: String) -> int:
		var value := int(data.get(stat_name))
		for modifier in data.active_modifiers:
			if modifier.get("stat", "") == stat_name:
				value += int(modifier.get("delta", 0))
		return maxi(0, value)

	func battle_speed(use_weapon: Resource = null) -> int:
		var equipped := use_weapon if use_weapon != null else weapon
		return get_effective_stat("speed") - maxi(
			0, int(equipped.wt) - get_effective_stat("strength"))

	func accuracy(use_weapon: Resource = null) -> int:
		var equipped := use_weapon if use_weapon != null else weapon
		return get_effective_stat("skill") * 2 + get_effective_stat("luck") \
			+ int(equipped.hit)

	func dodge(use_weapon: Resource = null) -> int:
		return battle_speed(use_weapon) * 2 + get_effective_stat("luck")

	func crit_rate(use_weapon: Resource = null) -> int:
		var equipped := use_weapon if use_weapon != null else weapon
		return get_effective_stat("skill") / 2 + int(equipped.crit)

	func crit_avoid() -> int:
		return get_effective_stat("luck")

	func get_terrain_def_bonus() -> int:
		return 0

	func get_terrain_dodge_bonus() -> int:
		return 0

	func get_weapon_rank(track: String) -> String:
		return GameConstants.weapon_rank_for_wexp(int(data.weapon_wexp.get(track, 0)))


func _make_unit(id: String, team_id: String, tile: Vector2i) -> MockUnit:
	var unit_data := UnitDataScript.new()
	unit_data.unit_id = id
	unit_data.unit_name = id
	unit_data.hp = 30
	unit_data.max_hp = 30
	unit_data.strength = 10
	unit_data.defense = 5
	unit_data.skill = 10
	unit_data.speed = 10
	unit_data.luck = 5
	var weapon := WeaponDataScript.new()
	weapon.id = "%s_sword" % id
	weapon.combat_family = "sword"
	weapon.wexp_track = "sword"
	weapon.mt = 6
	weapon.hit = 85
	weapon.wt = 5
	weapon.range_min_formula = "1"
	weapon.range_max_formula = "1"
	var unit := MockUnit.new()
	unit.data = unit_data
	unit.weapon = weapon
	unit.team = team_id
	unit.tile_position = tile
	root.add_child(unit)
	return unit


func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1


func _init() -> void:
	await process_frame
	var projection := root.get_node_or_null("ProjectionService")
	var combat := root.get_node_or_null("CombatResolver")
	var rng := root.get_node_or_null("RngService")
	var game_state := root.get_node_or_null("GameState")
	if projection == null or combat == null or rng == null or game_state == null:
		print("\nResults: 0 passed, 1 failed")
		quit(1)
		return

	var attacker := _make_unit("projection_attacker", "blue", Vector2i.ZERO)
	var defender := _make_unit("projection_defender", "red", Vector2i(1, 0))
	var direct: Dictionary = combat.preview_combat(attacker, defender)
	var rng_before: Dictionary = rng.to_save_dict().duplicate(true)
	var gold_before: int = game_state.party_gold
	var attacker_before: Dictionary = {
		"hp": attacker.data.hp,
		"modifiers": attacker.data.active_modifiers.duplicate(true),
		"counters": attacker.data.skill_use_counters.duplicate(true),
	}
	var result = projection.project_combat(attacker, defender, "test")
	_check(result.valid and result.visible_outcome == direct,
		"combat projection delegates to the existing preview math")
	_check(result.rng_summary.get("attacker_hit") == direct["attacker_hit"] \
		and result.rng_summary.get("committed_draws") == 0,
		"projection reports odds without committed draws")
	_check(rng.to_save_dict() == rng_before and game_state.party_gold == gold_before,
		"projection preserves RNG and resource save fields")
	_check(attacker.data.hp == attacker_before["hp"] \
		and attacker.data.active_modifiers == attacker_before["modifiers"] \
		and attacker.data.skill_use_counters == attacker_before["counters"],
		"projection preserves mutable unit state")
	var invalid = projection.project_combat(attacker, null)
	_check(not invalid.valid and invalid.failure_reason == "missing_target",
		"invalid combat target returns a structured failure")

	print("\nResults: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
