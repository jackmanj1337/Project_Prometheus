extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_map_cursor_input.gd
# Unit tests for the MapCursorInput slice (D-3): key-event decoding and the held-key
# auto-repeat timer. decode_key relies on the project InputMap (loaded from project
# settings in --script mode), so events are built with keycodes matching that map.

# Build a key event with the given keycode. The project InputMap entries match on
# `keycode` (physical_keycode is 0 for all of them), so setting keycode is enough.
func _key(keycode: int, pressed: bool = true) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.pressed = pressed
	return e


func _init() -> void:
	print("=== MapCursorInput Test ===")
	var passed := 0
	var failed := 0

	var inp: MapCursorInput = MapCursorInput.new()

	# ---- decode_key: confirm / cancel / next_unit ----
	if inp.decode_key(_key(KEY_Z))["intent"] == MapCursorInput.Intent.CONFIRM:
		print("OK  decode_key(Z) → CONFIRM"); passed += 1
	else:
		print("FAIL decode_key(Z)"); failed += 1

	if inp.decode_key(_key(KEY_X))["intent"] == MapCursorInput.Intent.CANCEL:
		print("OK  decode_key(X) → CANCEL"); passed += 1
	else:
		print("FAIL decode_key(X)"); failed += 1

	if inp.decode_key(_key(KEY_TAB))["intent"] == MapCursorInput.Intent.NEXT_UNIT:
		print("OK  decode_key(Tab) → NEXT_UNIT"); passed += 1
	else:
		print("FAIL decode_key(Tab)"); failed += 1

	# ---- decode_key: each direction → MOVE + the right vector ----
	var dir_cases := {
		KEY_W: Vector2i(0, -1), KEY_S: Vector2i(0, 1),
		KEY_A: Vector2i(-1, 0), KEY_D: Vector2i(1, 0),
	}
	for kc in dir_cases:
		var d := inp.decode_key(_key(kc))
		if d["intent"] == MapCursorInput.Intent.MOVE and d["dir"] == dir_cases[kc]:
			print("OK  decode_key direction → MOVE %s" % str(dir_cases[kc])); passed += 1
		else:
			print("FAIL decode_key direction: keycode=%d got %s" % [kc, str(d)]); failed += 1

	# ---- decode_key: ESCAPE → CANCEL (cancel binds both X and ESCAPE) ----
	if inp.decode_key(_key(KEY_ESCAPE))["intent"] == MapCursorInput.Intent.CANCEL:
		print("OK  decode_key(Escape) → CANCEL"); passed += 1
	else:
		print("FAIL decode_key(Escape)"); failed += 1

	# ---- decode_key: M → OPEN_MENU (rebound off ESCAPE, so now reachable) ----
	if inp.decode_key(_key(KEY_M))["intent"] == MapCursorInput.Intent.OPEN_MENU:
		print("OK  decode_key(M) → OPEN_MENU"); passed += 1
	else:
		print("FAIL decode_key(M)"); failed += 1

	# ---- decode_key: O → OPEN_SETTINGS ----
	if inp.decode_key(_key(KEY_O))["intent"] == MapCursorInput.Intent.OPEN_SETTINGS:
		print("OK  decode_key(O) → OPEN_SETTINGS"); passed += 1
	else:
		print("FAIL decode_key(O)"); failed += 1

	# ---- decode_key: an unmapped key → NONE ----
	if inp.decode_key(_key(KEY_J))["intent"] == MapCursorInput.Intent.NONE:
		print("OK  decode_key(unmapped) → NONE"); passed += 1
	else:
		print("FAIL decode_key(unmapped)"); failed += 1

	# ---- tick before any arm_repeat → ZERO ----
	var ti: MapCursorInput = MapCursorInput.new()
	if ti.tick(0.1) == Vector2i.ZERO:
		print("OK  tick before arm_repeat → ZERO"); passed += 1
	else:
		print("FAIL tick before arm"); failed += 1

	# ---- arm_repeat + tick: ZERO before DELAY (0.25s), direction once it elapses ----
	ti.arm_repeat(Vector2i(1, 0))
	var before := ti.tick(0.20)            # 0.20 < 0.25 → not yet
	var first := ti.tick(0.10)             # crosses 0.25 → fires
	if before == Vector2i.ZERO and first == Vector2i(1, 0):
		print("OK  arm_repeat: tick is ZERO before DELAY, direction after"); passed += 1
	else:
		print("FAIL arm_repeat timing: before=%s first=%s" % [str(before), str(first)])
		failed += 1

	# ---- the first auto-repeat uses RATE (the old double-DELAY quirk is fixed) ----
	# After the first fire the timer is re-armed with RATE (0.10), so the next repeat
	# lands one RATE later — no second DELAY wait.
	if ti.tick(0.10) == Vector2i(1, 0):
		print("OK  first auto-repeat uses RATE (double-DELAY quirk fixed)"); passed += 1
	else:
		print("FAIL first repeat: expected RATE cadence"); failed += 1

	# ---- subsequent repeats also use RATE (0.10s) ----
	if ti.tick(0.10) == Vector2i(1, 0):
		print("OK  subsequent repeats use RATE cadence"); passed += 1
	else:
		print("FAIL RATE cadence"); failed += 1

	# ---- note_key_released clears the held direction when the key matches ----
	ti.arm_repeat(Vector2i(1, 0))
	ti.note_key_released(_key(KEY_A, false))   # cursor_left released — does not match
	var still_held := ti._held_dir == Vector2i(1, 0)
	ti.note_key_released(_key(KEY_D, false))   # cursor_right released — matches
	if still_held and ti._held_dir == Vector2i.ZERO:
		print("OK  note_key_released clears _held_dir only on a matching key"); passed += 1
	else:
		print("FAIL note_key_released: still_held=%s now=%s" % [still_held, str(ti._held_dir)])
		failed += 1

	# ---- clear_repeat drops the held direction ----
	ti.arm_repeat(Vector2i(0, 1))
	ti.clear_repeat()
	if ti._held_dir == Vector2i.ZERO:
		print("OK  clear_repeat clears _held_dir"); passed += 1
	else:
		print("FAIL clear_repeat: _held_dir=%s" % str(ti._held_dir)); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
