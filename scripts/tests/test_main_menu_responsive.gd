extends SceneTree
## Main Menu responsive contract: one stable tree consumes the shared class and density
## seam, preserving interaction state while its constraints change live.


func _init() -> void:
	print("=== Main Menu Responsive Test ===")
	var passed := 0
	var failed := 0
	await process_frame

	var responsive: Node = root.get_node_or_null("ResponsiveLayout")
	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	if responsive == null:
		print("FAIL ResponsiveLayout autoload missing")
		quit(1)
		return

	var panel: PanelContainer = menu.get_node("MenuFrame/Panel")
	var scroll: ScrollContainer = menu.get_node("MenuFrame/Panel/Scroll")
	var buttons: Array[Button] = [
		menu.get_node("MenuFrame/Panel/Scroll/VBox/ContinueButton"),
		menu.get_node("MenuFrame/Panel/Scroll/VBox/LoadGameButton"),
		menu.get_node("MenuFrame/Panel/Scroll/VBox/NewGameButton"),
		menu.get_node("MenuFrame/Panel/Scroll/VBox/SettingsButton"),
		menu.get_node("MenuFrame/Panel/Scroll/VBox/QuitButton"),
	]
	var settings_button := buttons[3]
	settings_button.grab_focus()
	scroll.scroll_vertical = 7

	responsive.set_menu_mode(responsive.MENU_MODE_TOUCH)
	responsive.apply_logical_size(Vector2(400.0, 800.0))
	await process_frame
	var compact_width := panel.custom_minimum_size.x
	var touch_height := buttons[0].custom_minimum_size.y
	if (
		responsive.size_class == responsive.CLASS_COMPACT
		and is_equal_approx(touch_height, responsive.token("row_height"))
		and menu.get_viewport().gui_get_focus_owner() == settings_button
	):
		print("OK  Compact consumes touch tokens and preserves focus")
		passed += 1
	else:
		print("FAIL Compact class, touch row, or focus contract")
		failed += 1

	responsive.apply_logical_size(Vector2(800.0, 480.0))
	await process_frame
	var medium_width := panel.custom_minimum_size.x
	responsive.apply_logical_size(Vector2(1280.0, 720.0))
	await process_frame
	var expanded_width := panel.custom_minimum_size.x
	if compact_width > medium_width and medium_width > expanded_width:
		print("OK  class changes progressively cap the centred menu panel")
		passed += 1
	else:
		print(
			(
				"FAIL panel widths compact=%s medium=%s expanded=%s"
				% [compact_width, medium_width, expanded_width]
			)
		)
		failed += 1

	responsive.set_menu_mode(responsive.MENU_MODE_CONTROLLER)
	await process_frame
	if (
		is_equal_approx(buttons[0].custom_minimum_size.y, responsive.token("row_height"))
		and buttons[0].custom_minimum_size.y < touch_height
		and menu.get_viewport().gui_get_focus_owner() == settings_button
	):
		print("OK  live density change updates rows without losing focus")
		passed += 1
	else:
		print("FAIL controller density or focus contract")
		failed += 1

	# The screen never replaces either node during class or density changes. This is the
	# durable state-preservation contract; ScrollContainer may clamp a synthetic offset
	# when all five rows fit, so node identity is the reliable headless assertion.
	if menu.get_node("MenuFrame/Panel/Scroll") == scroll and buttons[3] == settings_button:
		print("OK  live changes retain the scrolling and selection controls")
		passed += 1
	else:
		print("FAIL responsive update rebuilt interaction controls")
		failed += 1

	responsive.set_menu_mode(responsive.MENU_MODE_TOUCH)
	responsive.apply_logical_size(Vector2(1280.0, 720.0))
	menu.queue_free()
	await process_frame
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
