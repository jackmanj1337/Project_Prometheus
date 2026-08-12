extends Control
# Cosmetic phase-change banner: slides in from the right, holds, slides out left.
# GDD spec: slide-in 0.3s, hold 0.8s, slide-out 0.3s.

@onready var _panel: Panel = $Panel
@onready var _label: Label = $Panel/Label

const SLIDE_DURATION: float = 0.3
const HOLD_DURATION: float = 0.8
const CENTER_X: float = 0.0


func _ready() -> void:
	_sync_panel_width()
	get_viewport().size_changed.connect(_sync_panel_width)
	_panel.position.x = _offscreen_right()
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.phase_changed.connect(_on_phase_changed)


# [V070-09] The Panel shipped with a hard-coded 1280 px width (layout_mode 0, fixed
# offsets 0..1280), so at any wider logical viewport the banner stopped short of the
# edge — the v0.7.0 return's "the phase banner does not always go across the entire
# screen at 2x viewport". It read as "not always" rather than "never" because the
# slide distances below were already viewport-derived while the width was not.
#
# The width is derived here rather than anchored in the scene: the Panel has to stay
# free-positioned so the slide tween can drive position.x, and anchors would fight it.
func _sync_panel_width() -> void:
	if _panel == null:
		return
	_panel.size.x = get_viewport().get_visible_rect().size.x


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
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_panel.position.x = _offscreen_right()
	# Slide in
	tween.tween_property(_panel, "position:x", CENTER_X, SLIDE_DURATION)
	# Hold
	tween.tween_interval(HOLD_DURATION)
	# Slide out
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(_panel, "position:x", _offscreen_left(), SLIDE_DURATION)


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
