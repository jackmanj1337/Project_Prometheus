class_name SpriteSheetFramesBuilder extends RefCounted
## Pure conversion boundary from a decoded sprite sidecar to in-memory SpriteFrames.
## The caller owns file/JSON loading so this module stays usable by runtime, editor, and tests.


static func build(
	texture: Texture2D,
	sidecar: Dictionary,
	target_size: Vector2i = Vector2i.ZERO,
	warn_on_non_integer_scale: bool = true
) -> Dictionary:
	var errors: Array[String] = validate(texture, sidecar)
	if not errors.is_empty():
		return {"sprite_frames": null, "frame_pivots": {}, "warnings": [], "errors": errors}

	var output := SpriteFrames.new()
	var frame_pivots: Dictionary = {}
	output.remove_animation(&"default")
	var animations: Dictionary = sidecar["animations"]
	var animation_names: Array = animations.keys()
	animation_names.sort()
	for animation_name_value in animation_names:
		var animation_name := StringName(String(animation_name_value))
		var definition: Dictionary = animations[animation_name_value]
		output.add_animation(animation_name)
		output.set_animation_speed(animation_name, float(definition.get("fps", 1.0)))
		output.set_animation_loop(animation_name, bool(definition.get("loop", true)))
		frame_pivots[animation_name] = []
		for frame_value in definition["frames"]:
			var frame: Dictionary = frame_value
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = texture
			atlas_frame.region = _frame_rect(frame)
			output.add_frame(animation_name, atlas_frame, float(frame.get("duration", 1.0)))
			frame_pivots[animation_name].append(_frame_pivot(frame))
	return {
		"sprite_frames": output,
		"frame_pivots": frame_pivots,
		"warnings": _scale_warnings(sidecar, target_size, warn_on_non_integer_scale),
		"errors": errors,
	}


static func validate(texture: Texture2D, sidecar: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if texture == null:
		errors.append("SpriteSheetFramesBuilder: sheet texture is missing")
		return errors
	if int(sidecar.get("schema_version", 0)) != 1:
		errors.append("SpriteSheetFramesBuilder: schema_version must be 1")
	var animations_value: Variant = sidecar.get("animations")
	if not animations_value is Dictionary or animations_value.is_empty():
		errors.append("SpriteSheetFramesBuilder: animations must be a non-empty object")
		return errors
	var animations: Dictionary = animations_value
	for animation_name_value in animations:
		var animation_name := String(animation_name_value)
		var definition_value: Variant = animations[animation_name_value]
		if animation_name.strip_edges().is_empty():
			errors.append("SpriteSheetFramesBuilder: animation names cannot be empty")
			continue
		if not definition_value is Dictionary:
			errors.append(
				"SpriteSheetFramesBuilder: animation '%s' must be an object" % animation_name
			)
			continue
		var definition: Dictionary = definition_value
		var fps: float = float(definition.get("fps", 1.0))
		if not is_finite(fps) or fps <= 0.0:
			errors.append(
				"SpriteSheetFramesBuilder: animation '%s' fps must be positive" % animation_name
			)
		var frames_value: Variant = definition.get("frames")
		if not frames_value is Array or frames_value.is_empty():
			errors.append(
				"SpriteSheetFramesBuilder: animation '%s' needs at least one frame" % animation_name
			)
			continue
		for frame_index in frames_value.size():
			_validate_frame(texture, animation_name, frame_index, frames_value[frame_index], errors)
	return errors


static func _validate_frame(
	texture: Texture2D,
	animation_name: String,
	frame_index: int,
	frame_value: Variant,
	errors: Array[String]
) -> void:
	var label := "animation '%s' frame %d" % [animation_name, frame_index]
	if not frame_value is Dictionary:
		errors.append("SpriteSheetFramesBuilder: %s must be an object" % label)
		return
	var frame: Dictionary = frame_value
	if not _is_point(frame.get("from")) or not _is_point(frame.get("to")):
		errors.append("SpriteSheetFramesBuilder: %s needs integer from/to pixel points" % label)
		return
	var rect := _frame_rect(frame)
	var sheet_size := texture.get_size()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		errors.append("SpriteSheetFramesBuilder: %s has an empty or reversed rectangle" % label)
	elif (
		rect.position.x < 0.0
		or rect.position.y < 0.0
		or not Rect2(Vector2.ZERO, sheet_size).encloses(rect)
	):
		errors.append("SpriteSheetFramesBuilder: %s rectangle is outside the sheet" % label)
	var duration: float = float(frame.get("duration", 1.0))
	if not is_finite(duration) or duration <= 0.0:
		errors.append("SpriteSheetFramesBuilder: %s duration must be positive" % label)
	if frame.has("pivot") and not _is_point(frame["pivot"]):
		errors.append("SpriteSheetFramesBuilder: %s pivot must be an integer pixel point" % label)


static func _frame_rect(frame: Dictionary) -> Rect2:
	var from := _point(frame["from"])
	var to := _point(frame["to"])
	return Rect2(from, to - from)


static func _frame_pivot(frame: Dictionary) -> Vector2:
	if frame.has("pivot"):
		return _point(frame["pivot"])
	var rect := _frame_rect(frame)
	return Vector2(rect.size.x / 2.0, rect.size.y)


static func _scale_warnings(
	sidecar: Dictionary, target_size: Vector2i, enabled: bool
) -> Array[String]:
	var warnings: Array[String] = []
	if not enabled or target_size == Vector2i.ZERO or not sidecar.has("cell"):
		return warnings
	if not _is_point(sidecar["cell"]):
		warnings.append("SpriteSheetFramesBuilder: cell must be an integer pixel size")
		return warnings
	var cell := Vector2i(_point(sidecar["cell"]))
	if cell.x <= 0 or cell.y <= 0:
		warnings.append("SpriteSheetFramesBuilder: cell must be positive")
		return warnings
	if target_size.x % cell.x != 0 or target_size.y % cell.y != 0:
		warnings.append(
			(
				"SpriteSheetFramesBuilder: cell %s has a non-integer scale ratio to target %s"
				% [cell, target_size]
			)
		)
	return warnings


static func _is_point(value: Variant) -> bool:
	if not value is Array or value.size() != 2:
		return false
	return _is_integer(value[0]) and _is_integer(value[1])


static func _is_integer(value: Variant) -> bool:
	return (
		(value is int or value is float)
		and is_finite(float(value))
		and float(value) == floorf(float(value))
	)


static func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))
