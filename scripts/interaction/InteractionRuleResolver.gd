class_name InteractionRuleResolver
extends RefCounted
# adopter-todo: AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10
# The PURE resolver for authored trait interactions — slice 2 of
# AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10. It reads validated profiles, evaluates their
# `when` trees through RequirementSystem, and returns the provenance record
# `InteractionProfileSchema.RESULT_FIELDS` declares. `[ITR-1..7]`.
#
# IT MUTATES NOTHING. No transaction, no unit, no registry, no autoload lookup: effects
# come back as inert payloads naming a composition and a target, and something else
# executes them. That is the whole point of the slice — a resolver that could apply an
# effect would be a resolver nobody can call twice (preview, AI, execution) and `[ITR-6]`
# needs exactly that. `resolve()` is static and reads only its arguments.
#
# WHAT THIS SLICE DOES NOT DO, so the next one is not surprised:
#   - slice 3 owns PRIORITY and STACK POLICY. Profiles are read in declaration order and
#     `stack_policy` is echoed into the record, never applied: two matching rules in one
#     group both appear, and nothing here decides that "highest" means one of them wins.
#   - slice 4 owns the EFFECT BRIDGE. Composition ids are copied through unresolved;
#     the registry catalogue is not consulted and is not even a dependency here.
#   - slice 5 owns the COMBAT ADAPTER — the thing that binds `source`/`target`/
#     `equipped_source` from a live exchange and calls this.
#
# WHY IT DOES NOT RE-VALIDATE. `InteractionProfileSchema.validate()` is an activation-time
# check over a whole pack; running it per exchange would pay for a whole-pack walk on
# every hit. The resolver instead guards the handful of mismatches that would otherwise
# resolve SILENTLY — an unknown context, a subject the profile binds but the caller never
# supplied, a predicate that errors — and reports each one rather than returning a clean
# empty result. An unresolvable profile must never read as "no interaction applies".
#
# WHY THE RETURN IS AN ENVELOPE. `RESULT_FIELDS` is the per-profile record and has no
# room for "this profile could not be read at all". Errors therefore ride beside the
# records instead of inside them, and a caller that ignores `errors` gets fewer records,
# never a wrong one.
#
# MAGNITUDES ARE FIXED-POINT. `FormulaEvaluator` works in units of `SCALE` (1000), so an
# authored magnitude of 3 arrives here as 3000. Every key carrying one is named
# `*_fixed` for that reason: a consumer that reads a bare `magnitude` and applies 3000×
# damage is the defect this naming exists to prevent. Slice 4 converts at the effect
# boundary, once.

const Formula = preload("res://scripts/req/FormulaEvaluator.gd")
const Schema = preload("res://scripts/interaction/InteractionProfileSchema.gd")


