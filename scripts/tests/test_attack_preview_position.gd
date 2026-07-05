extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_attack_preview_position.gd
# Verifies the 2026-05-24d CameraController.pan_by_pixels addition. The full
# screen-space positioning logic in AttackPreview is verified by playtest
# because get_global_transform_with_canvas() and PanelContainer auto-sizing
# do not return useful values in a SceneTree script without a continuously-
# ticking main loop. test_targeting.gd already proves show_preview /
# hide_preview do not crash in an instantiated GameMap scene.

const GameConstants    = preload("res://scripts/shared/GameConstants.gd")
const CameraController = preload("res://scripts/core/CameraController.gd")
const AttackPreviewS   = preload("res://scripts/ui/AttackPreview.gd")


class StubGrid extends Node:
	var map_width: int = 0
	var map_height: int = 0


# GridManager stand-in with the tile<->world math CameraController's framing
# needs (mirrors GridManager.tile_to_world / world_to_tile). Sized like the
# playtest map so both walls are farther apart than any zoomed view span.
class WallGrid extends Node:
	const MAP_W := 42
	const MAP_H := 26
	var map_width: int = MAP_W
	var map_height: int = MAP_H

	func tile_to_world(tile: Vector2i) -> Vector2:
		return Vector2(tile.x * GameConstants.TILE_SIZE, tile.y * GameConstants.TILE_SIZE)

	func world_to_tile(world: Vector2) -> Vector2i:
		return Vector2i(
			int(world.x) / GameConstants.TILE_SIZE, int(world.y) / GameConstants.TILE_SIZE)


