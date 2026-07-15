class_name DeathResult extends RefCounted
## Structured outcome returned to death producers and future disposition consumers.

var ok: bool = false
var failure_reason: String = ""
var subject_id: String = ""
var removed_from_map: bool = false
var incapacitated: bool = false
var custody_events: Array[Dictionary] = []
var inventory_events: Array[Dictionary] = []
var objective_events: Array[Dictionary] = []
var messages: Array[String] = []


static func failure(reason: String) -> RefCounted:
	var result: RefCounted = load("res://scripts/death/DeathResult.gd").new()
	result.failure_reason = reason
	return result
