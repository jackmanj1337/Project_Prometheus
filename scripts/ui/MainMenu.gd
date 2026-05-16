extends Control
# Main menu: New Game opens the NewGameScreen overlay (gameplay-rule setup);
# Quit exits the application.

@onready var _new_game_btn: Button = $Panel/VBox/NewGameButton
@onready var _quit_btn: Button = $Panel/VBox/QuitButton
@onready var _new_game_screen: Control = $NewGameScreen


func _ready() -> void:
	_new_game_btn.pressed.connect(_on_new_game)
	_quit_btn.pressed.connect(_on_quit)
	_new_game_screen.back_pressed.connect(_on_new_game_back)
	_new_game_btn.grab_focus()


func _on_new_game() -> void:
	# NewGameScreen handles roster load + scene change once the player hits Start.
	_new_game_screen.open()


func _on_new_game_back() -> void:
	_new_game_btn.grab_focus()


func _on_quit() -> void:
	get_tree().quit()
