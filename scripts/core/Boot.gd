extends Node
# First scene. For MVP just transitions to MainMenu.
# In Phase 3+ this is where a splash screen or loading bar lives.

const BuildInfo = preload("res://scripts/shared/BuildInfo.gd")


func _ready() -> void:
	# Write the build stamp first so every godot.log opens with the build identity,
	# a fresh per-launch timestamp (proof the log was written this run), and the
	# resolved log location — in an exported build that path is the OS user-data dir.
	for line in BuildInfo.stamp_lines():
		print(line)
	for line in BuildInfo.runtime_environment_lines():
		print(line)
	# The diagnostics session header goes out here, not from DiagnosticsLog._ready():
	# that autoload is registered first so every later one can record during its own
	# _ready(), so at its _ready() the settings, content and RNG services it must
	# report do not exist yet. Boot is the first code that runs with the whole
	# autoload list up.
	var diagnostics := get_node_or_null("/root/DiagnosticsLog")
	if diagnostics != null:
		diagnostics.write_session_header()
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
