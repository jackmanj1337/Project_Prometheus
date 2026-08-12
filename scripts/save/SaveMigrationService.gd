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


static func validate_declaration(
	declaration: Variant, destination_package_id: String
) -> Array[String]:
	var errors: Array[String] = []
	if not declaration is Dictionary:
		return ["migration_declaration_invalid"]
	var source_id := String(declaration.get("source_package_id", ""))
	var source_version := String(declaration.get("source_package_version", ""))
	var destination_version := String(declaration.get("destination_package_version", ""))
	if source_id.is_empty() or source_version.is_empty() or destination_version.is_empty():
		errors.append("migration_identity_incomplete")
	if source_id != destination_package_id:
		errors.append("cross_package_migration_unsupported")
	if source_version == destination_version:
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
