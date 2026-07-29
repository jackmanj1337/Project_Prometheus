extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_display_confirm_flow.gd
# End-to-end test of the confirm-or-revert flow for risky display changes: a resolution
# change applies immediately but only persists on Keep; Revert (or the 15s timeout)
# restores the previous value and resets the dropdown. Drives the real
# SettingsScreen._on_enum_setting_changed path so the wiring is covered, not just the
# dialog in isolation.

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


# Finds the confirm dialog the flow adds as a child of the screen.
func _find_dialog(screen: Node) -> Node:
	for child in screen.get_children():
		if child is CanvasLayer and child.has_signal("reverted") and child.has_signal("kept"):
			return child
	return null


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
		not row.is_empty() and row.get("confirm", false),
		"resolution row exists and is confirm-gated"
	)

	# ---- change applies immediately and opens the dialog ----
	screen._on_enum_setting_changed(2, row)  # index 2 -> "1920x1080"
	_ok(sm.resolution == "1920x1080", "the new resolution is applied immediately")
	var dlg: Node = _find_dialog(screen)
	_ok(dlg != null, "a confirm dialog is shown after the change")

	# ---- Revert restores the previous value + resets the dropdown ----
	dlg._on_revert()
	_ok(sm.resolution == "1280x720", "Revert restores the previous resolution")
	var opt: OptionButton = screen._vbox.get_node(row["node"])
	_ok(opt.selected == 0, "Revert resets the dropdown to the previous option")

	# ---- timeout (auto-revert) behaves like Revert ----
	screen._on_enum_setting_changed(1, row)  # -> "1600x900"
	_ok(sm.resolution == "1600x900", "second change applies")
	var dlg2: Node = _find_dialog(screen)
	for _i in 15:  # the default 15s countdown elapsing
		dlg2._tick()
	_ok(sm.resolution == "1280x720", "the 15s timeout auto-reverts to the previous value")

	# ---- Keep persists the new value (no revert) ----
	screen._on_enum_setting_changed(2, row)  # -> "1920x1080"
	var dlg3: Node = _find_dialog(screen)
	dlg3._on_keep()
	_ok(sm.resolution == "1920x1080", "Keep retains the new resolution")

	# Restore a sane default for any later suite sharing this process.
	sm.resolution = "1280x720"
	screen.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
