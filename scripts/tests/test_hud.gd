extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_hud.gd
# Verifies HUD.tscn instantiates and the debug-mode banner — the red "DEBUG MODE"
# label — toggles with the debug-build flag via _apply_debug_banner(), and that
# the text lists the active debug aids when any are flipped on.

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

	# _apply_debug_banner(true, []) shows the banner with the base text.
	# Typed locals — _apply_debug_banner's `active_aids` is Array[String], and
	# an untyped `[]` literal won't satisfy that typed parameter.
	if label != null:
		var no_aids: Array[String] = []
		var one_aid: Array[String] = ["force-levelup"]
		var two_aids: Array[String] = ["force-levelup", "growth-boost"]

		hud._apply_debug_banner(true, no_aids)
		if label.visible and label.text == "● DEBUG MODE":
			print("OK  banner shown with base text when no aids active"); passed += 1
		else:
			print("FAIL base banner: visible=%s text=%q" % [label.visible, label.text])
			failed += 1

		# _apply_debug_banner(true, [...]) lists each active aid by name.
		hud._apply_debug_banner(true, one_aid)
		if label.visible and label.text == "● DEBUG MODE — force-levelup":
			print("OK  banner lists a single active aid"); passed += 1
		else:
			print("FAIL one-aid banner: text=%q" % label.text); failed += 1

		hud._apply_debug_banner(true, two_aids)
		if label.visible and label.text == "● DEBUG MODE — force-levelup, growth-boost":
			print("OK  banner joins multiple active aids"); passed += 1
		else:
			print("FAIL multi-aid banner: text=%q" % label.text); failed += 1

		# is_debug=false hides the banner AND clears the text — the strict
		# invariant prevents a stale aid list from sitting under the hidden label.
		hud._apply_debug_banner(false, one_aid)
		if not label.visible and label.text == "":
			print("OK  banner hidden and text cleared when debug inactive"); passed += 1
		else:
			print("FAIL hide path: visible=%s text=%q" % [label.visible, label.text])
			failed += 1

	# Flipping a GameState debug flag must re-emit through EventBus and refresh
	# the banner — the live-update path used from the remote debugger.
	var gs := root.get_node_or_null("GameState")
	var bus := root.get_node_or_null("EventBus")
	if gs != null and bus != null and label != null:
		# Start clean so a leftover value from another suite can't skew us.
		gs.debug_force_levelup = false
		gs.debug_growth_boost = false
		await process_frame
		var empty_aids: Array[String] = []
		hud._apply_debug_banner(true, empty_aids)  # baseline text
		gs.debug_force_levelup = true       # setter -> signal -> _refresh_debug_banner
		await process_frame
		# OS.is_debug_build() is true under --script, so visible stays true; the
		# refresh re-reads the live flag list and rewrites the text.
		if label.text.find("force-levelup") != -1:
			print("OK  flag toggle refreshes banner text"); passed += 1
		else:
			print("FAIL flag toggle did not refresh: text=%q" % label.text); failed += 1
		# Reset the flags after toggling — defensive only; each suite runs in
		# its own godot process under run_tests.sh, so this state never leaks
		# across suites. Cheap belt-and-braces against future test layering.
		gs.debug_force_levelup = false
		gs.debug_growth_boost = false
	else:
		print("SKIP live flag-toggle test (GameState/EventBus autoload absent)")

	hud.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
