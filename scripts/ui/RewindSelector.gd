class_name RewindSelector extends Control
# Compact retained-history picker shared by the map menu and defeat overlay.

signal rewind_selected(target_index: int, cost: int)
signal cancelled

const FocusNavigatorS = preload("res://scripts/shared/FocusNavigator.gd")

@onready var _choices: VBoxContainer = $Panel/VBox/Scroll/Choices
@onready var _cancel: Button = $Panel/VBox/Cancel
@onready var _scroll: ScrollContainer = $Panel/VBox/Scroll
var _focus_nav: RefCounted


func _ready() -> void:
	_focus_nav = FocusNavigatorS.new(self, _scroll)
	hide()
	_cancel.pressed.connect(_close)


func open(options: Array[Dictionary]) -> void:
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	var first_button: Button = null
	for option in options:
		var button := Button.new()
		button.text = String(option.get("label", "Rewind"))
		button.pressed.connect(
			func() -> void:
				hide()
				rewind_selected.emit(int(option["target_index"]), int(option["cost"]))
		)
		_choices.add_child(button)
		if first_button == null:
			first_button = button
	show()
	_focus_nav.clear()
	if first_button != null:
		first_button.call_deferred("grab_focus")
	else:
		_cancel.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		_close()
		get_viewport().set_input_as_handled()
	elif visible and _focus_nav.consume_direction(event):
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if visible:
		_focus_nav.poll(delta)


func _close() -> void:
	hide()
	cancelled.emit()
