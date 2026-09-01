extends Node

## The condition system. Built on the shared effect contract from its first line.
##
## THIS FILE USED TO BE A STUB — five constants (poison, sleep, silence, berserk,
## stun) and five methods that were each `pass  # [STUB — M8]`, with no caller
## anywhere in the repository including the TurnManager its own comment claimed
## called it. Session 8 was written down as a MIGRATION of that stub; there was
## nothing to migrate, so it is a first build instead, and the five engine ids
## are deleted rather than moved: a condition is authored pack content now, in
## the open `conditions` registry family (owner ruling 3, 2026-09-01).
##
## WHAT THIS OWNS: authored definitions, stacking, duration, immunity and
## scheduling. WHAT IT DOES NOT OWN: the consequences. Damage from a poison tick,
## the healing from a cleanse, a stat swing — those are shared compositions
## prepared into the caller's transaction, exactly like an item effect or a
## combat exchange. Nothing here writes live state, and one tick is ONE prepared
## transaction, which is what makes a tick that both damages and expires atomic.
##
## SCHEDULING is subscription, not a timer. A condition names the tick sources it
## listens to; a firing of a source ticks only its subscribers. Sources are their
## own open registry so an authored effect can fire tick A without firing tick B
## (owner direction, 2026-08-31) — a bare "tick this unit" call cannot express
## that, and neither can an engine enum.

const ModelScript = preload("res://scripts/conditions/ConditionModel.gd")
const ActionContextScript = preload("res://scripts/actions/ActionContext.gd")

const FAMILY := "conditions"
const TICK_FAMILY := "tick_sources"

## Passed as `duration` to ask for the definition's own default.
const DEFAULT_DURATION := -2

## Why a condition left, carried on the removal event so presentation and the
## journal agree about what happened.
const REASON_EXPIRED := "expired"
const REASON_CLEANSED := "cleansed"
const REASON_REMOVED := "removed"
const REASON_MAP_END := "map_end"
const REASON_DEATH := "death"

# ---- Definitions ----


func _registry() -> Node:
	return get_node_or_null("/root/RegistryManager")


## Every authored condition, id -> ConditionDef, in registry order (priority then
## id). Ordering is not decoration: several conditions may subscribe to the same
## tick source, and the order they tick in has to be a stated rule rather than
## whatever order a Dictionary happened to hand back.
func definitions() -> Dictionary:
	var registry := _registry()
	var result: Dictionary = {}
	if registry == null:
		return result
	for id in registry.ids(FAMILY):
		result[id] = registry.entry(FAMILY, id)
	return result


func definition(condition_id: String) -> Resource:
	var registry := _registry()
	if registry == null or not registry.has_entry(FAMILY, condition_id):
		return null
	return registry.entry(FAMILY, condition_id)


func tick_source(source_id: String) -> Resource:
	var registry := _registry()
	if registry == null or not registry.has_entry(TICK_FAMILY, source_id):
		return null
	return registry.entry(TICK_FAMILY, source_id)


func tick_source_ids() -> Array[String]:
	var registry := _registry()
	if registry == null:
		return [] as Array[String]
	return registry.ids(TICK_FAMILY)


## Engine tick sources published by one lifecycle point, in firing order. The
## engine publishes an OCCASION and looks up who subscribed; it never names a
## condition, which is what keeps the source list open to packs.
func sources_for_lifecycle(lifecycle: String) -> Array[String]:
	var result: Array[String] = []
	for id in tick_source_ids():
		var source := tick_source(id)
		if source != null and String(source.publisher) == "engine":
			if String(source.lifecycle) == lifecycle:
				result.append(id)
	return result


# ---- Queries ----


func conditions_of(unit: Node, sink: RefCounted = null) -> Array:
	if unit == null or unit.data == null:
		return []
	if sink != null and sink.has_method("read_conditions"):
		return sink.read_conditions(unit)
	return ModelScript.normalize(unit.data.conditions)


func has_condition(unit: Node, condition_id: String, sink: RefCounted = null) -> bool:
	return ModelScript.index_of(conditions_of(unit, sink), condition_id) >= 0


