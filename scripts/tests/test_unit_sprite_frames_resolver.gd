extends SceneTree
## Headless contract for active-pack sprite image/sidecar resolution and fallback.

const Resolver = preload("res://scripts/core/UnitSpriteFramesResolver.gd")

var _temp_paths: Array[String] = []


func _init() -> void:
	print("=== Unit Sprite Frames Resolver Test ===")
	var passed := 0
	var failed := 0
	var image_path := _temp_path("png")
	var sidecar_path := _temp_path("json")
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.3, 0.6, 0.9))
	image.save_png(image_path)
	_write_json(
		sidecar_path,
		{
			"schema_version": 1,
			"cell": [8, 8],
			"animations":
			{"idle": {"fps": 1, "loop": true, "frames": [{"from": [0, 0], "to": [8, 8]}]}},
		}
	)
	var assets := {
		"hero_map": {"path": image_path, "sidecar_path": sidecar_path, "decoded_type": "image"}
	}
	var resolved: Dictionary = Resolver.resolve("hero_map", assets, Vector2i(64, 64))
	var frames: SpriteFrames = resolved["sprite_frames"]
	if (
		frames != null
		and frames.has_animation(&"idle")
		and frames.get_frame_count(&"idle") == 1
		and resolved["repair_report"].is_empty()
	):
		print("OK  active-pack image and sidecar build runtime frames")
		passed += 1
	else:
		print("FAIL resolved sprite: %s" % [resolved])
		failed += 1

	var missing: Dictionary = Resolver.resolve("missing_map", assets)
	if (
		missing["sprite_frames"] == null
		and (
			missing["repair_report"]
			== [{"kind": "unit_sprite", "id": "missing_map", "reason": "missing_asset"}]
		)
	):
		print("OK  missing optional art returns structured repair evidence")
		passed += 1
	else:
		print("FAIL missing-art repair result: %s" % [missing])
		failed += 1

	var no_sidecar := {"hero_map": {"path": image_path, "decoded_type": "image"}}
	var incomplete: Dictionary = Resolver.resolve("hero_map", no_sidecar)
	if (
		incomplete["sprite_frames"] == null
		and incomplete["repair_report"][0]["reason"] == "missing_or_invalid_sidecar"
	):
		print("OK  incomplete catalogue binding fails to the placeholder path")
		passed += 1
	else:
		print("FAIL incomplete binding: %s" % [incomplete])
		failed += 1

	var packed: PackedScene = load("res://scenes/units/Unit.tscn")
	var unit: Unit = packed.instantiate()
	root.add_child(unit)
	await process_frame
	var sprite := unit.get_node("Sprite2D") as AnimatedSprite2D
	var placeholder := sprite.sprite_frames
	var unresolved: Dictionary = unit.apply_pack_sprite_asset(assets)
	if unresolved["sprite_frames"] == null and sprite.sprite_frames == placeholder:
		print("OK  empty class sprite identity preserves the built-in placeholder")
		passed += 1
	else:
		print("FAIL Unit placeholder fallback")
		failed += 1
	var dm := root.get_node_or_null("DataManager")
	var class_data: ClassData = dm.get_class_data("knight") if dm != null else null
	var old_sprite_id := class_data.sprite_id if class_data != null else ""
	if class_data != null:
		class_data.sprite_id = "hero_map"
	var unit_data := UnitData.new()
	unit_data.class_id = "knight"
	unit.data = unit_data
	var applied: Dictionary = unit.apply_pack_sprite_asset(assets)
	if applied["sprite_frames"] != null and sprite.sprite_frames.has_animation(&"idle"):
		print("OK  Unit installs frames resolved through its class sprite id")
		passed += 1
	else:
		print("FAIL Unit class-keyed frame installation: %s" % [applied])
		failed += 1
	if class_data != null:
		class_data.sprite_id = old_sprite_id
	unit.queue_free()

	for path in _temp_paths:
		DirAccess.remove_absolute(path)
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _temp_path(extension: String) -> String:
	var path := "user://unit_sprite_resolver_%d.%s" % [Time.get_ticks_usec(), extension]
	_temp_paths.append(path)
	return path


func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
