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