func _init() -> void:
	print("=== AttackPreview Positioning Test ===")
	var passed := 0
	var failed := 0

	var cam := Camera2D.new()
	root.add_child(cam)
	cam.position = Vector2(640, 360)

	var grid := StubGrid.new()
	grid.map_width = 40   # 40 * 64 = 2560 px wide
	grid.map_height = 30  # 30 * 64 = 1920 px tall
	root.add_child(grid)

	# Camera2D.get_viewport() returns null until the main loop has processed
	# the ENTER_TREE notification, even when add_child has already returned.
	# A single process_frame await lets the camera bind to its viewport so
	# CameraController.pan_by_pixels can read the visible-rect size.
	await process_frame

	var cc := CameraController.new()
	cc.setup(cam, grid)
	var view: Vector2 = root.get_visible_rect().size
	var half := view * 0.5

	# ---- pan_by_pixels: mid-map shift is exact -----------------------
	var before: Vector2 = cam.position
	cc.pan_by_pixels(Vector2(100, 0))
	if cam.position == before + Vector2(100, 0):
		print("OK  pan_by_pixels mid-map shifts by exact delta"); passed += 1
	else:
		print("FAIL pan_by_pixels mid-map: %s -> %s" % [before, cam.position])
		failed += 1

	# ---- pan_by_pixels: clamp to left map edge -----------------------
	cc.pan_by_pixels(Vector2(-10000, 0))
	if cam.position.x == half.x:
		print("OK  pan_by_pixels clamps to left map edge"); passed += 1
	else:
		print("FAIL left clamp: %f (expected %f)" % [cam.position.x, half.x])
		failed += 1

	# ---- pan_by_pixels: clamp to right map edge ----------------------
	cc.pan_by_pixels(Vector2(10000, 0))
	var map_right: float = float(grid.map_width * GameConstants.TILE_SIZE) - half.x
	if cam.position.x == map_right:
		print("OK  pan_by_pixels clamps to right map edge"); passed += 1
	else:
		print("FAIL right clamp: %f (expected %f)" % [cam.position.x, map_right])
		failed += 1

	# ---- pan_by_pixels: clamp to top map edge ------------------------
	cc.pan_by_pixels(Vector2(0, -10000))
	if cam.position.y == half.y:
		print("OK  pan_by_pixels clamps to top map edge"); passed += 1
	else:
		print("FAIL top clamp: %f (expected %f)" % [cam.position.y, half.y])
		failed += 1

	# ---- pan_by_pixels: clamp to bottom map edge ---------------------
	cc.pan_by_pixels(Vector2(0, 10000))
	var map_bottom: float = float(grid.map_height * GameConstants.TILE_SIZE) - half.y
	if cam.position.y == map_bottom:
		print("OK  pan_by_pixels clamps to bottom map edge"); passed += 1
	else:
		print("FAIL bottom clamp: %f (expected %f)" % [cam.position.y, map_bottom])
		failed += 1

	# ---- pan_by_pixels: zero delta is a no-op ------------------------
	var before_zero := cam.position
	cc.pan_by_pixels(Vector2.ZERO)
	if cam.position == before_zero:
		print("OK  pan_by_pixels zero delta is a no-op"); passed += 1
	else:
		print("FAIL zero delta moved camera"); failed += 1

	# ---- pan_by_pixels: null camera / grid -> no crash ---------------
	var bare := CameraController.new()
	bare.pan_by_pixels(Vector2(50, 50))
	print("OK  pan_by_pixels without setup() is a safe no-op"); passed += 1

	# ── _place_clear_of: HUD-avoidance placement (playtest v0.1.4 #2.4) ──────────
	# Pure helper, unit-testable without canvas transforms. view = 1280x720, margin 16.
	var vw := Vector2(1280, 720)
	var psize := Vector2(200, 170)
	var m := 16.0
	var unit_info := Rect2(8, 610, 300, 102)   # bottom-left HUD panel
	var objective := Rect2(8, 48, 292, 92)      # top-left HUD panel

	# 1) No avoid rects → position unchanged (already inside the viewport).
	var p_noavoid: Vector2 = AttackPreviewS._place_clear_of(Vector2(400, 300), psize, vw, [] as Array[Rect2], m)
	if p_noavoid == Vector2(400, 300):
		print("OK  _place_clear_of: no avoid rects leaves an in-view position unchanged"); passed += 1
	else:
		print("FAIL no-avoid: %s" % p_noavoid); failed += 1

	# 2) Overlapping the bottom-left unit-info panel → pushed ABOVE it (no room below).
	var p_bottom: Vector2 = AttackPreviewS._place_clear_of(Vector2(8, 600), psize, vw, [unit_info] as Array[Rect2], m)
	if p_bottom.y == unit_info.position.y - psize.y - m and not Rect2(p_bottom, psize).intersects(unit_info):
		print("OK  _place_clear_of: pushes the panel above the bottom HUD panel"); passed += 1
	else:
		print("FAIL bottom-avoid: %s (want y=%f)" % [p_bottom, unit_info.position.y - psize.y - m]); failed += 1

	# 3) Overlapping the top objective panel → pushed BELOW it (no room above).
	var p_top: Vector2 = AttackPreviewS._place_clear_of(Vector2(8, 40), psize, vw, [objective] as Array[Rect2], m)
	if p_top.y == objective.position.y + objective.size.y + m and not Rect2(p_top, psize).intersects(objective):
		print("OK  _place_clear_of: pushes the panel below the top HUD panel"); passed += 1
	else:
		print("FAIL top-avoid: %s (want y=%f)" % [p_top, objective.position.y + objective.size.y + m]); failed += 1

	# 4) An off-viewport desired position is clamped back inside.
	var p_clamp: Vector2 = AttackPreviewS._place_clear_of(Vector2(5000, 5000), psize, vw, [] as Array[Rect2], m)
	if p_clamp.x == vw.x - psize.x - m and p_clamp.y == vw.y - psize.y - m:
		print("OK  _place_clear_of: clamps an off-screen position back into the viewport"); passed += 1
	else:
		print("FAIL clamp: %s" % p_clamp); failed += 1

	# 5) Defender tile avoidance uses the same helper path as HUD avoidance, so a
	# forecast that starts over the defender slides clear instead of hiding the unit.
	var defender_rect := AttackPreviewS._defender_avoid_rect(Vector2(640, 320), 64.0)
	var p_defender: Vector2 = AttackPreviewS._place_clear_of(Vector2(620, 300),
		psize, vw, [defender_rect] as Array[Rect2], m)
	if not Rect2(p_defender, psize).intersects(defender_rect):
		print("OK  _place_clear_of: pushes the panel clear of the defender tile"); passed += 1
	else:
		print("FAIL defender-avoid: %s still intersects %s" % [p_defender, defender_rect])
		failed += 1

	# ── V025-04c: reposition() re-anchor hook contract ──────────────────────────
	# The screen-space placement is playtest-verified (canvas transforms don't
	# resolve headless), but the hook's guards are unit-testable: reposition() must
	# no-op when hidden/unanchored, and hide_preview() must clear the anchor defender
	# so a zoom change never re-anchors to a stale unit.
	var preview_packed := load("res://scenes/ui/AttackPreview.tscn")
	if preview_packed != null:
		var preview: Control = preview_packed.instantiate()
		root.add_child(preview)
		await process_frame
		preview.reposition()  # hidden + no anchor defender: must be a safe no-op
		var noop_safe: bool = not preview.visible and preview._anchor_defender == null
		preview._anchor_defender = grid  # pretend anchored to some node
		preview.hide_preview()
		if noop_safe and preview._anchor_defender == null:
			print("OK  V025-04c reposition no-ops when hidden; hide_preview clears the anchor")
			passed += 1
		else:
			print("FAIL reposition/anchor contract: noop_safe=%s anchor=%s" % [
				noop_safe, preview._anchor_defender]); failed += 1
		preview.queue_free()
	else:
		print("FAIL could not load AttackPreview.tscn"); failed += 1

	# ── V027-03a: deferred first-show sizing re-pass contract ───────────────────
	# The inflated-RichTextLabel first show is a rendered-layout artifact (playtest
	# verified), so headless we verify the mechanism instead: _resize_after_layout
	# holds the panel transparent for one frame, re-seeds the panel height off the
	# settled minimums, restores alpha, and a superseded (stale) pass bails without
	# clobbering the alpha a newer pass is holding.
	var pv_packed := load("res://scenes/ui/AttackPreview.tscn")
	if pv_packed != null:
		var pv: Control = pv_packed.instantiate()
		root.add_child(pv)
		await process_frame
		pv.show()
		pv._anchor_defender = grid
		# Simulate the frozen over-tall first-show frame.
		pv._panel.offset_bottom = pv._panel.offset_top + 500.0
		pv._resize_after_layout()
		var held_transparent: bool = pv._panel.modulate.a == 0.0
		await process_frame
		await process_frame  # the re-pass resumes on the first tick; settle one more
		var repass_h: float = pv._panel.offset_bottom - pv._panel.offset_top
		var reseeded: bool = absf(repass_h - AttackPreviewS.PANEL_DEFAULT_HEIGHT) <= 0.5
		var alpha_restored: bool = pv._panel.modulate.a == 1.0
		# Generation guard: two passes in the same frame — only the newest restores.
		pv._resize_after_layout()
		pv._resize_after_layout()
		await process_frame
		await process_frame
		var guard_ok: bool = pv._panel.modulate.a == 1.0
		if held_transparent and reseeded and alpha_restored and guard_ok:
			print("OK  V027-03a deferred re-pass re-seeds height, restores alpha, guards stale passes")
			passed += 1
		else:
			print("FAIL V027-03a re-pass: transparent=%s h=%f reseeded=%s alpha=%s guard=%s" % [
				held_transparent, repass_h, reseeded, alpha_restored, guard_ok])
			failed += 1
		pv.queue_free()
	else:
		print("FAIL could not load AttackPreview.tscn for V027-03a"); failed += 1

	# ── V027-03b repro: wall placement at high zoom against a REAL current camera ─
	# The v0.2.7 tester reported the right-wall misplacement fixed but "the same
	# thing on the left wall" at max zoom. This drives the real placement path
	# headless — current camera, flushed canvas transform (the V026-03/04a seam),
	# real AttackPreview scene — sweeping defender tiles on both walls across the
	# high zoom levels. The panel must land inside the viewport, clear of the
	# defender's tile, and ADJACENT to it (beside either edge, or right-flush when
	# the pan branch made room) — "somewhere on screen but away from the unit" is
	# exactly the reported bug, so adjacency is the load-bearing assert.
	var cam2 := Camera2D.new()
	root.add_child(cam2)
	cam2.make_current()
	var grid2 := WallGrid.new()
	root.add_child(grid2)
	await process_frame
	var cc2: RefCounted = CameraController.new()
	cc2.setup(cam2, grid2)
	var pv2_packed := load("res://scenes/ui/AttackPreview.tscn")
	var pv2: Control = pv2_packed.instantiate()
	root.add_child(pv2)
	await process_frame
	pv2.setup(cam2, grid2, cc2)
	pv2.show()
	pv2._size_panel_to_content()
	await process_frame  # settle the panel's container minimum
	var defender2 := Node2D.new()
	root.add_child(defender2)
	var view2: Vector2 = root.get_visible_rect().size
	var margin2: float = float(AttackPreviewS.PANEL_MARGIN_PX)
	var sweep_failed := 0
	for wall_x in [0, 1, 2, WallGrid.MAP_W - 1]:
		for zoom_idx in [5, 6, 7]:  # 2.0× / 3.0× / 4.0× — the high-zoom band
			var t := Vector2i(wall_x, 13)
			defender2.position = grid2.tile_to_world(t)
			cc2.set_zoom_index(zoom_idx, t)
			pv2._anchor_defender = defender2
			pv2._reposition_for(defender2)
			var tpx: float = float(GameConstants.TILE_SIZE) * cc2.get_zoom()
			# Re-read AFTER placement — the pan branch may have moved the camera.
			var dscr: Vector2 = defender2.get_global_transform_with_canvas().origin
			var panel_sz: Vector2 = Vector2(pv2._panel.offset_right - pv2._panel.offset_left,
				pv2._panel.offset_bottom - pv2._panel.offset_top)
			var ppos: Vector2 = pv2._panel.position
			var def_rect := Rect2(dscr, Vector2(tpx, tpx))
			var in_view: bool = ppos.x >= 0.0 and ppos.y >= 0.0 \
				and ppos.x + panel_sz.x <= view2.x and ppos.y + panel_sz.y <= view2.y
			var clear2: bool = not Rect2(ppos, panel_sz).intersects(def_rect)
			var beside_right: bool = absf(ppos.x - (dscr.x + tpx + margin2)) <= 1.0
			var beside_left: bool = absf((ppos.x + panel_sz.x + margin2) - dscr.x) <= 1.0
			var pan_flush: bool = absf(ppos.x - (view2.x - margin2 - panel_sz.x)) <= 1.0
			if not (in_view and clear2 and (beside_right or beside_left or pan_flush)):
				sweep_failed += 1
				print("FAIL V027-03b wall sweep: tile=%s zoom=%.2f panel=%s size=%s def_screen=%s in_view=%s clear=%s right=%s left=%s pan=%s" % [
					t, cc2.get_zoom(), ppos, panel_sz, dscr, in_view, clear2,
					beside_right, beside_left, pan_flush])
	if sweep_failed == 0:
		print("OK  V027-03b wall sweep: panel adjacent + clear of defender on both walls at high zoom")
		passed += 1
	else:
		failed += sweep_failed

	# Same-frame placement after a cursor-driven scroll (keep_cursor_in_view):
	# every other camera write callers read synchronously flushes the canvas
	# transform (V026-03/04a); a placement in the same frame as a cursor scroll
	# must see the settled view too, or the panel lands offset by the scroll delta.
	cc2.set_zoom_index(7, Vector2i(20, 13))
	await process_frame  # settle mid-map, far from the wall
	var t_wall := Vector2i(0, 13)
	defender2.position = grid2.tile_to_world(t_wall)
	cc2.keep_cursor_in_view(t_wall, 2)  # cursor scroll to the left wall — no await
	pv2._reposition_for(defender2)      # same-frame read
	var tpx_w: float = float(GameConstants.TILE_SIZE) * cc2.get_zoom()
	var dscr_w: Vector2 = defender2.get_global_transform_with_canvas().origin
	var psize_w: Vector2 = Vector2(pv2._panel.offset_right - pv2._panel.offset_left,
		pv2._panel.offset_bottom - pv2._panel.offset_top)
	var ppos_w: Vector2 = pv2._panel.position
	var clear_w: bool = not Rect2(ppos_w, psize_w).intersects(Rect2(dscr_w, Vector2(tpx_w, tpx_w)))
	var beside_w: bool = absf(ppos_w.x - (dscr_w.x + tpx_w + margin2)) <= 1.0 \
		or absf((ppos_w.x + psize_w.x + margin2) - dscr_w.x) <= 1.0 \
		or absf(ppos_w.x - (view2.x - margin2 - psize_w.x)) <= 1.0
	if clear_w and beside_w:
		print("OK  V027-03b same-frame cursor-scroll placement reads a settled transform")
		passed += 1
	else:
		print("FAIL V027-03b same-frame scroll: panel=%s size=%s def_screen=%s clear=%s beside=%s" % [
			ppos_w, psize_w, dscr_w, clear_w, beside_w])
		failed += 1
	pv2.queue_free(); cam2.queue_free(); grid2.queue_free(); defender2.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