## The stat deltas a unit's conditions contribute, in the shape
## Unit.get_effective_stat() already reads. Derived, never written: a condition
## contributes the same amount in a forecast, in a projection and in a resolved
## fight because all three read the same held entry through the same view.
func stat_modifiers(unit: Node, sink: RefCounted = null) -> Array:
	return ModelScript.stat_modifiers(conditions_of(unit, sink), definitions())


## True when any held condition carries `tag` — the query gates like "this unit
## is asleep and cannot act" resolve through, so the engine never names a
## condition id.
func has_tag(unit: Node, tag: String, sink: RefCounted = null) -> bool:
	var defs := definitions()
	for entry in conditions_of(unit, sink):
		var def: Resource = defs.get(String(entry["type"]))
		if def != null and def.tags.has(tag):
			return true
	return false


## Immunity is condition-owned: a held condition declares the tags it keeps out,
## so "Panacea grants immunity to poison" is authored on the condition Panacea
## applies rather than in an engine table.
func is_immune_to(unit: Node, condition_id: String, sink: RefCounted = null) -> bool:
	var incoming := definition(condition_id)
	if incoming == null:
		return false
	var defs := definitions()
	for entry in conditions_of(unit, sink):
		var held: Resource = defs.get(String(entry["type"]))
		if held == null:
			continue
		for tag in held.immunity_tags:
			if incoming.tags.has(String(tag)):
				return true
	return false


# ---- Preparation ----
# Every one of these prepares into the caller's transaction and returns a
# {ok, ...} report. Nothing commits: the transaction's owner decides.


func prepare_apply(
	transaction: RefCounted, unit: Node, condition_id: String, duration: int = DEFAULT_DURATION
) -> Dictionary:
	if transaction == null:
		return {"ok": false, "code": "missing_transaction"}
	if unit == null or unit.data == null:
		return {"ok": false, "code": "missing_subject"}
	var def := definition(condition_id)
	if def == null:
		return {"ok": false, "code": "unknown_condition", "condition_id": condition_id}
	var sink: RefCounted = transaction.sink
	if is_immune_to(unit, condition_id, sink):
		return {"ok": false, "code": "immune", "condition_id": condition_id}
	var turns: int = int(def.default_duration) if duration == DEFAULT_DURATION else duration
	var before: Array = sink.read_conditions(unit)
	var after := ModelScript.applied(before, def, turns)
	var step_id: String = transaction.next_step("condition_apply:%s" % condition_id)
	sink.write_conditions(step_id, unit, after)
	var landed := ModelScript.index_of(after, condition_id)
	sink.note_condition_applied(
		unit, condition_id, int((after[landed] as Dictionary)["turns_remaining"])
	)
	var composition := _prepare_composition(String(def.apply_composition), transaction, unit)
	if not composition.ok:
		return composition
	return {"ok": true, "condition_id": condition_id, "step_id": step_id, "conditions": after}


func prepare_remove(
	transaction: RefCounted, unit: Node, condition_id: String, reason: String = REASON_REMOVED
) -> Dictionary:
	if transaction == null:
		return {"ok": false, "code": "missing_transaction"}
	if unit == null or unit.data == null:
		return {"ok": false, "code": "missing_subject"}
	var sink: RefCounted = transaction.sink
	var before: Array = sink.read_conditions(unit)
	if ModelScript.index_of(before, condition_id) < 0:
		# Not an error. "Cure a unit that is not poisoned" is a legal action with
		# nothing to do, and failing it would make a cleanse composition abort on
		# the healthiest unit in the party.
		return {"ok": true, "condition_id": condition_id, "changed": false}
	var step_id: String = transaction.next_step("condition_remove:%s" % condition_id)
	sink.write_conditions(step_id, unit, ModelScript.removed(before, condition_id))
	sink.note_condition_removed(unit, condition_id, reason)
	var def := definition(condition_id)
	var composition_id := ""
	if def != null:
		composition_id = (
			String(def.expire_composition)
			if reason == REASON_EXPIRED
			else String(def.remove_composition)
		)
	var composition := _prepare_composition(composition_id, transaction, unit)
	if not composition.ok:
		return composition
	return {"ok": true, "condition_id": condition_id, "changed": true, "step_id": step_id}


