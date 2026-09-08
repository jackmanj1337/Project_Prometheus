class_name SpriteCompositionDef extends RefCounted
# adopter-todo: SPRITE-COMPOSITION-SCHEMA-2026-08-26

## JSON-friendly authored ordered layer stack for a composed sprite.
##
## Layer ids are the stable editing identity. The renderer will later consume
## the resolved layer array exactly as authored; this schema never assigns
## meaning to names such as body, shadow, badge, or halo.

const SCHEMA_VERSION := 1
const ROOT_ANCHOR := "origin"
const LAYER_OPERATIONS: Array[String] = [
	"replace", "insert_before", "insert_after", "remove", "move_before", "move_after"
]

var schema_version: int = SCHEMA_VERSION
var id: String = ""
var display_name: String = ""
var base_composition_id: String = ""
var anchors: Array[Dictionary] = []
var layers: Array[Dictionary] = []
var layer_operations: Array[Dictionary] = []


static func parse(raw: Variant, source_path: String, errors: Array[String]) -> SpriteCompositionDef:
	var prefix := "SpriteCompositionDef(%s)" % source_path
	if not raw is Dictionary:
		errors.append("%s: root must be an object" % prefix)
		return null
	var data: Dictionary = raw
	var composition = new()
	composition.schema_version = _integer_field(data, "schema_version", prefix, errors, true)
	composition.id = _string_field(data, "id", prefix, errors, true)
	composition.display_name = _string_field(data, "display_name", prefix, errors, false)
	composition.base_composition_id = _string_field(
		data, "base_composition_id", prefix, errors, false
	)
	composition.anchors = _dictionary_array(data.get("anchors", []), "anchors", prefix, errors)
	composition.layers = _dictionary_array(data.get("layers", []), "layers", prefix, errors)
	composition.layer_operations = _dictionary_array(
		data.get("layer_operations", []), "layer_operations", prefix, errors
	)
	for validation_error in composition.validation_errors():
		errors.append("%s: %s" % [prefix, validation_error])
	if errors.any(func(error: String): return error.begins_with(prefix + ":")):
		return null
	return composition


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if schema_version != SCHEMA_VERSION:
		errors.append("schema_version must be %d" % SCHEMA_VERSION)
	if not _valid_id(id):
		errors.append("id must use lowercase letters, digits, '_' or '-'")
	if not base_composition_id.is_empty() and not _valid_id(base_composition_id):
		errors.append("base_composition_id must be empty or a valid id")
	if not base_composition_id.is_empty() and not layers.is_empty():
		errors.append("layers must be empty when base_composition_id is set; use layer_operations")
	var anchor_ids := {ROOT_ANCHOR: true}
	for index in anchors.size():
		var anchor: Dictionary = anchors[index]
		var anchor_id := String(anchor.get("id", "")).strip_edges()
		if anchor_id.is_empty():
			errors.append("anchors[%d] is missing id" % index)
			continue
		if anchor_id == ROOT_ANCHOR:
			errors.append(
				"anchors[%d] cannot redefine the reserved '%s' anchor" % [index, ROOT_ANCHOR]
			)
		elif anchor_ids.has(anchor_id):
			errors.append("anchors[%d] duplicates anchor '%s'" % [index, anchor_id])
		else:
			anchor_ids[anchor_id] = true
		var parent := String(anchor.get("parent", ROOT_ANCHOR)).strip_edges()
		if parent.is_empty():
			parent = ROOT_ANCHOR
		if not _valid_id(anchor_id):
			errors.append("anchors[%d] id '%s' is invalid" % [index, anchor_id])
		if not _valid_id(parent):
			errors.append("anchors[%d] parent '%s' is invalid" % [index, parent])
		var offset_error := _point_error(anchor.get("offset", [0, 0]))
		if not offset_error.is_empty():
			errors.append("anchors[%d] %s" % [index, offset_error])
	for anchor in anchors:
		var parent := String(anchor.get("parent", ROOT_ANCHOR)).strip_edges()
		if parent.is_empty():
			parent = ROOT_ANCHOR
		if not anchor_ids.has(parent):
			errors.append(
				"anchor '%s' references missing parent '%s'" % [anchor.get("id", ""), parent]
			)
			continue
		if _anchor_has_cycle(String(anchor.get("id", "")), anchors):
			errors.append("anchor '%s' participates in an anchor cycle" % anchor.get("id", ""))

	var layer_ids := {}
	for index in layers.size():
		_validate_layer(layers[index], "layers[%d]" % index, anchor_ids, layer_ids, errors)
	_validate_operations(layer_operations, errors)
	if base_composition_id.is_empty() and layers.is_empty():
		errors.append("layers must contain at least one authored layer")
	return errors


