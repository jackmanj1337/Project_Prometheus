class_name FocusNavigator extends RefCounted
# Shared held-input navigation for scene-root menus and embedded selectors.

const MenuRepeatPolicy = preload("res://scripts/shared/MenuRepeatPolicy.gd")

var root: Control
var scroll: ScrollContainer
var repeat := MenuRepeatPolicy.new("", "", "ui_up", "ui_down")


func _init(owner: Control, focus_scroll: ScrollContainer = null) -> void:
	root = owner
	scroll = focus_scroll


func clear() -> void:
	repeat.clear()


func consume_direction(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down")


func poll(delta: float) -> void:
	if root == null or not root.is_visible_in_tree():
		return
	var step := repeat.poll(delta)
	if step.y != 0:
		move_focus(step.y)


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
