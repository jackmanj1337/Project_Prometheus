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


# ── Gamepad brand-aware prompts (B6-INPUT prompt swapping) ────────────────────
# SDL (Godot 4.5+ controller backend) normalizes button POSITION, not label:
# JOY_BUTTON_A is always the physical BOTTOM face button on every brand, so our
# bindings are already brand-correct with no per-brand code. Only the printed
# LABEL differs — Nintendo swaps the A/B and X/Y physical positions vs Xbox, and
# PlayStation prints ✕ ○ □ △. Godot exposes no native controller-type API, so brand
# is classified heuristically from Input.get_joy_name() (the community-standard
# workaround; see godot-proposals#8519). Behaviour never depends on the brand — only
# the on-screen prompt text does — so a wrong guess is cosmetic, never a mis-input.

enum Brand { XBOX, PLAYSTATION, NINTENDO, GENERIC }


# Classifies a joypad name string into a Brand. Lower-cased substring match; unknown
# pads fall back to GENERIC (Xbox-style A/B/X/Y labels, the de-facto PC default).
static func detect_brand(joy_name: String) -> int:
	var n := joy_name.to_lower()
	if "nintendo" in n or "switch" in n or "joycon" in n or "joy-con" in n or "joy con" in n:
		return Brand.NINTENDO
	if "sony" in n or "playstation" in n or "dualshock" in n or "dualsense" in n \
			or "ps3" in n or "ps4" in n or "ps5" in n:
		return Brand.PLAYSTATION
	if "xbox" in n or "xinput" in n or "x-box" in n or "microsoft" in n:
		return Brand.XBOX
	return Brand.GENERIC


# Brand of the first connected joypad (GENERIC when none is attached).
static func active_pad_brand() -> int:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return Brand.GENERIC
	return detect_brand(Input.get_joy_name(pads[0]))


# The label the player actually sees printed on THEIR pad for a positional button
# index. Face buttons swap by brand; non-face buttons (shoulders/dpad/stick/menu)
# don't move except PlayStation shoulders, so they defer to the positional name.
static func joypad_button_label(button_index: int, brand: int) -> String:
	match brand:
		Brand.NINTENDO:
			match button_index:
				JOY_BUTTON_A: return "B"  # physical bottom is labeled B on a Switch pad
				JOY_BUTTON_B: return "A"
				JOY_BUTTON_X: return "Y"
				JOY_BUTTON_Y: return "X"
		Brand.PLAYSTATION:
			match button_index:
				JOY_BUTTON_A: return "Cross"
				JOY_BUTTON_B: return "Circle"
				JOY_BUTTON_X: return "Square"
				JOY_BUTTON_Y: return "Triangle"
				JOY_BUTTON_LEFT_SHOULDER: return "L1"
				JOY_BUTTON_RIGHT_SHOULDER: return "R1"
		_:
			match button_index:
				JOY_BUTTON_A: return "A"
				JOY_BUTTON_B: return "B"
				JOY_BUTTON_X: return "X"
				JOY_BUTTON_Y: return "Y"
	# Non-face buttons (and unlisted PS shoulders fall through to here): positional
	# name minus the "Pad " prefix reads fine as a prompt ("LB", "Start", "D-pad Up").
	return _joypad_button_to_string(button_index).trim_prefix("Pad ")


# The first pad label bound to `action`, brand-corrected. "" when the action has no
# joypad binding (caller can fall back to the key label).
static func first_pad_label_for_action(action: String, brand: int) -> String:
	if not InputMap.has_action(action):
		return ""
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton:
			return joypad_button_label((ev as InputEventJoypadButton).button_index, brand)
		if ev is InputEventJoypadMotion:
			var m := ev as InputEventJoypadMotion
			return _joypad_axis_to_string(m.axis, m.axis_value)
	return ""


# Player-facing prompt for `action` under an explicit input mode + brand. Gamepad
# mode → brand-correct pad label (falling back to the key if nothing is bound to a
# pad); every other mode → first key. Pure (no autoload/tree access) so it is unit-
# testable; live callers use live_action_prompt().
static func action_prompt(action: String, mode: String, brand: int = Brand.GENERIC) -> String:
	if mode == "gamepad":
		var pad := first_pad_label_for_action(action, brand)
		if pad != "":
			return pad
	return first_key_for_action(action)


# Active input mode from the InputModeManager autoload, or "mouse_keyboard" when it
# can't be reached. `tree_node` is any node in the scene tree (to reach /root).
static func active_mode(tree_node: Node) -> String:
	if tree_node != null:
		var imm := tree_node.get_node_or_null("/root/InputModeManager")
		if imm != null:
			return String(imm.get("active_input_mode"))
	return "mouse_keyboard"


# Live prompt: resolves the active input mode from the InputModeManager autoload and
# the attached pad's brand, so a "press X" hint prints the right key or glyph for
# whatever the player is currently holding. `tree_node` is any node in the tree (to
# reach /root/InputModeManager); mouse_keyboard + GENERIC when it can't be reached.
static func live_action_prompt(action: String, tree_node: Node) -> String:
	return action_prompt(action, active_mode(tree_node), active_pad_brand())


# Mode-appropriate "how to open More Info" hint. `subject` is the clickable noun
# ("value" for the forecast, "entry" for the sheet); pass "" for the compact terrain
# prompt, which has nothing to click. Reads live mode + brand from the tree.
static func more_info_hint(tree_node: Node, subject: String) -> String:
	return more_info_hint_for(active_mode(tree_node), subject, active_pad_brand())


# Pure core of more_info_hint (no tree/autoload access) so it is unit-testable. The
# prompt token is the more_info binding: a key in keyboard/touch, the brand-correct
# pad label in gamepad mode.
static func more_info_hint_for(mode: String, subject: String, brand: int = Brand.GENERIC) -> String:
	var token := action_prompt("more_info", mode, brand)
	match mode:
		"gamepad":
			var t := token if token != "" else "the More Info button"
			return ("Press %s for details." % t) if subject != "" else ("Press %s for more info" % t)
		"touch":
			return ("Tap any %s for details." % subject) if subject != "" else "Tap for more info"
		_:
			var k := token if token != "" else "F"
			return ("Click any %s, or press %s, for details." % [subject, k]) if subject != "" \
				else ("Press %s for more info" % k)


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
