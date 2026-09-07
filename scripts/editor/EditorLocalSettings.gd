class_name EditorLocalSettings extends RefCounted
# `[CEUI-S1]`'s four editor-local settings -- scale, font size, information density and
# reduced motion -- and the file they persist to.
#
# EDITOR-LOCAL MEANS TWO SEPARATE THINGS, AND BOTH ARE LOAD-BEARING.
#
#   1. THEY ARE NOT THE PLAYER'S SETTINGS. `[CEUI-S1]` kept the player's Menu Scale out of
#      the editor because the editor is a different KIND of surface -- heavy text entry,
#      dense dropdowns, and a game session running inside it. The promoted question that
#      gated the whole `S9` walk was what happens if Menu Scale reaches here: `2.0x` on
#      `1920x880` is an effective `960x440`, and `[CEUI-S2]`'s floor never fires. So this
#      object never reads or writes `SettingsManager`, and it persists to its OWN file.
#   2. THEY ARE NOT THE `ResponsiveLayout` AUTOLOAD'S GLOBALS. `menu_mode` and
#      `info_density` are single global values on that autoload. A screen that called
#      `set_menu_mode(MENU_MODE_EDITOR)` or `set_info_density(...)` would flip the density
#      of every game screen with it and leave it flipped when the editor closed. The
#      editor's column is read STATICALLY with `tokens_for_mode()`, and the density
#      preference lives here instead of being written to the autoload. `[CEUI-S3]`'s
#      per-viewport context is the mechanism that eventually carries an editor mode without
#      a global flip, and it is not this row's to build.
#
# THE CLASS IS `EditorLocalSettings`, NOT `EditorSettings`. `EditorSettings` is a native
# Godot class, and `class_name EditorSettings` is a hard parse error ("hides a global script
# class or native class"), not a style preference. The row named the file
# `scripts/editor/EditorSettings.gd`; the name had to move for the engine's sake and
# "editor-local" is what the ruling calls these anyway.
#
# WHAT THIS OBJECT DOES NOT DO: it draws nothing. `[CEUI-S11]` names the six header actions
# and no ruling places a settings surface inside the editor, so inventing a seventh action
# or an unruled panel would be this build asserting UI the walk did not rule. The knob is
# the caller's to place; everything a knob needs -- levels, validation, the `EW-1` warning
# and confirm-or-revert staging -- is here.

const ResponsiveLayoutScript = preload("res://scripts/autoloads/ResponsiveLayout.gd")

## Its own file, beside `user://settings.cfg` rather than inside it. Point 1 above is the
## reason: a key in the player's settings file is one refactor away from being read by a
## player-facing screen, and the separation is what makes that structurally hard.
const SETTINGS_PATH := "user://editor_settings.cfg"
const SECTION := "editor"

