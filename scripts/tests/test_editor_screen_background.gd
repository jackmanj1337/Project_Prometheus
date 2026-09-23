extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_screen_background.gd
#
# The editor is hosted by MainMenu, which keeps its own menu tree alive while the
# editor mode is visible. This scene contract prevents that hidden host from
# painting through the editor and from receiving pointer input underneath it.

const ScreenScene = preload("res://scenes/ui/CampaignEditorScreen.tscn")
const DIMMER_COLOR := Color(0.04, 0.04, 0.07, 0.97)
const BACKGROUND_COLOR := Color(0.12, 0.12, 0.16, 1.0)

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Campaign Editor Screen Background Test ===")
	var screen: Control = ScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	_the_dimmer_is_the_first_full_rect_layer(screen)
	_the_opaque_background_is_behind_the_shell(screen)
	_the_shell_is_painted_above_the_dimmer(screen)
	_the_dimmer_blocks_input_bleed_through(screen)

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  -- %s" % detail) if detail != "" else ""])


func _the_dimmer_is_the_first_full_rect_layer(screen: Control) -> void:
	print("\n-- the editor owns an established full-screen dimmer --")
	var dimmer := screen.get_node_or_null("Dimmer") as ColorRect
	_check("the editor has a dimmer node", dimmer != null)
	if dimmer == null:
		return
	_check("the dimmer is the first child behind the shell", screen.get_child(0) == dimmer)
	_check("the dimmer uses the shared overlay token", dimmer.color.is_equal_approx(DIMMER_COLOR))
	_check("the dimmer covers the full editor width", is_equal_approx(dimmer.anchor_right, 1.0))
	_check("the dimmer covers the full editor height", is_equal_approx(dimmer.anchor_bottom, 1.0))


func _the_shell_is_painted_above_the_dimmer(screen: Control) -> void:
	print("\n-- editor chrome remains above the backdrop --")
	var shell := screen.get_node_or_null("Shell") as Control
	var minimum_size_state := screen.get_node_or_null("MinimumSizeState") as Control
	_check(
		"the shell is present above the dimmer",
		shell != null and screen.get_children().find(shell) > 0
	)
	_check(
		"the minimum-size state is present above the dimmer",
		minimum_size_state != null and screen.get_children().find(minimum_size_state) > 0
	)


func _the_opaque_background_is_behind_the_shell(screen: Control) -> void:
	print("\n-- the established opaque panel hides the host menu completely --")
	var background := screen.get_node_or_null("Background") as Panel
	var shell := screen.get_node_or_null("Shell") as Control
	_check("the editor has an opaque background panel", background != null)
	if background == null:
		return
	_check(
		"the background panel uses the shared opaque surface token",
		background.get_theme_stylebox("panel").bg_color.is_equal_approx(BACKGROUND_COLOR)
	)
	_check(
		"the background panel covers the full editor width",
		is_equal_approx(background.anchor_right, 1.0)
	)
	_check(
		"the background panel covers the full editor height",
		is_equal_approx(background.anchor_bottom, 1.0)
	)
	_check(
		"the shell is painted above the opaque background",
		shell != null and screen.get_children().find(shell) > screen.get_children().find(background)
	)


func _the_dimmer_blocks_input_bleed_through(screen: Control) -> void:
	print("\n-- the backdrop owns pointer input while the editor is open --")
	var dimmer := screen.get_node_or_null("Dimmer") as ColorRect
	var background := screen.get_node_or_null("Background") as Panel
	_check(
		"the dimmer stops input from reaching the live main menu",
		dimmer != null and dimmer.mouse_filter == Control.MOUSE_FILTER_STOP,
		"mouse_filter=%s" % (str(dimmer.mouse_filter) if dimmer != null else "missing")
	)
	_check(
		"the opaque background stops input from reaching the live main menu",
		background != null and background.mouse_filter == Control.MOUSE_FILTER_STOP,
		"mouse_filter=%s" % (str(background.mouse_filter) if background != null else "missing")
	)
