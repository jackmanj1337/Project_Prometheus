extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_new_game_screen.gd
# Verifies NewGameScreen.tscn instantiates, the nodes its script's @onready vars
# expect resolve, and the opaque Dimmer exists so the screen is modal (#4).

func _init() -> void:
	print("=== NewGameScreen Test ===")
	var passed := 0
	var failed := 0

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
		"Panel/VBox/HBoxMap/OptMap",
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

	var map_opt: OptionButton = screen.get_node_or_null("Panel/VBox/HBoxMap/OptMap")
	var run_opt: OptionButton = screen.get_node_or_null("Panel/VBox/HBoxRun/OptRun")
	if run_opt != null and run_opt.item_count == 2 \
			and run_opt.get_item_text(1) == "The Proving Grounds":
		print("OK  run selector exposes the campaign beside the developer map path"); passed += 1
	else:
		print("FAIL run selector missing the campaign choice"); failed += 1

	if run_opt != null:
		run_opt.selected = 1
		run_opt.item_selected.emit(1)
		var campaign_owns_map := map_opt.disabled
		run_opt.selected = 0
		run_opt.item_selected.emit(0)
		if campaign_owns_map and not map_opt.disabled:
			print("OK  campaign selection disables only its inapplicable map picker"); passed += 1
		else:
			print("FAIL run selection did not toggle the developer map picker"); failed += 1
	if map_opt != null and map_opt.item_count >= 8:
		print("OK  map selector is populated from the registry source"); passed += 1
	else:
		print("FAIL map selector missing or empty"); failed += 1

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

	# ---- map selection keeps last-launched semantics until Start ----
	# Unlike the rule toggles above, the Map dropdown is a launch choice. Closing
	# without Start must not rewrite GameState.next_map_data_path; reopening seeds
	# from the last configured/launched map path.
	if gs_node != null and map_opt != null and map_opt.item_count > 1:
		var original_path: String = screen._map_options[0]["map_data_path"]
		gs_node.set("next_map_data_path", original_path)
		screen.open()
		map_opt.selected = 1
		screen._on_back()
		screen.open()
		var map_kept_last_launch: bool = map_opt.selected == 0 \
			and String(gs_node.get("next_map_data_path")) == original_path
		screen._on_back()
		if map_kept_last_launch:
			print("OK  map dropdown reopens on last launched map, not unsaved selection")
			passed += 1
		else:
			print("FAIL map last-launched behavior: selected=%d path=%s want=%s" % [
				map_opt.selected, String(gs_node.get("next_map_data_path")), original_path])
			failed += 1
	else:
		print("SKIP map last-launched behavior (GameState/map options unavailable)")

	# ---- modal focus containment and repeat in the live MainMenu parent ----
	if gs_node != null:
		var menu_packed := load("res://scenes/ui/MainMenu.tscn")
		var menu: Control = menu_packed.instantiate()
		root.add_child(menu)
		await process_frame
		var modal: Control = menu.get_node("NewGameScreen")
		var background_continue: Button = menu.get_node("Panel/VBox/ContinueButton")
		var modal_map: OptionButton = modal.get_node("Panel/VBox/HBoxMap/OptMap")
		var modal_permadeath: OptionButton = modal.get_node("Panel/VBox/HBoxPermadeath/OptPermadeath")
		menu._on_new_game()
		await process_frame
		background_continue.grab_focus()
		modal._process(0.016)
		var focus_owner := modal.get_viewport().gui_get_focus_owner()
		var contained_focus := modal.is_ancestor_of(focus_owner)
		modal_map.grab_focus()
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
		modal_map.show_popup()
		await process_frame
		var popup_seen: bool = modal._capture_ui_active()
		Input.action_press("ui_down", 1.0)
		modal._process(0.016)
		modal._process(0.016)
		focus_owner = modal.get_viewport().gui_get_focus_owner()
		var popup_stood_down := focus_owner == modal_permadeath
		modal_map.get_popup().hide()
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
