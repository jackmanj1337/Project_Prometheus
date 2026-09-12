class_name EffectTransaction extends RefCounted

## One unit of change, prepared in full before any of it lands.
##
## Two things move state: a JOURNAL of before/after values for fields the effect
## can simply write, and PARTICIPANTS — authorities that can refuse, because
## their state is structural rather than a value (an inventory entry that may
## have been traded away, a class change that may no longer be legal).
##
## commit() revalidates everything against live state first, then commits the
## fallible participants in order, then the journal. A participant that fails
## rolls back the ones already committed, so the caller is never left holding
## half a transaction — which is exactly what "consume the item, then apply the
## effect" used to produce when the second half declined.
##
## Participant ORDER is the caller's contract: put the reversible authorities
## first and the irreversible one last, so a late refusal can still be undone.

const SinkScript = preload("res://scripts/actions/UnitStateSink.gd")

var sink: RefCounted
var participants: Array = []
var committed: bool = false
var failure: Dictionary = {}

var _step: int = 0


func _init() -> void:
	sink = SinkScript.new()


func add_participant(participant: RefCounted) -> void:
	participants.append(participant)


func commit() -> Dictionary:
	if committed:
		return {"ok": true, "already_committed": true}
	var check: Dictionary = sink.state_view.revalidate()
	if not check.get("ok", false):
		failure = check
		return check
	for participant in participants:
		var participant_check: Dictionary = participant.revalidate(null)
		if not participant_check.get("ok", false):
			failure = participant_check
			return participant_check

	var applied: Array = []
	for participant in participants:
		var outcome: Dictionary = participant.commit(null)
		if not outcome.get("ok", false):
			_rollback(applied)
			failure = outcome
			return outcome
		applied.push_front(participant)

	var journal_outcome: Dictionary = sink.state_view.commit()
	if not journal_outcome.get("ok", false):
		_rollback(applied)
		failure = journal_outcome
		return journal_outcome
	committed = true
	return {"ok": true}


# Presentation is replayed only after the commit lands, so no bar or signal
# announces a change the transaction went on to reject.
func flush_presentation(bus: Node) -> void:
	sink.flush_presentation(bus)


func save_fields_touched() -> Array[String]:
	return sink.state_view.journal.save_fields()


func deltas() -> Array[Dictionary]:
	return sink.state_view.journal.duplicate_entries()


func next_step(prefix: String) -> String:
	_step += 1
	return "%s_%d" % [prefix, _step]


func _rollback(applied: Array) -> void:
	for participant in applied:
		participant.rollback(null)
