class_name ActionPrimitiveRunner extends RefCounted

const Result = preload("res://scripts/actions/ActionResult.gd")
const Request = preload("res://scripts/actions/ActionRequest.gd")
const StateView = preload("res://scripts/actions/EffectStateView.gd")

var _registry: Node
var _requirements: Node
var _handlers := {"apply_active_modifier": _active_modifier, "set_state_value": _state_value}


func _init(registry: Node = null, requirement_system: Node = null) -> void:
	_registry = registry
	_requirements = requirement_system


func validate(request: RefCounted, context: RefCounted) -> ActionResult:
	if request == null or request.primitive_id.strip_edges() == "":
		return Result.failure("invalid_request", "Action primitive id is required.")
	if context == null:
		return Result.failure("invalid_context", "Action context is required.")
	if _registry == null or not _registry.has_entry("action_primitives", request.primitive_id):
		return Result.failure(
			"unknown_primitive", "Unknown action primitive '%s'." % request.primitive_id
		)
	var entry = _registry.entry("action_primitives", request.primitive_id)
	if not _handlers.has(String(entry.primitive_handler)):
		return Result.failure(
			"unknown_handler", "No runtime handler for '%s'." % entry.primitive_handler
		)
	for subject_id in entry.subjects:
		if not context.subjects.has(subject_id) or context.subjects[subject_id] == null:
			return Result.failure(
				"missing_subject", "Required subject '%s' is missing." % subject_id
			)
	for param_id in entry.params_schema:
		var spec: Dictionary = entry.params_schema[param_id]
		if not request.params.has(param_id):
			if bool(spec.get("required", false)):
				return Result.failure(
					"missing_param", "Required parameter '%s' is missing." % param_id
				)
			continue
		if not _matches_type(request.params[param_id], String(spec.get("type", ""))):
			return Result.failure(
				"invalid_param_type", "Parameter '%s' has the wrong type." % param_id
			)
	return Result.success()


func commit(request: RefCounted, context: RefCounted) -> ActionResult:
	var check := validate(request, context)
	if not check.ok or context.dry_run:
		return check
	var entry = _registry.entry("action_primitives", request.primitive_id)
	return (_handlers[String(entry.primitive_handler)] as Callable).call(request, context, entry)


func prepare_composition(composition_id: String, context: RefCounted) -> ActionResult:
	if context == null:
		return Result.failure("invalid_context", "Action context is required.")
	if _registry == null or not _registry.has_entry("effect_compositions", composition_id):
		return Result.failure("unknown_composition", "Unknown composition '%s'." % composition_id)
	if context.state_view == null:
		context.state_view = StateView.new()
	context.phase = "prepare"
	var aggregate := Result.success()
	for step in _registry.entry("effect_compositions", composition_id).composition:
		var request = Request.from_step(step)
		var target_check := _resolve_target(request, context)
		if not target_check.ok:
			return target_check
		var gate := _evaluate_gate(request, context)
		if not gate.ok:
			if request.required or request.on_failure == "abort":
				return gate
			context.diagnostics.append({"step_id": request.step_id, "failure": gate.failure_reason})
			if request.on_failure == "halt":
				aggregate.halted_at = request.step_id
				break
			continue
		var validation := validate(request, context)
		if not validation.ok:
			return validation
		var entry = _registry.entry("action_primitives", request.primitive_id)
		var step_result: ActionResult = (
			(_handlers[String(entry.primitive_handler)] as Callable).call(request, context, entry)
		)
		step_result.step_id = request.step_id
		if not step_result.ok:
			return step_result
		aggregate.steps.append(step_result)
		_merge(aggregate, step_result)
	aggregate.deltas = context.state_view.journal.duplicate_entries()
	var declared: Array[String] = []
	for step_result in aggregate.steps:
		for field in step_result.save_fields_touched:
			if not declared.has(field):
				declared.append(field)
	for field in context.state_view.journal.save_fields():
		if not declared.has(field):
			return Result.failure(
				"undeclared_save_field", "Prepared write was not declared.", {"save_field": field}
			)
	aggregate.save_fields_touched = context.state_view.journal.save_fields()
	return aggregate


