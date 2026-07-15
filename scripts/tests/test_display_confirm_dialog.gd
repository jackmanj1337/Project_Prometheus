extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_display_confirm_dialog.gd
# Covers the confirm-or-revert dialog's core: the countdown reverts at the deadline,
# Keep emits kept, Revert emits reverted. The countdown is driven via _tick() directly
# so the test is deterministic and doesn't wait real seconds.

const DialogS = preload("res://scripts/ui/DisplayConfirmDialog.gd")

var _passed := 0
var _failed := 0
var _kept := false
var _reverted := false


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("OK  ", msg)
		_passed += 1
	else:
		print("FAIL ", msg)
		_failed += 1


func _init() -> void:
	print("=== DisplayConfirmDialog Test ===")

	# ---- countdown auto-reverts exactly at the deadline ----
	var d1: CanvasLayer = DialogS.new()
	root.add_child(d1)
	d1.reverted.connect(func() -> void: _reverted = true)
	d1.start(3)
	_ok(d1._remaining == 3, "start(3) sets the countdown to 3")
	d1._tick()
	d1._tick()
	_ok(not _reverted, "no revert before the deadline (2 of 3 ticks)")
	d1._tick()
	_ok(_reverted, "auto-reverts when the countdown reaches zero")

	# ---- start clamps a non-positive deadline to 1 (reverts on the first tick) ----
	_reverted = false
	var d2: CanvasLayer = DialogS.new()
	root.add_child(d2)
	d2.reverted.connect(func() -> void: _reverted = true)
	d2.start(0)
	_ok(d2._remaining == 1, "start(0) clamps the deadline to 1")
	d2._tick()
	_ok(_reverted, "a clamped deadline still auto-reverts")

	# ---- Keep emits kept (and not reverted) ----
	# NB: use member flags, not locals — GDScript lambdas capture locals by value, so
	# `kept = true` inside a closure would mutate a copy, never the outer local.
	_kept = false
	_reverted = false
	var d3: CanvasLayer = DialogS.new()
	root.add_child(d3)
	d3.kept.connect(func() -> void: _kept = true)
	d3.reverted.connect(func() -> void: _reverted = true)
	d3.start(15)
	d3._on_keep()
	_ok(_kept and not _reverted, "Keep emits kept, not reverted")

	# ---- Revert button emits reverted ----
	_reverted = false
	var d4: CanvasLayer = DialogS.new()
	root.add_child(d4)
	d4.reverted.connect(func() -> void: _reverted = true)
	d4.start(15)
	d4._on_revert()
	_ok(_reverted, "Revert button emits reverted")

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
