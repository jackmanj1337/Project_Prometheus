class_name UnitSpriteFramesResolver extends RefCounted
## Resolves one active-pack sprite catalogue record into runtime SpriteFrames.
## The catalogue adapter owns path validation; this seam only loads the already-resolved
## image/sidecar pair and delegates frame semantics to SpriteSheetFramesBuilder.

const FramesBuilder = preload("res://scripts/resources/SpriteSheetFramesBuilder.gd")


static func resolve(
	sprite_id: String,
	assets: Dictionary,
	target_size: Vector2i = Vector2i.ZERO,
	warn_on_non_integer_scale: bool = true
) -> Dictionary:
	var result := {
		"sprite_frames": null,
		"frame_pivots": {},
		"warnings": [],
		"errors": [],
		"repair_report": [],
	}
	if sprite_id.is_empty():
		return result
	var record_value: Variant = assets.get(sprite_id)
	if not record_value is Dictionary:
		_repair(result, sprite_id, "missing_asset")
		return result
	var record: Dictionary = record_value
	var texture := _load_texture(String(record.get("path", "")))
	if texture == null:
		_repair(result, sprite_id, "missing_or_invalid_texture")
		return result
	var sidecar: Variant = _load_sidecar(String(record.get("sidecar_path", "")))
	if sidecar == null:
		_repair(result, sprite_id, "missing_or_invalid_sidecar")
		return result
	var built: Dictionary = FramesBuilder.build(
		texture, sidecar, target_size, warn_on_non_integer_scale
	)
	result["sprite_frames"] = built["sprite_frames"]
	result["frame_pivots"] = built["frame_pivots"]
	result["warnings"] = built["warnings"]
	result["errors"] = built["errors"]
	if built["sprite_frames"] == null:
		_repair(result, sprite_id, "invalid_frame_sidecar")
	return result


static func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


static func _load_sidecar(path: String) -> Variant:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else null


static func _repair(result: Dictionary, sprite_id: String, reason: String) -> void:
	result["repair_report"].append({"kind": "unit_sprite", "id": sprite_id, "reason": reason})
