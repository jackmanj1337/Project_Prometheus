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

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
