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
	var occurrences := {
		"cavalier_move":
		{
			"document_ref": "class:cavalier",
			"source_ref": "fed20_classes",
			"field_path": "/base_movement",
		}
	}

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

	var mismatched_occurrences := occurrences.duplicate(true)
	mismatched_occurrences["cavalier_move"]["document_ref"] = "class:paladin"
	var mismatch_errors: Array[Dictionary] = registry.validate_document(
		"class", 1, valid_class, sources, mismatched_occurrences
	)
	if (
		mismatch_errors.size() == 1
		and mismatch_errors[0].get("code") == "provenance_occurrence_document_mismatch"
	):
		print("OK  occurrence audits bind to the document that references them")
		passed += 1
	else:
		print("FAIL occurrence document binding: %s" % [mismatch_errors])
		failed += 1

	var bad_field_occurrences := occurrences.duplicate(true)
	bad_field_occurrences["cavalier_move"]["field_path"] = "/variants/9/overrides/stat_caps"
	var bad_field_errors: Array[Dictionary] = registry.validate_document(
		"class", 1, valid_class, sources, bad_field_occurrences
	)
	if (
		bad_field_errors.size() == 1
		and bad_field_errors[0].get("code") == "provenance_occurrence_field_unresolved"
	):
		print("OK  occurrence audit field paths resolve in the owning document")
		passed += 1
	else:
		print("FAIL occurrence field coverage: %s" % [bad_field_errors])
		failed += 1

	var unreferenced_occurrences := occurrences.duplicate(true)
	unreferenced_occurrences["unclaimed"] = {
		"document_ref": "class:cavalier",
		"source_ref": "fed20_classes",
		"field_path": "/stat_caps/hp",
	}
	var unreferenced_errors: Array[Dictionary] = registry.validate_document(
		"class", 1, valid_class, sources, unreferenced_occurrences
	)
	if (
		unreferenced_errors.size() == 1
		and unreferenced_errors[0].get("code") == "provenance_occurrence_coverage_missing"
	):
		print("OK  every occurrence naming a document is referenced by that document")
		passed += 1
	else:
		print("FAIL reverse occurrence coverage: %s" % [unreferenced_errors])
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

	var unknown_class_eligibility := valid_class.duplicate(true)
	unknown_class_eligibility["variants"][0]["eligibility"]["handler_id"] = "pack_predicate"
	var unknown_class_eligibility_errors: Array[Dictionary] = registry.validate_document(
		"class", 1, unknown_class_eligibility, sources, occurrences
	)
	if (
		unknown_class_eligibility_errors.size() == 1
		and unknown_class_eligibility_errors[0].get("code") == "handler_unknown"
		and (
			unknown_class_eligibility_errors[0].get("path")
			== "$[class@1:cavalier].variants[0].eligibility.handler_id"
		)
	):
		print("OK  class variant eligibility resolves through the trusted handler registry")
		passed += 1
	else:
		print("FAIL class variant eligibility response: %s" % [unknown_class_eligibility_errors])
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

	var selected_resolution := ClassAdvancement.resolve(edge, "paladin", "female", "paladin_only")
	var selected_unit := UnitData.new()
	selected_unit.class_id = "cavalier"
	selected_unit.weapon_wexp = {"sword": 10}
	if (
		ClassAdvancement.commit_state(selected_unit, selected_resolution, true)
		and selected_unit.class_id == "paladin"
		and selected_unit.class_variant_id == "female"
		and selected_unit.advancement_edge_id == "cavalier_promotion"
		and selected_unit.advancement_edge_variant_id == "paladin_only"
	):
		print("OK  confirmed advancement records durable selections on UnitData")
		passed += 1
	else:
		print("FAIL UnitData advancement selection")
		failed += 1

	var transition := {
		"handler_id": "class_advancement_v1",
		"schema_version": 1,
		"parameters": {},
	}
	var valid_edge := {
		"kind": "advancement_edge",
		"schema_version": 1,
		"id": "cavalier_promotion",
		"display_name": "Cavalier Promotion",
		"source_refs": ["fed20_classes"],
		"source_class_ref": "cavalier",
		"destination_class_refs": ["paladin", "great_knight"],
		"route_refs": ["master_seal"],
		"transition": transition,
		"stat_gains": {"strength": 2},
		"weapon_wexp_grants": {"sword": 50},
		"variants":
		[
			{
				"variant_id": "paladin_only",
				"eligibility":
				{
					"handler_id": "fact_contains_v1",
					"schema_version": 1,
					"parameters": {"fact_id": "oath"},
				},
				"overrides": {"destination_class_refs": ["paladin"]},
			}
		],
	}
	var edge_errors: Array[Dictionary] = registry.validate_document(
		"advancement_edge", 1, valid_edge, sources, occurrences
	)
	if edge_errors.is_empty():
		print("OK  golden branching advancement edge passes the engine-owned schema")
		passed += 1
	else:
		print("FAIL golden edge errors: %s" % [edge_errors])
		failed += 1

	# A fixed edge is the same document with one destination; it must not need a
	# different schema or a different code path.
	var fixed_edge := valid_edge.duplicate(true)
	fixed_edge["destination_class_refs"] = ["paladin"]
	fixed_edge["variants"] = []
	var fixed_edge_errors: Array[Dictionary] = registry.validate_document(
		"advancement_edge", 1, fixed_edge, sources, occurrences
	)
	if fixed_edge_errors.is_empty():
		print("OK  fixed and branching edges share one schema")
		passed += 1
	else:
		print("FAIL fixed edge errors: %s" % [fixed_edge_errors])
		failed += 1

	var empty_destination := valid_edge.duplicate(true)
	empty_destination["destination_class_refs"] = []
	var empty_destination_errors: Array[Dictionary] = registry.validate_document(
		"advancement_edge", 1, empty_destination, sources, occurrences
	)
	if (
		empty_destination_errors.size() == 1
		and empty_destination_errors[0].get("code") == "array_too_short"
	):
		print("OK  an edge must admit at least one destination class")
		passed += 1
	else:
		print("FAIL empty destination response: %s" % [empty_destination_errors])
		failed += 1

	var forbidden_edge_override := valid_edge.duplicate(true)
	forbidden_edge_override["variants"][0]["overrides"] = {"route_refs": ["free_promotion"]}
	var edge_override_errors: Array[Dictionary] = registry.validate_document(
		"advancement_edge", 1, forbidden_edge_override, sources, occurrences
	)
	if (
		edge_override_errors.size() == 1
		and edge_override_errors[0].get("code") == "variant_override_forbidden"
		and (
			edge_override_errors[0].get("path")
			== "$[advancement_edge@1:cavalier_promotion].variants[0].overrides.route_refs"
		)
	):
		print("OK  edge variants cannot override the routes that gate the transition")
		passed += 1
	else:
		print("FAIL edge variant boundary response: %s" % [edge_override_errors])
		failed += 1

	var unknown_edge_eligibility := valid_edge.duplicate(true)
	unknown_edge_eligibility["variants"][0]["eligibility"]["handler_id"] = "pack_predicate"
	var unknown_edge_eligibility_errors: Array[Dictionary] = registry.validate_document(
		"advancement_edge", 1, unknown_edge_eligibility, sources, occurrences
	)
	if (
		unknown_edge_eligibility_errors.size() == 1
		and unknown_edge_eligibility_errors[0].get("code") == "handler_unknown"
		and (
			unknown_edge_eligibility_errors[0].get("path")
			== "$[advancement_edge@1:cavalier_promotion].variants[0].eligibility.handler_id"
		)
	):
		print("OK  edge variant eligibility resolves through the trusted handler registry")
		passed += 1
	else:
		print("FAIL edge variant eligibility response: %s" % [unknown_edge_eligibility_errors])
		failed += 1

	var unknown_handler := valid_edge.duplicate(true)
	unknown_handler["transition"]["handler_id"] = "pack_supplied_promotion"
	var unknown_handler_errors: Array[Dictionary] = registry.validate_document(
		"advancement_edge", 1, unknown_handler, sources, occurrences
	)
	if (
		unknown_handler_errors.size() == 1
		and unknown_handler_errors[0].get("code") == "handler_unknown"
		and (
			unknown_handler_errors[0].get("path")
			== "$[advancement_edge@1:cavalier_promotion].transition.handler_id"
		)
	):
		print("OK  packs cannot select an unregistered transition handler")
		passed += 1
	else:
		print("FAIL unknown handler response: %s" % [unknown_handler_errors])
		failed += 1

	var unsupported_version := valid_edge.duplicate(true)
	unsupported_version["transition"]["schema_version"] = 2
	var unsupported_version_errors: Array[Dictionary] = registry.validate_document(
		"advancement_edge", 1, unsupported_version, sources, occurrences
	)
	if (
		unsupported_version_errors.size() == 1
		and unsupported_version_errors[0].get("code") == "handler_version_unsupported"
	):
		print("OK  a registered handler rejects a schema version it does not admit")
		passed += 1
	else:
		print("FAIL unsupported handler version response: %s" % [unsupported_version_errors])
		failed += 1

	var valid_route := {
		"kind": "advancement_route",
		"schema_version": 1,
		"id": "master_seal",
		"display_name": "Master Seal",
		"source_refs": ["fed20_classes"],
		"trigger": transition,
		"requirements": [transition],
		"cost": transition,
		"selection": transition,
		"transition": transition,
		"priority": 10,
	}
	var route_errors: Array[Dictionary] = registry.validate_document(
		"advancement_route", 1, valid_route, sources, occurrences
	)
	if route_errors.is_empty():
		print("OK  golden advancement route passes the engine-owned schema")
		passed += 1
	else:
		print("FAIL golden route errors: %s" % [route_errors])
		failed += 1

	# Requirements are ordered authored data; an empty list is legal (zero or more).
	var no_requirements := valid_route.duplicate(true)
	no_requirements["requirements"] = []
	var no_requirement_errors: Array[Dictionary] = registry.validate_document(
		"advancement_route", 1, no_requirements, sources, occurrences
	)
	if no_requirement_errors.is_empty():
		print("OK  a route may carry zero requirements")
		passed += 1
	else:
		print("FAIL zero-requirement route errors: %s" % [no_requirement_errors])
		failed += 1

	var untrusted_requirement := valid_route.duplicate(true)
	untrusted_requirement["requirements"] = [
		{"handler_id": "pack_supplied_check", "schema_version": 1, "parameters": {}}
	]
	var untrusted_requirement_errors: Array[Dictionary] = registry.validate_document(
		"advancement_route", 1, untrusted_requirement, sources, occurrences
	)
	if (
		untrusted_requirement_errors.size() == 1
		and untrusted_requirement_errors[0].get("code") == "handler_unknown"
		and (
			untrusted_requirement_errors[0].get("path")
			== "$[advancement_route@1:master_seal].requirements[0].handler_id"
		)
	):
		print("OK  every route descriptor resolves before preview, not at runtime")
		passed += 1
	else:
		print("FAIL untrusted requirement response: %s" % [untrusted_requirement_errors])
		failed += 1

	# --- Weapons ---------------------------------------------------------------
	# Weapons reuse the identity/provenance header proved above; these cases cover
	# only what is weapon-specific: registered range selection, the author-facing
	# vocabularies, and the coherence rules the combat code depends on.
	var weapon_occurrences := {
		"iron_sword_might":
		{
			"document_ref": "weapon:iron_sword",
			"source_ref": "fed20_classes",
			"field_path": "/mt",
		}
	}
	var valid_weapon := {
		"kind": "weapon",
		"schema_version": 1,
		"id": "iron_sword",
		"display_name": "Iron Sword",
		"source_refs": ["fed20_classes"],
		"occurrence_audit_refs": ["iron_sword_might"],
		"combat_family": "sword",
		"wexp_track": "sword",
		"required_rank": "E",
		"mt": 5,
		"hit": 90,
		"crit": 0,
		"wt": 5,
		"uses": 46,
		"cost": 460,
		"wexp": 1,
		"effect_tags": [],
		"strikes_per_attack": 1,
		"range_min_formula_id": "literal",
		"range_min_parameters": {"value": 1},
		"range_max_formula_id": "literal",
		"range_max_parameters": {"value": 1},
		"field_completeness": {"mt": "verified"},
	}
	var weapon_errors: Array[Dictionary] = registry.validate_document(
		"weapon", 1, valid_weapon, sources, weapon_occurrences
	)
	if weapon_errors.is_empty():
		print("OK  golden weapon document passes the engine-owned schema")
		passed += 1
	else:
		print("FAIL golden weapon errors: %s" % [weapon_errors])
		failed += 1

	# A stat-driven bound (Physic's MAG/2) is authored the same way a literal is.
	var dynamic_weapon := valid_weapon.duplicate(true)
	dynamic_weapon["range_max_formula_id"] = "stat_divisor"
	dynamic_weapon["range_max_parameters"] = {"stat": "magic", "divisor": 2}
	var dynamic_errors: Array[Dictionary] = registry.validate_document(
		"weapon", 1, dynamic_weapon, sources, weapon_occurrences
	)
	if dynamic_errors.is_empty():
		print("OK  registered stat-driven range formulas are admitted")
		passed += 1
	else:
		print("FAIL stat-driven range errors: %s" % [dynamic_errors])
		failed += 1

	# The old "1" / "MAG/2" grammar stays an import concern; a registered document
	# that still carries it must fail rather than silently keep two range authorities.
	var legacy_range := valid_weapon.duplicate(true)
	legacy_range["range_min_formula"] = "1"
	var legacy_errors := _codes_by_path(
		registry.validate_document("weapon", 1, legacy_range, sources, weapon_occurrences)
	)
	if legacy_errors.get("unknown_field", "") == "$[weapon@1:iron_sword].range_min_formula":
		print("OK  legacy range strings are not admitted by the registered envelope")
		passed += 1
	else:
		print("FAIL legacy range response: %s" % [legacy_errors])
		failed += 1

	var unknown_formula := valid_weapon.duplicate(true)
	unknown_formula["range_max_formula_id"] = "mag_over_two"
	var unknown_formula_errors := _codes_by_path(
		registry.validate_document("weapon", 1, unknown_formula, sources, weapon_occurrences)
	)
	var bad_parameters := valid_weapon.duplicate(true)
	bad_parameters["range_max_formula_id"] = "stat_divisor"
	bad_parameters["range_max_parameters"] = {"stat": "charisma", "divisor": 2}
	var bad_parameter_errors := _codes_by_path(
		registry.validate_document("weapon", 1, bad_parameters, sources, weapon_occurrences)
	)
	if (
		(
			unknown_formula_errors.get("range_formula_unknown", "")
			== "$[weapon@1:iron_sword].range_max_formula_id"
		)
		and (
			bad_parameter_errors.get("range_formula_parameters_invalid", "")
			== "$[weapon@1:iron_sword].range_max_parameters"
		)
	):
		print("OK  unknown range formulas and bad parameters fail before evaluation")
		passed += 1
	else:
		print(
			"FAIL range formula response: %s / %s" % [unknown_formula_errors, bad_parameter_errors]
		)
		failed += 1

	var bad_vocabulary := valid_weapon.duplicate(true)
	bad_vocabulary["combat_family"] = "sord"
	bad_vocabulary["wexp_track"] = "sord"
	bad_vocabulary["required_rank"] = "Z"
	bad_vocabulary["effect_tags"] = ["effective_armored"]
	var vocabulary_paths := {}
	for error in registry.validate_document(
		"weapon", 1, bad_vocabulary, sources, weapon_occurrences
	):
		if error.get("code") == "vocabulary_value_unknown":
			vocabulary_paths[error.get("path")] = true
	if (
		vocabulary_paths.has("$[weapon@1:iron_sword].combat_family")
		and vocabulary_paths.has("$[weapon@1:iron_sword].wexp_track")
		and vocabulary_paths.has("$[weapon@1:iron_sword].required_rank")
		and vocabulary_paths.has("$[weapon@1:iron_sword].effect_tags[0]")
	):
		print("OK  family, track, rank, and effect tags resolve through open vocabularies")
		passed += 1
	else:
		print("FAIL vocabulary response: %s" % [vocabulary_paths])
		failed += 1

	# fire/thunder/wind all train elemental_magic; naming the family as the track is
	# the exact drift that would train progress no class can spend.
	var mismatched_track := valid_weapon.duplicate(true)
	mismatched_track["combat_family"] = "fire"
	mismatched_track["wexp_track"] = "fire"
	mismatched_track["uses_mag"] = true
	var track_errors := _codes_by_path(
		registry.validate_document("weapon", 1, mismatched_track, sources, weapon_occurrences)
	)
	var mistagged_heal := valid_weapon.duplicate(true)
	mistagged_heal["effect_tags"] = ["heal_10_plus_mag"]
	var heal_errors := _codes_by_path(
		registry.validate_document("weapon", 1, mistagged_heal, sources, weapon_occurrences)
	)
	if (
		track_errors.get("wexp_track_family_mismatch", "") == "$[weapon@1:iron_sword].wexp_track"
		and (
			heal_errors.get("effect_tag_family_mismatch", "")
			== "$[weapon@1:iron_sword].effect_tags"
		)
	):
		print("OK  track and effect tags must cohere with the declared combat family")
		passed += 1
	else:
		print("FAIL coherence response: %s / %s" % [track_errors, heal_errors])
		failed += 1

	var inverted_range := valid_weapon.duplicate(true)
	inverted_range["range_min_parameters"] = {"value": 3}
	inverted_range["range_max_parameters"] = {"value": 2}
	var inverted_errors := _codes_by_path(
		registry.validate_document("weapon", 1, inverted_range, sources, weapon_occurrences)
	)
	if (
		inverted_errors.get("range_min_exceeds_max", "")
		== "$[weapon@1:iron_sword].range_min_formula_id"
	):
		print("OK  literal range bounds must be coherent")
		passed += 1
	else:
		print("FAIL inverted range response: %s" % [inverted_errors])
		failed += 1

	# A natural weapon is granted by a shifted form, so it is never bought and never
	# spends durability; 0 uses is a weapon that could never be swung at all.
	var priced_natural := valid_weapon.duplicate(true)
	priced_natural["is_natural_weapon"] = true
	var natural_errors := _codes_by_path(
		registry.validate_document("weapon", 1, priced_natural, sources, weapon_occurrences)
	)
	var zero_uses := valid_weapon.duplicate(true)
	zero_uses["uses"] = 0
	var zero_uses_errors := _codes_by_path(
		registry.validate_document("weapon", 1, zero_uses, sources, weapon_occurrences)
	)
	if (
		natural_errors.get("natural_weapon_cost_forbidden", "") == "$[weapon@1:iron_sword].cost"
		and natural_errors.get("natural_weapon_uses_forbidden", "") == "$[weapon@1:iron_sword].uses"
		and zero_uses_errors.get("weapon_uses_invalid", "") == "$[weapon@1:iron_sword].uses"
	):
		print("OK  natural-weapon cost/use rules and unusable durability fail closed")
		passed += 1
	else:
		print("FAIL durability response: %s / %s" % [natural_errors, zero_uses_errors])
		failed += 1

	var weapon_variant_override := valid_weapon.duplicate(true)
	weapon_variant_override["variants"] = [
		{
			"variant_id": "reforged",
			"eligibility":
			{
				"handler_id": "fact_contains_v1",
				"schema_version": 1,
				"parameters": {"fact_id": "forge", "value": "reforged"},
			},
			"overrides": {"mt": 7, "combat_family": "axe"},
		}
	]
	var weapon_variant_errors := _codes_by_path(
		registry.validate_document(
			"weapon", 1, weapon_variant_override, sources, weapon_occurrences
		)
	)
	if (
		weapon_variant_errors.get("variant_override_forbidden", "")
		== "$[weapon@1:iron_sword].variants[0].overrides.combat_family"
	):
		print("OK  weapon variants cannot re-declare who may equip the weapon")
		passed += 1
	else:
		print("FAIL weapon variant boundary response: %s" % [weapon_variant_errors])
		failed += 1

	var unsourced_weapon := valid_weapon.duplicate(true)
	unsourced_weapon["source_refs"] = ["missing_weapon_source"]
	var unsourced_errors := _codes_by_path(
		registry.validate_document("weapon", 1, unsourced_weapon, sources, weapon_occurrences)
	)
	if (
		(
			unsourced_errors.get("provenance_source_unresolved", "")
			== "$[weapon@1:iron_sword].source_refs[0]"
		)
		and unsourced_errors.has("provenance_occurrence_source_unresolved")
	):
		print("OK  weapon provenance resolves through the shared audit contract")
		passed += 1
	else:
		print("FAIL weapon provenance response: %s" % [unsourced_errors])
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


# Collapses diagnostics to code -> path so a case can assert the codes it cares
# about without depending on the order or count of unrelated diagnostics.
static func _codes_by_path(errors: Array[Dictionary]) -> Dictionary:
	var by_code := {}
	for error in errors:
		by_code[String(error.get("code", ""))] = String(error.get("path", ""))
	return by_code
