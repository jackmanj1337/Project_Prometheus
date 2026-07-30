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
	var new_game: Button = menu.get_node("Panel/VBox/NewGameButton")
	var settings: Button = menu.get_node("Panel/VBox/SettingsButton")
	if (
		new_game.disabled
		and new_game.text == "New Game (No Packs)"
		and "install or select" in new_game.tooltip_text.to_lower()
		and not settings.disabled
		and menu.get_viewport().gui_get_focus_owner() == settings
	):
		print("OK  no-pack menu disables play, explains recovery, and focuses Settings")
		passed += 1
	else:
		print(
			(
				"FAIL no-pack menu: disabled=%s text=%s tooltip=%s settings=%s focus=%s"
				% [
					new_game.disabled,
					new_game.text,
					new_game.tooltip_text,
					settings.disabled,
					menu.get_viewport().gui_get_focus_owner(),
				]
			)
		)
		failed += 1

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
