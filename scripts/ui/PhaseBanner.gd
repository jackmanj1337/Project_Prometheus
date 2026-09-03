extends Control
# Cosmetic phase-change banner: slides in from the right, holds, slides out left.
# GDD spec: slide-in 0.3s, hold 0.8s, slide-out 0.3s.

@onready var _panel: Panel = $Panel
@onready var _label: Label = $Panel/Label

const SLIDE_DURATION: float = 0.3
const HOLD_DURATION: float = 0.8
const CENTER_X: float = 0.0

# [V0715-01] Opt-in diagnostics for the NATIVE resumed-load reproduction.
#
# The v0.7.15 return found the opening blue banner still on screen for a whole
# player phase after loading a battle. The width half of that defect is proven;
# this half is NOT -- exact-export Playwright could not load the returned
# suspend in a clean profile, so nobody has yet observed the tween while it
# fails. The row therefore requires an instrumented native run BEFORE the
# lifecycle is patched, because the plausible mechanism (an ordinary phase
# transition animated through a scene that is still restoring) and the
# plausible fix do not follow from each other.
#
# Set PROMETHEUS_BANNER_TRACE=1 to print one line per phase signal and per
# animation step. Inert otherwise, so this costs a released build nothing.
#
# DELETE THIS once V0715-01 lands. It is scaffolding for one measurement, not a
# telemetry surface -- leaving it would be the third thing in this file that
# outlived its reason.
static var _trace_enabled: int = -1


static func _tracing() -> bool:
	if _trace_enabled < 0:
		_trace_enabled = 1 if OS.get_environment("PROMETHEUS_BANNER_TRACE") == "1" else 0
	return _trace_enabled == 1


func _trace(event: String) -> void:
	if not _tracing():
		return
	var viewport := get_viewport()
	var visible_rect: Rect2 = viewport.get_visible_rect() if viewport else Rect2()
	print(
		(
			(
				"BANNER_TRACE %s | panel_visible=%s panel_x=%.1f panel_w=%.1f "
				+ "visible_rect=%.1fx%.1f window=%s stretch_scale=%s tree_paused=%s"
			)
			% [
				event,
				str(_panel != null and _panel.is_visible_in_tree()),
				_panel.position.x if _panel else -1.0,
				_panel.size.x if _panel else -1.0,
				visible_rect.size.x,
				visible_rect.size.y,
				str(DisplayServer.window_get_size()),
				str(get_tree().root.content_scale_factor if get_tree() else 0.0),
				str(get_tree().paused if get_tree() else false),
			]
		)
	)


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
	_trace("phase_changed:%d:%s" % [new_phase, faction_id])
	_animate()


# Compute offscreen distances from current viewport so any resolution works.
func _offscreen_right() -> float:
	return get_viewport().get_visible_rect().size.x


func _offscreen_left() -> float:
	return -get_viewport().get_visible_rect().size.x


func _animate() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_panel.position.x = _offscreen_right()
	_trace("animate_start")
	# Slide in
	tween.tween_property(_panel, "position:x", CENTER_X, SLIDE_DURATION)
	# Hold
	tween.tween_interval(HOLD_DURATION)
	# Slide out
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(_panel, "position:x", _offscreen_left(), SLIDE_DURATION)
	if _tracing():
		# Deliberately the ONLY finished handler: adding a real one would be the
		# lifecycle fix, and that must follow the measurement, not precede it.
		tween.finished.connect(func() -> void: _trace("tween_finished"))


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
