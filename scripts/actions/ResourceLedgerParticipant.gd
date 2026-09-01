extends "res://scripts/actions/TransactionParticipant.gd"

## Adapts one ResourceLedger reservation into the shared transaction boundary.

var _ledger: Node
var _reservation: RefCounted


func _init(ledger: Node, reservation: RefCounted) -> void:
	authority_id = "resource_ledger"
	_ledger = ledger
	_reservation = reservation


func revalidate(_context: RefCounted) -> Dictionary:
	if _ledger == null or _reservation == null:
		return {"ok": false, "code": "missing_authority"}
	return _ledger.revalidate_reserved(_reservation)


func commit(_context: RefCounted) -> Dictionary:
	var result: RefCounted = _ledger.commit_reserved(_reservation)
	return {"ok": result.ok, "code": "" if result.ok else "resource_commit_failed"}


func rollback(_context: RefCounted) -> Dictionary:
	if _reservation == null or not _reservation.committed:
		return {"ok": true}
	var result: RefCounted = _ledger.refund(_reservation)
	return {"ok": result.ok, "code": "" if result.ok else "resource_rollback_failed"}
