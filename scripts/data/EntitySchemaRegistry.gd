class_name EntitySchemaRegistry extends RefCounted
# Engine-owned declarative schemas interpreted by one strict validator. Packs
# select registered kind/version pairs; they cannot register executable code.

var _schemas: Dictionary = {}
# handler_id -> set of admitted schema_versions. Packs select registered handlers;
# they never supply evaluators.
var _handlers: Dictionary = {}


static func with_core_schemas():
	var registry = new()
	var nonnegative_int := {"type": "integer", "minimum": 0}
	var string_list := {
		"type": "array", "unique_items": true, "items": {"type": "string", "min_length": 1}
	}
	var int_map := {"type": "object", "additional_properties": nonnegative_int}
	var descriptor := {
		"type": "object",
		"required": ["handler_id", "schema_version", "parameters"],
		"properties":
		{
			"handler_id": {"type": "string", "min_length": 1},
			"schema_version": {"type": "integer", "minimum": 1},
			"parameters": {"type": "object", "additional_properties": {}},
		},
	}
	var variant := {
		"type": "object",
		"required": ["variant_id", "eligibility", "overrides"],
		"properties":
		{
			"variant_id": {"type": "string", "min_length": 1},
			"eligibility": descriptor,
			"overrides": {"type": "object", "additional_properties": {}},
		},
	}
	(
		registry
		. register_schema(
			"class",
			1,
			{
				"required":
				[
					"kind",
					"schema_version",
					"id",
					"display_name",
					"source_refs",
					"tier",
					"max_level",
					"base_movement",
					"internal_level_rule",
					"weapon_wexp_bases",
					"weapon_wexp_caps",
					"player_growth_rates",
					"enemy_growth_rates",
					"stat_caps",
					"field_completeness",
					"advancement_edge_refs"
				],
				"properties":
				{
					"kind": {"type": "string", "enum": ["class"]},
					"schema_version": {"type": "integer", "enum": [1]},
					"id": {"type": "string", "min_length": 1},
					"display_name": {"type": "string", "min_length": 1},
					"display_name_key": {"type": "string", "min_length": 1},
					"description": {"type": "string"},
					"source_refs":
					{
						"type": "array",
						"min_items": 1,
						"unique_items": true,
						"items": {"type": "string", "min_length": 1},
						"resolves_in": "sources",
					},
					"occurrence_audit_refs":
					{
						"type": "array",
						"unique_items": true,
						"items": {"type": "string", "min_length": 1},
						"resolves_in": "occurrences",
					},
					"tier": {"type": "integer", "minimum": 1},
					"max_level": {"type": "integer", "minimum": 1},
					"base_hp": nonnegative_int,
					"base_strength": nonnegative_int,
					"base_magic": nonnegative_int,
					"base_defense": nonnegative_int,
					"base_resistance": nonnegative_int,
					"base_skill": nonnegative_int,
					"base_speed": nonnegative_int,
					"base_luck": nonnegative_int,
					"base_movement": nonnegative_int,
					"base_constitution": nonnegative_int,
					"base_line_of_sight": nonnegative_int,
					"internal_level_rule": {"type": "string", "enum": ["base", "promoted"]},
					"weapon_wexp_bases": int_map,
					"weapon_wexp_caps": int_map,
					"player_growth_rates": int_map,
					"enemy_growth_rates": int_map,
					"stat_caps": int_map,
					"skill_unlocks":
					{
						"type": "object",
						"additional_properties": {"type": "string", "min_length": 1}
					},
					"field_completeness":
					{
						"type": "object",
						"additional_properties":
						{"type": "string", "enum": ["verified", "unverified", "not_applicable"]}
					},
					"advancement_edge_refs": string_list,
					"allowed_weapon_families": string_list,
					"class_groups": string_list,
					"special_qualities": string_list,
					"vulnerability_groups": string_list,
					"sprite_id": {"type": "string"},
					"default_movement_profile_id": {"type": "string", "min_length": 1},
					"variants": {"type": "array", "unique_key": "variant_id", "items": variant},
				},
				"validator": Callable(EntitySchemaRegistry, "_validate_class_contract"),
			}
		)
	)

	# Trusted executable descriptors resolve through an open registry rather than a
	# hardcoded match, so a new advancement handler is a registration, not an engine
	# edit. Trial v1 admits only `class_advancement_v1` (class schema trial doc).
	registry.register_handler("class_advancement_v1", 1)

	# Advancement edges and routes share the descriptor shape and the identity/
	# provenance header used by every content document.
	var signed_int_map := {"type": "object", "additional_properties": {"type": "integer"}}
	var descriptor_list := {"type": "array", "items": descriptor}
	var edge_variant := {
		"type": "object",
		"required": ["variant_id", "eligibility", "overrides"],
		"properties":
		{
			"variant_id": {"type": "string", "min_length": 1},
			"eligibility": descriptor,
			"overrides": {"type": "object", "additional_properties": {}},
		},
	}
	var document_header := {
		"kind": {"type": "string", "min_length": 1},
		"schema_version": {"type": "integer", "enum": [1]},
		"id": {"type": "string", "min_length": 1},
		"display_name": {"type": "string", "min_length": 1},
		"display_name_key": {"type": "string", "min_length": 1},
		"description": {"type": "string"},
		"source_refs":
		{
			"type": "array",
			"min_items": 1,
			"unique_items": true,
			"items": {"type": "string", "min_length": 1},
			"resolves_in": "sources",
		},
		"occurrence_audit_refs":
		{
			"type": "array",
			"unique_items": true,
			"items": {"type": "string", "min_length": 1},
			"resolves_in": "occurrences",
		},
	}

	var edge_properties := document_header.duplicate(true)
	edge_properties["kind"] = {"type": "string", "enum": ["advancement_edge"]}
	edge_properties["source_class_ref"] = {"type": "string", "min_length": 1}
	# A fixed edge has exactly one destination and a branching edge has more than
	# one; both use this schema and the same commit path, so only emptiness fails.
	edge_properties["destination_class_refs"] = {
		"type": "array",
		"min_items": 1,
		"unique_items": true,
		"items": {"type": "string", "min_length": 1},
	}
	edge_properties["route_refs"] = {
		"type": "array", "unique_items": true, "items": {"type": "string", "min_length": 1}
	}
	edge_properties["transition"] = descriptor
	# Promotion gains are added, so a negative adjustment is meaningful; WEXP grants
	# are applied as floors via max(), so a negative grant never is.
	edge_properties["stat_gains"] = signed_int_map
	edge_properties["weapon_wexp_grants"] = int_map
	edge_properties["operations"] = descriptor_list
	edge_properties["selected_class_variant_id"] = {"type": "string", "min_length": 1}
	edge_properties["variants"] = {
		"type": "array", "unique_key": "variant_id", "items": edge_variant
	}
	(
		registry
		. register_schema(
			"advancement_edge",
			1,
			{
				"required":
				[
					"kind",
					"schema_version",
					"id",
					"display_name",
					"source_refs",
					"source_class_ref",
					"destination_class_refs",
					"route_refs",
					"transition",
					"stat_gains",
					"weapon_wexp_grants",
					"variants"
				],
				"properties": edge_properties,
				"validator": Callable(registry, "_validate_edge_contract"),
			}
		)
	)

	var route_properties := document_header.duplicate(true)
	route_properties["kind"] = {"type": "string", "enum": ["advancement_route"]}
	route_properties["trigger"] = descriptor
	# Authored order is meaningful for requirements, so this stays an ordered array
	# and is never sorted or deduplicated.
	route_properties["requirements"] = descriptor_list
	route_properties["cost"] = descriptor
	route_properties["selection"] = descriptor
	route_properties["transition"] = descriptor
	route_properties["priority"] = {"type": "integer"}
	(
		registry
		. register_schema(
			"advancement_route",
			1,
			{
				"required":
				[
					"kind",
					"schema_version",
					"id",
					"display_name",
					"source_refs",
					"trigger",
					"requirements",
					"cost",
					"selection",
					"transition",
					"priority"
				],
				"properties": route_properties,
				"validator": Callable(registry, "_validate_route_contract"),
			}
		)
	)
	return registry


