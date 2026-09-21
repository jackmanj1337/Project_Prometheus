class_name InteractionRuleResolver
extends RefCounted
# The resolver for authored trait interactions — slices 2 and 3 of
# AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10. It reads validated profiles, evaluates their
# `when` trees through RequirementSystem, COMPOSES the matches under the authored
# priority/stacking rules, and returns the provenance the `[ITR-6]` record declares.
# `[ITR-1..7]`.
#
# IT MUTATES NOTHING. No transaction, no unit, no registry, no autoload lookup: effects
# come back as inert payloads naming a composition and a target, and something else
# executes them. That is the whole point of the slice — a resolver that could apply an
# effect would be a resolver nobody can call twice (preview, AI, execution) and `[ITR-6]`
# needs exactly that. `resolve()` is static and reads only its arguments.
#
# WHAT SLICE 3 ADDED, and the one contract change it forced:
#   - RESOLUTION ORDER is `priority` descending, then DECLARATION ORDER. Godot's
#     `sort_custom` is not documented as stable, so declaration order is compared
#     explicitly rather than relied on.
#   - STACK POLICIES are applied. `first|highest|lowest|sum|multiply|all` compose the
#     contributions of every profile in a group.
#   - `stops_below` is applied: a matched profile that declares it removes every match
#     from every profile of strictly lower priority.
#   - THE CONTRACT CHANGE: `resolve()` now returns `{context, records, groups, effects,
#     errors}`. A summed or multiplied magnitude is the GROUP's, not any one profile's, so
#     the flat composed `effects` list at the envelope is what a consumer executes.
#     `records[i]["effects"]` still means "what applies FROM THIS PROFILE" and the two
#     agree by construction — the envelope list is the records' lists concatenated in
#     resolution order, never a second computation of the same thing.
#
# WHAT THIS SLICE STILL DOES NOT DO, so the next one is not surprised:
#   - slice 4 owns the EFFECT BRIDGE. Composition ids are copied through unresolved; the
#     registry catalogue is not consulted and is not even a dependency here. It also owns
#     the conversion out of fixed point, at the effect boundary, once.
#   - slice 5 owns the COMBAT ADAPTER — the thing that binds `source`/`target`/
#     `equipped_source`/`equipped_target` from a live exchange and calls this.
#
# WHY IT DOES NOT RE-VALIDATE. `InteractionProfileSchema.validate()` is an activation-time
# check over a whole pack; running it per exchange would pay for a whole-pack walk on
# every hit. The resolver instead guards the handful of mismatches that would otherwise
# resolve SILENTLY — an unknown context, a subject the profile binds but the caller never
# supplied, a predicate that errors, a stack group with two policies — and reports each
# one rather than returning a clean empty result. An unresolvable profile must never read
# as "no interaction applies".
#
# WHY ERRORS RIDE BESIDE THE RECORDS. `RESULT_FIELDS` is the per-profile record and has no
# room for "this profile could not be read at all". A caller that ignores `errors`
# therefore gets fewer records, never a wrong one.
#
# MAGNITUDES ARE FIXED-POINT. `FormulaEvaluator` works in units of `SCALE` (1000), so an
# authored magnitude of 3 arrives here as 3000. Every key carrying one is named
# `*_fixed` for that reason: a consumer that reads a bare `magnitude` and applies 3000×
# damage is the defect this naming exists to prevent. `sum` and `multiply` compose through
# `FormulaEvaluator`'s own saturating helpers, so a policy and an authored `add`/`mul`
# produce the same number rather than two roundings of it.

const Formula = preload("res://scripts/req/FormulaEvaluator.gd")
const Schema = preload("res://scripts/interaction/InteractionProfileSchema.gd")

# Why a dropped contribution says which of these it was. "My rule matched and nothing
# happened" is the single hardest thing to debug in an authored rule system, so every
# contribution that does not apply carries the reason it did not.
const DROP_CONFLICT := "the group declares conflicting stack_policy"
const DROP_UNAVAILABLE := "its magnitude could not be evaluated"
const DROP_LOST := "a higher-ranked contribution won stack_policy '%s'"
const DROP_AGGREGATED := "it was aggregated into another contribution by stack_policy '%s'"


