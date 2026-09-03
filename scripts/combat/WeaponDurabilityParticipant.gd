extends "res://scripts/actions/TransactionParticipant.gd"

## Weapon uses are a FALLIBLE authority, so they join the transaction as a
## participant rather than as journal entries.
##
## Two properties stop this being a plain field write. Spending the last use
## removes the InventoryEntry from the inventory, so the "after" state is not a
## number but a structural change; and the entry is shared with everything else
## that can move an item (trade, drop, a shop sale between the forecast and the
## swing). Recording the intent and re-reading the entry at commit is what makes
## a stolen or already-spent weapon fail the whole exchange instead of silently
## decrementing something else.

const AUTHORITY := "weapon_durability"

# unit instance id -> {"unit": Node, "weapon_id": String, "count": int, "before": int}
var _planned: Dictionary = {}
var _applied: Array[Dictionary] = []


func _init() -> void:
	authority_id = AUTHORITY


func plan(unit: Node, weapon_id: String) -> void:
	if unit == null or not unit.has_method("use_weapon_durability"):
		return
	var id: int = unit.get_instance_id()
	if not _planned.has(id):
		_planned[id] = {
			"unit": unit,
			"weapon_id": weapon_id,
			"count": 0,
			"before": _uses_remaining(unit),
		}
	(_planned[id] as Dictionary)["count"] += 1


func planned_uses(unit: Node) -> int:
	if unit == null:
		return 0
	return int((_planned.get(unit.get_instance_id(), {}) as Dictionary).get("count", 0))


func revalidate(_context: RefCounted) -> Dictionary:
	for id: int in _planned:
		var plan_entry: Dictionary = _planned[id]
		var unit: Node = plan_entry["unit"]
		if unit == null or not is_instance_valid(unit):
			return {"ok": false, "code": "missing_authority"}
		if _uses_remaining(unit) != int(plan_entry["before"]):
			return {"ok": false, "code": "stale_precondition"}
	return {"ok": true}


func commit(_context: RefCounted) -> Dictionary:
	var check := revalidate(null)
	if not check.ok:
		return check
	for id: int in _planned:
		var plan_entry: Dictionary = _planned[id]
		var unit: Node = plan_entry["unit"]
		for _i in int(plan_entry["count"]):
			unit.use_weapon_durability(String(plan_entry["weapon_id"]))
		_applied.append(plan_entry)
	return {"ok": true}


# Durability cannot be un-spent through the public API — a broken weapon's entry
# is gone. Rollback therefore reports what it could not restore instead of
# pretending; the runner already refuses to commit past a failed participant, so
# this only runs when a LATER participant failed, and the honest signal is that
# the transaction needs its participants ordered with durability last.
func rollback(_context: RefCounted) -> Dictionary:
	if _applied.is_empty():
		return {"ok": true}
	return {"ok": false, "code": "irreversible", "applied": _applied.size()}


func _uses_remaining(unit: Node) -> int:
	if unit == null or not unit.has_method("get_equipped_weapon_entry"):
		return -1
	var entry = unit.get_equipped_weapon_entry()
	return entry.uses_remaining if entry != null else -1
