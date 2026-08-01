class_name EntitySchemaRegistry extends RefCounted
# Engine-owned declarative schemas interpreted by one strict validator. Packs
# select registered kind/version pairs; they cannot register executable code.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")
const StatRegistry = preload("res://scripts/core/StatRegistry.gd")
const AIProfileRegistry = preload("res://scripts/core/AIProfileRegistry.gd")

var _schemas: Dictionary = {}
# handler_id -> set of admitted schema_versions. Packs select registered handlers;
# they never supply evaluators.
var _handlers: Dictionary = {}
# vocabulary_id -> set of admitted string values. Author-facing vocabularies are an
# open registry so admitting a new combat family or effect tag is a registration,
# not another `match` inside the validator.
var _vocabularies: Dictionary = {}


static func with_core_schemas():
	var registry = new()
	var nonnegative_int := {"type": "integer", "minimum": 0}
	var string_list := {
		"type": "array", "unique_items": true, "items": {"type": "string", "min_length": 1}
	}
	var int_map := {"type": "object", "additional_properties": nonnegative_int}
	# Per-field transcription state, shared by every content family so an author can
	# mark exactly which values are verified against their cited source.
	var completeness_map := {
		"type": "object",
		"additional_properties":
		{"type": "string", "enum": ["verified", "unverified", "not_applicable"]},
	}
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
					"field_completeness": completeness_map,
					"advancement_edge_refs": string_list,
					"allowed_weapon_families": string_list,
					"class_groups": string_list,
					"special_qualities": string_list,
					"vulnerability_groups": string_list,
					"sprite_id": {"type": "string"},
					"default_movement_profile_id": {"type": "string", "min_length": 1},
					"variants": {"type": "array", "unique_key": "variant_id", "items": variant},
				},
				"validator": Callable(registry, "_validate_class_contract"),
			}
		)
	)

	# Trusted executable descriptors resolve through an open registry rather than a
	# hardcoded match, so a new advancement handler is a registration, not an engine
	# edit. Trial v1 admits only `class_advancement_v1` (class schema trial doc).
	registry.register_handler("class_advancement_v1", 1)
	# Variant eligibility is a trusted predicate descriptor too. The trial fixtures
	# use this minimal fact predicate until the full B3-REQ registry supersedes it.
	registry.register_handler("fact_contains_v1", 1)

	# Author-facing vocabularies are seeded from the engine's existing single-source
	# lists rather than restated here, so there is still exactly one place to edit
	# when a family, track, rank, or effect tag is added.
	registry.register_vocabulary("combat_family", GameConstants.VALID_COMBAT_FAMILIES)
	registry.register_vocabulary("wexp_track", GameConstants.VALID_WEXP_TRACKS)
	registry.register_vocabulary("weapon_rank", GameConstants.WEXP_RANK_THRESHOLDS.keys())
	registry.register_vocabulary("effect_tag", GameConstants.VALID_EFFECT_TAGS)
	# Rosters name stats and AI profiles. Both already have one engine-side registry,
	# so they are seeded from it rather than restated — an authored stat or profile
	# widens those registries, never this file.
	registry.register_vocabulary("growth_stat", StatRegistry.GROWTH_STAT_IDS)
	registry.register_vocabulary("ai_profile", AIProfileRegistry.PROFILES.keys())

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

	# Weapons project the existing `WeaponData` surface, so every admitted field name
	# is the runtime property name the adapter writes. The legacy `range_*_formula`
	# grammar is deliberately absent: it stays an import/compatibility concern, and a
	# registered document that still carries it fails as an unknown field.
	var weapon_variant := {
		"type": "object",
		"required": ["variant_id", "eligibility", "overrides"],
		"properties":
		{
			"variant_id": {"type": "string", "min_length": 1},
			"eligibility": descriptor,
			"overrides": {"type": "object", "additional_properties": {}},
		},
	}
	var weapon_properties := document_header.duplicate(true)
	weapon_properties["kind"] = {"type": "string", "enum": ["weapon"]}
	weapon_properties["combat_family"] = {
		"type": "string", "min_length": 1, "vocabulary": "combat_family"
	}
	weapon_properties["wexp_track"] = {
		"type": "string", "min_length": 1, "vocabulary": "wexp_track"
	}
	weapon_properties["required_rank"] = {
		"type": "string", "min_length": 1, "vocabulary": "weapon_rank"
	}
	# Only hybrids need this; an empty override means "use the combat family".
	weapon_properties["triangle_family"] = {
		"type": "string", "min_length": 1, "vocabulary": "combat_family"
	}
	weapon_properties["mt"] = nonnegative_int
	weapon_properties["hit"] = nonnegative_int
	weapon_properties["crit"] = nonnegative_int
	weapon_properties["wt"] = nonnegative_int
	weapon_properties["cost"] = nonnegative_int
	weapon_properties["wexp"] = nonnegative_int
	# -1 is the authored infinite-durability sentinel, so uses is the one numeric
	# field that admits a negative value. The contract validator rejects exactly 0.
	weapon_properties["uses"] = {"type": "integer", "minimum": -1}
	weapon_properties["strikes_per_attack"] = {"type": "integer", "minimum": 1}
	weapon_properties["uses_mag"] = {"type": "boolean"}
	weapon_properties["is_natural_weapon"] = {"type": "boolean"}
	weapon_properties["icon"] = {"type": "string"}
	weapon_properties["effect_tags"] = {
		"type": "array",
		"unique_items": true,
		"items": {"type": "string", "min_length": 1, "vocabulary": "effect_tag"},
	}
	# Registered formula selection plus its parameters. The contract validator hands
	# both to RangeFormulaRegistry so an unknown id or a bad parameter set fails here
	# rather than as a pushed error the first time a unit is asked for its range.
	weapon_properties["range_min_formula_id"] = {"type": "string", "min_length": 1}
	weapon_properties["range_min_parameters"] = {"type": "object", "additional_properties": {}}
	weapon_properties["range_max_formula_id"] = {"type": "string", "min_length": 1}
	weapon_properties["range_max_parameters"] = {"type": "object", "additional_properties": {}}
	weapon_properties["field_completeness"] = completeness_map
	weapon_properties["variants"] = {
		"type": "array", "unique_key": "variant_id", "items": weapon_variant
	}
	(
		registry
		. register_schema(
			"weapon",
			1,
			{
				"required":
				[
					"kind",
					"schema_version",
					"id",
					"display_name",
					"source_refs",
					"combat_family",
					"wexp_track",
					"required_rank",
					"mt",
					"hit",
					"crit",
					"wt",
					"uses",
					"cost",
					"wexp",
					"range_min_formula_id",
					"range_min_parameters",
					"range_max_formula_id",
					"range_max_parameters",
					"field_completeness"
				],
				"properties": weapon_properties,
				"validator": Callable(registry, "_validate_weapon_contract"),
			}
		)
	)

	# Rosters project the existing `UnitData` surface for the same reason weapons
	# project `WeaponData`: the runtime adapter writes admitted field names straight
	# onto the resource, so a name that diverges from the property is a silently
	# dropped field. One `roster` document holds many units — the catalogue already
	# indexes rosters by id and cross-references `roster.units[].class_id`, so `units`
	# is validated as a nested array rather than split into per-unit documents.
	#
	# Deliberately NOT admitted, and why:
	#   - `faction` / sprite / portrait ids: `UnitData` has no such property today
	#     (faction lives on a map's enemy placement, not on the unit), so admitting
	#     one would author a field nothing reads.
	#   - `is_default_roster`, `is_incapacitated`, `conditions`, `active_modifiers`:
	#     engine-written runtime/battle state, not authored content.
	var stat_map := {
		"type": "object", "key_vocabulary": "growth_stat", "additional_properties": nonnegative_int
	}
	var wexp_map := {
		"type": "object", "key_vocabulary": "wexp_track", "additional_properties": nonnegative_int
	}
	# An authored inventory slot is a weapon slot: items and equipment belong to the
	# Items family and are not admitted until that family has an identity schema.
	var inventory_entry := {
		"type": "object",
		"required": ["weapon_id"],
		"properties":
		{
			"weapon_id": {"type": "string", "min_length": 1},
			# -1 is the infinite-durability sentinel, matching the weapon contract.
			"uses": {"type": "integer", "minimum": -1},
			# Durable weapon-variant selection. Weapon variants were validated by the
			# Weapons change but nothing selected one; this is where a slot commits to
			# a variant, and `SaveCodec` restores it with the rest of the entry.
			"weapon_variant_id": {"type": "string", "min_length": 1},
		},
	}
	var unit := {
		"type": "object",
		"required": ["unit_id", "class_id"],
		"properties":
		{
			"unit_id": {"type": "string", "min_length": 1},
			"unit_name": {"type": "string", "min_length": 1},
			"class_id": {"type": "string", "min_length": 1},
			"class_line_id": {"type": "string", "min_length": 1},
			# The durable authored selections the class vertical already round-trips.
			"class_variant_id": {"type": "string", "min_length": 1},
			"advancement_edge_id": {"type": "string", "min_length": 1},
			"advancement_edge_variant_id": {"type": "string", "min_length": 1},
			"level": {"type": "integer", "minimum": 1},
			"exp": nonnegative_int,
			"internal_level": {"type": "integer", "minimum": 1},
			"is_promoted": {"type": "boolean"},
			# A unit with no HP can never be deployed, so the floor is in the schema
			# where the diagnostic carries a path — not only in the runtime adapter.
			"max_hp": {"type": "integer", "minimum": 1},
			"hp": {"type": "integer", "minimum": 1},
			"strength": nonnegative_int,
			"magic": nonnegative_int,
			"defense": nonnegative_int,
			"resistance": nonnegative_int,
			"skill": nonnegative_int,
			"speed": nonnegative_int,
			"luck": nonnegative_int,
			"movement": nonnegative_int,
			"constitution": nonnegative_int,
			"line_of_sight": nonnegative_int,
			"growth_rates": stat_map,
			"growth_accumulators": stat_map,
			"weapon_wexp": wexp_map,
			"skills": string_list,
			"earned_skills": string_list,
			"reclass_options": string_list,
			"inventory": {"type": "array", "items": inventory_entry},
			"gold": nonnegative_int,
			"can_seize": {"type": "boolean"},
			"ai_profile": {"type": "string", "min_length": 1, "vocabulary": "ai_profile"},
		},
	}
	var roster_properties := document_header.duplicate(true)
	roster_properties["kind"] = {"type": "string", "enum": ["roster"]}
	roster_properties["field_completeness"] = completeness_map
	roster_properties["units"] = {
		"type": "array", "min_items": 1, "unique_key": "unit_id", "items": unit
	}
	(
		registry
		. register_schema(
			"roster",
			1,
			{
				"required":
				["kind", "schema_version", "id", "display_name", "source_refs", "units"],
				"properties": roster_properties,
				"validator": Callable(registry, "_validate_roster_contract"),
			}
		)
	)
	return registry