# Resolves every profile declared for `context_id` against the supplied subject bindings.
#
# `subjects` maps a subject key the context declares (`source`, `target`,
# `equipped_source`, `equipped_target` for combat) to whatever the domain adapter bound
# there — a unit node, a unit resource, a weapon, or `null`. A key bound to `null` is a
# BINDING, not a missing one: "this attacker has no equipped weapon" is a fact a predicate
# may legitimately test, while a key the caller never passed at all is an adapter that
# forgot, and those must not look alike.
#
# `deps` carries:
#   "requirements" — a RequirementSystem, REQUIRED; there is no evaluation without it
#   "rules"        — CampaignRules, for the pack's value-term budgets (optional)
#   "context"      — extra evaluation-context keys (campaign flags, units, map state)
#                    that predicates read beside the subjects (optional)
#
# Returns the `InteractionProfileSchema.ENVELOPE_FIELDS` envelope.
static func resolve(
	profiles: Variant, context_id: String, subjects: Dictionary, deps: Dictionary = {}
) -> Dictionary:
	var errors: Array[String] = []
	var records: Array[Dictionary] = []
	var no_groups: Array[Dictionary] = []

	var requirements: Variant = deps.get("requirements")
	if requirements == null or not requirements.has_method("evaluate"):
		errors.append("no RequirementSystem was supplied; no profile can be resolved")
	if not Schema.ENGINE_CONTEXTS.has(context_id):
		errors.append("unknown context '%s'" % context_id)
	if not profiles is Array:
		errors.append("interaction_profiles must be an array")
	if not errors.is_empty():
		return _envelope(context_id, records, no_groups, errors)

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
		return _envelope(context_id, records, no_groups, errors)

	for entry in _resolution_order(profiles as Array, context_id, errors):
		var record := _resolve_profile(
			entry["profile"] as Dictionary, context_id, subjects, evaluation_context, deps, errors
		)
		if record.is_empty():
			continue
		# Carried on the record only until `_apply_removals` erases them: `stops_below` is
		# a comparison between two profiles' priorities, so the pass needs both, and
		# RESULT_FIELDS has no room for either.
		record["_priority"] = int(entry["priority"])
		record["_stops_below"] = bool(entry["stops_below"])
		records.append(record)

	_apply_removals(records)
	var groups := _compose(records, errors)
	return _envelope(context_id, records, groups, errors)


static func _envelope(
	context_id: String, records: Array[Dictionary], groups: Array[Dictionary], errors: Array[String]
) -> Dictionary:
	var effects: Array[Dictionary] = []
	for record in records:
		for effect in record["effects"] as Array:
			effects.append(effect as Dictionary)
	return {
		"context": context_id,
		"records": records,
		"groups": groups,
		"effects": effects,
		"errors": errors
	}


# `[ITR-4]`: authored priority decides, and "stable declaration order" is the LAST
# tie-breaker. Declaration order is compared explicitly rather than left to the sort
# because `Array.sort_custom` is not documented as stable — relying on it would make the
# resolution order of two equal-priority profiles an implementation detail of Godot's
# sort, which is precisely the kind of silent ordering this row exists to remove.
#
# Profiles written for another context are skipped silently: a pack authors many contexts
# and only this one's are this call's business. A non-profile entry is reported.
static func _resolution_order(
	profiles: Array, context_id: String, errors: Array[String]
) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for index in profiles.size():
		var profile: Variant = profiles[index]
		if not profile is Dictionary:
			errors.append("interaction_profiles[%d] is not a profile object" % index)
			continue
		if String((profile as Dictionary).get("context", "")) != context_id:
			continue
		(
			entries
			. append(
				{
					"profile": profile,
					"declaration_index": index,
					"priority": _integer((profile as Dictionary).get("priority", 0)),
					"stops_below": bool((profile as Dictionary).get("stops_below", false)),
				}
			)
		)
	entries.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if int(a["priority"]) != int(b["priority"]):
				return int(a["priority"]) > int(b["priority"])
			return int(a["declaration_index"]) < int(b["declaration_index"])
	)
	return entries


