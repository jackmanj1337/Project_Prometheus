extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_diagnostics_layout.gd

const LayoutAudit = preload("res://scripts/shared/LayoutAudit.gd")

var passed := 0
var failed := 0


func _init() -> void:
	print("=== Diagnostics layout audit test ===")
	await process_frame
	var canvas := Control.new()
	canvas.name = "AuditCanvas"
	canvas.size = Vector2(320.0, 240.0)
	root.add_child(canvas)

	var clipped := Label.new()
	clipped.name = "ClippedLabel"
	clipped.text = "A deliberately long diagnostic label that cannot fit"
	clipped.clip_text = true
	clipped.size = Vector2(40.0, 24.0)
	canvas.add_child(clipped)

	var overflowing := ColorRect.new()
	overflowing.name = "OverflowingControl"
	overflowing.position = Vector2(300.0, 220.0)
	overflowing.size = Vector2(80.0, 60.0)
	canvas.add_child(overflowing)

	var dialog := PanelContainer.new()
	dialog.name = "SettingsDialog"
	dialog.position = Vector2(16.0, 16.0)
	dialog.size = Vector2(180.0, 100.0)
	canvas.add_child(dialog)
	await process_frame

	# The v0.7.17 shape: a ScrollContainer whose content is taller than the viewport,
	# which is what makes it scroll. The Settings screen reported its ENTIRE subtree
	# as overflowing on every settle -- a 1709 px margin inside a 720 px viewport,
	# logged as a defect -- and 388 of the 401 layout records the round retained were
	# that one screen. The cap then fired at t=150 s of a 3,300 s session, so the
	# fullscreen pass, the 4K window and all of Section 3's resizes were never
	# recorded at all. The false positives did not merely add noise; they spent the
	# budget before anything interesting happened.
	var scroll := ScrollContainer.new()
	scroll.name = "SettingsScroll"
	scroll.position = Vector2(0.0, 40.0)
	scroll.size = Vector2(200.0, 100.0)
	# A vertical list, like the Settings screen: content may exceed it downwards and
	# that is by design, but nothing is reachable sideways.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	var tall := Control.new()
	tall.name = "TallScrolledContent"
	tall.custom_minimum_size = Vector2(180.0, 1709.0)
	scroll.add_child(tall)

	# A control genuinely outside its clipping ancestor, sideways, on the axis the
	# container does NOT scroll. Exempting the whole subtree would lose this.
	var sideways := ColorRect.new()
	sideways.name = "SidewaysInsideScroll"
	sideways.position = Vector2(600.0, 0.0)
	sideways.size = Vector2(40.0, 20.0)
	tall.add_child(sideways)
	await process_frame
	await process_frame

	var findings := LayoutAudit.audit(canvas, Rect2(Vector2.ZERO, canvas.size), "test_settle")
	_check(_has_event(findings, "label_clipped"), "audit finds a clipped visible label")
	_check(_has_event(findings, "control_overflow"), "audit finds a control outside the viewport")
	_check(_has_event(findings, "dialog_geometry"), "audit records visible dialog geometry")
	_check(_has_event(findings, "focus_lost"), "audit records a visible dialog with no focus owner")
	_check(
		(
			_has_field(findings, "control_overflow", "path")
			and _has_field(findings, "control_overflow", "rect")
			and _has_field(findings, "control_overflow", "viewport")
		),
		"layout findings carry stable paths and geometry"
	)

	# V0717-04, the predicate half.
	_check(
		not _has_overflow_for(findings, "TallScrolledContent"),
		"a tall child of a ScrollContainer is not reported as overflow"
	)
	_check(
		not _has_overflow_for(findings, "SettingsScroll"),
		"the ScrollContainer itself, fully inside the viewport, is not reported"
	)
	_check(
		_has_overflow_for(findings, "SidewaysInsideScroll"),
		"a control outside its clipping ancestor on a non-scrolling axis is still reported"
	)
	_check(
		_has_overflow_for(findings, "OverflowingControl"),
		"a control outside the viewport with no clipping ancestor is still reported"
	)
	# The clipping ancestor is what the control is measured against now, so the
	# record has to say which one, or a reader cannot check the verdict.
	_check(
		_has_field(findings, "control_overflow", "clipped_by"),
		"an overflow finding names the ancestor it was measured against"
	)

	await _check_real_settings_screen()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


# The screen that actually produced the 388 false positives, audited for real.
# A synthetic ScrollContainer proves the predicate; only the shipped scene proves
# the case the v0.7.17 return was made of. Measured in a SubViewport of a real
# size, because ResponsiveLayout alone sets the class and tokens but not the
# viewport, so every widget would otherwise measure at the headless default.
func _check_real_settings_screen() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(694, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var screen: Control = load("res://scenes/ui/SettingsScreen.tscn").instantiate()
	viewport.add_child(screen)
	screen.show()
	screen.apply_menu_scale(1.0)
	await process_frame
	await process_frame

	var findings := LayoutAudit.audit(
		screen, Rect2(Vector2.ZERO, Vector2(viewport.size)), "size_class_changed"
	)
	var scrolled: Array[String] = []
	for finding: Dictionary in findings:
		if String(finding.get("event", "")) != "control_overflow":
			continue
		var path := String(finding.get("fields", {}).get("path", ""))
		if path.contains("ScrollContainer/"):
			scrolled.append(path)
	_check(
		scrolled.is_empty(), "the real Settings screen reports no overflow for its scrolled content"
	)
	if not scrolled.is_empty():
		print("     %s" % str(scrolled))
	viewport.queue_free()


func _has_overflow_for(findings: Array, node_name: String) -> bool:
	for finding: Dictionary in findings:
		if String(finding.get("event", "")) != "control_overflow":
			continue
		if String(finding.get("fields", {}).get("path", "")).ends_with("/%s" % node_name):
			return true
	return false


func _check(ok: bool, label: String) -> void:
	if ok:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s" % label)
		failed += 1


func _has_event(findings: Array, event: String) -> bool:
	for finding: Dictionary in findings:
		if String(finding.get("event", "")) == event:
			return true
	return false


func _has_field(findings: Array, event: String, field: String) -> bool:
	for finding: Dictionary in findings:
		if String(finding.get("event", "")) == event:
			return (finding.get("fields", {}) as Dictionary).has(field)
	return false
