extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_game_over_sequencing.gd
# Covers B5-VICTORY-PROGRESSION-SEQ (review Q6 / V026-05d): the GameOverScreen must
# present UNDER pending level-ups and promotions. A result that lands while the
# progression queue is non-empty is held until the queue drains, so progression
# earned on the killing blow (kill boss -> level up -> promote -> THEN victory)
# resolves before the battle-end overlay appears.


func _init() -> void:
	print("=== GameOver Sequencing Test ===")
	var passed := 0
	var failed := 0

	var bus: Node = load("res://scripts/autoloads/EventBus.gd").new()
	bus.name = "EventBus"
	root.add_child(bus)
	await process_frame

	var packed := load("res://scenes/ui/GameOverScreen.tscn")
	if packed == null:
		print("FAIL could not load GameOverScreen.tscn")
		quit(1)
		return
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame

	# --- Case 1: a plain victory with no progression presents immediately --------
	bus.map_victory.emit()
	bus.map_resolved.emit("blue", [])
	await process_frame
	if screen.visible and screen.get_node("Panel/VBox/Title").text == "Victory!":
		print("OK  victory with no pending progression presents immediately"); passed += 1
	else:
		print("FAIL immediate victory: visible=%s title=%s" % [
			screen.visible, screen.get_node("Panel/VBox/Title").text]); failed += 1

	# Reset the overlay for the sequencing case (mirror a fresh map).
	screen.hide()
	screen._result_pending = false

	# --- Case 2: kill boss -> level up -> promote -> THEN victory -----------------
	# The killing blow awards EXP first (level_up_started, and a promotion queued
	# behind it), THEN unit_died -> map_resolved. So the result lands while the
	# level-up is still up.
	bus.level_up_started.emit()
	await process_frame
	bus.map_victory.emit()
	bus.map_resolved.emit("blue", [])
	await process_frame
	var hidden_during_levelup := not screen.visible

	# Level-up dismissed. In the live flow the queued promotion opens SYNCHRONOUSLY
	# during this emit (promotion_started nested inside level_up_finished); emitting
	# them in sequence before the deferred present flush reproduces that gap. A naive
	# synchronous present would pop the overlay here, between the two modals.
	bus.level_up_finished.emit()
	bus.promotion_started.emit()
	await process_frame
	var hidden_during_promotion := not screen.visible

	# Promotion confirmed -> the queue is finally empty -> present now.
	bus.promotion_finished.emit()
	await process_frame
	var visible_after_queue := screen.visible

	if hidden_during_levelup and hidden_during_promotion and visible_after_queue:
		print("OK  victory waits out the level-up AND the queued promotion, then presents"); passed += 1
	else:
		print("FAIL sequencing: hidden_lvl=%s hidden_promo=%s visible_after=%s" % [
			hidden_during_levelup, hidden_during_promotion, visible_after_queue]); failed += 1

	screen.queue_free()
	bus.queue_free()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
