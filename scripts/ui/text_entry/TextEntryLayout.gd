class_name TextEntryLayout
extends RefCounted

const ACTIONS := [&"backspace", &"cancel", &"candidate_select", &"submit", &"switch_layer"]

var id: StringName
var layers: Dictionary


static func load_json(path: String) -> TextEntryLayout:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return null
	var result := TextEntryLayout.new()
	result.id = StringName(str(parsed.get("id", "")))
	result.layers = parsed.get("layers", {})
	return result if result.is_valid() else null


func is_valid() -> bool:
	if id.is_empty() or layers.is_empty():
		return false
	for layer: Variant in layers.values():
		if not layer is Array:
			return false
		for row: Variant in layer:
			if not row is Array:
				return false
			for key: Variant in row:
				if not key is Dictionary:
					return false
				var emits := str(key.get("emit", ""))
				var action := StringName(str(key.get("action", "")))
				if emits.length() != 1 and action not in ACTIONS:
					return false
	return true
