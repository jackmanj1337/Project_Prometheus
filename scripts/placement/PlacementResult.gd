class_name PlacementResult extends RefCounted

var ok: bool = false
var failure_reason: String = ""
var from_tile: Vector2i = Vector2i(-1, -1)
var to_tile: Vector2i = Vector2i(-1, -1)
var fallback_used: bool = false
var queued: bool = false
var skipped: bool = false
var affected_ids: Array[String] = []


static func failure(reason: String, context: RefCounted) -> RefCounted:
	var result := new()
	result.failure_reason = reason
	result.from_tile = context.from_tile
	result.to_tile = context.desired_tile
	if context.subject_id != "":
		result.affected_ids.append(context.subject_id)
	return result
