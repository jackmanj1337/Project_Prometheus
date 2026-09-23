extends SceneTree
# Slice 3 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: COMPOSITION.
# Slice 2's suite is about what one profile returns; this one is about what happens when
# several of them match at once — authored priority, the stack policies, `stops_below`,
# and the reaver worked example `[ITR-5]` requires. The failure this slice can produce is
# a number that depends on the order profiles happen to be written in, so the property
# test at the end is the point of the file rather than an extra. `[ITR-1..7]`.

const Resolver = preload("res://scripts/interaction/InteractionRuleResolver.gd")
const Schema = preload("res://scripts/interaction/InteractionProfileSchema.gd")
const Formula = preload("res://scripts/req/FormulaEvaluator.gd")
const RequirementSystemScript = preload("res://scripts/autoloads/RequirementSystem.gd")

const REAVER_FIXTURE := "res://scripts/tests/fixtures/interaction/reaver_profiles.json"
var _passed := 0


# The shape `RequirementSystem._unit_data` reads: anything with `groups` answers
# has_trait/in_group, which is all these profiles select on.
class StubSubject:
	extends RefCounted

	var groups: Array[String] = []

	func _init(in_groups: Array[String] = []) -> void:
		groups = in_groups


func _init() -> void:
	var failed := 0
	var requirements := RequirementSystemScript.new()
	requirements._ready()
	var deps := {"requirements": requirements}
	var swordsman := StubSubject.new(["sword"])
	var axeman := StubSubject.new(["axe"])
	var subjects := {
		"source": swordsman,
		"target": axeman,
		"equipped_source": swordsman,
		"equipped_target": axeman,
	}

	# --- the envelope the contract declares -----------------------------------
	var one := Resolver.resolve([_profile({})], "combat", subjects, deps)
	failed += _check(
		_keys(one) == _sorted(Schema.ENVELOPE_FIELDS),
		"resolve() returns EXACTLY ENVELOPE_FIELDS, so slice 4 has one declared shape to read"
	)
	failed += _check(
		_keys(one["records"][0]) == _sorted(Schema.RESULT_FIELDS),
		"the per-profile record is still exactly RESULT_FIELDS: composition added no key to it"
	)
	failed += _check(
		one["groups"].size() == 1 and _keys(one["groups"][0]) == _sorted(Schema.GROUP_FIELDS),
		"each stack group returns exactly GROUP_FIELDS"
	)
	failed += _check(
		(
			one["effects"].size() == 1
			and one["effects"][0]["stack_group"] == "group_a"
			and one["effects"][0]["composed_from"] == [{"profile_id": "p1", "rule_id": "r1"}]
		),
		"an applied payload names the group that composed it and the match it came from"
	)

	# --- resolution order is priority, then declaration [ITR-4] ---------------
	var ordered := (
		Resolver
		. resolve(
			[
				_profile({"profile_id": "low", "priority": 1, "stack_group": "g_low"}),
				_profile({"profile_id": "high", "priority": 99, "stack_group": "g_high"}),
			],
			"combat",
			subjects,
			deps
		)
	)
	failed += _check(
		_profile_order(ordered) == ["high", "low"],
		"records come back in authored priority order, not declaration order"
	)

	# --- stack policies -------------------------------------------------------
	# Two profiles in one group, both matching, contributing to the SAME slot: same
	# composition, same target, same params. This is the only situation a policy decides.
	var high_low := [
		_profile(
			{
				"profile_id": "a",
				"priority": 20,
				"stack_policy": "PLACEHOLDER",
				"rules": [_rule({"effects": [_effect({"magnitude": {"literal": 3}})]})]
			}
		),
		_profile(
			{
				"profile_id": "b",
				"priority": 10,
				"stack_policy": "PLACEHOLDER",
				"rules":
				[_rule({"rule_id": "r2", "effects": [_effect({"magnitude": {"literal": 5}})]})]
			}
		),
	]
	failed += _check(
		_applied_magnitudes(_with_policy(high_low, "first"), requirements) == [3 * Formula.SCALE],
		"'first' keeps the contribution that comes first in RESOLUTION order, not the largest"
	)
	failed += _check(
		_applied_magnitudes(_with_policy(high_low, "highest"), requirements) == [5 * Formula.SCALE],
		"'highest' keeps the largest magnitude even though it is the lower-priority profile"
	)
	failed += _check(
		_applied_magnitudes(_with_policy(high_low, "lowest"), requirements) == [3 * Formula.SCALE],
		"'lowest' keeps the smallest magnitude"
	)
	failed += _check(
		_applied_magnitudes(_with_policy(high_low, "sum"), requirements) == [8 * Formula.SCALE],
		"'sum' adds the group's magnitudes into one payload"
	)
	failed += _check(
		(
			_applied_magnitudes(_with_policy(high_low, "multiply"), requirements)
			== [15 * Formula.SCALE]
		),
		"'multiply' composes in fixed point: 3 x 5 is 15, not 15000"
	)
	failed += _check(
		(
			_applied_magnitudes(_with_policy(high_low, "all"), requirements)
			== [3 * Formula.SCALE, 5 * Formula.SCALE]
		),
		"'all' composes nothing: every contribution applies on its own"
	)

	# The composition and an authored formula must agree, or a pack gets two different
	# numbers for the same arithmetic depending on where it wrote it.
	var authored := Formula.evaluate(
		{"op": "mul", "operands": [{"literal": 3}, {"literal": 5}]}, {}, 16, 128
	)
	failed += _check(
		(
			int(authored["value"])
			== _applied_magnitudes(_with_policy(high_low, "multiply"), requirements)[0]
		),
		"the 'multiply' policy and an authored `mul` produce the same fixed-point number"
	)

	var summed := Resolver.resolve(_with_policy(high_low, "sum"), "combat", subjects, deps)
	var sum_group: Dictionary = summed["groups"][0]
	failed += _check(
		(
			sum_group["applied"].size() == 1
			and sum_group["applied"][0]["profile_id"] == "a"
			and sum_group["applied"][0]["composed_from"].size() == 2
			and sum_group["dropped"].size() == 1
			and String(sum_group["dropped"][0]["reason"]).contains("aggregated")
		),
		"an aggregate is carried by the leading match, names every contributor, and says so"
	)
	failed += _check(
		_record_for(summed, "b")["matched_rules"] == ["r2"],
		"losing a composition is NOT losing the match: the rule still reports as matched"
	)
	failed += _check(
		_record_for(summed, "b")["effects"].is_empty() and _flat_effects(summed).size() == 1,
		"but its effect leaves `effects`, which still means what applies"
	)
	failed += _check(
		_flat_effects(summed) == (summed["effects"] as Array),
		"the envelope's effects are the records' effects concatenated, never a second computation"
	)

	# --- a slot is composition + target + params ------------------------------
	var two_slots := [
		_profile(
			{
				"profile_id": "a",
				"stack_policy": "sum",
				"rules": [_rule({"effects": [_effect({"magnitude": {"literal": 3}})]})]
			}
		),
		_profile(
			{
				"profile_id": "b",
				"stack_policy": "sum",
				"rules":
				[_rule({"effects": [_effect({"target": "target", "magnitude": {"literal": 5}})]})]
			}
		),
	]
	failed += _check(
		_applied_magnitudes(two_slots, requirements) == [3 * Formula.SCALE, 5 * Formula.SCALE],
		"contributions to different target subjects are different slots and do not compose"
	)
	var param_slots := [
		_profile(
			{
				"profile_id": "a",
				"stack_policy": "sum",
				"rules":
				[
					_rule(
						{
							"effects":
							[_effect({"params": {"stat": "hit"}, "magnitude": {"literal": 3}})]
						}
					)
				]
			}
		),
		_profile(
			{
				"profile_id": "b",
				"stack_policy": "sum",
				"rules":
				[
					_rule(
						{
							"effects":
							[_effect({"params": {"stat": "crit"}, "magnitude": {"literal": 5}})]
						}
					)
				]
			}
		),
	]
	failed += _check(
		_applied_magnitudes(param_slots, requirements) == [3 * Formula.SCALE, 5 * Formula.SCALE],
		"different params are different slots: a summed payload must not describe one and count both"
	)

	# --- an unavailable magnitude is not a small number -----------------------
	var broken_effect := _effect({"magnitude": {"source_id": "nowhere"}})
	var unavailable := Resolver.resolve(
		[_profile({"stack_policy": "highest", "rules": [_rule({"effects": [broken_effect]})]})],
		"combat",
		subjects,
		deps
	)
	failed += _check(
		(
			unavailable["effects"].is_empty()
			and unavailable["groups"][0]["dropped"].size() == 1
			and String(unavailable["groups"][0]["dropped"][0]["reason"]).contains(
				"could not be evaluated"
			)
			and unavailable["records"][0]["formula_results"].size() == 1
		),
		"a policy that reads magnitudes drops one it could not evaluate, and says why"
	)
	var unavailable_all := Resolver.resolve(
		[_profile({"stack_policy": "all", "rules": [_rule({"effects": [broken_effect]})]})],
		"combat",
		subjects,
		deps
	)
	failed += _check(
		unavailable_all["effects"].size() == 1 and not unavailable_all["effects"][0]["available"],
		"'all' reads no magnitude, so it passes the unavailable payload to slice 4 to rule on"
	)

	# --- stops_below [ITR-4] ---------------------------------------------------
	var stopping := [
		_profile(
			{"profile_id": "stopper", "priority": 50, "stack_group": "g_stop", "stops_below": true}
		),
		_profile({"profile_id": "below", "priority": 10, "stack_group": "g_below"}),
		_profile({"profile_id": "level", "priority": 50, "stack_group": "g_level"}),
	]
	var stopped := Resolver.resolve(stopping, "combat", subjects, deps)
	var below_record := _record_for(stopped, "below")
	failed += _check(
		(
			below_record["matched_rules"].is_empty()
			and below_record["effects"].is_empty()
			and below_record["suppressed_rules"].size() == 1
			and below_record["suppressed_rules"][0]["by"][0]["reason"] == "stops_below"
			and below_record["suppressed_rules"][0]["by"][0]["profile_id"] == "stopper"
		),
		"stops_below removes a lower-priority match and records which profile stopped it"
	)
	failed += _check(
		below_record["suppressed_rules"][0]["by"][0]["rule_id"] == "",
		"a stop is a profile-level act, so no rule id is invented for it"
	)
	failed += _check(
		not _record_for(stopped, "level")["matched_rules"].is_empty(),
		"an equal-priority profile is NOT stopped: 'below' is strict, or ties would decide by order"
	)
	failed += _check(
		not _record_for(stopped, "stopper")["matched_rules"].is_empty(),
		"a stopping profile does not stop itself"
	)
	var no_match_stopper := (
		Resolver
		. resolve(
			[
				_profile(
					{
						"profile_id": "stopper",
						"priority": 50,
						"stack_group": "g_stop",
						"stops_below": true,
						"rules":
						[
							_rule(
								{
									"when":
									{
										"predicate_id": "has_trait",
										"subject": {"kind": "source"},
										"params": {"id": "lance"}
									}
								}
							)
						]
					}
				),
				_profile({"profile_id": "below", "priority": 10, "stack_group": "g_below"}),
			],
			"combat",
			subjects,
			deps
		)
	)
	failed += _check(
		not _record_for(no_match_stopper, "below")["matched_rules"].is_empty(),
		"a profile that matched nothing stops nothing: stops_below is a consequence of matching"
	)

	# --- one group, one policy -------------------------------------------------
	var conflicting := [
		_profile({"profile_id": "a", "stack_group": "shared", "stack_policy": "sum"}),
		_profile({"profile_id": "b", "stack_group": "shared", "stack_policy": "highest"}),
	]
	var conflicted := Resolver.resolve(conflicting, "combat", subjects, deps)
	failed += _check(
		(
			_has_error(conflicted, "conflicting stack_policy")
			and conflicted["effects"].is_empty()
			and conflicted["groups"][0]["dropped"].size() == 2
		),
		"two policies for one group is refused and applies nothing, rather than picking by order"
	)
	failed += _check(
		_has_error_text(
			Schema.validate(conflicting, {"requirements": requirements, "catalog": _catalog()}),
			"one group, one policy"
		),
		"and the schema refuses it at LOAD time, so a pack cannot reach combat in that state"
	)

	# --- reaver, the worked example [ITR-5] ------------------------------------
	var reaver_fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(REAVER_FIXTURE))
	var reaver_profiles: Array = (reaver_fixture as Dictionary)["profiles"]
	var sword_reaver := StubSubject.new(["sword", "reaver"])
	var parity_subjects := {
		"source": swordsman,
		"target": axeman,
		"equipped_source": sword_reaver,
		"equipped_target": axeman,
	}
	var reaved := Resolver.resolve(reaver_profiles, "combat", parity_subjects, deps)
	failed += _check(
		reaved["errors"].is_empty(),
		"the reaver fixture resolves clean: the vocabulary carries [CEX-17] with no new mechanism"
	)
	failed += _check(
		_profile_order(reaved) == ["reaver_weapon_triangle", "physical_weapon_triangle"],
		"the mirrored profile runs first because it is authored at higher priority"
	)
	var base_record := _record_for(reaved, "physical_weapon_triangle")
	failed += _check(
		(
			base_record["matched_rules"].is_empty()
			and base_record["suppressed_rules"].size() == 1
			and base_record["suppressed_rules"][0]["by"][0]["reason"] == "suppresses"
		),
		"reaver SUPPRESSES the base triangle rather than transforming its result"
	)
	failed += _check(
		_magnitudes(reaved) == [-20 * Formula.SCALE, -4 * Formula.SCALE],
		"the inversion and the doubling are AUTHORED arithmetic: +10/+2 becomes -20/-4"
	)
	var axe_reaver := StubSubject.new(["axe", "reaver"])
	var both := (
		Resolver
		. resolve(
			reaver_profiles,
			"combat",
			{
				"source": swordsman,
				"target": axeman,
				"equipped_source": sword_reaver,
				"equipped_target": axe_reaver,
			},
			deps
		)
	)
	failed += _check(
		(
			_record_for(both, "reaver_weapon_triangle")["matched_rules"].is_empty()
			and _magnitudes(both) == [10 * Formula.SCALE, 2 * Formula.SCALE]
		),
		"two reaver weapons cancel: the parity predicate stops matching and the base applies"
	)

	# --- the property: order in, same answer out ------------------------------
	# Six permutations of three profiles at distinct priorities. Everything observable —
	# record order, applied magnitudes, group contents — must be identical, because the
	# authored priority is the only thing allowed to decide it.
	var permuted := [
		_profile(
			{
				"profile_id": "p_high",
				"priority": 30,
				"stack_group": "g_high",
				"rules": [_rule({"effects": [_effect({"magnitude": {"literal": 1}})]})]
			}
		),
		_profile(
			{
				"profile_id": "p_mid",
				"priority": 20,
				"stack_group": "g_mid",
				"rules": [_rule({"effects": [_effect({"magnitude": {"literal": 2}})]})]
			}
		),
		_profile(
			{
				"profile_id": "p_low",
				"priority": 10,
				"stack_group": "g_low",
				"rules": [_rule({"effects": [_effect({"magnitude": {"literal": 3}})]})]
			}
		),
	]
	var baseline := JSON.stringify(
		_observable(Resolver.resolve(permuted, "combat", subjects, deps))
	)
	var stable := true
	for order in _permutations([0, 1, 2]):
		var arrangement: Array = []
		for index in order:
			arrangement.append(permuted[int(index)])
		var observed := JSON.stringify(
			_observable(Resolver.resolve(arrangement, "combat", subjects, deps))
		)
		if observed != baseline:
			stable = false
			print("  permutation %s diverged" % [order])
	failed += _check(
		stable, "every permutation of a distinctly-prioritised set resolves identically"
	)

	# The DECLARED exception: equal priorities are broken by declaration order, and that is
	# the one case where rewriting the array legitimately changes the answer.
	var tied := [
		_profile(
			{
				"profile_id": "first_declared",
				"priority": 5,
				"stack_policy": "first",
				"rules": [_rule({"effects": [_effect({"magnitude": {"literal": 1}})]})]
			}
		),
		_profile(
			{
				"profile_id": "second_declared",
				"priority": 5,
				"stack_policy": "first",
				"rules":
				[_rule({"rule_id": "r2", "effects": [_effect({"magnitude": {"literal": 2}})]})]
			}
		),
	]
	var reversed_tie: Array = [tied[1], tied[0]]
	failed += _check(
		(
			_applied_magnitudes(tied, requirements) == [1 * Formula.SCALE]
			and _applied_magnitudes(reversed_tie, requirements) == [2 * Formula.SCALE]
		),
		"on a priority tie declaration order decides, which is the declared final tie-breaker"
	)

	print("=== Interaction Rule Composition Results: %d passed, %d failed ===" % [_passed, failed])
	quit(1 if failed else 0)


