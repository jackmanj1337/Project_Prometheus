extends Node
# Centralised item-effect dispatcher. Mirrors SkillHandler's design: callers pass
# the unit and the inventory entry dict; all item logic lives here so MapCursor
# and future AI systems stay free of item mechanics.

# Canonical list of effect_ids implemented by apply_item's match below. Read by
# DataManager._validate_cross_references at startup (B6) so a typo in an item
# .tres surfaces immediately rather than as a runtime push_warning the first time
# the item is used. Keep this list in lockstep with apply_item's match cases —
# add the case AND a string here whenever a new item effect lands.
const IMPLEMENTED_EFFECT_IDS: Array[String] = ["heal_flat", "heal_full", "promote", "reclass", "stat_buff"]

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
		push_warning("ItemHandler: item '%s' is not currently usable by '%s'" % [
			item.id, unit.data.unit_name])
		return
	var amount: int = int(item.effect_params.get("amount", 0))
	match item.effect_id:
		"heal_flat":
			unit.heal(amount)
		"heal_full":
			unit.heal(unit.data.max_hp)
		"promote":
			push_warning("ItemHandler: promote items must be resolved through PromotionScreen")
			return
		"reclass":
			push_warning("ItemHandler: reclass items must be resolved through ReclassScreen")
			return
		"stat_buff":
			# Stamps an active_modifier on the unit using ItemData.effect_params.
			# Used by the strength_tonic fixture so previews and unit details can
			# reliably surface a positive modifier in a single validation run.
			if not unit.has_method("add_modifier"):
				return
			var stat: String = String(item.effect_params.get("stat", ""))
			var delta: int = int(item.effect_params.get("delta", 0))
			var duration: int = int(item.effect_params.get("duration", -1))
			var duration_type: String = String(item.effect_params.get("duration_type", "turn"))
			if stat == "" or delta == 0:
				return
			unit.add_modifier(stat, delta, "item:%s" % item.id, duration, duration_type)
		_:
			push_warning("ItemHandler: unknown effect_id '%s'" % item.effect_id)
			return  # Don't consume the item if we can't apply its effect
	consume_entry(unit, entry)


func can_apply_item(unit: Node, entry: InventoryEntry) -> bool:
	if unit == null or unit.data == null or entry == null or entry.item_id.is_empty():
		return false
	if not entry.has_uses():
		return false
	var item: ItemData = _item_from_entry(entry)
	if item == null:
		return false
	match item.effect_id:
		"heal_flat", "heal_full":
			return true
		"promote":
			return _can_apply_promotion_item(unit, item)
		"reclass":
			return unit.has_method("can_use_second_seal") and unit.can_use_second_seal()
		"stat_buff":
			return unit.has_method("add_modifier")
		_:
			return false


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
