extends SceneTree
# Acceptance test for the first generic entity-schema/provenance prototype.

const EntitySchemaRegistry = preload("res://scripts/data/EntitySchemaRegistry.gd")
const ClassAdvancement = preload("res://scripts/resources/ClassAdvancement.gd")


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
		"kind": "class",
		"schema_version": 1,
		"id": "cavalier",
		"display_name": "Cavalier",
		"source_refs": ["fed20_classes"],
		"occurrence_audit_refs": ["cavalier_move"],
		"tier": 1,
		"max_level": 20,
		"base_movement": 7,
		"internal_level_rule": "base",
		"weapon_wexp_bases": {"sword": 1, "lance": 1},
		"weapon_wexp_caps": {"sword": 200, "lance": 200},
		"player_growth_rates": {"hp": 20},
		"enemy_growth_rates": {"hp": 40},
		"stat_caps": {"hp": 40},
		"field_completeness": {"stat_caps": "verified"},
		"advancement_edge_refs": ["cavalier_promotion"],
		"variants":
		[
			{
				"variant_id": "swift",
				"eligibility":
				{
					"handler_id": "fact_contains_v1",
					"schema_version": 1,
					"parameters": {"fact_id": "training", "value": "swift"},
				},
				"overrides": {"stat_caps": {"hp": 38}},
			}
		],
	}
	var occurrences := {"cavalier_move": {"document_ref": "class:cavalier"}}

	var valid_errors: Array[Dictionary] = registry.validate_document(
		"class", 1, valid_class, sources, occurrences
	)
	if valid_errors.is_empty():
		print("OK  golden class document passes the engine-owned schema")
		passed += 1
	else:
		print("FAIL golden class errors: %s" % [valid_errors])
		failed += 1

	var invalid_class := {
		"kind": "class",
		"schema_version": 1,
		"id": "cavalier",
		"source_refs": ["missing_source"],
		"engine_script": "res://unsafe.gd",
	}
	var errors: Array[Dictionary] = registry.validate_document("class", 1, invalid_class, sources)
	var by_code := {}
	var has_display_missing := false
	for error in errors:
		by_code[error.get("code", "")] = error
		if (
			error.get("code") == "required_field_missing"
			and error.get("path") == "$[class@1:cavalier].display_name"
		):
			has_display_missing = true
	if (
		has_display_missing
		and by_code.has("unknown_field")
		and by_code["unknown_field"].get("path") == "$[class@1:cavalier].engine_script"
		and by_code.has("provenance_source_unresolved")
		and (
			by_code["provenance_source_unresolved"].get("path")
			== "$[class@1:cavalier].source_refs[0]"
		)
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

	var missing_occurrence := valid_class.duplicate(true)
	missing_occurrence["occurrence_audit_refs"] = ["missing_occurrence"]
	var occurrence_errors: Array[Dictionary] = registry.validate_document(
		"class", 1, missing_occurrence, sources, occurrences
	)
	if (
		occurrence_errors.size() == 1
		and occurrence_errors[0].get("code") == "provenance_occurrence_unresolved"
		and occurrence_errors[0].get("path") == "$[class@1:cavalier].occurrence_audit_refs[0]"
	):
		print("OK  dangling occurrence evidence is distinct from a dangling source")
		passed += 1
	else:
		print("FAIL occurrence provenance response: %s" % [occurrence_errors])
		failed += 1

	var forbidden_variant := valid_class.duplicate(true)
	forbidden_variant["variants"][0]["overrides"] = {"id": "other_class"}
	var variant_errors: Array[Dictionary] = registry.validate_document(
		"class", 1, forbidden_variant, sources, occurrences
	)
	if (
		variant_errors.size() == 1
		and variant_errors[0].get("code") == "variant_override_forbidden"
		and variant_errors[0].get("path") == "$[class@1:cavalier].variants[0].overrides.id"
	):
		print("OK  class variants cannot override identity or provenance")
		passed += 1
	else:
		print("FAIL variant boundary response: %s" % [variant_errors])
		failed += 1

	var invalid_wexp := valid_class.duplicate(true)
	invalid_wexp["weapon_wexp_bases"]["sword"] = 201
	var wexp_errors: Array[Dictionary] = registry.validate_document(
		"class", 1, invalid_wexp, sources, occurrences
	)
	if (
		wexp_errors.size() == 1
		and wexp_errors[0].get("code") == "wexp_base_exceeds_cap"
		and wexp_errors[0].get("path") == "$[class@1:cavalier].weapon_wexp_bases.sword"
	):
		print("OK  class WEXP bases cannot exceed their authored caps")
		passed += 1
	else:
		print("FAIL WEXP boundary response: %s" % [wexp_errors])
		failed += 1

	var edge := {
		"id": "cavalier_promotion",
		"destination_class_refs": ["paladin", "great_knight"],
		"stat_gains": {"strength": 2},
		"weapon_wexp_grants": {"sword": 50},
		"variants":
		[
			{
				"variant_id": "paladin_only",
				"overrides": {"destination_class_refs": ["paladin"]},
			}
		],
	}
	var fixed := edge.duplicate(true)
	fixed["destination_class_refs"] = ["paladin"]
	var fixed_resolution := ClassAdvancement.resolve(fixed, "paladin")
	var branch_resolution := ClassAdvancement.resolve(edge, "great_knight")
	if fixed_resolution["valid"] and branch_resolution["valid"]:
		print("OK  fixed and branching advancement share one resolver")
		passed += 1
	else:
		print("FAIL advancement resolution: %s / %s" % [fixed_resolution, branch_resolution])
		failed += 1

	var state := {"class_id": "cavalier", "strength": 5, "weapon_wexp": {"sword": 10}}
	var before_state := state.duplicate(true)
	var rejected := ClassAdvancement.resolve(edge, "great_knight", "", "paladin_only")
	var cancelled_commit := ClassAdvancement.commit_state(state, branch_resolution, false)
	var rejected_commit := ClassAdvancement.commit_state(state, rejected, true)
	if not cancelled_commit and not rejected_commit and state == before_state:
		print("OK  cancelled and invalid advancement leave state untouched")
		passed += 1
	else:
		print("FAIL rejected advancement mutated state: %s" % [state])
		failed += 1

	var committed := ClassAdvancement.commit_state(state, branch_resolution, true)
	if (
		committed
		and state["class_id"] == "great_knight"
		and state["strength"] == 7
		and state["weapon_wexp"]["sword"] == 50
		and state["class_variant_id"] == null
	):
		print("OK  confirmed advancement records selection and applies gains atomically")
		passed += 1
	else:
		print("FAIL advancement commit: %s" % [state])
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
