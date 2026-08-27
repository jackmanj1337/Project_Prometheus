class_name SaveMigrationService extends RefCounted
# Direct, declarative v1 migration for durable content references. All work is
# performed on a deep copy; callers commit only a fully validated result.

const FAMILIES: Array[String] = [
	"campaign", "campaign_node", "map", "unit", "item", "class", "skill"
]
const KEY_FAMILIES := {
	"campaign_id": "campaign",
	"node_id": "campaign_node",
	"map_id": "map",
	"unit_id": "unit",
	"item_id": "item",
	"weapon_id": "item",
	"class_id": "class",
	"class_variant_id": "class",
	"skill_id": "skill",
}
const ARRAY_FAMILIES := {
	"skills": "skill",
	"earned_skills": "skill",
	"mastery_skills": "skill",
	"cleared_nodes": "campaign_node",
	"discovered_units": "unit",
	"watch_set": "unit",
}

const STATUS_EXACT := "exact"
const STATUS_SUCCESSOR := "successor"
const STATUS_MISSING := "missing"
const STATUS_INCOMPATIBLE := "incompatible"
const STATUS_FINGERPRINT_MISMATCH := "fingerprint_mismatch"
const STATUS_INVALID := "invalid"


# Pure discovery result. Resolution never activates a pack or mutates the save;
# later load stages may act only on an exact or compatible-successor candidate.
class ResolutionResult:
	extends RefCounted
	var status := STATUS_INVALID
	var saved_identity: Dictionary = {}
	var candidate_identity: Dictionary = {}
	var installed_identities: Array[Dictionary] = []
	var errors: Array[String] = []

	func can_continue() -> bool:
		return status in [STATUS_EXACT, STATUS_SUCCESSOR]


static func resolve_source(source: Variant, installed_summaries: Array) -> ResolutionResult:
	var result := ResolutionResult.new()
	if not source is Dictionary:
		result.errors.append("save_source_invalid")
		return result
	result.saved_identity = _source_identity(source)
	if not _valid_source_identity(result.saved_identity):
		result.errors.append("save_source_identity_invalid")
		return result

	var same_package: Array[Dictionary] = []
	for raw_summary in installed_summaries:
		if not raw_summary is Dictionary:
			continue
		var identity := _installed_identity(raw_summary)
		if identity["package_id"] != result.saved_identity["package_id"]:
			continue
		same_package.append(identity)
	same_package.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return String(a["package_version"]) < String(b["package_version"])
	)
	result.installed_identities = same_package.duplicate(true)
	if same_package.is_empty():
		result.status = STATUS_MISSING
		return result

	for identity in same_package:
		if identity["package_version"] != result.saved_identity["package_version"]:
			continue
		result.candidate_identity = identity.duplicate(true)
		if identity["content_fingerprint"] != result.saved_identity["content_fingerprint"]:
			result.status = STATUS_FINGERPRINT_MISMATCH
		else:
			result.status = STATUS_EXACT
		return result

	for identity in same_package:
		var chain := plan_chain(
			result.saved_identity, identity, identity.get("save_migrations", [])
		)
		if chain["ok"]:
			result.status = STATUS_SUCCESSOR
			result.candidate_identity = identity.duplicate(true)
			return result
		result.errors.append_array(chain["errors"])
	result.status = STATUS_INCOMPATIBLE
	return result


static func _source_identity(source: Dictionary) -> Dictionary:
	return {
		"package_id": String(source.get("package_id", "")),
		"package_version": String(source.get("package_version", "")),
		"content_schema_version": int(source.get("content_schema_version", 0)),
		"content_fingerprint": String(source.get("content_fingerprint", "")),
		"campaign_id": String(source.get("campaign_id", "")),
	}


static func _valid_source_identity(identity: Dictionary) -> bool:
	var fingerprint := String(identity["content_fingerprint"])
	return (
		not String(identity["package_id"]).is_empty()
		and not String(identity["package_version"]).is_empty()
		and int(identity["content_schema_version"]) > 0
		and not String(identity["campaign_id"]).is_empty()
		and fingerprint.begins_with("sha256:")
		and fingerprint.length() == 71
	)


