class_name FocusNavigator extends RefCounted
# Shared held-input navigation for scene-root menus and embedded selectors.

const MenuRepeatPolicy = preload("res://scripts/shared/MenuRepeatPolicy.gd")

var root: Control
var scroll: ScrollContainer
var repeat := MenuRepeatPolicy.new("", "", "ui_up", "ui_down")

# V031-GP-02 parity with ModalScreen: true while an embedded popup Window (an
# OptionButton dropdown, context menu, …) was capturing input last frame. Without
# this gate the process-global Input poll steps focus on the screen *behind* an
# open dropdown, the exact v0.3.1 regression ModalScreen already fixed.
var _capture_ui_was_active: bool = false


func _init(owner: Control, focus_scroll: ScrollContainer = null) -> void:
	root = owner
	scroll = focus_scroll


func clear() -> void:
	repeat.clear()


# True while direction events must be suppressed so the engine's built-in focus
# navigation does not ALSO move focus. Callers wire this into `_input` (which runs
# BEFORE the GUI focus-nav phase); wiring it into `_unhandled_input` is too late —
# the engine has already stepped focus and consumed the event by then.
func consume_direction(event: InputEvent) -> bool:
	# Do not suppress while an embedded popup is open: its own list needs ui_up/
	# ui_down to navigate (matches ModalScreen._input's _capture_ui_active guard).
	if _capture_ui_active():
		return false
	return event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down")


func poll(delta: float) -> void:
	if root == null or not root.is_visible_in_tree():
		return
	# Skip while an embedded popup owns the event stream; re-latch to neutral the
	# frame it closes so a direction still held from inside it never leaks a step.
	if _capture_ui_active():
		_capture_ui_was_active = true
		return
	if _capture_ui_was_active:
		_capture_ui_was_active = false
		repeat.clear()
		return
	var step := repeat.poll(delta)
	if step.y != 0:
		move_focus(step.y)


# Any embedded subwindow visible in this owner's viewport (single-window game, so
# an open dropdown always registers here). Mirrors ModalScreen._capture_ui_active.
func _capture_ui_active() -> bool:
	if root == null:
		return false
	var vp := root.get_viewport()
	if vp == null:
		return false
	for w in vp.get_embedded_subwindows():
		if w.visible:
			return true
	return false


func grab_default() -> void:
	var controls := focusable_controls()
	if not controls.is_empty():
		controls[0].grab_focus()


func move_focus(direction: int) -> void:
	var controls := focusable_controls()
	if controls.is_empty():
		return
	var focused := root.get_viewport().gui_get_focus_owner()
	var index := controls.find(focused)
	index = 0 if index < 0 else wrapi(index + direction, 0, controls.size())
	var target: Control = controls[index]
	target.grab_focus()
	_apply_lookahead(target, direction)


func focusable_controls() -> Array[Control]:
	var out: Array[Control] = []
	_collect(root, out)
	return out


func _collect(node: Node, out: Array[Control]) -> void:
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			if (
				control.is_visible_in_tree()
				and control.focus_mode != Control.FOCUS_NONE
				and not (control is BaseButton and (control as BaseButton).disabled)
			):
				out.append(control)
		_collect(child, out)


func _apply_lookahead(control: Control, direction: int) -> void:
	if scroll == null or not scroll.is_visible_in_tree():
		return
	# follow_focus performs the immediate reveal. The deferred margin keeps roughly
	# three rows visible in the direction of travel after containers settle.
	var row_height := maxf(control.size.y, 1.0)
	var margin := minf(row_height * 3.0, scroll.size.y * 0.4)
	var local := scroll.get_global_transform().affine_inverse() * control.global_position
	if direction > 0:
		scroll.scroll_vertical = maxi(
			scroll.scroll_vertical, int(local.y + control.size.y + margin - scroll.size.y)
		)
	elif direction < 0:
		scroll.scroll_vertical = mini(scroll.scroll_vertical, maxi(0, int(local.y - margin)))
