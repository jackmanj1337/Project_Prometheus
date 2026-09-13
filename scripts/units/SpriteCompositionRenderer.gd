class_name SpriteCompositionRenderer extends RefCounted
## Installs an authored sprite composition as ordered AnimatedSprite2D layers.
##
## The composition owns order and anchors. This renderer deliberately does not
## invent semantic slots such as body, shadow, badge, or halo.

const FramesResolver = preload("res://scripts/core/UnitSpriteFramesResolver.gd")
const PaletteSwap = preload("res://scripts/core/UnitPaletteSwap.gd")

const ROOT_NAME := "SpriteComposition"


static func render(
	parent: Node2D,
	composition: Dictionary,
	assets: Dictionary,
	palettes: Dictionary = {},
	faction_id: String = "",
	target_size: Vector2i = Vector2i.ZERO
) -> Dictionary:
	var result := {"ok": false, "root": null, "layers": [], "warnings": [], "errors": []}
	if parent == null:
		result.errors.append("SpriteCompositionRenderer: parent is missing")
		return result
	# A failed refresh must not leave an old composition masking the caller's
	# placeholder or single-sprite fallback.
	clear(parent)
	var raw_layers: Variant = composition.get("layers")
	if not raw_layers is Array or raw_layers.is_empty():
		result.errors.append("SpriteCompositionRenderer: composition needs at least one layer")
		return result

	var anchors := _anchor_positions(composition.get("anchors", []), result.errors)
	if not result.errors.is_empty():
		return result

	var prepared: Array[Dictionary] = []
	for index in raw_layers.size():
		var raw_layer: Variant = raw_layers[index]
		if not raw_layer is Dictionary:
			result.errors.append("layers[%d] must be an object" % index)
			continue
		var layer: Dictionary = raw_layer
		var layer_id := String(layer.get("id", "")).strip_edges()
		var asset_id := String(layer.get("asset_id", "")).strip_edges()
		if layer_id.is_empty() or asset_id.is_empty():
			result.errors.append("layers[%d] needs id and asset_id" % index)
			continue
		var anchor_id := String(layer.get("anchor", "origin")).strip_edges()
		if anchor_id.is_empty():
			anchor_id = "origin"
		if not anchors.has(anchor_id):
			result.errors.append("layers[%d] references missing anchor '%s'" % [index, anchor_id])
			continue
		var resolved := FramesResolver.resolve(asset_id, assets, target_size)
		result.warnings.append_array(resolved.get("warnings", []))
		if resolved.get("sprite_frames") == null:
			result.errors.append_array(resolved.get("errors", []))
			var repairs: Array = resolved.get("repair_report", [])
			if repairs.is_empty():
				result.errors.append(
					"layer '%s' could not resolve asset '%s'" % [layer_id, asset_id]
				)
			else:
				result.errors.append(
					(
						"layer '%s' could not resolve asset '%s': %s"
						% [layer_id, asset_id, repairs[0].get("reason", "unknown")]
					)
				)
			continue
		var frames: SpriteFrames = resolved["sprite_frames"]
		var animation_name := _animation_name(frames, String(layer.get("animation", "idle")))
		var frame := clampi(
			int(layer.get("frame", 0)), 0, frames.get_frame_count(animation_name) - 1
		)
		var pivots: Array = resolved.get("frame_pivots", {}).get(animation_name, [])
		var pivot := Vector2.ZERO
		if frame < pivots.size() and pivots[frame] is Vector2:
			pivot = pivots[frame]
		var offset := _point(layer.get("offset", [0, 0]))
		(
			prepared
			. append(
				{
					"id": layer_id,
					"frames": frames,
					"animation": animation_name,
					"frame": frame,
					"pivot": pivot,
					"position": anchors[anchor_id] + offset,
					"layer": layer,
					"index": index,
				}
			)
		)

	if not result.errors.is_empty():
		return result

	var root := Node2D.new()
	root.name = ROOT_NAME
	parent.add_child(root)
	for prepared_layer in prepared:
		var sprite := AnimatedSprite2D.new()
		sprite.name = _node_name(prepared_layer["id"])
		sprite.centered = false
		sprite.sprite_frames = prepared_layer["frames"]
		sprite.position = prepared_layer["position"] - prepared_layer["pivot"]
		sprite.z_index = prepared_layer["index"]
		sprite.visible = _layer_visible(prepared_layer["layer"])
		var layer: Dictionary = prepared_layer["layer"]
		var selected_palette := _select_palette(
			String(layer.get("palette_id", "")), palettes, faction_id
		)
		if not selected_palette.is_empty():
			var material := PaletteSwap.build_material(selected_palette.get("mappings", []))
			if material != null:
				sprite.material = material
			else:
				sprite.modulate = _color(selected_palette.get("fallback_tint", []), Color.WHITE)
		root.add_child(sprite)
		if layer.has("frame"):
			sprite.stop()
			sprite.frame = prepared_layer["frame"]
		else:
			sprite.play(prepared_layer["animation"])
		result.layers.append(sprite)
	result.ok = true
	result.root = root
	return result


