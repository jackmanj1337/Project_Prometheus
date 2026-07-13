extends Node

const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")
const ResourceManifest = preload("res://scripts/shared/ResourceManifest.gd")

const PRESET_DIRECTORIES: Array[String] = [
	"res://data/registries/action_primitives/",
	"res://data/registries/resource_types/",
	"res://data/registries/occupancy_policies/",
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
]

var _catalog: RefCounted
var _load_errors: Array[String] = []


func _ready() -> void:
	reload_presets()
	for error in _load_errors:
		push_error(error)


func reload_presets() -> Array[String]:
	_catalog = RegistryCatalogScript.new()
	_load_errors.clear()
	for handler_id in BUILTIN_PRIMITIVE_HANDLERS:
		_load_errors.append_array(_catalog.register_primitive_handler(handler_id))
	for directory in PRESET_DIRECTORIES:
		for path in ResourceManifest.load_paths(directory):
			var resource := ResourceLoader.load(path)
			if resource == null or resource.get_script() != RegistryEntryScript:
				_load_errors.append("RegistryManager: '%s' is not a RegistryEntry" % path)
				continue
			for error in _catalog.register_entry(resource):
				_load_errors.append("RegistryManager: %s (%s)" % [error, path])
	return _load_errors.duplicate()


func has_entry(family: String, id: String) -> bool:
	return _catalog != null and _catalog.has_entry(family, id)


func entry(family: String, id: String):
	if _catalog == null:
		return null
	return _catalog.entry(family, id)


func ids(family: String) -> Array[String]:
	if _catalog == null:
		return []
	return _catalog.ids(family)


func load_errors() -> Array[String]:
	return _load_errors.duplicate()
