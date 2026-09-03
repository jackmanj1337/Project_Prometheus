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

	# Campaign traversal is already a runtime contract. The pack-facing schema must
	# admit both runtime modes while rejecting typos before activation.
	var valid_campaign := {
		"kind": "campaign",
		"schema_version": 1,
		"id": "free_roam_trial",
		"display_name": "Free Roam Trial",
		"source_refs": ["fed20_classes"],
		"campaign_id": "free_roam_trial",
		"label": "Free Roam Trial",
		"traversal_mode": "free_roam",
		"nodes": [{"node_id": "start", "map_id": "map_001", "next": []}],
	}
	var campaign_errors: Array[Dictionary] = registry.validate_document(
		"campaign", 1, valid_campaign, sources
	)
	var linear_campaign := valid_campaign.duplicate(true)
	linear_campaign["traversal_mode"] = "linear"
	var linear_errors: Array[Dictionary] = registry.validate_document(
		"campaign", 1, linear_campaign, sources
	)
	if campaign_errors.is_empty() and linear_errors.is_empty():
		print("OK  campaign schema admits both runtime traversal modes")
		passed += 1
	else:
		print(
			(
				"FAIL campaign traversal modes: free_roam=%s linear=%s"
				% [campaign_errors, linear_errors]
			)
		)
		failed += 1

	var invalid_campaign := valid_campaign.duplicate(true)
	invalid_campaign["traversal_mode"] = "open_world"
	var invalid_campaign_errors: Array[Dictionary] = registry.validate_document(
		"campaign", 1, invalid_campaign, sources
	)
	if (
		invalid_campaign_errors.size() == 1
		and invalid_campaign_errors[0].get("code") == "value_not_admitted"
		and (
			invalid_campaign_errors[0].get("path") == "$[campaign@1:free_roam_trial].traversal_mode"
		)
	):
		print("OK  campaign schema rejects unknown traversal modes")
		passed += 1
	else:
		print("FAIL invalid campaign traversal response: %s" % [invalid_campaign_errors])
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

	# --- Skills ----------------------------------------------------------------
	var valid_skill := {
		"kind": "skill",
		"schema_version": 1,
		"id": "fixture_vantage",
		"display_name": "Fixture Vantage",
		"source_refs": ["fed20_classes"],
		"trigger": "on_combat_start",
		"effect_id": "vantage",
		"effect_params": {},
		"release_available": true,
		"field_completeness": {"effect_id": "verified"},
	}
	var skill_errors: Array[Dictionary] = registry.validate_document(
		"skill", 1, valid_skill, sources
	)
	var bad_effect := valid_skill.duplicate(true)
	bad_effect["effect_id"] = "pack_code"
	var bad_effect_codes := _codes_by_path(
		registry.validate_document("skill", 1, bad_effect, sources)
	)
	var bad_trigger := valid_skill.duplicate(true)
	bad_trigger["trigger"] = "sometimes"
	var bad_trigger_codes := _codes_by_path(
		registry.validate_document("skill", 1, bad_trigger, sources)
	)
	if (
		skill_errors.is_empty()
		and (
			bad_effect_codes.get("vocabulary_value_unknown", "")
			== "$[skill@1:fixture_vantage].effect_id"
		)
		and (
			bad_trigger_codes.get("vocabulary_value_unknown", "")
			== "$[skill@1:fixture_vantage].trigger"
		)
	):
		print("OK  skill triggers are closed and effect ids resolve through the engine registry")
		passed += 1
	else:
		print(
			"FAIL skill schema: %s / %s / %s" % [skill_errors, bad_effect_codes, bad_trigger_codes]
		)
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
	var physical_tome := valid_weapon.duplicate(true)
	physical_tome["combat_family"] = "fire"
	physical_tome["wexp_track"] = "elemental_magic"
	var physical_tome_errors := _codes_by_path(
		registry.validate_document("weapon", 1, physical_tome, sources, weapon_occurrences)
	)
	if (
		track_errors.get("wexp_track_family_mismatch", "") == "$[weapon@1:iron_sword].wexp_track"
		and (
			physical_tome_errors.get("magic_weapon_requires_uses_mag", "")
			== "$[weapon@1:iron_sword].uses_mag"
		)
		and (
			heal_errors.get("effect_tag_family_mismatch", "")
			== "$[weapon@1:iron_sword].effect_tags"
		)
	):
		print("OK  track, magic damage, and effect tags cohere with the combat family")
		passed += 1
	else:
		print(
			(
				"FAIL coherence response: %s / %s / %s"
				% [track_errors, physical_tome_errors, heal_errors]
			)
		)
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

	# --- Rosters ---------------------------------------------------------------
	# One roster document holds many units, so these cases concentrate on what only
	# a nested array can get wrong: paths that must stay unit-qualified, the stat and
	# track vocabularies that live in a map's KEYS, and the durable selections that a
	# save round-trip cannot repair once they stop resolving.
	var valid_roster := {
		"kind": "roster",
		"schema_version": 1,
		"id": "starting_party",
		"display_name": "Starting Party",
		"source_refs": ["fed20_classes"],
		"units":
		[
			{
				"unit_id": "hero",
				"unit_name": "Hero",
				"class_id": "cavalier",
				"class_variant_id": "swift",
				"level": 1,
				"exp": 0,
				"max_hp": 20,
				"hp": 18,
				"strength": 5,
				"growth_rates": {"hp": 60, "strength": 40},
				"weapon_wexp": {"sword": 31},
				"skills": ["canto"],
				"reclass_options": ["knight"],
				"ai_profile": "basic",
				"inventory": [{"weapon_id": "iron_sword", "uses": 46}],
			}
		],
	}
	var roster_errors: Array[Dictionary] = registry.validate_document(
		"roster", 1, valid_roster, sources
	)
	if roster_errors.is_empty():
		print("OK  golden roster document passes the engine-owned schema")
		passed += 1
	else:
		print("FAIL golden roster errors: %s" % [roster_errors])
		failed += 1

	# A nested array is exactly where a path can degrade to "somewhere in this file".
	var unknown_unit_fields := valid_roster.duplicate(true)
	unknown_unit_fields["units"][0]["moral"] = 5
	unknown_unit_fields["units"][0]["inventory"][0]["forge_level"] = 2
	var unknown_paths := {}
	for error in registry.validate_document("roster", 1, unknown_unit_fields, sources):
		if error.get("code") == "unknown_field":
			unknown_paths[error.get("path")] = true
	if (
		unknown_paths.has("$[roster@1:starting_party].units[0].moral")
		and unknown_paths.has("$[roster@1:starting_party].units[0].inventory[0].forge_level")
	):
		print("OK  unknown fields inside units and inventory report exact paths")
		passed += 1
	else:
		print("FAIL nested unknown-field response: %s" % [unknown_paths])
		failed += 1

	# `strenght: 40` is admitted by any value-only map check and then silently never
	# rolls, which is the whole reason these maps carry a key vocabulary.
	var bad_map_keys := valid_roster.duplicate(true)
	bad_map_keys["units"][0]["growth_rates"] = {"strenght": 40}
	bad_map_keys["units"][0]["weapon_wexp"] = {"greatsword": 31}
	var key_paths := {}
	for error in registry.validate_document("roster", 1, bad_map_keys, sources):
		if error.get("code") == "vocabulary_key_unknown":
			key_paths[error.get("path")] = true
	var bad_profile := valid_roster.duplicate(true)
	bad_profile["units"][0]["ai_profile"] = "berserker"
	var profile_errors := _codes_by_path(
		registry.validate_document("roster", 1, bad_profile, sources)
	)
	if (
		key_paths.has("$[roster@1:starting_party].units[0].growth_rates.strenght")
		and key_paths.has("$[roster@1:starting_party].units[0].weapon_wexp.greatsword")
		and (
			profile_errors.get("vocabulary_value_unknown", "")
			== "$[roster@1:starting_party].units[0].ai_profile"
		)
	):
		print("OK  stat keys, WEXP track keys, and AI profiles resolve through registries")
		passed += 1
	else:
		print("FAIL roster vocabulary response: %s / %s" % [key_paths, profile_errors])
		failed += 1

	var no_hp := valid_roster.duplicate(true)
	no_hp["units"][0]["hp"] = 0
	var no_hp_errors := _codes_by_path(registry.validate_document("roster", 1, no_hp, sources))
	var over_hp := valid_roster.duplicate(true)
	over_hp["units"][0]["hp"] = 21
	var over_hp_errors := _codes_by_path(registry.validate_document("roster", 1, over_hp, sources))
	if (
		no_hp_errors.get("value_too_small", "") == "$[roster@1:starting_party].units[0].hp"
		and (
			over_hp_errors.get("unit_hp_exceeds_max", "")
			== "$[roster@1:starting_party].units[0].hp"
		)
	):
		print("OK  a unit cannot start with no HP or above its own maximum")
		passed += 1
	else:
		print("FAIL roster hp response: %s / %s" % [no_hp_errors, over_hp_errors])
		failed += 1

	# The durable selections the class vertical round-trips: an edge variant with no
	# edge selects nothing, and a zero-use slot is a weapon that can never be swung.
	var orphan_variant := valid_roster.duplicate(true)
	orphan_variant["units"][0]["advancement_edge_variant_id"] = "mounted"
	var orphan_errors := _codes_by_path(
		registry.validate_document("roster", 1, orphan_variant, sources)
	)
	var dead_slot := valid_roster.duplicate(true)
	dead_slot["units"][0]["inventory"][0]["uses"] = 0
	var dead_slot_errors := _codes_by_path(
		registry.validate_document("roster", 1, dead_slot, sources)
	)
	if (
		(
			orphan_errors.get("selected_edge_variant_without_edge", "")
			== "$[roster@1:starting_party].units[0].advancement_edge_variant_id"
		)
		and (
			dead_slot_errors.get("inventory_uses_invalid", "")
			== "$[roster@1:starting_party].units[0].inventory[0].uses"
		)
	):
		print("OK  orphaned edge variants and unusable inventory slots fail closed")
		passed += 1
	else:
		print("FAIL durable selection response: %s / %s" % [orphan_errors, dead_slot_errors])
		failed += 1

	var duplicate_units := valid_roster.duplicate(true)
	duplicate_units["units"].append(duplicate_units["units"][0].duplicate(true))
	var duplicate_errors := _codes_by_path(
		registry.validate_document("roster", 1, duplicate_units, sources)
	)
	if duplicate_errors.get("duplicate_value", "") == "$[roster@1:starting_party].units":
		print("OK  unit ids are unique within a roster")
		passed += 1
	else:
		print("FAIL duplicate unit response: %s" % [duplicate_errors])
		failed += 1

	# ── Items ─────────────────────────────────────────────────────────────────
	var valid_item := {
		"kind": "item",
		"schema_version": 1,
		"id": "vulnerary",
		"display_name": "Vulnerary",
		"source_refs": ["fed20_classes"],
		"item_type": "healing",
		"icon": "vulnerary_icon",
		"uses": 3,
		"cost": 300,
		"effect_id": "heal_flat",
		"effect_params": {"amount": 10},
		"field_completeness": {"cost": "verified"},
	}
	var item_document_errors: Array[Dictionary] = registry.validate_document(
		"item", 1, valid_item, sources
	)
	if item_document_errors.is_empty():
		print("OK  golden item document passes the engine-owned schema")
		passed += 1
	else:
		print("FAIL golden item errors: %s" % [item_document_errors])
		failed += 1

	# `ItemHandler` commits through `ItemEffectRegistry`; an unregistered effect is a
	# push_warning at use time today, which is far too late to be useful.
	var unknown_effect := valid_item.duplicate(true)
	unknown_effect["effect_id"] = "heal_everything"
	var unknown_effect_codes := _codes_by_path(
		registry.validate_document("item", 1, unknown_effect, sources)
	)

	var orphan_params := valid_item.duplicate(true)
	orphan_params.erase("effect_id")
	var orphan_param_codes := _codes_by_path(
		registry.validate_document("item", 1, orphan_params, sources)
	)

	var dead_item := valid_item.duplicate(true)
	dead_item["uses"] = 0
	var dead_item_codes := _codes_by_path(registry.validate_document("item", 1, dead_item, sources))

	if (
		(
			unknown_effect_codes.get("vocabulary_value_unknown", "")
			== "$[item@1:vulnerary].effect_id"
		)
		and (
			orphan_param_codes.get("item_effect_params_without_effect", "")
			== "$[item@1:vulnerary].effect_params"
		)
		and dead_item_codes.get("item_uses_invalid", "") == "$[item@1:vulnerary].uses"
	):
		print("OK  unregistered effects, orphaned parameters, and dead items fail closed")
		passed += 1
	else:
		print(
			(
				"FAIL item contract: effect=%s params=%s uses=%s"
				% [unknown_effect_codes, orphan_param_codes, dead_item_codes]
			)
		)
		failed += 1

	# Inventory slots now admit items as well as weapons, but a slot is one or the
	# other — `InventoryEntry` keys its whole behaviour off a single entry_type.
	var item_slot := valid_roster.duplicate(true)
	item_slot["units"][0]["inventory"] = [{"item_id": "vulnerary", "uses": 3}]
	var item_slot_errors: Array[Dictionary] = registry.validate_document(
		"roster", 1, item_slot, sources
	)

	var both_ids := valid_roster.duplicate(true)
	both_ids["units"][0]["inventory"][0]["item_id"] = "vulnerary"
	var both_codes := _codes_by_path(registry.validate_document("roster", 1, both_ids, sources))

	var neither_id := valid_roster.duplicate(true)
	neither_id["units"][0]["inventory"] = [{"uses": 3}]
	var neither_codes := _codes_by_path(
		registry.validate_document("roster", 1, neither_id, sources)
	)

	var variant_on_item := valid_roster.duplicate(true)
	variant_on_item["units"][0]["inventory"] = [
		{"item_id": "vulnerary", "weapon_variant_id": "reforged"}
	]
	var variant_on_item_codes := _codes_by_path(
		registry.validate_document("roster", 1, variant_on_item, sources)
	)

	var slot_root := "$[roster@1:starting_party].units[0].inventory[0]"
	if (
		item_slot_errors.is_empty()
		and both_codes.get("inventory_slot_ambiguous", "") == slot_root
		and neither_codes.get("inventory_slot_empty", "") == slot_root
		and (
			variant_on_item_codes.get("inventory_variant_on_item", "")
			== "%s.weapon_variant_id" % slot_root
		)
	):
		print("OK  an inventory slot holds exactly one of a weapon or an item")
		passed += 1
	else:
		print(
			(
				"FAIL inventory slot contract: item=%s both=%s neither=%s variant=%s"
				% [item_slot_errors, both_codes, neither_codes, variant_on_item_codes]
			)
		)
		failed += 1

	# ── Media identity ────────────────────────────────────────────────────────
	# The allow-list is the project's existing one; this asserts the type table cannot
	# drift from it, because a new extension with no canonical type would otherwise be
	# admitted by preflight and then be untypeable in a registry record.
	var allow_list := CampaignArchivePreflight.APPROVED_MEDIA_EXTENSIONS
	var typed_extensions: Array = EntitySchemaRegistry.MEDIA_TYPES_BY_EXTENSION.keys()
	typed_extensions.sort()
	var sorted_allow_list: Array = allow_list.duplicate()
	sorted_allow_list.sort()
	if typed_extensions == sorted_allow_list:
		print("OK  every admitted media extension has exactly one canonical type")
		passed += 1
	else:
		print("FAIL media type table drift: typed=%s allowed=%s" % [typed_extensions, allow_list])
		failed += 1

	var valid_assets := {
		"kind": "asset_registry",
		"schema_version": 1,
		"id": "fixture_assets",
		"assets":
		{
			"hero_portrait":
			{
				"path": "assets/hero.png",
				"decoded_type": "image/png",
				"byte_size": 70,
				"sha256": "0000000000000000000000000000000000000000000000000000000000000000",
				"original_filename": "hero.png",
			}
		},
	}
	# An asset registry is an infrastructure document: it carries no `source_refs`,
	# and that must not be reported as missing provenance.
	var asset_errors: Array[Dictionary] = registry.validate_document(
		"asset_registry", 1, valid_assets, sources
	)
	if asset_errors.is_empty():
		print("OK  a golden asset registry passes without document-level source_refs")
		passed += 1
	else:
		print("FAIL golden asset registry errors: %s" % [asset_errors])
		failed += 1

	var valid_palette := {
		"kind": "palette_swap",
		"schema_version": 1,
		"id": "azure_done",
		"display_name": "Azure Done",
		"source_refs": ["fed20_classes"],
		"faction_id": "author_defined_faction",
		"state": "done",
		"tint_fallback": [60, 90, 150, 255],
		"mappings": [{"from": [255, 0, 0, 255], "to": [0, 0, 255, 255]}],
	}
	var palette_errors: Array[Dictionary] = registry.validate_document(
		"palette_swap", 1, valid_palette, sources
	)
	var too_many := valid_palette.duplicate(true)
	too_many["mappings"] = []
	for index in 33:
		too_many["mappings"].append({"from": [index, 0, 0, 255], "to": [0, index, 0, 255]})
	var too_many_codes := _codes_by_path(
		registry.validate_document("palette_swap", 1, too_many, sources)
	)
	var transparent := valid_palette.duplicate(true)
	transparent["mappings"][0]["to"] = [0, 0, 0, 0]
	var transparent_codes := _codes_by_path(
		registry.validate_document("palette_swap", 1, transparent, sources)
	)
	var bad_state := valid_palette.duplicate(true)
	bad_state["state"] = "sleeping"
	var bad_state_codes := _codes_by_path(
		registry.validate_document("palette_swap", 1, bad_state, sources)
	)
	if (
		palette_errors.is_empty()
		and too_many_codes.has("array_too_long")
		and transparent_codes.has("palette_transparent_output")
		and bad_state_codes.has("value_not_admitted")
	):
		print("OK  palette swaps bound capacity/state/output while faction ids stay open")
		passed += 1
	else:
		print(
			(
				"FAIL palette schema: valid=%s max=%s alpha=%s state=%s"
				% [palette_errors, too_many_codes, transparent_codes, bad_state_codes]
			)
		)
		failed += 1

	var sidecar_assets := valid_assets.duplicate(true)
	sidecar_assets["assets"]["hero_portrait"]["sidecar_path"] = "assets/hero.frames.json"
	var sidecar_errors: Array[Dictionary] = registry.validate_document(
		"asset_registry", 1, sidecar_assets, sources
	)
	var unsafe_sidecar := sidecar_assets.duplicate(true)
	unsafe_sidecar["assets"]["hero_portrait"]["sidecar_path"] = "../hero.json"
	var unsafe_sidecar_codes := _codes_by_path(
		registry.validate_document("asset_registry", 1, unsafe_sidecar, sources)
	)
	var non_json_sidecar := sidecar_assets.duplicate(true)
	non_json_sidecar["assets"]["hero_portrait"]["sidecar_path"] = "assets/hero.tres"
	var non_json_sidecar_codes := _codes_by_path(
		registry.validate_document("asset_registry", 1, non_json_sidecar, sources)
	)
	var sidecar_field := "$[asset_registry@1:fixture_assets].assets.hero_portrait.sidecar_path"
	if (
		sidecar_errors.is_empty()
		and unsafe_sidecar_codes.get("asset_sidecar_path_unsafe", "") == sidecar_field
		and non_json_sidecar_codes.get("asset_sidecar_not_json", "") == sidecar_field
	):
		print("OK  sprite sidecars require an explicit safe JSON path")
		passed += 1
	else:
		print(
			(
				"FAIL sidecar contract: valid=%s unsafe=%s type=%s"
				% [sidecar_errors, unsafe_sidecar_codes, non_json_sidecar_codes]
			)
		)
		failed += 1

	# SVG is the case the plan calls out by name: it is a real image type, but it is
	# not production-admitted, so it must fail on the extension rather than the type.
	var svg_asset := valid_assets.duplicate(true)
	svg_asset["assets"]["hero_portrait"]["path"] = "assets/hero.svg"
	svg_asset["assets"]["hero_portrait"]["decoded_type"] = "image/svg+xml"
	var svg_codes := _codes_by_path(
		registry.validate_document("asset_registry", 1, svg_asset, sources)
	)

	var escaping_asset := valid_assets.duplicate(true)
	escaping_asset["assets"]["hero_portrait"]["path"] = "../outside/hero.png"
	var escaping_codes := _codes_by_path(
		registry.validate_document("asset_registry", 1, escaping_asset, sources)
	)

	var stray_asset := valid_assets.duplicate(true)
	stray_asset["assets"]["hero_portrait"]["path"] = "data/hero.png"
	var stray_codes := _codes_by_path(
		registry.validate_document("asset_registry", 1, stray_asset, sources)
	)

	# A record whose declared type disagrees with its own extension is ambiguous about
	# which authority the engine should believe, so neither is trusted.
	var mistyped_asset := valid_assets.duplicate(true)
	mistyped_asset["assets"]["hero_portrait"]["decoded_type"] = "audio/ogg"
	var mistyped_codes := _codes_by_path(
		registry.validate_document("asset_registry", 1, mistyped_asset, sources)
	)

	var record_root := "$[asset_registry@1:fixture_assets].assets.hero_portrait"
	if (
		svg_codes.has("vocabulary_value_unknown")
		and svg_codes.get("asset_extension_not_admitted", "") == "%s.path" % record_root
		and escaping_codes.get("asset_path_unsafe", "") == "%s.path" % record_root
		and stray_codes.get("asset_path_outside_assets", "") == "%s.path" % record_root
		and (
			mistyped_codes.get("asset_type_extension_mismatch", "")
			== "%s.decoded_type" % record_root
		)
	):
		print("OK  unadmitted, escaping, misplaced, and mistyped media all fail closed")
		passed += 1
	else:
		print(
			(
				"FAIL media admission: svg=%s escaping=%s stray=%s mistyped=%s"
				% [svg_codes, escaping_codes, stray_codes, mistyped_codes]
			)
		)
		failed += 1

	var malformed_digest := valid_assets.duplicate(true)
	malformed_digest["assets"]["hero_portrait"]["sha256"] = ("NOTHEX00000000000000000000000000000000000000000000000000000000AB")
	var digest_codes := _codes_by_path(
		registry.validate_document("asset_registry", 1, malformed_digest, sources)
	)
	if digest_codes.get("asset_sha256_malformed", "") == "%s.sha256" % record_root:
		print("OK  a hand-edited digest is rejected before any file is read")
		passed += 1
	else:
		print("FAIL digest response: %s" % [digest_codes])
		failed += 1

	# Byte-level integrity needs a real file, so this case writes one. The declared
	# size and digest are correct; only the content type is a lie, which is exactly
	# what trusting the authored field would have missed.
	var media_root := "user://test_entity_schema_registry_media"
	DirAccess.make_dir_recursive_absolute(media_root.path_join("assets"))
	var png_bytes := PackedByteArray([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x01])
	_write_bytes(media_root.path_join("assets/hero.png"), png_bytes)
	_write_bytes(media_root.path_join("assets/liar.png"), PackedByteArray([0x4F, 0x67, 0x67, 0x53]))

	var truthful := valid_assets.duplicate(true)
	truthful["assets"]["hero_portrait"]["byte_size"] = png_bytes.size()
	truthful["assets"]["hero_portrait"]["sha256"] = FileAccess.get_sha256(
		media_root.path_join("assets/hero.png")
	)
	truthful["assets"]["hero_portrait"]["sidecar_path"] = "assets/hero.frames.json"
	_write_bytes(
		media_root.path_join("assets/hero.frames.json"),
		JSON.stringify({"schema_version": 1}).to_utf8_buffer()
	)
	var truthful_integrity := EntitySchemaRegistry.collect_asset_integrity_errors(
		truthful, media_root
	)

	var lying := truthful.duplicate(true)
	lying["assets"]["hero_portrait"]["path"] = "assets/liar.png"
	var lying_codes := _codes_by_path(
		EntitySchemaRegistry.collect_asset_integrity_errors(lying, media_root)
	)

	var absent := truthful.duplicate(true)
	absent["assets"]["hero_portrait"]["path"] = "assets/absent.png"
	var absent_codes := _codes_by_path(
		EntitySchemaRegistry.collect_asset_integrity_errors(absent, media_root)
	)
	var absent_sidecar := truthful.duplicate(true)
	absent_sidecar["assets"]["hero_portrait"]["sidecar_path"] = "assets/absent.json"
	var absent_sidecar_codes := _codes_by_path(
		EntitySchemaRegistry.collect_asset_integrity_errors(absent_sidecar, media_root)
	)

	if (
		truthful_integrity.is_empty()
		and lying_codes.has("asset_byte_size_mismatch")
		and lying_codes.has("asset_sha256_mismatch")
		and lying_codes.get("asset_content_type_mismatch", "") == "%s.decoded_type" % record_root
		and absent_codes.get("asset_file_missing", "") == "%s.path" % record_root
		and (
			absent_sidecar_codes.get("asset_sidecar_missing", "") == "%s.sidecar_path" % record_root
		)
	):
		print("OK  recorded bytes are verified against the file, not taken on trust")
		passed += 1
	else:
		print(
			(
				"FAIL integrity: truthful=%s lying=%s absent=%s"
				% [truthful_integrity, lying_codes, absent_codes]
			)
		)
		failed += 1

	# ── Maps / encounters ─────────────────────────────────────────────────────
	var valid_map := {
		"kind": "map_data",
		"schema_version": 1,
		"id": "chapter_01",
		"display_name": "Chapter 1",
		"source_refs": ["fed20_classes"],
		"grid": ["...", "..."],
		"player_start_tiles": [[0, 0]],
		"camera_start_tile": [1, 1],
		"activation_mode": "WHOLE_PHASE",
		"factions": [{"id": "blue", "alliance_group": "allies", "color": [0.2, 0.4, 0.9]}],
		"turn_order": ["blue"],
		"enemy_placements":
		[
			{
				"unit": {"unit_id": "brigand", "class_id": "fighter"},
				"tile": [2, 1],
				"faction": "red",
				"ai_profile": "basic",
			}
		],
		"victory_conditions": {"allies": [{"type": "rout", "faction_id": "red"}]},
		"reward_gold": 500,
		"reward_items": ["vulnerary"],
	}
	var map_errors: Array[Dictionary] = registry.validate_document(
		"map_data", 1, valid_map, sources
	)
	if map_errors.is_empty():
		print("OK  golden map document passes the engine-owned schema")
		passed += 1
	else:
		print("FAIL golden map errors: %s" % [map_errors])
		failed += 1

	# A pack carries indexed JSON plus approved Tier-1 media, so it can never ship the
	# PackedScene `tilemap_scene_path` names. It must fail as an unadmitted field.
	var scene_map := valid_map.duplicate(true)
	scene_map["tilemap_scene_path"] = "res://maps/chapter_01.tscn"
	var scene_codes := _codes_by_path(registry.validate_document("map_data", 1, scene_map, sources))

	# The inline placement unit reuses the roster's unit object, so an unknown field
	# inside it must report a placement-qualified path rather than being swallowed.
	var bad_placement := valid_map.duplicate(true)
	bad_placement["enemy_placements"][0]["unit"]["morale"] = 5
	var placement_codes := _codes_by_path(
		registry.validate_document("map_data", 1, bad_placement, sources)
	)

	var bad_condition := valid_map.duplicate(true)
	bad_condition["victory_conditions"]["allies"][0]["reinforcements"] = true
	var condition_codes := _codes_by_path(
		registry.validate_document("map_data", 1, bad_condition, sources)
	)

	if (
		scene_codes.get("unknown_field", "") == "$[map_data@1:chapter_01].tilemap_scene_path"
		and (
			placement_codes.get("unknown_field", "")
			== "$[map_data@1:chapter_01].enemy_placements[0].unit.morale"
		)
		and (
			condition_codes.get("unknown_field", "")
			== "$[map_data@1:chapter_01].victory_conditions.allies[0].reinforcements"
		)
	):
		print("OK  unknown fields in scenes, placements, and conditions report exact paths")
		passed += 1
	else:
		print(
			(
				"FAIL map unknown fields: scene=%s placement=%s condition=%s"
				% [scene_codes, placement_codes, condition_codes]
			)
		)
		failed += 1

	# Objective conditions are the canonical [TCV-4] open registry: a type resolves
	# against ObjectiveConditionRegistry, so adding one is a registration.
	var unknown_objective := valid_map.duplicate(true)
	unknown_objective["victory_conditions"]["allies"][0]["type"] = "collect_all_coins"
	var objective_codes := _codes_by_path(
		registry.validate_document("map_data", 1, unknown_objective, sources)
	)

	# Activation mode is the opposite: a CLOSED engine vocabulary, because a new mode
	# is a turn-scheduler change rather than authored content.
	var bad_mode := valid_map.duplicate(true)
	bad_mode["activation_mode"] = "SIMULTANEOUS"
	var mode_codes := _codes_by_path(registry.validate_document("map_data", 1, bad_mode, sources))

	if (
		(
			objective_codes.get("vocabulary_value_unknown", "")
			== "$[map_data@1:chapter_01].victory_conditions.allies[0].type"
		)
		and (
			mode_codes.get("vocabulary_value_unknown", "")
			== "$[map_data@1:chapter_01].activation_mode"
		)
	):
		print("OK  objective types resolve through a registry; activation modes are closed")
		passed += 1
	else:
		print("FAIL map vocabularies: objective=%s mode=%s" % [objective_codes, mode_codes])
		failed += 1

	# A tile is exactly [x, y]. Without an upper bound a third coordinate would be
	# accepted here and silently discarded by the adapter's Vector2i conversion.
	var long_tile := valid_map.duplicate(true)
	long_tile["player_start_tiles"][0] = [0, 0, 0]
	var long_tile_codes := _codes_by_path(
		registry.validate_document("map_data", 1, long_tile, sources)
	)

	var duplicate_factions := valid_map.duplicate(true)
	duplicate_factions["factions"].append({"id": "blue", "alliance_group": "foes"})
	var duplicate_faction_codes := _codes_by_path(
		registry.validate_document("map_data", 1, duplicate_factions, sources)
	)

	if (
		(
			long_tile_codes.get("array_too_long", "")
			== "$[map_data@1:chapter_01].player_start_tiles[0]"
		)
		and (
			duplicate_faction_codes.get("duplicate_value", "")
			== "$[map_data@1:chapter_01].factions"
		)
	):
		print("OK  tiles are fixed-width and faction ids are unique within a map")
		passed += 1
	else:
		print("FAIL map shape: tile=%s factions=%s" % [long_tile_codes, duplicate_faction_codes])
		failed += 1

	# ── Terrain ───────────────────────────────────────────────────────────────
	var valid_terrain := {
		"kind": "terrain",
		"schema_version": 1,
		"id": "forest",
		"display_name": "Deep Wood",
		"source_refs": ["fed20_classes"],
		"grid_char": "F",
		"move_costs": {"infantry": 2, "mounted": 3, "flying": 1},
		"def_bonus": 2,
		"avoid_bonus": 25,
		"heal_fraction": 0.0,
		"tile_asset_id": "",
	}
	var terrain_errors: Array[Dictionary] = registry.validate_document(
		"terrain", 1, valid_terrain, sources
	)
	if terrain_errors.is_empty():
		print("OK  golden terrain document passes the engine-owned schema")
		passed += 1
	else:
		print("FAIL golden terrain errors: %s" % [terrain_errors])
		failed += 1

	# [TER-2] lifted the closed `terrain_id` vocabulary: a pack may introduce terrain,
	# so an unknown id is now an ordinary open identity rather than a shape error. The
	# paintability rule it used to stand in for did not disappear — it moved to
	# TerrainRegistry.collect_coherence_errors, which is the only place the media
	# reference can actually be resolved.
	var invented_terrain := valid_terrain.duplicate(true)
	invented_terrain["id"] = "swamp"
	var invented_codes := _codes_by_path(
		registry.validate_document("terrain", 1, invented_terrain, sources)
	)

	# `tile_source_id` still indexes the engine's generated tileset, so it remains
	# engine identity rather than authored content and must not be admitted at all.
	var source_id_terrain := valid_terrain.duplicate(true)
	source_id_terrain["tile_source_id"] = 4
	var source_id_codes := _codes_by_path(
		registry.validate_document("terrain", 1, source_id_terrain, sources)
	)

	if (
		not invented_codes.has("vocabulary_value_unknown")
		and source_id_codes.get("unknown_field", "") == "$[terrain@1:forest].tile_source_id"
	):
		print("OK  terrain ids are open ([TER-2]); tile_source_id is still not authored")
		passed += 1
	else:
		print("FAIL terrain identity: invented=%s source_id=%s" % [invented_codes, source_id_codes])
		failed += 1

	# Move costs carry their vocabulary in their KEYS, like the roster's growth maps:
	# an authored `light` (the HUD's label) instead of `light_footed` used to be the
	# kind of typo a value-only check admits and then never applies.
	var bad_movement_key := valid_terrain.duplicate(true)
	bad_movement_key["move_costs"]["light"] = 1
	var movement_key_codes := _codes_by_path(
		registry.validate_document("terrain", 1, bad_movement_key, sources)
	)

	# A free tile is not something pathfinding admits.
	var free_terrain := valid_terrain.duplicate(true)
	free_terrain["move_costs"]["infantry"] = 0
	var free_codes := _codes_by_path(
		registry.validate_document("terrain", 1, free_terrain, sources)
	)

	if (
		(
			movement_key_codes.get("vocabulary_key_unknown", "")
			== "$[terrain@1:forest].move_costs.light"
		)
		and free_codes.get("value_too_small", "") == "$[terrain@1:forest].move_costs.infantry"
	):
		print("OK  move costs are keyed by movement type and cost at least 1")
		passed += 1
	else:
		print("FAIL terrain costs: key=%s free=%s" % [movement_key_codes, free_codes])
		failed += 1

	# A grid char is exactly one character, or a map row cannot be read char by char.
	var wide_char := valid_terrain.duplicate(true)
	wide_char["grid_char"] = "FF"
	var wide_char_codes := _codes_by_path(
		registry.validate_document("terrain", 1, wide_char, sources)
	)

	# A heal fraction is a share of max HP, never a multiple of it.
	var over_heal := valid_terrain.duplicate(true)
	over_heal["heal_fraction"] = 1.5
	var over_heal_codes := _codes_by_path(
		registry.validate_document("terrain", 1, over_heal, sources)
	)

	if (
		wide_char_codes.get("value_too_long", "") == "$[terrain@1:forest].grid_char"
		and over_heal_codes.get("value_too_large", "") == "$[terrain@1:forest].heal_fraction"
	):
		print("OK  grid chars are single characters and heal fractions are bounded")
		passed += 1
	else:
		print("FAIL terrain bounds: char=%s heal=%s" % [wide_char_codes, over_heal_codes])
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


static func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)


# Collapses diagnostics to code -> path so a case can assert the codes it cares
# about without depending on the order or count of unrelated diagnostics.
static func _codes_by_path(errors: Array[Dictionary]) -> Dictionary:
	var by_code := {}
	for error in errors:
		by_code[String(error.get("code", ""))] = String(error.get("path", ""))
	return by_code
