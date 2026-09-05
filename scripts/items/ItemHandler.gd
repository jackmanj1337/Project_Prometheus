extends Node
# Centralised item-effect dispatcher. Mirrors SkillHandler's design: callers pass
# the unit and the inventory entry dict; all item logic lives here so MapCursor
# and future AI systems stay free of item mechanics.

const ActionRequestScript = preload("res://scripts/actions/ActionRequest.gd")
const ActionContextScript = preload("res://scripts/actions/ActionContext.gd")
const ItemEffectRegistryScript = preload("res://scripts/registries/ItemEffectRegistry.gd")
const EffectTransactionScript = preload("res://scripts/actions/EffectTransaction.gd")
const CustodyScript = preload("res://scripts/items/InventoryCustodyParticipant.gd")

var _effects: RefCounted


# Uses an item: its effect and the custody of the entry it came from land
# together or not at all.
#
# This used to be two writes in sequence — commit the effect, then decrement the
# entry. An effect that declined halfway left the item spent, and an effect that
# succeeded against an entry traded away in the meantime consumed nothing. Both
# halves are now prepared into one transaction: custody is a participant that
# can refuse, and the effect is journalled.
#
# Returns the transaction outcome so callers can tell a refusal from a use.
func apply_item(unit: Node, entry: InventoryEntry) -> Dictionary:
	if unit == null or unit.data == null or entry == null:
		return {"ok": false, "code": "invalid_request"}
	if entry.item_id.is_empty():
		return {"ok": false, "code": "invalid_request"}
	var item: ItemData = _item_from_entry(entry)
	if item == null:
		return {"ok": false, "code": "unknown_item"}
	if not can_apply_item(unit, entry):
		push_warning(
			(
				"ItemHandler: item '%s' is not currently usable by '%s'"
				% [item.id, unit.data.unit_name]
			)
		)
		return {"ok": false, "code": "not_usable"}

	var transaction := EffectTransactionScript.new()
	var result: Dictionary = _effect_registry().prepare(item.effect_id, unit, item, transaction)
	if not result.get("ok", false):
		if result.get("error", "") == "screen_required":
			push_warning(
				(
					"ItemHandler: '%s' items must be resolved through their modal screen"
					% item.effect_id
				)
			)
		else:
			push_warning("ItemHandler: unknown or failed effect_id '%s'" % item.effect_id)
		return {"ok": false, "code": String(result.get("error", "effect_declined"))}

	if result.get("consume", true):
		var custody: RefCounted = CustodyScript.new()
		var held: Dictionary = custody.plan(unit, entry)
		if not held.get("ok", false):
			push_warning("ItemHandler: '%s' is no longer held as prepared" % item.id)
			return held
		transaction.add_participant(custody)

	var outcome: Dictionary = transaction.commit()
	if not outcome.get("ok", false):
		push_warning(
			"ItemHandler: '%s' was not applied (%s)" % [item.id, String(outcome.get("code", ""))]
		)
		return outcome
	transaction.flush_presentation(get_node_or_null("/root/EventBus"))
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("item_used"):
		bus.item_used.emit(unit, item.id)
	return outcome


func can_apply_item(unit: Node, entry: InventoryEntry) -> bool:
	if unit == null or unit.data == null or entry == null or entry.item_id.is_empty():
		return false
	if not entry.has_uses():
		return false
	var item: ItemData = _item_from_entry(entry)
	if item == null:
		return false
	return _effect_registry().can_apply(item.effect_id, unit, item)


func preview_item(unit: Node, entry: InventoryEntry) -> Dictionary:
	var item := _item_from_entry(entry)
	if item == null or not can_apply_item(unit, entry):
		return {"ok": false, "mode": "", "error": "not_usable"}
	return _effect_registry().preview(item.effect_id, unit, item)


# Spends one use outside a transaction. Kept for callers that have nothing else
# to make atomic with it; anything that also changes unit state should take
# custody through InventoryCustodyParticipant instead, so the two land together.
func consume_entry(unit: Node, entry: InventoryEntry) -> void:
	if unit == null or unit.data == null or entry == null:
		return
	if entry.uses_remaining == -1:
		return  # infinite-use item: never consumed
	entry.uses_remaining -= 1
	if entry.uses_remaining <= 0:
		unit.data.inventory.erase(entry)


func get_item_data(entry: InventoryEntry) -> ItemData:
	return _item_from_entry(entry)


func _item_from_entry(entry: InventoryEntry) -> ItemData:
	if entry == null or entry.item_id.is_empty():
		return null
	var dm := get_node_or_null("/root/DataManager")
	if dm == null:
		return null
	var item: ItemData = dm.get_item(entry.item_id)
	if item == null:
		push_warning("ItemHandler: unknown item_id '%s'" % entry.item_id)
	return item


