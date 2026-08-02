extends Node

const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")
const ResourceManifest = preload("res://scripts/shared/ResourceManifest.gd")

const DEFAULT_CONTENT_SOURCE := "res://data"
const REQUIRED_FAMILIES: Array[String] = [
	"action_primitives",
	"resource_types",
	"occupancy_policies",
	"objective_conditions",
	"item_effects",
]
const BUILTIN_PRIMITIVE_HANDLERS: Array[String] = [
	"apply_active_modifier",
	"party_gold_wallet",
	"unit_gold_wallet",
	"require_empty_placement",
	"nearest_free_placement",
	"delay_placement",
	"skip_placement",
	"unimplemented_placement",
	"rout",
	"defeat_boss",
	"seize",
	"escape",
	"survive",
	"protect",
	"turn_limit",
	"heal_flat",
	"heal_full",
	"promote",
	"reclass",
	"stat_buff",
]

var _catalog: RefCounted
var _load_errors: Array[String] = []


func _ready() -> void:
	deactivate()


func reload_presets(source: String = DEFAULT_CONTENT_SOURCE) -> Array[String]:
	var candidate: Dictionary = build_candidate(source)
	# Legacy diagnostic seam: direct callers intentionally inspect a partial
	# catalogue. Atomic source activation uses build_candidate + commit_candidate.
	_catalog = candidate["catalog"]
	_load_errors = candidate["errors"]
	return _load_errors.duplicate()


# Builds a complete catalogue without touching live state. DataManager composes
# this with its own candidate so one invalid registry family cannot leave half of
# a content source active.
func build_candidate(source: String) -> Dictionary:
	var catalog = RegistryCatalogScript.new()
	var errors: Array[String] = []
	for handler_id in BUILTIN_PRIMITIVE_HANDLERS:
		errors.append_array(catalog.register_primitive_handler(handler_id))
	for family in REQUIRED_FAMILIES:
		var directory := source.path_join("registries").path_join(family)
		for path in ResourceManifest.load_paths(directory):
			var resource := ResourceLoader.load(path)
			if resource == null or resource.get_script() != RegistryEntryScript:
				errors.append("RegistryManager: '%s' is not a RegistryEntry" % path)
				continue
			for error in catalog.register_entry(resource):
				errors.append("RegistryManager: %s (%s)" % [error, path])
		if catalog.ids(family).is_empty():
			errors.append(
				(
					"RegistryManager: source '%s' has no valid entries for required family '%s'"
					% [source, family]
				)
			)
	return {"catalog": catalog, "errors": errors}


func commit_candidate(candidate: Dictionary) -> bool:
	var errors: Array[String] = candidate.get("errors", [])
	if not errors.is_empty() or candidate.get("catalog") == null:
		return false
	_catalog = candidate["catalog"]
	_load_errors.clear()
	return true


func deactivate() -> void:
	_catalog = RegistryCatalogScript.new()
	_load_errors.clear()
	for handler_id in BUILTIN_PRIMITIVE_HANDLERS:
		_load_errors.append_array(_catalog.register_primitive_handler(handler_id))


# Tier-2 packages currently contribute campaign data, not registry entries. Keep
# engine-owned policies available while package content is active without
# implying that package registries have been composed into the live catalogue.
func activate_engine_baseline() -> bool:
	return commit_candidate(build_candidate(DEFAULT_CONTENT_SOURCE))


func has_entry(family: String, id: String) -> bool:
	return _catalog != null and _catalog.has_entry(family, id)


func entry(family: String, id: String) -> Resource:
	if _catalog == null:
		return null
	return _catalog.entry(family, id)


func ids(family: String) -> Array[String]:
	if _catalog == null:
		return []
	return _catalog.ids(family)


func load_errors() -> Array[String]:
	return _load_errors.duplicate()
