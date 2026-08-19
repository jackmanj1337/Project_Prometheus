class_name RegistryCatalog extends RefCounted

const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")

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
	"campaign_var_value",
]
const REQUIRED_FAMILIES: Array[String] = [
	"action_primitives",
	"resource_types",
	"occupancy_policies",
	"objective_conditions",
	"item_effects",
	"campaign_vars"
]


static func builtin_primitive_handlers() -> Array[String]:
	return BUILTIN_PRIMITIVE_HANDLERS.duplicate()


var _entries: Dictionary = {}
var _primitive_handlers: Dictionary = {}


func register_primitive_handler(handler_id: String) -> Array[String]:
	if handler_id.strip_edges() == "":
		return ["RegistryCatalog: primitive handler id is empty"]
	_primitive_handlers[handler_id] = true
	return []


func register_entry(entry: Resource) -> Array[String]:
	var errors := validate_entry(entry)
	if not errors.is_empty():
		return errors
	var family_entries: Dictionary = _entries.get(entry.family, {})
	if family_entries.has(entry.id):
		return ["RegistryCatalog: duplicate id '%s' in family '%s'" % [entry.id, entry.family]]
	family_entries[entry.id] = entry
	_entries[entry.family] = family_entries
	return []


func validate_entry(entry: Resource) -> Array[String]:
	var errors: Array[String] = []
	if entry == null:
		return ["RegistryCatalog: entry is null"]
	if entry.id.strip_edges() == "":
		errors.append("RegistryCatalog: entry is missing id")
	if entry.family.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing family" % entry.id)
	if entry.label_key.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing label_key" % entry.id)
	if entry.owner_feature.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing owner_feature" % entry.id)
	if entry.version < 1:
		errors.append("RegistryCatalog: entry '%s' version must be >= 1" % entry.id)
	if entry.kind.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing kind" % entry.id)
	if entry.primitive_handler.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing primitive_handler" % entry.id)
	elif not _primitive_handlers.has(entry.primitive_handler):
		errors.append(
			(
				"RegistryCatalog: entry '%s' references unknown primitive handler '%s'"
				% [entry.id, entry.primitive_handler]
			)
		)
	for param_id in entry.params_schema.keys():
		var spec: Variant = entry.params_schema[param_id]
		if not (spec is Dictionary) or String(spec.get("type", "")) == "":
			errors.append(
				(
					"RegistryCatalog: entry '%s' parameter '%s' needs a schema dictionary with type"
					% [entry.id, String(param_id)]
				)
			)
	if entry.kind == "mutation" and entry.save_fields.is_empty():
		errors.append("RegistryCatalog: mutating entry '%s' must declare save_fields" % entry.id)
	for part in entry.composition:
		var handler_id := String(part.get("primitive_handler", ""))
		if handler_id == "" or not _primitive_handlers.has(handler_id):
			(
				errors
				. append(
					(
						"RegistryCatalog: entry '%s' composition references unknown primitive handler '%s'"
						% [entry.id, handler_id]
					)
				)
			)
	if entry.docs_text.strip_edges() == "":
		errors.append("RegistryCatalog: entry '%s' is missing docs_text" % entry.id)
	if entry.test_fixture.is_empty():
		errors.append("RegistryCatalog: entry '%s' is missing test_fixture" % entry.id)
	if entry.has_method("validation_errors"):
		errors.append_array(entry.validation_errors())
	return errors


func has_entry(family: String, id: String) -> bool:
	return _entries.has(family) and (_entries[family] as Dictionary).has(id)


func entry(family: String, id: String) -> Resource:
	if not has_entry(family, id):
		return null
	return (_entries[family] as Dictionary)[id]


func ids(family: String) -> Array[String]:
	var sorted_entries: Array[Resource] = []
	if _entries.has(family):
		for registry_entry in (_entries[family] as Dictionary).values():
			sorted_entries.append(registry_entry)
	sorted_entries.sort_custom(
		func(a: Resource, b: Resource) -> bool:
			if a.priority != b.priority:
				return a.priority < b.priority
			return a.id < b.id
	)
	var result: Array[String] = []
	for registry_entry in sorted_entries:
		result.append(registry_entry.id)
	return result
