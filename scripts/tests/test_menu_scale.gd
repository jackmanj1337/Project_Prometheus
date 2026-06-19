extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_menu_scale.gd
# Verifies Menu Scale stays local to menu/modal panels and preserves centering at
# every supported scale. HUD layout is covered separately by test_hud_layout.gd.

const MenuScale = preload("res://scripts/ui/MenuScale.gd")
const LEVELS: Array[float] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

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
		["NewGameScreen", "res://scenes/ui/NewGameScreen.tscn", "Panel"],
		["PromotionScreen", "res://scenes/ui/PromotionScreen.tscn", "Panel"],
		["ReclassScreen", "res://scenes/ui/ReclassScreen.tscn", "Panel"],
		["LevelUpScreen", "res://scenes/ui/LevelUpScreen.tscn", "Panel"],
		["GameOverScreen", "res://scenes/ui/GameOverScreen.tscn", "Panel"],
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
	for factor in LEVELS:
		node.call("apply_menu_scale", factor)
		await process_frame
		var rect: Rect2 = _visual_rect(panel)
		var center: Vector2 = rect.position + rect.size * 0.5
		if center.distance_to(view_center) > 2.0:
			centered_all = false
			print("FAIL %s %.2fx center=%s expected=%s rect=%s" % [
				label, factor, center, view_center, rect])
			break
	_ok(centered_all, "%s stays visually centered at every menu scale" % label)
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
	var scales_from_top_left: bool = node.scale == Vector2(2.0, 2.0) \
		and node.pivot_offset == Vector2.ZERO
	_ok(scales_from_top_left, "%s scales from top-left for cursor anchoring" % label)
	node.queue_free()


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
