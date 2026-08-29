extends SceneTree

const RecordScreenStateS = preload("res://scripts/ui/record/RecordScreenState.gd")

var _passed := 0
var _failed := 0


func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK  " + label)
		_passed += 1
	else:
		print("FAIL " + label)
		_failed += 1


func _init() -> void:
	print("=== RecordScreenState Test ===")
	var state := RecordScreenStateS.new()
	state.select(&"list", "unit_b")
	_check(
		state.restore(&"list", ["unit_c", "unit_b", "unit_a"]) == "unit_b",
		"stable selection survives row reorder",
	)
	_check(
		state.restore(&"list", ["unit_c", "unit_a"], "unit_a") == "unit_a",
		"removed selection falls back to the preferred stable id",
	)
	_check(
		state.restore(&"list", ["unit_c"]) == "unit_c",
		"removed selection without a preference falls back to the first record",
	)
	_check(
		state.restore(&"list", []) == "" and state.selected_id(&"list") == "",
		"empty refresh clears stale selection",
	)

	state.active_region = &"detail"
	state.select(&"detail", "weapon:iron_sword")
	state.filter_text = "iron"
	state.sort_id = &"name_desc"
	state.presenter_mode = &"compact"
	var restored := RecordScreenStateS.new()
	restored.restore_snapshot(state.snapshot())
	_check(
		(
			restored.active_region == &"detail"
			and restored.selected_id(&"detail") == "weapon:iron_sword"
			and restored.filter_text == "iron"
			and restored.sort_id == &"name_desc"
			and restored.presenter_mode == &"compact"
		),
		"snapshot round-trip preserves presentation and per-region selection state",
	)

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
