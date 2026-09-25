extends SceneTree
# Run with: godot --headless --path . --script res://scripts/tests/test_pack_font_hud_readability.gd
#
# Regression for the v0.8.4 free-roam capture: its active TinyRPG face must remain on the
# live HUD, and the Objectives, unit and terrain labels must keep readable rendered ink.
# The test measures the actual theme font metrics and label geometry. Native visual
# inspection still checks the rendered glyphs.

const UiFontStackScript = preload("res://scripts/ui/UiFontStack.gd")

const PACK_ROOT := "res://Draft UI assets/tinyrpgfontkit01_v1_2"
const PACK_FONT := "TinyRPG-BrilliantStrength.ttf"
const VIEW_SIZE := Vector2i(1280, 720)
## fontTools inspection of the actual free-roam TTF found a 28-unit em line box but 32-unit
## glyph ink bounds (-6..26). The visible ink therefore needs 32/28 line-height at the
## pack's natural scale; asserting only Label control height misses the 14.3% overhang.
const PACK_GLYPH_INK_RATIO := 32.0 / 28.0

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Active pack HUD font readability test ===")
	await process_frame  # Let DataManager finish startup before activating a pack face.
	_check("free-roam pack face activates", UiFontStackScript.apply(PACK_ROOT, PACK_FONT))
	_check(
		"the active face remains the free-roam pack face",
		UiFontStackScript.active_font_path() == PACK_ROOT.path_join(PACK_FONT),
		UiFontStackScript.active_font_path()
	)

	var viewport := SubViewport.new()
	viewport.size = VIEW_SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var hud := (load("res://scenes/ui/HUD.tscn") as PackedScene).instantiate() as Control
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(hud)
	await process_frame
	await process_frame

	var objective_header := hud.get_node("ObjectivePanel/VBox/ObjectiveHeader") as Label
	var objective_list := hud.get_node("ObjectivePanel/VBox/ObjectiveList") as Label
	var unit_name := hud.get_node("UnitInfoPanel/VBox/UnitName") as Label
	var unit_class := hud.get_node("UnitInfoPanel/VBox/UnitClass") as Label
	var unit_hp := hud.get_node("UnitInfoPanel/VBox/UnitHP") as Label
	var unit_weapon := hud.get_node("UnitInfoPanel/VBox/UnitWeapon") as Label
	var terrain_name := hud.get_node("TerrainCorner/TerrainInfoPanel/VBox/TerrainName") as Label
	var terrain_coord := hud.get_node("TerrainCorner/TerrainInfoPanel/VBox/TerrainCoord") as Label
	var terrain_def := hud.get_node("TerrainCorner/TerrainInfoPanel/VBox/TerrainDef") as Label
	var terrain_dodge := hud.get_node("TerrainCorner/TerrainInfoPanel/VBox/TerrainDodge") as Label
	var terrain_hint := hud.get_node("TerrainCorner/TerrainInfoPanel/VBox/TerrainHint") as Label

	objective_header.text = "Objectives"
	objective_list.text = "Win: Rout all hostiles\nLose: Rout all allies"
	unit_name.text = "Unit_01"
	unit_class.text = "Cavalier  Lv 1"
	unit_hp.text = "HP 17 / 17"
	unit_weapon.text = "Iron Lance"
	terrain_name.text = "Plain"
	terrain_coord.text = "Tile (2, 4)"
	terrain_def.text = "DEF +0"
	terrain_dodge.text = "DODGE +0"
	terrain_hint.text = "Press F for more info"

	hud.get_node("ObjectivePanel").visible = true
	hud.get_node("UnitInfoPanel").visible = true
	var terrain_panel := hud.get_node("TerrainCorner/TerrainInfoPanel") as Control
	terrain_panel.visible = true
	await process_frame
	await process_frame

	var font := ThemeDB.get_default_theme().default_font
	_check("active pack face is the font drawing HUD text", font != null and _uses_pack_font(font))
	for label in [
		hud.get_node("PhaseLabel") as Label,
		hud.get_node("TurnLabel") as Label,
		objective_header,
		unit_name,
		terrain_name,
	]:
		_check(
			"%s uses the readable pack HUD size" % label.name,
			label.get_theme_font_size("font_size") == hud.PACK_HUD_FONT_SIZE
		)
	_check(
		"free-roam pack face remains active after HUD startup",
		UiFontStackScript.active_font_path() == PACK_ROOT.path_join(PACK_FONT)
	)
	_check(
		"the Objectives header allocates height for visible pack glyph ink",
		objective_header.size.y >= _ink_safe_height(objective_header),
		(
			"allocated %.1f; ink-safe height %.1f"
			% [objective_header.size.y, _ink_safe_height(objective_header)]
		)
	)
	_check(
		"Objective header and content rows have ink-safe separation",
		(
			objective_list.global_position.y - objective_header.global_position.y
			>= _ink_safe_height(objective_header) - 0.5
		),
		(
			"header y %.1f, content y %.1f, ink-safe step %.1f"
			% [
				objective_header.global_position.y,
				objective_list.global_position.y,
				_ink_safe_height(objective_header)
			]
		)
	)
	_check_panel_rows(
		"unit panel",
		[unit_name, unit_class, unit_hp, unit_weapon],
		hud.get_node("UnitInfoPanel") as Control
	)
	_check_panel_rows(
		"terrain panel",
		[terrain_name, terrain_coord, terrain_def, terrain_dodge, terrain_hint],
		terrain_panel
	)
	var objective_line_count := objective_list.get_line_count()
	_check(
		"Objectives content keeps both authored lines",
		objective_line_count == 2,
		str(objective_line_count)
	)
	_check(
		"Objectives content allocates ink-safe height for every rendered line",
		objective_list.size.y + 0.5 >= _objective_required_height(objective_list),
		(
			"allocated %.1f; required %.1f"
			% [objective_list.size.y, _objective_required_height(objective_list)]
		)
	)
	_check(
		"Objectives content remains inside its panel",
		(hud.get_node("ObjectivePanel") as Control).get_global_rect().encloses(
			objective_list.get_global_rect()
		),
		(
			"panel %s; content %s"
			% [
				str((hud.get_node("ObjectivePanel") as Control).get_global_rect()),
				str(objective_list.get_global_rect())
			]
		)
	)

	UiFontStackScript.apply()
	var engine_hud := (load("res://scenes/ui/HUD.tscn") as PackedScene).instantiate() as Control
	viewport.add_child(engine_hud)
	await process_frame
	_check(
		"HUD without an active pack keeps the engine font size",
		(
			(engine_hud.get_node("UnitInfoPanel/VBox/UnitName") as Label).get_theme_font_size(
				"font_size"
			)
			!= hud.PACK_HUD_FONT_SIZE
		)
	)
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _uses_pack_font(font: Font) -> bool:
	var variation := font as FontVariation
	return (
		variation != null
		and variation.base_font is FontFile
		and (variation.base_font as FontFile).get_font_name().contains("Brilliant Strength")
	)