## `EW-1`, ruled: NOTHING BOUNDS HOW FAR DOWN THE SCALE KNOB MAY GO. Clearing `[CEUI-S2]`'s
## floor on a 1366x768 laptop costs 36% of physical type size, and the ruling's answer was
## "allow it, but warn" -- not "clamp it". So these are the levels a knob OFFERS, and
## `set_editor_scale()` accepts any positive value, including one below the first level.
## Only non-positive values are refused, because a non-positive scale is not a small
## editor: `EditorShellMetrics.effective_size()` reports `Vector2.ZERO` for it, which reads
## as below the floor and shows the minimum-size state over nonsense metrics.
const SCALE_LEVELS: Array[float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

## `EW-1`'s warning threshold, stated as the ruling states it: warn below
## `DPR x scale = 1.0`. Below that the author is rendering editor chrome at less than one
## physical pixel per logical pixel, which is where the 36% type-size loss lives.
const PHYSICAL_PIXEL_RATIO_FLOOR := 1.0

## The editor column's `body_font` is 14. These are the sizes a knob offers around it; as
## with scale, `set_font_size()` accepts any positive value and the list is the knob's.
const FONT_SIZE_LEVELS: Array[float] = [12.0, 13.0, 14.0, 16.0, 18.0, 20.0]
const DEFAULT_FONT_SIZE := 14.0

## Emitted after any accepted change, so a screen re-reads rather than being pushed at.
signal changed

## `[CEUI-S1]`'s four. Read them; write them through the setters, which validate.
var editor_scale: float = 1.0
var font_size: float = DEFAULT_FONT_SIZE
## Editor-local information density. Same vocabulary as `ResponsiveLayout.DENSITIES`
## because it means the same thing -- how MUCH is shown, orthogonal to how big it is -- but
## held here, never written to the autoload. See point 2 above.
var info_density: String = ResponsiveLayoutScript.DENSITY_STANDARD
## No editor surface animates yet, so this setting currently has no consumer inside the
## shell. It is carried anyway because the alternative is that the FIRST animated editor
## surface invents its own preference key, and `[CEUI-S1]` already ruled where this one
## lives.
var reduced_motion: bool = false

# `[EW-1]`'s confirm-or-revert staging. The value is applied live so the author can see
# what they chose, and the PREVIOUS value is held until they keep or revert -- the same
# shape `SettingsScreen._change_with_confirm()` uses for resolution and window mode.
var _pending_scale_previous: float = 0.0
var _scale_change_pending := false


## `true` when `scale` at this device pixel ratio falls below `EW-1`'s threshold. Static
## because the caller asks it BEFORE committing to a value, and a dialog decision should
## not require mutating the settings object first.
static func scale_needs_confirmation(scale: float, device_pixel_ratio: float) -> bool:
	if scale <= 0.0:
		return true
	return scale * device_pixel_ratio < PHYSICAL_PIXEL_RATIO_FLOOR


## Names the ratio and both numbers behind it. An author who is told only "this is small"
## cannot tell whether to change the scale or the display.
static func scale_warning_message(scale: float, device_pixel_ratio: float) -> String:
	return (
		(
			"Editor scale %.2f at display scale %.2f renders chrome at %.2f physical"
			+ " pixels per logical pixel.\nText will be smaller than the editor was"
			+ " designed for."
		)
		% [scale, device_pixel_ratio, scale * device_pixel_ratio]
	)


## Refuses a non-positive scale and returns whether the value was taken. See `SCALE_LEVELS`
## for why that is the only refusal.
func set_editor_scale(scale: float) -> bool:
	if scale <= 0.0:
		return false
	if is_equal_approx(scale, editor_scale):
		return true
	editor_scale = scale
	changed.emit()
	return true


func set_font_size(size: float) -> bool:
	if size <= 0.0:
		return false
	if is_equal_approx(size, font_size):
		return true
	font_size = size
	changed.emit()
	return true


## Refuses a density outside `ResponsiveLayout.DENSITIES` rather than silently falling back
## to standard: a typo that quietly means "standard" is a setting that ignores the author.
func set_info_density(density: String) -> bool:
	if not density in ResponsiveLayoutScript.DENSITIES:
		return false
	if density == info_density:
		return true
	info_density = density
	changed.emit()
	return true


func set_reduced_motion(enabled: bool) -> void:
	if enabled == reduced_motion:
		return
	reduced_motion = enabled
	changed.emit()


# ---- EW-1 confirm-or-revert ----


## Applies `scale` live and reports whether `EW-1` wants it confirmed. The value is NOT
## persisted here: `confirm_scale_change()` saves, `revert_scale_change()` puts the old one
## back. A caller that ignores the returned `needs_confirmation` has applied a legal value
## and simply owes no dialog -- which is the case for every scale at or above the ratio.
func begin_scale_change(scale: float, device_pixel_ratio: float) -> Dictionary:
	var previous := editor_scale
	if not set_editor_scale(scale):
		return {
			"applied": false,
			"needs_confirmation": false,
			"message": "",
			"previous": previous,
		}
	var needs := scale_needs_confirmation(scale, device_pixel_ratio)
	if needs:
		_pending_scale_previous = previous
		_scale_change_pending = true
	return {
		"applied": true,
		"needs_confirmation": needs,
		"message": scale_warning_message(scale, device_pixel_ratio) if needs else "",
		"previous": previous,
	}


func scale_change_pending() -> bool:
	return _scale_change_pending


## Keeps the applied value and persists it. Returns the save's error code so a caller that
## cares can report a failed write instead of assuming one.
func confirm_scale_change(path: String = SETTINGS_PATH) -> int:
	_scale_change_pending = false
	_pending_scale_previous = 0.0
	return save_to(path)


## Puts the previous value back WITHOUT saving. Nothing was persisted on the way in, so
## reverting is only an in-memory restore.
func revert_scale_change() -> void:
	if not _scale_change_pending:
		return
	_scale_change_pending = false
	var previous := _pending_scale_previous
	_pending_scale_previous = 0.0
	if previous > 0.0:
		editor_scale = previous
		changed.emit()


# ---- tokens ----


## `[CEUI-S50]`'s editor column with this author's font size substituted for the column's
## `body_font`. Everything else in the column is the ratified table: `min_target` stays 24
## (`EW-9`), and the six editor-only tokens -- `workspace_bar`, `tab_height`, `tree_width`,
## `inspector_width`, `form_measure`, `split_threshold` -- come through untouched.
##
## The scale is deliberately NOT multiplied into these. `[CEUI-S2]` measures the floor as
## `window / scale`, so scale is applied once, to the viewport, and the tokens are already
## in the effective space that measurement produces. Multiplying here as well would apply
## it twice and reintroduce the double-scaling the ruling exists to prevent.
func tokens() -> Dictionary:
	var column := (
		ResponsiveLayoutScript.tokens_for_mode(ResponsiveLayoutScript.MENU_MODE_EDITOR).duplicate()
	)
	column["body_font"] = font_size
	return column


# ---- persistence ----


func to_dict() -> Dictionary:
	return {
		"editor_scale": editor_scale,
		"font_size": font_size,
		"info_density": info_density,
		"reduced_motion": reduced_motion,
	}


## Takes each field through its setter, so a hand-edited or corrupt file cannot install a
## value the setters refuse. A rejected field leaves the default standing; the load as a
## whole still succeeds, because one bad key is not a reason to discard an author's other
## three preferences.
func apply_dict(values: Dictionary) -> void:
	if values.has("editor_scale"):
		set_editor_scale(float(values["editor_scale"]))
	if values.has("font_size"):
		set_font_size(float(values["font_size"]))
	if values.has("info_density"):
		set_info_density(str(values["info_density"]))
	if values.has("reduced_motion"):
		set_reduced_motion(bool(values["reduced_motion"]))


## Returns the `ConfigFile` error code. A missing file is `ERR_FILE_NOT_FOUND` and is the
## normal first-run case, not a failure: the defaults are already correct.
func load_from(path: String = SETTINGS_PATH) -> int:
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	if err != OK:
		return err
	var values: Dictionary = {}
	for key in ["editor_scale", "font_size", "info_density", "reduced_motion"]:
		if cfg.has_section_key(SECTION, key):
			values[key] = cfg.get_value(SECTION, key)
	apply_dict(values)
	return OK


func save_to(path: String = SETTINGS_PATH) -> int:
	var cfg := ConfigFile.new()
	var values := to_dict()
	for key in values:
		cfg.set_value(SECTION, key, values[key])
	return cfg.save(path)
