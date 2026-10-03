extends CanvasLayer
# Confirm-or-revert dialog for any setting that carries reachability risk [UUI-18]:
# a change that can leave the UI hard or impossible to get back from (window mode,
# resolution, Viewport Scale, Menu Scale). After such a change is applied (so the
# player can see it), this dialog gives them a bounded window to confirm; if they
# don't, it auto-reverts. Since [UUI-20] removed every player-facing minimum size,
# this dialog is the ONLY guard against a too-small view.
#
# EXEMPT FROM THE SETTING IT CONFIRMS. Viewport Scale 4.0 applied to this dialog
# would render the safety net itself unreadable, so the dialog cancels the window's
# content factor back to the display's default factor, owns its own theme (no
# MenuScale, no ResponsiveLayout tokens, so Menu Scale and Menu Mode cannot reach it
# either), and gives both buttons a 44pt target. It is then bounded by the game view
# like every modal: when even the safe scale does not fit, it shrinks to fit rather
# than clip, because the undo path is the one thing that may never clip.
#
# The scale is applied to TYPE and metrics, never as a CanvasLayer/Control transform:
# a transform stretches already-rasterized pixel-font glyphs and smears them (the
# V021-18 lesson MenuScale records). Rendered check: a layer transform of 1.9 made the
# prompt unreadable at 320x480.
#
# Built in code (no authored .tscn). Emits `kept` on confirm and `reverted` on either
# the Revert button or the countdown reaching zero — the caller does the actual
# persist/restore. The countdown logic (the heart of "15s or auto-revert") is driven
# by a 1s Timer but exposed via _tick() so it is deterministically testable.

signal kept
signal reverted

const DEFAULT_SECONDS: int = 15
# The touch-target floor and type size the dialog holds regardless of the pending
# change, in dialog units (one unit = one logical px at the safe scale).
const TARGET_MIN: float = 44.0
const FONT_SIZE: int = 16
# 280 so the whole panel (plus margins and the 0.9 fit ratio) holds full size at the
# 375px test floor [UUI-20]; at 320 it shrank to 43px targets there.
const PANEL_WIDTH: float = 280.0
# Fraction of the game view the panel may fill before it shrinks to fit.
const FIT_RATIO: float = 0.9

var _remaining: int = 0
var _label: Label = null
var _timer: Timer = null
var _root: Control = null
var _panel: PanelContainer = null
var _revert_button: Button = null
var _keep_button: Button = null
var _title: Label = null
var _margin: MarginContainer = null
var _vbox: VBoxContainer = null
var _hbox: HBoxContainer = null
# The unit scale currently applied to type and metrics (1.0 = dialog units are
# logical px).
var _unit_scale: float = 1.0
# Set by the first answer; a second (Escape in the same frame, a late tick) is ignored
# so a dialog can never emit both kept and reverted.
var _answered: bool = false


func _init() -> void:
	layer = 200  # above SettingsScreen and the HUD


# Shows the dialog and starts the countdown. `seconds` is the revert deadline.
func start(seconds: int = DEFAULT_SECONDS) -> void:
	_remaining = maxi(1, seconds)
	_build_ui()
	_update_label()
	_fit_to_game_view()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_fit_to_game_view):
		# The change being confirmed usually resizes the logical viewport itself.
		vp.size_changed.connect(_fit_to_game_view)
	# Refit once the first layout has settled (see _fit_to_game_view on measuring).
	if is_inside_tree():
		_fit_to_game_view.call_deferred()
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.one_shot = false
	_timer.timeout.connect(_tick)
	add_child(_timer)
	# Timer.start() requires the node to be in the scene tree. In production the dialog
	# is add_child'd before start(); a test that drives _tick() directly may not be.
	if _timer.is_inside_tree():
		_timer.start()


func _build_ui() -> void:
	# One root Control owns the fixed theme, so nothing inherited from the screen
	# underneath (a MenuScale-derived theme) decides the dialog's type size.
	_root = Control.new()
	_root.theme = _fixed_theme()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	_panel = PanelContainer.new()
	center.add_child(_panel)
	_margin = MarginContainer.new()
	_panel.add_child(_margin)
	_vbox = VBoxContainer.new()
	_margin.add_child(_vbox)
	var vbox := _vbox

	var title := Label.new()
	_title = title
	# Revert is the safe focused default when an accidental Enter should undo an
	# unusable change; state that action in the prompt rather than making the focus
	# convention invisible.
	title.text = "Keep this change?\nPress Enter to revert now."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_label)

	_hbox = HBoxContainer.new()
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_hbox)
	var keep := Button.new()
	_keep_button = keep
	keep.text = "Keep"
	_hbox.add_child(keep)
	_revert_button = Button.new()
	_revert_button.text = "Revert now"
	_hbox.add_child(_revert_button)
	_apply_unit_scale(1.0)

	keep.pressed.connect(_on_keep)
	_revert_button.pressed.connect(_on_revert)
	# Default focus on Revert: an accidental Enter is the safe (reverting) choice.
	# grab_focus requires the control to be in the tree (it is in production).
	if _revert_button.is_inside_tree():
		_revert_button.grab_focus()


