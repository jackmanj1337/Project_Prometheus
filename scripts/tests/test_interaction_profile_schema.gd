extends SceneTree
# Slice 1 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: the authored-interaction CONTRACT.
# Every assertion here is about what the schema REFUSES, because the whole value of a
# contract slice is the set of packs it will not admit. `[ITR-1..7]`.

const Schema = preload("res://scripts/interaction/InteractionProfileSchema.gd")
const RequirementSystemScript = preload("res://scripts/autoloads/RequirementSystem.gd")
const CampaignRuleSchemaScript = preload("res://scripts/save/CampaignRuleSchema.gd")

# The DEFAULT PACK, not a fixture. Slice 1 validated a hand-written migration fixture here
# because the behaviour it described was still a constant in the engine; slice 5 deleted the
# constant and authored the real thing, so this suite now checks the profiles the game
# actually ships. A fixture kept beside them would be a second triangle to keep in step.
const PACK_PATH := "res://data/campaigns/proving_grounds.json"


# Stands in for RegistryCatalog, which is built from a whole content source. The suite
# asserts below that the real catalogue still offers the method this duck-types against,
# so the stub cannot drift away from its subject unnoticed.
class StubCatalog:
	extends RefCounted

	var known: Array[String] = []

	func _init(ids: Array[String] = []) -> void:
		known = ids

	func has_entry(family: String, id: String) -> bool:
		return family == "effect_compositions" and known.has(id)


