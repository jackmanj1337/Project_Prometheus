extends Node

const ActionPrimitiveRunnerScript = preload("res://scripts/actions/ActionPrimitiveRunner.gd")

var _runner: RefCounted


func _ready() -> void:
	var registry := get_node_or_null("/root/RegistryManager")
	_runner = ActionPrimitiveRunnerScript.new(registry)


func validate(request: RefCounted, context: RefCounted) -> ActionResult:
	_ensure_runner()
	return _runner.validate(request, context)


func commit(request: RefCounted, context: RefCounted) -> ActionResult:
	_ensure_runner()
	return _runner.commit(request, context)


func handler_id_for(primitive_id: String) -> String:
	_ensure_runner()
	return _runner.handler_id_for(primitive_id)


func _ensure_runner() -> void:
	if _runner == null:
		_ready()
