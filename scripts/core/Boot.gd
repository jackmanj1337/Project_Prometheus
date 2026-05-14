extends Node
# First scene. For MVP just transitions to MainMenu.
# In Phase 3+ this is where a splash screen or loading bar lives.

func _ready() -> void:
	if ResourceLoader.exists("res://scenes/ui/MainMenu.tscn"):
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	else:
		push_error("Boot: MainMenu.tscn not found")
		get_tree().quit(1)
