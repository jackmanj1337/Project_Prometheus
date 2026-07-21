extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_game_over_sequencing.gd
# Covers B5-VICTORY-PROGRESSION-SEQ (review Q6 / V026-05d): MapResultsScreen must
# present UNDER pending level-ups and promotions. A result that lands while the
# progression queue is non-empty is held until the queue drains, so progression
# earned on the killing blow (kill boss -> level up -> promote -> THEN victory)
# resolves before the battle-end overlay appears.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")
const SaveManagerScript = preload("res://scripts/autoloads/SaveManager.gd")

const TEST_SAVE_DIR := "user://test_game_over_suspend_cleanup"


func _init() -> void:
	print("=== GameOver Sequencing Test ===")
	var passed := 0
	var failed := 0
	_clean_test_dir()

	var bus: Node = load("res://scripts/autoloads/EventBus.gd").new()
	bus.name = "EventBus"
	root.add_child(bus)
	var save_manager: Node = SaveManagerScript.new()
	save_manager.name = "SaveManager"
	save_manager.configure_save_dir_for_tests(TEST_SAVE_DIR)
	root.add_child(save_manager)
	var gs_script := GDScript.new()
	gs_script.source_code = "extends Node\nvar rewind_charges_left := 2\nfunc can_rewind() -> bool: return true\n"
	gs_script.reload()
	var game_state: Node = gs_script.new()
	game_state.name = "GameState"
	root.add_child(game_state)
	await process_frame

	var packed := load("res://scenes/ui/MapResultsScreen.tscn")
	if packed == null:
		print("FAIL could not load MapResultsScreen.tscn")
		quit(1)
		return
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame

	# --- Case 1: a plain victory with no progression presents immediately --------
	save_manager.save_slot(SaveManagerScript.MID_MAP_SLOT, _make_suspend_save())
	bus.map_victory.emit()
	bus.map_resolved.emit("blue", [])
	await process_frame
	if (
		screen.visible
		and screen.get_node("Panel/VBox/Title").text == "Victory!"
		and not save_manager.has_slot(SaveManagerScript.MID_MAP_SLOT)
		and bus.is_gameplay_modal_locked()
		and screen.get_node("Backdrop").mouse_filter == Control.MOUSE_FILTER_STOP
	):
		print("OK  victory presents immediately and deletes the mid-map slot")
		passed += 1
	else:
		print(
			(
				"FAIL immediate victory: visible=%s title=%s has_mid_map=%s"
				% [
					screen.visible,
					screen.get_node("Panel/VBox/Title").text,
					save_manager.has_slot(SaveManagerScript.MID_MAP_SLOT)
				]
			)
		)
		failed += 1

	# Reset the overlay for the sequencing case (mirror a fresh map).
	screen.hide()
	screen._release_modal_lock()
	screen._result_pending = false

	# --- Case 2: kill boss -> level up -> promote -> THEN victory -----------------
	# The killing blow awards EXP first (level_up_started, and a promotion queued
	# behind it), THEN unit_died -> map_resolved. So the result lands while the
	# level-up is still up.
	bus.level_up_started.emit()
	await process_frame
	bus.reward_committed.emit({"gold_earned": 75, "total_gold": 100, "items_awarded": []})
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
	var receipt_retained: bool = (
		"Gold earned: 75\nTotal gold: 100" in screen.get_node("Panel/VBox/Rewards").text
	)

	if (
		hidden_during_levelup
		and hidden_during_promotion
		and visible_after_queue
		and receipt_retained
	):
		print("OK  victory waits out the level-up AND the queued promotion, then presents")
		passed += 1
	else:
		print(
			(
				"FAIL sequencing: hidden_lvl=%s hidden_promo=%s visible_after=%s receipt=%s"
				% [
					hidden_during_levelup,
					hidden_during_promotion,
					visible_after_queue,
					receipt_retained
				]
			)
		)
		failed += 1

	# Victory and defeat own distinct surfaces: GameOver must ignore victory and
	# MapResults must not replace the defeat action menu.
	var game_over: Control = load("res://scenes/ui/GameOverScreen.tscn").instantiate()
	root.add_child(game_over)
	await process_frame
	screen.hide()
	screen._release_modal_lock()
	bus.map_victory.emit()
	bus.map_resolved.emit("blue", [])
	await process_frame
	var defeat_hidden_on_victory := not game_over.visible
	screen.hide()
	bus.map_defeat.emit()
	bus.map_resolved.emit("red", [])
	await process_frame
	if (
		defeat_hidden_on_victory
		and game_over.visible
		and not screen.visible
		and bus.is_gameplay_modal_locked()
		and game_over.get_node("Backdrop").mouse_filter == Control.MOUSE_FILTER_STOP
	):
		print("OK  victory and defeat present on separate result surfaces")
		passed += 1
	else:
		print(
			(
				"FAIL split surfaces: game_over_on_win=%s game_over_on_loss=%s results_on_loss=%s"
				% [not defeat_hidden_on_victory, game_over.visible, screen.visible]
			)
		)
		failed += 1
	var retry := game_over.get_node_or_null("Panel/VBox/RetryButton")
	var recent: Button = game_over.get_node_or_null("Panel/VBox/ReloadRecentButton")
	var any_save: Button = game_over.get_node_or_null("Panel/VBox/LoadGameButton")
	var rewind: Button = game_over.get_node_or_null("Panel/VBox/RewindButton")
	var main_menu := game_over.get_node_or_null("Panel/VBox/MainMenuButton")
	var all_actions := (
		retry != null
		and recent != null
		and any_save != null
		and rewind != null
		and main_menu != null
		and not rewind.disabled
		and rewind.text == "Rewind (2)"
	)
	if all_actions:
		print("OK  defeat exposes Retry, recent/any load, Rewind, and Main Menu")
		passed += 1
	else:
		print("FAIL defeat multi-choice action contract")
		failed += 1
	save_manager.save_slot("defeat_reload", _make_suspend_save())
	game_over._refresh_defeat_actions()
	if not recent.disabled and not any_save.disabled:
		print("OK  defeat enables recent/any reload when a slot exists")
		passed += 1
	else:
		print("FAIL defeat reload actions did not discover the slot")
		failed += 1
	game_over.queue_free()

	# A malformed nonterminal result must never masquerade as campaign completion.
	var cm_script := GDScript.new()
	cm_script.source_code = (
		"extends Node\n"
		+ "func is_campaign_active() -> bool: return true\n"
		+ 'func get_pending_result() -> Dictionary: return {"campaign_complete": false}\n'
		+ "func get_pending_successor_options() -> Array: return []\n"
	)
	cm_script.reload()
	var existing_campaign_manager := root.get_node_or_null("CampaignManager")
	if existing_campaign_manager != null:
		root.remove_child(existing_campaign_manager)
		existing_campaign_manager.queue_free()
	var campaign_manager: Node = cm_script.new()
	campaign_manager.name = "CampaignManager"
	root.add_child(campaign_manager)
	screen._refresh_result()
	var continue_button: Button = screen.get_node("Panel/VBox/ContinueButton")
	if not continue_button.disabled and continue_button.text == "Return to Menu":
		print("OK  malformed nonterminal result reports the fault but permits menu recovery")
		passed += 1
	else:
		print(
			(
				"FAIL malformed nonterminal result: text=%s disabled=%s manager=%s"
				% [continue_button.text, continue_button.disabled, screen._campaign_manager()]
			)
		)
		failed += 1
	campaign_manager.queue_free()

	screen.queue_free()
	save_manager.queue_free()
	game_state.queue_free()
	bus.queue_free()
	_clean_test_dir()

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _make_suspend_save() -> RefCounted:
	var save: RefCounted = SaveDataScript.new()
	save.map_runtime["map_id"] = "map_001"
	save.map_runtime["map_path"] = "res://data/maps/map_001_rout/map_001_data.tres"
	save.suspend["kind"] = "map"
	(
		save
		. ledger
		. append(
			{
				"reason": "round_start",
				"entry":
				{
					"map_runtime": save.map_runtime.duplicate(true),
					"suspend": save.suspend.duplicate(true),
					"party": {"gold": 0, "items": [], "roster": []},
				}
			}
		)
	)
	return SaveDataScript.from_dict(save.to_dict())


func _clean_test_dir() -> void:
	var err := DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("test_game_over_sequencing: failed to create test dir: %s" % error_string(err))
		return
	var dir := DirAccess.open(TEST_SAVE_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		dir.remove(file_name)
