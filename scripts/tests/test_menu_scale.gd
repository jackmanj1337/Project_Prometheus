extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_menu_scale.gd
# Verifies Menu Scale stays local to menu/modal panels, scales CRISPLY (type, not a
# bitmap stretch — V021-18/D2), and preserves centering at every supported scale.
# HUD layout is covered separately by test_hud_layout.gd.

const MenuScale = preload("res://scripts/ui/MenuScale.gd")
const LEVELS: Array[float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
const BASE_FONT := 16  # MenuScale._BASE_DEFAULT_FONT_SIZE (engine default)

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
	print("=== Menu Scale Test ===")

	var centered_cases: Array = [
		["MapMenu", "res://scenes/ui/MapMenu.tscn", "Panel"],
		["SettingsScreen", "res://scenes/ui/SettingsScreen.tscn", "Panel"],
		["UnitDetailsScreen", "res://scenes/ui/UnitDetailsScreen.tscn", "Panel"],
		["NewGameScreen", "res://scenes/ui/NewGameScreen.tscn", "Panel"],
		["PromotionScreen", "res://scenes/ui/PromotionScreen.tscn", "Panel"],
		["ReclassScreen", "res://scenes/ui/ReclassScreen.tscn", "Panel"],
		["LevelUpScreen", "res://scenes/ui/LevelUpScreen.tscn", "Panel"],
		["GameOverScreen", "res://scenes/ui/GameOverScreen.tscn", "Panel"],
		["MapResultsScreen", "res://scenes/ui/MapResultsScreen.tscn", "Panel"],
	]
	for entry in centered_cases:
		await _check_centered_panel(String(entry[0]), String(entry[1]), String(entry[2]))

	var contextual_cases: Array = [
		["ActionMenu", "res://scenes/ui/ActionMenu.tscn"],
		["ItemMenu", "res://scenes/ui/ItemMenu.tscn"],
		["WeaponMenu", "res://scenes/ui/WeaponMenu.tscn"],
	]
	for entry in contextual_cases:
		await _check_context_menu_scale(String(entry[0]), String(entry[1]))

	await _check_crisp_type_scaling()
	await _check_fit_clamp()
	await _check_reactive_recenter()

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check_centered_panel(label: String, scene_path: String, panel_path: String) -> void:
	var packed := load(scene_path)
	if packed == null:
		_ok(false, "%s scene loads" % label)
		return
	var node: Control = packed.instantiate()
	root.add_child(node)
	node.show()
	await process_frame
	var panel: Control = node.get_node_or_null(panel_path)
	if panel == null or not node.has_method("apply_menu_scale"):
		_ok(false, "%s exposes a scalable panel" % label)
		node.queue_free()
		return

	var view_center: Vector2 = root.get_visible_rect().size * 0.5
	var centered_all := true
	var crisp_all := true
	for factor in LEVELS:
		node.call("apply_menu_scale", factor)
		await process_frame
		# Crisp: the panel must never bitmap-scale; text is sized via the theme.
		if panel.scale != Vector2.ONE:
			crisp_all = false
		var rect: Rect2 = _visual_rect(panel)
		var center: Vector2 = rect.position + rect.size * 0.5
		if center.distance_to(view_center) > 2.0:
			centered_all = false
			print(
				(
					"FAIL %s %.2fx center=%s expected=%s rect=%s"
					% [label, factor, center, view_center, rect]
				)
			)
			break
	_ok(centered_all, "%s stays visually centered at every menu scale" % label)
	_ok(crisp_all, "%s scales type (Control.scale stays 1) not a bitmap stretch" % label)
	node.queue_free()


func _check_context_menu_scale(label: String, scene_path: String) -> void:
	var packed := load(scene_path)
	if packed == null:
		_ok(false, "%s scene loads" % label)
		return
	var node: Control = packed.instantiate()
	root.add_child(node)
	await process_frame
	if not node.has_method("apply_menu_scale"):
		_ok(false, "%s exposes apply_menu_scale" % label)
		node.queue_free()
		return
	node.call("apply_menu_scale", 2.0)
	await process_frame
	# Contextual menus keep their cursor anchor (no recentre) and scale crisply:
	# Control.scale stays 1 and the derived theme drives the larger text.
	var crisp: bool = node.scale == Vector2.ONE
	var themed: bool = node.theme != null and node.theme.default_font_size == BASE_FONT * 2
	_ok(crisp and themed, "%s scales type from its cursor anchor (crisp, scale==1)" % label)
	node.queue_free()


# Crisp mechanism: Control.scale stays 1, the derived theme scales default text,
# explicit font-size overrides scale off a captured base, and re-applying at a new
# factor never compounds (it reads the base, not the last scaled value).
func _check_crisp_type_scaling() -> void:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 20)  # an explicit title-style size
	vbox.add_child(label)
	panel.add_child(vbox)
	root.add_child(panel)
	await process_frame

	MenuScale.apply_to(panel, 2.0, true)
	await process_frame
	_ok(panel.scale == Vector2.ONE, "crisp: Control.scale stays 1 at 2.0x")
	_ok(
		panel.theme != null and panel.theme.default_font_size == BASE_FONT * 2,
		"derived theme scales default font size (16 -> 32) at 2.0x"
	)
	_ok(
		label.get_theme_font_size("font_size") == 40,
		"explicit font-size override scales off its base (20 -> 40) at 2.0x"
	)

	# Re-apply at 1.0: everything returns to base, proving no compounding.
	MenuScale.apply_to(panel, 1.0, true)
	await process_frame
	_ok(
		label.get_theme_font_size("font_size") == 20,
		"override returns to base at 1.0x (re-apply never compounds)"
	)
	panel.queue_free()


