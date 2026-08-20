extends SceneTree

const Formula = preload("res://scripts/req/FormulaEvaluator.gd")

# Fixed-point values chosen so their raw product (~8.1e25) overflows int64 well before the
# clamp would ever see it. 9e12 scaled is 9e15 = MAX_FIXED.
const HUGE := {"literal": 9000000000000.0}


func _init() -> void:
	var failed := 0
	failed += _check(
		(
			Formula.evaluate({"op": "add", "operands": [{"literal": 1.25}, {"literal": 2}]}).value
			== 3250
		),
		"fixed-point addition"
	)
	failed += _check(
		(
			(
				Formula
				. evaluate(
					{
						"op": "div",
						"operands": [{"literal": 1}, {"literal": 0}],
						"on_zero": "to_zero"
					}
				)
				. value
			)
			== 0
		),
		"division zero policy"
	)
	failed += _check(
		not (
			Formula.validate({"op": "div", "operands": [{"literal": 1}, {"literal": 0}]}).is_empty()
		),
		"div requires on_zero"
	)
	failed += _check(
		Formula.evaluate({"op": "pow", "operands": [{"literal": 0}, {"literal": 0}]}).value == 1000,
		"zero to zero is one"
	)
	failed += _check(
		(
			Formula.evaluate({"op": "and", "operands": [{"literal": true}, {"literal": 2}]}).value
			== 1000
		),
		"number booleans are canonical"
	)

	# --- Slice 5 names "clamp on overflow" in its test list; it was never written, and the
	# --- defect it would have caught made `pow` return a NEGATIVE value for a positive
	# --- base. These pin the saturation behaviour so a regression fails loudly.
	failed += _check(
		Formula.evaluate({"op": "mul", "operands": [HUGE, HUGE]}).value == Formula.MAX_FIXED,
		"mul saturates at MAX_FIXED instead of wrapping"
	)
	var cubed: Dictionary = Formula.evaluate({"op": "pow", "operands": [HUGE, {"literal": 3}]})
	failed += _check(cubed.value > 0, "pow of a positive base stays positive")
	failed += _check(cubed.value == Formula.MAX_FIXED, "pow saturates at MAX_FIXED")
	failed += _check(
		(
			Formula.evaluate({"op": "mul", "operands": [{"literal": -9000000000000.0}, HUGE]}).value
			== -Formula.MAX_FIXED
		),
		"mul saturation keeps the sign"
	)

	# --- Operator arity. Each of these used to validate clean and then throw at runtime
	# --- by indexing an empty operand list.
	for op in ["abs", "neg", "not", "truthy", "min", "max"]:
		failed += _check(
			not Formula.validate({"op": op, "operands": []}).is_empty(),
			"'%s' with no operands is a validate error" % op
		)
	failed += _check(
		not Formula.validate({"op": "sub", "operands": []}).is_empty(),
		"'sub' with no operands is a validate error"
	)

	# --- Extra operands on a binary operator were silently discarded: sub(10,3,2) == 7.0.
	var three := [{"literal": 10}, {"literal": 3}, {"literal": 2}]
	failed += _check(
		not Formula.validate({"op": "sub", "operands": three}).is_empty(),
		"'sub' rejects a third operand instead of dropping it"
	)
	failed += _check(
		not Formula.validate({"op": "div", "operands": three, "on_zero": "to_zero"}).is_empty(),
		"'div' rejects a third operand instead of dropping it"
	)
	failed += _check(
		Formula.validate({"op": "add", "operands": three}).is_empty(),
		"variadic operators still accept many operands"
	)

	# --- The remaining on_zero policies Slice 5 requires; only to_zero had coverage.
	failed += _check(
		(
			(
				Formula
				. evaluate(
					{"op": "div", "operands": [{"literal": 1}, {"literal": 0}], "on_zero": "to_max"}
				)
				. value
			)
			== Formula.MAX_FIXED
		),
		"div on_zero to_max"
	)
	failed += _check(
		(
			(
				Formula
				. evaluate(
					{
						"op": "div",
						"operands": [{"literal": 1}, {"literal": 0}],
						"on_zero": {"to_value": {"literal": 7}}
					}
				)
				. value
			)
			== 7000
		),
		"div on_zero to_value evaluates its fallback term"
	)
	# The to_value form used to THROW: _zero_result compared a Dictionary policy against a
	# String, which is a hard runtime error in GDScript, so one of the three ratified
	# REQ-16 policies crashed on every divide by zero.
	failed += _check(
		(
			(
				Formula
				. evaluate(
					{
						"op": "div",
						"operands": [{"literal": 1}, {"literal": 0}],
						"on_zero": {"to_value": {"literal": 7}}
					}
				)
				. errors
			)
			. is_empty()
		),
		"div on_zero to_value does not error"
	)
	failed += _check(
		not (
			Formula
			. validate(
				{"op": "div", "operands": [{"literal": 1}, {"literal": 2}], "on_zero": "banana"}
			)
			. is_empty()
		),
		"an unknown on_zero policy is a validate error"
	)

	# --- Rounding overrides, also named by Slice 5 and previously untested.
	failed += _check(
		(
			(
				Formula
				. evaluate(
					{
						"op": "div",
						"operands": [{"literal": 10}, {"literal": 4}],
						"on_zero": "to_zero",
						"round": "floor"
					}
				)
				. value
			)
			== 2500
		),
		"floor rounding"
	)
	print("=== Formula results: %d failed ===" % failed)
	quit(1 if failed else 0)


func _check(ok: bool, label: String) -> int:
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
