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


# faction_id arrives on the phase_changed signal — the faction whose phase is
# starting (empty falls through to the "Unknown" label).
func _on_phase_changed(new_phase: int, faction_id: String = "") -> void:
	# Honor the phase_banner preference — "skip" suppresses the cosmetic banner.
	var sm := get_node_or_null("/root/SettingsManager")
	if sm and sm.get("phase_banner") == "skip":
		return
	var fid: String = "blue" if new_phase == GameState.Phase.PLAYER else faction_id
	var faction_label: String = _faction_label(fid)
	_label.text = "%s PHASE" % faction_label.to_upper()
	_panel.modulate = _faction_color(fid)
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


func _faction_label(faction_id: String) -> String:
	var md: MapData = _current_map_data()
	if md != null:
		var f: FactionData = md.get_faction(faction_id)
		if f != null:
			return f.get_label()
	return FactionData.display_label(faction_id)


func _faction_color(faction_id: String) -> Color:
	var md: MapData = _current_map_data()
	if md != null:
		var f: FactionData = md.get_faction(faction_id)
		if f != null:
			return f.color
	return Color(1, 1, 1, 1)


func _current_map_data() -> MapData:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return null
	return gs.map_data
