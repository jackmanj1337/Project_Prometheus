extends Node

## Shared, map-optional requirement evaluator. Consumers supply an immutable
## context dictionary; predicate/value-source vocabularies remain open through
## registration instead of growing consumer-specific switches.

const Formula = preload("res://scripts/req/FormulaEvaluator.gd")
# Preloaded rather than referenced as an autoload: this evaluator is constructed directly
# by tests and tools, where autoloads are not live.
const Constants = preload("res://scripts/shared/GameConstants.gd")
const MAX_DEPTH := 32
const MAX_NODES := 512

# Per-entry gate presentation. [EPUX-02] gives every gated entry this choice and
# [EPUX-04] puts the hidden-vs-disabled decision in the shell, so the value has to
# survive validation and reach the consumer inside the reason — hidden presentation
# suppresses PLAYER display, never diagnostics.
const GATE_VISIBLE_DISABLED := "visible_disabled"
const GATE_HIDDEN_UNTIL_MET := "hidden_until_met"
const GATES := [GATE_VISIBLE_DISABLED, GATE_HIDDEN_UNTIL_MET]

var _predicates: Dictionary = {}
var _value_sources: Dictionary = {}


func _ready() -> void:
	register_predicate("flag", _eval_flag, "req.flag", "req.flag.inverse")
	register_predicate(
		"campaign_var", _eval_campaign_var, "req.campaign_var", "req.campaign_var.inverse"
	)
	register_predicate("unit_is", _eval_unit_is, "req.unit_is", "req.unit_is.inverse")
	register_predicate(
		"unit_present", _eval_unit_present, "req.unit_present", "req.unit_present.inverse"
	)
	register_predicate("has_skill", _eval_has_skill, "req.has_skill", "req.has_skill.inverse")
	register_predicate("has_trait", _eval_has_trait, "req.has_trait", "req.has_trait.inverse")
	register_predicate("in_group", _eval_in_group, "req.in_group", "req.in_group.inverse")
	register_predicate("compare", _eval_compare, "req.compare", "req.compare.inverse")
	# The remaining [REQ-2] v1 vocabulary. Param shapes are the ratified ones, not
	# invented here: class_level {class_id?, op, n}, proficiency {track, op, rank},
	# stat {name, op, n}, has_item {item_id, location: held|equipped|convoy}.
	register_predicate(
		"class_level", _eval_class_level, "req.class_level", "req.class_level.inverse"
	)
	register_predicate(
		"proficiency", _eval_proficiency, "req.proficiency", "req.proficiency.inverse"
	)
	register_predicate("stat", _eval_stat, "req.stat", "req.stat.inverse")
	register_predicate("has_item", _eval_has_item, "req.has_item", "req.has_item.inverse")
	register_value_source("campaign_var", _value_campaign_var)
	register_value_source("literal_context", _value_context)


func register_predicate(
	id: String, evaluator: Callable, text_key: String, inverse_text_key: String
) -> bool:
	if id.is_empty() or not evaluator.is_valid() or _predicates.has(id):
		return false
	_predicates[id] = {
		"evaluate": evaluator, "text_key": text_key, "inverse_text_key": inverse_text_key
	}
	return true


func register_value_source(id: String, evaluator: Callable) -> bool:
	if id.is_empty() or not evaluator.is_valid() or _value_sources.has(id):
		return false
	_value_sources[id] = evaluator
	return true


