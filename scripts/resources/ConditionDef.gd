class_name ConditionDef
extends "res://scripts/resources/RegistryEntry.gd"

## An authored status condition. The engine ships NONE of these.
##
## Poison, sleep, silence, berserk and stun were five hard-coded constants on the
## ConditionManager stub. They are gone: a condition is pack content now, exactly
## like an item effect or a skill, and a pack adds one with no engine edit
## (owner ruling 3, 2026-09-01). What the engine still owns is the RULE SET a
## definition selects from — the stacking rules, the tick-source mechanism, and
## the shared compositions the consequences run through.

const ModelScript = preload("res://scripts/conditions/ConditionModel.gd")

## Named tick sources this condition listens to. A condition may subscribe to
## several; each firing of a source ticks only its own subscribers, so an
## authored effect can fire tick A without firing tick B. Empty means the
## condition never ticks on its own and only ends when something removes it.
@export var tick_sources: Array[String] = []

## Which engine stacking rule a re-application of this condition follows.
@export_enum("refresh_duration", "add_instance", "take_max")
var stacking: String = "refresh_duration"

## Ceiling for `add_instance`. 0 means uncapped; ignored by the other rules.
@export var max_stacks: int = 0

## Firings of a subscribed source before this condition expires. -1 is indefinite.
@export var default_duration: int = ModelScript.INDEFINITE

## Stat deltas contributed once per stack, read by Unit.get_effective_stat()
## through the same view the rest of the transaction reads. A condition never
## writes a modifier: its contribution is derived from the held entry, so it is
## correct in a forecast, in a projection and in a resolved fight without anyone
## remembering to apply or revert it. Shape: [{"stat": String, "delta": int}].
@export var stat_modifiers: Array[Dictionary] = []

## Conditions carrying any of these tags cannot be applied while this condition
## is held. Immunity is condition-owned, not a table in the engine.
@export var tags: Array[String] = []
@export var immunity_tags: Array[String] = []

## Effect compositions prepared into the caller's transaction. Each is optional;
## a condition that only debuffs stats needs none of them.
@export var apply_composition: String = ""
@export var tick_composition: String = ""
@export var expire_composition: String = ""
@export var remove_composition: String = ""

## Map-scoped by default; an authored opt-in survives the map end, and a second
## opt-in survives the holder's death (owner ruling 5). Death cannot be survived
## without surviving the map, because a dead unit leaves the map either way.
@export var persists_across_maps: bool = false
@export var persists_through_death: bool = false


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if stacking not in ModelScript.STACKING_RULES:
		errors.append("ConditionDef '%s' has unknown stacking rule '%s'" % [id, stacking])
	if stacking == ModelScript.STACK_ADD_INSTANCE and max_stacks < 0:
		errors.append("ConditionDef '%s' has a negative stack cap" % id)
	if default_duration == 0 or default_duration < ModelScript.INDEFINITE:
		errors.append("ConditionDef '%s' default_duration must be -1 or at least 1" % id)
	if persists_through_death and not persists_across_maps:
		errors.append("ConditionDef '%s' cannot survive death without surviving the map" % id)
	for source in tick_sources:
		if String(source).strip_edges() == "":
			errors.append("ConditionDef '%s' subscribes to an unnamed tick source" % id)
	for raw in stat_modifiers:
		if not raw is Dictionary:
			errors.append("ConditionDef '%s' stat modifier is not a dictionary" % id)
			continue
		if String((raw as Dictionary).get("stat", "")).strip_edges() == "":
			errors.append("ConditionDef '%s' stat modifier is missing its stat" % id)
		if int((raw as Dictionary).get("delta", 0)) == 0:
			errors.append("ConditionDef '%s' stat modifier has no delta" % id)
	# A condition that ticks but has nothing to do on a tick, and never expires,
	# is inert authored content: the subscription reads as if it does something.
	if (
		not tick_sources.is_empty()
		and tick_composition == ""
		and default_duration == ModelScript.INDEFINITE
	):
		errors.append(
			"ConditionDef '%s' subscribes to a tick source but neither ticks nor expires" % id
		)
	return errors
