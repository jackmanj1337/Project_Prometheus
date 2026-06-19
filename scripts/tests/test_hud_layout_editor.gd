extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_hud_layout_editor.gd
# Smoke-tests the HUD layout editor's non-mouse paths (Display & Accessibility item 4):
# open() builds handles, Reset clears, Done persists hud.current_layout() to
# SettingsManager, Cancel restores the layout captured at open(). The drag/scale mouse
# interaction itself is verified by playtest (as with AttackPreview positioning).

const HUDScene = preload("res://scenes/ui/HUD.tscn")
const HudLayoutEditorS = preload("res://scripts/ui/HudLayoutEditor.gd")

var _passed := 0
var _failed := 0


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
		_passed += 1
	else:
		print("FAIL ", msg)
		_failed += 1


func _init() -> void:
	print("=== HUD Layout Editor Test ===")
	var hud: Control = HUDScene.instantiate()
	root.add_child(hud)
	await process_frame
	await process_frame

	var panel: Control = hud.get_layout_panel("unit_info")
	var base: Vector2 = panel.position

	# ---- open() builds one drag handle per movable panel + toolbar ----
	var editor: CanvasLayer = HudLayoutEditorS.new()
	root.add_child(editor)
	editor.open(hud)
	_ok(editor.get_child_count() > 0, "open() builds the editor overlay")

	# ---- V020-12: handles use red/yellow outline styleboxes + sample text ----
	var any_id: String = ""
	for id in editor._handles:
		any_id = id
		break
	editor._selected_id = any_id
	editor._refresh_handles()
	var sel_style: StyleBox = editor._handles[any_id].get_theme_stylebox("panel")
	_ok(sel_style is StyleBoxFlat and sel_style.border_color == Color(1, 0.95, 0.2, 1),
		"selected handle uses the yellow outline stylebox (V020-12)")
	var other_id: String = ""
	for id in editor._handles:
		if id != any_id:
			other_id = id
			break
	if other_id != "":
		var other_style: StyleBox = editor._handles[other_id].get_theme_stylebox("panel")
		_ok(other_style is StyleBoxFlat and other_style.border_color == Color(1, 0.25, 0.25, 1),
			"unselected handle uses the bright-red outline stylebox (V020-12)")
	var sample_lbl: Label = editor._handle_labels.get(any_id)
	_ok(sample_lbl != null and "Sample" in sample_lbl.text and any_id in sample_lbl.text,
		"each handle shows editor-only sample text (V020-12)")
	editor._selected_id = ""  # reset so the persistence checks below are unaffected

	# ---- Done persists the current HUD layout to SettingsManager ----
	hud.set_panel_layout("unit_info", Vector2(30, -12), 1.25)
	editor._on_done()
	var sm := root.get_node_or_null("SettingsManager")
	_ok(sm != null, "SettingsManager autoload present")
	var saved: Variant = sm.hud_layout.get("unit_info", {})
	_ok(saved is Dictionary and saved.get("offset", Vector2.ZERO) == Vector2(30, -12)
		and is_equal_approx(saved.get("scale", 0.0), 1.25),
		"Done saves hud.current_layout() to SettingsManager.hud_layout")

	# ---- Cancel restores the layout captured at open() ----
	# Re-apply the saved state, open a fresh editor (snapshots it), modify, then Cancel.
	hud.apply_layout(sm.hud_layout)
	var editor2: CanvasLayer = HudLayoutEditorS.new()
	root.add_child(editor2)
	editor2.open(hud)
	hud.set_panel_layout("unit_info", Vector2(200, 200), 2.0)  # a change to be discarded
	editor2._on_cancel()
	_ok(panel.position == hud._clamp_panel_on_screen(panel, base + Vector2(30, -12))
		and is_equal_approx(panel.scale.x, 1.25),
		"Cancel restores the layout captured at open()")

	# ---- Reset clears back to the authored base ----
	var editor3: CanvasLayer = HudLayoutEditorS.new()
	root.add_child(editor3)
	editor3.open(hud)
	editor3._on_reset()
	_ok(panel.position == base and is_equal_approx(panel.scale.x, 1.0),
		"Reset restores the authored base layout")
	# _on_done with an empty layout writes {} back.
	editor3._on_done()
	_ok(sm.hud_layout.is_empty(), "Done after Reset saves an empty layout")

	hud.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
