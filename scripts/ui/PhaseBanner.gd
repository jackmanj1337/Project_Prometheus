extends Control
# Cosmetic phase-change banner: slides in from the right, holds, slides out left.
# GDD spec: slide-in 0.3s, hold 0.8s, slide-out 0.3s.

@onready var _panel: Panel = $Panel
@onready var _label: Label = $Panel/Label

const SLIDE_DURATION: float = 0.3
const HOLD_DURATION: float = 0.8
const OFFSCREEN_RIGHT: float = 1280.0
const OFFSCREEN_LEFT: float = -1280.0
const CENTER_X: float = 0.0


func _ready() -> void:
	_panel.position.x = OFFSCREEN_RIGHT
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.phase_changed.connect(_on_phase_changed)


func _on_phase_changed(new_phase: int) -> void:
	_label.text = "PLAYER PHASE" if new_phase == 0 else "ENEMY PHASE"
	_animate()


func _animate() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_panel.position.x = OFFSCREEN_RIGHT
	# Slide in
	tween.tween_property(_panel, "position:x", CENTER_X, SLIDE_DURATION)
	# Hold
	tween.tween_interval(HOLD_DURATION)
	# Slide out
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(_panel, "position:x", OFFSCREEN_LEFT, SLIDE_DURATION)
