extends SceneTree
## Headless contract for campaign-editor sprite composition authoring.

const Editor = preload("res://scripts/editor/SpriteCompositionEditor.gd")

var _temp_paths: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Sprite Composition Editor Test ===")
	var passed := 0
	var failed := 0
	var editor := Editor.new()
	var base := {
		"schema_version": 1,
		"id": "base_unit",
		"anchors": [{"id": "feet", "parent": "origin", "offset": [2, 3]}],
		"layers":
		[
			{"id": "shadow", "asset_id": "shadow", "anchor": "feet"},
			{"id": "body", "asset_id": "body", "anchor": "feet", "palette_id": "body_blue"},
		],
	}
	var child := base.duplicate(true)
	child["id"] = "child_unit"
	var palette := {
		"schema_version": 1,
		"id": "body_blue",
		"fallback_tint": [77, 140, 238, 255],
		"mappings": [{"from": [255, 255, 255, 255], "to": [77, 140, 238, 255]}],
	}
	var initial := editor.set_document(child, {"body_blue": palette}, {"base_unit": base})
	if initial["status"] == Editor.ACCEPTED and editor.validation()["errors"].is_empty():
		_ok("valid composition and full palette load into the authoring model", passed)
		passed += 1
	else:
		_fail("initial document: %s / %s" % [initial, editor.validation()], failed)
		failed += 1

	var reordered := editor.reorder_layers(["body", "shadow"])
	if (
		reordered["status"] == Editor.ACCEPTED
		and editor.composition()["layers"][0]["id"] == "body"
		and editor.composition()["layers"][1]["id"] == "shadow"
	):
		_ok("authors can reorder layers without semantic slot rules", passed)
		passed += 1
	else:
		_fail("reorder: %s" % [reordered], failed)
		failed += 1

	var anchor_edit := editor.set_anchor("badge_anchor", "feet", [4, -8])
	if (
		anchor_edit["status"] == Editor.ACCEPTED
		and editor.composition()["anchors"][1]["id"] == "badge_anchor"
		and editor.composition()["anchors"][1]["offset"] == [4, -8]
	):
		_ok("authors can add and retarget nested anchors", passed)
		passed += 1
	else:
		_fail("anchor edit: %s" % [anchor_edit], failed)
		failed += 1

	var bad_order := editor.reorder_layers(["body", "body"])
	if bad_order["status"] == Editor.REFUSED and editor.composition()["layers"].size() == 2:
		_ok("invalid layer orders are refused without mutating the document", passed)
		passed += 1
	else:
		_fail("bad order: %s" % [bad_order], failed)
		failed += 1

	var mapping_edit := editor.set_palette_mapping(
		"body_blue", 0, [0, 0, 0, 255], [77, 140, 238, 255]
	)
	var fallback_edit := editor.set_palette_fallback("body_blue", [90, 150, 240, 255])
	if (
		mapping_edit["status"] == Editor.ACCEPTED
		and fallback_edit["status"] == Editor.ACCEPTED
		and editor.palettes()["body_blue"]["mappings"][0]["from"] == [0, 0, 0, 255]
		and editor.palettes()["body_blue"]["fallback_tint"] == [90, 150, 240, 255]
	):
		_ok("authors can edit exact palette mappings and fallback tint", passed)
		passed += 1
	else:
		_fail("palette edit: %s / %s" % [mapping_edit, fallback_edit], failed)
		failed += 1

	var inherited := (
		editor
		. set_inheritance(
			"base_unit",
			[
				{
					"op": "replace",
					"layer_id": "body",
					"layer": {"id": "body", "asset_id": "body", "anchor": "feet"},
				}
			],
		)
	)
	var resolved := editor.resolved_composition()
	if inherited["status"] == Editor.ACCEPTED and resolved["errors"].is_empty():
		_ok("authors can replace a base layer through stable-id inheritance", passed)
		passed += 1
	else:
		_fail("inheritance: %s / %s" % [inherited, resolved], failed)
		failed += 1

	var collision_warnings := (
		editor
		. collision_warnings(
			{
				"body": Rect2(0, 0, 10, 10),
				"shadow": Rect2(5, 5, 10, 10),
			}
		)
	)
	if collision_warnings.size() == 1 and "Potential collision" in collision_warnings[0]:
		_ok("overlapping layer bounds produce an advisory collision warning", passed)
		passed += 1
	else:
		_fail("collision diagnostics: %s" % collision_warnings, failed)
		failed += 1

	var preview_parent := Node2D.new()
	root.add_child(preview_parent)
	var preview := editor.preview(
		preview_parent, {"body": _asset("body"), "shadow": _asset("shadow")}, "blue"
	)
	if preview["ok"] and preview["layers"].size() == 2:
		_ok("preview delegates to the runtime renderer over the resolved composition", passed)
		passed += 1
	else:
		_fail("preview: %s" % preview, failed)
		failed += 1

	for path in _temp_paths:
		DirAccess.remove_absolute(path)
	preview_parent.queue_free()
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _asset(asset_id: String) -> Dictionary:
	var image_path := (
		"user://sprite_composition_editor_%s_%d.png" % [asset_id, Time.get_ticks_usec()]
	)
	var sidecar_path := (
		"user://sprite_composition_editor_%s_%d.json" % [asset_id, Time.get_ticks_usec()]
	)
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
						"animations":
						{
							"idle":
							{
								"fps": 1,
								"loop": true,
								"frames": [{"from": [0, 0], "to": [4, 4]}],
							},
						},
					}
				)
			)
		)
	)
	return {"path": image_path, "sidecar_path": sidecar_path}


func _ok(message: String, _passed: int) -> void:
	print("OK  " + message)


func _fail(message: String, _failed: int) -> void:
	print("FAIL " + message)
