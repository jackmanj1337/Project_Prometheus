extends SceneTree

const CombatResolverScript = preload("res://scripts/core/CombatResolver.gd")
const GameConstants = preload("res://scripts/shared/GameConstants.gd")
const InventoryEntry = preload("res://scripts/resources/InventoryEntry.gd")
const RngServiceScript = preload("res://scripts/autoloads/RngService.gd")
const UnitDataScript = preload("res://scripts/resources/UnitData.gd")
const WeaponDataScript = preload("res://scripts/resources/WeaponData.gd")


class MockUnit:
	extends Node
	var data: Resource
	var tile_position := Vector2i.ZERO
	var team := "blue"
	var weapon: Resource
	var weapon_uses := 99

	func get_equipped_weapon() -> Resource:
		return weapon

	func get_equipped_weapon_entry():
		if weapon == null:
			return null
		var entry := InventoryEntry.new()
		entry.entry_type = "weapon"
		entry.weapon_id = weapon.id
		entry.uses_remaining = weapon_uses
		return entry

	func battle_speed(candidate: Resource = null) -> int:
		var active: Resource = candidate if candidate != null else weapon
		if active == null:
			return get_effective_stat("speed")
		return (
			get_effective_stat("speed") - maxi(0, int(active.wt) - get_effective_stat("strength"))
		)

	func accuracy(candidate: Resource = null) -> int:
		var active: Resource = candidate if candidate != null else weapon
		return (
			get_effective_stat("skill") * 2
			+ get_effective_stat("luck")
			+ (int(active.hit) if active != null else 0)
		)

	func dodge(_candidate: Resource = null) -> int:
		return battle_speed() * 2 + get_effective_stat("luck")

	func crit_rate(candidate: Resource = null) -> int:
		var active: Resource = candidate if candidate != null else weapon
		return get_effective_stat("skill") / 2 + (int(active.crit) if active != null else 0)

	func crit_avoid() -> int:
		return get_effective_stat("luck")

	func get_terrain_def_bonus() -> int:
		return 0

	func get_terrain_dodge_bonus() -> int:
		return 0

	func get_effective_stat(stat_name: String) -> int:
		var value: Variant = data.get(stat_name)
		return maxi(0, int(value) if value != null else 0)

	func has_skill(_skill_id: String) -> bool:
		return false

	func has_vulnerability(_group: String) -> bool:
		return false


