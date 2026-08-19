class_name CadenceEngine
extends RefCounted

## Deterministic campaign cadence evaluator. Trigger families are an open
## registry so new authored clocks do not require edits to this class.

var _families: Dictionary = {}


func _init() -> void:
	register_family("counter", _evaluate_counter)
	register_family("predicate", _evaluate_predicate)


func register_family(family_id: String, evaluator: Callable) -> bool:
	if family_id.is_empty() or not evaluator.is_valid() or _families.has(family_id):
		return false
	_families[family_id] = evaluator
	return true


func validate(definitions: Dictionary, requirement_system: Node = null) -> Array[String]:
	var errors: Array[String] = []
	for trigger_id in definitions:
		var path := "cadence_triggers.%s" % trigger_id
		var trigger: Variant = definitions[trigger_id]
		if String(trigger_id).is_empty() or not trigger is Dictionary:
			errors.append("%s must be a named object" % path)
			continue
		var family := String(trigger.get("family", ""))
		if not _families.has(family):
			errors.append("%s has unknown family '%s'" % [path, family])
			continue
		if family == "counter":
			if String(trigger.get("counter_id", "")).is_empty():
				errors.append("%s.counter_id is required" % path)
			if String(trigger.get("mode", "")) not in ["after", "every"]:
				errors.append("%s.mode must be 'after' or 'every'" % path)
			if int(trigger.get("threshold", 0)) < 1:
				errors.append("%s.threshold must be >= 1" % path)
		elif family == "predicate":
			var requirement: Variant = trigger.get("requirement", {})
			if not requirement is Dictionary or requirement.is_empty():
				errors.append("%s.requirement must be an object" % path)
			elif requirement_system != null:
				for error in requirement_system.call("validate", requirement):
					errors.append("%s.requirement: %s" % [path, error])
	return errors


func evaluate(definitions: Dictionary, state: Dictionary, context: Dictionary = {}) -> Dictionary:
	var fired: Array[String] = []
	var next_state := normalize_state(state)
	for trigger_id in definitions:
		var trigger: Variant = definitions[trigger_id]
		if not trigger is Dictionary:
			continue
		var family := String(trigger.get("family", ""))
		if not _families.has(family):
			continue
		var trigger_context := context.duplicate(false)
		trigger_context["trigger_id"] = String(trigger_id)
		var result: Dictionary = _families[family].call(trigger, next_state, trigger_context)
		if bool(result.get("fired", false)):
			fired.append(String(trigger_id))
		if result.has("latch"):
			next_state["latched"][String(trigger_id)] = bool(result.latch)
	return {"fired": fired, "state": next_state}


func normalize_state(source: Variant) -> Dictionary:
	var state := {"counters": {}, "latched": {}, "last_fired": {}}
	if source is Dictionary:
		if source.get("counters", {}) is Dictionary:
			state["counters"] = source.get("counters", {}).duplicate(true)
		if source.get("latched", {}) is Dictionary:
			state["latched"] = source.get("latched", {}).duplicate(true)
		if source.get("last_fired", {}) is Dictionary:
			state["last_fired"] = source.get("last_fired", {}).duplicate(true)
	return state


func increment_counter(state: Dictionary, counter_id: String, amount: int = 1) -> void:
	var counters: Dictionary = state.get_or_add("counters", {})
	counters[counter_id] = maxi(0, int(counters.get(counter_id, 0)) + amount)


func _evaluate_counter(trigger: Dictionary, state: Dictionary, _context: Dictionary) -> Dictionary:
	var value := int(state.get("counters", {}).get(String(trigger.get("counter_id", "")), 0))
	var threshold := int(trigger.get("threshold", 0))
	if threshold < 1:
		return {"fired": false}
	if String(trigger.get("mode", "after")) == "every":
		var trigger_id := String(_context.get("trigger_id", ""))
		var fired := (
			value > 0
			and value % threshold == 0
			and int(state.get("last_fired", {}).get(trigger_id, -1)) != value
		)
		if fired:
			state["last_fired"][trigger_id] = value
		return {"fired": fired}
	return {"fired": value >= threshold, "latch": value >= threshold}


func _evaluate_predicate(trigger: Dictionary, state: Dictionary, context: Dictionary) -> Dictionary:
	var trigger_id := String(context.get("trigger_id", ""))
	var reversible := bool(trigger.get("reversible", false))
	if not reversible and bool(state.get("latched", {}).get(trigger_id, false)):
		return {"fired": true, "latch": true}
	var requirement_system: Node = context.get("requirement_system")
	if requirement_system == null:
		return {"fired": false}
	var result: Dictionary = requirement_system.call(
		"evaluate", trigger.get("requirement", {}), context.get("requirement_context", {})
	)
	var met := bool(result.get("met", false))
	return {"fired": met, "latch": met} if not reversible else {"fired": met}
