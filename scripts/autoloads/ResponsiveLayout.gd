extends Node
## Responsive layout seam: derives a SIZE CLASS from the logical viewport and publishes it.
##
## The model (responsive_ui_redesign_2026-08-06.md): screens are not authored at one size
## and centred in whatever they get. Two inputs produce one derived class, with no device
## database:
##
##     logical viewport = backing size / content_scale_factor   (the player owns the factor)
##     size class       = f(logical viewport width)
##
## Compact < 600 <= Medium < 1024 <= Expanded. Today's 1280x720 layouts survive as the
## LARGEST class rather than the only one.
##
## THE CLASS IS LIVE, not a startup decision. The player can drag the window to an
## arbitrary size (UI-VIEWPORT-ASPECT-2026-07-31 decision 2) and can change Viewport Scale
## from the Settings screen while looking at it, so a screen can change class WHILE OPEN
## and must survive it. Nothing here may be read once in _ready().
##
## This is the seam only: it publishes the class and the density tokens and changes no
## screen but UnitDetailsScreen, whose hard-coded 900.0 threshold was the ad-hoc size class
## this generalises. Screens convert one per branch afterwards.
##
## Deliberately does NOT touch SettingsManager.gd: that file is claimed by
## IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29, which is still open pending its Windows
## return. This node CONSUMES SettingsManager's existing `display_size_changed` signal
## rather than adding anything to it, and holds Menu Mode / information density in memory
## until that claim clears and they can become persisted settings.

## Emitted when the size class actually changes, never on a same-class resize. That is the
## primary state-preservation mechanism in the whole design: a screen that receives no
## signal cannot lose the player's selection, scroll position or open More Info target
## rebuilding for a change that did not happen.
signal size_class_changed(new_class: String, previous_class: String)

## Emitted when Menu Mode or information density changes. Separate from the size class
## because they are orthogonal: class picks a layout, mode picks a density column, density
## picks how much is shown.
signal density_changed

const CLASS_COMPACT := "compact"
const CLASS_MEDIUM := "medium"
const CLASS_EXPANDED := "expanded"
const SIZE_CLASSES: Array[String] = [CLASS_COMPACT, CLASS_MEDIUM, CLASS_EXPANDED]

## Logical-width boundaries. A class owns [lower, upper).
const BREAKPOINT_MEDIUM: float = 600.0
const BREAKPOINT_EXPANDED: float = 1024.0

## Hysteresis margin, in logical px, applied to BOTH sides of the CURRENT class's band.
## A window parked at exactly 600 logical px must not oscillate: sub-pixel jitter, a
## scrollbar appearing, or a one-pixel edge drag would otherwise re-parent panes
## repeatedly. 24px is wide enough to swallow that and narrow enough that a deliberate
## resize still lands in the class the player can see they asked for.
const CLASS_HYSTERESIS: float = 24.0

## Debounce window for republishing after a resize. An OS window drag emits a resize per
## frame and a class change re-parents panes; rebuilding on every frame of a live drag is
## the same defect shape as the mobile controller's republish-during-gesture bug — a
## gesture and a rebuild fighting each other. One publish per settled drag instead.
const RESIZE_DEBOUNCE_SEC: float = 0.12

## Menu Mode is NOT a look-and-feel preference — it selects a density token set, and
## density is a function of the input device. Awakening's bottom sheet runs a 17.6px row
## pitch, a third of any touch minimum, because nothing on that surface is ever tapped.
const MENU_MODE_TOUCH := "touch"
const MENU_MODE_CONTROLLER := "controller"
const MENU_MODES: Array[String] = [MENU_MODE_TOUCH, MENU_MODE_CONTROLLER]

## Information density: how MUCH is shown, orthogonal to how big it is. Precedent is
## Awakening's player-facing `Interface: Full`.
const DENSITY_FULL := "full"
const DENSITY_STANDARD := "standard"
const DENSITY_MINIMAL := "minimal"
const DENSITIES: Array[String] = [DENSITY_FULL, DENSITY_STANDARD, DENSITY_MINIMAL]

