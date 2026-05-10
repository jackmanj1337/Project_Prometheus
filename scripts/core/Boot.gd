extends Node
# First scene. For MVP just transitions to MainMenu.
# In Phase 3+ this is where a splash screen or loading bar lives.

func _ready() -> void:
	# MainMenu not yet implemented; change this path once Milestone 5 scene exists
	if ResourceLoader.exists("res://scenes/ui/MainMenu.tscn"):
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	else:
		print("Boot: project loaded OK — MainMenu not yet built (Milestone 5)")
