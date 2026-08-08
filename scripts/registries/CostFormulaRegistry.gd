class_name CostFormulaRegistry
extends RefCounted

const DESCRIPTORS := {
	"fixed": {"schema_version": 1, "parameters": ["amount"]},
	"quantity_times_unit_price":
	{"schema_version": 1, "parameters": ["quantity_binding", "unit_price_binding"]},
}


static func evaluate(id: String, parameters: Dictionary, context: Dictionary) -> FormulaResult:
	if not DESCRIPTORS.has(id):
		return FormulaResult.failure("unknown cost formula '%s'" % id)
	for key in parameters:
		if key not in DESCRIPTORS[id]["parameters"]:
			return FormulaResult.failure("cost formula '%s' has extra parameter '%s'" % [id, key])
	if id == "fixed":
		if not parameters.get("amount") is int:
			return FormulaResult.failure("fixed cost amount must be an integer")
		return FormulaResult.success(int(parameters["amount"]))
	for required in DESCRIPTORS[id]["parameters"]:
		if not parameters.has(required) or not parameters[required] is String:
			return FormulaResult.failure(
				"cost formula '%s' is missing binding '%s'" % [id, required]
			)
		var binding := str(parameters[required])
		if not context.has(binding) or not context[binding] is int:
			return FormulaResult.failure(
				"cost context binding '%s' is missing or not integer" % binding
			)
	var quantity := int(context[str(parameters["quantity_binding"])])
	var unit_price := int(context[str(parameters["unit_price_binding"])])
	if quantity < 0 or unit_price < 0 or (quantity != 0 and unit_price > 2147483647 / quantity):
		return FormulaResult.failure("cost formula result overflows its non-negative bound")
	return FormulaResult.success(quantity * unit_price)
