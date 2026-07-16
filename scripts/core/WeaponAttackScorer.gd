class_name WeaponAttackScorer
extends RefCounted

# Pure integer scoring for an already-legal weapon attack. Scores are clamped so
# malformed/modded forecast values cannot overflow or dominate later tie-breaks.
const SCORE_MIN: int = -1_000_000
const SCORE_MAX: int = 1_000_000
const RATIO_SCALE: int = 10_000

const PRESET_SHIPPED_COMPATIBILITY: StringName = &"shipped_compatibility"
const PRESET_TACTICAL_FORECAST: StringName = &"tactical_forecast"


# The compatibility preset exactly represents the shipped target rule: nearest
# Manhattan target, with caller order deciding equal-distance ties.
static func score(distance: int, target_hp: int, preview: Dictionary = {},
		preset: StringName = PRESET_SHIPPED_COMPATIBILITY) -> int:
	if preset == PRESET_SHIPPED_COMPATIBILITY:
		return clampi(-maxi(distance, 0), SCORE_MIN, SCORE_MAX)

	var hp: int = maxi(target_hp, 1)
	var attack_damage: int = _bounded_total(preview.get("attacker_damage", 0),
		preview.get("attacker_attacks", 1))
	var counter_damage: int = _bounded_total(preview.get("defender_damage", 0),
		preview.get("defender_attacks", 0)) if preview.get("can_counter", false) else 0
	var damage_ratio: int = _ratio(attack_damage, hp)
	var counter_ratio: int = _ratio(counter_damage, hp)
	var kill_bonus: int = 600_000 if attack_damage >= hp else 0
	# Integer-only arithmetic makes the result reproducible across platforms.
	var result: int = kill_bonus + damage_ratio * 30 - counter_ratio * 20 \
		- mini(maxi(distance, 0), 10_000)
	return clampi(result, SCORE_MIN, SCORE_MAX)


static func choose_target(attacker: Node, targets: Array[Node], preview_provider: Callable,
		preset: StringName = PRESET_SHIPPED_COMPATIBILITY) -> Node:
	var best: Node = null
	var best_score: int = SCORE_MIN
	for target in targets:
		if not is_instance_valid(target):
			continue
		var distance: int = absi(target.tile_position.x - attacker.tile_position.x) \
			+ absi(target.tile_position.y - attacker.tile_position.y)
		var forecast: Dictionary = {}
		# Compatibility must not run forecasts: besides being cheaper, this keeps
		# the exact shipped decision surface independent of future combat features.
		if preset != PRESET_SHIPPED_COMPATIBILITY and preview_provider.is_valid():
			forecast = preview_provider.call(attacker, target)
		var hp: int = target.data.hp if target.get("data") != null else 1
		var candidate_score: int = score(distance, hp, forecast, preset)
		if best == null or candidate_score > best_score:
			best = target
			best_score = candidate_score
	return best


static func _bounded_total(per_strike: Variant, strikes: Variant) -> int:
	var damage: int = clampi(int(per_strike), 0, SCORE_MAX)
	var count: int = clampi(int(strikes), 0, 100)
	return mini(damage * count, SCORE_MAX)


static func _ratio(value: int, denominator: int) -> int:
	return clampi((clampi(value, 0, SCORE_MAX) * RATIO_SCALE) / maxi(denominator, 1),
		0, RATIO_SCALE)
