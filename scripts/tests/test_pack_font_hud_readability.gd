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
const HUD_LAYOUT_CASES := [
	{"name": "1280x720", "size": Vector2i(1280, 720), "content": 1.0, "menu": 2},
	{"name": "560x900", "size": Vector2i(560, 900), "content": 1.0, "menu": 2},
	{"name": "900x760", "size": Vector2i(900, 760), "content": 1.0, "menu": 2},
	{"name": "1920x1080", "size": Vector2i(1920, 1080), "content": 1.0, "menu": 2},
	{"name": "1280x720 content 0.5", "size": Vector2i(1280, 720), "content": 0.5, "menu": 2},
	{"name": "1280x720 content 2", "size": Vector2i(1280, 720), "content": 2.0, "menu": 2},
	{"name": "1280x720 menu 0.5", "size": Vector2i(1280, 720), "content": 1.0, "menu": 0},
	{"name": "1280x720 menu 2", "size": Vector2i(1280, 720), "content": 1.0, "menu": 6},
]
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
	await _check_live_map_matrix()

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
	await _check_fresh_no_pack_live_map()
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


func _check_live_map_matrix() -> void:
	var game_state := root.get_node_or_null("GameState")
	var settings := root.get_node_or_null("SettingsManager")
	if game_state == null or settings == null:
		_check("live-map layout matrix has GameState and SettingsManager", false)
		return
	_check("live-map layout matrix has GameState and SettingsManager", true)
	var original_content_scale := float(settings.get("content_scale_factor"))
	var original_menu_scale := int(settings.get("menu_scale_index"))
	var live_viewport := SubViewport.new()
	live_viewport.size = VIEW_SIZE
	live_viewport.transparent_bg = true
	live_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(live_viewport)
	game_state.call("reset_map_state")
	game_state.call("load_default_roster")
	game_state.call(
		"configure_next_map", "res://data/maps/map_001_rout/map_001_data.tres", "default_roster", ""
	)
	var game_map := (load("res://scenes/core/GameMap.tscn") as PackedScene).instantiate()
	live_viewport.add_child(game_map)
	for _frame in range(5):
		await process_frame
	var hud := game_map.get_node_or_null("HUDMainLayer/HUD") as Control
	_check("HUD is attached to a running GameMap", hud != null)
	if hud == null:
		live_viewport.queue_free()
		return
	_check(
		"live GameMap activated its Objectives panel",
		(hud.get_node("ObjectivePanel") as Control).visible
	)
	_check(
		"live GameMap activated its unit panel", (hud.get_node("UnitInfoPanel") as Control).visible
	)
	var panels := [
		{"name": "Objectives", "node": hud.get_node("ObjectivePanel") as Control},
		{"name": "unit", "node": hud.get_node("UnitInfoPanel") as Control},
		{"name": "terrain", "node": hud.get_node("TerrainCorner/TerrainInfoPanel") as Control},
	]
	var row_paths := [
		["ObjectivePanel/VBox/ObjectiveHeader", "ObjectivePanel/VBox/ObjectiveList"],
		[
			"UnitInfoPanel/VBox/UnitName",
			"UnitInfoPanel/VBox/UnitClass",
			"UnitInfoPanel/VBox/UnitHP",
			"UnitInfoPanel/VBox/UnitWeapon"
		],
		[
			"TerrainCorner/TerrainInfoPanel/VBox/TerrainName",
			"TerrainCorner/TerrainInfoPanel/VBox/TerrainCoord",
			"TerrainCorner/TerrainInfoPanel/VBox/TerrainDef",
			"TerrainCorner/TerrainInfoPanel/VBox/TerrainDodge",
			"TerrainCorner/TerrainInfoPanel/VBox/TerrainHint",
		],
	]
	for case in HUD_LAYOUT_CASES:
		var expected_extent: Vector2 = Vector2(case["size"]) / float(case["content"])
		live_viewport.size = Vector2i(expected_extent)
		settings.call("set_content_scale_factor", float(case["content"]), false)
		settings.set("menu_scale_index", int(case["menu"]))
		settings.call("_apply_menu_scale")
		for _frame in range(3):
			await process_frame
		var view_rect := hud.get_viewport().get_visible_rect()
		_check(
			"%s viewport uses its expected logical extent" % case["name"],
			view_rect.size.distance_to(expected_extent) <= 1.0,
			"actual %s; expected %s" % [str(view_rect.size), str(expected_extent)]
		)
		for panel_info in panels:
			var panel := panel_info["node"] as Control
			if not panel.visible:
				continue
			_check(
				"%s %s panel stays inside the viewport" % [case["name"], panel_info["name"]],
				view_rect.encloses(panel.get_global_rect()),
				"viewport %s; panel %s" % [str(view_rect), str(panel.get_global_rect())]
			)
			var rows: Array[Label] = []
			for path in row_paths[panels.find(panel_info)]:
				var label := hud.get_node(path) as Label
				if label.visible:
					rows.append(label)
			for index in range(rows.size()):
				var label := rows[index]
				_check(
					(
						"%s %s.%s visible ink fits its allocated row"
						% [case["name"], panel_info["name"], label.name]
					),
					label.size.y + 0.5 >= _ink_safe_height(label),
					"allocated %.1f; ink-safe %.1f" % [label.size.y, _ink_safe_height(label)]
				)
				_check(
					(
						"%s %s.%s does not clip horizontally"
						% [case["name"], panel_info["name"], label.name]
					),
					label.size.x + 0.5 >= label.get_minimum_size().x,
					(
						"allocated width %.1f; minimum %.1f"
						% [label.size.x, label.get_minimum_size().x]
					)
				)
				if not panel.get_global_rect().encloses(label.get_global_rect()):
					_check(
						(
							"%s %s.%s row stays inside its panel"
							% [case["name"], panel_info["name"], label.name]
						),
						false,
						(
							"panel %s; row %s"
							% [str(panel.get_global_rect()), str(label.get_global_rect())]
						)
					)
				if index > 0:
					var previous := rows[index - 1]
					_check(
						(
							"%s %s rows %s/%s keep ink-safe spacing"
							% [case["name"], panel_info["name"], previous.name, label.name]
						),
						(
							label.global_position.y - previous.global_position.y
							>= _ink_safe_height(previous) - 0.5
						),
						(
							"row advance %.1f; previous ink %.1f"
							% [
								label.global_position.y - previous.global_position.y,
								_ink_safe_height(previous)
							]
						)
					)
		# v0.8.5 walk 1A: every row fitted its own panel at 640x360, and the panels still
		# painted over EACH OTHER. No visible HUD panel may overlap another.
		for a in range(panels.size()):
			for b in range(a + 1, panels.size()):
				var first := panels[a]["node"] as Control
				var second := panels[b]["node"] as Control
				if not first.is_visible_in_tree() or not second.is_visible_in_tree():
					continue
				_check(
					(
						"%s %s and %s panels do not overlap"
						% [case["name"], panels[a]["name"], panels[b]["name"]]
					),
					not first.get_global_rect().intersects(second.get_global_rect()),
					"%s vs %s" % [str(first.get_global_rect()), str(second.get_global_rect())]
				)
		var objectives := hud.get_node("ObjectivePanel/VBox/ObjectiveList") as Label
		if not objectives.visible:
			# Collapsed to its header to make room -- only allowed when the full box
			# would have overlapped (see HUD._objective_collapsed).
			_check(
				"%s Objectives collapse only when the canvas is short" % case["name"],
				bool(hud.call("is_objective_collapsed")) and expected_extent.y < 720.0,
				"collapsed at logical %s" % str(expected_extent)
			)
			continue
		_check(
			"%s live Objectives allocate ink-safe height for all lines" % case["name"],
			objectives.size.y + 0.5 >= _objective_required_height(objectives),
			(
				"allocated %.1f; required %.1f"
				% [objectives.size.y, _objective_required_height(objectives)]
			)
		)
		_check(
			"%s Objectives lines remain within the panel" % case["name"],
			(hud.get_node("ObjectivePanel") as Control).get_global_rect().encloses(
				objectives.get_global_rect()
			),
			(
				"panel %s; text %s"
				% [
					str((hud.get_node("ObjectivePanel") as Control).get_global_rect()),
					str(objectives.get_global_rect())
				]
			)
		)
	settings.call("set_content_scale_factor", original_content_scale, false)
	settings.set("menu_scale_index", original_menu_scale)
	settings.call("_apply_menu_scale")
	live_viewport.queue_free()
	await process_frame


