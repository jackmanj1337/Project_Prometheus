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
	"rout", "defeat_boss", "seize", "escape", "survive", "protect", "turn_limit",
	"heal_flat", "heal_full", "promote", "reclass", "stat_buff",
]

var _catalog: RefCounted
var _load_errors: Array[String] = []


func _ready() -> void:
	reload_presets()
	for error in _load_errors:
		push_error(error)


func reload_presets(source: String = DEFAULT_CONTENT_SOURCE) -> Array[String]:
	_catalog = RegistryCatalogScript.new()
	_load_errors.clear()
	for handler_id in BUILTIN_PRIMITIVE_HANDLERS:
		_load_errors.append_array(_catalog.register_primitive_handler(handler_id))
	for family in REQUIRED_FAMILIES:
		var directory := source.path_join("registries").path_join(family)
		for path in ResourceManifest.load_paths(directory):
			var resource := ResourceLoader.load(path)
			if resource == null or resource.get_script() != RegistryEntryScript:
				_load_errors.append("RegistryManager: '%s' is not a RegistryEntry" % path)
				continue
			for error in _catalog.register_entry(resource):
				_load_errors.append("RegistryManager: %s (%s)" % [error, path])
		if _catalog.ids(family).is_empty():
			_load_errors.append("RegistryManager: source '%s' has no valid entries for required family '%s'" % [
				source, family])
	return _load_errors.duplicate()


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
