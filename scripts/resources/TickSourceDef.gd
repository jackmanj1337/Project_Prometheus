class_name TickSourceDef
extends "res://scripts/resources/RegistryEntry.gd"

## A NAMED occasion on which subscribed conditions tick.
##
## The load-bearing word is named. The owner's direction of 2026-08-31 replaced
## "who calls tick_conditions" with "what publishes tick events, and how does a
## condition declare which ones it listens to" — and a bare `tick(unit)` call,
## a boolean, or an engine enum all fail the same test: an authored effect must
## be able to fire tick A without firing tick B, and only an addressable id can
## express that.
##
## So sources are an open registry like conditions themselves. The engine ships
## the ones it publishes; a pack authors its own and subscribes to it with no
## engine edit, and reaches it through the `fire_tick_source` primitive.

## Who fires this source. "engine" sources are published by an engine lifecycle
## point named in `lifecycle`; "authored" sources are fired only by an effect.
@export_enum("engine", "authored") var publisher: String = "authored"

## The engine lifecycle point that publishes this source. Engine sources declare
## one; authored sources leave it empty. This is a declaration, not a hook: it is
## what lets a pack SEE which occasions exist rather than guessing at ids.
@export var lifecycle: String = ""

## Whose conditions this firing ticks. "holder" fires for one named unit;
## "all_units" fires for every living unit, which is what a round-start source
## means. Named scope_of_firing rather than scope because the shared registry
## document schema already spends `scope` on the campaign-variable families.
@export_enum("holder", "all_units") var scope_of_firing: String = "holder"

# The lifecycle points TurnManager ACTUALLY publishes today. The owner's
# enumerated set also named the end of the holder's phase; TurnManager has no
# single point where every faction's phase ends, so `phase_end` is deliberately
# NOT listed. An authored source naming it therefore fails validation with a
# clear message instead of being admitted and then never firing — the inert
# authored content this whole family is meant to prevent. Adding it is a
# TurnManager change plus one entry here, tracked as its own row.
const ENGINE_LIFECYCLES: Array[String] = [
	"round_start",
	"phase_start",
	"turn_ending_action",
]


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if publisher == "engine":
		if lifecycle.strip_edges() == "":
			errors.append("TickSourceDef '%s' is an engine source with no lifecycle" % id)
		elif lifecycle not in ENGINE_LIFECYCLES:
			errors.append("TickSourceDef '%s' names unknown lifecycle '%s'" % [id, lifecycle])
	elif lifecycle.strip_edges() != "":
		errors.append("TickSourceDef '%s' is authored but claims an engine lifecycle" % id)
	return errors
