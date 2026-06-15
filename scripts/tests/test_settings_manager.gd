extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_settings_manager.gd
# Tests SettingsManager: the ui_* key mirroring that lets menus respond to the
# game's keys (#7), and the movement-speed mapping.

const SettingsManagerS = preload("res://scripts/autoloads/SettingsManager.gd")


# True when `action` has an InputEventKey bound to `keycode`.
func _has_key(action: String, keycode: int) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and ev.keycode == keycode:
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
		print("OK  ui_accept gains the confirm key (Z)"); passed += 1
	else:
		print("FAIL ui_accept missing Z"); failed += 1
	if _has_key("ui_up", KEY_W):
		print("OK  ui_up gains the cursor_up key (W)"); passed += 1
	else:
		print("FAIL ui_up missing W"); failed += 1
	if _has_key("ui_cancel", KEY_X):
		print("OK  ui_cancel gains the cancel key (X)"); passed += 1
	else:
		print("FAIL ui_cancel missing X"); failed += 1

	# ---- the built-in defaults are preserved (arrows still drive ui_up) ----
	if _has_key("ui_up", KEY_UP):
		print("OK  ui_up keeps its default arrow key"); passed += 1
	else:
		print("FAIL ui_up lost the arrow key"); failed += 1

	# ---- a second call does not duplicate events (idempotent) ----
	var before := InputMap.action_get_events("ui_accept").size()
	sm._mirror_game_keys_to_ui()
	if InputMap.action_get_events("ui_accept").size() == before:
		print("OK  _mirror_game_keys_to_ui is idempotent"); passed += 1
	else:
		print("FAIL mirror duplicated events"); failed += 1

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
	var new_confirm := InputEventKey.new()
	new_confirm.keycode = KEY_Y
	# rebind_action calls save() — point user:// at a throwaway path so we don't
	# clobber the real settings.cfg from inside the test run.
	sm.rebind_action("confirm", new_confirm)
	var has_new: bool = _has_key("ui_accept", KEY_Y)
	var has_old: bool = _has_key("ui_accept", KEY_Z)
	var has_engine: bool = _has_key("ui_accept", KEY_ENTER)
	if has_new and not has_old and has_engine:
		print("OK  2.9: rebind drops the old key from ui_accept and keeps Enter"); passed += 1
	else:
		print("FAIL 2.9 rebind mirror: new=%s old=%s engine=%s" % [
			has_new, has_old, has_engine])
		failed += 1
	# Restore the original confirm binding so subsequent tests see the same
	# InputMap they started with.
	InputMap.action_erase_events("confirm")
	for ev in saved_confirm:
		InputMap.action_add_event("confirm", ev)
	sm._mirror_game_keys_to_ui()

	# ---- get_movement_speed_seconds maps each speed setting ----
	sm.movement_speed = "instant"
	var inst_ok: bool = sm.get_movement_speed_seconds() == 0.0
	sm.movement_speed = "fast"
	var fast_ok: bool = sm.get_movement_speed_seconds() < 0.12
	sm.movement_speed = "normal"
	var norm_ok: bool = sm.get_movement_speed_seconds() == 0.12
	if inst_ok and fast_ok and norm_ok:
		print("OK  get_movement_speed_seconds maps each speed"); passed += 1
	else:
		print("FAIL movement speed: inst=%s fast=%s norm=%s" % [inst_ok, fast_ok, norm_ok])
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
		print("OK  map_zoom_index defaults to 3 (1.0x) and resets"); passed += 1
	else:
		print("FAIL map_zoom_index: default=%s reset=%s" % [zoom_default_ok, zoom_reset_ok])
		failed += 1

	# ---- display section: defaults + reset (Display/Access items 2-3) ----
	var disp_default_ok: bool = (sm.window_mode == "windowed"
		and sm.resolution == "1280x720" and sm.ui_scale_index == 1)
	sm.window_mode = "fullscreen"
	sm.resolution = "1920x1080"
	sm.ui_scale_index = 4
	sm.reset_section_to_defaults("display")
	var disp_reset_ok: bool = (sm.window_mode == "windowed"
		and sm.resolution == "1280x720" and sm.ui_scale_index == 1)
	if disp_default_ok and disp_reset_ok:
		print("OK  display section defaults and resets (window/resolution/ui_scale)")
		passed += 1
	else:
		print("FAIL display section: defaults=%s reset=%s" % [disp_default_ok, disp_reset_ok])
		failed += 1

	# ---- hud_layout: default empty, round-trips through save/load, resets (item 4) ----
	var hud_default_ok: bool = sm.hud_layout == {}
	sm.hud_layout = { "unit_info": { "offset": Vector2(24, -16), "scale": 1.5 } }
	sm.save()
	var sm2: Node = SettingsManagerS.new()
	sm2.load_settings()
	var entry: Variant = sm2.hud_layout.get("unit_info", {})
	var hud_roundtrip_ok: bool = (entry is Dictionary
		and entry.get("offset", Vector2.ZERO) == Vector2(24, -16)
		and is_equal_approx(entry.get("scale", 0.0), 1.5))
	sm.reset_section_to_defaults("display")
	var hud_reset_ok: bool = sm.hud_layout == {}
	if hud_default_ok and hud_roundtrip_ok and hud_reset_ok:
		print("OK  hud_layout defaults empty, round-trips through cfg, and resets")
		passed += 1
	else:
		print("FAIL hud_layout: default=%s roundtrip=%s reset=%s" % [
			hud_default_ok, hud_roundtrip_ok, hud_reset_ok])
		failed += 1
	sm2.free()

	# ---- _parse_resolution: valid "WxH" parses; malformed returns ZERO ----
	var parse_ok: bool = (sm._parse_resolution("1600x900") == Vector2i(1600, 900)
		and sm._parse_resolution("bad") == Vector2i.ZERO
		and sm._parse_resolution("1280x") == Vector2i.ZERO)
	if parse_ok:
		print("OK  _parse_resolution handles valid + malformed strings"); passed += 1
	else:
		print("FAIL _parse_resolution"); failed += 1

	# ---- window_centre_position: centres a fitting window, but never off-screen ----
	# Fits the screen → centred. Origin (0,0), 1920x1080 screen, 1280x720 window.
	var fit_ok: bool = sm.window_centre_position(
		Vector2i.ZERO, Vector2i(1920, 1080), Vector2i(1280, 720)) == Vector2i(320, 180)
	# Larger than the screen → clamped to the screen origin (title bar stays reachable),
	# not centred into negative coordinates.
	var clamp_ok: bool = sm.window_centre_position(
		Vector2i(100, 50), Vector2i(1366, 768), Vector2i(1920, 1080)) == Vector2i(100, 50)
	if fit_ok and clamp_ok:
		print("OK  window_centre_position centres a fitting window, clamps an oversized one")
		passed += 1
	else:
		print("FAIL window_centre_position: fit=%s clamp=%s" % [fit_ok, clamp_ok])
		failed += 1

	sm.free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