func _init() -> void:
	print("=== Ordered Exchange Projection Test ===")
	var passed := 0
	var failed := 0
	var resolver: Node = CombatResolverScript.new()
	root.add_child(resolver)
	var rng: Node = root.get_node_or_null("RngService")
	if rng == null:
		rng = RngServiceScript.new()
		rng.name = "RngService"
		root.add_child(rng)
	rng.start_map(20260719)

	var sword := _weapon("projection_sword", 20, 100, 0, 1)
	var weak_sword := _weapon("weak_sword", 1, 100, 0, 1)
	var attacker := _unit("attacker", sword, 20, 20, 12, 20, 10, 5)
	var defender := _unit("defender", weak_sword, 12, 12, 5, 5, 0, 0)
	root.add_child(attacker)
	root.add_child(defender)
	await process_frame
	attacker.data.inventory.append(InventoryEntry.make_item("vulnerary", 2))
	attacker.tile_position = Vector2i(1, 1)
	defender.tile_position = Vector2i(2, 1)

	var preview_before := JSON.stringify(resolver.preview_combat(attacker, defender))
	var hp_before := [attacker.data.hp, defender.data.hp]
	var counters_before: Dictionary = attacker.data.skill_use_counters.duplicate(true)
	var inventory_before: Array = attacker.data.inventory.duplicate(true)
	var rng_before: Dictionary = rng.to_save_dict()
	var projection: Dictionary = resolver.project_exchange(
		attacker, defender, sword, "plain", "exclude"
	)
	var preview_after := JSON.stringify(resolver.preview_combat(attacker, defender))
	var lethal_order_ok: bool = (
		is_equal_approx(float(projection["defender_death_probability"]), 1.0)
		and is_zero_approx(float(projection["attacker_death_probability"]))
		and projection["outcomes"].all(func(state): return int(state["attacker_hp"]) == 20)
	)
	passed += _report(lethal_order_ok, "death stops the guaranteed defender counter")
	failed += int(not lethal_order_ok)

	var purity_ok: bool = (
		[attacker.data.hp, defender.data.hp] == hp_before
		and attacker.weapon_uses == 99
		and attacker.data.skill_use_counters == counters_before
		and attacker.data.inventory == inventory_before
		and rng.to_save_dict() == rng_before
		and preview_before == preview_after
	)
	passed += _report(
		purity_ok, "projection leaves HP, durability, counters, and preview unchanged"
	)
	failed += int(not purity_ok)

	var styles_ok: bool = (
		projection["styles"] == {"attacker": null, "defender": null}
		and projection["strikes"].all(func(strike): return strike["style"] == null)
	)
	passed += _report(styles_ok, "both combatants carry symmetric null style slots")
	failed += int(not styles_ok)

	attacker.tile_position = Vector2i(8, 8)
	var cached: Dictionary = resolver.project_exchange(attacker, defender, sword, "plain")
	var cache_ok: bool = cached == projection and resolver.exchange_projection_cache_size() == 1
	passed += _report(cache_ok, "cache key excludes the literal attacker tile")
	failed += int(not cache_ok)

	var brave := _weapon("one_use_brave", 3, 100, 0, 2)
	attacker.weapon = brave
	attacker.weapon_uses = 1
	attacker.data.hp = 30
	attacker.data.speed = 20
	defender.data.hp = 30
	defender.weapon = null
	resolver.clear_exchange_projection_cache()
	var break_projection: Dictionary = resolver.project_exchange(attacker, defender, brave, "plain")
	var first_strike: Dictionary = break_projection["strikes"][0]
	var first_strike_expected: float = (
		(
			minf(float(first_strike["damage"]), defender.data.hp)
			* (1.0 - float(first_strike["crit_probability_on_hit"]))
		)
		+ (
			minf(float(first_strike["crit_damage"]), defender.data.hp)
			* float(first_strike["crit_probability_on_hit"])
		)
	)
	var break_ok: bool = (
		break_projection["strikes"].size() == 4
		and is_equal_approx(
			float(break_projection["expected_damage_to_defender"]), first_strike_expected
		)
	)
	passed += _report(break_ok, "one-use Brave weapon stops after its first ordered strike")
	failed += int(not break_ok)

	var uncertain := _weapon("uncertain", 4, 40, 20, 1)
	attacker.weapon = uncertain
	attacker.weapon_uses = 20
	attacker.data.speed = 5
	defender.data.hp = 25
	resolver.clear_exchange_projection_cache()
	var bounded: Dictionary = resolver.project_exchange(
		attacker, defender, uncertain, "forest", "expected_value"
	)
	var bounds_ok: bool = (
		float(bounded["probability_total"]) >= 0.999999
		and float(bounded["probability_total"]) <= 1.000001
		and float(bounded["defender_death_probability"]) >= 0.0
		and float(bounded["defender_death_probability"]) <= 1.0
		and float(bounded["expected_damage_to_defender"]) >= 0.0
		and float(bounded["expected_damage_to_defender"]) <= defender.data.hp
		and bounded["proc_handling"] == "expected_value"
		and resolver.exchange_projection_cache_size("expected_value") == 1
	)
	passed += _report(
		bounds_ok, "probability and damage extremes stay bounded for expected-value mode"
	)
	failed += int(not bounds_ok)

	resolver.queue_free()
	attacker.queue_free()
	defender.queue_free()
	await process_frame
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _report(ok: bool, label: String) -> int:
	print("%s  %s" % ["OK" if ok else "FAIL", label])
	return int(ok)


func _weapon(id: String, might: int, hit: int, crit: int, strikes: int) -> Resource:
	var weapon := WeaponDataScript.new()
	weapon.id = id
	weapon.combat_family = "sword"
	weapon.wexp_track = GameConstants.combat_family_to_wexp_track("sword")
	weapon.mt = might
	weapon.hit = hit
	weapon.crit = crit
	weapon.wt = 0
	weapon.range_min_formula = "1"
	weapon.range_max_formula = "1"
	weapon.strikes_per_attack = strikes
	return weapon


func _unit(
	id: String,
	weapon: Resource,
	hp: int,
	max_hp: int,
	strength: int,
	speed: int,
	defense: int,
	luck: int
) -> MockUnit:
	var data := UnitDataScript.new()
	data.unit_id = id
	data.hp = hp
	data.max_hp = max_hp
	data.strength = strength
	data.speed = speed
	data.defense = defense
	data.resistance = defense
	data.skill = 20
	data.luck = luck
	var unit := MockUnit.new()
	unit.data = data
	unit.weapon = weapon
	return unit
