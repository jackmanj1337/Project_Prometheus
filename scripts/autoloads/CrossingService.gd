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

var _resolver: RefCounted = ResolverScript.new()


# Delegating wrappers rather than exposing _resolver: the single-owner rule is
# easier to keep when there is no handle to copy.
func register_consumer(consumer_id: String, probe: Callable) -> Array[String]:
	return _resolver.register_consumer(consumer_id, probe)


func unregister_consumer(consumer_id: String) -> void:
	_resolver.unregister_consumer(consumer_id)


func clear_consumers() -> void:
	_resolver.clear_consumers()


func has_consumer(consumer_id: String) -> bool:
	return _resolver.has_consumer(consumer_id)


func consumer_ids() -> Array[String]:
	return _resolver.consumer_ids()


func resolve(unit: Node, path: Array[Vector2i]) -> CrossingOutcome:
	return _resolver.resolve(unit, path)
