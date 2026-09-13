class_name CampaignPackRegistry extends RefCounted
# Read-only discovery/cache for installed campaign packs. Discovery validates
# every candidate but never activates content or mutates installed bytes.
#
# THE INSTALLED IDENTITY IS id | version | content_fingerprint.
# It used to be id | version, which is coarser than the identity a save is validated
# against, and that gap decided two consecutive playtest rounds (V0716-03, then
# V0717-01): two builds shipped under one version number could not coexist, so a
# backup's package was silently skipped and every save it carried became unopenable.
#
# TWO LAYOUTS LIVE UNDER installed/. A release now sits at
#   installed/<package_id>/<package_version>/<fingerprint>/
# where <fingerprint> is the first FINGERPRINT_DIR_DIGITS hex digits of the content
# fingerprint, so the version directory is a CONTAINER for the builds published under
# that version number rather than a release itself. Libraries written before this
# change keep their release directly at installed/<package_id>/<package_version>/, and
# discovery reads that shape unchanged — an existing library is never rewritten just by
# being read. `CampaignPackInstaller` relocates such a release into its own fingerprint
# directory the first time something is installed beside it.

const INSTALLED_DIR := "installed"
const MANIFEST_PATH := "manifest.json"
const DEFAULT_STORAGE_ROOT := "user://campaign_packs"

# Long enough that a collision between two real builds is not a practical concern, and
# short enough to keep installed paths readable on Windows. Discovery does not trust it
# either way: a candidate whose directory name disagrees with the fingerprint its own
# catalogue produces is reported as an error rather than read as that identity.
const FINGERPRINT_DIR_DIGITS := 16
const FINGERPRINT_PREFIX := "sha256:"

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
			var version_root := identity_root.path_join(version)
			# A manifest directly under the version directory is the pre-fingerprint
			# layout: that directory IS the release. Otherwise it is a container and
			# each child is one build.
			if FileAccess.file_exists(version_root.path_join(MANIFEST_PATH)):
				_discover_candidate(version_root, package_id, version, "")
				continue
			for fingerprint_name in _directory_names(version_root):
				_discover_candidate(
					version_root.path_join(fingerprint_name), package_id, version, fingerprint_name
				)
	# Fingerprint joins the sort key because it is now part of the identity: without it
	# two builds of one version would order arbitrarily, and every caller that walks
	# summaries would see them in whatever order the filesystem listed.
	_summaries.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var a_key := (
				"%s\n%s\n%s" % [a["package_id"], a["package_version"], a["content_fingerprint"]]
			)
			var b_key := (
				"%s\n%s\n%s" % [b["package_id"], b["package_version"], b["content_fingerprint"]]
			)
			return a_key < b_key
	)
	return summaries()


func summaries() -> Array[Dictionary]:
	return _summaries.duplicate(true)


func errors() -> Array[String]:
	return _errors.duplicate()


# Kept for callers that only have the coarse identity to ask with. It answers with the
# FIRST build published under that version, which is the right answer only when there
# is one: anything comparing content must ask `find_identity` or read `find_all`.
func find(package_id: String, package_version: String) -> Dictionary:
	for summary in _summaries:
		if summary["package_id"] == package_id and summary["package_version"] == package_version:
			return summary.duplicate(true)
	return {}


# The whole identity. An empty fingerprint matches nothing rather than matching the
# first build, because "I do not know which content" is not the same question.
func find_identity(
	package_id: String, package_version: String, content_fingerprint: String
) -> Dictionary:
	if content_fingerprint.is_empty():
		return {}
	for summary in _summaries:
		if (
			summary["package_id"] == package_id
			and summary["package_version"] == package_version
			and summary["content_fingerprint"] == content_fingerprint
		):
			return summary.duplicate(true)
	return {}


# Every build published under one version number, in discovery order. Empty means
# nothing readable is installed there — which is not the same as nothing being there,
# and callers that overwrite need to tell those apart.
func find_all(package_id: String, package_version: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for summary in _summaries:
		if summary["package_id"] == package_id and summary["package_version"] == package_version:
			found.append(summary.duplicate(true))
	return found


func playable_campaign_count() -> int:
	var count := 0
	for summary in _summaries:
		for campaign in summary.get("campaigns", []):
			if not bool(campaign.get("is_dev_only", false)):
				count += 1
	return count


# The container for every build published under one version number. This is where a
# pre-fingerprint library put the release itself, so the name is unchanged and callers
# that only need "is anything installed under this id and version" still read correctly.
static func installed_path(
	storage_root: String, package_id: String, package_version: String
) -> String:
	return storage_root.trim_suffix("/").path_join(INSTALLED_DIR).path_join(package_id).path_join(
		package_version
	)


# Where one BUILD lives. Pure string arithmetic, so it names a path whether or not
# anything is there; `resolve_installed_path` is the one that looks.
static func build_path(
	storage_root: String, package_id: String, package_version: String, content_fingerprint: String
) -> String:
	var directory := fingerprint_dir(content_fingerprint)
	if directory.is_empty():
		return ""
	return installed_path(storage_root, package_id, package_version).path_join(directory)


# The directory-name form of a content fingerprint. Empty for anything that is not a
# well-formed sha256 fingerprint, so a malformed value can never be turned into a path.
static func fingerprint_dir(content_fingerprint: String) -> String:
	if not content_fingerprint.begins_with(FINGERPRINT_PREFIX):
		return ""
	var digest := content_fingerprint.substr(FINGERPRINT_PREFIX.length())
	if digest.length() < FINGERPRINT_DIR_DIGITS:
		return ""
	for character in digest:
		if not character in "0123456789abcdef":
			return ""
	return digest.left(FINGERPRINT_DIR_DIGITS)


# The installed directory a save should be loaded from, by disk probe rather than by
# full discovery: `refresh()` parses every installed catalogue, and this runs on the
# load path where the answer is one directory lookup.
#
# The requested content wins when it is installed. When it is not, this still answers
# with whatever IS installed under that id and version, so the caller reaches its own
# fingerprint comparison and reports a mismatch — the diagnosis the player needs —
# instead of the package looking absent. Returns "" only when nothing is there.
static func resolve_installed_path(
	storage_root: String,
	package_id: String,
	package_version: String,
	content_fingerprint: String = ""
) -> String:
	var version_root := installed_path(storage_root, package_id, package_version)
	if not DirAccess.dir_exists_absolute(version_root):
		return ""
	var directory := fingerprint_dir(content_fingerprint)
	if not directory.is_empty():
		var exact := version_root.path_join(directory)
		if FileAccess.file_exists(exact.path_join(MANIFEST_PATH)):
			return exact
	if FileAccess.file_exists(version_root.path_join(MANIFEST_PATH)):
		return version_root
	for name in _directory_names(version_root):
		var candidate := version_root.path_join(name)
		if FileAccess.file_exists(candidate.path_join(MANIFEST_PATH)):
			return candidate
	return ""


func _discover_candidate(
	path: String, directory_id: String, directory_version: String, directory_fingerprint: String
) -> void:
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
	# The directory name is part of the identity, so it is checked against the content
	# exactly as the manifest's id and version are. Reading a build as an identity its
	# own bytes do not produce is how the coarse identity failed in the first place.
	if (
		not directory_fingerprint.is_empty()
		and directory_fingerprint != fingerprint_dir(destination_fingerprint)
	):
		_errors.append(
			(
				"CampaignPackRegistry(%s): installed path identity does not match content '%s'"
				% [path, destination_fingerprint]
			)
		)
		return
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