# --- builders, mirroring slice 2's suite so both describe the same profile ----


func _profile(overrides: Dictionary) -> Dictionary:
	var profile := {
		"profile_id": "p1",
		"context": "combat",
		"subjects": ["source", "target", "equipped_source"],
		"priority": 10,
		"stack_group": "group_a",
		"stack_policy": "highest",
		"stops_below": false,
		"rules": [_rule({})],
	}
	for key in overrides:
		profile[key] = overrides[key]
	return profile


func _rule(overrides: Dictionary) -> Dictionary:
	var rule := {
		"rule_id": "r1",
		"when":
		{"predicate_id": "has_trait", "subject": {"kind": "source"}, "params": {"id": "sword"}},
		"effects": [_effect({})],
	}
	for key in overrides:
		rule[key] = overrides[key]
	return rule


func _effect(overrides: Dictionary) -> Dictionary:
	var effect := {"composition_id": "combat_damage_modifier", "target": "source"}
	for key in overrides:
		effect[key] = overrides[key]
	return effect


# Restates the same profile pair under a different policy. Written as a rebuild rather
# than a mutation so no case can leak a policy into the next one.
func _with_policy(profiles: Array, policy: String) -> Array:
	var out: Array = []
	for profile in profiles:
		var copy: Dictionary = (profile as Dictionary).duplicate(true)
		copy["stack_policy"] = policy
		out.append(copy)
	return out


