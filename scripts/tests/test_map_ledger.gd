extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_map_ledger.gd
# B1-LEDGER Phase 2: the decaying ledger's push/peek/prune, in isolation from
# GameState (MapLedger is a plain RefCounted, so no autoloads are needed). Proves
# the two-tier prune keeps the UNION of "last A activations" and "last R round-
# starts", always retains the round-0 boundary, and honours the 1 / N / infinite
# budgets called out in the plan's Phase 2 test list.

const MapLedgerScript = preload("res://scripts/save/MapLedger.gd")


# A tagged, identifiable board stand-in — the ledger stores whatever dict it is
# handed, so a {"n": i} marker is enough to assert which entries survived a prune.
func _push(ledger: RefCounted, n: int, reason: String) -> void:
	ledger.push({"n": n}, reason)


# The ordered list of marker ids currently retained, for exact-set assertions.
func _ids(ledger: RefCounted) -> Array:
	var out: Array = []
	for i in ledger.size():
		out.append(int(ledger.peek(i).get("n", -1)))
	return out


func _check(label: String, got: Variant, want: Variant, counters: Array) -> void:
	if got == want:
		print("OK  %s" % label)
		counters[0] += 1
	else:
		print("FAIL %s: got %s, want %s" % [label, got, want])
		counters[1] += 1


func _init() -> void:
	print("=== MapLedger push/peek/prune Test (B1-LEDGER Phase 2) ===")
	var counters: Array = [0, 0]  # [passed, failed]
	const R := MapLedgerScript.REASON_ROUND_START
	const A := MapLedgerScript.REASON_ACTIVATION
	const INF := MapLedgerScript.BUDGET_INFINITE

	# ---- push / peek / size / reason_at basics ----
	var led: RefCounted = MapLedgerScript.new()
	_check("empty ledger size 0", led.size(), 0, counters)
	_check("peek out of range returns {}", led.peek(0), {}, counters)
	_push(led, 0, R)  # round-0 boundary
	_push(led, 1, A)
	_check("size after two pushes", led.size(), 2, counters)
	_check("peek returns the stored entry", led.peek(1), {"n": 1}, counters)
	_check("reason_at tags the push", led.reason_at(0), R, counters)
	# peek hands back a deep copy — mutating it must not touch the ledger.
	var borrowed: Dictionary = led.peek(0)
	borrowed["n"] = 999
	_check("peek is a deep copy (ledger unmutated)", led.peek(0), {"n": 0}, counters)

	# ---- prune keeps (last A activations) UNION (last R round-starts) ----
	# Timeline: r0(round) a1 a2 r3(round) a4 a5  — ids are the markers.
	led = MapLedgerScript.new()
	_push(led, 0, R)
	_push(led, 1, A)
	_push(led, 2, A)
	_push(led, 3, R)
	_push(led, 4, A)
	_push(led, 5, A)

	# Budget of 1 each: last 1 activation (5) + last 1 round-start (3), plus the
	# always-retained round-0 (0). Order preserved.
	var b1: RefCounted = _clone(led)
	b1.prune(1, 1)
	_check("prune(1,1) keeps round-0 + last activation + last round-start", _ids(b1), [0, 3, 5], counters)

	# Budget of N (2 each): last 2 activations (4,5) + last 2 round-starts (0,3).
	# Round-0 is among the kept round-starts here — the union stays deduplicated.
	var bn: RefCounted = _clone(led)
	bn.prune(2, 2)
	_check("prune(2,2) keeps the last two of each tier, deduped", _ids(bn), [0, 3, 4, 5], counters)

	# Infinite activations, zero rounds: every activation survives; round-starts drop
	# EXCEPT the forced round-0 boundary. Proves 0 keeps none beyond round-0.
	var binf: RefCounted = _clone(led)
	binf.prune(INF, 0)
	_check("prune(INF,0) keeps all activations + only the round-0 boundary", _ids(binf), [0, 1, 2, 4, 5], counters)

	# Zero activations, infinite rounds: every round-start survives; activations drop.
	var brinf: RefCounted = _clone(led)
	brinf.prune(0, INF)
	_check("prune(0,INF) keeps all round-starts, no activations", _ids(brinf), [0, 3], counters)

	# ---- round-0 is retained even when both budgets are 0 ----
	var bzero: RefCounted = _clone(led)
	bzero.prune(0, 0)
	_check("prune(0,0) still retains the round-0 boundary", _ids(bzero), [0], counters)

	# ---- prune on a single-entry ledger is a no-op (never drops round-0) ----
	var solo: RefCounted = MapLedgerScript.new()
	_push(solo, 0, R)
	solo.prune(0, 0)
	_check("prune never empties a round-0-only ledger", _ids(solo), [0], counters)

	# ---- clear() empties the ledger ----
	var branch: RefCounted = _clone(led)
	branch.truncate_after(2)
	_check("truncate_after drops the abandoned future", _ids(branch), [0, 1, 2], counters)
	var persisted: Array[Dictionary] = branch.to_save_array()
	var restored := MapLedgerScript.new()
	_check("restore_from_save accepts the persisted unified-slot form",
		restored.restore_from_save(persisted) and _ids(restored) == [0, 1, 2], true, counters)
	_check("restore_from_save rejects malformed entries without mutation",
		not restored.restore_from_save([{"reason": "unknown", "entry": {}}]) \
			and _ids(restored) == [0, 1, 2], true, counters)

	bn.clear()
	_check("clear empties the ledger", bn.size(), 0, counters)

	print("\n=== Results: %d passed, %d failed ===" % [counters[0], counters[1]])
	quit(0 if counters[1] == 0 else 1)


# A fresh ledger carrying the same entries — prune mutates in place, so each budget
# case needs its own copy of the shared timeline.
func _clone(source: RefCounted) -> RefCounted:
	var out: RefCounted = MapLedgerScript.new()
	for i in source.size():
		out.push(source.peek(i), source.reason_at(i))
	return out
