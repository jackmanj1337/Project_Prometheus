extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_load_game_populated_layout.gd
#
# A populated Load Game screen must keep grouped saves, multi-line labels and recovery
# controls inside their layout. The internal FE pack declares no ui_font, so its screens
# use the engine's TinyRPG FineFantasyStrategies face. PIL sampling at 18px found glyph
# ink 15–18px high against an 18px line box; geometry uses that font's own line height.

const UiFontStackScript = preload("res://scripts/ui/UiFontStack.gd")
const SaveRecoveryScript = preload("res://scripts/save/SaveRecovery.gd")
const VIEW_SIZE := Vector2i(1280, 720)

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Populated Load Game layout test ===")
	await process_frame
	_check("engine UI face is selected", UiFontStackScript.apply())

	var viewport := SubViewport.new()
	viewport.size = VIEW_SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main_menu := (load("res://scenes/ui/MainMenu.tscn") as PackedScene).instantiate()
	viewport.add_child(main_menu)
	await process_frame
	await process_frame

	var picker := main_menu.get_node("LoadGameScreen") as Control
	picker.visible = true
	var rows := picker.get_node("Panel/VBox/Scroll/Rows") as VBoxContainer
	var header := {
		"package_id": "prometheus-proving-grounds-internal-fe",
		"package_version": "0.1.0",
		"campaign_id": "proving_grounds",
		"node_id": "chapter_6_hallowed",
		"save_kind": "between_map",
		"campaign_state": "in_progress",
	}
	var recovery := SaveRecoveryScript.describe(SaveRecoveryScript.REASON_MISSING, header)
	var missing_campaign_row := {
		"header": header.duplicate(true),
		"content_state": SaveRecoveryScript.STATE_DISABLED,
		"recovery": recovery,
		"label": "Chapter 6 — Hallowed Grounds",
		"origin": "manual",
		"saved_at_unix": 1790000000,
	}
	var ready_header: Dictionary = header.duplicate(true)
	ready_header["node_id"] = "chapter_5_fortress"
	var ready_campaign_row := {
		"header": ready_header,
		"content_state": SaveRecoveryScript.STATE_READY,
		"label": "Chapter 5 — The Fortress",
		"origin": "manual",
		"saved_at_unix": 1789900000,
	}
	var group_heading := Label.new()
	group_heading.name = "SaveGroupLabel"
	group_heading.text = "prometheus-proving-grounds-internal-fe v0.1.0 — proving_grounds"
	group_heading.add_theme_font_size_override("font_size", 18)
	rows.add_child(group_heading)
	rows.add_child(picker.call("_make_row", "ready_ch5", ready_campaign_row))
	rows.add_child(picker.call("_make_row", "missing_ch6", missing_campaign_row))
	for _frame in range(4):
		await process_frame

	var panel := picker.get_node("Panel") as Control
	var panel_rect := panel.get_global_rect()
	_check(
		"Load Game panel fits in the 1280x720 viewport",
		viewport.get_visible_rect().encloses(panel_rect),
		str(panel_rect)
	)
	var font: Font = ThemeDB.get_default_theme().default_font
	_check(
		"Load Game uses the engine FineFantasyStrategies face",
		font != null and _uses_engine_font(font)
	)
	if font != null:
		_check(
			"SaveGroupLabel remains inside Load Game panel",
			panel_rect.encloses(group_heading.get_global_rect()),
			"panel %s; heading %s" % [str(panel_rect), str(group_heading.get_global_rect())]
		)
		_check(
			"SaveGroupLabel fits its measured text width",
			group_heading.size.x + 0.5 >= group_heading.get_minimum_size().x,
			(
				"allocated %.1f; minimum %.1f"
				% [group_heading.size.x, group_heading.get_minimum_size().x]
			)
		)
		_check(
			"SaveGroupLabel fits its font line height",
			group_heading.size.y + 0.5 >= _label_line_height(group_heading, font),
			(
				"allocated %.1f; line height %.1f"
				% [group_heading.size.y, _label_line_height(group_heading, font)]
			)
		)
		for row_id in ["ready_ch5", "missing_ch6"]:
			var row := rows.get_node("Row_%s" % row_id) as HBoxContainer
			var row_rect := row.get_global_rect()
			_check(
				"%s row remains inside Load Game panel" % row_id,
				panel_rect.encloses(row_rect),
				str(row_rect)
			)
			var buttons: Array[Button] = []
			for child in row.get_children():
				if child is Button:
					buttons.append(child as Button)
			var expected_actions := 5 if row_id == "missing_ch6" else 3
			_check(
				"%s renders the expected Load/recovery/delete/export controls" % row_id,
				buttons.size() == expected_actions,
				"found %d controls" % buttons.size()
			)
			for button in buttons:
				_check(
					"%s %s button fits its measured text width" % [row_id, button.name],
					button.size.x + 0.5 >= button.get_combined_minimum_size().x,
					(
						"allocated %.1f; minimum %.1f"
						% [button.size.x, button.get_combined_minimum_size().x]
					)
				)
				_check(
					"%s %s button fits visible text line height" % [row_id, button.name],
					button.size.y + 0.5 >= _button_line_height(button, font),
					(
						"allocated %.1f; required %.1f; text=%s"
						% [button.size.y, _button_line_height(button, font), button.text]
					)
				)
			for index in range(buttons.size()):
				for other_index in range(index + 1, buttons.size()):
					_check(
						(
							"%s %s and %s controls do not overlap"
							% [row_id, buttons[index].name, buttons[other_index].name]
						),
						not buttons[index].get_global_rect().intersects(
							buttons[other_index].get_global_rect()
						),
						(
							"%s / %s"
							% [
								str(buttons[index].get_global_rect()),
								str(buttons[other_index].get_global_rect())
							]
						)
					)
		var first := rows.get_node("Row_ready_ch5") as Control
		var second := rows.get_node("Row_missing_ch6") as Control
		_check(
			"two populated save rows preserve vertical separation",
			second.global_position.y >= first.global_position.y + first.size.y,
			"first %s; second %s" % [str(first.get_global_rect()), str(second.get_global_rect())]
		)

	UiFontStackScript.apply()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _uses_engine_font(font: Font) -> bool:
	var variation := font as FontVariation
	return (
		variation != null
		and variation.base_font is FontFile
		and (variation.base_font as FontFile).resource_path.ends_with(
			"TinyRPG-FineFantasyStrategies.ttf"
		)
	)


func _button_line_height(button: Button, font: Font) -> float:
	var lines := maxi(button.text.split("\n").size(), 1)
	var font_size := button.get_theme_font_size("font_size")
	var style := button.get_theme_stylebox("normal")
	var style_height := style.get_minimum_size().y if style != null else 0.0
	return font.get_height(font_size) * float(lines) + style_height


func _label_line_height(label: Label, font: Font) -> float:
	return font.get_height(label.get_theme_font_size("font_size"))


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])
