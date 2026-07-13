extends SceneTree

const RegistryManagerScript = preload("res://scripts/autoloads/RegistryManager.gd")
const RunnerScript = preload("res://scripts/actions/ActionPrimitiveRunner.gd")
const RequestScript = preload("res://scripts/actions/ActionRequest.gd")
const ContextScript = preload("res://scripts/actions/ActionContext.gd")


class MockUnit extends Node:
	var data := UnitData.new()

	func add_modifier(stat: String, delta: int, source: String,
			duration: int, duration_type: String) -> void:
		data.active_modifiers = data.active_modifiers.filter(
			func(modifier): return modifier.get("source", "") != source)
		data.active_modifiers.append({
			"stat": stat,
			"delta": delta,
			"source": source,
			"duration": duration,
			"duration_type": duration_type,
		})


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
	if not unknown.ok and unknown.failure_reason.get("code") == "unknown_primitive" \
			and unit.data.active_modifiers.is_empty():
		print("OK  unknown primitives return a structured failure without mutation"); passed += 1
	else:
		print("FAIL unknown primitive result: %s" % [unknown.failure_reason]); failed += 1

	var malformed_params := valid_params.duplicate(true)
	malformed_params["delta"] = "two"
	var malformed = runner.commit(RequestScript.new("apply_active_modifier", malformed_params), context)
	if not malformed.ok and malformed.failure_reason.get("code") == "invalid_param_type" \
			and unit.data.active_modifiers.is_empty():
		print("OK  malformed parameters fail before mutation"); passed += 1
	else:
		print("FAIL malformed result or mutation: %s %s" % [malformed.failure_reason, unit.data.active_modifiers]); failed += 1

	if runner.handler_id_for("apply_active_modifier") == "apply_active_modifier" \
			and runner.handler_id_for("missing") == "":
		print("OK  registry entries resolve deterministically to runtime handlers"); passed += 1
	else:
		print("FAIL handler resolution"); failed += 1

	var dry_context = ContextScript.new("map_event", {"actor": unit, "target": unit})
	dry_context.dry_run = true
	var dry_result = runner.commit(RequestScript.new("apply_active_modifier", valid_params), dry_context)
	if dry_result.ok and unit.data.active_modifiers.is_empty():
		print("OK  dry-run validates successfully without mutation"); passed += 1
	else:
		print("FAIL dry-run result or mutation"); failed += 1

	var committed = runner.commit(RequestScript.new("apply_active_modifier", valid_params), context)
	if committed.ok and unit.data.active_modifiers.size() == 1 \
			and committed.affected_ids == ["runner_target"] \
			and committed.save_fields_touched == ["UnitData.active_modifiers"]:
		print("OK  successful commit reports affected ids and save fields"); passed += 1
	else:
		print("FAIL success result: %s %s" % [unit.data.active_modifiers, committed.failure_reason]); failed += 1

	# A second domain reuses the same primitive and refreshes the same source.
	var map_params := valid_params.duplicate(true)
	map_params["delta"] = 3
	var map_context = ContextScript.new("map_event", {"actor": unit, "target": unit})
	var map_result = runner.commit(RequestScript.new("apply_active_modifier", map_params), map_context)
	if map_result.ok and unit.data.active_modifiers.size() == 1 \
			and unit.data.active_modifiers[0].delta == 3:
		print("OK  item and map_event domains share the same primitive"); passed += 1
	else:
		print("FAIL cross-domain primitive reuse: %s" % [unit.data.active_modifiers]); failed += 1

	unit.free()
	registry.free()
	runner = null
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