static func _installed_identity(summary: Dictionary) -> Dictionary:
	return {
		"package_id": String(summary.get("package_id", "")),
		"package_version": String(summary.get("package_version", "")),
		"content_schema_version": int(summary.get("content_schema_version", 0)),
		"content_fingerprint": String(summary.get("content_fingerprint", "")),
		"save_migrations":
		(
			summary.get("save_migrations", []).duplicate(true)
			if summary.get("save_migrations", []) is Array
			else []
		),
	}


static func plan_chain(
	source: Dictionary, destination: Dictionary, declarations: Variant
) -> Dictionary:
	var result := {"ok": false, "errors": [], "chain": []}
	if not declarations is Array:
		result["errors"].append("migration_chain_invalid")
		return result
	var edges := {}
	for declaration in declarations:
		var declaration_errors := validate_declaration(
			declaration, String(destination.get("package_id", ""))
		)
		if not declaration_errors.is_empty():
			result["errors"].append_array(declaration_errors)
			continue
		var key := _endpoint_key(_declaration_source(declaration))
		if edges.has(key):
			result["errors"].append("migration_chain_ambiguous:%s" % key)
		else:
			edges[key] = declaration
	if not result["errors"].is_empty():
		return result

	var cursor := _source_identity(source)
	var destination_identity := _source_identity(destination)
	var visited := {}
	while _endpoint_key(cursor) != _endpoint_key(destination_identity):
		var key := _endpoint_key(cursor)
		if visited.has(key):
			result["errors"].append("migration_chain_cycle:%s" % key)
			return result
		visited[key] = true
		if not edges.has(key):
			result["errors"].append("migration_chain_gap:%s" % key)
			return result
		var edge: Dictionary = edges[key]
		result["chain"].append(edge.duplicate(true))
		cursor = _declaration_destination(edge)
		if String(cursor["package_id"]) != String(destination_identity["package_id"]):
			result["errors"].append("cross_package_migration_unsupported")
			return result
	result["ok"] = true
	return result


static func _endpoint_key(identity: Dictionary) -> String:
	return (
		"%s@%s#%d:%s"
		% [
			identity.get("package_id", ""),
			identity.get("package_version", ""),
			int(identity.get("content_schema_version", 0)),
			identity.get("content_fingerprint", ""),
		]
	)


static func _declaration_source(declaration: Dictionary) -> Dictionary:
	return {
		"package_id": String(declaration.get("source_package_id", "")),
		"package_version": String(declaration.get("source_package_version", "")),
		"content_schema_version": int(declaration.get("source_content_schema_version", 0)),
		"content_fingerprint": String(declaration.get("source_content_fingerprint", "")),
		"campaign_id": "",
	}


static func _declaration_destination(declaration: Dictionary) -> Dictionary:
	return {
		"package_id": String(declaration.get("destination_package_id", "")),
		"package_version": String(declaration.get("destination_package_version", "")),
		"content_schema_version": int(declaration.get("destination_content_schema_version", 0)),
		"content_fingerprint": String(declaration.get("destination_content_fingerprint", "")),
		"campaign_id": "",
	}


static func validate_declaration(
	declaration: Variant, destination_package_id: String
) -> Array[String]:
	var errors: Array[String] = []
	if not declaration is Dictionary:
		return ["migration_declaration_invalid"]
	var source_id := String(declaration.get("source_package_id", ""))
	var source_version := String(declaration.get("source_package_version", ""))
	var source_schema := int(declaration.get("source_content_schema_version", 0))
	var source_fingerprint := String(declaration.get("source_content_fingerprint", ""))
	var destination_id := String(declaration.get("destination_package_id", ""))
	var destination_version := String(declaration.get("destination_package_version", ""))
	var destination_schema := int(declaration.get("destination_content_schema_version", 0))
	var destination_fingerprint := String(declaration.get("destination_content_fingerprint", ""))
	if (
		source_id.is_empty()
		or source_version.is_empty()
		or source_schema <= 0
		or not _valid_fingerprint(source_fingerprint)
		or destination_id.is_empty()
		or destination_version.is_empty()
		or destination_schema <= 0
		or not _valid_fingerprint(destination_fingerprint)
	):
		errors.append("migration_identity_incomplete")
	if source_id != destination_package_id or destination_id != destination_package_id:
		errors.append("cross_package_migration_unsupported")
	if (
		source_version == destination_version
		and source_schema == destination_schema
		and source_fingerprint == destination_fingerprint
	):
		errors.append("migration_edge_not_direct")
	var aliases: Variant = declaration.get("aliases", {})
	if not aliases is Dictionary:
		errors.append("migration_aliases_invalid")
		return errors
	for family in aliases:
		if String(family) not in FAMILIES or not aliases[family] is Dictionary:
			errors.append("migration_alias_family_invalid:%s" % String(family))
			continue
		var destinations := {}
		for source in aliases[family]:
			var destination := String(aliases[family][source])
			if String(source).is_empty() or destination.is_empty():
				errors.append("migration_alias_empty:%s" % String(family))
			elif destinations.has(destination):
				errors.append("migration_alias_ambiguous:%s:%s" % [family, destination])
			destinations[destination] = true
	return errors