# JSON parses every number as a float, so an authored `"priority": 100` arrives as 100.0
# while the same value from a .tres arrives as an int. Slice 1 hit this in its validator;
# the ordering has to agree with what that validator accepted.
static func _integer(value: Variant) -> int:
	if value is int:
		return int(value)
	if value is float:
		return int(floor(float(value)))
	return 0


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
	# THE VALUE SOURCES AN AUTHORED MAGNITUDE IS ALLOWED TO READ. `FormulaEvaluator`
	# resolves `{"source_id": ...}` out of `context.value_sources` and reports the source
	# "unavailable" when that key is absent -- which it always was here, so a magnitude
	# could name no source at all and a formula-scaled effect was DROPPED as unevaluable.
	# The table is RequirementSystem's, taken whole rather than copied, so a source
	# registered there is readable from an interaction without a second registration.
	var requirements: Variant = deps.get("requirements")
	if (
		requirements != null
		and requirements.has_method("value_sources")
		and not evaluation_context.has("value_sources")
	):
		evaluation_context["value_sources"] = requirements.call("value_sources")
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
		# SLICE 6. Carried verbatim and DUPLICATED, because a record is handed to consumers
		# and a consumer that edits its label would be editing the loaded pack. An absent or
		# non-object `presentation` becomes `{}`: the record's shape must not depend on
		# whether the author wrote a readout, or every reader gains a type check.
		"presentation": _presentation(profile),
	}
	# Not part of the [ITR-6] record: what this profile's matched rules suppress is an
	# input to the pass below, not provenance a consumer reads. It is removed there so the
	# record's keys stay exactly RESULT_FIELDS.
	record["_suppresses"] = suppresses
	return record


static func _presentation(profile: Dictionary) -> Dictionary:
	var declared: Variant = profile.get("presentation")
	return (declared as Dictionary).duplicate(true) if declared is Dictionary else {}


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
			# Filled by the composition pass so a payload can be executed without reading
			# back the group it came from. `composed_from` names one rule for a
			# pass-through and every contributor for an aggregate.
			"stack_group": "",
			"composed_from": [],
		}
		# An effect with no authored magnitude is not a zero — zero damage and "the
		# composition supplies its own amount" are different statements. It carries the
		# fixed-point representation of 1, the identity for the multiply policy, and
		# slice 4 decides what a composition does with it.
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


