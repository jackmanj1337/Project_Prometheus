extends SceneTree
# Run with:
#   godot --headless --path . --script res://scripts/tests/test_modal_responsive_frame.gd
#
# Covers ModalScreen._apply_responsive_frame's size contract, which the existing
# suites did not: they assert a centered panel is ENCLOSED by the viewport, and the
# Playwright album asserts the same thing. Both are satisfied by a panel that is far
# too LARGE, which is exactly the defect that shipped — every panel authored without a
# custom_minimum_size was pinned to 90% x 90% of the safe viewport, so a 480x360 Load
# Game dialog rendered at 1152x648 on a 720p display.
#
# The rules under test:
#   1. an authored custom_minimum_size is the preference and is honoured when it fits;
#   2. a panel authored WITHOUT one sizes to its content, not to the cap;
#   3. no frame exceeds 90% of the safe viewport on either axis;
#   4. frames centre on the SAFE viewport, not the raw one.

const SAFE_RATIO := 0.9

var _passed := 0
var _failed := 0


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
		_passed += 1
	else:
		print("FAIL ", msg)
		_failed += 1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Modal Responsive Frame Test ===")
	await _check_authored_preference_is_kept()
	await _check_grow_to_content_is_not_inflated()
	await _check_cap_is_enforced()
	await _check_scroll_frame_is_given_room()
	await _check_centres_on_safe_area()
	print("Results: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# A modal whose Panel carries an authored custom_minimum_size keeps it on a display
# with room to spare — the cap must not become the size.
func _check_authored_preference_is_kept() -> void:
	var screen: Control = load("res://scenes/ui/SettingsScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var panel: Control = screen.get_node("Panel")
	var authored := Vector2(760.0, 620.0)
	screen.apply_menu_scale(1.0)
	await process_frame
	var size := panel.size
	var view: Vector2 = screen.get_viewport_rect().size
	# Only meaningful while the authored size actually fits the test viewport.
	if authored.x <= view.x * SAFE_RATIO and authored.y <= view.y * SAFE_RATIO:
		_ok(
			is_equal_approx(size.x, authored.x) and is_equal_approx(size.y, authored.y),
			"authored panel keeps its %s preference (got %s)" % [authored, size]
		)
	else:
		_ok(true, "authored panel skipped: viewport %s too small for %s" % [view, authored])
	screen.queue_free()
	await process_frame


# The regression that shipped. LoadGameScreen's Panel has no custom_minimum_size, so
# it must size to content — comfortably under the cap, not equal to it.
func _check_grow_to_content_is_not_inflated() -> void:
	var screen: Control = load("res://scenes/ui/LoadGameScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var panel: Control = screen.get_node("Panel")
	# Authored via the anchor span + offsets (-240..240, -180..180), not via
	# custom_minimum_size — the expression the old code could not read.
	var authored := Vector2(480.0, 360.0)
	screen.apply_menu_scale(1.0)
	await process_frame
	# The captured preference proves the offsets were read: the scene sets no
	# custom_minimum_size, so anything but (0,0) here came from the anchor span.
	_ok(
		panel.get_meta("_responsive_preferred_size", Vector2.ZERO) == authored,
		(
			"offset-authored size is captured as the preference (got %s)"
			% panel.get_meta("_responsive_preferred_size", Vector2.ZERO)
		)
	)
	var view: Vector2 = screen.get_viewport_rect().size
	var cap := view * SAFE_RATIO
	var size := panel.size
	_ok(
		is_equal_approx(size.x, authored.x) and is_equal_approx(size.y, authored.y),
		"offset-authored panel keeps its %s size (got %s)" % [authored, size]
	)
	# The shipped defect: this same panel measured exactly the cap on both axes.
	_ok(
		size.x < cap.x - 1.0 and size.y < cap.y - 1.0,
		"offset-authored panel is not inflated to the %s cap (got %s)" % [cap, size]
	)
	screen.queue_free()
	await process_frame


# A panel whose authored preference exceeds the cap is reduced to the cap, on the axis
# that overflows. MapResultsScreen is authored 1120x620 — wider than a 720p cap.
func _check_cap_is_enforced() -> void:
	var screen: Control = load("res://scenes/ui/MapResultsScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var panel: Control = screen.get_node("Panel")
	screen.apply_menu_scale(1.0)
	await process_frame
	var view: Vector2 = screen.get_viewport_rect().size
	var cap := view * SAFE_RATIO
	_ok(
		panel.size.x <= cap.x + 1.0 and panel.size.y <= cap.y + 1.0,
		"oversized panel is capped to %s of the safe viewport (got %s)" % [cap, panel.size]
	)
	screen.queue_free()
	await process_frame


# A frame with no authored size that is built around a ScrollContainer has no
# intrinsic height to grow to. NewGameScreen measured 458x32 when the content minimum
# was used as its fallback — technically "not inflated", and useless.
func _check_scroll_frame_is_given_room() -> void:
	var screen: Control = load("res://scenes/ui/NewGameScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var panel: Control = screen.get_node("Panel")
	screen.apply_menu_scale(1.0)
	await process_frame
	var view: Vector2 = screen.get_viewport_rect().size
	var cap := view * SAFE_RATIO
	var size := panel.size
	_ok(
		size.y > view.y * 0.25,
		"scroll-framed panel is given usable height (got %s of viewport %s)" % [size, view]
	)
	_ok(
		size.x <= cap.x + 1.0 and size.y <= cap.y + 1.0,
		"scroll-framed panel still respects the %s cap (got %s)" % [cap, size]
	)
	screen.queue_free()
	await process_frame


# Safe-area insets shift the centre. With asymmetric insets the frame must centre on
# the safe rect, so its margins to each safe edge stay equal.
func _check_centres_on_safe_area() -> void:
	var settings := root.get_node_or_null("SettingsManager")
	if settings == null or not settings.has_method("get_safe_area_insets"):
		_ok(true, "safe-area centring skipped: SettingsManager unavailable headless")
		return
	var previous: Vector4i = settings.get_safe_area_insets()
	settings.safe_area_insets = Vector4i(40, 20, 0, 0)
	var screen: Control = load("res://scenes/ui/SettingsScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.apply_menu_scale(1.0)
	await process_frame
	var panel: Control = screen.get_node("Panel")
	var view: Vector2 = screen.get_viewport_rect().size
	var safe_position := Vector2(40.0, 20.0)
	var safe_size := Vector2(view.x - 40.0, view.y - 20.0)
	var rect := panel.get_global_rect()
	var left_margin := rect.position.x - safe_position.x
	var right_margin := safe_position.x + safe_size.x - rect.end.x
	_ok(
		absf(left_margin - right_margin) <= 1.5,
		"frame centres on the safe rect (left %.1f vs right %.1f)" % [left_margin, right_margin]
	)
	settings.safe_area_insets = previous
	screen.queue_free()
	await process_frame
