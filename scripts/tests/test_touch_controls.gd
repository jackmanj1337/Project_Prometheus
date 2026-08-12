extends SceneTree

const TouchControlsS = preload("res://scripts/ui/TouchControls.gd")


class FakeCameraController:
	extends RefCounted
	var pans: Array[Vector2] = []
	var zoom_steps: Array[int] = []

	func pan_by_pixels(delta: Vector2) -> void:
		pans.append(delta)

	func step_zoom(direction: int, _tile: Vector2i, _buffer: int) -> int:
		zoom_steps.append(direction)
		return 4 if direction > 0 else 2


func _touch(index: int, pressed: bool, position: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	return event


func _drag(index: int, position: Vector2, relative: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	event.relative = relative
	return event


func _buttons_below(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for child in node.get_children():
		if child is Button:
			buttons.append(child)
		buttons.append_array(_buttons_below(child))
	return buttons


func _init() -> void:
	var passed := 0
	var failed := 0

	var overlay := TouchControlsS.new()
	root.add_child(overlay)
	await process_frame
	var buttons := _buttons_below(overlay)
	var labels: Array[String] = []
	var sized := true
	for button in buttons:
		labels.append(button.text)
		sized = (
			sized and button.custom_minimum_size.x >= 44.0 and button.custom_minimum_size.y >= 44.0
		)
	labels.sort()
	if labels == ["Back", "Info", "Menu", "More"] and sized:
		print("OK  touch overlay exposes four finger-sized contextual actions")
		passed += 1
	else:
		print("FAIL touch overlay buttons: labels=%s sized=%s" % [labels, sized])
		failed += 1

	overlay.visible = false
	overlay._input(_touch(0, true, Vector2(10, 10)))
	if overlay.visible:
		print("OK  first genuine touch reveals the web overlay")
		passed += 1
	else:
		print("FAIL touch did not reveal overlay")
		failed += 1
	overlay.queue_free()

	var cursor := MapCursor.new()
	root.add_child(cursor)
	var camera := FakeCameraController.new()
	cursor._camera_ctrl = camera
	cursor._unhandled_input(_touch(0, true, Vector2(100, 100)))
	cursor._handle_screen_drag(_drag(0, Vector2(108, 100), Vector2(8, 0)))
	var below_threshold := camera.pans.is_empty()
	cursor._handle_screen_drag(_drag(0, Vector2(120, 100), Vector2(12, 0)))
	if below_threshold and camera.pans == [Vector2(-12, 0)]:
		print("OK  one-finger drag thresholds then pans opposite the finger")
		passed += 1
	else:
		print("FAIL touch drag pans=%s below=%s" % [camera.pans, below_threshold])
		failed += 1
	cursor._handle_screen_touch(_touch(0, false, Vector2(120, 100)))
	if cursor._touch_points.is_empty() and cursor._touch_primary_index == -1:
		print("OK  drag release resets gesture state without a tap")
		passed += 1
	else:
		print("FAIL drag release left state=%s" % cursor._touch_points)
		failed += 1
	if cursor._recent_touch_event():
		print("OK  synthetic mouse input is suppressed immediately after touch")
		passed += 1
	else:
		print("FAIL recent touch did not arm mouse suppression")
		failed += 1

	cursor._handle_screen_touch(_touch(0, true, Vector2(100, 100)))
	cursor._handle_screen_touch(_touch(1, true, Vector2(200, 100)))
	cursor._handle_screen_drag(_drag(1, Vector2(220, 100), Vector2(20, 0)))
	if camera.zoom_steps == [1]:
		print("OK  outward pinch steps the existing bounded zoom API")
		passed += 1
	else:
		print("FAIL pinch zoom steps=%s" % camera.zoom_steps)
		failed += 1

	cursor.queue_free()
	await process_frame
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