## The two token sets, in logical px. Sources are recorded per row in the design doc:
## Material 48dp and Apple HIG 44pt for touch; the measured Awakening menu pitch (32) and
## bottom-sheet detail row (17.6) for controller. `min_target` is 0 in controller mode
## because there is no pointer to hit — the row marker is the focus ring.
## No scene may carry a hard-coded pixel value; it reads a token from here.
const DENSITY_TOKENS: Dictionary = {
	MENU_MODE_TOUCH:
	{
		"row_height": 48.0,
		"row_gap": 8.0,
		"body_font": 16.0,
		"detail_row": 44.0,
		"min_target": 44.0,
		"gutter": 16.0,
		"header": 72.0,
		"footer": 64.0,
	},
	MENU_MODE_CONTROLLER:
	{
		"row_height": 28.0,
		"row_gap": 2.0,
		"body_font": 14.0,
		"detail_row": 18.0,
		"min_target": 0.0,
		"gutter": 8.0,
		"header": 40.0,
		"footer": 26.0,
	},
}

## The current class. Seeded to Expanded so that a consumer constructed before the first
## measurement behaves like today's 1280x720 authoring rather than like a phone.
var size_class: String = CLASS_EXPANDED

## Last measured logical viewport, in logical px (already divided by content_scale_factor
## by the engine — Viewport.get_visible_rect() reports logical units, not backing pixels).
var logical_size: Vector2 = Vector2.ZERO

## Owner decision 2026-08-06: defaults are large buttons with the controller on screen, so
## touch density is the default. Held here, not in SettingsManager — see the class comment.
var menu_mode: String = MENU_MODE_TOUCH
var info_density: String = DENSITY_STANDARD

var _debounce_timer: Timer = null
var _settings: Node = null


func _ready() -> void:
	_debounce_timer = Timer.new()
	_debounce_timer.one_shot = true
	_debounce_timer.wait_time = RESIZE_DEBOUNCE_SEC
	# Layout must keep settling while the game is paused: a pause menu is a menu, and the
	# player can resize the window with it open.
	_debounce_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_debounce_timer.timeout.connect(_on_debounce_timeout)
	add_child(_debounce_timer)

	_settings = get_node_or_null("/root/SettingsManager")
	if (
		_settings != null
		and _settings.has_signal("display_size_changed")
		and not _settings.is_connected("display_size_changed", _on_display_changed)
	):
		# SettingsManager already coalesces viewport resize AND window resize into one
		# settled emission per frame, and a content_scale_factor write reaches it too
		# (Window.set_content_scale_factor emits size_changed). One upstream seam covers
		# both inputs of the model, which is why this node adds nothing to that file.
		_settings.connect("display_size_changed", _on_display_changed)
	else:
		# No SettingsManager (isolated tests, tools): fall back to the raw viewport signal
		# so the class still tracks reality instead of silently freezing at the seed.
		var vp := get_viewport()
		if vp != null and not vp.size_changed.is_connected(_on_display_changed):
			vp.size_changed.connect(_on_display_changed)

	# First measurement is immediate: there is no gesture to fight at startup, and a
	# debounced first publish would leave every screen laying out as Expanded for the
	# first eighth of a second.
	refresh_now()


# --- Pure classification -------------------------------------------------------------
# Static and side-effect free so the boundary and hysteresis rules can be proven headless.
# Headless pins the logical viewport at the project base (SettingsManager._apply_content_scale
# falls back to KEEP at 1280x720 because a 64x64 headless window would make all layout
# maths meaningless), so a test CANNOT drive these rules through a real window. They have
# to be callable directly, or they are untested.


## The class a width falls in, ignoring the current class. No hysteresis.
static func class_for_width(width: float) -> String:
	if width < BREAKPOINT_MEDIUM:
		return CLASS_COMPACT
	if width < BREAKPOINT_EXPANDED:
		return CLASS_MEDIUM
	return CLASS_EXPANDED


