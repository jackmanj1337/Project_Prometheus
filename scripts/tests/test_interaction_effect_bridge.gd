extends SceneTree
# Slice 4 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: THE EFFECT BRIDGE.
# Slices 2 and 3 are about what a resolved interaction SAYS; this one is about what it
# DOES. The failures it can produce are quiet ones — a magnitude that leaves fixed point
# twice, or not at all; an authored param dropped on the way to a primitive; a composition
# that runs with a number nobody computed — so most of this file is about the boundary
# rather than about the arithmetic. `[ITR-1..7]`.

const Bridge = preload("res://scripts/interaction/InteractionEffectBridge.gd")
const Resolver = preload("res://scripts/interaction/InteractionRuleResolver.gd")
const Schema = preload("res://scripts/interaction/InteractionProfileSchema.gd")
const Formula = preload("res://scripts/req/FormulaEvaluator.gd")
const RequirementSystemScript = preload("res://scripts/autoloads/RequirementSystem.gd")
const RunnerScript = preload("res://scripts/actions/ActionPrimitiveRunner.gd")
const ContextScript = preload("res://scripts/actions/ActionContext.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")


# The shape `RequirementSystem._unit_data` reads, as in slices 2 and 3.
class StubSubject:
	extends RefCounted

	var groups: Array[String] = []

	func _init(in_groups: Array[String] = []) -> void:
		groups = in_groups


# A catalogue is a Node in production (RegistryManager) and a RefCounted in the catalogue
# itself; the bridge duck-types both, so the stub is the smaller of the two.
class StubCatalog:
	extends Node

	var entries: Dictionary = {}

	func has_entry(family: String, id: String) -> bool:
		return entries.has("%s:%s" % [family, id])

	func entry(family: String, id: String) -> Resource:
		return entries.get("%s:%s" % [family, id])


