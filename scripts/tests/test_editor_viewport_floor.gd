extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_viewport_floor.gd
#
# `[CEUI-S2]`'s floor as the editor actually meets it, after
# `EDITOR-MINSIZE-GATE-MEASURES-VIEWPORT-2026-09-22`: the gate measured the LOGICAL
# viewport, which the project's own content scale pins to exactly 1280x720 on every
# standard 16:9 display, so the editor could not be opened at any window size and shipped
# unopened twice.
#
# THE ASSERTIONS THAT CARRY THE FIX, and that nothing else can catch:
#
#   * THE ARITHMETIC THAT MADE THE GATE UNPASSABLE IS NAMED, NOT IMPLIED. A test that only
#     asserted "1920x1080 clears the floor" would have passed before the fix too -- the
#     metrics function was always right. What was wrong was the size handed to it, so the
#     regression is asserted as a pair: the real window clears the floor AND the logical
#     viewport the old call would have measured does not, at the same display.
#   * THE OPT-OUT RESTORES WHAT WAS THERE, NOT A CONSTANT. The row was ruled as "restore
#     `(1280, 720)` on exit". The project has not used a fixed design size since
#     `UI-VIEWPORT-ASPECT-2026-07-31`, so restoring a constant would introduce a letterbox
#     on the way OUT of the editor -- a defect visible only after closing it, on the screen
#     after. Asserted by restoring an arbitrary factor and size, not the neutral ones.
#   * ENTERING TWICE DOES NOT OVERWRITE THE SAVED STATE. The second `enter()` would save the
#     NEUTRALISED values over the player's, stranding their window at factor 1.0 for the
#     rest of the session. It is invisible at factor 1.0 -- every 720p display, and every
#     headless run -- which is exactly why it needs an assertion rather than a look.
#   * HEADLESS IS EXCLUDED ON PURPOSE. Its window is a fixed 64x64 with no display behind
#     it. A build that opted out there would hand the shell a 64x64 canvas and make every
#     other headless layout assertion in this repo measure that instead.

const MetricsScript = preload("res://scripts/editor/EditorShellMetrics.gd")
const OptOutScript = preload("res://scripts/editor/EditorViewportOptOut.gd")
const SettingsManagerScript = preload("res://scripts/autoloads/SettingsManager.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Viewport Floor Test ===")
	await process_frame

	_the_logical_viewport_is_pinned_to_the_design_size()
	_the_real_window_clears_the_floor_where_the_viewport_could_not()
	_the_opt_out_neutralises_the_window()
	_the_opt_out_restores_what_was_there()
	_entering_twice_does_not_overwrite_the_saved_state()
	_exiting_without_entering_is_a_no_op()
	await _the_screen_measures_the_window()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])


# ---- the arithmetic the gate was measuring ----


## The defect, stated as arithmetic so it cannot come back quietly. `[V070-01]` made the
## derived factor the SMALLER of the identity diagonal and the fit, and the fit is the
## largest 0.5 step that still fits 1280x720 inside the window, snapped DOWN. On a 16:9
## display that step IS the diagonal, so `window / factor` is the design size exactly.
func _the_logical_viewport_is_pinned_to_the_design_size() -> void:
	print("\n-- the logical viewport is pinned to the design size --")
	var design := Vector2(1280, 720)
	for window in [
		Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)
	]:
		var factor := SettingsManagerScript.fit_content_scale_factor_for_size(window)
		var logical := Vector2(window) / factor
		_check(
			"%s at the fitted factor %s is logically %s" % [window, factor, design],
			logical.is_equal_approx(design),
			str(logical)
		)
		_check(
			"...and that logical size is BELOW the editor floor",
			MetricsScript.is_below_floor(MetricsScript.effective_size(logical, 1.0))
		)


## The other half of the pair. Without this, the case above is just a description of the
## bug; together they say the fix changed which of two numbers the gate is handed.
func _the_real_window_clears_the_floor_where_the_viewport_could_not() -> void:
	print("\n-- the real window clears the floor where the viewport could not --")
	# FHD at 100% IS the floor, which is `[CEUI-S2]`'s floor class by construction.
	_check(
		"1920x1080 at editor scale 1.0 is at or above the floor",
		not MetricsScript.is_below_floor(MetricsScript.effective_size(Vector2(1920, 1080), 1.0))
	)
	_check(
		"3840x2160 at editor scale 2.0 is at or above the floor",
		not MetricsScript.is_below_floor(MetricsScript.effective_size(Vector2(3840, 2160), 2.0))
	)
	# The floor is still a floor: the fix must not have turned the gate off.
	_check(
		"1600x900 still fails, on width",
		MetricsScript.effective_size(Vector2(1600, 900), 1.0).x < MetricsScript.VIEWPORT_FLOOR.x
	)
	_check(
		"ultrawide 3440x1440 still fails, on height",
		MetricsScript.effective_size(Vector2(3440, 1440), 2.0).y < MetricsScript.VIEWPORT_FLOOR.y
	)
	_check(
		"FHD at 125% still fails on height, which is `[CEUI-5]`'s measured case",
		MetricsScript.is_below_floor(MetricsScript.effective_size(Vector2(1920, 1080), 1.25))
	)