## The class a width resolves to given the class already showing, with hysteresis.
##
## The rule is one sentence: widen the CURRENT class's band by CLASS_HYSTERESIS on both
## sides; if the width still falls inside that widened band, keep the current class,
## otherwise take the raw class. Expressed this way it stays correct for a jump of two
## classes (a maximise from 400 to 1600 lands on Expanded, not Medium) without a
## direction-of-travel special case.
static func resolve_class(width: float, current_class: String) -> String:
	if not current_class in SIZE_CLASSES:
		return class_for_width(width)
	var lower := -INF
	var upper := INF
	match current_class:
		CLASS_COMPACT:
			upper = BREAKPOINT_MEDIUM + CLASS_HYSTERESIS
		CLASS_MEDIUM:
			lower = BREAKPOINT_MEDIUM - CLASS_HYSTERESIS
			upper = BREAKPOINT_EXPANDED + CLASS_HYSTERESIS
		CLASS_EXPANDED:
			lower = BREAKPOINT_EXPANDED - CLASS_HYSTERESIS
	if width >= lower and width < upper:
		return current_class
	return class_for_width(width)


## True when `candidate` is at least as wide a class as `minimum`. Lets a caller write
## `at_least(CLASS_MEDIUM)` instead of comparing strings or re-deriving the ordering.
static func class_rank(size_class_name: String) -> int:
	return SIZE_CLASSES.find(size_class_name)


func at_least(minimum_class: String) -> bool:
	return class_rank(size_class) >= class_rank(minimum_class)


func is_compact() -> bool:
	return size_class == CLASS_COMPACT


# --- Density tokens ------------------------------------------------------------------


## A density token in logical px for the active Menu Mode. Unknown names return
## `fallback` rather than 0 so a typo shows up as an obviously wrong layout in a capture
## instead of a collapsed row that reads like a data problem.
func token(token_name: String, fallback: float = 0.0) -> float:
	return tokens_for_mode(menu_mode).get(token_name, fallback)


static func tokens_for_mode(mode: String) -> Dictionary:
	return DENSITY_TOKENS.get(mode, DENSITY_TOKENS[MENU_MODE_TOUCH])


func set_menu_mode(mode: String) -> void:
	if not mode in MENU_MODES or mode == menu_mode:
		return
	menu_mode = mode
	density_changed.emit()


func set_info_density(density: String) -> void:
	if not density in DENSITIES or density == info_density:
		return
	info_density = density
	density_changed.emit()


# --- Live republishing ---------------------------------------------------------------


func _on_display_changed() -> void:
	# Restart, don't accumulate: each resize during a drag pushes the settle point out, so
	# a continuous drag publishes exactly once, when it stops.
	if _debounce_timer == null:
		refresh_now()
		return
	_debounce_timer.start(RESIZE_DEBOUNCE_SEC)


func _on_debounce_timeout() -> void:
	refresh_now()


## Measures the viewport and publishes if the class changed. Public because tests and any
## caller that needs the class to be correct RIGHT NOW (rather than after the debounce)
## must not have to wait on a timer to observe a settled value.
func refresh_now() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	apply_logical_size(vp.get_visible_rect().size)


## Publishes the class implied by an explicit logical size. Separated from measurement so
## the live behaviour — including "no signal on a same-class resize" — is testable without
## a window, which headless cannot vary.
func apply_logical_size(new_logical_size: Vector2) -> void:
	logical_size = new_logical_size
	var resolved := resolve_class(new_logical_size.x, size_class)
	if resolved == size_class:
		return
	var previous := size_class
	size_class = resolved
	size_class_changed.emit(size_class, previous)


## Drops a pending debounced publish and settles immediately. For a caller that knows a
## gesture has ended — or a test that does not want to wait out RESIZE_DEBOUNCE_SEC.
func flush_pending_resize() -> void:
	if _debounce_timer != null and not _debounce_timer.is_stopped():
		_debounce_timer.stop()
	refresh_now()
