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

	sm.free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
