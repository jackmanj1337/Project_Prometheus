extends "res://scripts/actions/TransactionParticipant.gd"

## Reversible custody for the campaign convoy's legacy item-id projection.

var _game_state: Node
var _item_ids: Array[String] = []
var _before_items: Array[String] = []
var _committed: bool = false


func _init(game_state: Node, item_ids: Array[String]) -> void:
	authority_id = "party_item_custody"
	_game_state = game_state
	_item_ids = item_ids.duplicate()
	if _game_state != null:
		_before_items = (_game_state.party_items as Array[String]).duplicate()


func revalidate(_context: RefCounted) -> Dictionary:
	if _game_state == null:
		return {"ok": false, "code": "missing_authority"}
	if _game_state.party_items != _before_items:
		return {"ok": false, "code": "stale_precondition"}
	return {"ok": true}


func commit(_context: RefCounted) -> Dictionary:
	var check := revalidate(null)
	if not check.ok:
		return check
	_game_state.party_items.append_array(_item_ids)
	_committed = true
	return {"ok": true}


func rollback(_context: RefCounted) -> Dictionary:
	if _committed and _game_state != null:
		_game_state.party_items = _before_items.duplicate()
	_committed = false
	return {"ok": true}