func validate(definition: Dictionary, rules: CampaignRules = null) -> Array[String]:
	var errors: Array[String] = []
	var budget := rules.requirement_node_budget if rules != null else 128
	# The depth budget is pack-lowerable like the node budget, and MAX_DEPTH is the
	# ceiling neither can exceed. Recursion in _evaluate_node is bounded by THIS
	# check running first, so the two are coupled: see the Slice 5 disposition note.
	var depth_budget := mini(rules.requirement_depth_budget if rules != null else 16, MAX_DEPTH)
	var stack: Array[Dictionary] = [{"node": definition, "path": "$", "depth": 1}]
	var count := 0
	while not stack.is_empty():
		var frame: Dictionary = stack.pop_back()
		var node: Dictionary = frame.node
		count += 1
		if count > mini(budget, MAX_NODES):
			errors.append("%s exceeds requirement node budget" % frame.path)
			break
		if frame.depth > depth_budget:
			errors.append("%s exceeds requirement depth budget" % frame.path)
			continue
		errors.append_array(_presentation_errors(node, frame.path))
		var composition := String(node.get("op", ""))
		if composition in ["all", "any", "not"]:
			var children: Variant = node.get("children", [])
			# An EMPTY composition is rejected, not tolerated. `all` over no children is
			# vacuously true, so a missing or empty `children` used to validate clean and
			# then OPEN the gate — the wrong failure direction for the system that decides
			# whether content is available. `not` still takes exactly one child.
			if (
				not children is Array
				or children.is_empty()
				or (composition == "not" and children.size() != 1)
			):
				errors.append("%s has invalid %s children" % [frame.path, composition])
				continue
			for index in children.size():
				if children[index] is Dictionary:
					stack.append(
						{
							"node": children[index],
							"path": "%s.children[%d]" % [frame.path, index],
							"depth": frame.depth + 1
						}
					)
				else:
					errors.append("%s.children[%d] must be an object" % [frame.path, index])
			continue
		var predicate_id := String(node.get("predicate_id", ""))
		if not _predicates.has(predicate_id):
			errors.append("%s has unknown predicate_id '%s'" % [frame.path, predicate_id])
		if predicate_id == "compare":
			for side in ["left", "right"]:
				var term: Variant = node.get("params", {}).get(side)
				if not term is Dictionary:
					errors.append("%s.params.%s must be a value term" % [frame.path, side])
				else:
					errors.append_array(
						Formula.validate(
							term,
							rules.value_term_depth_budget if rules != null else 16,
							rules.value_term_node_budget if rules != null else 128
						)
					)
	return errors


func evaluate(definition: Dictionary, context: Dictionary = {}) -> Dictionary:
	var errors := validate(definition, context.get("campaign_rules"))
	if not errors.is_empty():
		return {"met": false, "reasons": [], "trace": [], "errors": errors}
	return _evaluate_node(definition, context, "$")


func _evaluate_node(node: Dictionary, context: Dictionary, path: String) -> Dictionary:
	var op := String(node.get("op", ""))
	if op in ["all", "any", "not"]:
		# Read through `get` so a malformed node degrades instead of throwing. validate()
		# already rejects these, but this stays reachable for direct callers.
		var children: Array = node.get("children", [])
		var results: Array[Dictionary] = []
		for index in children.size():
			results.append(
				_evaluate_node(children[index], context, "%s.children[%d]" % [path, index])
			)
		if results.is_empty():
			return {"met": false, "reasons": [], "trace": [], "errors": []}
		if op == "all":
			var reasons: Array = []
			for result in results:
				if not result.met:
					reasons.append_array(result.reasons)
			return {"met": reasons.is_empty(), "reasons": reasons, "trace": results, "errors": []}
		if op == "any":
			for result in results:
				if result.met:
					return {"met": true, "reasons": [], "trace": results, "errors": []}
			return {
				"met": false,
				"reasons": results[0].reasons if not results.is_empty() else [],
				"trace": results,
				"errors": []
			}
		var child: Dictionary = results[0]
		return {
			"met": not child.met,
			"reasons": [] if not child.met else [_reason(node.children[0], path, true)],
			"trace": results,
			"errors": []
		}
	var predicate_id := String(node.predicate_id)
	var met := bool(_predicates[predicate_id].evaluate.call(node, context))
	return {
		"met": met,
		"reasons": [] if met else [_reason(node, path, false)],
		"trace": [{"path": path, "predicate_id": predicate_id, "met": met}],
		"errors": []
	}


func render_reason(reason: Dictionary, text_db: Node = null) -> String:
	var key := String(reason.text_key)
	if text_db != null and text_db.has_method("tr_key"):
		return text_db.call("tr_key", key, reason.params)
	return key


func evaluate_objective_condition(
	condition: Resource, for_group: String, game_state: Node, registry: RefCounted
) -> Dictionary:
	# REQ-8 bridge: battle objectives keep their established registry contract
	# while callers receive the shared structured result shape.
	var met := bool(registry.call("evaluate", condition, for_group, game_state))
	return {
		"met": met,
		"reasons":
		(
			[]
			if met
			else [
				{
					"code": "objective_unmet",
					"predicate_path": "$",
					"text_key": "req.objective",
					"params": {}
				}
			]
		),
		"trace": [],
		"errors": []
	}