# ---- the opt-out ----


## A detached `Window` rather than the root: the root's content scale is the running
## suite's, and these cases have to be able to set an arbitrary one.
func _spare_window(factor: float, size: Vector2i) -> Window:
	var window := Window.new()
	window.content_scale_factor = factor
	window.content_scale_size = size
	return window


func _the_opt_out_neutralises_the_window() -> void:
	print("\n-- the opt-out neutralises the window --")
	var window := _spare_window(3.0, Vector2i.ZERO)
	var opt_out := OptOutScript.new()
	_check("entering reports that it did something", opt_out.enter(window))
	_check("and says so afterwards", opt_out.is_active())
	_check(
		"the window's content scale is the identity",
		is_equal_approx(window.content_scale_factor, 1.0),
		str(window.content_scale_factor)
	)
	_check(
		"and its base size stays unset, so the window IS the viewport",
		window.content_scale_size == Vector2i.ZERO
	)
	opt_out.exit()
	window.free()


## The ruling said "restore `(1280, 720)`". A constant is asserted against here on purpose:
## the project has no fixed design size, so restoring one would letterbox every screen drawn
## after the editor closed.
func _the_opt_out_restores_what_was_there() -> void:
	print("\n-- the opt-out restores what was there --")
	var window := _spare_window(1.5, Vector2i(1600, 900))
	var opt_out := OptOutScript.new()
	opt_out.enter(window)
	_check("exiting reports that it did something", opt_out.exit())
	_check("and says so afterwards", not opt_out.is_active())
	_check(
		"the player's factor is back",
		is_equal_approx(window.content_scale_factor, 1.5),
		str(window.content_scale_factor)
	)
	_check(
		"and the base size is the one it found, not the design size",
		window.content_scale_size == Vector2i(1600, 900),
		str(window.content_scale_size)
	)
	window.free()


func _entering_twice_does_not_overwrite_the_saved_state() -> void:
	print("\n-- entering twice does not overwrite the saved state --")
	var window := _spare_window(2.0, Vector2i.ZERO)
	var opt_out := OptOutScript.new()
	opt_out.enter(window)
	_check("a second enter refuses", not opt_out.enter(window))
	opt_out.exit()
	_check(
		"so the restore is the player's factor, not the neutralised one",
		is_equal_approx(window.content_scale_factor, 2.0),
		str(window.content_scale_factor)
	)
	window.free()


func _exiting_without_entering_is_a_no_op() -> void:
	print("\n-- exiting without entering is a no-op --")
	var window := _spare_window(2.5, Vector2i.ZERO)
	var opt_out := OptOutScript.new()
	_check("exit refuses when nothing was entered", not opt_out.exit())
	_check(
		"and the window is untouched",
		is_equal_approx(window.content_scale_factor, 2.5),
		str(window.content_scale_factor)
	)
	window.free()


# ---- the screen ----


## Headless CANNOT exercise the opt-out -- see the header -- so what is asserted here is the
## exclusion itself, plus that the measurement still reports the stable project-base
## viewport the rest of the headless suite lays out against. The opt-out's own behaviour is
## covered above against a spare window, and the on-screen result needs a rendered run.
func _the_screen_measures_the_window() -> void:
	print("\n-- the screen measures the window --")
	var screen: Control = preload("res://scenes/ui/CampaignEditorScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame

	_check("this run is headless", DisplayServer.get_name() == "headless")
	_check("so the editor does not opt the window out", not screen.viewport_opt_out_active())
	_check(
		"and the measurement falls back to the logical viewport, not the 64x64 window",
		screen.effective_viewport_size().is_equal_approx(root.get_visible_rect().size),
		"%s vs %s" % [screen.effective_viewport_size(), root.get_visible_rect().size]
	)
	# The editor scale still divides, which is the half of `[CEUI-S2]` the fix must not have
	# disturbed.
	screen.set_editor_scale(2.0)
	await process_frame
	_check(
		"editor scale still divides the measurement",
		screen.effective_viewport_size().is_equal_approx(root.get_visible_rect().size / 2.0),
		str(screen.effective_viewport_size())
	)

	screen.queue_free()
	await process_frame
