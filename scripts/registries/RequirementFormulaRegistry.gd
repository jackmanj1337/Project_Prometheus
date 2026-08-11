class_name RequirementFormulaRegistry
extends RefCounted

const MAX_DEPTH := 8


static func evaluate(definition: Dictionary, facts: Dictionary, depth := 0) -> FormulaResult:
	if depth > MAX_DEPTH:
		return FormulaResult.failure("requirement composition exceeds depth %d" % MAX_DEPTH)
	var id := str(definition.get("id", ""))
	var parameters: Dictionary = definition.get("parameters", {})
	match id:
		"always":
			return FormulaResult.success({"met": true, "reason": ""})
		"fact_equals":
			if parameters.keys().any(
				func(key: Variant) -> bool: return key not in ["fact", "value", "reason"]
			):
				return FormulaResult.failure("fact_equals has an unknown parameter")
			var fact := str(parameters.get("fact", ""))
			if fact.is_empty() or not facts.has(fact):
				return FormulaResult.failure("requirement names unknown fact '%s'" % fact)
			var met: bool = facts[fact] == parameters.get("value")
			return FormulaResult.success(
				{"met": met, "reason": "" if met else str(parameters.get("reason", "Unavailable"))}
			)
		"all":
			var children: Variant = parameters.get("requirements")
			if not children is Array:
				return FormulaResult.failure("all requirement needs a requirements array")
			for child in children:
				if not child is Dictionary:
					return FormulaResult.failure("requirement child must be a dictionary")
				var result := evaluate(child, facts, depth + 1)
				if not result.ok or not bool(result.value["met"]):
					return result
			return FormulaResult.success({"met": true, "reason": ""})
	return FormulaResult.failure("unknown requirement formula '%s'" % id)
