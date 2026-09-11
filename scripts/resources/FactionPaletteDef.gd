class_name FactionPaletteDef extends RefCounted

## JSON-friendly authored palette for one sprite composition layer.
##
## A palette is deliberately a complete exact-RGBA mapping with a tint fallback.
## The renderer can choose the mapping when it is available and fall back to the
## tint without changing the non-colour faction cues owned by the engine.

const SCHEMA_VERSION := 1
const MAX_MAPPINGS := 32
const AUTHORING_WARNING_MAPPINGS := 16

var schema_version: int = SCHEMA_VERSION
var id: String = ""
var display_name: String = ""
var fallback_tint: Color = Color.WHITE
var mappings: Array[Dictionary] = []


static func parse(raw: Variant, source_path: String, errors: Array[String]) -> FactionPaletteDef:
	var prefix := "FactionPaletteDef(%s)" % source_path
	if not raw is Dictionary:
		errors.append("%s: root must be an object" % prefix)
		return null
	var data: Dictionary = raw
	var palette = new()
	palette.schema_version = _integer_field(data, "schema_version", prefix, errors, true)
	palette.id = _string_field(data, "id", prefix, errors, true)
	palette.display_name = _string_field(data, "display_name", prefix, errors, false)
	if data.has("fallback_tint"):
		var tint: Variant = _parse_color(data["fallback_tint"])
		if tint == null:
			errors.append("%s: fallback_tint must be an RGBA byte array" % prefix)
		else:
			palette.fallback_tint = tint
	else:
		errors.append("%s: missing fallback_tint" % prefix)

	var raw_mappings: Variant = data.get("mappings", [])
	if not raw_mappings is Array:
		errors.append("%s: mappings must be an array" % prefix)
	else:
		for index in raw_mappings.size():
			var entry: Variant = raw_mappings[index]
			if not entry is Dictionary:
				errors.append("%s: mappings[%d] must be an object" % [prefix, index])
				continue
			var mapping: Dictionary = (entry as Dictionary).duplicate(true)
			var from: Variant = _parse_color(mapping.get("from"))
			var to: Variant = _parse_color(mapping.get("to"))
			if from == null or to == null:
				errors.append(
					"%s: mappings[%d] needs RGBA byte arrays for from and to" % [prefix, index]
				)
				continue
			mapping["from"] = from
			mapping["to"] = to
			palette.mappings.append(mapping)

	for validation_error in palette.validation_errors():
		errors.append("%s: %s" % [prefix, validation_error])
	if errors.any(func(error: String): return error.begins_with(prefix + ":")):
		return null
	return palette


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if schema_version != SCHEMA_VERSION:
		errors.append("schema_version must be %d" % SCHEMA_VERSION)
	if not _valid_id(id):
		errors.append("id must use lowercase letters, digits, '_' or '-'")
	if mappings.is_empty():
		errors.append("mappings must contain at least one exact colour mapping")
	if mappings.size() > MAX_MAPPINGS:
		errors.append("mappings cannot contain more than %d entries" % MAX_MAPPINGS)
	var seen := {}
	for index in mappings.size():
		var mapping: Dictionary = mappings[index]
		var from: Variant = _parse_color(mapping.get("from"))
		var to: Variant = _parse_color(mapping.get("to"))
		if from == null or to == null:
			errors.append("mappings[%d] needs RGBA byte arrays or Colors" % index)
			continue
		var key: String = from.to_html(true)
		if seen.has(key):
			errors.append(
				"mappings[%d] duplicates source colour from mappings[%d]" % [index, seen[key]]
			)
		else:
			seen[key] = index
		if is_zero_approx(from.a) or is_zero_approx(to.a):
			errors.append("mappings[%d] cannot map transparent colours" % index)
		elif not is_equal_approx(from.a, to.a):
			errors.append("mappings[%d] cannot change alpha" % index)
	return errors


func validation_warnings() -> Array[String]:
	var warnings: Array[String] = []
	if mappings.size() > AUTHORING_WARNING_MAPPINGS and mappings.size() <= MAX_MAPPINGS:
		warnings.append(
			(
				"mappings contains %d entries; more than %d is above the tested authoring range"
				% [mappings.size(), AUTHORING_WARNING_MAPPINGS]
			)
		)
	return warnings


func normalized_mappings() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for mapping in mappings:
		var from: Variant = _parse_color(mapping.get("from"))
		var to: Variant = _parse_color(mapping.get("to"))
		if from != null and to != null:
			output.append({"from": from, "to": to})
	return output


func to_dict() -> Dictionary:
	var raw_mappings: Array[Dictionary] = []
	for mapping in mappings:
		var row: Dictionary = mapping.duplicate(true)
		row["from"] = _color_bytes(_parse_color(row.get("from")))
		row["to"] = _color_bytes(_parse_color(row.get("to")))
		raw_mappings.append(row)
	return {
		"schema_version": schema_version,
		"id": id,
		"display_name": display_name,
		"fallback_tint": _color_bytes(fallback_tint),
		"mappings": raw_mappings,
	}


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


static func _parse_color(value: Variant) -> Variant:
	if value is Color:
		return value
	if not value is Array or value.size() != 4:
		return null
	for channel in value:
		if not (channel is int or channel is float):
			return null
		if (
			float(channel) != floorf(float(channel))
			or float(channel) < 0.0
			or float(channel) > 255.0
		):
			return null
	return Color8(int(value[0]), int(value[1]), int(value[2]), int(value[3]))


static func _color_bytes(value: Variant) -> Array:
	if not value is Color:
		return []
	var color: Color = value
	return [color.r8, color.g8, color.b8, color.a8]


static func _valid_id(value: String) -> bool:
	if value.is_empty():
		return false
	var expression := RegEx.new()
	expression.compile("^[a-z0-9_-]+$")
	return expression.search(value) != null
