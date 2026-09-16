class_name InteractionProfileSchema
extends RefCounted
# adopter-todo: AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10
# Contract and validation for authored trait interactions — slice 1 of
# AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10. THERE IS NO EVALUATOR HERE: this file
# decides what an authored profile may say and refuses everything else. The resolver
# that reads a validated profile is slice 2 (`InteractionRuleResolver`), and the
# combat adapter that binds subjects for it is slice 5.
#
# Authority: the `[ITR-1..7]` rulings and the seven-slice plan they cite. Resolve both
# through `GDD_Feature_Index.md` rather than by path — the documents they live in are
# dated and movable, this contract is not.
#
# SHAPE. `CampaignRules.interaction_profiles` is an ORDERED array of profiles:
#
#   {
#     "profile_id":   unique, non-empty
#     "context":      a context id this engine declares (see ENGINE_CONTEXTS)
#     "subjects":     the subject keys the profile binds, a subset of its context's
#     "priority":     int; higher runs first (slice 3 owns the ordering itself)
#     "stack_group":  the named group whose policy composes simultaneous matches
#     "stack_policy": one of STACK_POLICIES
#     "stops_below":  bool; explicitly stop lower-priority groups   `[ITR-4]`
#     "presentation": optional authored readout, consumed in slice 6   `[ITR-6]`
#     "rules":        ordered array of rules
#   }
#
# and a rule is:
#
#   {
#     "rule_id":    unique within its profile
#     "when":       a RequirementSystem tree — the SOLE selector language `[ITR-2]`
#     "suppresses": stack_group ids this rule suppresses          `[ITR-4]`/`[ITR-5]`
#     "effects":    array of {composition_id, target, params, magnitude?}
#   }
#
# WHY NO SECOND VOCABULARY. `[ITR-2]` and `[ITR-7]` put selection in
# `RequirementSystem`, arithmetic in value terms (`FormulaEvaluator`), and mutation in
# registered effect compositions. So this validator OWNS almost no grammar of its own:
# it checks the profile envelope and then hands `when` to RequirementSystem and
# `magnitude` to FormulaEvaluator. A trait-specific mini-language here is the failure
# this slice exists to prevent.
#
# WHY CONTEXTS ARE ENGINE-DECLARED AND SUBJECTS ARE NOT INVENTED. `[ITR-1]` makes the
# resolver context-agnostic but leaves legal contexts, phases and targets with the
# DOMAIN ADAPTER (`[ITR-7]`). A pack that could name its own context would be naming a
# call site no adapter calls — authored data that silently never runs. Unknown context
# is therefore an error, and a profile may only bind subjects its context offers.
#
# WHY VALIDATION REFUSES WITHOUT A REQUIREMENT EVALUATOR. Predicates cannot be checked
# without the registry that owns them, and "no evaluator supplied" must not read as
# "no errors found" — that is how a pack with unknown predicates activates clean. A
# missing evaluator is an error in its own right; see `validate`.
#
# BUDGETS ARE BORROWED, NOT INVENTED. Nested requirement trees and value terms are
# validated under the pack's existing `requirement_*`/`value_term_*` budgets on
# CampaignRules. This slice adds no third complexity budget.

const Formula = preload("res://scripts/req/FormulaEvaluator.gd")

# Composition policies an author may name for a stack group `[ITR-4]`. They all SELECT
# or AGGREGATE matches; none transforms one, which is the whole of `[ITR-5]`'s ruling —
# reaver is expressed as a higher-priority mirrored profile that suppresses the base
# group, not as a transform policy. Adding a transform here reopens that ruling.
const STACK_POLICIES: Array[String] = ["first", "highest", "lowest", "sum", "multiply", "all"]

# Contexts the engine declares, with the subjects each offers. Combat is the only
# adapter slice 5 builds; movement and economy join by adding their entry here beside
# the adapter that calls the resolver, not by a pack naming a new context.
const ENGINE_CONTEXTS := {
	"combat": {"subjects": ["source", "target", "equipped_source"]},
}

