extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_map_menu.gd
# Covers the pause-style MapMenu signal contract, including the new
# Exit-to-Main-Menu button.


func _init() -> void:
	print("=== MapMenu Test ===")
	var passed := 0
	var failed := 0

	var packed := load("res://scenes/ui/MapMenu.tscn")
	if packed == null:
		print("FAIL could not load MapMenu.tscn")
		quit(1)
		return
	var menu: Control = packed.instantiate()
	root.add_child(menu)
	await process_frame

	var events := {
		"end_turn": 0,
		"settings": 0,
		"quit_to_menu": 0,
		"closed": 0,
	}
	menu.end_turn_requested.connect(func() -> void: events["end_turn"] += 1)
	menu.settings_requested.connect(func() -> void: events["settings"] += 1)
	menu.quit_to_menu_requested.connect(func() -> void: events["quit_to_menu"] += 1)
	menu.menu_closed.connect(func() -> void: events["closed"] += 1)

	menu.open()
	menu._on_quit_to_menu()
	if not menu.visible and events["quit_to_menu"] == 1 and events["closed"] == 0:
		print("OK  quit-to-menu hides the menu and emits only quit_to_menu_requested")
		passed += 1
	else:
		print("FAIL quit-to-menu: visible=%s quit=%s closed=%s" % [
			menu.visible, events["quit_to_menu"], events["closed"]])
		failed += 1

	menu.open()
	menu._on_settings()
	if not menu.visible and events["settings"] == 1 and events["closed"] == 0:
		print("OK  settings hides the menu without emitting menu_closed")
		passed += 1
	else:
		print("FAIL settings path: visible=%s settings=%s closed=%s" % [
			menu.visible, events["settings"], events["closed"]])
		failed += 1

	menu.open()
	menu._on_end_turn()
	if not menu.visible and events["end_turn"] == 1 and events["closed"] == 1:
		print("OK  end-turn hides the menu and emits menu_closed")
		passed += 1
	else:
		print("FAIL end-turn path: visible=%s end=%s closed=%s" % [
			menu.visible, events["end_turn"], events["closed"]])
		failed += 1

	# V021-13: a left-click on the backdrop dismisses the menu (emits menu_closed).
	menu.open()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	menu._on_backdrop_input(click)
	if not menu.visible and events["closed"] == 2:
		print("OK  V021-13 backdrop click dismisses the menu")
		passed += 1
	else:
		print("FAIL V021-13 backdrop: visible=%s closed=%s" % [menu.visible, events["closed"]])
		failed += 1

	menu.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
