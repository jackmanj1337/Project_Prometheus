extends Node

const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")
const ResourceManifest = preload("res://scripts/shared/ResourceManifest.gd")

const DEFAULT_CONTENT_SOURCE := "res://engine_data"
const REQUIRED_FAMILIES := RegistryCatalogScript.REQUIRED_FAMILIES
const OPTIONAL_FAMILIES := RegistryCatalogScript.OPTIONAL_FAMILIES
const BUILTIN_PRIMITIVE_HANDLERS := RegistryCatalogScript.BUILTIN_PRIMITIVE_HANDLERS

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
	var entries: Array[Resource] = []
	var load_errors: Array[String] = []
	for family in REQUIRED_FAMILIES + OPTIONAL_FAMILIES:
		var directory := source.path_join("registries").path_join(family)
		for path in ResourceManifest.load_paths(directory):
			var resource := ResourceLoader.load(path)
			if resource == null or not resource is RegistryEntry:
				load_errors.append("RegistryManager: '%s' is not a RegistryEntry" % path)
				continue
			entries.append(resource)
	var candidate := build_candidate_from_entries(entries, source)
	(candidate["errors"] as Array).append_array(load_errors)
	return candidate


func build_candidate_from_entries(entries: Array[Resource], source: String) -> Dictionary:
	var catalog = RegistryCatalogScript.new()
	var errors: Array[String] = []
	for handler_id in BUILTIN_PRIMITIVE_HANDLERS:
		errors.append_array(catalog.register_primitive_handler(handler_id))
	for resource in entries:
		for error in catalog.register_entry(resource):
			errors.append("RegistryManager: %s (%s)" % [error, source])
	for family in REQUIRED_FAMILIES:
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
		# Record why the commit was refused. This used to return false while leaving
		# _load_errors untouched, so a caller that reported load_errors() on failure
		# printed the PREVIOUS state's errors — in practice an empty list, i.e. a
		# failure with no stated cause.
		_load_errors = errors.duplicate()
		if _load_errors.is_empty():
			_load_errors.append("RegistryManager: candidate has no catalogue")
		return false
	_catalog = candidate["catalog"]
	_load_errors.clear()
	return true


# Registry catalogues participate in DataManager's content-session transaction.
# The catalogue is immutable after commit, so retaining its reference is enough
# to restore the exact prior vocabulary without rebuilding from disk.
func capture_snapshot() -> Dictionary:
	return {"catalog": _catalog, "errors": _load_errors.duplicate()}


func restore_snapshot(snapshot: Dictionary) -> void:
	_catalog = snapshot.get("catalog")
	_load_errors.clear()
	for error in snapshot.get("errors", []):
		_load_errors.append(String(error))


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