static func clear(parent: Node2D) -> void:
	if parent == null:
		return
	var existing := parent.get_node_or_null(ROOT_NAME)
	if existing != null:
		existing.free()


static func _anchor_positions(raw_anchors: Variant, errors: Array) -> Dictionary:
	var definitions := {}
	if raw_anchors is Array:
		for raw_anchor in raw_anchors:
			if raw_anchor is Dictionary:
				definitions[String(raw_anchor.get("id", ""))] = raw_anchor
	var positions := {"origin": Vector2.ZERO}
	for anchor_id in definitions:
		_resolve_anchor(String(anchor_id), definitions, positions, [], errors)
	return positions


static func _resolve_anchor(
	anchor_id: String,
	definitions: Dictionary,
	positions: Dictionary,
	ancestry: Array,
	errors: Array
) -> Vector2:
	if positions.has(anchor_id):
		return positions[anchor_id]
	if ancestry.has(anchor_id):
		errors.append("anchor '%s' participates in an anchor cycle" % anchor_id)
		return Vector2.ZERO
	if not definitions.has(anchor_id):
		errors.append("anchor '%s' references a missing definition" % anchor_id)
		return Vector2.ZERO
	var next_ancestry := ancestry.duplicate()
	next_ancestry.append(anchor_id)
	var anchor: Dictionary = definitions[anchor_id]
	var parent_id := String(anchor.get("parent", "origin")).strip_edges()
	if parent_id.is_empty():
		parent_id = "origin"
	var position := _resolve_anchor(parent_id, definitions, positions, next_ancestry, errors)
	position += _point(anchor.get("offset", [0, 0]))
	positions[anchor_id] = position
	return position


static func _animation_name(frames: SpriteFrames, preferred: String) -> StringName:
	var candidate := StringName(preferred)
	if frames.has_animation(candidate):
		return candidate
	if frames.has_animation(&"idle"):
		return &"idle"
	if frames.has_animation(&"default"):
		return &"default"
	var names := frames.get_animation_names()
	return names[0] if not names.is_empty() else &"default"


static func _select_palette(
	palette_id: String, palettes: Dictionary, faction_id: String
) -> Dictionary:
	if palette_id.is_empty():
		return {}
	if palettes.has(palette_id) and palettes[palette_id] is Dictionary:
		var exact: Dictionary = palettes[palette_id]
		if faction_id.is_empty() or palette_id.ends_with("_" + faction_id):
			return exact
	var separator := palette_id.rfind("_")
	if separator >= 0 and not faction_id.is_empty():
		var faction_palette_id := palette_id.substr(0, separator) + "_" + faction_id
		if palettes.has(faction_palette_id) and palettes[faction_palette_id] is Dictionary:
			return palettes[faction_palette_id]
	return palettes[palette_id] if palettes.get(palette_id) is Dictionary else {}


static func _layer_visible(layer: Dictionary) -> bool:
	return bool(layer.get("author_visible", true)) and bool(layer.get("player_visible", true))


static func _point(value: Variant) -> Vector2:
	if not value is Array or value.size() != 2:
		return Vector2.ZERO
	return Vector2(float(value[0]), float(value[1]))


static func _color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is Array and value.size() == 4:
		return Color8(int(value[0]), int(value[1]), int(value[2]), int(value[3]))
	return fallback


static func _node_name(layer_id: String) -> String:
	return "Layer_%s" % layer_id.replace("-", "_")