func _init() -> void:
	var failed := 0
	var requirements := RequirementSystemScript.new()
	requirements._ready()
	var catalog := (
		StubCatalog
		. new(
			[
				"combat_accuracy_modifier",
				"combat_damage_modifier",
				"combat_damage_multiplier",
				"combat_might_multiplier",
			]
		)
	)
	var deps := {"requirements": requirements, "catalog": catalog}

	# --- the shipped pack ------------------------------------------------------
	var pack: Variant = JSON.parse_string(FileAccess.get_file_as_string(PACK_PATH))
	failed += _check(pack is Dictionary, "the default pack parses")
	var rules: Variant = (pack as Dictionary).get("rules", {}) if pack else {}
	var profiles: Variant = (rules as Dictionary).get("interaction_profiles", [])
	var pack_errors := Schema.validate(profiles, deps)
	failed += _check(
		pack_errors.is_empty(),
		(
			"the default pack's authored triangle and effectiveness are admissible: %s"
			% ", ".join(pack_errors)
		)
	)

	# --- the envelope ----------------------------------------------------------
	failed += _check(
		Schema.validate({}, deps) == ["interaction_profiles must be an array"],
		"a non-array profile collection is refused"
	)
	failed += _check(
		_has_error(Schema.validate([_profile({"context": "economy"})], deps), "unknown context"),
		"a context no adapter declares is refused"
	)
	failed += _check(
		_has_error(
			Schema.validate([_profile({"subjects": ["source", "bystander"]})], deps),
			"context 'combat' does not offer"
		),
		"a subject the context does not offer is refused"
	)
	failed += _check(
		_has_error(
			Schema.validate([_profile({"stack_policy": "transform"})], deps),
			"unsupported stack_policy"
		),
		"a transform policy is refused: [ITR-5] keeps the evaluator selecting, not rewriting"
	)
	failed += _check(
		_has_error(
			Schema.validate(
				[_profile({"profile_id": "dup"}), _profile({"profile_id": "dup"})], deps
			),
			"duplicate profile_id"
		),
		"duplicate profile ids are refused, so declaration order can tie-break unambiguously"
	)
	var twin_rule := _rule({})
	failed += _check(
		_has_error(
			Schema.validate([_profile({"rules": [twin_rule, twin_rule.duplicate(true)]})], deps),
			"duplicate rule_id"
		),
		"duplicate rule ids within a profile are refused"
	)
	failed += _check(
		_has_error(
			Schema.validate([_profile({"presentation": {"colour": "red"}})], deps),
			"presentation declares unknown field"
		),
		"an unknown presentation field is refused rather than ignored"
	)
	# SLICE 6 TYPED THE PRESENTATION. Slice 1 checked only `display_order`, so every other
	# authored readout key validated clean whatever it held and became a rendering defect in
	# front of a player rather than a refusal at load.
	failed += _check(
		_has_error(
			Schema.validate([_profile({"presentation": {"glyph": 3}})], deps),
			"presentation glyph must be a string"
		),
		"a non-string presentation field is refused"
	)
	failed += _check(
		_has_error(
			Schema.validate([_profile({"presentation": {"color": "not-a-colour"}})], deps),
			"is not an HTML colour"
		),
		"an unparseable presentation colour is refused at LOAD, not silently replaced at render"
	)
	failed += _check(
		(
			Schema
			. validate(
				[
					_profile(
						{
							"presentation":
							{
								"label_key": "interaction.x",
								"glyph": "\u25b2",
								"color": "#61c454",
								"display_order": 10,
							}
						}
					)
				],
				deps
			)
			. is_empty()
		),
		"a fully authored readout validates: an HTML colour, a glyph, a label key and an order"
	)
	failed += _check(
		Schema.validate([_profile({"presentation": {"color": "crimson"}})], deps).is_empty(),
		"...and a NAMED Godot colour is accepted too, which html_is_valid alone would refuse"
	)

	# --- fails closed, never quietly ------------------------------------------
	failed += _check(
		_has_error(Schema.validate([_profile({})], {"catalog": catalog}), "no RequirementSystem"),
		"validation without a requirement evaluator is an ERROR, not an empty result"
	)
	failed += _check(
		_has_error(
			Schema.validate([_profile({})], {"requirements": requirements}), "no registry catalog"
		),
		"validation without a registry catalogue is an ERROR, not an empty result"
	)
	failed += _check(
		_has_error(
			Schema.validate(
				[_profile({"rules": [_rule({"effects": [_effect({"composition_id": "nope"})]})]})],
				deps
			),
			"unknown effect composition 'nope'"
		),
		"an effect composition no registry admits is refused"
	)
	failed += _check(
		_has_error(
			Schema.validate(
				[
					_profile(
						{
							"rules":
							[
								_rule(
									{
										"when":
										{"predicate_id": "vibes", "subject": {"kind": "source"}}
									}
								)
							]
						}
					)
				],
				deps
			),
			"unknown predicate_id"
		),
		"an unknown predicate surfaces through RequirementSystem, not a second selector language"
	)
	failed += _check(
		_has_error(
			Schema.validate(
				[
					_profile(
						{
							"subjects": ["source"],
							"rules":
							[
								_rule(
									{
										"when":
										{
											"predicate_id": "has_trait",
											"subject": {"kind": "target"},
											"params": {"id": "axe"}
										},
										"effects": [_effect({"target": "source"})]
									}
								)
							]
						}
					)
				],
				deps
			),
			"reads unbound subject 'target'"
		),
		"a rule reading a subject its profile never bound is refused"
	)
	failed += _check(
		_has_error(
			Schema.validate(
				[_profile({"rules": [_rule({"effects": [_effect({"target": "foe"})]})]})], deps
			),
			"targets unbound subject 'foe'"
		),
		"an effect aimed at an unbound subject is refused"
	)
	failed += _check(
		_has_error(
			Schema.validate([_profile({"rules": [_rule({"effects": []})]})], deps),
			"must emit at least one effect"
		),
		"a rule that emits nothing is refused"
	)

	# --- arithmetic is the shared value-term grammar ---------------------------
	failed += _check(
		_has_error(
			Schema.validate(
				[
					_profile(
						{"rules": [_rule({"effects": [_effect({"magnitude": {"op": "sqrt"}})]})]}
					)
				],
				deps
			),
			"unknown operator"
		),
		"a magnitude term reaches FormulaEvaluator instead of a bespoke scaler"
	)
	var deep_term: Dictionary = {"literal": 1}
	for _i in 4:
		deep_term = {"op": "neg", "operands": [deep_term]}
	var deep := [_profile({"rules": [_rule({"effects": [_effect({"magnitude": deep_term})]})]})]
	var rules_resource := CampaignRules.new()
	rules_resource.value_term_depth_budget = 2
	var budget_deps := deps.duplicate()
	budget_deps["rules"] = rules_resource
	failed += _check(
		(
			_has_error(Schema.validate(deep, budget_deps), "depth budget")
			and Schema.validate(deep, deps).is_empty()
		),
		"a pack-lowered value-term budget applies here too, rather than a third budget"
	)

	# --- suppression ----------------------------------------------------------
	failed += _check(
		_has_error(
			Schema.validate([_profile({"rules": [_rule({"suppresses": ["ghosts"]})]})], deps),
			"suppresses unknown stack_group 'ghosts'"
		),
		"suppressing a group nobody declares is refused"
	)
	var forward := [
		_profile({"profile_id": "a", "rules": [_rule({"suppresses": ["later_group"]})]}),
		_profile({"profile_id": "b", "stack_group": "later_group"}),
	]
	failed += _check(
		Schema.validate(forward, deps).is_empty(),
		"a rule may suppress a group declared by a later profile: order tie-breaks, it does not gate validity"
	)

	# --- the result contract [ITR-6] ------------------------------------------
	for field in [
		"matched_rules",
		"suppressed_rules",
		"predicate_trace",
		"formula_results",
		"effects",
		# Added by slice 6: the authored readout travels with the record, so a consumer
		# rendering it never has to re-open the pack to find the label for what it resolved.
		"presentation",
	]:
		failed += _check(
			Schema.RESULT_FIELDS.has(field),
			"the provenance record slice 2 must return names '%s'" % field
		)

	# --- the seams this contract duck-types against ---------------------------
	var catalog_source := FileAccess.get_file_as_string(
		"res://scripts/registries/RegistryCatalog.gd"
	)
	failed += _check(
		catalog_source.contains("func has_entry(family: String, id: String) -> bool:"),
		"RegistryCatalog still offers the has_entry the validator and its stub rely on"
	)

	# --- the save seam --------------------------------------------------------
	var normalized := CampaignRuleSchemaScript.normalize(
		{"interaction_profiles": [{"profile_id": "kept"}, "damaged", 7]}
	)
	failed += _check(
		(
			normalized["interaction_profiles"].size() == 1
			and normalized["interaction_profiles"][0]["profile_id"] == "kept"
		),
		"a damaged save drops non-object profiles instead of carrying them into a run"
	)
	failed += _check(
		CampaignRuleSchemaScript.defaults()["interaction_profiles"] == [],
		"a pack that authors no interactions defaults to none, not to an engine table"
	)
	var round_trip := CampaignRules.new()
	CampaignRuleSchemaScript.apply_to_resource(round_trip, {"interaction_profiles": profiles})
	failed += _check(
		round_trip.interaction_profiles.size() == (profiles as Array).size(),
		"authored profiles survive the CampaignRules round trip"
	)

	print("=== Interaction Profile Schema Results: %d failed ===" % failed)
	quit(1 if failed else 0)


# Builds a minimal admissible profile, with `overrides` replacing individual keys. Tests
# state only the field under test, so a new required field fails every case loudly rather
# than one case obscurely.
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
		"when": {"predicate_id": "has_trait", "subject": {"kind": "source"}, "params": {"id": "x"}},
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


func _has_error(errors: Array, fragment: String) -> bool:
	for message in errors:
		if String(message).contains(fragment):
			return true
	return false


func _check(ok: bool, label: String) -> int:
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
