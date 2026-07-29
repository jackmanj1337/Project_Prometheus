class_name EntitySchemaRegistry extends RefCounted
# Engine-owned declarative schemas interpreted by one strict validator. Packs
# select registered kind/version pairs; they cannot register executable code.

var _schemas: Dictionary = {}


static func with_core_schemas():
	var registry = new()
	(
		registry
		. register_schema(
			"class",
			1,
			{
				"required": ["id", "display_name", "source_refs"],
				"properties":
				{
					"id": {"type": "string", "min_length": 1},
					"display_name": {"type": "string", "min_length": 1},
					"source_refs":
					{
						"type": "array",
						"min_items": 1,
						"items": {"type": "string", "min_length": 1},
						"resolves_in": "sources",
					},
				},
			}
		)
	)
	return registry


func register_schema(kind: String, version: int, schema: Dictionary) -> void:
	_schemas[_schema_key(kind, version)] = schema.duplicate(true)


func validate_document(
	kind: String, version: int, document: Variant, sources: Dictionary
) -> Array[Dictionary]:
	var errors: Array[Dictionary] = []
	var key := _schema_key(kind, version)
	if not _schemas.has(key):
		errors.append(
			_error(
				"schema_unknown",
				"$",
				"No engine schema is registered for '%s' version %d." % [kind, version]
			)
		)
		return errors
	if not document is Dictionary:
		errors.append(
			_error(
				"type_mismatch",
				"$[%s@%d:<unknown>]" % [kind, version],
				"Document must be an object."
			)
		)
		return errors

	var schema: Dictionary = _schemas[key]
	var properties: Dictionary = schema.get("properties", {})
	var root_path := _document_root(kind, version, document)
	for field: String in schema.get("required", []):
		if not document.has(field):
			errors.append(
				_error(
					"required_field_missing",
					"%s.%s" % [root_path, field],
					"Required field '%s' is missing." % field
				)
			)

	var fields: Array = document.keys()
	fields.sort()
	for field: Variant in fields:
		var field_name := String(field)
		if not properties.has(field_name):
			errors.append(
				_error(
					"unknown_field",
					"%s.%s" % [root_path, field_name],
					"Field '%s' is not admitted by this schema." % field_name
				)
			)
			continue
		_validate_value(
			document[field_name],
			properties[field_name],
			"%s.%s" % [root_path, field_name],
			sources,
			errors
		)
	return errors


func _validate_value(
	value: Variant,
	field_schema: Dictionary,
	path: String,
	sources: Dictionary,
	errors: Array[Dictionary]
) -> void:
	if not field_schema.has("type") or String(field_schema.get("type", "")).strip_edges() == "":
		errors.append(
			_error("schema_type_missing", path, "Engine schema field has no declared type.")
		)
		return
	var declared_type := String(field_schema["type"])
	match declared_type:
		"string":
			if typeof(value) != TYPE_STRING:
				errors.append(_error("type_mismatch", path, "Value must be a string."))
			elif String(value).length() < int(field_schema.get("min_length", 0)):
				errors.append(_error("value_too_short", path, "String value is too short."))
		"array":
			if not value is Array:
				errors.append(_error("type_mismatch", path, "Value must be an array."))
				return
			if value.size() < int(field_schema.get("min_items", 0)):
				errors.append(_error("array_too_short", path, "Array has too few entries."))
			var item_schema: Dictionary = field_schema.get("items", {})
			for index in value.size():
				var item_path := "%s[%d]" % [path, index]
				_validate_value(value[index], item_schema, item_path, sources, errors)
				if (
					field_schema.get("resolves_in") == "sources"
					and typeof(value[index]) == TYPE_STRING
					and not sources.has(value[index])
				):
					errors.append(
						_error(
							"source_ref_unresolved",
							item_path,
							"Source reference '%s' does not resolve." % value[index]
						)
					)
		"object":
			errors.append(
				_error(
					"schema_type_unsupported",
					path,
					"Nested object fields are not supported by entity schema version 1."
				)
			)
		_:
			errors.append(
				_error(
					"schema_type_unknown",
					path,
					"Engine schema declares unknown field type '%s'." % declared_type
				)
			)


func _document_root(kind: String, version: int, document: Dictionary) -> String:
	var entity_id := String(document.get("id", "<unknown>"))
	if entity_id == "":
		entity_id = "<unknown>"
	return "$[%s@%d:%s]" % [kind, version, entity_id]


func _schema_key(kind: String, version: int) -> String:
	return "%s@%d" % [kind, version]


func _error(code: String, path: String, message: String) -> Dictionary:
	return {"code": code, "path": path, "message": message}
