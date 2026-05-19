class_name MapCursorInput extends RefCounted
# Keyboard decoding + held-key auto-repeat, extracted from MapCursor (D-3 slice).
#
# A plain RefCounted, not a Node: Godot only delivers _unhandled_input / _process to
# a Node in the tree, so MapCursor stays the input receiver and forwards raw key
# events here. This object is a state-agnostic decoder plus the auto-repeat timer —
# no SceneTree needed, so it is fully unit-testable.

# Key-repeat timings — source of truth is GameConstants (aliases for readability).
const KEY_REPEAT_DELAY: float = GameConstants.CURSOR_KEY_REPEAT_DELAY
const KEY_REPEAT_RATE: float  = GameConstants.CURSOR_KEY_REPEAT_RATE

# What a key event means. MapCursor maps a MOVE to a cursor step / target cycle /
# no-op depending on its _state — the decoding here is deliberately state-agnostic.
enum Intent { NONE, MOVE, CONFIRM, CANCEL, NEXT_UNIT, OPEN_MENU, OPEN_SETTINGS }

# Held-direction auto-repeat timer state.
var _held_dir: Vector2i = Vector2i.ZERO
var _held_timer: float = 0.0


# State-agnostic key decode. The caller (MapCursor._unhandled_input) has already
# filtered to pressed, non-echo key events — this does not re-check. Returns
# {"intent": Intent, "dir": Vector2i}; dir is ZERO unless intent is MOVE.
# The action checks run in the same order as the old _handle_key_press if/elif
# chain, so a key bound to two actions resolves to the first one listed here.
func decode_key(event: InputEventKey) -> Dictionary:
	var dir := _direction_from_event(event)
	if dir != Vector2i.ZERO:
		return {"intent": Intent.MOVE, "dir": dir}
	if event.is_action_pressed("confirm"):
		return {"intent": Intent.CONFIRM, "dir": Vector2i.ZERO}
	if event.is_action_pressed("cancel"):
		return {"intent": Intent.CANCEL, "dir": Vector2i.ZERO}
	if event.is_action_pressed("next_unit"):
		return {"intent": Intent.NEXT_UNIT, "dir": Vector2i.ZERO}
	if event.is_action_pressed("open_menu"):
		return {"intent": Intent.OPEN_MENU, "dir": Vector2i.ZERO}
	if event.is_action_pressed("open_settings"):
		return {"intent": Intent.OPEN_SETTINGS, "dir": Vector2i.ZERO}
	return {"intent": Intent.NONE, "dir": Vector2i.ZERO}


func _direction_from_event(event: InputEventKey) -> Vector2i:
	if event.is_action_pressed("cursor_up"):    return Vector2i(0, -1)
	if event.is_action_pressed("cursor_down"):  return Vector2i(0, 1)
	if event.is_action_pressed("cursor_left"):  return Vector2i(-1, 0)
	if event.is_action_pressed("cursor_right"): return Vector2i(1, 0)
	return Vector2i.ZERO


# Arm the auto-repeat timer on a fresh direction press — the initial DELAY pause.
func arm_repeat(dir: Vector2i) -> void:
	_held_dir = dir
	_held_timer = KEY_REPEAT_DELAY


# Clear the held direction if the released key matches it.
func note_key_released(event: InputEventKey) -> void:
	var dir := Vector2i.ZERO
	if event.is_action_released("cursor_up"):      dir = Vector2i(0, -1)
	elif event.is_action_released("cursor_down"):  dir = Vector2i(0, 1)
	elif event.is_action_released("cursor_left"):  dir = Vector2i(-1, 0)
	elif event.is_action_released("cursor_right"): dir = Vector2i(1, 0)
	if dir != Vector2i.ZERO and _held_dir == dir:
		_held_dir = Vector2i.ZERO


# Drop any held direction and reset the timer — called by MapCursor.lock().
func clear_repeat() -> void:
	_held_dir = Vector2i.ZERO
	_held_timer = 0.0


# Per-frame auto-repeat tick. Returns a step direction when the timer fires this
# frame, ZERO otherwise. The initial press waits KEY_REPEAT_DELAY (set by
# arm_repeat); every repeat after that waits KEY_REPEAT_RATE — a flat 0.25s pause
# then 0.10s per step, as the cursor UX intends.
func tick(delta: float) -> Vector2i:
	if _held_dir == Vector2i.ZERO:
		return Vector2i.ZERO
	_held_timer -= delta
	if _held_timer <= 0.0:
		_held_timer = KEY_REPEAT_RATE
		return _held_dir
	return Vector2i.ZERO
