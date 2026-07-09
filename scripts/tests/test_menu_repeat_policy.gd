extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_menu_repeat_policy.gd
# Pins the shared repeat/deadzone policy used by custom modal menus.

const MenuRepeatPolicy = preload("res://scripts/shared/MenuRepeatPolicy.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== MenuRepeatPolicy Test ===")

	var policy: RefCounted = MenuRepeatPolicy.new()
	_check(policy.poll(0.016) == Vector2i.ZERO, "resting input produces no step")

	Input.action_press("cursor_down", 1.0)
	_check(policy.poll(0.016) == Vector2i(0, 1), "fresh press steps immediately")
	_check(policy.poll(0.20) == Vector2i.ZERO, "held direction waits through repeat delay")
	_check(policy.poll(0.06) == Vector2i(0, 1), "held direction repeats after delay")
	Input.action_release("cursor_down")
	_check(policy.poll(0.016) == Vector2i.ZERO, "release clears held direction")

	Input.action_press("cursor_right", 1.0)
	Input.action_press("cursor_down", 0.5)
	_check(policy.poll(0.016) == Vector2i(1, 0), "dominant axis wins diagonal input")
	Input.action_release("cursor_right")
	Input.action_release("cursor_down")
	policy.clear()

	var ui_policy: RefCounted = MenuRepeatPolicy.new("ui_left", "ui_right", "ui_up", "ui_down")
	Input.action_press("ui_up", 1.0)
	_check(ui_policy.poll(0.016) == Vector2i(0, -1), "custom action vocabulary works")
	Input.action_release("ui_up")
	ui_policy.clear()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK  " + label)
		_passed += 1
	else:
		print("FAIL " + label)
		_failed += 1
