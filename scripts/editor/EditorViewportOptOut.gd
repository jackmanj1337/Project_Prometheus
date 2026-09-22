class_name EditorViewportOptOut extends RefCounted
# `[CEUI-S2]` measures the real WINDOW, so the editor shell has to be laid out in real
# window pixels too. This object is the one place that opts the window out of the player's
# content scale while the editor is open, and puts back exactly what was there on the way
# out. `EDITOR-MINSIZE-GATE-MEASURES-VIEWPORT-2026-09-22`.
#
# WHY THE MEASUREMENT WAS ALWAYS 1280x720. `SettingsManager._derived_content_scale_factor()`
# takes the smaller of the identity diagonal and `fit_content_scale_factor_for_size()`, and
# the fit term is defined as "the largest 0.5 step that still fits 1280x720 inside the
# window, snapped DOWN". On a standard 16:9 display that step lands exactly on the
# diagonal -- 1.0 at 1280x720, 1.5 at 1920x1080, 2.0 at 2560x1440, 3.0 at 3840x2160 -- and
# the logical viewport is `window / factor`, so it is EXACTLY 1280x720 in all four cases.
# The `[CEUI-S2]` floor of 1920x880 was therefore unreachable by resizing: 1600x900
# measures 1600x900 and fails on width, ultrawide 3440x1440 measures 1720x720 and fails on
# both. The walk that found this read a byte-identical "This window is 1280 x 720" at three
# different window sizes and reasonably called the number stale. It was not stale; it was
# the correct division, three times over.
#
# WHY THE FACTOR AND NOT THE SIZE. The row was ruled as "set `content_scale_size` to
# `(0, 0)` on entry and restore `(1280, 720)` on exit", on the understanding that the
# project pins a fixed design size. It does not, and has not since
# `UI-VIEWPORT-ASPECT-2026-07-31`: `SettingsManager._apply_content_scale` already sets
# `content_scale_size = Vector2i.ZERO` with `CONTENT_SCALE_ASPECT_EXPAND` on every
# non-headless run, which is Godot's no-stretch branch. So the entry half of the ruling is
# a no-op, and the exit half would INTRODUCE a 1280x720 letterbox that would shrink every
# player-facing screen the moment the editor closed. The factor is the knob that was
# actually pinning the measurement, so the factor is what is opted out of. The size is
# still saved and restored, because this object's contract is "the window is exactly as it
# was", and a future caller that does arrive with a non-zero size must not lose it.
#
# THE PLAYER'S SETTINGS ARE NOT TOUCHED. `SettingsManager.content_scale_factor` -- the
# PERSISTED value, and the one `MenuScale` divides by -- is never written here. Only the
# live `Window` property is. That is what `[CEUI-S1]` point 1 means by editor-local: the
# player's file was never a party to it, and closing the editor restores the window.

## The editor lays out in window pixels, so the window's own scale is the identity while it
## is open. `[CEUI-S1]`'s `editor_scale` is the author's knob for size inside the shell, and
## it is applied by `EditorShellMetrics.effective_size`, not here -- multiplying the two
## would be the double-scaling `[CEUI-S2]` exists to prevent.
const NEUTRAL_FACTOR := 1.0

var _window: Window = null
var _saved_factor := 0.0
var _saved_size := Vector2i.ZERO


## True between a successful `enter()` and its `exit()`. The screen's measurement asks this
## rather than assuming: when the opt-out is NOT in effect, the window is not what the shell
## is laid out in, and measuring it would report a size nothing on screen has.
func is_active() -> bool:
	return _window != null and is_instance_valid(_window)


## Returns false when there was nothing to do -- no window, or already entered.
##
## ENTERING TWICE MUST NOT OVERWRITE THE SAVED STATE. Saving the neutralised values over the
## player's would leave their window at factor 1.0 for the rest of the session, and it is
## invisible on any display whose factor is already 1.0 -- which is every 720p one, and
## every headless run. That is the whole reason the saved state is guarded rather than
## simply re-read.
func enter(window: Window) -> bool:
	if window == null or not is_instance_valid(window) or is_active():
		return false
	_window = window
	_saved_factor = window.content_scale_factor
	_saved_size = window.content_scale_size
	if window.content_scale_size != Vector2i.ZERO:
		window.content_scale_size = Vector2i.ZERO
	# Same-value guard: `Window.set_content_scale_factor` emits `size_changed` even for an
	# identical write, and the screen re-enters layout from that signal. The expand model in
	# `SettingsManager._apply_content_scale` carries the same guard for the same reason.
	if not is_equal_approx(window.content_scale_factor, NEUTRAL_FACTOR):
		window.content_scale_factor = NEUTRAL_FACTOR
	return true


## Restores the window to the values `enter()` saved. Returns false when the opt-out was not
## in effect, so a caller that syncs on every visibility change can call it unconditionally.
##
## The state is cleared BEFORE the window is written, so a restore that re-enters this
## object through `size_changed` finds it inactive rather than restoring twice.
func exit() -> bool:
	if _window == null:
		return false
	var window := _window
	var factor := _saved_factor
	var size := _saved_size
	_window = null
	_saved_factor = 0.0
	_saved_size = Vector2i.ZERO
	if not is_instance_valid(window):
		return false
	if window.content_scale_size != size:
		window.content_scale_size = size
	if not is_equal_approx(window.content_scale_factor, factor):
		window.content_scale_factor = factor
	return true
