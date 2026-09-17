extends SceneTree
# Slice 2 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: the PURE resolver.
# Slice 1's suite is about what the contract refuses; this one is about what the resolver
# RETURNS and, just as importantly, what it refuses to return silently. The failure this
# slice can produce is not a crash — it is an authored rule that quietly never fires, so
# most of these checks assert that a mismatch surfaces as an error rather than as an empty
# result. `[ITR-1..7]`.

const Resolver = preload("res://scripts/interaction/InteractionRuleResolver.gd")
const Schema = preload("res://scripts/interaction/InteractionProfileSchema.gd")
const Formula = preload("res://scripts/req/FormulaEvaluator.gd")
const RequirementSystemScript = preload("res://scripts/autoloads/RequirementSystem.gd")

const FIXTURE_PATH := "res://scripts/tests/fixtures/interaction/physical_triangle_profiles.json"


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

	# --- a match, and the record it returns ------------------------------------
	var swordsman := StubSubject.new(["sword"])
	var axeman := StubSubject.new(["axe"])
	var subjects := {"source": swordsman, "target": axeman, "equipped_source": swordsman}
	var result := Resolver.resolve([_profile({})], "combat", subjects, deps)
	failed += _check(result["errors"].is_empty(), "a resolvable profile reports no errors")
	failed += _check(result["records"].size() == 1, "one record per profile declared here")
	var record: Dictionary = result["records"][0] if result["records"].size() == 1 else {}
	failed += _check(
		_keys(record) == _sorted(Schema.RESULT_FIELDS),
		"the record's keys are EXACTLY RESULT_FIELDS, so [ITR-6] is one shape and not a superset"
	)
	failed += _check(record.get("matched_rules", []) == ["r1"], "a met rule is named as matched")
	failed += _check(
		(
			record.get("effects", []).size() == 1
			and record["effects"][0]["composition_id"] == "combat_damage_modifier"
			and record["effects"][0]["target"] == "source"
		),
		"a matched rule's effect is returned as an inert payload"
	)
	failed += _check(
		record.get("stack_group", "") == "group_a" and record.get("stack_policy", "") == "highest",
		"the profile's group and policy are echoed for slice 3 rather than applied here"
	)
	failed += _check(
		record.get("predicate_trace", []).size() == 1 and record["predicate_trace"][0]["met"],
		"the predicate trace carries the evaluated rule"
	)

	# --- a non-match is a REPORTED non-match, not an absence -------------------
	var lancer := StubSubject.new(["lance"])
	var miss := Resolver.resolve(
		[_profile({})],
		"combat",
		{"source": lancer, "target": axeman, "equipped_source": lancer},
		deps
	)
	var miss_record: Dictionary = miss["records"][0]
	failed += _check(
		(
			miss["records"].size() == 1
			and miss_record["matched_rules"].is_empty()
			and miss_record["predicate_trace"].size() == 1
			and not miss_record["predicate_trace"][0]["met"]
			and not miss_record["predicate_trace"][0]["reasons"].is_empty()
		),
		"a profile that matched nothing still returns its trace and reasons"
	)

	# --- the migration fixture resolves ----------------------------------------
	var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	var profiles: Array = (fixture as Dictionary)["profiles"]
	var triangle := Resolver.resolve(profiles, "combat", subjects, deps)
	var triangle_record: Dictionary = _record_for(triangle, "physical_weapon_triangle")
	failed += _check(
		triangle_record.get("matched_rules", []) == ["sword_beats_axe"],
		"slice 1's migration fixture resolves: sword beats axe, and the losing rule does not fire"
	)
	failed += _check(
		(
			triangle_record.get("effects", []).size() == 2
			and int(triangle_record["effects"][0]["magnitude_fixed"]) == 10 * Formula.SCALE
			and int(triangle_record["effects"][1]["magnitude_fixed"]) == 2 * Formula.SCALE
		),
		"authored magnitudes come back in FormulaEvaluator's fixed point, named as such"
	)
	failed += _check(
		_record_for(triangle, "weapon_effectiveness").get("matched_rules", []).is_empty(),
		"a second profile in the same context is resolved independently"
	)

	# --- it mutates nothing ----------------------------------------------------
	var before := JSON.stringify(profiles)
	Resolver.resolve(profiles, "combat", subjects, deps)
	failed += _check(
		JSON.stringify(profiles) == before,
		"resolving does not write back into the authored profiles it was handed"
	)

	# --- fails closed, never quietly ------------------------------------------
	failed += _check(
		_has_error(Resolver.resolve([_profile({})], "economy", subjects, deps), "unknown context"),
		"a context no adapter declares is an error, not an empty result"
	)
	failed += _check(
		_has_error(
			Resolver.resolve([_profile({})], "combat", subjects, {}), "no RequirementSystem"
		),
		"resolving without a requirement evaluator is an ERROR, not an empty result"
	)
	var unsupplied := Resolver.resolve(
		[_profile({})], "combat", {"source": swordsman, "target": axeman}, deps
	)
	failed += _check(
		_has_error(unsupplied, "did not supply") and unsupplied["records"].is_empty(),
		"a profile binding a subject the caller never passed is reported, not read as no-match"
	)
	failed += _check(
		_has_error(
			Resolver.resolve(
				[_profile({})],
				"combat",
				{
					"source": swordsman,
					"target": axeman,
					"equipped_source": swordsman,
					"ally": axeman
				},
				deps
			),
			"caller bound subject 'ally'"
		),
		"a caller binding a subject the context does not declare is refused"
	)
	failed += _check(
		_has_error(
			Resolver.resolve(
				[_profile({})],
				"combat",
				subjects,
				{"requirements": requirements, "context": {"source": axeman}}
			),
			"bind it once"
		),
		"a subject supplied twice is refused rather than resolved by dictionary order"
	)
	var broken := _profile(
		{"rules": [_rule({"when": {"predicate_id": "vibes", "subject": {"kind": "source"}}})]}
	)
	var broken_result := Resolver.resolve([broken], "combat", subjects, deps)
	failed += _check(
		(
			_has_error(broken_result, "unknown predicate_id")
			and broken_result["records"][0]["matched_rules"].is_empty()
		),
		"a rule whose predicates cannot be evaluated is reported AND excluded, never matched"
	)

	# --- another context's profiles are skipped, not refused -------------------
	var other_context := _profile({"profile_id": "elsewhere", "context": "economy"})
	var skipped := Resolver.resolve([other_context, _profile({})], "combat", subjects, deps)
	failed += _check(
		skipped["errors"].is_empty() and skipped["records"].size() == 1,
		"a profile written for a different context is passed over silently, not reported"
	)

	# --- magnitude ------------------------------------------------------------
	var bare: Dictionary = Resolver.resolve([_profile({})], "combat", subjects, deps)["records"][0]
	failed += _check(
		(
			int(bare["effects"][0]["magnitude_fixed"]) == Formula.SCALE
			and bare["formula_results"].is_empty()
		),
		"an effect with no authored magnitude carries the identity, not a zero"
	)
	var unavailable := Resolver.resolve(
		[
			_profile(
				{"rules": [_rule({"effects": [_effect({"magnitude": {"source_id": "nowhere"}})]})]}
			)
		],
		"combat",
		subjects,
		deps
	)
	var unavailable_record: Dictionary = unavailable["records"][0]
	failed += _check(
		(
			_has_error(unavailable, "value source 'nowhere' is unavailable")
			and not unavailable_record["effects"][0]["available"]
			and unavailable_record["formula_results"].size() == 1
			and not unavailable_record["formula_results"][0]["available"]
		),
		"an unresolvable magnitude is reported and marked unavailable, not silently zero"
	)
	var rules_resource := CampaignRules.new()
	rules_resource.value_term_depth_budget = 2
	var deep_term: Dictionary = {"literal": 1}
	for _i in 4:
		deep_term = {"op": "neg", "operands": [deep_term]}
	var budgeted := Resolver.resolve(
		[_profile({"rules": [_rule({"effects": [_effect({"magnitude": deep_term})]})]})],
		"combat",
		subjects,
		{"requirements": requirements, "rules": rules_resource}
	)
	failed += _check(
		_has_error(budgeted, "depth budget"),
		"the pack's own value-term budget applies at resolve time, not just at validation"
	)

	# --- suppression [ITR-4]/[ITR-5] -------------------------------------------
	var base_profile := _profile({"profile_id": "base", "stack_group": "ga"})
	var reaver := _profile(
		{"profile_id": "reaver", "stack_group": "gb", "rules": [_rule({"suppresses": ["ga"]})]}
	)
	var suppressed := Resolver.resolve([base_profile, reaver], "combat", subjects, deps)
	var base_record: Dictionary = _record_for(suppressed, "base")
	failed += _check(
		(
			base_record["matched_rules"].is_empty()
			and base_record["suppressed_rules"].size() == 1
			and base_record["suppressed_rules"][0]["rule_id"] == "r1"
			and base_record["suppressed_rules"][0]["by"][0]["profile_id"] == "reaver"
		),
		"a suppressed match moves to suppressed_rules and names who suppressed it"
	)
	failed += _check(
		base_record["effects"].is_empty() and base_record["formula_results"].is_empty(),
		"a suppressed profile's effects are dropped: `effects` means what applies"
	)
	failed += _check(
		not _record_for(suppressed, "reaver")["matched_rules"].is_empty(),
		"the suppressing profile keeps its own match"
	)
	var reversed := Resolver.resolve([reaver, base_profile], "combat", subjects, deps)
	failed += _check(
		(
			_record_for(reversed, "base")["matched_rules"].is_empty()
			and not _record_for(reversed, "reaver")["matched_rules"].is_empty()
		),
		"suppression does not depend on declaration order: it is collected before it is applied"
	)
	var mutual_a := _profile(
		{"profile_id": "ma", "stack_group": "ga", "rules": [_rule({"suppresses": ["gb"]})]}
	)
	var mutual_b := _profile(
		{"profile_id": "mb", "stack_group": "gb", "rules": [_rule({"suppresses": ["ga"]})]}
	)
	var mutual := Resolver.resolve([mutual_a, mutual_b], "combat", subjects, deps)
	failed += _check(
		(
			_record_for(mutual, "ma")["matched_rules"].is_empty()
			and _record_for(mutual, "mb")["matched_rules"].is_empty()
		),
		"mutual suppression cancels both rather than letting the first read win"
	)
	var self_suppressing := _profile(
		{"profile_id": "solo", "stack_group": "gs", "rules": [_rule({"suppresses": ["gs"]})]}
	)
	failed += _check(
		not (
			_record_for(Resolver.resolve([self_suppressing], "combat", subjects, deps), "solo")["matched_rules"]
			. is_empty()
		),
		"a rule does not suppress its own profile, which would erase the match doing the suppressing"
	)

	print("=== Interaction Rule Resolver Results: %d failed ===" % failed)
	quit(1 if failed else 0)


# Mirrors slice 1's builders so the two suites describe the same admissible profile; only
# the field under test is stated in a case.
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


func _record_for(result: Dictionary, profile_id: String) -> Dictionary:
	for record in result["records"]:
		if String(record["profile_id"]) == profile_id:
			return record
	return {}


func _keys(record: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for key in record.keys():
		out.append(String(key))
	out.sort()
	return out


func _sorted(values: Array[String]) -> Array[String]:
	var out: Array[String] = values.duplicate()
	out.sort()
	return out


func _has_error(result: Dictionary, fragment: String) -> bool:
	for message in result["errors"]:
		if String(message).contains(fragment):
			return true
	return false


func _check(ok: bool, label: String) -> int:
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