func commit_composition(composition_id: String, context: RefCounted) -> ActionResult:
	var result := prepare_composition(composition_id, context)
	if not result.ok or context.dry_run:
		return result
	context.phase = "commit"
	var committed: Array = []
	for participant in context.participants:
		var check: Dictionary = participant.revalidate(context)
		if not check.get("ok", false):
			return Result.failure("stale_precondition", "A participant changed before commit.")
	for participant in context.participants:
		var outcome: Dictionary = participant.commit(context)
		if not outcome.get("ok", false):
			for prior in committed:
				prior.rollback(context)
			return Result.failure("participant_commit_failed", "A participant failed to commit.")
		committed.push_front(participant)
	var journal_outcome: Dictionary = context.state_view.commit()
	if not journal_outcome.ok:
		for prior in committed:
			prior.rollback(context)
		return Result.failure(String(journal_outcome.code), "Effect state changed before commit.")
	return result


func handler_id_for(primitive_id: String) -> String:
	if _registry == null or not _registry.has_entry("action_primitives", primitive_id):
		return ""
	return String(_registry.entry("action_primitives", primitive_id).primitive_handler)


func _resolve_target(request: RefCounted, context: RefCounted) -> ActionResult:
	var kind := String(request.target_ref.get("kind", ""))
	var key := String(request.target_ref.get("key", ""))
	var target: Variant
	match kind:
		"subject":
			target = context.subjects.get(key)
		"self":
			target = context.subjects.get("actor")
		"source":
			target = context.source_ref
		"tile", "group", "party", "campaign":
			target = context.target_refs.get(key if key != "" else kind)
	if target == null:
		return Result.failure(
			"unresolved_target",
			"Effect target could not be resolved.",
			{"step_id": request.step_id}
		)
	context.subjects["target"] = target
	return Result.success()


func _evaluate_gate(request: RefCounted, context: RefCounted) -> ActionResult:
	if request.requirements.is_empty():
		return Result.success()
	if _requirements == null:
		return Result.failure("requirement_system_unavailable", "RequirementSystem is unavailable.")
	var evaluation: Dictionary = _requirements.evaluate(
		request.requirements, context.requirement_context
	)
	if not evaluation.errors.is_empty() or not evaluation.met:
		return Result.failure("requirement_unmet", "Effect requirements were not met.", evaluation)
	return Result.success()


func _state_value(request: RefCounted, context: RefCounted, entry: Resource) -> ActionResult:
	var params: Dictionary = request.params
	context.state_view.write(
		request.step_id,
		String(params.authority_id),
		String(params.save_field),
		context.subjects.target,
		params.get("value")
	)
	var result := Result.success()
	result.save_fields_touched.assign(entry.save_fields)
	return result


func _active_modifier(request: RefCounted, context: RefCounted, entry: Resource) -> ActionResult:
	var params: Dictionary = request.params
	var target: Node = context.subjects.target
	target.add_modifier(
		String(params.get("stat", "")),
		int(params.get("delta", 0)),
		String(params.get("source", "")),
		int(params.get("duration", 0)),
		String(params.get("duration_type", ""))
	)
	var result := Result.success()
	if target.data != null and "unit_id" in target.data:
		result.affected_ids.append(String(target.data.unit_id))
	result.save_fields_touched.assign(entry.save_fields)
	return result


func _merge(aggregate: ActionResult, step: ActionResult) -> void:
	for id in step.affected_ids:
		if not aggregate.affected_ids.has(id):
			aggregate.affected_ids.append(id)
	for event in step.events_emitted:
		if not aggregate.events_emitted.has(event):
			aggregate.events_emitted.append(event)
	aggregate.rng_draws += step.rng_draws


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
		"variant":
			return true
		_:
			return false
