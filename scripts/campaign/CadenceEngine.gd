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


# Returns fired (this evaluation), active (satisfied right now) and the next
# state. The two lists are different questions and different subscribers ask
# them: a battle target or activity set asks what is CURRENTLY selected, while a
# restock asks whether a clock has TICKED since it last acted.
func evaluate(definitions: Dictionary, state: Dictionary, context: Dictionary = {}) -> Dictionary:
	var fired: Array[String] = []
	var active: Array[String] = []
	var next_state := normalize_state(state)
	var previous_active: Dictionary = next_state["active"]
	var current_active := {}
	for trigger_id in definitions:
		var trigger: Variant = definitions[trigger_id]
		if not trigger is Dictionary:
			continue
		var family := String(trigger.get("family", ""))
		if not _families.has(family):
			continue
		var id := String(trigger_id)
		var trigger_context := context.duplicate(false)
		trigger_context["trigger_id"] = id
		var result: Dictionary = _families[family].call(trigger, next_state, trigger_context)
		var did_fire := bool(result.get("fired", false))
		# A family that does not answer "active" is a state trigger: satisfied
		# for exactly as long as it fires. Only instantaneous families opt out.
		var is_active := bool(result.get("active", did_fire))
		if did_fire:
			fired.append(id)
		if is_active:
			active.append(id)
			current_active[id] = true
		if result.has("latch"):
			next_state["latched"][id] = bool(result.latch)
		# Ticks count EDGES, not evaluations — an instantaneous fire, or a state
		# trigger becoming satisfied. An entity that restocks on cadence stores
		# the tick it last acted on and compares ([CVS-S6]), so the engine keeps
		# no per-consumer drain state and a missed evaluation cannot lose a tick.
		if did_fire and (not is_active or not bool(previous_active.get(id, false))):
			var ticks: Dictionary = next_state["ticks"]
			ticks[id] = int(ticks.get(id, 0)) + 1
	next_state["active"] = current_active
	return {"fired": fired, "active": active, "state": next_state}


func normalize_state(source: Variant) -> Dictionary:
	var state := {"counters": {}, "latched": {}, "last_fired": {}, "ticks": {}, "active": {}}
	if source is Dictionary:
		for key in state:
			if source.get(key, {}) is Dictionary:
				state[key] = source.get(key, {}).duplicate(true)
	return state


# A subscription entry is either a bare trigger id — "this trigger simply
# selects me" — or {trigger, value}, where value is OPAQUE to the engine and
# interpreted by the subscribing family. Keeping the payload opaque is what lets
# activity set, battle target, activity variant and stock share one mechanism
# instead of growing four per-feature timers.
static func normalize_binding(entry: Variant) -> Dictionary:
	if entry is String:
		return {} if String(entry).is_empty() else {"trigger": String(entry), "value": true}
	if entry is Dictionary:
		var trigger := String(entry.get("trigger", ""))
		return {} if trigger.is_empty() else {"trigger": trigger, "value": entry.get("value", true)}
	return {}


# Resolves authored subscriptions against the currently satisfied trigger ids.
# Authored order IS the precedence contract, exactly as CampaignData's node order
# is: the LAST satisfied entry wins, so an author appends a later override
# without rewriting the entries before it.
func resolve_subscriptions(subscriptions: Dictionary, satisfied: Array) -> Dictionary:
	var resolved := {}
	for subscriber_id in subscriptions:
		var entries: Variant = subscriptions[subscriber_id]
		if not entries is Array:
			continue
		for entry in entries:
			var binding := normalize_binding(entry)
			if binding.is_empty() or not satisfied.has(binding["trigger"]):
				continue
			resolved[String(subscriber_id)] = binding["value"]
	return resolved


func increment_counter(state: Dictionary, counter_id: String, amount: int = 1) -> void:
	var counters: Dictionary = state.get_or_add("counters", {})
	counters[counter_id] = maxi(0, int(counters.get(counter_id, 0)) + amount)


func _evaluate_counter(trigger: Dictionary, state: Dictionary, context: Dictionary) -> Dictionary:
	var value := int(state.get("counters", {}).get(String(trigger.get("counter_id", "")), 0))
	var threshold := int(trigger.get("threshold", 0))
	if threshold < 1:
		return {"fired": false, "active": false}
	if String(trigger.get("mode", "after")) == "every":
		var trigger_id := String(context.get("trigger_id", ""))
		var fired := (
			value > 0
			and value % threshold == 0
			and int(state.get("last_fired", {}).get(trigger_id, -1)) != value
		)
		if fired:
			state["last_fired"][trigger_id] = value
		# An interval is an EVENT: it happens at the boundary and is never a
		# standing selection, so nothing can subscribe to it as a state.
		return {"fired": fired, "active": false}
	var met := value >= threshold
	return {"fired": met, "active": met, "latch": met}


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
