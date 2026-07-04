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
		"Panel/ScrollContainer/VBox/HBoxMouseCursor/OptMouseCursor",
		"Panel/ScrollContainer/VBox/HBoxAutoEndTurn/OptAutoEndTurn",
		"Panel/ScrollContainer/VBox/HBoxCameraBuffer/SliderCameraBuffer",
		"Panel/ScrollContainer/VBox/HBoxCameraBuffer/LabelCameraBuffer",
		"Panel/ScrollContainer/VBox/HBoxMapZoom/SliderMapZoom",
		"Panel/ScrollContainer/VBox/HBoxMapZoom/LabelMapZoom",
		"Panel/ScrollContainer/VBox/HBoxUIScale/SliderUIScale",
		"Panel/ScrollContainer/VBox/HBoxUIScale/LabelUIScale",
		"Panel/ScrollContainer/VBox/HBoxResolution/LabelResolutionApplied",
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

	var menu_scale_title := screen.get_node_or_null("Panel/ScrollContainer/VBox/HBoxUIScale/LabelUIScaleTitle")
	if menu_scale_title != null and String(menu_scale_title.get("text")) == "Menu Scale":
		print("OK  display scale row is labeled Menu Scale"); passed += 1
	else:
		print("FAIL Menu Scale label missing or stale"); failed += 1

	# V023-01: live Menu Scale must not move the slider's control column under the
	# pointer. SettingsScreen applies stable row columns after every scale pass.
	screen.show()
	var scale_slider: Control = screen.get_node_or_null("Panel/ScrollContainer/VBox/HBoxUIScale/SliderUIScale")
	var slider_positions: Array[float] = []
	if scale_slider != null:
		for factor in [0.5, 1.0, 2.0]:
			screen.apply_menu_scale(float(factor))
			await process_frame
			slider_positions.append(scale_slider.get_global_rect().position.x)
	var slider_stable := slider_positions.size() == 3 \
		and absf(slider_positions[0] - slider_positions[1]) <= 1.0 \
		and absf(slider_positions[1] - slider_positions[2]) <= 1.0
	if slider_stable:
		print("OK  Menu Scale slider x-position stays stable during live scaling")
		passed += 1
	else:
		print("FAIL Menu Scale slider drift: %s" % str(slider_positions))
		failed += 1

	# V023-01 follow-up (v0.2.5): the slider must also hold its VERTICAL position —
	# rows above it change height with the scale factor, so apply_menu_scale anchors
	# the row by compensating with the ScrollContainer's scroll_vertical one frame
	# later. Extra process_frame awaits let the deferred layout + anchor pass settle.
	var scale_row: Control = screen.get_node_or_null("Panel/ScrollContainer/VBox/HBoxUIScale")
	var row_y_stable := false
	if scale_row != null:
		screen.apply_menu_scale(1.0)
		for i in 3:
			await process_frame
		var row_y_before: float = scale_row.global_position.y
		screen.apply_menu_scale(2.0)
		for i in 3:
			await process_frame
		var row_y_after: float = scale_row.global_position.y
		row_y_stable = absf(row_y_after - row_y_before) <= 2.0
		if not row_y_stable:
			print("FAIL Menu Scale row y drift: before=%s after=%s" % [row_y_before, row_y_after])
	if row_y_stable:
		print("OK  Menu Scale row y-position stays anchored during live scaling")
		passed += 1
	else:
		failed += 1

	# V025-01b: the settings ScrollContainer must not scroll horizontally — at high
	# scale the rows adapt/ellipsize within the (now wider) panel instead of summoning
	# a horizontal scrollbar.
	var scroll := screen.get_node_or_null("Panel/ScrollContainer") as ScrollContainer
	if scroll != null and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		print("OK  V025-01b settings horizontal scroll is disabled"); passed += 1
	else:
		print("FAIL settings h-scroll not disabled: mode=%s" % [
			scroll.horizontal_scroll_mode if scroll != null else "<no scroll>"]); failed += 1

	# V025-01a: while the Menu Scale slider is being DRAGGED, changing its value must
	# only preview the label — it must NOT re-apply the scale (that shifts the track
	# under the cursor and makes the value oscillate). Release commits the value.
	if root.get_node_or_null("SettingsManager") != null and scale_slider != null:
		var sm_drag := root.get_node_or_null("SettingsManager")
		sm_drag.set("menu_scale_index", 1)  # a known committed baseline
		screen._on_menu_scale_drag_started()
		screen._on_menu_scale_changed(0)  # drag moved to a different step
		var previewed_not_applied: bool = int(sm_drag.get("menu_scale_index")) == 1
		screen._on_menu_scale_drag_ended(true)  # release commits the slider's value
		var committed_on_release: bool = int(sm_drag.get("menu_scale_index")) \
			== int(scale_slider.value)
		if previewed_not_applied and committed_on_release:
			print("OK  V025-01a Menu Scale previews during drag and commits on release")
			passed += 1
		else:
			print("FAIL menu-scale drag: previewed_not_applied=%s committed=%s idx=%d slider=%d" % [
				previewed_not_applied, committed_on_release,
				int(sm_drag.get("menu_scale_index")), int(scale_slider.value)])
			failed += 1
	else:
		print("SKIP menu-scale drag test (SettingsManager autoload absent)")

	# Keybinding list is populated from the InputMap (#8).
	var list := screen.get_node_or_null("Panel/ScrollContainer/VBox/KeybindList")
	if list != null and list.get_child_count() > 0:
		print("OK  keybinding list populated (%d rows)" % list.get_child_count())
		passed += 1
	else:
		print("FAIL keybinding list empty or missing"); failed += 1

	# Debug-only rows: visible in debug builds, absent in release. Headless
	# tests run via the Godot binary which is a debug build, so the assertion
	# checks the debug-build path. Release verification is by inspection of the
	# OS.is_debug_build() gate in SettingsScreen._populate_keybindings.
	if list != null and OS.is_debug_build():
		var has_force_levelup_row := false
		var has_growth_boost_row := false
		for row in list.get_children():
			# Each row is HBoxContainer( name_label, key_label ); read the first
			# child's text to find the debug entries by their display label.
			if row.get_child_count() == 0:
				continue
			var label_text: String = String(row.get_child(0).get("text"))
			if label_text == "Debug: Force Level Up":
				has_force_levelup_row = true
			elif label_text == "Debug: Growth Boost":
				has_growth_boost_row = true
		if has_force_levelup_row and has_growth_boost_row:
			print("OK  debug-only keybinding rows present in debug build"); passed += 1
		else:
			print("FAIL debug rows missing: force_levelup=%s growth_boost=%s" \
				% [has_force_levelup_row, has_growth_boost_row])
			failed += 1

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