func register_vocabulary(vocabulary_id: String, values: Array) -> void:
	if not _vocabularies.has(vocabulary_id):
		_vocabularies[vocabulary_id] = {}
	for value in values:
		_vocabularies[vocabulary_id][String(value)] = true


func vocabulary_admits(vocabulary_id: String, value: String) -> bool:
	return _vocabularies.get(vocabulary_id, {}).has(value)


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
	_validate_occurrence_coverage(document, root_path, sources, occurrences, errors)
	return errors


static func _validate_occurrence_coverage(
	document: Dictionary,
	root_path: String,
	sources: Dictionary,
	occurrences: Dictionary,
	errors: Array[Dictionary]
) -> void:
	var document_ref := "%s:%s" % [document.get("kind", ""), document.get("id", "")]
	var referenced := {}
	var has_unresolved_reference := false
	for index in document.get("occurrence_audit_refs", []).size():
		var occurrence_id := String(document["occurrence_audit_refs"][index])
		referenced[occurrence_id] = true
		if not occurrences.has(occurrence_id) or not occurrences[occurrence_id] is Dictionary:
			has_unresolved_reference = true
			continue  # The schema pass owns unresolved-reference diagnostics.
		var occurrence: Dictionary = occurrences[occurrence_id]
		var path := "%s.occurrence_audit_refs[%d]" % [root_path, index]
		if String(occurrence.get("document_ref", "")) != document_ref:
			errors.append(
				_error(
					"provenance_occurrence_document_mismatch",
					path,
					"Occurrence audit does not name this document."
				)
			)
		var source_ref := String(occurrence.get("source_ref", ""))
		if (
			source_ref.is_empty()
			or not sources.has(source_ref)
			or not document.get("source_refs", []).has(source_ref)
		):
			errors.append(
				_error(
					"provenance_occurrence_source_unresolved",
					path,
					"Occurrence audit source does not resolve through this document."
				)
			)
		if not _json_pointer_resolves(document, String(occurrence.get("field_path", ""))):
			errors.append(
				_error(
					"provenance_occurrence_field_unresolved",
					path,
					"Occurrence audit field_path does not resolve in this document."
				)
			)
	if has_unresolved_reference:
		return  # Avoid cascading reverse-coverage noise behind a direct dangling ref.
	for occurrence_id in occurrences:
		var occurrence: Variant = occurrences[occurrence_id]
		if (
			occurrence is Dictionary
			and String(occurrence.get("document_ref", "")) == document_ref
			and not referenced.has(occurrence_id)
		):
			errors.append(
				_error(
					"provenance_occurrence_coverage_missing",
					"%s.occurrence_audit_refs" % root_path,
					"An occurrence audit naming this document is not referenced by it."
				)
			)


