extends RefCounted
# Shared directional auto-repeat + deadzone policy for custom modal menus
# (ActionMenu, UnitDetailsScreen) and any screen that wants tuned held-direction
# stepping instead of per-event action checks (V030-GP-01 repeat half / V030-GP-02).
#
# No `class_name`: callers `preload()` this and use it via a const, e.g.
#   const MenuRepeatPolicy = preload("res://scripts/shared/MenuRepeatPolicy.gd")
# That keeps headless `--script` test runs working without a manual entry in the
# gitignored global class cache (same convention as InputDisplay / MapCursorInput).
#
# WHY a poller, not per-event handling: the left-stick axis is bound to the
# cursor_* / ui_* actions, and a held stick emits an event on every analog
# fluctuation above threshold — so per-event `is_action_pressed` stepped the menu
# once per jitter ("too fast") and stopped entirely when the value stabilised
# ("stops weirdly"). Polling action strength through Input.get_vector applies the
# InputMap deadzone and feeds ONE tuned delay/repeat timer, exactly like the map
# cursor's proven MapCursorInput.poll_direction. Keyboard is unaffected: a tap
# yields one step (fresh direction fires immediately), a held key repeats after
# the same delay — matching the prior keyboard feel.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")

# Repeat timings — same source of truth as the map cursor so menu and map feel match.
const REPEAT_DELAY: float = GameConstants.CURSOR_KEY_REPEAT_DELAY  # initial hold pause
const REPEAT_RATE: float  = GameConstants.CURSOR_KEY_REPEAT_RATE   # per-step pause while held

# The four navigation actions, polled as an analog vector. Left-stick + d-pad +
# keyboard all feed these, so one poll covers every device. Defaults are the
# custom-menu cursor_* vocabulary (ActionMenu / UnitDetailsScreen); screens driven
# by engine focus nav construct with the ui_* set instead. All four share the same
# stick axes, so whichever set a caller passes still catches the analog jitter.
var _neg_x: String = "cursor_left"
var _pos_x: String = "cursor_right"
var _neg_y: String = "cursor_up"
var _pos_y: String = "cursor_down"

var _held_dir: Vector2i = Vector2i.ZERO
var _held_timer: float = 0.0
var _wait_for_neutral: bool = false


# Optional: override the polled action set (e.g. the ui_* engine-focus vocabulary).
# Pass the four action names in left/right/up/down order.
func _init(neg_x: String = "cursor_left", pos_x: String = "cursor_right",
		neg_y: String = "cursor_up", pos_y: String = "cursor_down") -> void:
	_neg_x = neg_x
	_pos_x = pos_x
	_neg_y = neg_y
	_pos_y = pos_y


# Per-frame poll. Returns a step direction (a single cardinal Vector2i) when a
# step should happen THIS frame, ZERO otherwise. A fresh direction fires
# immediately then waits REPEAT_DELAY; subsequent repeats wait REPEAT_RATE.
# Releasing to centre clears the timer so the next press fires immediately again.
func poll(delta: float) -> Vector2i:
	var dir := _direction_from_actions()
	if _wait_for_neutral:
		if dir == Vector2i.ZERO:
			_wait_for_neutral = false
		return Vector2i.ZERO
	if dir == Vector2i.ZERO:
		_reset_repeat()
		return Vector2i.ZERO
	if dir != _held_dir:
		_held_dir = dir
		_held_timer = REPEAT_DELAY
		return dir
	_held_timer -= delta
	if _held_timer <= 0.0:
		_held_timer = REPEAT_RATE
		return _held_dir
	return Vector2i.ZERO


# Drop any held direction and reset the timer (call when the owning menu hides,
# so a re-open starts clean and never carries a stale held step). If a direction
# is already held at clear-time, wait until the stick/key returns to neutral.
func clear() -> void:
	_wait_for_neutral = _direction_from_actions() != Vector2i.ZERO
	_reset_repeat()


func _reset_repeat() -> void:
	_held_dir = Vector2i.ZERO
	_held_timer = 0.0


# Dominant cardinal from the live ui_* actions. Input.get_vector applies the
# per-action deadzone, so a resting stick reads ZERO and no jitter leaks through.
func _direction_from_actions() -> Vector2i:
	var v := Vector2(
		_action_strength(_pos_x) - _action_strength(_neg_x),
		_action_strength(_pos_y) - _action_strength(_neg_y)
	)
	if is_zero_approx(v.length()):
		return Vector2i.ZERO
	if absf(v.x) >= absf(v.y):
		return Vector2i(1 if v.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if v.y > 0.0 else -1)


func _action_strength(action: String) -> float:
	if action == "":
		return 0.0
	return Input.get_action_strength(action)
