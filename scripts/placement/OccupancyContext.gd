class_name OccupancyContext extends RefCounted

# One non-standard placement request. Policies are registry ids; the service
# resolves them to engine primitives instead of teaching consumers a switch.
var source: Variant = null
var subject: Variant = null
var from_tile: Vector2i = Vector2i(-1, -1)
var desired_tile: Vector2i = Vector2i.ZERO
var reason: String = "spawn"
var collision_policy: String = "require_empty"
var passability_policy: String = "require_passable"
var fallback_policy: String = "none"
var result_sink: Callable = Callable()
var subject_id: String = ""


static func create(
	p_subject: Variant,
	p_tile: Vector2i,
	p_policy: String = "require_empty",
	p_subject_id: String = ""
) -> RefCounted:
	var context := new()
	context.subject = p_subject
	context.desired_tile = p_tile
	context.collision_policy = p_policy
	context.subject_id = p_subject_id
	return context