## Resolve a composition and all its base compositions.
## `definitions` is a pack-scoped id -> Dictionary or SpriteCompositionDef map.
static func resolve(raw: Variant, definitions: Dictionary = {}) -> Dictionary:
	var errors: Array[String] = []
	var lookup := definitions.duplicate(true)
	var root_data := _as_dictionary(raw)
	var root_id := String(root_data.get("id", ""))
	if not root_id.is_empty():
		lookup[root_id] = raw
	var ancestry: Array[String] = []
	var resolved := _resolve(raw, lookup, ancestry, errors)
	return {"composition": resolved, "errors": errors}


func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"id": id,
		"display_name": display_name,
		"base_composition_id": base_composition_id,
		"anchors": anchors.duplicate(true),
		"layers": layers.duplicate(true),
		"layer_operations": layer_operations.duplicate(true),
	}


static func _resolve(
	raw: Variant, definitions: Dictionary, ancestry: Array[String], errors: Array[String]
) -> Dictionary:
	var data := _as_dictionary(raw)
	if data.is_empty():
		errors.append("composition must be an object")
		return {}
	var composition_id := String(data.get("id", ""))
	if composition_id.is_empty():
		errors.append("composition is missing id")
		return {}
	if ancestry.has(composition_id):
		errors.append(
			"composition inheritance cycle: %s -> %s" % [" -> ".join(ancestry), composition_id]
		)
		return {}

	var base: Dictionary = {}
	var base_id := String(data.get("base_composition_id", ""))
	if not base_id.is_empty():
		if not definitions.has(base_id):
			errors.append(
				"composition '%s' references missing base '%s'" % [composition_id, base_id]
			)
		else:
			var next_ancestry: Array[String] = ancestry.duplicate()
			next_ancestry.append(composition_id)
			base = _resolve(definitions[base_id], definitions, next_ancestry, errors)

	var result := {
		"schema_version": int(data.get("schema_version", 0)),
		"id": composition_id,
		"display_name": String(data.get("display_name", "")),
		"base_composition_id": base_id,
		"anchors": _merge_anchors(base.get("anchors", []), data.get("anchors", [])),
		"layers": base.get("layers", []).duplicate(true),
		"layer_operations": data.get("layer_operations", []).duplicate(true),
	}
	if base.is_empty():
		result["layers"] = data.get("layers", []).duplicate(true)
	elif not data.get("layers", []).is_empty():
		errors.append("composition '%s' cannot define layers with a base" % composition_id)
	_apply_layer_operations(
		result["layers"], data.get("layer_operations", []), composition_id, errors
	)
	var resolved_anchor_ids := {ROOT_ANCHOR: true}
	for anchor in result["anchors"]:
		if anchor is Dictionary:
			resolved_anchor_ids[String(anchor.get("id", ""))] = true
	var resolved_layer_ids := {}
	for index in result["layers"].size():
		_validate_layer(
			result["layers"][index],
			"composition '%s' resolved layers[%d]" % [composition_id, index],
			resolved_anchor_ids,
			resolved_layer_ids,
			errors
		)
	if result["layers"].is_empty():
		errors.append("composition '%s' resolves to no layers" % composition_id)
	return result