func _init() -> void:
	print("=== Interaction Effect Bridge Test ===")
	var failed := 0
	var requirements := RequirementSystemScript.new()
	requirements._ready()
	var deps := {"requirements": requirements}
	var swordsman := StubSubject.new(["sword"])
	var axeman := StubSubject.new(["axe"])
	var subjects := {
		"source": swordsman,
		"target": axeman,
		"equipped_source": swordsman,
		"equipped_target": axeman,
	}
	var catalog := _catalog()

	# --- the plan's declared shape ---------------------------------------------
	var envelope := Resolver.resolve(
		[_profile({"rules": [_rule({"effects": [_effect({"magnitude": {"literal": 3}})]})]})],
		"combat",
		subjects,
		deps
	)
	var plan := Bridge.plan(envelope, {"catalog": catalog})
	failed += _check(
		_keys(plan) == _sorted(Bridge.PLAN_FIELDS),
		"plan() returns EXACTLY PLAN_FIELDS, so a consumer has one declared shape to read"
	)
	failed += _check(
		plan["effects"].size() == 1 and _keys(plan["effects"][0]) == _sorted(Bridge.EFFECT_FIELDS),
		"a planned effect is EXACTLY EFFECT_FIELDS"
	)
	failed += _check(
		String(plan["context"]) == "combat", "the plan carries the context it was resolved for"
	)

	# --- the single conversion out of fixed point ------------------------------
	var planned: Dictionary = plan["effects"][0]
	failed += _check(
		int(planned["magnitude_fixed"]) == 3 * Formula.SCALE,
		"the planned effect still carries the FIXED-POINT magnitude, for a readout to show"
	)
	failed += _check(
		int(planned["magnitude"]) == 3,
		"...and the converted one beside it: an authored 3 reaches a primitive as 3, not 3000"
	)
	failed += _check(
		int((planned["step_overrides"]["modify"]["params"] as Dictionary)["delta"]) == 3,
		"the magnitude is bound into the parameter the STEP names, already converted"
	)
	# Halfway cases are where a second conversion written at the boundary would disagree
	# with the evaluator, so they are asserted against the evaluator's own helper.
	failed += _check(
		Formula.to_int(1500) == 2 and Formula.to_int(-1500) == -2,
		"to_int rounds half AWAY FROM ZERO, so a bonus and its mirrored penalty agree"
	)

	# --- authored params survive the trip --------------------------------------
	var with_params := (
		Bridge
		. plan(
			(
				Resolver
				. resolve(
					[
						_profile(
							{
								"rules":
								[
									_rule(
										{
											"effects":
											[
												_effect(
													{
														"params": {"stat": "hit", "duration": 1},
														"magnitude": {"literal": 4},
													}
												)
											]
										}
									)
								]
							}
						)
					],
					"combat",
					subjects,
					deps
				)
			),
			{"catalog": catalog}
		)
	)
	var merged: Dictionary = with_params["effects"][0]["step_overrides"]["modify"]["params"]
	failed += _check(
		String(merged.get("stat", "")) == "hit" and int(merged.get("duration", 0)) == 1,
		"the authored params reach the step beside the magnitude, not instead of it"
	)
	failed += _check(
		int(merged.get("delta", 0)) == 4, "...and the magnitude does not overwrite them either"
	)

	# --- the authored target wins, but only over a SUBJECT ---------------------
	var target_override: Dictionary = with_params["effects"][0]["step_overrides"]["modify"]
	failed += _check(
		String((target_override["target"] as Dictionary)["key"]) == "source",
		"a subject step is re-aimed at the subject the AUTHORED effect names"
	)
	var tile_plan := Bridge.plan(
		Resolver.resolve(
			[
				_profile(
					{
						"rules":
						[_rule({"effects": [_effect({"composition_id": "tile_composition"})]})]
					}
				)
			],
			"combat",
			subjects,
			deps
		),
		{"catalog": catalog}
	)
	failed += _check(
		not (tile_plan["effects"][0]["step_overrides"]["mark"] as Dictionary).has("target"),
		"a step aimed at a TILE is left alone: no interaction profile can name a tile"
	)

	# --- the ruling slice 3 left open: an unavailable magnitude ----------------
	#
	# `all` is the only policy that passes one through, so both halves of the ruling are
	# asserted under it: the composition that binds a magnitude refuses, and the one that
	# binds none runs.
	var broken := {"source_id": "nowhere"}
	var unavailable_reading := (
		Bridge
		. plan(
			(
				Resolver
				. resolve(
					[
						_profile(
							{
								"stack_policy": "all",
								"rules": [_rule({"effects": [_effect({"magnitude": broken})]})],
							}
						)
					],
					"combat",
					subjects,
					deps
				)
			),
			{"catalog": catalog}
		)
	)
	failed += _check(
		unavailable_reading["effects"].is_empty() and unavailable_reading["skipped"].size() == 1,
		"an unavailable magnitude does NOT run a composition that binds one"
	)
	failed += _check(
		String(unavailable_reading["skipped"][0]["reason"]).contains("could not be evaluated"),
		"...and the skip says why, because a silent drop is this system's worst failure"
	)
	var unavailable_ignoring := (
		Bridge
		. plan(
			(
				Resolver
				. resolve(
					[
						_profile(
							{
								"stack_policy": "all",
								"rules":
								[
									_rule(
										{
											"effects":
											[
												_effect(
													{
														"composition_id": "flag_composition",
														"magnitude": broken,
													}
												)
											]
										}
									)
								],
							}
						)
					],
					"combat",
					subjects,
					deps
				)
			),
			{"catalog": catalog}
		)
	)
	failed += _check(
		unavailable_ignoring["effects"].size() == 1,
		"a composition that binds NO magnitude still runs: it was never going to read one"
	)
	failed += _check(
		not bool(unavailable_ignoring["effects"][0]["reads_magnitude"]),
		"...and it says so, so a reader can tell the two cases apart"
	)

	# --- refusals --------------------------------------------------------------
	var unknown := Bridge.plan(
		Resolver.resolve(
			[
				_profile(
					{"rules": [_rule({"effects": [_effect({"composition_id": "not_registered"})]})]}
				)
			],
			"combat",
			subjects,
			deps
		),
		{"catalog": catalog}
	)
	failed += _check(
		(
			unknown["effects"].is_empty()
			and String(unknown["skipped"][0]["reason"]).contains("not in the registry catalogue")
		),
		"a composition id the catalogue does not hold is skipped with the reason, not run"
	)
	var undeclared := (
		Bridge
		. plan(
			(
				Resolver
				. resolve(
					[
						_profile(
							{
								"rules":
								[
									_rule(
										{
											"effects":
											[
												_effect(
													{
														"composition_id": "mistyped_composition",
														"magnitude": {"literal": 1},
													}
												)
											]
										}
									)
								]
							}
						)
					],
					"combat",
					subjects,
					deps
				)
			),
			{"catalog": catalog}
		)
	)
	failed += _check(
		(
			undeclared["effects"].is_empty()
			and String(undeclared["skipped"][0]["reason"]).contains("does not declare")
		),
		"a magnitude bound to a parameter the primitive never declared is refused"
	)
	var no_catalog := Bridge.plan(envelope, {})
	failed += _check(
		_has_error_text(no_catalog["errors"], "no registry catalogue"),
		"a missing catalogue is REPORTED: 'nothing resolved' must not read as 'nothing applies'"
	)
	failed += _check(
		_has_error_text(Bridge.plan({}, {"catalog": catalog})["errors"], "not a resolver envelope"),
		"a dictionary that is not an envelope is refused against the CONTRACT, not one key"
	)
	var resolver_failure := Bridge.plan(
		Resolver.resolve([_profile({})], "no_such_context", subjects, deps), {"catalog": catalog}
	)
	failed += _check(
		_has_error_text(resolver_failure["errors"], "resolver:"),
		"the resolver's own errors are carried into the plan, labelled as its"
	)

	# --- the double-apply trap -------------------------------------------------
	var two := (
		Resolver
		. resolve(
			[
				_profile(
					{
						"stack_policy": "all",
						"rules":
						[
							_rule({"effects": [_effect({"magnitude": {"literal": 1}})]}),
							_rule(
								{
									"rule_id": "r2",
									"effects": [_effect({"magnitude": {"literal": 2}})],
								}
							),
						],
					}
				)
			],
			"combat",
			subjects,
			deps
		)
	)
	var per_record: Array = []
	for record in two["records"]:
		per_record.append_array(record["effects"] as Array)
	failed += _check(
		(two["effects"] as Array).size() == per_record.size(),
		"envelope.effects and the records' effects are the SAME list, so a consumer picks one"
	)
	failed += _check(
		Bridge.plan(two, {"catalog": catalog})["effects"].size() == 2,
		"...and the bridge plans it ONCE: two matched rules are two effects, not four"
	)

	# --- apply() prepares into the caller's transaction ------------------------
	failed += _apply_checks()

	print("=== Interaction Effect Bridge Results: %d failed ===" % failed)
	quit(1 if failed else 0)


