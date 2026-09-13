extends SceneTree
# v0.7.16 return: idle resize exposed a visible panel parked at the old width.

const BannerScene = preload("res://scenes/ui/PhaseBanner.tscn")
var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("OK  ", label)
	else:
		failed += 1
		print("FAIL ", label)


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	root.add_child(viewport)
	var banner: Control = BannerScene.instantiate()
	viewport.add_child(banner)
	var panel := banner.get_node("Panel") as Panel
	_check(not panel.visible, "the banner starts hidden")
	banner._animate()
	var first: Tween = banner.get("_tween")
	await create_timer(0.1).timeout
	banner._animate()
	_check(first != null and not first.is_valid(), "a new phase cancels the previous tween")
	_check(panel.visible, "the replacement phase is visible")
	await create_timer(1.6).timeout
	_check(
		not panel.visible and panel.position.x + panel.size.x <= 0,
		"completion hides and parks the whole panel"
	)
	viewport.size = Vector2i(1920, 1009)
	await process_frame
	_check(
		not panel.visible and panel.position.x + panel.size.x <= 0,
		"idle growth cannot expose the old 640px stripe"
	)
	_check(is_equal_approx(panel.size.x, 1920), "the panel spans the resized viewport")
	_check(
		is_equal_approx(panel.position.y + panel.size.y / 2, 1009.0 / 2),
		"the banner is vertically centred"
	)
	# Resizing in slide-in, hold and slide-out always cancels the cosmetic tween.
	for delay in [0.1, 0.5, 1.2]:
		banner._animate()
		await create_timer(delay).timeout
		viewport.size = Vector2i(1280, 720)
		await process_frame
		_check(
			not panel.visible and panel.position.x + panel.size.x <= 0,
			"resize at %.1fs cancels and hides" % delay
		)
		viewport.size = Vector2i(1920, 1009)
		await process_frame
	banner._animate()
	_check(
		panel.visible and panel.position.x == 1920, "the next phase starts at the new right edge"
	)
	await create_timer(1.6).timeout
	_check(not panel.visible, "animation still completes after resize cancellation")
	viewport.queue_free()
	await process_frame
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
