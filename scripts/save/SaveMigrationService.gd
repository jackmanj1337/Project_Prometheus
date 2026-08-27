class_name SaveMigrationService extends RefCounted
# Direct, declarative v1 migration for durable content references. All work is
# performed on a deep copy; callers commit only a fully validated result.

const FAMILIES: Array[String] = [
	"campaign", "campaign_node", "map", "unit", "item", "class", "skill"
]
const REFERENCE_PATHS := {
	"source.campaign_id": "campaign",
	"campaign.campaign_id": "campaign",
	"campaign.node_id": "campaign_node",
	"campaign.cleared_nodes[]": "campaign_node",
	"roster.units[].unit_id": "unit",
	"roster.units[].class_id": "class",
	"roster.units[].class_variant_id": "class",
	"roster.units[].skills[]": "skill",
	"roster.units[].earned_skills[]": "skill",
	"roster.units[].mastery_skills[]": "skill",
	"roster.units[].inventory[].item_id": "item",
	"roster.units[].inventory.entries[].item_id": "item",
	"map_runtime.map_id": "map",
	"map_runtime.discovered_units[]": "unit",
	"map_runtime.watch_set[]": "unit",
	"map_runtime.units[].unit_id": "unit",
	"map_runtime.units[].class_id": "class",
	"map_runtime.units[].class_variant_id": "class",
	"map_runtime.units[].skills[]": "skill",
	"map_runtime.units[].inventory[].item_id": "item",
	"map_runtime.units[].inventory.entries[].item_id": "item",
}
const MUTABLE_PATHS: Array[String] = [
	"campaign.vars",
	"campaign.flags",
	"campaign.mutable_state",
	"campaign.rules",
	"campaign.per_map_overrides",
	"campaign.active_mid_map_overrides",
	"party.resources",
	"party.convoy",
	"party.training_purchase_counts",
	"roster.units[].progression",
	"roster.units[].status",
	"roster.units[].inventory",
	"roster.units[].equipment",
	"roster.units[].proficiency_xp",
	"map_runtime.vars",
	"map_runtime.flags",
	"map_runtime.turn",
	"map_runtime.objective_latches",
	"map_runtime.objects",
]
const OPERATION_TYPES: Array[String] = [
	"rename_id",
	"map_value",
	"set_default_if_absent",
	"numeric_transform",
	"move_field",
	"copy_field",
	"delete_field",
	"reject",
]

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
	var operations: Variant = declaration.get("operations", [])
	if not operations is Array:
		errors.append("migration_operations_invalid")
		return errors
	for index in operations.size():
		errors.append_array(_validate_operation(operations[index], index))
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
	var aliases: Dictionary = declaration.get("aliases", {})
	if not aliases.is_empty():
		_apply_aliases(payload, aliases, destination_exists, result)
	for operation in declaration.get("operations", []):
		_apply_operation(payload, operation, destination_exists, result)
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


static func _apply_aliases(
	payload: Dictionary, aliases: Dictionary, destination_exists: Callable, result: Dictionary
) -> void:
	for path in REFERENCE_PATHS:
		var family := String(REFERENCE_PATHS[path])
		for target in _resolve_targets(payload, String(path)):
			target["parent"][target["key"]] = _map_reference(
				family, target["value"], aliases, destination_exists, result, target["path"]
			)


static func _validate_operation(operation: Variant, index: int) -> Array[String]:
	var errors: Array[String] = []
	if not operation is Dictionary:
		return ["migration_operation_invalid:%d" % index]
	var kind := String(operation.get("op", ""))
	if kind not in OPERATION_TYPES:
		return ["migration_operation_unknown:%d:%s" % [index, kind]]
	var path := String(operation.get("path", ""))
	if not _path_allowed(path):
		errors.append("migration_path_not_allowed:%d:%s" % [index, path])
	if kind in ["move_field", "copy_field"]:
		var destination := String(operation.get("destination", ""))
		if not _path_allowed(destination) or "[]" in path or "[]" in destination:
			errors.append("migration_destination_path_not_allowed:%d:%s" % [index, destination])
	if kind == "rename_id":
		if (
			not REFERENCE_PATHS.has(path)
			or String(operation.get("family", "")) != REFERENCE_PATHS[path]
		):
			errors.append("migration_reference_path_mismatch:%d:%s" % [index, path])
		if (
			String(operation.get("from", "")).is_empty()
			or String(operation.get("to", "")).is_empty()
		):
			errors.append("migration_reference_value_invalid:%d" % index)
	if kind == "map_value" and not operation.get("values", {}) is Dictionary:
		errors.append("migration_value_map_invalid:%d" % index)
	if kind == "numeric_transform":
		for key in ["multiply", "add", "minimum", "maximum"]:
			if operation.has(key) and not operation[key] is int and not operation[key] is float:
				errors.append("migration_numeric_bound_invalid:%d:%s" % [index, key])
		if (
			float(operation.get("minimum", 0.0)) > float(operation.get("maximum", 0.0))
			and operation.has("minimum")
			and operation.has("maximum")
		):
			errors.append("migration_numeric_bounds_reversed:%d" % index)
	return errors


