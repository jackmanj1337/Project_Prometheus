class_name TextEntryOverlay
extends PanelContainer

signal submitted(value: String)
signal cancelled

var _session: TextEntrySession
var _presenter: GridTextEntryPresenter
var _owns_session := false
var _target: LineEdit
var _layers: Array[String] = []
var _layer_index := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	custom_minimum_size.y = 280.0
	focus_mode = Control.FOCUS_ALL
	_presenter = get_node_or_null("GridTextEntryPresenter") as GridTextEntryPresenter
	if _presenter == null:
		_presenter = GridTextEntryPresenter.new()
		_presenter.name = "GridTextEntryPresenter"
		add_child(_presenter)
	_presenter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()


func open(
	target: LineEdit,
	request: TextEntryRequest,
	layout: TextEntryLayout,
	owner_session: TextEntrySession = null
) -> bool:
	if target == null or request == null or layout == null:
		return false
	_bind_session(owner_session)
	_target = target
	request.initial_text = target.text
	if not _session.active or _session.request != request:
		_session.begin(request)
	if not _presenter.configure(layout, request):
		_session.finish()
		return false
	_layers.assign(layout.layers.keys())
	_layer_index = _layers.find(_presenter.active_layer)
	if _layer_index < 0:
		_layer_index = 0
		_presenter.set_layer(_layers[0])
	show()
	grab_focus()
	return true


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
	_session.submitted.connect(_on_submitted)
	_session.cancelled.connect(_on_cancelled)


func _disconnect_session() -> void:
	if _presenter.character_entered.is_connected(_session.insert):
		_presenter.character_entered.disconnect(_session.insert)
	if _presenter.action_invoked.is_connected(_on_action):
		_presenter.action_invoked.disconnect(_on_action)
	if _session.text_changed.is_connected(_sync_target):
		_session.text_changed.disconnect(_sync_target)
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


func _sync_target(value: String) -> void:
	if _target == null or _target.text == value:
		return
	_target.text = value
	_target.caret_column = value.length()
	# Assigning LineEdit.text does not emit text_changed. Callers that listen on
	# the LineEdit rather than on this overlay would otherwise never observe grid
	# input, so mirror the signal the target would have emitted for typed text.
	_target.text_changed.emit(value)


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
