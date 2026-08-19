extends SceneTree

const Formula = preload("res://scripts/req/FormulaEvaluator.gd")


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
	print("=== Formula results: %d failed ===" % failed)
	quit(1 if failed else 0)


func _check(ok: bool, label: String) -> int:
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