# The two ways one match removes another: SUPPRESSION by group name `[ITR-4]`/`[ITR-5]`,
# and `stops_below` by priority `[ITR-4]`. Both are collected from the whole matched set
# BEFORE either is applied, so neither outcome depends on the order profiles were read:
# two profiles suppressing each other cancel both rather than the earlier one winning.
# Declaration order is only ever the final tie-breaker for ORDER, never for validity.
#
# A rule does not suppress its own profile. A profile whose group it suppresses would
# erase the very match that did the suppressing, which is a paradox, not an authored
# intent; reaver — the case `[ITR-5]` ruled on — suppresses the OTHER profile's group.
#
# `stops_below` stops STRICTLY lower priorities, which is also what makes it self-
# consistent: a stopper that is itself stopped can only have stopped things below its own
# priority, and those are below its stopper's priority too, so collecting before applying
# changes no outcome here — it just keeps the rule the same one suppression follows.
#
# Removed effects are dropped from the record rather than flagged in place: `effects`
# means "what applies", and a consumer that has to filter it is a consumer that will
# forget to. What was removed, by whom, and under which of the two rules stays in
# `suppressed_rules`.
static func _apply_removals(records: Array[Dictionary]) -> void:
	var suppressors: Array[Dictionary] = []
	var stoppers: Array[Dictionary] = []
	for record in records:
		for entry in record["_suppresses"] as Array:
			(
				suppressors
				. append(
					{
						"profile_id": record["profile_id"],
						"rule_id": entry["rule_id"],
						"stack_group": entry["stack_group"],
						"priority": int(record["_priority"]),
					}
				)
			)
		if bool(record["_stops_below"]) and not (record["matched_rules"] as Array).is_empty():
			stoppers.append(
				{"profile_id": record["profile_id"], "priority": int(record["_priority"])}
			)

	for record in records:
		var priority := int(record["_priority"])
		record.erase("_suppresses")
		record.erase("_priority")
		record.erase("_stops_below")
		var by: Array[Dictionary] = []
		for suppressor in suppressors:
			if (
				String(suppressor["stack_group"]) == String(record["stack_group"])
				and String(suppressor["profile_id"]) != String(record["profile_id"])
			):
				(
					by
					. append(
						{
							"profile_id": String(suppressor["profile_id"]),
							"rule_id": String(suppressor["rule_id"]),
							"reason": "suppresses",
							"priority": int(suppressor["priority"]),
						}
					)
				)
		for stopper in stoppers:
			if int(stopper["priority"]) > priority:
				# A stop is a PROFILE-level act — `stops_below` is a profile field, and the
				# profile stops lower priorities because it matched at all — so no single
				# rule owns it and `rule_id` is deliberately empty. The keys stay the same
				# as a suppression's so a consumer reads one shape, not two.
				(
					by
					. append(
						{
							"profile_id": String(stopper["profile_id"]),
							"rule_id": "",
							"reason": "stops_below",
							"priority": int(stopper["priority"]),
						}
					)
				)
		if by.is_empty():
			continue
		var suppressed: Array[Dictionary] = []
		for rule_id in record["matched_rules"] as Array:
			(
				suppressed
				. append(
					{
						"rule_id": String(rule_id),
						"stack_group": String(record["stack_group"]),
						"by": by.duplicate(),
					}
				)
			)
		var no_rules: Array[String] = []
		var no_effects: Array[Dictionary] = []
		var no_formulas: Array[Dictionary] = []
		record["suppressed_rules"] = suppressed
		record["matched_rules"] = no_rules
		record["effects"] = no_effects
		record["formula_results"] = no_formulas


# `[ITR-4]`: the authored stack policy composes simultaneous matches. This is the pass
# that makes `stack_policy` mean something rather than be echoed.
#
# WHAT COMPETES. A policy composes contributions within one stack group and within one
# SLOT — the same composition id, on the same target subject, with the same params. Two
# contributions with different params are not two answers to one question: their params
# are what a composition reads, so summing their magnitudes would produce a payload whose
# params describe one of them and whose number describes both. Different params, different
# slot, both apply.
#
# UNAVAILABLE MAGNITUDES. `all` is the only policy that does not read a magnitude, so it
# is the only one that passes an unavailable contribution through for slice 4 to rule on.
# Every other policy either compares or combines numbers, and a number that could not be
# evaluated is not a small number — it is an absent one. Those contributions are dropped
# with a reason and were already reported as errors by the magnitude evaluation above.
#
# AGGREGATES ARE ATTRIBUTED, NOT INVENTED. `sum` and `multiply` produce one payload, and it
# is carried by the leading contribution — highest priority, then declaration order — with
# `composed_from` naming every contributor. There is no synthetic record for an aggregate:
# a payload nobody authored is a payload nobody can find in the pack.
static func _compose(records: Array[Dictionary], errors: Array[String]) -> Array[Dictionary]:
	var group_order: Array[String] = []
	var declared_policies: Dictionary = {}
	for record in records:
		var group := String(record["stack_group"])
		if not declared_policies.has(group):
			var seen: Array[String] = []
			declared_policies[group] = seen
			group_order.append(group)
		var policy := String(record["stack_policy"])
		if not (declared_policies[group] as Array).has(policy):
			(declared_policies[group] as Array).append(policy)

	var groups: Array[Dictionary] = []
	# Keyed "<record index>:<effect index>" — the payload that survived composition, which
	# may be the authored one or an aggregate carried by it. Identity is by index because a
	# Dictionary is not a dependable key.
	var kept: Dictionary = {}

	for group in group_order:
		var policies: Array = declared_policies[group]
		var conflict: bool = policies.size() > 1
		var policy := String(policies[0]) if not conflict else ""
		if conflict:
			var named: Array[String] = []
			for entry in policies:
				named.append("'%s'" % String(entry))
			(
				errors
				. append(
					(
						"stack_group '%s' is declared with conflicting stack_policy %s; one group, one policy, so nothing in it applies"
						% [group, ", ".join(named)]
					)
				)
			)
		var contributions := _contributions(records, group)
		var applied: Array[Dictionary] = []
		var dropped: Array[Dictionary] = []
		if conflict:
			for contribution in contributions:
				dropped.append(_dropped(contribution, DROP_CONFLICT))
		elif policy == "all":
			for contribution in contributions:
				_keep(
					kept, contribution, int(contribution["magnitude_fixed"]), [contribution], group
				)
				applied.append(
					_applied(contribution, int(contribution["magnitude_fixed"]), [contribution])
				)
		else:
			_compose_slots(contributions, group, policy, kept, applied, dropped)
		(
			groups
			. append(
				{
					"stack_group": group,
					"stack_policy": policy,
					"contributions": _public(contributions),
					"applied": applied,
					"dropped": dropped,
				}
			)
		)

	for record_index in records.size():
		var record: Dictionary = records[record_index]
		var surviving: Array[Dictionary] = []
		for effect_index in (record["effects"] as Array).size():
			var key := "%d:%d" % [record_index, effect_index]
			if kept.has(key):
				surviving.append(kept[key] as Dictionary)
		record["effects"] = surviving
	return groups


