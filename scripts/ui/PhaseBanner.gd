extends Control
# Cosmetic phase-change banner: slides in from the right, holds, slides out left.
# GDD spec: slide-in 0.3s, hold 0.8s, slide-out 0.3s.

@onready var _panel: Panel = $Panel
@onready var _label: Label = $Panel/Label

const SLIDE_DURATION: float = 0.3
const HOLD_DURATION: float = 0.8
const CENTER_X: float = 0.0


func _ready() -> void:
	_panel.position.x = _offscreen_right()
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.phase_changed.connect(_on_phase_changed)


func _on_phase_changed(new_phase: int) -> void:
	_label.text = "PLAYER PHASE" if new_phase == GameState.Phase.PLAYER else "ENEMY PHASE"
	_animate()


# Compute offscreen distances from current viewport so any resolution works.
func _offscreen_right() -> float:
	return get_viewport().get_visible_rect().size.x

func _offscreen_left() -> float:
	return -get_viewport().get_visible_rect().size.x


func _animate() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_panel.position.x = _offscreen_right()
	# Slide in
	tween.tween_property(_panel, "position:x", CENTER_X, SLIDE_DURATION)
	# Hold
	tween.tween_interval(HOLD_DURATION)
	# Slide out
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(_panel, "position:x", _offscreen_left(), SLIDE_DURATION)
