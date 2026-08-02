extends Node

signal session_started(mode: StringName)
signal session_ended(submitted: bool, value: String)

const GRID_KEYBOARD_SCENE := preload("res://scenes/ui/text_entry/GridKeyboard.tscn")

var session := TextEntrySession.new()
var active_mode: StringName = &""
var _registry := TextEntryRegistry.new()
var _hardware := HardwareTextEntryPresenter.new()
var _overlay: TextEntryOverlay
var _target: LineEdit
var _host_viewport: Viewport
var _initial_text := ""
var _generation := 0


func _ready() -> void:
	session.name = "TextEntrySession"
	add_child(session)
	_hardware.name = "HardwareTextEntryPresenter"
	add_child(_hardware)
	_registry.register(&"hardware", func() -> Node: return HardwareTextEntryPresenter.new())
	_registry.register(&"grid", func() -> Node: return GridTextEntryPresenter.new())
	_hardware.character_entered.connect(session.insert)
	_hardware.action_invoked.connect(_on_action)
	session.text_changed.connect(_sync_target)
	session.submitted.connect(_on_submitted)
	session.cancelled.connect(_on_cancelled)
	set_process_input(false)


func begin(request: TextEntryRequest, requested_mode: StringName = &"auto") -> bool:
	if request == null or not is_instance_valid(request.target):
		return false
	if session.active:
		session.cancel()
	_target = request.target
	_initial_text = _target.text
	request.initial_text = _initial_text
	_generation += 1
	var generation := _generation
	active_mode = _registry.resolve(_configured_mode(requested_mode), _active_input_mode())
	match active_mode:
		&"grid":
			session.begin(request)
			_target.focus_exited.connect(_on_target_focus_exited)
			_host_viewport = request.host_viewport
			if _host_viewport == null:
				_host_viewport = _target.get_viewport()
			_host_viewport.gui_focus_changed.connect(_on_host_focus_changed)
			# FileDialog focus signals run inside native input dispatch. Building a
			# Control tree there caused the v0.6.0 Windows crash, so construction is
			# always deferred and guarded against a superseding request.
			_open_grid_deferred.call_deferred(request, generation)
		&"hardware":
			session.begin(request)
			_hardware.configure(request)
			_target.grab_focus()
			set_process_input(true)
		_:
			_reset()
			return false
	session_started.emit(active_mode)
	return true


func cancel() -> bool:
	return session.cancel()


func submit() -> bool:
	return session.submit()


func _input(event: InputEvent) -> void:
	if active_mode == &"hardware" and _hardware.handle(event):
		get_viewport().set_input_as_handled()


func _open_grid(request: TextEntryRequest) -> bool:
	var host := request.host_viewport
	if host == null and is_instance_valid(request.target):
		host = request.target.get_viewport()
	if host == null:
		return false
	_overlay = GRID_KEYBOARD_SCENE.instantiate() as TextEntryOverlay
	if _overlay == null:
		return false
	host.add_child(_overlay)
	if not _overlay.open(_target, request, TextEntryLayout.load_default_grid(), session):
		_overlay.queue_free()
		_overlay = null
		return false
	return true


func _open_grid_deferred(request: TextEntryRequest, generation: int) -> void:
	if generation != _generation or not session.active or session.request != request:
		return
	if not _open_grid(request):
		session.cancel()


func _on_target_focus_exited() -> void:
	_withdraw_if_focus_left.call_deferred(_generation)


func _on_host_focus_changed(_owner: Control) -> void:
	_withdraw_if_focus_left.call_deferred(_generation)


func _withdraw_if_focus_left(generation: int) -> void:
	if generation != _generation or not session.active:
		return
	var owner := (
		_target.get_viewport().gui_get_focus_owner() if is_instance_valid(_target) else null
	)
	if owner == _target:
		return
	if is_instance_valid(_overlay) and (owner == _overlay or _overlay.is_ancestor_of(owner)):
		return
	session.cancel()


func _active_input_mode() -> StringName:
	var modes := get_node_or_null("/root/InputModeManager")
	return StringName(str(modes.get("active_input_mode"))) if modes != null else &"mouse_keyboard"


func _configured_mode(requested_mode: StringName) -> StringName:
	if requested_mode != &"auto":
		return requested_mode
	var settings := get_node_or_null("/root/SettingsManager")
	return StringName(str(settings.get("text_entry_mode"))) if settings != null else &"auto"


func _sync_target(value: String) -> void:
	if not is_instance_valid(_target) or _target.text == value:
		return
	_target.text = value
	_target.caret_column = value.length()
	_target.text_changed.emit(value)


func _on_action(action: StringName) -> void:
	match action:
		&"backspace":
			session.backspace()
		&"submit":
			session.submit()
		&"cancel":
			session.cancel()


func _on_submitted(value: String) -> void:
	session_ended.emit(true, value)
	_reset()


func _on_cancelled() -> void:
	var value := session.text
	if (
		session.request != null
		and session.request.dismissal_policy == TextEntryRequest.DismissalPolicy.RESTORE_INITIAL
	):
		value = _initial_text
		_sync_target(value)
	session_ended.emit(false, value)
	_reset()


func _reset() -> void:
	_generation += 1
	set_process_input(false)
	_hardware.enabled = false
	if is_instance_valid(_target) and _target.focus_exited.is_connected(_on_target_focus_exited):
		_target.focus_exited.disconnect(_on_target_focus_exited)
	if (
		_host_viewport != null
		and _host_viewport.gui_focus_changed.is_connected(_on_host_focus_changed)
	):
		_host_viewport.gui_focus_changed.disconnect(_on_host_focus_changed)
	if is_instance_valid(_overlay):
		_overlay.release()
		_overlay.queue_free()
	_overlay = null
	_target = null
	_host_viewport = null
	_initial_text = ""
	active_mode = &""
