class_name VisibilityStateParticipant extends RefCounted

var _authority: Variant
var _spotted: Array[Node] = []
var _mover: Variant
var _before: Dictionary


func _init(authority: Variant, spotted: Array, mover: Variant) -> void:
	_authority = authority
	for unit in spotted:
		_spotted.append(unit)
	_mover = mover
	_before = authority.discovered_units.duplicate() if authority != null else {}


func revalidate(_context: Variant) -> Dictionary:
	if _authority == null or not _authority.has_method("commit_reveal"):
		return {"ok": false, "code": "visibility_authority_unavailable"}
	for unit in _spotted:
		if unit == null or not is_instance_valid(unit):
			return {"ok": false, "code": "spotted_unit_unavailable"}
	return {"ok": true}


func commit(_context: Variant) -> Dictionary:
	_authority.commit_reveal(_spotted, _mover)
	return {"ok": true}


func rollback(_context: Variant) -> void:
	if _authority == null:
		return
	_authority.discovered_units = _before.duplicate()
	_authority.refresh()
