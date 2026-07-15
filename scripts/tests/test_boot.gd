extends SceneTree
# Verifies the exported entry scene defers its transition until Boot is fully
# attached, then opens MainMenu without the busy-parent startup error.


func _init() -> void:
	print("=== Boot Test ===")
	var packed := load("res://scenes/core/Boot.tscn")
	if packed == null:
		print("FAIL could not load Boot.tscn")
		quit(1)
		return

	var boot: Node = packed.instantiate()
	root.add_child(boot)
	current_scene = boot
	await process_frame
	await process_frame

	if current_scene != null and current_scene.name == "MainMenu":
		print("OK  Boot defers and opens MainMenu")
		print("\n=== Results: 1 passed, 0 failed ===")
		quit(0)
	else:
		print("FAIL Boot did not open MainMenu")
		print("\n=== Results: 0 passed, 1 failed ===")
		quit(1)
