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
	_summaries.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var a_key := "%s\n%s" % [a["package_id"], a["package_version"]]
			var b_key := "%s\n%s" % [b["package_id"], b["package_version"]]
			return a_key < b_key
	)
	return summaries()


func summaries() -> Array[Dictionary]:
	return _summaries.duplicate(true)


func errors() -> Array[String]:
	return _errors.duplicate()


func find(package_id: String, package_version: String) -> Dictionary:
	for summary in _summaries:
		if summary["package_id"] == package_id and summary["package_version"] == package_version:
			return summary.duplicate(true)
	return {}


func playable_campaign_count() -> int:
	var count := 0
	for summary in _summaries:
		for campaign in summary.get("campaigns", []):
			if not bool(campaign.get("is_dev_only", false)):
				count += 1
	return count


static func installed_path(
	storage_root: String, package_id: String, package_version: String
) -> String:
	return storage_root.trim_suffix("/").path_join(INSTALLED_DIR).path_join(package_id).path_join(
		package_version
	)


func _discover_candidate(path: String, directory_id: String, directory_version: String) -> void:
	var manifest_errors: Array[String] = []
	var manifest_raw: Variant = _read_json(path.path_join(MANIFEST_PATH), manifest_errors)
	var manifest: PackManifest = null
	if manifest_raw != null:
		manifest = PackManifest.parse(manifest_raw, MANIFEST_PATH, manifest_errors)
	if manifest == null:
		_append_candidate_errors(path, manifest_errors)
		return
	if manifest.id != directory_id or manifest.version != directory_version:
		_errors.append(
			(
				"CampaignPackRegistry(%s): installed path identity does not match manifest '%s/%s'"
				% [path, manifest.id, manifest.version]
			)
		)
		return

	var catalogue_errors: Array[String] = []
	var catalogue := Tier2Catalogue.load_campaign_pack(path, catalogue_errors)
	if catalogue == null:
		_append_candidate_errors(path, catalogue_errors)
		return
	var destination_fingerprint := catalogue.content_fingerprint()
	for index in manifest.save_migrations.size():
		var destination: Dictionary = SaveMigrationService._declaration_destination(
			manifest.save_migrations[index]
		)
		# Only an edge that terminates on THIS release can be checked against
		# this catalogue. An intermediate edge names a superseded version whose
		# content is not installed and is verified instead by the chain: its
		# destination must be the next edge's source, and only the last edge's
		# destination is compared to the content a load will actually run on.
		if String(destination["package_version"]) != manifest.version:
			continue
		if (
			int(destination["content_schema_version"]) != catalogue.format_version
			or String(destination["content_fingerprint"]) != destination_fingerprint
		):
			(
				_errors
				. append(
					(
						"CampaignPackRegistry(%s): save_migrations[%d] destination content identity does not match catalogue"
						% [path, index]
					)
				)
			)
			return
	var campaigns: Array[Dictionary] = []
	var content_ids := {
		"campaign": {},
		"campaign_node": {},
		"map": {},
		"unit": {},
		"map_unit": {},
		"item": {},
		"class": {},
		"skill": {},
	}
	var campaign_ids := {}
	for entry in catalogue.entries:
		var entry_kind := String(entry["kind"])
		if content_ids.has(entry_kind):
			content_ids[entry_kind][String(entry["id"])] = true
		if entry_kind == "weapon":
			content_ids["item"][String(entry["id"])] = true
		if entry_kind == "map_data":
			var map_id := String(entry["id"])
			content_ids["map"][map_id] = true
			var map_document: Variant = catalogue.get_document("map_data", map_id)
			if map_document is Dictionary:
				for placement in map_document.get("enemy_placements", []):
					if not placement is Dictionary or not placement.get("unit", {}) is Dictionary:
						continue
					var unit_id := String(placement["unit"].get("unit_id", ""))
					if unit_id.is_empty():
						continue
					content_ids["map_unit"]["%s#%s" % [map_id, unit_id]] = true
					content_ids["map_unit"]["campaign-pack://%s/%s/%s#%s" % [manifest.id, manifest.version, map_id, unit_id]] = true
		if entry_kind == "roster":
			var roster: Variant = catalogue.get_document("roster", entry["id"])
			if roster is Dictionary:
				for unit in roster.get("units", []):
					if unit is Dictionary:
						content_ids["unit"][String(unit.get("unit_id", ""))] = true
		if entry["kind"] != "campaign":
			continue
		var document: Dictionary = catalogue.get_document("campaign", entry["id"])
		content_ids["campaign"][String(entry["id"])] = true
		for node in document.get("nodes", []):
			if node is Dictionary:
				content_ids["campaign_node"][String(node.get("node_id", ""))] = true
		(
			campaigns
			. append(
				{
					"campaign_id": String(entry["id"]),
					"label": String(document.get("label", entry["id"])),
					"author_id": String(document.get("author_id", manifest.id)),
					"campaign_version": String(document.get("campaign_version", "1.0.0")),
					"compatible_status_sources":
					(
						document.get("compatible_status_sources", []).duplicate(true)
						if document.get("compatible_status_sources", []) is Array
						else []
					),
					"rules":
					(
						document.get("rules", {}).duplicate(true)
						if document.get("rules", {}) is Dictionary
						else {}
					),
				}
			)
		)
		campaign_ids[String(entry["id"])] = true
	for entry in catalogue.entries:
		if entry["kind"] != "map_registry":
			continue
		var map_registry_document: Variant = catalogue.get_document("map_registry", entry["id"])
		# Registered map documents wrap their rows in `entries`; retain the legacy
		# array form until compatibility content is removed from the engine build.
		var map_entries: Array = (
			map_registry_document.get("entries", [])
			if map_registry_document is Dictionary
			else map_registry_document
		)
		for map_entry in map_entries:
			var map_id := String(map_entry.get("id", ""))
			var synthetic_id := CampaignData.single_map_campaign_id(map_id)
			if map_id.is_empty() or campaign_ids.has(synthetic_id):
				continue
			(
				campaigns
				. append(
					{
						"campaign_id": synthetic_id,
						"label": String(map_entry.get("label", map_id)),
						"rules": {},
						"is_dev_only": bool(map_entry.get("is_dev_only", false)),
					}
				)
			)
	campaigns.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return a["campaign_id"] < b["campaign_id"]
	)
	(
		_summaries
		. append(
			{
				"package_id": manifest.id,
				"package_version": manifest.version,
				"content_schema_version": catalogue.format_version,
				"content_fingerprint": destination_fingerprint,
				"builder_content_version": manifest.builder_content_version,
				"forked_from": manifest.forked_from,
				"save_migrations": manifest.save_migrations.duplicate(true),
				"path": path,
				"campaigns": campaigns,
				"content_ids": content_ids,
			}
		)
	)


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
