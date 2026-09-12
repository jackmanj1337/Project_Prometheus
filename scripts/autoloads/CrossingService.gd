extends Node
# Autoload seam for the crossing resolver ([PCM-1]). Unit.move_along_path looks
# this up by node path, so movement resolves crossings without every caller
# having to thread a resolver through — which is what keeps player, AI and
# Instant-speed moves on one code path ([PCM-3]).
#
# It owns exactly one CrossingResolver. Consumers (fog Slice 3's ambush reveal,
# pass-through terrain, perception on_cross, traversing displacement) register
# here; nobody constructs a second resolver.

const ResolverScript = preload("res://scripts/core/CrossingResolver.gd")
const OutcomeScript = preload("res://scripts/core/CrossingOutcome.gd")
const ContextScript = preload("res://scripts/actions/ActionContext.gd")

var _resolver: RefCounted


func _ready() -> void:
	_resolver = ResolverScript.new(_commit_composition)


func _ensure_resolver() -> void:
	if _resolver == null:
		_ready()


func _commit_composition(composition_id: String, crossing_context: Dictionary) -> Dictionary:
	var runner := get_node_or_null("/root/ActionEffectRunner")
	if runner == null:
		return {"ok": false, "code": "effect_runner_unavailable"}
	var subjects: Dictionary = crossing_context.get("subjects", {}).duplicate()
	var mover: Variant = crossing_context.get("unit")
	if not subjects.has("actor"):
		subjects["actor"] = mover
	if not subjects.has("target"):
		subjects["target"] = mover
	var context = ContextScript.new("crossing", subjects)
	context.event_metadata = crossing_context.get("event_metadata", {}).duplicate(true)
	context.event_metadata["tile"] = crossing_context.get("tile")
	context.event_metadata["step_index"] = crossing_context.get("step_index")
	var result = runner.commit_composition(composition_id, context)
	return {"ok": result.ok, "code": result.failure_reason.get("code", "")}


# Delegating wrappers rather than exposing _resolver: the single-owner rule is
# easier to keep when there is no handle to copy.
func register_consumer(consumer_id: String, probe: Callable) -> Array[String]:
	_ensure_resolver()
	return _resolver.register_consumer(consumer_id, probe)


func unregister_consumer(consumer_id: String) -> void:
	_ensure_resolver()
	_resolver.unregister_consumer(consumer_id)


func clear_consumers() -> void:
	_ensure_resolver()
	_resolver.clear_consumers()


func has_consumer(consumer_id: String) -> bool:
	_ensure_resolver()
	return _resolver.has_consumer(consumer_id)


func consumer_ids() -> Array[String]:
	_ensure_resolver()
	return _resolver.consumer_ids()


func resolve(unit: Node, path: Array[Vector2i]) -> CrossingOutcome:
	_ensure_resolver()
	return _resolver.resolve(unit, path)
