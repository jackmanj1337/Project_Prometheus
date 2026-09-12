extends SceneTree

const RegistryManagerScript = preload("res://scripts/autoloads/RegistryManager.gd")
const RunnerScript = preload("res://scripts/actions/ActionPrimitiveRunner.gd")
const RequestScript = preload("res://scripts/actions/ActionRequest.gd")
const ContextScript = preload("res://scripts/actions/ActionContext.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")


class MockUnit:
	extends Node
	var data := UnitData.new()

	func add_modifier(
		stat: String, delta: int, source: String, duration: int, duration_type: String
	) -> void:
		data.active_modifiers = data.active_modifiers.filter(
			func(modifier): return modifier.get("source", "") != source
		)
		(
			data
			. active_modifiers
			. append(
				{
					"stat": stat,
					"delta": delta,
					"source": source,
					"duration": duration,
					"duration_type": duration_type,
				}
			)
		)


class StubRegistry:
	extends Node
	var registry_entry: Resource

	func has_entry(family: String, id: String) -> bool:
		return family == "action_primitives" and id == registry_entry.id

	func entry(_family: String, _id: String) -> Resource:
		return registry_entry


class CompositionRegistry:
	extends Node
	var entries: Dictionary = {}

	func has_entry(family: String, id: String) -> bool:
		return entries.has("%s:%s" % [family, id])

	func entry(family: String, id: String) -> Resource:
		return entries.get("%s:%s" % [family, id])