# Every effect a group's surviving matches offered, in resolution order.
static func _contributions(records: Array[Dictionary], group: String) -> Array[Dictionary]:
	var contributions: Array[Dictionary] = []
	for record_index in records.size():
		var record: Dictionary = records[record_index]
		if String(record["stack_group"]) != group:
			continue
		for effect_index in (record["effects"] as Array).size():
			var effect: Dictionary = (record["effects"] as Array)[effect_index]
			(
				contributions
				. append(
					{
						"profile_id": String(record["profile_id"]),
						"rule_id": String(effect["rule_id"]),
						"composition_id": String(effect["composition_id"]),
						"target": String(effect["target"]),
						"magnitude_fixed": int(effect["magnitude_fixed"]),
						"available": bool(effect["available"]),
						"record_index": record_index,
						"effect_index": effect_index,
						"effect": effect,
					}
				)
			)
	return contributions


static func _compose_slots(
	contributions: Array[Dictionary],
	group: String,
	policy: String,
	kept: Dictionary,
	applied: Array[Dictionary],
	dropped: Array[Dictionary]
) -> void:
	var slot_order: Array[String] = []
	var slots: Dictionary = {}
	for contribution in contributions:
		if not bool(contribution["available"]):
			dropped.append(_dropped(contribution, DROP_UNAVAILABLE))
			continue
		var key := _slot_key(contribution)
		if not slots.has(key):
			var bucket: Array[Dictionary] = []
			slots[key] = bucket
			slot_order.append(key)
		(slots[key] as Array[Dictionary]).append(contribution)

	for key in slot_order:
		var slot: Array[Dictionary] = slots[key]
		var leader: Dictionary = slot[0]
		var magnitude := int(leader["magnitude_fixed"])
		var contributors: Array[Dictionary] = [leader]
		match policy:
			"first":
				pass
			"highest", "lowest":
				for contribution in slot:
					var value := int(contribution["magnitude_fixed"])
					# Strict comparison keeps the FIRST contribution in resolution order on
					# a tie, which is the declared tie-breaker rather than an accident.
					var wins: bool = value > magnitude if policy == "highest" else value < magnitude
					if wins:
						magnitude = value
						leader = contribution
				contributors = [leader]
			"sum":
				contributors = slot.duplicate()
				for index in range(1, slot.size()):
					magnitude = Formula.add_fixed(magnitude, int(slot[index]["magnitude_fixed"]))
			"multiply":
				contributors = slot.duplicate()
				for index in range(1, slot.size()):
					magnitude = Formula.multiply_fixed(
						magnitude, int(slot[index]["magnitude_fixed"])
					)
		# `highest`/`lowest` are the only policies that move the carrier off the leading
		# contribution; `sum` and `multiply` deliberately keep it there so an aggregate is
		# attributed to the match a reader can find first in the authored data.
		var carrier: Dictionary = leader
		_keep(kept, carrier, magnitude, contributors, group)
		applied.append(_applied(carrier, magnitude, contributors))
		var reason := (
			DROP_AGGREGATED % policy
			if policy == "sum" or policy == "multiply"
			else DROP_LOST % policy
		)
		for contribution in slot:
			if (
				int(contribution["record_index"]) == int(carrier["record_index"])
				and int(contribution["effect_index"]) == int(carrier["effect_index"])
			):
				continue
			dropped.append(_dropped(contribution, reason))


