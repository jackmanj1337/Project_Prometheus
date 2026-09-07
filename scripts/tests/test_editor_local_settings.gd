extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_editor_local_settings.gd
#
# Covers `[CEUI-S1]`'s four editor-local settings and `EW-1`'s scale warning --
# `EditorLocalSettings`, and the one place in `CampaignEditorScreen` the settings reach.
#
# THE ASSERTIONS THAT CARRY THE RULINGS, and that nothing else can catch:
#
#   * EDITOR-LOCAL MEANS THE PLAYER'S SETTINGS ARE UNTOUCHED. `[CEUI-S1]` kept Menu Scale
#     out of the editor because `2.0x` on `1920x880` is an effective `960x440` and
#     `[CEUI-S2]`'s floor never fires. Asserted by reading `SettingsManager` across an
#     editor-scale change, and by the settings file being a different path.
#   * EDITOR-LOCAL ALSO MEANS THE `ResponsiveLayout` AUTOLOAD'S GLOBALS ARE UNTOUCHED.
#     `menu_mode` and `info_density` are ONE global value each. A screen that wrote them
#     would flip every game screen's density and leave it flipped after the editor closed --
#     a defect nothing in the editor's own behaviour would ever show. Asserted by reading
#     both globals after the editor has taken a density and drawn itself.
#   * `EW-1`: THE KNOB IS NOT CLAMPED, IT IS WARNED. The ruling allows clearing the floor
#     and asks for confirm-or-revert below `DPR x scale = 1.0`. A build that clamped instead
#     would satisfy every "is it legible" instinct and contradict the ruling; asserted from
#     both sides of the ratio, and by a below-level scale being ACCEPTED.
#   * REVERTING NEVER WROTE ANYTHING. The value is applied live so the author can see it,
#     and persisted only on keep. Asserted by the file's absence after a revert -- a build
#     that saved on apply would look identical until the next launch.
#   * SCALE IS APPLIED ONCE. `[CEUI-S2]` measures the floor as `window / scale`, so the
#     tokens are already in effective space. Multiplying scale into them as well is the
#     double-scaling the ruling exists to prevent, and it is invisible at scale 1.0 --
#     which is every default test.
#   * A REFUSED VALUE LEAVES THE OTHERS STANDING. One corrupt key in a hand-edited file is
#     not a reason to discard the author's other three preferences.

const SettingsScript = preload("res://scripts/editor/EditorLocalSettings.gd")
const ResponsiveLayoutScript = preload("res://scripts/autoloads/ResponsiveLayout.gd")
const MetricsScript = preload("res://scripts/editor/EditorShellMetrics.gd")

const TEST_PATH := "user://test_editor_settings.cfg"

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Local Settings Test ===")
	# The autoloads are not on the tree yet when `_init` runs, and two of the assertions
	# below are precisely "the autoloads were not written to" -- reading them too early
	# would report a PASS that never looked at anything.
	await process_frame

	_defaults_are_the_ratified_column()
	_the_players_settings_are_untouched()
	_the_responsive_layout_globals_are_untouched()
	_the_scale_knob_is_warned_not_clamped()
	_confirm_or_revert_persists_only_on_keep()
	_scale_is_applied_once_not_twice()
	_font_size_reaches_the_token_column()
	_a_refused_value_leaves_the_others_standing()
	_the_file_roundtrips()
	await _the_screen_wires_the_settings_into_one_place()

	_cleanup()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])


