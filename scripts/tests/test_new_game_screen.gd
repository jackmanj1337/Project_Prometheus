extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_new_game_screen.gd
# Verifies NewGameScreen.tscn instantiates, the nodes its script's @onready vars
# expect resolve, and the opaque Dimmer exists so the screen is modal (#4).

func _init() -> void:
	print("=== NewGameScreen Test ===")
	var passed := 0
	var failed := 0
	if root.get_node_or_null("RegistryManager") == null:
		var registry_manager: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
		registry_manager.name = "RegistryManager"
		root.add_child(registry_manager)
	if root.get_node_or_null("DataManager") == null:
		var data_manager: Node = load("res://scripts/autoloads/DataManager.gd").new()
		data_manager.name = "DataManager"
		root.add_child(data_manager)
	if root.get_node_or_null("SaveManager") == null:
		var save_manager: Node = load("res://scripts/autoloads/SaveManager.gd").new()
		save_manager.name = "SaveManager"
		save_manager.configure_save_dir_for_tests("user://test_new_game_preferences")
		root.add_child(save_manager)
		DirAccess.make_dir_recursive_absolute("user://test_new_game_preferences")
		var preference_dir := DirAccess.open("user://test_new_game_preferences")
		for file_name in preference_dir.get_files():
			preference_dir.remove(file_name)

	var packed := load("res://scenes/ui/NewGameScreen.tscn")
	if packed == null:
		print("FAIL could not load NewGameScreen.tscn"); quit(1); return
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame

	# Dimmer makes the screen opaque/modal over MainMenu (#4).
	if screen.get_node_or_null("Dimmer") != null:
		print("OK  Dimmer node present (#4 background)"); passed += 1
	else:
		print("FAIL no Dimmer node (#4)"); failed += 1

	# Every node the NewGameScreen script's @onready vars depend on must exist.
	var expected := [
		"Panel/VBox/HBoxRun/OptRun",
		"Panel/VBox/HBoxPermadeath/OptPermadeath",
		"Panel/VBox/HBoxAutoPromote/OptAutoPromote",
		"Panel/VBox/HBoxLeveling/OptLeveling",
		"Panel/VBox/HBoxPairUp/OptPairUp",
		"Panel/VBox/BtnManageCampaigns",
		"Panel/VBox/BtnStart",
		"Panel/VBox/BtnBack",
	]
	var all_present := true
	for path in expected:
		if screen.get_node_or_null(path) == null:
			all_present = false
			print("FAIL missing node: " + path)
			failed += 1
	if all_present:
		print("OK  all @onready-referenced nodes resolve"); passed += 1

	var run_opt: OptionButton = screen.get_node_or_null("Panel/VBox/HBoxRun/OptRun")
	var has_proving := false
	var has_single_map := false
	if run_opt != null:
		for index in run_opt.item_count:
			has_proving = has_proving or run_opt.get_item_text(index) == "The Proving Grounds"
			has_single_map = has_single_map or run_opt.get_item_text(index) == "Map 001 - Rout"
	if has_proving and has_single_map and screen.get_node_or_null("Panel/VBox/HBoxMap") == null:
		print("OK  every map and authored run share the one campaign selector"); passed += 1
	else:
		print("FAIL unified campaign selector proving=%s single=%s" % [
			has_proving, has_single_map]); failed += 1
	var save_manager: Node = root.get_node("SaveManager")
	save_manager.record_campaign_imported({
		"campaign_id": CampaignData.single_map_campaign_id("map_001")})
	screen._select_preferred_run()
	var imported_selected: bool = screen._run_options[run_opt.selected]["campaign_id"] \
		== CampaignData.single_map_campaign_id("map_001")
	save_manager.record_campaign_started({"campaign_id": "proving_grounds"})
	screen._select_preferred_run()
	if imported_selected and screen._run_options[run_opt.selected]["campaign_id"] == "proving_grounds":
		print("OK  selector prefers last-started, else most-recently-imported"); passed += 1
	else:
		print("FAIL campaign selector preference"); failed += 1

	var auto_opt: OptionButton = screen.get_node_or_null("Panel/VBox/HBoxAutoPromote/OptAutoPromote")
	if auto_opt != null and auto_opt.item_count == 2:
		print("OK  auto-promote selector is present with Off/On choices"); passed += 1
	else:
		print("FAIL auto-promote selector missing or not populated"); failed += 1

	var pair_opt: OptionButton = screen.get_node_or_null("Panel/VBox/HBoxPairUp/OptPairUp")
	if pair_opt != null and pair_opt.item_count == 2:
		print("OK  pair-up selector is present with Off/On choices"); passed += 1
	else:
		print("FAIL pair-up selector missing or not populated"); failed += 1

	screen._apply_rule_authority({"rules": {
		"death_mode": {"authority": "mandate", "value": "classic"},
		"pair_up_enabled": {"authority": "default", "value": false},
	}})
	var permadeath_opt: OptionButton = screen.get_node(
		"Panel/VBox/HBoxPermadeath/OptPermadeath")
	if permadeath_opt.disabled and permadeath_opt.selected == 1 \
			and not pair_opt.disabled and pair_opt.selected == 0:
		print("OK  mandated campaign rules lock while authored defaults stay editable"); passed += 1
	else:
		print("FAIL campaign rule authority controls"); failed += 1
	# Restore ordinary controls for the persistence checks below.
	screen._apply_rule_authority({})

	# Some tests run without autoloads; add the tiny subset NewGameScreen.open()
	# needs so the persistence checks below exercise real code paths.
	var created_gs := false
	var gs_node := root.get_node_or_null("GameState")
	if gs_node == null:
		var gs_script := GDScript.new()
		gs_script.source_code = """
extends Node
var next_map_data_path: String = ""
const CampaignRulesScript = preload("res://scripts/resources/CampaignRules.gd")
var campaign_rules = CampaignRulesScript.make_default()
"""
		gs_script.reload()
		gs_node = gs_script.new()
		gs_node.name = "GameState"
		root.add_child(gs_node)
		created_gs = true

	# open() / _on_back() drive visibility. open() reads GameState — skip the
	# check cleanly when that autoload is absent.
	if gs_node != null:
		screen.open()
		var shown := screen.visible
		screen._on_back()
		if shown and not screen.visible:
			print("OK  open() shows the screen, _on_back() hides it"); passed += 1
		else:
			print("FAIL visibility: shown=%s after_back=%s" % [shown, screen.visible])
			failed += 1
	else:
		print("SKIP open()/back visibility (GameState autoload absent)")

	# ---- rule toggles persist to GameState on change, without pressing Start ----
	# playtest v0.1.4 #1.2: changing Pair Up / Auto Promote then closing the panel
	# (no Start) must be remembered. The on-change handler writes through to
	# GameState; open() seeds the controls back from it.
	if gs_node != null:
		var rules: CampaignRules = gs_node.get("campaign_rules") as CampaignRules
		var want_pair := not rules.pair_up_enabled
		var want_auto := not rules.auto_promote_at_max_level
		pair_opt.selected = 1 if want_pair else 0
		pair_opt.item_selected.emit(pair_opt.selected)   # as a click would
		auto_opt.selected = 1 if want_auto else 0
		auto_opt.item_selected.emit(auto_opt.selected)
		# Note: no _on_start() — this is the "closed without starting" path.
		var persisted_ok: bool = rules.pair_up_enabled == want_pair \
			and rules.auto_promote_at_max_level == want_auto
		if persisted_ok:
			print("OK  rule toggles persist to GameState on change (no Start needed)"); passed += 1
		else:
			print("FAIL rule persistence: pair=%s want=%s | auto=%s want=%s" % [
				rules.pair_up_enabled, want_pair,
				rules.auto_promote_at_max_level, want_auto])
			failed += 1
	else:
		print("SKIP rule persistence (GameState autoload absent)")

	# ---- modal focus containment and repeat in the live MainMenu parent ----
	if gs_node != null:
		var menu_packed := load("res://scenes/ui/MainMenu.tscn")
		var menu: Control = menu_packed.instantiate()
		root.add_child(menu)
		await process_frame
		var modal: Control = menu.get_node("NewGameScreen")
		var background_continue: Button = menu.get_node("Panel/VBox/ContinueButton")
		var modal_run: OptionButton = modal.get_node("Panel/VBox/HBoxRun/OptRun")
		var modal_permadeath: OptionButton = modal.get_node("Panel/VBox/HBoxPermadeath/OptPermadeath")
		menu._on_new_game()
		await process_frame
		background_continue.grab_focus()
		modal._process(0.016)
		var focus_owner := modal.get_viewport().gui_get_focus_owner()
		var contained_focus := modal.is_ancestor_of(focus_owner)
		modal_run.grab_focus()
		Input.action_press("ui_down", 1.0)
		modal._process(0.016)
		focus_owner = modal.get_viewport().gui_get_focus_owner()
		var repeated_down := focus_owner == modal_permadeath
		Input.action_release("ui_down")
		modal._process(0.016)

		# V031-GP-02: while an OptionButton popup (a capture-mode embedded Window)
		# is open, polled focus stepping stands down — a held direction must NOT
		# move the panel focus behind the popup, and the popup-close frame
		# re-latches the repeat so the still-held direction doesn't step either.
		modal_permadeath.grab_focus()
		modal_run.show_popup()
		await process_frame
		var popup_seen: bool = modal._capture_ui_active()
		Input.action_press("ui_down", 1.0)
		modal._process(0.016)
		modal._process(0.016)
		focus_owner = modal.get_viewport().gui_get_focus_owner()
		var popup_stood_down := focus_owner == modal_permadeath
		modal_run.get_popup().hide()
		await process_frame
		modal._process(0.016)  # close frame: re-latch, no step
		focus_owner = modal.get_viewport().gui_get_focus_owner()
		var close_frame_latched := focus_owner == modal_permadeath
		Input.action_release("ui_down")
		modal._process(0.016)
		Input.action_press("ui_down", 1.0)
		modal._process(0.016)
		focus_owner = modal.get_viewport().gui_get_focus_owner()
		var steps_after_neutral := focus_owner != modal_permadeath
		Input.action_release("ui_down")
		modal._process(0.016)

		menu.queue_free()
		if contained_focus and repeated_down:
			print("OK  MainMenu-hosted NewGame modal contains focus and repeats down")
			passed += 1
		else:
			print("FAIL modal focus: contained=%s repeated_down=%s focus=%s" % [
				contained_focus, repeated_down, focus_owner])
			failed += 1
		if popup_seen and popup_stood_down and close_frame_latched and steps_after_neutral:
			print("OK  open dropdown stands down polled focus stepping and re-latches on close")
			passed += 1
		else:
			print("FAIL popup standdown: seen=%s stood_down=%s latched=%s after_neutral=%s focus=%s" % [
				popup_seen, popup_stood_down, close_frame_latched, steps_after_neutral, focus_owner])
			failed += 1
	else:
		print("SKIP modal focus containment (GameState unavailable)")

	if created_gs and gs_node != null:
		gs_node.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
