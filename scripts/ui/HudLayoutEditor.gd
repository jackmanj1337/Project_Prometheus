extends CanvasLayer
# In-map HUD layout editor (Display & Accessibility item 4). Overlays the live HUD
# with one draggable frame per movable panel plus a scale control, and persists the
# result to SettingsManager.hud_layout. Built entirely in code — the per-panel frames
# are dynamic, so there is no authored .tscn.
#
# Launched by SettingsScreen's "Edit HUD Layout" button with the live HUD (found via
# the "hud" group). Done saves; Cancel restores the layout captured at open(); Reset
# clears to the authored layout. The drag/scale interaction is mouse-driven and
# verified by playtest (as with AttackPreview positioning); open()/close() and the
# save/cancel paths are smoke-tested headless.

signal closed()

const _SCALE_STEP: float = 0.25

var _hud: Control = null
var _start_layout: Dictionary = {}      # snapshot for Cancel
var _selected_id: String = ""
var _handles: Dictionary = {}           # panel_id -> Panel (drag frame)
var _dragging: bool = false

var _scale_label: Label = null


func _init() -> void:
	layer = 128  # above the HUD's CanvasLayer so the editor sits on top


# Opens the editor over `hud`. Captures the current layout so Cancel can restore it.
func open(hud: Control) -> void:
	_hud = hud
	_start_layout = hud.current_layout()
	_build_toolbar()
	_build_handles()
	_refresh_handles()


func _build_toolbar() -> void:
	# Full-rect dimmer eats clicks that miss a handle so the map underneath is inert.
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var bar := HBoxContainer.new()
	bar.position = Vector2(8, 8)
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)

	var title := Label.new()
	title.text = "Edit HUD Layout — drag panels"
	bar.add_child(title)

	var minus := Button.new(); minus.text = "Scale −"; bar.add_child(minus)
	_scale_label = Label.new(); _scale_label.text = "—"; bar.add_child(_scale_label)
	var plus := Button.new(); plus.text = "Scale +"; bar.add_child(plus)
	var reset := Button.new(); reset.text = "Reset"; bar.add_child(reset)
	var done := Button.new(); done.text = "Done"; bar.add_child(done)
	var cancel := Button.new(); cancel.text = "Cancel"; bar.add_child(cancel)

	minus.pressed.connect(_bump_scale.bind(-_SCALE_STEP))
	plus.pressed.connect(_bump_scale.bind(_SCALE_STEP))
	reset.pressed.connect(_on_reset)
	done.pressed.connect(_on_done)
	cancel.pressed.connect(_on_cancel)


func _build_handles() -> void:
	for id in _hud.LAYOUT_PANEL_IDS:
		var panel: Control = _hud.get_layout_panel(id)
		if panel == null:
			continue
		var frame := Panel.new()
		frame.mouse_filter = Control.MOUSE_FILTER_STOP
		var lbl := Label.new()
		lbl.text = id
		lbl.position = Vector2(4, 2)
		frame.add_child(lbl)
		frame.gui_input.connect(_on_handle_input.bind(id))
		add_child(frame)
		_handles[id] = frame


# Positions each drag frame over its panel's current on-screen rect and tints the
# selected one. Re-run after every move/scale so the frame tracks the panel.
func _refresh_handles() -> void:
	for id in _handles:
		var panel: Control = _hud.get_layout_panel(id)
		var frame: Panel = _handles[id]
		if panel == null:
			continue
		var rect: Rect2 = panel.get_global_rect()
		frame.global_position = rect.position
		frame.size = rect.size
		frame.self_modulate = (Color(0.4, 0.8, 1.0, 0.55) if id == _selected_id
			else Color(1, 1, 1, 0.30))
	_update_scale_label()


func _on_handle_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_selected_id = id
			_dragging = true
			_refresh_handles()
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging and _selected_id == id:
		# event.relative is the screen-pixel delta since the last motion; accumulate
		# it onto the panel's current offset-from-base.
		var new_offset: Vector2 = _offset_of(id) + event.relative
		_hud.set_panel_layout(id, new_offset, _scale_of(id))
		_refresh_handles()


func _bump_scale(step: float) -> void:
	if _selected_id == "":
		return
	var new_scale: float = clampf(_scale_of(_selected_id) + step,
		_hud.MIN_PANEL_SCALE, _hud.MAX_PANEL_SCALE)
	_hud.set_panel_layout(_selected_id, _offset_of(_selected_id), new_scale)
	_refresh_handles()


func _update_scale_label() -> void:
	if _scale_label == null:
		return
	_scale_label.text = ("%.2fx" % _scale_of(_selected_id)) if _selected_id != "" else "—"


# Reads the live offset/scale of a panel from the HUD (offset-from-authored-base).
func _offset_of(id: String) -> Vector2:
	var entry: Variant = _hud.current_layout().get(id, {})
	return entry.get("offset", Vector2.ZERO) if entry is Dictionary else Vector2.ZERO


func _scale_of(id: String) -> float:
	var entry: Variant = _hud.current_layout().get(id, {})
	return float(entry.get("scale", 1.0)) if entry is Dictionary else 1.0


func _on_reset() -> void:
	_hud.reset_layout()
	_selected_id = ""
	_refresh_handles()


func _on_done() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null:
		sm.set("hud_layout", _hud.current_layout())
		sm.call("save")
	_close()


func _on_cancel() -> void:
	_hud.apply_layout(_start_layout)
	_close()


func _close() -> void:
	closed.emit()
	queue_free()
