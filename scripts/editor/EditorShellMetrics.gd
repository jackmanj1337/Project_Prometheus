class_name EditorShellMetrics extends RefCounted
# `[CEUI-S2]`'s viewport floor and the arithmetic around it, in one place because three
# different parts of the shell now measure against it: the screen (which shows the
# minimum-size state below it), `EditorWorkspaces` (whose `EW-4` panel default is a
# function of height), and the tests, which assert the boundary from both sides.
#
# THE FLOOR IS EFFECTIVE, NOT PHYSICAL, AND THAT IS THE WHOLE RULING. `[CEUI-S2]` measures
# `window size / editor scale`, and `[CEUI-S1]` makes that scale the editor's own. A
# 3840-wide window at editor scale 2.0 is 1920 effective and is AT the floor, not double
# it. Anything checking `get_viewport().size` directly against 1920 has quietly replaced
# the ruling with a different one.
#
# BELOW THE FLOOR THE SHELL IS REPLACED, NEVER REFLOWED. `[CEUI-5]` removed the compact
# desktop mode outright, so there is no smaller editor to fall back to and no breakpoint
# to add later. The wireframes' measured consequence: FHD at 125% -- a common Windows
# default on 1080p laptops -- fails, and it fails on HEIGHT by 216 px, not on width. A
# check that only guarded width would pass the one configuration most likely to hit this.

## `[CEUI-S2]`. Effective pixels.
const VIEWPORT_FLOOR := Vector2(1920, 880)

## The wireframes' three distinct effective viewports: FHD-at-100% (which is the floor),
## QHD-at-100%/4K-at-150%, and 4K-at-100%. Named so a test that means "the middle one"
## does not spell a magic pair of numbers.
const VIEWPORT_FLOOR_CLASS := Vector2(1920, 880)
const VIEWPORT_ROOMY_CLASS := Vector2(2560, 1240)
const VIEWPORT_LARGE_CLASS := Vector2(3840, 1960)


## Window size divided by editor scale. A non-positive scale returns zero rather than
## dividing: zero reads as below the floor, which is the state that shows a message
## instead of drawing a shell against nonsense metrics.
static func effective_size(window_size: Vector2, editor_scale: float) -> Vector2:
	if editor_scale <= 0.0:
		return Vector2.ZERO
	return window_size / editor_scale


static func is_below_floor(effective: Vector2) -> bool:
	return effective.x < VIEWPORT_FLOOR.x or effective.y < VIEWPORT_FLOOR.y


## Author-facing, and it names both numbers on purpose: an author whose window fails on
## height alone cannot act on a message that only says "too small".
static func minimum_size_message(effective: Vector2) -> String:
	return (
		"The campaign editor needs at least %d x %d.\nThis window is %d x %d."
		% [
			int(VIEWPORT_FLOOR.x),
			int(VIEWPORT_FLOOR.y),
			int(effective.x),
			int(effective.y),
		]
	)