static func _apply_layer_operations(
	resolved_layers: Array, operations: Variant, composition_id: String, errors: Array[String]
) -> void:
	if not operations is Array:
		errors.append("composition '%s' layer_operations must be an array" % composition_id)
		return
	for index in operations.size():
		var operation: Variant = operations[index]
		if not operation is Dictionary:
			errors.append(
				"composition '%s' layer_operations[%d] must be an object" % [composition_id, index]
			)
			continue
		var row: Dictionary = operation
		var kind := String(row.get("op", ""))
		var layer_id := String(row.get("layer_id", ""))
		var at := _layer_index(resolved_layers, layer_id)
		if kind not in LAYER_OPERATIONS:
			errors.append(
				(
					"composition '%s' layer_operations[%d] has unknown op '%s'"
					% [composition_id, index, kind]
				)
			)
			continue
		if kind == "remove":
			if at < 0:
				errors.append(
					"composition '%s' cannot remove missing layer '%s'" % [composition_id, layer_id]
				)
			else:
				resolved_layers.remove_at(at)
			continue
		if kind == "replace":
			if at < 0:
				errors.append(
					(
						"composition '%s' cannot replace missing layer '%s'"
						% [composition_id, layer_id]
					)
				)
			elif not row.get("layer") is Dictionary:
				errors.append(
					"composition '%s' replace for '%s' needs layer" % [composition_id, layer_id]
				)
			else:
				resolved_layers[at] = (row["layer"] as Dictionary).duplicate(true)
			continue
		if kind in ["insert_before", "insert_after"]:
			var relative_id := String(row.get("relative_to", ""))
			var relative_at := _layer_index(resolved_layers, relative_id)
			if relative_at < 0 or not row.get("layer") is Dictionary:
				errors.append(
					(
						"composition '%s' %s needs an existing relative_to and layer"
						% [composition_id, kind]
					)
				)
			else:
				var insert_at := relative_at if kind == "insert_before" else relative_at + 1
				resolved_layers.insert(insert_at, (row["layer"] as Dictionary).duplicate(true))
			continue
		var relative_id := String(row.get("relative_to", ""))
		var relative_at := _layer_index(resolved_layers, relative_id)
		if at < 0 or relative_at < 0:
			errors.append(
				(
					"composition '%s' %s needs existing layer_id and relative_to"
					% [composition_id, kind]
				)
			)
			continue
		var moved: Dictionary = resolved_layers[at]
		resolved_layers.remove_at(at)
		if relative_at > at:
			relative_at -= 1
		var destination := relative_at if kind == "move_before" else relative_at + 1
		resolved_layers.insert(destination, moved)


static func _validate_operations(operations: Array[Dictionary], errors: Array[String]) -> void:
	for index in operations.size():
		var row: Dictionary = operations[index]
		var label := "layer_operations[%d]" % index
		var operation := String(row.get("op", ""))
		if operation not in LAYER_OPERATIONS:
			errors.append("%s has unknown op '%s'" % [label, operation])
			continue
		if operation in ["replace", "remove", "move_before", "move_after"]:
			_validate_operation_id(row, "layer_id", label, errors)
		if operation in ["insert_before", "insert_after", "move_before", "move_after"]:
			_validate_operation_id(row, "relative_to", label, errors)
		if operation in ["replace", "insert_before", "insert_after"]:
			if not row.get("layer") is Dictionary:
				errors.append("%s needs a layer object" % label)
			elif operation == "replace":
				var replacement: Dictionary = row["layer"]
				if String(replacement.get("id", "")) != String(row.get("layer_id", "")):
					errors.append("%s replacement layer id must match layer_id" % label)


static func _validate_operation_id(
	row: Dictionary, field: String, label: String, errors: Array[String]
) -> void:
	var value := String(row.get(field, "")).strip_edges()
	if value.is_empty():
		errors.append("%s is missing %s" % [label, field])
	elif not _valid_id(value):
		errors.append("%s %s '%s' is invalid" % [label, field, value])


static func _validate_layer(
	value: Variant,
	label: String,
	anchor_ids: Dictionary,
	layer_ids: Dictionary,
	errors: Array[String]
) -> void:
	if not value is Dictionary:
		errors.append("%s must be an object" % label)
		return
	var layer: Dictionary = value
	var layer_id := String(layer.get("id", "")).strip_edges()
	if layer_id.is_empty():
		errors.append("%s is missing id" % label)
	elif not _valid_id(layer_id):
		errors.append("%s id '%s' is invalid" % [label, layer_id])
	elif layer_ids.has(layer_id):
		errors.append("%s duplicates layer '%s'" % [label, layer_id])
	else:
		layer_ids[layer_id] = true
	var asset_id := String(layer.get("asset_id", "")).strip_edges()
	if asset_id.is_empty():
		errors.append("%s is missing asset_id" % label)
	var anchor := String(layer.get("anchor", ROOT_ANCHOR)).strip_edges()
	if anchor.is_empty():
		anchor = ROOT_ANCHOR
	if not anchor_ids.has(anchor):
		errors.append("%s references missing anchor '%s'" % [label, anchor])
	var point_error := _point_error(layer.get("offset", [0, 0]))
	if not point_error.is_empty():
		errors.append("%s offset %s" % [label, point_error])
	point_error = _point_error(layer.get("scale", [1, 1]))
	if not point_error.is_empty():
		errors.append("%s scale %s" % [label, point_error])
	else:
		var scale: Array = layer.get("scale", [1, 1])
		if is_zero_approx(float(scale[0])) or is_zero_approx(float(scale[1])):
			errors.append("%s scale cannot contain zero" % label)
	var rotation := float(layer.get("rotation_degrees", 0.0))
	if not is_finite(rotation):
		errors.append("%s rotation_degrees must be finite" % label)
	for boolean_key in ["author_visible", "player_visible", "flip_h", "flip_v"]:
		if layer.has(boolean_key) and not layer[boolean_key] is bool:
			errors.append("%s %s must be boolean" % [label, boolean_key])
	if layer.has("frame") and not (layer["frame"] is int or layer["frame"] is float):
		errors.append("%s frame must be an integer" % label)
	elif layer.has("frame") and float(layer["frame"]) != floorf(float(layer["frame"])):
		errors.append("%s frame must be an integer" % label)
	for string_key in ["asset_id", "animation", "palette_id", "palette_role"]:
		if layer.has(string_key) and not layer[string_key] is String:
			errors.append("%s %s must be a string" % [label, string_key])
	if layer.has("visibility") and not layer["visibility"] is Dictionary:
		errors.append("%s visibility must be an object" % label)