# Validates the optional presentation block. An unknown `gate` is an error rather than a
# silent fallback: a typo would otherwise leave an entry displayed the default way while
# its author believed it was hidden.
func _presentation_errors(node: Dictionary, path: String) -> Array[String]:
	var errors: Array[String] = []
	var presentation: Variant = node.get("presentation")
	if presentation == null:
		return errors
	if not presentation is Dictionary:
		errors.append("%s presentation must be an object" % path)
		return errors
	if presentation.has("gate") and String(presentation.gate) not in GATES:
		errors.append("%s has unknown presentation gate '%s'" % [path, String(presentation.gate)])
	return errors


# The gate an entry declares, defaulting to visible-and-disabled-with-reason.
func gate_for(node: Dictionary) -> String:
	var presentation: Variant = node.get("presentation", {})
	if not presentation is Dictionary:
		return GATE_VISIBLE_DISABLED
	var gate := String(presentation.get("gate", ""))
	return gate if gate in GATES else GATE_VISIBLE_DISABLED


func _reason(node: Dictionary, path: String, inverse: bool) -> Dictionary:
	var entry: Dictionary = _predicates[String(node.predicate_id)]
	var override_key := String(node.get("presentation", {}).get("override_text_key", ""))
	return {
		"code": "predicate_unmet",
		"predicate_path": path,
		"subject": node.get("subject", {}),
		"gate": gate_for(node),
		"text_key":
		(
			override_key
			if not override_key.is_empty()
			else entry.inverse_text_key if inverse else entry.text_key
		),
		"params": node.get("params", {}).duplicate(true)
	}


func _eval_flag(node: Dictionary, context: Dictionary) -> bool:
	var params: Dictionary = node.get("params", {})
	var flags: Dictionary = context.get(
		"map_flags" if params.get("scope") == "map" else "campaign_flags", {}
	)
	return bool(flags.get(String(params.get("name", "")), false))


func _eval_campaign_var(node: Dictionary, context: Dictionary) -> bool:
	var store: Node = context.get("campaign_vars")
	return (
		store != null
		and (
			store.call("get_var", String(node.get("params", {}).get("id", "")))
			== node.get("params", {}).get("value")
		)
	)


func _subject(node: Dictionary, context: Dictionary) -> Variant:
	var subject: Dictionary = node.get("subject", {})
	var kind := String(subject.get("kind", ""))
	if kind == "named_unit":
		return context.get("units", {}).get(String(subject.get("unit_id", "")))
	return context.get(kind)


func _unit_data(value: Variant) -> Variant:
	if value == null:
		return null
	return value.unit_data if value is Node and "unit_data" in value else value


func _eval_unit_is(node: Dictionary, context: Dictionary) -> bool:
	var unit: Variant = _unit_data(_subject(node, context))
	return unit != null and String(unit.id) == String(node.get("params", {}).get("unit_id", ""))


func _eval_unit_present(node: Dictionary, context: Dictionary) -> bool:
	return _subject(node, context) != null


func _eval_has_skill(node: Dictionary, context: Dictionary) -> bool:
	var unit: Variant = _unit_data(_subject(node, context))
	return unit != null and String(node.get("params", {}).get("id", "")) in unit.skills


func _eval_has_trait(node: Dictionary, context: Dictionary) -> bool:
	return _eval_in_group(node, context)


func _eval_in_group(node: Dictionary, context: Dictionary) -> bool:
	var unit: Variant = _unit_data(_subject(node, context))
	return unit != null and String(node.get("params", {}).get("id", "")) in unit.groups


# Shared ordering used by every [REQ-2] threshold predicate, so `op` means the same thing
# in class_level, proficiency, stat and compare.
func _compare_values(left: Variant, op: String, right: Variant) -> bool:
	match op:
		"eq":
			return left == right
		"ne":
			return left != right
		"lt":
			return left < right
		"lte":
			return left <= right
		"gt":
			return left > right
		"gte":
			return left >= right
	return false


# [REQ-2] class_level {subject, class_id?, op, n} -> UnitData.level, optionally scoped to
# a class id so "level 10 as a Myrmidon" is expressible.
func _eval_class_level(node: Dictionary, context: Dictionary) -> bool:
	var unit: Variant = _unit_data(_subject(node, context))
	if unit == null:
		return false
	var params: Dictionary = node.get("params", {})
	var class_id := String(params.get("class_id", ""))
	if not class_id.is_empty() and String(unit.class_id) != class_id:
		return false
	return _compare_values(
		int(unit.level), String(params.get("op", "gte")), int(params.get("n", 0))
	)


