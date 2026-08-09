class_name RangeFormulaRegistry
extends RefCounted

const StatRegistry = preload("res://scripts/core/StatRegistry.gd")

const DESCRIPTORS := {
	"literal": {"schema_version": 1, "parameters": ["value"]},
	"stat_divisor": {"schema_version": 1, "parameters": ["stat", "divisor"]},
}


static func validate(id: String, parameters: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not DESCRIPTORS.has(id):
		return ["unknown range formula '%s'" % id]
	var expected: Array = DESCRIPTORS[id]["parameters"]
	for key in parameters:
		if key not in expected:
			errors.append("range formula '%s' has extra parameter '%s'" % [id, key])
	for key in expected:
		if not parameters.has(key):
			errors.append("range formula '%s' is missing parameter '%s'" % [id, key])
	if id == "literal" and parameters.has("value") and not parameters["value"] is int:
		errors.append("range literal value must be an integer")
	if id == "stat_divisor":
		if parameters.has("stat") and not StatRegistry.is_registered_stat(str(parameters["stat"])):
			errors.append("range formula names unknown stat '%s'" % parameters["stat"])
		if (
			parameters.has("divisor")
			and (not parameters["divisor"] is int or int(parameters["divisor"]) <= 0)
		):
			errors.append("range divisor must be a positive integer")
	return errors


static func evaluate(id: String, parameters: Dictionary, stats: Dictionary) -> FormulaResult:
	var errors := validate(id, parameters)
	if not errors.is_empty():
		return FormulaResult.failure(errors[0])
	var value := 0
	if id == "literal":
		value = int(parameters["value"])
	else:
		var stat := str(parameters["stat"])
		if not stats.has(stat) or not stats[stat] is int:
			return FormulaResult.failure("range input is missing integer stat '%s'" % stat)
		value = int(stats[stat]) / int(parameters["divisor"])
	return FormulaResult.success(clampi(value, 1, 99))