static func _path_allowed(path: String) -> bool:
	if REFERENCE_PATHS.has(path):
		return true
	for root_path in MUTABLE_PATHS:
		if path == root_path or path.begins_with("%s." % root_path):
			return true
	return false


static func _apply_operation(
	payload: Dictionary, operation: Dictionary, destination_exists: Callable, result: Dictionary
) -> void:
	var kind := String(operation["op"])
	var path := String(operation["path"])
	var targets := _resolve_targets(payload, path)
	if kind == "set_default_if_absent":
		_set_default_targets(payload, path, operation.get("value"), result)
		return
	if kind == "reject":
		if not targets.is_empty():
			result["errors"].append("migration_explicit_reject:%s" % path)
		return
	if kind in ["move_field", "copy_field"]:
		if targets.size() != 1:
			result["errors"].append("migration_source_path_missing:%s" % path)
			return
		var value: Variant = (
			targets[0]["value"].duplicate(true)
			if typeof(targets[0]["value"]) in [TYPE_DICTIONARY, TYPE_ARRAY]
			else targets[0]["value"]
		)
		if not _set_exact_path(payload, String(operation["destination"]), value, false):
			result["errors"].append(
				"migration_destination_path_exists:%s" % operation["destination"]
			)
			return
		if kind == "move_field":
			targets[0]["parent"].erase(targets[0]["key"])
		return
	for target in targets:
		match kind:
			"rename_id":
				if String(target["value"]) == String(operation["from"]):
					var aliases := {
						String(operation["family"]):
						{String(operation["from"]): String(operation["to"])}
					}
					target["parent"][target["key"]] = _map_reference(
						String(operation["family"]),
						target["value"],
						aliases,
						destination_exists,
						result,
						target["path"]
					)
			"map_value":
				var values: Dictionary = operation["values"]
				if values.has(String(target["value"])):
					target["parent"][target["key"]] = values[String(target["value"])]
			"numeric_transform":
				if not target["value"] is int and not target["value"] is float:
					result["errors"].append("migration_numeric_source_invalid:%s" % target["path"])
					continue
				var transformed := (
					float(target["value"]) * float(operation.get("multiply", 1.0))
					+ float(operation.get("add", 0.0))
				)
				if operation.has("minimum"):
					transformed = maxf(transformed, float(operation["minimum"]))
				if operation.has("maximum"):
					transformed = minf(transformed, float(operation["maximum"]))
				target["parent"][target["key"]] = (
					int(transformed) if target["value"] is int else transformed
				)
			"delete_field":
				target["parent"].erase(target["key"])


static func _resolve_targets(root: Variant, path: String) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	_resolve_target_parts(root, path.split("."), 0, "", targets)
	return targets


static func _resolve_target_parts(
	current: Variant,
	parts: PackedStringArray,
	part_index: int,
	prefix: String,
	targets: Array[Dictionary]
) -> void:
	if part_index >= parts.size() or not current is Dictionary:
		return
	var part := String(parts[part_index])
	var expands := part.ends_with("[]")
	var key := part.trim_suffix("[]")
	if not current.has(key):
		return
	var concrete_path := key if prefix.is_empty() else "%s.%s" % [prefix, key]
	if expands:
		if not current[key] is Array:
			return
		for index in current[key].size():
			var item_path := "%s[%d]" % [concrete_path, index]
			if part_index == parts.size() - 1:
				targets.append(
					{
						"parent": current[key],
						"key": index,
						"value": current[key][index],
						"path": item_path
					}
				)
			else:
				_resolve_target_parts(
					current[key][index], parts, part_index + 1, item_path, targets
				)
	elif part_index == parts.size() - 1:
		targets.append(
			{"parent": current, "key": key, "value": current[key], "path": concrete_path}
		)
	else:
		_resolve_target_parts(current[key], parts, part_index + 1, concrete_path, targets)


static func _set_default_targets(
	root: Dictionary, path: String, value: Variant, result: Dictionary
) -> void:
	if "[]" in path:
		result["errors"].append("migration_default_wildcard_unsupported:%s" % path)
		return
	_set_exact_path(root, path, value, true)


static func _set_exact_path(
	root: Dictionary, path: String, value: Variant, only_if_absent: bool
) -> bool:
	var parts := path.split(".")
	var current: Dictionary = root
	for index in parts.size() - 1:
		var key := String(parts[index])
		if not current.has(key) or not current[key] is Dictionary:
			return false
		current = current[key]
	var leaf := String(parts[-1])
	if current.has(leaf):
		return only_if_absent
	current[leaf] = (
		value.duplicate(true) if typeof(value) in [TYPE_DICTIONARY, TYPE_ARRAY] else value
	)
	return true


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
