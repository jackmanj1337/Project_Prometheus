extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_display_confirm_flow.gd
# End-to-end test of the confirm-or-revert flow for reachability-risk changes [UUI-18]:
# a resolution change applies immediately but only persists on Keep; Revert (or the 15s
# timeout) restores the previous value and resets the dropdown. Viewport Scale and Menu
# Scale go through the same dialog. Drives the real SettingsScreen handlers so the
# wiring is covered, not just the dialog in isolation.

const SettingsScene = preload("res://scenes/ui/SettingsScreen.tscn")
const SettingsManagerS = preload("res://scripts/autoloads/SettingsManager.gd")

var _passed := 0
var _failed := 0


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
		_passed += 1
	else:
		print("FAIL ", msg)
		_failed += 1


# The dialog the flow added that has not answered yet. An answered dialog is only
# queued for deletion, so it is still a child until the frame ends; matching it would
# drive a dead dialog.
func _find_live_dialog(screen: Node) -> Node:
	for child in screen.get_children():
		if child is CanvasLayer and child.has_signal("reverted") and not child._answered:
			return child
	return null


func _count_live_dialogs(screen: Node) -> int:
	var n := 0
	for child in screen.get_children():
		if child is CanvasLayer and child.has_signal("reverted") and not child._answered:
			n += 1
	return n


func _drain(dlg: Node) -> void:
	for _i in 15:
		dlg._tick()


func _resolution_row(screen: Node) -> Dictionary:
	for row in screen._ENUM_SETTINGS:
		if row["key"] == "resolution":
			return row
	return {}


