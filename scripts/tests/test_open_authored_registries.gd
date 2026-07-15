extends SceneTree
# Objective conditions and item effects grow by registration, while legacy ids
# keep their validation/display/evaluation/preview/commit behavior.

const ObjectiveRegistry = preload("res://scripts/registries/ObjectiveConditionRegistry.gd")
const ItemRegistry = preload("res://scripts/registries/ItemEffectRegistry.gd")


func _init() -> void:
	var passed := 0
	var failed := 0
	var objectives := ObjectiveRegistry.new()
	var expected_objectives := [
		"defeat_boss", "escape", "protect", "rout", "seize", "survive", "turn_limit"
	]
	if objectives.ids() == expected_objectives:
		print("OK  legacy objective ids are registered unchanged")
		passed += 1
	else:
		print("FAIL objective compatibility ids: %s" % [objectives.ids()])
		failed += 1
	if not objectives.register_condition("rout", "rout", "rout", "rout").is_empty():
		print("OK  duplicate objective ids fail loud")
		passed += 1
	else:
		print("FAIL duplicate objective id accepted")
		failed += 1
	var unknown := ObjectiveCondition.new()
	unknown.type = "missing_condition"
	if (
		objectives.display_text(unknown) == ""
		and not objectives.evaluate(unknown, "allies", null)
		and not objectives.validate(unknown, _objective_context()).is_empty()
	):
		print("OK  unknown objective ids fail validation and remain unmet")
		passed += 1
	else:
		print("FAIL unknown objective behavior")
		failed += 1

	objectives.register_validation_handler("custom", Callable(self, "_valid_objective"))
	objectives.register_display_handler("custom", Callable(self, "_display_objective"))
	objectives.register_evaluation_handler("custom", Callable(self, "_evaluate_objective"))
	var custom_registration := objectives.register_condition(
		"custom_counter", "custom", "custom", "custom"
	)
	var custom := ObjectiveCondition.new()
	custom.type = "custom_counter"
	custom.turns = 3
	if (
		custom_registration.is_empty()
		and objectives.validate(custom, _objective_context()).is_empty()
		and objectives.display_text(custom) == "Custom 3"
		and objectives.evaluate(custom, "allies", null)
	):
		print(
			"OK  a new objective registers validation, display, and evaluation without switch edits"
		)
		passed += 1
	else:
		print("FAIL custom objective registration")
		failed += 1

	var items := ItemRegistry.new()
	var expected_items := ["heal_flat", "heal_full", "promote", "reclass", "stat_buff"]
	if items.ids() == expected_items:
		print("OK  legacy item-effect ids are registered unchanged")
		passed += 1
	else:
		print("FAIL item compatibility ids: %s" % [items.ids()])
		failed += 1
	if not items.register_effect("heal_flat", "amount", "heal_flat").is_empty():
		print("OK  duplicate item-effect ids fail loud")
		passed += 1
	else:
		print("FAIL duplicate item-effect id accepted")
		failed += 1
	var unknown_item := ItemData.new()
	unknown_item.id = "unknown"
	unknown_item.effect_id = "missing_effect"
	if (
		not items.validate_item(unknown_item, {}).is_empty()
		and not items.preview(unknown_item.effect_id, null, unknown_item).get("ok", false)
		and not items.commit(unknown_item.effect_id, null, unknown_item).get("ok", false)
	):
		print("OK  unknown item effects fail validation, preview, and commit")
		passed += 1
	else:
		print("FAIL unknown item-effect behavior")
		failed += 1

	items.register_validation_handler("custom", Callable(self, "_valid_item"))
	items.register_runtime_handler(
		"custom",
		Callable(self, "_can_item"),
		Callable(self, "_preview_item"),
		Callable(self, "_commit_item")
	)
	var item_registration := items.register_effect("custom_charge", "custom", "custom", "custom")
	var custom_item := ItemData.new()
	custom_item.id = "charge"
	custom_item.effect_id = "custom_charge"
	if (
		item_registration.is_empty()
		and items.validate_item(custom_item, {}).is_empty()
		and items.can_apply(custom_item.effect_id, null, custom_item)
		and items.preview(custom_item.effect_id, null, custom_item).get("mode", "") == "custom"
		and items.commit(custom_item.effect_id, null, custom_item).get("committed", false)
	):
		print(
			"OK  a new item effect registers validation, preview, and commit without switch edits"
		)
		passed += 1
	else:
		print("FAIL custom item-effect registration")
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed else 0)


func _objective_context() -> Dictionary:
	return {
		"map_path": "fixture",
		"field_name": "victory_conditions",
		"group_name": "allies",
		"faction_ids": {},
		"alliance_groups": {},
		"width": 10,
		"height": 10
	}


func _valid_objective(_condition: ObjectiveCondition, _context: Dictionary) -> Array[String]:
	return []


func _display_objective(condition: ObjectiveCondition) -> String:
	return "Custom %d" % condition.turns


func _evaluate_objective(condition: ObjectiveCondition, _group: String, _state: Node) -> bool:
	return condition.turns == 3


func _valid_item(_item: ItemData, _classes: Dictionary) -> Array[String]:
	return []


func _can_item(_unit: Node, _item: ItemData) -> bool:
	return true


func _preview_item(_unit: Node, _item: ItemData) -> Dictionary:
	return {"ok": true}


func _commit_item(_unit: Node, _item: ItemData) -> Dictionary:
	return {"ok": true, "consume": true, "committed": true}
