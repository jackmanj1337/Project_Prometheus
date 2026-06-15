extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_level_up_screen.gd
# Covers playtest 3 #2: a left-click while the level-up panel is shown must
# dismiss it the same way the confirm key does. Previously the panel only
# responded to keyboard confirm/cancel, so a mouse-only player was stuck.

func _init() -> void:
	print("=== LevelUpScreen Test ===")
	var passed := 0
	var failed := 0

	var packed := load("res://scenes/ui/LevelUpScreen.tscn")
	if packed == null:
		print("FAIL could not load LevelUpScreen.tscn"); quit(1); return
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame

	# Populate the panel's queue directly with a stub level-up entry and call
	# _show_next so we don't depend on a real Unit / EventBus / level_up_started.
	var stub_unit_script := GDScript.new()
	stub_unit_script.source_code = """
extends Node
class StubData:
	var unit_name: String = \"Test Unit\"
	var level: int = 2
var data: StubData = StubData.new()
"""
	stub_unit_script.reload()
	var stub_unit: Node = _make_stub_unit(stub_unit_script, "Test Unit", 2)
	root.add_child(stub_unit)
	screen._queue.append({"unit": stub_unit, "increases": {"hp": 1}})
	screen._show_next()
	await process_frame

	if screen.visible:
		print("OK  panel visible after _show_next"); passed += 1
	else:
		print("FAIL panel not visible after _show_next"); failed += 1

	# Mouse-click while the panel is up must dismiss it (playtest 3 #2).
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	screen._unhandled_input(click)
	await process_frame
	if not screen.visible:
		print("OK  left-click dismisses the level-up panel (playtest 3 #2)")
		passed += 1
	else:
		print("FAIL left-click did not dismiss the panel"); failed += 1

	# Confirm action still works after the change — guards against regression.
	screen._queue.append({"unit": stub_unit, "increases": {"hp": 1}})
	screen._show_next()
	var confirm := InputEventAction.new()
	confirm.action = "confirm"
	confirm.pressed = true
	screen._unhandled_input(confirm)
	await process_frame
	if not screen.visible:
		print("OK  confirm key still dismisses the panel"); passed += 1
	else:
		print("FAIL confirm key no longer dismisses"); failed += 1

	# A level-up that learns a skill announces it on the stats label (M3).
	screen._queue.append({
		"unit": stub_unit, "increases": {"hp": 1}, "learned": [{"id": "vantage", "equipped": true}],
	})
	screen._show_next()
	await process_frame
	var stats_label: Label = screen.get_node("Panel/VBox/LabelStats")
	if "Learned" in stats_label.text and "Vantage" in stats_label.text:
		print("OK  level-up panel announces a learned skill"); passed += 1
	else:
		print("FAIL learned-skill line missing: '%s'" % stats_label.text); failed += 1
	screen._unhandled_input(confirm)
	await process_frame

	# M6.3: when the skill cap is full, the learned line explains the skill was stored.
	screen._queue.append({
		"unit": stub_unit, "increases": {"hp": 1},
		"learned": [{"id": "wrath", "equipped": false}],
	})
	screen._show_next()
	await process_frame
	if "skill slots full" in stats_label.text and "Wrath" in stats_label.text:
		print("OK  learned-skill line explains when the skill is stored due to full slots"); passed += 1
	else:
		print("FAIL stored-skill line missing: '%s'" % stats_label.text); failed += 1
	screen._unhandled_input(confirm)
	await process_frame

	# Multiple queued entries must advance in-order without dropping the middle item.
	var queue_unit_a: Node = _make_stub_unit(stub_unit_script, "Queue A", 3)
	var queue_unit_b: Node = _make_stub_unit(stub_unit_script, "Queue B", 4)
	var queue_unit_c: Node = _make_stub_unit(stub_unit_script, "Queue C", 5)
	root.add_child(queue_unit_a)
	root.add_child(queue_unit_b)
	root.add_child(queue_unit_c)
	screen._queue.append({"unit": queue_unit_a, "increases": {"hp": 1}})
	screen._queue.append({"unit": queue_unit_b, "increases": {"strength": 1}})
	screen._queue.append({"unit": queue_unit_c, "increases": {"speed": 1}})
	screen._show_next()
	await process_frame
	var queue_names: Array[String] = [screen.get_node("Panel/VBox/LabelName").text]
	screen._unhandled_input(confirm)
	await process_frame
	queue_names.append(screen.get_node("Panel/VBox/LabelName").text)
	screen._unhandled_input(confirm)
	await process_frame
	queue_names.append(screen.get_node("Panel/VBox/LabelName").text)
	screen._unhandled_input(confirm)
	await process_frame
	if queue_names == ["Queue A", "Queue B", "Queue C"] and not screen.visible:
		print("OK  queued level-up panels advance in order without dropping entries"); passed += 1
	else:
		print("FAIL queued level-up order: %s visible=%s" % [queue_names, screen.visible]); failed += 1

	# A long stat burst should resize the panel instead of clipping the text.
	screen._queue.append({
		"unit": stub_unit,
		"increases": {"hp": 1, "strength": 1, "magic": 1, "defense": 1, "resistance": 1, "skill": 1, "speed": 1, "luck": 1},
	})
	screen._show_next()
	await process_frame
	var panel: Panel = screen.get_node("Panel")
	if panel.size.y > 200.0:
		print("OK  panel grows for long level-up summaries"); passed += 1
	else:
		print("FAIL panel did not grow for long summary: size=%s" % str(panel.size)); failed += 1
	screen._unhandled_input(confirm)
	await process_frame

	stub_unit.queue_free()
	queue_unit_a.queue_free()
	queue_unit_b.queue_free()
	queue_unit_c.queue_free()
	screen.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _make_stub_unit(stub_unit_script: GDScript, unit_name: String, level: int) -> Node:
	var stub_unit: Node = stub_unit_script.new()
	stub_unit.data.unit_name = unit_name
	stub_unit.data.level = level
	return stub_unit
