extends Node
# First scene. For MVP just transitions to MainMenu.
# In Phase 3+ this is where a splash screen or loading bar lives.

const BuildInfo = preload("res://scripts/shared/BuildInfo.gd")


func _ready() -> void:
	# Write the build stamp first so every godot.log opens with the build identity,
	# a fresh per-launch timestamp (proof the log was written this run), and the
	# resolved log location — in a self-contained build that path is next to the exe.
	for line in BuildInfo.stamp_lines():
		print(line)
	# Scene changes remove the current root, so defer until Godot finishes
	# attaching Boot to the tree. Changing synchronously here logs
	# "Parent node is busy adding/removing children" in exported builds.
	call_deferred("_open_main_menu")


func _open_main_menu() -> void:
	if ResourceLoader.exists("res://scenes/ui/MainMenu.tscn"):
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	else:
		push_error("Boot: MainMenu.tscn not found")
		get_tree().quit(1)
