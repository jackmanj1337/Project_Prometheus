extends Control
# Defeat-only overlay. Victories are presented by MapResultsScreen so campaign
# continuation and authored branch choice never share the failure-action menu.

@onready var _title: Label = $Panel/VBox/Title
@onready var _standings_label: Label = $Panel/VBox/Standings
@onready var _retry_btn: Button = $Panel/VBox/RetryButton
@onready var _quit_btn: Button = $Panel/VBox/QuitButton

const MenuScale = preload("res://scripts/ui/MenuScale.gd")
const Standings = preload("res://scripts/ui/StandingsFormatter.gd")

# Victory/defeat presentation must sit UNDER pending level-ups and promotions, so
# progression earned on the killing blow resolves before the battle ends
# (V026-05d / B5-VICTORY-PROGRESSION-SEQ). CombatResolver awards EXP (→
# level_up_started, and a queued promotion_available when auto-promote is on)
# BEFORE handle_death fires unit_died → map_resolved, so by the time a result
# lands one of these progression flags is already set. We hold the result and
# present only once the level-up/promotion queue has drained.
var _result_pending: bool = false
var _level_up_active: bool = false
var _promotion_active: bool = false
var _suspend_deleted_for_result: bool = false
var _defeat_received: bool = false


func _ready() -> void:
	add_to_group(MenuScale.GROUP)
	hide()
	_retry_btn.pressed.connect(_on_retry)
	_quit_btn.pressed.connect(_on_quit)
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.map_defeat.connect(_on_defeat)
		bus.map_resolved.connect(_on_map_resolved)
		# Track the progression queue so presentation waits it out.
		bus.level_up_started.connect(func(): _level_up_active = true)
		bus.level_up_finished.connect(_on_level_up_finished)
		bus.promotion_started.connect(func(): _promotion_active = true)
		bus.promotion_finished.connect(_on_promotion_finished)
	_apply_menu_scale_from_settings()


func apply_menu_scale(factor: float) -> void:
	MenuScale.apply_to($Panel, factor, true)


func _apply_menu_scale_from_settings() -> void:
	apply_menu_scale(MenuScale.factor_from_settings(self))


func _on_defeat() -> void:
	_defeat_received = true
	_title.text = "Defeat..."
	_request_present()


# M16 stage 4: paint the ranked standings under the title. Receives the same
# winner / standings the TurnManager evaluator built (Decision 8).
func _on_map_resolved(winner_group: String, standings: Array) -> void:
	if not _defeat_received:
		return
	# The header is set by the matching map_victory / map_defeat call which fires
	# right before this one — overwrite only when we have a clearer state to show.
	if winner_group == "":
		_title.text = "Draw"
	_standings_label.text = Standings.format(winner_group, standings)
	_request_present()


# --- Present-after-progression gate (V026-05d) --------------------------------

# Marks a result ready and tries to show it now. The common case (a victory with
# no pending level-up/promotion) presents synchronously here, unchanged. When a
# progression modal is up, presentation defers until the queue drains.
func _request_present() -> void:
	_delete_mid_map_slot_after_resolution()
	_result_pending = true
	_try_present()


# Shows the overlay only when no level-up/promotion is in flight. Idempotent: the
# first successful call clears the pending flag so repeat/deferred calls are no-ops.
func _try_present() -> void:
	if not _result_pending:
		return
	if _level_up_active or _promotion_active:
		return  # progression modal still up — re-checked when it finishes
	_result_pending = false
	_show_overlay()


func _on_level_up_finished() -> void:
	_level_up_active = false
	# Defer the retry: a promotion queued behind this level-up starts SYNCHRONOUSLY
	# during this same emit (PromotionScreen._on_level_up_finished → promotion_started),
	# and signal-connection order is not guaranteed. Deferring lets that cascade set
	# _promotion_active before we test, so we never present between the two modals.
	if _result_pending:
		call_deferred("_try_present")


func _on_promotion_finished() -> void:
	_promotion_active = false
	if _result_pending:
		call_deferred("_try_present")


func _show_overlay() -> void:
	show()
	_retry_btn.grab_focus()


func _delete_mid_map_slot_after_resolution() -> void:
	if _suspend_deleted_for_result:
		return
	_suspend_deleted_for_result = true
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("delete_slot"):
		save_manager.call("delete_slot", "resume_battle")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# Block all input while the overlay is up
	get_viewport().set_input_as_handled()


func _on_retry() -> void:
	# The same map is about to be replayed, so its result must not advance the
	# campaign — drop it before the reload (B1-CST Slice 2 retry rule).
	var cm := get_node_or_null("/root/CampaignManager")
	if cm and cm.has_method("clear_pending_result"):
		cm.call("clear_pending_result")
	# B1-LEDGER Phase 2: Retry is a read of the ledger's round-0 boundary entry
	# (restore_history(0)) — the same rollback the old party-only snapshot did, now
	# sourced from the unified within-map ledger.
	var gs := get_node_or_null("/root/GameState")
	var restored := false
	if gs and gs.has_method("restore_history"):
		restored = bool(gs.restore_history(0))
	# Campaign retries return to prep so deployment can change. A bare map and a
	# suspend-resumed map retain the historical direct reload behavior.
	if restored and cm and cm.has_method("route_retry_to_prep") \
			and bool(cm.call("route_retry_to_prep")):
		return
	get_tree().reload_current_scene()


func _on_quit() -> void:
	# Quitting to the menu abandons the run: the campaign position is runtime-only
	# until Slice 3 persists it, so leaving the map ends the campaign.
	var cm := get_node_or_null("/root/CampaignManager")
	if cm and cm.has_method("end_campaign"):
		cm.call("end_campaign")
	_quit_to_menu()


func _quit_to_menu() -> void:
	# Return to Boot/MainMenu — Boot re-routes to MainMenu in non-dev builds
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.has_method("reset_map_state"):
		gs.reset_map_state()
	get_tree().change_scene_to_file("res://scenes/core/Boot.tscn")
