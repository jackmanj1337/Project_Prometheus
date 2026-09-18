extends SceneTree
# Slice 4 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: THE FORECAST CONVERGENCE.
#
# Three code paths used to answer "what does this strike do" — the live exchange, the
# `preview_combat()` readout and the `project_exchange()` projection — and they had
# drifted in four separate places. Every suite covering them was green throughout,
# because each tested its own path against its own expectation. This one tests them
# AGAINST EACH OTHER, which is the only assertion a drift cannot pass.
#
# It also pins the three arithmetic facts the convergence had to choose between, so a
# later edit that picks the other answer fails here rather than in a fight. `[ITR-6]`

const CombatResolverScript = preload("res://scripts/core/CombatResolver.gd")
const GameConstants = preload("res://scripts/shared/GameConstants.gd")
const RngServiceScript = preload("res://scripts/autoloads/RngService.gd")
const UnitDataScript = preload("res://scripts/resources/UnitData.gd")
const WeaponDataScript = preload("res://scripts/resources/WeaponData.gd")


# Deliberately honours the weapon handed to `dodge()`, unlike the mock in
# `test_project_exchange`: the weight penalty the dodger's own weapon imposes is one of
# the four things that had drifted, and a mock that ignores the argument cannot see it.
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
		return null

	func battle_speed(candidate: Resource = null, sink: RefCounted = null) -> int:
		var active: Resource = candidate if candidate != null else weapon
		if active == null:
			return get_effective_stat("speed", sink)
		return (
			get_effective_stat("speed", sink)
			- maxi(0, int(active.wt) - get_effective_stat("strength", sink))
		)

	func accuracy(candidate: Resource = null, sink: RefCounted = null) -> int:
		var active: Resource = candidate if candidate != null else weapon
		return (
			get_effective_stat("skill", sink) * 2
			+ get_effective_stat("luck", sink)
			+ (int(active.hit) if active != null else 0)
		)

	func dodge(candidate: Resource = null, sink: RefCounted = null) -> int:
		return battle_speed(candidate, sink) * 2 + get_effective_stat("luck", sink)

	func crit_rate(candidate: Resource = null, sink: RefCounted = null) -> int:
		var active: Resource = candidate if candidate != null else weapon
		return get_effective_stat("skill", sink) / 2 + (int(active.crit) if active != null else 0)

	func crit_avoid(_sink: RefCounted = null) -> int:
		return get_effective_stat("luck")

	func get_terrain_def_bonus() -> int:
		return 0

	func get_terrain_dodge_bonus() -> int:
		return 0

	func effective_modifiers(_sink: RefCounted = null) -> Array:
		return []

	func get_effective_stat(stat_name: String, _sink: RefCounted = null) -> int:
		var value: Variant = data.get(stat_name)
		return maxi(0, int(value) if value != null else 0)

	func has_skill(_skill_id: String) -> bool:
		return false

	func has_vulnerability(_group: String) -> bool:
		return false


