class_name SpriteCompositionEditor extends RefCounted
# adopter-todo: EDITOR-SPRITE-COMPOSITION-2026-08-26
## Headless authoring model for sprite compositions and faction palettes.
##
## The editor edits the same JSON-shaped documents the runtime consumes. It does
## not create semantic slots or a second preview renderer.

const Composition = preload("res://scripts/resources/SpriteCompositionDef.gd")
const Palette = preload("res://scripts/resources/FactionPaletteDef.gd")
const Renderer = preload("res://scripts/units/SpriteCompositionRenderer.gd")

const ACCEPTED := "accepted"
const REFUSED := "refused"

var _composition: Dictionary = {}
var _palettes: Dictionary = {}
var _definitions: Dictionary = {}


func set_document(
	composition: Dictionary, palettes: Dictionary = {}, definitions: Dictionary = {}
) -> Dictionary:
	var errors: Array[String] = []
	var parsed = Composition.parse(composition, "editor.composition", errors)
	if parsed == null:
		return _refused("Composition is invalid.", errors)
	var accepted_palettes: Dictionary = {}
	for palette_id in palettes:
		var palette_errors: Array[String] = []
		var palette = Palette.parse(
			palettes[palette_id], "editor.palette.%s" % palette_id, palette_errors
		)
		if palette == null:
			return _refused("Palette '%s' is invalid." % palette_id, palette_errors)
		accepted_palettes[String(palette_id)] = palette.to_dict()
	_composition = composition.duplicate(true)
	_palettes = accepted_palettes
	_definitions = definitions.duplicate(true)
	return _accepted()


func composition() -> Dictionary:
	return _composition.duplicate(true)


func palettes() -> Dictionary:
	return _palettes.duplicate(true)


func reorder_layers(order: Array[String]) -> Dictionary:
	var current: Array = _composition.get("layers", [])
	if order.size() != current.size():
		return _refused("The reordered list must contain every layer exactly once.")
	var by_id := {}
	for layer in current:
		if layer is Dictionary:
			by_id[String(layer.get("id", ""))] = layer
	var reordered: Array[Dictionary] = []
	for layer_id in order:
		if (
			not by_id.has(layer_id)
			or reordered.any(func(row: Dictionary): return row.get("id") == layer_id)
		):
			return _refused("Layer order contains an unknown or repeated layer '%s'." % layer_id)
		reordered.append((by_id[layer_id] as Dictionary).duplicate(true))
	var candidate := _composition.duplicate(true)
	candidate["layers"] = reordered
	return _commit_composition(candidate)


func set_anchor(anchor_id: String, parent_id: String, offset: Array) -> Dictionary:
	var candidate := _composition.duplicate(true)
	var anchors: Array = candidate.get("anchors", []).duplicate(true)
	var found := false
	for index in anchors.size():
		if String(anchors[index].get("id", "")) == anchor_id:
			anchors[index]["parent"] = parent_id
			anchors[index]["offset"] = offset.duplicate()
			found = true
			break
	if not found:
		anchors.append({"id": anchor_id, "parent": parent_id, "offset": offset.duplicate()})
	candidate["anchors"] = anchors
	return _commit_composition(candidate)


func set_inheritance(base_id: String, operations: Array[Dictionary]) -> Dictionary:
	var candidate := _composition.duplicate(true)
	candidate["base_composition_id"] = base_id
	candidate["layers"] = []
	candidate["layer_operations"] = operations.duplicate(true)
	return _commit_composition(candidate)


func set_palette(palette_id: String, palette: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var parsed = Palette.parse(palette, "editor.palette.%s" % palette_id, errors)
	if parsed == null:
		return _refused("Palette '%s' is invalid." % palette_id, errors)
	_palettes[palette_id] = parsed.to_dict()
	return _accepted()


func set_palette_mapping(
	palette_id: String, mapping_index: int, source: Array, target: Array
) -> Dictionary:
	if not _palettes.has(palette_id):
		return _refused("Palette '%s' does not exist." % palette_id)
	var candidate: Dictionary = _palettes[palette_id].duplicate(true)
	var mappings: Array = candidate.get("mappings", []).duplicate(true)
	if mapping_index < 0:
		mappings.append({"from": source.duplicate(), "to": target.duplicate()})
	elif mapping_index < mappings.size():
		mappings[mapping_index] = {"from": source.duplicate(), "to": target.duplicate()}
	else:
		return _refused("Palette mapping index %d does not exist." % mapping_index)
	candidate["mappings"] = mappings
	return set_palette(palette_id, candidate)


func set_palette_fallback(palette_id: String, tint: Array) -> Dictionary:
	if not _palettes.has(palette_id):
		return _refused("Palette '%s' does not exist." % palette_id)
	var candidate: Dictionary = _palettes[palette_id].duplicate(true)
	candidate["fallback_tint"] = tint.duplicate()
	return set_palette(palette_id, candidate)


func validation() -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var parsed = Composition.parse(_composition, "editor.composition", errors)
	if parsed == null:
		return {"errors": errors, "warnings": warnings}
	for palette_id in _palettes:
		var palette_errors: Array[String] = []
		var palette = Palette.parse(
			_palettes[palette_id], "editor.palette.%s" % palette_id, palette_errors
		)
		errors.append_array(palette_errors)
		if palette != null:
			warnings.append_array(palette.validation_warnings())
	return {"errors": errors, "warnings": warnings}


func resolved_composition() -> Dictionary:
	var resolved := Composition.resolve(_composition, _definitions)
	return {
		"composition": resolved.get("composition", {}),
		"errors": resolved.get("errors", []),
	}


func preview(parent: Node2D, assets: Dictionary, faction_id: String = "") -> Dictionary:
	var resolved := resolved_composition()
	if not (resolved["errors"] as Array).is_empty():
		return {
			"ok": false, "root": null, "layers": [], "warnings": [], "errors": resolved["errors"]
		}
	return Renderer.render(parent, resolved["composition"], assets, _palettes, faction_id)


func collision_warnings(layer_bounds: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	var ids: Array = layer_bounds.keys()
	ids.sort()
	for left_index in range(ids.size()):
		var left_id := String(ids[left_index])
		if not layer_bounds[left_id] is Rect2:
			continue
		for right_index in range(left_index + 1, ids.size()):
			var right_id := String(ids[right_index])
			if (
				layer_bounds[right_id] is Rect2
				and layer_bounds[left_id].intersects(layer_bounds[right_id])
			):
				warnings.append(
					(
						"Potential collision between authored layers '%s' and '%s'."
						% [left_id, right_id]
					)
				)
	return warnings


func _commit_composition(candidate: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var parsed = Composition.parse(candidate, "editor.composition", errors)
	if parsed == null:
		return _refused("The edit would make the composition invalid.", errors)
	_composition = candidate
	return _accepted()


func _accepted() -> Dictionary:
	return {"status": ACCEPTED, "reason": ""}


func _refused(reason: String, errors: Array = []) -> Dictionary:
	return {"status": REFUSED, "reason": reason, "errors": errors}
