extends "res://scripts/actions/TransactionParticipant.gd"

## The class change half of a promotion or reclass.
##
## It is IRREVERSIBLE by construction: promote() and reclass() rewrite base
## stats, caps, weapon ranks and the skill list, and there is no public way to
## put a unit back. So it goes last in the participant order and rollback()
## reports honestly rather than pretending — anything that could still refuse
## must have refused before this ran.

const AUTHORITY := "unit_class"

var _unit: Node = null
var _kind: String = ""
var _target_class_id: String = ""
var _class_line_id: String = ""
var _before_class_id: String = ""


static func promotion(unit: Node, target_class_id: String) -> RefCounted:
	return _make(unit, "promote", target_class_id, "")


static func reclass(unit: Node, target_class_id: String, class_line_id: String) -> RefCounted:
	return _make(unit, "reclass", target_class_id, class_line_id)


static func _make(
	unit: Node, kind: String, target_class_id: String, class_line_id: String
) -> RefCounted:
	var participant = load("res://scripts/items/ClassChangeParticipant.gd").new()
	participant.authority_id = AUTHORITY
	participant._unit = unit
	participant._kind = kind
	participant._target_class_id = target_class_id
	participant._class_line_id = class_line_id
	participant._before_class_id = String(unit.data.class_id) if unit != null else ""
	return participant


func revalidate(_context: RefCounted) -> Dictionary:
	if _unit == null or not is_instance_valid(_unit) or _unit.data == null:
		return {"ok": false, "code": "missing_authority"}
	if String(_unit.data.class_id) != _before_class_id:
		return {"ok": false, "code": "stale_precondition"}
	return {"ok": true}


func commit(_context: RefCounted) -> Dictionary:
	var check := revalidate(null)
	if not check.ok:
		return check
	var changed: bool = (
		_unit.reclass(_target_class_id, _class_line_id)
		if _kind == "reclass"
		else _unit.promote(_target_class_id)
	)
	if not changed:
		return {"ok": false, "code": "class_change_refused"}
	return {"ok": true}


func rollback(_context: RefCounted) -> Dictionary:
	return {"ok": false, "code": "irreversible"}
