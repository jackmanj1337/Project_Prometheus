extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_mrd_scene.gd
#
# Durable headless replication of the 2026-07-05 B6-MRD live-verification pass
# (session note 2026-07-05b), which was run with a throwaway harness and then
# deleted. Boots the SHIPPED GameMap.tscn — real overlay TileMapLayer +
# overlay_tileset.tres, real MapCursor resolver, real InputMap, real
# SettingsManager — and reads back painted cells + state for every MRD feature:
#
#   1. watch resolver paints source 4 (darker red) over a real enemy's threat
#   2. combined mode paints faction (src 3) + watch (src 4), watch wins shares
#   3. the watched-enemy "D" marker renders
#   4. lock() clears the paint but retains state; unlock() repaints
#   5. hover-peek paints as an opaque top layer and clears on release
#   6. path arrows track get_movement_path and clear on deselect
#   7. grid_dim fades the terrain layer ONLY
#   8. the optional stacked overlay lane is wired in the shipped scene
#   9. a simulated gamepad R3 press drives the resolver end-to-end
#
# Pixel-level appearance (colour legibility, "D" glyph, arrow art) still needs
# a real display and stays with the display/controller polish pass.

var _passed := 0
var _failed := 0


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  " + label)
		_passed += 1
	else:
		print("FAIL " + label + ("" if detail == "" else " — " + detail))
		_failed += 1


# Painted overlay cells for one source id, as a Dictionary set of Vector2i.
func _cells_with_source(overlay: TileMapLayer, source_id: int) -> Dictionary:
	var out: Dictionary = {}
	for t in overlay.get_used_cells():
		if overlay.get_cell_source_id(t) == source_id:
			out[t] = true
	return out


func _as_set(tiles: Array[Vector2i]) -> Dictionary:
	var out: Dictionary = {}
	for t in tiles:
		out[t] = true
	return out


# Live (not queued-for-deletion) children — marker/arrow teardown uses
# queue_free, so freshly cleared nodes linger until a frame processes.
func _live_children(parent: Node) -> Array[Node]:
	var out: Array[Node] = []
	if parent == null:
		return out
	for c in parent.get_children():
		if not c.is_queued_for_deletion():
			out.append(c)
	return out


