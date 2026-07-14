extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_settings_screen.gd
# Verifies SettingsScreen.tscn instantiates, the nodes its script's @onready vars
# expect resolve, the opaque Dimmer exists (#1), and the keybinding list/capture
# flow is wired to staged SettingsManager changes.


func _row_label_text(row: Node) -> String:
	if row == null or row.get_child_count() == 0:
		return ""
	var label := row.get_child(0) as Label
	return label.text if label != null else ""


func _has_key(action: String, keycode: int) -> bool:
	if not InputMap.has_action(action):
		return false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and ev.keycode == keycode:
			return true
	return false


func _has_joy_button(action: String, button_index: int) -> bool:
	if not InputMap.has_action(action):
		return false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton and ev.button_index == button_index:
			return true
	return false


func _restore_action_events(action: String, events: Array[InputEvent]) -> void:
	InputMap.action_erase_events(action)
	for ev in events:
		InputMap.action_add_event(action, ev)

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
		"Panel/ScrollContainer/Margin/VBox/HBoxInputMode/OptInputMode",
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

	var input_prompt_label := screen.get_node_or_null(
		"Panel/ScrollContainer/Margin/VBox/HBoxInputMode/Label") as Label
	if input_prompt_label != null and input_prompt_label.text == "Input Prompts":
		print("OK  Input Mode row is relabeled Input Prompts (prompt-only semantics)")
		passed += 1
	else:
		print("FAIL input prompt label: %s" % [
			input_prompt_label.text if input_prompt_label != null else "<none>"])
		failed += 1

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
	if scroll != null and not scroll.follow_focus:
		print("OK  settings lookahead is the sole focus-scroll owner")
		passed += 1
	else:
		print("FAIL settings has competing engine and custom focus scrolling")
		failed += 1

	# V034-UI-02: traverse without wrapping and require the scrollbar to move only
	# in the direction of travel. This catches the live opposite-end oscillation.
	var monotonic_down := scroll != null
	var monotonic_up := scroll != null
	var bounded_steps := scroll != null
	var down_positions: Array[int] = []
	var up_positions: Array[int] = []
	if scroll != null:
		screen.apply_menu_scale(2.0)
		for i in 3:
			await process_frame
		var focusables: Array[Control] = screen._focusable_controls(screen._menu_scale_target())
		if focusables.size() > 1:
			focusables[0].grab_focus()
			await process_frame
			scroll.scroll_vertical = 0
			var previous_scroll := scroll.scroll_vertical
			for i in range(1, focusables.size()):
				var before := scroll.scroll_vertical
				screen._move_modal_focus(1)
				await process_frame
				await process_frame
				down_positions.append(scroll.scroll_vertical)
				if scroll.scroll_vertical < previous_scroll:
					monotonic_down = false
					break
				if scroll.scroll_vertical - before > scroll.size.y + 1:
					bounded_steps = false
				previous_scroll = scroll.scroll_vertical
			focusables[-1].grab_focus()
			await process_frame
			var bar := scroll.get_v_scroll_bar()
			scroll.scroll_vertical = roundi(maxf(0.0, bar.max_value - bar.page))
			previous_scroll = scroll.scroll_vertical
			for i in range(focusables.size() - 2, -1, -1):
				var before := scroll.scroll_vertical
				screen._move_modal_focus(-1)
				await process_frame
				await process_frame
				up_positions.append(scroll.scroll_vertical)
				if scroll.scroll_vertical > previous_scroll:
					monotonic_up = false
					break
				if before - scroll.scroll_vertical > scroll.size.y + 1:
					bounded_steps = false
				previous_scroll = scroll.scroll_vertical
		else:
			monotonic_down = false
	if monotonic_down and monotonic_up and bounded_steps:
		print("OK  Settings scroll is monotonic and bounded in both directions")
		passed += 1
	else:
		print("FAIL Settings scroll: down=%s up=%s bounded=%s" % [
			monotonic_down, monotonic_up, bounded_steps])
		print("     down=%s up=%s" % [down_positions, up_positions])
		failed += 1

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
	var derived_actions_present: bool = true
	for action in ["more_info", "peek_range", "zoom_in", "zoom_out", "zoom_reset"]:
		var info: Dictionary = screen._keybind_rows.get(action, {})
		if info.is_empty() or info.get("rebind") == null or info.get("pad_rebind") == null:
			derived_actions_present = false
	if derived_actions_present:
		print("OK  keybinding rows include all shipped gameplay InputMap actions")
		passed += 1
	else:
		print("FAIL keybinding rows missing derived gameplay actions")
		failed += 1

	# Debug-only rows: visible in debug builds, absent in release. Headless
	# tests run via the Godot binary which is a debug build, so the assertion
	# checks the debug-build path. Release verification is by inspection of the
	# OS.is_debug_build() gate in SettingsScreen._populate_keybindings.
	if list != null and OS.is_debug_build():
		var has_force_levelup_row := false
		var has_growth_boost_row := false
		for row in list.get_children():
			# Each row is HBoxContainer( name_label, key_label, optional controls );
			# read the first child's text to find debug entries by display label.
			var label_text: String = _row_label_text(row)
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
			if _row_label_text(row) == "Debug: Hotseat All Factions":
				has_hotseat_row = true
		if has_hotseat_row:
			print("OK  V026-01c hotseat debug keybinding row present"); passed += 1
		else:
			print("FAIL V026-01c hotseat debug keybinding row missing"); failed += 1

		var debug_rows_read_only: bool = screen._keybind_rows.has("debug_toggle_force_levelup") \
			and screen._keybind_rows["debug_toggle_force_levelup"]["rebind"] == null \
			and screen._keybind_rows["debug_toggle_force_levelup"]["pad_rebind"] == null \
			and screen._keybind_rows["debug_toggle_growth_boost"]["rebind"] == null \
			and screen._keybind_rows["debug_toggle_growth_boost"]["pad_rebind"] == null \
			and screen._keybind_rows["debug_toggle_hotseat_override"]["rebind"] == null \
			and screen._keybind_rows["debug_toggle_hotseat_override"]["pad_rebind"] == null
		if debug_rows_read_only:
			print("OK  debug keybinding rows stay read-only"); passed += 1
		else:
			print("FAIL debug keybinding rows exposed edit controls"); failed += 1

	# ---- B6-INPUT rebind UI slice: staged K&M capture + conflict flow ----
	var sm_bind := root.get_node_or_null("SettingsManager")
	if sm_bind != null and list != null:
		var saved_confirm: Array[InputEvent] = []
		for ev in InputMap.action_get_events("confirm"):
			saved_confirm.append(ev)
		var saved_cancel: Array[InputEvent] = []
		for ev in InputMap.action_get_events("cancel"):
			saved_cancel.append(ev)
		screen._reset_keybindings_to_defaults()
		var confirm_info: Dictionary = screen._keybind_rows["confirm"]
		var confirm_rebind: Button = confirm_info["rebind"]
		var apply_btn: Button = screen._btn_apply_keybindings
		var revert_btn: Button = screen._btn_revert_keybindings

		confirm_rebind.pressed.emit()
		var ev_f := InputEventKey.new()
		ev_f.keycode = KEY_F
		ev_f.pressed = true
		screen._input(ev_f)
		var derived_conflict: bool = screen._keybind_conflicts.has("confirm") \
			and screen._keybind_conflicts.has("more_info") \
			and apply_btn.disabled
		revert_btn.pressed.emit()
		if derived_conflict:
			print("OK  conflict scan includes derived gameplay actions")
			passed += 1
		else:
			print("FAIL derived action conflict was not detected")
			failed += 1
		confirm_info = screen._keybind_rows["confirm"]
		confirm_rebind = confirm_info["rebind"]
		apply_btn = screen._btn_apply_keybindings
		revert_btn = screen._btn_revert_keybindings

		confirm_rebind.pressed.emit()
		var capture_started: bool = screen._capturing_action == "confirm" \
			and confirm_rebind.text == "Press key..."
		# During capture the base ModalScreen up/down focus repeat must be off, so
		# holding a direction to rebind it does not scroll focus off the row.
		if not screen._modal_focus_repeat_enabled():
			print("OK  modal focus repeat suppressed while capturing a keybind")
			passed += 1
		else:
			print("FAIL modal focus repeat active during keybind capture"); failed += 1
		var ev_y := InputEventKey.new()
		ev_y.keycode = KEY_Y
		ev_y.pressed = true
		screen._input(ev_y)
		var staged_not_live: bool = screen._pending_keybindings.has("confirm") \
			and not _has_key("confirm", KEY_Y) \
			and apply_btn.disabled == false
		revert_btn.pressed.emit()
		apply_btn = screen._btn_apply_keybindings
		var reverted: bool = screen._pending_keybindings.is_empty() \
			and not _has_key("confirm", KEY_Y) \
			and apply_btn.disabled
		if capture_started and staged_not_live and reverted:
			print("OK  rebind capture stages pending key without touching live InputMap")
			passed += 1
		else:
			print("FAIL staged capture: started=%s staged=%s reverted=%s" % [
				capture_started, staged_not_live, reverted]); failed += 1

		confirm_rebind = screen._keybind_rows["confirm"]["rebind"]
		apply_btn = screen._btn_apply_keybindings
		confirm_rebind.pressed.emit()
		var ev_x := InputEventKey.new()
		ev_x.keycode = KEY_X
		ev_x.pressed = true
		screen._input(ev_x)
		var cancel_info: Dictionary = screen._keybind_rows["cancel"]
		var conflict_rows_red: bool = screen._keybind_conflicts.has("confirm") \
			and screen._keybind_conflicts.has("cancel") \
			and (screen._keybind_rows["confirm"]["row"] as HBoxContainer).modulate \
				== screen._KEYBIND_CONFLICT_COLOR \
			and (cancel_info["row"] as HBoxContainer).modulate \
				== screen._KEYBIND_CONFLICT_COLOR
		var conflict_blocks_apply: bool = apply_btn.disabled \
			and (screen._keybind_rows["confirm"]["clear"] as Button).visible \
			and (cancel_info["clear"] as Button).visible
		if conflict_rows_red and conflict_blocks_apply:
			print("OK  conflicting staged key marks both rows and disables Apply")
			passed += 1
		else:
			print("FAIL conflict state: rows=%s apply=%s" % [
				conflict_rows_red, conflict_blocks_apply]); failed += 1

		var cancel_clear: Button = cancel_info["clear"]
		cancel_clear.pressed.emit()
		var cancel_label: Label = screen._keybind_rows["cancel"]["label"]
		var clear_resolved: bool = screen._keybind_conflicts.is_empty() \
			and not apply_btn.disabled \
			and cancel_label.text.find("(unbound)") >= 0
		apply_btn.pressed.emit()
		var applied: bool = _has_key("confirm", KEY_X) \
			and not _has_key("cancel", KEY_X) \
			and screen._pending_keybindings.is_empty()
		if clear_resolved and applied:
			print("OK  Clear resolves conflict and Apply commits the pending batch")
			passed += 1
		else:
			print("FAIL clear/apply: resolved=%s applied=%s" % [
				clear_resolved, applied]); failed += 1

		confirm_rebind = screen._keybind_rows["confirm"]["rebind"]
		confirm_rebind.pressed.emit()
		var ev_escape := InputEventKey.new()
		ev_escape.keycode = KEY_ESCAPE
		ev_escape.pressed = true
		screen._input(ev_escape)
		var escape_aborted: bool = screen._capturing_action == "" \
			and screen._pending_keybindings.is_empty()
		if escape_aborted:
			print("OK  Esc aborts capture without staging a binding"); passed += 1
		else:
			print("FAIL Esc did not abort capture"); failed += 1

		var reset_btn: Button = list.get_node("KeybindActions/BtnResetKeybindings")
		reset_btn.pressed.emit()
		var reset_ok: bool = _has_key("confirm", KEY_Z) and _has_key("cancel", KEY_X)
		if reset_ok:
			print("OK  Reset Controls restores default keybindings"); passed += 1
		else:
			print("FAIL Reset Controls did not restore defaults"); failed += 1

		var confirm_pad_rebind: Button = screen._keybind_rows["confirm"]["pad_rebind"]
		confirm_pad_rebind.pressed.emit()
		var pad_capture_started: bool = screen._capturing_action == "confirm" \
			and screen._capturing_slot == "pad" \
			and confirm_pad_rebind.text == "Press pad..."
		var ev_pad_b := InputEventJoypadButton.new()
		ev_pad_b.button_index = JOY_BUTTON_B
		ev_pad_b.pressed = true
		screen._input(ev_pad_b)
		apply_btn = screen._btn_apply_keybindings
		cancel_info = screen._keybind_rows["cancel"]
		var pad_conflict: bool = screen._keybind_conflicts.has("confirm") \
			and screen._keybind_conflicts.has("cancel") \
			and apply_btn.disabled \
			and (screen._keybind_rows["confirm"]["clear"] as Button).visible \
			and (cancel_info["clear"] as Button).visible
		(cancel_info["clear"] as Button).pressed.emit()
		apply_btn = screen._btn_apply_keybindings
		apply_btn.pressed.emit()
		var pad_applied: bool = pad_capture_started \
			and pad_conflict \
			and _has_key("confirm", KEY_Z) \
			and _has_joy_button("confirm", JOY_BUTTON_B) \
			and not _has_joy_button("cancel", JOY_BUTTON_B)
		if pad_applied:
			print("OK  pad capture stages conflicts and applies only the pad slot")
			passed += 1
		else:
			print("FAIL pad capture/apply: started=%s conflict=%s applied=%s" % [
				pad_capture_started, pad_conflict, pad_applied]); failed += 1

		screen._reset_keybindings_to_defaults()
		_restore_action_events("confirm", saved_confirm)
		_restore_action_events("cancel", saved_cancel)
		sm_bind.call("_mirror_game_keys_to_ui")
	else:
		print("SKIP keybind capture tests (SettingsManager/list absent)")

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

	# ---- V027-05c (Q6): Resolution row grayed out outside Windowed ----
	# In Borderless/Fullscreen the dropdown is inert: it must be disabled (saved
	# request preserved underneath) and the readout pinned to the native display
	# size. Returning to Windowed re-enables it with the request intact.
	var sm_q6 := root.get_node_or_null("SettingsManager")
	if sm_q6 != null:
		var opt_q6: OptionButton = screen.get_node_or_null(
			"Panel/ScrollContainer/Margin/VBox/HBoxResolution/OptResolution")
		var lbl_q6: Label = screen.get_node_or_null(
			"Panel/ScrollContainer/Margin/VBox/HBoxResolution/LabelResolutionApplied")
		var prev_res_q6: String = String(sm_q6.get("resolution"))
		var prev_mode_q6: String = String(sm_q6.get("window_mode"))
		sm_q6.set("window_mode", "borderless")
		sm_q6.set("resolution", "2560x1440")
		screen.open()
		# Headless can report a zero native size, in which case the label is blank.
		var native_label_ok: bool = String(lbl_q6.text).begins_with("native ") \
			or String(lbl_q6.text) == ""
		var disabled_ok: bool = opt_q6.disabled and native_label_ok
		sm_q6.set("window_mode", "windowed")
		screen.open()
		var reenabled_ok: bool = not opt_q6.disabled \
			and String(sm_q6.get("resolution")) == "2560x1440" \
			and opt_q6.selected == 3  # the preserved 1440p request
		sm_q6.set("resolution", prev_res_q6)
		sm_q6.set("window_mode", prev_mode_q6)
		screen._on_back()
		if disabled_ok and reenabled_ok:
			print("OK  V027-05c Resolution row disabled outside Windowed, request preserved")
			passed += 1
		else:
			print("FAIL V027-05c gray-out: disabled=%s label='%s' reenabled=%s sel=%d" % [
				opt_q6.disabled, lbl_q6.text, reenabled_ok, opt_q6.selected])
			failed += 1
	else:
		print("SKIP V027-05c gray-out (SettingsManager autoload absent)")

	# V030D-DSP-01: maximize/restored resizes do not emit resolution_written_back
	# because the resolution must not be persisted. The Settings readout still has
	# to refresh from SettingsManager's settled display-size notification.
	var sm_live_size := root.get_node_or_null("SettingsManager")
	if sm_live_size != null and sm_live_size.has_signal("display_size_changed"):
		var lbl_live: Label = screen.get_node_or_null(
			"Panel/ScrollContainer/Margin/VBox/HBoxResolution/LabelResolutionApplied")
		var opt_live: OptionButton = screen.get_node_or_null(
			"Panel/ScrollContainer/Margin/VBox/HBoxResolution/OptResolution")
		var prev_live_res: String = String(sm_live_size.get("resolution"))
		var prev_live_mode: String = String(sm_live_size.get("window_mode"))
		sm_live_size.set("window_mode", "borderless")
		sm_live_size.set("resolution", "1800x1013")
		screen.open()
		var before_live_text: String = String(lbl_live.text)
		sm_live_size.set("window_mode", "windowed")
		sm_live_size.emit_signal("display_size_changed")
		await process_frame
		var display_signal_refresh_ok: bool = String(lbl_live.text) == "client 1800x1013" \
			and before_live_text != String(lbl_live.text) \
			and not opt_live.disabled
		sm_live_size.set("resolution", prev_live_res)
		sm_live_size.set("window_mode", prev_live_mode)
		screen._on_back()
		if display_signal_refresh_ok:
			print("OK  V030D-DSP-01 Settings readout refreshes on display_size_changed")
			passed += 1
		else:
			print("FAIL V030D-DSP-01 display signal refresh: before='%s' after='%s' disabled=%s" % [
				before_live_text, lbl_live.text, opt_live.disabled])
			failed += 1
	else:
		print("SKIP V030D-DSP-01 display signal refresh (SettingsManager autoload absent)")

	# V030-DSP-01/Q4: a maximized window is a transient window state, so show its
	# live client size without writing it back into the saved Resolution value.
	var max_label: String = screen._applied_size_text(true, true, Vector2i(2368, 1310),
		Vector2i.ZERO, {})
	var custom_label: String = screen._applied_size_text(true, false, Vector2i.ZERO,
		Vector2i.ZERO, {"kind": "custom", "applied": Vector2i(1800, 1013)})
	var native_label: String = screen._applied_size_text(false, false, Vector2i.ZERO,
		Vector2i(3840, 2160), {})
	if max_label == "Maximized (2368x1310)" and custom_label == "client 1800x1013" \
			and native_label == "native 3840x2160":
		print("OK  V030-DSP-01 applied-size text distinguishes Maximized/client/native")
		passed += 1
	else:
		print("FAIL V030-DSP-01 labels: max=%s custom=%s native=%s" % [
			max_label, custom_label, native_label])
		failed += 1

	# ---- B6-INPUT: input-mode gray-state selector ----
	# The Input Mode dropdown lists every mode; ones unsupported on this platform are
	# DISABLED (visible, unselectable), not hidden. Headless runs as a non-mobile
	# desktop build, so Touch must be disabled while Auto/Gamepad/Mouse&Keyboard stay
	# live. The saved value still round-trips through open().
	var imm := root.get_node_or_null("InputModeManager")
	var sm_mode := root.get_node_or_null("SettingsManager")
	if imm != null and sm_mode != null:
		var opt_mode: OptionButton = screen.get_node_or_null(
			"Panel/ScrollContainer/Margin/VBox/HBoxInputMode/OptInputMode")
		var available: Dictionary = imm.call("available_modes")
		var mode_values := ["auto", "gamepad", "touch", "mouse_keyboard"]
		var items_ok: bool = opt_mode != null and opt_mode.item_count == mode_values.size()
		var disable_ok := true
		if items_ok:
			for i in mode_values.size():
				var want_disabled: bool = not bool(available.get(mode_values[i], true))
				if opt_mode.is_item_disabled(i) != want_disabled:
					disable_ok = false
			# Touch is unavailable on a desktop/headless build → must be disabled.
			if not opt_mode.is_item_disabled(mode_values.find("touch")):
				disable_ok = false
		var prev_mode_val: String = String(sm_mode.get("input_mode"))
		sm_mode.set("input_mode", "gamepad")
		screen.open()
		var roundtrip_ok: bool = opt_mode != null \
			and opt_mode.selected == mode_values.find("gamepad")
		sm_mode.set("input_mode", prev_mode_val)
		screen._on_back()
		if items_ok and disable_ok and roundtrip_ok:
			print("OK  B6-INPUT input-mode selector grays unsupported modes, round-trips value")
			passed += 1
		else:
			print("FAIL input-mode selector: items=%s disable=%s roundtrip=%s" % [
				items_ok, disable_ok, roundtrip_ok])
			failed += 1
	else:
		print("SKIP input-mode selector (InputModeManager/SettingsManager absent)")

	# ---- B6-INPUT: focus-grab subscriber (ModalScreen base) ----
	# A live switch to gamepad while the screen is open grabs the Back button (its
	# _focus_default override); a switch to touch drops the focus highlight. A switch
	# while hidden is a no-op. mouse_keyboard is left alone (keyboard nav keeps focus).
	if root.get_node_or_null("SettingsManager") != null:
		screen.open()
		var back_btn: Button = screen.get_node_or_null(
			"Panel/ScrollContainer/Margin/VBox/BtnBack")
		screen._on_input_mode_changed("gamepad")
		var grabbed_back: bool = back_btn != null and back_btn.has_focus()
		screen._on_input_mode_changed("touch")
		var released: bool = screen.get_viewport().gui_get_focus_owner() == null
		# Hidden screens ignore the switch: re-grab, hide, then a gamepad switch must
		# not move focus back into the hidden screen.
		screen._on_input_mode_changed("gamepad")
		screen.hide()
		screen.get_viewport().gui_release_focus()
		screen._on_input_mode_changed("gamepad")
		var hidden_noop: bool = screen.get_viewport().gui_get_focus_owner() == null
		screen.show()
		screen._on_back()
		if grabbed_back and released and hidden_noop:
			print("OK  B6-INPUT focus-grab: gamepad grabs Back, touch releases, hidden no-op")
			passed += 1
		else:
			print("FAIL focus-grab: grabbed=%s released=%s hidden_noop=%s" % [
				grabbed_back, released, hidden_noop])
			failed += 1
	else:
		print("SKIP focus-grab subscriber (SettingsManager autoload absent)")

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