func register_handler(handler_id: String, schema_version: int) -> void:
	if not _handlers.has(handler_id):
		_handlers[handler_id] = {}
	_handlers[handler_id][schema_version] = true


func register_schema(kind: String, version: int, schema: Dictionary) -> void:
	_schemas[_schema_key(kind, version)] = schema.duplicate(true)


func validate_document(
	kind: String, version: int, document: Variant, sources: Dictionary, occurrences: Dictionary = {}
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
			var code := "required_field_missing"
			if field == "source_refs":
				code = "provenance_document_missing"
			errors.append(
				_error(
					code, "%s.%s" % [root_path, field], "Required field '%s' is missing." % field
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
			{"sources": sources, "occurrences": occurrences},
			errors
		)
	var validator: Callable = schema.get("validator", Callable())
	if validator.is_valid():
		validator.call(document, root_path, errors)
	return errors


func _validate_value(
	value: Variant,
	field_schema: Dictionary,
	path: String,
	registries: Dictionary,
	errors: Array[Dictionary]
) -> void:
	if not field_schema.has("type") or String(field_schema.get("type", "")).strip_edges() == "":
		errors.append(
			_error("schema_type_missing", path, "Engine schema field has no declared type.")
		)
		return
	var declared_type := String(field_schema["type"])
	if field_schema.has("enum") and not field_schema["enum"].has(value):
		errors.append(_error("value_not_admitted", path, "Value is not in the admitted set."))
		return
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
			if bool(field_schema.get("unique_items", false)):
				var seen := {}
				for item in value:
					var token := JSON.stringify(item)
					if seen.has(token):
						errors.append(
							_error("duplicate_value", path, "Array entries must be unique.")
						)
						break
					seen[token] = true
			var unique_key := String(field_schema.get("unique_key", ""))
			if not unique_key.is_empty():
				var seen_keys := {}
				for item in value:
					if item is Dictionary and item.has(unique_key):
						var token := String(item[unique_key])
						if seen_keys.has(token):
							errors.append(
								_error(
									"duplicate_value",
									path,
									"'%s' values must be unique." % unique_key
								)
							)
							break
						seen_keys[token] = true
			var item_schema: Dictionary = field_schema.get("items", {})
			for index in value.size():
				var item_path := "%s[%d]" % [path, index]
				_validate_value(value[index], item_schema, item_path, registries, errors)
				if (
					field_schema.has("resolves_in")
					and typeof(value[index]) == TYPE_STRING
					and not registries.get(String(field_schema["resolves_in"]), {}).has(
						value[index]
					)
				):
					var registry_name := String(field_schema["resolves_in"])
					var code := "reference_unresolved"
					if registry_name == "sources":
						code = "provenance_source_unresolved"
					elif registry_name == "occurrences":
						code = "provenance_occurrence_unresolved"
					errors.append(
						_error(
							code,
							item_path,
							"Source reference '%s' does not resolve." % value[index]
						)
					)
		"integer":
			if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
				errors.append(_error("type_mismatch", path, "Value must be an integer."))
			elif int(value) != value:
				errors.append(_error("type_mismatch", path, "Value must be an integer."))
			elif field_schema.has("minimum") and int(value) < int(field_schema["minimum"]):
				errors.append(
					_error("value_too_small", path, "Integer value is below the minimum.")
				)
		"object":
			if not value is Dictionary:
				errors.append(_error("type_mismatch", path, "Value must be an object."))
				return
			var properties: Dictionary = field_schema.get("properties", {})
			for required_field: String in field_schema.get("required", []):
				if not value.has(required_field):
					errors.append(
						_error(
							"required_field_missing",
							"%s.%s" % [path, required_field],
							"Required field is missing."
						)
					)
			var keys: Array = value.keys()
			keys.sort()
			for key: Variant in keys:
				var key_name := String(key)
				if properties.has(key_name):
					_validate_value(
						value[key],
						properties[key_name],
						"%s.%s" % [path, key_name],
						registries,
						errors
					)
				elif field_schema.has("additional_properties"):
					var additional: Dictionary = field_schema["additional_properties"]
					if not additional.is_empty():
						_validate_value(
							value[key], additional, "%s.%s" % [path, key_name], registries, errors
						)
				else:
					errors.append(
						_error(
							"unknown_field",
							"%s.%s" % [path, key_name],
							"Field is not admitted by this object."
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


static func _validate_class_contract(
	document: Dictionary, root_path: String, errors: Array[Dictionary]
) -> void:
	var allowed_overrides := {
		"base_hp": true,
		"base_strength": true,
		"base_magic": true,
		"base_defense": true,
		"base_resistance": true,
		"base_skill": true,
		"base_speed": true,
		"base_luck": true,
		"base_movement": true,
		"base_constitution": true,
		"base_line_of_sight": true,
		"weapon_wexp_bases": true,
		"weapon_wexp_caps": true,
		"allowed_weapon_families": true,
		"class_groups": true,
		"special_qualities": true,
		"vulnerability_groups": true,
		"player_growth_rates": true,
		"enemy_growth_rates": true,
		"stat_caps": true,
		"skill_unlocks": true,
		"sprite_id": true,
		"default_movement_profile_id": true,
	}
	for index in document.get("variants", []).size():
		var variant: Variant = document.get("variants", [])[index]
		if not variant is Dictionary or not variant.get("overrides", null) is Dictionary:
			continue
		for field in variant["overrides"]:
			if not allowed_overrides.has(String(field)):
				errors.append(
					_error(
						"variant_override_forbidden",
						"%s.variants[%d].overrides.%s" % [root_path, index, field],
						"Class variants may override only class-owned fields."
					)
				)
	var bases: Dictionary = document.get("weapon_wexp_bases", {})
	var caps: Dictionary = document.get("weapon_wexp_caps", {})
	for track in bases:
		if caps.has(track) and int(bases[track]) > int(caps[track]):
			errors.append(
				_error(
					"wexp_base_exceeds_cap",
					"%s.weapon_wexp_bases.%s" % [root_path, track],
					"WEXP base cannot exceed its cap."
				)
			)


func _validate_edge_contract(
	document: Dictionary, root_path: String, errors: Array[Dictionary]
) -> void:
	# Edge variants are deliberately narrower than class variants: they may retarget
	# and re-price the transition, but never restate identity, provenance, or the
	# routes/handler that decide whether the transition may happen at all.
	var allowed_overrides := {
		"destination_class_refs": true,
		"stat_gains": true,
		"weapon_wexp_grants": true,
		"operations": true,
	}
	for index in document.get("variants", []).size():
		var variant: Variant = document.get("variants", [])[index]
		if not variant is Dictionary or not variant.get("overrides", null) is Dictionary:
			continue
		for field in variant["overrides"]:
			if not allowed_overrides.has(String(field)):
				(
					errors
					. append(
						_error(
							"variant_override_forbidden",
							"%s.variants[%d].overrides.%s" % [root_path, index, field],
							"Advancement edge variants may override only destination, gains, and operations."
						)
					)
				)
	# A selected destination variant is only meaningful once eligibility has admitted
	# a destination, so an edge naming one must admit at least one destination class.
	var selected := String(document.get("selected_class_variant_id", ""))
	var destinations: Variant = document.get("destination_class_refs", [])
	if not selected.is_empty() and (not destinations is Array or destinations.is_empty()):
		errors.append(
			_error(
				"selected_variant_without_destination",
				"%s.selected_class_variant_id" % root_path,
				"A selected class variant requires at least one destination class."
			)
		)
	_validate_descriptor(document.get("transition", null), "%s.transition" % root_path, errors)
	_validate_descriptor_list(document.get("operations", []), "%s.operations" % root_path, errors)


func _validate_route_contract(
	document: Dictionary, root_path: String, errors: Array[Dictionary]
) -> void:
	# Every executable descriptor on a route resolves against the trusted registry
	# before any preview runs, so an unknown handler fails validation rather than
	# surfacing as a runtime error mid-transition.
	for field in ["trigger", "cost", "selection", "transition"]:
		_validate_descriptor(document.get(field, null), "%s.%s" % [root_path, field], errors)
	_validate_descriptor_list(
		document.get("requirements", []), "%s.requirements" % root_path, errors
	)


func _validate_descriptor_list(value: Variant, path: String, errors: Array[Dictionary]) -> void:
	if not value is Array:
		return
	for index in value.size():
		_validate_descriptor(value[index], "%s[%d]" % [path, index], errors)


func _validate_descriptor(value: Variant, path: String, errors: Array[Dictionary]) -> void:
	# Shape errors are already reported by the schema pass; this only decides whether
	# a well-formed descriptor names a handler the engine actually trusts.
	if not value is Dictionary or not value.has("handler_id"):
		return
	var handler_id := String(value["handler_id"])
	if not _handlers.has(handler_id):
		errors.append(
			_error(
				"handler_unknown",
				"%s.handler_id" % path,
				"Handler '%s' is not registered with the engine." % handler_id
			)
		)
		return
	if not value.has("schema_version"):
		return
	var version := int(value["schema_version"])
	if not _handlers[handler_id].has(version):
		errors.append(
			_error(
				"handler_version_unsupported",
				"%s.schema_version" % path,
				"Handler '%s' does not admit schema version %d." % [handler_id, version]
			)
		)


func _document_root(kind: String, version: int, document: Dictionary) -> String:
	var entity_id := String(document.get("id", "<unknown>"))
	if entity_id == "":
		entity_id = "<unknown>"
	return "$[%s@%d:%s]" % [kind, version, entity_id]


func _schema_key(kind: String, version: int) -> String:
	return "%s@%d" % [kind, version]


static func _error(code: String, path: String, message: String) -> Dictionary:
	return {"code": code, "path": path, "message": message}
