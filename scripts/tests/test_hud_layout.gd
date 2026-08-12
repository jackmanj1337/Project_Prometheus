extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_hud_layout.gd
# Covers the per-panel HUD layout core (Display & Accessibility item 4): apply_layout,
# set_panel_layout, current_layout, reset_layout, base-position capture, the scale
# clamp, and the on-screen clamp. The drag/scale editor UX itself is playtest-verified
# (mouse-driven), as with AttackPreview positioning — these are the pure seams.

const HUDScene = preload("res://scenes/ui/HUD.tscn")

var _passed := 0
var _failed := 0


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
		_passed += 1
	else:
		print("FAIL ", msg)
		_failed += 1


func _layout_with(hud: Control, panel_id: String, values: Dictionary) -> Dictionary:
	var layout: Dictionary = hud.current_layout()
	for key in values:
		layout["panels"][panel_id][key] = values[key]
	return layout


func _init() -> void:
	print("=== HUD Layout Test ===")
	var hud: Control = HUDScene.instantiate()
	root.add_child(hud)
	# Let _ready + its deferred _apply_saved_layout run and the first layout pass
	# settle, so base positions are captured from the authored .tscn layout.
	await process_frame
	await process_frame

	# ---- apply_layout: offset + scale move/resize the targeted panel ----
	var unit_panel: Control = hud.get_layout_panel("unit_info")
	var phase_panel: Control = hud.get_layout_panel("phase_label")
	_ok(unit_panel != null and phase_panel != null, "layout panels resolve by id")
	var unit_base: Vector2 = unit_panel.position
	var phase_base: Vector2 = phase_panel.position

	# ---- attachment matrix: every panel point x viewport point resolves ----
	var attachment_matrix_ok := true
	for panel_attachment: String in hud.ATTACHMENT_IDS:
		for viewport_attachment: String in hud.ATTACHMENT_IDS:
			var matrix_layout: Dictionary = hud.current_layout()
			var matrix_entry: Dictionary = matrix_layout["panels"]["unit_info"]
			matrix_entry["panel_attachment"] = panel_attachment
			matrix_entry["viewport_attachment"] = viewport_attachment
			matrix_entry["offset"] = Vector2.ZERO
			hud.apply_layout(matrix_layout)
			var expected: Vector2 = hud._position_for_attachments(
				unit_panel, matrix_entry, Vector2.ZERO
			)
			attachment_matrix_ok = attachment_matrix_ok and unit_panel.position == expected
	_ok(attachment_matrix_ok, "all 8x8 panel-to-viewport attachment pairs resolve")
	hud.reset_layout()

	hud.apply_layout(_layout_with(hud, "unit_info", {"offset": Vector2(24, -16), "scale": 1.5}))
	_ok(
		unit_panel.position != unit_base,
		"apply_layout recomputes the targeted panel from its attachment pair"
	)
	_ok(is_equal_approx(unit_panel.scale.x, 1.5), "apply_layout sets the targeted panel scale")
	_ok(
		phase_panel.position == phase_base and is_equal_approx(phase_panel.scale.x, 1.0),
		"apply_layout leaves unlisted panels at their authored base"
	)

	# ---- current_layout: reflects only the changed panel, as offset-from-base ----
	var snapshot: Dictionary = hud.current_layout()
	_ok(
		(
			int(snapshot.get("schema_version", 0)) == hud.HUD_LAYOUT_SCHEMA_VERSION
			and snapshot.get("panels", {}).size() == hud.LAYOUT_PANEL_IDS.size()
		),
		"current_layout carries the versioned attachment schema"
	)
	_ok(
		(
			snapshot["panels"]["unit_info"]["offset"] == Vector2(24, -16)
			and is_equal_approx(snapshot["panels"]["unit_info"]["scale"], 1.5)
		),
		"current_layout records the offset-from-base and scale"
	)

	# ---- reset_layout: restores authored base position + scale ----
	hud.reset_layout()
	_ok(
		unit_panel.position == unit_base and is_equal_approx(unit_panel.scale.x, 1.0),
		"reset_layout restores the authored base layout"
	)
	_ok(
		hud.current_layout()["panels"]["unit_info"]["offset"] == Vector2(8, -78),
		"current_layout restores authored attachments after reset"
	)

	# ---- reset_layout: terrain More Info stays anchored to the compact panel ----
	var terrain_corner: Control = hud.get_layout_panel("terrain_corner")
	var terrain_info: Control = terrain_corner.get_node("TerrainInfoPanel")
	var terrain_base: Vector2 = terrain_info.get_global_rect().end
	hud._terrain_more_page = hud.TERRAIN_PAGE_DESCRIPTION
	hud._render_terrain_page(Vector2i(0, 0), "plain")
	await process_frame
	hud.apply_layout(
		_layout_with(hud, "terrain_corner", {"offset": Vector2(-80, -40), "scale": 1.25})
	)
	await process_frame
	hud.reset_layout()
	await process_frame
	var terrain_after_reset: Vector2 = terrain_info.get_global_rect().end
	_ok(
		(
			terrain_after_reset.distance_to(terrain_base) < 1.0
			and is_equal_approx(terrain_corner.scale.x, 1.0)
		),
		(
			"reset_layout keeps expanded terrain More Info anchored to the compact panel (%s -> %s)"
			% [terrain_base, terrain_after_reset]
		)
	)
	hud._terrain_more_page = hud.TERRAIN_PAGE_HIDDEN
	hud._terrain_more_panel.hide()
	hud.reset_layout()

	# ---- scale clamp: an out-of-range scale is clamped to [MIN, MAX] ----
	hud.apply_layout(_layout_with(hud, "unit_info", {"offset": Vector2.ZERO, "scale": 9.0}))
	_ok(
		is_equal_approx(unit_panel.scale.x, hud.MAX_PANEL_SCALE),
		"apply_layout clamps an oversized scale to MAX_PANEL_SCALE"
	)
	hud.reset_layout()

	# ---- on-screen clamp: a huge offset can't push the panel fully off-screen ----
	var view: Vector2 = hud.get_viewport_rect().size
	hud.apply_layout(
		_layout_with(hud, "unit_info", {"offset": Vector2(100000, 100000), "scale": 1.0})
	)
	_ok(
		unit_panel.position.x <= view.x - 1.0 and unit_panel.position.y <= view.y - 1.0,
		"apply_layout clamps a far offset back on-screen"
	)
	hud.reset_layout()

	# ---- set_panel_layout: single-panel live edit ----
	hud.set_panel_layout("unit_info", Vector2(10, 10), 1.25)
	_ok(
		unit_panel.position != unit_base and is_equal_approx(unit_panel.scale.x, 1.25),
		"set_panel_layout edits one panel live"
	)

	# ---- malformed entry tolerated (non-dict / missing keys / wrong-typed fields) ----
	hud.reset_layout()
	# A dict entry whose offset/scale are the wrong type (e.g. a corrupt cfg) must not
	# crash the typed assignment — the panel stays at base.
	var malformed: Dictionary = hud.current_layout()
	malformed["panels"]["unit_info"] = "garbage"
	malformed["panels"]["objective"] = {}
	malformed["panels"]["turn_label"] = {"offset": "bad", "scale": "also bad"}
	hud.apply_layout(malformed)
	_ok(
		unit_panel.position == unit_base,
		"apply_layout tolerates a malformed entry (uses authored attachment)"
	)
	var turn_panel: Control = hud.get_layout_panel("turn_label")
	_ok(
		is_equal_approx(turn_panel.scale.x, 1.0),
		"apply_layout tolerates wrong-typed offset/scale without crashing"
	)

	# ---- safe-area insets shrink the on-screen clamp (D5/E6) ----
	# A non-zero right/bottom inset must pull the clamp bound further inward than the
	# bare _MIN_VISIBLE_PX edge, proving HUD anchoring reads the single safe-area seam.
	# Desktop/headless insets are ZERO, so this is the only place the path is exercised.
	var sm_node := root.get_node_or_null("/root/SettingsManager")
	if sm_node != null:
		sm_node.safe_area_insets = Vector4i(0, 0, 40, 60)  # right=40, bottom=60
		hud.apply_layout(
			_layout_with(hud, "unit_info", {"offset": Vector2(100000, 100000), "scale": 1.0})
		)
		_ok(
			(
				unit_panel.position.x + unit_panel.size.x <= view.x - 40.0 + 0.5
				and unit_panel.position.y + unit_panel.size.y <= view.y - 60.0 + 0.5
			),
			"safe-area insets keep the full HUD panel reachable (D5/E6)"
		)
		sm_node.safe_area_insets = Vector4i.ZERO  # restore so later autoload reads see zero
		hud.reset_layout()
	else:
		_ok(false, "SettingsManager autoload available for safe-area test")

	hud.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