# Resolves every profile declared for `context_id` against the supplied subject bindings.
#
# `subjects` maps a subject key the context declares (`source`, `target`,
# `equipped_source` for combat) to whatever the domain adapter bound there — a unit node,
# a unit resource, a weapon, or `null`. A key bound to `null` is a BINDING, not a missing
# one: "this attacker has no equipped weapon" is a fact a predicate may legitimately test,
# while a key the caller never passed at all is an adapter that forgot, and those must not
# look alike.
#
# `deps` carries:
#   "requirements" — a RequirementSystem, REQUIRED; there is no evaluation without it
#   "rules"        — CampaignRules, for the pack's value-term budgets (optional)
#   "context"      — extra evaluation-context keys (campaign flags, units, map state)
#                    that predicates read beside the subjects (optional)
#
# Returns `{"context": String, "records": Array[Dictionary], "errors": Array[String]}`.
static func resolve(
	profiles: Variant, context_id: String, subjects: Dictionary, deps: Dictionary = {}
) -> Dictionary:
	var errors: Array[String] = []
	var records: Array[Dictionary] = []

	var requirements: Variant = deps.get("requirements")
	if requirements == null or not requirements.has_method("evaluate"):
		errors.append("no RequirementSystem was supplied; no profile can be resolved")
	if not Schema.ENGINE_CONTEXTS.has(context_id):
		errors.append("unknown context '%s'" % context_id)
	if not profiles is Array:
		errors.append("interaction_profiles must be an array")
	if not errors.is_empty():
		return _envelope(context_id, records, errors)

	var legal_subjects: Array = Schema.ENGINE_CONTEXTS[context_id]["subjects"]
	for key in subjects.keys():
		if not legal_subjects.has(String(key)):
			errors.append(
				(
					"caller bound subject '%s', which context '%s' does not offer"
					% [String(key), context_id]
				)
			)

	var evaluation_context := _evaluation_context(subjects, deps, errors)
	if not errors.is_empty():
		return _envelope(context_id, records, errors)

	for index in (profiles as Array).size():
		var profile: Variant = (profiles as Array)[index]
		if not profile is Dictionary:
			errors.append("interaction_profiles[%d] is not a profile object" % index)
			continue
		if String((profile as Dictionary).get("context", "")) != context_id:
			continue
		var record := _resolve_profile(
			profile as Dictionary, context_id, subjects, evaluation_context, deps, errors
		)
		if not record.is_empty():
			records.append(record)

	_apply_suppression(records)
	return _envelope(context_id, records, errors)


static func _envelope(
	context_id: String, records: Array[Dictionary], errors: Array[String]
) -> Dictionary:
	return {"context": context_id, "records": records, "errors": errors}


# The dictionary RequirementSystem evaluates against. Subjects are merged in as top-level
# keys because `RequirementSystem._subject` looks `subject.kind` up as a KEY of the
# evaluation context; that is the same fact slice 1's binding validation rests on.
#
# A subject key that the base context already carries is an ERROR rather than an
# overwrite: the only ways it happens are an adapter passing the same thing twice and an
# adapter passing its whole evaluation context in as `subjects`, and silently picking a
# winner between the two would decide which unit a predicate reads by dictionary order.
static func _evaluation_context(
	subjects: Dictionary, deps: Dictionary, errors: Array[String]
) -> Dictionary:
	var base: Variant = deps.get("context", {})
	if not base is Dictionary:
		errors.append("deps.context must be a dictionary of evaluation-context keys")
		return {}
	var evaluation_context: Dictionary = (base as Dictionary).duplicate()
	for key in subjects.keys():
		if evaluation_context.has(key):
			errors.append(
				"subject '%s' is also supplied by deps.context; bind it once" % String(key)
			)
		else:
			evaluation_context[key] = subjects[key]
	# Borrowed budgets, per slice 1: the pack's own requirement/value-term limits apply to
	# an interaction's trees, and RequirementSystem reads them off this key.
	var rules: Variant = deps.get("rules")
	if rules != null and not evaluation_context.has("campaign_rules"):
		evaluation_context["campaign_rules"] = rules
	return evaluation_context


