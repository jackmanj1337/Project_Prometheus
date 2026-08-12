class_name EntitySchemaRegistry extends RefCounted
# Engine-owned declarative schemas interpreted by one strict validator. Packs
# select registered kind/version pairs; they cannot register executable code.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")
const StatRegistry = preload("res://scripts/core/StatRegistry.gd")
const AIProfileRegistry = preload("res://scripts/core/AIProfileRegistry.gd")
const SkillEffectRegistry = preload("res://scripts/registries/SkillEffectRegistry.gd")
const RegistryCatalog = preload("res://scripts/registries/RegistryCatalog.gd")

var _schemas: Dictionary = {}
# handler_id -> set of admitted schema_versions. Packs select registered handlers;
# they never supply evaluators.
var _handlers: Dictionary = {}
# vocabulary_id -> set of admitted string values. Author-facing vocabularies are an
# open registry so admitting a new combat family or effect tag is a registration,
# not another `match` inside the validator.
var _vocabularies: Dictionary = {}

# The canonical media type of every extension on the project's Tier-1 allow-list
# (`CampaignArchivePreflight.APPROVED_MEDIA_EXTENSIONS`). That list decides what may
# ride inside a pack; this table only names the type each admitted extension decodes
# to, so a declared `decoded_type` can be checked against the file it points at
# instead of being taken on trust. `test_entity_schema_registry` asserts this table
# covers the allow-list exactly, so adding an extension there without a type here
# fails a test rather than silently admitting an untyped format.
const MEDIA_TYPES_BY_EXTENSION := {
	"png": "image/png",
	"ogg": "audio/ogg",
	"wav": "audio/wav",
	"ttf": "font/ttf",
	"otf": "font/otf",
}