# A catalogue answering has_entry for the composition ids these fixtures name; slice 1's
# validation refuses an unresolvable composition id and this suite is not testing that.
func _catalog() -> RefCounted:
	return StubCatalog.new()


class StubCatalog:
	extends RefCounted

	func has_entry(_family: String, _id: String) -> bool:
		return true


# --- readers ------------------------------------------------------------------


func _applied_magnitudes(profiles: Array, requirements: Variant) -> Array:
	var swordsman := StubSubject.new(["sword"])
	var axeman := StubSubject.new(["axe"])
	return _magnitudes(
		(
			Resolver
			. resolve(
				profiles,
				"combat",
				{
					"source": swordsman,
					"target": axeman,
					"equipped_source": swordsman,
					"equipped_target": axeman,
				},
				{"requirements": requirements}
			)
		)
	)


func _magnitudes(result: Dictionary) -> Array:
	var values: Array = []
	for effect in result["effects"]:
		values.append(int(effect["magnitude_fixed"]))
	return values


func _flat_effects(result: Dictionary) -> Array:
	var effects: Array = []
	for record in result["records"]:
		for effect in record["effects"]:
			effects.append(effect)
	return effects


func _profile_order(result: Dictionary) -> Array:
	var ids: Array = []
	for record in result["records"]:
		ids.append(String(record["profile_id"]))
	return ids


