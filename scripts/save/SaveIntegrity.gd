extends RefCounted
# Canonical integrity stamps are advisory tamper evidence, never authentication.
# They support the firmed homebrew contract: mismatch warns, parse/schema errors fail.

const PAYLOAD_WARNING := "Save data was changed or corrupted. You may continue at your own risk."
const PROTECTED_WARNING := "Protected campaign rules or progression were changed. This campaign may not behave as authored."


static func stamp(source: Dictionary) -> Dictionary:
	var out := source.duplicate(true)
	out["integrity"] = {"payload_hash": "", "schema_hash": ""}
	var schema_hash := _hash(_protected_projection(out))
	var payload_hash := _hash(out)
	out["integrity"] = {"payload_hash": payload_hash, "schema_hash": schema_hash}
	return out


static func verify(source: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	var stamped: Variant = source.get("integrity", {})
	if not (stamped is Dictionary):
		warnings.append(PAYLOAD_WARNING)
		warnings.append(PROTECTED_WARNING)
		return warnings
	var expected_payload := String(stamped.get("payload_hash", ""))
	var expected_schema := String(stamped.get("schema_hash", ""))
	var blanked := source.duplicate(true)
	blanked["integrity"] = {"payload_hash": "", "schema_hash": ""}
	if expected_payload.is_empty() or expected_payload != _hash(blanked):
		warnings.append(PAYLOAD_WARNING)
	if expected_schema.is_empty() or expected_schema != _hash(_protected_projection(blanked)):
		warnings.append(PROTECTED_WARNING)
	return warnings


static func _protected_projection(source: Dictionary) -> Dictionary:
	var campaign: Dictionary = source.get("campaign", {}) \
		if source.get("campaign", {}) is Dictionary else {}
	var protected := {
		"format_version": source.get("format_version"),
		"campaign": {
			"campaign_id": campaign.get("campaign_id", ""),
			"package_id": campaign.get("package_id", ""),
			"package_version": campaign.get("package_version", ""),
			"node_id": campaign.get("node_id", ""),
			"cleared_nodes": campaign.get("cleared_nodes", []),
			"rules": campaign.get("rules", {}),
		},
	}
	# Campaign authors may add dotted paths without changing the integrity engine.
	var authored: Variant = campaign.get("protected_fields", [])
	if authored is Array:
		var extras := {}
		for raw_path in authored:
			var path := String(raw_path)
			if not path.is_empty():
				extras[path] = _value_at_path(source, path)
		protected["authored_fields"] = extras
	return protected


static func _value_at_path(source: Dictionary, path: String) -> Variant:
	var value: Variant = source
	for part in path.split(".", false):
		if not (value is Dictionary) or not value.has(part):
			return null
		value = value[part]
	return value.duplicate(true) if value is Dictionary or value is Array else value


static func _hash(value: Dictionary) -> String:
	return JSON.stringify(_canonical_value(value), "", true).sha256_text()


static func _canonical_value(value: Variant) -> Variant:
	if value is Dictionary:
		var out := {}
		for key in value:
			out[String(key)] = _canonical_value(value[key])
		return out
	if value is Array:
		var out := []
		for item in value:
			out.append(_canonical_value(item))
		return out
	# Godot's JSON parser represents JSON numbers as floats. Canonicalize whole
	# values so write -> parse -> verify remains stable.
	if value is float and is_equal_approx(value, float(int(value))):
		return int(value)
	return value
