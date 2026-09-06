extends SceneTree
# Settings keeps its desktop preference while fitting the supported 360x640 logical
# floor. The production ScrollContainer remains the vertical overflow mechanism.

const LayoutAudit = preload("res://scripts/shared/LayoutAudit.gd")

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
	var labels: Array[Node] = (
		screen
		. get_node("Panel/ScrollContainer/Margin/VBox/KeybindList")
		. find_children("*", "Label", true, false)
	)
	for factor in [1.0, 2.0, 3.0]:
		screen.apply_menu_scale(factor)
		await process_frame
		await process_frame
		for label: Label in labels:
			_ok(
				(
					not label.clip_text
					and label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART
					and label.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING
				),
				"compact %.0fx binding label wraps without truncation: %s" % [factor, label.text]
			)
			_ok(label.get_global_rect().end.x <= 361.0, "wrapped label fits the viewport")
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
	var labels: Array[Node] = (
		screen
		. get_node("Panel/ScrollContainer/Margin/VBox/KeybindList")
		. find_children("*", "Label", true, false)
	)
	var keybind_list := (
		screen.get_node("Panel/ScrollContainer/Margin/VBox/KeybindList") as VBoxContainer
	)
	for row in keybind_list.get_children():
		if not row.has_meta("keybind_action"):
			continue
		var binding_label := row.get_child(1) as Label
		_ok(
			binding_label != null and binding_label.custom_minimum_size.x > 1.0,
			"desktop binding label keeps a real minimum width"
		)
	var findings: Array = LayoutAudit.audit(screen, viewport.get_visible_rect(), "v0717_keybinds")
	for finding: Dictionary in findings:
		if (
			String(finding.get("event", "")) == "label_clipped"
			and "/KeybindList/" in String(finding.get("fields", {}).get("path", ""))
		):
			_ok(false, "desktop binding labels are not clipped: %s" % finding)
	var preferences: Array = []
	for label: Label in labels:
		preferences.append([label.clip_text, label.autowrap_mode, label.text_overrun_behavior])
	viewport.size = Vector2i(360, 640)
	screen._stabilize_settings_rows()
	await process_frame
	viewport.size = Vector2i(1280, 720)
	screen._stabilize_settings_rows()
	await process_frame
	for i in labels.size():
		var label := labels[i] as Label
		_ok(
			[label.clip_text, label.autowrap_mode, label.text_overrun_behavior] == preferences[i],
			"desktop text layout restores after Compact"
		)
	viewport.queue_free()
	await process_frame
