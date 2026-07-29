extends SceneTree
# UI-INSPECTION headless preview harness (mockup-only tool, per the 2026-07-10
# session's RESUME note option (c): a throwaway preview scene/script instead of
# guessing at theme margins in the editor).
#
# Renders ActionMenu / UnitDetailsScreen / AttackPreview with mock data into
# res://ui_previews/ (gitignored — these are review artifacts, not content)
# via an offscreen SubViewport, and runs two families of headless-safe checks
# that do NOT depend on GPU pixel output being real:
#   - effective theme resolution: get_theme_stylebox()/get_theme_font() on the
#     live node walks Godot's actual ancestor-theme fallback chain, so it
#     tells the truth about which StyleBox a node will render with even when
#     this container has no GPU. This is what surfaces whether the Mana Soul
#     theme (assets/themes/manasoul_ui.tres) actually reaches a given panel.
#   - layout sanity: Control.get_global_rect() sibling-overlap and
#     viewport-bounds checks (the kind of bug V030-REG-01 was — Main Menu
#     2.0x Continue/title overlap).
# The rendered PNG is still saved and given a best-effort non-blank check, but
# per the RESUME note this container's headless Godot has no GPU, so a
# uniform-color capture is reported as a WARN (inconclusive), not a FAIL —
# treat the Windows-host editor as the visual source of truth (AGENTS.md).
#
# Menu-scale iteration only runs for screens actually wired to
# MenuScale.apply_to(): ActionMenu (targets itself directly) and
# UnitDetailsScreen (its ModalScreen base targets the "Panel" child, NOT the
# themed root — that distinction is exactly what makes the two screens behave
# differently under the same MenuScale code path; see the session note).
# AttackPreview has no menu-scale hook in production code today, so it is
# rendered once at native size.
#
# Run with:
#   godot --headless --path . --script res://scripts/tools/ui_inspection_preview.gd

const GameConstants = preload("res://scripts/shared/GameConstants.gd")