func _init() -> void:
	print("=== ActionEffectRunner Test ===")
	var passed := 0
	var failed := 0
	var registry := RegistryManagerScript.new()
	registry.reload_presets()
	var runner = RunnerScript.new(registry)
	var unit := MockUnit.new()
	unit.data.unit_id = "runner_target"
	var valid_params := {
		"stat": "strength",
		"delta": 2,
		"source": "test:modifier",
		"duration": 1,
		"duration_type": "turn",
	}
	var context = ContextScript.new("item", {"actor": unit, "target": unit})

	var unknown = runner.commit(RequestScript.new("missing", {}), context)
	if (
		not unknown.ok
		and unknown.failure_reason.get("code") == "unknown_primitive"
		and unit.data.active_modifiers.is_empty()
	):
		print("OK  unknown primitives return a structured failure without mutation")
		passed += 1
	else:
		print("FAIL unknown primitive result: %s" % [unknown.failure_reason])
		failed += 1

	var malformed_params := valid_params.duplicate(true)
	malformed_params["delta"] = "two"
	var malformed = runner.commit(
		RequestScript.new("apply_active_modifier", malformed_params), context
	)
	if (
		not malformed.ok
		and malformed.failure_reason.get("code") == "invalid_param_type"
		and unit.data.active_modifiers.is_empty()
	):
		print("OK  malformed parameters fail before mutation")
		passed += 1
	else:
		print(
			(
				"FAIL malformed result or mutation: %s %s"
				% [malformed.failure_reason, unit.data.active_modifiers]
			)
		)
		failed += 1

	if (
		runner.handler_id_for("apply_active_modifier") == "apply_active_modifier"
		and runner.handler_id_for("missing") == ""
	):
		print("OK  registry entries resolve deterministically to runtime handlers")
		passed += 1
	else:
		print("FAIL handler resolution")
		failed += 1

	var dry_context = ContextScript.new("map_event", {"actor": unit, "target": unit})
	dry_context.dry_run = true
	var dry_result = runner.commit(
		RequestScript.new("apply_active_modifier", valid_params), dry_context
	)
	if dry_result.ok and unit.data.active_modifiers.is_empty():
		print("OK  dry-run validates successfully without mutation")
		passed += 1
	else:
		print("FAIL dry-run result or mutation")
		failed += 1

	var committed = runner.commit(RequestScript.new("apply_active_modifier", valid_params), context)
	if (
		committed.ok
		and unit.data.active_modifiers.size() == 1
		and committed.affected_ids == ["runner_target"]
		and committed.save_fields_touched == ["UnitData.active_modifiers"]
	):
		print("OK  successful commit reports affected ids and save fields")
		passed += 1
	else:
		print("FAIL success result: %s %s" % [unit.data.active_modifiers, committed.failure_reason])
		failed += 1

	# Optional schema fields must reach the handler through their neutral defaults
	# instead of crashing after validation succeeds.
	var optional_entry: Resource = RegistryEntryScript.new()
	optional_entry.id = "optional_modifier"
	optional_entry.family = "action_primitives"
	optional_entry.primitive_handler = "apply_active_modifier"
	optional_entry.subjects.assign(["actor", "target"])
	optional_entry.params_schema = {
		"stat": {"type": "string"},
		"delta": {"type": "int"},
		"source": {"type": "string"},
		"duration": {"type": "int"},
		"duration_type": {"type": "string"},
	}
	var stub_registry := StubRegistry.new()
	stub_registry.registry_entry = optional_entry
	var optional_runner = RunnerScript.new(stub_registry)
	unit.data.active_modifiers.clear()
	var optional_result = optional_runner.commit(
		RequestScript.new("optional_modifier", {}), context
	)
	if (
		optional_result.ok
		and unit.data.active_modifiers.size() == 1
		and (
			unit.data.active_modifiers[0]
			== {"stat": "", "delta": 0, "source": "", "duration": 0, "duration_type": ""}
		)
	):
		print("OK  omitted optional parameters commit with neutral defaults")
		passed += 1
	else:
		print(
			(
				"FAIL optional parameter defaults: %s %s"
				% [optional_result.failure_reason, unit.data.active_modifiers]
			)
		)
		failed += 1
	unit.data.active_modifiers.clear()

	# A second domain reuses the same primitive and refreshes the same source.
	var map_params := valid_params.duplicate(true)
	map_params["delta"] = 3
	var map_context = ContextScript.new("map_event", {"actor": unit, "target": unit})
	var map_result = runner.commit(
		RequestScript.new("apply_active_modifier", map_params), map_context
	)
	if (
		map_result.ok
		and unit.data.active_modifiers.size() == 1
		and unit.data.active_modifiers[0].delta == 3
	):
		print("OK  item and map_event domains share the same primitive")
		passed += 1
	else:
		print("FAIL cross-domain primitive reuse: %s" % [unit.data.active_modifiers])
		failed += 1

	var primitive := RegistryEntryScript.new()
	primitive.id = "set_campaign_value"
	primitive.family = "action_primitives"
	primitive.primitive_handler = "set_state_value"
	primitive.params_schema = {
		"authority_id": {"type": "string", "required": true},
		"save_field": {"type": "string", "required": true},
		"value": {"type": "variant", "required": true},
	}
	primitive.save_fields.assign(["campaign_vars.proof"])
	var composition := RegistryEntryScript.new()
	composition.id = "cross_source_proof"
	composition.family = "effect_compositions"
	(
		composition
		. composition
		. assign(
			[
				{
					"step_id": "first",
					"primitive_id": "set_campaign_value",
					"params":
					{"authority_id": "campaign", "save_field": "campaign_vars.proof", "value": 1},
					"target": {"kind": "campaign"},
				},
				{
					"step_id": "second",
					"primitive_id": "set_campaign_value",
					"params":
					{"authority_id": "campaign", "save_field": "campaign_vars.proof", "value": 2},
					"target": {"kind": "campaign"},
				},
			]
		)
	)
	var composition_registry := CompositionRegistry.new()
	composition_registry.entries["action_primitives:set_campaign_value"] = primitive
	composition_registry.entries["effect_compositions:cross_source_proof"] = composition
	var composition_runner = RunnerScript.new(composition_registry)
	var live := {"campaign_vars.proof": 0}
	var proof_context = ContextScript.new("story", {})
	proof_context.target_refs["campaign"] = "proof_campaign"
	proof_context.state_view = load("res://scripts/actions/EffectStateView.gd").new()
	proof_context.state_view.register_authority(
		"campaign",
		func(field, _ref): return live[field],
		func(field, _ref, value): live[field] = value
	)
	var prepared = composition_runner.prepare_composition("cross_source_proof", proof_context)
	if (
		prepared.ok
		and live["campaign_vars.proof"] == 0
		and prepared.deltas.map(func(delta): return delta.after) == [1, 2]
		and prepared.save_fields_touched == ["campaign_vars.proof"]
	):
		print("OK  ordered composition prepare reports deltas without live mutation")
		passed += 1
	else:
		print("FAIL composition prepare: %s %s" % [prepared.failure_reason, prepared.deltas])
		failed += 1
	var committed_proof = composition_runner.commit_composition("cross_source_proof", proof_context)
	if committed_proof.ok and live["campaign_vars.proof"] == 2:
		print("OK  composition commit applies the prepared primitive in order")
		passed += 1
	else:
		print("FAIL composition commit: %s %s" % [committed_proof.failure_reason, live])
		failed += 1
	composition_registry.free()

	unit.free()
	registry.free()
	runner = null
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
