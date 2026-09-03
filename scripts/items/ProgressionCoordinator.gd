extends Node

## Owns the commit for a promotion or a reclass.
##
## The choice and the commit had grown into the same object: PromotionScreen and
## ReclassScreen each called `unit.promote()` / `unit.reclass()` and then asked
## ItemHandler to consume the seal, as two separate writes with nothing joining
## them. A promotion that succeeded against a seal somebody had traded away in
## the meantime was free, and a UI that closed between the two left the unit
## promoted with the seal still in the bag.
##
## The screens now only collect a choice. This commits it: custody of the seal
## first, because it is the reversible half, and the class change last, because
## it is not. If the class change refuses, custody rolls back and the seal stays
## exactly as it was.

const EffectTransactionScript = preload("res://scripts/actions/EffectTransaction.gd")
const CustodyScript = preload("res://scripts/items/InventoryCustodyParticipant.gd")
const ClassChangeScript = preload("res://scripts/items/ClassChangeParticipant.gd")


func commit_promotion(
	unit: Node, target_class_id: String, consume_entry: RefCounted = null
) -> Dictionary:
	return _commit_class_change(
		unit, consume_entry, ClassChangeScript.promotion(unit, target_class_id)
	)


func commit_reclass(
	unit: Node, target_class_id: String, class_line_id: String, consume_entry: RefCounted = null
) -> Dictionary:
	return _commit_class_change(
		unit, consume_entry, ClassChangeScript.reclass(unit, target_class_id, class_line_id)
	)


func _commit_class_change(unit: Node, consume_entry: RefCounted, change: RefCounted) -> Dictionary:
	if unit == null or not is_instance_valid(unit) or unit.data == null:
		return {"ok": false, "code": "missing_unit"}
	var transaction := EffectTransactionScript.new()
	if consume_entry != null:
		var custody: RefCounted = CustodyScript.new()
		var held: Dictionary = custody.plan(unit, consume_entry)
		if not held.get("ok", false):
			return held
		transaction.add_participant(custody)
	transaction.add_participant(change)
	return transaction.commit()
