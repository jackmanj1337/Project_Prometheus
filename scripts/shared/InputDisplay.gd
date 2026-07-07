extends RefCounted
# Helpers for rendering InputMap actions/events as human-readable key strings.
#
# No `class_name`: callers `preload()` this script and use it via a const, e.g.
#   const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")
# That keeps headless `--script` test runs working without needing a manual
# entry in the gitignored global class cache.

# Renders one InputEventKey as a display string, e.g. "Shift+Tab".
# Modifiers are listed in a stable order so the same binding always reads the
# same way. Returns "" for non-key events (mouse buttons, joypad, etc.).
static func event_to_string(event: InputEvent) -> String:
	if not (event is InputEventKey):
		return ""
	var parts: Array[String] = []
	if event.ctrl_pressed:  parts.append("Ctrl")
	if event.shift_pressed: parts.append("Shift")
	if event.alt_pressed:   parts.append("Alt")
	if event.meta_pressed:  parts.append("Meta")
	# Prefer keycode; fall back to physical_keycode for layout-independent binds.
	var code: int = event.keycode if event.keycode != 0 else event.physical_keycode
	parts.append(OS.get_keycode_string(code))
	return "+".join(parts)


static func binding_to_string(event: InputEvent) -> String:
	if event is InputEventKey:
		return event_to_string(event)
	if event is InputEventMouseButton:
		return _mouse_button_to_string(event.button_index)
	if event is InputEventJoypadButton:
		return _joypad_button_to_string(event.button_index)
	if event is InputEventJoypadMotion:
		return _joypad_axis_to_string(event.axis, event.axis_value)
	return ""


# The first key bound to `action`, rendered for display. Returns "" when the
# action is missing or has no key event (e.g. only a mouse button bound).
static func first_key_for_action(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return event_to_string(ev)
	return ""


# Every key bound to `action`, joined with " / ". Returns "(unbound)" when the
# action has no key events.
static func keys_for_action(action: String) -> String:
	var keys: Array[String] = []
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				keys.append(event_to_string(ev))
	return " / ".join(keys) if not keys.is_empty() else "(unbound)"


# Every player-readable binding for an action, including mouse and gamepad.
static func bindings_for_action(action: String) -> String:
	var labels: Array[String] = []
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			var label := binding_to_string(ev)
			if label != "":
				labels.append(label)
	return " / ".join(labels) if not labels.is_empty() else "(unbound)"


static func _mouse_button_to_string(button_index: int) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return "Left Click"
		MOUSE_BUTTON_RIGHT:
			return "Right Click"
		MOUSE_BUTTON_MIDDLE:
			return "Middle Click"
		MOUSE_BUTTON_WHEEL_UP:
			return "Wheel Up"
		MOUSE_BUTTON_WHEEL_DOWN:
			return "Wheel Down"
		_:
			return "Mouse %d" % button_index


static func _joypad_button_to_string(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A:
			return "Pad A"
		JOY_BUTTON_B:
			return "Pad B"
		JOY_BUTTON_X:
			return "Pad X"
		JOY_BUTTON_Y:
			return "Pad Y"
		JOY_BUTTON_BACK:
			return "View"
		JOY_BUTTON_START:
			return "Start"
		JOY_BUTTON_LEFT_STICK:
			return "L3"
		JOY_BUTTON_RIGHT_STICK:
			return "R3"
		JOY_BUTTON_LEFT_SHOULDER:
			return "LB"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "RB"
		JOY_BUTTON_DPAD_UP:
			return "D-pad Up"
		JOY_BUTTON_DPAD_DOWN:
			return "D-pad Down"
		JOY_BUTTON_DPAD_LEFT:
			return "D-pad Left"
		JOY_BUTTON_DPAD_RIGHT:
			return "D-pad Right"
		_:
			return "Pad Button %d" % button_index


static func _joypad_axis_to_string(axis: int, value: float) -> String:
	match axis:
		JOY_AXIS_LEFT_X:
			return "Left Stick Left" if value < 0.0 else "Left Stick Right"
		JOY_AXIS_LEFT_Y:
			return "Left Stick Up" if value < 0.0 else "Left Stick Down"
		JOY_AXIS_TRIGGER_LEFT:
			return "LT"
		JOY_AXIS_TRIGGER_RIGHT:
			return "RT"
		_:
			return "Pad Axis %d" % axis
