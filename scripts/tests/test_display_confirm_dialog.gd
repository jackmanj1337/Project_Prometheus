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

	# ---- one answer only: a late tick or Escape after Keep emits nothing ----
	_kept = false
	_reverted = false
	var d5: CanvasLayer = DialogS.new()
	root.add_child(d5)
	d5.kept.connect(func() -> void: _kept = true)
	d5.reverted.connect(func() -> void: _reverted = true)
	d5.start(1)
	d5._on_keep()
	d5._tick()
	d5._on_revert()
	_ok(_kept and not _reverted, "a dialog never emits both kept and reverted")

	# ---- Escape (cancel) reverts ----
	_reverted = false
	var d6: CanvasLayer = DialogS.new()
	root.add_child(d6)
	d6.reverted.connect(func() -> void: _reverted = true)
	d6.start(15)
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	d6._input(esc)
	_ok(_reverted, "Escape reverts")

	# ---- [UUI-18] exempt from the setting it confirms ----
	# The live fit needs a viewport, which a node added during _init does not have yet.
	await process_frame
	var d7: CanvasLayer = DialogS.new()
	root.add_child(d7)
	d7.start(15)
	var k7: float = d7.layer_scale()
	_ok(
		is_equal_approx(d7._revert_button.custom_minimum_size.y, DialogS.TARGET_MIN * k7),
		"Revert holds the 44pt target at the safe scale regardless of Menu Mode"
	)
	_ok(
		(
			d7._root.theme != null
			and d7._root.theme.default_font_size == roundi(DialogS.FONT_SIZE * k7)
		),
		"the dialog carries its own type size, not the Menu Scale theme"
	)
	_ok(
		d7.transform == Transform2D.IDENTITY,
		"the scale reaches type and metrics, never a glyph-stretching layer transform"
	)
	# Viewport Scale 4.0 pending on a display whose default is 1.5: the layer cancels the
	# 4.0 and draws at 1.5 when the panel fits.
	var big_view := Vector2(1920.0, 1080.0) / 4.0
	var k_fit: float = DialogS.layer_scale_for(1.5, 4.0, big_view, Vector2(100.0, 50.0))
	_ok(is_equal_approx(k_fit, 0.375), "a 4.0 pending factor is cancelled back to the safe 1.5")
	# The same change on a panel too large for the view shrinks it to fit, like every modal.
	var k_shrunk: float = DialogS.layer_scale_for(1.5, 4.0, big_view, Vector2(344.0, 160.0))
	_ok(
		(
			344.0 * k_shrunk <= big_view.x * DialogS.FIT_RATIO + 0.001
			and 160.0 * k_shrunk <= big_view.y * DialogS.FIT_RATIO + 0.001
		),
		"a panel larger than the game view shrinks to fit inside it"
	)
	# A shrinking factor (0.5) is cancelled upward the same way.
	_ok(
		is_equal_approx(
			DialogS.layer_scale_for(1.0, 0.5, Vector2(2000, 2000), Vector2(100, 50)), 2.0
		),
		"a 0.5 pending factor is cancelled back up to the safe scale"
	)
	# The live layer obeys the same rule: its panel is inside the game view.
	var view: Vector2 = d7.get_viewport().get_visible_rect().size
	var drawn: Vector2 = d7._panel.get_combined_minimum_size()
	_ok(
		drawn.x <= view.x * DialogS.FIT_RATIO + 0.5 and drawn.y <= view.y * DialogS.FIT_RATIO + 0.5,
		"the live panel fits inside the game view (%s in %s)" % [drawn, view]
	)

	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
