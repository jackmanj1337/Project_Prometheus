class_name TextEntryOverlay
extends PanelContainer

signal submitted(value: String)
signal cancelled

var _session := TextEntrySession.new()
var _presenter := GridTextEntryPresenter.new()
var _target: LineEdit
var _layers: Array[String] = []
var _layer_index := 0


func _ready() -> void:
	name = "TextEntryOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	custom_minimum_size.y = 280.0
	focus_mode = Control.FOCUS_ALL
	add_child(_session)
	add_child(_presenter)
	_presenter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_presenter.character_entered.connect(_session.insert)
	_presenter.action_invoked.connect(_on_action)
	_session.text_changed.connect(_sync_target)
	_session.submitted.connect(_on_submitted)
	_session.cancelled.connect(_on_cancelled)
	hide()


func open(target: LineEdit, request: TextEntryRequest, layout: TextEntryLayout) -> bool:
	if target == null or request == null or layout == null:
		return false
	_target = target
	request.initial_text = target.text
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


func close() -> void:
	_session.finish()
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