func _can_apply_promotion_item(unit: Node, item: ItemData) -> bool:
	if unit == null or not unit.has_method("can_promote") or not unit.can_promote():
		return false
	var class_data := _class_data_for(unit)
	if class_data == null:
		return false
	var allowed_classes: Array = item.effect_params.get("allowed_classes", [])
	var allowed_groups: Array = item.effect_params.get("allowed_class_groups", [])
	if allowed_classes.is_empty() and allowed_groups.is_empty():
		return true
	if String(unit.data.class_id) in allowed_classes:
		return true
	for group_id in allowed_groups:
		if String(group_id) in class_data.class_groups:
			return true
	return false


func _class_data_for(unit: Node) -> ClassData:
	if unit == null or unit.data == null:
		return null
	var dm := get_node_or_null("/root/DataManager")
	return dm.get_class_data(unit.data.class_id) if dm != null else null


func _effect_registry() -> RefCounted:
	if _effects != null:
		return _effects
	_effects = ItemEffectRegistryScript.new()
	_effects.register_runtime_handler(
		"heal_flat",
		Callable(self, "_can_direct"),
		Callable(self, "_preview_direct"),
		Callable(self, "_prepare_heal_flat")
	)
	_effects.register_runtime_handler(
		"heal_full",
		Callable(self, "_can_direct"),
		Callable(self, "_preview_direct"),
		Callable(self, "_prepare_heal_full")
	)
	_effects.register_runtime_handler(
		"promote",
		Callable(self, "_can_promote"),
		Callable(self, "_preview_promotion"),
		Callable(self, "_prepare_screen_required")
	)
	_effects.register_runtime_handler(
		"reclass",
		Callable(self, "_can_reclass"),
		Callable(self, "_preview_reclass"),
		Callable(self, "_prepare_screen_required")
	)
	_effects.register_runtime_handler(
		"stat_buff",
		Callable(self, "_can_stat_buff"),
		Callable(self, "_preview_direct"),
		Callable(self, "_prepare_stat_buff")
	)
	return _effects


func _can_direct(_unit: Node, _item: ItemData) -> bool:
	return true


func _can_promote(unit: Node, item: ItemData) -> bool:
	return _can_apply_promotion_item(unit, item)


func _can_reclass(unit: Node, _item: ItemData) -> bool:
	return unit.has_method("can_use_second_seal") and unit.can_use_second_seal()


func _can_stat_buff(unit: Node, _item: ItemData) -> bool:
	return unit.has_method("add_modifier")


func _preview_direct(_unit: Node, _item: ItemData) -> Dictionary:
	return {"ok": true, "mode": "direct"}


func _preview_promotion(_unit: Node, _item: ItemData) -> Dictionary:
	return {"ok": true, "mode": "promotion"}


func _preview_reclass(_unit: Node, _item: ItemData) -> Dictionary:
	return {"ok": true, "mode": "reclass"}


# Every direct effect below prepares through UnitStateSink — the same primitive
# combat and skills prepare through. There is no item-private way to move HP or
# stamp a modifier any more.
func _prepare_heal_flat(unit: Node, item: ItemData, transaction: RefCounted) -> Dictionary:
	if transaction == null:
		return {"ok": false, "consume": false, "error": "missing_transaction"}
	transaction.sink.heal(
		transaction.next_step("item:%s" % item.id), unit, int(item.effect_params.get("amount", 0))
	)
	return {"ok": true, "consume": true}


func _prepare_heal_full(unit: Node, item: ItemData, transaction: RefCounted) -> Dictionary:
	if transaction == null:
		return {"ok": false, "consume": false, "error": "missing_transaction"}
	transaction.sink.heal(transaction.next_step("item:%s" % item.id), unit, unit.data.max_hp)
	return {"ok": true, "consume": true}


func _prepare_screen_required(_unit: Node, _item: ItemData, _transaction: RefCounted) -> Dictionary:
	return {"ok": false, "consume": false, "error": "screen_required"}


# Stat buffs go through the registered `apply_active_modifier` primitive rather
# than reaching for the sink directly: the primitive is what content can author
# and what validation checks, and the item is only one of its callers.
func _prepare_stat_buff(unit: Node, item: ItemData, transaction: RefCounted) -> Dictionary:
	if transaction == null:
		return {"ok": false, "consume": false, "error": "missing_transaction"}
	var runner := get_node_or_null("/root/ActionEffectRunner")
	if runner == null:
		return {"ok": false, "consume": false, "error": "missing_runner"}
	var request = (
		ActionRequestScript
		. new(
			"apply_active_modifier",
			{
				"stat": String(item.effect_params.get("stat", "")),
				"delta": int(item.effect_params.get("delta", 0)),
				"duration": int(item.effect_params.get("duration", -1)),
				"duration_type": String(item.effect_params.get("duration_type", "turn")),
				"source": "item:%s" % item.id,
			}
		)
	)
	request.step_id = transaction.next_step("item:%s" % item.id)
	var context = ActionContextScript.new("item", {"actor": unit, "target": unit})
	context.effect_sink = transaction.sink
	context.state_view = transaction.sink.state_view
	return {"ok": runner.prepare(request, context).ok, "consume": true}
