extends SceneTree
# Run with:
#   godot --headless --path . --script res://scripts/tests/test_shell_disabled_focus.gd
#
# [EPUX-07] (owner ruling 2026-07-26, restated as [RPD-15] on 2026-08-13 and promoted to
# all five availability surfaces): a DISABLED entry REMAINS IN THE FOCUS ORDER so its
# unmet reason is reachable by keyboard and controller rather than by pointer hover only;
# activating it does nothing. Both rulings put this at the SHELL, precisely so the
# availability adapters cannot drift into different disabled treatments — so it is tested
# here once, against the two traversal implementations the shell actually has, rather than
# per screen.
#
# The shipped code implemented the ruling BACKWARDS: ModalScreen._is_focus_disabled and
# FocusNavigator._collect each EXCLUDED disabled buttons from traversal, which made every
# disabled entry unreachable by keyboard and controller.
#
# Two distinct questions, and conflating them is what made the original filter look
# reasonable:
#   * TRAVERSAL order — includes disabled entries (the ruling).
#   * ENTRY focus — prefers an available entry, because landing the player's first focus
#     on an inert control is a bad entry point, and MainMenu/MapMenu already hand-encode
#     that preference. A fully-gated surface still takes focus, or its reasons are
#     unreachable again.
#
# The last check pins an ENGINE fact this fix rests on, measured on Godot 4.6.3: a
# disabled BaseButton accepts focus but emits no `pressed`. That is what makes
# "focusable but not activatable" free rather than needing a bespoke inert treatment. If a
# future Godot changes it, this suite is where that is meant to surface.

const ModalScreenS = preload("res://scripts/ui/ModalScreen.gd")
const FocusNavigatorS = preload("res://scripts/shared/FocusNavigator.gd")

