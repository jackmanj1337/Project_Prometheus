extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_settings_manager.gd
# Tests SettingsManager: the ui_* key mirroring that lets menus respond to the
# game's keys (#7), and the movement-speed mapping.

const SettingsManagerS = preload("res://scripts/autoloads/SettingsManager.gd")


# Counts group re-apply calls for the V027-04a resize-hook test.
class ScaleTarget extends Control:
	var calls: int = 0

	func apply_menu_scale(_factor: float) -> void:
		calls += 1


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
	var has_confirm_pad: bool = _has_joy_button("confirm", JOY_BUTTON_A)
	var has_ui_pad: bool = _has_joy_button("ui_accept", JOY_BUTTON_A)
	if has_new and not has_old and has_engine and has_confirm_pad and has_ui_pad:
		print("OK  2.9: rebind drops old key, keeps Enter, and preserves Pad A"); passed += 1
	else:
		print("FAIL 2.9 rebind mirror: new=%s old=%s engine=%s pad=%s ui_pad=%s" % [
			has_new, has_old, has_engine, has_confirm_pad, has_ui_pad])
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

	# ---- V021-17: mouse_cursor vocabulary defaults, resets, and migrates legacy values ----
	var modes_ok: bool = sm.VALID_MOUSE_CURSOR_MODES == ["follow", "click", "disabled"]
	var mouse_default_ok: bool = sm.mouse_cursor == "follow"
	var mouse_migration_ok: bool = (sm.normalize_mouse_cursor_mode("enabled") == "follow"
		and sm.normalize_mouse_cursor_mode("snap") == "click"
		and sm.normalize_mouse_cursor_mode("disabled") == "disabled"
		and sm.normalize_mouse_cursor_mode("bad") == "follow")
	sm.mouse_cursor = "click"
	sm.reset_section_to_defaults("gameplay")
	var mouse_reset_ok: bool = sm.mouse_cursor == "follow"
	if modes_ok and mouse_default_ok and mouse_migration_ok and mouse_reset_ok:
		print("OK  V021-17 mouse_cursor modes default/reset and migrate legacy values")
		passed += 1
	else:
		print("FAIL mouse_cursor modes: modes=%s default=%s migration=%s reset=%s" % [
			modes_ok, mouse_default_ok, mouse_migration_ok, mouse_reset_ok])
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
		and sm.resolution == "1280x720" and sm.menu_scale_index == 2
		and sm.MENU_SCALE_LEVELS == [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0])
	sm.window_mode = "fullscreen"
	sm.resolution = "1920x1080"
	sm.menu_scale_index = 4
	sm.reset_section_to_defaults("display")
	var disp_reset_ok: bool = (sm.window_mode == "windowed"
		and sm.resolution == "1280x720" and sm.menu_scale_index == 2)
	# V021-19: the curated list must offer native 1440p + 4K alongside the smaller modes,
	# and they must parse to the expected pixel sizes.
	var hi_res_ok: bool = (sm.RESOLUTION_CHOICES.has("2560x1440")
		and sm.RESOLUTION_CHOICES.has("3840x2160")
		and sm._parse_resolution("2560x1440") == Vector2i(2560, 1440)
		and sm._parse_resolution("3840x2160") == Vector2i(3840, 2160))
	if disp_default_ok and disp_reset_ok and hi_res_ok:
		print("OK  display section defaults/resets + offers native 1440p/4K (V021-19)")
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

	# V023-06: windowed native-size choices clamp inside the usable display so the
	# OS title bar remains reachable. Borderless/fullscreen keep exact native modes
	# through separate DisplayServer window modes, so this helper is windowed only.
	var win_fit_ok: bool = sm.windowed_client_size_for_screen(
		Vector2i(2560, 1440), Vector2i(3840, 2160)) == Vector2i(2560, 1440)
	var win_clamped: Vector2i = sm.windowed_client_size_for_screen(
		Vector2i(3840, 2160), Vector2i(3840, 2160))
	var win_clamp_ok: bool = win_clamped.x < 3840 and win_clamped.y < 2160 \
		and absf((float(win_clamped.x) / float(win_clamped.y)) - (16.0 / 9.0)) < 0.001
	if win_fit_ok and win_clamp_ok:
		print("OK  windowed client size keeps monitor-sized choices inside titled window bounds")
		passed += 1
	else:
		print("FAIL windowed size clamp: fit=%s clamped=%s" % [win_fit_ok, win_clamped])
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
		print("OK  applied_windowed_size returns a size for valid res, ZERO for malformed (V025-06)")
		passed += 1
	else:
		print("FAIL applied_windowed_size: valid=%s bad=%s" % [applied_valid, applied_bad])
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
		print("FAIL menu-scale migration: shift=%s v2=%s absent=%s" % [
			mig_shift_ok, mig_v2_ok, mig_absent_ok])
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
	sm_wb.apply_resize_write_back(Vector2i.ZERO)        # degenerate — no-op
	var wb_zero_ok: bool = sm_wb.resolution == "1280x720" and wb_signals.is_empty()
	sm_wb.apply_resize_write_back(Vector2i(1800, 1013)) # an OS drag
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
		print("FAIL V027-04b write-back: own=%s zero=%s written=%s repeat=%s persist=%s" % [
			wb_own_ok, wb_zero_ok, wb_written_ok, wb_repeat_ok, wb_persist_ok])
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
	var calls_before: int = scale_target.calls
	sm_rz.get_viewport().size_changed.emit()
	sm_rz.get_viewport().size_changed.emit()
	sm_rz.get_viewport().size_changed.emit()
	await process_frame  # let the deferred re-apply run
	var coalesced_ok: bool = scale_target.calls == calls_before + 1
	sm_rz.get_viewport().size_changed.emit()
	await process_frame
	var refires_ok: bool = scale_target.calls == calls_before + 2
	if coalesced_ok and refires_ok:
		print("OK  V027-04a size_changed re-applies Menu Scale once per settled frame")
		passed += 1
	else:
		print("FAIL V027-04a resize hook: before=%d after3=%d refire=%s" % [
			calls_before, scale_target.calls, refires_ok])
		failed += 1
	scale_target.queue_free()
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
		print("OK  [MRD-5] grid_dim round-trips, clamps to [0,0.5], resets to 0"); passed += 1
	else:
		print("FAIL [MRD-5] grid_dim: rt=%s hi=%s lo=%s reset=%s" % [
			grid_roundtrip, grid_clamp_hi, grid_clamp_lo, grid_reset]); failed += 1

	# ---- [MRD-5] _apply_grid_dim fades only terrain group members ----
	var sm_dim: Node = SettingsManagerS.new()
	root.add_child(sm_dim)  # _ready runs against the isolated user:// cfg
	var terrain_stub := Node2D.new()       # a CanvasItem terrain stand-in
	terrain_stub.add_to_group("grid_dim_target")
	root.add_child(terrain_stub)
	var non_terrain := Node2D.new()        # units/overlays: NOT in the group
	root.add_child(non_terrain)
	await process_frame  # nodes aren't is_inside_tree() until a frame passes
	sm_dim.set_grid_dim(0.4)
	var terrain_faded: bool = is_equal_approx(terrain_stub.modulate.a, 0.6)
	var other_untouched: bool = is_equal_approx(non_terrain.modulate.a, 1.0)
	sm_dim.set_grid_dim(0.0)
	var terrain_restored: bool = is_equal_approx(terrain_stub.modulate.a, 1.0)
	if terrain_faded and other_untouched and terrain_restored:
		print("OK  [MRD-5] _apply_grid_dim fades only terrain group members"); passed += 1
	else:
		print("FAIL [MRD-5] apply: faded=%s other=%s restored=%s" % [
			terrain_faded, other_untouched, terrain_restored]); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