## Fires one NAMED tick source at one unit, as ONE prepared transaction step set.
##
## A poison tick both damages and expires. Those are two authorities, and this is
## the single place they are prepared together: the damage composition and the
## duration decrement land in the same journal, so the tick commits whole or not
## at all. That is also why nothing needs to persist mid-tick across a save
## (owner ruling 5) — there is no mid-tick.
func prepare_tick(transaction: RefCounted, unit: Node, source_id: String) -> Dictionary:
	if transaction == null:
		return {"ok": false, "code": "missing_transaction"}
	if unit == null or unit.data == null:
		return {"ok": false, "code": "missing_subject"}
	if tick_source(source_id) == null:
		return {"ok": false, "code": "unknown_tick_source", "source": source_id}
	var sink: RefCounted = transaction.sink
	var defs := definitions()
	var before: Array = sink.read_conditions(unit)
	var outcome := ModelScript.ticked(before, defs, source_id)
	if (outcome["ticked"] as Array).is_empty():
		return {"ok": true, "ticked": [] as Array[String], "expired": [] as Array[String]}
	# The periodic consequence runs for every subscriber that ticked, including
	# one that expires on this same firing: a final poison tick still hurts.
	for condition_id in outcome["ticked"]:
		var def: Resource = defs.get(String(condition_id))
		if def == null:
			continue
		var composition := _prepare_composition(String(def.tick_composition), transaction, unit)
		if not composition.ok:
			return composition
	var step_id: String = transaction.next_step("condition_tick:%s" % source_id)
	sink.write_conditions(step_id, unit, outcome["conditions"])
	for condition_id in outcome["expired"]:
		var def: Resource = defs.get(String(condition_id))
		sink.note_condition_removed(unit, String(condition_id), REASON_EXPIRED)
		if def != null:
			var composition := _prepare_composition(
				String(def.expire_composition), transaction, unit
			)
			if not composition.ok:
				return composition
	return {
		"ok": true,
		"ticked": outcome["ticked"],
		"expired": outcome["expired"],
		"step_id": step_id,
	}


## Clears every condition a unit holds. Called by a cleanse effect (the Restore
## staff and the Panacea item in the old stub's comment), and by the map-end and
## death paths with their own reason, which is what makes conditions map-scoped
## by default with an authored opt-in to persist (owner ruling 5).
func prepare_clear(
	transaction: RefCounted, unit: Node, reason: String = REASON_CLEANSED
) -> Dictionary:
	if transaction == null:
		return {"ok": false, "code": "missing_transaction"}
	if unit == null or unit.data == null:
		return {"ok": false, "code": "missing_subject"}
	var sink: RefCounted = transaction.sink
	var before: Array = sink.read_conditions(unit)
	if before.is_empty():
		return {"ok": true, "removed": [] as Array[String], "changed": false}
	var retained: Array = []
	if reason == REASON_MAP_END or reason == REASON_DEATH:
		retained = ModelScript.retained_after(before, definitions(), reason)
	var removed: Array[String] = []
	for entry in before:
		var id := String(entry["type"])
		if ModelScript.index_of(retained, id) < 0:
			removed.append(id)
	if removed.is_empty():
		return {"ok": true, "removed": removed, "changed": false}
	var step_id: String = transaction.next_step("condition_clear:%s" % reason)
	sink.write_conditions(step_id, unit, retained)
	for id in removed:
		sink.note_condition_removed(unit, id, reason)
	return {"ok": true, "removed": removed, "changed": true, "step_id": step_id}


func _prepare_composition(
	composition_id: String, transaction: RefCounted, unit: Node
) -> Dictionary:
	if composition_id.strip_edges() == "":
		return {"ok": true, "composition": ""}
	var runner := get_node_or_null("/root/ActionEffectRunner")
	if runner == null:
		return {"ok": false, "code": "missing_runner", "composition": composition_id}
	var context = ActionContextScript.new("condition", {"actor": unit, "target": unit})
	context.effect_sink = transaction.sink
	context.state_view = transaction.sink.state_view
	context.transaction = transaction
	context.participants = transaction.participants
	var result = runner.prepare_composition(composition_id, context)
	if not result.ok:
		return {
			"ok": false,
			"code": "composition_failed",
			"composition": composition_id,
			"failure": result.failure_reason,
		}
	return {"ok": true, "composition": composition_id}
