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
		"Panel/VBox/HBoxPermadeath/OptPermadeath",
		"Panel/VBox/HBoxLeveling/OptLeveling",
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

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