# [REQ-2] proficiency {subject, track, op, rank} -> weapon_rank_for_wexp over the unit's
# accumulated weapon experience. Ranks compare by their threshold, so "at least C" works.
func _eval_proficiency(node: Dictionary, context: Dictionary) -> bool:
	var unit: Variant = _unit_data(_subject(node, context))
	if unit == null:
		return false
	var params: Dictionary = node.get("params", {})
	var thresholds: Dictionary = Constants.WEXP_RANK_THRESHOLDS
	var wanted := String(params.get("rank", "E"))
	if not thresholds.has(wanted):
		return false
	var track := String(params.get("track", ""))
	var actual := Constants.weapon_rank_for_wexp(int(unit.weapon_wexp.get(track, 0)))
	return _compare_values(
		int(thresholds[actual]), String(params.get("op", "gte")), int(thresholds[wanted])
	)


# [REQ-2] stat {subject, name, op, n}. Prefers Unit.get_effective_stat so modifiers and
# pair-up bonuses are included; falls back to the raw UnitData field when the subject is
# bare data rather than a placed unit.
func _eval_stat(node: Dictionary, context: Dictionary) -> bool:
	var subject: Variant = _subject(node, context)
	if subject == null:
		return false
	var params: Dictionary = node.get("params", {})
	var stat_name := String(params.get("name", ""))
	var value: int
	if subject is Node and subject.has_method("get_effective_stat"):
		value = int(subject.call("get_effective_stat", stat_name))
	else:
		var unit: Variant = _unit_data(subject)
		if unit == null or not stat_name in unit:
			return false
		value = int(unit.get(stat_name))
	return _compare_values(value, String(params.get("op", "gte")), int(params.get("n", 0)))


# [REQ-2] has_item {subject, item_id, location: held|equipped|convoy}. `convoy` is a party
# holding rather than a unit one, so it reads the context and needs no subject.
func _eval_has_item(node: Dictionary, context: Dictionary) -> bool:
	var params: Dictionary = node.get("params", {})
	var item_id := String(params.get("item_id", ""))
	var location := String(params.get("location", "held"))
	if item_id.is_empty():
		return false
	if location == "convoy":
		return item_id in context.get("convoy", [])
	var subject: Variant = _subject(node, context)
	if subject == null:
		return false
	if location == "equipped":
		if not (subject is Node and subject.has_method("get_equipped_weapon_entry")):
			return false
		return _entry_matches(subject.call("get_equipped_weapon_entry"), item_id)
	var unit: Variant = _unit_data(subject)
	if unit == null:
		return false
	for entry in unit.inventory:
		if _entry_matches(entry, item_id):
			return true
	return false


# An inventory entry names its content through weapon_id or item_id depending on kind.
func _entry_matches(entry: Variant, item_id: String) -> bool:
	if entry == null:
		return false
	return String(entry.item_id) == item_id or String(entry.weapon_id) == item_id


func _eval_compare(node: Dictionary, context: Dictionary) -> bool:
	var formula_context := context.duplicate(false)
	formula_context.value_sources = _value_sources
	var params: Dictionary = node.get("params", {})
	var left: Dictionary = Formula.evaluate(params.left, formula_context)
	var right: Dictionary = Formula.evaluate(params.right, formula_context)
	if not left.available or not right.available:
		return false
	return _compare_values(left.value, String(params.get("op", "eq")), right.value)


func _value_campaign_var(term: Dictionary, context: Dictionary) -> Dictionary:
	var store: Node = context.get("campaign_vars")
	if store == null:
		return {"available": false, "value": 0, "errors": ["campaign_vars unavailable"]}
	var value: Variant = store.call("get_var", String(term.get("params", {}).get("id", "")))
	if not value is int and not value is float and not value is bool:
		return {"available": false, "value": 0, "errors": ["campaign variable is not numeric"]}
	return {
		"available": true,
		"value": (1000 if value else 0) if value is bool else roundi(float(value) * 1000),
		"errors": []
	}


func _value_context(term: Dictionary, context: Dictionary) -> Variant:
	return context.get("values", {}).get(String(term.get("params", {}).get("key", "")), 0)
