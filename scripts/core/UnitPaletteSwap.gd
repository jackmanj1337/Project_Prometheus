class_name UnitPaletteSwap extends RefCounted
# Pure palette-remap construction shared by Unit and headless contract tests.

const MAX_MAPPINGS := 32
const AUTHORING_WARNING_MAPPINGS := 16


static func normalized_mappings(raw: Array) -> Dictionary:
	var mappings: Array[Dictionary] = []
	var warnings: Array[String] = []
	var seen := {}
	for entry in raw:
		if not entry is Dictionary:
			continue
		var from: Variant = _color(entry.get("from", []))
		var to: Variant = _color(entry.get("to", []))
		if from == null or to == null or is_zero_approx(to.a):
			continue
		var key: String = (from as Color).to_html(true)
		if seen.has(key):
			warnings.append("Duplicate palette input %s ignored; first mapping wins." % key)
			continue
		seen[key] = true
		mappings.append({"from": from, "to": to})
		if mappings.size() == MAX_MAPPINGS:
			break
	return {"mappings": mappings, "warnings": warnings}


static func remap_color(source: Color, mappings: Array) -> Color:
	for entry in normalized_mappings(mappings)["mappings"]:
		if source == entry["from"]:
			return entry["to"]
	return source


static func build_material(raw: Array) -> ShaderMaterial:
	var mappings: Array = normalized_mappings(raw)["mappings"]
	if mappings.is_empty():
		return null
	var shader := Shader.new()
	shader.code = _shader_code(mappings.size())
	var material := ShaderMaterial.new()
	material.shader = shader
	for index in mappings.size():
		material.set_shader_parameter("from_%d" % index, mappings[index]["from"])
		material.set_shader_parameter("to_%d" % index, mappings[index]["to"])
	return material


static func _shader_code(count: int) -> String:
	var uniforms := ""
	var comparisons := ""
	for index in count:
		uniforms += "uniform vec4 from_%d; uniform vec4 to_%d;\n" % [index, index]
		comparisons += ("if (all(equal(src, from_%d))) { src = to_%d; } else " % [index, index])
	return (
		(
			"shader_type canvas_item;\n%svoid fragment() {\n"
			+ " vec4 src = texture(TEXTURE, UV);\n %s{}\n"
			+ " COLOR = src * COLOR;\n}\n"
		)
		% [uniforms, comparisons]
	)


static func _color(value: Variant) -> Variant:
	if value is Color:
		return value
	if not value is Array or value.size() != 4:
		return null
	for channel in value:
		if not channel is int and not channel is float:
			return null
		if float(channel) < 0.0 or float(channel) > 255.0:
			return null
	return Color8(int(value[0]), int(value[1]), int(value[2]), int(value[3]))