# One record per profile declared for this context, whether or not anything matched: a
# profile that matched nothing still carries the predicate trace explaining why, which is
# the only thing that tells an author "my rule never fires" apart from "my rule is not
# loaded". Returns `{}` when the profile cannot be resolved at all.
static func _resolve_profile(
	profile: Dictionary,
	context_id: String,
	subjects: Dictionary,
	evaluation_context: Dictionary,
	deps: Dictionary,
	errors: Array[String]
) -> Dictionary:
	var profile_id := String(profile.get("profile_id", ""))
	var bound: Array[String] = []
	var declared: Variant = profile.get("subjects", [])
	if declared is Array:
		for subject in declared as Array:
			bound.append(String(subject))

	# Fail closed on an unsupplied binding. `RequirementSystem._subject` returns null for a
	# key the context lacks, so every predicate reading it would be quietly false and the
	# profile would report "no match" — an authored rule that never fires and never
	# complains. This is the single most likely adapter defect in slice 5.
	var missing: Array[String] = []
	for subject in bound:
		if not subjects.has(subject):
			missing.append(subject)
	if not missing.is_empty():
		errors.append(
			(
				"profile '%s' binds subject(s) %s that the caller did not supply"
				% [profile_id, ", ".join(missing)]
			)
		)
		return {}

	var matched_rules: Array[String] = []
	var predicate_trace: Array[Dictionary] = []
	var formula_results: Array[Dictionary] = []
	var effects: Array[Dictionary] = []
	var suppresses: Array[Dictionary] = []

	var rule_list: Variant = profile.get("rules", [])
	if rule_list is Array:
		for index in (rule_list as Array).size():
			var rule: Variant = (rule_list as Array)[index]
			if not rule is Dictionary:
				errors.append("profile '%s' rules[%d] is not a rule object" % [profile_id, index])
				continue
			var rule_id := String((rule as Dictionary).get("rule_id", ""))
			var when: Variant = (rule as Dictionary).get("when")
			var evaluation: Dictionary = (
				deps["requirements"].evaluate(when, evaluation_context)
				if when is Dictionary
				else {"met": false, "reasons": [], "trace": [], "errors": ["missing when clause"]}
			)
			var rule_errors: Array = evaluation.get("errors", [])
			for message in rule_errors:
				errors.append(
					"profile '%s' rule '%s' when %s" % [profile_id, rule_id, String(message)]
				)
			# A rule whose predicates could not be evaluated is NOT a rule that did not
			# match: it is reported above and excluded here, so a broken tree can never
			# read as an absent interaction.
			var met: bool = bool(evaluation.get("met", false)) and rule_errors.is_empty()
			(
				predicate_trace
				. append(
					{
						"rule_id": rule_id,
						"met": met,
						"reasons": evaluation.get("reasons", []),
						"trace": evaluation.get("trace", []),
						"errors": rule_errors,
					}
				)
			)
			if not met:
				continue
			matched_rules.append(rule_id)
			for group in _string_array((rule as Dictionary).get("suppresses", [])):
				suppresses.append({"rule_id": rule_id, "stack_group": group})
			_collect_effects(
				rule as Dictionary,
				rule_id,
				profile_id,
				evaluation_context,
				deps,
				effects,
				formula_results,
				errors
			)

	var empty_suppressed: Array[Dictionary] = []
	var record := {
		"profile_id": profile_id,
		"context": context_id,
		"subjects": bound,
		"matched_rules": matched_rules,
		"suppressed_rules": empty_suppressed,
		"predicate_trace": predicate_trace,
		"formula_results": formula_results,
		"effects": effects,
		"stack_group": String(profile.get("stack_group", "")),
		"stack_policy": String(profile.get("stack_policy", "")),
	}
	# Not part of the [ITR-6] record: what this profile's matched rules suppress is an
	# input to the pass below, not provenance a consumer reads. It is removed there so the
	# record's keys stay exactly RESULT_FIELDS.
	record["_suppresses"] = suppresses
	return record


