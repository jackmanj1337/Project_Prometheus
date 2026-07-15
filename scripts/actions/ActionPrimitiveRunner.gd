class_name ActionPrimitiveRunner extends RefCounted

const ActionResultScript = preload("res://scripts/actions/ActionResult.gd")

var _registry: Node
var _handlers: Dictionary = {}


func _init(registry: Node = null) -> void:
	_registry = registry
	_handlers["apply_active_modifier"] = _commit_active_modifier


func validate(request: RefCounted, context: RefCounted) -> ActionResult:
	if request == null or request.primitive_id.strip_edges() == "":
		return ActionResultScript.failure("invalid_request", "Action primitive id is required.")
	if context == null:
		return ActionResultScript.failure("invalid_context", "Action context is required.")
	if _registry == null or not _registry.has_entry("action_primitives", request.primitive_id):
		return ActionResultScript.failure(
			"unknown_primitive", "Unknown action primitive '%s'." % request.primitive_id
		)
	var entry = _registry.entry("action_primitives", request.primitive_id)
	var handler_id := String(entry.primitive_handler)
	if not _handlers.has(handler_id):
		return ActionResultScript.failure(
			"unknown_handler", "No runtime handler for '%s'." % handler_id
		)
	for subject_id in entry.subjects:
		if not context.subjects.has(subject_id) or context.subjects[subject_id] == null:
			return ActionResultScript.failure(
				"missing_subject",
				"Required subject '%s' is missing." % subject_id,
				{"subject": subject_id}
			)
	for param_id in entry.params_schema:
		var spec: Dictionary = entry.params_schema[param_id]
		if not request.params.has(param_id):
			if bool(spec.get("required", false)):
				return ActionResultScript.failure(
					"missing_param",
					"Required parameter '%s' is missing." % param_id,
					{"parameter": param_id}
				)
			continue
		if not _matches_type(request.params[param_id], String(spec.get("type", ""))):
			return ActionResultScript.failure(
				"invalid_param_type",
				"Parameter '%s' must be %s." % [param_id, spec.type],
				{"parameter": param_id, "expected": spec.type}
			)
		if (
			bool(spec.get("non_empty", false))
			and String(request.params[param_id]).strip_edges() == ""
		):
			return ActionResultScript.failure(
				"invalid_param_value",
				"Parameter '%s' cannot be empty." % param_id,
				{"parameter": param_id}
			)
		if bool(spec.get("non_zero", false)) and int(request.params[param_id]) == 0:
			return ActionResultScript.failure(
				"invalid_param_value",
				"Parameter '%s' cannot be zero." % param_id,
				{"parameter": param_id}
			)
	var target: Variant = context.subjects.get("target")
	if (
		handler_id == "apply_active_modifier"
		and (not target is Node or not target.has_method("add_modifier"))
	):
		return ActionResultScript.failure(
			"invalid_subject", "Target cannot receive active modifiers.", {"subject": "target"}
		)
	return ActionResultScript.success()


func commit(request: RefCounted, context: RefCounted) -> ActionResult:
	var validation: Variant = validate(request, context)
	if not validation.ok or context.dry_run:
		return validation
	var entry = _registry.entry("action_primitives", request.primitive_id)
	var handler: Callable = _handlers[String(entry.primitive_handler)]
	return handler.call(request.params, context, entry)


func handler_id_for(primitive_id: String) -> String:
	if _registry == null or not _registry.has_entry("action_primitives", primitive_id):
		return ""
	return String(_registry.entry("action_primitives", primitive_id).primitive_handler)


func _commit_active_modifier(
	params: Dictionary, context: RefCounted, entry: Resource
) -> ActionResult:
	var target: Node = context.subjects["target"]
	target.add_modifier(
		String(params.get("stat", "")),
		int(params.get("delta", 0)),
		String(params.get("source", "")),
		int(params.get("duration", 0)),
		String(params.get("duration_type", ""))
	)
	var result: Variant = ActionResultScript.success()
	if target.data != null and "unit_id" in target.data:
		result.affected_ids.append(String(target.data.unit_id))
	result.save_fields_touched.assign(entry.save_fields)
	return result


func _matches_type(value: Variant, type_id: String) -> bool:
	match type_id:
		"string":
			return value is String
		"int":
			return value is int
		"float":
			return value is float
		"bool":
			return value is bool
		"dictionary":
			return value is Dictionary
		"array":
			return value is Array
		_:
			return false