static func _valid_fingerprint(value: String) -> bool:
	return value.begins_with("sha256:") and value.length() == 71


static func preview(
	source: SaveData,
	destination_package_id: String,
	declaration: Dictionary,
	destination_exists: Callable = Callable()
) -> Dictionary:
	var result := {"ok": false, "errors": [], "mappings": [], "pass_through": [], "save": null}
	result["errors"].append_array(validate_declaration(declaration, destination_package_id))
	if source == null:
		result["errors"].append("migration_source_invalid")
		return result
	result["errors"].append_array(source.validate())
	var source_campaign: Dictionary = source.campaign
	if (
		String(source_campaign.get("package_id", "")) != destination_package_id
		or (
			String(source_campaign.get("package_version", ""))
			!= String(declaration.get("source_package_version", ""))
		)
	):
		result["errors"].append("migration_source_identity_mismatch")
	if not result["errors"].is_empty():
		return result
	var payload: Dictionary = source.to_dict().duplicate(true)
	_walk(payload, declaration.get("aliases", {}), destination_exists, result, "")
	if not result["errors"].is_empty():
		return result
	payload["campaign"]["package_id"] = destination_package_id
	payload["campaign"]["package_version"] = declaration["destination_package_version"]
	if payload.get("source", {}) is Dictionary:
		payload["source"]["package_id"] = destination_package_id
		payload["source"]["package_version"] = declaration["destination_package_version"]
	var migrated: SaveData = SaveData.from_dict(payload) as SaveData
	result["errors"].append_array(migrated.validate())
	if result["errors"].is_empty():
		result["ok"] = true
		result["save"] = migrated
	return result


static func _walk(
	value: Variant,
	aliases: Dictionary,
	destination_exists: Callable,
	result: Dictionary,
	path: String
) -> void:
	if value is Dictionary:
		for key in value.keys():
			var child_path := String(key) if path.is_empty() else "%s.%s" % [path, key]
			if KEY_FAMILIES.has(String(key)) and value[key] is String:
				value[key] = _map_reference(
					String(KEY_FAMILIES[key]),
					value[key],
					aliases,
					destination_exists,
					result,
					child_path
				)
			elif ARRAY_FAMILIES.has(String(key)) and value[key] is Array:
				for index in value[key].size():
					value[key][index] = _map_reference(
						String(ARRAY_FAMILIES[key]),
						value[key][index],
						aliases,
						destination_exists,
						result,
						"%s[%d]" % [child_path, index]
					)
			else:
				_walk(value[key], aliases, destination_exists, result, child_path)
	elif value is Array:
		for index in value.size():
			_walk(value[index], aliases, destination_exists, result, "%s[%d]" % [path, index])


static func _map_reference(
	family: String,
	raw: Variant,
	aliases: Dictionary,
	destination_exists: Callable,
	result: Dictionary,
	path: String
) -> String:
	var source := String(raw)
	if source.is_empty():
		return source
	var rows: Dictionary = aliases.get(family, {})
	var destination := String(rows.get(source, source))
	var record := {"family": family, "source": source, "destination": destination, "path": path}
	if source == destination:
		result["pass_through"].append(record)
	else:
		result["mappings"].append(record)
	if destination_exists.is_valid() and not bool(destination_exists.call(family, destination)):
		result["errors"].append("migration_destination_missing:%s:%s" % [family, destination])
	return destination
