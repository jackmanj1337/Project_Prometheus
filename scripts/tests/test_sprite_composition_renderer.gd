extends SceneTree
## Runtime contract for ordered, anchored authored sprite composition layers.

const Renderer = preload("res://scripts/units/SpriteCompositionRenderer.gd")

var _temp_paths: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Sprite Composition Renderer Test ===")
	var passed := 0
	var failed := 0
	var parent := Node2D.new()
	root.add_child(parent)
	var assets := {}
	for asset_id in ["shadow", "body", "badge"]:
		assets[asset_id] = _asset(asset_id)
	var palettes := {
		"body_blue":
		{
			"fallback_tint": [77, 140, 238, 255],
			"mappings": [{"from": [255, 255, 255, 255], "to": [77, 140, 238, 255]}],
		},
		"body_red":
		{
			"fallback_tint": [238, 84, 84, 255],
			"mappings": [{"from": [255, 255, 255, 255], "to": [238, 84, 84, 255]}],
		},
	}
	var composition := {
		"anchors":
		[
			{"id": "feet", "parent": "origin", "offset": [10, 20]},
			{"id": "badge_anchor", "parent": "feet", "offset": [-3, -4]},
		],
		"layers":
		[
			{"id": "shadow", "asset_id": "shadow", "anchor": "feet"},
			{
				"id": "body",
				"asset_id": "body",
				"anchor": "feet",
				"palette_id": "body_blue",
				"animation": "idle",
			},
			{
				"id": "badge",
				"asset_id": "badge",
				"anchor": "badge_anchor",
				"palette_id": "body_blue",
				"player_visible": false,
				"frame": 0,
			},
		],
	}
	var rendered := Renderer.render(parent, composition, assets, palettes, "red")
	if rendered["ok"] and rendered["layers"].size() == 3 and rendered["errors"].is_empty():
		_ok("all authored assets resolve into runtime layers", passed)
		passed += 1
	else:
		_fail("layer construction: %s" % rendered, failed)
		failed += 1

	var layers: Array = rendered["layers"]
	if (
		layers.size() == 3
		and layers[0].name == "Layer_shadow"
		and layers[1].name == "Layer_body"
		and layers[2].name == "Layer_badge"
		and layers[0].z_index < layers[1].z_index
		and layers[1].z_index < layers[2].z_index
	):
		_ok("layer order is exactly the authored order", passed)
		passed += 1
	else:
		_fail("authored order: %s" % layers, failed)
		failed += 1

	if (
		layers[0].position == Vector2(9, 18)
		and layers[1].position == Vector2(9, 18)
		and layers[2].position == Vector2(6, 14)
	):
		_ok("nested anchors and frame pivots place layers at authored points", passed)
		passed += 1
	else:
		_fail(
			(
				"anchor positions: %s, %s, %s"
				% [layers[0].position, layers[1].position, layers[2].position]
			),
			failed
		)
		failed += 1

	var body_material: ShaderMaterial = layers[1].material
	if (
		body_material != null
		and body_material.get_shader_parameter("to_0") == Color8(238, 84, 84)
		and layers[2].visible == false
	):
		_ok("faction palette selection and player visibility apply per layer", passed)
		passed += 1
	else:
		_fail(
			"palette or visibility: material=%s visible=%s" % [body_material, layers[2].visible],
			failed
		)
		failed += 1

	var missing := Renderer.render(
		parent, {"layers": [{"id": "missing", "asset_id": "not_registered"}]}, assets
	)
	if not missing["ok"] and parent.get_node_or_null(Renderer.ROOT_NAME) == null:
		_ok("missing optional assets fail without leaving a partial composition", passed)
		passed += 1
	else:
		_fail("missing asset cleanup: %s" % missing, failed)
		failed += 1

	for path in _temp_paths:
		DirAccess.remove_absolute(path)
	parent.queue_free()
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _asset(asset_id: String) -> Dictionary:
	var image_path := "user://sprite_composition_%s_%d.png" % [asset_id, Time.get_ticks_usec()]
	var sidecar_path := "user://sprite_composition_%s_%d.json" % [asset_id, Time.get_ticks_usec()]
	_temp_paths.append(image_path)
	_temp_paths.append(sidecar_path)
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	image.save_png(image_path)
	var file := FileAccess.open(sidecar_path, FileAccess.WRITE)
	(
		file
		. store_string(
			(
				JSON
				. stringify(
					{
						"schema_version": 1,
						"cell": [4, 4],
						"animations":
						{
							"idle":
							{
								"fps": 1,
								"loop": true,
								"frames": [{"from": [0, 0], "to": [4, 4], "pivot": [1, 2]}],
							},
						},
					}
				)
			)
		)
	)
	return {"path": image_path, "sidecar_path": sidecar_path, "decoded_type": "image"}


func _ok(message: String, _passed: int) -> void:
	print("OK  " + message)


func _fail(message: String, _failed: int) -> void:
	print("FAIL " + message)