static func _collect_effects(
	rule: Dictionary,
	rule_id: String,
	profile_id: String,
	evaluation_context: Dictionary,
	deps: Dictionary,
	effects: Array[Dictionary],
	formula_results: Array[Dictionary],
	errors: Array[String]
) -> void:
	var declared: Variant = rule.get("effects", [])
	if not declared is Array:
		return
	var rules: Variant = deps.get("rules")
	var depth: int = rules.value_term_depth_budget if rules != null else 16
	var nodes: int = rules.value_term_node_budget if rules != null else 128
	for index in (declared as Array).size():
		var effect: Variant = (declared as Array)[index]
		if not effect is Dictionary:
			errors.append(
				(
					"profile '%s' rule '%s' effects[%d] is not an effect object"
					% [profile_id, rule_id, index]
				)
			)
			continue
		var payload := {
			"rule_id": rule_id,
			"composition_id": String((effect as Dictionary).get("composition_id", "")),
			"target": String((effect as Dictionary).get("target", "")),
			"params": (effect as Dictionary).get("params", {}),
			"magnitude_fixed": Formula.SCALE,
			"available": true,
		}
		# An effect with no authored magnitude is not a zero — zero damage and "the
		# composition supplies its own amount" are different statements. It carries the
		# fixed-point representation of 1, the identity for the multiply policies slice 3
		# adds, and slice 4 decides what a composition does with it.
		if (effect as Dictionary).has("magnitude"):
			var magnitude: Variant = (effect as Dictionary)["magnitude"]
			var result: Dictionary = (
				Formula.evaluate(magnitude as Dictionary, evaluation_context, depth, nodes)
				if magnitude is Dictionary
				else {"available": false, "value": 0, "errors": ["magnitude is not a value term"]}
			)
			payload["magnitude_fixed"] = int(result.get("value", 0))
			payload["available"] = bool(result.get("available", false))
			(
				formula_results
				. append(
					{
						"rule_id": rule_id,
						"effect_index": index,
						"composition_id": payload["composition_id"],
						"available": payload["available"],
						"value_fixed": payload["magnitude_fixed"],
						"errors": result.get("errors", []),
					}
				)
			)
			for message in result.get("errors", []):
				errors.append(
					(
						"profile '%s' rule '%s' effects[%d] magnitude %s"
						% [profile_id, rule_id, index, String(message)]
					)
				)
		effects.append(payload)


# Suppression `[ITR-4]`/`[ITR-5]`. Every matched rule's suppressions are collected BEFORE
# any of them is applied, so the outcome does not depend on the order profiles were read:
# two profiles suppressing each other cancel both rather than the earlier one winning.
# That order-independence is the property slice 3 gets to property-test once priority
# exists; declaration order is only ever the final tie-breaker.
#
# A rule does not suppress its own profile. A profile whose group it suppresses would
# erase the very match that did the suppressing, which is a paradox, not an authored
# intent; reaver — the case `[ITR-5]` ruled on — suppresses the OTHER profile's group.
#
# Suppressed effects are dropped from the record rather than flagged in place: `effects`
# means "what applies", and a consumer that has to filter it is a consumer that will
# forget to. What was suppressed, and by whom, stays in `suppressed_rules`.
static func _apply_suppression(records: Array[Dictionary]) -> void:
	var suppressors: Array[Dictionary] = []
	for record in records:
		for entry in record["_suppresses"] as Array:
			(
				suppressors
				. append(
					{
						"profile_id": record["profile_id"],
						"rule_id": entry["rule_id"],
						"stack_group": entry["stack_group"],
					}
				)
			)
	for record in records:
		record.erase("_suppresses")
		var group := String(record["stack_group"])
		var by: Array[Dictionary] = []
		for suppressor in suppressors:
			if (
				String(suppressor["stack_group"]) == group
				and String(suppressor["profile_id"]) != String(record["profile_id"])
			):
				by.append(suppressor)
		if by.is_empty():
			continue
		var suppressed: Array[Dictionary] = []
		for rule_id in record["matched_rules"] as Array:
			var by_entries: Array[Dictionary] = []
			for suppressor in by:
				(
					by_entries
					. append(
						{
							"profile_id": String(suppressor["profile_id"]),
							"rule_id": String(suppressor["rule_id"]),
						}
					)
				)
			suppressed.append({"rule_id": String(rule_id), "stack_group": group, "by": by_entries})
		var no_rules: Array[String] = []
		var no_effects: Array[Dictionary] = []
		var no_formulas: Array[Dictionary] = []
		record["suppressed_rules"] = suppressed
		record["matched_rules"] = no_rules
		record["effects"] = no_effects
		record["formula_results"] = no_formulas


static func _string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for entry in value as Array:
			out.append(String(entry))
	return out
