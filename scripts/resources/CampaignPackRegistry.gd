class_name CampaignPackRegistry extends RefCounted
# Read-only discovery/cache for installed campaign packs. Discovery validates
# every candidate but never activates content or mutates installed bytes.

const INSTALLED_DIR := "installed"
const MANIFEST_PATH := "manifest.json"
const DEFAULT_STORAGE_ROOT := "user://campaign_packs"

var _storage_root: String
var _summaries: Array[Dictionary] = []
var _errors: Array[String] = []


func _init(storage_root: String) -> void:
	_storage_root = storage_root.trim_suffix("/")


func refresh() -> Array[Dictionary]:
	_summaries.clear()
	_errors.clear()
	var installed_root := _storage_root.path_join(INSTALLED_DIR)
	if not DirAccess.dir_exists_absolute(installed_root):
		return []
	for package_id in _directory_names(installed_root):
		var identity_root := installed_root.path_join(package_id)
		for version in _directory_names(identity_root):
			_discover_candidate(identity_root.path_join(version), package_id, version)
	_summaries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := "%s\n%s" % [a["package_id"], a["package_version"]]
		var b_key := "%s\n%s" % [b["package_id"], b["package_version"]]
		return a_key < b_key)
	return summaries()


func summaries() -> Array[Dictionary]:
	return _summaries.duplicate(true)


func errors() -> Array[String]:
	return _errors.duplicate()


func find(package_id: String, package_version: String) -> Dictionary:
	for summary in _summaries:
		if summary["package_id"] == package_id \
				and summary["package_version"] == package_version:
			return summary.duplicate(true)
	return {}


static func installed_path(storage_root: String, package_id: String,
		package_version: String) -> String:
	return storage_root.trim_suffix("/").path_join(INSTALLED_DIR) \
		.path_join(package_id).path_join(package_version)


func _discover_candidate(path: String, directory_id: String,
		directory_version: String) -> void:
	var manifest_errors: Array[String] = []
	var manifest_raw: Variant = _read_json(path.path_join(MANIFEST_PATH), manifest_errors)
	var manifest: PackManifest = null
	if manifest_raw != null:
		manifest = PackManifest.parse(manifest_raw, MANIFEST_PATH, manifest_errors)
	if manifest == null:
		_append_candidate_errors(path, manifest_errors)
		return
	if manifest.id != directory_id or manifest.version != directory_version:
		_errors.append("CampaignPackRegistry(%s): installed path identity does not match manifest '%s/%s'" % [
			path, manifest.id, manifest.version])
		return

	var catalogue_errors: Array[String] = []
	var catalogue := Tier2Catalogue.load_campaign_pack(path, catalogue_errors)
	if catalogue == null:
		_append_candidate_errors(path, catalogue_errors)
		return
	var campaigns: Array[Dictionary] = []
	for entry in catalogue.entries:
		if entry["kind"] != "campaign":
			continue
		var document: Dictionary = catalogue.get_document("campaign", entry["id"])
		campaigns.append({
			"campaign_id": String(entry["id"]),
			"label": String(document.get("label", entry["id"])),
		})
	campaigns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["campaign_id"] < b["campaign_id"])
	_summaries.append({
		"package_id": manifest.id,
		"package_version": manifest.version,
		"builder_content_version": manifest.builder_content_version,
		"forked_from": manifest.forked_from,
		"path": path,
		"campaigns": campaigns,
	})


func _append_candidate_errors(path: String, candidate_errors: Array[String]) -> void:
	if candidate_errors.is_empty():
		_errors.append("CampaignPackRegistry(%s): validation failed without details" % path)
		return
	for error in candidate_errors:
		_errors.append("CampaignPackRegistry(%s): %s" % [path, error])


static func _directory_names(path: String) -> Array[String]:
	var names: Array[String] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return names
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		if directory.current_is_dir() and name not in [".", ".."]:
			names.append(name)
		name = directory.get_next()
	directory.list_dir_end()
	names.sort()
	return names


static func _read_json(path: String, errors: Array[String]) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("cannot open manifest '%s'" % path)
		return null
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		errors.append("invalid manifest '%s': %s" % [path, json.get_error_message()])
		return null
	return json.data
