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
		"Panel/ScrollContainer/Margin/VBox/HBoxMaster/SliderMaster",
		"Panel/ScrollContainer/Margin/VBox/HBoxMaster/LabelMaster",
		"Panel/ScrollContainer/Margin/VBox/OptCombatAnim",
		"Panel/ScrollContainer/Margin/VBox/HBoxMovementSpeed/OptMovementSpeed",
		"Panel/ScrollContainer/Margin/VBox/HBoxPhaseBanner/OptPhaseBanner",
		"Panel/ScrollContainer/Margin/VBox/HBoxLevelUp/OptLevelUpScreen",
		"Panel/ScrollContainer/Margin/VBox/HBoxMouseCursor/OptMouseCursor",
		"Panel/ScrollContainer/Margin/VBox/HBoxAutoEndTurn/OptAutoEndTurn",
		"Panel/ScrollContainer/Margin/VBox/HBoxCameraBuffer/SliderCameraBuffer",
		"Panel/ScrollContainer/Margin/VBox/HBoxCameraBuffer/LabelCameraBuffer",
		"Panel/ScrollContainer/Margin/VBox/HBoxMapZoom/SliderMapZoom",
		"Panel/ScrollContainer/Margin/VBox/HBoxMapZoom/LabelMapZoom",
		"Panel/ScrollContainer/Margin/VBox/HBoxUIScale/SliderUIScale",
		"Panel/ScrollContainer/Margin/VBox/HBoxUIScale/LabelUIScale",
		"Panel/ScrollContainer/Margin/VBox/HBoxResolution/LabelResolutionApplied",
		"Panel/ScrollContainer/Margin/VBox/KeybindList",
		"Panel/ScrollContainer/Margin/VBox/BtnBack",
	]
	var all_present := true
	for path in expected:
		if screen.get_node_or_null(path) == null:
			all_present = false
			print("FAIL missing node: " + path)
			failed += 1
	if all_present:
		print("OK  all @onready-referenced nodes resolve"); passed += 1

	var menu_scale_title := screen.get_node_or_null("Panel/ScrollContainer/Margin/VBox/HBoxUIScale/LabelUIScaleTitle")
	if menu_scale_title != null and String(menu_scale_title.get("text")) == "Menu Scale":
		print("OK  display scale row is labeled Menu Scale"); passed += 1
	else:
		print("FAIL Menu Scale label missing or stale"); failed += 1

	# V023-01: scaling must not move the slider's control column WITHIN the panel
	# (stable row columns). Measured panel-relative since V026-01a: the panel itself
	# now legitimately grows + recenters with the factor, and mid-drag track shift is
	# impossible anyway because the scale only applies on drag release (V025-01a).
	screen.show()
	var scale_slider: Control = screen.get_node_or_null("Panel/ScrollContainer/Margin/VBox/HBoxUIScale/SliderUIScale")
	var panel_for_slider: Control = screen.get_node_or_null("Panel")
	var slider_offsets: Array[float] = []
	if scale_slider != null and panel_for_slider != null:
		for factor in [0.5, 1.0, 2.0]:
			screen.apply_menu_scale(float(factor))
			await process_frame
			slider_offsets.append(scale_slider.get_global_rect().position.x
				- panel_for_slider.get_global_rect().position.x)
	var slider_stable := slider_offsets.size() == 3 \
		and absf(slider_offsets[0] - slider_offsets[1]) <= 1.0 \
		and absf(slider_offsets[1] - slider_offsets[2]) <= 1.0
	if slider_stable:
		print("OK  Menu Scale slider column stays stable within the panel during scaling")
		passed += 1
	else:
		print("FAIL Menu Scale slider drift within panel: %s" % str(slider_offsets))
		failed += 1

	# V023-01 follow-up (v0.2.5): the slider must also hold its VERTICAL position —
	# rows above it change height with the scale factor, so apply_menu_scale anchors
	# the row by compensating with the ScrollContainer's scroll_vertical one frame
	# later. Extra process_frame awaits let the deferred layout + anchor pass settle.
	var scale_row: Control = screen.get_node_or_null("Panel/ScrollContainer/Margin/VBox/HBoxUIScale")
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
	var list := screen.get_node_or_null("Panel/ScrollContainer/Margin/VBox/KeybindList")
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
		# V026-01c: the F9 hotseat override must be listed with the other debug rows.
		var has_hotseat_row := false
		for row in list.get_children():
			if row.get_child_count() > 0 \
					and String(row.get_child(0).get("text")) == "Debug: Hotseat All Factions":
				has_hotseat_row = true
		if has_hotseat_row:
			print("OK  V026-01c hotseat debug keybinding row present"); passed += 1
		else:
			print("FAIL V026-01c hotseat debug keybinding row missing"); failed += 1

	# V026-01b: a MarginContainer keeps the rows clear of the vertical scrollbar.
	var margin := screen.get_node_or_null("Panel/ScrollContainer/Margin") as MarginContainer
	if margin != null and margin.get_theme_constant("margin_right") > 0:
		print("OK  V026-01b right margin present between rows and scrollbar"); passed += 1
	else:
		print("FAIL V026-01b scrollbar right margin missing"); failed += 1

	# V026-01a: the FIRST scale apply on a fresh instance must leave the panel
	# horizontally centered — previously the recenter ran against the authored frame
	# size and the deferred layout then grew the panel rightward (off-center until a
	# later re-apply "settled" it). Checked on a fresh instance because re-applies
	# masked the bug.
	var fresh: Control = packed.instantiate()
	root.add_child(fresh)
	await process_frame
	var centered_ok := true
	for factor in [2.0, 0.5]:
		fresh.apply_menu_scale(float(factor))
		for i in 2:
			await process_frame
		var panel := fresh.get_node_or_null("Panel") as Control
		var vp_w: float = fresh.get_viewport_rect().size.x
		var center_off: float = absf(
			panel.global_position.x + panel.size.x * 0.5 - vp_w * 0.5)
		var min_w: float = panel.get_combined_minimum_size().x
		if center_off > 2.0:
			centered_ok = false
			print("FAIL V026-01a panel off-center at %sx: offset=%.1f" % [factor, center_off])
		if panel.size.x + 0.5 < minf(min_w, vp_w):
			centered_ok = false
			print("FAIL V026-01a panel narrower than content at %sx: %.1f < %.1f" \
				% [factor, panel.size.x, min_w])
	if centered_ok:
		print("OK  V026-01a first-apply keeps the settings panel centered at 2.0x/0.5x")
		passed += 1
	else:
		failed += 1
	fresh.queue_free()

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

	# ---- V027-04b: Resolution dropdown renders a write-back as "Custom (WxH)" ----
	# A non-preset saved resolution (OS drag write-back, Q5) must show as a
	# trailing display-only Custom item — the old find() silently selected the
	# first preset. A live resolution_written_back re-syncs while the screen is
	# open, and returning to a preset drops the Custom item again.
	var sm_res := root.get_node_or_null("SettingsManager")
	if sm_res != null:
		var opt_res: OptionButton = screen.get_node_or_null(
			"Panel/ScrollContainer/Margin/VBox/HBoxResolution/OptResolution")
		var preset_count: int = 0
		for s in screen._ENUM_SETTINGS:
			if String(s["key"]) == "resolution":
				preset_count = (s["values"] as Array).size()
		var prev_res: String = String(sm_res.get("resolution"))
		var prev_mode: String = String(sm_res.get("window_mode"))
		sm_res.set("window_mode", "windowed")
		sm_res.set("resolution", "1800x1013")
		screen.open()
		var custom_ok: bool = opt_res.item_count == preset_count + 1 \
			and opt_res.selected == preset_count \
			and opt_res.get_item_text(preset_count) == "Custom (1800x1013)"
		# A write-back landing while the screen is open re-syncs the dropdown.
		sm_res.set("resolution", "1920x1080")
		sm_res.emit_signal("resolution_written_back")
		var resync_ok: bool = opt_res.item_count == preset_count and opt_res.selected == 2
		# Re-opening on a preset keeps the plain preset list.
		sm_res.set("resolution", "1280x720")
		screen.open()
		var preset_ok: bool = opt_res.item_count == preset_count and opt_res.selected == 0
		sm_res.set("resolution", prev_res)
		sm_res.set("window_mode", prev_mode)
		screen._on_back()
		if custom_ok and resync_ok and preset_ok:
			print("OK  V027-04b Resolution dropdown: Custom item for write-backs, live re-sync")
			passed += 1
		else:
			print("FAIL V027-04b dropdown: custom=%s resync=%s preset=%s items=%d sel=%d" % [
				custom_ok, resync_ok, preset_ok, opt_res.item_count, opt_res.selected])
			failed += 1
	else:
		print("SKIP V027-04b dropdown (SettingsManager autoload absent)")

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