# Everything a consumer can see, for the property test: if any of this depends on
# declaration order at distinct priorities, the resolver is not deterministic.
func _observable(result: Dictionary) -> Dictionary:
	return {
		"order": _profile_order(result),
		"magnitudes": _magnitudes(result),
		"groups": result["groups"],
		"errors": result["errors"],
	}


func _permutations(values: Array) -> Array:
	if values.size() <= 1:
		return [values]
	var out: Array = []
	for index in values.size():
		var rest: Array = values.duplicate()
		var head: Variant = rest.pop_at(index)
		for tail in _permutations(rest):
			var permutation: Array = [head]
			permutation.append_array(tail as Array)
			out.append(permutation)
	return out


func _record_for(result: Dictionary, profile_id: String) -> Dictionary:
	for record in result["records"]:
		if String(record["profile_id"]) == profile_id:
			return record
	return {}


func _keys(value: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for key in value.keys():
		out.append(String(key))
	out.sort()
	return out


func _sorted(values: Array[String]) -> Array[String]:
	var out: Array[String] = values.duplicate()
	out.sort()
	return out


func _has_error(result: Dictionary, fragment: String) -> bool:
	return _has_error_text(result["errors"], fragment)


func _has_error_text(errors: Array, fragment: String) -> bool:
	for message in errors:
		if String(message).contains(fragment):
			return true
	return false


func _check(ok: bool, label: String) -> int:
	if ok:
		_passed += 1
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