func _init() -> void:
	print("=== Display Confirm Flow Test ===")
	# Autoloads aren't present in a --script SceneTree run, so stand one up under
	# /root with the autoload name the screen looks up (`/root/SettingsManager`).
	var sm: Node = SettingsManagerS.new()
	sm.name = "SettingsManager"
	root.add_child(sm)

	var screen: Control = SettingsScene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.open()  # populates dropdowns from SettingsManager

	# Baseline: a known windowed resolution (index 0).
	sm.window_mode = "windowed"
	sm.resolution = "1280x720"
	var row: Dictionary = _resolution_row(screen)
	_ok(
		not row.is_empty() and row.get("reachability_risk", false),
		"resolution row exists and carries reachability risk"
	)

	# ---- [UUI-18]: the risk flag and the display-config hiding flag are separate ----
	var risk_keys: Array = []
	var display_keys: Array = []
	for r in screen._ENUM_SETTINGS:
		if r.get("reachability_risk", false):
			risk_keys.append(r["key"])
		if r.get("display_config", false):
			display_keys.append(r["key"])
		_ok(not r.has("confirm"), "row %s no longer uses the retired confirm flag" % r["key"])
		if String(r["key"]) in screen.REACHABILITY_RISK_KEYS:
			_ok(
				r.get("reachability_risk", false),
				"enum row %s is in the UUI-18 table and carries the flag" % r["key"]
			)
	risk_keys.sort()
	display_keys.sort()
	_ok(
		risk_keys == ["resolution", "window_mode"],
		"the risky enum rows are exactly window mode + resolution"
	)
	_ok(display_keys == ["resolution", "window_mode"], "display-config hiding is its own flag")
	for k in ["content_scale_factor", "menu_scale_index"]:
		_ok(k in screen.REACHABILITY_RISK_KEYS, "%s is in the UUI-18 table" % k)

	# ---- change applies immediately and opens the dialog ----
	screen._on_enum_setting_changed(2, row)  # index 2 -> "1920x1080"
	_ok(sm.resolution == "1920x1080", "the new resolution is applied immediately")
	var dlg: Node = _find_live_dialog(screen)
	_ok(dlg != null, "a confirm dialog is shown after the change")

	# ---- Revert restores the previous value + resets the dropdown ----
	dlg._on_revert()
	_ok(sm.resolution == "1280x720", "Revert restores the previous resolution")
	var opt: OptionButton = screen._vbox.get_node(row["node"])
	_ok(opt.selected == 0, "Revert resets the dropdown to the previous option")

	# ---- timeout (auto-revert) behaves like Revert ----
	screen._on_enum_setting_changed(1, row)  # -> "1600x900"
	_ok(sm.resolution == "1600x900", "second change applies")
	var dlg2: Node = _find_live_dialog(screen)
	for _i in 15:  # the default 15s countdown elapsing
		dlg2._tick()
	_ok(sm.resolution == "1280x720", "the 15s timeout auto-reverts to the previous value")

	# ---- Keep persists the new value (no revert) ----
	screen._on_enum_setting_changed(2, row)  # -> "1920x1080"
	var dlg3: Node = _find_live_dialog(screen)
	dlg3._on_keep()
	_ok(sm.resolution == "1920x1080", "Keep retains the new resolution")

	# ---- Viewport Scale: applied live, reverted by the dialog ----
	sm.content_scale_factor = 1.0
	screen._slider_viewport_scale.set_value_no_signal(1.0)
	screen._commit_viewport_scale(2.0, true)
	_ok(is_equal_approx(sm.content_scale_factor, 2.0), "a Viewport Scale change applies live")
	var dlg_vs: Node = _find_live_dialog(screen)
	_ok(dlg_vs != null, "a Viewport Scale change opens the confirm dialog")
	_ok(
		not screen._modal_focus_repeat_enabled(), "screen focus repeat stands down under the dialog"
	)
	_drain(dlg_vs)
	_ok(
		is_equal_approx(sm.content_scale_factor, 1.0),
		"the countdown restores the previous Viewport Scale"
	)
	_ok(
		is_equal_approx(screen._slider_viewport_scale.value, 1.0),
		"the Viewport Scale slider follows the revert"
	)
	_ok(screen._modal_focus_repeat_enabled(), "screen focus repeat resumes once the dialog answers")

	# ---- a commit that lands on the current value opens nothing ----
	screen._commit_viewport_scale(1.0, true)
	await process_frame
	_ok(
		_find_live_dialog(screen) == null, "re-applying the current Viewport Scale needs no confirm"
	)

	# ---- a live preview mid-drag never opens the dialog ----
	screen._commit_viewport_scale(3.0, false)
	_ok(_find_live_dialog(screen) == null, "a mid-drag preview opens no dialog")
	_ok(is_equal_approx(sm.content_scale_factor, 1.0), "a mid-drag preview applies nothing")

	# ---- Menu Scale: Keep persists, Escape reverts ----
	sm.menu_scale_index = 1
	screen._commit_menu_scale(2.0, true)
	_ok(sm.menu_scale_index == 2, "a Menu Scale change applies live")
	var dlg_ms: Node = _find_live_dialog(screen)
	_ok(dlg_ms != null, "a Menu Scale change opens the confirm dialog")
	dlg_ms._on_keep()
	_ok(sm.menu_scale_index == 2, "Keep retains the new Menu Scale")
	await process_frame

	screen._commit_menu_scale(0.0, true)
	var dlg_esc: Node = _find_live_dialog(screen)
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	dlg_esc._input(esc)
	_ok(sm.menu_scale_index == 2, "Escape in the dialog reverts the Menu Scale")
	_ok(screen.visible, "Escape answers the dialog, not the Settings screen behind it")
	_ok(int(screen._slider_menu_scale.value) == 2, "the Menu Scale slider follows the revert")
	await process_frame

	# ---- a second change while the dialog is open joins it and reverts with it ----
	sm.content_scale_factor = 1.0
	screen._commit_menu_scale(0.0, true)
	var dlg_two: Node = _find_live_dialog(screen)
	screen._commit_viewport_scale(2.0, true)
	_ok(_count_live_dialogs(screen) == 1, "a second risky change does not stack a second dialog")
	dlg_two._on_revert()
	_ok(
		sm.menu_scale_index == 2 and is_equal_approx(sm.content_scale_factor, 1.0),
		"one Revert restores both changes the dialog answered for"
	)
	await process_frame

	# Restore a sane default for any later suite sharing this process.
	sm.resolution = "1280x720"
	sm.menu_scale_index = 1
	screen.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