var _passed := 0
var _failed := 0


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
		_passed += 1
	else:
		print("FAIL ", msg)
		_failed += 1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Shell Disabled-Entry Focus Test ===")
	await _check_modal_traversal_includes_disabled()
	await _check_modal_entry_focus_prefers_available()
	await _check_modal_entry_focus_falls_back_when_all_gated()
	await _check_navigator_traversal_includes_disabled()
	await _check_navigator_entry_focus_prefers_available()
	await _check_disabled_button_is_focusable_but_inert()
	print("Results: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


# Builds a modal shaped like the real ones: a Panel host (what _menu_scale_target
# returns) holding a VBox of entries, the middle one gated.
func _make_modal(gated: PackedInt32Array, count: int = 3) -> Control:
	var screen: Control = ModalScreenS.new()
	var panel := Panel.new()
	panel.name = "Panel"
	screen.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	for i in range(count):
		var button := Button.new()
		button.name = "Entry%d" % i
		button.text = "Entry %d" % i
		button.focus_mode = Control.FOCUS_ALL
		button.disabled = i in gated
		box.add_child(button)
	root.add_child(screen)
	screen.show()
	return screen


# Node.name is a StringName; comparing an Array of those to an Array of String literals
# is false even when every element matches, so the cast is the assertion working at all.
func _names(controls: Array) -> Array:
	var out: Array = []
	for c in controls:
		out.append(String((c as Control).name))
	return out


func _check_modal_traversal_includes_disabled() -> void:
	var screen := _make_modal(PackedInt32Array([1]))
	await process_frame
	var order: Array = screen._focusable_controls(screen.get_node("Panel"))
	_ok(
		_names(order) == ["Entry0", "Entry1", "Entry2"],
		"ModalScreen traversal keeps the gated entry in order (got %s)" % [_names(order)]
	)
	# Stepping through must actually land on it — the order array alone would be
	# satisfied by a step that skipped the entry it contains.
	order[0].grab_focus()
	await process_frame
	screen._move_modal_focus(1)
	await process_frame
	_ok(
		screen.get_viewport().gui_get_focus_owner() == order[1],
		"a focus step LANDS on the gated entry so its reason is reachable"
	)
	screen.queue_free()
	await process_frame


func _check_modal_entry_focus_prefers_available() -> void:
	# First entry gated: entry focus must skip past it rather than open on a dead control.
	var screen := _make_modal(PackedInt32Array([0]))
	await process_frame
	var entry: Control = screen._focus_default()
	_ok(
		entry != null and entry.name == "Entry1",
		"ModalScreen entry focus skips a leading gated entry (got %s)" % [entry]
	)
	screen.queue_free()
	await process_frame


func _check_modal_entry_focus_falls_back_when_all_gated() -> void:
	# Every entry gated. Refusing to focus anything would put the reasons out of reach
	# again, which is the failure the ruling exists to prevent.
	var screen := _make_modal(PackedInt32Array([0, 1, 2]))
	await process_frame
	var entry: Control = screen._focus_default()
	_ok(
		entry != null and entry.name == "Entry0",
		"a fully gated modal still takes focus (got %s)" % [entry]
	)
	screen.queue_free()
	await process_frame


# PrepScreen — the [EPUX] availability surface the ruling was written for — navigates
# through FocusNavigator, not ModalScreen, so the shell rule has to hold in both.
func _make_navigator_host(gated: PackedInt32Array, count: int = 3) -> Control:
	var host := Control.new()
	host.size = Vector2(400, 300)
	var box := VBoxContainer.new()
	host.add_child(box)
	for i in range(count):
		var button := Button.new()
		button.name = "Row%d" % i
		button.text = "Row %d" % i
		button.focus_mode = Control.FOCUS_ALL
		button.disabled = i in gated
		box.add_child(button)
	root.add_child(host)
	return host


func _check_navigator_traversal_includes_disabled() -> void:
	var host := _make_navigator_host(PackedInt32Array([1]))
	await process_frame
	var nav: RefCounted = FocusNavigatorS.new(host)
	var order: Array = nav.focusable_controls()
	_ok(
		_names(order) == ["Row0", "Row1", "Row2"],
		"FocusNavigator traversal keeps the gated row in order (got %s)" % [_names(order)]
	)
	order[0].grab_focus()
	await process_frame
	nav.move_focus(1)
	await process_frame
	_ok(
		host.get_viewport().gui_get_focus_owner() == order[1],
		"a FocusNavigator step LANDS on the gated row"
	)
	host.queue_free()
	await process_frame


func _check_navigator_entry_focus_prefers_available() -> void:
	var host := _make_navigator_host(PackedInt32Array([0]))
	await process_frame
	var nav: RefCounted = FocusNavigatorS.new(host)
	nav.grab_default()
	await process_frame
	var owner_control := host.get_viewport().gui_get_focus_owner()
	_ok(
		owner_control != null and owner_control.name == "Row1",
		"FocusNavigator default focus skips a leading gated row (got %s)" % [owner_control]
	)
	host.queue_free()
	await process_frame


# The engine fact the whole fix rests on. Without it, including disabled entries in
# traversal would hand the player a control that swallows confirm with no feedback, and
# the shell would owe a bespoke inert treatment instead.
func _check_disabled_button_is_focusable_but_inert() -> void:
	var host := Control.new()
	root.add_child(host)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_ALL
	button.disabled = true
	var hits := {"n": 0}
	button.pressed.connect(func() -> void: hits["n"] += 1)
	host.add_child(button)
	await process_frame
	button.grab_focus()
	await process_frame
	_ok(button.has_focus(), "a disabled BaseButton accepts focus (Godot 4.6.3 native)")
	# Godot's own traversal agrees, so the shell is not fighting the engine here.
	_ok(
		button.find_next_valid_focus() != null,
		"engine focus traversal does not treat a disabled button as a dead end"
	)
	var press := InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = "ui_accept"
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	await process_frame
	_ok(hits["n"] == 0, "confirming a focused disabled entry does nothing (not activatable)")
	host.queue_free()
	await process_frame
