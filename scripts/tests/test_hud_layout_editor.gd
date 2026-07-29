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
# Captures the editor's `closed` emit for the teardown-contract test below.
var _teardown_closed_fired := false


func _on_editor_closed_signal() -> void:
	_teardown_closed_fired = true


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
	_ok(
		sel_style is StyleBoxFlat and sel_style.border_color == Color(1, 0.95, 0.2, 1),
		"selected handle uses the yellow outline stylebox (V020-12)"
	)
	var other_id: String = ""
	for id in editor._handles:
		if id != any_id:
			other_id = id
			break
	if other_id != "":
		var other_style: StyleBox = editor._handles[other_id].get_theme_stylebox("panel")
		_ok(
			other_style is StyleBoxFlat and other_style.border_color == Color(1, 0.25, 0.25, 1),
			"unselected handle uses the bright-red outline stylebox (V020-12)"
		)
	var sample_lbl: Label = editor._handle_labels.get(any_id)
	_ok(
		sample_lbl != null and "Sample" in sample_lbl.text and any_id in sample_lbl.text,
		"each handle shows editor-only sample text (V020-12)"
	)
	editor._selected_id = ""  # reset so the persistence checks below are unaffected

	# ---- Done persists the current HUD layout to SettingsManager ----
	hud.set_panel_layout("unit_info", Vector2(30, -12), 1.25)
	editor._on_done()
	var sm := root.get_node_or_null("SettingsManager")
	_ok(sm != null, "SettingsManager autoload present")
	var saved: Variant = sm.hud_layout.get("unit_info", {})
	_ok(
		(
			saved is Dictionary
			and saved.get("offset", Vector2.ZERO) == Vector2(30, -12)
			and is_equal_approx(saved.get("scale", 0.0), 1.25)
		),
		"Done saves hud.current_layout() to SettingsManager.hud_layout"
	)

	# ---- Cancel restores the layout captured at open() ----
	# Re-apply the saved state, open a fresh editor (snapshots it), modify, then Cancel.
	hud.apply_layout(sm.hud_layout)
	var editor2: CanvasLayer = HudLayoutEditorS.new()
	root.add_child(editor2)
	editor2.open(hud)
	hud.set_panel_layout("unit_info", Vector2(200, 200), 2.0)  # a change to be discarded
	editor2._on_cancel()
	_ok(
		(
			panel.position == hud._clamp_panel_on_screen(panel, base + Vector2(30, -12))
			and is_equal_approx(panel.scale.x, 1.25)
		),
		"Cancel restores the layout captured at open()"
	)

	# ---- Reset clears back to the authored base ----
	var editor3: CanvasLayer = HudLayoutEditorS.new()
	root.add_child(editor3)
	editor3.open(hud)
	editor3._on_reset()
	_ok(
		panel.position == base and is_equal_approx(panel.scale.x, 1.0),
		"Reset restores the authored base layout"
	)
	# _on_done with an empty layout writes {} back.
	editor3._on_done()
	_ok(sm.hud_layout.is_empty(), "Done after Reset saves an empty layout")

	# ---- V021-03: handle frames clip their sample text to their bounds ----
	var editor5: CanvasLayer = HudLayoutEditorS.new()
	root.add_child(editor5)
	editor5.open(hud)
	var clip_id: String = ""
	for id in editor5._handles:
		clip_id = id
		break
	_ok(
		clip_id != "" and editor5._handles[clip_id].clip_contents,
		"V021-03 handle frames clip sample text to their bounds"
	)

	# ---- V021-02: the cancel action closes the editor + restores the layout ----
	# The editor is a hard modal — its _input swallows the cancel and routes it to
	# Cancel, so it never reaches (and closes) the Settings screen beneath it.
	hud.apply_layout({})  # clean authored base
	editor5._on_cancel()  # discard the open() snapshot editor
	var editor6: CanvasLayer = HudLayoutEditorS.new()
	root.add_child(editor6)
	editor6.open(hud)
	hud.set_panel_layout("unit_info", Vector2(50, 50), 1.5)  # change to be discarded
	var cancel_ev := InputEventAction.new()
	cancel_ev.action = "cancel"
	cancel_ev.pressed = true
	editor6._input(cancel_ev)
	await process_frame
	_ok(
		panel.position == base and is_equal_approx(panel.scale.x, 1.0),
		"V021-02 cancel input restores the pre-edit layout"
	)
	_ok(
		not is_instance_valid(editor6) or editor6.is_queued_for_deletion(),
		"V021-02 cancel input closes the editor"
	)

	# ---- V053-05/-06: modal lock while open + scale buttons gated on selection ----
	# Close the first editor (opened at line 37 and never dismissed) so no stray
	# modal lock lingers into this check.
	if is_instance_valid(editor):
		editor._on_cancel()
	await process_frame
	var bus := root.get_node_or_null("EventBus")
	var editor7: CanvasLayer = HudLayoutEditorS.new()
	root.add_child(editor7)
	editor7.open(hud)
	_ok(
		bus != null and bus.is_gameplay_modal_locked(),
		"V053-05 editor holds the gameplay modal lock while open (silences MapCursor poll)"
	)
	_ok(
		(
			editor7._scale_minus != null
			and editor7._scale_minus.disabled
			and editor7._scale_plus.disabled
		),
		"V053-06 Scale −/+ start disabled with no panel selected"
	)
	var pick_id: String = ""
	for id in editor7._handles:
		pick_id = id
		break
	editor7._selected_id = pick_id
	editor7._refresh_handles()
	_ok(
		not editor7._scale_minus.disabled and not editor7._scale_plus.disabled,
		"V053-06 Scale −/+ enable once a panel is selected"
	)
	editor7._on_done()
	await process_frame
	_ok(
		bus != null and not bus.is_gameplay_modal_locked(),
		"V053-05 editor releases the gameplay modal lock on close"
	)

	# ---- Teardown contract: `closed` + lock release fire even without _close() ----
	# SettingsScreen re-enables its focus-repeat poll only on `closed`, so a
	# teardown that bypasses the Done/Cancel path (scene teardown, external free)
	# must still emit it — otherwise the settings screen stays stuck. Free the
	# editor via queue_free (NOT _on_done/_on_cancel) and assert both fire once.
	var editor8: CanvasLayer = HudLayoutEditorS.new()
	root.add_child(editor8)
	editor8.open(hud)
	_teardown_closed_fired = false
	editor8.closed.connect(_on_editor_closed_signal)
	editor8.queue_free()  # bypasses _close(): only _exit_tree runs
	await process_frame
	await process_frame
	_ok(
		_teardown_closed_fired and bus != null and not bus.is_gameplay_modal_locked(),
		"teardown without _close() still emits `closed` and releases the lock"
	)

	hud.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