func _check_fresh_no_pack_live_map() -> void:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		_check("no-pack GameMap has GameState", false)
		return
	game_state.call("reset_map_state")
	game_state.call("load_default_roster")
	game_state.call(
		"configure_next_map", "res://data/maps/map_001_rout/map_001_data.tres", "default_roster", ""
	)
	var game_map := (load("res://scenes/core/GameMap.tscn") as PackedScene).instantiate()
	root.add_child(game_map)
	for _frame in range(5):
		await process_frame
	var hud := game_map.get_node_or_null("HUDMainLayer/HUD") as Control
	_check("no-pack HUD is attached to a running GameMap", hud != null)
	if hud != null:
		var viewport_rect := hud.get_viewport().get_visible_rect()
		for path in [
			"ObjectivePanel",
			"UnitInfoPanel",
			"TerrainCorner/TerrainInfoPanel",
		]:
			var panel := hud.get_node(path) as Control
			if panel.visible:
				_check(
					"no-pack %s panel stays inside the viewport" % path,
					viewport_rect.encloses(panel.get_global_rect()),
					"viewport %s; panel %s" % [str(viewport_rect), str(panel.get_global_rect())]
				)
		for label in [
			hud.get_node("ObjectivePanel/VBox/ObjectiveHeader") as Label,
			hud.get_node("UnitInfoPanel/VBox/UnitName") as Label,
			hud.get_node("TerrainCorner/TerrainInfoPanel/VBox/TerrainName") as Label,
		]:
			if label.visible:
				_check(
					"no-pack %s row fits its measured font height" % label.name,
					label.size.y + 0.5 >= _font_height(label),
					"allocated %.1f; font height %.1f" % [label.size.y, _font_height(label)]
				)
		_check_engine_rows(
			"no-pack unit",
			[
				hud.get_node("UnitInfoPanel/VBox/UnitName") as Label,
				hud.get_node("UnitInfoPanel/VBox/UnitClass") as Label,
				hud.get_node("UnitInfoPanel/VBox/UnitHP") as Label,
				hud.get_node("UnitInfoPanel/VBox/UnitWeapon") as Label,
			],
			hud.get_node("UnitInfoPanel") as Control
		)
		_check_engine_rows(
			"no-pack terrain",
			[
				hud.get_node("TerrainCorner/TerrainInfoPanel/VBox/TerrainName") as Label,
				hud.get_node("TerrainCorner/TerrainInfoPanel/VBox/TerrainCoord") as Label,
				hud.get_node("TerrainCorner/TerrainInfoPanel/VBox/TerrainDef") as Label,
				hud.get_node("TerrainCorner/TerrainInfoPanel/VBox/TerrainDodge") as Label,
				hud.get_node("TerrainCorner/TerrainInfoPanel/VBox/TerrainHint") as Label,
			],
			hud.get_node("TerrainCorner/TerrainInfoPanel") as Control
		)
	game_map.queue_free()
	await process_frame


