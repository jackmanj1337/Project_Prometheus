extends SceneTree
# `[EW-8]` rendered proof for the two-theme editor boundary. The model declaration in
# `EditorTestSession` is necessary, but this test asks Godot's live theme fallback chain for
# both metrics and styleboxes on nodes in the two scopes. That is the useful container-side
# prediction of the Windows build: if a pack theme ever leaks across the viewport boundary,
# these assertions fail without needing a GPU screenshot.

const WorkspacesScript = preload("res://scripts/editor/EditorWorkspaces.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Editor Theme Isolation Test ===")
	await _the_live_editor_and_pack_scopes_are_isolated()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])


func _the_live_editor_and_pack_scopes_are_isolated() -> void:
	print("\n-- live chrome and pack themes stay in separate scopes --")
	var packed: PackedScene = load("res://scenes/ui/CampaignEditorScreen.tscn")
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame

	var settings = screen.call("editor_settings")
	settings.set_font_size(20.0)
	await process_frame
	var shell_root: Control = screen.get_node("Shell")
	var chrome_label: Label = screen.get_node("Shell/Header/DraftIdentity")
	var chrome_button: Button = screen.get_node(
		"Shell/Body/Workspace/Centre/DocumentColumns/Document/TestSession/Keyboard/End"
	)
	_check("the shell owns a distinct editor theme", shell_root.theme != null)
	_check(
		"chrome metrics resolve from the editor theme",
		chrome_label.get_theme_font_size("font_size") == 20,
		str(chrome_label.get_theme_font_size("font_size"))
	)

	var viewport: SubViewport = (
		screen
		. get_node(
			"Shell/Body/Workspace/Centre/DocumentColumns/Document/TestSession/Surround/Simulator/Viewport"
		)
	)
	var pack_root := Control.new()
	pack_root.name = "PackThemeRoot"
	pack_root.custom_minimum_size = Vector2(320, 160)
	var pack_theme := Theme.new()
	pack_theme.set_font_size("font_size", "Button", 42)
	var pack_style := StyleBoxFlat.new()
	pack_style.bg_color = Color("d94f70")
	pack_style.set_corner_radius_all(9)
	pack_theme.set_stylebox("normal", "Button", pack_style)
	pack_root.theme = pack_theme
	viewport.add_child(pack_root)
	var pack_button := Button.new()
	pack_button.text = "Pack theme probe"
	pack_root.add_child(pack_button)
	await process_frame

	_check(
		"the pack theme reaches a node inside the session viewport",
		pack_button.get_theme_font_size("font_size") == 42,
		str(pack_button.get_theme_font_size("font_size"))
	)
	_check(
		"pack paint resolves on the session node",
		pack_button.get_theme_stylebox("normal") == pack_style
	)
	_check(
		"pack metrics cannot reach editor chrome",
		chrome_button.get_theme_font_size("font_size") == 20,
		str(chrome_button.get_theme_font_size("font_size"))
	)
	_check(
		"pack paint cannot reach editor chrome",
		chrome_button.get_theme_stylebox("normal") != pack_style
	)
	_check(
		"the test workspace keeps its dedicated open panel",
		(
			String(WorkspacesScript.WORKSPACES[WorkspacesScript.TEST]["panel"])
			== WorkspacesScript.PANEL_OPEN
		)
	)

	pack_button.queue_free()
	pack_root.queue_free()
	screen.queue_free()
	await process_frame
