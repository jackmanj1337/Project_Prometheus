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

signal closed

const _SCALE_STEP: float = 0.25

var _hud: Control = null
var _start_layout: Dictionary = {}  # snapshot for Cancel
var _selected_id: String = ""
var _handles: Dictionary = {}  # panel_id -> Panel (drag frame)
var _handle_labels: Dictionary = {}  # panel_id -> Label (id + sample text)
var _dragging: bool = false

var _scale_label: Label = null
# Scale −/+ are disabled until a panel is selected: they no-op without a
# selection, so a tester who clicks them first sees "nothing happens" (V053-06).
var _scale_minus: Button = null
var _scale_plus: Button = null
# EventBus gameplay-modal lock, held while open so MapCursor (which polls Input
# every frame and honours the lock) stops driving the map underneath (V053-05).
var _modal_lock_held: bool = false
# Guards _teardown so `closed` and the lock release fire exactly once no matter
# how the editor is torn down (button/key _close, or the _exit_tree safety net).
var _closed_emitted: bool = false

# Reserved height of the top toolbar strip. The strip is a MOUSE_FILTER_STOP band
# added after the drag frames, so a panel frame overlapping the toolbar can no
# longer steal clicks meant for the buttons (V053-06).
const _TOOLBAR_STRIP_HEIGHT: float = 48.0

# Distinct outline styleboxes (V020-12): a bright-red border on every editable
# panel, switched to yellow on the selected one — clearer than the old
# self_modulate tint, which only dimmed the frame's whole colour.
const _UNSELECTED_BORDER := Color(1, 0.25, 0.25, 1)  # bright red
const _SELECTED_BORDER := Color(1, 0.95, 0.2, 1)  # yellow
# Base font size for the in-frame sample text; scaled by each panel's scale so the
# tester can see how big that panel's text will render at the chosen scale.
const _SAMPLE_FONT_BASE := 16


func _init() -> void:
	layer = 128  # above the HUD's CanvasLayer so the editor sits on top


# The editor is a hard modal: while it is open it swallows every non-mouse input so
# the map cursor / menus underneath can't be driven — even if the Settings screen that
# launched it is dismissed out from under it (V021-02 input leak). Mouse events fall
# through to the full-rect dimmer + drag frames. The `cancel` action closes the editor
# (restoring the pre-edit layout, mirroring the Cancel button) and is consumed here so
# it never reaches the Settings screen beneath. _input runs before _unhandled_input, so
# this reliably preempts MapCursor / ModalScreen, which read cancel via _unhandled_input.
func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		return
	if event.is_action_pressed("cancel"):
		_on_cancel()
	get_viewport().set_input_as_handled()


# Opens the editor over `hud`. Captures the current layout so Cancel can restore it.
func open(hud: Control) -> void:
	_hud = hud
	_start_layout = hud.current_layout()
	_acquire_modal_lock()
	# Order matters: dimmer (bottom) → drag frames → toolbar (top). Building the
	# toolbar last puts its reserved strip above the frames so overlapping frames
	# can't steal toolbar clicks (V053-06).
	_build_dimmer()
	_build_handles()
	_build_toolbar()
	_refresh_handles()


func _build_dimmer() -> void:
	# Full-rect dimmer eats clicks that miss a handle so the map underneath is inert.
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)


func _build_toolbar() -> void:
	# Reserved top strip: a full-width MOUSE_FILTER_STOP band added after the drag
	# frames so a panel frame overlapping the toolbar cannot win clicks meant for
	# the buttons (V053-06). The bar and its buttons sit on top of it.
	var strip := ColorRect.new()
	strip.color = Color(0, 0, 0, 0.55)
	strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	strip.custom_minimum_size = Vector2(0, _TOOLBAR_STRIP_HEIGHT)
	strip.size.y = _TOOLBAR_STRIP_HEIGHT
	strip.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(strip)

	var bar := HBoxContainer.new()
	bar.position = Vector2(8, 8)
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)

	var title := Label.new()
	title.text = "Edit HUD Layout — drag panels"
	bar.add_child(title)

	_scale_minus = Button.new()
	_scale_minus.text = "Scale Panel −"
	bar.add_child(_scale_minus)
	_scale_label = Label.new()
	_scale_label.text = "—"
	bar.add_child(_scale_label)
	_scale_plus = Button.new()
	_scale_plus.text = "Scale Panel +"
	bar.add_child(_scale_plus)
	var reset := Button.new()
	reset.text = "Reset"
	bar.add_child(reset)
	var done := Button.new()
	done.text = "Done"
	bar.add_child(done)
	var cancel := Button.new()
	cancel.text = "Cancel"
	bar.add_child(cancel)

	_scale_minus.pressed.connect(_bump_scale.bind(-_SCALE_STEP))
	_scale_plus.pressed.connect(_bump_scale.bind(_SCALE_STEP))
	reset.pressed.connect(_on_reset)
	done.pressed.connect(_on_done)
	cancel.pressed.connect(_on_cancel)
	_update_scale_buttons()


