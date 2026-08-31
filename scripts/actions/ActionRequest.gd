class_name ActionRequest extends RefCounted

# Immutable-by-convention request passed from a feature domain to the runner.
var primitive_id: String
var params: Dictionary
var step_id: String = ""
var target_ref: Dictionary = {}
var requirements: Dictionary = {}
var required: bool = true
var on_failure: String = "abort"


func _init(requested_primitive_id: String = "", requested_params: Dictionary = {}) -> void:
	primitive_id = requested_primitive_id
	params = requested_params.duplicate(true)


static func from_step(step: Dictionary) -> ActionRequest:
	var request: RefCounted = load("res://scripts/actions/ActionRequest.gd").new(
		String(step.get("primitive_id", "")), step.get("params", {})
	)
	request.step_id = String(step.get("step_id", ""))
	request.target_ref = step.get("target", {}).duplicate(true)
	request.requirements = step.get("requirements", {}).duplicate(true)
	request.required = bool(step.get("required", true))
	request.on_failure = String(step.get("on_failure", "abort"))
	return request
