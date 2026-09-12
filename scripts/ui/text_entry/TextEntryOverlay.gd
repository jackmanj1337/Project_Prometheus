class_name TextEntryOverlay
extends PanelContainer

signal submitted(value: String)
signal cancelled
signal input_received(event: InputEvent)

var _session: TextEntrySession
var _presenter: GridTextEntryPresenter
var _owns_session := false
var _target: LineEdit
var _layers: Array[String] = []
var _layer_index := 0
var _editor: LineEdit
var _prompt: Label
var _validation: Label
var _cancel: Button
var _confirm: Button
var _restore_focus: Control
var _mode: StringName = &""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_presenter = get_node_or_null("GridTextEntryPresenter") as GridTextEntryPresenter
	if _presenter == null:
		_presenter = GridTextEntryPresenter.new()
		_presenter.name = "GridTextEntryPresenter"
		add_child(_presenter)
	_build_surface()
	hide()


func open(
	target: LineEdit,
	request: TextEntryRequest,
	layout: TextEntryLayout,
	owner_session: TextEntrySession = null,
	mode: StringName = &"grid"
) -> bool:
	if target == null or request == null or layout == null:
		return false
	_bind_session(owner_session)
	_target = target
	_restore_focus = target
	_mode = mode
	request.initial_text = target.text
	if not _session.active or _session.request != request:
		_session.begin(request)
	if mode == &"grid" and not _presenter.configure(layout, request):
		_session.finish()
		return false
	_layers.clear()
	if mode == &"grid":
		_layers.assign(layout.layers.keys())
		_layer_index = _layers.find(_presenter.active_layer)
		if _layer_index < 0:
			_layer_index = 0
			_presenter.set_layer(_layers[0])
	_presenter.visible = mode == &"grid"
	_prompt.text = request.prompt
	_editor.placeholder_text = request.placeholder
	_cancel.text = request.cancel_label
	_confirm.text = request.confirm_label
	_sync_target(_session.text)
	_on_validation_changed(_session.validation_code)
	show()
	if mode == &"hardware":
		_editor.grab_focus()
		_editor.select_all()
		_session.set_selection(_session.text.length(), 0)
	return true


func _build_surface() -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.0, 0.0, 0.0, 0.65)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	var panel := VBoxContainer.new()
	panel.name = "Surface"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-260, -150)
	panel.size = Vector2(520, 300)
	add_child(panel)
	_prompt = Label.new()
	_prompt.name = "Prompt"
	panel.add_child(_prompt)
	_editor = LineEdit.new()
	_editor.name = "Value"
	_editor.editable = false
	_editor.focus_mode = Control.FOCUS_ALL
	_editor.gui_input.connect(_on_editor_gui_input)
	panel.add_child(_editor)
	_validation = Label.new()
	_validation.name = "Validation"
	panel.add_child(_validation)
	_presenter.reparent(panel)
	_presenter.custom_minimum_size = Vector2(500, 180)
	var actions := HBoxContainer.new()
	panel.add_child(actions)
	_cancel = Button.new()
	_cancel.name = "Cancel"
	_cancel.pressed.connect(func() -> void: _session.cancel())
	actions.add_child(_cancel)
	_confirm = Button.new()
	_confirm.name = "Confirm"
	_confirm.pressed.connect(func() -> void: _session.submit())
	actions.add_child(_confirm)


func _bind_session(owner_session: TextEntrySession) -> void:
	if _session != null:
		_disconnect_session()
	_owns_session = owner_session == null
	_session = owner_session if owner_session != null else TextEntrySession.new()
	if _owns_session:
		_session.name = "TextEntrySession"
		add_child(_session)
	_presenter.character_entered.connect(_session.insert)
	_presenter.action_invoked.connect(_on_action)
	_session.text_changed.connect(_sync_target)
	_session.selection_changed.connect(_sync_selection)
	_session.validation_changed.connect(_on_validation_changed)
	_session.submitted.connect(_on_submitted)
	_session.cancelled.connect(_on_cancelled)


func _disconnect_session() -> void:
	if _presenter.character_entered.is_connected(_session.insert):
		_presenter.character_entered.disconnect(_session.insert)
	if _presenter.action_invoked.is_connected(_on_action):
		_presenter.action_invoked.disconnect(_on_action)
	if _session.text_changed.is_connected(_sync_target):
		_session.text_changed.disconnect(_sync_target)
	if _session.selection_changed.is_connected(_sync_selection):
		_session.selection_changed.disconnect(_sync_selection)
	if _session.validation_changed.is_connected(_on_validation_changed):
		_session.validation_changed.disconnect(_on_validation_changed)
	if _session.submitted.is_connected(_on_submitted):
		_session.submitted.disconnect(_on_submitted)
	if _session.cancelled.is_connected(_on_cancelled):
		_session.cancelled.disconnect(_on_cancelled)
	if _owns_session:
		_session.queue_free()


func close() -> void:
	_session.finish()
	hide()


func release() -> void:
	if _session != null:
		_session.finish()
		_disconnect_session()
		_session = null
	hide()
	if is_instance_valid(_restore_focus) and _restore_focus.is_visible_in_tree():
		_restore_focus.grab_focus()
	_restore_focus = null
	_mode = &""


func _sync_target(value: String) -> void:
	if _target == null or _target.text == value:
		return
	_target.text = value
	_target.caret_column = value.length()
	# Assigning LineEdit.text does not emit text_changed. Callers that listen on
	# the LineEdit rather than on this overlay would otherwise never observe grid
	# input, so mirror the signal the target would have emitted for typed text.
	_target.text_changed.emit(value)
	_editor.text = value


func _sync_selection(caret: int, anchor: int) -> void:
	_editor.caret_column = caret
	if caret != anchor:
		_editor.select(mini(caret, anchor), maxi(caret, anchor))
	else:
		_editor.deselect()


func _on_validation_changed(code: StringName) -> void:
	_validation.text = str(code)
	# availability-todo: AVAILABILITY-REASON-REMEDIATION-2026-08-21 — reason is in _validation.text, which focus never announces
	_confirm.disabled = not code.is_empty()


func focus_next() -> void:
	var controls: Array[Control] = [_editor, _cancel, _confirm]
	var current := get_viewport().gui_get_focus_owner()
	var index := controls.find(current)
	controls[wrapi(index + 1, 0, controls.size())].grab_focus()


func _on_editor_gui_input(event: InputEvent) -> void:
	if _mode != &"hardware":
		return
	input_received.emit(event)
	_editor.accept_event()


func _on_action(action: StringName) -> void:
	match action:
		&"backspace":
			_session.backspace()
		&"submit":
			_session.submit()
		&"cancel":
			_session.cancel()
		&"switch_layer":
			if not _layers.is_empty():
				_layer_index = (_layer_index + 1) % _layers.size()
				_presenter.set_layer(_layers[_layer_index])


func _on_submitted(value: String) -> void:
	hide()
	submitted.emit(value)


func _on_cancelled() -> void:
	hide()
	cancelled.emit()