# V021-08 (crisp world): a grow-to-content menu taller than the viewport has its
# factor dialled down so it still fits; a small menu reaches the full factor.
func _check_fit_clamp() -> void:
	var vp: Vector2 = root.get_visible_rect().size

	# A PanelContainer whose content is already nearly viewport-tall: scaling to 2.0
	# would overflow, so the clamp must reduce the applied theme factor.
	var tall := PanelContainer.new()
	var tall_box := VBoxContainer.new()
	var rows: int = int(vp.y / float(BASE_FONT)) - 1  # ~fills the height at factor 1
	for i in maxi(rows, 1):
		var row := Label.new()
		row.text = "row %d" % i
		tall_box.add_child(row)
	tall.add_child(tall_box)
	root.add_child(tall)
	await process_frame
	MenuScale.apply_to(tall, 2.0, true)
	await process_frame
	var fits: bool = tall.size.y <= vp.y + 0.5
	var clamped: bool = tall.theme != null and tall.theme.default_font_size < BASE_FONT * 2
	_ok(fits and clamped, "tall menu is clamped to fit the viewport height (V021-08)")
	tall.queue_free()

	var small := PanelContainer.new()
	var small_box := VBoxContainer.new()
	small_box.add_child(Label.new())
	small.add_child(small_box)
	root.add_child(small)
	await process_frame
	MenuScale.apply_to(small, 2.0, true)
	await process_frame
	_ok(
		small.theme != null and small.theme.default_font_size == BASE_FONT * 2,
		"a small menu still scales to the full requested factor (V021-08)"
	)
	small.queue_free()


# V028-03 root cause: a centered panel the ENGINE grows AFTER the initial center used
# to sit off-center until a manual re-apply (the recurring maximize/resize bug). The
# reactive `resized` hook must re-center it with NO further apply_to call.
func _check_reactive_recenter() -> void:
	var view_center: Vector2 = root.get_visible_rect().size * 0.5
	# A Container so its combined_minimum_size tracks the child (a plain Control does not).
	var panel := PanelContainer.new()
	var child := Control.new()
	child.custom_minimum_size = Vector2(200, 120)
	panel.add_child(child)
	root.add_child(panel)
	await process_frame
	MenuScale.apply_to(panel, 1.0, true)
	await process_frame
	# Grow the content: the engine resizes the panel in a later layout pass, which
	# historically left it off-center. Only the reactive hook re-centers here.
	child.custom_minimum_size = Vector2(480, 360)
	await process_frame
	await process_frame
	var rect: Rect2 = _visual_rect(panel)
	var center: Vector2 = rect.position + rect.size * 0.5
	_ok(
		center.distance_to(view_center) <= 2.0,
		"reactive hook re-centers a panel the engine grows after apply (V028-03 root cause)"
	)
	panel.queue_free()


func _visual_rect(control: Control) -> Rect2:
	var xf: Transform2D = control.get_global_transform_with_canvas()
	var points: Array[Vector2] = [
		xf * Vector2.ZERO,
		xf * Vector2(control.size.x, 0.0),
		xf * Vector2(0.0, control.size.y),
		xf * control.size,
	]
	var min_p: Vector2 = points[0]
	var max_p: Vector2 = points[0]
	for p in points:
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)
	return Rect2(min_p, max_p - min_p)