# The end-to-end half: a real `ActionPrimitiveRunner` over a real primitive, driven by a
# plan the bridge built from a real envelope. It asserts the thing no unit check can —
# that the step overrides the bridge computes are a shape the runner actually accepts.
func _apply_checks() -> int:
	var failed := 0
	var requirements := RequirementSystemScript.new()
	requirements._ready()
	var subjects := {
		"source": StubSubject.new(["sword"]),
		"target": StubSubject.new(["axe"]),
		"equipped_source": StubSubject.new(["sword"]),
		"equipped_target": StubSubject.new(["axe"]),
	}
	var envelope := (
		Resolver
		. resolve(
			[
				_profile(
					{
						"rules":
						[
							_rule(
								{
									"effects":
									[
										_effect(
											{
												"composition_id": "campaign_composition",
												"params":
												{
													"authority_id": "campaign",
													"save_field": "campaign_vars.proof",
												},
												"magnitude": {"literal": 7},
											}
										)
									]
								}
							)
						]
					}
				)
			],
			"combat",
			subjects,
			{"requirements": requirements}
		)
	)
	var catalog := _catalog()
	var plan := Bridge.plan(envelope, {"catalog": catalog})
	var runner = RunnerScript.new(catalog)
	var live := {"campaign_vars.proof": 0}
	var context = ContextScript.new("combat", {})
	context.target_refs["campaign"] = "proof_campaign"
	context.state_view = load("res://scripts/actions/EffectStateView.gd").new()
	context.state_view.register_authority(
		"campaign",
		func(field, _ref): return live[field],
		func(field, _ref, value): live[field] = value
	)
	var applied = Bridge.apply(plan, runner, context)
	failed += _check(applied.ok, "apply() prepares a planned composition through the real runner")
	failed += _check(
		live["campaign_vars.proof"] == 0,
		"...and COMMITS NOTHING: the write is in the transaction, not in the authority"
	)
	var journal: Array = context.state_view.journal.duplicate_entries()
	failed += _check(
		journal.size() == 1 and int(journal[0]["value"]) == 7,
		"the authored magnitude reached the primitive as the prepared value"
	)
	failed += _check(
		applied.steps.size() == 1 and String(applied.steps[0].step_id) == "campaign_composition",
		"each prepared composition is a step on the aggregate, named by its composition id"
	)
	var no_runner = Bridge.apply(plan, null, context)
	failed += _check(
		not no_runner.ok and String(no_runner.failure_reason["code"]) == "no_runner",
		"apply() without a runner fails rather than reporting an empty success"
	)
	return failed


