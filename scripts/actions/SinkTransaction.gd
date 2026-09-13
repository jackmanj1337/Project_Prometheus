class_name SinkTransaction extends RefCounted

## The transaction shape for a caller that brought a sink but no transaction.
##
## Preparation helpers ask their caller for `sink`, `participants` and
## `next_step()` — that trio IS the transaction as far as they are concerned.
## An authored composition, though, may be prepared through a context that only
## carries an effect_sink, because the primitive runner builds one itself when
## the caller had none (`_ensure_sink`). Without this the condition primitives
## would have had to grow a second, sink-only code path, and two paths through a
## commit boundary is the exact duplication this whole architecture is retiring.
##
## It owns nothing: the sink and the participant list belong to whoever built
## them, and commit stays with the real owner.

var sink: RefCounted
var participants: Array = []

var _step: int = 0


func _init(existing_sink: RefCounted, existing_participants: Array = []) -> void:
	sink = existing_sink
	participants = existing_participants


func next_step(prefix: String) -> String:
	_step += 1
	return "%s_%d" % [prefix, _step]
