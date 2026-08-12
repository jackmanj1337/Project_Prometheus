extends CanvasLayer
# Minimal dedicated-touch overlay. Buttons emit the same InputMap actions as physical
# devices so existing menu/modal ownership remains authoritative.

const BUTTON_SIZE := Vector2(104.0, 52.0)

var _root: Control
var _left: VBoxContainer
var _right: VBoxContainer


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_left = _make_stack(Control.PRESET_BOTTOM_LEFT)
	_right = _make_stack(Control.PRESET_BOTTOM_RIGHT)
	_add_action_button(_left, "Menu", "open_menu")
	_add_action_button(_left, "Info", "inspect_unit")
	_add_action_button(_left, "More", "more_info")
	_add_action_button(_right, "Back", "cancel")
	_apply_safe_area()
	visible = OS.has_feature("mobile")


func _input(event: InputEvent) -> void:
	# Web builds do not carry Godot's mobile feature, so reveal the controls on the
	# first genuine touch. Mouse-only desktop players keep an unobstructed canvas.
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		visible = true


func _make_stack(preset: int) -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(preset)
	stack.add_theme_constant_override("separation", 8)
	_root.add_child(stack)
	return stack


func _add_action_button(parent: VBoxContainer, label: String, action: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = BUTTON_SIZE
	button.modulate.a = 0.82
	button.focus_mode = Control.FOCUS_NONE
	button.button_down.connect(_emit_action.bind(action, true))
	button.button_up.connect(_emit_action.bind(action, false))
	parent.add_child(button)


func _emit_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _apply_safe_area() -> void:
	var safe := Vector4i.ZERO
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("get_safe_area_insets"):
		safe = settings.call("get_safe_area_insets")
	_left.offset_left = 12.0 + safe.x
	_left.offset_bottom = -12.0 - safe.w
	_right.offset_right = -12.0 - safe.z
	_right.offset_bottom = -12.0 - safe.w
