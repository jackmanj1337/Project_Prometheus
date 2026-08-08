extends Node

signal input_mode_changed(mode: String)

const SettingsManagerS = preload("res://scripts/autoloads/SettingsManager.gd")

const MODE_AUTO := "auto"
const MODE_GAMEPAD := "gamepad"
const MODE_TOUCH := "touch"
const MODE_MOUSE_KEYBOARD := "mouse_keyboard"
const VALID_INPUT_MODES: Array[String] = SettingsManagerS.VALID_INPUT_MODES
const TOUCH_MOUSE_SUPPRESSION_MSEC := 150
const JOY_MOTION_DEADZONE := 0.5

var active_input_mode: String = MODE_MOUSE_KEYBOARD
var last_detected_input_mode: String = ""
var last_active_joypad_device: int = -1

var _provisional_seed: String = MODE_MOUSE_KEYBOARD
var _last_touch_ticks_msec: int = -1000000
var _joypad_identity: Dictionary = {}


func _ready() -> void:
	_provisional_seed = platform_seed()
	var settings := get_node_or_null("/root/SettingsManager")
	if (
		settings != null
		and settings.has_signal("settings_changed")
		and not settings.is_connected("settings_changed", _refresh_active_input_mode)
	):
		settings.connect("settings_changed", _refresh_active_input_mode)
	_refresh_active_input_mode()
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	for device_id in Input.get_connected_joypads():
		_log_controller(int(device_id), true)


func _input(event: InputEvent) -> void:
	var joy_device := event_joypad_device(event)
	if joy_device >= 0:
		last_active_joypad_device = joy_device
	var mode := detect_event_mode_with_touch_guard(event)
	if mode != "":
		note_detected_input_mode(mode)


func note_detected_input_mode(mode: String) -> void:
	if not (mode in [MODE_GAMEPAD, MODE_TOUCH, MODE_MOUSE_KEYBOARD]):
		return
	last_detected_input_mode = mode
	_refresh_active_input_mode()


func detect_event_mode_with_touch_guard(event: InputEvent) -> String:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_last_touch_ticks_msec = Time.get_ticks_msec()
		return MODE_TOUCH
	if event is InputEventMouse:
		var elapsed := Time.get_ticks_msec() - _last_touch_ticks_msec
		if elapsed >= 0 and elapsed <= TOUCH_MOUSE_SUPPRESSION_MSEC:
			return ""
	return event_to_input_mode(event, JOY_MOTION_DEADZONE)


func _refresh_active_input_mode() -> void:
	var setting := _settings_value("input_mode", MODE_AUTO)
	var available := available_modes()
	var resolved := resolve_input_mode(
		setting, last_detected_input_mode, available, _provisional_seed
	)
	_set_active_input_mode(resolved)


func _set_active_input_mode(mode: String) -> void:
	if mode == "" or active_input_mode == mode:
		return
	active_input_mode = mode
	input_mode_changed.emit(active_input_mode)


func _settings_value(key: String, fallback: String) -> String:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return fallback
	var value: Variant = settings.get(key)
	return String(value) if value != null else fallback


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	_log_controller(device, connected)
	if not connected and device == last_active_joypad_device:
		last_active_joypad_device = -1
	_refresh_active_input_mode()


func _log_controller(device: int, connected: bool) -> void:
	var identity: Dictionary = _joypad_identity.get(device, {})
	if connected:
		identity = {
			"name": Input.get_joy_name(device),
			"guid": Input.get_joy_guid(device),
		}
		_joypad_identity[device] = identity
	print(
		controller_log_line(
			device, connected, String(identity.get("name", "")), String(identity.get("guid", ""))
		)
	)
	if not connected:
		_joypad_identity.erase(device)


static func controller_log_line(device: int, connected: bool, name: String, guid: String) -> String:
	return (
		"PLAYTEST CONTROLLER device_id=%d connected=%s name=%s guid=%s"
		% [device, connected, name, guid]
	)


