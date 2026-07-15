extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_camera_controller.gd
# Guards the zoom-aware CameraController refactor (Display & Accessibility item 1a).
# The controller does all its tile/pan math in WORLD units; before this refactor it
# sized the view from raw viewport PIXELS, which is only correct at zoom == 1. These
# tests pin (a) parity at zoom 1 — the behaviour-neutral guarantee — and (b) correct
# framing/clamping at other zoom levels. View size is read from the live viewport
# rather than hardcoded so the asserts hold regardless of the host window size.

const CameraControllerS = preload("res://scripts/core/CameraController.gd")
const GameConstants = preload("res://scripts/shared/GameConstants.gd")

const MAP_W := 40  # tiles — larger than the viewport so the edge clamp is exercised
const MAP_H := 30


# Minimal GridManager stand-in: just the surface CameraController reads. Tile<->world
# math mirrors GridManager.tile_to_world / world_to_tile (integer division by TILE_SIZE).
class GridStub extends Node:
	var map_width: int = MAP_W
	var map_height: int = MAP_H

	func tile_to_world(tile: Vector2i) -> Vector2:
		return Vector2(tile.x * GameConstants.TILE_SIZE, tile.y * GameConstants.TILE_SIZE)

	func world_to_tile(world: Vector2) -> Vector2i:
		return Vector2i(
			int(world.x) / GameConstants.TILE_SIZE, int(world.y) / GameConstants.TILE_SIZE)


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
	print("=== CameraController Test ===")

	var cam := Camera2D.new()
	root.add_child(cam)
	var grid := GridStub.new()
	root.add_child(grid)

	# Camera2D.get_viewport() returns null until the main loop has processed the
	# ENTER_TREE notification, even after add_child returns (see test_attack_preview_
	# position.gd). One process_frame await lets the camera bind to its viewport.
	await process_frame

	var cc: RefCounted = CameraControllerS.new()
	cc.setup(cam, grid)

	var tile: int = GameConstants.TILE_SIZE
	var view_px: Vector2 = root.get_visible_rect().size
	var far := Vector2i(MAP_W - 1, MAP_H - 1)  # bottom-right corner tile

	# ---- _visible_world_size: viewport px at zoom 1, scaled by 1/zoom otherwise ----
	cam.zoom = Vector2.ONE
	_ok(cc._visible_world_size() == view_px,
		"_visible_world_size == viewport px at zoom 1")
	cam.zoom = Vector2(2, 2)
	_ok(cc._visible_world_size() == view_px * 0.5,
		"_visible_world_size halves at zoom 2x")
	cam.zoom = Vector2(0.5, 0.5)
	_ok(cc._visible_world_size() == view_px * 2.0,
		"_visible_world_size doubles at zoom 0.5x")

	# ---- zoom-awareness: visible tile count scales with 1/zoom ----
	cam.zoom = Vector2.ONE
	var tiles_1x: int = int(cc._visible_world_size().x / tile)
	cam.zoom = Vector2(2, 2)
	var tiles_2x: int = int(cc._visible_world_size().x / tile)
	cam.zoom = Vector2(0.5, 0.5)
	var tiles_half: int = int(cc._visible_world_size().x / tile)
	_ok(tiles_2x < tiles_1x and tiles_half > tiles_1x,
		"visible tile count shrinks at 2x and grows at 0.5x (was fixed before)")

	# ---- framing (zoom 1): keep_cursor_in_view frames the cursor, stays in bounds ----
	cam.zoom = Vector2.ONE
	cam.position = view_px * 0.5  # top-left of view at world origin
	cc.keep_cursor_in_view(far, 2)
	_ok(cc.clamp_tile_to_view(far) == far,
		"cursor tile is framed after keep_cursor_in_view (zoom 1)")
	var tl1: Vector2i = grid.world_to_tile(cam.position - cc._visible_world_size() * 0.5)
	_ok(tl1.x >= 0 and tl1.y >= 0,
		"view never scrolls past the top-left map edge (zoom 1)")

	# ---- framing (zoom 2x): still frames the cursor using the narrower span ----
	cam.zoom = Vector2(2, 2)
	cam.position = view_px * 0.25  # top-left at origin for the 2x span
	cc.keep_cursor_in_view(far, 2)
	_ok(cc.clamp_tile_to_view(far) == far,
		"cursor tile is framed after keep_cursor_in_view (zoom 2x)")

	# ---- clamp_tile_to_view: a tile just past the 2x span is pulled back in ----
	# At 2x the view is half as many tiles wide; a tile that sits comfortably on
	# screen at 1x can be off the right edge at 2x and must clamp to the edge.
	cam.zoom = Vector2(2, 2)
	cam.position = view_px * 0.25
	var clamped: Vector2i = cc.clamp_tile_to_view(far)
	var tl2: Vector2i = grid.world_to_tile(cam.position - cc._visible_world_size() * 0.5)
	var right_edge: int = tl2.x + int(cc._visible_world_size().x / tile) - 1
	_ok(clamped.x <= right_edge,
		"clamp_tile_to_view respects the narrower span at 2x")

	# ---- pan_by_pixels: argument is SCREEN px, converted to world via 1/zoom ----
	# Map world = 2560x1920; the positions below are mid-map so the clamp never bites.
	cam.zoom = Vector2(2, 2)
	cam.position = Vector2(900, 600)
	cc.pan_by_pixels(Vector2(100, 0))
	_ok(is_equal_approx(cam.position.x, 950.0),
		"pan_by_pixels: 100 screen px -> 50 world units at 2x")
	cam.zoom = Vector2.ONE
	cam.position = Vector2(900, 600)
	cc.pan_by_pixels(Vector2(100, 0))
	_ok(is_equal_approx(cam.position.x, 1000.0),
		"pan_by_pixels: 1:1 at zoom 1 (parity)")

	# ---- zoom API: levels, default, stepping, clamping ----
	_ok(cc.get_zoom_count() == 8, "get_zoom_count == 8 levels")
	cam.zoom = Vector2.ONE
	cc.set_zoom_index_silent(cc.DEFAULT_ZOOM_INDEX)
	_ok(cc.get_zoom_index() == cc.DEFAULT_ZOOM_INDEX and is_equal_approx(cc.get_zoom(), 1.0),
		"default zoom index is 1.0x")
	_ok(is_equal_approx(cam.zoom.x, 1.0), "set_zoom_index_silent applies Camera2D.zoom")
	# step_zoom changes the level and the Camera2D zoom.
	cc.set_zoom_index(cc.DEFAULT_ZOOM_INDEX, Vector2i(5, 5))
	cc.step_zoom(1, Vector2i(5, 5))
	_ok(is_equal_approx(cam.zoom.x, 1.5), "step_zoom(+1) moves to the next level (1.5x)")
	# Clamp at the bottom: stepping out from index 0 stays at 0 (0.25x).
	cc.set_zoom_index(0, Vector2i(5, 5))
	var min_pos_before: Vector2 = cam.position
	cc.step_zoom(-1, Vector2i(5, 5))
	_ok(cc.get_zoom_index() == 0 and is_equal_approx(cam.zoom.x, 0.25),
		"step_zoom clamps at the zoomed-out end")
	_ok(cam.position == min_pos_before,
		"step_zoom below min is a no-op and does not reframe")
	# Clamp at the top: stepping in from the last index stays there (4x).
	cc.set_zoom_index(cc.get_zoom_count() - 1, Vector2i(5, 5))
	var max_pos_before: Vector2 = cam.position
	cc.step_zoom(1, Vector2i(5, 5))
	_ok(cc.get_zoom_index() == cc.get_zoom_count() - 1 and is_equal_approx(cam.zoom.x, 4.0),
		"step_zoom clamps at the zoomed-in end")
	_ok(cam.position == max_pos_before,
		"step_zoom above max is a no-op and does not reframe")
	_ok(cc._effective_edge_buffer(2, 5) == 2
		and cc._effective_edge_buffer(2, 4) == 1
		and cc._effective_edge_buffer(2, 2) == 0,
		"effective edge buffer shrinks when the visible tile span is tiny")
	# reset_zoom returns to the default level.
	cc.reset_zoom(Vector2i(5, 5))
	_ok(cc.get_zoom_index() == cc.DEFAULT_ZOOM_INDEX, "reset_zoom returns to 1.0x")

	# ---- V026-03/04a: camera writes must land in the canvas transform SAME-FRAME ----
	# Camera2D defers its viewport-scroll update to end of frame, so the menu/preview
	# re-anchoring MapCursor runs right after a zoom change read last frame's view (the
	# panel landed visibly wrong at high zoom until a no-op zoom input re-ran it).
	# CameraController._flush_scroll (force_update_scroll) makes the write synchronous.
	cam.make_current()
	await process_frame
	cc.set_zoom_index(cc.DEFAULT_ZOOM_INDEX, Vector2i(5, 5))
	await process_frame  # settle a known baseline transform
	cc.set_zoom_index(6, far)  # 3.0x re-framed at the far corner — a large camera move
	var xf: Transform2D = root.get_canvas_transform()  # read NOW, no frame await
	var flush_scale_ok: bool = xf.get_scale().distance_to(Vector2(3.0, 3.0)) < 0.01
	# DRAG_CENTER: the camera's world position must already map to the screen centre.
	var flush_center_ok: bool = (xf * cam.position).distance_to(view_px * 0.5) < 1.0
	_ok(flush_scale_ok and flush_center_ok,
		"set_zoom_index flushes the canvas transform in the same frame (V026-03/04a)")
	cc.reset_zoom(Vector2i(5, 5))

	# ---- too-small map: a fully-visible map is centred, not pinned to a corner ----
	grid.map_width = 4   # 4*64 = 256 px wide
	grid.map_height = 3  # 3*64 = 192 px tall
	cc.set_zoom_index(0, Vector2i(0, 0))  # 0.25x — view dwarfs the map on both axes
	_ok(cc.get_camera().position == Vector2(128, 96),
		"too-small map is centred on both axes (no blank-space pinning)")

	# cc is RefCounted — it frees itself when the last reference drops; only the
	# scene-tree nodes need an explicit queue_free.
	cam.queue_free()
	grid.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
