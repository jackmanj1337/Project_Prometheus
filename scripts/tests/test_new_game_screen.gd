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
		"Panel/VBox/HBoxMap/OptMap",
		"Panel/VBox/HBoxPermadeath/OptPermadeath",
		"Panel/VBox/HBoxAutoPromote/OptAutoPromote",
		"Panel/VBox/HBoxLeveling/OptLeveling",
		"Panel/VBox/HBoxPairUp/OptPairUp",
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

	# open() / _on_back() drive visibility. open() reads GameState — skip the
	# check cleanly when that autoload is absent.
	if root.get_node_or_null("GameState") != null:
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
	var gs_node := root.get_node_or_null("GameState")
	if gs_node != null:
		var want_pair := not bool(gs_node.get("pair_up_enabled"))
		var want_auto := not bool(gs_node.get("auto_promote_at_max_level"))
		pair_opt.selected = 1 if want_pair else 0
		pair_opt.item_selected.emit(pair_opt.selected)   # as a click would
		auto_opt.selected = 1 if want_auto else 0
		auto_opt.item_selected.emit(auto_opt.selected)
		# Note: no _on_start() — this is the "closed without starting" path.
		var persisted_ok: bool = bool(gs_node.get("pair_up_enabled")) == want_pair \
			and bool(gs_node.get("auto_promote_at_max_level")) == want_auto
		if persisted_ok:
			print("OK  rule toggles persist to GameState on change (no Start needed)"); passed += 1
		else:
			print("FAIL rule persistence: pair=%s want=%s | auto=%s want=%s" % [
				gs_node.get("pair_up_enabled"), want_pair,
				gs_node.get("auto_promote_at_max_level"), want_auto])
			failed += 1
	else:
		print("SKIP rule persistence (GameState autoload absent)")

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
