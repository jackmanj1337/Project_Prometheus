extends Control
# Main menu: New Game → loads default roster → GameMap.
# Quit exits the application. Settings placeholder for Phase 3.

@onready var _new_game_btn: Button = $Panel/VBox/NewGameButton
@onready var _quit_btn: Button = $Panel/VBox/QuitButton


func _ready() -> void:
	_new_game_btn.pressed.connect(_on_new_game)
	_quit_btn.pressed.connect(_on_quit)
	_new_game_btn.grab_focus()


func _on_new_game() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.load_default_roster()
	get_tree().change_scene_to_file("res://scenes/core/GameMap.tscn")


func _on_quit() -> void:
	get_tree().quit()
