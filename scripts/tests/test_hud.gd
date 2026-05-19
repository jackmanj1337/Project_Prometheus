extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_hud.gd
# Verifies HUD.tscn instantiates and the debug-mode banner — the red "DEBUG MODE"
# label — toggles with the debug-build flag via _apply_debug_banner().

func _init() -> void:
	print("=== HUD Test ===")
	var passed := 0
	var failed := 0

	var packed := load("res://scenes/ui/HUD.tscn")
	if packed == null:
		print("FAIL could not load HUD.tscn"); quit(1); return
	var hud: Control = packed.instantiate()
	root.add_child(hud)
	await process_frame

	# The debug-mode banner label must exist.
	var label: Label = hud.get_node_or_null("DebugLabel")
	if label != null:
		print("OK  DebugLabel node present"); passed += 1
	else:
		print("FAIL no DebugLabel node"); failed += 1

	# _apply_debug_banner(true) shows the banner; (false) hides it.
	if label != null:
		hud._apply_debug_banner(true)
		if label.visible:
			print("OK  banner shown when debug active"); passed += 1
		else:
			print("FAIL banner hidden when debug active"); failed += 1
		hud._apply_debug_banner(false)
		if not label.visible:
			print("OK  banner hidden when debug inactive"); passed += 1
		else:
			print("FAIL banner shown when debug inactive"); failed += 1

	hud.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
