extends SceneTree

var passed := 0
var failed := 0


func _init() -> void:
	var two := HitFormulaRegistry.evaluate("two_roll", 50, [20, 40])
	var single := HitFormulaRegistry.evaluate("single_roll", 50, [60])
	_check(two.ok and two.value and single.ok and not single.value, "registered hit formulas")
	_check(
		(
			HitFormulaRegistry.rn_count("missing") == -1
			and not HitFormulaRegistry.evaluate("missing", 50, []).ok
		),
		"unknown hit formula fails loud"
	)
	var preview := HitFormulaRegistry.preview_probability("two_roll", 50)
	_check(preview.ok and preview.value > 0.0 and preview.value < 1.0, "hit preview is draw-free")

	var literal := RangeFormulaRegistry.evaluate("literal", {"value": 2}, {})
	var dynamic := RangeFormulaRegistry.evaluate(
		"stat_divisor", {"stat": "magic", "divisor": 2}, {"magic": 9}
	)
	_check(
		literal.ok and literal.value == 2 and dynamic.ok and dynamic.value == 4, "range formulas"
	)
	_check(
		not RangeFormulaRegistry.evaluate("stat_divisor", {"stat": "bogus", "divisor": 0}, {}).ok,
		"range validation rejects stat and divisor"
	)
	var weapon := WeaponData.new()
	weapon.range_max_formula = "MAG/2"
	var unit := Unit.new()
	unit.data = UnitData.new()
	unit.data.magic = 9
	_check(weapon.get_range_max(unit) == 4, "legacy range adapts through registry")
	weapon.range_max_formula_id = "literal"
	weapon.range_max_parameters = {"value": 3}
	_check(weapon.get_range_max(unit) == 3, "registered weapon range takes authority")
	unit.free()

	var scaled := CostFormulaRegistry.evaluate(
		"quantity_times_unit_price",
		{"quantity_binding": "quantity", "unit_price_binding": "unit_price"},
		{"quantity": 3, "unit_price": 25}
	)
	_check(scaled.ok and scaled.value == 75, "bounded cost multiplication")
	_check(
		not (
			CostFormulaRegistry
			. evaluate(
				"quantity_times_unit_price",
				{"quantity_binding": "quantity", "unit_price_binding": "unit_price"},
				{"quantity": 2147483647, "unit_price": 2}
			)
			. ok
		),
		"cost overflow rejects"
	)

	# RequirementFormulaRegistry was deleted here (REQ-LEGACY-REGISTRY-RECONCILE): it was a
	# second, weaker requirement evaluator shipped beside RequirementSystem, with no
	# production caller and only this assertion referencing it. Its coverage is NOT dropped
	# — it lives in scripts/tests/test_requirement.gd, which asserts the same obligation
	# against the surviving evaluator and more of it:
	#   :39 "structured unmet reason"    — an unmet tree reports which node failed
	#   :44 "text-key reason rendering"  — the reason renders to player-facing text
	# The legacy assertion checked a raw `reason` STRING baked into the content; the
	# successor carries a text_key rendered through TextDB, so re-adding the old form here
	# would assert the un-localizable shape the new system exists to replace.

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s" % label)
		failed += 1
