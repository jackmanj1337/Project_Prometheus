class_name TransactionParticipant extends RefCounted
# adopter-todo: SHARED-EFFECT-RUNNER-WIRING-2026-08-31

## Interface for fallible authorities that join an effect transaction.

var authority_id: String = ""


func prepare(_context: RefCounted) -> Dictionary:
	return {"ok": true}


func revalidate(_context: RefCounted) -> Dictionary:
	return {"ok": true}


func commit(_context: RefCounted) -> Dictionary:
	return {"ok": true}


func rollback(_context: RefCounted) -> Dictionary:
	return {"ok": true}
