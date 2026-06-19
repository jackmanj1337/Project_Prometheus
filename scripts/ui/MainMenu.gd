extends Control
# Main menu: New Game opens the NewGameScreen overlay (gameplay-rule setup);
# Settings opens the SettingsScreen overlay (also reachable via the open_settings
# keybinding); Quit exits the application.

@onready var _new_game_btn: Button = $Panel/VBox/NewGameButton
@onready var _settings_btn: Button = $Panel/VBox/SettingsButton
@onready var _quit_btn: Button = $Panel/VBox/QuitButton
@onready var _new_game_screen: Control = $NewGameScreen
@onready var _settings_screen: Control = $SettingsScreen

const MenuScale = preload("res://scripts/ui/MenuScale.gd")


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	_new_game_btn.pressed.connect(_on_new_game)
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)
	_new_game_screen.back_pressed.connect(_on_new_game_back)
	_settings_screen.back_pressed.connect(_on_settings_back)
	_apply_menu_scale_from_settings()
	_new_game_btn.grab_focus()


func apply_menu_scale(factor: float) -> void:
	MenuScale.apply_to($Panel, factor, true)


func _apply_menu_scale_from_settings() -> void:
	apply_menu_scale(MenuScale.factor_from_settings(self))


func _on_new_game() -> void:
	# NewGameScreen handles roster load + scene change once the player hits Start.
	_new_game_screen.open()


func _on_new_game_back() -> void:
	_new_game_btn.grab_focus()


func _on_settings() -> void:
	_settings_screen.open()


func _on_settings_back() -> void:
	_settings_btn.grab_focus()


# The open_settings keybinding opens the settings screen from the main menu.
# Ignored while either overlay is already showing — those handle their own input.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_settings") \
			and not _settings_screen.visible and not _new_game_screen.visible:
		_on_settings()
		get_viewport().set_input_as_handled()


func _on_quit() -> void:
	get_tree().quit()