# The catalogue these fixtures name. Written out rather than loaded from engine_data so
# the suite states the composition shapes it depends on instead of inheriting them.
func _catalog() -> Node:
	var catalog := StubCatalog.new()
	catalog.entries["action_primitives:apply_active_modifier"] = _primitive(
		"apply_active_modifier",
		{
			"delta": {"type": "int", "required": true},
			"stat": {"type": "string", "required": false},
			"duration": {"type": "int", "required": false},
		}
	)
	catalog.entries["action_primitives:set_campaign_value"] = _primitive(
		"set_campaign_value",
		{
			"authority_id": {"type": "string", "required": true},
			"save_field": {"type": "string", "required": true},
			"value": {"type": "int", "required": true},
		},
		"set_state_value"
	)
	catalog.entries["action_primitives:reveal_fog_units"] = _primitive("reveal_fog_units", {})
	catalog.entries["effect_compositions:combat_damage_modifier"] = _composition(
		"combat_damage_modifier",
		[
			{
				"step_id": "modify",
				"primitive_id": "apply_active_modifier",
				"params": {"stat": "damage"},
				"target": {"kind": "subject", "key": "target"},
				"magnitude_param": "delta",
			}
		]
	)
	# Binds no magnitude at all — the half of the slice 3 ruling that must still run.
	catalog.entries["effect_compositions:flag_composition"] = _composition(
		"flag_composition",
		[
			{
				"step_id": "flag",
				"primitive_id": "reveal_fog_units",
				"params": {},
				"target": {"kind": "subject", "key": "target"},
			}
		]
	)
	catalog.entries["effect_compositions:tile_composition"] = _composition(
		"tile_composition",
		[
			{
				"step_id": "mark",
				"primitive_id": "reveal_fog_units",
				"params": {},
				"target": {"kind": "tile", "key": "tile"},
			}
		]
	)
	# Names a parameter its primitive does not declare: the authoring mistake the bridge
	# cross-checks at plan time, because the registry cannot check it at register time.
	catalog.entries["effect_compositions:mistyped_composition"] = _composition(
		"mistyped_composition",
		[
			{
				"step_id": "modify",
				"primitive_id": "apply_active_modifier",
				"params": {},
				"target": {"kind": "subject", "key": "target"},
				"magnitude_param": "amount",
			}
		]
	)
	catalog.entries["effect_compositions:campaign_composition"] = _composition(
		"campaign_composition",
		[
			{
				"step_id": "write",
				"primitive_id": "set_campaign_value",
				"params": {},
				"target": {"kind": "campaign"},
				"magnitude_param": "value",
			}
		]
	)
	return catalog


func _primitive(id: String, params_schema: Dictionary, handler: String = "") -> Resource:
	var entry := RegistryEntryScript.new()
	entry.id = id
	entry.family = "action_primitives"
	entry.kind = "mutation"
	entry.primitive_handler = handler if handler != "" else id
	entry.params_schema = params_schema
	entry.save_fields = ["campaign_vars.proof", "UnitData.active_modifiers"]
	return entry


func _composition(id: String, steps: Array) -> Resource:
	var entry := RegistryEntryScript.new()
	entry.id = id
	entry.family = "effect_compositions"
	entry.kind = "composition"
	var typed: Array[Dictionary] = []
	for step in steps:
		typed.append(step as Dictionary)
	entry.composition = typed
	return entry


func _profile(overrides: Dictionary) -> Dictionary:
	var profile := {
		"profile_id": "p1",
		"context": "combat",
		"subjects": ["source", "target", "equipped_source"],
		"priority": 10,
		"stack_group": "group_a",
		"stack_policy": "highest",
		"stops_below": false,
		"rules": [_rule({})],
	}
	for key in overrides:
		profile[key] = overrides[key]
	return profile


func _rule(overrides: Dictionary) -> Dictionary:
	var rule := {
		"rule_id": "r1",
		"when":
		{"predicate_id": "has_trait", "subject": {"kind": "source"}, "params": {"id": "sword"}},
		"effects": [_effect({})],
	}
	for key in overrides:
		rule[key] = overrides[key]
	return rule


func _effect(overrides: Dictionary) -> Dictionary:
	var effect := {"composition_id": "combat_damage_modifier", "target": "source"}
	for key in overrides:
		effect[key] = overrides[key]
	return effect


func _keys(value: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for key in value.keys():
		out.append(String(key))
	out.sort()
	return out


func _sorted(values: Array[String]) -> Array[String]:
	var out: Array[String] = values.duplicate()
	out.sort()
	return out


func _has_error_text(errors: Array, fragment: String) -> bool:
	for message in errors:
		if String(message).contains(fragment):
			return true
	return false


func _check(ok: bool, label: String) -> int:
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
