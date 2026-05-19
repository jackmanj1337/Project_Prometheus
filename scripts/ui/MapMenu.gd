extends Control
# Pause-style map menu: End Turn, Settings, Close.
# Opens on open_menu action; closes on cancel or after a selection.

signal end_turn_requested()
signal settings_requested()
signal menu_closed()

@onready var _panel: PanelContainer = $Panel
@onready var _end_turn_btn: Button = $Panel/VBox/EndTurnButton
@onready var _settings_btn: Button = $Panel/VBox/SettingsButton
@onready var _close_btn: Button = $Panel/VBox/CloseButton


func _ready() -> void:
	hide()
	_end_turn_btn.pressed.connect(_on_end_turn)
	_settings_btn.pressed.connect(_on_settings)
	_close_btn.pressed.connect(_on_close)


func open() -> void:
	show()
	_end_turn_btn.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("open_menu"):
		_on_close()
		get_viewport().set_input_as_handled()


func _on_end_turn() -> void:
	hide()
	end_turn_requested.emit()
	menu_closed.emit()


# Hides the menu and asks for the settings overlay. Deliberately does NOT emit
# menu_closed — that would unlock the cursor while Settings is still open.
func _on_settings() -> void:
	hide()
	settings_requested.emit()


func _on_close() -> void:
	hide()
	menu_closed.emit()
