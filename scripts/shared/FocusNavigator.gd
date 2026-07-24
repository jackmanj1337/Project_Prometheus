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
var _lookahead_generation: int = 0


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
	if scroll == null or not scroll.is_visible_in_tree() or not scroll.is_ancestor_of(control):
		return
	_lookahead_generation += 1
	var generation := _lookahead_generation
	# Dynamic lists settle one frame after a focus step. Coalesce held-repeat calls
	# so an older row can never pull the viewport away from the latest focus owner.
	await root.get_tree().process_frame
	if (
		generation != _lookahead_generation
		or not is_instance_valid(scroll)
		or not is_instance_valid(control)
		or root.get_viewport().gui_get_focus_owner() != control
	):
		return
	var row := _visual_scroll_row(control)
	var view := scroll.get_global_rect()
	var rect := row.get_global_rect()
	var current := float(scroll.scroll_vertical)
	# Convert viewport coordinates to an absolute content coordinate. The former
	# code treated a viewport-relative Y as content Y, causing mid-list jumps.
	var content_top := current + rect.position.y - view.position.y
	var desired := _visual_rows_height(row, 3, direction if direction != 0 else 1)
	var margin := minf(desired, maxf(0.0, (view.size.y - rect.size.y) * 0.5))
	var target := current
	if direction < 0 and content_top - margin < current:
		target = content_top - margin
	elif direction > 0 and content_top + rect.size.y + margin > current + view.size.y:
		target = content_top + rect.size.y + margin - view.size.y
	elif rect.position.y < view.position.y:
		target = content_top
	elif rect.end.y > view.end.y:
		target = content_top + rect.size.y - view.size.y
	var bar := scroll.get_v_scroll_bar()
	var maximum := maxf(0.0, bar.max_value - bar.page) if bar != null else target
	scroll.scroll_vertical = roundi(clampf(target, 0.0, maximum))


func _visual_scroll_row(control: Control) -> Control:
	var row := control
	while row.get_parent() is Control:
		if row.get_parent() is VBoxContainer:
			break
		row = row.get_parent() as Control
	return row


func _visual_rows_height(row: Control, count: int, direction: int) -> float:
	var parent := row.get_parent()
	if parent == null:
		return 0.0
	var siblings := parent.get_children()
	var index := siblings.find(row)
	var height := 0.0
	var found := 0
	var stop := siblings.size() if direction > 0 else -1
	for i in range(index + direction, stop, direction):
		var sibling := siblings[i]
		if sibling is Control and sibling.is_visible_in_tree():
			height += (sibling as Control).get_global_rect().size.y
			found += 1
			if found == count:
				break
	return height