func _init() -> void:
	print("=== Combat Forecast Convergence Test ===")
	var failed := 0
	var resolver: Node = CombatResolverScript.new()
	root.add_child(resolver)
	var rng: Node = root.get_node_or_null("RngService")
	if rng == null:
		rng = RngServiceScript.new()
		rng.name = "RngService"
		root.add_child(rng)
	rng.start_map(20260918)

	# --- the three arithmetic rulings, against a hand-built context -------------
	#
	# Driven through `strike_forecast` directly so the numbers under test are the ones
	# the function returns, not a downstream summary of them.
	var sword := _weapon("sword", 9, 40, 0, 0)
	var axe := _weapon("axe", 9, 40, 0, 0)
	# The target's defence is 6 so the base figure is ODD (12 + 9 - 6 = 15), which is what
	# makes the two truncation orders below disagree. It was 5 until slice 5 of
	# AUTHORED-TRAIT-RELATIONSHIPS: this hand-built context has no `skip_effectiveness`
	# flag, the deleted `_get_effectiveness_multiplier` read that key unguarded, and the
	# failed read left the multiplier at 0.0 -- so the fixture had been fighting with a
	# weapon whose might was multiplied away, and the odd number it needed came from the
	# defect rather than from the stats.
	var actor := _unit("actor", sword, 40, 40, 12, 12, 5, 4)
	var target := _unit("target", axe, 40, 40, 11, 12, 6, 4)
	root.add_child(actor)
	root.add_child(target)

	var plain := _context(sword, axe, 1.0, 0.0)
	var plain_forecast: Dictionary = resolver.strike_forecast(actor, target, plain, false)
	var base: int = int(plain_forecast["damage"])
	failed += _check(base > 0, "the fixture deals damage at all", str(plain_forecast))
	failed += _check(
		int(plain_forecast["crit_damage"]) == base * 3,
		"with no multiplier a crit is exactly triple",
		str(plain_forecast)
	)

	# RULING 1: `damage_multiplier` applies to the FINAL figure, crit included. The live
	# exchange always did this and the projection did not, so they disagreed by where the
	# truncation landed. 15 * 1.5 = 22.5 -> 22; 45 * 1.5 = 67.5 -> 67, not 22 * 3 = 66.
	var scaled: Dictionary = resolver.strike_forecast(
		actor, target, _context(sword, axe, 1.5, 0.0), false
	)
	failed += _check(
		int(scaled["damage"]) == int(base * 1.5),
		"a damage multiplier scales the ordinary figure",
		"%d vs %d" % [int(scaled["damage"]), int(base * 1.5)]
	)
	failed += _check(
		int(scaled["crit_damage"]) == int(base * 3 * 1.5),
		"...and the CRIT figure is scaled from the tripled base, not tripled after scaling",
		"%d vs %d" % [int(scaled["crit_damage"]), int(base * 3 * 1.5)]
	)
	failed += _check(
		int(scaled["crit_damage"]) != int(scaled["damage"]) * 3,
		"...and the fixture is one where those two answers actually differ",
		"%d vs %d" % [int(scaled["crit_damage"]), int(scaled["damage"]) * 3]
	)

	# RULING 2: `ignore_def_fraction` reaches the forecast. It reached the live exchange
	# and the projection and never reached `preview_combat`, so a defence-ignoring skill
	# was invisible in the number the player reads before choosing to use it.
	var piercing: Dictionary = resolver.strike_forecast(
		actor, target, _context(sword, axe, 1.0, 1.0), false
	)
	failed += _check(
		int(piercing["damage"]) > base,
		"ignoring defence raises the forecast damage",
		"%d vs %d" % [int(piercing["damage"]), base]
	)

	# RULING 3: the dodger's OWN weapon sets the weight penalty in `dodge()`. A forecast
	# of a hypothetical loadout is the only caller that can tell, and it is exactly the
	# question the equip and shop screens ask.
	var heavy := _weapon("heavy_axe", 9, 40, 0, 20)
	var heavy_hit: int = int(
		resolver.strike_forecast(actor, target, _context(sword, heavy, 1.0, 0.0), false)["hit_pct"]
	)
	failed += _check(
		heavy_hit > int(plain_forecast["hit_pct"]),
		"a heavier weapon on the DEFENDER lowers their dodge, so the attacker hits more",
		"%d vs %d" % [heavy_hit, int(plain_forecast["hit_pct"])]
	)

	# --- the convergence itself ------------------------------------------------
	#
	# The same pair, read by the two public forecasts. `project_exchange` models strike
	# order and `preview_combat` models per-side totals, but the FIRST attacker strike is
	# the same strike in both, so its hit chance and damage must be the same number.
	var preview: Dictionary = resolver.preview_combat(actor, target)
	var projection: Dictionary = resolver.project_exchange(actor, target, sword, "plain")
	var first_attacker_strike := _first_attacker_strike(projection)
	failed += _check(
		not first_attacker_strike.is_empty(), "the projection produced an attacker strike"
	)
	# Guards the two comparisons below from agreeing at zero, which is what a fixture
	# whose attacker cannot reach the defender would do.
	failed += _check(
		int(preview["attacker_damage"]) > 0 and int(preview["attacker_hit"]) > 0,
		"the preview forecasts a real strike, so the agreement below is not 0 == 0",
		"%d damage at %d%%" % [int(preview["attacker_damage"]), int(preview["attacker_hit"])]
	)
	if not first_attacker_strike.is_empty():
		failed += _check(
			int(first_attacker_strike["damage"]) == int(preview["attacker_damage"]),
			"PREVIEW AND PROJECTION AGREE on the attacker's damage",
			"%d vs %d" % [int(first_attacker_strike["damage"]), int(preview["attacker_damage"])]
		)
		failed += _check(
			is_equal_approx(
				float(first_attacker_strike["hit_probability"]),
				int(preview["attacker_hit"]) / 100.0
			),
			"...and on the attacker's hit chance",
			(
				"%f vs %f"
				% [
					float(first_attacker_strike["hit_probability"]),
					int(preview["attacker_hit"]) / 100.0
				]
			)
		)

	resolver.queue_free()
	actor.queue_free()
	target.queue_free()
	print("=== Results: %d failed ===" % failed)
	quit(1 if failed else 0)


# The strike specs are not returned by `project_exchange`; the outcome states are. The
# projection's first attacker strike is recoverable from its own spec list, which the
# summary carries for exactly this kind of reading.
func _first_attacker_strike(projection: Dictionary) -> Dictionary:
	for strike in projection.get("strikes", []):
		if String((strike as Dictionary).get("actor_role", "")) == "attacker":
			return strike as Dictionary
	return {}


# The shape `_build_combat_context` produces, reduced to the keys `strike_forecast` reads.
# Written out rather than built through the real context so the case under test is the
# forecast arithmetic and not the modifier collection that feeds it.
func _context(
	attacker_weapon: Resource,
	defender_weapon: Resource,
	damage_multiplier: float,
	ignore_def: float
) -> Dictionary:
	return {
		"attacker_weapon": attacker_weapon,
		"defender_weapon": defender_weapon,
		"atk_mod": _modifiers(damage_multiplier),
		"def_mod": _modifiers(1.0),
		"flags": {"attacker_ignores_def": ignore_def, "defender_ignores_def": 0.0},
		"effect_sink": null,
	}


func _modifiers(damage_multiplier: float) -> Dictionary:
	return {
		"accuracy": 0,
		"dodge": 0,
		"damage": 0,
		"crit": 0,
		"crit_avoid": 0,
		"strikes": 0,
		"damage_multiplier": damage_multiplier,
	}


func _weapon(id: String, might: int, hit: int, crit: int, weight: int) -> Resource:
	var weapon := WeaponDataScript.new()
	weapon.id = id
	weapon.combat_family = "sword"
	weapon.wexp_track = GameConstants.combat_family_to_wexp_track("sword")
	weapon.mt = might
	weapon.hit = hit
	weapon.crit = crit
	weapon.wt = weight
	weapon.range_min_formula = "1"
	weapon.range_max_formula = "1"
	weapon.strikes_per_attack = 1
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


func _check(ok: bool, label: String, detail: String = "") -> int:
	print(
		"%s  %s%s" % ["OK " if ok else "FAIL", label, "" if ok or detail == "" else " — " + detail]
	)
	return 0 if ok else 1