func _cleanup() -> void:
	# The screen's own `request_editor_scale()` writes the REAL path on a safe change, so
	# both are cleared: a leftover file would make the next run start from the last run's
	# preferences rather than from the first-run defaults this suite asserts.
	for path in [TEST_PATH, SettingsScript.SETTINGS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ---- the settings object ----


## First run must BE the wireframed editor: the defaults are the ratified column, not a
## convenient round number that happens to be near it.
func _defaults_are_the_ratified_column() -> void:
	print("\n-- the defaults are the ratified column --")
	var settings := SettingsScript.new()
	var column: Dictionary = ResponsiveLayoutScript.DENSITY_TOKENS[
		ResponsiveLayoutScript.MENU_MODE_EDITOR
	]
	_check("scale defaults to 1.0", is_equal_approx(settings.editor_scale, 1.0))
	_check(
		"font size defaults to the column's body_font",
		is_equal_approx(settings.font_size, float(column["body_font"])),
		str(settings.font_size)
	)
	_check(
		"density defaults to standard",
		settings.info_density == ResponsiveLayoutScript.DENSITY_STANDARD
	)
	_check("reduced motion defaults off", not settings.reduced_motion)
	_check(
		"the default tokens ARE the column",
		settings.tokens() == column,
		str(settings.tokens().get("body_font"))
	)


## `[CEUI-S1]` point 1. The failure this catches is a settings key that migrates into
## `user://settings.cfg` "for convenience" and is then read by a player-facing screen.
func _the_players_settings_are_untouched() -> void:
	print("\n-- the player's settings are untouched --")
	var player: Object = _root_node("/root/SettingsManager")
	if player == null:
		_check("SettingsManager autoload is present", false, "not in this scene tree")
		return
	var before_menu_scale: int = player.get("menu_scale_index")
	var before_density: String = str(player.get("info_density"))
	var before_factor: float = float(player.get("content_scale_factor"))

	var settings := SettingsScript.new()
	settings.set_editor_scale(1.75)
	settings.set_font_size(20.0)
	settings.set_info_density(ResponsiveLayoutScript.DENSITY_MINIMAL)
	settings.set_reduced_motion(true)

	_check(
		"the player's menu scale is unchanged",
		int(player.get("menu_scale_index")) == before_menu_scale
	)
	_check(
		"the player's info density is unchanged", str(player.get("info_density")) == before_density
	)
	_check(
		"the player's content scale factor is unchanged",
		is_equal_approx(float(player.get("content_scale_factor")), before_factor)
	)
	_check(
		"the editor's file is not the player's file",
		SettingsScript.SETTINGS_PATH != "user://settings.cfg",
		SettingsScript.SETTINGS_PATH
	)


## `[CEUI-S1]` point 2. `menu_mode` and `info_density` are one global value each, so the
## editor taking a density must not be the whole game taking it.
func _the_responsive_layout_globals_are_untouched() -> void:
	print("\n-- the ResponsiveLayout globals are untouched --")
	var layout: Object = _root_node("/root/ResponsiveLayout")
	if layout == null:
		_check("ResponsiveLayout autoload is present", false, "not in this scene tree")
		return
	var before_mode: String = str(layout.get("menu_mode"))
	var before_density: String = str(layout.get("info_density"))

	var settings := SettingsScript.new()
	settings.set_info_density(ResponsiveLayoutScript.DENSITY_FULL)
	var tokens := settings.tokens()

	_check(
		"the editor still reads the editor column",
		is_equal_approx(float(tokens["min_target"]), 24.0)
	)
	_check(
		"the autoload's menu_mode is unchanged",
		str(layout.get("menu_mode")) == before_mode,
		str(layout.get("menu_mode"))
	)
	_check(
		"the autoload's info_density is unchanged",
		str(layout.get("info_density")) == before_density,
		str(layout.get("info_density"))
	)
	_check(
		"the editor's density is its own",
		settings.info_density == ResponsiveLayoutScript.DENSITY_FULL
	)


## `EW-1`, ruled: allow it, but warn. Both halves are asserted, because a build that
## clamped would pass every legibility instinct and fail the ruling.
func _the_scale_knob_is_warned_not_clamped() -> void:
	print("\n-- EW-1: the scale knob is warned, not clamped --")
	var settings := SettingsScript.new()
	var below_every_level := 0.4
	_check(
		"a scale below the offered levels is ACCEPTED",
		(
			settings.set_editor_scale(below_every_level)
			and is_equal_approx(settings.editor_scale, below_every_level)
		)
	)
	_check(
		"it is below every offered level", below_every_level < float(SettingsScript.SCALE_LEVELS[0])
	)
	_check("a zero scale is refused", not settings.set_editor_scale(0.0))
	_check("a negative scale is refused", not settings.set_editor_scale(-1.0))
	_check(
		"the refusal left the previous value standing",
		is_equal_approx(settings.editor_scale, below_every_level)
	)

	# The ratio, from both sides. 0.8 x 1.25 is exactly 1.0 and must NOT warn -- a `<=`
	# there would put a dialog in front of an author at the threshold the ruling allows.
	_check(
		"DPR 1.0, scale 1.0 does not warn", not SettingsScript.scale_needs_confirmation(1.0, 1.0)
	)
	_check(
		"DPR 1.25, scale 0.8 does not warn", not SettingsScript.scale_needs_confirmation(0.8, 1.25)
	)
	_check("DPR 1.0, scale 0.75 warns", SettingsScript.scale_needs_confirmation(0.75, 1.0))
	_check(
		"DPR 2.0, scale 0.75 does not warn", not SettingsScript.scale_needs_confirmation(0.75, 2.0)
	)
	_check(
		"the warning names the ratio, not just 'too small'",
		SettingsScript.scale_warning_message(0.75, 1.0).contains("0.75")
	)


func _confirm_or_revert_persists_only_on_keep() -> void:
	print("\n-- confirm-or-revert persists only on keep --")
	_cleanup()
	var settings := SettingsScript.new()
	settings.set_editor_scale(1.0)

	var report := settings.begin_scale_change(0.5, 1.0)
	_check("the value is applied live", is_equal_approx(settings.editor_scale, 0.5))
	_check("and confirmation is asked for", bool(report["needs_confirmation"]))
	_check("nothing was persisted on the way in", not FileAccess.file_exists(TEST_PATH))
	settings.revert_scale_change()
	_check("reverting restores the previous value", is_equal_approx(settings.editor_scale, 1.0))
	_check("and still wrote nothing", not FileAccess.file_exists(TEST_PATH))

	var safe := settings.begin_scale_change(1.5, 1.0)
	_check(
		"a scale at or above the ratio needs no confirmation", not bool(safe["needs_confirmation"])
	)
	_check("and leaves nothing pending", not settings.scale_change_pending())

	var warned := settings.begin_scale_change(0.5, 1.0)
	_check("a second warned change is pending again", bool(warned["needs_confirmation"]))
	_check("keeping persists", settings.confirm_scale_change(TEST_PATH) == OK)
	var reloaded := SettingsScript.new()
	_check("and the kept value is what reloads", reloaded.load_from(TEST_PATH) == OK)
	_check(
		"with the value that was kept",
		is_equal_approx(reloaded.editor_scale, 0.5),
		str(reloaded.editor_scale)
	)
	_cleanup()


## Invisible at scale 1.0, which is every other test in the project.
func _scale_is_applied_once_not_twice() -> void:
	print("\n-- scale is applied once, to the viewport, not twice --")
	var settings := SettingsScript.new()
	var at_default := settings.tokens()
	settings.set_editor_scale(2.0)
	var at_double := settings.tokens()
	_check(
		"tree_width does not move with scale", at_double["tree_width"] == at_default["tree_width"]
	)
	_check(
		"split_threshold does not move with scale",
		at_double["split_threshold"] == at_default["split_threshold"]
	)
	# The one place scale IS applied, and the ruling's own arithmetic.
	_check(
		"the floor is window / scale",
		MetricsScript.effective_size(Vector2(3840, 1760), 2.0) == Vector2(1920, 880)
	)
	_check(
		"so a 3840-wide window at scale 2.0 is AT the floor, not double it",
		not MetricsScript.is_below_floor(MetricsScript.effective_size(Vector2(3840, 1760), 2.0))
	)


func _font_size_reaches_the_token_column() -> void:
	print("\n-- font size reaches the token column --")
	var settings := SettingsScript.new()
	settings.set_font_size(20.0)
	var tokens := settings.tokens()
	_check("body_font is the author's size", is_equal_approx(float(tokens["body_font"]), 20.0))
	_check(
		"and the rest of the column is untouched",
		(
			is_equal_approx(float(tokens["tree_width"]), 280.0)
			and is_equal_approx(float(tokens["min_target"]), 24.0)
		)
	)
	_check("a zero font size is refused", not settings.set_font_size(0.0))
	_check(
		"mutating the returned tokens does not corrupt the ratified table",
		is_equal_approx(
			float(
				(
					ResponsiveLayoutScript
					. DENSITY_TOKENS[ResponsiveLayoutScript.MENU_MODE_EDITOR]["body_font"]
				)
			),
			14.0
		)
	)


func _a_refused_value_leaves_the_others_standing() -> void:
	print("\n-- a refused value leaves the others standing --")
	var settings := SettingsScript.new()
	(
		settings
		. apply_dict(
			{
				"editor_scale": -3.0,
				"font_size": 18.0,
				"info_density": "not-a-density",
				"reduced_motion": true,
			}
		)
	)
	_check("the bad scale was refused", is_equal_approx(settings.editor_scale, 1.0))
	_check(
		"the bad density was refused",
		settings.info_density == ResponsiveLayoutScript.DENSITY_STANDARD
	)
	_check("the good font size still landed", is_equal_approx(settings.font_size, 18.0))
	_check("the good reduced-motion flag still landed", settings.reduced_motion)


func _the_file_roundtrips() -> void:
	print("\n-- the file roundtrips --")
	_cleanup()
	var settings := SettingsScript.new()
	var missing := settings.load_from(TEST_PATH)
	_check("a missing file is reported, not fatal", missing != OK)
	_check("and leaves the defaults standing", is_equal_approx(settings.editor_scale, 1.0))

	settings.set_editor_scale(1.25)
	settings.set_font_size(16.0)
	settings.set_info_density(ResponsiveLayoutScript.DENSITY_MINIMAL)
	settings.set_reduced_motion(true)
	_check("saving succeeds", settings.save_to(TEST_PATH) == OK)

	var reloaded := SettingsScript.new()
	_check("loading succeeds", reloaded.load_from(TEST_PATH) == OK)
	_check(
		"all four fields roundtrip",
		reloaded.to_dict() == settings.to_dict(),
		str(reloaded.to_dict())
	)
	_cleanup()


# ---- the screen ----


func _the_screen_wires_the_settings_into_one_place() -> void:
	print("\n-- the screen wires the settings into one place --")
	var screen: Control = preload("res://scenes/ui/CampaignEditorScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame

	var settings: EditorLocalSettings = screen.editor_settings()
	_check("the screen exposes the settings object rather than copying them", settings != null)

	var before: Vector2 = screen.effective_viewport_size()
	screen.set_editor_scale(2.0)
	await process_frame
	var after: Vector2 = screen.effective_viewport_size()
	_check(
		"the effective viewport follows the setting",
		after.x < before.x or before == Vector2.ZERO,
		"%s -> %s" % [before, after]
	)
	_check(
		"through the settings object, not a private field",
		is_equal_approx(settings.editor_scale, 2.0)
	)

	var emitted := [0]
	screen.editor_settings_changed.connect(func() -> void: emitted[0] += 1)
	settings.set_font_size(20.0)
	await process_frame
	_check("a settings change is published", emitted[0] == 1, str(emitted[0]))

	var tree_pane: Control = screen.get_node("Shell/Body/TreePane")
	_check(
		"the tree pane still takes its width from the ratified column",
		is_equal_approx(tree_pane.custom_minimum_size.x, 280.0),
		str(tree_pane.custom_minimum_size.x)
	)
	var shell_root: Control = screen.get_node("Shell")
	_check("the font size reaches a theme the shell owns", shell_root.theme != null)
	_check(
		"and that theme carries the author's size",
		shell_root.theme != null and shell_root.theme.default_font_size == 20,
		str(shell_root.theme.default_font_size) if shell_root.theme != null else "no theme"
	)

	# `EW-1` through the screen: below the ratio a dialog is raised, above it none is.
	var dialogs_before := _dialog_count(screen)
	screen.request_editor_scale(1.5, 1.0)
	await process_frame
	_check("a safe scale raises no dialog", _dialog_count(screen) == dialogs_before)
	screen.request_editor_scale(0.5, 1.0)
	await process_frame
	_check(
		"a scale below the ratio raises confirm-or-revert", _dialog_count(screen) > dialogs_before
	)
	_check("and the value is applied while it is up", is_equal_approx(settings.editor_scale, 0.5))

	screen.queue_free()
	await process_frame


func _dialog_count(screen: Node) -> int:
	var count := 0
	for child in screen.get_children():
		if child is CanvasLayer:
			count += 1
	return count


func _root_node(path: String) -> Object:
	return root.get_node_or_null(path)