static func _json_pointer_resolves(document: Dictionary, pointer: String) -> bool:
	if not pointer.begins_with("/") or pointer == "/":
		return false
	var value: Variant = document
	for encoded_part in pointer.trim_prefix("/").split("/"):
		var part := encoded_part.replace("~1", "/").replace("~0", "~")
		if value is Dictionary and value.has(part):
			value = value[part]
		elif value is Array and part.is_valid_int() and int(part) >= 0 and int(part) < value.size():
			value = value[int(part)]
		else:
			return false
	return true


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
	if field_schema.has("enum") and not _enum_has(field_schema["enum"], value):
		errors.append(_error("value_not_admitted", path, "Value is not in the admitted set."))
		return
	match declared_type:
		"string":
			if typeof(value) != TYPE_STRING:
				errors.append(_error("type_mismatch", path, "Value must be a string."))
			elif String(value).length() < int(field_schema.get("min_length", 0)):
				errors.append(_error("value_too_short", path, "String value is too short."))
			elif (
				field_schema.has("vocabulary")
				and not vocabulary_admits(String(field_schema["vocabulary"]), String(value))
			):
				errors.append(
					_error(
						"vocabulary_value_unknown",
						path,
						(
							"'%s' is not registered in the '%s' vocabulary."
							% [value, field_schema["vocabulary"]]
						)
					)
				)
		"boolean":
			if typeof(value) != TYPE_BOOL:
				errors.append(_error("type_mismatch", path, "Value must be a boolean."))
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
			# An open-ended map (growth rates, WEXP totals, stat caps) carries its
			# vocabulary in its KEYS, so the key itself is validated here. Without this
			# a misspelled stat authored as `strenght: 40` would be admitted by
			# `additional_properties` and then silently never roll.
			var key_vocabulary := String(field_schema.get("key_vocabulary", ""))
			for key: Variant in keys:
				var key_name := String(key)
				if (
					not key_vocabulary.is_empty()
					and not vocabulary_admits(key_vocabulary, key_name)
				):
					errors.append(
						_error(
							"vocabulary_key_unknown",
							"%s.%s" % [path, key_name],
							(
								"'%s' is not registered in the '%s' vocabulary."
								% [key_name, key_vocabulary]
							)
						)
					)
					continue
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


