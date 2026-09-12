extends Node

## Typed mutable author state. Definitions come from the open campaign_vars
## registry; tests and authoring tools may inject definitions before activation.

var _definitions: Dictionary = {}
var _campaign_values: Dictionary = {}
var _map_values: Dictionary = {}
var _errors: Array[String] = []


func register_definition(definition: Resource) -> Array[String]:
	if definition == null:
		return ["CampaignVars: definition is null"]
	var errors: Array[String] = definition.call("validation_errors")
	if definition.id.strip_edges().is_empty():
		errors.append("CampaignVars: definition id is empty")
	elif _definitions.has(definition.id):
		errors.append("CampaignVars: duplicate definition '%s'" % definition.id)
	if errors.is_empty():
		_definitions[definition.id] = definition
	return errors


func clear_all() -> void:
	_campaign_values.clear()
	_map_values.clear()
	_errors.clear()


func clear_definitions() -> void:
	_definitions.clear()
	clear_all()


func reset_map_scope() -> void:
	_map_values.clear()


func get_var(id: String) -> Variant:
	var definition: Resource = _definition(id)
	if definition == null:
		_record_error("CampaignVars: unknown variable '%s'" % id)
		return null
	var values: Dictionary = _values_for(definition)
	var default_value: Variant = definition.call("normalized_default_value")
	return values.get(id, default_value)


func set_var(id: String, value: Variant) -> bool:
	var definition: Resource = _definition(id)
	if definition == null:
		_record_error("CampaignVars: unknown variable '%s'" % id)
		return false
	var error: String = _value_error(definition, value)
	if not error.is_empty():
		_record_error(error)
		return false
	_values_for(definition)[id] = value
	return true


func exposed_definitions(stage: String) -> Array[Resource]:
	var result: Array[Resource] = []
	for definition in _all_definitions():
		if definition.exposed == stage:
			result.append(definition)
	return result


func capture_campaign_values() -> Dictionary:
	return _campaign_values.duplicate(true)


func restore_campaign_values(values: Dictionary) -> bool:
	var candidate: Dictionary = {}
	for raw_id in values:
		var id := String(raw_id)
		var definition: Resource = _definition(id)
		# The campaign envelope also carries legacy open facts. They remain owned
		# by CampaignManager and are deliberately ignored by this typed view.
		if definition == null or definition.scope != "campaign":
			continue
		var error: String = _value_error(definition, values[raw_id])
		if not error.is_empty():
			_record_error(error)
			return false
		candidate[id] = values[raw_id]
	_campaign_values = candidate
	return true


func validation_errors() -> Array[String]:
	return _errors.duplicate()


func _definition(id: String) -> Resource:
	if _definitions.has(id):
		return _definitions[id]
	var registry := get_node_or_null("/root/RegistryManager") if is_inside_tree() else null
	if registry != null and registry.has_method("entry"):
		var resource: Resource = registry.call("entry", "campaign_vars", id)
		if resource != null and resource.has_method("validation_errors"):
			return resource
	return null


func _all_definitions() -> Array[Resource]:
	var result: Array[Resource] = []
	for definition in _definitions.values():
		result.append(definition)
	var registry := get_node_or_null("/root/RegistryManager") if is_inside_tree() else null
	if registry != null:
		for id in registry.call("ids", "campaign_vars"):
			var definition: Resource = registry.call("entry", "campaign_vars", id)
			if (
				definition != null
				and definition.has_method("validation_errors")
				and not result.has(definition)
			):
				result.append(definition)
	return result


func _values_for(definition: Resource) -> Dictionary:
	return _map_values if definition.scope == "map" else _campaign_values


func _value_error(definition: Resource, value: Variant) -> String:
	if definition.value_type == "bool" and not value is bool:
		return "CampaignVars: '%s' requires bool" % definition.id
	if definition.value_type == "int":
		if not value is int:
			return "CampaignVars: '%s' requires int" % definition.id
		if int(value) < definition.min_value or int(value) > definition.max_value:
			return (
				"CampaignVars: '%s' is outside [%d, %d]"
				% [definition.id, definition.min_value, definition.max_value]
			)
	if (
		definition.value_type == "enum"
		and (not value is String or String(value) not in definition.options)
	):
		return "CampaignVars: '%s' is not an allowed enum value" % definition.id
	return ""


func _record_error(error: String) -> void:
	if error not in _errors:
		_errors.append(error)