func _fixed_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	return t


# The display's own default Viewport Scale -- what a fresh install would pick -- read
# from SettingsManager so the dialog's size does not depend on the pending factor.
# Headless and a missing manager both answer the neutral 1.0.
func safe_content_scale() -> float:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null and sm.has_method("_derived_content_scale_factor"):
		return maxf(float(sm.call("_derived_content_scale_factor")), 0.1)
	return 1.0


# The factor the window is drawing at right now, which may be the pending change.
func _window_content_scale() -> float:
	var win := get_window() if is_inside_tree() else null
	if win == null:
		return 1.0
	return maxf(win.content_scale_factor, 0.01)


# Unit scale that cancels the window's factor and applies the safe one instead, then
# shrinks further if the panel at that scale would not fit inside the game view.
# `panel_size` is the panel at unit scale 1. Pure so the arithmetic is testable
# without a real window.
static func layer_scale_for(
	safe_factor: float, window_factor: float, view_size: Vector2, panel_size: Vector2
) -> float:
	var k := safe_factor / maxf(window_factor, 0.01)
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return k
	if panel_size.x > 0.0:
		k = minf(k, view_size.x * FIT_RATIO / panel_size.x)
	if panel_size.y > 0.0:
		k = minf(k, view_size.y * FIT_RATIO / panel_size.y)
	return maxf(k, 0.01)


# Every size the dialog owns, multiplied by `k`: type, wrap width, spacing and the
# 44pt targets. Text is laid out at its true pixel size, so it stays crisp.
func _apply_unit_scale(k: float) -> void:
	_unit_scale = k
	if _root != null:
		_root.theme.default_font_size = maxi(1, roundi(FONT_SIZE * k))
	var gap := roundi(12.0 * k)
	if _margin != null:
		for side in ["left", "right", "top", "bottom"]:
			_margin.add_theme_constant_override("margin_" + side, gap)
	if _vbox != null:
		_vbox.add_theme_constant_override("separation", gap)
	if _hbox != null:
		_hbox.add_theme_constant_override("separation", roundi(16.0 * k))
	for label in [_title, _label]:
		if label != null:
			(label as Label).custom_minimum_size.x = PANEL_WIDTH * k
	for button in [_keep_button, _revert_button]:
		if button != null:
			(button as Button).custom_minimum_size = Vector2(TARGET_MIN * 2.0, TARGET_MIN) * k


func _fit_to_game_view() -> void:
	if _root == null or not is_inside_tree():
		return
	var view := get_viewport().get_visible_rect().size
	# The panel at unit scale 1, from the panel as it stands divided by the scale in
	# force. Re-applying 1.0 and measuring at once does NOT work: a theme font change
	# reaches the labels' minimum sizes a frame later, so it read the previous scale's
	# panel and halved the fit on every refit.
	var panel_size := Vector2.ZERO
	if _panel != null:
		panel_size = _panel.get_combined_minimum_size() / maxf(_unit_scale, 0.01)
	var k := layer_scale_for(safe_content_scale(), _window_content_scale(), view, panel_size)
	_apply_unit_scale(k)
	_root.position = Vector2.ZERO
	_root.size = view


# The unit scale in force: how many logical px one dialog unit occupies.
func layer_scale() -> float:
	return _unit_scale


func _update_label() -> void:
	if _label != null:
		_label.text = "Reverting in %d second%s…" % [_remaining, "" if _remaining == 1 else "s"]


# One countdown step. Reverts when the deadline is reached. Public-ish (called by the
# Timer) so tests can drive the countdown deterministically without real time.
func _tick() -> void:
	_remaining -= 1
	if _remaining <= 0:
		_on_revert()
	else:
		_update_label()


# Cancel answers the dialog, never the screen behind it: Escape reverts, the same
# safe default as Enter on the focused Revert button.
func _input(event: InputEvent) -> void:
	if _answered:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		_on_revert()


func _on_keep() -> void:
	if _answered:
		return
	_answered = true
	kept.emit()
	_close()


func _on_revert() -> void:
	if _answered:
		return
	_answered = true
	reverted.emit()
	_close()


func _close() -> void:
	if _timer != null:
		_timer.stop()
	var vp := get_viewport()
	if vp != null and vp.size_changed.is_connected(_fit_to_game_view):
		vp.size_changed.disconnect(_fit_to_game_view)
	set_process_input(false)
	queue_free()
