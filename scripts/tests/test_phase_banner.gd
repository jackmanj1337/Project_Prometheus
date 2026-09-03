extends SceneTree
## Focused PhaseBanner coverage.
##
## WHY THIS EXISTS. The v0.7.15 Windows return found the banner uncentred at
## fullscreen AND still visible for a whole player phase after a resumed load
## (V0715-01). Neither could have been caught here, because before this file
## there was NO phase-banner test at all -- the August width fix for [V070-09]
## shipped, regressed at another scale, and the 159-suite gate had nothing to
## say about it either time.
##
## SCOPE, DELIBERATELY. This suite pins the LIFECYCLE half: tween ownership,
## what the banner leaves behind when an animation ends, and what happens when
## two phases arrive close together. Those are the properties the resumed-load
## defect is made of and they are observable headlessly.
##
## It does NOT try to reproduce the fullscreen coordinate defect. That one is a
## logical-versus-physical conversion on a root CanvasLayer, and the review's
## Playwright pass could not reproduce it either; the row requires a NATIVE
## instrumented run before anyone patches it. A test asserting the current
## logical geometry would pass on a build the tester has already rejected --
## which is exactly the trap V0715-03 documents, where a containment assertion
## passed on an unreadable screen. So the width cases here assert only what is
## true in every coordinate space, and the native check stays a native check.

const BannerScene = preload("res://scenes/ui/PhaseBanner.tscn")

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s" % label)
		failed += 1


func _make_banner() -> Control:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var banner: Control = BannerScene.instantiate()
	layer.add_child(banner)
	return banner


func _panel_of(banner: Control) -> Panel:
	return banner.get_node("Panel") as Panel


func _run() -> void:
	print("=== PhaseBanner ===")
	await process_frame

	# ---- width tracks the viewport it is measured against ----
	var banner := _make_banner()
	var panel := _panel_of(banner)
	var viewport_width: float = banner.get_viewport().get_visible_rect().size.x
	_check(
		is_equal_approx(panel.size.x, viewport_width),
		"the panel spans the width it measured at _ready"
	)
	_check(
		not is_equal_approx(panel.size.x, 1280.0) or is_equal_approx(viewport_width, 1280.0),
		"the panel width is derived, not the scene's hard-coded 1280"
	)

	# ---- the tween is not owned, which is the lifecycle gap ----
	#
	# _animate() calls create_tween() and keeps no reference, so nothing can
	# kill a running animation and nothing runs on completion. These two checks
	# record that as the CURRENT state rather than asserting it is correct: when
	# V0715-01 is fixed they must be inverted, and the row says so.
	_check(
		not "_tween" in banner,
		"CURRENT STATE: the banner stores no tween handle (invert when V0715-01 lands)"
	)
	_check(
		not banner.has_method("_reset_after_animation"),
		"CURRENT STATE: the banner has no completion reset (invert when V0715-01 lands)"
	)

	# ---- two phases in quick succession ----
	#
	# The returned defect is a banner that never went away. The mechanism the
	# review proposes is an animation started while the scene is still
	# restoring, with no way to supersede it. Overlapping animations are the
	# same shape and are reachable here.
	banner._animate()
	var first_x: float = panel.position.x
	await process_frame
	banner._animate()
	await process_frame
	_check(
		panel.position.x <= viewport_width and panel.position.x >= -viewport_width,
		"a second phase arriving mid-animation leaves the panel within slide bounds"
	)
	_check(first_x >= 0.0, "an animation starts from the offscreen-right edge")

	# ---- the banner settles offscreen once the full sequence has elapsed ----
	#
	# Slide-in 0.3 + hold 0.8 + slide-out 0.3 = 1.4s. This is the assertion the
	# return would have failed: after the sequence the panel must not be sitting
	# where the player can still see it.
	var settled := _make_banner()
	var settled_panel := _panel_of(settled)
	settled._animate()
	var elapsed := 0.0
	while elapsed < 1.6:
		await process_frame
		elapsed += float(root.get_process_delta_time())
	_check(
		settled_panel.position.x < 0.0,
		"after the full 1.4s sequence the panel has left the visible area"
	)

	# ---- resize while idle ----
	var resized := _make_banner()
	var resized_panel := _panel_of(resized)
	resized._sync_panel_width()
	_check(
		is_equal_approx(resized_panel.size.x, resized.get_viewport().get_visible_rect().size.x),
		"re-syncing width matches the viewport it is measured against"
	)

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)