func _font_height(label: Label) -> float:
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	return font.get_height(size) if font != null else INF


func _row_advance(label: Label) -> float:
	return _font_height(label) + float(label.get_theme_constant("line_spacing"))


func _ink_safe_height(label: Label) -> float:
	return _font_height(label) * PACK_GLYPH_INK_RATIO


func _objective_required_height(label: Label) -> float:
	var count := maxi(label.get_line_count(), 1)
	return (
		_ink_safe_height(label) * float(count)
		+ float(label.get_theme_constant("line_spacing")) * float(count - 1)
	)


func _check_panel_rows(panel_name: String, labels: Array[Label], panel: Control) -> void:
	for index in range(labels.size()):
		var label := labels[index]
		_check(
			"%s %s row accommodates measured pack glyph ink" % [panel_name, label.name],
			label.size.y + 0.5 >= _ink_safe_height(label),
			"allocated %.1f; ink-safe height %.1f" % [label.size.y, _ink_safe_height(label)]
		)
		_check(
			"%s %s remains inside its panel" % [panel_name, label.name],
			panel.get_global_rect().encloses(label.get_global_rect()),
			"panel %s; row %s" % [str(panel.get_global_rect()), str(label.get_global_rect())]
		)
		if index == 0:
			continue
		var previous := labels[index - 1]
		_check(
			"%s rows %s and %s preserve ink-safe gap" % [panel_name, previous.name, label.name],
			(
				label.global_position.y - previous.global_position.y
				>= _ink_safe_height(previous) - 0.5
			),
			(
				"row step %.1f; ink-safe height %.1f"
				% [label.global_position.y - previous.global_position.y, _ink_safe_height(previous)]
			)
		)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])
