extends SceneTree
# A RENDERED proof that the campaign editor opens, for
# `EDITOR-MINSIZE-GATE-MEASURES-VIEWPORT-2026-09-22`. Headless cannot answer this: the
# opt-out is deliberately skipped there (its window is a fixed 64x64 with no display), so
# the only thing that can show the shell drawing at full window size is a real rasteriser.
#
#   Xvfb :99 -screen 0 1920x1080x24 &        # `xvfb-run` fails in this image: no xauth
#   DISPLAY=:99 HOME=$(mktemp -d) godot --path . --rendering-driver opengl3 \
#     --resolution 1920x1080 --script res://scripts/tools/probe_editor_floor.gd
#
# A FRESH `HOME` IS LOAD-BEARING. The defect only exists at a content scale factor above
# 1.0, and an accumulated `user://settings.cfg` pins the factor to whatever the last run
# left. With a fresh home the first-launch default derives 1.5 for a 1080p screen, which is
# the case that used to report "This window is 1280 x 720" at a 1920x1080 window.
#
# What it prints, and what each line is evidence of:
#   BEFORE  -- the defect: a 1920x1080 window whose LOGICAL viewport is 1280x720.
#   EDITOR  -- the fix: opted out, logical and effective both 1920x1080, shell visible and
#              the minimum-size state hidden.
#   AFTER   -- the half that is invisible from inside the editor: Back restores the
#              player's factor, and the PERSISTED setting was never written.
#
# It does not answer DPI scaling, window-manager behaviour or the GPU path -- `AGENTS.md`'s
# Windows-host visual pass is still the authority for those, and this row still owes one.


func _init() -> void:
	await process_frame
	var target := Vector2i(1920, 1080)
	root.size = target
	DisplayServer.window_set_size(target)
	await process_frame
	await process_frame

	var sm: Object = root.get_node_or_null("/root/SettingsManager")
	print(
		(
			"BEFORE  persisted factor=%s  window factor=%s  window=%s  logical=%s"
			% [
				sm.get("content_scale_factor") if sm != null else "?",
				root.content_scale_factor,
				DisplayServer.window_get_size(),
				root.get_visible_rect().size,
			]
		)
	)

	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	root.add_child(menu)
	for i in 5:
		await process_frame

	var button: Button = menu.get_node("MenuFrame/Panel/Scroll/VBox/CampaignEditorButton")
	button.emit_signal("pressed")
	for i in 8:
		await process_frame

	var screen: Control = menu.get_node("CampaignEditorScreen")
	print(
		(
			"EDITOR  visible=%s  opted_out=%s  window factor=%s  logical=%s  effective=%s"
			% [
				screen.visible,
				screen.viewport_opt_out_active(),
				root.content_scale_factor,
				root.get_visible_rect().size,
				screen.effective_viewport_size(),
			]
		)
	)
	print(
		(
			"SHELL   shell_visible=%s  minsize_state_visible=%s"
			% [
				screen.get_node("Shell").visible,
				(
					screen.get_node("MinimumSizeState").visible
					if screen.has_node("MinimumSizeState")
					else "?"
				),
			]
		)
	)
	root.get_texture().get_image().save_png("user://editor_floor_1920x1080.png")

	screen.emit_signal("back_pressed")
	for i in 5:
		await process_frame
	print(
		(
			"AFTER   window factor=%s  logical=%s  persisted=%s"
			% [
				root.content_scale_factor,
				root.get_visible_rect().size,
				sm.get("content_scale_factor") if sm != null else "?",
			]
		)
	)
	root.get_texture().get_image().save_png("user://editor_floor_after_back.png")
	quit(0)
