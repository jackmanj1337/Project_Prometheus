extends Node
# Centralised item-effect dispatcher. Mirrors SkillHandler's design: callers pass
# the unit and the inventory entry dict; all item logic lives here so MapCursor
# and future AI systems stay free of item mechanics.

const ActionRequestScript = preload("res://scripts/actions/ActionRequest.gd")
const ActionContextScript = preload("res://scripts/actions/ActionContext.gd")
const ItemEffectRegistryScript = preload("res://scripts/registries/ItemEffectRegistry.gd")

var _effects: RefCounted


# Applies the effect of an item entry to `unit`.
# Decrements uses_remaining and removes exhausted entries from the inventory.
func apply_item(unit: Node, entry: InventoryEntry) -> void:
	if unit == null or unit.data == null or entry == null:
		return
	if entry.item_id.is_empty():
		return
	var item: ItemData = _item_from_entry(entry)
	if item == null:
		return
	if not can_apply_item(unit, entry):
		push_warning(
			(
				"ItemHandler: item '%s' is not currently usable by '%s'"
				% [item.id, unit.data.unit_name]
			)
		)
		return
	var result: Dictionary = _effect_registry().commit(item.effect_id, unit, item)
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
		return
	if result.get("consume", true):
		consume_entry(unit, entry)


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
		Callable(self, "_commit_heal_flat")
	)
	_effects.register_runtime_handler(
		"heal_full",
		Callable(self, "_can_direct"),
		Callable(self, "_preview_direct"),
		Callable(self, "_commit_heal_full")
	)
	_effects.register_runtime_handler(
		"promote",
		Callable(self, "_can_promote"),
		Callable(self, "_preview_promotion"),
		Callable(self, "_commit_screen_required")
	)
	_effects.register_runtime_handler(
		"reclass",
		Callable(self, "_can_reclass"),
		Callable(self, "_preview_reclass"),
		Callable(self, "_commit_screen_required")
	)
	_effects.register_runtime_handler(
		"stat_buff",
		Callable(self, "_can_stat_buff"),
		Callable(self, "_preview_direct"),
		Callable(self, "_commit_stat_buff")
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


func _commit_heal_flat(unit: Node, item: ItemData) -> Dictionary:
	unit.heal(int(item.effect_params.get("amount", 0)))
	return {"ok": true, "consume": true}


func _commit_heal_full(unit: Node, _item: ItemData) -> Dictionary:
	unit.heal(unit.data.max_hp)
	return {"ok": true, "consume": true}


func _commit_screen_required(_unit: Node, _item: ItemData) -> Dictionary:
	return {"ok": false, "consume": false, "error": "screen_required"}


func _commit_stat_buff(unit: Node, item: ItemData) -> Dictionary:
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
	var context = ActionContextScript.new("item", {"actor": unit, "target": unit})
	return {"ok": runner.commit(request, context).ok, "consume": true}
