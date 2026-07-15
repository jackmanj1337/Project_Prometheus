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
		print("FAIL could not load LevelUpScreen.tscn")
		quit(1)
		return
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
		print("OK  panel visible after _show_next")
		passed += 1
	else:
		print("FAIL panel not visible after _show_next")
		failed += 1

	# V025-05b: clicks are now handled in _gui_input (the STOP root consumes mouse
	# buttons in the GUI phase before _unhandled_input can see them on desktop). Drive
	# the real handler here; the mouse_filter invariant below proves a click actually
	# reaches this root on the live build.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	screen._gui_input(click)
	await process_frame
	if not screen.visible:
		print("OK  left-click dismisses the level-up panel (playtest 3 #2 / V025-05b)")
		passed += 1
	else:
		print("FAIL left-click did not dismiss the panel")
		failed += 1

	# V025-05b structural invariant: the root must be STOP (so it receives the GUI
	# mouse phase) and every descendant of the Panel must be IGNORE (so a click
	# anywhere on the screen falls through to the root's _gui_input, not a child).
	# This is the desktop-routing guarantee headless picking can't exercise directly.
	var root_stop: bool = screen.mouse_filter == Control.MOUSE_FILTER_STOP
	var subtree_ignore := true
	var offender := ""
	var stack: Array[Node] = [screen.get_node("Panel")]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Control and (n as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			subtree_ignore = false
			offender = String(n.name)
		for child in n.get_children():
			stack.push_back(child)
	if root_stop and subtree_ignore:
		print(
			"OK  root is STOP and the Panel subtree is IGNORE — clicks reach _gui_input (V025-05b)"
		)
		passed += 1
	else:
		print(
			(
				"FAIL mouse_filter routing: root_stop=%s subtree_ignore=%s offender=%s"
				% [root_stop, subtree_ignore, offender]
			)
		)
		failed += 1

	# V023-05: mouse wheel and zoom actions are input to block, not dismissal.
	screen._queue.append({"unit": stub_unit, "increases": {"hp": 1}})
	screen._show_next()
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	screen._unhandled_input(wheel)
	await process_frame
	var wheel_kept_open: bool = screen.visible
	var zoom := InputEventAction.new()
	zoom.action = "zoom_in"
	zoom.pressed = true
	screen._unhandled_input(zoom)
	await process_frame
	var zoom_kept_open: bool = screen.visible
	if wheel_kept_open and zoom_kept_open:
		print("OK  wheel/zoom input is blocked without dismissing level-up (V023-05)")
		passed += 1
	else:
		print(
			(
				"FAIL wheel/zoom dismissed level-up: wheel=%s zoom=%s"
				% [wheel_kept_open, zoom_kept_open]
			)
		)
		failed += 1
	screen._advance()
	await process_frame

	# Confirm action still works after the change — guards against regression.
	screen._queue.append({"unit": stub_unit, "increases": {"hp": 1}})
	screen._show_next()
	var confirm := InputEventAction.new()
	confirm.action = "confirm"
	confirm.pressed = true
	screen._unhandled_input(confirm)
	await process_frame
	if not screen.visible:
		print("OK  confirm key still dismisses the panel")
		passed += 1
	else:
		print("FAIL confirm key no longer dismisses")
		failed += 1

	# A level-up that learns a skill announces it on the stats label (M3).
	(
		screen
		. _queue
		. append(
			{
				"unit": stub_unit,
				"increases": {"hp": 1},
				"learned": [{"id": "vantage", "equipped": true}],
			}
		)
	)
	screen._show_next()
	await process_frame
	var stats_label: Label = screen.get_node("Panel/Margin/VBox/LabelStats")
	if "Learned" in stats_label.text and "Vantage" in stats_label.text:
		print("OK  level-up panel announces a learned skill")
		passed += 1
	else:
		print("FAIL learned-skill line missing: '%s'" % stats_label.text)
		failed += 1
	screen._unhandled_input(confirm)
	await process_frame

	# M6.3: when the skill cap is full, the learned line explains the skill was stored.
	(
		screen
		. _queue
		. append(
			{
				"unit": stub_unit,
				"increases": {"hp": 1},
				"learned": [{"id": "wrath", "equipped": false}],
			}
		)
	)
	screen._show_next()
	await process_frame
	if "skill slots full" in stats_label.text and "Wrath" in stats_label.text:
		print("OK  learned-skill line explains when the skill is stored due to full slots")
		passed += 1
	else:
		print("FAIL stored-skill line missing: '%s'" % stats_label.text)
		failed += 1
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
	var queue_names: Array[String] = [screen.get_node("Panel/Margin/VBox/LabelName").text]
	screen._unhandled_input(confirm)
	await process_frame
	queue_names.append(screen.get_node("Panel/Margin/VBox/LabelName").text)
	screen._unhandled_input(confirm)
	await process_frame
	queue_names.append(screen.get_node("Panel/Margin/VBox/LabelName").text)
	screen._unhandled_input(confirm)
	await process_frame
	if queue_names == ["Queue A", "Queue B", "Queue C"] and not screen.visible:
		print("OK  queued level-up panels advance in order without dropping entries")
		passed += 1
	else:
		print("FAIL queued level-up order: %s visible=%s" % [queue_names, screen.visible])
		failed += 1

	# A long stat burst should resize the panel instead of clipping the text.
	(
		screen
		. _queue
		. append(
			{
				"unit": stub_unit,
				"increases":
				{
					"hp": 1,
					"strength": 1,
					"magic": 1,
					"defense": 1,
					"resistance": 1,
					"skill": 1,
					"speed": 1,
					"luck": 1
				},
			}
		)
	)
	screen._show_next()
	await process_frame
	var panel: PanelContainer = screen.get_node("Panel")
	if panel.size.y > 200.0:
		print("OK  panel grows for long level-up summaries")
		passed += 1
	else:
		print("FAIL panel did not grow for long summary: size=%s" % str(panel.size))
		failed += 1
	screen._unhandled_input(confirm)
	await process_frame

	# V025-05a: the FIRST level-up shown on a fresh screen used to pin a degenerate
	# narrow/tall frame (recenter sized an un-laid-out autowrap label). With autowrap
	# dropped + deferred sizing, a fresh screen's first show must match a second show.
	var fresh: Control = packed.instantiate()
	root.add_child(fresh)
	await process_frame
	var burst: Dictionary = {"hp": 1, "strength": 1, "speed": 1}
	fresh._queue.append({"unit": stub_unit, "increases": burst})
	fresh._show_next()
	await process_frame
	await process_frame  # deferred size settles one layout frame after show
	var first_panel: PanelContainer = fresh.get_node("Panel")
	var first_size: Vector2 = first_panel.size
	fresh._queue.append({"unit": stub_unit, "increases": burst})
	fresh._show_next()  # second show, identical content
	await process_frame
	await process_frame
	var second_size: Vector2 = first_panel.size
	# The two shows must agree (the bug was a first-show-only race), and the panel
	# must not have collapsed to a narrow sliver — the degenerate frame was ~sliver
	# wide because an un-laid-out autowrap label reported a tiny minimum width.
	var stable: bool = (
		absf(first_size.x - second_size.x) <= 2.0 and absf(first_size.y - second_size.y) <= 2.0
	)
	var not_sliver: bool = first_size.x >= 100.0
	if stable and not_sliver:
		print("OK  V025-05a first-show panel size is non-sliver and matches second show")
		passed += 1
	else:
		print("FAIL first-show size: first=%s second=%s" % [first_size, second_size])
		failed += 1
	fresh.queue_free()

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
