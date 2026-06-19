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

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
