class_name ActionRequest extends RefCounted

# Immutable-by-convention request passed from a feature domain to the runner.
var primitive_id: String
var params: Dictionary


func _init(requested_primitive_id: String = "", requested_params: Dictionary = {}) -> void:
	primitive_id = requested_primitive_id
	params = requested_params.duplicate(true)
