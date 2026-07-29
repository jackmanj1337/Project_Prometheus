extends SceneTree
# Acceptance test for the first generic entity-schema/provenance prototype.

const EntitySchemaRegistry = preload("res://scripts/data/EntitySchemaRegistry.gd")


func _init() -> void:
	print("=== Entity Schema Registry Test ===")
	var passed := 0
	var failed := 0
	var registry = EntitySchemaRegistry.with_core_schemas()
	var sources := {
		"fed20_classes":
		{
			"locator": "http://fed20.wikidot.com/classes",
			"title": "FEd20 classes",
			"rights_status": "internal_reference_only",
			"verified_at": "2026-07-28",
		}
	}
	var valid_class := {
		"id": "cavalier",
		"display_name": "Cavalier",
		"source_refs": ["fed20_classes"],
	}

	var valid_errors: Array[Dictionary] = registry.validate_document(
		"class", 1, valid_class, sources
	)
	if valid_errors.is_empty():
		print("OK  golden class document passes the engine-owned schema")
		passed += 1
	else:
		print("FAIL golden class errors: %s" % [valid_errors])
		failed += 1

	var invalid_class := {
		"id": "cavalier",
		"source_refs": ["missing_source"],
		"engine_script": "res://unsafe.gd",
	}
	var errors: Array[Dictionary] = registry.validate_document("class", 1, invalid_class, sources)
	var by_code := {}
	for error in errors:
		by_code[error.get("code", "")] = error
	if (
		by_code.has("required_field_missing")
		and by_code["required_field_missing"].get("path") == "$[class@1:cavalier].display_name"
		and by_code.has("unknown_field")
		and by_code["unknown_field"].get("path") == "$[class@1:cavalier].engine_script"
		and by_code.has("source_ref_unresolved")
		and by_code["source_ref_unresolved"].get("path") == "$[class@1:cavalier].source_refs[0]"
	):
		print("OK  required, unknown, and dangling-source failures are structured")
		passed += 1
	else:
		print("FAIL structured errors: %s" % [errors])
		failed += 1

	var unknown_schema: Array[Dictionary] = registry.validate_document(
		"class", 99, valid_class, sources
	)
	if (
		unknown_schema.size() == 1
		and unknown_schema[0].get("code") == "schema_unknown"
		and unknown_schema[0].get("path") == "$"
	):
		print("OK  unknown schema versions fail closed")
		passed += 1
	else:
		print("FAIL unknown schema response: %s" % [unknown_schema])
		failed += 1

	# Engine schema mistakes must fail closed. A missing/empty/misspelled type used
	# to fall through the match and silently accept arbitrary field values.
	var malformed_cases := [
		["missing", {}, "schema_type_missing"],
		["empty", {"type": ""}, "schema_type_missing"],
		["typo", {"type": "strng"}, "schema_type_unknown"],
		["nested", {"type": "object"}, "schema_type_unsupported"],
	]
	for malformed in malformed_cases:
		var malformed_kind: String = malformed[0]
		registry.register_schema(
			malformed_kind, 1, {"required": ["payload"], "properties": {"payload": malformed[1]}}
		)
		var malformed_errors: Array[Dictionary] = registry.validate_document(
			malformed_kind, 1, {"id": "entity_7", "payload": {"anything": true}}, sources
		)
		var expected_code: String = malformed[2]
		if (
			malformed_errors.size() == 2
			and malformed_errors[0].get("code") == "unknown_field"
			and malformed_errors[1].get("code") == expected_code
			and malformed_errors[1].get("path") == "$[%s@1:entity_7].payload" % malformed_kind
		):
			print("OK  %s field type fails closed with entity-qualified path" % malformed_kind)
			passed += 1
		else:
			print("FAIL %s schema response: %s" % [malformed_kind, malformed_errors])
			failed += 1

	registry.register_schema(
		"array_items_missing",
		1,
		{"required": ["payload"], "properties": {"payload": {"type": "array", "items": {}}}}
	)
	var item_errors: Array[Dictionary] = registry.validate_document(
		"array_items_missing", 1, {"id": "entity_8", "payload": [42]}, sources
	)
	if (
		item_errors.size() == 2
		and item_errors[1].get("code") == "schema_type_missing"
		and item_errors[1].get("path") == "$[array_items_missing@1:entity_8].payload[0]"
	):
		print("OK  array item schema without a type fails closed at the item path")
		passed += 1
	else:
		print("FAIL missing array item type response: %s" % [item_errors])
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