# The provenance record slice 2 returns and every consumer reads `[ITR-6]`. Declared
# here, with the contract, so "one truth for consumers" is a checked fact before the
# resolver exists rather than a claim made after it. `test_interaction_profile_schema`
# asserts this list; slice 2 populates it and slices 4/6 consume it.
const RESULT_FIELDS: Array[String] = [
	"profile_id",
	"context",
	"subjects",
	"matched_rules",
	"suppressed_rules",
	"predicate_trace",
	"formula_results",
	"effects",
	"stack_group",
	"stack_policy",
]

# Optional authored readout keys `[ITR-6]`. Anything a profile omits renders generically
# from the provenance record, so this is an allow-list of what MAY be declared, never a
# set of required fields.
const PRESENTATION_FIELDS: Array[String] = ["label_key", "glyph", "color", "display_order"]


# Returns a flat error list, empty when every profile is admissible.
#
# `deps` carries the collaborators this contract defers to:
#   "rules"        — CampaignRules, for the requirement/value-term budgets (optional)
#   "requirements" — a RequirementSystem, REQUIRED whenever any rule declares `when`
#   "catalog"      — a RegistryCatalog, required to resolve effect composition ids
#
# A missing `requirements` or `catalog` is reported rather than skipped: the pack
# activation path supplies both, and silence would turn an unverifiable pack into a
# valid one.
static func validate(profiles: Variant, deps: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	if not profiles is Array:
		return ["interaction_profiles must be an array"]
	var rules: Variant = deps.get("rules")
	var requirements: Variant = deps.get("requirements")
	var catalog: Variant = deps.get("catalog")
	var profile_ids: Dictionary = {}
	var declared_groups: Dictionary = {}
	var suppression_refs: Array[Dictionary] = []

	for index in (profiles as Array).size():
		var path := "interaction_profiles[%d]" % index
		var profile: Variant = (profiles as Array)[index]
		if not profile is Dictionary:
			errors.append("%s must be an object" % path)
			continue
		var profile_id := String((profile as Dictionary).get("profile_id", ""))
		if profile_id.strip_edges() == "":
			errors.append("%s is missing profile_id" % path)
		elif profile_ids.has(profile_id):
			errors.append("%s has duplicate profile_id '%s'" % [path, profile_id])
		else:
			profile_ids[profile_id] = true
		errors.append_array(
			_validate_profile(
				profile, path, rules, requirements, catalog, declared_groups, suppression_refs
			)
		)

	# Suppression is checked last: a rule may suppress a group declared by a LATER
	# profile, and rejecting that on declaration order would make the array's order
	# load-bearing for validity rather than only for tie-breaking.
	for reference in suppression_refs:
		var group := String(reference["group"])
		if not declared_groups.has(group):
			errors.append(
				"%s suppresses unknown stack_group '%s'" % [String(reference["path"]), group]
			)
	return errors


static func _validate_profile(
	profile: Dictionary,
	path: String,
	rules: Variant,
	requirements: Variant,
	catalog: Variant,
	declared_groups: Dictionary,
	suppression_refs: Array[Dictionary]
) -> Array[String]:
	var errors: Array[String] = []
	var context := String(profile.get("context", ""))
	var legal_subjects: Array = []
	if not ENGINE_CONTEXTS.has(context):
		errors.append("%s declares unknown context '%s'" % [path, context])
	else:
		legal_subjects = ENGINE_CONTEXTS[context]["subjects"]

	var subjects: Variant = profile.get("subjects", [])
	var bound_subjects: Array[String] = []
	if not subjects is Array or (subjects as Array).is_empty():
		errors.append("%s must bind at least one subject" % path)
	else:
		for subject in subjects as Array:
			var key := String(subject)
			if bound_subjects.has(key):
				errors.append("%s binds subject '%s' twice" % [path, key])
			elif not legal_subjects.is_empty() and not legal_subjects.has(key):
				errors.append(
					(
						"%s binds subject '%s', which context '%s' does not offer"
						% [path, key, context]
					)
				)
			else:
				bound_subjects.append(key)

	if not _is_integer(profile.get("priority", 0)):
		errors.append("%s priority must be an integer" % path)

	var stack_group := String(profile.get("stack_group", ""))
	if stack_group.strip_edges() == "":
		errors.append("%s is missing stack_group" % path)
	else:
		declared_groups[stack_group] = true

	var stack_policy := String(profile.get("stack_policy", ""))
	if stack_policy not in STACK_POLICIES:
		errors.append(
			(
				"%s has unsupported stack_policy '%s'; expected one of %s"
				% [path, stack_policy, ", ".join(STACK_POLICIES)]
			)
		)

	if profile.has("stops_below") and not profile["stops_below"] is bool:
		errors.append("%s stops_below must be a bool" % path)

	errors.append_array(_validate_presentation(profile.get("presentation"), path))

	var rule_list: Variant = profile.get("rules", [])
	if not rule_list is Array or (rule_list as Array).is_empty():
		errors.append("%s must declare at least one rule" % path)
		return errors

	var rule_ids: Dictionary = {}
	for index in (rule_list as Array).size():
		var rule_path := "%s.rules[%d]" % [path, index]
		var rule: Variant = (rule_list as Array)[index]
		if not rule is Dictionary:
			errors.append("%s must be an object" % rule_path)
			continue
		var rule_id := String((rule as Dictionary).get("rule_id", ""))
		if rule_id.strip_edges() == "":
			errors.append("%s is missing rule_id" % rule_path)
		elif rule_ids.has(rule_id):
			errors.append("%s has duplicate rule_id '%s'" % [rule_path, rule_id])
		else:
			rule_ids[rule_id] = true
		errors.append_array(
			_validate_rule(
				rule, rule_path, bound_subjects, rules, requirements, catalog, suppression_refs
			)
		)
	return errors


# JSON carries one number type, so an authored `"priority": 100` arrives as a float
# while the same value in a .tres arrives as an int. An `is int` test would therefore
# reject every integer a pack author writes in JSON and accept the identical value from
# the editor — a contract that depends on which file format the author happened to use.
# Found by the migration fixture on the first run of this suite.
static func _is_integer(value: Variant) -> bool:
	if value is int:
		return true
	# NAN and INF fail this comparison, which is the answer we want for both.
	return value is float and float(value) == floor(float(value))


static func _validate_presentation(presentation: Variant, path: String) -> Array[String]:
	var errors: Array[String] = []
	if presentation == null:
		return errors
	if not presentation is Dictionary:
		errors.append("%s presentation must be an object" % path)
		return errors
	for key in (presentation as Dictionary).keys():
		if not PRESENTATION_FIELDS.has(String(key)):
			errors.append(
				(
					"%s presentation declares unknown field '%s'; expected one of %s"
					% [path, String(key), ", ".join(PRESENTATION_FIELDS)]
				)
			)
	var order: Variant = (presentation as Dictionary).get("display_order", 0)
	if not _is_integer(order):
		errors.append("%s presentation display_order must be an integer" % path)
	return errors


static func _validate_rule(
	rule: Dictionary,
	path: String,
	bound_subjects: Array[String],
	rules: Variant,
	requirements: Variant,
	catalog: Variant,
	suppression_refs: Array[Dictionary]
) -> Array[String]:
	var errors: Array[String] = []

	var when: Variant = rule.get("when")
	if when == null:
		errors.append("%s is missing a when clause" % path)
	elif not when is Dictionary:
		errors.append("%s when must be a requirement object" % path)
	elif requirements == null or not requirements.has_method("validate"):
		# Refusing beats skipping: an unchecked predicate set is exactly the thing this
		# contract exists to reject.
		errors.append("%s when cannot be validated: no RequirementSystem was supplied" % path)
	else:
		for message in requirements.validate(when, rules):
			errors.append("%s when %s" % [path, String(message)])
	if when is Dictionary:
		errors.append_array(_validate_subject_bindings(when, path, bound_subjects))

	var suppresses: Variant = rule.get("suppresses", [])
	if not suppresses is Array:
		errors.append("%s suppresses must be an array of stack_group ids" % path)
	else:
		for group in suppresses as Array:
			var group_id := String(group)
			if group_id.strip_edges() == "":
				errors.append("%s suppresses an empty stack_group id" % path)
			else:
				suppression_refs.append({"path": path, "group": group_id})

	var effects: Variant = rule.get("effects", [])
	if not effects is Array or (effects as Array).is_empty():
		errors.append("%s must emit at least one effect" % path)
		return errors
	for index in (effects as Array).size():
		errors.append_array(
			_validate_effect(
				(effects as Array)[index],
				"%s.effects[%d]" % [path, index],
				bound_subjects,
				rules,
				catalog
			)
		)
	return errors


# RequirementSystem resolves a node's subject by looking `subject.kind` up as a KEY in
# the evaluation context (`_subject`), so a subject a profile never bound is a lookup
# that silently returns null and a predicate that is quietly always false. Refusing it
# here is what makes "profiles declare which subject bindings they accept" `[ITR-1]`
# mean something. `named_unit` is exempt: it addresses a unit by id out of the roster
# rather than through a bound subject.
static func _validate_subject_bindings(
	when: Dictionary, path: String, bound_subjects: Array[String]
) -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	var stack: Array[Dictionary] = [when]
	# The tree is depth-bounded by RequirementSystem's own budgets; this cap only stops
	# a cyclic or absurd document from spinning here before that check has run.
	var visits := 0
	while not stack.is_empty() and visits < 512:
		visits += 1
		var node: Dictionary = stack.pop_back()
		var subject: Variant = node.get("subject")
		if subject is Dictionary:
			var kind := String((subject as Dictionary).get("kind", ""))
			if kind != "" and kind != "named_unit" and not bound_subjects.has(kind):
				if not seen.has(kind):
					seen[kind] = true
					errors.append("%s when reads unbound subject '%s'" % [path, kind])
		var children: Variant = node.get("children", [])
		if children is Array:
			for child in children as Array:
				if child is Dictionary:
					stack.append(child)
	return errors


static func _validate_effect(
	effect: Variant, path: String, bound_subjects: Array[String], rules: Variant, catalog: Variant
) -> Array[String]:
	var errors: Array[String] = []
	if not effect is Dictionary:
		return ["%s must be an object" % path]

	var composition_id := String((effect as Dictionary).get("composition_id", ""))
	if composition_id.strip_edges() == "":
		errors.append("%s is missing composition_id" % path)
	elif catalog == null or not catalog.has_method("has_entry"):
		errors.append(
			"%s composition_id cannot be resolved: no registry catalog was supplied" % path
		)
	elif not catalog.has_entry("effect_compositions", composition_id):
		errors.append("%s references unknown effect composition '%s'" % [path, composition_id])

	var target := String((effect as Dictionary).get("target", ""))
	if target.strip_edges() == "":
		errors.append("%s is missing target" % path)
	elif not bound_subjects.has(target):
		errors.append("%s targets unbound subject '%s'" % [path, target])

	if (effect as Dictionary).has("params") and not (effect as Dictionary)["params"] is Dictionary:
		errors.append("%s params must be an object" % path)

	# Magnitude is a shared value term, never a stat-name switch or a bespoke scaler
	# `[ITR-3]`. Literals are expressed as value terms too, so there is one grammar.
	if (effect as Dictionary).has("magnitude"):
		var magnitude: Variant = (effect as Dictionary)["magnitude"]
		if not magnitude is Dictionary:
			errors.append("%s magnitude must be a value term" % path)
		else:
			var depth: int = rules.value_term_depth_budget if rules != null else 16
			var nodes: int = rules.value_term_node_budget if rules != null else 128
			for message in Formula.validate(magnitude, depth, nodes):
				errors.append("%s magnitude %s" % [path, String(message)])
	return errors
