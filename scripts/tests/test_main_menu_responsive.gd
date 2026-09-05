extends SceneTree
## Main Menu responsive contract: one stable tree consumes the shared class and density
## seam, preserving interaction state while its constraints change live.

const MainMenuScript = preload("res://scripts/ui/MainMenu.gd")

# The supported logical width floor and the checklist's Compact window. The floor is the
# case that matters: the gate label clears it by 0.0 px, so anything that grows the menu
# font, the compact gutter token or _PANEL_WIDTH_RATIOS starts clipping it there first.
const _FIT_SIZES: Array[Vector2i] = [Vector2i(282, 720), Vector2i(360, 640)]


# How far MainMenu.NO_PACK_LABEL overruns what the viewport can show, in pixels; <= 0
# means it is drawn whole. Two overruns are measured because either one alone is
# self-fulfilling:
#
#   1. text vs button   -- catches clip_text / ellipsis once something caps the button.
#   2. button vs viewport -- catches the case that actually happens. The button takes its
#      minimum width FROM its text, so a longer label widens the button and the panel
#      instead of overflowing them, and assertion 1 stays true right up until the menu
#      hangs off the edge of the screen. Verified by lengthening the constant: only this
#      second measurement moves.
#
# A Control also only measures at its real width inside a viewport of that size --
# ResponsiveLayout.apply_logical_size() sets the class and tokens but not the viewport,
# so measuring without one measures the headless default (~1152 px) and passes on
# anything at all.
func _label_overflow(responsive: Node, size: Vector2i, factor: float) -> float:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	responsive.apply_logical_size(Vector2(size))
	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	viewport.add_child(menu)
	menu.show()
	menu.apply_menu_scale(factor)
	await process_frame
	var button: Button = menu.get_node("MenuFrame/Panel/Scroll/VBox/NewGameButton")
	button.disabled = true
	button.text = MainMenuScript.NO_PACK_LABEL
	await process_frame
	await process_frame
	var font: Font = button.get_theme_font("font")
	var font_size: int = button.get_theme_font_size("font_size")
	var needed: float = (
		font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	)
	var style: StyleBox = button.get_theme_stylebox("normal")
	var available: float = (
		button.size.x - style.get_margin(SIDE_LEFT) - style.get_margin(SIDE_RIGHT)
	)
	var rect := button.get_global_rect()
	var overflow: float = maxf(needed - available, rect.end.x - float(size.x))
	overflow = maxf(overflow, -rect.position.x)
	viewport.queue_free()
	await process_frame
	return overflow


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

	# V0710-MAIN-MENU-CLIPPING-2026-08-25 was closed by archiving its abbreviation rather
	# than merging it, because the full label fits everywhere it has to. Factor 2.0 is
	# measured as well: Main Menu ignores the Menu Scale preference by design (it is a
	# pinned-large home screen), so the 2x failure mode that broke Settings must not be
	# able to reach this label either. Sub-pixel slack is real slack; only overflow fails.
	responsive.set_menu_mode(responsive.MENU_MODE_TOUCH)
	var worst_overflow := -INF
	var worst_case := ""
	for fit_size in _FIT_SIZES:
		for factor in [1.0, 2.0]:
			var overflow: float = await _label_overflow(responsive, fit_size, factor)
			if overflow > worst_overflow:
				worst_overflow = overflow
				worst_case = "%dx%d at %.1fx" % [fit_size.x, fit_size.y, factor]
	if worst_overflow <= 0.0:
		print(
			(
				"OK  the full gate label fits every supported Compact width (worst %s, %.1f px spare)"
				% [worst_case, absf(worst_overflow)]
			)
		)
		passed += 1
	else:
		print(
			(
				"FAIL gate label overruns the visible width by %.1f px at %s"
				% [worst_overflow, worst_case]
			)
		)
		failed += 1

	responsive.set_menu_mode(responsive.MENU_MODE_TOUCH)
	responsive.apply_logical_size(Vector2(1280.0, 720.0))
	menu.queue_free()
	await process_frame
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
