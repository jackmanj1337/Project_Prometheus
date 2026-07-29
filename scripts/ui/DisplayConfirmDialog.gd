extends CanvasLayer
# Confirm-or-revert dialog for risky display changes (resolution / window mode).
# After such a change is applied (so the player can see it), this dialog gives them
# a bounded window to confirm; if they don't, it auto-reverts. Guards the case where
# a new resolution or fullscreen mode leaves the screen unusable and the player can't
# find/click a control to undo it.
#
# Built in code (no authored .tscn). Emits `kept` on confirm and `reverted` on either
# the Revert button or the countdown reaching zero — the caller does the actual
# persist/restore. The countdown logic (the heart of "15s or auto-revert") is driven
# by a 1s Timer but exposed via _tick() so it is deterministically testable.

signal kept
signal reverted

const DEFAULT_SECONDS: int = 15

var _remaining: int = 0
var _label: Label = null
var _timer: Timer = null


func _init() -> void:
	layer = 200  # above SettingsScreen and the HUD


# Shows the dialog and starts the countdown. `seconds` is the revert deadline.
func start(seconds: int = DEFAULT_SECONDS) -> void:
	_remaining = maxi(1, seconds)
	_build_ui()
	_update_label()
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
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Keep these display settings?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)
	var keep := Button.new()
	keep.text = "Keep"
	hbox.add_child(keep)
	var revert := Button.new()
	revert.text = "Revert now"
	hbox.add_child(revert)

	keep.pressed.connect(_on_keep)
	revert.pressed.connect(_on_revert)
	# Default focus on Revert: an accidental Enter is the safe (reverting) choice.
	# grab_focus requires the control to be in the tree (it is in production).
	if revert.is_inside_tree():
		revert.grab_focus()


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


func _on_keep() -> void:
	kept.emit()
	_close()


func _on_revert() -> void:
	reverted.emit()
	_close()


func _close() -> void:
	if _timer != null:
		_timer.stop()
	queue_free()
