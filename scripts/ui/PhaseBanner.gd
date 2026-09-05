extends Control
# Cosmetic phase-change banner: slides in from the right, holds, slides out left.
# GDD spec: slide-in 0.3s, hold 0.8s, slide-out 0.3s.

@onready var _panel: Panel = $Panel
@onready var _label: Label = $Panel/Label

const SLIDE_DURATION: float = 0.3
const HOLD_DURATION: float = 0.8
const CENTER_X: float = 0.0

var _tween: Tween


func _ready() -> void:
	_sync_panel_geometry()
	get_viewport().size_changed.connect(_sync_panel_geometry)
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.phase_changed.connect(_on_phase_changed)


# Resize cancels the cosmetic animation. Its old endpoints cannot describe the
# new viewport; the next phase starts a fresh animation at the new bounds.
func _sync_panel_geometry() -> void:
	if _panel == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	_panel.size.x = viewport_size.x
	_panel.position.y = (viewport_size.y - _panel.size.y) / 2.0
	_reset_after_animation()


func _reset_after_animation() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	_panel.hide()
	_panel.position.x = _offscreen_left()


func _on_phase_changed(new_phase: int, faction_id: String = "") -> void:
	# Honor the phase_banner preference — "skip" suppresses the cosmetic banner.
	var sm := get_node_or_null("/root/SettingsManager")
	if sm and sm.get("phase_banner") == "skip":
		return
	if faction_id == "":
		faction_id = "blue" if new_phase == GameState.Phase.PLAYER else _active_faction_id()
	var faction_label: String = _faction_phase_label(faction_id)
	_label.text = "%s PHASE" % faction_label.to_upper()
	_panel.modulate = _faction_color(faction_id)
	_animate()


# Compute offscreen distances from current viewport so any resolution works.
func _offscreen_right() -> float:
	return get_viewport().get_visible_rect().size.x


func _offscreen_left() -> float:
	return -get_viewport().get_visible_rect().size.x


func _animate() -> void:
	_reset_after_animation()
	_panel.position.x = _offscreen_right()
	_panel.show()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_panel, "position:x", CENTER_X, SLIDE_DURATION)
	_tween.tween_interval(HOLD_DURATION)
	_tween.set_ease(Tween.EASE_IN)
	_tween.tween_property(_panel, "position:x", _offscreen_left(), SLIDE_DURATION)
	_tween.finished.connect(_reset_after_animation)


func _active_faction_id() -> String:
	var turn := get_node_or_null("/root/GameMap/TurnManager")
	if turn != null and turn.has_method("active_faction"):
		var fid: String = turn.active_faction()
		if fid != "":
			return fid
	return "red"


func _faction_phase_label(faction_id: String) -> String:
	var md: Resource = _current_map_data()
	if md != null:
		var faction: FactionData = md.get_faction(faction_id)
		if faction != null:
			return faction.get_phase_label()
	return "Unknown" if faction_id == "" else FactionData.default_phase_label(faction_id)


func _faction_color(faction_id: String) -> Color:
	var md: Resource = _current_map_data()
	if md != null:
		var faction: FactionData = md.get_faction(faction_id)
		if faction != null:
			return faction.color
	return Color(1, 1, 1, 1)


func _current_map_data() -> Resource:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return null
	return gs.map_data
