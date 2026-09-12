class_name ActionResult extends RefCounted

var ok: bool = false
var failure_reason: Dictionary = {}
var affected_ids: Array[String] = []
var events_emitted: Array[String] = []
var resources_spent: Dictionary = {}
var rng_draws: int = 0
var save_fields_touched: Array[String] = []
var messages: Array[String] = []
var step_id: String = ""
var steps: Array = []
var deltas: Array[Dictionary] = []
var halted_at: String = ""
var uncertain: Array[Dictionary] = []


static func success() -> ActionResult:
	var result = load("res://scripts/actions/ActionResult.gd").new()
	result.ok = true
	return result


static func failure(code: String, message: String, details: Dictionary = {}) -> ActionResult:
	var result = load("res://scripts/actions/ActionResult.gd").new()
	result.failure_reason = {
		"code": code,
		"message": message,
		"details": details.duplicate(true),
	}
	return result