func _check_engine_rows(panel_name: String, labels: Array[Label], panel: Control) -> void:
	for index in range(labels.size()):
		var label := labels[index]
		if not label.visible:
			continue
		_check(
			"%s %s row fits its engine font height" % [panel_name, label.name],
			label.size.y + 0.5 >= _font_height(label),
			"allocated %.1f; font height %.1f" % [label.size.y, _font_height(label)]
		)
		_check(
			"%s %s remains inside its panel" % [panel_name, label.name],
			panel.get_global_rect().encloses(label.get_global_rect()),
			"panel %s; row %s" % [str(panel.get_global_rect()), str(label.get_global_rect())]
		)
		_check(
			"%s %s text width fits its row" % [panel_name, label.name],
			label.size.x + 0.5 >= label.get_minimum_size().x,
			"allocated %.1f; minimum %.1f" % [label.size.x, label.get_minimum_size().x]
		)
		if index > 0:
			var previous := labels[index - 1]
			_check(
				"%s rows %s/%s keep font-height spacing" % [panel_name, previous.name, label.name],
				(
					label.global_position.y - previous.global_position.y
					>= _font_height(previous) - 0.5
				),
				(
					"row advance %.1f; font height %.1f"
					% [label.global_position.y - previous.global_position.y, _font_height(previous)]
				)
			)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])