# Returns the last joypad that sent real input and is still connected. Falls back to
# the first connected pad so zero-input gamepad mode still has a usable prompt brand.
func active_joypad_device() -> int:
	var pads := Input.get_connected_joypads()
	for pad in pads:
		if int(pad) == last_active_joypad_device:
			return last_active_joypad_device
	return int(pads[0]) if not pads.is_empty() else -1


static func event_to_input_mode(
	event: InputEvent, joy_deadzone: float = JOY_MOTION_DEADZONE
) -> String:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		return MODE_MOUSE_KEYBOARD
	if event is InputEventJoypadButton:
		return MODE_GAMEPAD
	if event is InputEventJoypadMotion:
		return (
			MODE_GAMEPAD
			if absf((event as InputEventJoypadMotion).axis_value) >= joy_deadzone
			else ""
		)
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return MODE_TOUCH
	return ""


static func event_joypad_device(
	event: InputEvent, joy_deadzone: float = JOY_MOTION_DEADZONE
) -> int:
	if event is InputEventJoypadButton:
		return event.device
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return motion.device if absf(motion.axis_value) >= joy_deadzone else -1
	return -1


static func resolve_input_mode(
	setting: String, last_detected: String, available: Dictionary, provisional_seed: String
) -> String:
	var normalized_setting := normalize_input_mode(setting)
	var detected := _detect_floor(last_detected, available, provisional_seed)
	if normalized_setting == MODE_AUTO:
		return detected
	if bool(available.get(normalized_setting, false)):
		return normalized_setting
	return detected


static func normalize_input_mode(value: Variant) -> String:
	return SettingsManagerS.normalize_input_mode(value)


static func platform_seed() -> String:
	if OS.has_feature("mobile") or has_web_touch_platform():
		return MODE_TOUCH
	# Steam Deck can be handled here when the build has a reliable feature flag.
	return MODE_MOUSE_KEYBOARD


# Godot tags "mobile" only for a NATIVE Android/iOS export. A PWA on an iPhone is
# tagged web + web_ios, so OS.has_feature("mobile") is false there and touch was
# unavailable BY CONSTRUCTION: mouse-emulation-from-touch still delivered taps, so
# the game was operable and the gap read as "touch feels wrong" rather than as a
# missing mode. Both strings are confirmed present in the 4.6.3 godot.js we ship.
# The feature list itself lives in SettingsManager, which also derives the mobile-web
# content scale from it; this delegates so the two cannot disagree about what a
# mobile browser is.
static func has_web_touch_platform() -> bool:
	return SettingsManagerS.has_web_touch_platform()


static func available_modes() -> Dictionary:
	var mobile := OS.has_feature("mobile")
	return available_modes_for_platform(mobile, OS.has_feature("web"), has_web_touch_platform())


static func available_modes_for_platform(
	is_mobile: bool, is_web: bool = false, is_web_touch: bool = false
) -> Dictionary:
	return {
		MODE_AUTO: true,
		MODE_GAMEPAD: true,
		MODE_TOUCH: is_mobile or is_web_touch,
		# A mobile browser still reaches a Bluetooth keyboard or mouse, so web keeps
		# mouse_keyboard selectable even when touch is the seeded default.
		MODE_MOUSE_KEYBOARD: not is_mobile or is_web,
	}


static func _detect_floor(
	last_detected: String, available: Dictionary, provisional_seed: String
) -> String:
	if bool(available.get(last_detected, false)) and last_detected != MODE_AUTO:
		return last_detected
	if bool(available.get(provisional_seed, false)) and provisional_seed != MODE_AUTO:
		return provisional_seed
	for mode in [MODE_MOUSE_KEYBOARD, MODE_GAMEPAD, MODE_TOUCH]:
		if bool(available.get(mode, false)):
			return mode
	return MODE_MOUSE_KEYBOARD
