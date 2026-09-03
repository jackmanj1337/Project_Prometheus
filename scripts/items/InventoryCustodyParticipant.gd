extends "res://scripts/actions/TransactionParticipant.gd"

## Custody of an inventory entry for the length of one transaction.
##
## "Spend the item, then apply its effect" and "apply the effect, then spend the
## item" are both wrong, and the game did the second: a vulnerary whose effect
## declined still decremented, and an effect that succeeded against an entry
## somebody had traded away in the meantime consumed nothing. Neither half can
## go first — they have to go together.
##
## Custody is reversible, which is why it is a participant that commits BEFORE
## irreversible ones: an entry this holds can be handed back exactly as it was,
## re-inserted at its original index if spending it emptied the stack.

const AUTHORITY := "inventory_custody"

var _unit: Node = null
var _entry: RefCounted = null
var _before_uses: int = 0
var _before_index: int = -1
var _spent: bool = false


func _init() -> void:
	authority_id = AUTHORITY


# Takes custody of `entry`. Returns the same {"ok": bool} shape the transaction
# speaks, so a caller can refuse before preparing anything else.
func plan(unit: Node, entry: RefCounted) -> Dictionary:
	if unit == null or unit.data == null or entry == null:
		return {"ok": false, "code": "missing_entry"}
	var index: int = (unit.data.inventory as Array).find(entry)
	if index == -1:
		return {"ok": false, "code": "entry_not_held"}
	if not entry.has_uses():
		return {"ok": false, "code": "no_uses_remaining"}
	_unit = unit
	_entry = entry
	_before_uses = entry.uses_remaining
	_before_index = index
	return {"ok": true}


func revalidate(_context: RefCounted) -> Dictionary:
	if _entry == null:
		return {"ok": true}
	if _unit == null or not is_instance_valid(_unit) or _unit.data == null:
		return {"ok": false, "code": "missing_authority"}
	if (_unit.data.inventory as Array).find(_entry) != _before_index:
		return {"ok": false, "code": "stale_precondition"}
	if _entry.uses_remaining != _before_uses:
		return {"ok": false, "code": "stale_precondition"}
	return {"ok": true}


func commit(_context: RefCounted) -> Dictionary:
	var check := revalidate(null)
	if not check.ok:
		return check
	if _entry == null or _entry.uses_remaining == -1:
		return {"ok": true}  # infinite-use item: held, never spent
	_entry.uses_remaining -= 1
	if _entry.uses_remaining <= 0:
		_unit.data.inventory.remove_at(_before_index)
	_spent = true
	return {"ok": true}


func rollback(_context: RefCounted) -> Dictionary:
	if not _spent or _entry == null:
		return {"ok": true}
	if _unit != null and is_instance_valid(_unit) and _unit.data != null:
		if not (_unit.data.inventory as Array).has(_entry):
			_unit.data.inventory.insert(_before_index, _entry)
	_entry.uses_remaining = _before_uses
	_spent = false
	return {"ok": true}