static func _enum_has(admitted: Array, value: Variant) -> bool:
	if admitted.has(value):
		return true
	# JSON decodes numeric tokens as floats. Integral values must compare equal to
	# integer schema literals or every schema_version loaded from disk fails.
	if typeof(value) == TYPE_FLOAT and float(value) == floor(float(value)):
		return admitted.has(int(value))
	return false


func _validate_class_contract(
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
		if variant is Dictionary:
			_validate_descriptor(
				variant.get("eligibility", null),
				"%s.variants[%d].eligibility" % [root_path, index],
				errors
			)
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
		if variant is Dictionary:
			_validate_descriptor(
				variant.get("eligibility", null),
				"%s.variants[%d].eligibility" % [root_path, index],
				errors
			)
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


func _validate_weapon_contract(
	document: Dictionary, root_path: String, errors: Array[Dictionary]
) -> void:
	# Weapon variants re-price and re-tune one weapon; they never restate identity,
	# provenance, or the family/track/rank triple that decides who may equip it.
	var allowed_overrides := {
		"mt": true,
		"hit": true,
		"crit": true,
		"wt": true,
		"uses": true,
		"cost": true,
		"wexp": true,
		"effect_tags": true,
		"uses_mag": true,
		"triangle_family": true,
		"strikes_per_attack": true,
		"icon": true,
		"range_min_formula_id": true,
		"range_min_parameters": true,
		"range_max_formula_id": true,
		"range_max_parameters": true,
	}
	for index in document.get("variants", []).size():
		var variant: Variant = document.get("variants", [])[index]
		if variant is Dictionary:
			_validate_descriptor(
				variant.get("eligibility", null),
				"%s.variants[%d].eligibility" % [root_path, index],
				errors
			)
		if not variant is Dictionary or not variant.get("overrides", null) is Dictionary:
			continue
		for field in variant["overrides"]:
			if not allowed_overrides.has(String(field)):
				errors.append(
					_error(
						"variant_override_forbidden",
						"%s.variants[%d].overrides.%s" % [root_path, index, field],
						"Weapon variants may override only combat numbers, effects, and range."
					)
				)

	var min_bound := _validate_range_selection(document, "min", root_path, errors)
	var max_bound := _validate_range_selection(document, "max", root_path, errors)
	# Only literal ranges are decidable here; a stat-driven bound depends on the unit
	# holding the weapon, so it is checked at evaluation instead.
	if min_bound >= 0 and max_bound >= 0 and min_bound > max_bound:
		errors.append(
			_error(
				"range_min_exceeds_max",
				"%s.range_min_formula_id" % root_path,
				"Minimum range cannot exceed maximum range."
			)
		)

	# -1 is infinite and any positive count is finite; 0 is a weapon that can never
	# be used, which is an authoring mistake rather than a balance choice.
	if document.has("uses") and int(document["uses"]) == 0:
		errors.append(
			_error("weapon_uses_invalid", "%s.uses" % root_path, "Uses must be -1 or at least 1.")
		)

	# Natural weapons are granted by a shifted form, not bought or spent.
	if bool(document.get("is_natural_weapon", false)):
		if int(document.get("cost", 0)) != 0:
			errors.append(
				_error(
					"natural_weapon_cost_forbidden",
					"%s.cost" % root_path,
					"A natural weapon cannot carry a purchase cost."
				)
			)
		if int(document.get("uses", -1)) != -1:
			errors.append(
				_error(
					"natural_weapon_uses_forbidden",
					"%s.uses" % root_path,
					"A natural weapon cannot consume uses."
				)
			)

	# The engine derives WEXP gain from the track and equip legality from the family,
	# so a weapon whose track is not its family's track trains progress its wielder's
	# class can never spend.
	var combat_family := String(document.get("combat_family", ""))
	var wexp_track := String(document.get("wexp_track", ""))
	if (
		not combat_family.is_empty()
		and not wexp_track.is_empty()
		and wexp_track != GameConstants.combat_family_to_wexp_track(combat_family)
	):
		errors.append(
			_error(
				"wexp_track_family_mismatch",
				"%s.wexp_track" % root_path,
				(
					"Track '%s' is not the WEXP track of combat family '%s'."
					% [wexp_track, combat_family]
				)
			)
		)

	# `WeaponData.is_healing_staff` keys off this tag plus the staff family; tagging a
	# non-staff weapon with it would produce a healer the action menu never offers.
	var effect_tags: Variant = document.get("effect_tags", [])
	if (
		effect_tags is Array
		and effect_tags.has(GameConstants.TAG_HEAL_PLUS_MAG)
		and combat_family != "staff"
	):
		errors.append(
			_error(
				"effect_tag_family_mismatch",
				"%s.effect_tags" % root_path,
				"The heal effect tag is only meaningful on the staff combat family."
			)
		)


func _validate_roster_contract(
	document: Dictionary, root_path: String, errors: Array[Dictionary]
) -> void:
	var units: Variant = document.get("units", [])
	if not units is Array:
		return  # The schema pass already reported the mistyped units array.
	for index in units.size():
		var unit: Variant = units[index]
		if not unit is Dictionary:
			continue
		var unit_path := "%s.units[%d]" % [root_path, index]

		# Authored damage is meaningful (a wounded recruit), but a unit that starts
		# above its own maximum is an authoring mistake the level-up clamp would hide.
		if unit.has("hp") and unit.has("max_hp") and int(unit["hp"]) > int(unit["max_hp"]):
			errors.append(
				_error(
					"unit_hp_exceeds_max",
					"%s.hp" % unit_path,
					"Starting HP cannot exceed the unit's maximum HP."
				)
			)

		# A variant selection is only meaningful against the edge that offers it, so
		# naming one without an edge selects nothing at all.
		if (
			not String(unit.get("advancement_edge_variant_id", "")).is_empty()
			and String(unit.get("advancement_edge_id", "")).is_empty()
		):
			errors.append(
				_error(
					"selected_edge_variant_without_edge",
					"%s.advancement_edge_variant_id" % unit_path,
					"A selected edge variant requires the advancement edge it belongs to."
				)
			)

		var inventory: Variant = unit.get("inventory", [])
		if not inventory is Array:
			continue
		for slot in inventory.size():
			var entry: Variant = inventory[slot]
			# Same rule as the weapon contract: -1 is infinite and any positive count is
			# finite, but a slot authored with 0 uses is a weapon that can never be swung.
			if entry is Dictionary and entry.has("uses") and int(entry["uses"]) == 0:
				errors.append(
					_error(
						"inventory_uses_invalid",
						"%s.inventory[%d].uses" % [unit_path, slot],
						"Inventory uses must be -1 or at least 1."
					)
				)


# Returns the resolved literal bound, or -1 when the bound is unknown because the
# selection failed, is missing, or depends on a live unit's stats.
func _validate_range_selection(
	document: Dictionary, bound: String, root_path: String, errors: Array[Dictionary]
) -> int:
	var id_field := "range_%s_formula_id" % bound
	var parameter_field := "range_%s_parameters" % bound
	var formula_id := String(document.get(id_field, ""))
	var parameters: Variant = document.get(parameter_field, null)
	if formula_id.is_empty() or not parameters is Dictionary:
		return -1  # The schema pass already reported the missing or mistyped selection.
	if not RangeFormulaRegistry.DESCRIPTORS.has(formula_id):
		errors.append(
			_error(
				"range_formula_unknown",
				"%s.%s" % [root_path, id_field],
				"Range formula '%s' is not registered with the engine." % formula_id
			)
		)
		return -1
	var normalized: Dictionary = normalize_json_integers(parameters)
	var formula_errors := RangeFormulaRegistry.validate(formula_id, normalized)
	if not formula_errors.is_empty():
		errors.append(
			_error(
				"range_formula_parameters_invalid",
				"%s.%s" % [root_path, parameter_field],
				formula_errors[0]
			)
		)
		return -1
	if formula_id != "literal":
		return -1
	return int(normalized["value"])


# JSON decodes every number as a float, so an authored `{"value": 1}` arrives as 1.0
# and would fail registries that require a true integer. This narrows integral floats
# back to ints at the pack boundary instead of loosening those registries.
static func normalize_json_integers(value: Variant) -> Variant:
	if value is Dictionary:
		var mapped := {}
		for key in value:
			mapped[key] = normalize_json_integers(value[key])
		return mapped
	if value is Array:
		var items := []
		for item in value:
			items.append(normalize_json_integers(item))
		return items
	if typeof(value) == TYPE_FLOAT and float(value) == floor(float(value)):
		return int(value)
	return value


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
