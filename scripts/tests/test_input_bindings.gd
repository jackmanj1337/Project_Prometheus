extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_input_bindings.gd
# B6-INPUT slice 1: project InputMap carries the locked gamepad defaults, and
# SettingsManager mirrors gameplay navigation onto Godot's built-in ui_* actions.

const SettingsManagerS = preload("res://scripts/autoloads/SettingsManager.gd")


func _has_joy_button(action: String, button_index: int) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button_index:
			return true
	return false


func _has_joy_axis(action: String, axis: int, axis_value: float) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis \
				and is_equal_approx(event.axis_value, axis_value):
			return true
	return false


func _has_any_joypad(action: String) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false


func _record(ok: bool, label: String, counters: Dictionary) -> void:
	if ok:
		print("OK  %s" % label)
		counters["passed"] += 1
	else:
		print("FAIL %s" % label)
		counters["failed"] += 1


func _init() -> void:
	print("=== Input Bindings Test ===")
	var counters := {"passed": 0, "failed": 0}

	var button_cases := {
		"confirm": JOY_BUTTON_A,
		"cancel": JOY_BUTTON_B,
		"more_info": JOY_BUTTON_X,
		"inspect_unit": JOY_BUTTON_Y,
		"peek_range": JOY_BUTTON_BACK,
		"open_menu": JOY_BUTTON_START,
		"zoom_reset": JOY_BUTTON_LEFT_STICK,
		"show_danger_zone": JOY_BUTTON_RIGHT_STICK,
		"prev_unit": JOY_BUTTON_LEFT_SHOULDER,
		"next_unit": JOY_BUTTON_RIGHT_SHOULDER,
		"cursor_up": JOY_BUTTON_DPAD_UP,
		"cursor_down": JOY_BUTTON_DPAD_DOWN,
		"cursor_left": JOY_BUTTON_DPAD_LEFT,
		"cursor_right": JOY_BUTTON_DPAD_RIGHT,
	}
	for action in button_cases:
		_record(_has_joy_button(action, button_cases[action]),
			"%s has gamepad button %d" % [action, button_cases[action]], counters)

	var axis_cases := [
		["cursor_up", JOY_AXIS_LEFT_Y, -1.0],
		["cursor_down", JOY_AXIS_LEFT_Y, 1.0],
		["cursor_left", JOY_AXIS_LEFT_X, -1.0],
		["cursor_right", JOY_AXIS_LEFT_X, 1.0],
		["zoom_in", JOY_AXIS_TRIGGER_RIGHT, 1.0],
		["zoom_out", JOY_AXIS_TRIGGER_LEFT, 1.0],
	]
	for row in axis_cases:
		_record(_has_joy_axis(row[0], row[1], row[2]),
			"%s has gamepad axis %d/%s" % [row[0], row[1], row[2]], counters)

	_record(not _has_any_joypad("open_settings"),
		"open_settings stays menu-only on gamepad", counters)
	for action in [
		"debug_toggle_force_levelup",
		"debug_toggle_growth_boost",
		"debug_toggle_hotseat_override",
	]:
		_record(not _has_any_joypad(action),
			"%s stays keyboard-only" % action, counters)

	var sm: Node = SettingsManagerS.new()
	sm._mirror_game_keys_to_ui()
	_record(_has_joy_button("ui_accept", JOY_BUTTON_A),
		"ui_accept mirrors confirm Pad A", counters)
	_record(_has_joy_button("ui_cancel", JOY_BUTTON_B),
		"ui_cancel mirrors cancel Pad B", counters)
	_record(_has_joy_button("ui_up", JOY_BUTTON_DPAD_UP)
			and _has_joy_axis("ui_up", JOY_AXIS_LEFT_Y, -1.0),
		"ui_up mirrors d-pad and stick up", counters)

	print("\n=== Results: %d passed, %d failed ===" % [counters["passed"], counters["failed"]])
	if counters["failed"] > 0:
		quit(1)
	else:
		quit(0)
