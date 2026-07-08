extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_input_mode_manager.gd

const InputModeManagerS = preload("res://scripts/autoloads/InputModeManager.gd")


func _ok(condition: bool, label: String, passed: Array, failed: Array) -> void:
	if condition:
		print("OK  " + label)
		passed[0] += 1
	else:
		print("FAIL " + label)
		failed[0] += 1


func _init() -> void:
	print("=== InputModeManager Test ===")
	var passed := [0]
	var failed := [0]

	var desktop := {
		"auto": true,
		"gamepad": true,
		"touch": false,
		"mouse_keyboard": true,
	}
	var mobile := {
		"auto": true,
		"gamepad": true,
		"touch": true,
		"mouse_keyboard": false,
	}
	_ok(InputModeManagerS.resolve_input_mode("auto", "gamepad", desktop, "mouse_keyboard") == "gamepad",
		"Auto follows the last detected available mode", passed, failed)
	_ok(InputModeManagerS.resolve_input_mode("gamepad", "mouse_keyboard", desktop, "mouse_keyboard") == "gamepad",
		"explicit available setting pins the active mode", passed, failed)
	_ok(InputModeManagerS.resolve_input_mode("touch", "mouse_keyboard", desktop, "mouse_keyboard") == "mouse_keyboard",
		"explicit unavailable setting falls back to detect floor", passed, failed)
	_ok(InputModeManagerS.resolve_input_mode("auto", "", mobile, "touch") == "touch",
		"zero-input mobile seed resolves to touch", passed, failed)
	_ok(InputModeManagerS.resolve_input_mode("bad", "", desktop, "mouse_keyboard") == "mouse_keyboard",
		"invalid stored input mode normalizes to Auto", passed, failed)

	var key_ev := InputEventKey.new()
	key_ev.keycode = KEY_A
	var mouse_ev := InputEventMouseButton.new()
	mouse_ev.button_index = MOUSE_BUTTON_LEFT
	var pad_ev := InputEventJoypadButton.new()
	pad_ev.button_index = JOY_BUTTON_A
	var stick_ev := InputEventJoypadMotion.new()
	stick_ev.axis = JOY_AXIS_LEFT_X
	stick_ev.axis_value = 0.75
	var drift_ev := InputEventJoypadMotion.new()
	drift_ev.axis = JOY_AXIS_LEFT_X
	drift_ev.axis_value = 0.1
	var touch_ev := InputEventScreenTouch.new()
	_ok(InputModeManagerS.event_to_input_mode(key_ev) == "mouse_keyboard"
			and InputModeManagerS.event_to_input_mode(mouse_ev) == "mouse_keyboard",
		"key and mouse events detect keyboard/mouse mode", passed, failed)
	_ok(InputModeManagerS.event_to_input_mode(pad_ev) == "gamepad"
			and InputModeManagerS.event_to_input_mode(stick_ev) == "gamepad",
		"joypad button and real stick movement detect gamepad mode", passed, failed)
	_ok(InputModeManagerS.event_to_input_mode(drift_ev) == "",
		"sub-deadzone joypad motion is ignored", passed, failed)
	_ok(InputModeManagerS.event_to_input_mode(touch_ev) == "touch",
		"screen touch detects touch mode", passed, failed)

	var desktop_available: Dictionary = InputModeManagerS.available_modes_for_platform(false)
	var mobile_available: Dictionary = InputModeManagerS.available_modes_for_platform(true)
	_ok(bool(desktop_available.get("gamepad")) and not bool(desktop_available.get("touch"))
			and bool(desktop_available.get("mouse_keyboard")),
		"desktop availability enables gamepad/K&M and grays touch", passed, failed)
	_ok(bool(mobile_available.get("gamepad")) and bool(mobile_available.get("touch"))
			and not bool(mobile_available.get("mouse_keyboard")),
		"mobile availability keeps supportable gamepad enabled and grays K&M", passed, failed)

	var manager: Node = InputModeManagerS.new()
	var seen: Array[String] = []
	manager.input_mode_changed.connect(func(mode: String): seen.append(mode))
	manager._set_active_input_mode("gamepad")
	manager._set_active_input_mode("gamepad")
	manager._set_active_input_mode("mouse_keyboard")
	_ok(seen == ["gamepad", "mouse_keyboard"],
		"input_mode_changed emits only on real active-mode changes", passed, failed)
	manager.free()

	var settings := root.get_node_or_null("SettingsManager")
	if settings == null:
		settings = load("res://scripts/autoloads/SettingsManager.gd").new()
		settings.name = "SettingsManager"
		root.add_child(settings)
		await process_frame
	var prev_input_mode: String = String(settings.get("input_mode"))
	settings.set("input_mode", "auto")
	settings.call("save")
	var live_manager: Node = InputModeManagerS.new()
	root.add_child(live_manager)
	await process_frame
	var live_seen: Array[String] = []
	live_manager.input_mode_changed.connect(func(mode: String): live_seen.append(mode))
	settings.set("input_mode", "gamepad")
	settings.call("save")
	_ok(String(live_manager.get("active_input_mode")) == "gamepad"
			and live_seen == ["gamepad"],
		"SettingsManager save signal refreshes active input mode immediately", passed, failed)
	live_manager.set("last_detected_input_mode", "")
	live_manager.set("_provisional_seed", "mouse_keyboard")
	settings.call("reset_section_to_defaults", "controls")
	_ok(String(live_manager.get("active_input_mode")) == "mouse_keyboard",
		"controls reset signal re-resolves input mode without an input event", passed, failed)
	settings.set("input_mode", prev_input_mode)
	settings.call("save")
	live_manager.free()

	print("\n=== Results: %d passed, %d failed ===" % [passed[0], failed[0]])
	quit(0 if failed[0] == 0 else 1)