# Leading bytes that prove a file really is what its record claims. This is the
# validation-time weight of the plan's "decoder-verified" requirement: a full decode
# belongs to the authoring/import tool, but a magic-byte check is cheap, needs no
# display server, and is strictly stronger than believing the authored field.
const MEDIA_MAGIC_BY_TYPE := {
	"image/png": [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
	"audio/ogg": [0x4F, 0x67, 0x67, 0x53],  # "OggS"
	"audio/wav": [0x52, 0x49, 0x46, 0x46],  # "RIFF"
	"font/ttf": [0x00, 0x01, 0x00, 0x00],
	"font/otf": [0x4F, 0x54, 0x54, 0x4F],  # "OTTO"
}


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
	registry.register_vocabulary("skill_effect", SkillEffectRegistry.builtin_ids())
	registry.register_vocabulary("skill_trigger", GameConstants.VALID_SKILL_TRIGGERS)
	registry.register_vocabulary("stat", StatRegistry.display_stat_ids())
	registry.register_vocabulary("primitive_handler", RegistryCatalog.builtin_primitive_handlers())
	(
		registry
		. register_vocabulary(
			"registry_family",
			[
				"action_primitives",
				"resource_types",
				"occupancy_policies",
				"objective_conditions",
				"item_effects",
			]
		)
	)

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

	var skill_properties := document_header.duplicate(true)
	skill_properties["kind"] = {"type": "string", "enum": ["skill"]}
	skill_properties["trigger"] = {"type": "string", "min_length": 1, "vocabulary": "skill_trigger"}
	skill_properties["effect_id"] = {
		"type": "string", "min_length": 1, "vocabulary": "skill_effect"
	}
	skill_properties["effect_params"] = {"type": "object", "additional_properties": {}}
	skill_properties["activation_chance_stat"] = {"type": "string", "vocabulary": "growth_stat"}
	skill_properties["activation_divisor"] = {"type": "integer", "minimum": 1}
	skill_properties["is_player_activated"] = {"type": "boolean"}
	skill_properties["release_available"] = {"type": "boolean"}
	skill_properties["max_uses_per_map"] = {"type": "integer", "minimum": -1}
	skill_properties["max_uses_per_combat"] = {"type": "integer", "minimum": -1}
	skill_properties["field_completeness"] = completeness_map
	(
		registry
		. register_schema(
			"skill",
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
					"effect_id",
					"effect_params",
					"release_available",
					"field_completeness",
				],
				"properties": skill_properties,
			}
		)
	)

	var pair_up_properties := document_header.duplicate(true)
	pair_up_properties["kind"] = {"type": "string", "enum": ["pair_up_bonus_table"]}
	pair_up_properties["scaling_divisor"] = {"type": "integer", "minimum": 1}
	pair_up_properties["scaling_stats"] = {
		"type": "array",
		"unique_items": true,
		"items": {"type": "string", "min_length": 1, "vocabulary": "stat"},
	}
	pair_up_properties["class_bonuses"] = {
		"type": "object",
		"additional_properties":
		{
			"type": "object",
			"key_vocabulary": "stat",
			"additional_properties": nonnegative_int,
		},
	}
	pair_up_properties["field_completeness"] = completeness_map
	(
		registry
		. register_schema(
			"pair_up_bonus_table",
			1,
			{
				"required":
				[
					"kind",
					"schema_version",
					"id",
					"display_name",
					"source_refs",
					"scaling_divisor",
					"scaling_stats",
					"class_bonuses",
					"field_completeness",
				],
				"properties": pair_up_properties,
			}
		)
	)

	var registry_part := {
		"type": "object",
		"required": ["primitive_handler"],
		"properties":
		{
			"primitive_handler":
			{"type": "string", "min_length": 1, "vocabulary": "primitive_handler"},
		},
	}
	var registry_properties := document_header.duplicate(true)
	registry_properties["kind"] = {"type": "string", "enum": ["registry_entry"]}
	registry_properties["family"] = {
		"type": "string", "min_length": 1, "vocabulary": "registry_family"
	}
	registry_properties["entry_id"] = {"type": "string", "min_length": 1}
	registry_properties["label_key"] = {"type": "string", "min_length": 1}
	registry_properties["owner_feature"] = {"type": "string", "min_length": 1}
	registry_properties["version"] = {"type": "integer", "minimum": 1}
	registry_properties["entry_kind"] = {"type": "string", "min_length": 1}
	registry_properties["priority"] = {"type": "integer"}
	registry_properties["primitive_handler"] = {
		"type": "string", "min_length": 1, "vocabulary": "primitive_handler"
	}
	registry_properties["params_schema"] = {"type": "object", "additional_properties": {}}
	registry_properties["subjects"] = string_list
	registry_properties["composition"] = {"type": "array", "items": registry_part}
	registry_properties["projection_support"] = {"type": "boolean"}
	registry_properties["save_fields"] = string_list
	registry_properties["docs_text"] = {"type": "string", "min_length": 1}
	registry_properties["test_fixture"] = {"type": "object", "additional_properties": {}}
	(
		registry
		. register_schema(
			"registry_entry",
			1,
			{
				"required":
				[
					"kind",
					"schema_version",
					"id",
					"display_name",
					"source_refs",
					"family",
					"entry_id",
					"label_key",
					"owner_feature",
					"version",
					"entry_kind",
					"primitive_handler",
					"params_schema",
					"docs_text",
					"test_fixture",
				],
				"properties": registry_properties,
			}
		)
	)

	var campaign_properties := document_header.duplicate(true)
	campaign_properties["kind"] = {"type": "string", "enum": ["campaign"]}
	for field in ["campaign_id", "label", "author_id", "campaign_version", "start_node_id"]:
		campaign_properties[field] = {"type": "string", "min_length": 1}
	campaign_properties["is_dev_only"] = {"type": "boolean"}
	campaign_properties["protected_fields"] = string_list
	campaign_properties["compatible_status_sources"] = {
		"type": "array", "items": {"type": "object", "additional_properties": {}}
	}
	campaign_properties["status_import_benefits"] = {
		"type": "array", "items": {"type": "object", "additional_properties": {}}
	}
	campaign_properties["rules"] = {"type": "object", "additional_properties": {}}
	campaign_properties["nodes"] = {
		"type": "array",
		"min_items": 1,
		"items": {"type": "object", "additional_properties": {}},
	}
	(
		registry
		. register_schema(
			"campaign",
			1,
			{
				"required":
				[
					"kind",
					"schema_version",
					"id",
					"display_name",
					"source_refs",
					"campaign_id",
					"label",
					"nodes",
				],
				"properties": campaign_properties,
			}
		)
	)

	var map_registry_row := {
		"type": "object",
		"required": ["id", "label", "map_data_id", "roster_id"],
		"properties":
		{
			"id": {"type": "string", "min_length": 1},
			"label": {"type": "string", "min_length": 1},
			"map_data_id": {"type": "string", "min_length": 1},
			"roster_id": {"type": "string", "min_length": 1},
			"description": {"type": "string"},
			"is_dev_only": {"type": "boolean"},
		},
	}
	var map_registry_properties := document_header.duplicate(true)
	map_registry_properties["kind"] = {"type": "string", "enum": ["map_registry"]}
	map_registry_properties["entries"] = {
		"type": "array", "min_items": 1, "unique_key": "id", "items": map_registry_row
	}
	(
		registry
		. register_schema(
			"map_registry",
			1,
			{
				"required":
				["kind", "schema_version", "id", "display_name", "source_refs", "entries"],
				"properties": map_registry_properties,
			}
		)
	)

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
	# An authored inventory slot holds either a weapon or an item, mirroring
	# `InventoryEntry.entry_type`. Neither id is individually required, because the
	# choice is exclusive rather than optional — the roster contract enforces exactly
	# one, which gives a slot-qualified diagnostic that `required` could not.
	# Equip slots still wait: `InventoryEntry`'s equip fields are M10 forging surface
	# that nothing authors or reads yet.
	var inventory_entry := {
		"type": "object",
		"properties":
		{
			"weapon_id": {"type": "string", "min_length": 1},
			"item_id": {"type": "string", "min_length": 1},
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
	# Items project the existing `ItemData` surface, on the same rule as weapons and
	# rosters: every admitted field name is the runtime property the adapter writes.
	#
	# Deliberately NOT constrained, and why:
	#   - `item_type` is admitted as a plain string. It is a real `ItemData` property,
	#     so a pack may author it, but nothing in the engine reads it yet — binding it
	#     to a vocabulary now would invent a constraint no behaviour justifies. The
	#     vocabulary lands with the first consumer.
	#   - No `variants` array. Weapons have one because forging selects it; nothing
	#     selects an item variant, and authoring a selection surface nothing reads is
	#     the trap the roster family avoided with `faction`.
	var item_properties := document_header.duplicate(true)
	item_properties["kind"] = {"type": "string", "enum": ["item"]}
	item_properties["item_type"] = {"type": "string"}
	item_properties["icon"] = {"type": "string"}
	# -1 is the infinite/equippable sentinel, matching the weapon contract. The
	# contract validator rejects exactly 0.
	item_properties["uses"] = {"type": "integer", "minimum": -1}
	item_properties["cost"] = nonnegative_int
	# `ItemHandler` commits through `ItemEffectRegistry`, so an unregistered effect is
	# a warning at use time today. Resolving it here fails the pack instead.
	item_properties["effect_id"] = {"type": "string", "min_length": 1, "vocabulary": "item_effect"}
	item_properties["effect_params"] = {"type": "object", "additional_properties": {}}
	item_properties["field_completeness"] = completeness_map
	(
		registry
		. register_schema(
			"item",
			1,
			{
				"required":
				["kind", "schema_version", "id", "display_name", "source_refs", "cost", "uses"],
				"properties": item_properties,
				"validator": Callable(registry, "_validate_item_contract"),
			}
		)
	)
	# Seeded from the engine's item-effect registry rather than restated, so adding an
	# effect entry admits it for authoring automatically — a registration, not an edit
	# to this file.
	registry.register_vocabulary("item_effect", ItemEffectRegistry.new().ids())

	# Media identity. `asset_registry` is one of the infrastructure documents the plan
	# exempts from document-level `source_refs` (with the catalogue, manifest, and
	# source registry) — but every record inside it is still validated. The logical
	# ids are author-defined, so `assets` carries NO key vocabulary; it is the values
	# that are bounded. This is the schema the class/weapon/item icon deferral needs.
	var asset_record := {
		"type": "object",
		"required": ["path", "decoded_type", "byte_size", "sha256", "original_filename"],
		"properties":
		{
			"path": {"type": "string", "min_length": 1},
			"decoded_type": {"type": "string", "min_length": 1, "vocabulary": "media_type"},
			# A zero-byte asset decodes to nothing: an authoring mistake, not an
			# intentionally empty file.
			"byte_size": {"type": "integer", "minimum": 1},
			"sha256": {"type": "string", "min_length": 64},
			"original_filename": {"type": "string", "min_length": 1},
			# Sprite frame metadata is ordinary pack JSON, but it is admitted only when
			# an asset record names it explicitly. This keeps archive admission closed
			# without relying on a filename convention.
			"sidecar_path": {"type": "string", "min_length": 1},
			# Notes explain a decision; they never replace the structured fields.
			"author_notes": {"type": "string"},
		},
	}
	var asset_registry_properties := document_header.duplicate(true)
	asset_registry_properties["kind"] = {"type": "string", "enum": ["asset_registry"]}
	asset_registry_properties["assets"] = {"type": "object", "additional_properties": asset_record}
	(
		registry
		. register_schema(
			"asset_registry",
			1,
			{
				"required": ["kind", "schema_version", "id", "assets"],
				"properties": asset_registry_properties,
				"validator": Callable(registry, "_validate_asset_registry_contract"),
			}
		)
	)
	# Admission reuses the project's existing Tier-1 media allow-list rather than
	# starting a second one: `CampaignArchivePreflight` already decides which
	# extensions may ride along inside a pack, so the canonical media type of each
	# admitted extension is the only new fact this file introduces. SVG is
	# deliberately absent — the plan withholds production admission until a separate
	# contract defines active-feature sanitization and canonical decode behaviour.
	registry.register_vocabulary("media_type", MEDIA_TYPES_BY_EXTENSION.values())

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

	# Maps project the existing `MapData` surface. One document holds terrain AND the
	# encounter (placements, factions, objectives, rewards) because `MapData` holds
	# both today: registering two documents here would invent a split the resource,
	# the adapter, and `collect_map_data_validation_errors` do not have. The split
	# belongs with the first encounter authored independently of its terrain.
	#
	# This schema owns DOCUMENT SHAPE only — admitted fields, types, vocabularies, and
	# JSON-path diagnostics. Semantics (tile bounds, faction coherence, duplicate
	# tiles, objective validity) are already owned by
	# `DataManager.collect_map_data_validation_errors`, which now runs on Tier-2 packs
	# at activation. Restating those rules here would create the second authority the
	# implementation plan forbids.
	#
	# `tilemap_scene_path` is deliberately NOT admitted: a pack may only carry indexed
	# JSON plus approved Tier-1 media, so it can never ship the `PackedScene` that
	# field names. A registered map that carries one fails as an unknown field.
	var tile := {
		"type": "array",
		"min_items": 2,
		"max_items": 2,
		"items": {"type": "integer"},
	}
	var placement := {
		"type": "object",
		"required": ["unit", "tile"],
		"properties":
		# The inline enemy is the same surface the roster schema describes, so it
		{
			# reuses that object rather than a second copy that would drift from it.
			"unit": unit,
			"tile": tile,
			"faction": {"type": "string", "min_length": 1},
			"is_boss": {"type": "boolean"},
			# An explicit override; omission preserves the unit's own profile, so an
			# empty string here would mean something different from absence.
			"ai_profile": {"type": "string", "min_length": 1, "vocabulary": "ai_profile"},
		},
	}
	var faction := {
		"type": "object",
		"required": ["id"],
		"properties":
		{
			"id": {"type": "string", "min_length": 1},
			"display_name": {"type": "string", "min_length": 1},
			# RGB or RGBA in 0..1. JSON has no Color, so the adapter converts.
			"color": {"type": "array", "min_items": 3, "max_items": 4, "items": {"type": "number"}},
			"alliance_group": {"type": "string", "min_length": 1},
			# `FactionData.controller` is an open enum on purpose ("so new controllers
			# slot in without touching this file"), so it is admitted as a plain string.
			"controller": {"type": "string", "min_length": 1},
		},
	}
	var objective_condition := {
		"type": "object",
		"required": ["type"],
		"properties":
		# The canonical [TCV-4] open registry: an objective type resolves against
		# ObjectiveConditionRegistry, so adding a condition is a registration and
		{
			# never another arm of a match statement.
			"type": {"type": "string", "min_length": 1, "vocabulary": "objective_condition"},
			"faction_id": {"type": "string"},
			"unit_ids": string_list,
			"tiles": {"type": "array", "items": tile},
			"tile": tile,
			"turns": nonnegative_int,
		},
	}
	var condition_groups := {
		# Keys are author-defined alliance-group names, so this carries NO key
		# vocabulary — the group names are cross-checked against the map's own factions
		# by the semantic pass instead.
		"type": "object",
		"additional_properties": {"type": "array", "items": objective_condition},
	}
	var map_properties := document_header.duplicate(true)
	map_properties["kind"] = {"type": "string", "enum": ["map_data"]}
	map_properties["grid"] = {"type": "array", "min_items": 1, "items": {"type": "string"}}
	map_properties["player_start_tiles"] = {"type": "array", "min_items": 1, "items": tile}
	map_properties["camera_start_tile"] = tile
	map_properties["enemy_placements"] = {"type": "array", "items": placement}
	map_properties["factions"] = {"type": "array", "unique_key": "id", "items": faction}
	map_properties["turn_order"] = string_list
	map_properties["activation_mode"] = {
		"type": "string", "min_length": 1, "vocabulary": "activation_mode"
	}
	map_properties["victory_conditions"] = condition_groups
	map_properties["defeat_conditions"] = condition_groups
	map_properties["reward_gold"] = nonnegative_int
	map_properties["reward_items"] = string_list
	map_properties["field_completeness"] = completeness_map
	(
		registry
		. register_schema(
			"map_data",
			1,
			{
				"required":
				[
					"kind",
					"schema_version",
					"id",
					"display_name",
					"source_refs",
					"grid",
					"player_start_tiles"
				],
				"properties": map_properties,
			}
		)
	)
	# Activation mode is a CLOSED engine vocabulary — a new mode is a turn-scheduler
	# change, not authored content — so it is seeded from the same list the runtime
	# validator enforces. Objective condition types are the opposite: an open registry.
	registry.register_vocabulary("activation_mode", GameConstants.VALID_ACTIVATION_MODES)
	registry.register_vocabulary("objective_condition", ObjectiveConditionRegistry.new().ids())

	# Terrain is the only family with no `*Data` resource behind it: its numbers were
	# baked into six engine tables, now consolidated in `TerrainRegistry`. A document
	# retunes a terrain the engine paints, or — since [TER-2] (owner decision
	# 2026-08-01) — introduces one of its own.
	#
	# `id` used to resolve against a vocabulary seeded from the engine set, because a
	# tile's appearance came from the engine's generated tileset by source id and a
	# pack ships indexed JSON plus approved Tier-1 media, never a `TileSet`.
	# `TerrainTileSetBuilder` now builds atlas sources from that media at activation,
	# so the vocabulary restriction is lifted and the id is an OPEN identity like every
	# other family's. The reason behind the old restriction is unchanged and still
	# enforced — an introduced terrain that names no resolvable art would paint as wall
	# with no diagnostic — but it is a `TerrainRegistry` coherence rule now, where the
	# media reference can actually be checked, rather than a shape rule here.
	#
	# `tile_source_id` is still not admitted: it indexes the engine tileset, so it is
	# engine identity rather than authored content. A pack names art by asset id.
	var terrain_properties := document_header.duplicate(true)
	terrain_properties["kind"] = {"type": "string", "enum": ["terrain"]}
	terrain_properties["id"] = {"type": "string", "min_length": 1}
	# Exactly one character, or a `map_data` grid row cannot be read char by char.
	terrain_properties["grid_char"] = {"type": "string", "min_length": 1, "max_length": 1}
	# Costs are keyed by movement type, so the desert rule (mounts and armour bog
	# down, the light-footed slip through) and the flier's flat 1 are authored cells
	# rather than engine branches. A partial map retunes only the types it names.
	# Cost 0 would make a tile free to cross, which pathfinding does not admit.
	terrain_properties["move_costs"] = {
		"type": "object",
		"key_vocabulary": "movement_type",
		"additional_properties": {"type": "integer", "minimum": 1},
	}
	terrain_properties["def_bonus"] = nonnegative_int
	terrain_properties["avoid_bonus"] = nonnegative_int
	# A share of max HP restored per phase; 0.0 for terrain that does not heal. This
	# is what replaced `TurnManager`'s literal `== "fort"` test.
	terrain_properties["heal_fraction"] = {"type": "number", "minimum": 0.0, "maximum": 1.0}
	# Resolved against the pack's asset registries by the same MEDIA_REFERENCE_FIELDS
	# table class/weapon/item icons use. Since [TER-2] this is what the renderer
	# actually paints an introduced terrain with, not just a reference held for later.
	terrain_properties["tile_asset_id"] = {"type": "string"}
	terrain_properties["field_completeness"] = completeness_map
	(
		registry
		. register_schema(
			"terrain",
			1,
			{
				"required": ["kind", "schema_version", "id", "display_name", "source_refs"],
				"properties": terrain_properties,
			}
		)
	)
	# A decorative variant ([TER-1]): a second grid char pointing at an existing
	# terrain's stat block, with its own art and label. This is the shape that answers
	# RULE-011/AWR-8 — a throne is a variant of fort, not a terrain of its own — so the
	# id-matching consumers (`GridManager.get_terrain_at`, AI scoring, tags, tests) all
	# keep seeing "fort".
	#
	# Deliberately carries NO stats. A variant that could set `def_bonus` would be a
	# second terrain wearing a variant's name, and the hand-synced duplicate stat blocks
	# the six-table consolidation removed would be back one layer up.
	var terrain_variant_properties := document_header.duplicate(true)
	terrain_variant_properties["kind"] = {"type": "string", "enum": ["terrain_variant"]}
	terrain_variant_properties["id"] = {"type": "string", "min_length": 1}
	# The terrain whose stat block this variant shares. Left open rather than bound to
	# a vocabulary because a pack may introduce both the terrain and its variants;
	# `TerrainRegistry.collect_coherence_errors` resolves the reference once every
	# document is applied, which is the only point at which it can be answered.
	terrain_variant_properties["terrain"] = {"type": "string", "min_length": 1}
	terrain_variant_properties["grid_char"] = {"type": "string", "min_length": 1, "max_length": 1}
	terrain_variant_properties["tile_asset_id"] = {"type": "string"}
	terrain_variant_properties["field_completeness"] = completeness_map
	(
		registry
		. register_schema(
			"terrain_variant",
			1,
			{
				"required":
				["kind", "schema_version", "id", "display_name", "terrain", "source_refs"],
				"properties": terrain_variant_properties,
			}
		)
	)
	# Seeded from the engine's own single source rather than restated: the movement
	# types every cost column is keyed by. Adding one is a change at its owner, not in
	# this file. (`terrain_id` is no longer a closed vocabulary — see the note above.)
	registry.register_vocabulary("movement_type", GameConstants.VALID_MOVEMENT_TYPES)

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
				field_schema.has("max_length")
				and String(value).length() > int(field_schema["max_length"])
			):
				# Fixed-width strings: a map grid char must be exactly one character or
				# the row cannot be indexed char by char.
				errors.append(_error("value_too_long", path, "String value is too long."))
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
			# Fixed-width arrays (a [x, y] tile, an [r, g, b, a] colour) need an upper
			# bound too, or a third coordinate would be silently discarded by the adapter.
			if field_schema.has("max_items") and value.size() > int(field_schema["max_items"]):
				errors.append(_error("array_too_long", path, "Array has too many entries."))
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
		"number":
			# A genuinely fractional value (a colour channel). Distinct from "integer",
			# which accepts JSON's float encoding but requires an integral value.
			if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
				errors.append(_error("type_mismatch", path, "Value must be a number."))
			elif field_schema.has("minimum") and float(value) < float(field_schema["minimum"]):
				errors.append(_error("value_too_small", path, "Number value is below the minimum."))
			elif field_schema.has("maximum") and float(value) > float(field_schema["maximum"]):
				# Bounded fractions (a heal fraction is a share of max HP, never 3x it).
				errors.append(_error("value_too_large", path, "Number value is above the maximum."))
		"integer":
			if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
				errors.append(_error("type_mismatch", path, "Value must be an integer."))
			elif int(value) != value:
				errors.append(_error("type_mismatch", path, "Value must be an integer."))
			elif field_schema.has("minimum") and int(value) < int(field_schema["minimum"]):
				errors.append(
					_error("value_too_small", path, "Integer value is below the minimum.")
				)
			elif field_schema.has("maximum") and int(value) > int(field_schema["maximum"]):
				errors.append(
					_error("value_too_large", path, "Integer value is above the maximum.")
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
	var magic_tracks: Array[String] = ["elemental_magic", "light", "dark"]
	if wexp_track in magic_tracks and not bool(document.get("uses_mag", false)):
		(
			errors
			. append(
				_error(
					"magic_weapon_requires_uses_mag",
					"%s.uses_mag" % root_path,
					"A weapon on a magic WEXP track must set uses_mag to true.",
				)
			)
		)
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


func _validate_item_contract(
	document: Dictionary, root_path: String, errors: Array[Dictionary]
) -> void:
	# Same rule as weapons and inventory slots: -1 is infinite, any positive count is
	# finite, and 0 is an item that can never be used.
	if document.has("uses") and int(document["uses"]) == 0:
		errors.append(
			_error("item_uses_invalid", "%s.uses" % root_path, "Uses must be -1 or at least 1.")
		)

	# Parameters with no effect to configure are silently inert: the authored numbers
	# read as if they do something, and nothing ever consumes them.
	var parameters: Variant = document.get("effect_params", null)
	if (
		parameters is Dictionary
		and not parameters.is_empty()
		and String(document.get("effect_id", "")).is_empty()
	):
		errors.append(
			_error(
				"item_effect_params_without_effect",
				"%s.effect_params" % root_path,
				"Effect parameters require an effect_id to configure."
			)
		)


func _validate_asset_registry_contract(
	document: Dictionary, root_path: String, errors: Array[Dictionary]
) -> void:
	var assets: Variant = document.get("assets", {})
	if not assets is Dictionary:
		return  # The schema pass already reported the mistyped assets map.
	for logical_id in assets:
		var record: Variant = assets[logical_id]
		if not record is Dictionary:
			continue
		var record_path := "%s.assets.%s" % [root_path, logical_id]
		var relative := String(record.get("path", ""))
		var sidecar_relative := String(record.get("sidecar_path", ""))

		# One rule, one place: media lives under `assets/` with an admitted extension,
		# exactly as `CampaignArchivePreflight` already requires of any unindexed file
		# riding inside an archive. A registry that admitted a different shape would
		# let a pack pass validation and then fail preflight on export.
		if not _safe_pack_relative(relative):
			errors.append(
				_error(
					"asset_path_unsafe",
					"%s.path" % record_path,
					"Asset path must be a pack-relative path with no traversal."
				)
			)
		elif not relative.begins_with("assets/"):
			errors.append(
				_error(
					"asset_path_outside_assets",
					"%s.path" % record_path,
					"Media must live under 'assets/'."
				)
			)
		else:
			var extension := relative.get_extension().to_lower()
			if not MEDIA_TYPES_BY_EXTENSION.has(extension):
				errors.append(
					_error(
						"asset_extension_not_admitted",
						"%s.path" % record_path,
						(
							"'%s' is not an admitted Tier-1 media extension."
							% (extension if not extension.is_empty() else relative)
						)
					)
				)
			elif (
				record.has("decoded_type")
				and String(record["decoded_type"]) != MEDIA_TYPES_BY_EXTENSION[extension]
			):
				# A record whose declared type disagrees with its own extension is
				# ambiguous about which one the engine should believe, so neither is used.
				errors.append(
					_error(
						"asset_type_extension_mismatch",
						"%s.decoded_type" % record_path,
						(
							"Declared type '%s' is not the type of a '.%s' file."
							% [record["decoded_type"], extension]
						)
					)
				)

		if not sidecar_relative.is_empty():
			if not _safe_pack_relative(sidecar_relative):
				errors.append(
					_error(
						"asset_sidecar_path_unsafe",
						"%s.sidecar_path" % record_path,
						"Asset sidecar path must be pack-relative with no traversal."
					)
				)
			elif not sidecar_relative.begins_with("assets/"):
				errors.append(
					_error(
						"asset_sidecar_outside_assets",
						"%s.sidecar_path" % record_path,
						"Asset sidecar JSON must live under 'assets/'."
					)
				)
			elif sidecar_relative.get_extension().to_lower() != "json":
				errors.append(
					_error(
						"asset_sidecar_not_json",
						"%s.sidecar_path" % record_path,
						"Asset sidecar must be a JSON file."
					)
				)

		# The integrity fields are generated, so a malformed digest means the record was
		# hand-edited. The bytes themselves are compared by the pack-root integrity pass.
		var digest := String(record.get("sha256", ""))
		if not digest.is_empty() and not _is_lowercase_sha256(digest):
			errors.append(
				_error(
					"asset_sha256_malformed",
					"%s.sha256" % record_path,
					"SHA-256 must be 64 lowercase hexadecimal characters."
				)
			)


# Verifies that each asset record describes the file actually present at `path`.
# Kept separate from the schema pass because it needs the pack root on disk, which
# `validate_document` deliberately does not take.
static func collect_asset_integrity_errors(
	document: Dictionary, pack_root: String
) -> Array[Dictionary]:
	var errors: Array[Dictionary] = []
	var assets: Variant = document.get("assets", {})
	if not assets is Dictionary:
		return errors
	var root_path := "$[asset_registry@1:%s]" % String(document.get("id", "<unknown>"))
	for logical_id in assets:
		var record: Variant = assets[logical_id]
		if not record is Dictionary:
			continue
		var record_path := "%s.assets.%s" % [root_path, logical_id]
		var relative := String(record.get("path", ""))
		if relative.is_empty() or not _safe_pack_relative(relative):
			continue  # The contract pass owns malformed paths.
		var absolute := pack_root.trim_suffix("/").path_join(relative)
		if not FileAccess.file_exists(absolute):
			errors.append(
				_error(
					"asset_file_missing",
					"%s.path" % record_path,
					"No file exists at '%s'." % relative
				)
			)
			continue
		var bytes := FileAccess.get_file_as_bytes(absolute)
		if record.has("byte_size") and int(record["byte_size"]) != bytes.size():
			errors.append(
				_error(
					"asset_byte_size_mismatch",
					"%s.byte_size" % record_path,
					(
						"Record declares %d bytes but the file holds %d."
						% [int(record["byte_size"]), bytes.size()]
					)
				)
			)
		var digest := String(record.get("sha256", ""))
		if not digest.is_empty() and digest != FileAccess.get_sha256(absolute):
			errors.append(
				_error(
					"asset_sha256_mismatch",
					"%s.sha256" % record_path,
					"The file's SHA-256 does not match the recorded digest."
				)
			)
		var declared_type := String(record.get("decoded_type", ""))
		if (
			MEDIA_MAGIC_BY_TYPE.has(declared_type)
			and not _has_magic(bytes, MEDIA_MAGIC_BY_TYPE[declared_type])
		):
			errors.append(
				_error(
					"asset_content_type_mismatch",
					"%s.decoded_type" % record_path,
					"File contents are not a '%s'." % declared_type
				)
			)
		var sidecar_relative := String(record.get("sidecar_path", ""))
		if not sidecar_relative.is_empty() and _safe_pack_relative(sidecar_relative):
			var sidecar_absolute := pack_root.trim_suffix("/").path_join(sidecar_relative)
			if not FileAccess.file_exists(sidecar_absolute):
				errors.append(
					_error(
						"asset_sidecar_missing",
						"%s.sidecar_path" % record_path,
						"No sidecar file exists at '%s'." % sidecar_relative
					)
				)
	return errors


static func _has_magic(bytes: PackedByteArray, magic: Array) -> bool:
	if bytes.size() < magic.size():
		return false
	for index in magic.size():
		if bytes[index] != int(magic[index]):
			return false
	return true


static func _is_lowercase_sha256(value: String) -> bool:
	if value.length() != 64:
		return false
	for index in value.length():
		var character := value[index]
		if (
			not (character >= "0" and character <= "9")
			and not (character >= "a" and character <= "f")
		):
			return false
	return true


static func _safe_pack_relative(path: String) -> bool:
	if path.is_empty() or "\\" in path:
		return false
	if path.is_absolute_path() or path.begins_with("res://") or path.begins_with("user://"):
		return false
	for part in path.split("/"):
		if part in ["", ".", ".."]:
			return false
	return true


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
			if not entry is Dictionary:
				continue
			var slot_path := "%s.inventory[%d]" % [unit_path, slot]
			# Same rule as the weapon contract: -1 is infinite and any positive count is
			# finite, but a slot authored with 0 uses is a weapon that can never be swung.
			if entry.has("uses") and int(entry["uses"]) == 0:
				errors.append(
					_error(
						"inventory_uses_invalid",
						"%s.uses" % slot_path,
						"Inventory uses must be -1 or at least 1."
					)
				)

			# `InventoryEntry` keys its whole behaviour off one entry_type, so a slot
			# naming both a weapon and an item has no single answer for what it holds,
			# and a slot naming neither builds an entry the runtime discards.
			var has_weapon := not String(entry.get("weapon_id", "")).is_empty()
			var has_item := not String(entry.get("item_id", "")).is_empty()
			if has_weapon and has_item:
				errors.append(
					_error(
						"inventory_slot_ambiguous",
						slot_path,
						"An inventory slot holds either a weapon or an item, not both."
					)
				)
			elif not has_weapon and not has_item:
				errors.append(
					_error(
						"inventory_slot_empty",
						slot_path,
						"An inventory slot must name a weapon or an item."
					)
				)

			# A weapon variant selects a variant of a weapon; on an item slot it names
			# a document the slot does not hold.
			if has_item and not String(entry.get("weapon_variant_id", "")).is_empty():
				errors.append(
					_error(
						"inventory_variant_on_item",
						"%s.weapon_variant_id" % slot_path,
						"An item slot cannot select a weapon variant."
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
