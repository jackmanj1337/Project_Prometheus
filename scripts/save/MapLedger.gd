extends RefCounted
# B1-LEDGER Phase 2 — the within-map decaying ledger.
#
# A single ordered list of SUSPEND-COMPLETE board entries (the format
# GameState._capture_map_runtime_entry produces), each tagged with the REASON it
# was pushed. The oldest entry (index 0) is the round-0 boundary a Retry rewinds
# to; later entries are the per-round-start and per-activation history a mid-map
# rewind (Phase 3) spends.
#
# Two tiers share one list rather than living in two arrays: the tier is just the
# push reason, and prune() keeps a UNION of "the last A activation entries" and
# "the last R round-start entries". Expressing tiers as data (a reason tag + two
# retention budgets) rather than a mode `match` follows the project's open-registry
# principle — a new retention rule is new budgets, not an engine edit.
#
# No class_name: preload this script (as GameState does with its save helpers) so
# adding it does not depend on the global class registry being reimported.
#
# Authority: [GDD-01-RUNTIME-CONTRACTS]
# (Phase 2); the entry format is GDD_01 §Determinism, Snapshot & Online.

# Push reasons. Round-0 is a round-start push; per-activation pushes tag ACTIVATION.
const REASON_ROUND_START := "round_start"
const REASON_ACTIVATION := "activation"

# A budget of this value means "retain every entry of that reason" — the coarse
# tier may legitimately be infinite (keep the whole round history).
const BUDGET_INFINITE := -1

# Each element is {"reason": String, "entry": Dictionary}. The board dict is stored
# verbatim; peek() hands back a deep copy so a reader never mutates the ledger.
var _entries: Array[Dictionary] = []


# Append one board entry under the given reason (defaults to a round-start push,
# which is what the round-0 seed and every round boundary are).
func push(
	board_entry: Dictionary, reason: String = REASON_ROUND_START, metadata: Dictionary = {}
) -> void:
	_entries.append({"reason": reason, "entry": board_entry, "metadata": metadata.duplicate(true)})


func size() -> int:
	return _entries.size()


func clear() -> void:
	_entries.clear()


func to_save_array() -> Array[Dictionary]:
	return _entries.duplicate(true)


# Serializes a prospective branch without mutating the live ledger. Rewind uses
# this while validating the staged suspend document, then truncates live state
# only after that durable document has been accepted.
func to_save_array_through(index: int) -> Array[Dictionary]:
	if index < 0:
		return []
	var result := _entries.duplicate(true)
	if index + 1 < result.size():
		result.resize(index + 1)
	return result


func restore_from_save(value: Variant) -> bool:
	if not (value is Array):
		return false
	var restored: Array[Dictionary] = []
	for item in value:
		if not (item is Dictionary):
			return false
		var reason := String(item.get("reason", ""))
		var entry: Variant = item.get("entry", null)
		if reason not in [REASON_ROUND_START, REASON_ACTIVATION] or not (entry is Dictionary):
			return false
		var metadata: Variant = item.get("metadata", {})
		if not metadata is Dictionary:
			return false
		restored.append(
			{"reason": reason, "entry": entry.duplicate(true), "metadata": metadata.duplicate(true)}
		)
	_entries = restored
	return true


func truncate_after(index: int) -> void:
	if index < 0:
		_entries.clear()
	elif index + 1 < _entries.size():
		_entries.resize(index + 1)


func set_map_runtime_value(index: int, key: String, value: Variant) -> void:
	if index < 0 or index >= _entries.size():
		return
	var entry: Dictionary = _entries[index].get("entry", {})
	var runtime: Dictionary = entry.get("map_runtime", {})
	runtime[key] = value


# The reason tag at index, or "" if out of range — for tests/UI that label an entry.
func reason_at(index: int) -> String:
	if index < 0 or index >= _entries.size():
		return ""
	return String(_entries[index]["reason"])


func metadata_at(index: int) -> Dictionary:
	if index < 0 or index >= _entries.size():
		return {}
	return _entries[index].get("metadata", {}).duplicate(true)


# A deep copy of the board entry at index (0 = the round-0 boundary), or {} if out
# of range, so a caller reads an entry without mutating the stored ledger.
func peek(index: int) -> Dictionary:
	if index < 0 or index >= _entries.size():
		return {}
	return _entries[index]["entry"].duplicate(true)


# Decay the ledger to (last `keep_activations` activation entries) UNION (last
# `keep_rounds` round-start entries). The round-0 boundary (index 0) is ALWAYS
# retained regardless of budget — a Retry must always be able to reach it. A
# budget of BUDGET_INFINITE keeps every entry of that reason; 0 keeps none (beyond
# the forced round-0). Order is preserved.
func prune(keep_activations: int, keep_rounds: int) -> void:
	if _entries.size() <= 1:
		return
	var keep: Dictionary = {0: true}  # round-0 boundary, always retained
	_mark_last_n_of_reason(keep, REASON_ACTIVATION, keep_activations)
	_mark_last_n_of_reason(keep, REASON_ROUND_START, keep_rounds)
	var kept: Array[Dictionary] = []
	for i in _entries.size():
		if keep.has(i):
			kept.append(_entries[i])
	_entries = kept


# Marks the indices of the last `n` entries whose reason matches. n == 0 marks
# nothing; n < 0 (BUDGET_INFINITE) marks every matching entry.
func _mark_last_n_of_reason(keep: Dictionary, reason: String, n: int) -> void:
	if n == 0:
		return
	var idxs: Array[int] = []
	for i in _entries.size():
		if String(_entries[i]["reason"]) == reason:
			idxs.append(i)
	var start: int = 0 if n < 0 else maxi(0, idxs.size() - n)
	for j in range(start, idxs.size()):
		keep[idxs[j]] = true
