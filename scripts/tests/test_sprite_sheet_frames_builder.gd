extends SceneTree
## Headless contract for arbitrary-rectangle sprite sidecars and loud validation.

const Builder = preload("res://scripts/resources/SpriteSheetFramesBuilder.gd")


func _init() -> void:
	print("=== Sprite Sheet Frames Builder Test ===")
	var passed := 0
	var failed := 0
	var image := Image.create(12, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	var sidecar := {
		"schema_version": 1,
		"animations":
		{
			"idle": {"fps": 2, "loop": true, "frames": [{"from": [0, 0], "to": [4, 8]}]},
			"walk_left":
			{
				"fps": 6,
				"loop": true,
				"frames":
				[
					{"from": [4, 0], "to": [8, 8]},
					{"from": [8, 0], "to": [12, 8], "duration": 2},
				],
			},
		},
	}
	var result: Dictionary = Builder.build(texture, sidecar)
	var frames: SpriteFrames = result["sprite_frames"]
	if (
		result["errors"].is_empty()
		and frames != null
		and frames.get_animation_names() == PackedStringArray(["idle", "walk_left"])
	):
		print("OK  open animation names build deterministically")
		passed += 1
	else:
		print("FAIL animation registry: %s" % [result])
		failed += 1

	var second: AtlasTexture = frames.get_frame_texture(&"walk_left", 1)
	if (
		frames.get_frame_count(&"walk_left") == 2
		and second.region == Rect2(8, 0, 4, 8)
		and is_equal_approx(frames.get_frame_duration(&"walk_left", 1), 2.0)
	):
		print("OK  arbitrary two-point rectangles and duration reach SpriteFrames")
		passed += 1
	else:
		print("FAIL frame regions or duration")
		failed += 1

	var bad_sidecar := sidecar.duplicate(true)
	bad_sidecar["animations"].erase("idle")
	bad_sidecar["animations"]["walk_left"]["frames"][0]["to"] = [20, 8]
	var bad: Dictionary = Builder.build(texture, bad_sidecar)
	var bad_errors: Array[String] = bad["errors"]
	if (
		bad["sprite_frames"] == null
		and _has_error(bad_errors, "required animation 'idle'")
		and _has_error(bad_errors, "outside the sheet")
	):
		print("OK  missing idle and out-of-bounds cells fail loud before build")
		passed += 1
	else:
		print("FAIL validation errors: %s" % [bad_errors])
		failed += 1

	var missing: Dictionary = Builder.build(null, sidecar)
	if missing["sprite_frames"] == null and _has_error(missing["errors"], "texture is missing"):
		print("OK  missing sheet fails with an actionable error")
		passed += 1
	else:
		print("FAIL missing texture validation")
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _has_error(errors: Array[String], fragment: String) -> bool:
	return errors.any(func(error: String): return fragment in error)
