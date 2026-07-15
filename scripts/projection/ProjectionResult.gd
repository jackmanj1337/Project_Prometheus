class_name ProjectionResult extends RefCounted
## Stable projection output; consumers choose which visible fields to render.

var valid: bool = false
var failure_reason: String = ""
var visible_outcome: Dictionary = {}
var knowledge_flags: Dictionary = {}
var state_deltas: Array[Dictionary] = []
var projected_events: Array[Dictionary] = []
var rng_summary: Dictionary = {}
var warnings: Array[String] = []
var real_outcome: Dictionary = {}


static func failure(reason: String) -> RefCounted:
	var result: RefCounted = load("res://scripts/projection/ProjectionResult.gd").new()
	result.failure_reason = reason
	return result
