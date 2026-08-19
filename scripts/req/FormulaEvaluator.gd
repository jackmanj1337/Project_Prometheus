class_name FormulaEvaluator
extends RefCounted

const SCALE := 1000
const MAX_FIXED := 9_000_000_000_000_000
const HARD_MAX_DEPTH := 32
const HARD_MAX_NODES := 512
const HARD_MAX_OPERANDS := 64
const OPERATORS := [
	"add", "sub", "mul", "div", "pow", "min", "max", "abs", "neg", "not", "and", "or", "truthy"
]


static func validate(term: Dictionary, max_depth := 16, max_nodes := 128) -> Array[String]:
	var errors: Array[String] = []
	var stack: Array[Dictionary] = [{"term": term, "path": "$", "depth": 1}]
	var nodes := 0
	while not stack.is_empty():
		var frame: Dictionary = stack.pop_back()
		var current: Dictionary = frame.term
		var path: String = frame.path
		var depth: int = frame.depth
		nodes += 1
		if nodes > mini(max_nodes, HARD_MAX_NODES):
			errors.append("%s exceeds value-term node budget" % path)
			break
		if depth > mini(max_depth, HARD_MAX_DEPTH):
			errors.append("%s exceeds value-term depth budget" % path)
			continue
		if current.has("literal"):
			if (
				current.size() != 1
				or (
					not current.literal is int
					and not current.literal is float
					and not current.literal is bool
				)
			):
				errors.append("%s literal must be a number or bool" % path)
			continue
		if current.has("source_id"):
			if String(current.source_id).is_empty():
				errors.append("%s source_id is empty" % path)
			continue
		var op := String(current.get("op", ""))
		var operands: Variant = current.get("operands", [])
		if op not in OPERATORS:
			errors.append("%s has unknown operator '%s'" % [path, op])
			continue
		if not operands is Array or operands.size() > HARD_MAX_OPERANDS:
			errors.append(
				"%s operands must be an array of at most %d terms" % [path, HARD_MAX_OPERANDS]
			)
			continue
		if op == "div" and not current.has("on_zero"):
			errors.append("%s div requires on_zero" % path)
		if op != "div" and current.has("on_zero"):
			errors.append("%s only div admits on_zero" % path)
		for index in operands.size():
			if operands[index] is Dictionary:
				stack.append(
					{
						"term": operands[index],
						"path": "%s.operands[%d]" % [path, index],
						"depth": depth + 1
					}
				)
			else:
				errors.append("%s.operands[%d] must be an object" % [path, index])
		var zero_policy: Variant = current.get("on_zero")
		if zero_policy is Dictionary and zero_policy.get("to_value") is Dictionary:
			stack.append(
				{
					"term": zero_policy.to_value,
					"path": path + ".on_zero.to_value",
					"depth": depth + 1
				}
			)
	return errors


static func evaluate(
	term: Dictionary, context: Dictionary = {}, max_depth := 16, max_nodes := 128
) -> Dictionary:
	var errors := validate(term, max_depth, max_nodes)
	if not errors.is_empty():
		return {"available": false, "value": 0, "errors": errors}
	return _evaluate_node(term, context, 0, {"remaining": mini(max_nodes, HARD_MAX_NODES)})


static func _evaluate_node(
	term: Dictionary, context: Dictionary, depth: int, budget: Dictionary
) -> Dictionary:
	budget.remaining -= 1
	if budget.remaining < 0 or depth > HARD_MAX_DEPTH:
		return _unavailable("value-term runtime budget exceeded")
	if term.has("literal"):
		if term.literal is bool:
			return _ok(SCALE if term.literal else 0)
		return _ok(_clamp(roundi(float(term.literal) * SCALE)))
	if term.has("source_id"):
		var sources: Dictionary = context.get("value_sources", {})
		var source_id := String(term.source_id)
		if not sources.has(source_id):
			return _unavailable("value source '%s' is unavailable" % source_id)
		var result: Variant = sources[source_id].call(term, context)
		if result is Dictionary:
			return result
		return _ok(_clamp(roundi(float(result) * SCALE)))
	var values: Array[int] = []
	for child in term.get("operands", []):
		var result := _evaluate_node(child, context, depth + 1, budget)
		if not result.available:
			return result
		values.append(int(result.value))
	var op := String(term.op)
	if op == "add":
		return _ok(_fold(values, 0, func(a: int, b: int) -> int: return _clamp(a + b)))
	if op == "sub":
		return _ok(values[0] if values.size() == 1 else _clamp(values[0] - values[1]))
	if op == "mul":
		return _ok(
			_fold(
				values,
				SCALE,
				func(a: int, b: int) -> int:
					return _rounded_div(a * b, SCALE, String(term.get("round", "half_up")))
			)
		)
	if op == "div":
		if values.size() < 2:
			return _unavailable("div requires two operands")
		if values[1] == 0:
			return _zero_result(term.on_zero, context, depth, budget)
		return _ok(
			_clamp(_rounded_div(values[0] * SCALE, values[1], String(term.get("round", "half_up"))))
		)
	if op == "pow":
		if values.size() < 2 or values[1] % SCALE != 0:
			return _unavailable("pow exponent must be an integer")
		var answer := SCALE
		for unused in absi(values[1] / SCALE):
			answer = _clamp(_rounded_div(answer * values[0], SCALE, "half_up"))
		if values[1] < 0:
			answer = _rounded_div(SCALE * SCALE, answer, "half_up") if answer != 0 else MAX_FIXED
		return _ok(answer)
	if op == "min":
		return _ok(values.min())
	if op == "max":
		return _ok(values.max())
	if op == "abs":
		return _ok(absi(values[0]))
	if op == "neg":
		return _ok(_clamp(-values[0]))
	if op == "not":
		return _ok(0 if _truthy(values[0]) else SCALE)
	if op == "and":
		return _ok(SCALE if values.all(_truthy) else 0)
	if op == "or":
		return _ok(SCALE if values.any(_truthy) else 0)
	if op == "truthy":
		return _ok(SCALE if _truthy(values[0]) else 0)
	return _unavailable("unsupported operator '%s'" % op)


static func _zero_result(
	policy: Variant, context: Dictionary, depth: int, budget: Dictionary
) -> Dictionary:
	if policy == "to_max":
		return _ok(MAX_FIXED)
	if policy == "to_zero":
		return _ok(0)
	if policy is Dictionary and policy.get("to_value") is Dictionary:
		return _evaluate_node(policy.to_value, context, depth + 1, budget)
	return _unavailable("invalid div on_zero policy")


static func _rounded_div(numerator: int, denominator: int, mode: String) -> int:
	if mode == "floor":
		return floori(float(numerator) / denominator)
	if mode == "ceil":
		return ceili(float(numerator) / denominator)
	var sign_value := -1 if (numerator < 0) != (denominator < 0) else 1
	return sign_value * floori(float(absi(numerator)) / absi(denominator) + 0.5)


static func _fold(values: Array[int], initial: int, callable: Callable) -> int:
	var result := initial
	for value in values:
		result = callable.call(result, value)
	return result


static func _truthy(value: int) -> bool:
	return value != 0


static func _clamp(value: int) -> int:
	return clampi(value, -MAX_FIXED, MAX_FIXED)


static func _ok(value: int) -> Dictionary:
	return {"available": true, "value": value, "errors": []}


static func _unavailable(error: String) -> Dictionary:
	return {"available": false, "value": 0, "errors": [error]}