func _build_handles() -> void:
	for id in _hud.LAYOUT_PANEL_IDS:
		var panel: Control = _hud.get_layout_panel(id)
		if panel == null:
			continue
		var frame := Panel.new()
		frame.mouse_filter = Control.MOUSE_FILTER_STOP
		# V021-03: clip children to the frame rect so the sample text can never spill
		# outside the panel it describes (the tester saw it escape the bounds).
		frame.clip_contents = true
		var lbl := Label.new()
		# Editor-only sample text: the panel id plus a dummy readout so the tester
		# can judge font size at the current scale. This label lives on the editor
		# frame, never on the live HUD, so it can't leak into gameplay.
		lbl.text = "%s\nSample 123" % id
		lbl.position = Vector2(4, 2)
		frame.add_child(lbl)
		frame.gui_input.connect(_on_handle_input.bind(id))
		add_child(frame)
		_handles[id] = frame
		_handle_labels[id] = lbl


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
		var style: StyleBoxFlat = _selected_style() if id == _selected_id else _unselected_style()
		frame.add_theme_stylebox_override("panel", style)
		# Sample text grows/shrinks with the panel scale so the chosen size is visible.
		var lbl: Label = _handle_labels.get(id)
		if lbl != null:
			lbl.add_theme_font_size_override(
				"font_size", int(round(_SAMPLE_FONT_BASE * _scale_of(id)))
			)
			# V021-03: bound the label to the frame (minus its 4,2 inset) and let it
			# wrap, so oversized sample text stays contained rather than overflowing.
			lbl.size = (frame.size - Vector2(8, 4)).max(Vector2.ZERO)
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_update_scale_label()


# Two cached outline styleboxes (selected/unselected), built once and swapped by
# reference — _refresh_handles runs every drag-move, so re-allocating a StyleBoxFlat
# per panel per frame was needless churn. Translucent fill so the panel underneath
# shows through, with a thick coloured border that reads as the editable edge.
var _style_selected: StyleBoxFlat = null
var _style_unselected: StyleBoxFlat = null


func _selected_style() -> StyleBoxFlat:
	if _style_selected == null:
		_style_selected = _make_frame_style(_SELECTED_BORDER)
	return _style_selected


func _unselected_style() -> StyleBoxFlat:
	if _style_unselected == null:
		_style_unselected = _make_frame_style(_UNSELECTED_BORDER)
	return _style_unselected


func _make_frame_style(border_color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.15)
	sb.border_color = border_color
	sb.set_border_width_all(3)
	return sb


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
	var new_scale: float = clampf(
		_scale_of(_selected_id) + step, _hud.MIN_PANEL_SCALE, _hud.MAX_PANEL_SCALE
	)
	_hud.set_panel_layout(_selected_id, _offset_of(_selected_id), new_scale)
	_refresh_handles()


func _update_scale_label() -> void:
	if _scale_label == null:
		return
	_scale_label.text = ("%.2fx" % _scale_of(_selected_id)) if _selected_id != "" else "—"
	_update_scale_buttons()


# Scale −/+ act on the selected panel, so they are dead without a selection.
# Disable them until one exists rather than silently no-opping (V053-06).
func _update_scale_buttons() -> void:
	var enabled := _selected_id != ""
	if _scale_minus != null:
		_scale_minus.disabled = not enabled
	if _scale_plus != null:
		_scale_plus.disabled = not enabled


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
	_teardown()
	queue_free()


func _exit_tree() -> void:
	# Safety net: if the editor leaves the tree by any path other than _close()
	# (scene teardown, an external free), still run teardown so the modal lock is
	# released AND `closed` fires — otherwise a still-open SettingsScreen keeps its
	# focus-repeat poll disabled forever, since it re-enables only on `closed`.
	_teardown()


# Idempotent teardown: releases the gameplay-modal lock and emits `closed` exactly
# once, whichever path frees the editor. `closed` names the fact "the editor is
# gone", so every teardown must honour it, not just the button/key path (_close).
func _teardown() -> void:
	if _closed_emitted:
		return
	_closed_emitted = true
	_release_modal_lock()
	closed.emit()


# Mirrors GameOverScreen's modal lock: while held, MapCursor (which honours
# EventBus.is_gameplay_modal_locked via _gameplay_modal_locked) stops polling
# movement, so WASD/arrows no longer drive the cursor under the editor (V053-05).
func _acquire_modal_lock() -> void:
	if _modal_lock_held:
		return
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_method("acquire_gameplay_modal"):
		bus.call("acquire_gameplay_modal", self)
		_modal_lock_held = true


func _release_modal_lock() -> void:
	if not _modal_lock_held:
		return
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_method("release_gameplay_modal"):
		bus.call("release_gameplay_modal", self)
	_modal_lock_held = false
