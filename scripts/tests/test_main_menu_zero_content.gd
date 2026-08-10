extends SceneTree
# Player-facing no-pack state keeps the shell usable while gameplay is disabled.

const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const TEST_SAVE_DIR := "user://test_main_menu_zero_content"


func _init() -> void:
	print("=== Main Menu Zero Content Test ===")
	var passed := 0
	var failed := 0
	await process_frame
	var manager := root.get_node_or_null("DataManager")
	manager.call("deactivate_campaign_package")
	Installer._remove_tree(TEST_SAVE_DIR)
	root.get_node("SaveManager").call("configure_save_dir_for_tests", TEST_SAVE_DIR)

	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var new_game: Button = menu.get_node("MenuFrame/Panel/Scroll/VBox/NewGameButton")
	var library: Button = menu.get_node("MenuFrame/Panel/Scroll/VBox/CampaignLibraryButton")
	var settings: Button = menu.get_node("MenuFrame/Panel/Scroll/VBox/SettingsButton")
	if (
		new_game.disabled
		and new_game.text == "New Game (No Data Packs Installed)"
		and "install or select" in new_game.tooltip_text.to_lower()
		and not library.disabled
		and not settings.disabled
		and menu.get_viewport().gui_get_focus_owner() == library
	):
		print("OK  no-pack menu disables play and focuses the available Campaign Library")
		passed += 1
	else:
		print(
			(
				"FAIL no-pack menu: disabled=%s text=%s tooltip=%s library=%s settings=%s focus=%s"
				% [
					new_game.disabled,
					new_game.text,
					new_game.tooltip_text,
					library.disabled,
					settings.disabled,
					menu.get_viewport().gui_get_focus_owner(),
				]
			)
		)
		failed += 1

	menu.call("_on_campaign_library")
	await process_frame
	var library_screen: Control = menu.get_node("CampaignLibraryScreen")
	if library_screen.visible:
		print("OK  Campaign Library opens directly from the zero-content main menu")
		passed += 1
	else:
		print("FAIL Campaign Library did not open from the main menu")
		failed += 1
	library_screen.call("_close")
	await process_frame

	manager.call("select_tier2_campaign_source", "user://missing-pack", "missing", "1.0")
	menu.call("_refresh_menu_state")
	if "validation failed" in new_game.tooltip_text.to_lower():
		print("OK  invalid-pack diagnostics remain visible from the no-pack state")
		passed += 1
	else:
		print("FAIL invalid-pack diagnostic: %s" % new_game.tooltip_text)
		failed += 1

	menu.queue_free()
	manager.call("activate_project_data_compatibility")
	Installer._remove_tree(TEST_SAVE_DIR)
	await process_frame
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
