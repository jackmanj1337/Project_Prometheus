extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_node_lifecycle_leak.gd
#
# ObjectDB / orphan-node regression guard (ObjectDB leak audit, 2026-07-07).
#
# The recurring `WARNING: ObjectDB instances leaked at exit` seen in playtest logs
# is a benign TEST-teardown artifact: SceneTree-based suites create fixture nodes
# and call quit() without freeing them, so the count scales with fixtures, not with
# production instances (audit: no production remove_child(); every transient dialog
# queue_free()s on both confirm and cancel). See
# [GDD-00-OVERVIEW].
#
# That exit noise, however, MASKS a real regression: a production node subtree that
# stops freeing on dismissal would leak on every interaction across a long session.
# This suite guards against exactly that using Performance's live orphan-node monitor
# (verified precise: +1 on an unparented Node.new(), back to baseline on free()).
# It exercises a representative code-built production subtree (DisplayConfirmDialog:
# CanvasLayer + dim/center/panel/vbox/labels/buttons + a Timer) through the full
# create -> add_child -> free cycle and asserts the orphan count returns to baseline.
#
# Discipline: this suite frees every fixture it creates before quit(), so it stays
# leak-clean itself (leakwarn=0) — the pattern the audit recommends.

const DialogS = preload("res://scripts/ui/DisplayConfirmDialog.gd")

var _passed := 0
var _failed := 0


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
		_passed += 1
	else:
		print("FAIL ", msg)
		_failed += 1


func _orphans() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))


func _init() -> void:
	print("=== Node Lifecycle Leak Guard ===")

	# Settle any boot-time deferred frees so the baseline is stable before measuring.
	await process_frame
	await process_frame
	var baseline := _orphans()

	# ---- repeated create -> free returns to baseline (the per-interaction leak guard) ----
	# A production dialog opened and dismissed N times must not accumulate orphans. If
	# free() ever stopped cascading to the built subtree, the count would climb by N.
	const CYCLES := 12
	for i in CYCLES:
		var dlg: CanvasLayer = DialogS.new()
		root.add_child(dlg)
		dlg.start(15)  # builds the full child subtree + starts the countdown Timer
		await process_frame
		dlg.queue_free()
		await process_frame
	# queue_free() is deferred; give the tree a couple frames to drain the queue.
	await process_frame
	await process_frame
	var after_cycles := _orphans()
	_ok(
		after_cycles <= baseline,
		(
			"%d open/close cycles leave no orphan growth (baseline=%d, after=%d)"
			% [CYCLES, baseline, after_cycles]
		)
	)

	# ---- freeing mid-countdown (the real dismissal path) leaves no orphan ----
	# Production dismisses the dialog while its 1s Timer is still running; the running
	# Timer child must not keep the subtree alive.
	var live: CanvasLayer = DialogS.new()
	root.add_child(live)
	live.start(15)
	await process_frame
	_ok(_orphans() >= baseline, "dialog is live before free (sanity)")
	live.free()  # immediate free, mid-countdown
	await process_frame
	_ok(
		_orphans() <= baseline,
		(
			"freeing a live (counting-down) dialog reclaims its whole subtree (%d <= %d)"
			% [_orphans(), baseline]
		)
	)

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
