extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_settings_manager.gd
# Tests SettingsManager: the ui_* key mirroring that lets menus respond to the
# game's keys (#7), and the movement-speed mapping.

const SettingsManagerS = preload("res://scripts/autoloads/SettingsManager.gd")


# Counts group re-apply calls for the V027-04a resize-hook test.
class ScaleTarget:
	extends Control
	var calls: int = 0

	func apply_menu_scale(_factor: float) -> void:
		calls += 1


# Overrides the device-derived content scale so the fresh-install path can be proven
# to consult it. Headless derives 1.0, which is exactly the literal default, so without
# a sentinel a regression here would be invisible.
class DerivedProbe:
	extends SettingsManagerS
	const SENTINEL: float = 2.5

	func _derived_content_scale_factor() -> float:
		return SENTINEL


# True when `action` has an InputEventKey bound to `keycode`.
func _has_key(action: String, keycode: int) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and ev.keycode == keycode:
			return true
	return false


func _has_joy_button(action: String, button_index: int) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton and ev.button_index == button_index:
			return true
	return false


func _init() -> void:
	print("=== SettingsManager Test ===")
	var passed := 0
	var failed := 0

	# .new() without add_child so _ready() does not run — we call methods directly.
	var sm: Node = SettingsManagerS.new()

	# ---- _mirror_game_keys_to_ui: game keys reach the built-in ui_* actions (#7) ----
	sm._mirror_game_keys_to_ui()
	if _has_key("ui_accept", KEY_Z):
		print("OK  ui_accept gains the confirm key (Z)")
		passed += 1
	else:
		print("FAIL ui_accept missing Z")
		failed += 1
	if _has_key("ui_up", KEY_W):
		print("OK  ui_up gains the cursor_up key (W)")
		passed += 1
	else:
		print("FAIL ui_up missing W")
		failed += 1
	if _has_key("ui_cancel", KEY_X):
		print("OK  ui_cancel gains the cancel key (X)")
		passed += 1
	else:
		print("FAIL ui_cancel missing X")
		failed += 1

	# ---- the built-in defaults are preserved (arrows still drive ui_up) ----
	if _has_key("ui_up", KEY_UP):
		print("OK  ui_up keeps its default arrow key")
		passed += 1
	else:
		print("FAIL ui_up lost the arrow key")
		failed += 1

	# ---- a second call does not duplicate events (idempotent) ----
	var before := InputMap.action_get_events("ui_accept").size()
	sm._mirror_game_keys_to_ui()
	if InputMap.action_get_events("ui_accept").size() == before:
		print("OK  _mirror_game_keys_to_ui is idempotent")
		passed += 1
	else:
		print("FAIL mirror duplicated events")
		failed += 1

	# ---- 2.9: rebind_action drops the old key from the mirrored ui_* action ──
	# Pre-2026-06-10 the mirror only ADDED events, so rebinding "confirm" from
	# Z to Y left BOTH Z and Y on ui_accept indefinitely. The mirror now resets
	# ui_* to its baseline (engine defaults) before re-stamping the current
	# game-key events, so the old binding is dropped cleanly.
	# Suppress the save() that follows rebind to keep the user:// cfg untouched.
	# Use Y as the new confirm key.
	var saved_confirm: Array[InputEvent] = []
	for ev in InputMap.action_get_events("confirm"):
		saved_confirm.append(ev)
	var saved_cancel: Array[InputEvent] = []
	for ev in InputMap.action_get_events("cancel"):
		saved_cancel.append(ev)
	var new_confirm := InputEventKey.new()
	new_confirm.keycode = KEY_Y
	# rebind_action calls save(); the assertions below inspect that generated cfg
	# and reset controls afterward so later tests start from authored defaults.
	sm.rebind_action("confirm", new_confirm)
	var has_new: bool = _has_key("ui_accept", KEY_Y)
	var has_old: bool = _has_key("ui_accept", KEY_Z)
	var has_engine: bool = _has_key("ui_accept", KEY_ENTER)
	var has_confirm_pad: bool = _has_joy_button("confirm", JOY_BUTTON_A)
	var has_ui_pad: bool = _has_joy_button("ui_accept", JOY_BUTTON_A)
	if has_new and not has_old and has_engine and has_confirm_pad and has_ui_pad:
		print("OK  2.9: rebind drops old key, keeps Enter, and preserves Pad A")
		passed += 1
	else:
		print(
			(
				"FAIL 2.9 rebind mirror: new=%s old=%s engine=%s pad=%s ui_pad=%s"
				% [has_new, has_old, has_engine, has_confirm_pad, has_ui_pad]
			)
		)
		failed += 1
	var cfg_text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(sm.SETTINGS_PATH))
	var cfg_plain_ok: bool = (
		cfg_text.find("profiles") >= 0
		and cfg_text.find("active_profile") >= 0
		and cfg_text.find("Object(InputEvent") == -1
		and cfg_text.find('"Y"') >= 0
	)
	if cfg_plain_ok:
		print("OK  keybind save uses profile-ready plain tokens, not Object(InputEvent) blobs")
		passed += 1
	else:
		print("FAIL keybind cfg was not plain/profile-ready:\n%s" % cfg_text)
		failed += 1
	# A pad rebind replaces only the pad slot; the keyboard slot stays on Y.
	var new_confirm_pad := InputEventJoypadButton.new()
	new_confirm_pad.button_index = JOY_BUTTON_B
	sm.rebind_action("confirm", new_confirm_pad)
	var pad_rebind_ok: bool = (
		_has_key("confirm", KEY_Y) and _has_joy_button("confirm", JOY_BUTTON_B)
	)
	if pad_rebind_ok:
		print("OK  pad rebind keeps the keyboard slot intact")
		passed += 1
	else:
		print("FAIL pad rebind did not preserve keyboard slot")
		failed += 1
	# Batch apply accepts token/event dictionaries and commits both slots together.
	var cancel_key := InputEventKey.new()
	cancel_key.keycode = KEY_C
	(
		sm
		. apply_keybindings(
			{
				"cancel":
				{
					"kbd": cancel_key,
					"pad": "JoyX",
				}
			}
		)
	)
	var batch_apply_ok: bool = _has_key("cancel", KEY_C) and _has_joy_button("cancel", JOY_BUTTON_X)
	if batch_apply_ok:
		print("OK  apply_keybindings commits pending kbd/pad slots as a batch")
		passed += 1
	else:
		print("FAIL apply_keybindings batch did not apply both slots")
		failed += 1
	# Round-trip through settings.cfg rehydrates the plain tokens into InputEvents.
	InputMap.action_erase_events("confirm")
	for ev in saved_confirm:
		InputMap.action_add_event("confirm", ev)
	InputMap.action_erase_events("cancel")
	for ev in saved_cancel:
		InputMap.action_add_event("cancel", ev)
	var sm_roundtrip: Node = SettingsManagerS.new()
	sm_roundtrip.load_settings()
	sm_roundtrip._apply_keybindings()
	sm_roundtrip._mirror_game_keys_to_ui()
	var roundtrip_ok: bool = (
		_has_key("confirm", KEY_Y)
		and _has_joy_button("confirm", JOY_BUTTON_B)
		and _has_key("cancel", KEY_C)
		and _has_joy_button("cancel", JOY_BUTTON_X)
		and _has_key("ui_accept", KEY_Y)
		and _has_joy_button("ui_accept", JOY_BUTTON_B)
	)
	sm_roundtrip.free()
	if roundtrip_ok:
		print("OK  plain-token keybindings reload and mirror correctly")
		passed += 1
	else:
		print("FAIL plain-token reload/mirror failed")
		failed += 1
	# A bad hand-edited token falls back to that action's default slot.
	var bad_cfg := ConfigFile.new()
	bad_cfg.set_value("controls", "active_profile", "Default")
	(
		bad_cfg
		. set_value(
			"controls",
			"profiles",
			{
				"Default":
				{
					"confirm":
					{
						"kbd": "NotARealKey",
						"pad": "JoyA",
					}
				}
			}
		)
	)
	bad_cfg.save(sm.SETTINGS_PATH)
	InputMap.action_erase_events("confirm")
	for ev in saved_confirm:
		InputMap.action_add_event("confirm", ev)
	var sm_bad: Node = SettingsManagerS.new()
	sm_bad.load_settings()
	sm_bad._apply_keybindings()
	var bad_fallback_ok: bool = (
		_has_key("confirm", KEY_Z) and _has_joy_button("confirm", JOY_BUTTON_A)
	)
	sm_bad.free()
	if bad_fallback_ok:
		print("OK  invalid keybind token falls back to the default slot")
		passed += 1
	else:
		print("FAIL invalid keybind token did not fall back to default")
		failed += 1
	# Old Object(InputEvent...) cfg blobs migrate into Default profile tokens.
	var legacy_key := InputEventKey.new()
	legacy_key.keycode = KEY_U
	var legacy_pad := InputEventJoypadButton.new()
	legacy_pad.button_index = JOY_BUTTON_Y
	var legacy_cfg := ConfigFile.new()
	legacy_cfg.set_value("controls", "keybindings", {"confirm": [legacy_key, legacy_pad]})
	legacy_cfg.save(sm.SETTINGS_PATH)
	InputMap.action_erase_events("confirm")
	for ev in saved_confirm:
		InputMap.action_add_event("confirm", ev)
	var sm_legacy: Node = SettingsManagerS.new()
	sm_legacy.load_settings()
	var legacy_profile: Dictionary = sm_legacy.profiles.get("Default", {})
	var legacy_confirm: Dictionary = legacy_profile.get("confirm", {})
	var legacy_profile_ok: bool = (
		String(legacy_confirm.get("kbd", "")) == "U"
		and String(legacy_confirm.get("pad", "")) == "JoyY"
	)
	var legacy_text := FileAccess.get_file_as_string(
		ProjectSettings.globalize_path(sm.SETTINGS_PATH)
	)
	var legacy_written_new_ok: bool = (
		legacy_text.find("keybindings") == -1
		and legacy_text.find("Object(InputEvent") == -1
		and legacy_text.find("profiles") >= 0
	)
	sm_legacy._apply_keybindings()
	var legacy_apply_ok: bool = (
		_has_key("confirm", KEY_U) and _has_joy_button("confirm", JOY_BUTTON_Y)
	)
	sm_legacy.reset_section_to_defaults("controls")
	sm_legacy.free()
	if legacy_profile_ok and legacy_written_new_ok and legacy_apply_ok:
		print("OK  legacy Object(InputEvent) keybind cfg migrates to Default profile tokens")
		passed += 1
	else:
		print(
			(
				"FAIL legacy migration: profile=%s written=%s apply=%s\n%s"
				% [legacy_profile_ok, legacy_written_new_ok, legacy_apply_ok, legacy_text]
			)
		)
		failed += 1
	# Restore the original confirm binding so subsequent tests see the same
	# InputMap they started with.
	InputMap.action_erase_events("confirm")
	for ev in saved_confirm:
		InputMap.action_add_event("confirm", ev)
	InputMap.action_erase_events("cancel")
	for ev in saved_cancel:
		InputMap.action_add_event("cancel", ev)
	sm._mirror_game_keys_to_ui()

	# ---- get_movement_speed_seconds maps each speed setting ----
	sm.movement_speed = "instant"
	var inst_ok: bool = sm.get_movement_speed_seconds() == 0.0
	sm.movement_speed = "fast"
	var fast_ok: bool = sm.get_movement_speed_seconds() < 0.12
	sm.movement_speed = "normal"
	var norm_ok: bool = sm.get_movement_speed_seconds() == 0.12
	if inst_ok and fast_ok and norm_ok:
		print("OK  get_movement_speed_seconds maps each speed")
		passed += 1
	else:
		print("FAIL movement speed: inst=%s fast=%s norm=%s" % [inst_ok, fast_ok, norm_ok])
		failed += 1

	# ---- V021-17: mouse_cursor vocabulary defaults, resets, and migrates legacy values ----
	var modes_ok: bool = sm.VALID_MOUSE_CURSOR_MODES == ["follow", "click", "disabled"]
	var mouse_default_ok: bool = sm.mouse_cursor == "follow"
	var mouse_migration_ok: bool = (
		sm.normalize_mouse_cursor_mode("enabled") == "follow"
		and sm.normalize_mouse_cursor_mode("snap") == "click"
		and sm.normalize_mouse_cursor_mode("disabled") == "disabled"
		and sm.normalize_mouse_cursor_mode("bad") == "follow"
	)
	var input_mode_ok: bool = (
		sm.VALID_INPUT_MODES == ["auto", "gamepad", "touch", "mouse_keyboard"]
		and sm.normalize_input_mode("gamepad") == "gamepad"
		and sm.normalize_input_mode("bad") == "auto"
	)
	var text_entry_mode_ok: bool = (
		sm.VALID_TEXT_ENTRY_MODES == ["auto", "grid", "hardware", "system"]
		and sm.normalize_text_entry_mode("grid") == "grid"
		and sm.normalize_text_entry_mode("bad") == "auto"
	)
	var touch_controls_ok: bool = (
		sm.VALID_TOUCH_CONTROLS == ["dedicated", "virtual_gamepad"]
		and sm.normalize_touch_controls("virtual_gamepad") == "virtual_gamepad"
		and sm.normalize_touch_controls("bad") == "dedicated"
	)
	sm.mouse_cursor = "click"
	sm.input_mode = "gamepad"
	sm.text_entry_mode = "grid"
	sm.touch_controls = "virtual_gamepad"
	sm.reset_section_to_defaults("controls")
	var controls_reset_ok: bool = (
		sm.mouse_cursor == "follow"
		and sm.input_mode == "auto"
		and sm.text_entry_mode == "auto"
		and sm.touch_controls == "dedicated"
	)
	var legacy_mouse_cfg := ConfigFile.new()
	legacy_mouse_cfg.set_value("gameplay", "mouse_cursor", "click")
	legacy_mouse_cfg.save(sm.SETTINGS_PATH)
	var sm_mouse_legacy: Node = SettingsManagerS.new()
	sm_mouse_legacy.load_settings()
	var legacy_mouse_loaded_ok: bool = sm_mouse_legacy.mouse_cursor == "click"
	sm_mouse_legacy.save()
	var migrated_mouse_cfg := ConfigFile.new()
	migrated_mouse_cfg.load(sm.SETTINGS_PATH)
	var legacy_mouse_written_ok: bool = (
		migrated_mouse_cfg.has_section_key("controls", "mouse_cursor")
		and not migrated_mouse_cfg.has_section_key("gameplay", "mouse_cursor")
	)
	sm_mouse_legacy.free()
	sm.reset_section_to_defaults("controls")
	if (
		modes_ok
		and mouse_default_ok
		and mouse_migration_ok
		and input_mode_ok
		and text_entry_mode_ok
		and touch_controls_ok
		and controls_reset_ok
		and legacy_mouse_loaded_ok
		and legacy_mouse_written_ok
	):
		print("OK  controls input modes and mouse_cursor default/reset + legacy migration")
		passed += 1
	else:
		print(
			(
				"FAIL controls modes: mouse_modes=%s mouse_default=%s mouse_migration=%s input=%s touch=%s reset=%s legacy_load=%s legacy_write=%s"
				% [
					modes_ok,
					mouse_default_ok,
					mouse_migration_ok,
					input_mode_ok,
					touch_controls_ok,
					controls_reset_ok,
					legacy_mouse_loaded_ok,
					legacy_mouse_written_ok
				]
			)
		)
		failed += 1

	# ---- #2/#17: new gameplay settings exist with sane defaults + reset ----
	var defaults_ok: bool = sm.auto_end_turn == true and sm.camera_edge_buffer == 2
	sm.auto_end_turn = false
	sm.camera_edge_buffer = 5
	sm.reset_section_to_defaults("gameplay")
	var reset_ok: bool = sm.auto_end_turn == true and sm.camera_edge_buffer == 2
	if defaults_ok and reset_ok:
		print("OK  auto_end_turn / camera_edge_buffer default and reset (#2/#17)")
		passed += 1
	else:
		print("FAIL new gameplay settings: defaults=%s reset=%s" % [defaults_ok, reset_ok])
		failed += 1

	# ---- map_zoom_index: default 3 (1.0x), reset restores it (Display/Access item 1) ----
	var zoom_default_ok: bool = sm.map_zoom_index == 3
	sm.map_zoom_index = 6
	sm.reset_section_to_defaults("gameplay")
	var zoom_reset_ok: bool = sm.map_zoom_index == 3
	if zoom_default_ok and zoom_reset_ok:
		print("OK  map_zoom_index defaults to 3 (1.0x) and resets")
		passed += 1
	else:
		print("FAIL map_zoom_index: default=%s reset=%s" % [zoom_default_ok, zoom_reset_ok])
		failed += 1

	# ---- display section: defaults + reset (Display/Access items 2-3) ----
	var disp_default_ok: bool = (
		sm.window_mode == "windowed"
		and sm.resolution == "1280x720"
		and sm.menu_scale_index == 2
		and sm.MENU_SCALE_LEVELS == [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
	)
	sm.window_mode = "fullscreen"
	sm.resolution = "1920x1080"
	sm.menu_scale_index = 4
	sm.reset_section_to_defaults("display")
	var disp_reset_ok: bool = (
		sm.window_mode == "windowed" and sm.resolution == "1280x720" and sm.menu_scale_index == 2
	)
	# V021-19: the curated list must offer native 1440p + 4K alongside the smaller modes,
	# and they must parse to the expected pixel sizes.
	var hi_res_ok: bool = (
		sm.RESOLUTION_CHOICES.has("2560x1440")
		and sm.RESOLUTION_CHOICES.has("3840x2160")
		and sm._parse_resolution("2560x1440") == Vector2i(2560, 1440)
		and sm._parse_resolution("3840x2160") == Vector2i(3840, 2160)
	)
	if disp_default_ok and disp_reset_ok and hi_res_ok:
		print("OK  display section defaults/resets + offers native 1440p/4K (V021-19)")
		passed += 1
	else:
		print("FAIL display section: defaults=%s reset=%s" % [disp_default_ok, disp_reset_ok])
		failed += 1

	# ---- hud_layout: default empty, round-trips through save/load, resets (item 4) ----
	var hud_default_ok: bool = sm.hud_layout == {}
	sm.hud_layout = {"unit_info": {"offset": Vector2(24, -16), "scale": 1.5}}
	sm.save()
	var sm2: Node = SettingsManagerS.new()
	sm2.load_settings()
	var entry: Variant = sm2.hud_layout.get("unit_info", {})
	var hud_roundtrip_ok: bool = (
		entry is Dictionary
		and entry.get("offset", Vector2.ZERO) == Vector2(24, -16)
		and is_equal_approx(entry.get("scale", 0.0), 1.5)
	)
	sm.reset_section_to_defaults("display")
	var hud_reset_ok: bool = sm.hud_layout == {}
	if hud_default_ok and hud_roundtrip_ok and hud_reset_ok:
		print("OK  hud_layout defaults empty, round-trips through cfg, and resets")
		passed += 1
	else:
		print(
			(
				"FAIL hud_layout: default=%s roundtrip=%s reset=%s"
				% [hud_default_ok, hud_roundtrip_ok, hud_reset_ok]
			)
		)
		failed += 1
	sm2.free()

	# ---- _parse_resolution: valid "WxH" parses; malformed returns ZERO ----
	var parse_ok: bool = (
		sm._parse_resolution("1600x900") == Vector2i(1600, 900)
		and sm._parse_resolution("bad") == Vector2i.ZERO
		and sm._parse_resolution("1280x") == Vector2i.ZERO
	)
	if parse_ok:
		print("OK  _parse_resolution handles valid + malformed strings")
		passed += 1
	else:
		print("FAIL _parse_resolution")
		failed += 1

	# ---- window_centre_position: centres a fitting window, but never off-screen ----
	# Fits the screen → centred. Origin (0,0), 1920x1080 screen, 1280x720 window.
	var fit_ok: bool = (
		sm.window_centre_position(Vector2i.ZERO, Vector2i(1920, 1080), Vector2i(1280, 720))
		== Vector2i(320, 180)
	)
	# Larger than the screen → clamped to the screen origin (title bar stays reachable),
	# not centred into negative coordinates.
	var clamp_ok: bool = (
		sm.window_centre_position(Vector2i(100, 50), Vector2i(1366, 768), Vector2i(1920, 1080))
		== Vector2i(100, 50)
	)
	if fit_ok and clamp_ok:
		print("OK  window_centre_position centres a fitting window, clamps an oversized one")
		passed += 1
	else:
		print("FAIL window_centre_position: fit=%s clamp=%s" % [fit_ok, clamp_ok])
		failed += 1

	# V023-06: windowed native-size choices clamp inside the usable display so the
	# OS title bar remains reachable. Borderless/fullscreen keep exact native modes
	# through separate DisplayServer window modes, so this helper is windowed only.
	# UI-VIEWPORT-ASPECT-2026-07-31: the clamp is now per-axis to the usable rect (no 16:9
	# forcing) — a window may be any aspect under the expand model.
	var win_fit_ok: bool = (
		sm.windowed_client_size_for_screen(Vector2i(2560, 1440), Vector2i(3840, 2160))
		== Vector2i(2560, 1440)
	)
	var win_clamped: Vector2i = sm.windowed_client_size_for_screen(
		Vector2i(3840, 2160), Vector2i(3840, 2160)
	)
	# Each axis clamped to (screen - decoration margin); aspect is NOT forced to 16:9.
	var expected_clamp := Vector2i(
		3840 - sm.WINDOWED_DECORATION_MARGIN.x, 2160 - sm.WINDOWED_DECORATION_MARGIN.y
	)
	var win_clamp_ok: bool = (
		win_clamped == expected_clamp and win_clamped.x < 3840 and win_clamped.y < 2160
	)
	if win_fit_ok and win_clamp_ok:
		print("OK  windowed client size keeps monitor-sized choices inside titled window bounds")
		passed += 1
	else:
		print("FAIL windowed size clamp: fit=%s clamped=%s" % [win_fit_ok, win_clamped])
		failed += 1

	# Free resize (UI-VIEWPORT-ASPECT-2026-07-31): a non-16:9 request that fits is preserved
	# as-is, and an oversize request clamps per-axis without coercing the aspect to 16:9.
	var ultrawide_ok: bool = (
		sm.windowed_client_size_for_screen(Vector2i(2560, 1080), Vector2i(3840, 2160))
		== Vector2i(2560, 1080)
	)
	var oversize_x: Vector2i = sm.windowed_client_size_for_screen(
		Vector2i(5000, 1000), Vector2i(3840, 2160)
	)
	var oversize_ok: bool = oversize_x == Vector2i(3840 - sm.WINDOWED_DECORATION_MARGIN.x, 1000)
	if ultrawide_ok and oversize_ok:
		print("OK  free resize preserves non-16:9 windows and clamps per-axis (UI-VIEWPORT-ASPECT)")
		passed += 1
	else:
		print("FAIL free resize: ultrawide=%s oversize=%s" % [ultrawide_ok, oversize_x])
		failed += 1

	# V025-06: applied_windowed_size() surfaces the clamped window size for the Settings
	# readout. It returns a non-zero size for a valid resolution and ZERO for a malformed
	# one (so the label leaves the row blank rather than showing garbage).
	var prev_res: String = String(sm.get("resolution"))
	sm.set("resolution", "1920x1080")
	var applied_valid: Vector2i = sm.applied_windowed_size()
	sm.set("resolution", "not-a-resolution")
	var applied_bad: Vector2i = sm.applied_windowed_size()
	sm.set("resolution", prev_res)
	if applied_valid != Vector2i.ZERO and applied_bad == Vector2i.ZERO:
		print(
			"OK  applied_windowed_size returns a size for valid res, ZERO for malformed (V025-06)"
		)
		passed += 1
	else:
		print("FAIL applied_windowed_size: valid=%s bad=%s" % [applied_valid, applied_bad])
		failed += 1

	# ---- V028-02 (Q1): windowed_size_status separates preset REQUEST from custom size ----
	# The saved `resolution` means two different things and the readout must not
	# conflate them: a preset is a request the clamp may shrink; a written-back custom
	# size is already the observed client size and must never be re-run through the clamp.
	var sm_ws: Node = SettingsManagerS.new()
	sm_ws.window_mode = "windowed"
	sm_ws.resolution = "1920x1080"  # a preset request
	var st_preset: Dictionary = sm_ws.windowed_size_status()
	var ws_preset_ok: bool = (
		String(st_preset.get("kind")) == "preset"
		and st_preset.get("requested") == Vector2i(1920, 1080)
	)
	sm_ws.resolution = "3840x2071"  # a non-preset OS write-back = observed client size
	var st_custom: Dictionary = sm_ws.windowed_size_status()
	var ws_custom_ok: bool = (
		String(st_custom.get("kind")) == "custom"
		and st_custom.get("requested") == Vector2i(3840, 2071)
		and st_custom.get("applied") == Vector2i(3840, 2071)
	)  # NOT re-clamped
	sm_ws.free()
	if ws_preset_ok and ws_custom_ok:
		print("OK  V028-02 windowed_size_status tags preset vs custom, no re-clamp of custom")
		passed += 1
	else:
		print("FAIL V028-02 status: preset=%s custom=%s" % [st_preset, st_custom])
		failed += 1

	# ---- V028-03 (Q2): maximize is a window STATE, never a persisted resolution ----
	var sm_mx: Node = SettingsManagerS.new()
	sm_mx.window_mode = "windowed"
	var MODE_W := DisplayServer.WINDOW_MODE_WINDOWED
	var MODE_M := DisplayServer.WINDOW_MODE_MAXIMIZED
	# A plain windowed edge drag writes the observed size back.
	var act_drag_ok: bool = sm_mx.resize_write_back_action(MODE_W, MODE_W) == "write_back"
	# Entering maximize is ignored — the maximized client size is never persisted.
	var act_max_ok: bool = sm_mx.resize_write_back_action(MODE_M, MODE_W) == "ignore"
	# Leaving maximize restores the saved windowed size instead of writing back.
	var act_restore_ok: bool = sm_mx.resize_write_back_action(MODE_W, MODE_M) == "restore"
	# Outside windowed mode nothing is written back.
	sm_mx.window_mode = "borderless"
	var act_nonwin_ok: bool = sm_mx.resize_write_back_action(MODE_W, MODE_W) == "ignore"
	sm_mx.free()
	if act_drag_ok and act_max_ok and act_restore_ok and act_nonwin_ok:
		print("OK  V028-03 resize policy: drag=write_back, maximize=ignore, un-maximize=restore")
		passed += 1
	else:
		print(
			(
				"FAIL V028-03 policy: drag=%s max=%s restore=%s nonwin=%s"
				% [act_drag_ok, act_max_ok, act_restore_ok, act_nonwin_ok]
			)
		)
		failed += 1

	# ---- menu-scale schema migration (V023-01, guarded in v0.2.5) ----
	# v1 cfg with a stored index: shifts up one slot so the factor is preserved
	# (old 1 == 1.0x -> new 2 == 1.0x after 0.5x was prepended).
	var mig_cfg := ConfigFile.new()
	mig_cfg.set_value("display", "menu_scale_index", 1)
	mig_cfg.save(sm.SETTINGS_PATH)
	var sm_v1: Node = SettingsManagerS.new()
	sm_v1.load_settings()
	var mig_shift_ok: bool = sm_v1.menu_scale_index == 2
	sm_v1.free()
	# v2 cfg: index already uses the new vocabulary — no shift.
	mig_cfg.set_value("display", "menu_scale_index", 2)
	mig_cfg.set_value("display", "menu_scale_schema_version", 2)
	mig_cfg.save(sm.SETTINGS_PATH)
	var sm_v2: Node = SettingsManagerS.new()
	sm_v2.load_settings()
	var mig_v2_ok: bool = sm_v2.menu_scale_index == 2
	sm_v2.free()
	# Cfg predating the menu-scale setting (no stored index at all): the default must
	# NOT be shifted — that would silently land old configs on 1.25x instead of 1.0x.
	var old_cfg := ConfigFile.new()
	old_cfg.set_value("display", "window_mode", "windowed")
	old_cfg.save(sm.SETTINGS_PATH)
	var sm_old: Node = SettingsManagerS.new()
	sm_old.load_settings()
	var mig_absent_ok: bool = sm_old.menu_scale_index == 2
	sm_old.free()
	# Leave a current-schema cfg behind for anything loading it after this suite.
	sm.save()
	if mig_shift_ok and mig_v2_ok and mig_absent_ok:
		print("OK  menu-scale migration shifts stored v1 indices only, never the default")
		passed += 1
	else:
		print(
			(
				"FAIL menu-scale migration: shift=%s v2=%s absent=%s"
				% [mig_shift_ok, mig_v2_ok, mig_absent_ok]
			)
		)
		failed += 1

	# ---- content scale factor: viewport expand model (UI-VIEWPORT-ASPECT-2026-07-31) ----
	# Identity-diagonal calibration (pure/static, no DisplayServer): the migration
	# guarantee that an existing player's view is unchanged rides on these exact stops.
	var csf_identity_ok: bool = (
		is_equal_approx(SettingsManagerS.identity_factor_for_height(720), 1.0)
		and is_equal_approx(SettingsManagerS.identity_factor_for_height(1080), 1.5)
		and is_equal_approx(SettingsManagerS.identity_factor_for_height(1440), 2.0)
		and is_equal_approx(SettingsManagerS.identity_factor_for_height(2160), 3.0)
		and is_equal_approx(SettingsManagerS.identity_factor_for_height(0), 1.0)
	)
	# Clamp/normalize: out-of-range shrinks to the supported band; junk falls back to 1.0
	# so a corrupt cfg can never blank the viewport.
	var csf_clamp_ok: bool = (
		is_equal_approx(SettingsManagerS.normalize_content_scale_factor(0.1), 0.5)
		and is_equal_approx(SettingsManagerS.normalize_content_scale_factor(10.0), 4.0)
		and is_equal_approx(SettingsManagerS.normalize_content_scale_factor(-2.0), 1.0)
		and is_equal_approx(SettingsManagerS.normalize_content_scale_factor(NAN), 1.0)
		and is_equal_approx(SettingsManagerS.normalize_content_scale_factor(1.25), 1.25)
	)
	# First launch (no stored key): derive the neutral default. Headless derives 1.0.
	var csf_absent_cfg := ConfigFile.new()
	csf_absent_cfg.set_value("display", "window_mode", "windowed")
	csf_absent_cfg.save(sm.SETTINGS_PATH)
	var sm_csf_absent: Node = SettingsManagerS.new()
	sm_csf_absent.load_settings()
	var csf_default_ok: bool = is_equal_approx(sm_csf_absent.content_scale_factor, 1.0)
	sm_csf_absent.free()
	# A GENUINELY fresh install — no settings file at all — must derive it too. That
	# path used to return early with the literal 1.0, so the derived default reached
	# only UPGRADING players (a cfg that exists but lacks the key, the case above).
	# It survived because everyone testing already had a cfg. Headless derives 1.0,
	# which is indistinguishable from the literal, so the probe overrides the
	# derivation and asserts it was actually consulted.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(sm.SETTINGS_PATH))
	var sm_fresh: Node = DerivedProbe.new()
	sm_fresh.load_settings()
	var csf_fresh_ok: bool = is_equal_approx(sm_fresh.content_scale_factor, DerivedProbe.SENTINEL)
	sm_fresh.free()
	# Stored value round-trips and is clamped on load.
	var csf_cfg := ConfigFile.new()
	csf_cfg.set_value("display", "content_scale_factor", 1.75)
	csf_cfg.save(sm.SETTINGS_PATH)
	var sm_csf: Node = SettingsManagerS.new()
	sm_csf.load_settings()
	var csf_load_ok: bool = is_equal_approx(sm_csf.content_scale_factor, 1.75)
	sm_csf.save()  # persist and reload to prove the round-trip
	var sm_csf_rt: Node = SettingsManagerS.new()
	sm_csf_rt.load_settings()
	var csf_roundtrip_ok: bool = is_equal_approx(sm_csf_rt.content_scale_factor, 1.75)
	sm_csf_rt.free()
	# Effective menu scale divides out the global factor so menus stay a fixed on-screen
	# size: at menu factor 2.0, a global factor of 2.0 yields an on-screen 1.0, while a
	# global factor of 1.0 leaves it at 2.0. This is what stops the two multiplying.
	sm_csf.menu_scale_index = 6  # MENU_SCALE_LEVELS[6] == 2.0
	sm_csf.content_scale_factor = 2.0
	var eff_divided_ok: bool = is_equal_approx(sm_csf.get_effective_menu_scale(), 1.0)
	sm_csf.content_scale_factor = 1.0
	var eff_neutral_ok: bool = is_equal_approx(sm_csf.get_effective_menu_scale(), 2.0)
	# Public setter: normalizes into range, returns the applied value, and no-ops on an
	# unchanged value (a detached node's _apply_* early-out, so this asserts the field +
	# return contract the Settings slider relies on).
	var set_applied: float = sm_csf.set_content_scale_factor(2.5)
	var set_ok: bool = (
		is_equal_approx(set_applied, 2.5)
		and is_equal_approx(sm_csf.content_scale_factor, 2.5)
		and is_equal_approx(sm_csf.set_content_scale_factor(10.0), 4.0)  # clamp high
		and is_equal_approx(sm_csf.content_scale_factor, 4.0)
		and is_equal_approx(sm_csf.set_content_scale_factor(4.0), 4.0)
	)  # unchanged no-op
	sm_csf.free()
	sm.save()  # restore a current-schema cfg for anything loading it after this block
	# Headless fallback: with no display to expand into, _apply_content_scale must keep a
	# fixed logical base (aspect=KEEP, size=project base) so layout tests are deterministic
	# — never content_scale_size=(0,0), which would collapse the viewport to the 64x64
	# headless window and break every viewport-relative suite. The SettingsManager autoload
	# already applied this to the real root window on _ready, so assert on it directly.
	# The autoload enters the tree after the first frame in --script mode, so settle first.
	await process_frame
	var headless_fallback_ok: bool = (
		root.content_scale_size == sm._project_base_viewport()
		and root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP
	)
	if (
		csf_identity_ok
		and csf_clamp_ok
		and csf_default_ok
		and csf_fresh_ok
		and csf_load_ok
		and csf_roundtrip_ok
		and eff_divided_ok
		and eff_neutral_ok
		and headless_fallback_ok
		and set_ok
	):
		print("OK  content_scale_factor: identity default, clamp, round-trip, menu reconcile")
		passed += 1
	else:
		print(
			(
				"FAIL content_scale_factor: identity=%s clamp=%s default=%s fresh=%s load=%s rt=%s eff_div=%s eff_neu=%s headless=%s set=%s"
				% [
					csf_identity_ok,
					csf_clamp_ok,
					csf_default_ok,
					csf_fresh_ok,
					csf_load_ok,
					csf_roundtrip_ok,
					eff_divided_ok,
					eff_neutral_ok,
					headless_fallback_ok,
					set_ok
				]
			)
		)
		failed += 1

	# ---- controller layout: the two keys ControllerService persists ----------
	# Slice 4 step 1. The on-screen controller rebuilt its collection every launch,
	# so it was the one control setting that did not survive a reload. Stored raw
	# and validated by ControllerLayout when the service restores it, so this only
	# has to prove the cfg round-trip and the type guard — a hand-edited scalar
	# where an array belongs must not reach the service as one.
	var ctl_default_ok: bool = (
		sm.controller_combinations.is_empty() and sm.controller_active_id.is_empty()
	)
	var ctl_saved: Array = [{"schema_version": 1, "id": "slot-2", "profile": "virtual_gamepad"}]
	sm.controller_combinations = ctl_saved
	sm.controller_active_id = "slot-2"
	sm.save()
	var sm_ctl: Node = SettingsManagerS.new()
	sm_ctl.load_settings()
	var ctl_roundtrip_ok: bool = (
		sm_ctl.controller_combinations.size() == 1
		and String(sm_ctl.controller_combinations[0].get("id", "")) == "slot-2"
		and sm_ctl.controller_active_id == "slot-2"
	)
	sm_ctl.free()
	var ctl_bad_cfg := ConfigFile.new()
	ctl_bad_cfg.load(sm.SETTINGS_PATH)
	ctl_bad_cfg.set_value("controls", "controller_combinations", "not an array")
	ctl_bad_cfg.set_value("controls", "controller_active_id", 17)
	ctl_bad_cfg.save(sm.SETTINGS_PATH)
	var sm_ctl_bad: Node = SettingsManagerS.new()
	sm_ctl_bad.load_settings()
	var ctl_guard_ok: bool = (
		sm_ctl_bad.controller_combinations is Array
		and sm_ctl_bad.controller_combinations.is_empty()
		and sm_ctl_bad.controller_active_id.is_empty()
	)
	sm_ctl_bad.free()
	# Reset clears both, which is exactly the never-saved state the service falls
	# back to — not a third "reset" state it would need to recognise separately.
	sm.controller_combinations = ctl_saved
	sm.controller_active_id = "slot-2"
	sm.reset_section_to_defaults("controls")
	var ctl_reset_ok: bool = (
		sm.controller_combinations.is_empty() and sm.controller_active_id.is_empty()
	)
	sm.save()  # restore a clean cfg for anything loading it after this block
	if ctl_default_ok and ctl_roundtrip_ok and ctl_guard_ok and ctl_reset_ok:
		print("OK  controller layout: defaults, cfg round-trip, type guard, controls reset")
		passed += 1
	else:
		print(
			(
				"FAIL controller layout: default=%s roundtrip=%s guard=%s reset=%s"
				% [ctl_default_ok, ctl_roundtrip_ok, ctl_guard_ok, ctl_reset_ok]
			)
		)
		failed += 1

	# ---- controller auto-hide: the delay, snapped to the offered vocabulary ---
	# Slice 4 step 4. Deliberately NOT stored inside a combination like position and
	# size are: those describe one arrangement, this describes how long any of them
	# lingers, and per-slot it would have to be set six times to mean anything.
	var hide_default_ok: bool = is_equal_approx(sm.controller_auto_hide_seconds, 0.0)
	sm.controller_auto_hide_seconds = 10.0
	sm.save()
	var sm_hide: Node = SettingsManagerS.new()
	sm_hide.load_settings()
	var hide_roundtrip_ok: bool = is_equal_approx(sm_hide.controller_auto_hide_seconds, 10.0)
	sm_hide.free()
	# A value the dropdown cannot show would be a setting the player can see and
	# never reproduce, so loading snaps it to one that is offered rather than
	# clamping it into range.
	var hide_cfg := ConfigFile.new()
	hide_cfg.load(sm.SETTINGS_PATH)
	hide_cfg.set_value("controls", "controller_auto_hide_seconds", 9.0)
	hide_cfg.save(sm.SETTINGS_PATH)
	var sm_hide_odd: Node = SettingsManagerS.new()
	sm_hide_odd.load_settings()
	var hide_snap_ok: bool = is_equal_approx(sm_hide_odd.controller_auto_hide_seconds, 10.0)
	sm_hide_odd.free()
	hide_cfg.set_value("controls", "controller_auto_hide_seconds", "soon")
	hide_cfg.save(sm.SETTINGS_PATH)
	var sm_hide_bad: Node = SettingsManagerS.new()
	sm_hide_bad.load_settings()
	var hide_guard_ok: bool = is_equal_approx(sm_hide_bad.controller_auto_hide_seconds, 0.0)
	sm_hide_bad.free()
	sm.controller_auto_hide_seconds = 30.0
	sm.reset_section_to_defaults("controls")
	var hide_reset_ok: bool = is_equal_approx(sm.controller_auto_hide_seconds, 0.0)
	sm.save()
	if hide_default_ok and hide_roundtrip_ok and hide_snap_ok and hide_guard_ok and hide_reset_ok:
		print("OK  controller auto-hide: default off, round-trip, snap, type guard, reset")
		passed += 1
	else:
		print(
			(
				"FAIL controller auto-hide: default=%s roundtrip=%s snap=%s guard=%s reset=%s"
				% [
					hide_default_ok,
					hide_roundtrip_ok,
					hide_snap_ok,
					hide_guard_ok,
					hide_reset_ok,
				]
			)
		)
		failed += 1

	# ---- is_display_config_supported: true off Web (E1 desktop-only gate) ----
	# The test runner is a desktop headless build (no "web" feature), so the seam
	# must report supported here — i.e. desktop display config behaviour is unchanged.
	# On a Web export OS.has_feature("web") flips it to false, gating _apply_display.
	var display_supported_ok: bool = sm.is_display_config_supported() == true
	if display_supported_ok:
		print("OK  is_display_config_supported true on desktop (E1 gate inert off Web)")
		passed += 1
	else:
		print("FAIL is_display_config_supported should be true on a desktop build")
		failed += 1

	# ---- safe-area provider: ZERO on desktop, reflects a fed inset (D5/E6) ----
	# The single seam HUD/menu edge-anchoring reads. Zero on desktop/headless; a future
	# mobile-web feed sets safe_area_insets and the getter mirrors it with no re-plumbing.
	var safe_zero_ok: bool = sm.get_safe_area_insets() == Vector4i.ZERO
	sm.safe_area_insets = Vector4i(1, 2, 3, 4)
	var safe_feed_ok: bool = sm.get_safe_area_insets() == Vector4i(1, 2, 3, 4)
	sm.safe_area_insets = Vector4i.ZERO
	if safe_zero_ok and safe_feed_ok:
		print("OK  safe-area provider ZERO on desktop, mirrors a fed inset (D5/E6)")
		passed += 1
	else:
		print("FAIL safe-area provider: zero=%s feed=%s" % [safe_zero_ok, safe_feed_ok])
		failed += 1

	# ---- mobile-web default content scale (MOBILE-WEB-UX-GAPS-2026-08-03) ----
	# The largest 0.5 step that still fits 1280x720 in the actual canvas. An iPhone
	# landscape canvas backed at 3x (2556x1179) fits 1.5 on both axes; the same device
	# reported by CSS pixels alone (852x393) cannot reach even one design floor and
	# floors at the 0.5 minimum, which is what the screen-derived factor was picking.
	var fit_iphone: float = SettingsManagerS.fit_content_scale_factor_for_size(Vector2i(2556, 1179))
	var fit_css_only: float = SettingsManagerS.fit_content_scale_factor_for_size(Vector2i(852, 393))
	var fit_720p: float = SettingsManagerS.fit_content_scale_factor_for_size(Vector2i(1280, 720))
	# Snapping DOWN is the point: 1300/720 = 1.80 rounds UP to 2.0 under the identity
	# factor's snappedf, which would put the viewport at 650 logical px and clip every
	# layout authored to the 720 floor.
	var fit_snap_down: float = SettingsManagerS.fit_content_scale_factor_for_size(
		Vector2i(2400, 1300)
	)
	var fit_degenerate: float = SettingsManagerS.fit_content_scale_factor_for_size(Vector2i.ZERO)
	var mobile_fit_ok: bool = (
		is_equal_approx(fit_iphone, 1.5)
		and is_equal_approx(fit_css_only, 0.5)
		and is_equal_approx(fit_720p, 1.0)
		and is_equal_approx(fit_snap_down, 1.5)
		and is_equal_approx(fit_degenerate, 1.0)
	)
	if mobile_fit_ok:
		print("OK  mobile-web content scale fits the design floor and snaps down")
		passed += 1
	else:
		print(
			(
				"FAIL mobile-web fit: iphone=%s css=%s 720p=%s snap=%s degenerate=%s"
				% [fit_iphone, fit_css_only, fit_720p, fit_snap_down, fit_degenerate]
			)
		)
		failed += 1

	# ---- mobile-web safe-area conversion (MOBILE-WEB-UX-GAPS-2026-08-03) ----
	# The shell answers in CSS pixels; consumers subtract these from
	# get_viewport_rect().size, which is post-content-scale. Both conversions are
	# checked with an iPhone-shaped case: a 852x393 CSS canvas backed at 3x, notch
	# left/right in landscape, content scale 1.5. 47 CSS px * (2556/852) / 1.5 = 94.
	var iphone_insets: Vector4i = SettingsManagerS.safe_area_insets_from_shell(
		{"left": 47.0, "top": 0.0, "right": 47.0, "bottom": 21.0},
		Vector2(852.0, 393.0),
		Vector2i(2556, 1179),
		1.5
	)
	var iphone_ok: bool = iphone_insets == Vector4i(94, 0, 94, 42)
	# devicePixelRatio is NOT trusted: a shell reporting the same CSS rect as the
	# window pixels means one engine pixel per CSS pixel, whatever the DPR claims.
	var css_identity: Vector4i = SettingsManagerS.safe_area_insets_from_shell(
		{"left": 10.0, "top": 20.0, "right": 30.0, "bottom": 40.0},
		Vector2(1280.0, 720.0),
		Vector2i(1280, 720),
		1.0
	)
	var identity_ok: bool = css_identity == Vector4i(10, 20, 30, 40)
	# Degenerate inputs return ZERO rather than a guess: a zero-width canvas rect is
	# the shell answering before layout, and a bad scale would move every HUD panel.
	var pre_layout: Vector4i = SettingsManagerS.safe_area_insets_from_shell(
		{"left": 47.0}, Vector2.ZERO, Vector2i(2556, 1179), 1.5
	)
	var no_window: Vector4i = SettingsManagerS.safe_area_insets_from_shell(
		{"left": 47.0}, Vector2(852.0, 393.0), Vector2i.ZERO, 1.5
	)
	var bad_scale: Vector4i = SettingsManagerS.safe_area_insets_from_shell(
		{"left": 47.0}, Vector2(852.0, 393.0), Vector2i(2556, 1179), 0.0
	)
	var degenerate_ok: bool = (
		pre_layout == Vector4i.ZERO and no_window == Vector4i.ZERO and bad_scale == Vector4i.ZERO
	)
	# A browser without env(safe-area-inset-*) omits keys entirely, and a hostile or
	# broken value must not produce a negative inset that grows the usable rect.
	var absent: Vector4i = SettingsManagerS.safe_area_insets_from_shell(
		{"left": "nonsense", "bottom": -40.0}, Vector2(1280.0, 720.0), Vector2i(1280, 720), 1.0
	)
	var absent_ok: bool = absent == Vector4i.ZERO
	if iphone_ok and identity_ok and degenerate_ok and absent_ok:
		print("OK  shell CSS insets convert to viewport units and fail closed")
		passed += 1
	else:
		print(
			(
				"FAIL shell inset conversion: iphone=%s identity=%s degenerate=%s absent=%s"
				% [iphone_insets, css_identity, degenerate_ok, absent]
			)
		)
		failed += 1

	# ---- V027-04b: OS drag-resize write-back core (Q5: full write-back) ----
	# While windowed, an OS resize writes the actual client size into the saved
	# resolution and announces it. The size _apply_display itself requested and
	# degenerate sizes are ignored, so a dropdown apply never self-overwrites.
	var sm_wb: Node = SettingsManagerS.new()
	sm_wb.window_mode = "windowed"
	sm_wb.resolution = "1280x720"
	sm_wb._requested_window_size = Vector2i(1280, 720)
	var wb_signals: Array = []
	sm_wb.resolution_written_back.connect(func() -> void: wb_signals.append(true))
	sm_wb.apply_resize_write_back(Vector2i(1280, 720))  # our own resize — no-op
	var wb_own_ok: bool = sm_wb.resolution == "1280x720" and wb_signals.is_empty()
	sm_wb.apply_resize_write_back(Vector2i.ZERO)  # degenerate — no-op
	var wb_zero_ok: bool = sm_wb.resolution == "1280x720" and wb_signals.is_empty()
	sm_wb.apply_resize_write_back(Vector2i(1800, 1013))  # an OS drag
	var wb_written_ok: bool = sm_wb.resolution == "1800x1013" and wb_signals.size() == 1
	# A second identical report (coalesced hook re-fires) is a no-op again.
	sm_wb.apply_resize_write_back(Vector2i(1800, 1013))
	var wb_repeat_ok: bool = wb_signals.size() == 1
	# Persisted: a fresh instance loads the written-back custom size.
	var sm_wb_reload: Node = SettingsManagerS.new()
	sm_wb_reload.load_settings()
	var wb_persist_ok: bool = sm_wb_reload.resolution == "1800x1013"
	sm_wb_reload.free()
	# Restore the cfg for anything loading it after this suite.
	sm_wb.resolution = "1280x720"
	sm_wb.save()
	sm_wb.free()
	if wb_own_ok and wb_zero_ok and wb_written_ok and wb_repeat_ok and wb_persist_ok:
		print("OK  V027-04b write-back stores + persists OS sizes, skips our own resizes")
		passed += 1
	else:
		print(
			(
				"FAIL V027-04b write-back: own=%s zero=%s written=%s repeat=%s persist=%s"
				% [wb_own_ok, wb_zero_ok, wb_written_ok, wb_repeat_ok, wb_persist_ok]
			)
		)
		failed += 1

	# ---- V027-04a: viewport size_changed re-applies Menu Scale, coalesced ----
	# Nothing re-applied Menu Scale on a window resize, so a post-resize content
	# minimum change grew a live panel off-screen (v0.2.7 §1.6). The hook must fire
	# the group re-apply, and many same-frame resize events (an OS drag) must
	# coalesce into ONE deferred re-apply.
	# Use the live autoload when present — adding a second SettingsManager would
	# double-connect the hook and double-count the group calls. Autoloads only
	# enter the tree after the first frame in --script mode, so settle first.
	await process_frame
	var sm_rz: Node = root.get_node_or_null("SettingsManager")
	var sm_rz_owned: bool = false
	if sm_rz == null:
		sm_rz = SettingsManagerS.new()
		root.add_child(sm_rz)  # _ready() connects viewport size_changed
		sm_rz_owned = true
		await process_frame
	var scale_target := ScaleTarget.new()
	scale_target.add_to_group("menu_scale_targets")
	root.add_child(scale_target)
	var display_resize_signals: Array = []
	if sm_rz.has_signal("display_size_changed"):
		sm_rz.connect("display_size_changed", func() -> void: display_resize_signals.append(true))
	var calls_before: int = scale_target.calls
	sm_rz.get_viewport().size_changed.emit()
	sm_rz.get_viewport().size_changed.emit()
	sm_rz.get_viewport().size_changed.emit()
	await process_frame  # let the deferred re-apply run
	var coalesced_ok: bool = scale_target.calls == calls_before + 1
	var first_signal_ok: bool = display_resize_signals.size() == 1
	sm_rz.get_viewport().size_changed.emit()
	await process_frame
	var refires_ok: bool = scale_target.calls == calls_before + 2
	var second_signal_ok: bool = display_resize_signals.size() == 2
	var calls_after_viewport: int = scale_target.calls
	sm_rz.get_window().size_changed.emit()
	sm_rz.get_window().size_changed.emit()
	await process_frame
	var window_hook_ok: bool = (
		scale_target.calls == calls_after_viewport + 1 and display_resize_signals.size() == 3
	)
	if coalesced_ok and first_signal_ok and refires_ok and second_signal_ok and window_hook_ok:
		print("OK  V027-04a resize hooks re-apply Menu Scale and announce settled size")
		passed += 1
	else:
		print(
			(
				"FAIL V027-04a resize hook: before=%d calls=%d coalesced=%s refire=%s signals=%d window=%s"
				% [
					calls_before,
					scale_target.calls,
					coalesced_ok,
					refires_ok,
					display_resize_signals.size(),
					window_hook_ok
				]
			)
		)
		failed += 1
	scale_target.queue_free()

	# ---- V031-DSP-01: in-tree write-back defers the disk persist (settle) ----
	# Memory + readout update immediately, but save() waits for the settle
	# window so an OS drag does one disk write, not one per size event. Reuse
	# the in-tree instance from the V027-04a block; flush manually (the timer's
	# timeout path) rather than awaiting 0.75s of frames.
	var st_prev_mode: String = sm_rz.window_mode
	var st_prev_res: String = sm_rz.resolution
	sm_rz.window_mode = "windowed"
	sm_rz.resolution = "1280x720"
	sm_rz._requested_window_size = Vector2i(1280, 720)
	sm_rz.save()
	sm_rz.apply_resize_write_back(Vector2i(1500, 900))
	var st_pending_ok: bool = sm_rz._resize_save_pending and sm_rz.resolution == "1500x900"
	var st_probe: Node = SettingsManagerS.new()
	st_probe.load_settings()
	var st_deferred_ok: bool = st_probe.resolution == "1280x720"
	st_probe.free()
	sm_rz._flush_resize_settle_save()
	var st_flushed_ok: bool = not sm_rz._resize_save_pending
	var st_probe2: Node = SettingsManagerS.new()
	st_probe2.load_settings()
	var st_persisted_ok: bool = st_probe2.resolution == "1500x900"
	st_probe2.free()
	# A flush with nothing pending must not re-save (no infinite settle loops).
	sm_rz._flush_resize_settle_save()
	sm_rz.window_mode = st_prev_mode
	sm_rz.resolution = st_prev_res
	sm_rz._requested_window_size = Vector2i.ZERO
	sm_rz.save()
	if st_pending_ok and st_deferred_ok and st_flushed_ok and st_persisted_ok:
		print("OK  V031-DSP-01 write-back updates memory immediately and persists on settle")
		passed += 1
	else:
		print(
			(
				"FAIL V031-DSP-01 settle: pending=%s deferred=%s flushed=%s persisted=%s"
				% [st_pending_ok, st_deferred_ok, st_flushed_ok, st_persisted_ok]
			)
		)
		failed += 1

	if sm_rz_owned:
		sm_rz.queue_free()

	sm.free()
	# ---- [MRD-5] grid_dim round-trip + clamp + reset ----
	var sm_g: Node = SettingsManagerS.new()  # sm was freed above
	sm_g.grid_dim = 0.3
	sm_g.save()
	sm_g.grid_dim = 0.0
	sm_g.load_settings()
	var grid_roundtrip: bool = is_equal_approx(sm_g.grid_dim, 0.3)
	sm_g.set_grid_dim(1.0)
	var grid_clamp_hi: bool = is_equal_approx(sm_g.grid_dim, 0.5)
	sm_g.set_grid_dim(-1.0)
	var grid_clamp_lo: bool = is_equal_approx(sm_g.grid_dim, 0.0)
	sm_g.grid_dim = 0.4
	sm_g.reset_section_to_defaults("display")
	var grid_reset: bool = is_equal_approx(sm_g.grid_dim, 0.0)
	sm_g.free()
	if grid_roundtrip and grid_clamp_hi and grid_clamp_lo and grid_reset:
		print("OK  [MRD-5] grid_dim round-trips, clamps to [0,0.5], resets to 0")
		passed += 1
	else:
		print(
			(
				"FAIL [MRD-5] grid_dim: rt=%s hi=%s lo=%s reset=%s"
				% [grid_roundtrip, grid_clamp_hi, grid_clamp_lo, grid_reset]
			)
		)
		failed += 1

	# ---- [MRD-5] _apply_grid_dim fades only terrain group members ----
	var sm_dim: Node = SettingsManagerS.new()
	root.add_child(sm_dim)  # _ready runs against the isolated user:// cfg
	var terrain_stub := Node2D.new()  # a CanvasItem terrain stand-in
	terrain_stub.add_to_group("grid_dim_target")
	root.add_child(terrain_stub)
	var non_terrain := Node2D.new()  # units/overlays: NOT in the group
	root.add_child(non_terrain)
	await process_frame  # nodes aren't is_inside_tree() until a frame passes
	sm_dim.set_grid_dim(0.4)
	var terrain_faded: bool = is_equal_approx(terrain_stub.modulate.a, 0.6)
	var other_untouched: bool = is_equal_approx(non_terrain.modulate.a, 1.0)
	sm_dim.set_grid_dim(0.0)
	var terrain_restored: bool = is_equal_approx(terrain_stub.modulate.a, 1.0)
	if terrain_faded and other_untouched and terrain_restored:
		print("OK  [MRD-5] _apply_grid_dim fades only terrain group members")
		passed += 1
	else:
		print(
			(
				"FAIL [MRD-5] apply: faded=%s other=%s restored=%s"
				% [terrain_faded, other_untouched, terrain_restored]
			)
		)
		failed += 1

	# Printable confirm/cancel keys belong to a focused text editor, not to the
	# mirrored ui_accept/ui_cancel actions (v0.5.1 FileDialog return).
	var text_guard := SettingsManagerS.new()
	root.add_child(text_guard)
	var line := LineEdit.new()
	root.add_child(line)
	line.grab_focus()
	await process_frame
	for code in [KEY_X, KEY_Z]:
		var event := InputEventKey.new()
		event.pressed = true
		event.keycode = code
		event.physical_keycode = code
		event.unicode = code
		text_guard._input(event)
	if line.text == "XZ":
		print("OK  focused text entry receives printable X/Z before mirrored UI actions")
		passed += 1
	else:
		print("FAIL text-entry guard: %s" % line.text)
		failed += 1
	line.queue_free()
	var dialog: FileDialog = load("res://scripts/ui/FileDialogInputGuard.gd").new()
	root.add_child(dialog)
	dialog.popup_centered(Vector2i(640, 420))
	await process_frame
	var filename: LineEdit = dialog.get_line_edit()
	filename.text = ""
	filename.grab_focus()
	var dialog_x := InputEventKey.new()
	dialog_x.pressed = true
	dialog_x.keycode = KEY_X
	dialog_x.physical_keycode = KEY_X
	dialog_x.unicode = KEY_X
	Input.parse_input_event(dialog_x)
	await process_frame
	if dialog.visible and filename.text.to_lower() == "x":
		print("OK  dispatched X types into a real FileDialog without closing it")
		passed += 1
	else:
		print(
			"FAIL FileDialog text ownership: visible=%s text=%s" % [dialog.visible, filename.text]
		)
		failed += 1
	filename.grab_focus()
	var dialog_escape := InputEventKey.new()
	dialog_escape.pressed = true
	dialog_escape.keycode = KEY_ESCAPE
	dialog_escape.physical_keycode = KEY_ESCAPE
	# Exercise the Window's first-stage boundary directly. A global synthetic Escape
	# races other headless suites' windows when run_tests executes in parallel.
	dialog.call("_on_window_input", dialog_escape)
	await process_frame
	if dialog.visible and not filename.has_focus():
		print("OK  first FileDialog Escape leaves filename edit without closing the dialog")
		passed += 1
	else:
		print(
			(
				"FAIL FileDialog first Escape: visible=%s filename_focus=%s"
				% [dialog.visible, filename.has_focus()]
			)
		)
		failed += 1
	dialog.queue_free()
	text_guard.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