func _init() -> void:
	print("=== MRD Scene Test (headless live-verify replication) ===")

	# Real autoloads, same boot shape as test_game_map_scene.
	for info in [
		["EventBus", "res://scripts/autoloads/EventBus.gd"],
		["SettingsManager", "res://scripts/autoloads/SettingsManager.gd"],
		["DataManager", "res://scripts/autoloads/DataManager.gd"],
		["GameState", "res://scripts/autoloads/GameState.gd"],
	]:
		if root.get_node_or_null(info[0]) == null:
			var n: Node = load(info[1]).new()
			n.name = info[0]
			root.add_child(n)
	await process_frame

	var gs: Node = root.get_node("GameState")
	gs.reset_map_state()
	gs.load_default_roster()
	gs.configure_next_map("res://data/maps/map_001_rout/map_001_data.tres", "default_roster", "")

	var instance: Node = load("res://scenes/core/GameMap.tscn").instantiate()
	root.add_child(instance)
	await process_frame

	var grid: GridManager = instance.get_node("GridManager")
	var cursor: MapCursor = instance.get_node("MapCursor")
	var overlay: TileMapLayer = instance.get_node("TileMapLayer_Overlay")
	var overlay_top: TileMapLayer = instance.get_node("TileMapLayer_OverlayTop")
	var terrain: TileMapLayer = instance.get_node("TileMapLayer_Terrain")

	# A hostile attack-capable enemy the resolver can watch.
	var enemy: Node = null
	for u in instance.get_node("UnitsContainer").get_children():
		if u.team == "red" and u.data != null and u.data.hp > 0 \
				and not grid.get_unit_threat_tiles(u).is_empty():
			enemy = u
			break
	_check(enemy != null, "found a hostile attack-capable enemy on the shipped map")
	if enemy == null:
		_finish()
		return

	# ---- 1. Watch resolver paints source 4 over the enemy's real threat ----
	cursor._state = MapCursor.State.FREE
	cursor._danger_mode = "none"
	cursor._watch_set.clear()
	cursor.current_tile = enemy.tile_position
	cursor._on_danger_zone_press()
	var threat := _as_set(grid.get_unit_threat_tiles(enemy))
	var src4 := _cells_with_source(overlay, GridManager.OVERLAY_DARKER_RED)
	_check(cursor._watch_set.has(enemy.data.unit_id) and cursor._danger_mode == "selected",
		"[TUR] press over the enemy watches it and auto-promotes none→selected",
		"watch=%s mode=%s" % [cursor._watch_set.keys(), cursor._danger_mode])
	_check(not src4.is_empty() and src4.keys().all(func(t): return threat.has(t)) \
			and threat.keys().all(func(t): return src4.has(t)),
		"[TUR] watch paint (src 4) exactly matches get_unit_threat_tiles",
		"painted=%d threat=%d" % [src4.size(), threat.size()])

	# ---- 2. Combined mode: faction src 3 + watch src 4, watch wins shares ----
	cursor._danger_mode = "combined"
	cursor.repaint()
	var faction := _as_set(grid.get_enemy_danger_tiles("blue"))
	src4 = _cells_with_source(overlay, GridManager.OVERLAY_DARKER_RED)
	var src3 := _cells_with_source(overlay, GridManager.OVERLAY_DARK_RED)
	var watch_wins := threat.keys().all(func(t): return src4.has(t) and not src3.has(t))
	var faction_rest := true
	for t in faction.keys():
		if not threat.has(t) and not src3.has(t):
			faction_rest = false
			break
	_check(not src3.is_empty() and not src4.is_empty() and watch_wins and faction_rest,
		"[MRD-1] combined paints faction(src3)+watch(src4); watch wins shared cells",
		"src3=%d src4=%d wins=%s rest=%s" % [src3.size(), src4.size(), watch_wins, faction_rest])

	# ---- 3. The watched-enemy "D" marker renders in world space ----
	var markers := _live_children(instance.find_child("WatchMarkers", true, false))
	var marker_ok: bool = markers.size() == 1 and markers[0] is Label and markers[0].text == "D"
	_check(marker_ok, "[TUR-2] one \"D\" marker Label rendered for the watched enemy",
		"live markers=%d" % markers.size())

	# ---- 4. lock() clears paint + markers but retains state; unlock repaints ----
	cursor.lock()
	await process_frame  # let queued marker frees process
	var locked_clear := overlay.get_used_cells().is_empty() \
		and _live_children(instance.find_child("WatchMarkers", true, false)).is_empty()
	var retained := cursor._watch_set.has(enemy.data.unit_id) and cursor._danger_mode == "combined"
	cursor.unlock()
	src4 = _cells_with_source(overlay, GridManager.OVERLAY_DARKER_RED)
	var repainted := threat.keys().all(func(t): return src4.has(t))
	_check(locked_clear and retained and repainted,
		"[TUR] lock clears paint, retains watch-set + mode; unlock repaints",
		"clear=%s retained=%s repainted=%s" % [locked_clear, retained, repainted])

	# ---- 5. Hover-peek paints as an opaque top layer, release restores ----
	# With the faction threat showing, a peek over the enemy must WIN its shared
	# cells (precedence 100/101 vs 20), then hand them back on release.
	cursor._danger_mode = "full"
	cursor._watch_set.clear()
	cursor.repaint()
	cursor.current_tile = enemy.tile_position
	cursor._begin_peek()
	var peek_move := _as_set(cursor._peek_move)
	var shared: Variant = null
	for t in peek_move.keys():
		if faction.has(t):
			shared = t
			break
	var peek_painted := not peek_move.is_empty() \
		and overlay.get_cell_source_id(peek_move.keys()[0]) in \
			[GridManager.OVERLAY_BLUE, GridManager.OVERLAY_RED]
	var peek_wins := shared != null and overlay.get_cell_source_id(shared) == GridManager.OVERLAY_BLUE
	cursor._end_peek()
	var restored := shared != null \
		and overlay.get_cell_source_id(shared) == GridManager.OVERLAY_DARK_RED
	_check(peek_painted and peek_wins and restored,
		"[MRD-2] peek paints opaque on top of threat and restores it on release",
		"painted=%s wins=%s restored=%s" % [peek_painted, peek_wins, restored])
	cursor._danger_mode = "none"
	cursor.repaint()

	# ---- 6. Path arrows track get_movement_path; clear on deselect ----
	var mover: Node = null
	var dest := Vector2i.ZERO
	for u in gs.get_living_player_units():
		for t in grid.get_movement_range(u):
			if grid.get_movement_path(u, t).size() >= 3:
				mover = u
				dest = t
				break
		if mover != null:
			break
	_check(mover != null, "found a player unit with a ≥3-step reachable path")
	if mover != null:
		cursor.current_tile = mover.tile_position
		cursor._try_select_unit_at_cursor()
		cursor._set_tile(dest)  # real cursor move → cursor_moved → arrow refresh
		var want_path := grid.get_movement_path(mover, dest)
		var path_ok: bool = cursor._state == MapCursor.State.UNIT_SELECTED \
			and cursor._path_arrow_tiles == want_path
		var lines := _live_children(instance.find_child("PathArrows", true, false))
		var line_ok: bool = lines.size() == 1 and lines[0] is Line2D \
			and lines[0].get_point_count() == want_path.size()
		cursor._deselect()
		var arrows_cleared: bool = cursor._path_arrow_tiles.is_empty() \
			and _live_children(instance.find_child("PathArrows", true, false)).is_empty()
		_check(path_ok and line_ok and arrows_cleared,
			"[MRD-4] path arrows == get_movement_path, one polyline, cleared on deselect",
			"path=%s line=%s cleared=%s" % [path_ok, line_ok, arrows_cleared])

	# ---- 7. grid_dim fades the terrain layer ONLY ----
	# Direct field + _apply_grid_dim() is the slider's apply path minus the
	# user:// save (tests must not write the shared settings.cfg — run_tests.sh).
	var sm: Node = root.get_node("SettingsManager")
	sm.grid_dim = 0.4
	sm._apply_grid_dim()
	var dimmed: bool = absf(terrain.modulate.a - 0.6) < 0.001
	var others_full: bool = overlay.modulate.a == 1.0 \
		and overlay_top.modulate.a == 1.0 \
		and instance.get_node("UnitsContainer").modulate.a == 1.0
	sm.grid_dim = 0.0
	sm._apply_grid_dim()
	var undimmed: bool = terrain.modulate.a == 1.0
	_check(dimmed and others_full and undimmed,
		"[MRD-5] grid_dim 0.4 → terrain a=0.6, overlays/units untouched, 0.0 restores",
		"dim=%s others=%s undo=%s" % [dimmed, others_full, undimmed])

	# ---- 8. Optional stacked-perimeter overlay lane is wired in the shipped scene ----
	var shared_tile := Vector2i(2, 2)
	var adjacent_threat := Vector2i(2, 3)
	var lane_specs := {
		GridManager.OVERLAY_LAYER_MOVE: {
			"tiles": [shared_tile] as Array[Vector2i],
			"source": GridManager.OVERLAY_BLUE,
		},
		GridManager.OVERLAY_LAYER_WATCH_THREAT: {
			"tiles": [shared_tile, adjacent_threat] as Array[Vector2i],
			"source": GridManager.OVERLAY_DARKER_RED,
		},
	}
	grid.set_shared_cell_mode(GridManager.SHARED_CELL_STACKED_PERIMETER)
	grid.repaint_overlays(lane_specs)
	var expected_mask: int = GridManager.PERIMETER_EDGE_TOP \
		| GridManager.PERIMETER_EDGE_RIGHT | GridManager.PERIMETER_EDGE_LEFT
	var expected_perimeter_source: int = GridManager.threat_perimeter_source(
		GridManager.OVERLAY_DARKER_RED, expected_mask)
	var lane_base_source := overlay.get_cell_source_id(shared_tile)
	var lane_top_source := overlay_top.get_cell_source_id(shared_tile)
	var lane_ok: bool = lane_base_source == expected_perimeter_source \
		and lane_top_source == GridManager.OVERLAY_BLUE
	grid.set_shared_cell_mode(GridManager.SHARED_CELL_SINGLE)
	grid.clear_overlays()
	_check(lane_ok,
		"[MRD-7] shipped GameMap wires the stacked-perimeter overlay lane",
		"base=%d top=%d" % [lane_base_source, lane_top_source])

	# ---- 9. Simulated gamepad R3 drives the resolver end-to-end ----
	# R3 is bound at test runtime (the real project.godot pad bindings land with
	# gamepad plan slice 1); the press goes through the engine input pipeline,
	# not a direct method call, so this covers dispatch → MapCursor._input.
	var r3_bind := InputEventJoypadButton.new()
	r3_bind.button_index = JOY_BUTTON_RIGHT_STICK
	r3_bind.device = -1
	InputMap.action_add_event("show_danger_zone", r3_bind)
	cursor._state = MapCursor.State.FREE
	cursor._danger_mode = "none"
	cursor._watch_set.clear()
	cursor.repaint()
	cursor.current_tile = enemy.tile_position
	var r3_press := InputEventJoypadButton.new()
	r3_press.button_index = JOY_BUTTON_RIGHT_STICK
	r3_press.pressed = true
	Input.parse_input_event(r3_press)
	Input.flush_buffered_events()
	await process_frame
	src4 = _cells_with_source(overlay, GridManager.OVERLAY_DARKER_RED)
	_check(cursor._watch_set.has(enemy.data.unit_id) and not src4.is_empty(),
		"[PAD] engine-dispatched R3 press watches the enemy and paints src 4",
		"watch=%s src4=%d" % [cursor._watch_set.keys(), src4.size()])
	InputMap.action_erase_event("show_danger_zone", r3_bind)

	_finish()


func _finish() -> void:
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
