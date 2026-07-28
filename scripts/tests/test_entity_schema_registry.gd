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
		and by_code["required_field_missing"].get("path") == "$.display_name"
		and by_code.has("unknown_field")
		and by_code["unknown_field"].get("path") == "$.engine_script"
		and by_code.has("source_ref_unresolved")
		and by_code["source_ref_unresolved"].get("path") == "$.source_refs[0]"
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

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