const OUTPUT_DIR := "res://ui_previews"
const VIEWPORT_SIZE := Vector2i(1280, 720)
const MANASOUL_PANEL_TEX := "res://Draft UI assets/tiopalada_tinyrpg_manasoulgui_v_1_0/20250420manaSoul9SlicesA-Sheet.png"
const MANASOUL_BUTTON_TEX := "res://Draft UI assets/tiopalada_tinyrpg_manasoulgui_v_1_0/20250421manaSoulButtonA-Sheet.png"
# Mirrors SettingsManager.MENU_SCALE_LEVELS — duplicated rather than imported
# since SettingsManager is an autoload singleton this tool never boots.
const SCALE_FACTORS: Array[float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

var _ok_count := 0
var _warn_count := 0
var _fail_count := 0

# --- stubs (mirror scripts/tests/test_action_menu.gd and test_attack_preview_selector.gd) ---


class StubActionUnit:
	extends Node
	var data: UnitData
	var _weapon = null
	var _weapons: Array = []
	var tile_position: Vector2i = Vector2i.ZERO
	var team: String = "blue"

	func get_equipped_weapon():
		return _weapon

	func get_equippable_weapons() -> Array:
		return _weapons


class StubActionGrid:
	extends Node
	var enemies: Array = []
	var heal_targets: Array = []

	func get_attackable_enemies_from_tile(_u, _t) -> Array:
		return enemies

	func get_healable_allies(_u) -> Array:
		return heal_targets


class StubDetailsUnit:
	extends Node
	var data: UnitData
	var team: String = "blue"

	func get_effective_stat(stat_name: String) -> int:
		var base = data.get(stat_name)
		var total: int = int(base) if base != null else 0
		for mod in data.active_modifiers:
			if String(mod.get("stat", "")) == stat_name:
				total += int(mod.get("delta", 0))
		return max(0, total)

	func get_stored_weapon_rank(track: String) -> String:
		return GameConstants.weapon_rank_for_wexp(int(data.weapon_wexp.get(track, 0)))

	func is_weapon_track_available(track: String) -> bool:
		return track == "lance"


class StubCombatResolver:
	extends Node
	var preview_data: Dictionary = {}

	func preview_combat(_a: Node, _d: Node) -> Dictionary:
		return preview_data.duplicate(true)


class StubPreviewUnit:
	extends Node2D
	var data = null
	var _weapon = null

	func get_equipped_weapon():
		return _weapon


func _init() -> void:
	print("=== UI-INSPECTION Preview Harness ===")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	# Unlike the scripts/tests/test_*.gd suite (which never lets a frame pass
	# before touching autoloads), this tool awaits several frames per screen —
	# long enough for SceneTree::initialize() to finish spinning up
	# project.godot's real [autoload] singletons (DataManager, GameState,
	# CombatResolver, ...) after this _init() has already started running.
	# DataManager's real data is exactly what UnitDetailsScreen.open() wants,
	# so it's left alone. CombatResolver's real preview_combat() needs a full
	# tile/grid context this mockup doesn't have, so it's swapped for a stub
	# with canned forecast numbers once the real one exists (see
	# _replace_autoload).
	await process_frame

	await _run_action_menu()
	await _run_unit_details()
	await _run_attack_preview()

	print("")
	print("=== Summary: %d OK, %d WARN, %d FAIL ===" % [_ok_count, _warn_count, _fail_count])
	print("PNGs written to: %s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	quit(1 if _fail_count > 0 else 0)


# Frees whatever real autoload singleton is currently at /root/<name> (if any)
# and installs `replacement` in its place under the same name, so subsequent
# get_node_or_null("/root/<name>") lookups from scene code resolve to it.
func _replace_autoload(autoload_name: String, replacement: Node) -> void:
	var existing := root.get_node_or_null(autoload_name)
	if existing != null:
		root.remove_child(existing)
		existing.queue_free()
	replacement.name = autoload_name
	root.add_child(replacement)


# --- viewport / capture -------------------------------------------------------


func _new_viewport(label: String) -> SubViewport:
	var vp := SubViewport.new()
	vp.name = "Preview_%s" % label
	vp.size = VIEWPORT_SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	vp.disable_3d = true
	root.add_child(vp)
	return vp


func _factor_tag(factor: float) -> String:
	return ("%.2f" % factor).replace(".", "_") + "x"


func _capture(vp: SubViewport, name: String) -> void:
	# NOTE: awaiting RenderingServer.frame_post_draw hangs forever under
	# --headless in this container (the render loop never advances without a
	# GPU/display driver) — a few process_frame ticks is the best we get here.
	await process_frame
	await process_frame
	await process_frame
	var img := vp.get_texture().get_image()
	if img == null:
		_warn_count += 1
		print(
			(
				"WARN %s: get_image() returned null — this container's headless Godot has no real rendering driver (see RESUME note), so pixel capture is unavailable here. Structural checks above still hold; verify visually on the Windows host."
				% name
			)
		)
		return
	var path := "%s/%s.png" % [OUTPUT_DIR, name]
	img.save_png(ProjectSettings.globalize_path(path))
	if _is_uniform(img):
		_warn_count += 1
		print(
			(
				"WARN %s: captured image is a single uniform color — GPU rendering may be unavailable in this container; verify visually on the Windows host."
				% name
			)
		)
	else:
		_ok_count += 1
		print(
			(
				"OK   %s: captured non-uniform image (%dx%d)"
				% [name, img.get_width(), img.get_height()]
			)
		)


func _is_uniform(img: Image) -> bool:
	var w := img.get_width()
	var h := img.get_height()
	if w == 0 or h == 0:
		return true
	var first := img.get_pixel(0, 0)
	var step_x: int = max(1, w / 32)
	var step_y: int = max(1, h / 32)
	var x := 0
	while x < w:
		var y := 0
		while y < h:
			if img.get_pixel(x, y) != first:
				return false
			y += step_y
		x += step_x
	return true


# --- effective-theme checks (headless-safe: real Godot theme cascade, no GPU needed) ---


func _texture_source_path(tex: Texture2D) -> String:
	if tex == null:
		return ""
	if tex is AtlasTexture:
		var atlas := (tex as AtlasTexture).atlas
		return atlas.resource_path if atlas != null else ""
	return tex.resource_path


func _describe_stylebox(sb: StyleBox) -> String:
	if sb == null:
		return "<none>"
	if sb is StyleBoxTexture:
		return "StyleBoxTexture(%s)" % _texture_source_path((sb as StyleBoxTexture).texture)
	return sb.get_class()


func _check_effective_style(
	node: Control,
	theme_type: String,
	style_name: String,
	expect_texture_path: String,
	label: String
) -> void:
	var sb := node.get_theme_stylebox(style_name, theme_type)
	var desc := _describe_stylebox(sb)
	var ok := (
		sb is StyleBoxTexture
		and _texture_source_path((sb as StyleBoxTexture).texture) == expect_texture_path
	)
	if ok:
		_ok_count += 1
		print("OK   %s: effective %s/%s = %s" % [label, theme_type, style_name, desc])
	else:
		_fail_count += 1
		print(
			(
				"FAIL %s: effective %s/%s = %s (expected the Mana Soul StyleBoxTexture — theme is not reaching this node)"
				% [label, theme_type, style_name, desc]
			)
		)


# --- layout checks (headless-safe: Control rects, no GPU needed) -------------


func _check_no_sibling_overlap(container: Node, label: String) -> void:
	var rects: Array = []
	for child in container.get_children():
		if child is Control and (child as Control).is_visible_in_tree():
			rects.append([child.name, (child as Control).get_global_rect()])
	var bad := false
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			var a: Rect2 = rects[i][1]
			var b: Rect2 = rects[j][1]
			if a.intersects(b):
				bad = true
				_fail_count += 1
				print(
					"FAIL %s: %s overlaps %s (%s vs %s)" % [label, rects[i][0], rects[j][0], a, b]
				)
	if not bad and not rects.is_empty():
		_ok_count += 1
		print("OK   %s: no sibling overlap among %d visible children" % [label, rects.size()])


func _check_within_viewport(control: Control, viewport_size: Vector2i, label: String) -> void:
	var r := control.get_global_rect()
	if (
		r.position.x < -0.5
		or r.position.y < -0.5
		or r.end.x > viewport_size.x + 0.5
		or r.end.y > viewport_size.y + 0.5
	):
		_fail_count += 1
		print("FAIL %s: rect %s exceeds viewport %s (clipped)" % [label, r, viewport_size])
	else:
		_ok_count += 1
		print("OK   %s: rect %s fits within viewport" % [label, r])


# --- screen runners ------------------------------------------------------------


func _run_action_menu() -> void:
	print("\n--- ActionMenu ---")
	var vp := _new_viewport("ActionMenu")

	var menu: Control = load("res://scenes/ui/ActionMenu.tscn").instantiate()
	vp.add_child(menu)
	await process_frame  # _ready() runs here — MenuScale.apply_to(self, ...) fires immediately

	var unit := StubActionUnit.new()
	unit.data = UnitData.new()
	unit.data.hp = 20
	unit.data.max_hp = 20
	unit._weapon = load("res://data/weapons/iron_sword.tres")
	root.add_child(unit)
	var grid := StubActionGrid.new()
	grid.enemies = [unit]  # non-empty — ActionMenu only checks .size()
	root.add_child(grid)

	for factor in SCALE_FACTORS:
		menu.show_for(unit, grid)
		menu.apply_menu_scale(factor)
		await process_frame
		var tag := "action_menu_%s" % _factor_tag(factor)
		_check_effective_style(
			menu, "PanelContainer", "panel", MANASOUL_PANEL_TEX, "%s panel" % tag
		)
		_check_effective_style(
			menu._btn_attack, "Button", "normal", MANASOUL_BUTTON_TEX, "%s BtnAttack" % tag
		)
		_check_no_sibling_overlap(menu.get_node("VBox"), "%s buttons" % tag)
		_check_within_viewport(menu, VIEWPORT_SIZE, tag)
		await _capture(vp, tag)

	menu.queue_free()
	unit.queue_free()
	grid.queue_free()
	vp.queue_free()


func _run_unit_details() -> void:
	print("\n--- UnitDetailsScreen ---")
	var vp := _new_viewport("UnitDetailsScreen")

	var screen: Control = load("res://scenes/ui/UnitDetailsScreen.tscn").instantiate()
	vp.add_child(screen)
	await process_frame

	var d := UnitData.new()
	d.unit_name = "Preview Knight"
	d.class_id = "soldier"
	d.level = 7
	d.internal_level = 7
	d.strength = 9
	d.movement = 6
	d.defense = 8
	d.growth_rates = {"strength": 20}
	d.growth_accumulators = {"strength": 35}
	d.weapon_wexp = {"lance": 130}
	d.unit_id = "ui_inspection_preview"
	d.active_modifiers = []

	var unit := StubDetailsUnit.new()
	unit.data = d
	root.add_child(unit)

	var panel: Control = screen.get_node("Panel")

	for factor in SCALE_FACTORS:
		screen.open(unit)
		# open() queues call_deferred("_apply_menu_scale_from_settings") for the
		# first-show degenerate-size mitigation (V025-05a) — let that flush at
		# the DEFAULT factor before forcing ours, or it would clobber our factor
		# right back to 1.0 on the next idle frame.
		await process_frame
		screen.apply_menu_scale(factor)
		await process_frame
		var tag := "unit_details_%s" % _factor_tag(factor)
		_check_effective_style(
			panel, "PanelContainer", "panel", MANASOUL_PANEL_TEX, "%s panel" % tag
		)
		_check_within_viewport(panel, VIEWPORT_SIZE, tag)
		await _capture(vp, tag)

	screen.queue_free()
	unit.queue_free()
	vp.queue_free()


func _run_attack_preview() -> void:
	print("\n--- AttackPreview ---")
	var vp := _new_viewport("AttackPreview")

	var resolver := StubCombatResolver.new()
	resolver.name = "CombatResolver"
	resolver.preview_data = {
		"attacker_hit": 90,
		"attacker_damage": 10,
		"attacker_crit": 5,
		"attacker_attacks": 2,
		"attacker_battle_speed": 9,
		"defender_battle_speed": 3,
		"follow_up_threshold": 5,
		"can_counter": true,
		"defender_hit": 40,
		"defender_damage": 6,
		"defender_crit": 0,
		"defender_attacks": 1,
		"attacker_weapon": null,
		"defender_weapon": null,
		"defender_vantage": false,
		"attacker_triangle": "advantage",
		"defender_triangle": "disadvantage",
		"attacker_effective": true,
		"defender_effective": false,
		"attacker_effectiveness_mult": 3.0,
		"defender_effectiveness_mult": 1.0,
	}
	_replace_autoload("CombatResolver", resolver)

	var preview: Control = load("res://scenes/ui/AttackPreview.tscn").instantiate()
	vp.add_child(preview)
	await process_frame

	var attacker := StubPreviewUnit.new()
	attacker.data = UnitData.new()
	attacker.data.unit_name = "Hero"
	attacker.data.hp = 24
	attacker.data.max_hp = 30
	attacker._weapon = load("res://data/weapons/iron_sword.tres")
	root.add_child(attacker)

	var defender := StubPreviewUnit.new()
	defender.data = UnitData.new()
	defender.data.unit_name = "Brigand"
	defender.data.hp = 18
	defender.data.max_hp = 28
	root.add_child(defender)

	preview.show_preview(attacker, defender)
	await process_frame

	var panel: Control = preview.get_node("Panel")
	_check_effective_style(
		panel, "PanelContainer", "panel", MANASOUL_PANEL_TEX, "attack_preview panel"
	)
	_check_within_viewport(panel, VIEWPORT_SIZE, "attack_preview")
	await _capture(vp, "attack_preview_native")

	preview.queue_free()
	resolver.queue_free()
	attacker.queue_free()
	defender.queue_free()
	vp.queue_free()
