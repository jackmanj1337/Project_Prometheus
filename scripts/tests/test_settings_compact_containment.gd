extends SceneTree
# Settings keeps its desktop preference while fitting the supported 360x640 logical
# floor. The production ScrollContainer remains the vertical overflow mechanism.

var _passed := 0
var _failed := 0


func _ok(condition: bool, message: String) -> void:
	if condition:
		print("OK  ", message)
		_passed += 1
	else:
		print("FAIL ", message)
		_failed += 1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Settings Compact Containment Test ===")
	await _check_compact_floor()
	await _check_desktop_preference()
	print("Results: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _make_screen(viewport_size: Vector2i) -> Array:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var screen: Control = load("res://scenes/ui/SettingsScreen.tscn").instantiate()
	viewport.add_child(screen)
	screen.show()
	screen.apply_menu_scale(1.0)
	await process_frame
	await process_frame
	return [viewport, screen]


func _check_compact_floor() -> void:
	var fixture := await _make_screen(Vector2i(360, 640))
	var viewport := fixture[0] as SubViewport
	var screen := fixture[1] as Control
	var panel := screen.get_node("Panel") as Control
	var scroll := screen.get_node("Panel/ScrollContainer") as ScrollContainer
	var rect := panel.get_global_rect()
	_ok(rect.position.x >= -1.0, "compact panel starts inside the left edge (%s)" % rect)
	_ok(rect.end.x <= 361.0, "compact panel ends inside the right edge (%s)" % rect)
	_ok(
		scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED,
		"compact Settings keeps vertical scrolling enabled"
	)
	var title := (
		screen.get_node("Panel/ScrollContainer/Margin/VBox/HBoxMaster/LabelMasterTitle") as Label
	)
	_ok(
		(
			title.get_parent() is VBoxContainer
			and not title.clip_text
			and title.tooltip_text == title.text
		),
		"compact rows put the full label above their controls"
	)
	for factor in [1.0, 2.0, 3.0]:
		screen.apply_menu_scale(factor)
		await process_frame
		_ok(
			title.size.x >= title.get_minimum_size().x and title.tooltip_text == title.text,
			"compact %.0fx preserves the full Settings label contract" % factor
		)
	viewport.queue_free()
	await process_frame


func _check_desktop_preference() -> void:
	var fixture := await _make_screen(Vector2i(1280, 720))
	var viewport := fixture[0] as SubViewport
	var screen := fixture[1] as Control
	var panel := screen.get_node("Panel") as Control
	var title := (
		screen.get_node("Panel/ScrollContainer/Margin/VBox/HBoxMaster/LabelMasterTitle") as Label
	)
	_ok(
		panel.size.is_equal_approx(Vector2(760.0, 620.0)),
		"desktop Settings keeps its 760x620 preferred frame (got %s)" % panel.size
	)
	_ok(
		title.get_parent() is HBoxContainer and is_equal_approx(title.custom_minimum_size.x, 340.0),
		"desktop rows keep the stable label column"
	)
	viewport.queue_free()
	await process_frame
