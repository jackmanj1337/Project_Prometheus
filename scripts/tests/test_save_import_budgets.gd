extends SceneTree
# Stable size/headroom gate plus non-blocking timing/memory evidence.

const Measurement = preload("res://scripts/tools/SaveBudgetMeasurement.gd")
const ImportBudgetConfig = preload("res://scripts/resources/ImportBudgets.gd")


func _init() -> void:
	var passed := 0
	var failed := 0
	var rows := Measurement.measure_all()
	for row in rows:
		print(
			(
				"MEASURE save budget %s: %d JSON bytes, parse %d usec, observed memory delta %d bytes"
				% [
					row["id"],
					row["json_bytes"],
					row["parse_usec"],
					row["observed_memory_delta_bytes"]
				]
			)
		)
		if (
			row["parsed"]
			and row["json_bytes"] < ImportBudgetConfig.portable_save_warning_bytes()
			and row["warning_headroom_bytes"] > row["json_bytes"]
		):
			print("OK  %s parses and has more than 2x headroom below warning budget" % row["id"])
			passed += 1
		else:
			print("FAIL %s measurement: %s" % [row["id"], row])
			failed += 1

	if rows.size() == 4:
		print("OK  all four representative save families were measured")
		passed += 1
	else:
		print("FAIL expected four representative save families, got %d" % rows.size())
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed else 0)
