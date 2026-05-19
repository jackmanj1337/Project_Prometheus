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
	var stub_unit: Node = stub_unit_script.new()
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

	stub_unit.queue_free()
	screen.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
