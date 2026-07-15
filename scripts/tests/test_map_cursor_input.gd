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


func _pad_button(button_index: int, pressed: bool = true) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button_index
	e.pressed = pressed
	return e


func _init() -> void:
	print("=== MapCursorInput Test ===")
	var passed := 0
	var failed := 0

	var inp: MapCursorInput = MapCursorInput.new()

	# ---- decode_key: confirm / cancel / next_unit ----
	if inp.decode(_key(KEY_Z))["intent"] == MapCursorInput.Intent.CONFIRM:
		print("OK  decode(Z) → CONFIRM")
		passed += 1
	else:
		print("FAIL decode(Z)")
		failed += 1

	if inp.decode(_key(KEY_X))["intent"] == MapCursorInput.Intent.CANCEL:
		print("OK  decode(X) → CANCEL")
		passed += 1
	else:
		print("FAIL decode(X)")
		failed += 1

	if inp.decode(_key(KEY_TAB))["intent"] == MapCursorInput.Intent.NEXT_UNIT:
		print("OK  decode(Tab) → NEXT_UNIT")
		passed += 1
	else:
		print("FAIL decode(Tab)")
		failed += 1

	# ---- decode_key: Shift+Tab → PREV_UNIT (#3) ----
	# Shift+Tab also matches the modifier-less next_unit action, so decode_key
	# must check prev_unit first. Plain Tab above must still decode as NEXT_UNIT.
	var shift_tab := _key(KEY_TAB)
	shift_tab.shift_pressed = true
	if inp.decode(shift_tab)["intent"] == MapCursorInput.Intent.PREV_UNIT:
		print("OK  decode(Shift+Tab) → PREV_UNIT")
		passed += 1
	else:
		print("FAIL decode(Shift+Tab)")
		failed += 1

	# ---- decode_key: each direction → MOVE + the right vector ----
	var dir_cases := {
		KEY_W: Vector2i(0, -1),
		KEY_S: Vector2i(0, 1),
		KEY_A: Vector2i(-1, 0),
		KEY_D: Vector2i(1, 0),
	}
	for kc in dir_cases:
		var d := inp.decode(_key(kc))
		if d["intent"] == MapCursorInput.Intent.MOVE and d["dir"] == dir_cases[kc]:
			print("OK  decode direction → MOVE %s" % str(dir_cases[kc]))
			passed += 1
		else:
			print("FAIL decode direction: keycode=%d got %s" % [kc, str(d)])
			failed += 1

	# ---- decode_key: ESCAPE → CANCEL (cancel binds both X and ESCAPE) ----
	if inp.decode(_key(KEY_ESCAPE))["intent"] == MapCursorInput.Intent.CANCEL:
		print("OK  decode(Escape) → CANCEL")
		passed += 1
	else:
		print("FAIL decode(Escape)")
		failed += 1

	# ---- decode_key: M → OPEN_MENU (rebound off ESCAPE, so now reachable) ----
	if inp.decode(_key(KEY_M))["intent"] == MapCursorInput.Intent.OPEN_MENU:
		print("OK  decode(M) → OPEN_MENU")
		passed += 1
	else:
		print("FAIL decode(M)")
		failed += 1

	# ---- decode_key: O → OPEN_SETTINGS ----
	if inp.decode(_key(KEY_O))["intent"] == MapCursorInput.Intent.OPEN_SETTINGS:
		print("OK  decode(O) → OPEN_SETTINGS")
		passed += 1
	else:
		print("FAIL decode(O)")
		failed += 1

	# ---- decode_key: I → INSPECT_UNIT (#1) ----
	if inp.decode(_key(KEY_I))["intent"] == MapCursorInput.Intent.INSPECT_UNIT:
		print("OK  decode(I) → INSPECT_UNIT")
		passed += 1
	else:
		print("FAIL decode(I)")
		failed += 1

	# ---- decode_key: an unmapped key → NONE ----
	if inp.decode(_key(KEY_J))["intent"] == MapCursorInput.Intent.NONE:
		print("OK  decode(unmapped) → NONE")
		passed += 1
	else:
		print("FAIL decode(unmapped)")
		failed += 1

	# ---- decode: d-pad button events use the same MOVE intent path ----
	var dpad := inp.decode(_pad_button(JOY_BUTTON_DPAD_RIGHT))
	if dpad["intent"] == MapCursorInput.Intent.MOVE and dpad["dir"] == Vector2i(1, 0):
		print("OK  decode(D-pad Right) → MOVE (1, 0)")
		passed += 1
	else:
		print("FAIL decode(D-pad Right): got %s" % str(dpad))
		failed += 1

	var pad_cases := [
		[JOY_BUTTON_A, MapCursorInput.Intent.CONFIRM, "Pad A"],
		[JOY_BUTTON_B, MapCursorInput.Intent.CANCEL, "Pad B"],
		[JOY_BUTTON_RIGHT_SHOULDER, MapCursorInput.Intent.NEXT_UNIT, "RB"],
		[JOY_BUTTON_LEFT_SHOULDER, MapCursorInput.Intent.PREV_UNIT, "LB"],
		[JOY_BUTTON_START, MapCursorInput.Intent.OPEN_MENU, "Start"],
		[JOY_BUTTON_Y, MapCursorInput.Intent.INSPECT_UNIT, "Pad Y"],
	]
	for row in pad_cases:
		var decoded := inp.decode(_pad_button(row[0]))
		if decoded["intent"] == row[1]:
			print("OK  decode(%s) → expected intent" % row[2])
			passed += 1
		else:
			print("FAIL decode(%s): got %s" % [row[2], str(decoded)])
			failed += 1

	# ---- tick before any arm_repeat → ZERO ----
	var ti: MapCursorInput = MapCursorInput.new()
	if ti.tick(0.1) == Vector2i.ZERO:
		print("OK  tick before arm_repeat → ZERO")
		passed += 1
	else:
		print("FAIL tick before arm")
		failed += 1

	# ---- arm_repeat + tick: ZERO before DELAY (0.25s), direction once it elapses ----
	ti.arm_repeat(Vector2i(1, 0))
	var before := ti.tick(0.20)  # 0.20 < 0.25 → not yet
	var first := ti.tick(0.10)  # crosses 0.25 → fires
	if before == Vector2i.ZERO and first == Vector2i(1, 0):
		print("OK  arm_repeat: tick is ZERO before DELAY, direction after")
		passed += 1
	else:
		print("FAIL arm_repeat timing: before=%s first=%s" % [str(before), str(first)])
		failed += 1

	# ---- the first auto-repeat uses RATE (the old double-DELAY quirk is fixed) ----
	# After the first fire the timer is re-armed with RATE (0.10), so the next repeat
	# lands one RATE later — no second DELAY wait.
	if ti.tick(0.10) == Vector2i(1, 0):
		print("OK  first auto-repeat uses RATE (double-DELAY quirk fixed)")
		passed += 1
	else:
		print("FAIL first repeat: expected RATE cadence")
		failed += 1

	# ---- subsequent repeats also use RATE (0.10s) ----
	if ti.tick(0.10) == Vector2i(1, 0):
		print("OK  subsequent repeats use RATE cadence")
		passed += 1
	else:
		print("FAIL RATE cadence")
		failed += 1

	# ---- note_key_released clears the held direction when the key matches ----
	ti.arm_repeat(Vector2i(1, 0))
	ti.note_released(_key(KEY_A, false))  # cursor_left released — does not match
	var still_held := ti._held_dir == Vector2i(1, 0)
	ti.note_released(_key(KEY_D, false))  # cursor_right released — matches
	if still_held and ti._held_dir == Vector2i.ZERO:
		print("OK  note_released clears _held_dir only on a matching key")
		passed += 1
	else:
		print("FAIL note_released: still_held=%s now=%s" % [still_held, str(ti._held_dir)])
		failed += 1

	# ---- note_released handles d-pad releases too ----
	ti.arm_repeat(Vector2i(0, -1))
	ti.note_released(_pad_button(JOY_BUTTON_DPAD_UP, false))
	if ti._held_dir == Vector2i.ZERO:
		print("OK  note_released clears held d-pad direction")
		passed += 1
	else:
		print("FAIL d-pad release held_dir=%s" % str(ti._held_dir))
		failed += 1

	# ---- clear_repeat drops the held direction ----
	ti.arm_repeat(Vector2i(0, 1))
	ti.clear_repeat()
	if ti._held_dir == Vector2i.ZERO:
		print("OK  clear_repeat clears _held_dir")
		passed += 1
	else:
		print("FAIL clear_repeat: _held_dir=%s" % str(ti._held_dir))
		failed += 1

	# ---- poll_direction: stick/action vector moves immediately, then repeats ----
	Input.action_press("cursor_right", 1.0)
	var poll_first := ti.poll_direction(0.01)
	var poll_before := ti.poll_direction(0.20)
	var poll_repeat := ti.poll_direction(0.10)
	Input.action_release("cursor_right")
	ti.poll_direction(0.01)
	if (
		poll_first == Vector2i(1, 0)
		and poll_before == Vector2i.ZERO
		and poll_repeat == Vector2i(1, 0)
		and ti._held_dir == Vector2i.ZERO
	):
		print("OK  poll_direction immediate move, delay, repeat, then clears")
		passed += 1
	else:
		print(
			(
				"FAIL poll_direction: first=%s before=%s repeat=%s held=%s"
				% [str(poll_first), str(poll_before), str(poll_repeat), str(ti._held_dir)]
			)
		)
		failed += 1

	# ---- poll_direction chooses the dominant axis for diagonal stick input ----
	Input.action_press("cursor_right", 0.4)
	Input.action_press("cursor_down", 0.8)
	var dominant := ti.poll_direction(0.01)
	Input.action_release("cursor_right")
	Input.action_release("cursor_down")
	ti.poll_direction(0.01)
	if dominant == Vector2i(0, 1):
		print("OK  poll_direction uses dominant axis for diagonal vectors")
		passed += 1
	else:
		print("FAIL poll_direction dominant axis: %s" % str(dominant))
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
