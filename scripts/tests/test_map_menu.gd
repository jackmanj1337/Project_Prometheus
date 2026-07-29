extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_map_menu.gd
# Covers the pause-style MapMenu signal contract, including the new
# Suspend & Quit and Exit-to-Main-Menu buttons.


func _init() -> void:
	print("=== MapMenu Test ===")
	var passed := 0
	var failed := 0
	var bus: Node = load("res://scripts/autoloads/EventBus.gd").new()
	bus.name = "EventBus"
	root.add_child(bus)

	var packed := load("res://scenes/ui/MapMenu.tscn")
	if packed == null:
		print("FAIL could not load MapMenu.tscn")
		quit(1)
		return
	var menu: Control = packed.instantiate()
	root.add_child(menu)
	await process_frame
	if (
		menu.format_party_gold(0) == "Total gold: 0"
		and menu.format_party_gold(987654321) == "Total gold: 987654321"
	):
		print("OK  Map Menu formats zero and large read-only balances")
		passed += 1
	else:
		print("FAIL Map Menu gold formatting")
		failed += 1

	var events := {
		"end_turn": 0,
		"settings": 0,
		"suspend": 0,
		"quit_to_menu": 0,
		"closed": 0,
	}
	if menu.get_node_or_null("Panel/VBox/RewindButton") != null:
		print("OK  rewind action is present in the map menu")
		passed += 1
	else:
		print("FAIL rewind action missing")
		failed += 1
	menu.end_turn_requested.connect(func() -> void: events["end_turn"] += 1)
	menu.settings_requested.connect(func() -> void: events["settings"] += 1)
	menu.suspend_and_quit_requested.connect(func() -> void: events["suspend"] += 1)
	menu.quit_to_menu_requested.connect(func() -> void: events["quit_to_menu"] += 1)
	menu.menu_closed.connect(func() -> void: events["closed"] += 1)

	menu.set_ai_phase_mode(true)
	menu.set_suspend_available(true)
	menu.open()
	if bus.is_gameplay_modal_locked():
		print("OK  opening Map Menu acquires the shared gameplay-modal lock")
		passed += 1
	else:
		print("FAIL Map Menu did not acquire gameplay-modal lock")
		failed += 1
	var end_button: Button = menu.get_node("Panel/VBox/EndTurnButton")
	var rewind_button: Button = menu.get_node("Panel/VBox/RewindButton")
	var suspend_button: Button = menu.get_node("Panel/VBox/SuspendAndQuitButton")
	if end_button.disabled and rewind_button.disabled and suspend_button.has_focus():
		print("OK  AI-phase menu disables phase mutation and focuses Suspend")
		passed += 1
	else:
		print("FAIL AI-phase restricted menu")
		failed += 1
	menu.hide()
	menu._release_modal_lock()
	menu.set_ai_phase_mode(false)

	menu.open()
	var rewind_options: Array[Dictionary] = [{"target_index": 0, "cost": 1, "label": "Previous"}]
	menu.open_rewind_selector(rewind_options)
	if not menu.get_node("Panel").visible and menu.get_node("RewindSelector").visible:
		print("OK  rewind selector disables its host panel and retains modal ownership")
		passed += 1
	else:
		print("FAIL rewind selector host visibility")
		failed += 1
	menu.close_rewind_selector()
	if menu.get_node("Panel").visible and bus.is_gameplay_modal_locked():
		print("OK  cancelling rewind restores host focus without leaking/releasing its lock")
		passed += 1
	else:
		print("FAIL rewind cancel modal state")
		failed += 1
	menu.hide()
	menu._release_modal_lock()
	if not bus.is_gameplay_modal_locked():
		print("OK  closing Map Menu releases the shared gameplay-modal lock")
		passed += 1
	else:
		print("FAIL Map Menu leaked gameplay-modal lock")
		failed += 1

	menu.set_suspend_available(false)
	menu.open()
	menu._on_suspend_and_quit()
	if menu.visible and events["suspend"] == 0:
		print("OK  disabled suspend button does not emit")
		passed += 1
	else:
		print("FAIL disabled suspend: visible=%s suspend=%s" % [menu.visible, events["suspend"]])
		failed += 1
	menu._on_close()

	menu.set_suspend_available(true)
	menu.open()
	menu._on_suspend_and_quit()
	if not menu.visible and events["suspend"] == 1 and events["closed"] == 1:
		print("OK  suspend hides the menu and emits suspend_and_quit_requested")
		passed += 1
	else:
		print(
			(
				"FAIL suspend path: visible=%s suspend=%s closed=%s"
				% [menu.visible, events["suspend"], events["closed"]]
			)
		)
		failed += 1

	menu.open()
	menu._on_quit_to_menu()
	if not menu.visible and events["quit_to_menu"] == 1 and events["closed"] == 1:
		print("OK  quit-to-menu hides the menu and emits only quit_to_menu_requested")
		passed += 1
	else:
		print(
			(
				"FAIL quit-to-menu: visible=%s quit=%s closed=%s"
				% [menu.visible, events["quit_to_menu"], events["closed"]]
			)
		)
		failed += 1

	menu.open()
	menu._on_settings()
	if not menu.visible and events["settings"] == 1 and events["closed"] == 1:
		print("OK  settings hides the menu without emitting menu_closed")
		passed += 1
	else:
		print(
			(
				"FAIL settings path: visible=%s settings=%s closed=%s"
				% [menu.visible, events["settings"], events["closed"]]
			)
		)
		failed += 1

	menu.open()
	menu._on_end_turn()
	if not menu.visible and events["end_turn"] == 1 and events["closed"] == 2:
		print("OK  end-turn hides the menu and emits menu_closed")
		passed += 1
	else:
		print(
			(
				"FAIL end-turn path: visible=%s end=%s closed=%s"
				% [menu.visible, events["end_turn"], events["closed"]]
			)
		)
		failed += 1

	# V021-13: a left-click on the backdrop dismisses the menu (emits menu_closed).
	menu.open()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	menu._on_backdrop_input(click)
	if not menu.visible and events["closed"] == 3:
		print("OK  V021-13 backdrop click dismisses the menu")
		passed += 1
	else:
		print("FAIL V021-13 backdrop: visible=%s closed=%s" % [menu.visible, events["closed"]])
		failed += 1

	menu.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
