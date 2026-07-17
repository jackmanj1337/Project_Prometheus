class_name RewindSelector extends Control
# Compact retained-history picker shared by the map menu and defeat overlay.

signal rewind_selected(target_index: int, cost: int)
signal cancelled

@onready var _choices: VBoxContainer = $Panel/VBox/Choices
@onready var _cancel: Button = $Panel/VBox/Cancel


func _ready() -> void:
	hide()
	_cancel.pressed.connect(_close)


func open(options: Array[Dictionary]) -> void:
	for child in _choices.get_children():
		child.queue_free()
	for option in options:
		var button := Button.new()
		button.text = String(option.get("label", "Rewind"))
		button.pressed.connect(
			func() -> void:
				hide()
				rewind_selected.emit(int(option["target_index"]), int(option["cost"]))
		)
		_choices.add_child(button)
	show()
	if _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus()
	else:
		_cancel.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _close() -> void:
	hide()
	cancelled.emit()
