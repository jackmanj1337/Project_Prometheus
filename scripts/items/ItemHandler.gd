extends Node
# Centralised item-effect dispatcher. Mirrors SkillHandler's design: callers pass
# the unit and the inventory entry dict; all item logic lives here so MapCursor
# and future AI systems stay free of item mechanics.

# Applies the effect of an item entry to `unit`.
# Decrements uses_remaining and removes exhausted entries from the inventory.
func apply_item(unit: Node, entry: Dictionary) -> void:
	if unit == null or unit.data == null:
		return
	var item_id: String = entry.get("item_id", "")
	if item_id.is_empty():
		return
	var dm := get_node_or_null("/root/DataManager")
	if dm == null:
		return
	var item: ItemData = dm.get_item(item_id)
	if item == null:
		push_warning("ItemHandler: unknown item_id '%s'" % item_id)
		return
	var amount: int = int(item.effect_params.get("amount", 0))
	match item.effect_id:
		"heal_flat":
			unit.heal(amount)
		"heal_full":
			unit.heal(unit.data.max_hp)
		_:
			push_warning("ItemHandler: unknown effect_id '%s'" % item.effect_id)
			return  # Don't consume the item if we can't apply its effect
	entry["uses_remaining"] -= 1
	if entry["uses_remaining"] <= 0:
		unit.data.inventory.erase(entry)