# A slot is "the same effect, on the same subject, with the same parameters". `params` is
# part of the identity because it is what the composition reads; `JSON.stringify` sorts
# keys, so two authors writing the same parameters in a different order land in one slot.
static func _slot_key(contribution: Dictionary) -> String:
	return (
		"%s|%s|%s"
		% [
			String(contribution["composition_id"]),
			String(contribution["target"]),
			JSON.stringify((contribution["effect"] as Dictionary).get("params", {}))
		]
	)


static func _keep(
	kept: Dictionary,
	carrier: Dictionary,
	magnitude: int,
	contributors: Array[Dictionary],
	group: String
) -> void:
	var payload: Dictionary = (carrier["effect"] as Dictionary).duplicate()
	payload["magnitude_fixed"] = magnitude
	payload["stack_group"] = group
	payload["composed_from"] = _named(contributors)
	kept["%d:%d" % [int(carrier["record_index"]), int(carrier["effect_index"])]] = payload


static func _applied(
	carrier: Dictionary, magnitude: int, contributors: Array[Dictionary]
) -> Dictionary:
	return {
		"profile_id": String(carrier["profile_id"]),
		"rule_id": String(carrier["rule_id"]),
		"composition_id": String(carrier["composition_id"]),
		"target": String(carrier["target"]),
		"magnitude_fixed": magnitude,
		"composed_from": _named(contributors),
	}


static func _dropped(contribution: Dictionary, reason: String) -> Dictionary:
	return {
		"profile_id": String(contribution["profile_id"]),
		"rule_id": String(contribution["rule_id"]),
		"composition_id": String(contribution["composition_id"]),
		"target": String(contribution["target"]),
		"magnitude_fixed": int(contribution["magnitude_fixed"]),
		"reason": reason,
	}


static func _named(contributors: Array[Dictionary]) -> Array[Dictionary]:
	var named: Array[Dictionary] = []
	for contribution in contributors:
		(
			named
			. append(
				{
					"profile_id": String(contribution["profile_id"]),
					"rule_id": String(contribution["rule_id"]),
				}
			)
		)
	return named


# The group record carries contributions without the resolver's own bookkeeping: the
# record/effect indices and the payload reference are how this pass finds its way back to
# a record, not provenance a consumer should read.
static func _public(contributions: Array[Dictionary]) -> Array[Dictionary]:
	var public: Array[Dictionary] = []
	for contribution in contributions:
		(
			public
			. append(
				{
					"profile_id": String(contribution["profile_id"]),
					"rule_id": String(contribution["rule_id"]),
					"composition_id": String(contribution["composition_id"]),
					"target": String(contribution["target"]),
					"magnitude_fixed": int(contribution["magnitude_fixed"]),
					"available": bool(contribution["available"]),
				}
			)
		)
	return public


static func _string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for entry in value as Array:
			out.append(String(entry))
	return out