static func _anchor_has_cycle(anchor_id: String, all_anchors: Array[Dictionary]) -> bool:
	var by_id := {}
	for anchor in all_anchors:
		by_id[String(anchor.get("id", ""))] = anchor
	var seen := {}
	var current := anchor_id
	while current != ROOT_ANCHOR and by_id.has(current):
		if seen.has(current):
			return true
		seen[current] = true
		current = String(by_id[current].get("parent", ROOT_ANCHOR)).strip_edges()
		if current.is_empty():
			current = ROOT_ANCHOR
	return false


static func _merge_anchors(base_value: Variant, child_value: Variant) -> Array[Dictionary]:
	var merged: Array[Dictionary] = []
	var positions := {}
	for value in [base_value, child_value]:
		if not value is Array:
			continue
		for raw_anchor in value:
			if not raw_anchor is Dictionary:
				continue
			var anchor: Dictionary = raw_anchor
			var anchor_id := String(anchor.get("id", ""))
			if positions.has(anchor_id):
				merged[positions[anchor_id]] = anchor.duplicate(true)
			else:
				positions[anchor_id] = merged.size()
				merged.append(anchor.duplicate(true))
	return merged


static func _dictionary_array(
	value: Variant, field: String, prefix: String, errors: Array[String]
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not value is Array:
		errors.append("%s: %s must be an array" % [prefix, field])
		return result
	for index in value.size():
		if not value[index] is Dictionary:
			errors.append("%s: %s[%d] must be an object" % [prefix, field, index])
			continue
		result.append((value[index] as Dictionary).duplicate(true))
	return result


static func _as_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


static func _layer_index(layers_value: Array, layer_id: String) -> int:
	for index in layers_value.size():
		if (
			layers_value[index] is Dictionary
			and String(layers_value[index].get("id", "")) == layer_id
		):
			return index
	return -1


static func _point_error(value: Variant) -> String:
	if not value is Array or value.size() != 2:
		return "must be a two-number point"
	for component in value:
		if not (component is int or component is float) or not is_finite(float(component)):
			return "must be a finite two-number point"
	return ""


static func _string_field(
	data: Dictionary, field: String, prefix: String, errors: Array[String], required: bool
) -> String:
	if not data.has(field):
		if required:
			errors.append("%s: missing %s" % [prefix, field])
		return ""
	if typeof(data[field]) != TYPE_STRING:
		errors.append("%s: %s must be a string" % [prefix, field])
		return ""
	var value := String(data[field]).strip_edges()
	if required and value.is_empty():
		errors.append("%s: %s cannot be empty" % [prefix, field])
	return value


static func _integer_field(
	data: Dictionary, field: String, prefix: String, errors: Array[String], required: bool
) -> int:
	if not data.has(field):
		if required:
			errors.append("%s: missing %s" % [prefix, field])
		return 0
	if (
		not (data[field] is int or data[field] is float)
		or float(data[field]) != floorf(float(data[field]))
	):
		errors.append("%s: %s must be an integer" % [prefix, field])
		return 0
	return int(data[field])


static func _valid_id(value: String) -> bool:
	if value.is_empty():
		return false
	var expression := RegEx.new()
	expression.compile("^[a-z0-9_-]+$")
	return expression.search(value) != null
