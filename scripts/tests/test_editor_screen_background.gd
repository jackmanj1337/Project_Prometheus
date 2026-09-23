extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_screen_background.gd
#
# EDITOR-SCREEN-HAS-NO-BACKGROUND-2026-09-22. `MainMenu._open_modal()` keeps its own menu
# tree alive and visible while the editor is open, and the editor scene was a bare Control
# whose first child was the shell -- so the live main menu's title, frame and five buttons
# drew straight through the editor's document area. This contract pins the one backdrop
# layer that stops it, in paint and in pointer input.
#
# WHY THE COLOUR IS THE EDITOR'S OWN and not the game theme's panel, which is what
# `SettingsScreen` uses: `EW-8` (`[CEUI-S50]`) rules that the editor's chrome must come from
# a theme a pack cannot reach, because both themes render in the same window at the same
# time. Taking the game theme's `SB_panel` here would hand a pack's theme the editor's
# backdrop. The editor already owns literal chrome colours for exactly this reason -- see
# `EditorCampaignGraphView`'s node palette. The VALUE is provisional: `[CEUI-S50]` adopted
# the album's editor token column as six METRICS with no colour, so no ruling names this
# surface's colour yet.
#
# ONE LAYER, NOT TWO. A dimmer plus an opaque panel is what `SettingsScreen` does, but there
# the panel is inset and the dimmer is what the player sees around it. Here the backdrop is
# full-rect and opaque, so a dimmer beneath it could never be seen and could never receive an
# event the panel did not already stop.

const ScreenScene = preload("res://scenes/ui/CampaignEditorScreen.tscn")
const BACKGROUND_COLOR := Color(0.12, 0.12, 0.16, 1.0)

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Campaign Editor Screen Background Test ===")
	var screen: Control = ScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	_the_backdrop_is_the_first_layer(screen)
	_the_backdrop_is_opaque_and_full_rect(screen)
	_the_chrome_is_painted_above_it(screen)
	_the_backdrop_owns_pointer_input(screen)

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  -- %s" % detail) if detail != "" else ""])


func _the_backdrop_is_the_first_layer(screen: Control) -> void:
	print("\n-- the editor opens on a backdrop of its own --")
	var background := screen.get_node_or_null("Background") as Panel
	_check("the editor scene has a backdrop node", background != null)
	if background == null:
		return
	_check(
		"it is the first child, so everything else paints over it",
		screen.get_child(0) == background
	)


func _the_backdrop_is_opaque_and_full_rect(screen: Control) -> void:
	print("\n-- it hides the live host menu completely --")
	var background := screen.get_node_or_null("Background") as Panel
	if background == null:
		return
	var box := background.get_theme_stylebox("panel") as StyleBoxFlat
	_check("the backdrop paints a flat editor-owned surface", box != null)
	if box == null:
		return
	# Opacity is the whole defect: anything below 1.0 lets the host menu through, which is
	# what a tester photographed on 2026-09-22.
	_check(
		"the surface is fully opaque",
		is_equal_approx(box.bg_color.a, 1.0),
		"alpha=%s" % str(box.bg_color.a)
	)
	_check(
		"the surface carries the editor's provisional backdrop colour",
		box.bg_color.is_equal_approx(BACKGROUND_COLOR),
		"bg_color=%s" % str(box.bg_color)
	)
	_check(
		"the backdrop covers the full editor width", is_equal_approx(background.anchor_right, 1.0)
	)
	_check(
		"the backdrop covers the full editor height", is_equal_approx(background.anchor_bottom, 1.0)
	)


func _the_chrome_is_painted_above_it(screen: Control) -> void:
	print("\n-- editor chrome remains above the backdrop --")
	var background := screen.get_node_or_null("Background") as Control
	var shell := screen.get_node_or_null("Shell") as Control
	var minimum_size_state := screen.get_node_or_null("MinimumSizeState") as Control
	var background_index: int = screen.get_children().find(background)
	_check(
		"the shell is painted above the backdrop",
		shell != null and screen.get_children().find(shell) > background_index
	)
	# The minimum-size state replaces the shell below the floor, so it needs the backdrop too.
	_check(
		"the minimum-size state is painted above the backdrop",
		(
			minimum_size_state != null
			and screen.get_children().find(minimum_size_state) > background_index
		)
	)


func _the_backdrop_owns_pointer_input(screen: Control) -> void:
	print("\n-- and it owns pointer input while the editor is open --")
	var background := screen.get_node_or_null("Panel") as Control
	if background == null:
		background = screen.get_node_or_null("Background") as Control
	# A click that falls through the editor reaches the main menu's buttons, which are still
	# in the tree and still enabled. Paint alone does not stop that.
	_check(
		"the backdrop stops a click from reaching the live main menu",
		background != null and background.mouse_filter == Control.MOUSE_FILTER_STOP,
		"mouse_filter=%s" % (str(background.mouse_filter) if background != null else "missing")
	)
