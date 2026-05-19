extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_settings_screen.gd
# Verifies SettingsScreen.tscn instantiates, the nodes its script's @onready vars
# expect resolve, the opaque Dimmer exists (#1), and the read-only keybinding
# list is populated from the InputMap (#8).

func _init() -> void:
	print("=== SettingsScreen Test ===")
	var passed := 0
	var failed := 0

	var packed := load("res://scenes/ui/SettingsScreen.tscn")
	if packed == null:
		print("FAIL could not load SettingsScreen.tscn"); quit(1); return
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame

	# Dimmer makes the screen modal/opaque (#1).
	if screen.get_node_or_null("Dimmer") != null:
		print("OK  Dimmer node present (#1 opacity)"); passed += 1
	else:
		print("FAIL no Dimmer node"); failed += 1

	# Every node the SettingsScreen script's @onready vars depend on must exist.
	var expected := [
		"Panel/ScrollContainer/VBox/HBoxMaster/SliderMaster",
		"Panel/ScrollContainer/VBox/HBoxMaster/LabelMaster",
		"Panel/ScrollContainer/VBox/OptCombatAnim",
		"Panel/ScrollContainer/VBox/HBoxMovementSpeed/OptMovementSpeed",
		"Panel/ScrollContainer/VBox/HBoxPhaseBanner/OptPhaseBanner",
		"Panel/ScrollContainer/VBox/HBoxLevelUp/OptLevelUpScreen",
		"Panel/ScrollContainer/VBox/HBoxMouseTargeting/OptMouseTargeting",
		"Panel/ScrollContainer/VBox/HBoxAutoEndTurn/OptAutoEndTurn",
		"Panel/ScrollContainer/VBox/HBoxCameraBuffer/SliderCameraBuffer",
		"Panel/ScrollContainer/VBox/HBoxCameraBuffer/LabelCameraBuffer",
		"Panel/ScrollContainer/VBox/KeybindList",
		"Panel/ScrollContainer/VBox/BtnBack",
	]
	var all_present := true
	for path in expected:
		if screen.get_node_or_null(path) == null:
			all_present = false
			print("FAIL missing node: " + path)
			failed += 1
	if all_present:
		print("OK  all @onready-referenced nodes resolve"); passed += 1

	# Keybinding list is populated from the InputMap (#8).
	var list := screen.get_node_or_null("Panel/ScrollContainer/VBox/KeybindList")
	if list != null and list.get_child_count() > 0:
		print("OK  keybinding list populated (%d rows)" % list.get_child_count())
		passed += 1
	else:
		print("FAIL keybinding list empty or missing"); failed += 1

	# open() / _on_back() drive visibility. open() needs the SettingsManager
	# autoload to read values from — skip the check cleanly when it is absent.
	if root.get_node_or_null("SettingsManager") != null:
		screen.open()
		var shown := screen.visible
		screen._on_back()
		if shown and not screen.visible:
			print("OK  open() shows the screen, _on_back() hides it"); passed += 1
		else:
			print("FAIL visibility: shown=%s after_back=%s" % [shown, screen.visible])
			failed += 1
	else:
		print("SKIP open()/back visibility (SettingsManager autoload absent)")

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
