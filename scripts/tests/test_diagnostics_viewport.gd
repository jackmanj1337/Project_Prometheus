extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_diagnostics_viewport.gd
#
# Exercises the live trace at the same seam that owns resize settling. The test drives
# logical sizes because a headless display cannot produce a meaningful native drag, then
# checks that the structured record still carries before/after state and a screen response.

const ResponsiveLayoutS = preload("res://scripts/autoloads/ResponsiveLayout.gd")
const DiagnosticsSession = preload("res://scripts/shared/DiagnosticsSession.gd")

var passed := 0
var failed := 0


func _init() -> void:
	print("=== Diagnostics viewport trace test ===")
	await process_frame
	var log: Node = root.get_node_or_null("DiagnosticsLog")
	if log == null:
		_fail("DiagnosticsLog autoload is available")
	else:
		log.reset()
		_test_snapshot_contract()
		await _test_live_resize_trace(log)
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s%s" % [label, ("\n     %s" % detail) if not detail.is_empty() else ""])
		failed += 1


func _fail(label: String) -> void:
	_check(false, label)


func _test_snapshot_contract() -> void:
	var layout: Node = ResponsiveLayoutS.new()
	var before := DiagnosticsSession.viewport_snapshot(layout)
	layout.logical_size = Vector2(600.0, 720.0)
	var after := DiagnosticsSession.viewport_snapshot(layout)
	var records := DiagnosticsSession.screen_response_records(before, after)
	_check(
		(
			before.has_all(["context", "size_class", "logical_size", "headless"])
			and after.has("logical_size")
		),
		"viewport snapshots carry context, class, logical size and display mode"
	)
	_check(
		(
			not records.is_empty()
			and String(records[0]["event"]) == "screen_response"
			and (records[0]["fields"] as Dictionary).has("screen_count")
		),
		"screen response records remain present on headless display"
	)
	layout.free()


func _test_live_resize_trace(log: Node) -> void:
	var layout: Node = ResponsiveLayoutS.new()
	root.add_child(layout)
	await process_frame
	var initial_count := _event_count(log, "viewport_changed")
	layout.apply_logical_size(Vector2(500.0, 720.0))
	layout.apply_logical_size(Vector2(1100.0, 720.0))
	log.flush()
	var traces := _events(log, "viewport_changed")
	_check(
		traces.size() >= initial_count + 2,
		"each changed logical viewport emits a structured trace",
		"before=%d after=%d" % [initial_count, traces.size()]
	)
	if traces.size() >= 2:
		var fields: String = String(traces[traces.size() - 1]["fields"])
		_check(
			(
				fields.contains("before=")
				and fields.contains("after=")
				and fields.contains("size_class_before=")
				and fields.contains("size_class_after=")
				and fields.contains("logical_size_before=")
				and fields.contains("logical_size_after=")
			),
			"trace contains before/after geometry, scale and class fields",
			fields
		)
	else:
		_fail("trace field contract can be inspected")
	_check(
		_event_count(log, "screen_response") >= 2,
		"each viewport change has a screen response record"
	)
	layout.queue_free()


func _events(log: Node, event_name: String) -> Array:
	var result: Array = []
	for item: Dictionary in log.records:
		if String(item.get("event", "")) == event_name:
			result.append(item)
	return result


func _event_count(log: Node, event_name: String) -> int:
	return _events(log, event_name).size()
