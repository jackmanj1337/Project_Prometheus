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

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


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
